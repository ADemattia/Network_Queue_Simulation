classdef gasServer < server
    %GASSERVER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        serverSeries % cell array rappresentante vincoli di sequenzialità - assumiamo struttura parallela
        utilitisServerSeries % variabile ausiliaria utile nelle funzioni 
        numType % numero tipi customer 
        serverPerType % cell array con server eleggibili per tipo
        selectedServerId % variabile ausiliaria 

        exitStuckList % lista customer a servizio finito bloccati nel traffico 
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


            obj.utilitisServerSeries = cell(1, obj.numServer); % cell array contenente per ogni server la serie di cui fa parte 
            for j = 1:length(obj.serverSeries)
                currentSeries = obj.serverSeries{j}; 

                for l = 1:length(currentSeries) % salva la serie per ogni server 
                    serverId = currentSeries(l);
                    obj.utilitisServerSeries{serverId} = currentSeries; 
                end
            end
        end

        function canBeServed = customerCheckAvailability(obj, selectedCustomer, currentQueue) % funzione di controllo livello customer 

            canBeServed = false; 
            
            customerType = selectedCustomer.type; % tipo customer 
            eligibleServers = obj.serverPerType{customerType}; % server che soddisfano il tipo 

            obj.selectedServerId = [];  % valore di default del server assegnato 
            
            % ricerca server da assegnare rispettando vincoli 
            for j = 1:length(obj.serverSeries)
                selectedSeries = obj.serverSeries{j}; % array ordinato di indici

                firstBusyIndex = []; % posizione vettore del primo server busy (non utilizzabile) 

                % scorrimento per cercare server disponibili in una serie
                for l = 1:length(selectedSeries)
                    currentServerId = selectedSeries(l);
                    if (obj.serverState(currentServerId) == serverState.Working || obj.serverState(currentServerId) == serverState.Waiting || obj.serverState(currentServerId) == serverState.StuckInTraffic)
                        firstBusyIndex = l;  % solo server precedenti possono essere utilizzati per precedenza
                        break;
                    end
                end

                 
                availableServerId = []; % vettore id server disponibili 

                if ~isempty(firstBusyIndex) && firstBusyIndex > 1
                    availableServerId = selectedSeries(1:firstBusyIndex - 1);
                elseif isempty(firstBusyIndex) % nessun server è occuppato  
                    availableServerId = selectedSeries;  % presi tutti 
                elseif firstBusyIndex == 1
                    availableServerId = [];
                end

                if ~isempty(availableServerId)
                    for h = length(availableServerId):-1:1  % scorre da ultimo server disponibile a primo
                        serverId = availableServerId(h);
                        if ismember(serverId, eligibleServers) % il server è adatto al tipo di customer  
                            obj.selectedServerId = serverId;  % trovato l'id del server più lontano adatto
                            break; % usciamo da blocco ricerca 
                        end
                    end
                end

            % se ha trovato un server si può servire 
                if ~isempty(obj.selectedServerId)
                    canBeServed = true;
                    obj.selectedQueue = currentQueue;  % salva la coda selezionata
                    return; % esce da funzione 
                end 
            end
        end 

        function [servicePossible, selectedCustomer] = checkAvailability(obj)
            % assegnazione di default 
            servicePossible = 0;
            selectedCustomer = customer(); 

            % se almeno un servitore è disponibile
            if obj.notFullyOccupied == true

                for i = 1 : obj.numPreviousQueues  % ordinamento grafo, nessuna prioritarità
                    currentQueue = obj.previousQueues(i);

                    if currentQueue.lengthQueue > 0
              
                        selectedCustomer = currentQueue.customerList(1); % preso primo customer coda (FIFO) 
                        canBeServed = obj.customerCheckAvailability(selectedCustomer, currentQueue); % assegna eventualmente anche il server di lavorazione  
                        if canBeServed == true 
                            servicePossible = true;
                            return; % esce dalla funzione  
                        elseif currentQueue.overtakingFlag == true % è possibile fare sorpassi in coda 
    
                            for c = 2:length(currentQueue.customerList)
                                selectedCustomer = currentQueue.customerList(c); % preso c-esimo customer 
                                canBeServed = obj.customerCheckAvailability(selectedCustomer, currentQueue); 
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

        function scheduleNextEvents(obj, customer, externalClock)

            customer.path(end + 1) = obj.id;
            customer.startTime(obj.id) = externalClock; % memorizza tempo entrata in server

            % eliminazione customer da coda 
            queueToUpdate = obj.selectedQueue; 
            queueToUpdate.exitMangement(customer); % gestione uscita customer da coda precedente 

            
            serverId = obj.selectedServerId; % trovato durante checkAvailability 
            obj.serverState(serverId) = serverState.Working; % mette in stato occupato il server
            obj.customerToServer(serverId) = customer; % che customer serve un server  

            obj.selectedServerId = []; 

            serviceTime = obj.serverDistribution(serverId);  % tempo di servizio 
            obj.clockServer(serverId) = externalClock + serviceTime;

            
            [obj.clock, obj.eventServer] = min(obj.clockServer); % aggiornamento nuovo evento e indice nuovo evento

            
            if any(obj.serverState == serverState.Free) % aggiornamento stato disponibilità
                obj.notFullyOccupied = true;  % se almeno uno è libero, il server è disponibile
            else
                obj.notFullyOccupied = false;  % tutti i server non liberi
            end
        end

        function addWaiting(obj) % mette il server in modalità waiting e aggiorna prossimo evento
            

            customer = obj.customerToServer(obj.eventServer); % customer a fine servizio

            series = obj.utilitisServerSeries{obj.eventServer}; % serie in cui si trova il server    
            positionInSeries = find(series == obj.eventServer); % posizione server in serie 
            followingServers = series(positionInSeries+1:end); % id server successivi (se è vuoto la condizione dopo viene valutata come true) 
            
            % verifica se server successii sono liberi 
            if all(obj.serverState(followingServers) == serverState.Free)
                % tutti liberi, il customer può uscire senza problemi
                obj.exitWaitingList(end+1) = customer; % customer aggiunto a lista waiting in uscita 
                obj.clockServer(obj.eventServer) = inf;
                obj.serverState(obj.eventServer) = serverState.Waiting; % server associato in stato Waiting 
            else % almeno un server successivo è occupato (working, waiting, instuck) 
                obj.exitStuckList(end+1) = customer; % customer aggiunto a lista dei bloccati nel traffico
                obj.clockServer(obj.eventServer) = inf;
                obj.serverState(obj.eventServer) = serverState.StuckInTraffic; % server associato in stato StuckInTraffic
            end
            
            % schedula evento successivo 
            obj.eventServer = NaN;  % l'assegnazione server prossimo evento ritorna nulla 
            [obj.clock, obj.eventServer] = min(obj.clockServer); % riassegnazione clock
        end 

        function exitCustomer(obj, externalClock)

            obj.count = obj.count + 1; % aggiornamento customer serviti
            randomIndex = randi(length(obj.exitWaitingList));  % scegliamo customer in uscita casualmente 
            exitCustomer = obj.exitWaitingList(randomIndex);
            obj.exitWaitingList(randomIndex) = []; % rimuoviamo customer da waiting list

            exitCustomer.endTime(obj.id) = externalClock; % memorizza tempo uscita da coda 

            arrivalQueue = obj.destinationQueue; % gestione arrivi in prossima coda 
            arrivalQueue.arrivalManagment(exitCustomer); % accoglienza nuovo customer

            [~, serverId] = obj.getServerFromCustomer(exitCustomer);

            obj.customerToServer(serverId) = customer();  % impostato customer di default     
            obj.serverState(serverId) = serverState.Free;  % server ritorna libero


            i = length(obj.exitStuckList);

            while i >= 1 
                stuckCustomer = obj.exitStuckList(i);
            
                [found, stuckServerId] = obj.getServerFromCustomer(stuckCustomer); % server associato al customer

                if found == false
                    disp("There is something Wrong!!")
                    i = i - 1;
                    continue;  % Salta all'iterazione successiva
                end

            
                stuckSeries = obj.utilitisServerSeries{stuckServerId}; % serie associata al server        
                idInSeries = find(stuckSeries == stuckServerId); % posizione server in serie  
                followingServers = stuckSeries(idInSeries+1:end); % server successivi (se è vuoto la condizione dopo viene valutata come true) 
                
                % se successivi sono ora tutti liberi 
                if all(obj.serverState(followingServers) == serverState.Free)
                    % ora  il customer può uscire senza problemi
                    obj.exitWaitingList(end+1) = stuckCustomer; % customer aggiunto a lista waiting in uscita 
                    obj.exitStuckList(i) = []; 
                    obj.clockServer(stuckServerId) = inf;
                    obj.serverState(stuckServerId) = serverState.Waiting; % server va in stato Waiting 
                else % non ancora libero
                   
                end

                i = i - 1;
            end

            if any(obj.serverState == serverState.Free) % aggiornamento stato disponibilità
                obj.notFullyOccupied = true;  % se almeno uno è libero, il server è disponibile
            else
                obj.notFullyOccupied = false;  % tutti i server non liberi
            end

            obj.eventServer = NaN;  % l'assegnazione server prossimo evento ritorna nulla 
            [obj.clock, obj.eventServer] = min(obj.clockServer); % riassegnazione clock
        end

        % Pulitore statistiche 
        function clearServer(obj)
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
        end 
    end
end

