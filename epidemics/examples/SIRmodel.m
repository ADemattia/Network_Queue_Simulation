%% MODELLO EPIDEMICO SIR 
clear all
clc

addpath(genpath('simulation'))
addpath('epidemics/core')
addpath('epidemics/utils')

rng(10); 

rateRecov = 1;
rateLink = 2;
numIndividuals = 5;

% preallocazione array di funzioni anonime
recoveryDistributionArray = cell(1, numIndividuals);
linkActivationDistributionArray = cell(1, numIndividuals);

for i = 1:numIndividuals
    pdRecov = makedist('Exponential', 'mu', 1/rateRecov);
    recoveryDistributionArray(i) = {@() random(pdRecov)};  % usa cell array dentro array

    pdLink = makedist('Exponential', 'mu', 1/rateLink);
    linkActivationDistributionArray(i) = {@(neighborIdx) random(pdLink)};
end

infectiousIndividuals = [1];
recoveredIndividuals = [];

individualGraph = [0 1 0 0 1;
                   1 0 1 0 0;
                   0 1 0 1 0;
                   0 0 1 0 1;
                   1 0 0 1 0];

network = networkEpidemic(individualGraph, numIndividuals, infectiousIndividuals, recoveredIndividuals); 
individualCellArray = network.scenarioSetUp(recoveryDistributionArray, linkActivationDistributionArray); 
network.networkSetUp();

horizon = 10;  
displayFlag = true;

simulator = simulator(horizon, individualCellArray, displayFlag); 
simulator.agentSetUp(); 
simulator.displayAgentStates();
simulator.excuteSimulation(); 
simulator.displayAgentStates();


