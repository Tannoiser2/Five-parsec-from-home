# Note sulla trascrizione della creazione personaggi (file PDF 14-37)

Fonte: pagine stampate 12-35 (file PDF 14-37). Riscritti `specie.json` e `creazione.json`. Delle bozze ho tenuto solo la struttura, gli id delle specie già presenti e la lista `nomi`.

## Scelte strutturali
- `tipo_equipaggio`, `alieni_primari` e `personaggi_strani` ora sono nel formato `{"_dado":"d100","righe":[...]}` di LEGGIMI_DATI. Prima erano array semplici, quindi chi li legge deve usare `.righe`. Lo stesso vale per `background`, `motivazione`, `classe` e le tabelle di `dettagli_colore`.
- Nuove specie aggiunte rispetto alla bozza: `alieno_minore` (Minor Alien), `empatico` (Empath), `bio_potenziato` (Bio-upgrade). La tabella Strange Characters ha 18 voci: gli intervalli della bozza erano tutti sbagliati.
- La pedina di ogni specie ha lo stesso nome dell'id (es. `recluta_speranzosa`, non più `recluta`). La cartella `assets/pedine` oggi è vuota, quindi non si rompe niente.
- I riferimenti dalle specie alle righe di creazione (`background_fisso`, `motivazione_fissa`, `motivazione_extra`, `sostituzioni_classe`) usano il campo `en` della riga (es. `"Revenge"`, `"Lower Megacity Class"`).
- Ho tenuto `limiti_stat` e `costi_avanzamento` in creazione.json, verificati sulla Ability Increase Table di p.123. Ho aggiunto `fortuna_umani: 3`.
- `fortuna_max` per specie vale 3 per gli Umani e per i personaggi strani che sono Umani (gene-mod, "As Baseline Human": Passato misterioso, Stalker, Hulker, Recluta, Elevato genetico, Mutante, Primitivo, Feeler, Empatico, Bio-potenziato). Vale 1 per gli alieni (Hakshan, Manipolatore, Alieno minore, Viaggiatore, De-convertito, Agente Unity) e 0 per Bot, Bot d'assalto ed Emo-soppresso. **Interpretazione mia**: il libro dice solo che "gli Umani" possono superare 1 punto di Fortuna. Quali personaggi strani contino come Umani, e se il Viaggiatore o l'Agente Unity lo siano, non è detto.

## Dubbi e ambiguità del testo
- **Soulless e i potenziamenti da Bot**: p.17 dice che possono installarli pagando 1,5 volte il costo. p.123 dice "Soulless use the normal XP process and cannot buy Bot upgrades". Ho seguito p.17 (`upgrade_bot_moltiplicatore: 1.5`) e ho segnalato il conflitto nel testo delle regole. Decidete voi quale prevale (p.123 sembra un'errata più recente).
- **Bot d'assalto**: "Savvy is +0, and cannot be upgraded" può voler dire che non si migliora l'Acume oppure che non si migliora il Bot intero. Ho scelto la prima lettura (`acume_bloccato`) e gli lascio `upgrade_crediti` per le altre caratteristiche.
- **Hulker**: il profilo ha Combattimento +1, ma quando spara vale sempre +0. Quindi il +1 conta solo in Rissa. Chiave `combattimento_tiro_fisso: 0`.
- **Hakshan**: "oltre ai normali tiri... hai automaticamente la motivazione Verità". L'ho letto così: si tira la Motivazione normalmente e in più si ottiene Verità con i suoi benefici (`motivazione_extra`). Non è chiaro se i benefici di Verità (1 Diceria, +1 punto Storia) vadano applicati. Io presumo di sì.
- **Motivazione/Background fissi** (De-convertito, Agente Unity, Mutante, Manipolatore, Primitivo, Emo-soppresso, Viaggiatore): presumo che si applichino anche gli effetti della riga fissata (es. Vendetta dà +2 XP e un Rivale). Il libro dice solo "do not roll on the relevant table".
- **Mutante**: il testo dice "Lower classes of megacity". Ho collegato la riga Background "Lower Megacity Class" (35-39).
- **Alieno minore e Bio-potenziato**: la riduzione dei crediti bonus (-1 o -2) si applica "all'aumento finale". Non è chiaro se vada per ogni tabella o sul totale delle tre. Per l'Alieno minore vale anche per i punti Storia. Il valore minimo presumibile è 0.
- **Elevato genetico**: si ignorano solo i crediti del *Background*, non quelli di Motivazione e Classe. Il Rivale extra è nei `bonus` (`rivale: 1`).
- **Passato misterioso**: i punti Storia ignorati sono solo quelli bonus delle tre tabelle. Tira 2 Background.
- **Viaggiatore**: "+2 story points e 2 Quest Rumors" all'inizio sono nei `bonus` (`punti_storia`, `dicerie`), non in `effetti`. Il motore deve applicarli alla creazione.
- **Recluta speranzosa**: "Begin with 1 Luck". Non è chiaro se si sommi al punto Fortuna del Leader. Presumo di sì, entro il massimo di 3 per gli Umani.
- **Classe operaia**: "+1 Luck" l'ho messo come `stat.fortuna: 1`. Per un alieno non umano supera comunque il limite di 1 solo se ha già Fortuna (es. se è Leader). Il motore deve applicare il tetto `fortuna_max`.
- "Rumor" nelle tabelle equivale a Quest Rumor, cioè `dicerie` (p.36 lo conferma).
- **Punti Storia iniziali**: non sono in queste pagine. Si decidono nella preparazione della campagna (p.63 e seguenti, fuori dal mio blocco). L'esempio dice solo "aggiungerò un punto Storia al mio tiro".
- Nella tabella Gear (p.29) "Scanner bot" compare sia tra il Gear (86-89) sia tra i Gadget (56-60). Probabilmente è un refuso del libro, da controllare da chi trascrive l'equipaggiamento. Nella tabella High-tech compare "Infantry laser" (46-55), che è anche un'arma militare.

## Regole non automatizzabili (solo testo)
- Swift: planata, salto di varchi, caduta senza danni. Le chiavi esistono, ma servono regole di altezza in battaglia.
- Agente Unity: "Chiedere un favore" (2D6 a ogni turno di campagna, scelta tra 3 opzioni, viaggio obbligato con 2-4).
- Viaggiatore: tiro 2D6 dopo la battaglia (sparizione o Missione).
- Feeler: lascia l'equipaggio se litiga con un compagno. Emo-soppresso: può ignorare gli eventi di lite.
- Manipolatore: 1D6 per ogni punto Storia guadagnato. Ogni 6 dà un punto in più, senza tiri a catena.
- Leader: non lascia mai l'equipaggio per eventi casuali.
- Patroni e Rivali iniziali: vanno generati nel primo turno (Patrono locale) e sulla tabella Rivali sconosciuti (p.94).
- `dettagli_colore`: puro colore, nessun effetto.
