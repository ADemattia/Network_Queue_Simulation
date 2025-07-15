%% TEST Classico con un generatore, una coda a capacità infinita e un server 
clear all
clc

addpath(genpath('simulation'))
addpath('queues/core')
addpath('queues/utils')
addpath('queues/implementations')

rng(10);
arrivalRate = 2; 
serviceRate = 3; 

% GENERATOR 1 
pd1 = makedist('Exponential', 'mu', 1/arrivalRate);
interArrivalDistribution = @(n) random(pd1);
numType = 1; 
typeDistribution = @(n) 1; 
 
gen1 = generator(interArrivalDistribution, numType, typeDistribution); % 1 

% QUEUE 2 
overtaking = false; 
capacity = inf; 
waitingFlag = false; 

queue2 = classicQueue(overtaking,waitingFlag, capacity); % 2

% SERVER 3 
numServer = 1; 
pd2 = makedist('Exponential', 'mu', 1/serviceRate);
serverDistribution = @(n) random(pd2);  
revenueFunction = @(n) 0; 

server3 = classicServer(numServer,serverDistribution, revenueFunction);  % 3

% vettore nodi, grafo struttura e orizzonte 
queueNodes = {gen1, queue2, server3}; 
queueGraph = [0, 1, 0; 0, 0, 1; 0, 0, 0]; 

network = networkQueue(queueNodes, queueGraph); 
network.networkSetUp(); 


horizon = 1e2;  
displayFlag = false;

simulator = simulator(horizon, queueNodes, displayFlag); 
simulator.agentSetUp(); 
%simulator.displayAgentStates();
simulator.excuteSimulation(); 
%simulator.displayAgentStates();
 

statisticsArray = network.collectStatistics(); 
statisticsArrayWaiting = network.waitingTimeStatistic();

