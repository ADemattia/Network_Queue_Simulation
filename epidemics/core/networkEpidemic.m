classdef networkEpidemic < handle
    % la classe networkEpidemic permette di gestire in modo semplice la
    % simulazione SIR: 
    % 1. crea gli individui 
    % 2. gestisce network 
    
    properties
        individualGraph % grafo di contatto individui (matrice adiacenza)  
        numIndividual 
        infectiousIndividual % lista individui infetti (posizione) 
        recoveredIndividual % lista individui recovery (posizione)

        individualCellArray % lista individui 
    end
    
    methods
        function obj = networkEpidemic(individualGraph, numIndividual, infectiousIndividual, recoveredIndividual)

            obj.individualGraph = individualGraph; 
            obj.numIndividual = numIndividual; 
            obj.infectiousIndividual = infectiousIndividual; 
            obj.recoveredIndividual = recoveredIndividual; 

        end
        

        function individualCellArray = scenarioSetUp(obj, recoveryDistributionArray, linkActivationDistributionArray)
            % recoveryDistributionArray: cell array di funzioni (anche randomiche)  tempi recupero
            % linkActivationDistributionArray : cell array di funzioni (anche randomiche) tempo di attivazione link 
            individualCellArray = cell(1, obj.numIndividual);

            for i = 1:obj.numIndividual
                currentRecoveryDistribution = recoveryDistributionArray{i};
                currentLinkActivationDistribution = linkActivationDistributionArray{i}; 

                if ismember(i, obj.infectiousIndividual) % individuo i deve essere infetto
                    currentIndividual = individual(individualState.Infectious, currentRecoveryDistribution, currentLinkActivationDistribution); 

                elseif ismember(i, obj.recoveredIndividual) 

                    currentIndividual = individual(individualState.Recovered, currentRecoveryDistribution, currentLinkActivationDistribution); 

                else % altrimenti è suscettibile  

                    currentIndividual = individual(individualState.Susceptible, currentRecoveryDistribution, currentLinkActivationDistribution); 

                end 

                individualCellArray{i} = currentIndividual; 

            end 

            obj.individualCellArray = individualCellArray; 

        end

        function networkSetUp(obj)
            for i = 1:obj.numIndividual
                adjacentIndividuals = find(obj.individualGraph(i, :) == 1);
                outNeighbourhood = [obj.individualCellArray{adjacentIndividuals}]; % selezione individui adiacenti 
                individual = obj.individualCellArray{i}; 
                individual.neighbourhoodAssignment(outNeighbourhood); 
            end 

        end 
    end 
end

