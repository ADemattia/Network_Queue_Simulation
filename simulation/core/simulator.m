classdef simulator < handle
    % simulatore a eventi discreti per reti di code (generatori, code, server)
    
    properties
        externalClock   % orologio globale della simulazione
        horizon         % tempo di termine della simulazione
        
        agentList % agenti simulazione (cell array) 
        numAgents 
        eventsList % vettore tempo eventi degli agenti - handle list 

        displayFlag % flag di visualizzazione degli eventi  
    end
    
    methods

        function obj = simulator(horizon, agentList, displayFlag)
            % istanziazioni di default
            obj.externalClock = 0; % orologgio settato a zero
            obj.numAgents = length(agentList); 

            % lista eventi inizializzata a inf
            startList = inf(obj.numAgents,1);  
            obj.eventsList = handleList(startList); 

            obj.agentList = agentList; 
            obj.horizon = horizon;  % orizzonete temporale 

            obj.displayFlag = displayFlag;             
        end
        
        function agentSetUp(obj)
            % aggiornati id locali per posizione in simulazione
            for i = 1:length(obj.agentList)
                agent = obj.agentList{i}; 

                agent.simulationId = i; 
            end 
        end 
  
        function excuteSimulation(obj)
            % setup iniziale 

            for i = 1: length(obj.agentList)
                % inizializzazione di ogni agente della simulazione
                agent = obj.agentList{i};
                agent.initialize(); 
                
                % aggiornamento lista eventi 
                listToUpdate = obj.eventsList; 
                listToUpdate.update(i, agent.clock); 

               
            end
      
            while obj.externalClock < obj.horizon
                
                % ricerca prossimo evento 
                currentEventList =  obj.eventsList; 
                [nextEvent, nextId] = currentEventList.minList(); 

                % aggiornamento clock simulazione 
                obj.externalClock = nextEvent;
                eventAgent = obj.agentList{nextId};

                % esecuzione evento 
                eventAgent.execute(obj.externalClock, obj.eventsList, obj.displayFlag);

                % flag per gli update 
                canUpdate = true; 

                % ATTENZIONE: la seguente modalità di update è stata preferita per chiarezza del codice
                % maggiore efficenza è ottenibile tramite update locali e ricorsivi 
                while canUpdate
                    canUpdate = false; 

                    for i = 1:length(obj.agentList)
                        agent = obj.agentList{i};
                        updateFlag = agent.update(obj.externalClock, obj.eventsList, obj.displayFlag);

                        canUpdate = canUpdate || updateFlag; 
                    end 
                end 
            end 
        end 

        % FUNZIONI AUSILIARIE 
        function displayAgentStates(obj)
            fprintf('Clock %.2f — Stato degli agenti:\n', obj.externalClock);
            for i = 1:obj.numAgents
                agent = obj.agentList{i};
                agent.displayAgentState(obj.externalClock);
            end
            fprintf('------------------------------------------------------------\n');
        end

        function clear(obj)
            % resetta le statistiche per ogni agente 
            for i = 1:length(obj.agentList)
                agent = obj.agentList{i}; 
                agent.clear();
            end 
            fprintf('Tutte le statistiche sono state azzerate.\n');
        end 
    end
end

