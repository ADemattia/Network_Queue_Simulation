clc
clear all 

addpath(genpath('../core'));
addpath(genpath('../utils'));
addpath(genpath('../implementations'));

rng(10); 

% GENERATOR 1 
arrivalRate = 2; 
pd1 = makedist('Exponential', 'mu', 1/arrivalRate);
interArrivalDistribution1 = @(n) random(pd1);
numType = 2; 
typeDistribution1 = @(n) randi([1,2]); 

gen1 = generator(interArrivalDistribution1, numType, typeDistribution1); % 1

% QUEUE 2 (Coda per entrata) 
capacity = 10; 
overtakingFlag = 0; % sorpasso in coda non possibile 
waitingFlag = false; % customer non aspetta, entra subito sempre (in una coda a capacità finita si perde)  

queue2 = classicQueue(overtakingFlag, waitingFlag, capacity); % 2

% SERVER 3 
serviceRate = 1; 
numServer = 4; 
pd2 = makedist('Exponential', 'mu', 1/serviceRate);
serverDistribution = @(n) random(pd2);  
revenueFunction = @(n) 0; 
numType = 2; 
serverSeries = {[1; 2], [3; 4]}; 
serverPerType = {[1; 2], [3; 4]}; 

server3 = gasServer(numServer,serverDistribution, revenueFunction, serverSeries, numType, serverPerType); % 3  

% QUEUE 4 (Coda per cassa) 
capacity = 5; 
overtakingFlag = false; % non è possibile il sorpasso  
waitingFlag = true; % i customer aspettano nel server non possono essere persi 

queue4 = classicQueue(overtakingFlag, waitingFlag, capacity); % 4

% SERVER 5 (Cassa) 
serviceRate = 0.5; % collo di bottiglia 
numServer = 2; % si può cambiare il numero di servitori  
pd3 = makedist('Exponential', 'mu', 1/serviceRate);
serverDistribution = @(n) random(pd3);  
revenueFunction = @(n) 0; 

server5 = classicServer(numServer,serverDistribution, revenueFunction); % 5

% SIMULAZIONE
queueNodes = {gen1, queue2, server3, queue4, server5}; 
queueGraph = [0, 1, 0, 0, 0; 0, 0, 1, 0, 0; 0, 0, 0, 1, 0; 0, 0, 0, 0, 1; 0, 0, 0, 0, 0];
horizon = 40; 
displayFlag = false; 

simulator = simulator(horizon,queueNodes,queueGraph, displayFlag); 
simulator.networkSetUp(); 
simulator.excuteSimulation(); 

statisticsArray = simulator.collectStatistics(); 
statisticsArrayWaiting = simulator.waitingTimeStatistic(); 

%simulator.displayCustomerTrajectories(); 
%simulator.clearSimulator(); 
%statisticsArray = simulator.collectStatistics();

