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
}

func _draw() -> void:
	if b == null:
		return
	if lato < 2:
		_calcola()
	var tot := Rect2(origine, Vector2(lato * b.W, lato * b.H))
	draw_rect(tot.grow(6), Color(0.05, 0.05, 0.06))
	draw_rect(tot.grow(6), UI.BORDO.darkened(0.3), false, 2.0)
	var rng := RandomNumberGenerator.new()
	for y in b.H:
		for x in b.W:
			var p := Vector2i(x, y)
			var t := b.t_at(p)
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
		Pedine.disegna(self, c, lato * 0.42, str(u.pedina), str(u.nome), nem, ev, u.lato == Battaglia.EQ and u.attivato)
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

func _rombo(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)

func _marcatori() -> void:
	var cc := centro_cella(b.centro)
	if b.obiettivo in ["consegnare", "accedere", "acquisire", "assicurare", "proteggere"]:
		draw_arc(cc, lato * (2.5 if b.obiettivo in ["assicurare"] else 0.6), 0, TAU, 40, Color(0.5, 0.9, 0.5, 0.8), 2.0)
		_rombo(cc, lato * 0.3, Color(0.5, 0.9, 0.5, 0.9))
		if b.obiettivo == "proteggere":
			draw_arc(cc, lato * 3.5, 0, TAU, 48, Color(0.5, 0.9, 0.5, 0.5), 2.0)
	if b.stato_obj.has("oggetto_a"):
		_rombo(centro_cella(b.stato_obj.oggetto_a), lato * 0.32, Color(0.95, 0.85, 0.3))
	if b.stato_obj.has("caduto"):
		_rombo(centro_cella(b.stato_obj.caduto.pos), lato * 0.28, Color(0.95, 0.85, 0.3))
	for pt in b.stato_obj.get("punti", []):
		var c := centro_cella(pt.cella)
		draw_arc(c, lato * 0.45, 0, TAU, 24, Color(0.5, 0.9, 0.5) if not pt.fatto else Color(0.5, 0.5, 0.5), 3.0)
	for sg in b.stato_obj.get("segnalini", []):
		if not sg.fatto:
			var c := centro_cella(sg.cella)
			draw_rect(Rect2(c - Vector2(lato * 0.2, lato * 0.2), Vector2(lato * 0.4, lato * 0.4)), Color(0.5, 0.9, 0.5, 0.9), false, 3.0)
	if b.stato_obj.has("luogo_pos") and not b.stato_obj.get("luogo_preso", false):
		var c := centro_cella(b.stato_obj.luogo_pos)
		draw_circle(c, lato * 0.28, Color(0.36, 0.78, 0.80, 0.9))
		draw_circle(c, lato * 0.14, Color(0.05, 0.1, 0.12))
