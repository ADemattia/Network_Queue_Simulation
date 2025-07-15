classdef individual < handle
    % individual è la classe base per la creazione di simulazioni epidemiche 
    
    properties
        id
        simulationId
        clock
        nextEventType % indica il tipo di evento successivo (0 - recovery, 1 - meeting, inf - nessun evento) 

        initialState % stato iniziale 
        infectionState % stato di infezione 
        recoveryDistribution % funzione (anche randomica) per tempo di recupero 
        recoveryClock % tempo di recupero 

        outNeighbourhood % individui con cui ha contatto
        numNeighbours 
        clockNeighbourhoodMeeting % tempo incontro con ogni vicino 
        selectedIndividualId % individuo selezionato per interazione successiva 
        linkActivationDistribution % funzione (anche randomica) per tempo attivazione di un link  
    end
    
    methods
        function obj = individual(infectionState, recoveryDistribution, linkActivationDistribution)
            % inizializzazione di default 
            obj.clock = inf; 
            obj.id = individualIdGenerator.getId();
            obj.recoveryClock = inf; 
            obj.selectedIndividualId = []; 
            obj.nextEventType = inf; 

            % inizializzazioni caratteristiche 
            obj.initialState = infectionState; 
            obj.infectionState = infectionState; 
            obj.recoveryDistribution = recoveryDistribution; 
            obj.linkActivationDistribution = linkActivationDistribution;  
        end

        % caratterizzazione Network locale 
        function neighbourhoodAssignment(obj, outNeighbourhood)

            obj.outNeighbourhood = outNeighbourhood; 
            obj.numNeighbours = length(obj.outNeighbourhood);
            obj.clockNeighbourhoodMeeting = inf(obj.numNeighbours, 1);  
        end

        function initialize(obj)

            % schedula prossimi incontri lungo i nodi
            if obj.infectionState == individualState.Susceptible

                for i = 1: obj.numNeighbours
                    nextMeeting = obj.linkActivationDistribution(i); 
                    obj.clockNeighbourhoodMeeting(i) = nextMeeting; 
                end

                [obj.clock, obj.selectedIndividualId] = min(obj.clockNeighbourhoodMeeting);
                obj.nextEventType = 1;

             % se individuo è infetto schedula tempo di recovery
            elseif obj.infectionState == individualState.Infectious

                obj.recoveryClock = obj.recoveryDistribution();
                obj.clock = obj.recoveryClock; % clock aggiornato con tempo guarigione 
                obj.nextEventType = 0;

            elseif obj.infectionState == individualState.Recovered

                obj.nextEventType = inf; % nessun evento
                obj.clock = inf; 
            end 
        end 

        function execute(obj, externalClock, eventsList, displayFlag)

            % cambia stato infezione e schedula possibile nuovo incontro 
            obj.changeState(externalClock, eventsList, displayFlag); 

        end 

        % non viene fatto nessun aggiornamento a seguito di altri eventi
        function updateFlag = update(obj, externalClock, eventsList, displayFlag)
            updateFlag = false; 
        end 

        function changeState(obj, externalClock, eventsList, displayFlag)

            if obj.nextEventType == 0 % evento recovery 

                % passaggio di stato a recovered
                obj.infectionState = individualState.Recovered;

                % aggiornamento stato eventi 
                obj.nextEventType = inf; 
                obj.recoveryClock = inf; % orlogio recovery ad inf
                obj.clock = inf; % non ci sono più eventi 

                if displayFlag
                    fprintf('Clock %.2f: Individuo %d → Recovered\n', externalClock, obj.simulationId);
                    fprintf('------------------------------------------------------------\n');
                end

            elseif obj.nextEventType == 1 % prossimo evento è incontro

                % stato individuo incontrato
                selectedIndividual = obj.outNeighbourhood(obj.selectedIndividualId); 
                meetingInfectionState = selectedIndividual.infectionState; 

                if displayFlag
                    fprintf('Clock %.2f: Individuo %d incontra Individuo %d (stato: %s)\n', ...
                            externalClock, obj.simulationId, selectedIndividual.simulationId, char(meetingInfectionState));
                    
                end

                % dinamica infezione (non bilaterale)  
                if obj.infectionState == individualState.Susceptible &&  meetingInfectionState == individualState.Infectious

                    % individuo infettato 
                    obj.infectionState = individualState.Infectious;

                    % spegnimento meeting in caso SIR (politiche diverse per modelli diversi) 
                    for i = 1: obj.numNeighbours
                        obj.clockNeighbourhoodMeeting(i) = inf;
                    end 

                    % schedulato recovery 
                    obj.recoveryClock = externalClock + obj.recoveryDistribution();
                    obj.nextEventType = 0;

                    obj.clock = obj.recoveryClock; % aggiornato prossimo evento 


                    if displayFlag
                        fprintf(' → Individuo %d diventa Infectious\n', obj.id);
                        fprintf('------------------------------------------------------------\n');
                    end

                elseif meetingInfectionState == individualState.Recovered

                    obj.clockNeighbourhoodMeeting(obj.selectedIndividualId) = inf;
                    obj.nextEventType = 1;

                    [obj.clock, obj.selectedIndividualId] = min(obj.clockNeighbourhoodMeeting);

                    if displayFlag
                        fprintf(' → Individuo %d rimane Susceptible\n', obj.id);
                        fprintf('------------------------------------------------------------\n');
                    end

                else % se nessuna infezione - schedulato prossimo meeting 

                    obj.clockNeighbourhoodMeeting(obj.selectedIndividualId) = externalClock + obj.linkActivationDistribution(obj.selectedIndividualId);
                    obj.nextEventType = 1;

                    [obj.clock, obj.selectedIndividualId] = min(obj.clockNeighbourhoodMeeting);


                    if displayFlag
                        fprintf(' → Individuo %d rimane Susceptible\n', obj.id);
                        fprintf('------------------------------------------------------------\n');
                    end
                end       
            end

            eventsList.update(obj.simulationId, obj.clock);
        end 

        function displayAgentState(obj, externalClock)
           fprintf('Individuo %d - Stato infezione: %s\n', obj.simulationId, char(obj.infectionState));
       end

       function clear(obj)
                obj.clock = inf;
                obj.recoveryClock = inf; 
                obj.infectionState = obj.initialState;
                obj.clockNeighbourhoodMeeting = inf(obj.numNeighbours, 1);
                obj.selectedIndividualId = []; 
       end
    end
end

