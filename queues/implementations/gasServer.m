classdef gasServer < server
    % gasServer è il server che simula dei server posti in file, dunque il
    % customer non potrà scegliere qualsiasi server ma dovrà rispettare
    % vincoli fisici 

    properties
        serverSeries % cell array con struttura vincoli in forma di array (e.g [1,2] la macchina 2 viene dopo la macchina 1) 
        utilitisServerSeries % variabile ausiliaria per vincoli  
        numType 
        serverPerType % cell array con server adatti per tipo di customer 
        selectedServerId % variabile ausiliaria  

        exitStuckList % lista customer bloccati nel traffico  
    end

    methods
        function obj = gasServer(numServer, serverDistribution, revenueFunction, serverSeries, numType, serverPerType)
            obj@server(numServer, serverDistribution, revenueFunction);

            % proprietà caratteristiche 
            obj.exitStuckList = customer.empty();
            obj.serverSeries = serverSeries; 
            obj.numType = numType; 
            obj.serverPerType = serverPerType;
            obj.selectedServerId = []; 

            % cell array contenente per ogni server la struttura della serie di cui fa parte
            obj.utilitisServerSeries = cell(1, obj.numServer);  
            for j = 1:length(obj.serverSeries)
                currentSeries = obj.serverSeries{j}; 

                % salva la serie per ogni server
                for l = 1:length(currentSeries)  
                    serverId = currentSeries(l);
                    obj.utilitisServerSeries{serverId} = currentSeries; 
                end
            end
        end

        % selectedCustomer può essere servito? 
        function canBeServed = customerCheckAvailability(obj, selectedCustomer, currentQueue) 
            % inizializzazione 
            canBeServed = false; 
            obj.selectedServerId = []; % server selezionato 
            
            % gestione tipo customer 
            customerType = selectedCustomer.type; % tipo customer 
            eligibleServers = obj.serverPerType{customerType}; % server che soddisfano il tipo 
            
            % ricerca server da assegnare rispettando vincoli 
            for j = 1:length(obj.serverSeries)
                selectedSeries = obj.serverSeries{j}; % estrazione di una serie di server 

                firstBusyIndex = []; % posizione vettore del primo server busy (non utilizzabile) nella serie  

                % scorrimento per definire firstBusyIndex
                % solo server precedenti possono essere utilizzati per precedenza
                for l = 1:length(selectedSeries)
                    currentServerId = selectedSeries(l);
                    if (obj.serverState(currentServerId) == serverState.Working || obj.serverState(currentServerId) == serverState.Waiting || obj.serverState(currentServerId) == serverState.StuckInTraffic)
                        firstBusyIndex = l;  
                        break;
                    end
                end

                % vettore di id dei server disponibili 
                availableServerId = [];  

                if ~isempty(firstBusyIndex) && firstBusyIndex > 1 
                    availableServerId = selectedSeries(1:firstBusyIndex - 1); % presi server precedenti 
                elseif isempty(firstBusyIndex) % nessun server è occuppato  
                    availableServerId = selectedSeries;  % presi tutti 
                elseif firstBusyIndex == 1
                    availableServerId = []; % nessun server disponibile nella serie 
                end

                if ~isempty(availableServerId) % se è disponibile almeno un server 
                    for h = length(availableServerId):-1:1  % scorre da ultimo server disponibile a primo - per vincoli 
                        serverId = availableServerId(h);
                        % se il server è adatto al tipo di customer viene assegnato l'id
                        if ismember(serverId, eligibleServers)   
                            obj.selectedServerId = serverId;  
                            break; % usciamo da blocco ricerca 
                        end
                    end
                end

                % se si è trovato qualcosa  
                if ~isempty(obj.selectedServerId)
                    canBeServed = true;
                    obj.selectedQueue = currentQueue;  % salva la coda selezionata
                    return; % esce da funzione 
                end 
            end
        end 

        % è possibile servire un nuovo customer? 
        function [servicePossible, selectedCustomer] = checkAvailability(obj)

            % assegnazione di default 
            servicePossible = false;
            selectedCustomer = customer(); 

            % se almeno un servitore è disponibile
            if obj.notFullyOccupied == true
                for i = 1 : obj.numPreviousQueues  % ordinamento grafo, nessuna priorità 
                    currentQueue = obj.previousQueues(i);
                    if currentQueue.lengthQueue > 0       
                        selectedCustomer = currentQueue.customerList(1); % preso primo customer coda (FIFO) 
                        canBeServed = obj.customerCheckAvailability(selectedCustomer, currentQueue); % controllo locale   
                        if canBeServed == true 
                            servicePossible = true;
                            return; % esce dalla funzione  

                        elseif currentQueue.overtakingFlag == true % è possibile fare sorpassi in coda 
    
                            for c = 2:length(currentQueue.customerList) % guarda customer successivi 
                                selectedCustomer = currentQueue.customerList(c); % preso c-esimo customer 
                                canBeServed = obj.customerCheckAvailability(selectedCustomer, currentQueue); % controllo locale 
                                if canBeServed == true 
                                    servicePossible = true;
                                    return; 
                                end
                            end
                        end                        
                    end
                end
            end
        end

        % schedulazione nuovo evento
        function scheduleNextEvents(obj, customer, externalClock, eventsList)

            % aggiornamento path ed eventi customer
            customer.path(end + 1) = obj.id;
            customer.startTime(obj.id) = externalClock; % memorizza tempo entrata in server

            % gestione uscita customer da coda 
            queueToUpdate = obj.selectedQueue; 
            queueToUpdate.exitMangement(customer, externalClock); % gestione uscita customer da coda precedente 

            % gestione assegnazione server
            serverId = obj.selectedServerId; 
            obj.updateServerTime(serverId, externalClock); %  aggiorna statistiche server
            obj.serverState(serverId) = serverState.Working; % mette il server in work 
            obj.customerToServer(serverId) = customer; % assegna customer a server  

            % pulisce variabile 
            obj.selectedServerId = []; 

            % tempo servizio
            serviceTime = obj.serverDistribution(serverId);  % tempo di servizio 
            obj.clockServer(serverId) = externalClock + serviceTime;
            
            % sono ancora disponibili server liberi?
            if any(obj.serverState == serverState.Free) 
                obj.notFullyOccupied = true;  
            else % tutti i server non liberi 
                obj.notFullyOccupied = false;  
            end

            % aggiorna clock e server evento 
            obj.eventServer = NaN;  % assengazione nulla 
            [obj.clock, obj.eventServer] = min(obj.clockServer); % riassegnazione
            eventsList.update(obj.simulationId, obj.clock); % aggiornamento orologio simulazione 
        end

        % sposta un customer in coda waiting/stucl e aggiorna server
        function addWaiting(obj, externalClock, eventsList) % mette il server in modalità waiting e aggiorna prossimo evento
            
            % ricerca customer e informazione su serie in cui si trova 
            customer = obj.customerToServer(obj.eventServer);
            series = obj.utilitisServerSeries{obj.eventServer}; % serie in cui si trova il server    
            positionInSeries = find(series == obj.eventServer); % posizione server in serie 
            followingServers = series(positionInSeries+1:end); % id server successivi (se è vuoto la condizione dopo viene valutata come true) 
            
            % verifica se server successivi sono liberi  
            if all(obj.serverState(followingServers) == serverState.Free) 
                % tutti liberi, il customer può uscire senza problemi 
                % gestione stato server e inserimento in waiting list 
                obj.exitWaitingList(end+1) = customer;
                obj.clockServer(obj.eventServer) = inf;
                obj.updateServerTime(obj.eventServer,externalClock); % aggiornamento statistiche server 
                obj.serverState(obj.eventServer) = serverState.Waiting; % server in stato waiting 
            
            else % almeno un server successivo è occupato (working, waiting, instuck)

                % gestione stato server e inserimento in stuck list 
                obj.exitStuckList(end+1) = customer; % customer aggiunto a lista dei bloccati nel traffico
                obj.clockServer(obj.eventServer) = inf;
                obj.updateServerTime(obj.eventServer,externalClock); % aggiornamento statistiche server
                obj.serverState(obj.eventServer) = serverState.StuckInTraffic; % server in stato stuck
            end
            
            % sono ancora disponibili server liberi?
            if any(obj.serverState == serverState.Free) 
                obj.notFullyOccupied = true;  
            else % tutti i server non liberi 
                obj.notFullyOccupied = false;  
            end

            % aggiorna clock e server evento 
            obj.eventServer = NaN;  % assengazione nulla 
            [obj.clock, obj.eventServer] = min(obj.clockServer); % riassegnazione 
            eventsList.update(obj.simulationId, obj.clock);  % aggiorna orologio esterno 
        end 

        % fa uscire customer e aggiorna server in modalità free e gestione stuck 
        function exitCustomer(obj, externalClock, eventsList)

            % aggiornamento statistiche
            obj.count = obj.count + 1; 

            % scelto primo customer da fare uscire (randomicamente) 
            randomIndex = randi(length(obj.exitWaitingList));  
            exitCustomer = obj.exitWaitingList(randomIndex);
            obj.exitWaitingList(randomIndex) = []; % customer rimosso da waiting list 

            % aggiornamento eventi del customer 
            exitCustomer.endTime(obj.id) = externalClock;  

            % gestione arrivo in coda destionazione
            arrivalQueue = obj.destinationQueue; % gestione arrivi in prossima coda 
            arrivalQueue.arrivalManagment(exitCustomer, externalClock); % accoglienza nuovo customer

            % server che sta servendo il customer
            [~, serverId] = obj.getServerFromCustomer(exitCustomer);

            % gestione liberazione server
            obj.customerToServer(serverId) = customer();  % impostato customer di default  
            obj.updateServerTime(serverId, externalClock); % aggiornamento statistiche server 
            obj.serverState(serverId) = serverState.Free;  % server ritorna libero

            % liberazione customer stuck, posti in lista waiting
            i = length(obj.exitStuckList);

            while i >= 1 
                % gestione customer 
                stuckCustomer = obj.exitStuckList(i);
                [~, stuckServerId] = obj.getServerFromCustomer(stuckCustomer); 

                % caratterizzazione serie di riferimento 
                stuckSeries = obj.utilitisServerSeries{stuckServerId}; % serie associata al server        
                idInSeries = find(stuckSeries == stuckServerId); % posizione server in serie  
                followingServers = stuckSeries(idInSeries+1:end); % server successivi (se è vuoto la condizione dopo viene valutata come true) 
                
                % se successivi sono ora tutti liberi 
                if all(obj.serverState(followingServers) == serverState.Free)
                    % ora il customer può uscire senza problemi
                    % gestione customer, server e lista
                    obj.exitWaitingList(end+1) = stuckCustomer; % customer aggiunto a lista waiting in uscita 
                    obj.exitStuckList(i) = []; 
                    obj.clockServer(stuckServerId) = inf;
                    obj.updateServerTime(stuckServerId, externalClock); % aggiornamento statistiche server 
                    obj.serverState(stuckServerId) = serverState.Waiting; % server va in stato Waiting 
                else % non ancora libero
                   % non si fa nulla 
                end
                i = i - 1;
            end

            % sono ancora disponibili server liberi?
            if any(obj.serverState == serverState.Free) 
                obj.notFullyOccupied = true;  
            else % tutti i server non liberi 
                obj.notFullyOccupied = false;  
            end

            % aggiorna clock e server evento 
            obj.eventServer = NaN;  % assengazione nulla 
            [obj.clock, obj.eventServer] = min(obj.clockServer); % riassegnazione
            eventsList.update(obj.simulationId, obj.clock);  % aggiornamento orologio esterno 
        end

        % Pulitore statistiche 
        function clear(obj)
            obj.clock = inf; 
            obj.count = 0; 
            obj.notFullyOccupied = 1; 
            obj.customerToServer = repmat(customer(), obj.numServer, 1); 
            obj.serverState = repmat(serverState.Free, obj.numServer, 1);
            obj.clockServer = inf(obj.numServer,1);
            obj.exitWaitingList = customer.empty();
            obj.exitStuckList = customer.empty();
            obj.selectedServerId = []; 
            obj.revenue = 0; 
            obj.timeInFree = zeros(obj.numServer,1); 
            obj.timeInWorking = zeros(obj.numServer,1);
            obj.timeInWaiting = zeros(obj.numServer,1);
            obj.timeInStuck = zeros(obj.numServer,1);
            obj.clockPreviousState = zeros(obj.numServer,1); % inizializzata a 0 
        end 
    end
end

