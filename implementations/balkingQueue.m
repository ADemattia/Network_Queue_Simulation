classdef balkingQueue < queue
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        hardCapacity  % capacità hard 
        
        softCapacity  % capacità soft 

        totalCapacity  % capacità totale 

        softCapacityDistribution % funzione distribuzione per accettazione posto soft 
    end
    
    methods
        function obj = balkingQueue(overtakingFlag, waitingFlag, hardCapacity, softCapacity, softCapacityDistribution)
            % chiamata a costruttore classe astratta
            obj@queue(overtakingFlag, waitingFlag); 

            % proprietà caratteristiche 
            obj.hardCapacity = hardCapacity; 
            obj.softCapacity = softCapacity; 
            obj.totalCapacity = obj.hardCapacity + obj.softCapacity; 

            obj.softCapacityDistribution = softCapacityDistribution;
        end

        function arrivalManagment(obj, customer)
            customer.path(end + 1) = obj.id;
            customer.startTime(obj.id) = obj.clock; % tempo entrata in coda 

            % politica di balking
            if obj.lengthQueue < obj.hardCapacity % posti hard
                obj.customerList(end + 1) = customer;
                obj.lengthQueue = obj.lengthQueue + 1; 
                obj.count = obj.count + 1; % aggiornato conteggio 

            elseif obj.lengthQueue >= obj.hardCapacity && obj.lengthQueue < obj.totalCapacity % posti soft 
                    decision = obj.softCapacityDistribution(); % campionamento decisione 

                    if decision == 1
                        obj.customerList(end + 1) = customer;
                        obj.lengthQueue = obj.lengthQueue + 1; 
                        obj.count = obj.count + 1; % aggiornato conteggio 

                    else % decision == 0 
                        obj.lostCustomer = obj.lostCustomer + 1; 
                    end

            else % obj.lengthQueue == obj.totalCapacity - posti esauriti 
                obj.lostCustomer = obj.lostCustomer + 1; 
            end 
        end

        function isAvailable = isQueueAvailable(obj)
            isAvailable = obj.waitingFlag; % sempre disponibile 
        end 
        
        % Pulitore statistiche 
        function clearQueue(obj)
            obj.clock = 0;
            obj.customerList = customer.empty();
            obj.lengthQueue = 0;
            obj.count = 0;
            obj.lostCustomer = 0;
            obj.averageLength = 0; 
        end

        function printStats(obj)
            fprintf('Lunghezza coda: %d\n', obj.lengthQueue);
            fprintf('Clienti persi: %d\n', obj.lostCustomer);
            fprintf('------------------------\n');
        end
    end
end

