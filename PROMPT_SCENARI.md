# Prompt per le illustrazioni degli scenari di Five Parsecs from Home

Prompt per generare le illustrazioni delle **schede di missione**: tipi di battaglia, obiettivi, condizioni di schieramento,
luoghi notevoli, eventi della battaglia e Zone Rossa/Nera. Si mostrano nella schermata di preparazione della battaglia e nei
riquadri degli eventi. I nomi dei file derivano dagli `id` e dai nomi in `data/incontri.json`.

Cartella: `assets/scenari/` (es. `assets/scenari/obiettivo_accedere.png`).


## Istruzioni per Codex

Questo file è pensato per essere eseguito da Codex (o da qualsiasi agente con generazione di immagini) dentro questo repository.

1. Leggi lo **stile comune** qui sotto e applicalo identico a **ogni** immagine del file: la serie deve sembrare dipinta dalla stessa mano.
2. Per ogni voce `### \`nome.png\`` genera un'immagine con il prompt indicato (stile comune + soggetto) e salvala esattamente in `assets/scenari/<nome>.png`.
3. Formato: orizzontale 3:2, 1536 x 1024 px. Sfondo: pieno, come descritto nello stile comune.
4. Nessun testo, lettera, numero, logo o filigrana nelle immagini. Se un'immagine esce con scritte o con un'inquadratura diversa, rigenerala.
5. Non toccare le immagini già presenti nella cartella a meno che non venga chiesto: genera solo quelle mancanti.
6. Lavora per sezioni e fai un commit per sezione (es. `Immagini: armi da fuoco`), così è facile rivedere e scartare.
7. Alla fine elenca i file generati e quelli saltati o falliti.

### Integrazione nel gioco (solo se richiesta)
Oggi la preparazione della battaglia è solo testo. Per usarle: caricatore come `pedine.gd` su `res://assets/scenari/`
(poi `user://scenari/`); nella schermata di preparazione mostrare in alto `battaglia_<tipo>.png`, e accanto all'obiettivo
`obiettivo_<id>.png`; la condizione di schieramento e il luogo notevole come miniature; l'evento della battaglia nel
riquadro che lo annuncia. Il nome del file di condizioni, luoghi ed eventi è il nome italiano ridotto in minuscolo senza
accenti, con `_` al posto di spazi e punteggiatura (es. «Scarsa visibilità» -> `condizione_scarsa_visibilita.png`).
Se l'immagine manca, si mostra solo il testo, come adesso.


## Stile comune (uguale per tutte le illustrazioni)

```
Landscape 3:2 image, 1536x1024. A cinematic illustration for a sci-fi skirmish wargame mission briefing card. Painterly digital illustration, gritty 'frontier space western' mood on a remote colony world: dusty frontier settlements, prefab buildings, cargo containers, rocky badlands, a pale sky with a large ringed planet. Muted palette of dusty ochre, rust, slate blue and teal with warm rim light. Small, distant figures seen from a low three-quarter angle; no close-up faces. Strong readable composition with one clear focal point in the centre, darker edges (vignette) so that the game can lay text over the bottom third. No text, no letters, no numbers, no logos, no watermark, no UI elements. Same style, lighting and colour grading for every illustration of the set.
```

Suggerimento: se un'illustrazione esce con scritte o con volti in primo piano, chiedi «same style as the previous briefing images, no text, small distant figures, vignette».

## Tipi di battaglia (5)

### `battaglia_patrono.png` - Battaglia per un Patrono

Prompt: `Mission briefing illustration, a small mercenary crew receiving a job from a well-dressed patron in a smoky spaceport office, a holographic map between them, the crew's ship visible through a window. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `battaglia_rivale.png` - Battaglia contro un Rivale

Prompt: `Mission briefing illustration, a tense standoff in a dusty street at sunset, the crew facing a rival gang across the road, long shadows, wanted-poster atmosphere. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `battaglia_missione.png` - Missione (Quest)

Prompt: `Mission briefing illustration, the crew following an old map to a half-buried alien ruin under a dramatic sky, a beam of light from the ruin. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `battaglia_opportunita.png` - Missione d'opportunità

Prompt: `Mission briefing illustration, the crew walking through a crowded frontier market at dusk, a hooded contact whispering a tip, neon lamps and stalls. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `battaglia_invasione.png` - Battaglia d'invasione

Prompt: `Mission briefing illustration, a colony under alien invasion, landing pods falling from a burning sky, colonists fleeing while the crew holds a barricade. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

## Obiettivi della missione (17)

### `obiettivo_accedere.png` - Accedere (Access)

Prompt: `Mission briefing illustration, a crew member hacking a glowing console in the middle of a ruined courtyard while comrades cover. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_acquisire.png` - Acquisire (Acquire)

Prompt: `Mission briefing illustration, a crew member grabbing a glowing sealed case from the centre of a battlefield under fire. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_difendere.png` - Difendere (Defend)

Prompt: `Mission briefing illustration, the crew holding a defensive line behind sandbags in front of a colony building, enemies advancing. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_consegnare.png` - Consegnare (Deliver)

Prompt: `Mission briefing illustration, a crew member running with a heavy cargo package towards a marked drop point at the centre of the battlefield. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_eliminare.png` - Eliminare (Eliminate)

Prompt: `Mission briefing illustration, a single enemy target in a long coat surrounded by bodyguards, seen through a sniper scope circle. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_respingere.png` - Respingere (Fight Off)

Prompt: `Mission briefing illustration, a chaotic firefight in a scrapyard, both sides exchanging shots across crates. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_attraversare.png` - Attraversare (Move Through)

Prompt: `Mission briefing illustration, the crew sprinting across a dangerous open valley towards the far edge, enemies on the ridges. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_pattugliare.png` - Pattugliare (Patrol)

Prompt: `Mission briefing illustration, the crew patrolling between three large landmarks (a water tower, a crashed shuttle, a rock spire), flashlights on. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_proteggere.png` - Proteggere (Protect)

Prompt: `Mission briefing illustration, the crew escorting a nervous unarmed VIP in a fine coat through a hostile street, shields raised. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_assicurare.png` - Assicurare (Secure)

Prompt: `Mission briefing illustration, the crew taking and holding a central plaza around a beacon, enemies closing in. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_perquisire.png` - Perquisire (Search)

Prompt: `Mission briefing illustration, crew members searching crates, wrecks and buildings across the battlefield for hidden cargo. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_imboscata.png` - Imboscata (Ambush)

Prompt: `Mission briefing illustration, enemies springing an ambush from rooftops and alleys on a surprised crew. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_rinforzi_amici.png` - Ha portato gli amici (Brought friends)

Prompt: `Mission briefing illustration, a rival leader arriving with extra armed friends stepping out of a dropship. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_resa_dei_conti.png` - Resa dei conti (Showdown)

Prompt: `Mission briefing illustration, a classic showdown, two groups facing each other in a wide empty square. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_assalto.png` - Assalto (Assault)

Prompt: `Mission briefing illustration, the crew barricaded inside a damaged building, enemies storming the doors. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_incursione.png` - Incursione (Raid)

Prompt: `Mission briefing illustration, enemies raiding the crew's landed starship on a landing pad, sparks and smoke from the hull. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `obiettivo_invasione.png` - Battaglia d'invasione (Invasion Battle)

Prompt: `Mission briefing illustration, a desperate last stand among burning colony domes while the galactic war rages in the sky. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

## Condizioni di schieramento (10)

«Nessuna condizione» non ha immagine.

### `condizione_scontro_ridotto.png` - Scontro ridotto (Small encounter)

Prompt: `Mission briefing illustration, a smaller-than-usual skirmish, a crew one member short, an empty space at the campfire. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `condizione_scarsa_visibilita.png` - Scarsa visibilità (Poor visibility)

Prompt: `Mission briefing illustration, a battlefield swallowed by thick dust storm, silhouettes barely visible. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `condizione_scontro_breve.png` - Scontro breve (Brief engagement)

Prompt: `Mission briefing illustration, a firefight with a countdown feeling, an alarm beacon flashing and sirens approaching. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `condizione_ambiente_tossico.png` - Ambiente tossico (Toxic environment)

Prompt: `Mission briefing illustration, a battlefield in toxic yellow-green gas clouds, leaking chemical tanks. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `condizione_incontro_a_sorpresa.png` - Incontro a sorpresa (Surprise encounter)

Prompt: `Mission briefing illustration, enemies caught completely off guard at their camp, eating around a fire. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `condizione_in_ritardo.png` - In ritardo (Delayed)

Prompt: `Mission briefing illustration, two crew members running late, arriving from a distant transport while the fight already started. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `condizione_terreno_scivoloso.png` - Terreno scivoloso (Slippery ground)

Prompt: `Mission briefing illustration, a battlefield of slick mud and oil puddles, figures slipping. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `condizione_lotta_accanita.png` - Lotta accanita (Bitter struggle)

Prompt: `Mission briefing illustration, grim, determined enemies refusing to back down, bandaged but still fighting. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `condizione_colti_alla_sprovvista.png` - Colti alla sprovvista (Caught off guard)

Prompt: `Mission briefing illustration, the crew surprised and scrambling for weapons as enemies appear. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `condizione_buio.png` - Buio (Gloomy)

Prompt: `Mission briefing illustration, a pitch-dark night battle lit only by muzzle flashes and torch beams. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

## Luoghi notevoli (8)

«Niente di speciale» non ha immagine. Sono illustrazioni; la pedina sul campo resta `segnalino_luogo.png` di PROMPT_PEDINE.md.

### `luogo_documentazione.png` - Documentazione (Documentation)

Prompt: `Mission briefing illustration, close view of a scattered pile of data pads and files glowing on a desk in a wrecked office. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `luogo_bersaglio_prioritario.png` - Bersaglio prioritario (Priority target)

Prompt: `Mission briefing illustration, close view of an important enemy figure marked by a targeting reticle of light. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `luogo_deposito_di_bottino.png` - Deposito di bottino (Loot cache)

Prompt: `Mission briefing illustration, close view of a hidden cache of weapons and supplies under a tarp. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `luogo_pezzi_luccicanti.png` - Pezzi luccicanti (Shiny bits)

Prompt: `Mission briefing illustration, close view of glinting salvage scattered on the ground, catching the light. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `luogo_pezzi_molto_luccicanti.png` - Pezzi molto luccicanti (Really shiny bits)

Prompt: `Mission briefing illustration, close view of a pile of very valuable glittering tech salvage, intense glints. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `luogo_persona_d_interesse.png` - Persona d'interesse (Person of interest)

Prompt: `Mission briefing illustration, close view of a mysterious hooded civilian hiding behind crates, waiting to be found. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `luogo_oggetto_singolare.png` - Oggetto singolare (Peculiar item)

Prompt: `Mission briefing illustration, close view of a peculiar alien object pulsing with odd light on a stone pedestal. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `luogo_oggetto_curioso.png` - Oggetto curioso (Curious item)

Prompt: `Mission briefing illustration, close view of a curious sealed container with unknown symbols-like patterns (no letters), half buried. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

## Eventi della battaglia (24, facoltativi)

### `evento_sforzi_rinnovati.png` - Sforzi rinnovati (Renewed efforts)

Prompt: `Battle event illustration, enemies regrouping and charging again with renewed energy. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_rinforzi_nemici.png` - Rinforzi nemici (Enemy reinforcements)

Prompt: `Battle event illustration, enemy reinforcements arriving from the battlefield edge. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_cambio_di_piani.png` - Cambio di piani (Change of plans)

Prompt: `Battle event illustration, an enemy leader shouting orders and pointing in a new direction. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_scoraggiati.png` - Scoraggiati (Lost heart)

Prompt: `Battle event illustration, a demoralised enemy throwing down a weapon and fleeing. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_colto_il_momento.png` - Colto il momento (Seized the moment)

Prompt: `Battle event illustration, a crew member seizing the moment, leaping forward heroically. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_bestiacce.png` - Bestiacce! (Critters!)

Prompt: `Battle event illustration, small vicious alien critters bursting out of the undergrowth. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_guasto_alle_munizioni.png` - Guasto alle munizioni (Ammo fault)

Prompt: `Battle event illustration, a jammed weapon smoking, a frustrated shooter. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_cambio_di_visibilita.png` - Cambio di visibilità (Visibility change)

Prompt: `Battle event illustration, a sudden change of light, clouds covering the sun over a battlefield. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_piu_duro_del_previsto.png` - Più duro del previsto (Tougher than expected)

Prompt: `Battle event illustration, a tough enemy shrugging off a hit and still advancing. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_tiro_istintivo.png` - Tiro istintivo (Snap shot)

Prompt: `Battle event illustration, a lightning-fast snap shot, a muzzle flash frozen in time. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_piano_astuto.png` - Piano astuto (Cunning plan)

Prompt: `Battle event illustration, an enemy flanking manoeuvre seen from above as glowing arrows-like dust trails (no symbols). Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_possibili_rinforzi.png` - Possibili rinforzi (Possible reinforcements)

Prompt: `Battle event illustration, distant dust clouds of vehicles approaching on the horizon. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_il_tempo_sta_per_scadere.png` - Il tempo sta per scadere (Clock is running out)

Prompt: `Battle event illustration, a ticking timer device with flashing lights on a crate. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_rischio_ambientale.png` - Rischio ambientale (Environmental hazard)

Prompt: `Battle event illustration, an explosion of a fuel tank, fire and debris on the battlefield. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_un_piano_disperato.png` - Un piano disperato (A desperate plan)

Prompt: `Battle event illustration, a crew member preparing a risky improvised explosive. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_un_momento_di_esitazione.png` - Un momento di esitazione (A moment of hesitation)

Prompt: `Battle event illustration, an enemy hesitating, weapon lowered, unsure. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_granata_sfuggita.png` - Granata sfuggita (Fumbled grenade)

Prompt: `Battle event illustration, a grenade bouncing out of a clumsy enemy's hand. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_rinforzi.png` - Rinforzi (Back up)

Prompt: `Battle event illustration, friendly backup arriving: a couple of armed allies jumping out of a vehicle. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_vip_nemico.png` - VIP nemico (Enemy VIP)

Prompt: `Battle event illustration, an enemy VIP in fine clothes appearing on the battlefield guarded by goons. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_banco_di_nebbia.png` - Banco di nebbia (Fog cloud)

Prompt: `Battle event illustration, a thick bank of fog rolling over the battlefield. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_perso.png` - Perso! (Lost!)

Prompt: `Battle event illustration, a lost crew member wandering in confusing ruins. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_ho_trovato_qualcosa.png` - Ho trovato qualcosa! (I found something!)

Prompt: `Battle event illustration, a crew member lifting a strange glowing item from rubble. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_sembra_prezioso.png` - Sembra prezioso (Looks valuable)

Prompt: `Battle event illustration, a glittering valuable object spotted in the distance. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `evento_vuoi_che_vada_a_controllare.png` - Vuoi che vada a controllare? (You want me to check that out?)

Prompt: `Battle event illustration, a crew member pointing at a suspicious door, asking to check it out. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

## Zone speciali (2)

### `zona_rossa.png` - Zona Rossa (Red Zone)

Prompt: `Mission briefing illustration, a heavily contested war-torn region, burnt-out vehicles, red warning lights, enemy patrols everywhere. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

### `zona_nera.png` - Zona Nera (Black Zone)

Prompt: `Mission briefing illustration, a top-secret black-ops mission in an abandoned high-tech facility, darkness and red emergency lights. Use the common briefing style: cinematic 3:2, frontier space western, vignette, no text.`

---

Totale: 66 illustrazioni (5 tipi di battaglia, 17 obiettivi, 10 condizioni, 8 luoghi notevoli, 24 eventi facoltativi, 2 zone).
