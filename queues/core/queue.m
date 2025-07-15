classdef (Abstract) queue < handle
    %QUEUE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        id
        simulationId
        clock 
        utilsClock % variabile ausiliaria 

        previousServers % server precedenti (anche più di uno)
        previousGenerators % generatori precedenti (anche più di uno)
        destinationServer % server destinazione (unico)

        customerList  
        lengthQueue  % lunghezza coda corrente 
        
        overtakingFlag % la coda che permette i sorpassi di customer nel servizio?
        waitingFlag % i customer dal server sono persi o aspettano liberazione posti? 
              
        count  % numero di customer che sono stati in coda (non conta i persi) 
        averageLength  
        lostCustomer  % numero customer persi

 
    end
    
    methods
        % Costruttore su caratteristiche intrinseche
        function obj = queue(overtakingFlag, waitingFlag) 

            % istanziazioni di default
            obj.id = nodeIdGenerator.getId();
            obj.simulationId = 0; 
            obj.clock = inf; 
            obj.utilsClock = 0; 
            obj.customerList = customer.empty(); 
            obj.lengthQueue = 0;  
            obj.count = 0; 
            obj.averageLength = 0; 
            obj.lostCustomer = 0; 

            % istanziazioni caratteristiche
            obj.overtakingFlag = overtakingFlag; 
            obj.waitingFlag = waitingFlag; 
        end
        
         % caraterizzazione Network locale

        function destinationServerAssignment(obj, destinationServer)
            obj.destinationServer = destinationServer;
        end

        function previousServersAssignment(obj, previousServers)
            obj.previousServers = previousServers;
        end

        function previousGeneratorsAssignment(obj, previousGenerators)
            obj.previousGenerators = previousGenerators;
        end

        function initialize(obj)
            % non fa nulla 
        end
        
        function updateFlag = update(obj, externalClock, eventsList, displayFlag)

             % verifica ed esecuzione uscita da coda 
             nextServer = obj.destinationServer;
             [servicePossible, selectedCustomer] = nextServer.checkAvailability(); % servicePossible è la flag 

             enterServerFlag = false; 

             % finquando è possibile 
             while servicePossible == true
                enterServerFlag = true; 
                nextServer.scheduleNextEvents(selectedCustomer, externalClock, eventsList);

                if displayFlag
                    fprintf('Customer %d preso in carico dal Server %d dalla Queue %d (clock %.2f)\n', ...
                    selectedCustomer.id, nextServer.simulationId, obj.simulationId, externalClock);
  
                    fprintf('--- Stato Server %d ---\n', nextServer.simulationId);
                    for j = 1:nextServer.numServer
                        fprintf(' • Servitore %d: %s\n', j, string(nextServer.serverState(j)));
                    end
                    fprintf('-----------------------------\n\n');
                end

                [servicePossible, selectedCustomer] = nextServer.checkAvailability();
             end

             % verifica ed esecuzione entrata in coda 
             exitServerFlag = false; 

             % ricerca di nuovi customer in coda 
             for i = 1:length(obj.previousServers) 

                 % server precedenti selezionati senza priorità 
                 prevServer = obj.previousServers(i);

                 % finquando è possibile libera il server e riempi la coda 
                 while prevServer.canExit()

                     exitServerFlag = true; 

                     % gestisce uscita da server 
                     prevServer.exitCustomer(externalClock, eventsList);

                     if displayFlag
                        newCustomer = obj.customerList(end); % ultimo customer inserito
                        fprintf('Customer %d è uscito dal Server %d ed è entrato in Queue %d (clock %.2f)\n', ...
                        newCustomer.id, prevServer.simulationId, obj.simulationId, externalClock);

                        fprintf('--- Stato Server %d ---\n', prevServer.simulationId);
                        for j = 1:prevServer.numServer
                            fprintf(' • Servitore %d: %s\n', j, string(prevServer.serverState(j)));
                        end
                        fprintf('-----------------------------\n\n');
                     end
                 end
             end

             % flag che indica se la coda è stata aggiornata
             updateFlag = enterServerFlag || exitServerFlag; 
        end 

        % funzione gestore uscita semplice 
        function exitMangement(obj, customer, externalClock)

            % ricerca customer 
              for i = length(obj.customerList):-1:1
                
                  if obj.customerList(i) == customer

                      % aggiornamento eventi customer 
                      customer.endTime(obj.id) = externalClock;


                      % aggiornamento coda 
                      obj.statUpdate(externalClock); % aggiornamento statistiche 
                      obj.customerList(i) = []; 
                      obj.lengthQueue = obj.lengthQueue - 1;

                      break;
                  end
              end
        end 

        function statUpdate(obj, externalClock) % aggiorna lunghezza media tramite utils clock 

            % lunghezza coda attuale è tenuta da precedente evento salvato

            % aggiornamento lunghezza media coda
            clockDiff = externalClock - obj.utilsClock;   
            totalLength = obj.averageLength * obj.utilsClock + clockDiff * obj.lengthQueue;
            obj.averageLength = totalLength/externalClock;

            % aggiorna clock 
            obj.utilsClock = externalClock; 

        end

        function displayAgentState(obj, externalClock)
            fprintf('Queue ID: %d\n', obj.simulationId);
            fprintf(' → Current Length: %d\n', obj.lengthQueue);
            fprintf(' → Average Length: %.2f\n', obj.averageLength);
            fprintf(' → Lost Customers: %d\n', obj.lostCustomer);
            fprintf(' → Customers transitati: %d\n', obj.count);
            fprintf('-----------------------------\n');
        end


    end
    methods (Abstract)
        arrivalManagment(obj, customer, externalClock)
        isAvailable = isQueueAvailable(obj) % è possibile rilasciare customer in coda da server? 
        clear(obj)
    end
end


