classdef generator < handle 
    % classe generatore per la simulazione di network queue, genera i
    % customer con tempi interarrivo e tipi personalizzabili 
    
    properties
        id
        simulationId
        clock

        interArrivalDistribution % funzione (anche randomica) per i tempi interarrivo 
        queueDestination % coda di destinazione 

        customerGenerated 
        networkLength % numero entità in rete (utile per costruzione customer) 

        numType % numero tipi di customer in tutto il sistema
        typeDistribution  % funzione (anche randomica) per l'assegnazione del tipo 
         
        count  % numero customer totali 
        countPerType % numero customer per tipo 
    end
    
    methods
        % FUNZIONI DI CREAZIONE 
        % Costruttore su caratteristiche intrinseche 
        function obj = generator(interArrivalDistribution, numType, typeDistribution) % Costruttore generator 
            % istanziazioni di default
            obj.id = nodeIdGenerator.getId();
            obj.simulationId = 0; 
            obj.clock = 0; 
            obj.customerGenerated = customer(); 
            obj.count = 0; 

            % istanziazioni caratteristiche 
            obj.interArrivalDistribution = interArrivalDistribution; 
            
            obj.numType = numType; 
            obj.typeDistribution = typeDistribution;
            
            obj.countPerType = zeros(numType,1); % da eliminare se i tipi sono continui, nel lavoro si sono considerati solo tipi discreti e finiti  
        end

        % caratterizzazione Network
        function queueAssignment(obj, queueDestination, networkLength)
            obj.networkLength = networkLength; 
            obj.queueDestination = queueDestination;
        end

        % FUNZIONI OPERATIVE

        % funzione per inizializzazione simulazione 
        function initialize(obj)
            obj.scheduleNextArrival();
        end
        
        % funzione di gestione eventi di generator 
        function execute(obj, externalClock, eventsList, displayFlag)

            if displayFlag
                lastCustomer = obj.customerGenerated;
                fprintf('Customer %d generato dal Generatore %d e inviato alla Queue %d (clock %.2f)\n', ...
                lastCustomer.id, obj.simulationId, obj.queueDestination.simulationId, externalClock);
                fprintf('-----------------------------\n\n');
            end

            % fa uscire customer e lo fa entrare in coda 
            obj.customerToQueue(externalClock);

            % schedula nuovo arrivo e aggiorna internamente l'orologio di eventsList
            obj.scheduleNextArrival(externalClock, eventsList, displayFlag); 

        end

        % funzione update stato 
        function updateFlag = update(obj, externalClock, eventsList, displayFlag)
            % il generatore non viene mai aggiornato per altri eventi
            updateFlag = false; 
        end 

        % schedulazione nuovo arrivo 
        function scheduleNextArrival(obj, externalClock, eventsList, displayFlag)

            % sono possibili accoppiate strane: tempo di arrivo influenza
            % tipo di customer o viceversa

            interArrival = obj.interArrivalDistribution();

            % clock nuovo arrivo 
            obj.clock = obj.clock + interArrival; 
            
            % randomicità customer 
            type = obj.typeDistribution(); 

            % chiamata a costruttore customer
            obj.customerGenerated = customer(type, obj.clock, obj.networkLength);
            
            % aggiornamento path ed eventi customer 
            obj.customerGenerated.path(end + 1) = obj.id;  
            obj.customerGenerated.startTime(obj.id) = obj.clock; 

            % aggiornamento conteggi 
            obj.count = obj.count + 1; 
            obj.countPerType(type) = obj.countPerType(type) + 1; 

            if nargin >= 3 && ~isempty(eventsList)
                % aggiorna lista eventi - con id della simulazione 
                eventsList.update(obj.simulationId, obj.clock);
            end
        end
        
        % funzione che gestisce l'uscita del customer dal generatore 
        function customerToQueue(obj, externalClock)
            customerToExit = obj.customerGenerated; 

            % aggiornamento eventi customer 
            customerToExit.endTime(obj.id) = obj.clock;

            % accoglienza nuovo customer in coda destinazione
            queue = obj.queueDestination; 
            queue.arrivalManagment(customerToExit, externalClock);  

            % liberazione in generator
            obj.customerGenerated = customer();
        end

        function displayAgentState(obj, externalClock)
            fprintf('Generator ID: %d\n', obj.simulationId);
            fprintf(' → Customer generati totali: %d\n', obj.count);
        
            if ~isempty(obj.countPerType)
                fprintf(' → Customer per tipo:\n');
                for i = 1:obj.numType
                    fprintf('    • Tipo %d: %d\n', i, obj.countPerType(i));
                end
            end
        
            fprintf('-----------------------------\n');
        end
        % resetta statistiche 
        function clear(obj)
            obj.clock = 0;
            obj.customerGenerated = customer();
            obj.count = 0;
            obj.countPerType = zeros(obj.numType, 1);
        end

        % FUNZIONI INFORMATIVE 
    end
end

