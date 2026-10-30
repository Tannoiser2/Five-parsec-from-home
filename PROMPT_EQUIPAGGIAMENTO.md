# Prompt per le icone dell'equipaggiamento di Five Parsecs from Home

Prompt per generare le icone di **tutte le armi, modifiche, mirini e oggetti** del gioco (114 immagini), da mostrare
nelle schede dei personaggi, nel deposito, nel bottino e nei negozi. I nomi dei file coincidono con gli `id` dei dati
(`data/armi.json`, `data/equipaggiamento.json`), così il gioco può trovarle senza tabelle di corrispondenza.

Cartella: `assets/oggetti/` (es. `assets/oggetti/fucile_plasma.png`).


## Istruzioni per Codex

Questo file è pensato per essere eseguito da Codex (o da qualsiasi agente con generazione di immagini) dentro questo repository.

1. Leggi lo **stile comune** qui sotto e applicalo identico a **ogni** immagine del file: la serie deve sembrare dipinta dalla stessa mano.
2. Per ogni voce `### \`nome.png\`` genera un'immagine con il prompt indicato (stile comune + soggetto) e salvala esattamente in `assets/oggetti/<nome>.png`.
3. Formato: quadrato 1:1, 1024 x 1024 px (vanno bene anche 512 x 512). Sfondo: pieno, come descritto nello stile comune.
4. Nessun testo, lettera, numero, logo o filigrana nelle immagini. Se un'immagine esce con scritte o con un'inquadratura diversa, rigenerala.
5. Non toccare le immagini già presenti nella cartella a meno che non venga chiesto: genera solo quelle mancanti.
6. Lavora per sezioni e fai un commit per sezione (es. `Immagini: armi da fuoco`), così è facile rivedere e scartare.
7. Alla fine elenca i file generati e quelli saltati o falliti.

### Integrazione nel gioco (solo se richiesta)
Oggi il gioco non mostra icone degli oggetti. Per usarle: aggiungere in `scripts/ui/` un caricatore uguale a `pedine.gd`
(cerca `res://assets/oggetti/<id>.png`, poi `user://oggetti/<id>.png`, cache, nessun errore se manca) e mostrare l'icona
accanto al nome dell'oggetto nella scheda del personaggio, nel deposito e nella schermata del bottino. Se l'icona manca
si mostra solo il testo, come adesso. Eseguire poi `python3 tools/controlla_glifi.py` e i test.


## Stile comune (uguale per tutte le icone)

```
Square 1:1 image, 1024x1024. A single inventory icon for a sci-fi skirmish wargame: one object only, shown in a three-quarter view, slightly tilted, centred and filling about 75% of the frame. Painterly digital illustration, gritty 'frontier space western' mood: used, scratched, practical hardware, muted palette of dusty ochre, rust, gunmetal, slate blue and teal, warm rim light from the upper left, soft shadow under the object. Plain dark charcoal-blue background with a subtle vignette, a thin brushed-brass square frame with rounded corners. No text, no letters, no numbers, no logos, no watermark, no hands, no people. Same style, lighting and framing for every icon of the set.
```

Suggerimento: se un'icona esce con scritte o con più oggetti, chiedi «same style as the previous icons, one single object, no text, brass square frame».

## Armi (36)

### `fucile_automatico.png` - Fucile automatico (Auto rifle)

Prompt: `Inventory icon, a rugged automatic rifle with a curved box magazine, wooden-and-steel furniture, worn bluing. Use the common icon style: single object, brass square frame, dark background, no text.`

### `pistola_raggi.png` - Pistola a raggi (Beam pistol)

Prompt: `Inventory icon, a sleek beam pistol with a glowing blue emitter crystal at the muzzle and cooling fins. Use the common icon style: single object, brass square frame, dark background, no text.`

### `lama.png` - Lama (Blade)

Prompt: `Inventory icon, a plain combat knife-blade, short sword length, wrapped leather grip, nicked edge. Use the common icon style: single object, brass square frame, dark background, no text.`

### `pistola_blaster.png` - Pistola blaster (Blast pistol)

Prompt: `Inventory icon, a chunky blast pistol with a bulbous energy chamber glowing orange and a stubby barrel. Use the common icon style: single object, brass square frame, dark background, no text.`

### `fucile_blaster.png` - Fucile blaster (Blast rifle)

Prompt: `Inventory icon, a long blast rifle with a glowing orange energy cell along the barrel and a skeletal stock. Use the common icon style: single object, brass square frame, dark background, no text.`

### `sciabola.png` - Sciabola d'arrembaggio (Boarding saber)

Prompt: `Inventory icon, a curved boarding saber with a basket hand-guard, starship-crew style, polished steel. Use the common icon style: single object, brass square frame, dark background, no text.`

### `arma_brutale.png` - Arma da mischia brutale (Brutal melee weapon)

Prompt: `Inventory icon, a brutal improvised melee weapon: a heavy pipe club studded with bolts and a spiked chain. Use the common icon style: single object, brass square frame, dark background, no text.`

### `pistola_fuoco.png` - Pistola a fuoco adesivo (Cling fire pistol)

Prompt: `Inventory icon, a cling fire pistol: a compact flame projector with a small pressurised tank of sticky glowing gel. Use the common icon style: single object, brass square frame, dark background, no text.`

### `fucile_coloniale.png` - Fucile coloniale (Colony rifle)

Prompt: `Inventory icon, a simple bolt-action colony rifle with a scuffed wooden stock and leather sling. Use the common icon style: single object, brass square frame, dark background, no text.`

### `granata_accecante.png` - Granata accecante (Dazzle grenade)

Prompt: `Inventory icon, a dazzle grenade: a cylindrical flash-bang canister with white reflective bands and a pull ring. Use the common icon style: single object, brass square frame, dark background, no text.`

### `pistola_duello.png` - Pistola da duello (Duelling pistol)

Prompt: `Inventory icon, an elegant duelling pistol with a long slim barrel, engraved silver details and a polished wooden grip. Use the common icon style: single object, brass square frame, dark background, no text.`

### `cannone_flak.png` - Fucile flak (Flak gun)

Prompt: `Inventory icon, a flak gun: a short wide-barrelled scatter weapon with a drum magazine and a heat shield. Use the common icon style: single object, brass square frame, dark background, no text.`

### `granata_frakk.png` - Granata Frakk (Frakk grenade)

Prompt: `Inventory icon, a Frakk grenade: a round fragmentation grenade with a segmented olive-green shell and a red primer. Use the common icon style: single object, brass square frame, dark background, no text.`

### `fucile_furia.png` - Fucile Furia (Fury rifle)

Prompt: `Inventory icon, a Fury rifle: a massive heavy anti-materiel rifle with a huge muzzle brake and a thick barrel. Use the common icon style: single object, brass square frame, dark background, no text.`

### `spada_luce.png` - Spada abbagliante (Glare sword)

Prompt: `Inventory icon, a glare sword: a sword whose blade is a bright white-gold light edge set in a metal frame. Use the common icon style: single object, brass square frame, dark background, no text.`

### `cannone_mano.png` - Cannone a mano (Hand cannon)

Prompt: `Inventory icon, a hand cannon: an oversized revolver-like heavy pistol with a thick barrel and huge cylinder. Use the common icon style: single object, brass square frame, dark background, no text.`

### `lanciafiamme_mano.png` - Lanciafiamme a mano (Hand flamer)

Prompt: `Inventory icon, a hand flamer: a pistol-sized flamethrower with a pilot light and a small fuel canister. Use the common icon style: single object, brass square frame, dark background, no text.`

### `laser_mano.png` - Laser a mano (Hand laser)

Prompt: `Inventory icon, a hand laser: a compact futuristic pistol with a red lens at the muzzle and a slim power cell. Use the common icon style: single object, brass square frame, dark background, no text.`

### `pistola.png` - Pistola (Hand gun)

Prompt: `Inventory icon, a standard semi-automatic hand gun, worn grip, practical and common. Use the common icon style: single object, brass square frame, dark background, no text.`

### `pistola_tascabile.png` - Pistola tascabile (Hold out pistol)

Prompt: `Inventory icon, a tiny hold-out pistol, palm sized, two short barrels, easy to conceal. Use the common icon style: single object, brass square frame, dark background, no text.`

### `fucile_caccia.png` - Fucile da caccia (Hunting rifle)

Prompt: `Inventory icon, a long hunting rifle with a telescopic scope and a wooden stock with carved details. Use the common icon style: single object, brass square frame, dark background, no text.`

### `iperblaster.png` - Iperblaster (Hyper blaster)

Prompt: `Inventory icon, a hyper blaster: a compact energy submachine gun with several glowing blue coils along the barrel. Use the common icon style: single object, brass square frame, dark background, no text.`

### `laser_fanteria.png` - Laser da fanteria (Infantry laser)

Prompt: `Inventory icon, an infantry laser rifle: military standard-issue energy rifle, matte olive casing, blue power cell. Use the common icon style: single object, brass square frame, dark background, no text.`

### `pistola_mitragliatrice.png` - Pistola mitragliatrice (Machine pistol)

Prompt: `Inventory icon, a machine pistol with an extended magazine and a folding foregrip. Use the common icon style: single object, brass square frame, dark background, no text.`

### `fucile_precisione.png` - Fucile di precisione (Marksman's rifle)

Prompt: `Inventory icon, a marksman's rifle with a long fluted barrel, bipod folded and a large precision scope. Use the common icon style: single object, brass square frame, dark background, no text.`

### `fucile_militare.png` - Fucile militare (Military rifle)

Prompt: `Inventory icon, a military rifle: standard assault rifle with rails, short scope and a sturdy polymer body. Use the common icon style: single object, brass square frame, dark background, no text.`

### `fucile_aghi.png` - Fucile ad aghi (Needle rifle)

Prompt: `Inventory icon, a needle rifle: a slender rifle with a transparent cylinder full of tiny crystal needles. Use the common icon style: single object, brass square frame, dark background, no text.`

### `fucile_plasma.png` - Fucile al plasma (Plasma rifle)

Prompt: `Inventory icon, a plasma rifle with a glowing green-white plasma chamber and heavy heat vents. Use the common icon style: single object, brass square frame, dark background, no text.`

### `artiglio_potenziato.png` - Artiglio potenziato (Power claw)

Prompt: `Inventory icon, a power claw: an armoured gauntlet with three large crackling metal talons. Use the common icon style: single object, brass square frame, dark background, no text.`

### `mitragliatrice.png` - Mitragliatrice (Rattle gun)

Prompt: `Inventory icon, a rattle gun: a heavy belt-fed machine gun with a long ammunition belt. Use the common icon style: single object, brass square frame, dark background, no text.`

### `spada_squarcio.png` - Spada dentata (Ripper sword)

Prompt: `Inventory icon, a ripper sword: a heavy sword with a motorised chain of serrated teeth along the edge. Use the common icon style: single object, brass square frame, dark background, no text.`

### `pistola_rottami.png` - Pistola di rottami (Scrap pistol)

Prompt: `Inventory icon, a scrap pistol: a crude pistol cobbled together from pipes, wire and scrap metal. Use the common icon style: single object, brass square frame, dark background, no text.`

### `ascia_frantumatrice.png` - Ascia frantumatrice (Shatter axe)

Prompt: `Inventory icon, a shatter axe: a large two-handed axe with a vibrating glowing-edged head. Use the common icon style: single object, brass square frame, dark background, no text.`

### `lanciaproiettili.png` - Lanciagranate (Shell gun)

Prompt: `Inventory icon, a shell gun: a stubby grenade launcher with a revolving cylinder of fat shells. Use the common icon style: single object, brass square frame, dark background, no text.`

### `fucile_pompa.png` - Fucile a pompa (Shotgun)

Prompt: `Inventory icon, a pump-action shotgun with a worn wooden pump and a short barrel. Use the common icon style: single object, brass square frame, dark background, no text.`

### `mazza_soppressione.png` - Mazza di soppressione (Suppression maul)

Prompt: `Inventory icon, a suppression maul: a heavy riot hammer with an electrified head crackling blue sparks. Use the common icon style: single object, brass square frame, dark background, no text.`


Non hanno icona le armi naturali e il combattimento a mani nude: `artigli_possenti`, `disarmato`, `zanne_artigli`, `zanne_grandi`.

## Modifiche alle armi (8)

### `lama_assalto.png` - Lama d'assalto (Assault blade)

Prompt: `Inventory icon, an assault blade: a bayonet blade clamped under a rifle barrel (only the front of the rifle shown). Use the common icon style: single object, brass square frame, dark background, no text.`

### `torcia.png` - Torcia tattica (Beam light)

Prompt: `Inventory icon, a beam light: a tactical flashlight module with a rail clamp, casting a bright beam. Use the common icon style: single object, brass square frame, dark background, no text.`

### `bipode.png` - Bipode (Bipod)

Prompt: `Inventory icon, a folding bipod with two extendable legs and a rail clamp. Use the common icon style: single object, brass square frame, dark background, no text.`

### `pacco_hot_shot.png` - Pacco hot shot (Hot shot pack)

Prompt: `Inventory icon, a hot shot pack: an overcharged power cell glowing hot orange with warning stripes painted but no text. Use the common icon style: single object, brass square frame, dark background, no text.`

### `nano_fango.png` - Nano-fango configurabile (Cyber-configurable nano-sludge)

Prompt: `Inventory icon, cyber-configurable nano-sludge: a small vial of shimmering silver nanite liquid with a nozzle. Use the common icon style: single object, brass square frame, dark background, no text.`

### `stabilizzatore.png` - Stabilizzatore (Stabilizer)

Prompt: `Inventory icon, a stabilizer: a gyroscopic weapon stabiliser module with small spinning rings. Use the common icon style: single object, brass square frame, dark background, no text.`

### `attacco_shock.png` - Attacco shock (Shock attachment)

Prompt: `Inventory icon, a shock attachment: a muzzle device with electrodes crackling with blue electricity. Use the common icon style: single object, brass square frame, dark background, no text.`

### `kit_potenziamento.png` - Kit di potenziamento (Upgrade kit)

Prompt: `Inventory icon, an upgrade kit: an open small toolcase with precision gun parts, springs and a new barrel. Use the common icon style: single object, brass square frame, dark background, no text.`

## Mirini (5)

### `mirino_laser.png` - Mirino laser (Laser sight)

Prompt: `Inventory icon, a laser sight: a small rail-mounted module emitting a thin red laser beam. Use the common icon style: single object, brass square frame, dark background, no text.`

### `mirino_qualita.png` - Mirino di qualità (Quality sight)

Prompt: `Inventory icon, a quality sight: a beautifully machined optical scope with brass fittings. Use the common icon style: single object, brass square frame, dark background, no text.`

### `mirino_cercatore.png` - Mirino cercatore (Seeker sight)

Prompt: `Inventory icon, a seeker sight: a scope with a small glowing targeting display and an antenna. Use the common icon style: single object, brass square frame, dark background, no text.`

### `mirino_tracciante.png` - Mirino tracciante (Tracker sight)

Prompt: `Inventory icon, a tracker sight: a scope with a rotating sensor drum and a teal glowing lens. Use the common icon style: single object, brass square frame, dark background, no text.`

### `mirino_unity.png` - Mirino da battaglia Unity (Unity battle sight)

Prompt: `Inventory icon, a Unity battle sight: a sleek military holographic sight in blue-grey with a floating reticle. Use the common icon style: single object, brass square frame, dark background, no text.`

## Corazze (5)

### `corazza_battaglia.png` - Armatura da battaglia (Battle dress)

Prompt: `Inventory icon, battle dress: a full suit of powered combat armour displayed on a stand, heavy plates. Use the common icon style: single object, brass square frame, dark background, no text.`

### `corazza_combattimento.png` - Corazza da combattimento (Combat armor)

Prompt: `Inventory icon, combat armor: a military chest plate with shoulder guards and webbing. Use the common icon style: single object, brass square frame, dark background, no text.`

### `flex_armor.png` - Flex-armor (Flex-armor)

Prompt: `Inventory icon, flex-armor: a flexible bodysuit of overlapping dark scales, folded. Use the common icon style: single object, brass square frame, dark background, no text.`

### `corazza_frag.png` - Giubbotto antischegge (Frag vest)

Prompt: `Inventory icon, a frag vest: a padded ballistic vest with ceramic plates and pockets. Use the common icon style: single object, brass square frame, dark background, no text.`

### `equip_furtivo.png` - Equipaggiamento furtivo (Stealth gear)

Prompt: `Inventory icon, stealth gear: a matte black hooded suit with sound-dampening pads and a dark visor. Use the common icon style: single object, brass square frame, dark background, no text.`

## Schermi (4)

### `mantello_mimetico.png` - Mantello mimetico (Camo cloak)

Prompt: `Inventory icon, a camo cloak: a folded chameleon cloak whose fabric half blends into the background. Use the common icon style: single object, brass square frame, dark background, no text.`

### `schermo_deflettore.png` - Campo deflettore (Deflector field)

Prompt: `Inventory icon, a deflector field generator: a belt device projecting a faint hexagonal energy bubble. Use the common icon style: single object, brass square frame, dark background, no text.`

### `schermo_flak.png` - Schermo flak (Flak screen)

Prompt: `Inventory icon, a flak screen: a shoulder-mounted generator emitting a shimmering curtain that stops shrapnel. Use the common icon style: single object, brass square frame, dark background, no text.`

### `generatore_schermo.png` - Generatore di schermo (Screen generator)

Prompt: `Inventory icon, a screen generator: a compact backpack unit with an emitter dish and a blue glow. Use the common icon style: single object, brass square frame, dark background, no text.`

## Consumabili (6)

### `booster.png` - Pillole booster (Booster pills)

Prompt: `Inventory icon, booster pills: a small medical blister pack of bright red pills. Use the common icon style: single object, brass square frame, dark background, no text.`

### `combat_serum.png` - Siero da combattimento (Combat serum)

Prompt: `Inventory icon, combat serum: an auto-injector syringe with glowing amber liquid. Use the common icon style: single object, brass square frame, dark background, no text.`

### `cristalli_kiranin.png` - Cristalli Kiranin (Kiranin crystals)

Prompt: `Inventory icon, Kiranin crystals: a cluster of hypnotic multicoloured glowing crystals in an open pouch. Use the common icon style: single object, brass square frame, dark background, no text.`

### `rage_out.png` - Rage Out (Rage out)

Prompt: `Inventory icon, Rage out: a cheap street-drug inhaler with an aggressive red glow. Use the common icon style: single object, brass square frame, dark background, no text.`

### `still.png` - Still (Still)

Prompt: `Inventory icon, Still: a small calming nasal spray vial with a pale blue liquid. Use the common icon style: single object, brass square frame, dark background, no text.`

### `stim.png` - Stim-pack (Stim-pack)

Prompt: `Inventory icon, a stim-pack: a chunky emergency injector with a green cross-shaped indicator light. Use the common icon style: single object, brass square frame, dark background, no text.`

## Impianti (11)

### `compagno_ia.png` - Compagno IA (AI companion)

Prompt: `Inventory icon, an AI companion: a small floating spherical drone with a friendly glowing eye. Use the common icon style: single object, brass square frame, dark background, no text.`

### `filo_corporeo.png` - Filo corporeo (Body wire)

Prompt: `Inventory icon, body wire: a coil of fine glowing neural wiring with surgical connectors. Use the common icon style: single object, brass square frame, dark background, no text.`

### `impianto_muscoli.png` - Braccio potenziato (Boosted arm)

Prompt: `Inventory icon, a boosted arm: a cybernetic arm with hydraulic muscles, detached on a workbench. Use the common icon style: single object, brass square frame, dark background, no text.`

### `impianto_gambe.png` - Gamba potenziata (Boosted leg)

Prompt: `Inventory icon, a boosted leg: a cybernetic leg with reinforced pistons, detached on a workbench. Use the common icon style: single object, brass square frame, dark background, no text.`

### `mano_cibernetica.png` - Mano cibernetica (Cyber hand)

Prompt: `Inventory icon, a cyber hand: a metal cybernetic hand with an opening palm compartment. Use the common icon style: single object, brass square frame, dark background, no text.`

### `difese_genetiche.png` - Difese genetiche (Genetic defenses)

Prompt: `Inventory icon, genetic defenses: a sealed gene-therapy ampoule with a DNA helix glowing inside. Use the common icon style: single object, brass square frame, dark background, no text.`

### `potenziamento_salute.png` - Potenziamento della salute (Health boost)

Prompt: `Inventory icon, a health boost implant: a small glowing green organ-like implant in a medical tray. Use the common icon style: single object, brass square frame, dark background, no text.`

### `regolatore_nervi.png` - Regolatore nervoso (Nerve adjuster)

Prompt: `Inventory icon, a nerve adjuster: a spine-shaped neural implant with tiny blue lights. Use the common icon style: single object, brass square frame, dark background, no text.`

### `impianto_riflessi.png` - Ottimizzazione neurale (Neural optimization)

Prompt: `Inventory icon, a neural optimization implant: a chip-like brain implant with glowing gold circuitry. Use the common icon style: single object, brass square frame, dark background, no text.`

### `visore_notturno.png` - Vista notturna (Night sight)

Prompt: `Inventory icon, night sight: a pair of cybernetic replacement eyes glowing green in a small case. Use the common icon style: single object, brass square frame, dark background, no text.`

### `soppressore_dolore.png` - Soppressore del dolore (Pain suppressor)

Prompt: `Inventory icon, a pain suppressor: a small neck implant with a soothing violet light. Use the common icon style: single object, brass square frame, dark background, no text.`

## Equipaggiamento da battaglia (20)

### `sensore_auto.png` - Sensore automatico (Auto sensor)

Prompt: `Inventory icon, an auto sensor: a shoulder-mounted motion-triggered sensor turret with a red eye. Use the common icon style: single object, brass square frame, dark background, no text.`

### `visore_battaglia.png` - Visore da battaglia (Battle visor)

Prompt: `Inventory icon, a battle visor: a tactical helmet visor with a holographic targeting overlay. Use the common icon style: single object, brass square frame, dark background, no text.`

### `comunicatore.png` - Comunicatore (Communicator)

Prompt: `Inventory icon, a communicator: a rugged wrist communicator with an antenna and small screen. Use the common icon style: single object, brass square frame, dark background, no text.`

### `lama_nascosta.png` - Lama nascosta (Concealed blade)

Prompt: `Inventory icon, a concealed blade: a sleeve-mounted spring-loaded throwing blade. Use the common icon style: single object, brass square frame, dark background, no text.`

### `dislocatore.png` - Dislocatore (Displacer)

Prompt: `Inventory icon, a displacer: a teleportation belt device with a swirling violet portal glow. Use the common icon style: single object, brass square frame, dark background, no text.`

### `bot_distrazione.png` - Bot diversivo (Distraction bot)

Prompt: `Inventory icon, a distraction bot: a small hovering bot with flashing lights and a speaker grille. Use the common icon style: single object, brass square frame, dark background, no text.`

### `rampino.png` - Lancia-rampino (Grapple launcher)

Prompt: `Inventory icon, a grapple launcher: a pistol-like launcher with a grappling hook and coiled cable. Use the common icon style: single object, brass square frame, dark background, no text.`

### `smorzatore_grav.png` - Smorzatore gravitazionale (Grav dampener)

Prompt: `Inventory icon, a grav dampener: a belt unit with anti-gravity rings glowing faintly blue. Use the common icon style: single object, brass square frame, dark background, no text.`

### `tuta_ambientale.png` - Tuta antirischio (Hazard suit)

Prompt: `Inventory icon, a hazard suit: a yellow-orange sealed environmental suit with a round helmet, folded. Use the common icon style: single object, brass square frame, dark background, no text.`

### `hoverboard.png` - Hoverboard (Hover board)

Prompt: `Inventory icon, a hover board: a battered sci-fi hoverboard with glowing thrusters underneath. Use the common icon style: single object, brass square frame, dark background, no text.`

### `insta_muro.png` - Insta-muro (Insta-wall)

Prompt: `Inventory icon, an insta-wall: a disc-shaped deployable device projecting a short wall of blue force energy. Use the common icon style: single object, brass square frame, dark background, no text.`

### `jump_belt.png` - Cintura a reazione (Jump belt)

Prompt: `Inventory icon, a jump belt: a belt with two small rocket thrusters and fuel cells. Use the common icon style: single object, brass square frame, dark background, no text.`

### `motion_tracker.png` - Rilevatore di movimento (Motion tracker)

Prompt: `Inventory icon, a motion tracker: a handheld scanner with a radar sweep display showing blips. Use the common icon style: single object, brass square frame, dark background, no text.`

### `multitaglio.png` - Multi-taglierina (Multi-cutter)

Prompt: `Inventory icon, a multi-cutter: a handheld industrial cutting tool with a bright plasma cutting tip. Use the common icon style: single object, brass square frame, dark background, no text.`

### `zampa_coniglio.png` - Robo-zampa di coniglio (Robo-rabbit's foot)

Prompt: `Inventory icon, a robo-rabbit's foot: a small mechanical rabbit-foot charm on a chain, cute and odd. Use the common icon style: single object, brass square frame, dark background, no text.`

### `scanner_bot.png` - Bot scanner (Scanner bot)

Prompt: `Inventory icon, a scanner bot: a small flying drone with a scanning cone of teal light. Use the common icon style: single object, brass square frame, dark background, no text.`

### `bot_spia.png` - Bot spia (Snooper bot)

Prompt: `Inventory icon, a snooper bot: a tiny insect-like spy drone with camera eyes. Use the common icon style: single object, brass square frame, dark background, no text.`

### `emettitore_sonico.png` - Emettitore sonico (Sonic emitter)

Prompt: `Inventory icon, a sonic emitter: a speaker-cone device emitting visible concentric sound rings. Use the common icon style: single object, brass square frame, dark background, no text.`

### `stivali_acciaio.png` - Stivali d'acciaio (Steel boots)

Prompt: `Inventory icon, steel boots: a pair of heavy steel-capped combat boots. Use the common icon style: single object, brass square frame, dark background, no text.`

### `distorsore_temporale.png` - Distorsore temporale (Time distorter)

Prompt: `Inventory icon, a time distorter: an ornate device with clock-like rings and a warped bubble of frozen time. Use the common icon style: single object, brass square frame, dark background, no text.`

## Oggetti della nave e di campagna (19)

### `analizzatore.png` - Analizzatore (Analyzer)

Prompt: `Inventory icon, an analyzer: a desktop scientific analysis unit with sample slots and holographic readouts. Use the common icon style: single object, brass square frame, dark background, no text.`

### `razioni_coloniali.png` - Razioni coloniali (Colonist ration packs)

Prompt: `Inventory icon, colonist ration packs: a stack of sealed vacuum-packed food bricks in a crate. Use the common icon style: single object, brass square frame, dark background, no text.`

### `duplicatore.png` - Duplicatore (Duplicator)

Prompt: `Inventory icon, a duplicator: a strange box machine with two identical small compartments and a glowing seam. Use the common icon style: single object, brass square frame, dark background, no text.`

### `documenti_falsi.png` - Documenti falsi (Fake ID)

Prompt: `Inventory icon, fake ID: a set of identity cards and a data chip, slightly suspicious, no readable text. Use the common icon style: single object, brass square frame, dark background, no text.`

### `fixer.png` - Fixer (Fixer)

Prompt: `Inventory icon, a fixer: a small autonomous repair gadget with tiny manipulator arms. Use the common icon style: single object, brass square frame, dark background, no text.`

### `kit_riconfigurazione.png` - Kit di riconfigurazione genetica (Genetic reconfiguration kit)

Prompt: `Inventory icon, a genetic reconfiguration kit: a medical case with vials of glowing gene serum. Use the common icon style: single object, brass square frame, dark background, no text.`

### `dadi_truccati.png` - Dadi truccati (Loaded dice)

Prompt: `Inventory icon, loaded dice: a pair of worn dice with blank faces and a subtle weighted glint, no pips visible. Use the common icon style: single object, brass square frame, dark background, no text.`

### `dadi_fortunati.png` - Dadi fortunati (Lucky dice)

Prompt: `Inventory icon, lucky dice: a pair of gleaming golden dice with blank faces and a lucky charm ribbon, no pips visible. Use the common icon style: single object, brass square frame, dark background, no text.`

### `traduttore_mk2.png` - Traduttore Mk II (Mk II translator)

Prompt: `Inventory icon, a Mk II translator: a small handheld translation device with a speaker and an earpiece. Use the common icon style: single object, brass square frame, dark background, no text.`

### `medikit.png` - Med-patch (Med-patch)

Prompt: `Inventory icon, a med-patch: a pack of adhesive medical patches in a sterile pouch. Use the common icon style: single object, brass square frame, dark background, no text.`

### `sfera_meditazione.png` - Sfera di meditazione (Meditation orb)

Prompt: `Inventory icon, a meditation orb: a smooth floating stone sphere with a soft inner light. Use the common icon style: single object, brass square frame, dark background, no text.`

### `nano_doc.png` - Nano-doc (Nano-doc)

Prompt: `Inventory icon, a nano-doc: a medical injector filled with silver healing nanites. Use the common icon style: single object, brass square frame, dark background, no text.`

### `peluche.png` - Peluche stravagante (Novelty stuffed animal)

Prompt: `Inventory icon, a novelty stuffed animal: a cute plush alien creature toy, a bit worn. Use the common icon style: single object, brass square frame, dark background, no text.`

### `purificatore.png` - Purificatore (Purifier)

Prompt: `Inventory icon, a purifier: a compact water purification machine with a clear water tank. Use the common icon style: single object, brass square frame, dark background, no text.`

### `kit_riparazione.png` - Bot riparatore (Repair Bot)

Prompt: `Inventory icon, a repair bot: a small boxy repair robot with welding arm and tool attachments. Use the common icon style: single object, brass square frame, dark background, no text.`

### `permesso_settore.png` - Permesso di settore (Sector permit)

Prompt: `Inventory icon, a sector permit: an official-looking data card with a holographic seal, no readable text. Use the common icon style: single object, brass square frame, dark background, no text.`

### `pezzi_ricambio.png` - Pezzi di ricambio (Spare parts)

Prompt: `Inventory icon, spare parts: a crate of assorted mechanical spare parts, gears, cables and plates. Use the common icon style: single object, brass square frame, dark background, no text.`

### `teach_bot.png` - Bot istruttore (Teach-bot)

Prompt: `Inventory icon, a teach-bot: a small tutor robot with a projector eye showing a hologram diagram. Use the common icon style: single object, brass square frame, dark background, no text.`

### `trascensore.png` - Trascensore (Transcender)

Prompt: `Inventory icon, a transcender: a mysterious alien artifact, a twisted crystalline pyramid with drifting light. Use the common icon style: single object, brass square frame, dark background, no text.`

---

Totale: 114 icone (36 armi, 8 modifiche, 5 mirini, 65 oggetti).
