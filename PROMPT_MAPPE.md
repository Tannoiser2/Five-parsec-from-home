# Prompt per le mappe (terreno della battaglia) di Five Parsecs from Home

Prompt per generare la grafica del **campo di battaglia su griglia**: plance e texture del suolo per ogni ambiente,
texture delle caselle di terreno difficile, elementi di terreno visti dall'alto e sovrapposizioni di visibilità.

Il campo è generato a caso dal gioco (`scripts/core/battaglia.gd`, Appendice II: 1 casella = 1 pollice, tavolo 24 x 24,
30 x 30 o 36 x 36 caselle), quindi **non servono mappe fisse**: servono i pezzi con cui il gioco le compone.
I tipi di casella del motore sono `APERTO`, `CAMPO` (fango, acqua), `AREA` (vegetazione, macerie), `BLOCCO` (edifici,
container, massi), `SINGOLO` (barili, alberi) e `LINEARE` (muretti, barricate); ogni voce indica a quale corrisponde.

Cartella: `assets/mappe/` (es. `assets/mappe/suolo_arido.png`, `assets/mappe/elementi/container.png`).


## Istruzioni per Codex

Questo file è pensato per essere eseguito da Codex (o da qualsiasi agente con generazione di immagini) dentro questo repository.

1. Leggi lo **stile comune** qui sotto e applicalo identico a **ogni** immagine del file: la serie deve sembrare dipinta dalla stessa mano.
2. Per ogni voce `### \`nome.png\`` genera un'immagine con il prompt indicato (stile comune + soggetto) e salvala esattamente in `assets/mappe/<nome>.png`.
3. Formato: vedi ogni sezione (texture 1024 x 1024 ripetibili, plance 2048 x 2048, elementi 1024 x 1024 o rettangolari). Sfondo: pieno per texture e plance, trasparente per elementi e sovrapposizioni (vedi punto 8).
4. Nessun testo, lettera, numero, logo o filigrana nelle immagini. Se un'immagine esce con scritte o con un'inquadratura diversa, rigenerala.
5. Non toccare le immagini già presenti nella cartella a meno che non venga chiesto: genera solo quelle mancanti.
6. Lavora per sezioni e fai un commit per sezione (es. `Immagini: armi da fuoco`), così è facile rivedere e scartare.
7. Alla fine elenca i file generati e quelli saltati o falliti.
8. **Sfondo trasparente** per gli elementi di terreno e le sovrapposizioni (sezioni D ed E): PNG con canale alfa, niente
   sfondo dipinto attorno all'oggetto. Per le texture e le plance (sezioni A, B, C) lo sfondo è pieno.
9. Le texture «seamless» devono ripetersi senza giunture visibili: controllale affiancando l'immagine a sé stessa 2 x 2
   e, se si vede la cucitura, correggila (offset di metà immagine e ritocco del centro) prima del commit.
10. Gli elementi vanno generati con le proporzioni indicate in caselle (es. 5 x 2 -> immagine 2560 x 1024 o 1536 x 640):
   l'oggetto deve riempire il rettangolo, perché il gioco lo stira sulle caselle che occupa.

### Integrazione nel gioco (solo se richiesta)
Oggi `scripts/ui/tavolo.gd` disegna il terreno con rettangoli e cerchi colorati. Per usare le immagini:
- caricatore come `pedine.gd` su `res://assets/mappe/` (poi `user://mappe/`), con cache e nessun errore se il file manca;
- ambiente della battaglia scelto dai tratti del mondo (Arido, Ghiacciato, Vegetazione rigogliosa, Cristalli, Zona di guerra;
  altrimenti `frontiera`, o `urbano` per gli Assalti), salvato nello stato della battaglia;
- se esiste `plancia_<ambiente>.png` disegnarla sotto tutto il tavolo, altrimenti ripetere `suolo_<ambiente>.png` casella per casella;
- caselle `CAMPO` con `campo_<ambiente>.png`;
- per ogni elemento in `Battaglia.elementi` disegnare `elementi/<nome>.png` sul rettangolo che racchiude le sue celle
  (elementi `AREA` ritagliati sulle loro celle; elementi `LINEARE` ripetendo il segmento casella per casella, ruotato di 90 gradi
  se verticale; «Deposito di casse» -> `cassa.png` per cella, «Barili» -> `barile.png`, «Alberi» -> `albero.png`);
- sovrapposizioni per Scarsa visibilità, Buio, Ambiente tossico e Banco di nebbia;
- se un'immagine manca, il tavolo si disegna come adesso. Griglia sempre sopra. Poi `tests/shot.gd` per controllare.


## Stile comune (uguale per tutte le immagini delle mappe)

```
Strictly top-down orthographic view (camera pointing straight down, no perspective, no horizon), for a grid-based sci-fi skirmish wargame battlefield where 1 grid square = 1 inch. Painterly digital illustration with a hand-painted miniature-terrain look, gritty 'frontier space western' mood, muted palette of dusty ochre, rust, slate blue and teal, soft light from the upper left with short soft shadows falling to the lower right. Readable at small size: clear shapes, moderate detail, no tiny clutter. No grid lines drawn, no text, no letters, no numbers, no logos, no watermark, no people, no creatures. Same scale, light direction and style for every image of the set.
```

Suggerimento: se un'immagine esce in prospettiva o con l'orizzonte, chiedi «strictly top-down orthographic, camera pointing straight down, same scale and light as the previous tiles».

## A. Texture del suolo, ripetibili (7) - caselle `APERTO`

1024 x 1024 px, ripetibili senza giunture; nell'immagine stanno circa 4 x 4 caselle di terreno (il gioco la scala di conseguenza).

### `suolo_frontiera.png` - Frontiera (standard)

Prompt: `Seamless tileable ground texture, dusty ochre frontier soil with scattered pebbles, dry grass tufts and tyre tracks, covering an area of about 4 by 4 inches. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

### `suolo_arido.png` - Arido (Barren)

Prompt: `Seamless tileable ground texture, cracked dry desert hardpan with sand drifts and bleached stones, covering an area of about 4 by 4 inches. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

### `suolo_ghiacciato.png` - Ghiacciato (Frozen)

Prompt: `Seamless tileable ground texture, frozen tundra: packed snow, blue-white ice patches and frosted gravel, covering an area of about 4 by 4 inches. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

### `suolo_rigoglioso.png` - Vegetazione rigogliosa (Overgrown)

Prompt: `Seamless tileable ground texture, lush alien jungle floor: moss, ferns, roots and teal-green alien grass, covering an area of about 4 by 4 inches. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

### `suolo_cristalli.png` - Cristalli (Crystals)

Prompt: `Seamless tileable ground texture, violet-grey rocky ground studded with small glowing crystal shards, covering an area of about 4 by 4 inches. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

### `suolo_zona_guerra.png` - Zona di guerra (Warzone)

Prompt: `Seamless tileable ground texture, scorched war-torn ground with craters, ash, spent shell casings and burnt debris, covering an area of about 4 by 4 inches. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

### `suolo_urbano.png` - Spazioporto / insediamento

Prompt: `Seamless tileable ground texture, cracked ferrocrete pavement of a frontier settlement with oil stains, drains and faded painted markings without letters, covering an area of about 4 by 4 inches. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

## B. Texture del terreno difficile, ripetibili (7) - caselle `CAMPO`

Stesso formato delle texture del suolo, nello stesso ambiente.

### `campo_frontiera.png` - Frontiera (standard): terreno difficile

Prompt: `Seamless tileable texture of a shallow muddy puddle with reeds, on dusty ochre frontier soil with scattered pebbles, dry grass tufts and tyre tracks ground. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

### `campo_arido.png` - Arido (Barren): terreno difficile

Prompt: `Seamless tileable texture of loose deep sand, on cracked dry desert hardpan with sand drifts and bleached stones ground. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

### `campo_ghiacciato.png` - Ghiacciato (Frozen): terreno difficile

Prompt: `Seamless tileable texture of thin cracked ice over dark water, on frozen tundra: packed snow, blue-white ice patches and frosted gravel ground. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

### `campo_rigoglioso.png` - Vegetazione rigogliosa (Overgrown): terreno difficile

Prompt: `Seamless tileable texture of a swampy bog with algae, on lush alien jungle floor: moss, ferns, roots and teal-green alien grass ground. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

### `campo_cristalli.png` - Cristalli (Crystals): terreno difficile

Prompt: `Seamless tileable texture of a pool of shimmering violet liquid, on violet-grey rocky ground studded with small glowing crystal shards ground. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

### `campo_zona_guerra.png` - Zona di guerra (Warzone): terreno difficile

Prompt: `Seamless tileable texture of a flooded shell crater with oily water, on scorched war-torn ground with craters, ash, spent shell casings and burnt debris ground. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

### `campo_urbano.png` - Spazioporto / insediamento: terreno difficile

Prompt: `Seamless tileable texture of a large spill of oily water and sludge, on cracked ferrocrete pavement of a frontier settlement with oil stains, drains and faded painted markings without letters ground. Use the common map style: strictly top-down, seamless tileable texture, no grid lines, no text.`

## C. Plance intere (7, facoltative)

2048 x 2048 px, quadrate, un unico fondo per tutto il tavolo (24 x 24 caselle) con più varietà delle texture ripetute. Solo suolo: niente edifici, alberi o ostacoli, che il gioco aggiunge da sé.

### `plancia_frontiera.png` - Frontiera (standard)

Prompt: `Square 2048x2048 battlefield base map, empty ground of dusty ochre frontier soil with scattered pebbles, dry grass tufts and tyre tracks, with gentle natural variation across the board, a few faint paths, no buildings, no trees, no obstacles. Use the common map style: strictly top-down, no grid lines, no text.`

### `plancia_arido.png` - Arido (Barren)

Prompt: `Square 2048x2048 battlefield base map, empty ground of cracked dry desert hardpan with sand drifts and bleached stones, with gentle natural variation across the board, a few faint paths, no buildings, no trees, no obstacles. Use the common map style: strictly top-down, no grid lines, no text.`

### `plancia_ghiacciato.png` - Ghiacciato (Frozen)

Prompt: `Square 2048x2048 battlefield base map, empty ground of frozen tundra: packed snow, blue-white ice patches and frosted gravel, with gentle natural variation across the board, a few faint paths, no buildings, no trees, no obstacles. Use the common map style: strictly top-down, no grid lines, no text.`

### `plancia_rigoglioso.png` - Vegetazione rigogliosa (Overgrown)

Prompt: `Square 2048x2048 battlefield base map, empty ground of lush alien jungle floor: moss, ferns, roots and teal-green alien grass, with gentle natural variation across the board, a few faint paths, no buildings, no trees, no obstacles. Use the common map style: strictly top-down, no grid lines, no text.`

### `plancia_cristalli.png` - Cristalli (Crystals)

Prompt: `Square 2048x2048 battlefield base map, empty ground of violet-grey rocky ground studded with small glowing crystal shards, with gentle natural variation across the board, a few faint paths, no buildings, no trees, no obstacles. Use the common map style: strictly top-down, no grid lines, no text.`

### `plancia_zona_guerra.png` - Zona di guerra (Warzone)

Prompt: `Square 2048x2048 battlefield base map, empty ground of scorched war-torn ground with craters, ash, spent shell casings and burnt debris, with gentle natural variation across the board, a few faint paths, no buildings, no trees, no obstacles. Use the common map style: strictly top-down, no grid lines, no text.`

### `plancia_urbano.png` - Spazioporto / insediamento

Prompt: `Square 2048x2048 battlefield base map, empty ground of cracked ferrocrete pavement of a frontier settlement with oil stains, drains and faded painted markings without letters, with gentle natural variation across the board, a few faint paths, no buildings, no trees, no obstacles. Use the common map style: strictly top-down, no grid lines, no text.`

## D. Elementi di terreno (20) - cartella `assets/mappe/elementi/`

Sfondo trasparente. Tra parentesi le caselle occupate e il tipo di casella del motore. Vanno bene per tutti gli ambienti (colori neutri).

### `elementi/edificio.png` - Edificio (4-5 x 3-4 caselle, `BLOCCO`)

Prompt: `Top-down terrain piece for a 4-5 x 3-4 grid squares footprint, the flat roof of a prefab frontier building: corrugated metal roof panels, a vent unit, an antenna, a hatch, rust streaks. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/edificio_grande.png` - Edificio grande (variante) (5 x 4 caselle, `BLOCCO`)

Prompt: `Top-down terrain piece for a 5 x 4 grid squares footprint, the roof of a larger warehouse with skylights, cooling fans and pipes. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/navetta_atterrata.png` - Navetta atterrata (5 x 2 caselle, `BLOCCO`)

Prompt: `Top-down terrain piece for a 5 x 2 grid squares footprint, a landed boxy cargo shuttle seen from above, stubby wings, scorched engine nozzles, open side ramp. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/container.png` - Container (1 x 3 caselle, `BLOCCO`)

Prompt: `Top-down terrain piece for a 1 x 3 grid squares footprint, a single long cargo container seen from above, ribbed metal, faded paint, no lettering. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/cassa.png` - Cassa (deposito di casse) (1 x 1 casella, `BLOCCO`)

Prompt: `Top-down terrain piece for a 1 x 1 grid square footprint, a single heavy cargo crate with metal reinforced corners. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/masso.png` - Masso (2 x 1-2 caselle, `BLOCCO`)

Prompt: `Top-down terrain piece for a 2 x 1-2 grid squares footprint, a large weathered boulder with cracks and lichen. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/rovine_muro.png` - Pezzo di muro delle rovine (1 x 1 casella, `BLOCCO`)

Prompt: `Top-down terrain piece for a 1 x 1 grid square footprint, a broken chunk of ruined concrete wall with exposed rebar. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/barile.png` - Barile (1 x 1 casella, `SINGOLO`)

Prompt: `Top-down terrain piece for a 1 x 1 grid square footprint, a single round fuel barrel seen from above, dented lid, rust ring. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/albero.png` - Albero (1 x 1 casella, `SINGOLO`)

Prompt: `Top-down terrain piece for a 1 x 1 grid square footprint, a single alien tree canopy seen from above, round crown of dark teal leaves. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/casse_navetta.png` - Casse della navetta (1 x 1 casella, `SINGOLO`)

Prompt: `Top-down terrain piece for a 1 x 1 grid square footprint, a small stack of two supply cases unloaded from a ship. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/bosco.png` - Bosco (area di raggio 4-6, `AREA`)

Prompt: `Top-down terrain piece for a area of radius 4-6 footprint, a dense patch of alien woodland: overlapping tree canopies and undergrowth with irregular soft edges. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/cespugli.png` - Cespugli (area di raggio 2, `AREA`)

Prompt: `Top-down terrain piece for a area of radius 2 footprint, a small cluster of scrubby bushes with irregular edges. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/rovine.png` - Rovine (macerie) (area di raggio 4, `AREA`)

Prompt: `Top-down terrain piece for a area of radius 4 footprint, a field of rubble, broken concrete slabs, bricks and twisted girders with irregular edges. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/vegetazione.png` - Vegetazione (tratto del mondo) (area di raggio 3, `AREA`)

Prompt: `Top-down terrain piece for a area of radius 3 footprint, a patch of tall alien grass and creeping vines with irregular edges. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/barricata.png` - Barricata (segmento di 1 casella, ripetibile, `LINEARE`)

Prompt: `Top-down terrain piece, one straight 1-square segment that tiles seamlessly end to end (left and right edges match), one straight segment of improvised barricade made of scrap plates and beams. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/recinzione.png` - Recinzione (segmento di 1 casella, ripetibile, `LINEARE`)

Prompt: `Top-down terrain piece, one straight 1-square segment that tiles seamlessly end to end (left and right edges match), one straight segment of chain-link fence with metal posts. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/muretto.png` - Muretto (segmento di 1 casella, ripetibile, `LINEARE`)

Prompt: `Top-down terrain piece, one straight 1-square segment that tiles seamlessly end to end (left and right edges match), one straight segment of a low stone-and-concrete wall. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/siepe.png` - Siepe (segmento di 1 casella, ripetibile, `LINEARE`)

Prompt: `Top-down terrain piece, one straight 1-square segment that tiles seamlessly end to end (left and right edges match), one straight segment of a thick alien hedge. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/sacchi_sabbia.png` - Sacchi di sabbia (segmento di 1 casella, ripetibile, `LINEARE`)

Prompt: `Top-down terrain piece, one straight 1-square segment that tiles seamlessly end to end (left and right edges match), one straight segment of stacked sandbags. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

### `elementi/muro_forza.png` - Muro di forza (Insta-muro) (segmento di 1 casella, ripetibile, `LINEARE`)

Prompt: `Top-down terrain piece, one straight 1-square segment that tiles seamlessly end to end (left and right edges match), one straight segment of a translucent glowing blue energy wall. Use the common map style: strictly top-down, isolated element on a transparent background, short soft shadow to the lower right, no text.`

## E. Sovrapposizioni di visibilità (4) - cartella `assets/mappe/sovrapposizioni/`

1024 x 1024 px, ripetibili, semitrasparenti: si stendono sopra il tavolo durante le condizioni e gli eventi corrispondenti.

### `sovrapposizioni/nebbia.png` - Nebbia / foschia

Prompt: `Top-down weather overlay texture, soft drifting white-grey fog wisps, semi-transparent, seamless tile. Use the common map style: strictly top-down, transparent background, no text.`

### `sovrapposizioni/buio.png` - Buio

Prompt: `Top-down weather overlay texture, a dark blue-black night overlay with a subtle soft noise, semi-transparent, seamless tile. Use the common map style: strictly top-down, transparent background, no text.`

### `sovrapposizioni/gas_tossico.png` - Ambiente tossico

Prompt: `Top-down weather overlay texture, drifting yellow-green toxic gas clouds, semi-transparent, seamless tile. Use the common map style: strictly top-down, transparent background, no text.`

### `sovrapposizioni/tempesta_polvere.png` - Scarsa visibilità

Prompt: `Top-down weather overlay texture, blowing ochre dust streaks, semi-transparent, seamless tile. Use the common map style: strictly top-down, transparent background, no text.`

---

Totale: 45 immagini (7 suoli, 7 terreni difficili, 7 plance facoltative, 20 elementi, 4 sovrapposizioni).
