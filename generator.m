classdef generator < handle 
    %GENERATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        id
        clock

        interArrivalDistribution % funzione per i tempi interarrivo 
        queueDestination

        customerGenerated
        networkLength

        numType % numero tipi in tutto il sistema, non solo generabili dall'oggetto specifico 
        typeDistribution  % funzione per la definizione del tipo di customer
         
        count  % numero customer generati
        countPerType 
    end
    
    methods
        % FUNZIONI DI CREAZIONE 
        % Costruttore su caratteristiche intrinseche 
        function obj = generator(interArrivalDistribution, numType, typeDistribution) % Costruttore generator 
            % istanziazioni di default
            obj.id = nodeIdGenerator.getId();
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

        % funzione per la gestone dei nuovi arrivi e caratterizzazione
        % customer 
        function scheduleNextArrival(obj)
            % randomicità arrivi 
            interArrival = obj.interArrivalDistribution(1);
            obj.clock = obj.clock + interArrival; 

            % randomicità customer 
            type = obj.typeDistribution(1); 

            % chiamata a costruttore customer
            obj.customerGenerated = customer(type, obj.clock, obj.networkLength);

            obj.count = obj.count + 1; % aggiorna conteggio totale 
            obj.countPerType(type) = obj.countPerType(type) + 1; % aggiorna conteggio per tipo 
        end
        
        % funzione che gestisce l'uscita del customer dal generatore 
        function customerExit(obj)
            customerInSystem = obj.customerGenerated; 
            queue = obj.queueDestination; 
            queue.arrivalManagment(customerInSystem); % accoglienza nuovo customer in coda destinazione 
            obj.customerGenerated = customer(); % liberazione in generator 
        end

        % Pulitore statistiche 
        function clearGenerator(obj)
            obj.clock = 0;
            obj.customerGenerated = customer();
            obj.count = 0;
            obj.countPerType = zeros(1, obj.numType);
        end

        % FUNZIONI INFORMATIVE 

        function dispClock(obj)
            disp(obj.clock); 
        end

        function dispCustomerGenerated(obj)
            obj.customerGenerated.dispCustomer();
        end 

        function dispStatus(obj)
            disp(['Genrarator ID: ', num2str(obj.id)]);
            fprintf('Tempo di arrivo: %.2f\n', obj.clock);
            fprintf('Informazioni cliente:\n');
            obj.customerGenerated.dispCustomer();
            fprintf('Numero clienti arrivati finora: %d\n', obj.count);
            fprintf('------------------------------\n');
        end
    end
end

