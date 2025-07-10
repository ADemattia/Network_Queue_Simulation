clc
clear all
close all 

pd = makedist('Exponential', 'mu', 1);

g = generator(10,pd); 
g.nextArrival; 
g.dispClock; 

%% 
pd1 = makedist('Exponential', 'mu', 1);

interArrivalDistribution = @(n) random(pd1); 

pd2 = makedist('Uniform', 'Lower', 1, 'Upper', 2);

typeDistribution = @(n) randsample([1, 2], 1, true); 

pd3 = makedist('Uniform', 'Lower', 5, 'Upper', 10);

revenueDistribution = @(n) random(pd3); 

queue = 1; 
gen = generator(interArrivalDistribution, typeDistribution, revenueDistribution);
gen.queueAssignment(queue,1); 

for i = 1:100
    gen.scheduleNextArrival();
    gen.dispStatus(); 
end 


%% 


% Definisco dati: arrivalRate, lowerProc1, upperProc1, lowerProc2, ...
% upperProc2, bufferSize
% Definisco (e inizializzo) variabili di stato:
% clock, eventTimes (array per tre tipi eventi)
% idle1, blocked1, idle2 (assumo variabili booleane;
% ootrei usare variabili intere con codici di stato predefiniti)
% queueLength, bufferLength, le due lunghezze di coda
% startBlocked, totalBlocked per mercare inizio blocking e cumulare i tempi
% horizon e' l'orizzonte simulato
eventTimes = [exprnd(1/arrivalRate); inf; inf];
clock = 0;
while clock <= horizon % loop di simulazione
 [clock, idx] = min(eventTimes);
 switch idx
 case 1
 manageArrival();
 case 2
     manageCompletion1();
 case 3
 manageCompletion2();
 end
end
% gestisco caso in cui la simulazione finisce in stato di blocking
if blocked1
 totalBlocked = totalBlocked + clock -startBlocked;
end
fractionBlocked = totalBlocked /clock;
%%%%%%%%%%%%%%%%%
function manageArrival()
 eventTimes(1) = clock + exprnd(1/arrivalRate);
 if idle1 && (~blocked1) % macchina 1 libera (ma non bloccata)
 idle1 = false;
 eventTimes(2) = clock + unifrnd(lowerProc1,upperProc1);
 else
 queueLength = queueLength + 1;
 end
end
%%%%%%%%%%%%%%%%%%
function manageCompletion1()
 % gestisco M1
 if bufferLength == bufferSize % buffer pieno, blocco
 idle1 = true;
 eventTimes(2) = inf;
 blocked1= true;
 startBlocked = clock;
 return; % non ho nulla da fare, esco
 else
 if queueLength > 0 % se coda, M1 passa al prossimo
 queueLength = queueLength - 1;
 eventTimes(2) = clock + unifrnd(lowerProc1,upperProc1);
 else % coda vuota, M1 idle
 idle1 = true;
 eventTimes(2) = inf;
 end
 end
 % gestisco M2 (non mi preoccupo di blocking)
 if idle2 % macchina 2 ferma, quindi buffer vuoto, parte 2
 idle2 = false;
 eventTimes(3) = clock + unifrnd(lowerProc2,upperProc2);
 else % 2 busy, metto pezzo in buffer
 bufferLength = bufferLength + 1;
 end
end
%%%%%%%%%%%%%%%%%%
function manageCompletion2()
 % gestisco M2
 if bufferLength == 0 % buffer vuoto, M2 idle
 idle2 = true;
 eventTimes(3) = inf;
 else
 eventTimes(3) = clock + unifrnd(lowerProc2,upperProc2);
 bufferLenght = bufferLenght - 1;
 if blocked1 % eventuale sblocco di M1
 blocked1 = false;
 totalBlocked = totalBlocked + clock - startBlocked;
 if queueLength > 0 % M1 riparte
 queueLength = queueLength - 1;
 idle1 = false;
 eventTimes(2) = clock + unifrnd(lowerProc1,upperProc1);
 end
 end
 end
end


%% 

%% SCRIPT DI SIMULAZIONE - test.m

% PARAMETRI DI SIMULAZIONE
arrivalRate = 1.5;
lowerProc1 = 0.5;
upperProc1 = 1.0;
lowerProc2 = 0.4;
upperProc2 = 0.8;
bufferSize = 5;
horizon = 1000;

% INIZIALIZZAZIONE
eventTimes = [exprnd(1/arrivalRate); inf; inf];
clock = 0;

idle1 = true;
idle2 = true;
blocked1 = false;

queueLength = 0;
bufferLength = 0;

startBlocked = 0;
totalBlocked = 0;

% GLOBAL PER FUNZIONI LOCALI
global clock eventTimes arrivalRate idle1 blocked1 lowerProc1 upperProc1 queueLength
global bufferSize bufferLength idle2 lowerProc2 upperProc2 startBlocked totalBlocked

% SIMULAZIONE
while clock <= horizon
    [clock, idx] = min(eventTimes);
    switch idx
        case 1
            manageArrival();
        case 2
            manageCompletion1();
        case 3
            manageCompletion2();
    end
end

if blocked1
    totalBlocked = totalBlocked + clock - startBlocked;
end

fractionBlocked = totalBlocked / clock;
fprintf('Tempo totale simulato: %.2f\n', clock);
fprintf('Tempo totale di blocco: %.2f\n', totalBlocked);
fprintf('Frazione di tempo in blocco: %.4f\n', fractionBlocked);

%% === FUNZIONI LOCALI ===

function manageArrival()
    global clock eventTimes arrivalRate idle1 blocked1 lowerProc1 upperProc1 queueLength
    eventTimes(1) = clock + exprnd(1/arrivalRate);
    if idle1 && (~blocked1)
        idle1 = false;
        eventTimes(2) = clock + unifrnd(lowerProc1, upperProc1);
    else
        queueLength = queueLength + 1;
    end
end

function manageCompletion1()
    global clock eventTimes lowerProc1 upperProc1 bufferSize bufferLength ...
           queueLength idle1 blocked1 startBlocked idle2 lowerProc2 upperProc2
    if bufferLength == bufferSize
        idle1 = true;
        eventTimes(2) = inf;
        blocked1 = true;
        startBlocked = clock;
        return;
    else
        if queueLength > 0
            queueLength = queueLength - 1;
            eventTimes(2) = clock + unifrnd(lowerProc1, upperProc1);
        else
            idle1 = true;
            eventTimes(2) = inf;
        end
    end

    if idle2
        idle2 = false;
        eventTimes(3) = clock + unifrnd(lowerProc2, upperProc2);
    else
        bufferLength = bufferLength + 1;
    end
end

function manageCompletion2()
    global clock eventTimes bufferLength idle2 lowerProc2 upperProc2 ...
           blocked1 totalBlocked startBlocked idle1 queueLength lowerProc1 upperProc1
    if bufferLength == 0
        idle2 = true;
        eventTimes(3) = inf;
    else
        eventTimes(3) = clock + unifrnd(lowerProc2, upperProc2);
        bufferLength = bufferLength - 1;

        if blocked1
            blocked1 = false;
            totalBlocked = totalBlocked + clock - startBlocked;
            if queueLength > 0
                queueLength = queueLength - 1;
                idle1 = false;
                eventTimes(2) = clock + unifrnd(lowerProc1, upperProc1);
            end
        end
    end
end









