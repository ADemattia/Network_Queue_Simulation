classdef classicServer < server
    % classicServer è la classe che modella il server classico con s
    % servitori (finiti), che lavorano in parallelo. I servitori possono
    % essere differenziati nei tempi di lavorazione tramite
    % serverDistribution 
    
    methods
        function  obj = classicServer(numServer, serverDistribution, revenueFunction)
            obj@server(numServer, serverDistribution, revenueFunction); 
        end
        
        function [servicePossible, selectedCustomer] = checkAvailability(obj) % viene scelto il customer da servire 
            % assegnazione di default 
            servicePossible = 0;
            selectedCustomer = customer(); 

            % se almeno un servitore è disponibile
            if obj.notFullyOccupied == true
                for i = 1 : obj.numPreviousQueues  % ordinamento grafo, nessuna prioritarità
                    currentQueue = obj.previousQueues(i);
                    if currentQueue.lengthQueue > 0
                        servicePossible = 1; 
                        selectedCustomer = currentQueue.customerList(1);
                        obj.selectedQueue = currentQueue; % salva coda selezionata per servizio 
                        return;
                    end
                end
            end
        end

        function scheduleNextEvents(obj, customer, externalClock)
            customer.path(end + 1) = obj.id;
            
            customer.startTime(obj.id) = externalClock; %  aggiorniamo tempo ingresso in coda 

            % eliminazione customer da coda 
            queueToUpdate = obj.selectedQueue; 
            queueToUpdate.exitMangement(customer); % gestione uscita coda precedente

            serverId = find(obj.serverState == serverState.Free, 1); % trova primo server libero 
            obj.updateServerTime(serverId,externalClock); % aggiorna statistiche di tempo 
            obj.serverState(serverId) = serverState.Working; % mette in stato occupato il server
            obj.customerToServer(serverId) = customer; % customer servito dal server scelto 

            
            serviceTime = obj.serverDistribution(1);  % tempo di servizio 
            obj.clockServer(serverId) = externalClock + serviceTime; 

            
            [obj.clock, obj.eventServer] = min(obj.clockServer); % aggiornamento nuovo evento e indice nuovo evento
 
            
            if any(obj.serverState == serverState.Free) % aggiornamento stato disponibilità
                obj.notFullyOccupied = true;  % se almeno uno è libero, il server è disponibile
            else
                obj.notFullyOccupied = false;  % tutti i server non liberi
            end
        end

        function addWaiting(obj, externalClock) % mette il server in modalità waiting e aggiorna prossimo evento 

            customer = obj.customerToServer(obj.eventServer); % customer a fine servizio
            obj.exitWaitingList(end+1) = customer; % customer aggiunto a lista di uscita

            obj.clockServer(obj.eventServer) = inf;     % tempo server riportato a inf
            obj.updateServerTime(obj.eventServer, externalClock);
            obj.serverState(obj.eventServer) = serverState.Waiting;       % server in wait

            % schedula evento successivo 
            obj.eventServer = NaN;  % l'assegnazione server prossimo evento ritorna nulla 
            [obj.clock, obj.eventServer] = min(obj.clockServer); % riassegnazione clock
        end 

        function exitCustomer(obj, externalClock)
            obj.count = obj.count + 1; % aggiornamento customer serviti
            exitCustomer = obj.exitWaitingList(1); % primo customer in uscita
            obj.exitWaitingList(1) = []; % eliminazione da lista waiting 

            exitCustomer.endTime(obj.id) = externalClock; % memorizza tempo uscita da server   

            [~, serverId] = obj.getServerFromCustomer(exitCustomer); 

            arrivalQueue = obj.destinationQueue; % gestione arrivi in prossima coda 
            arrivalQueue.arrivalManagment(exitCustomer); % accoglienza nuovo customer 

            obj.customerToServer(serverId) = customer();  % impostato customer di default
            obj.updateServerTime(serverId, externalClock);
            obj.serverState(serverId) = serverState.Free;  % server ritorna libero

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
            obj.exitWaitingList = customer.empty();
            obj.clockServer = inf(obj.numServer,1);
            obj.revenue = 0;
            obj.timeInFree = zeros(obj.numServer,1); 
            obj.timeInWorking = zeros(obj.numServer,1);
            obj.timeInWaiting = zeros(obj.numServer,1);
            obj.timeInStuck = zeros(obj.numServer,1);
            obj.clockPreviousState = zeros(obj.numServer,1); % inizializzata a 0 
        end 

    end
end

