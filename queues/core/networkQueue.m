classdef networkQueue
    
    properties
        queueNodes  % cell array di oggetti: generatori, code, server
        queueArray  % array di sole code, usato per statistiche di coda 
        
        queueGraph % matrice di adiacenza che descrive le connessioni tra nodi

        endQueue % coda finale in cui si accumulano i clienti usciti dall'ultimo server
    end
    
    methods
        function obj = networkQueue(queueNodes, queueGraph)

            obj.queueNodes = queueNodes; 
            obj.queueArray = [obj.queueNodes{cellfun(@(x) isa(x, 'queue'), obj.queueNodes)}]; 
            obj.queueGraph = queueGraph;
           
            waitingFlag = false; 
            obj.endQueue = classicQueue(1, waitingFlag, inf); % setup coda finale - collector 
            obj.endQueue.simulationId = inf; % id di simulazione a inf 
        end
        
        function networkSetUp(obj)

            networkLength = length(obj.queueNodes); 
            for i = 1: networkLength
                node = obj.queueNodes{i};

                if isa(node, 'generator')
                    % trova coda di destinazione e assegna al generatore
                    queueId = find(obj.queueGraph(i, :) == 1); 
                    node.queueAssignment(obj.queueNodes{queueId}, networkLength); 

                elseif isa(node, 'queue')
                    % assegna server di destinazione
                    destinationServerId = find(obj.queueGraph(i, :) == 1);
                    node.destinationServerAssignment(obj.queueNodes{destinationServerId}); 

                    % trova generatori e server precedenti e assegna
                    previousEntitiesId = find(obj.queueGraph(:, i) == 1);
                    previousGeneratorsId = []; 
                    previousServersId = [];

                    for j = 1:length(previousEntitiesId)
                        entityId = previousEntitiesId(j);
                        entity = obj.queueNodes{entityId};
                        
                        previousGeneratorsId = []; 
                        previousServersId = []; 

                        if isa(entity, 'generator')
                            previousGeneratorsId(end+1) = entityId;  
                        elseif isa(entity, 'server')
                            previousServersId(end+1) = entityId;    
                        end
                    end
                    
                    previousGenerators = [obj.queueNodes{previousGeneratorsId}];
                    previousServers = [obj.queueNodes{previousServersId}];
                    
                    node.previousGeneratorsAssignment(previousGenerators);
                    node.previousServersAssignment(previousServers);

                else % isa(node, 'server')
                    previousQueueId = find(obj.queueGraph(:, i) == 1);
                    previousQueues = [obj.queueNodes{previousQueueId}];  % array di oggetti coda
                    node.previousQueuesAssignment(previousQueues); 
                    
                    % server terminale
                    if i == networkLength % server finale
                        node.destinationQueueAssignment(obj.endQueue) % i customer finiscono nella coda collector 
                    else
                        destinationQueueId = find(obj.queueGraph(i, :) == 1);
                        node.destinationQueueAssignment(obj.queueNodes{destinationQueueId});
                    end 
                end
            end 
        end

        function statisticsArrayWaiting = waitingTimeStatistic(obj)
            % customers: array di customer con campi arrivalTime, startTime e endTime
            customerList     = obj.endQueue.customerList;
            numEntities      = length(obj.queueNodes); 
            waitingTimeTotal = zeros(numEntities,1);
            totalCount       = zeros(numEntities,1); 
            
            % calcolo tempi totali e conteggi
            for i = 1:length(customerList)
                customer = customerList(i); 
                for j = 1:numEntities
                    if ~isnan(customer.endTime(j))
                        totalCount(j) = totalCount(j) + 1;
                        waitingTimeTotal(j) = waitingTimeTotal(j) + ...
                            (customer.endTime(j) - customer.startTime(j));
                    end 
                end 
            end 
        
            % calcolo tempi medi (evitando divisione per zero)
            averageWaitingTime = NaN(numEntities,1);
            for j = 1:numEntities
                if totalCount(j) > 0
                    averageWaitingTime(j) = waitingTimeTotal(j) / totalCount(j);
                end
            end
        
            % stampa delle statistiche di waiting time
            fprintf('\n====== WAITING TIME STATISTICS ======\n');
            statisticsArrayWaiting = cell(numEntities,1);
            for j = 1:numEntities
                node = obj.queueNodes{j};
                stats = struct();
                
                % tipo di nodo
                if isa(node, 'generator')
                    stats.type = 'generator';
                elseif isa(node, 'queue')
                    stats.type = 'queue';
                elseif isa(node, 'server')
                    stats.type = 'server';
                else
                    stats.type = 'unknown';
                end
                
                stats.id      = node.id;
                stats.count   = totalCount(j);
                stats.avgWait = averageWaitingTime(j);
        
                switch stats.type
                    case 'generator'
                        nodeLabel = 'Generatore';
                    case 'queue'
                        nodeLabel = 'Coda';
                    case 'server'
                        nodeLabel = 'Server';
                end
        
                if isnan(stats.avgWait)
                    fprintf('%s ID %d (%s): nessun cliente servito\n', ...
                            nodeLabel, stats.id, stats.type);
                else
                    fprintf('%s ID %d (%s): clienti serviti = %d, tempo medio di attesa = %.2f\n', ...
                            nodeLabel, stats.id, stats.type, stats.count, stats.avgWait);
                end
        
                statisticsArrayWaiting{j} = stats;
            end
            fprintf('======================================\n\n');
        end
    
                function statisticsArray = collectStatistics(obj)
            statisticsArray = cell(length(obj.queueNodes), 1);
        
            fprintf('\n========= STATISTICHE FINALI =========\n');
        
            for i = 1:length(obj.queueNodes)
                node = obj.queueNodes{i};
                stats = struct(); % statistiche salvate in struct 
        
                if isa(node, 'generator')
                    stats.type = 'generator';
                    stats.count = node.count;
                    stats.countPerType = node.countPerType;
                    
                    fprintf('Generatore ID %d: clienti generati = %d\n', node.id, node.count);
                    for t = 1:length(node.countPerType)
                        fprintf('   Tipo %d: %d clienti\n', t, node.countPerType(t));
                    end

        
                elseif isa(node, 'queue')
                    stats.type = 'queue';
                    stats.lostCustomer = node.lostCustomer;
                    stats.lengthQueue = node.lengthQueue;
                    stats.count = node.count;  % <-- conteggio totale clienti passati
                    stats.averageLength = node.averageLength; 
                    fprintf('Coda ID %d: clienti totali = %d, persi = %d, lunghezza finale = %d, lunghezza media = %.2f\n', ...
                            node.id, node.count, node.lostCustomer, node.lengthQueue, node.averageLength);
                        
                elseif isa(node, 'server')
                    stats.type = 'server';
                    stats.count = node.count;
                    stats.revenue = node.revenue;
                    stats.timeInFree = node.timeInFree;
                    stats.timeInWorking = node.timeInWorking;
                    stats.timeInWaiting = node.timeInWaiting;
                    stats.timeInStuck = node.timeInStuck;
        
                    fprintf('Server ID %d: clienti serviti = %d, revenue = %.2f\n', ...
                            node.id, node.count, node.revenue);
                    % tempo occupazione per ogni server
                    numServer = length(node.timeInFree);
                    for j = 1:numServer
                        fprintf('   Server %d: Free = %.2f, Working = %.2f, Waiting = %.2f, Stuck = %.2f\n', j, ...
                            node.timeInFree(j), node.timeInWorking(j), node.timeInWaiting(j), node.timeInStuck(j));
                    end
        
                else
                    stats.type = 'unknown';
                end
        
                statisticsArray{i} = stats;
            end
        
            fprintf('======================================\n\n');
         end   
    end
end

