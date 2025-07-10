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



%% Parametri del modello
rng(10);
lambda = 2;      % Tasso di arrivo
mu = 3;          % Tasso di servizio
s = 2;           % Numero di server
T = 100;         % Tempo totale della simulazione

% Inizializzazione distribuzioni esponenziali
interArrivalDist = makedist('Exponential', 'mu', 1/lambda);
serviceDist = makedist('Exponential', 'mu', 1/mu);

% Inizializzazione variabili di stato
clock = 0;
nextArrival = random(interArrivalDist);
nextDeparture = inf(1, s);  % Uno per ogni server
queue = [];                 % Coda (tempi di arrivo)
busyServers = 0;

% Statistiche
numArrivals = 0;
numDepartures = 0;
areaQueue = 0;
lastEventTime = 0;

fprintf('Simulazione M/M/%d avviata...\n\n', s);

% Ciclo della simulazione
while clock < T
    % Trova prossimo evento
    [nextEventTime, eventIndex] = min([nextArrival, nextDeparture]);
    clock = nextEventTime;

    % Area sotto curva lunghezza coda
    areaQueue = areaQueue + length(queue) * (clock - lastEventTime);
    lastEventTime = clock;

    if eventIndex == 1
        % ARRIVO
        numArrivals = numArrivals + 1;
        fprintf('ARRIVO al tempo %.2f\n', clock);

        if busyServers < s
            % C'è un server libero
            busyServers = busyServers + 1;
            idx = find(isinf(nextDeparture), 1);
            nextDeparture(idx) = clock + random(serviceDist);
        else
            % Tutti occupati → metti in coda
            queue(end+1) = clock;
        end

        % Pianifica prossimo arrivo
        nextArrival = clock + random(interArrivalDist);

    else
        % USCITA (da uno dei server)
        serverId = eventIndex - 1;
        numDepartures = numDepartures + 1;
        fprintf('USCITA al tempo %.2f (Server %d)\n', clock, serverId);

        if ~isempty(queue)
            % Servi prossimo in coda
            arrivalTime = queue(1);
            queue(1) = [];
            nextDeparture(serverId) = clock + random(serviceDist);
        else
            % Libera il server
            nextDeparture(serverId) = inf;
            busyServers = busyServers - 1;
        end
    end
end

% Statistiche finali
fprintf('\n========== RISULTATI ==========\n');
fprintf('Clienti arrivati:     %d\n', numArrivals);
fprintf('Clienti serviti:      %d\n', numDepartures);
fprintf('Clienti in coda:      %d\n', length(queue));
fprintf('Tempo totale:         %.2f\n', T);
fprintf('Lunghezza media coda: %.4f\n', areaQueue / T);








