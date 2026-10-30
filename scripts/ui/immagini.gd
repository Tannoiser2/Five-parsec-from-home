## Immagini del gioco (pedine, icone degli oggetti, illustrazioni degli scenari, grafica del campo di battaglia).
## Cerca res://assets/<percorso>.webp|png|jpg, poi user://<percorso>.webp|png|jpg (per provarle nella versione da
## computer senza ricompilare). Se l'immagine manca restituisce null e l'interfaccia usa il disegno di ripiego.
class_name Immagini
extends RefCounted

const ESTENSIONI := ["webp", "png", "jpg"]

static var _cache := {}

static func texture(percorso: String) -> Texture2D:
	if percorso == "":
		return null
	if _cache.has(percorso):
		return _cache[percorso]
	var tex: Texture2D = null
	for e in ESTENSIONI:
		var p := "res://assets/%s.%s" % [percorso, e]
		if ResourceLoader.exists(p):
			tex = load(p)
			break
	if tex == null:
		for e in ESTENSIONI:
			var p := "user://%s.%s" % [percorso, e]
			if FileAccess.file_exists(p):
				var img := Image.load_from_file(ProjectSettings.globalize_path(p))
				if img != null:
					img.generate_mipmaps()
					tex = ImageTexture.create_from_image(img)
					break
	_cache[percorso] = tex
	return tex

## Nome di file da un nome italiano: minuscolo, senza accenti, «_» al posto di spazi e punteggiatura
## (es. «Scarsa visibilità» -> scarsa_visibilita). Stessa regola usata nei PROMPT_*.md.
static func slug(t: String) -> String:
	var s := t.to_lower()
	var accenti := {"à": "a", "á": "a", "è": "e", "é": "e", "ì": "i", "í": "i", "ò": "o", "ó": "o", "ù": "u", "ú": "u"}
	for k in accenti:
		s = s.replace(k, accenti[k])
	var r := ""
	for ch in s:
		var ok := (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9")
		if ok:
			r += ch
		elif not r.ends_with("_"):
			r += "_"
	return r.strip_edges().trim_prefix("_").trim_suffix("_")

## ---------------- scorciatoie ----------------

static func oggetto(id: String) -> Texture2D:
	return texture("oggetti/" + id)

static func scenario(nome: String) -> Texture2D:
	return texture("scenari/" + nome)

## Illustrazione del tipo di battaglia (patrono, rivale, missione, opportunita, invasione, zona_rossa).
static func tipo_battaglia(tipo: String) -> Texture2D:
	var t: String = str({"attacca_rivale": "rivale", "storia": "missione"}.get(tipo, tipo))
	if t == "zona_rossa":
		return scenario("zona_rossa")
	return scenario("battaglia_" + str(t))

static func obiettivo(id: String) -> Texture2D:
	return scenario("obiettivo_" + id)

static func condizione(nome: String) -> Texture2D:
	return scenario("condizione_" + slug(nome))

static func luogo(nome: String) -> Texture2D:
	return scenario("luogo_" + slug(nome))

static func evento(nome: String) -> Texture2D:
	return scenario("evento_" + slug(nome))

## Copia ridotta (larghezza data, proporzioni mantenute) per le icone dei bottoni, che le mostrano a grandezza naturale.
static func ridotta(tex: Texture2D, larghezza: int) -> Texture2D:
	if tex == null:
		return null
	var k := "%d@%d" % [tex.get_rid().get_id(), larghezza]
	if _cache.has(k):
		return _cache[k]
	var img := tex.get_image()
	if img == null:
		return tex
	if img.is_compressed():
		img.decompress()
	img.clear_mipmaps()
	var h := maxi(1, int(round(float(larghezza) * img.get_height() / img.get_width())))
	img.resize(larghezza, h, Image.INTERPOLATE_LANCZOS)
	var r := ImageTexture.create_from_image(img)
	_cache[k] = r
	return r

## ---------------- controlli ----------------

## Icona quadrata (per gli oggetti); null se l'immagine manca.
static func icona(tex: Texture2D, lato: float, suggerimento := "") -> TextureRect:
	if tex == null:
		return null
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	r.custom_minimum_size = Vector2(lato, lato)
	r.tooltip_text = suggerimento
	r.mouse_filter = Control.MOUSE_FILTER_PASS if suggerimento != "" else Control.MOUSE_FILTER_IGNORE
	return r

## Illustrazione a tutta larghezza, ritagliata per riempire l'altezza data; null se manca.
static func illustrazione(tex: Texture2D, altezza: float, larghezza := 0.0) -> TextureRect:
	if tex == null:
		return null
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	r.clip_contents = true
	r.custom_minimum_size = Vector2(larghezza, altezza)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

## Illustrazione con una didascalia sotto, dentro una cornice; null se l'immagine manca.
static func riquadro(tex: Texture2D, didascalia: String, altezza: float, larghezza := 0.0) -> Control:
	var ill := illustrazione(tex, altezza, larghezza)
	if ill == null:
		return null
	var v := UI.vbox(4)
	v.add_child(ill)
	if didascalia != "":
		v.add_child(UI.etichetta(didascalia, 16, UI.AMBRA, true))
	return UI.pannello(v, UI.PANNELLO_2, UI.BORDO.darkened(0.4))
