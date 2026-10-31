# Prompt per le pedine di Five Parsecs from Home

Prompt per generare con il generatore di immagini di ChatGPT le pedine viste dall'alto usate nelle battaglie su griglia.

## Come usarli

1. Apri ChatGPT e incolla **una volta sola** lo *stile comune* qui sotto, chiedendo di usarlo per tutte le immagini della conversazione.
2. Poi incolla, una alla volta, le righe «Prompt» delle pedine (o lo stile + il soggetto insieme, se preferisci una conversazione per pedina).
3. Scarica l'immagine (quadrata, almeno 512 x 512 px; 1024 x 1024 va benissimo) e salvala in formato **PNG** con il **nome file indicato**, nella cartella del repository `assets/pedine/` (es. `assets/pedine/kerin.png`).
4. Fai il commit (o mandami il file): il gioco carica da solo le immagini presenti e usa la pedina segnaposto (cerchio colorato con iniziali) per quelle che mancano. L'immagine viene ritagliata in un cerchio, quindi il soggetto deve stare al centro.
5. Nella versione da computer si possono provare anche mettendole nella cartella dati dell'utente `pedine/` (user://pedine): il gioco le legge senza ricompilare.

## Stile comune (uguale per tutte)

```
Square 1:1 image, 1024x1024. A single circular game token (pog) for a sci-fi skirmish wargame, seen from directly above in a 3/4 top-down view (head and shoulders toward the viewer, as if looking down at a miniature on the table). Painterly digital illustration, gritty 'frontier space western' mood, muted palette of dusty ochre, rust, slate blue and teal with warm rim light from the upper left. The figure fills about 80% of the circle and is centred. Plain dark charcoal-blue background inside the circle, a thin brushed-brass rim around the token, pure black outside the circle. No text, no letters, no numbers, no logos, no watermark, no UI elements. Same style, lighting and framing for every token of the set.
```

Suggerimento: se un'immagine esce con testo o con un'inquadratura diversa, chiedi «same style as the previous tokens, no text, top-down 3/4 view, centred in the circle».

## Equipaggio: specie e tipi di personaggio (26)

### `umano.png` - Umano qualunque, avventuriero di frontiera

Prompt: `Game token, a weathered human frontier adventurer in a patched long coat and light body armour, short-cropped hair, carrying a rifle across the chest. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `bot.png` - Bot da lavoro standard

Prompt: `Game token, a boxy utilitarian worker robot with a single round optical sensor, scuffed yellow-grey plating, rivets and hydraulic arms. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `engineer.png` - Engineer: piccolo alieno tecnico

Prompt: `Game token, a small, slender alien technician with an oversized bald head, large dark eyes and grey-blue skin, wearing a tool harness full of gadgets and goggles on the forehead. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `kerin.png` - K'Erin: alieno guerriero tozzo e orgoglioso

Prompt: `Game token, a stocky, heavily muscled alien warrior with thick reptilian brown hide, short tusks and a bony crest, ornate ceremonial armour plates and a heavy blade. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `soulless.png` - Soulless: cyborg collegato in rete

Prompt: `Game token, a tall gaunt cyborg humanoid, pale grey synthetic skin, glowing blue circuitry lines on the face, smooth integrated armour plating, expressionless. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `precursor.png` - Precursor: antico alieno elegante

Prompt: `Game token, a tall, elegant ancient alien with elongated features, iridescent pale skin, flowing robes over sleek armour, an air of serene mystery. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `feral.png` - Feral: umano modificato con tratti animali

Prompt: `Game token, a genetically modified human with feline features - pointed ears, slit amber eyes, faint fur on the cheeks - in practical scout gear. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `swift.png` - Swift: piccolo alieno alato

Prompt: `Game token, a small winged lizard-like alien with leathery bat wings folded on its back, bright green scales, big alert eyes, holding a compact carbine. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `deconvertito.png` - De-convertito: ex Convertito liberato

Prompt: `Game token, a human partially covered in removed cybernetic implants, scars and empty sockets on the skull, one mechanical arm, haunted expression. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `agente_unity.png` - Agente Unity: agente del governo galattico

Prompt: `Game token, a sharp-dressed government agent in a dark tailored armoured coat with a subtle silver insignia, earpiece, cool confident look. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `passato_misterioso.png` - Passato misterioso: figura incappucciata

Prompt: `Game token, a hooded human figure with face half in shadow, travel-worn cloak, a scar across the jaw, hand resting on a holstered pistol. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `hakshan.png` - Hakshan: alieno sincero che legge le emozioni

Prompt: `Game token, a gentle-looking alien with smooth lavender skin, large expressive eyes and small head fins, wearing a simple investigator's coat. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `stalker.png` - Stalker: cacciatore che si sfasa

Prompt: `Game token, a lean alien hunter with a blurred, flickering outline as if phasing out of reality, dark mottled skin, hunting mask and long knife. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `hulker.png` - Hulker: gigante forzuto

Prompt: `Game token, a massive hulking alien brute with grey rocky skin, tiny eyes, enormous shoulders and fists, crude armour straps. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `recluta_speranzosa.png` - Recluta speranzosa: giovane entusiasta

Prompt: `Game token, an eager young human recruit in oversized brand-new armour, bright hopeful face, clutching a pistol a little nervously. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `elevato_genetico.png` - Elevato genetico: animale potenziato

Prompt: `Game token, a genetically uplifted animal - an upright, intelligent wolf-like humanoid in tactical vest - with clever eyes. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `mutante.png` - Mutante: umano mutato dalle radiazioni

Prompt: `Game token, a radiation-mutated human with patchy discoloured skin, an extra small eye on the forehead and asymmetric limbs, in scavenged armour. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `bot_assalto.png` - Bot d'assalto: robot militare

Prompt: `Game token, a sleek military assault robot with angular armour plates painted olive drab, red visor slit and a built-in heavy weapon arm. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `manipolatore.png` - Manipolatore: alieno astuto con tentacoli

Prompt: `Game token, a cunning alien with a bulbous head and several slender tentacles instead of arms, each holding a small pistol, wearing a bureaucrat's sash. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `primitivo.png` - Primitivo: da un mondo regredito

Prompt: `Game token, a tribal human from a regressed world wearing furs and bone ornaments, war paint, holding a spear and a crude blade. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `feeler.png` - Feeler: alieno empatico sensibile

Prompt: `Game token, a delicate alien with translucent pale skin and long feathery antennae, soft glowing eyes, wrapped in light scarves. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `emo_soppresso.png` - Emo-soppresso: emozioni bloccate chimicamente

Prompt: `Game token, a calm, blank-faced human with a medical injector port on the neck, perfectly neat uniform, cold empty stare. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `alieno_minore.png` - Alieno minore: una delle tante piccole specie della Frontiera

Prompt: `Game token, a minor alien species member with blue mottled skin, small horns and four fingers, in mismatched spacer clothes. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `viaggiatore.png` - Viaggiatore: viene da molto lontano

Prompt: `Game token, a strange traveler in an unusual pearl-white suit of unknown design, faintly glowing eyes, carrying an odd archaic device. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `empatico.png` - Empatico: sente gli altri

Prompt: `Game token, a serene human empath with a soft halo of faint light around the head, closed eyes, simple monastic coat. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `bio_potenziato.png` - Bio-potenziato: corpo migliorato

Prompt: `Game token, a bio-enhanced human with visible grafted muscle tissue and glowing green vein implants, wearing a sleeveless combat suit. Use the common style: circular top-down token, brass rim, dark background, no text.`

## Nemici: Elementi criminali (15)

### `ganger.png` - Gangster

Prompt: `Game token, a street ganger in a sleeveless jacket covered in gang patches, mohawk, scrap pistol and knife. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `teppisti.png` - Teppisti (punk)

Prompt: `Game token, a young punk with spiked hair, safety pins and neon paint, wielding a crude club. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `predoni.png` - Predoni

Prompt: `Game token, a dusty raider in goggles and scarf mask, layered scrap armour, colony rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `cultisti.png` - Cultisti

Prompt: `Game token, a cultist in hooded crimson robes with a glowing sigil pendant, fanatic eyes. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `psicopatici.png` - Psicopatici

Prompt: `Game token, a deranged psycho with wild eyes and a manic grin, blood-spattered coveralls, big blade. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `banda_viziati.png` - Banda di viziati

Prompt: `Game token, a spoiled rich-kid gang member in flashy designer armour and gold jewellery, smug sneer. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `rinnegati_genetici.png` - Rinnegati genetici

Prompt: `Game token, a gene-modified renegade with unnatural crimson eyes and sharp features, in black tactical clothing. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `anarchici.png` - Anarchici

Prompt: `Game token, an anarchist rebel with a balaclava and painted symbol on the chest, improvised weapons. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `pirati.png` - Pirati

Prompt: `Game token, a space pirate with a cybernetic eye patch, long coat, cutlass and laser pistol. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `fuorilegge_kerin.png` - Fuorilegge K'Erin

Prompt: `Game token, a scarred K'Erin outlaw (stocky tusked reptilian alien) with stolen armour pieces and a heavy blade. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `briganti_skulker.png` - Briganti Skulker

Prompt: `Game token, a Skulker brigand: a wiry rat-like alien with big ears and whiskers, ragged cloak, shotgun. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `gangster_tech.png` - Gangster tecnologici

Prompt: `Game token, a tech ganger with glowing cybernetic implants, data cables in the hair and a hacked energy pistol. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `feccia_spazioporto.png` - Feccia dello spazioporto

Prompt: `Game token, a greasy starport thug in a stained flight jacket, stubble, cheap pistol. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `banda_hulker.png` - Banda di Hulker

Prompt: `Game token, a hulking grey-skinned brute in gang colours, chains around the shoulders, oversized club. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `pistoleri.png` - Pistoleri

Prompt: `Game token, a frontier gunslinger in a wide-brimmed hat and duster coat, twin pistols. Use the common style: circular top-down token, brass rim, dark background, no text.`

## Nemici: Forza mercenaria (Hired Muscle) (16)

### `mercenari_ignoti.png` - Mercenari ignoti

Prompt: `Game token, an anonymous mercenary in unmarked grey armour and full-face helmet, military rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `tutori_ordine.png` - Tutori dell'ordine

Prompt: `Game token, a law enforcer in blue riot armour with a visored helmet, badge and shotgun. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `truppe_gilda.png` - Truppe della Gilda

Prompt: `Game token, a guild trooper in polished corporate-guild armour with a heraldic shoulder plate, laser rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `roidganger.png` - Roidganger

Prompt: `Game token, a steroid-pumped gang bruiser with bulging veins, injector tubes on the arms and a huge hammer. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `squadra_operazioni_nere.png` - Squadra operazioni nere

Prompt: `Game token, a black-ops operative in matte black stealth armour with night vision goggles, silenced rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `robot_guerra.png` - Robot da guerra

Prompt: `Game token, a heavy war robot with thick armour, glowing red sensor cluster and twin gun arms. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `agenti_segreti.png` - Agenti segreti

Prompt: `Game token, a secret agent in a long dark coat and sunglasses, compact pistol, earpiece. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `assassini.png` - Assassini

Prompt: `Game token, a masked assassin in close-fitting dark armour with blades strapped everywhere. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `mercenari_ferali.png` - Mercenari ferali

Prompt: `Game token, a feral mercenary with feline features and claw-like nails, camouflage armour, rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `mercenari_skulker.png` - Mercenari Skulker

Prompt: `Game token, a Skulker mercenary (rat-like alien) in professional mismatched armour, scoped rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `sicurezza_aziendale.png` - Sicurezza aziendale

Prompt: `Game token, a corporate security guard in clean white-and-grey armour with a corporate logo-free shoulder stripe, visor and carbine. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `fanti_unity.png` - Fanti di Unity

Prompt: `Game token, a Unity grunt infantry soldier in standard blue-grey military armour and helmet, infantry laser. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `robot_sicurezza.png` - Robot di sicurezza

Prompt: `Game token, a sleek white security robot with a smooth faceplate and a single blue light bar. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `mercenari_drago_nero.png` - Mercenari del Drago Nero

Prompt: `Game token, an elite mercenary in black armour decorated with a stylised dragon motif painted in red, heavy rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `mercenari_lucertola_furiosa.png` - Mercenari della Lucertola Furiosa

Prompt: `Game token, a mercenary in sand-coloured armour with a snarling lizard painted on the helmet, aggressive stance. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `mercenari_tempesta_sangue.png` - Mercenari della Tempesta di Sangue

Prompt: `Game token, a mercenary in dark red armour with lightning-bolt markings, battle-scarred, auto rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

## Nemici: Parti interessate (16)

### `soldati_rinnegati.png` - Soldati rinnegati

Prompt: `Game token, a renegade soldier in torn military armour with removed insignia, grim face, military rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `cacciatori_taglie.png` - Cacciatori di taglie

Prompt: `Game token, a bounty hunter in a battered helmet with a T-shaped visor, trophies on the belt, hunting rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `abbandonati.png` - Abbandonati

Prompt: `Game token, a ragged abandoned colonist in tattered clothes and scraps of armour, desperate eyes. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `vigilanti.png` - Vigilanti

Prompt: `Game token, a masked vigilante with a scarf and improvised armour, determined, shotgun. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `isolazionisti.png` - Isolazionisti

Prompt: `Game token, an isolationist settler in homespun clothes and a wide hat, old hunting rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `zeloti.png` - Zeloti

Prompt: `Game token, a religious zealot in white robes with painted holy symbols and a burning torch-like weapon. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `mutanti.png` - Mutanti

Prompt: `Game token, a deformed mutant with lumpy greenish skin and mismatched eyes, crude weapon. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `primitivi.png` - Primitivi

Prompt: `Game token, a primitive tribal warrior with face paint, feathers and a spear. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `esuli_precursori.png` - Esuli Precursori

Prompt: `Game token, an exiled Precursor: tall elegant iridescent-skinned alien in worn, once-fine robes. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `coloni_kerin.png` - Coloni K'Erin

Prompt: `Game token, a K'Erin colonist: stocky tusked reptilian alien in farmer's work clothes with a rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `squadra_guerra_swift.png` - Squadra da guerra Swift

Prompt: `Game token, a Swift warrior: small winged green lizard alien with war paint and a carbine. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `task_force_senzanima.png` - Task force Soulless

Prompt: `Game token, a Soulless cyborg trooper with grey synthetic skin, glowing blue circuitry and heavy integrated armour. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `zeloti_tech.png` - Zeloti tecnologici

Prompt: `Game token, a tech zealot with machine-cult robes, many cybernetic arms and glowing red optics. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `milizia_coloniale.png` - Milizia coloniale

Prompt: `Game token, a colonial militia member in a padded jacket and old helmet, colony rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `nomadi_planetari.png` - Nomadi planetari

Prompt: `Game token, a planetary nomad wrapped in desert robes and goggles, long rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `squadra_recupero.png` - Squadra di recupero

Prompt: `Game token, a salvage crew worker in a heavy work suit with welding visor and a cutting tool. Use the common style: circular top-down token, brass rim, dark background, no text.`

## Nemici: Minacce vaganti (Roving Threats) (13)

### `acquisizione_convertiti.png` - Acquisizione dei Convertiti

Prompt: `Game token, a Converted cyborg: pale grey human body fused with black biomechanical implants, glowing violet eyes, blank face. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `infiltrati_convertiti.png` - Infiltrati Convertiti

Prompt: `Game token, a Converted infiltrator disguised in civilian clothes, with subtle biomechanical implants showing at the neck. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `predoni_rapitori.png` - Predoni rapitori

Prompt: `Game token, a sinister alien abductor with a gaunt grey face, dark goggles and a capture net launcher. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `covata_sciame.png` - Covata dello sciame

Prompt: `Game token, an insectoid swarm creature: chitinous, many-legged, mandibles and glowing amber eyes. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `robot_impazziti.png` - Robot impazziti

Prompt: `Game token, a haywire robot with sparking broken plating, flickering eye and twitching damaged limbs. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `lucertole_rasoio.png` - Lucertole rasoio

Prompt: `Game token, a razor lizard: a lean predatory reptile with blade-like spines along its back, seen from above. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `corridori_sabbie.png` - Corridori delle sabbie

Prompt: `Game token, a sand runner: a fast bipedal desert beast with long legs, sandy hide and a beak. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `squartatori_vuoto.png` - Squartatori del vuoto

Prompt: `Game token, a void ripper: a nightmarish black creature with too many claws and a gaping maw, faint purple glow. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `krorg.png` - Krorg

Prompt: `Game token, a Krorg: a huge armoured beast with massive claws, thick plated hide and a horned head. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `insetti_giganti.png` - Insetti giganti

Prompt: `Game token, a giant bug: oversized beetle-like insect with shiny carapace and serrated mandibles. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `inseguitori_carnivori.png` - Inseguitori carnivori

Prompt: `Game token, a carnivore chaser: a pack-hunting quadruped predator with a long snout full of teeth. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `striscianti_condotti.png` - Striscianti dei condotti

Prompt: `Game token, a vent crawler: a pale eyeless centipede-like creature emerging from a metal vent. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `distorti.png` - Distorti

Prompt: `Game token, a Distort: a twisted, glitching humanoid shape partly melted into static and shadow, unsettling. Use the common style: circular top-down token, brass rim, dark background, no text.`

## Nemici: Individui Unici (22)

### `picchiatore.png` - Picchiatore nemico (Individuo Unico)

Prompt: `Game token, a huge bruiser with a shaved head, knuckle-dusters and a reinforced leather harness. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `pesante.png` - Arma pesante nemica (Individuo Unico)

Prompt: `Game token, a heavy weapons specialist in bulky armour carrying a large rattle gun with an ammo belt. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `capo.png` - Capo nemico (Individuo Unico)

Prompt: `Game token, an enemy boss with an imposing long coat, ornate armour and a commanding glare, gesturing. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `killer.png` - Killer a pagamento (Individuo Unico)

Prompt: `Game token, a hired killer with a cold face, slicked hair, long dark coat and a sniper rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `spia_aziendale.png` - Spia aziendale (Individuo Unico)

Prompt: `Game token, a corporate spook in an elegant grey suit with hidden armour and a slim pistol. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `segugio_taglie.png` - Segugio di taglie (Individuo Unico)

Prompt: `Game token, a bounty tracker with a scanner monocle, hooded cloak and a net gun. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `mercenario_spietato.png` - Mercenario spietato (Individuo Unico)

Prompt: `Game token, a callous veteran mercenary with scars, cigar and battered heavy armour. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `freelance.png` - Freelance (Individuo Unico)

Prompt: `Game token, a freelancer adventurer in practical mixed gear and a confident smirk. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `agente_segreto.png` - Agente segreto (Individuo Unico)

Prompt: `Game token, a top secret agent in a sleek black suit with a hidden blade and pistol. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `hulker_rissaiolo.png` - Hulker rissaiolo (Individuo Unico)

Prompt: `Game token, a giant grey Hulker brawler with wrapped fists and a broken-tooth grin. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `pistolero.png` - Pistolero (Individuo Unico)

Prompt: `Game token, a legendary gunslinger with a long red scarf and two ornate pistols. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `tecnico_ingegnere.png` - Tecnico Engineer (Individuo Unico)

Prompt: `Game token, a small big-headed Engineer alien technician with a floating repair drone. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `mutante_picchiatore.png` - Mutante picchiatore (Individuo Unico)

Prompt: `Game token, an enormous mutant bruiser with a deformed oversized arm. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `viandante_precursore.png` - Viandante Precursor (Individuo Unico)

Prompt: `Game token, a wandering Precursor mystic: tall iridescent alien with a staff and travelling robes. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `investigatore_hakshan.png` - Investigatore Hakshan (Individuo Unico)

Prompt: `Game token, a Hakshan investigator: lavender-skinned alien with big eyes, trench coat and data pad. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `guerriero_kerin.png` - Guerriero K'Erin (Individuo Unico)

Prompt: `Game token, a proud K'Erin champion warrior with ornate armour and a great blade. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `esploratore_nomade.png` - Esploratore nomade (Individuo Unico)

Prompt: `Game token, a nomad scout in desert wraps with a long-barrelled rifle and binoculars. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `mercenario_cyborg.png` - Mercenario cyborg (Individuo Unico)

Prompt: `Game token, a cyborg mercenary with a full metal arm, half-metal face and red optic. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `psionico_rinnegato.png` - Psionico rinnegato (Individuo Unico)

Prompt: `Game token, a rogue psionic with glowing white eyes and floating debris around the head. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `cane_genetico.png` - Cane genetico (Individuo Unico)

Prompt: `Game token, a gene-engineered attack dog, large and muscular, with armour plates, seen from above. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `corridore_sabbie.png` - Corridore delle sabbie (Individuo Unico)

Prompt: `Game token, a giant alpha sand runner beast with scars and a crest. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `robot_sicurezza_mk2.png` - Robot di sicurezza Mk II (Individuo Unico)

Prompt: `Game token, an advanced Mk II security robot with twin targeting lenses and a fury rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

## Personaggi neutrali e VIP (13)

### `vip.png` - VIP da proteggere (obiettivo Proteggere)

Prompt: `Game token, an important unarmed civilian VIP in fine clothes, nervous, holding a briefcase. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `passante.png` - Passante (personaggio neutrale)

Prompt: `Game token, an ordinary bystander civilian in simple spacer clothes. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `teppista.png` - Teppista di strada (neutrale)

Prompt: `Game token, a street punk loitering with hands in pockets. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `gangster.png` - Gangster (neutrale)

Prompt: `Game token, a local gangster in a flashy jacket. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `impiegato_corporativo.png` - Rampante aziendale (neutrale)

Prompt: `Game token, a slick corporate employee in a suit with a data pad. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `bottegaio.png` - Bottegaio navigato (neutrale)

Prompt: `Game token, a hardened shopkeeper with an apron and a shotgun under the arm. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `colono.png` - Colono temprato (neutrale)

Prompt: `Game token, a hardened colonist in work clothes and a wide hat. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `robot_servizio.png` - Robot di servizio (neutrale)

Prompt: `Game token, a friendly service robot with a round body and manipulator arms. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `scienziato.png` - Scienziato (neutrale)

Prompt: `Game token, a scientist in a lab coat with goggles and a sample case. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `tecnico.png` - Tecnico (neutrale)

Prompt: `Game token, a technician with a tool belt and a welding visor pushed up. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `portuale.png` - Scaricatore portuale (neutrale)

Prompt: `Game token, a burly dock worker carrying a crate. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `guardia_sicurezza.png` - Guardia di sicurezza (neutrale)

Prompt: `Game token, a private security guard in a simple uniform with a baton. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `tutore_ordine.png` - Agente d'assalto (neutrale)

Prompt: `Game token, an enforcer officer in light riot gear. Use the common style: circular top-down token, brass rim, dark background, no text.`

## Battaglie della Traccia della Storia (7)

Il Capo («Sventato!», «Sabotare il piano») usa `capo.png`, il Picchiatore usa `picchiatore.png`, il Robot da guerra del Rapimento usa `robot_guerra.png`.

### `sicario.png` - Sicario della corporazione («Sventato!»)

Prompt: `Game token, a corporate hired gun in a dark long coat and a sleek half-mask, holding a colony rifle. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `arma_pesante.png` - Sicario con l'arma pesante («Sventato!»)

Prompt: `Game token, a burly mercenary carrying a heavy belt-fed rattle gun with an ammunition drum, braced to fire. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `scagnozzo.png` - Scagnozzo armato di pistola mitragliatrice («Sabotare il piano»)

Prompt: `Game token, a scruffy industrial-compound goon in a stained jumpsuit and cap, holding a compact machine pistol. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `sentinella_esterna.png` - Sentinella in tuta spaziale («Regolamento di conti»)

Prompt: `Game token, a sentry in a bulky vacuum suit with a domed helmet visor, holding a military rifle, on grey lunar dust. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `sentinella_interna.png` - Guardia interna del complesso («Regolamento di conti»)

Prompt: `Game token, an unarmoured facility guard in a grey work uniform with a military rifle, under harsh corridor light. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `qnarr.png` - Q'Narr, la nemesi («Regolamento di conti»)

Prompt: `Game token, a cunning alien crime lord with smooth violet skin, sharp features and an ornate armoured coat, holding a heavy hand cannon, menacing and alone. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `prigioniero.png` - Il vecchio compagno prigioniero («Stiamo arrivando!»)

Prompt: `Game token, a bruised human prisoner with hands bound by restraints, torn clothes, looking up hopefully. Use the common style: circular top-down token, brass rim, dark background, no text.`

## Segnalini di obiettivo (facoltativi, 4)

### `segnalino_pacco.png` - Segnalino: pacco da consegnare / oggetto della missione

Prompt: `Game token, a sealed metal cargo case with glowing seams, lying on the ground. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `segnalino_console.png` - Segnalino: console da violare (obiettivo Accedere)

Prompt: `Game token, a computer console terminal with holographic screen, seen from above. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `segnalino_luogo.png` - Segnalino: luogo notevole

Prompt: `Game token, a mysterious glinting object half buried in the dirt, faint teal glow. Use the common style: circular top-down token, brass rim, dark background, no text.`

### `segnalino_perquisire.png` - Segnalino: punto da perquisire

Prompt: `Game token, a pile of crates and debris to be searched. Use the common style: circular top-down token, brass rim, dark background, no text.`

---

Totale: 132 immagini (le pedine dei personaggi neutrali e i segnalini sono facoltativi: per ora il gioco li disegna da sé).
