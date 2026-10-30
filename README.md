# Five Parsecs from Home - versione digitale (Godot 4)

Versione digitale di **Five Parsecs from Home** (Ivan Sorensen, Modiphius Entertainment, terza edizione 2021):
campagne in solitario di un equipaggio di avventurieri sulla Frontiera della galassia, con battaglie su griglia.
Per uso personale, nella ludoteca digitale.

**Gioca nel browser:** https://five-parsec-from-home.ludoteca-digitale.com/ (ludoteca privata) · https://tannoiser2.github.io/Five-parsec-from-home/

La pubblicazione non parte da sola: Actions → **Pubblica** → *Run workflow*.

## Avvio
1. Apri Godot 4 (testato su 4.7) → *Importa* → seleziona `project.godot`.
2. Premi **F5**. F11 alterna schermo intero e finestra.

## Cosa c'è
- **Creazione dell'equipaggio** con tutte le tabelle del regolamento: tipo (Umano, Alieno primario, Bot, Personaggio strano),
  26 specie con le loro regole, Background, Motivazione e Classe tirati o scelti, Capo, equipaggiamento iniziale,
  nave con debito, crediti, punti Storia, Patroni e Rivali. Metodo casuale, standard o solo Umani; equipaggio di 6, 5 o 4.
- **Turno di campagna completo**: viaggio (carburante, eventi di viaggio, Rivali che seguono, licenze, tratti del mondo,
  fuga dall'invasione), mantenimento e debito della nave, incarichi dell'equipaggio (Patroni, addestramento, commercio,
  reclutamento, esplorazione, rintracciare, riparare, esca), offerte di lavoro dei Patroni (paga di pericolo, tempistica,
  benefici, rischi, condizioni), assegnazione dell'equipaggiamento, Dicerie e Missioni, controllo dei Rivali e scelta della battaglia.
- **Generazione degli incontri**: categorie e tabelle dei nemici (60 tipi e 22 Individui Unici), numero dei nemici per
  dimensione dell'equipaggio e difficoltà, Specialisti e Luogotenenti con le tabelle delle armi nemiche, condizioni di
  schieramento, luoghi notevoli, obiettivi di ogni tipo di missione.
- **Battaglia su griglia** (Appendice II, 1 casella = 1 pollice): campo generato secondo le regole del terreno (elemento
  al centro, elementi grandi, piccoli e lineari nei settori; aree, blocchi, ostacoli lineari, elementi singoli), Prendere
  l'iniziativa, tiro delle reazioni e fasi rapida/nemici/lenta, movimento e scatto con terreno difficile, linea di vista
  (terreno e figure), copertura, tiro (3+/5+/6+, mira, tratti delle armi), rissa, danni, tiri salvezza, Fortuna,
  stordimento, morale e fuga, eventi della battaglia, obiettivi (consegnare, accedere, acquisire, attraversare,
  pattugliare, assicurare, proteggere il VIP, perquisire, eliminare, respingere, difendere...) e resa del nemico.
  **IA dei nemici** secondo i comportamenti del regolamento: Aggressivo, Cauto, Tattico, Difensivo, Furia, Bestia, Guardiano.
  Si può giocare a mano, far finire la battaglia all'IA o risolverla in automatico.
- **Dopo la battaglia**: Rivali, Patroni, progresso della Missione, paga, ritrovamenti, Invasione, bottino con tutte le
  sottotabelle, ferite (anche dei Bot), esperienza e miglioramenti, addestramento avanzato, acquisti e vendite, eventi
  della campagna e del personaggio, guerra galattica.
- **Traccia della Storia** (Appendice V, facoltativa) e **Zona Rossa** (Appendice III): l'orologio e la licenza sono gestiti,
  gli eventi della storia preparano la battaglia; le loro regole speciali di battaglia vanno applicate a mano.
- Schede dei personaggi e della nave, deposito, contatti (Rivali e Patroni), mondo, **diario della campagna**,
  **regole in italiano** consultabili dal menu e in partita.
- **Salvataggi**: automatici sul dispositivo (anche nel browser) e **nel cloud** (Firebase): ogni campagna ha un codice di
  6 lettere con cui la si riapre da qualsiasi dispositivo.

## Grafica
Tutte le immagini sono state generate con i prompt dei file `PROMPT_*.md` e ridotte per il web (WebP); il gioco le carica
da `scripts/ui/immagini.gd` e, se un file manca, torna al disegno di ripiego (pedine con iniziali, terreno a colori).
- **Pedine** (`assets/pedine/`, 384 px): figure viste dall'alto per specie, nemici, Individui Unici, neutrali, VIP e segnalini
  di obiettivo (console, pacco, luogo notevole, punti da perquisire e da pattugliare). Prompt in **[PROMPT_PEDINE.md](PROMPT_PEDINE.md)**.
- **Icone dell'equipaggiamento** (`assets/oggetti/<id>.webp`, 256 px): nelle schede dei personaggi, nel deposito e negli
  acquisti. Prompt in **[PROMPT_EQUIPAGGIAMENTO.md](PROMPT_EQUIPAGGIAMENTO.md)**.
- **Scenari** (`assets/scenari/`, 1024 px): tipo di battaglia nella scelta, tipo e obiettivo nella preparazione, condizione di
  schieramento e luogo notevole accanto al testo; in battaglia l'obiettivo e poi l'ultimo evento. Prompt in
  **[PROMPT_SCENARI.md](PROMPT_SCENARI.md)**.
- **Mappe** (`assets/mappe/`): plancia dell'ambiente (frontiera, arido, ghiacciato, rigoglioso, cristalli, zona di guerra,
  urbano, scelto dai tratti del mondo e dal tipo di scontro; solo grafica), elementi di terreno sopra le caselle che occupano
  e sovrapposizioni per nebbia, buio, polvere e gas. Prompt in **[PROMPT_MAPPE.md](PROMPT_MAPPE.md)**.

Per aggiungere o sostituire un'immagine basta salvarla con lo stesso nome (`.webp` o `.png`); nella versione da computer si
possono provare anche nella cartella dati dell'utente (`user://pedine/`, `user://oggetti/`...). L'importazione usa
compressione con perdita e mipmap (`[importer_defaults]` in `project.godot`).

## Salvataggi nel cloud
Stesso progetto Firebase degli altri giochi (`flammerouge-f8669`, Realtime Database, accesso anonimo), radice
`fiveparsecs/campagne/<codice>` con `{nome, turno, aggiornato, uid, dati}` (lo stato completo è un testo JSON).
La regola è in `firebase/database.rules.json` (sezione `fiveparsecs`): **va pubblicata** sul progetto se le regole
attive non coprono già questa radice (Firebase console → Realtime Database → Regole).

## Font e simboli
Exo 2 (testi) e Oxanium (titoli), entrambi con licenza SIL Open Font License (`assets/fonts/OFL-*.txt`).
Nell'interfaccia non si usano simboli Unicode fuori dai font: `python3 tools/controlla_glifi.py` controlla ogni
carattere degli script e dei dati contro i due font (va eseguito prima di pubblicare).

## Prove
```
godot --headless --path . -s tests/test_regole.gd     # regole, tabelle, linea di vista, tiro, rissa, 20 battaglie automatiche
godot --headless --path . -s tests/sim_campagna.gd    # 6 campagne automatiche da 15 turni (tutte le difficoltà), salvataggio e ripresa
xvfb-run godot --path . -s tests/shot.gd              # screenshot di menu, creazione, campagna, battaglia
xvfb-run godot --path . -s tests/shot_mappe.gd        # il campo di battaglia in tutti gli ambienti
python3 tools/controlla_glifi.py                      # glifi
```

## Struttura
```
data/*.json                  tutte le tabelle del regolamento, tradotte (convenzioni in data/LEGGIMI_DATI.md)
data/note_*.md               note di trascrizione: dubbi e scelte interpretative tabella per tabella
scripts/core/dadi.gd         dadi ed espressioni (1d6, 2d6+1, 2d6_max...), tiri sulle tabelle
scripts/core/dati.gd         caricamento dei dati
scripts/core/personaggio.gd  personaggi: profilo, massimi, armi, tiri salvezza
scripts/core/campagna.gd     motore della campagna: creazione, turno, effetti delle tabelle, dopo la battaglia
scripts/core/battaglia.gd    battaglia su griglia: terreno, round, movimento, vista, tiro, rissa, morale, obiettivi
scripts/core/ia.gd           IA dei nemici (e dell'equipaggio in automatico)
scripts/net/                 Firebase e salvataggi
scripts/ui/                  interfaccia (menu, creazione, campagna, battaglia, regole, pedine, immagini)
tools/                       controllo dei glifi, pubblicazione su Cloudflare
```

## Scelte di questa versione (da verificare)
Le tabelle sono state trascritte dal PDF del regolamento (`5PH-Rulebook-210408T.pdf`); le note complete sono in
`data/note_*.md`. Le scelte principali:
- **Griglia**: distanza «a scacchiera» (diagonale = 1); una figura **adiacente** a un nemico è in contatto: lo attacca in
  rissa invece di sparargli. Respinta di 1 casella in direzione opposta all'attaccante.
- **Terreno difficile**: ogni casella costa 1,5 (1 pollice in più ogni 2). Gli ostacoli lineari contano come difficili
  da scavalcare. **Niente alture, arrampicate, salti e porte** per ora: il terreno è piatto.
- **Linea di vista**: linea tra i centri delle caselle; la bloccano edifici e altre figure; un'area (bosco, macerie) si vede
  dentro dal bordo ma non si attraversa; dentro la stessa area ci si vede entro 3 caselle. Copertura se la linea attraversa
  terreno a più di 1 casella da chi spara o se il bersaglio è in un'area.
- **Reazioni**: i dadi vengono assegnati in automatico per far agire più personaggi possibile nella fase rapida
  (con la regola del singolo 1 dei Feral).
- **Non ancora presenti**: fuoco di reazione (Snap Fire), fuoco nel panico, granate lanciate a mano su una casella, le
  regole speciali di molti nemici (sono mostrate nel testo ma non applicate), personaggi neutrali in battaglia.
- **Effetti delle tabelle**: crediti, punti Storia, Dicerie, Patroni, Rivali, XP, oggetti, scafo, debito, ferite e
  infermeria, prove con le statistiche e scelte sono automatici; gli effetti particolari (circa 90 voci) compaiono nel
  diario come «Regola da applicare a mano».
- **Individui Unici**: quando il libro dà solo modificatori rispetto al nemico base, si usa il profilo del nemico
  principale con quei modificatori.
- **Armi dei nemici**: codice «2B» = colonna Arma 2 per le figure base e colonna Specialista B per gli Specialisti
  (un tiro per gruppo); i nemici Aggressivi con Combattimento sopra +0 e i Luogotenenti hanno anche una Lama.
- **Prezzi**: il libro non dà prezzi per singole armi e oggetti: si compra un tiro su tabella per 3 crediti, e
  Pistola, Lama, Fucile coloniale e Fucile a pompa per 1 credito; si vende a 1 credito.
- **Soulless**: a p.17 possono installare potenziamenti da Bot a 1,5 volte il costo, a p.123 no: per ora seguono gli XP.
- **Sequestro della nave**: da 75 crediti di debito (p.76; a p.60 il libro dice «oltre 75»).
- **Paga**: ordine dei modificatori (miglior dado della Missione +1, Facile +1, 1-2 che valgono 3) non chiarito dal libro.
- **XP**: una sola voce tra vittima / sopravvissuto / sopravvissuto e vittorioso, più i bonus (confermato dall'esempio del libro).
- **Traccia della Storia e Zona Rossa/Nera**: dati completi in `data/storia.json` e `data/zone.json`; la battaglia
  usa il generatore normale e le regole speciali si applicano a mano.
- **Nomi dei mondi** inventati per il diario; i tratti del mondo vengono dalla tabella del regolamento.
