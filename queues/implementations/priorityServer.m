classdef priorityServer < server
    % priorityServer per modellare un server con capacità di servizio
    % finita (e.g. vendita biglietti aerei), inserendo anche un vettore di
    % priorità (caso con categorie finite di customer) 

    properties       
        capacity % capacità di servizio
        numType % numero tipi di customer
        priorityArray  % vettore di priorità per tipo
        countPerType % conteggio per tipo di customer 
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
        

        % è possibile servire un nuovo customer? 
        function [servicePossible, selectedCustomer] = checkAvailability(obj)
            % assegnazione di default 
            servicePossible = 0;
            selectedCustomer = customer(); 

            % se almeno un servitore è disponibile
            if obj.notFullyOccupied == 1
                for i = 1 : obj.numPreviousQueues  % ordinamento grafo, nessuna priorità
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

        % schedulazione nuovo evento
        function scheduleNextEvents(obj, customer, externalClock, eventsList)
            
            % aggiornamento path ed eventi customer 
            customer.path(end + 1) = obj.id;
            customer.startTime(obj.id) = externalClock;  

            % gestione uscita customer da coda 
            queueToUpdate = obj.selectedQueue; 
            queueToUpdate.exitMangement(customer, externalClock);


            customerType = customer.type; 
 
            % gestione assegnazione server 
            serverId = find(obj.serverState == serverState.Free, 1); 
            obj.updateServerTime(serverId,externalClock); % aggiorna statistiche server 
            obj.serverState(serverId) = serverState.Working; % mette il server in work 
            obj.customerToServer(serverId) = customer; % assegna customer a server 
           

            % check disponibilità 
            if obj.countPerType(customerType) < obj.priorityArray(customerType) && obj.capacity > 0

                serviceTime = obj.serverDistribution(serverId); % tempo servizio differenziato su server (serverId)  

                % aggiornamento statistiche 
                obj.countPerType(customerType) = obj.countPerType(customerType) + 1; 
                obj.capacity = obj.capacity - 1; % capacità residua  

                % aggiornamento revenue 
                customerRevenue = obj.revenueFunction(customer.type); % campionamento revenue su tipo 
                obj.revenue = obj.revenue + customerRevenue; 
            else
                serviceTime = 0;  % customer immediatamente cacciato 
            end

            % aggiornamento tempo 
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

        % sposta un customer in coda waiting e aggiorna server in modalità waiting
        function addWaiting(obj, externalClock, eventsList)

            % ricerca customer e spostamento in waiting list 
            customer = obj.customerToServer(obj.eventServer); 
            obj.exitWaitingList(end+1) = customer; 

            % gestione stato server
            obj.clockServer(obj.eventServer) = inf;     % tempo server riportato a inf
            obj.updateServerTime(obj.eventServer,externalClock); % aggiorna statistiche server 
            obj.serverState(obj.eventServer) = serverState.Waiting;       % server in wait

            % aggiorna clock e server evento 
            obj.eventServer = NaN;  % assengazione nulla 
            [obj.clock, obj.eventServer] = min(obj.clockServer); % riassegnazione 
            eventsList.update(obj.simulationId, obj.clock);  % aggiorna orologio esterno 
        end 

        function exitCustomer(obj, externalClock, eventsList)
            % aggiornamento statistiche e variabili 
            obj.count = obj.count + 1; 
            exitCustomer = obj.exitWaitingList(1); % nessuna priorità
            obj.exitWaitingList(1) = [];  

            % aggiornamento eventi del customer 
            exitCustomer.endTime(obj.id) = externalClock; 

            % server che sta servendo customer 
            [~, serverId] = obj.getServerFromCustomer(exitCustomer);

            % gestione arrivo in coda destionazione 
            arrivalQueue = obj.destinationQueue; 
            arrivalQueue.arrivalManagment(exitCustomer, externalClock);


            % gestione liberazione server     
            obj.customerToServer(serverId) = customer();  % impostato customer di default
            obj.updateServerTime(serverId,externalClock);
            obj.serverState(serverId) = serverState.Free;  % server ritorna libero

            % sono ancora disponibili server liberi?
            if any(obj.serverState == serverState.Free) 
                obj.notFullyOccupied = true;  
            else % tutti i server non liberi 
                obj.notFullyOccupied = false;  
            end

            % aggiorna clock e server evento 
            obj.eventServer = NaN;  % assengazione nulla 
            [obj.clock, obj.eventServer] = min(obj.clockServer); % riassegnazione
            eventsList.update(obj.simulationId, obj.clock); % aggiorna orologio esterno 
        end

        % Pulitore statistiche 
        function clear(obj)
            obj.clock = inf; 
            obj.count = 0; 
            obj.notFullyOccupied = 1; 
            obj.customerToServer = repmat(customer(), obj.numServer, 1);
            obj.serverState = repmat(serverState.Free, obj.numServer, 1);
            obj.exitWaitingList = customer.empty();
            obj.clockServer = inf(obj.numServer,1);
            obj.countPerType = zeros(obj.numType,1);
            obj.revenue = 0;
            obj.timeInFree = zeros(obj.numServer,1); 
            obj.timeInWorking = zeros(obj.numServer,1);
            obj.timeInWaiting = zeros(obj.numServer,1);
            obj.timeInStuck = zeros(obj.numServer,1);
            obj.clockPreviousState = zeros(obj.numServer,1); % inizializzata a 0 
        end 
    end
end

