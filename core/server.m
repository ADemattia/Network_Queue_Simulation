classdef (Abstract) server < handle
    % server è la classe astratta che rappresenta i servitori sono
    % implementate alcune proprietà 
    
    properties
        id
        clock 
         
        destinationQueue % coda arrivo (unica) 
        previousQueues % code precedenti (anche più di una) 
        numPreviousQueues % numero code precedenti 
        selectedQueue % coda selezionata per servizio 
        
        
        numServer % numero server
        serverState % indicatori stato server (Free, Working, Waiting, Producing, etc.) 
        clockServer % tempi completamento per ogni server
        customerToServer % vettore customer serviti da server 
        
        serverDistribution % distribuzione tempi di completamento 
        eventServer % server associato al primo evento 
        
        notFullyOccupied % variabile 0/1: almeno un server è libero (1) 
 
        exitWaitingList % lista customer in uscita 

        revenueFunction % funzione di revenue 
        revenue % revenue totali server 

        count % conteggio customer 
    end
    
    methods
        % Costruttore su caratteristiche intrinseche
        function obj = server(numServer, serverDistribution, revenueFunction) 
            % istanziazioni di default
            obj.id = nodeIdGenerator.getId();
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

        end
        
        % caratterizzazione Network locale 

        function destinationQueueAssignment(obj, destinationQueue)
            obj.destinationQueue = destinationQueue; % coda uscita
        end

        function previousQueuesAssignment(obj, previousQueues)
            obj.previousQueues = previousQueues; % code precedenti 
            obj.numPreviousQueues = length(obj.previousQueues); 
        end


        % dato un customer trova l'indice del server associato 
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
    end 

    methods (Abstract)
         [servicePossible, selectedCustomer] = checkAvailability(obj); % il server può iniziare un nuovo lavoro
         scheduleNextEvents(obj,customer,externalClock);
         addWaiting(obj);  
         exitCustomer(obj); 
         clearServer(obj); 
    end

end

