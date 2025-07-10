classdef resourceProducer < server
% Classe ispirata a rollQueue
% I server producono risorse in ordine, senza priorità.
% I customer arrivano e richiedono una quantità di un prodotto:
%   - se disponibile, vengono serviti subito (senza uso di server);
%   - altrimenti, prendono quanto c’è e attendono la produzione del resto.
    
    properties
        % numero prodotti presenti
        numProducts
        % capacità di storage per ogni prodotto
        storageCapacity
        % prodotti disponibili 
        productsAvailable
        % funzione (anche randomica) di produzione per ogni tipo di
        % prodotto 
        timeProduction

        % prodotto richiesto da customer
        requestDistribution

        % quantità richiesta
        quantityDistribution

        % indicatore di presenza customer in attesa
        % 0 - può entrare customer // 1 - customer non può entrare 
        busy
    end
    
    methods
        function  obj = resourceProducer(numServer, serverDistribution, revenueFunction, numProducts, storageCapacity, timeProduction, requestDistribution, quantityDistribution)
            obj@server(numServer, serverDistribution, revenueFunction);

            % inizializzazione delle proprietà specifiche di `resourceProducer`
            obj.numProducts = numProducts;
            obj.storageCapacity = storageCapacity;
            obj.timeProduction = timeProduction;
            obj.requestDistribution = requestDistribution;
            obj.quantityDistribution = quantityDistribution;
            obj.busy = 0; 

            % prodotti disponibili 
            obj.productsAvailable = zeros(numProducts, 1); % es. array per tenere traccia dei prodotti disponibili  
        end
        
        function [servicePossible, selectedCustomer] = checkAvailability(obj)
            % assegnazione di default 
            servicePossible = 0;
            selectedCustomer = customer(); 

            % se almeno un servitore è disponibile
            if obj.busy == 0
                for i = 1 : obj.numPreviousQueues  % ordinamento grafo, nessuna prioritarità
                    currentQueue = obj.previousQueues(i);
                    if currentQueue.lengthQueue > 0
                        servicePossible = 1; 
                        selectedCustomer = currentQueue.customerList(1);
                        obj.selectedQueue = currentQueue; % salva coda selezionata per servizio
                        obj.busy = 1; 
                        return;
                    end
                end
            end 
        end

        function scheduleNextEvents(obj, customer, externalClock)
            % eliminazione customer da coda 
            obj.selectedQueue.exitMangement(customer); 

           
           obj.

            obj.clockServer(serverId) = externalClock + serviceTime;
            % che server sta servendo il customer 
            obj.customerArray(serverId) = customer;
            % aggiornati clock e assignedServer indicando il nuovo primo
            % evento riguardante il server
            [obj.clock, obj.assignedServer] = min(obj.clockServer);
 
            % se tutti occupati
            if all(obj.serverState == 1)
                % non ci sono più disponibilità 
                obj.notFullyOccupied = 0;
            end 
        end
    end
end

