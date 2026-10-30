# Note sulle appendici (II, III, V, VIII)

Scelte interpretative e dubbi emersi trascrivendo le Appendici II, III, V e VIII. Le pagine indicate sono quelle stampate sul regolamento; tra parentesi le pagine del PDF.

## griglia.json — Appendice II (p.147-148, PDF 149-150)
- Il testo di p.147 su terminologia, funzioni mancanti, equipaggiamento e giocatori FiveCore riguarda la conversione da edizioni precedenti (Appendice I), quindi non è incluso.
- **Distanza**: il libro dice solo «si conta il percorso più breve, diagonale = 1». La formula `max(|dx|,|dy|)` (Chebyshev) l'ho ricavata io. Se il terreno blocca il passaggio serve comunque un pathfinding: la formula vale solo sulla griglia libera.
- **Attraversare i nemici**: il libro permette solo di attraversare le figure *amiche*. Ho messo `attraversa_nemici: false` per deduzione.
- **Adiacenza in mischia**: il libro dice «adiacente» senza precisare. Ho considerato valide anche le diagonali, coerentemente con il movimento diagonale a costo 1.
- **Respinta**: chi perde la mischia arretra di 1 casella. La direzione non è specificata; si presume in direzione opposta all'attaccante.
- **Linea di vista**: va tracciata «con un po' di flessibilità». Il motore deve scegliere un algoritmo, per esempio Bresenham o una linea tra centri con tolleranza sugli angoli.
- **Direzioni d8**: nei vettori `dx/dy` il Nord vale y = -1, cioè l'asse y punta verso il basso come in Godot.
- La `_nota` di armi.json rimanda a `regole_griglia in battaglia.json`, ma ora le regole stanno in griglia.json. Va allineata.

## zone.json — Appendice III (p.148-151, PDF 150-153)
- **Rinforzi consistenti** (Vincolo di tempo, 3): il testo dice «arrivano nemici aggiuntivi dal centro del bordo avversario» senza dire quanti. Ho segnato `manuale`. Un'ipotesi ragionevole è altri 3.
- **Conto alla rovescia** (4): «Roll 1D6 each round hereafter. On a 1…». Ho interpretato che il primo tiro avvenga subito, alla fine del Round 6, con soglia 1, e che la soglia salga di 1 a ogni round successivo.
- **Opposizione aumentata**: «7 figure + il modificatore del tipo di nemico, nessun altro modificatore». Ho dedotto che la Condizione di Minaccia «Opposizione pesante» (+2) si applichi comunque, perché è una regola specifica del Lavoro Rosso. Da confermare.
- **3 Specialisti, uno dei quali Luogotenente**: ho codificato `specialisti: 3, di_cui_luogotenenti: 1`.
- **Costo della licenza**: va scalato di 15 crediti, oppure di 13 con un Broker. In `effetti` c'è solo -15, quindi lo sconto va applicato dal codice tramite `sconto_broker`.
- **Lavori Neri, «3 tiri sulla tabella Armi del Bottino»**: ho usato il nuovo id `bottino_armi`, che non è nella lista standard di LEGGIMI. Va aggiunto oppure mappato sulla sotto-tabella Armi del Bottino.
- **Missione dei Lavori Neri**: la tabella va da 1-2 a 9-10, quindi è un d10.
- **Distruggi il caposaldo**: il raggio 1D6+3" si misura presumibilmente dal centro del campo, dove stanno le cariche. Detonare è un'Azione Gratuita. Segnato come manuale.
- **Squadre Passive**: «si numerano da sinistra a destra e si tira 1D6». Con più di 6 squadre passive, quelle dalla 7 in poi si attivano solo se vengono bersagliate o avvicinate entro 8".
- **Bonus +1 a Prendere l'Iniziativa** (Lavori Neri): il testo dice «may even claim a +1 bonus», senza condizioni. L'ho reso automatico.
- **Avversario «dalle Minacce Itineranti»**: l'id `minacce_itineranti` è un riferimento alla tabella nemici, che non è ancora trascritta.
- **Ricompense dei Lavori Neri vinti**: il «+5 sul prestito» l'ho codificato come `debito: "-5"`, applicabile solo se c'è un debito.

## storia.json — Appendice V (p.153-160, PDF 155-162)
- Il libro presenta il tracciato come esempio («Sample Story Track»): ci sono 7 eventi più il finale (vittoria o sconfitta), con la nemesi Q'Narr.
- **Evento 1**: in tabella il Panico è «1-2», ma la nota sotto dice 1 con il Capo vivo e 1-3 senza Capo. Ho dato priorità alla nota (`panico_con_capo` / `panico_senza_capo`). La regola «dal Round 6, con 3 figure o meno i nemici si ritirano» è nella colonna di destra di p.154 e l'ho attribuita all'Evento 1.
- **Evento 2**: per l'interrogatorio dopo la cattura in mischia ho aggiunto i flag `mercenario_catturato` e `vinto_evento_2`, che servono al bonus di iniziativa dell'Evento 3.
- **Evento 3**: la sigla «D*» nella colonna IA indica l'IA speciale descritta nel testo (Difensiva entro 12", altrimenti verso il centro). L'ho codificata come `difensiva_speciale`.
- **Evento 4**: il tiro di Morale è «2D6 ≤ perdite subite → il gruppo fugge» e sostituisce il Morale normale. L'ho presunto, non è detto esplicitamente. Il danno alla nave è codificato come `scafo: "-1d6-10"`. «Rimuovere un Rivale» è un'opzione e l'ho reso `rivale: -1`.
- **Evento 5**:
  - Il punto «se ci si muove a contatto con il luogo in cui è stato scoperto, 1D6: con 6 Indizio» non dice a cosa si riferisca. L'ho attribuito al Robot da guerra, perché il Cadavere ha già la sua regola (5-6).
  - Non c'è una condizione di vittoria esplicita, quindi non è chiaro se l'Orologio scenda per vittoria. In ogni caso l'Orologio non scende nei turni con un evento.
  - La «navetta» limita l'equipaggio a 4 membri, ma non è chiaro se il limite valga solo per questa battaglia o fino al ritorno. Ho codificato `equipaggio_max_battaglia: 4`.
- **Evento 5 → 6**: il tiro di ricerca (1D6 + Indizi, 7+) avviene «all'inizio di ogni turno successivo, compreso il seguente». Se fallisce si gioca un turno normale e si ottiene +1 Indizio. Bisogna contare i turni di ricerca (`conta_turni_ricerca`).
- **Evento 6**:
  - Per «ben preparati» ho interpretato «più di 3 turni» come 1 rinforzo per ogni turno oltre il terzo, quindi 4 turni danno 1 rinforzo.
  - Il prigioniero non ha un valore di Acume esplicito in altri punti: ho usato quello della sua scheda, +1.
  - Il «cono» della sentinella è una linea larga ±1". Per la direzione casuale si usa la tabella d8 di griglia.json.
- **Evento 7**:
  - Le sentinelle esterne hanno la tuta (6+), quelle interne no. Ho dato a tutte lo stesso profilo con Fucile militare; per le interne il libro dice solo «senza armatura».
  - Q'Narr ha Panico «-», cioè non fugge mai.
  - «Bots and Soulless» li ho resi come `robot` e `senzanima`; gli id vanno allineati a specie.json.
- **Finale**:
  - Il compagno che si unisce dopo la vittoria non conta per il Mantenimento, in modo permanente.
  - In caso di sconfitta, il Rivale automatico «sui prossimi tre mondi» è codificato come `rivale_per_prossimi_mondi: 3`.
  - Se il compagno era stato «portato via» nell'Evento 6 e si perde la storia, il testo non dice se torni. La regola dell'Evento 6 dice che si unisce «dopo aver concluso l'Evento 7»: ho interpretato che si applichi anche alla sconfitta, con il tiro 4+.
- Le chiavi che non sono in LEGGIMI (`flag`, `tick`, `indizi`, `ritrovamenti_campo`, `xp_tutto_equipaggio`, `xp_ogni_rimasto`, `niente_*` ecc.) sono documentate solo qui e nella `_nota`. Andrebbero aggiunte a LEGGIMI_DATI.md.

## neutrali.json — Appendice VIII (p.172-173, PDF 174-175)
- **Enforcer**: l'ho reso «Agente d'assalto» (id `tutore_ordine`).
- **Corporate slick**: l'ho reso «Rampante aziendale».
- **Chiave inglese** (Tecnico): non esiste in armi.json. È definita direttamente nel profilo (`arma_propria`, Danno +0, Mischia).
- **Robot di servizio**: Acume +0, oppure +2 per i compiti per cui è costruito (`acume_speciale`). Non è chiaro se abbia i tratti dei Robot (niente XP ecc.); la tabella non lo dice.
- **Scaricatore portuale**: l'arma dipende da «agitazioni sindacali». È una condizione narrativa decisa dal GM o dallo scenario.
- **Agente d'assalto**: «metà con Fucile a pompa, metà con Pistola». Con un numero dispari bisogna decidere come arrotondare.
- **Fase Neutrale**: avviene dopo la Fase Lenta. Il comportamento in battaglia dei PN non è specificato, quindi è affidato a scenario o GM.
