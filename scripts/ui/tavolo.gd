## Disegno del campo di battaglia su griglia: terreno, figure, caselle raggiungibili, bersagli, marcatori.
extends Control

signal cella_cliccata(p: Vector2i, destro: bool)
signal cella_sopra(p: Vector2i)

var b: Battaglia
var lato := 40.0
var origine := Vector2.ZERO
var raggiungibili := {}
var raggiungibili_scatto := {}
var bersagli := {}       # uid -> soglia
var selezionata := -1
var sopra := Vector2i(-1, -1)
var linea_tiro := []     # [da, a] per l'ultimo tiro
var anim := {}           # uid -> posizione disegnata (Vector2) per l'animazione

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	resized.connect(_calcola)

func _calcola() -> void:
	if b == null:
		return
	lato = floor(min(size.x / b.W, size.y / b.H))
	origine = ((size - Vector2(lato * b.W, lato * b.H)) / 2.0).floor()
	queue_redraw()

func centro_cella(p: Vector2i) -> Vector2:
	return origine + (Vector2(p) + Vector2(0.5, 0.5)) * lato

func cella_da(pos: Vector2) -> Vector2i:
	var q := ((pos - origine) / lato).floor()
	return Vector2i(int(q.x), int(q.y))

func _gui_input(e: InputEvent) -> void:
	if b == null:
		return
	if e is InputEventMouseMotion:
		var p := cella_da(e.position)
		if p != sopra:
			sopra = p
			cella_sopra.emit(p)
			queue_redraw()
	elif e is InputEventMouseButton and e.pressed and (e.button_index == MOUSE_BUTTON_LEFT or e.button_index == MOUSE_BUTTON_RIGHT):
		var p := cella_da(e.position)
		if b.dentro(p):
			cella_cliccata.emit(p, e.button_index == MOUSE_BUTTON_RIGHT)

const COL := {
	0: Color(0.27, 0.24, 0.19),   # aperto: terra battuta
	1: Color(0.45, 0.33, 0.20),   # lineare
	2: Color(0.18, 0.30, 0.17),   # area
	3: Color(0.33, 0.35, 0.40),   # blocco
	4: Color(0.30, 0.26, 0.20),   # singolo
	5: Color(0.20, 0.26, 0.30),   # campo
	6: Color(0.16, 0.15, 0.14),   # muro
	7: Color(0.45, 0.30, 0.16),   # porta
	8: Color(0.30, 0.42, 0.50),   # finestra
	9: Color(0.24, 0.22, 0.20),   # interno
	10: Color(0.25, 0.70, 0.85),  # muro di forza
}

## Grafica del campo (assets/mappe/): nome dell'elemento del motore -> immagine.
const ELEMENTI_IMG := {"Edificio chiuso": "edificio", "Navetta atterrata": "navetta_atterrata", "Container": "container",
	"Masso": "masso", "Bosco": "bosco", "Rovine": "rovine", "Cespugli": "cespugli", "Vegetazione": "vegetazione"}
const PER_CELLA := {"Muro in rovina": "rovine_muro", "Deposito di casse": "cassa", "Barili": "barile", "Alberi": "albero", "Casse della navetta": "casse_navetta"}
const LINEARI := {"Barricata": "barricata", "Recinzione": "recinzione", "Muretto": "muretto", "Siepe": "siepe",
	"Sacchi di sabbia": "sacchi_sabbia", "Muro di forza": "muro_forza"}
const ORIENTABILI := ["edificio", "edificio_grande", "navetta_atterrata", "container", "masso"]

func _draw() -> void:
	if b == null:
		return
	if lato < 2:
		_calcola()
	var tot := Rect2(origine, Vector2(lato * b.W, lato * b.H))
	draw_rect(tot.grow(6), Color(0.05, 0.05, 0.06))
	draw_rect(tot.grow(6), UI.BORDO.darkened(0.3), false, 2.0)
	var ha_suolo := _suolo(tot)
	var coperte := _elementi_grafici()
	var rng := RandomNumberGenerator.new()
	for y in b.H:
		for x in b.W:
			var p := Vector2i(x, y)
			var t := b.t_at(p)
			if coperte.has(p) or (ha_suolo and t == Battaglia.T.APERTO):
				continue
			var r := Rect2(origine + Vector2(x, y) * lato, Vector2(lato, lato))
			rng.seed = x * 7919 + y * 104729
			var base: Color = COL.get(t, COL[0])
			base = base.lightened(rng.randf() * 0.05)
			draw_rect(r, base)
			match t:
				Battaglia.T.AREA:
					for i in 3:
						var c := r.position + Vector2(rng.randf(), rng.randf()) * lato
						draw_circle(c, lato * (0.14 + rng.randf() * 0.12), Color(0.12, 0.40, 0.16, 0.9))
				Battaglia.T.BLOCCO:
					draw_rect(r.grow(-2), Color(0.42, 0.44, 0.50))
					draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(lato - 4, lato * 0.22)), Color(0.55, 0.57, 0.63))
				Battaglia.T.LINEARE:
					draw_rect(Rect2(r.position + Vector2(0, lato * 0.36), Vector2(lato, lato * 0.28)), Color(0.62, 0.46, 0.26))
				Battaglia.T.SINGOLO:
					draw_circle(r.get_center(), lato * 0.36, Color(0.50, 0.34, 0.20))
					draw_arc(r.get_center(), lato * 0.36, 0, TAU, 20, Color(0.25, 0.16, 0.08), 2.0)
					draw_arc(r.get_center(), lato * 0.2, 0, TAU, 16, Color(0.36, 0.24, 0.13), 1.5)
				Battaglia.T.CAMPO:
					draw_line(r.position + Vector2(lato * 0.2, lato * 0.5), r.position + Vector2(lato * 0.8, lato * 0.5), Color(0.4, 0.55, 0.65, 0.6), 2.0)
				Battaglia.T.INTERNO:
					draw_rect(r, Color(0.27, 0.25, 0.22))
					draw_rect(r.grow(-lato * 0.06), Color(0.33, 0.30, 0.26))
					draw_line(r.position + Vector2(lato * 0.5, lato * 0.06), r.position + Vector2(lato * 0.5, lato * 0.94), Color(0.25, 0.22, 0.19), 1.0)
				Battaglia.T.MURO, Battaglia.T.PORTA, Battaglia.T.FINESTRA:
					_disegna_muro(p, r, t)
				Battaglia.T.MURO_FORZA:
					draw_rect(r.grow(-2), Color(0.25, 0.70, 0.85, 0.45))
			if b.impraticabili.has(p):
				draw_rect(r, Color(0.35, 0.75, 0.20, 0.35))
	_sovrapposizione(tot)
	_altezze()
	# griglia
	for x in b.W + 1:
		draw_line(origine + Vector2(x * lato, 0), origine + Vector2(x * lato, b.H * lato), Color(0, 0, 0, 0.22), 1.0)
	for y in b.H + 1:
		draw_line(origine + Vector2(0, y * lato), origine + Vector2(b.W * lato, y * lato), Color(0, 0, 0, 0.22), 1.0)
	# bordi di schieramento
	draw_rect(Rect2(origine + Vector2(0, (b.H - 1) * lato), Vector2(b.W * lato, lato)), Color(0.95, 0.68, 0.28, 0.07))
	draw_rect(Rect2(origine, Vector2(b.W * lato, lato)), Color(0.88, 0.33, 0.30, 0.07))
	# marcatori di obiettivo
	_marcatori()
	# caselle raggiungibili
	for p in raggiungibili_scatto:
		if not raggiungibili.has(p):
			draw_rect(Rect2(origine + Vector2(p) * lato, Vector2(lato, lato)).grow(-3), Color(0.95, 0.68, 0.28, 0.12))
	for p in raggiungibili:
		draw_rect(Rect2(origine + Vector2(p) * lato, Vector2(lato, lato)).grow(-3), Color(0.36, 0.78, 0.80, 0.22))
	if b.dentro(sopra):
		draw_rect(Rect2(origine + Vector2(sopra) * lato, Vector2(lato, lato)), Color(1, 1, 1, 0.5), false, 2.0)
	# linea dell'ultimo tiro
	if linea_tiro.size() == 2:
		draw_line(centro_cella(linea_tiro[0]), centro_cella(linea_tiro[1]), Color(1.0, 0.85, 0.4, 0.8), 2.5)
	# figure
	for u in b.unita:
		if not u.attiva:
			continue
		var c: Vector2 = anim.get(u.uid, centro_cella(u.pos))
		var nem: bool = u.lato == Battaglia.NEM
		var ev: bool = u.uid == selezionata
		if bersagli.has(u.uid):
			draw_circle(c, lato * 0.5, Color(0.9, 0.2, 0.2, 0.35))
		Pedine.disegna(self, c, lato * 0.42, str(u.pedina), str(u.nome), nem, ev, (u.lato == Battaglia.EQ and u.attivato) or u.get("passiva", false) or u.lato == "prigioniero")
		if u.lato == Battaglia.MOSTRI:
			draw_arc(c, lato * 0.47, 0, TAU, 24, Color(0.6, 0.9, 0.3), 2.5)
		if b._congelato(u):
			draw_arc(c, lato * 0.5, 0, TAU, 24, Color(0.5, 0.8, 1.0), 3.0)
		if u.get("attesa", "") == "snap":
			draw_arc(c, lato * 0.5, -PI * 0.8, -PI * 0.2, 12, UI.AMBRA, 3.0)
		if b.a_at(u.pos) > 0:
			var fa: Font = UI.font_titoli
			var hs := "%d" % b.a_at(u.pos)
			draw_string_outline(fa, c + Vector2(lato * 0.22, lato * 0.46), hs, HORIZONTAL_ALIGNMENT_LEFT, -1, int(lato * 0.32), 3, Color.BLACK)
			draw_string(fa, c + Vector2(lato * 0.22, lato * 0.46), hs, HORIZONTAL_ALIGNMENT_LEFT, -1, int(lato * 0.32), Color(0.75, 0.9, 1.0))
		# stordimento: piccoli cerchi grigi
		for i in int(u.stordito):
			draw_circle(c + Vector2(-lato * 0.36 + i * lato * 0.2, -lato * 0.42), lato * 0.09, Color(0.85, 0.85, 0.85))
		if u.get("luogotenente", false) or u.get("unico", false):
			draw_rect(Rect2(c + Vector2(lato * 0.22, -lato * 0.48), Vector2(lato * 0.22, lato * 0.22)), UI.AMBRA if u.unico else UI.ACQUA)
		if u.porta != "":
			draw_rect(Rect2(c + Vector2(lato * 0.2, lato * 0.2), Vector2(lato * 0.24, lato * 0.24)), Color(0.9, 0.8, 0.3))
		if u.get("bersaglio", false):
			draw_arc(c, lato * 0.5, 0, TAU, 24, UI.ROSSO, 2.0)
		if bersagli.has(u.uid):
			var f: Font = UI.font_titoli
			var s := "%d+" % int(bersagli[u.uid])
			draw_string_outline(f, c + Vector2(-lato * 0.3, lato * 0.62), s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(lato * 0.4), 4, Color.BLACK)
			draw_string(f, c + Vector2(-lato * 0.3, lato * 0.62), s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(lato * 0.4), Color(1, 0.85, 0.5))

## ---------------- grafica del campo ----------------

func _mappa(nome: String) -> Texture2D:
	return Immagini.texture("mappe/" + nome)

func _elem(nome: String) -> Texture2D:
	return Immagini.texture("mappe/elementi/" + nome)

func _rett_cella(p: Vector2i) -> Rect2:
	return Rect2(origine + Vector2(p) * lato, Vector2(lato, lato))

func _bbox(celle: Array) -> Rect2:
	var a := Vector2i(999, 999)
	var z := Vector2i(-1, -1)
	for c in celle:
		a = Vector2i(min(a.x, c.x), min(a.y, c.y))
		z = Vector2i(max(z.x, c.x), max(z.y, c.y))
	return Rect2(origine + Vector2(a) * lato, Vector2(z - a + Vector2i.ONE) * lato)

## Fondo del tavolo: plancia intera dell'ambiente o, in mancanza, la texture del suolo ripetuta ogni 4 caselle.
func _suolo(tot: Rect2) -> bool:
	var amb := str(b.ambiente)
	var plancia := _mappa("plancia_" + amb)
	if plancia != null:
		draw_texture_rect(plancia, tot, false)
		return true
	var suolo := _mappa("suolo_" + amb)
	if suolo == null:
		return false
	for y in range(0, b.H, 4):
		for x in range(0, b.W, 4):
			var n := Vector2(min(4, b.W - x), min(4, b.H - y))
			draw_texture_rect_region(suolo, Rect2(origine + Vector2(x, y) * lato, n * lato), Rect2(Vector2.ZERO, suolo.get_size() * n / 4.0))
	return true

## Disegna un'immagine nel rettangolo; se l'immagine è orizzontale e il rettangolo verticale la ruota di 90 gradi.
func _disegna_in(tex: Texture2D, r: Rect2, orientabile: bool) -> void:
	var ts := tex.get_size()
	if orientabile and ts.x > ts.y * 1.1 and r.size.y > r.size.x * 1.1:
		draw_set_transform(r.get_center(), PI / 2.0, Vector2.ONE)
		draw_texture_rect(tex, Rect2(-Vector2(r.size.y, r.size.x) / 2.0, Vector2(r.size.y, r.size.x)), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect(tex, r, false)

## Ostacolo lineare: un quarto della striscia (lunga 4 caselle) per casella, ruotato dove l'ostacolo è verticale.
func _disegna_lineare(tex: Texture2D, celle: Array) -> void:
	var ts := tex.get_size()
	var quarto := Vector2(ts.x / 4.0, ts.y)
	for c in celle:
		var oriz: bool = (c + Vector2i.LEFT) in celle or (c + Vector2i.RIGHT) in celle
		var vert: bool = (c + Vector2i.UP) in celle or (c + Vector2i.DOWN) in celle
		var r := _rett_cella(c)
		var alto := lato * quarto.y / quarto.x
		if oriz or not vert:
			var src := Rect2(Vector2(float(posmod(c.x, 4)) * quarto.x, 0), quarto)
			draw_texture_rect_region(tex, Rect2(r.position.x, r.get_center().y - alto / 2.0, lato, alto), src)
		if vert:
			var src := Rect2(Vector2(float(posmod(c.y, 4)) * quarto.x, 0), quarto)
			draw_set_transform(r.get_center(), PI / 2.0, Vector2.ONE)
			draw_texture_rect_region(tex, Rect2(-lato / 2.0, -alto / 2.0, lato, alto), src)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Disegna gli elementi di terreno che hanno un'immagine; restituisce le caselle coperte (niente disegno di ripiego).
func _elementi_grafici() -> Dictionary:
	var coperte := {}
	var amb := str(b.ambiente)
	var campo := _mappa("campo_" + amb)
	if campo != null:
		var q := campo.get_size() / 4.0
		for y in b.H:
			for x in b.W:
				if b.t_at(Vector2i(x, y)) == Battaglia.T.CAMPO:
					draw_texture_rect_region(campo, _rett_cella(Vector2i(x, y)), Rect2(Vector2(x % 4, y % 4) * q, q))
					coperte[Vector2i(x, y)] = true
	# prima le aree (stanno sotto), poi il resto
	var ordinati := b.elementi.filter(func(e): return e.tipo == Battaglia.T.AREA) + b.elementi.filter(func(e): return e.tipo != Battaglia.T.AREA)
	var solidi := {}
	for e in ordinati:
		var nome := str(e.nome)
		var celle: Array = e.celle
		if e.get("interno", false):
			continue
		if e.tipo in [Battaglia.T.BLOCCO, Battaglia.T.SINGOLO]:
			for c in celle:
				solidi[c] = true
		if PER_CELLA.has(nome):
			var tex := _elem(PER_CELLA[nome])
			if tex == null:
				continue
			var g := 1.3 if nome == "Alberi" else 1.05
			for c in celle:
				var r := _rett_cella(c)
				draw_texture_rect(tex, Rect2(r.get_center() - r.size * g / 2.0, r.size * g), false)
				coperte[c] = true
		elif LINEARI.has(nome):
			var tex := _elem(LINEARI[nome])
			if tex == null:
				continue
			_disegna_lineare(tex, celle)
			for c in celle:
				coperte[c] = true
		elif ELEMENTI_IMG.has(nome):
			var chiave: String = ELEMENTI_IMG[nome]
			if chiave == "edificio" and celle.size() >= 20 and _elem("edificio_grande") != null:
				chiave = "edificio_grande"
			var tex := _elem(chiave)
			if tex == null:
				continue
			var area: bool = e.tipo == Battaglia.T.AREA
			_disegna_in(tex, _bbox(celle).grow(lato * (0.2 if area else 0.05)), chiave in ORIENTABILI)
			for c in celle:
				if b.t_at(c) == e.tipo:
					coperte[c] = true
	# pezzi di muro rimasti in piedi tra le rovine (blocchi che non appartengono a nessun elemento solido)
	var muro := _elem("rovine_muro")
	if muro != null:
		for y in b.H:
			for x in b.W:
				var p := Vector2i(x, y)
				if b.t_at(p) == Battaglia.T.BLOCCO and not solidi.has(p):
					draw_texture_rect(muro, _rett_cella(p).grow(lato * 0.08), false)
					coperte[p] = true
	return coperte

## Nebbia, buio, polvere o gas sopra il terreno, secondo la condizione di schieramento, l'evento o il mondo.
func _sovrapposizione(tot: Rect2) -> void:
	var cond := str(b.setup.get("condizione", {}).get("nome", ""))
	var ev := str(b.ultimo_evento.get("nome", ""))
	var tratti := " ".join(b.tratti_mondo).to_lower()
	var nome := ""
	if ev == "Banco di nebbia" or (ev == "Cambio di visibilità" and b.visibilita > 0):
		nome = "nebbia"
	elif cond == "Buio":
		nome = "buio"
	elif cond == "Scarsa visibilità":
		nome = "tempesta_polvere"
	elif cond == "Ambiente tossico":
		nome = "gas_tossico"
	elif tratti.contains("nebbia") or tratti.contains("foschia"):
		nome = "nebbia"
	elif tratti.contains("oscurità"):
		nome = "buio"
	if nome == "":
		return
	var tex := _mappa("sovrapposizioni/" + nome)
	if tex == null:
		return
	var alfa: float = {"nebbia": 0.5, "buio": 0.55, "tempesta_polvere": 0.4, "gas_tossico": 0.28}.get(nome, 0.5)
	var passo := 8
	for y in range(0, b.H, passo):
		for x in range(0, b.W, passo):
			var n := Vector2(min(passo, b.W - x), min(passo, b.H - y))
			draw_texture_rect_region(tex, Rect2(origine + Vector2(x, y) * lato, n * lato), Rect2(Vector2.ZERO, tex.get_size() * n / float(passo)), Color(1, 1, 1, alfa))

func _rombo(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)

func _marcatori() -> void:
	var cc := centro_cella(b.centro)
	var verde := Color(0.5, 0.9, 0.5, 0.9)
	if b.obiettivo in ["consegnare", "accedere", "acquisire", "assicurare", "proteggere"]:
		draw_arc(cc, lato * (2.5 if b.obiettivo in ["assicurare"] else 0.6), 0, TAU, 40, Color(0.5, 0.9, 0.5, 0.8), 2.0)
		var seg: String = str({"accedere": "segnalino_console", "consegnare": "obiettivo_consegna"}.get(b.obiettivo, ""))
		if not (seg != "" and Pedine.disegna_segnalino(self, cc, lato * 0.45, seg, verde)):
			if not b.stato_obj.has("oggetto_a"):
				_rombo(cc, lato * 0.3, verde)
		if b.obiettivo == "proteggere":
			draw_arc(cc, lato * 3.5, 0, TAU, 48, Color(0.5, 0.9, 0.5, 0.5), 2.0)
	var oro := Color(0.95, 0.85, 0.3)
	if b.stato_obj.has("oggetto_a"):
		var c := centro_cella(b.stato_obj.oggetto_a)
		if not Pedine.disegna_segnalino(self, c, lato * 0.45, "segnalino_pacco", oro):
			_rombo(c, lato * 0.32, oro)
	if b.stato_obj.has("caduto"):
		var c := centro_cella(b.stato_obj.caduto.pos)
		if not Pedine.disegna_segnalino(self, c, lato * 0.4, "segnalino_pacco", oro):
			_rombo(c, lato * 0.28, oro)
	for pt in b.stato_obj.get("punti", []):
		var c := centro_cella(pt.cella)
		var col := Color(0.5, 0.9, 0.5) if not pt.fatto else Color(0.5, 0.5, 0.5)
		if not Pedine.disegna_segnalino(self, c, lato * 0.45, "obiettivo_pattuglia", col, pt.fatto):
			draw_arc(c, lato * 0.45, 0, TAU, 24, col, 3.0)
	for sg in b.stato_obj.get("segnalini", []):
		if not sg.fatto:
			var c := centro_cella(sg.cella)
			if not Pedine.disegna_segnalino(self, c, lato * 0.42, "segnalino_perquisire", verde):
				draw_rect(Rect2(c - Vector2(lato * 0.2, lato * 0.2), Vector2(lato * 0.4, lato * 0.4)), verde, false, 3.0)
	if b.stato_obj.has("luogo_pos") and not b.stato_obj.get("luogo_preso", false):
		var c := centro_cella(b.stato_obj.luogo_pos)
		if not Pedine.disegna_segnalino(self, c, lato * 0.42, "segnalino_luogo", UI.ACQUA):
			draw_circle(c, lato * 0.28, Color(0.36, 0.78, 0.80, 0.9))
			draw_circle(c, lato * 0.14, Color(0.05, 0.1, 0.12))

## Altezza dei blocchi scalabili (in pollici), al centro dell'elemento.
func _altezze() -> void:
	var f: Font = UI.font_titoli
	for e in b.elementi:
		if e.tipo != Battaglia.T.BLOCCO or e.celle.is_empty():
			continue
		var c := _bbox(e.celle).get_center()
		var s := "%d\"" % int(e.get("altezza", b.a_at(e.celle[0])))
		var dim := int(lato * 0.42)
		draw_string_outline(f, c + Vector2(-lato * 0.25, lato * 0.15), s, HORIZONTAL_ALIGNMENT_LEFT, -1, dim, 4, Color(0, 0, 0, 0.9))
		draw_string(f, c + Vector2(-lato * 0.25, lato * 0.15), s, HORIZONTAL_ALIGNMENT_LEFT, -1, dim, Color(0.85, 0.92, 1.0))
	for sg in b.segnalini:
		var c := centro_cella(sg.pos)
		if sg.tipo == "rinforzi":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -lato * 0.35), c + Vector2(lato * 0.32, lato * 0.28), c + Vector2(-lato * 0.32, lato * 0.28)]), Color(0.88, 0.33, 0.30, 0.85))
		else:
			if not Pedine.disegna_segnalino(self, c, lato * 0.4, "segnalino_pacco", Color(0.95, 0.85, 0.3)):
				_rombo(c, lato * 0.3, Color(0.95, 0.85, 0.3))
	if not b.nebbia.is_empty():
		var nc := centro_cella(b.nebbia.centro)
		draw_circle(nc, lato * (float(b.nebbia.raggio) + 0.5), Color(0.8, 0.82, 0.85, 0.22))

## Muro di un edificio: lastra scura continua con bordo ambrato; porte e finestre come strisce lungo il muro.
func _disegna_muro(p: Vector2i, r: Rect2, t: int) -> void:
	draw_rect(r, Color(0.10, 0.10, 0.11))
	var oriz := b.t_at(p + Vector2i.LEFT) in [Battaglia.T.MURO, Battaglia.T.PORTA, Battaglia.T.FINESTRA] or b.t_at(p + Vector2i.RIGHT) in [Battaglia.T.MURO, Battaglia.T.PORTA, Battaglia.T.FINESTRA]
	var vert := b.t_at(p + Vector2i.UP) in [Battaglia.T.MURO, Battaglia.T.PORTA, Battaglia.T.FINESTRA] or b.t_at(p + Vector2i.DOWN) in [Battaglia.T.MURO, Battaglia.T.PORTA, Battaglia.T.FINESTRA]
	var piastra := Color(0.30, 0.31, 0.33)
	draw_rect(r.grow(-lato * 0.08), piastra)
	draw_rect(r.grow(-lato * 0.08), UI.BORDO.darkened(0.35), false, 1.5)
	var striscia: Rect2
	if oriz and not vert:
		striscia = Rect2(r.position + Vector2(lato * 0.08, lato * 0.36), Vector2(lato * 0.84, lato * 0.28))
	else:
		striscia = Rect2(r.position + Vector2(lato * 0.36, lato * 0.08), Vector2(lato * 0.28, lato * 0.84))
	if t == Battaglia.T.FINESTRA:
		draw_rect(striscia, Color(0.50, 0.72, 0.82, 0.95))
		draw_rect(striscia, Color(0.85, 0.95, 1.0, 0.8), false, 1.0)
	elif t == Battaglia.T.PORTA:
		if b.porte_aperte.has(p):
			draw_rect(r.grow(-lato * 0.08), Color(0.33, 0.30, 0.26))
		else:
			var porta := Rect2(r.position + Vector2(lato * 0.14, lato * 0.14), Vector2(lato * 0.72, lato * 0.72))
			draw_rect(porta, Color(0.58, 0.38, 0.18))
			draw_rect(porta, Color(0.95, 0.68, 0.28), false, 2.0)
