# Simulazione a Eventi Discreti di Reti di Code

Questo progetto fornisce un semplice **framework di simulazione a eventi discreti** sviluppato in **MATLAB**, pensato per modellare **reti di code** composte da generatori, code e server. L’obiettivo è studiare il comportamento di sistemi con dinamiche temporali, analizzando metriche come tempi di attesa, occupazione delle risorse e throughput.

## Motivazione

Abbiamo scelto di impostare la simulazione seguendo il paradigma delle **reti di code**, un approccio flessibile e intuitivo per rappresentare una vasta gamma di sistemi reali.

## Descrizione Generale

Il progetto fornisce un **framework di simulazione a eventi discreti** sviluppato in **MATLAB**, progettato per configurare e analizzare **reti di code** costituite da generatori, code e server.

Il modello è in grado di rappresentare efficacemente diversi sistemi reali basati su meccanismi di attesa e servizio, come ad esempio:

- Linee di montaggio in ambito produttivo  
- Sportelli o call center in ambito servizi  
- Stazioni di servizio con risorse fisiche limitate  

Grazie alla definizione di **classi personalizzabili**, la struttura del framework è **flessibile** e permette di adattare facilmente la logica della simulazione a scenari diversi, mantenendo una separazione chiara tra la gestione degli eventi e il comportamento degli elementi del sistema.

Sono incluse funzionalità per l’analisi delle prestazioni, tra cui il calcolo di **tempi di attesa**, **throughput** e **occupazione delle risorse**.

---

## Classi Principali e Funzionalità

### core/
- **`simulator.m`**: motore a eventi discreti. Gestisce l'orologio globale, il calendario eventi, l'avanzamento della simulazione e la raccolta delle statistiche.
- **`queue.m`**: classe astratta per definire l'interfaccia di una coda. Metodi obbligatori:
  - `arrivalManagment(obj, customer)`
  - `isQueueAvailable(obj)`
  - `clearQueue(obj)`
- **`server.m`**: classe astratta per definire l'interfaccia di un server. Metodi obbligatori:
  - `[servicePossible, customer] = checkAvailability(obj)`
  - `scheduleNextEvents(obj, customer, clock)`
  - `addWaiting(obj, clock)`
  - `exitCustomer(obj, clock)`
  - `clearServer(obj)`

### implementations/
- **`generator.m`**: genera arrivi secondo una distribuzione specificata e assegna tipi di cliente.

#### queue/
- **`classicQueue.m`**: coda FIFO con capacity limit e politica accept/reject.
- **`balkingQueue.m`**: coda balking con hard capacity (sempre accettazione) e soft capacity (accettazione probabilistica).

#### server/
- **`classicServer.m`**: multiserver parallelo classico FIFO.
- **`priorityServer.m`**: multiserver con limiti di capacità per tipo di cliente e regole di priorità.
- **`gasServer.m`**: serie di server con vincoli fisici di sequenza; gestisce overtaking e stuck traffic.

### utils/
Funzioni di supporto per analisi, plotting e conversione dati.

---

## Struttura del Repository
```
/project-root
│
├─ core/
│   ├─ generator.m
│   ├─ simulator.m
│   ├─ queue.m
│   └─ server.m
│
├─ implementations/
│   ├─ queue/
│   │   ├─ classicQueue.m
│   │   └─ balkingQueue.m
│   └─ server/
│       ├─ classicServer.m
│       ├─ priorityServer.m
│       └─ gasServer.m
│
├─ utils/
│   ├─ customerIdGenerator.m   % genera ID unici per i clienti
│   ├─ nodeIdGenerator.m       % genera ID unici per i nodi (generatori, code, server)
│   └─ serverState.m           % definisce stati possibili di un server
└─ examples/
    ├─ bufferSituation.m
    ├─ classicTest.m 
    ├─ gasStation.m
    ├─ MM1BalkingObj.m 
    └─ revenueManagment.m
    
```

---

## Come Far Funzionare il Codice

1. **Costruire la matrice di adiacenza** `queueGraph` (dimensione equal al numero di nodi). Un elemento `1` in posizione (i,j) indica un arco dal nodo i al nodo j: **Definire i nodi**: creare istanze di generatori, code e server. Es:
   ```matlab
   g1 = generator(@() exprnd(1), 1, @() 1);
   q1 = classicQueue(false, false, inf);
   s1 = classicServer(2, @() exprnd(2), @(~)0);
   nodes = {g1, q1, s1};
   ```
2. **Costruire la matrice di adiacenza** `queueGraph` (dimensione equal al numero di nodi). Un elemento `1` in posizione (i,j) indica un arco dal nodo i al nodo j:
   ```matlab
   % g1→q1→s1
   queueGraph = [0 1 0;
                 0 0 1;
                 0 0 0];
   ```
3. **Istanziare e configurare** il simulatore:
   ```matlab
   horizon     = 100;      % tempo di simulazione
   displayFlag = true;     % mostra debug passo-passo
   sim = simulator(horizon, nodes, queueGraph, displayFlag);
   sim.networkSetUp();
   ```
4. **Eseguire** la simulazione:
   ```matlab
   sim.excuteSimulation();
   ```
5. **Raccogliere statistiche**:
   ```matlab
   sim.collectStatistics();
   sim.waitingTimeStatistic();
   ```

---

## Come Implementare una Coda Custom
1. Creare un nuovo file nella cartella `implementations/queue`, es. `myQueue.m`.
2. Estendere la classe astratta:
   ```matlab
   classdef myQueue < queue
       methods
           function arrivalManagment(obj, customer)
               % logica di inserimento
           end
           function available = isQueueAvailable(obj)
               % condizione di disponibilità
           end
           function clearQueue(obj)
               % reset stato
           end
       end
   end
   ```
3. Usare la nuova coda in uno script: `q = myQueue(overtaking, waiting, capacity);`.

---

## Custom Server
Procedura analoga per `implementations/server`:
1. Creare `myServer.m` estendendo `server`.
2. Implementare i metodi astratti: `checkAvailability`, `scheduleNextEvents`, `addWaiting`, `exitCustomer`, `clearServer`.
3. Integrarlo in `examples/...` come nodo server.

---

## Esperimenti e Script Esemplificativi
- **Rete Base M/M/c (`example_basic.m`)**: flusso gen→coda→server classico con `classicQueue` infinita e `classicServer` a c linee parallele.
- **M/M/1 con Balking (`example_mm1_balking.m`)**: coda `balkingQueue` con hardCapacity e softCapacity; studio di impatto su attese e persi.
- **Buffering Server (`example_buffer.m`)**: test di `waitingFlag=true` per code `classicQueue` di capacità limitata, analisi di come i server attendono la liberazione della coda.
- **Server Prioritario con Revenue Management (`example_priority.m`)**: `priorityServer` con quote per tipo e funzione di revenue, combinato con `balkingQueue`, valutazione di ricavi e attese.
- **Gas Station (`example_gasStation.m`)**: `gasServer` con vincoli fisici in serie (`serverSeries = {[1,2],[3,4]}`) e `classicQueue` verso cassa, analisi traffico bloccato, simulazione distributore benzina.

---

## Licenza
Rilasciato sotto licenza MIT. Consultare `LICENSE.md` per i dettagli.
