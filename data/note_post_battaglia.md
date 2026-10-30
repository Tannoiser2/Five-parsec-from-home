# Note su post_battaglia.json

Fonte: pagine PDF 121-132 (libro pp. 119-130) e 137 (esempio).

## Scelte interpretative
- **Sequenza**: 14 passi nell'ordine del libro. Il passo 7 (Bottino) contiene solo il rimando (`"rimando": "bottino"`). Le tabelle Bottino le trascrive un altro file.
- **Nomi di gioco tradotti**: Tenere il Campo (Held the Field), Vittoria/Vinto (Won), vittima (casualty), Infermeria (Sick Bay), Diceria di Missione (Quest Rumor), Missione (Quest), Minaccia d'Invasione (Invasion Threat), Prove d'Invasione (Invasion Evidence), Senz'anima (Soulless), Scorta (Stash), Individuo Unico (Unique Individual), Minacce Vaganti (Roving Threats), Contratto Una Tantum (One-time Contract), Impavidi (Fearless), Scontro Diretto (Straight-up Fight). Se altri file usano termini diversi, conviene uniformarli.
- **Tabella Missione**: gli estremi aperti sono scritti come `da: -99` (punteggio di 3 o meno) e `a: 99` (7 o più). Lo stesso vale per la Guerra Galattica (10+ = `a: 99`).
- **Ferite**: `turni_recupero` contiene i turni in Infermeria. Nella tabella dei Bot contiene i turni di riparazione. "Death or permanent injury" è reso con `morte` + `rimosso`: per il motore l'esito è lo stesso, cioè il personaggio esce dalla campagna. Per la Ferita invalidante si usano `scelte`: pagare 1d6 crediti oppure applicare `stat_piu_alta` (-1 alla più alta tra Velocità e Robustezza). Il libro non dice cosa succede a pari valore; il motore può far scegliere il giocatore.
- **Fortuna e morte**: la regola "chi ha Fortuna sopravvive ma perde tutta la Fortuna" sta nelle `regole` e non negli effetti. Il motore deve applicarla prima di `morte`. Non è chiaro se valga anche per i Bot: i Bot hanno normalmente Fortuna 0, quindi la questione di solito non si pone.
- **XP**: ho reso la tabella come chiave->valore. Un personaggio prende una sola voce tra `ferito`, `sopravvissuto_non_vinto` e `sopravvissuto_vinto`, più i bonus. Questa lettura combacia con l'esempio: i feriti prendono 1, i sopravvissuti di una battaglia vinta 3, e c'è +1 per il primo a colpire. Il bonus `modalita_facile` e quello per la fase finale della Missione li ho intesi per personaggio.
- **Massimi delle statistiche**: Combattimento +5 e Acume +5 sono salvati come 5. Velocità 8" è salvata come 8. Fortuna ha massimo 1, ma 3 per gli Umani (`massimo_umani`).
- **Bot**: comprano gli aumenti pagando in crediti lo stesso numero del costo in XP, una volta sola per statistica. Il Tecnico dei Bot dà uno sconto di 1 credito.
- **Addestramento**: il costo si paga in XP, crediti o un misto (i Bot pagano solo in crediti). Il corso Meccanico dice che gli Ingegneri "contano doppi gli XP spesi": l'ho registrato come `xp_doppi_per`. Ho interpretato che ogni XP valga 2 punti di costo. Lo sconto di -2 per i Ferali sulla Sicurezza è in `sconto`. Pilota, Medicina e Mercante sono `manuale` perché toccano tiri di altre fasi.
- **Acquisti**: "Hand Guns, Blades, Colony Rifles, Shotguns" sono mappati sugli id di armi.json: `pistola`, `lama`, `fucile_coloniale`, `fucile_pompa`. Per i tiri a 3 crediti ho usato i codici `arma_militare`, `equip` e `gadget`.
- **Eventi di campagna**:
  - 4-8: il costo è 1d6 con -1 se c'è un Ingegnere (`mod_ingegnere`). Va gestito il minimo 0.
  - 36-38: se non ci sono Rivali il capitano prende +1 XP (`se_nessun_rivale`).
  - 52-56: il fisco fa pagare il dado più alto di 2d6 (`-2d6kh1`). Il sequestro della nave è manuale.
  - 75-78: si scelgono 3 armi, anche ripetute (`ripetibili: true`). Il testo dice "your choice of 3 weapons from the list" e mi sembra permettere i doppioni.
  - 79-81: il debito si riduce di 1d6+1 (`"debito": "-1d6-1"`).
  - 98-100: le `scelte` dipendono da una condizione (c'è stato o no un ferito). Il motore dovrebbe offrire solo l'opzione valida.
- **Eventi del personaggio**:
  - `esclusi` elenca le specie o classi immuni (kerin, ingegnere).
  - 13-15: il tiro è un d6 secco (`prova` senza `stat`).
  - 42-45: il personaggio e un altro membro a caso prendono +1 XP ciascuno (`xp` + `xp_casuale`).
  - 63-66: un turno in Infermeria e 1 danno allo Scafo.
- **Ritrovamenti**: ho introdotto i token oggetto `componente_nave` (vale 2 crediti solo per installare componenti della nave) e `ninnolo_personale` (su ogni nuovo pianeta si tira 2d6, con 9+ si ottiene un tiro sul Bottino). Per le righe 26-35 e 76-90 l'effetto alternativo per le Minacce d'Invasione è in `se_minaccia_invasione` e sostituisce gli `effetti` normali.
- **Invasione**: tra i modificatori ho aggiunto anche quelli citati altrove, segnandone l'origine: +2 dall'evento "voci di guerra" e -2 sui mondi liberati dalla Guerra Galattica.

## Chiavi nuove introdotte (non presenti in LEGGIMI_DATI)
`turni_recupero`, `morte`, `rimosso`, `danneggia_equip` (tutto / casuale / scorta_casuale), `perde_tutto`, `stat_piu_alta`, `tiro_tabella`, `se_minaccia_invasione`, `prova_invasione`, `mod_tiro_invasione`, `missione_finale`, `missione`, `nuovo_membro`, `cedi_oggetto`, `xp_tutti`, `xp_capitano`, `bersagli`, `bersagli_casuali`, `mod_ingegnere`, `blocca_nave_finche_pagato`, `rivale_per_turno_sul_pianeta`, `blocca_partenza_turni`, `salta_battaglia_turni`, `assente_turni`, `al_ritorno`, `niente_compiti_turni`, `niente_xp_turni`, `azione_extra_turni`, `se_infermeria`/`altrimenti`, `se_specie`, `se_motivazione`, `se_ferito_recente`, `se_nessun_rivale`, `se_nessun_debito`, `scelta_multipla`, `scelta_stat`, `ripara_oggetto`, `ignora_prossima_ferita`, `rivale_legato_al_personaggio`, `pianeta_perso`, `pianeta_liberato`, `mod_guerra`, `esclusi`, `solo_specie`. Nei corsi: `riparazione_scafo_extra`, `iniziativa`, `mod_licenze`, `mod_addestramento`, `mod_ricerca_patroni`, `sconto_potenziamenti_bot`. Se si preferisce, si possono ridurre a `manuale: true`.

## Dubbi
1. **Paga**: non è chiaro in che ordine si applicano "tieni il migliore di 2 +1" (finale di Missione), "+1 Facile" e "1-2 valgono 3". Ho supposto: prima si tira, poi si porta l'1-2 a 3, poi si aggiungono i bonus.
2. **Rivale esistente**: "On a 4 or better" si riferisce al tiro modificato. Il libro non dice cosa succede se non avete Tenuto il Campo: nessun tiro, il Rivale resta.
3. **Paga di Rischio e bonus Paga dei Patroni**: rimandano al capitolo dei Patroni e non sono trascritti qui.
4. **Eventi 9-12 e 39-41 (nuovo membro)**: per il motore il personaggio si crea con le regole di creazione. Nel 39-41 c'è solo il profilo base, e se nell'equipaggio ci sono Ferali anche il nuovo membro è Ferale. Questo vincolo non è codificato, sta solo nel testo.
5. **Evento 21-23 (vecchia nemesi)** ed **evento 57-59 (nuovo capitano)**: sono lasciati `manuale` perché richiedono scelte complesse e la regola sui K'Erin.
6. **Evento del personaggio 20-23 (rissa)** e **11-12 (lasciare l'equipaggio)**: sono `manuale`. Si possono automatizzare facilmente, ma servono chiavi dedicate.
7. **Evento 92-94**: "per ogni turno che restate su questo pianeta" è un effetto persistente legato al pianeta.
8. **Swift (Affari altrove)**: il personaggio non torna e viene sostituito da un nuovo Swift. L'evento resta `manuale`, perché le parti automatiche (`assente_turni`, `al_ritorno`) non valgono per gli Swift.
9. **Guerra Galattica**: ho inteso il +1 di "Making Ground" come cumulativo per pianeta. Il libro dice "add +1 to all future rolls", che è compatibile, ma non dice esplicitamente se si somma.
