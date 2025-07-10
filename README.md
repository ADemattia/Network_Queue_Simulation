# Simulatore a Eventi Discreti per Reti di Code

## Descrizione Generale
Il progetto fornisce un **framework di simulazione a eventi discreti** in MATLAB per configurare e analizzare reti di servizi basate su code, generatori e server. È ideale per:
- **Sistemi produttivi** con linee di montaggio
- **Reti di servizi** (call center, sportelli)
- **Stazioni di servizio** con vincoli fisici (gas station)
- **Analisi di performance**: tempi di attesa, throughput, occupazione risorse

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

### examples/
Script MATLAB che mostrano come configurare e avviare simulazioni per vari scenari:
- `example_basic.m`: rete minimalista gen → coda → server
- `example_mm1_balking.m`: M/M/1 con coda balking
- `example_classicTest.m`: multiserver 2-linee, code infinite
- `example_priority.m`: server con priorità e coda balking
- `example_gasStation.m`: simulazione stazione gas + cassa
- `example_trajectories.m`: estrazione e visualizzazione traiettorie clienti

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
1. **Clonare ed entrare** nella directory del progetto:
   ```bash
   git clone https://github.com/<utente>/<repo>.git
   cd <repo>
   ```
2. **Aprire MATLAB** nella root del progetto.
3. **Aggiungere** tutte le cartelle al percorso:
   ```matlab
   addpath(genpath(pwd));
   ```
4. **Eseguire** uno script di esempio, ad esempio:
   ```matlab
   run('examples/example_basic.m');
   ```
5. **Risultati**: il terminale MATLAB mostrerà statistiche sul numero di clienti serviti, tempi medi di attesa, utilizzo dei server e altre metriche.

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
