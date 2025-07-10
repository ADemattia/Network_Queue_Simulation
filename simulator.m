classdef simulator < handle
    %SIMULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        externalClock
        horizon
        
        queueNodes % array entità: code, generatori, server
        queueArray % array code 
        
        queueGraph % Matrice di adiacenza per descrizione network di code 
        eventsList
         
        endQueue % coda finale accumulo a fine sistema 

        displayFlag % flag per vedere la dinamica 
    end
    
    methods
        function obj = simulator(horizon,queueNodes,queueGraph, displayFlag)
            % istanziazioni di default
            obj.externalClock = 0; 
            numEntities = length(queueNodes); 
            obj.eventsList = inf(numEntities,1);

            obj.horizon = horizon; 
            obj.queueNodes = queueNodes; 
            obj.queueArray = [obj.queueNodes{cellfun(@(x) isa(x, 'queue'), obj.queueNodes)}]; 
            obj.queueGraph = queueGraph;
            obj.displayFlag = displayFlag; 

            waitingFlag = false; 
            obj.endQueue = classicQueue(1, waitingFlag, inf); % coda classica a capacità infinita 
        end

        function networkSetUp(obj)

            networkLength = length(obj.queueNodes); 
            for i = 1: networkLength
                node = obj.queueNodes{i};

                if isa(node, 'generator')
                    % cerca coda a cui è collegato da matrice adiancenza 
                    queueId = find(obj.queueGraph(i, :) == 1); 
                    node.queueAssignment(obj.queueNodes{queueId}, networkLength); 

                elseif isa(node, 'queue')
                    destinationServerId = find(obj.queueGraph(i, :) == 1);
                    node.destinationServerAssignment(obj.queueNodes{destinationServerId}); 

                    % assegnazione server e generatori precedenti queue 
                    previousEntitiesId = find(obj.queueGraph(:, i) == 1);
                    previousGeneratorsId = []; 
                    previousServersId = [];

                    for j = 1:length(previousEntitiesId)
                        entityId = previousEntitiesId(j);
                        entity = obj.queueNodes{entityId};
                        
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
                        node.destinationQueueAssignment(obj.endQueue) % i customer finiscono nella coda di accumulo finale
                    else
                        destinationQueueId = find(obj.queueGraph(i, :) == 1);
                        node.destinationQueueAssignment(obj.queueNodes{destinationQueueId});
                    end 
                end
            end 
        end
        

        function excuteSimulation(obj)
            for i = 1: length(obj.queueNodes)
                node = obj.queueNodes{i};
                if isa(node, 'generator')
                    node.scheduleNextArrival();
                end
            end

            % setup primi eventi 
            for i = 1 : length(obj.queueNodes)
                node = obj.queueNodes{i};
                % code non influenzano contatore, sono solo contenitori
                % eventi sono dettati da generator e server 
                if isa(node, 'queue')
                    % non fare nulla 
                else % server e generator 
                     obj.eventsList(i) = node.clock; 
                end
            end 

            contatore = 0; 
            while obj.externalClock < obj.horizon
                [nextEvent, nextId] = min(obj.eventsList);
                eventNode = obj.queueNodes{nextId};

                if obj.displayFlag == true 

                    fprintf('\n--- Iterazione #%d ---\n', contatore);
                    fprintf('Clock attuale: %.4f\n', obj.externalClock);
                    fprintf('Lista eventi:\n');
                    
                    for idx = 1:length(obj.eventsList)
                        if isinf(obj.eventsList(idx))
                            fprintf('  Nodo %2d: INF\n', idx);
                        else
                            fprintf('  Nodo %2d: %.4f\n', idx, obj.eventsList(idx));
                        end
                    end

                    if isa(eventNode, 'generator')
                        nodeType = 'Generator';
                    elseif isa(eventNode, 'queue')
                        nodeType  = 'Queue';
                    elseif isa(eventNode, 'server')
                        nodeType  = 'Server';
                    end
                    
                    fprintf('Prossimo evento: Nodo %d (%s)\n', nextId, nodeType );
                    fprintf('\n');  
                    
                    contatore = contatore + 1;
                end
                %disp(obj.externalClock); 


                % prossimo evento 
                obj.externalClock = nextEvent; 

                for k = 1:length(obj.queueArray) % aggiorniamo i clock di ogni coda 
                    obj.queueArray(k).clock = obj.externalClock; % clock per coda servono a statistiche non per lista eventi 
                end

                if isa(eventNode, 'generator')
                    gen = eventNode; 

                    queue = gen.queueDestination; 
                    server = queue.destinationServer;

                    gen.customerExit(); % gestisce uscita da generatore e entrata coda 

                    if obj.displayFlag == true
                        obj.displaySystemState
                    end
   
                    [servicePossible, selectedCustomer] = server.checkAvailability(); % verifica se si può schedulare nuovo servizio 
             
                    while servicePossible == 1   % servizio possibile
                        server.scheduleNextEvents(selectedCustomer,obj.externalClock);

                        if obj.displayFlag == true
                            obj.displaySystemState
                        end
 
                        obj.eventsList(server.id) = server.clock; % aggiorna prossimo evento legato a server

                        % verifica se coda può accogliere nuovo customer 
                        updatedQueue = server.selectedQueue; % coda di provenienza del customer
                        obj.propagateExit(updatedQueue);
                        [servicePossible, selectedCustomer] = server.checkAvailability();
                    end

                    gen.scheduleNextArrival();
                    obj.eventsList(gen.id) = gen.clock; % aggiorna prossimo evento legato a server % aggiorna prossimo evento legato a generatore

                else % isa(eventNode,'server')
                    server = eventNode; 
                    server.addWaiting(); % addWaiting deschedula l'evento precedente 

                    if obj.displayFlag == true
                        obj.displaySystemState
                    end

                    obj.eventsList(server.id) = server.clock; % aggiorna prossimo evento legato a server
    
                    if server.canExit() % verifica se si può rilasciare customer in coda
                        server.exitCustomer();
                        obj.eventsList(server.id) = server.clock;

                        if obj.displayFlag == true
                            obj.displaySystemState
                        end


                        while server.canExit() % verifica se si può svuotare ulteriormente la waiting list 
                            server.exitCustomer();
                            obj.eventsList(server.id) = server.clock;

                            if obj.displayFlag == true
                                obj.displaySystemState
                            end

                        end 


                        queue = server.destinationQueue; % coda successiva 

                        % verifica su schedulazione evento server successivo  
                        if ~isequal(queue, obj.endQueue) % se non è la coda finale
                            nextServer = queue.destinationServer; 
                           
                            [nextServicePossible, nextSelectedCustomer] = nextServer.checkAvailability(); % server successivo può prendere nuovo customer

                            if nextServicePossible == 1
                                nextServer.scheduleNextEvents(nextSelectedCustomer,obj.externalClock);

                                if obj.displayFlag == true
                                    obj.displaySystemState
                                end
                                
                                obj.eventsList(nextServer.id) = nextServer.clock; % aggiorna prossimo evento legato a server
                            end 
                        end 
                    end 

                    [servicePossible, selectedCustomer] = server.checkAvailability();  % verifica disponibilità

                    while servicePossible == 1 % servizio possibile
                        server.scheduleNextEvents(selectedCustomer,obj.externalClock);

                        if obj.displayFlag == true
                            obj.displaySystemState
                        end

                        obj.eventsList(server.id) = server.clock; % aggiorna prossimo evento legato a server
                        
                        % verifica se coda può accogliere nuovo customer 
                        updatedQueue = server.selectedQueue; % coda di provenienza del customer
                        obj.propagateExit(updatedQueue); % propagazione 

                        [servicePossible, selectedCustomer] = server.checkAvailability();  % verifica nuova disponibilità
                    end

                    obj.eventsList(server.id) = server.clock; 
                end
            end
        end 

        function propagateExit(obj, queue) % funzione ricorsiva
            previousServers = queue.previousServers; % vettore server precedenti la coda 

            if isempty(queue.previousServers)
                return;
            end

            for i = 1:length(previousServers) % nessuna priorità (solo ordine in grafo) 
                server = previousServers(i); 
                exitAllowed = server.canExit();
                if exitAllowed == true
                    server.exitCustomer(); % inserito customer in coda
                    obj.eventsList(server.id) = server.clock;

                    % COMMENTO: se è possibile prendere in carico un nuovo
                    % customer, si aggiornano ricorsivamente le code
                    % precedenti 

                    [servicePossible, selectedCustomer] = server.checkAvailability(); 

                    while servicePossible == true % servizio possibile

                        server.scheduleNextEvents(selectedCustomer,obj.externalClock); % customer tolto da coda precedente 

                        if obj.displayFlag == true
                            obj.displaySystemState
                        end

                        obj.eventsList(server.id) = server.clock; % aggiorna prossimo evento legato a server 

                        updatedQueue = server.selectedQueue; % coda di provenienza del customer
                        obj.propagateExit(updatedQueue); % ricorsione chiamata quando serve

                        [servicePossible, selectedCustomer] = server.checkAvailability();
                    end
                end
            end
         end

         function displaySystemState(obj)
            fprintf('\n========= SYSTEM STATE =========\n\n');
            
            % stato dei server
            fprintf('--- SERVER STATUS ---\n');
            for i = 1:length(obj.queueNodes)
                node = obj.queueNodes{i};
                if isa(node, 'server')
                    fprintf('Server ID: %d\n', node.id);
                    for j = 1:length(node.serverState)
                        fprintf('\tServitor %d: %s\n', j, string(node.serverState(j)));
                    end
                end
            end
            
            % stato delle code
            fprintf('\n--- QUEUE STATUS ---\n');
            for i = 1:length(obj.queueNodes)
                node = obj.queueNodes{i};
                if isa(node, 'queue')
                    fprintf('Queue ID: %d - Length: %d\n', node.id, node.lengthQueue);
                end
            end
        
            fprintf('\n===============================\n');
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
                    fprintf('Coda ID %d: clienti totali = %d, persi = %d, lunghezza finale = %d\n', ...
                            node.id, node.count, node.lostCustomer, node.lengthQueue);
                        
                elseif isa(node, 'server')
                    stats.type = 'server';
                    stats.count = node.count;
                    stats.revenue = node.revenue;
                    fprintf('Server ID %d: clienti serviti = %d, revenue = %.2f\n', ...
                            node.id, node.count, node.revenue);
        
                else
                    stats.type = 'unknown';
                end
        
                statisticsArray{i} = stats;
            end
        
            fprintf('======================================\n\n');
         end

         function clearSimulator(obj)

            for i = 1:length(obj.queueNodes)
                node = obj.queueNodes{i};
       
                if isa(node, 'server')
                    node.clearServer();
        
                elseif isa(node, 'generator')
                    node.clearGenerator();
        
                elseif isa(node, 'queue') 
                    node.clearQueue();
                end
            end
        
            % pulitura coda finale 
            if ~isempty(obj.endQueue) && ismethod(obj.endQueue, 'clearQueue')
                obj.endQueue.clearQueue();
            end
        
            % azzeramento clock e lista eventi 
            obj.externalClock = 0;
            obj.eventsList(:) = inf;
        
            fprintf('Tutte le statistiche sono state azzerate.\n');
        end

    end
end

