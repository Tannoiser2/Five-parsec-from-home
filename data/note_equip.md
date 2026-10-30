# Note su armi, equipaggiamento, nave e bottino

Fonti (pagine del PDF; tra parentesi la pagina stampata): 30-31 (28-29) tabelle di creazione, 33 (31) e 32 (30) Tabella delle navi e tratti, 51-60 (49-58) armi ed equipaggiamento, 61-64 (59-62) astronavi, 71 (69) viaggio, 78 (76) debito e riparazioni, 127 (125) acquisti, 133-136 (131-134) bottino, 106 (104) armi dei nemici, 187 (185) riepilogo armi.

## Scelte interpretative
- **Costi**: il libro non dà prezzi per armi e oggetti. Si compra un tiro su tabella Militare / Equipaggiamento / Gadget per 3 crediti; Pistola, Lama, Fucile coloniale e Fucile a pompa costano 1 credito l'una (p.125). Solo queste quattro armi hanno `costo`; gli oggetti non lo hanno. I costi delle bozze precedenti erano inventati e sono stati tolti. I Componenti della nave invece hanno il costo del libro.
- **Armi da Rissa**: `gittata` 0 e `colpi` 0 (nel libro "Brawl" e "-").
- **Granata accecante**: danno "NA" nel libro: scritto `danno: 0` più `danno_na: true` (col tratto Stordente non si tira il danno comunque).
- **Granate nel bottino**: la riga dà "3 Frakk Grenades" / "3 Dazzle grenades": `quantita: 3`. Le granate sono Monouso, quindi ogni copia è un uso.
- **Consumabili nel bottino**: "Consumables (2 uses)": `quantita: 2` sulla riga che rimanda alla sottotabella (si ottengono 2 dosi dello stesso consumabile).
- **Armi naturali dei nemici** (`zanne_artigli` +0, `zanne_grandi` +1, `artigli_possenti` +2, `disarmato`): non sono nella tabella delle armi, ma le tabelle dei nemici (p.101-109) danno "Claws/Fangs (Damage +N)". Le ho messe senza il tratto Mischia: il libro dà solo il Danno, e chi non ha armi da mischia colpisce con Danno +0 senza bonus (p.45). `artigli_possenti` è nuovo (per il Krorg, Claws +2). Le armi delle tabelle Enemy Weapons di p.106 (PDF) esistono tutte in `armi`.
- **Tipo "gadget"**: nel libro "Gadget" è solo il nome di una tabella di creazione; ogni oggetto ha il suo tipo vero (impianto, equip, nave, mod_arma, mirino, schermo...). Nessun oggetto ha tipo "gadget". I dispositivi di utilità (Utility devices, massimo 3 a testa) hanno tipo "equip"; gli oggetti di bordo (On-board items) hanno tipo "nave".
- **Mod e mirini**: sono sia in `equipaggiamento.json` (`oggetti`, per le tabelle) sia in `armi.json` (`mod_armi`, `mirini`), con gli stessi id e lo stesso contenuto (generati dalla stessa fonte). Se se ne cambia uno, va cambiato anche l'altro.
- **Lama d'assalto** (Assault blade): "Damage +1" l'ho letto come Danno +1 in Rissa (`danno_rissa`), perché la mod trasforma l'arma in arma da mischia; in teoria potrebbe valere anche per il tiro. Da decidere.
- **Bipode**: "+1 per colpire oltre 8\" quando si Mira o si spara dalla Copertura": basta una delle due condizioni.
- **Comunicatore**: nel libro è un dispositivo di utilità (dado in più nel tiro di Reazione), non +1 all'iniziativa come nella bozza.
- **Scanner bot**: compare sia nella tabella Equipaggiamento sia in quella Gadget: è lo stesso oggetto (id `scanner_bot`). Il bonus è all'iniziativa per tutto l'equipaggio.
- **Debito e sequestro**: p.60 dice "se il debito supera 75 crediti", p.76 dice "75 crediti o più". Ho seguito p.76 (`sequestro_soglia: 75`, si tira 2D6 e con 2-6 la nave è persa). Interessi: +1 se il debito è ≤30, +2 se ≥31, applicati dopo gli eventuali pagamenti.
- **Vendere la nave**: il libro non lo prevede. Ho scritto solo i rottami (relitto a terra 1D6+5 crediti; Componente rimosso: 1 credito ogni 5 del costo).
- **Fuga da un'invasione**: riassunta in `regole.fuga_invasione` perché i componenti Navetta e Torrette ci danno bonus; la regola completa è nella fase di viaggio (p.69).
- **Sostanza rara** (Rare Substance): "Tira 2D6, crediti pari al tiro più alto" = il dado più alto dei due: `crediti: "2d6_max"` (chiave nuova, documentata nel `_nota`).
- **Pezzi di nave**: `sconto_componente` (chiave nuova): il valore va tirato subito e si scala dal prossimo Componente.
- **Gittata delle granate**: il Braccio potenziato aumenta la gittata delle granate di 2" (granate Frakk e accecanti, 6").
- Ho usato `effetto` (singolare) negli oggetti e nei componenti, come nella bozza; nelle tabelle a dadi uso `effetti` come da LEGGIMI.

## Errori corretti rispetto alle bozze
- Tabelle armi: molte righe sbagliate (es. Militare 51-60 Fucile ad aghi, 61-75 Fucile automatico, 76-80 Mitragliatrice, 81-95 Sciabola, 96-100 Ascia; Alta tecnologia 86-100 Spada abbagliante).
- Statistiche: le bozze erano quasi tutte giuste (controllate una per una con p.50 e p.185); l'unico errore era l'Artiglio potenziato, che non è Perforante (solo Mischia e Goffa). I costi erano inventati.
- Testi dei tratti: Area colpisce entro 2" (non 1 casella), Impatto aggiunge un secondo Stordito solo se il bersaglio è già Stordito, Terrificante = ritirata di 1D6", Perforante ignora solo la corazza.
- Tabelle Equipaggiamento e Gadget e tutti gli oggetti riscritti dal libro (22 righe ciascuna).
- Tratti delle navi: i veri sono Propulsori d'emergenza, Basso consumo, Divora-carburante, Capriccioso, Dotazione standard, Corazzata, e solo 6 navi su 13 ne hanno uno.

## Id rinominati o rimossi
- Armi: id invariati. Aggiunto `artigli_possenti`.
- Oggetti mantenuti: `comunicatore`, `corazza_frag`, `corazza_combattimento`, `corazza_battaglia`, `schermo_deflettore`, `jump_belt`, `motion_tracker`, `scanner_bot`, `stim`, `booster`, `combat_serum`, `rage_out`, `visore_notturno` (ora è l'impianto Night sight), `medikit` (= Med-patch, oggetto di bordo), `kit_riparazione` (= Repair Bot, oggetto di bordo), `impianto_muscoli` (= Boosted arm), `impianto_gambe` (= Boosted leg), `impianto_riflessi` (= Neural optimization).
- Oggetti rimossi perché non esistono nel libro o erano confusi: `kit_assalto` (diventa la mod `lama_assalto`), `binocolo`, `set_da_viaggio`, `occhiali_visori`, `drone_combattimento`, `generatore_copertura` (il Screen generator è `generatore_schermo`), `schermo_flash` (il Flak screen è `schermo_flak`), `tuta_stealth` (diviso in `mantello_mimetico` = Camo cloak ed `equip_furtivo` = Stealth gear), `impianto_occhio`.
- Nave: i tratti delle navi hanno id nuovi (vedi sopra); `navi` ora è `{"_dado": "d100", "righe": [...]}` come le altre tabelle; `costo_viaggio` è passato in `parametri.costo_viaggio`.

## Dubbi aperti
- Il Bot scanner e il Rilevatore di movimento danno entrambi +1 all'iniziativa: per la regola "più oggetti diversi si sommano" in teoria si sommano.
- Tuta antirischio (Hazard suit): il tiro salvezza 5+ vale per i colpi dei rischi ambientali; non si capisce se si somma alla corazza (l'ho trattato come tiro salvezza separato).
- Cristalli Kiranin: "unable to act this round": li ho trattati come "non possono agire in questo round" (non come Storditi).
