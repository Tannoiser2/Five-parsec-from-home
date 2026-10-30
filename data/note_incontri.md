# Note su incontri.json

Fonte: pdf p.89-113 (libro p.87-111), Battle Events pdf p.118-119. IA nemiche da pdf p.44-45 (Enemy Movement); mira pdf p.48; morale e fine battaglia pdf p.116-117; Prendere l'Iniziativa pdf p.114.

## Scelte interpretative
- **Tipi di missione**: chiavi `opportunita`, `patrono`, `rivale`, `missione` (= Quest), `invasione`. Nel libro Opportunità e Patrono hanno una sola colonna per condizioni e luoghi notevoli: l'ho duplicata, così ogni tipo ha la sua tabella.
- **Colonna "rivale" delle categorie**: nel libro è "Unknown Rival" (Rivale inatteso o non noto). Per un Rivale già noto si usa il suo tipo.
- **Difficoltà**: id `facile`, `normale`, `impegnativo`, `hardcore`, `follia` (Easy, Normal, Challenging, Hardcore, Insanity). Nei dati di creazione non c'erano ancora id per la difficoltà: vanno allineati se un altro file li definisce.
- **Codici armi**: "2B" = colonna Arma 2 per le figure base e colonna Specialista B per gli Specialisti, verificato sull'esempio del libro (Ferali 2B: 3 = fucile militare, 6 = mitragliatrice). Ho riscritto la chiave `armi_nemici` di armi.json, che prima interpretava il codice in modo sbagliato (es. "1A" = pistola di rottami + lama fissi). La nuova struttura ha chiavi "1", "2", "3", "A", "B", "C", ognuna con una tabella d6 `righe` [{da, a, armi:[id]}], più `luogotenente` e `_regole`.
- **Panico**: `panico` = [min, max]; un campo di Panico 0 diventa `[]` con `_panico_0: true` (combattono fino alla morte, ma un effetto può portare il campo a 1). I veri Impavidi hanno `speciali.impavido: true` (Robot da guerra, Robot di sicurezza, tutti gli Individui Unici). Un panico "1" nel libro è scritto come [1, 1].
- **IA**: id `aggressivo`, `cauto`, `difensivo`, `guardiano`, `furia` (Rampaging), `tattico`, `bestia`. Nel blocco `_regole_generali` di `comportamenti_ia` ci sono: mira, ordine di attivazione, resa del nemico dopo che hai raggiunto l'obiettivo (1D6 Aggressivi, 2D6 per gli altri, si ritirano su un 1 naturale), morale e cambio di IA della tabella Connessioni.
- **Armi naturali** (Bestie, Krorg ecc.): il campo `arma_naturale` {nome, en, danno, id} riporta il danno dato dal libro. Come id ho usato `zanne_artigli` (danno +0) o `zanne_grandi` (danno +1) di armi.json, anche per Artigli, Schianto e Mandibole.
- **Primitivi**: `armi: ["lama"]`, con `speciali.armi_specialisti: ["arma_brutale"]`.
- **Individui Unici**: sono in `nemici` con categoria `individuo_unico` e id con prefisso `unico_` (per non confonderli con le Minacce vaganti dallo stesso nome, es. Sand Runner). Picchiatore, Arma pesante e Capo hanno nel libro "-" per le statistiche: le ho messe a `null`, con `relativo_al_nemico_base: true` e `modificatori` (es. Robustezza +1). Il Capo ha `ia: null`, cioè usa l'IA del nemico principale. Hanno `numeri: 0`, `panico: []` e il campo `fortuna`.
- **Luogotenente**: è Impavido (regola generale di pdf p.116), tranne contro i nemici con "Codardi" (Cowardly).
- **Effetti**: le tabelle di battaglia usano chiavi proprie (nemici_mod, visibilita, rinforzi, ia_cambia...), descritte nella `_nota` del file. Gli eventi di battaglia hanno tutti `manuale: true` perché vanno applicati durante lo scontro. Il motore di campagna può usare direttamente le chiavi standard (crediti, oggetti, dicerie...).
- **Luogo "Oggetto curioso"**: è codificato come `prova` senza `stat` (1D6 puro): con 5+ si tira sul Bottino, altrimenti si vende per 1 credito.
- **"Bersaglio prioritario"**: non è un oggetto da raccogliere; l'ho segnato `manuale`.
- **Oggetto singolare (+2 XP)**: assegnato al personaggio che lo raccoglie (`xp`, non `xp_casuale`).
- **Schieramento dei Guardiani**: il libro non lo dice; ho scritto "entro 3\" dalla figura protetta".
- **Hired Muscle / Careless / Alert**: i modificatori all'Iniziativa delle singole voci sono in `speciali.iniziativa_giocatore` e si sommano al -1 della categoria (es. Robot di sicurezza: totale 0; Mercenari Skulker: totale -2), come specifica il libro.

## Dubbi
- **"Psycho AI type"** (Enemy Weapons): il libro dice che i nemici con IA Psycho portano sempre una Lama, ma un'IA Psycho non esiste. Probabilmente intende gli Psicopatici (Psychos, IA Furia) o l'IA Furia in generale. L'ho lasciato come testo in `_regole`: il motore dovrebbe dare una Lama extra almeno agli `psicopatici`.
- **Lama extra agli Aggressivi**: il libro scrive "a meno che il loro Combattimento sia +0". Ho codificato `lama_extra_se_combattimento_maggiore_di_0`, ma non va applicata alle bestie e alle creature con armi naturali (Converted Acquisition, Krorg...). Vale solo per chi usa armi.
- **Converted Acquisition**: "Invasion Threat. Test at +1" è stato interpretato come +1 al tiro di controllo dell'Invasione dopo la battaglia (`test_invasione_mod: 1`).
- **Dogged (Isolazionisti)** e **Gene Dog**: rendono Impavidi in certe condizioni; il Cane genetico è già Impavido come Individuo Unico, per cui la clausola "diventa Fearless" è ridondante.
- **Rivale "Ha portato gli amici"/"Assalto"**: +1 figura; non è chiaro se si sommi a "Grudge"/"Cop killer" (io li considero cumulativi).
- **Difficoltà Impegnativa**: "ritira i dadi che fanno 1 o 2": ho supposto un solo ritiro e che valga anche con 1 solo dado (equipaggio 5).
- **Easy**: "togli 1 avversario normale se il totale è 5+": applicato dopo i modificatori, prima di quelli di Hardcore.
- **Tabella dei Ritrovamenti sul campo** (Battlefield Finds) e tabella del **Bottino** (p.131): sono citate ma fuori da queste pagine (`ritrovamenti_campo: 2` = tira due volte).
- **Distorti**: il Distorto rigenerato viene piazzato "1D6\" più lontano" (dal tuo equipaggio? dal punto di morte?). Ho lasciato la distanza come testo e come `rigenera.distanza`.

## Armi
Tutte le armi delle tabelle nemiche e degli Individui Unici esistono in armi.json. Mancano solo gli attacchi naturali con danno +2 (Artigli del Krorg) e +3 (Tocco dei Distorti): hanno `armi: []` e solo `arma_naturale` con `id: null`. Serve una voce `zanne_artigli` con danno variabile oppure due nuove armi naturali.
