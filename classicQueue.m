classdef classicQueue < queue
    % classicQueue è una classe concreta di queue e rappresenta una coda
    % con politica accept-reject rispetto alla capacità 
    
    properties
        capacity
    end
    
    methods
        function obj = classicQueue(overtakingFlag, waitingFlag, capacity)
            % chiamata a costruttore classe astratta 
            obj@queue(overtakingFlag,waitingFlag); 

            % proprietà caratteristiche 
            obj.capacity = capacity; 
        end

        function arrivalManagment(obj, customer)
            % politica di balking
            if obj.lengthQueue < obj.capacity
                obj.customerList(end + 1) = customer;
                obj.lengthQueue = obj.lengthQueue + 1;

                % se customer accettato, si aggiunge nel conteggio totale 
                obj.count = obj.count + 1; 

            else % obj.lengthQueue == obj.capacity - tutto occupato 
                obj.lostCustomer = obj.lostCustomer + 1; 
            end 
        end

        function isAvailable = isQueueAvailable(obj)
            if obj.waitingFlag == false % ovvero il customer va subito dentro
                isAvailable = true; 
            elseif obj.waitingFlag == true % il customer può aspettare nel server 
                if obj.lengthQueue < obj.capacity
                    isAvailable = true; 
                else % obj.lengthQueue >= obj.capacity - customer aspetta nel server che la coda si liberi
                    isAvailable = false; 
                end
            end
        end 


        function printStats(obj)
            fprintf('Lunghezza coda: %d\n', obj.lengthQueue);
            fprintf('Clienti persi: %d\n', obj.lostCustomer);
            fprintf('------------------------\n');
        end

        % Pulitore statistiche 
        function clearQueue(obj)
        obj.clock = 0;
        obj.customerList = customer.empty();
        obj.lengthQueue = 0;
        obj.count = 0;
        obj.lostCustomer = 0;
        end
    end
end

