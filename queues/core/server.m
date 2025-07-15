classdef (Abstract) server < handle
    % server è la classe astratta che rappresenta i servitori sono
    % implementate alcune proprietà 
    
    properties
        id
        simulationId
        clock 
         
        destinationQueue  % coda arrivo (unica) 
        previousQueues  % code precedenti (anche più di una) 
        numPreviousQueues % numero code precedenti 
        selectedQueue % coda selezionata per servizio 
        
        
        numServer % numero server
        serverState % indicatori stato server (Free, Working, Waiting, Producing, etc.) 
        clockServer % tempi completamento per ogni server
        customerToServer % vettore customer serviti da server 
        
        serverDistribution % distribuzione tempi di completamento 
        eventServer % server associato al primo evento 
        
        notFullyOccupied % indica se è disponibile almeno un servitore (1)  
 
        exitWaitingList % lista customer in uscita 

        revenueFunction % funzione di revenue 
        revenue % revenue totali server 

        count % conteggio customer 

        % vettori per calcolo tempo in uno stato dei server
        timeInFree
        timeInWorking
        timeInWaiting
        timeInStuck

        clockPreviousState  % variabile ausiliaria 
    end
    
    methods
        % Costruttore su caratteristiche intrinseche
        function obj = server(numServer, serverDistribution, revenueFunction) 
            % istanziazioni di default
            obj.id = nodeIdGenerator.getId();
            obj.simulationId = 0; 
            obj.clock = inf; 
            obj.eventServer = NaN;
            obj.exitWaitingList = customer.empty(); 
            obj.notFullyOccupied = 1;
            obj.revenue = 0;
            obj.count = 0; 

            % istanziazioni caratteristiche 
              
            obj.numServer = numServer;  
            obj.customerToServer = repmat(customer(), obj.numServer, 1); % indica quale customer sta servendo il server 
            obj.serverState = repmat(serverState.Free, obj.numServer, 1); % classe enumerazione 
            obj.clockServer = inf(obj.numServer,1); 
            obj.serverDistribution = serverDistribution; 
            obj.revenueFunction = revenueFunction;

            obj.timeInFree = zeros(obj.numServer,1); 
            obj.timeInWorking = zeros(obj.numServer,1);
            obj.timeInWaiting = zeros(obj.numServer,1);
            obj.timeInStuck = zeros(obj.numServer,1);
            obj.clockPreviousState = zeros(numServer,1); % inizializzata a 0 

        end
        
        
        % caratterizzazione Network locale 

        function destinationQueueAssignment(obj, destinationQueue)
            obj.destinationQueue = destinationQueue; % coda uscita
        end

        function previousQueuesAssignment(obj, previousQueues)
            obj.previousQueues = previousQueues; % code precedenti 
            obj.numPreviousQueues = length(obj.previousQueues); 
        end


        function initialize(obj)
            % non fa nulla 
        end
        

        function execute(obj, externalClock, eventsList, displayFlag)

            lastCustomer = obj.customerToServer(obj.eventServer);  % prendo lcultimo customer in lista waiting
            % customer inserito in lista waiting (lista uscita)
            obj.addWaiting(externalClock, eventsList);

            if  displayFlag        
                fprintf('Customer %d aggiunto in waiting/stuck list del Server %d (clock %.2f)\n', ...
                    lastCustomer.id, obj.simulationId, externalClock);
                fprintf('--- Stato Server %d ---\n', obj.simulationId);
                for i = 1:obj.numServer
                    fprintf(' • Servitore %d: %s\n', i, string(obj.serverState(i)));
                end
                fprintf('-----------------------------\n\n');
            end



            eventsList.update(obj.simulationId, obj.clock); 

            % se c'è possibilità di rilascio nella coda successiva 
            while obj.canExit() 
                % fa uscire customer e aggiorna server in modalità free
                % lista di eventi aggiornata internamente 
                obj.exitCustomer(externalClock, eventsList);

                if  displayFlag
                    newCustomer = obj.destinationQueue.customerList(end); % ultimo customer inserito
                    fprintf('Customer %d è uscito dal Server %d ed è entrato in Queue %d (clock %.2f)\n', ...
                        newCustomer.id, obj.simulationId, obj.destinationQueue.simulationId, externalClock);
                    fprintf('--- Stato Server %d ---\n', obj.simulationId);
                    for i = 1:obj.numServer
                        fprintf(' • Servitore %d: %s\n', i, string(obj.serverState(i)));
                    end
                    fprintf('-----------------------------\n\n');
                end 
                
            end 
        end 

        % funzione update stato server, cosa fa: 
        % 1. Server controlla possibilità nuove uscite
        % 2. Server controlla possibilità nuovi servizi 
        function updateFlag = update(obj, externalClock, eventsList, displayFlag)

            % flag che indica se la coda è stata aggiornata
            updateFlag = false; 

            while obj.canExit() 

                updateFlag = true; 

                % libera server e inserisce customer in coda successiva
                obj.exitCustomer(externalClock, eventsList);

                if displayFlag
                    newCustomer = obj.destinationQueue.customerList(end); % ultimo customer inserito
                    fprintf('Customer %d uscito dal Server %d e inviato alla Queue %d (clock %.2f)\n', ...
                        newCustomer.id, obj.simulationId, obj.destinationQueue.simulationId, externalClock);
                    fprintf('--- Stato Server %d ---\n', obj.simulationId);
                    for i = 1:obj.numServer
                        fprintf(' • Servitore %d: %s\n', i, string(obj.serverState(i)));
                    end
                    fprintf('-----------------------------\n\n');

                end
            end 

            % controllo possibilità nuovo servizio
            [servicePossible, selectedCustomer] = obj.checkAvailability(); 
     
            % finchè il servizio è possibile schedula nuovi eventi 
            while servicePossible 

                updateFlag = true;

                obj.scheduleNextEvents(selectedCustomer, externalClock, eventsList);

                if displayFlag
                    fprintf('Customer %d preso in carico dal Server %d dalla Queue %d (clock %.2f)\n', ...
                    selectedCustomer.id, obj.simulationId, obj.destinationQueue.simulationId, externalClock);

                    fprintf('--- Stato Server %d  ---\n', obj.simulationId);
                    for i = 1:obj.numServer
                        fprintf(' • Servitore %d: %s\n', i, string(obj.serverState(i)));
                    end
                    fprintf('-----------------------------\n\n');
                end

                % controllo possibilità nuovo servizio
                [servicePossible, selectedCustomer] = obj.checkAvailability();
            end

        end 

  
        % COMMENTO : si potrebbe raffinare sul tipo di customer
        function exitAllowed = canExit(obj) % indica se un lavoro finito può uscire        
            if isempty(obj.exitWaitingList) 
                exitAllowed = false;
                return;
            end

            queue = obj.destinationQueue; 
            isAvailable = queue.isQueueAvailable(); % disponibilità coda 
            exitAllowed = isAvailable; % possibilità uscita da server
        end 
    
        % funzione ausiliaria per calcolo 
        function updateServerTime(obj, serverId, externalClock)

            % calcola il tempo trascorso dall'ultimo aggiornamento
            deltaT = externalClock - obj.clockPreviousState(serverId);
        
            % Identifica lo stato corrente del server
            switch obj.serverState(serverId)
                case serverState.Free
                    obj.timeInFree(serverId) = obj.timeInFree(serverId) + deltaT;
                case serverState.Working
                    obj.timeInWorking(serverId) = obj.timeInWorking(serverId) + deltaT;
                case serverState.Waiting
                    obj.timeInWaiting(serverId) = obj.timeInWaiting(serverId) + deltaT;
                case serverState.StuckInTraffic
                    obj.timeInStuck(serverId) = obj.timeInStuck(serverId) + deltaT;
            end
        
            % aggiorna il tempo precedente di stato
            obj.clockPreviousState(serverId) = externalClock;
        end

        % funzione ausiliaria per ricerca customer 
        function [found, serverId] = getServerFromCustomer(obj, targetCustomer)
            found = false; 
            serverId = [];

            for i = 1:length(obj.customerToServer)
                if isequal(obj.customerToServer(i), targetCustomer)
                    found = true; 
                    serverId = i;
                    return;
                end
            end
        end
        function displayAgentState(obj, externalClock)
            fprintf('Server ID: %d\n', obj.simulationId);
            fprintf(' → Num Servitori: %d\n', obj.numServer);
            
            for i = 1:obj.numServer
                fprintf('   - Servitore %d: %s\n', i, string(obj.serverState(i)));
                fprintf('     • Tempo in Free:     %.2f\n', obj.timeInFree(i));
                fprintf('     • Tempo in Working:  %.2f\n', obj.timeInWorking(i));
                fprintf('     • Tempo in Waiting:  %.2f\n', obj.timeInWaiting(i));
                fprintf('     • Tempo in Stuck:    %.2f\n', obj.timeInStuck(i));
            end
        
            fprintf(' → Totale clienti gestiti: %d\n', obj.count);
            fprintf(' → Revenue accumulata: %.2f\n', obj.revenue);
            fprintf('-----------------------------\n');
        end
    end 



    methods (Abstract)
         [servicePossible, selectedCustomer] = checkAvailability(obj); % server può iniziare nuovo lavoro? 
         scheduleNextEvents(obj,customer,externalClock, eventsList); % schedulazione nuovo completmento

         % funzione waiting è eseguita a completamento servizio 
         addWaiting(obj, externalClock, eventsList);  % porta un customer nella coda dei wait

         % funzione exit fa uscire il customer (già servito) dalla waiting list 
         exitCustomer(obj, externalClock, eventsList); % fa uscire un customer 
         clear(obj); 
    end

end

