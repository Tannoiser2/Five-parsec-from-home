## Pedine viste dall'alto. Se esiste assets/pedine/<nome>.png si usa l'immagine (ritagliata in un cerchio),
## altrimenti una pedina segnaposto disegnata: colore della specie o del nemico, sagoma e iniziali.
class_name Pedine
extends RefCounted

static var _cache := {}
static var _mancanti := {}

static func texture(nome: String) -> Texture2D:
	if nome == "":
		return null
	if _cache.has(nome):
		return _cache[nome]
	if _mancanti.has(nome):
		return null
	var tex: Texture2D = null
	for base in ["res://assets/pedine/", "user://pedine/"]:
		var p: String = base + nome + ".png"
		if base.begins_with("res://") and ResourceLoader.exists(p):
			tex = load(p)
		elif base.begins_with("user://") and FileAccess.file_exists(p):
			var img := Image.load_from_file(ProjectSettings.globalize_path(p))
			if img != null:
				tex = ImageTexture.create_from_image(img)
		if tex != null:
			break
	if tex == null:
		_mancanti[nome] = true
	else:
		_cache[nome] = tex
	return tex

static func colore_da_nome(nome: String, nemico: bool) -> Color:
	var h := float(abs(nome.hash()) % 1000) / 1000.0
	if nemico:
		return Color.from_hsv(fmod(0.95 + h * 0.18, 1.0), 0.55, 0.62)
	return Color.from_hsv(0.42 + h * 0.3, 0.45, 0.62)

static func iniziali(nome: String) -> String:
	var parti := nome.strip_edges().split(" ", false)
	if parti.is_empty():
		return "?"
	if parti.size() == 1:
		return parti[0].substr(0, 2).to_upper()
	return (parti[0].substr(0, 1) + parti[parti.size() - 1].substr(0, 1)).to_upper()

## Disegna una pedina su ci (CanvasItem) con centro c e raggio r.
static func disegna(ci: CanvasItem, c: Vector2, r: float, chiave: String, nome: String, nemico: bool, evidenziata := false, attenuata := false) -> void:
	var bordo := UI.ROSSO if nemico else UI.AMBRA
	if evidenziata:
		ci.draw_circle(c, r + 5, Color(1, 1, 1, 0.85))
	ci.draw_circle(c + Vector2(2, 3), r, Color(0, 0, 0, 0.45))
	var tex := texture(chiave)
	var mod := Color(1, 1, 1, 0.45) if attenuata else Color.WHITE
	if tex != null:
		# immagine ritagliata nel cerchio con un poligono texturizzato
		var punti := PackedVector2Array()
		var uv := PackedVector2Array()
		for i in 40:
			var a := TAU * i / 40.0
			var d := Vector2(cos(a), sin(a))
			punti.append(c + d * r)
			uv.append(Vector2(0.5, 0.5) + d * 0.5)
		var col := PackedColorArray()
		col.resize(40)
		col.fill(mod)
		ci.draw_polygon(punti, col, uv, tex)
	else:
		var base := colore_da_nome(chiave if chiave != "" else nome, nemico)
		ci.draw_circle(c, r, base.darkened(0.15) * mod)
		ci.draw_circle(c, r * 0.82, base * mod)
		# sagoma vista dall'alto: spalle e testa
		var scura := base.darkened(0.45) * mod
		ci.draw_circle(c + Vector2(0, r * 0.18), r * 0.48, scura)
		ci.draw_circle(c + Vector2(0, -r * 0.22), r * 0.26, scura.lightened(0.15))
		var f: Font = UI.font_titoli
		var testo := iniziali(nome)
		var fs := int(r * 0.72)
		var w := f.get_string_size(testo, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		ci.draw_string_outline(f, c + Vector2(-w / 2, fs * 0.36), testo, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.8) * mod)
		ci.draw_string(f, c + Vector2(-w / 2, fs * 0.36), testo, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE * mod)
	ci.draw_arc(c, r, 0, TAU, 40, bordo * mod, 3.0, true)
	ci.draw_arc(c, r - 3.5, 0, TAU, 40, Color(0, 0, 0, 0.5) * mod, 1.5, true)

## Elenco di tutte le pedine previste (nome file senza estensione), usato dal README e dalle prove.
static func elenco() -> Array:
	Dati.carica()
	var r := []
	for k in Dati.f("specie").get("specie", {}):
		var p := str(Dati.specie(k).get("pedina", k))
		if not p in r:
			r.append(p)
	for k in Dati.f("incontri").get("nemici", {}):
		var p := str(k).trim_prefix("unico_")
		if not p in r:
			r.append(p)
	return r
