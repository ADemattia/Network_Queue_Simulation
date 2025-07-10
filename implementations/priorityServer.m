classdef priorityServer < server
    % priorityServer per modellare un server con capacità di servizio
    % finita (e.g. vendita biglietti aerei), inserendo anche un vettore di
    % priorità (caso con categorie finite di customer) 

    properties       
        capacity % capacità totale 
        numType % numero tipi di customer
        priorityArray  % vettore di priorità
        countPerType % conteggio per tipo 
    end
    
    methods
        function  obj = priorityServer(numServer, serverDistribution, revenueFunction, capacity, numType, priorityArray)
            obj@server(numServer, serverDistribution, revenueFunction); 

            % proprietà caratteristiche 
            obj.capacity = capacity; 
            obj.numType = numType; 

            obj.priorityArray = priorityArray; % array posti disponibili
            obj.countPerType = zeros(numType,1); 
        end
        

        % istanziazione funzioni astratte 

        function [servicePossible, selectedCustomer] = checkAvailability(obj)
            % assegnazione di default 
            servicePossible = 0;
            selectedCustomer = customer(); 

            % se almeno un servitore è disponibile
            if obj.notFullyOccupied == 1
                for i = 1 : obj.numPreviousQueues  % ordinamento grafo, nessuna prioritarità
                    currentQueue = obj.previousQueues(i);
                    if currentQueue.lengthQueue > 0
                        servicePossible = 1; 
                        selectedCustomer = currentQueue.customerList(1); % politica FIFO 
                        obj.selectedQueue = currentQueue; % salva coda selezionata per servizio 
                        return;
                    end
                end
            end 
        end

        function scheduleNextEvents(obj, customer, externalClock)
            
            customer.path(end + 1) = obj.id;
            customer.startTime(obj.id) = externalClock; % memorizza entrata in coda 

            % eliminazione customer da coda 
            queueToUpdate = obj.selectedQueue; 
            queueToUpdate.exitMangement(customer);


            customerType = customer.type; 
 
            serverId = find(obj.serverState == serverState.Free, 1); % trova primo server libero 
            obj.serverState(serverId) = serverState.Working; % mette in stato occupato il server
            obj.customerToServer(serverId) = customer; % customer servito dal server scelto
           

            % check disponibilità 
            if obj.countPerType(customerType) < obj.priorityArray(customerType) && obj.capacity > 0 
                serviceTime = obj.serverDistribution(serverId); % tempo servizio - si differenzia su server (serverId)  

                obj.countPerType(customerType) = obj.countPerType(customerType) + 1; 
                obj.capacity = obj.capacity - 1; % aggiornamento capacità 

                customerRevenue = obj.revenueFunction(customer.type); % calcolo revenue sulla base del tipo di customer
                obj.revenue = obj.revenue + customerRevenue; 
            else
                serviceTime = 0;  % se non sono più disponibili posti
            end

            obj.clockServer(serverId) = externalClock + serviceTime;

            [obj.clock, obj.eventServer] = min(obj.clockServer); % aggiornamento nuovo evento e indice nuovo evento
 
            if any(obj.serverState == serverState.Free) % aggiornamento stato disponibilità
                obj.notFullyOccupied = true;  % se almeno uno è libero, il server è disponibile
            else
                obj.notFullyOccupied = false;  % tutti i server non liberi
            end
        end

        function addWaiting(obj)
            customer = obj.customerToServer(obj.eventServer); % customer a fine servizio
            obj.exitWaitingList(end+1) = customer; % customer aggiunto a lista di uscita

            obj.clockServer(obj.eventServer) = inf;     % tempo server riportato a inf
            obj.serverState(obj.eventServer) = serverState.Waiting;       % server in wait

            % schedula evento successivo 
            obj.eventServer = NaN;  % l'assegnazione server prossimo evento ritorna nulla 
            [obj.clock, obj.eventServer] = min(obj.clockServer); % riassegnazione clock
        end 

        function exitCustomer(obj, externalClock)
            obj.count = obj.count + 1; % aggiornamento customer serviti
            exitCustomer = obj.exitWaitingList(1); % primo customer in uscita
            obj.exitWaitingList(1) = []; % eliminazione da lista waiting 

            exitCustomer.endTime(obj.id) = externalClock; % memorizza tempo uscita 

            [~, serverId] = obj.getServerFromCustomer(exitCustomer);

            arrivalQueue = obj.destinationQueue; 
            arrivalQueue.arrivalManagment(exitCustomer); 

            obj.customerToServer(serverId) = customer();  % impostato customer di default     
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
            obj.countPerType = zeros(obj.numType,1);
            obj.revenue = 0; 
        end 
    end
end

