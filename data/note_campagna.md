# Note su campagna.json (pagine PDF 65-88)

Scelte interpretative e dubbi emersi trascrivendo le regole di campagna.

## Formato
- Ho scritto le tabelle a dadi come `{"_dado": ..., "righe": [...]}`, come chiede LEGGIMI_DATI.md. La vecchia `eventi_viaggio` in nave.json era invece un array semplice. L'ho sostituita con lo stesso oggetto: se il codice Godot si aspetta un array, deve leggere `["righe"]`. Oggi nessuno script `.gd` usa questa chiave.
- nave.json è stato riletto e riscritto con `json.dump(indent=2)`. Il contenuto delle altre chiavi è identico, ma la formattazione del file (a capo e spazi) può essere cambiata.
- In `effetti` ho usato diverse chiavi nuove, oltre a quelle di LEGGIMI: `ritira`, `tabella`, `sottotabella`, `ripetizioni`, `tentativi`, `oggetti_danneggiati`, `ripara_oggetto`, `se_specie`, `specie_immuni`, `oggetto_speciale`, `monouso`, `bonus_turno` e altre. Sono documentate nella `_nota` principale di campagna.json. Valutare se aggiungerle a LEGGIMI_DATI.md.
- In `prova`, `"stat": null` vuol dire tiro secco di 1D6 senza statistica (es. "tira 1D6, con 6 +1 punto Storia").
- ID oggetti: `bottino` = Loot Table (p.131), `bottino_equip` = sottotabella Gear del Loot (p.132). Per le armi uso gli id di armi.json (pistola, fucile_coloniale, fucile_pompa, fucile_automatico, pistola_blaster, spada_luce, lama, granata_frakk/accecante). `stim` viene da equipaggiamento.json. **`med_patch`, `mirino_laser`, `bipiede` e `torcia_raggio` sono id provvisori**: in equipaggiamento.json non esistono, o lì "medikit" e "occhiali_visori" hanno nomi inglesi incerti. Vanno allineati.
- Gli id di specie (`ingegnere`, `kerin`, `senzanima`, `precursore`, `ferale`, `swift`) vanno verificati contro specie.json.

## Interpretazioni
- **Mantenimento con meno di 4 membri**: il testo dice "1 credito con 4-6 membri" e non tratta il caso sotto i 4. Ho assunto 1 credito.
- **Interessi del debito**: "+1 credito (+2 se devi 31 o più)". Ho letto la soglia di 31 come riferita al debito *prima* dell'aumento.
- **Asteroidi**: il testo non dice cosa succede se il tentativo di evitarli (1D6, 5+) fallisce. Ho assunto che allora si debba attraversare il campo (3 prove 1D6+Acume, 4+).
- **Problemi di navigazione**: la ferita per lo scafo danneggiato e il nuovo tiro sulla tabella si applicano entrambi. È marcato `manuale` perché serve la Tabella delle ferite.
- **Richiesta di soccorso 5-6**: "tre tiri sulla gear loot table" l'ho reso con la sottotabella Equipaggiamento del bottino (`bottino_equip`). Potrebbe invece voler dire la Gear Table di p.29 (`equip`).
- **Incidente**: "riposare un turno" l'ho codificato come `ferito_casuale: 1`. Il testo non dice se il membro è a caso o a scelta: ho assunto a caso.
- **Fenomeno cosmico**: non è chiaro quale membro riceva +1 Fortuna. Ho assunto un membro a caso (resta da decidere nel motore). "Se possono" si riferisce al massimo di Fortuna della specie.
- **Licenza falsa**: la regola è unica per mondo. Ho supposto che si possa tentare al posto dell'acquisto e che, se fallisce, si possa ancora pagare. Il testo non lo dice esplicitamente.
- **Soglie BHC**: ricavate dall'impaginazione a colonne di p.83. L'ordine delle colonne è Corporazione, Governo locale, Governo di settore, Individuo facoltoso, Organizzazione privata, Gruppo segreto. Risultato: Benefici 5+ solo per Individuo facoltoso, Rischi 5+ solo per Gruppo segreto, Condizioni 5+ solo per Corporazione, tutto il resto 8+.
- **Paga di pericolo e Tempistica** hanno righe "10+" a causa dei modificatori +1. Le ho codificate con `a: 99`.
- **Lavoro scottante (Hot Job)**: "you will earn an enemy on 1-2" l'ho interpretato come diventare Rivale con 1-2 invece di 1 (`rivale_soglia: 2`).
- **Trasporto privato** compare tra i *Rischi* nel libro anche se è un vantaggio. L'ho lasciato lì come nel testo.
- **Follia**: "+3 Invasione / -3 Iniziativa" sostituiscono i +2/-2 di Hardcore, non si sommano. Il nemico Base extra di Hardcore resta.
- **Facile**: "+1 credito alle ricompense post-battaglia" l'ho codificato come `crediti_ricompensa: 1`.
- **Pacco da consegnare (esplorazione 41-44)**: "con 1-2 acquisisci un Rivale *e* ricevi +1 punto Storia". Ho letto che entrambi gli effetti valgono solo con 1-2.
- **Commercio 31-34 Contrabbando**: con 4-6 sul dado dei crediti si riceve anche un Rivale. È codificato come `rivale_se_dado_almeno: 4`, una chiave nuova.
- **Ninnolo di lusso**: se lo trova uno Swift, lo tiene per sé e prende +2 XP, e le altre opzioni non sono disponibili.
- **Tecnico fanatico (45-47)**: un Ingegnere prende +2 XP *invece* del tiro di riparazione (`sostituisce: true`).
- **Recluta che esce da un incarico appena dimesso dall'Infermeria**: non può fare incarichi in quel turno (regola delle cure mediche).
- Il controllo dei Rivali nella scelta della battaglia somma +1 per ogni Esca. Lo dice la sezione Decoy di p.78 ed è confermato dall'esempio di p.86.
- Il passo "Assegnare l'equipaggiamento" ha una sezione propria (`assegna_equipaggiamento`) anche se non era nell'elenco richiesto.

## Dubbi da verificare sul libro
- Il testo del PDF a p.66 (stampata 64) è sovrapposto su due colonne. Ho ricostruito l'elenco delle condizioni di vittoria e la tabella D10 della natura delle Dicerie dall'impaginazione: sembrano corrette, ma conviene un controllo visivo.
- Le pagine citate nei testi (p.59, p.79, p.131...) sono quelle del libro stampato, non i numeri dei file PDF (stampata = PDF - 2).
- Le regole di Missione dopo la battaglia (Quest Rumors, p.120) e la Tabella del bottino (p.131) stanno fuori dall'intervallo 65-88: qui sono solo citate.
- Nella sequenza del turno, "Check for Invasion" e "Galactic War progress" rimandano a regole di altre pagine.
