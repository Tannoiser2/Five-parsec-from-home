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
- **Battaglia su griglia** (Appendice II, 1 casella = 1 pollice), allineata ai capitoli Azioni, Movimento, Terreno, Combattimento
  e Round di battaglia (p.37-48, 112-117):
  - **Terreno**: lineari (si scavalcano con 1" in più e danno copertura), singoli (non bloccano la vista, danno copertura),
    aree (difficili, la vista si ferma al bordo), campi (fango, acqua, pozze tossiche invalicabili), **blocchi con altezza**
    (massi, container, edifici chiusi: si scalano pagando l'altezza, si salta giù, si saltano i varchi) ed **edifici con
    interno** (muri, porte da aprire con 1", finestre da attraversare con 2"). Linea di vista in 2,5D: da un tetto si vede
    oltre i muretti; il bersaglio più in alto ha copertura. Tratti del mondo sul tavolo (vegetazione, zona di guerra,
    cristalli, ghiaccio con la scivolata).
  - **Round**: barra delle 5 fasi (Reazioni, Azioni rapide, Azioni nemiche, Azioni lente, Fine round), **dadi delle reazioni
    assegnati dal giocatore** (con l'assegnazione consigliata e la regola del singolo 1 dei Feral), Prendere l'iniziativa,
    **Snap Fire** e rinvio alla fase lenta.
  - **Azioni** del personaggio selezionato, divise in Movimento (muovi, scatta, salta giù, teletrasporto, cintura a reazione,
    hoverboard, dislocatore, planata degli Swift, scivolata), Azione di combattimento (spara **con l'arma scelta**,
    **fuoco nel panico**, Rissa, granate e armi ad area con il tiro 5+ se ci sono alleati vicini, bot di distrazione,
    insta-muro, multitaglio, rampino, azioni di obiettivo) e **Azioni gratuite** (consumabili, distorsore temporale,
    lama nascosta, impianto muscolare; la seconda costa l'azione di combattimento).
  - **Combattimento**: soglie 3+/5+/6+, mira (si ritirano gli 1), bersaglio obbligato entro 3", raffiche e cambio di
    bersaglio, tratti delle armi, **mod e mirini**, impianti ed equipaggiamento (schermi, corazze, mantello mimetico,
    emettitore sonico...), Rissa con **due avversari**, superiorità numerica, avversari storditi, **mossa di 2" dopo aver
    eliminato l'avversario**, mai a contatto dopo una Rissa, danni con spinta di 1" per colpo, tiri salvezza multipli,
    **Fortuna** (balzo di 1D6"), stimolanti, 3 segnalini Stordito = fuori combattimento, morale e fuga.
  - **Regole speciali di tutti i nemici** e delle specie (K'Erin, Swift, Feral, Hulker, Manipolatore, Primitivo...),
    tutti i 24 **eventi della battaglia** e tutte le **condizioni di schieramento** applicati in automatico.
  - **IA dei nemici** secondo i comportamenti del regolamento: Aggressivo, Cauto, Tattico, Difensivo, Furia, Bestia,
    Guardiano (scatto solo se non possono sparare, i Pesanti restano fermi, mirano dalla copertura...).
  Si può giocare a mano, far finire la battaglia all'IA o risolverla in automatico.
- **Dopo la battaglia**: Rivali, Patroni, progresso della Missione, paga, ritrovamenti, Invasione, bottino con tutte le
  sottotabelle, ferite (anche dei Bot), esperienza e miglioramenti, addestramento avanzato, acquisti e vendite, eventi
  della campagna e del personaggio, guerra galattica.
- **Traccia della Storia** (Appendice V, facoltativa): orologio, effetti del turno, le **7 battaglie della storia** con le loro
  regole (imboscata a 12", sabotaggio con IA D*, contrattacco con due gruppi e morale per gruppo, rapimento con i segnalini
  e gli Indizi, infiltrazione con sentinelle e prigioniero, complesso della nemesi), esiti e finale.
- **Zona Rossa e Zona Nera** (Appendice III): licenza, viaggio verso un mondo in Zona Rossa, condizione di minaccia,
  opposizione aumentata, vincolo di tempo al round 6, ricompense migliorate; Lavori Neri con squadre attive e passive,
  le 5 missioni, evacuazione e ricompense dell'Unità.
- **Voci delle tabelle della campagna** che prima andavano applicate a mano ora sono automatiche o diventano scelte
  (nave di pattuglia, archivio dati, merci di scambio, nuovo capo, rissa con un compagno, fisco, nemesi...).
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
godot --headless --path . -s tests/test_regole.gd     # regole, tabelle, battaglia (altezze, edifici, reazioni, Snap Fire,
                                                      # panico, rissa), tutti gli eventi, condizioni e nemici, Zona Rossa/Nera,
                                                      # le 7 battaglie della Storia, le voci speciali della campagna
godot --headless --path . -s tests/sim_campagna.gd    # 6 campagne automatiche da 15 turni (tutte le difficoltà), salvataggio e ripresa
xvfb-run godot --path . -s tests/shot.gd              # screenshot di menu, creazione, campagna, battaglia
xvfb-run godot --path . -s tests/shot_speciali.gd     # screenshot delle battaglie della Zona Nera e della Storia
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
- **Griglia**: distanza «a scacchiera» (diagonale = 1); una figura **adiacente** a un nemico è in contatto. Muoversi a
  contatto avvia subito la Rissa (p.41); con lo scatto non si entra in contatto. Le figure amiche si attraversano.
- **Terreno difficile**: ogni casella costa 1,5 (1 pollice in più ogni 2). Le caselle degli ostacoli lineari si scavalcano
  (+1") ma non ci si ferma sopra; le finestre si attraversano (+2") ma non ci si ferma dentro.
- **Altezze convenzionali**: muretti 1", barili e alberi 2" (solo copertura), aree 2", muri degli edifici 3" con tetto;
  le figure guardano da 1" sopra la superficie su cui stanno. Da 2" più in alto del bersaglio i muretti non danno copertura.
- **Mod e mirini** si considerano montati sull'arma da tiro principale che li accetta (la campagna non ha ancora una
  schermata per montarli su un'arma precisa).
- **Mano cibernetica**: integra la pistola migliore del personaggio.
- **Snap Fire**: chi resta in attesa spara al primo nemico che si muove nella sua vista e a gittata.
- **Lama nascosta**: si lancia con le soglie normali (3+ entro 6", 5+ in copertura), Danno +0.
- **Area**: dopo i colpi sul bersaglio, un colpo bonus con tiro per colpire contro ogni figura entro 2".
- **Rinforzi consistenti** (Zona Rossa): il libro non dice quanti nemici arrivano dal bordo avversario: se ne usano 2.
- **Lotta accanita**: «Morale nemico +1» è applicato riducendo di 1 il limite superiore del Panico.
- **Licenza della Zona Rossa**: lo sconto del Broker (-2 crediti) è previsto, ma nelle tabelle di questa edizione non c'è
  una classe Broker, quindi in pratica costa sempre 15.
- **Nano-doc**: si usa automaticamente sulla prima vittima della battaglia.
- **Nave di pattuglia**: si confiscano prima gli oggetti del Deposito, poi quelli dell'equipaggio.
- **Questo posto è proprio carino**: se ci sono punti Storia se ne spende uno automaticamente per far ripartire il personaggio.
- **Merci di scambio**: si vendono al primo mondo in cui valgono 4+ crediti.
- **Traccia della Storia**: in «Sabotare il piano» i bonus all'iniziativa (+2 se si è vinto l'Evento 2, +3 se si è catturato
  un mercenario) non si sommano: vale il più alto. Gli effetti del turno della storia applicati sono: niente attacchi
  dei Rivali, niente Rintracciare, niente Patroni; il resto è descritto nel diario. Nel «Rapimento» e in «Stiamo arrivando»
  l'equipaggio parte dal proprio bordo invece di entrare durante il round 1.
- **Zona Nera**: il campo è di 30 x 30 caselle per far posto alle squadre.
- **Soulless**: a p.17 possono installare potenziamenti da Bot a 1,5 volte il costo, a p.123 no: per ora seguono gli XP.
- **Sequestro della nave**: da 75 crediti di debito (p.76; a p.60 il libro dice «oltre 75»).
- **Paga**: ordine dei modificatori (miglior dado della Missione +1, Facile +1, 1-2 che valgono 3) non chiarito dal libro.
- **XP**: una sola voce tra vittima / sopravvissuto / sopravvissuto e vittorioso, più i bonus (confermato dall'esempio del libro).
- **Nomi dei mondi** inventati per il diario; i tratti del mondo vengono dalla tabella del regolamento.
