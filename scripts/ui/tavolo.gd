## Disegno del campo di battaglia su griglia: terreno, figure, caselle raggiungibili, bersagli, marcatori.
class_name Tavolo2D
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
var colpi: Array = []    # animazioni in corso: {da, a, lato, n, t, rissa}
var ultimo_tiro := {}    # freccia dell'ultimo tiro: {da, a, lato, t}; sfuma e sparisce dopo qualche secondo
var esplosioni: Array = [] # {pos, raggio, genere, t (negativo = in attesa che arrivi il colpo)}
var _atm_tipo := "?"
var _atm_nodi: Array = []
var _ritaglio: Control
var mostra_vista := true # linea di vista dal personaggio selezionato alla casella sotto il mouse

const VOLO := 0.32       # durata del volo di un colpo (secondi)
const RITMO := 0.11      # intervallo tra i colpi di una raffica

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	resized.connect(_calcola)
	set_process(false)

## ---------------- colpi e risse animati ----------------

## Tiro da una casella all'altra: i colpi partono da chi spara e arrivano a chi è colpito.
func spara(da: Vector2i, a: Vector2i, lato_: String, n := 1, genere := "proiettile") -> void:
	colpi.append({"da": da, "a": a, "lato": lato_, "n": clampi(n, 1, 6), "t": 0.0, "rissa": false, "genere": genere})
	ultimo_tiro = {"da": da, "a": a, "lato": lato_, "t": 0.0}
	set_process(true)

## Esplosione (granata, lanciagranate, cariche) o vampata (lanciafiamme) nella casella, dopo il ritardo in secondi.
func esplosione(pos: Vector2i, raggio: int, genere: String, ritardo := 0.0) -> void:
	esplosioni.append({"pos": pos, "raggio": raggio, "genere": genere, "t": -ritardo, "scoppiata": false})
	set_process(true)

func rissa(da: Vector2i, a: Vector2i, lato_: String) -> void:
	colpi.append({"da": da, "a": a, "lato": lato_, "n": 1, "t": 0.0, "rissa": true})
	set_process(true)

## Durata complessiva di un'animazione (per attendere prima di passare al nemico successivo).
const VOLO_GRANATA := 0.6

static func durata(c: Dictionary) -> float:
	if c.get("rissa", false):
		return 0.5
	match str(c.get("genere", "")):
		"granata":
			return VOLO_GRANATA
		"fiamma":
			return VOLO + 0.7
	return VOLO + RITMO * (int(c.n) - 1) + 0.25

## Momento (secondi dall'inizio del tiro) in cui il colpo arriva: lì parte l'esplosione.
static func arrivo(genere: String) -> float:
	match genere:
		"granata":
			return VOLO_GRANATA
		"fiamma":
			return VOLO * 0.8
	return VOLO

const DURATA_FRECCIA := 2.5   # secondi prima che la freccia dell'ultimo tiro sparisca
const DURATA_ESPLOSIONE := 0.9

func _process(d: float) -> void:
	for c in colpi:
		c.t += d
	colpi = colpi.filter(func(c): return c.t < durata(c))
	for e in esplosioni:
		e.t += d
		if e.t >= 0.0 and not e.scoppiata:
			e.scoppiata = true
			_scoppio(e)
	esplosioni = esplosioni.filter(func(e): return e.t < DURATA_ESPLOSIONE)
	if not ultimo_tiro.is_empty():
		ultimo_tiro.t = float(ultimo_tiro.get("t", 0.0)) + d
		if ultimo_tiro.t > DURATA_FRECCIA:
			ultimo_tiro = {}
	if colpi.is_empty() and esplosioni.is_empty() and ultimo_tiro.is_empty():
		set_process(false)
	queue_redraw()

static func colore_lato(l: String) -> Color:
	if l == Battaglia.EQ:
		return Color(1.0, 0.78, 0.35)
	if l == Battaglia.MOSTRI:
		return Color(0.6, 0.95, 0.35)
	if l == Battaglia.NEU:
		return Color(0.72, 0.80, 0.90)
	return Color(1.0, 0.35, 0.3)


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
	# freccia dell'ultimo tiro (sotto le figure)
	_freccia_tiro()
	# figure
	for u in b.unita:
		if not u.attiva:
			continue
		var c: Vector2 = anim.get(u.uid, centro_cella(u.pos))
		var nem: bool = u.lato == Battaglia.NEM
		var ev: bool = u.uid == selezionata
		if bersagli.has(u.uid):
			draw_circle(c, lato * 0.5, Color(0.9, 0.2, 0.2, 0.35))
		Pedine.disegna(self, c, lato * 0.42, str(u.pedina), str(u.nome), nem, ev, (u.lato == Battaglia.EQ and u.attivato) or u.get("passiva", false) or u.lato == "prigioniero", colore_lato(u.lato) if u.lato == Battaglia.NEU else Color(0, 0, 0, 0))
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
	_linea_vista()
	_disegna_colpi()
	_disegna_esplosioni()
	_aggiorna_atmosfera.call_deferred()

## ---------------- linea di vista, tiri ----------------

func _unita(uid: int) -> Dictionary:
	for u in b.unita:
		if u.uid == uid:
			return u
	return {}

## Freccia dell'ultimo tiro: da chi ha sparato a chi è stato bersagliato.
func _freccia_tiro() -> void:
	if ultimo_tiro.is_empty():
		return
	var a := centro_cella(ultimo_tiro.da)
	var z := centro_cella(ultimo_tiro.a)
	if a.distance_to(z) < 1:
		return
	var col := colore_lato(str(ultimo_tiro.lato))
	var t := float(ultimo_tiro.get("t", 0.0))
	col.a = 0.55 * clampf((DURATA_FRECCIA - t) / 0.8, 0.0, 1.0)
	if col.a <= 0.01:
		return
	var dir := (z - a).normalized()
	var punta := z - dir * lato * 0.45
	draw_line(a + dir * lato * 0.45, punta, col, 2.5, true)
	var n := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([punta + dir * lato * 0.02, punta - dir * lato * 0.3 + n * lato * 0.16, punta - dir * lato * 0.3 - n * lato * 0.16]), col)

## Colpi in volo e lampi d'impatto.
func _disegna_colpi() -> void:
	for c in colpi:
		var a := centro_cella(c.da)
		var z := centro_cella(c.a)
		var col := colore_lato(str(c.lato))
		if c.rissa:
			var m := (a + z) / 2.0
			var k: float = clampf(c.t / 0.5, 0.0, 1.0)
			draw_arc(m, lato * (0.2 + 0.5 * k), 0, TAU, 24, Color(col.r, col.g, col.b, 1.0 - k), 3.0)
			draw_line(a, z, Color(col.r, col.g, col.b, 0.8 * (1.0 - k)), 3.0, true)
			continue
		var dir := (z - a).normalized()
		var da := a + dir * lato * 0.4
		var gen := str(c.get("genere", "proiettile"))
		if gen == "granata":
			# lanciata ad arco: la granata sale e scende, con l'ombra sul terreno
			var k: float = clampf(float(c.t) / VOLO_GRANATA, 0.0, 1.0)
			if k < 1.0:
				var p := da.lerp(z, k)
				var alto := sin(PI * k) * lato * 1.6
				draw_circle(p, lato * 0.18 * (1.0 - 0.4 * sin(PI * k)), Color(0, 0, 0, 0.35))
				draw_circle(p - Vector2(0, alto), lato * 0.22, Color(0.25, 0.3, 0.22))
				draw_circle(p - Vector2(0, alto), lato * 0.22, Color(1.0, 0.85, 0.4), false, 2.5)
			continue
		if gen == "fiamma":
			# getto di fuoco: sbuffi arancioni che corrono verso il bersaglio
			for j in 10:
				var k: float = float(c.t) / VOLO - j * 0.07
				if k >= 0.0 and k <= 1.0:
					var p := da.lerp(z, k)
					var r := lato * (0.12 + 0.3 * k)
					draw_circle(p, r, Color(1.0, 0.45 + 0.3 * (1.0 - k), 0.1, 0.75 * (1.0 - k * 0.6)))
			continue
		for i in int(c.n):
			var t0 := RITMO * i
			var k: float = (float(c.t) - t0) / VOLO
			if k >= 0.0 and k <= 1.0:
				var testa := da.lerp(z, k)
				var coda := da.lerp(z, maxf(0.0, k - 0.3))
				draw_line(coda, testa, Color(col.r, col.g, col.b, 0.85), 3.0, true)
				draw_circle(testa, lato * 0.09, Color(1, 1, 0.9))
				if k < 0.3:
					draw_circle(da, lato * 0.16 * (1.0 - k / 0.3), Color(1, 0.95, 0.7, 0.9))
			elif k > 1.0 and k < 1.0 + 0.25 / VOLO:
				var e: float = (k - 1.0) * VOLO / 0.25
				draw_arc(z, lato * (0.15 + 0.45 * e), 0, TAU, 20, Color(1, 0.9, 0.6, 1.0 - e), 2.5)

## Linea di vista dal personaggio selezionato alla casella sotto il mouse: verde libera, gialla con copertura,
## rossa dove si interrompe (con una X sull'ostacolo).
func _linea_vista() -> void:
	if not mostra_vista or selezionata < 0 or not b.dentro(sopra):
		return
	var u := _unita(selezionata)
	if u.is_empty() or not u.attiva or u.pos == sopra:
		return
	var info := LineaVista.vista(b, u, sopra)
	var a := centro_cella(u.pos)
	var z := centro_cella(sopra)
	var col: Color = info.colore
	if info.blocco != null:
		var m := centro_cella(info.blocco)
		draw_line(a, m, LineaVista.VERDE, 2.5, true)
		draw_line(m, z, Color(col.r, col.g, col.b, 0.6), 2.0, true)
		var q := lato * 0.22
		draw_line(m - Vector2(q, q), m + Vector2(q, q), col, 3.5)
		draw_line(m - Vector2(q, -q), m + Vector2(q, -q), col, 3.5)
	else:
		draw_line(a, z, col, 2.5, true)
		draw_circle(z, lato * 0.1, col)
	var testo: String = info.testo
	var fo: Font = UI.font_titoli
	var dim := int(clampf(lato * 0.45, 15, 22))
	var pos := z + Vector2(lato * 0.55, -lato * 0.35)
	var w := fo.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT, -1, dim).x
	if pos.x + w > origine.x + lato * b.W:
		pos.x = z.x - lato * 0.55 - w
	draw_string_outline(fo, pos, testo, HORIZONTAL_ALIGNMENT_LEFT, -1, dim, 4, Color(0, 0, 0, 0.9))
	draw_string(fo, pos, testo, HORIZONTAL_ALIGNMENT_LEFT, -1, dim, Color.WHITE)

## ---------------- esplosioni e particelle ----------------

## Lampo e anello del raggio d'effetto (le scintille e il fumo sono particelle).
func _disegna_esplosioni() -> void:
	for e in esplosioni:
		if e.t < 0.0:
			continue
		var k: float = clampf(e.t / DURATA_ESPLOSIONE, 0.0, 1.0)
		var c := centro_cella(e.pos)
		var cols: Array = Atmosfera.colori_esplosione(str(e.genere))
		var lampo: Color = cols[0]
		var r := (float(e.raggio) + 0.5) * lato
		draw_circle(c, r * minf(1.0, k * 5.0), Color(lampo.r, lampo.g, lampo.b, 0.55 * (1.0 - k)))
		draw_arc(c, r, 0, TAU, 48, Color(lampo.r, lampo.g, lampo.b, 0.9 * (1.0 - k)), 3.0)
		if str(e.genere) == "accecante" and k < 0.35:
			draw_rect(Rect2(origine, Vector2(b.W, b.H) * lato), Color(1, 1, 1, 0.35 * (1.0 - k / 0.35)))

## Particelle di un'esplosione: scintille veloci e fumo lento.
func _scoppio(e: Dictionary) -> void:
	var c := centro_cella(e.pos)
	var cols: Array = Atmosfera.colori_esplosione(str(e.genere))
	var r := (float(e.raggio) + 0.5) * lato
	var n := 60 if str(e.genere) == "cariche" else 36
	_particelle_scoppio(c, cols[1], n, r * 2.2, 0.55, lato * 0.18 / 64.0 * 2.0)
	_particelle_scoppio(c, cols[2], int(n / 2.0), r * 0.7, 1.6, lato * 0.9 / 64.0 * 2.0)

func _particelle_scoppio(c: Vector2, col: Color, n: int, vel: float, vita: float, scala: float) -> void:
	var p := CPUParticles2D.new()
	p.position = c
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = maxi(4, n)
	p.lifetime = vita
	p.texture = Atmosfera.morbida()
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = vel * 0.35
	p.initial_velocity_max = vel
	p.damping_min = vel * 0.9
	p.damping_max = vel * 1.3
	p.scale_amount_min = scala * 0.6
	p.scale_amount_max = scala * 1.4
	p.color_ramp = Atmosfera.sfuma(col)
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(p)
	p.emitting = true
	get_tree().create_timer(vita + 0.3).timeout.connect(p.queue_free)

## Nebbia, polvere, gas o lucciole notturne che si muovono sul campo; banco di nebbia locale degli eventi.
func _aggiorna_atmosfera() -> void:
	if b == null:
		return
	var tipo := Atmosfera.tipo(b)
	var firma := "%s|%s|%s|%s" % [tipo, b.nebbia, lato, origine]
	if firma == _atm_tipo:
		return
	_atm_tipo = firma
	for n in _atm_nodi:
		(n as Node).queue_free()
	_atm_nodi = []
	var area := Vector2(b.W, b.H) * lato
	if _ritaglio == null:
		_ritaglio = Control.new()
		_ritaglio.clip_contents = true
		_ritaglio.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_ritaglio)
	_ritaglio.position = origine
	_ritaglio.size = area
	var centro := area / 2.0
	match tipo:
		"nebbia":
			_atm_nodi.append(_strato(centro, area / 2.0, Color(0.92, 0.94, 0.97, 0.16), 36, 16.0, Vector2(lato * 0.35, 0), lato * 5.0))
		"polvere":
			_atm_nodi.append(_strato(centro, area / 2.0, Color(0.82, 0.62, 0.38, 0.12), 26, 9.0, Vector2(lato * 1.2, lato * 0.1), lato * 6.0))
			_atm_nodi.append(_strato(centro, area / 2.0, Color(0.9, 0.72, 0.45, 0.55), 140, 3.0, Vector2(lato * 5.0, lato * 0.6), lato * 0.25))
		"gas":
			_atm_nodi.append(_strato(centro, area / 2.0, Color(0.55, 0.85, 0.25, 0.16), 34, 14.0, Vector2(lato * 0.2, -lato * 0.15), lato * 5.0))
		"buio":
			_atm_nodi.append(_strato(centro, area / 2.0, Color(0.85, 1.0, 0.45, 0.85), 30, 6.0, Vector2(lato * 0.25, -lato * 0.2), lato * 0.22, true))
	if not b.nebbia.is_empty():
		var nc := centro_cella(b.nebbia.centro) - origine
		var nr := (float(b.nebbia.raggio) + 0.5) * lato
		_atm_nodi.append(_strato(nc, Vector2(nr, nr) * 0.8, Color(0.95, 0.96, 0.98, 0.28), 30, 10.0, Vector2(lato * 0.2, 0), lato * 3.5))

## Strato di particelle persistenti su un rettangolo (estensione = metà lati).
func _strato(c: Vector2, est: Vector2, col: Color, n: int, vita: float, vel: Vector2, dim: float, lucciole := false) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = c
	p.amount = n
	p.lifetime = vita
	p.preprocess = vita
	p.texture = Atmosfera.morbida()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = est
	p.direction = vel.normalized() if vel.length() > 0 else Vector2.RIGHT
	p.spread = 25.0 if not lucciole else 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = vel.length() * 0.5
	p.initial_velocity_max = vel.length() * 1.2
	var sc := dim / 64.0
	p.scale_amount_min = sc * 0.6
	p.scale_amount_max = sc * 1.3
	var g := Gradient.new()
	g.set_color(0, Color(col.r, col.g, col.b, 0.0))
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	g.add_point(0.3, col)
	g.add_point(0.7, col)
	p.color_ramp = g
	if lucciole:
		p.hue_variation_min = -0.05
		p.hue_variation_max = 0.05
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_ritaglio.add_child(p)
	p.emitting = true
	return p

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
