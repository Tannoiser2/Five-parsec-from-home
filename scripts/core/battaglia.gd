## Battaglia su griglia (Appendice II: 1 casella = 1 pollice, diagonale = 1).
## Motore senza interfaccia, allineato al regolamento: terreno con altezze e interni (p.37-39), azioni (p.40),
## movimento, salti e movimenti alternativi (p.41-42), tiro, rissa, danni, Fortuna e mira (p.44-47),
## round con dadi delle reazioni, Snap Fire, fasi e morale (p.112-114), eventi della battaglia (p.116-117),
## condizioni di schieramento (p.88), regole speciali dei nemici e delle specie, equipaggiamento in battaglia.
## L'IA dei nemici è in ia.gd.
class_name Battaglia
extends RefCounted

## Tipi di terreno (p.37): i primi sei valori non cambiano (li usa la grafica).
enum T { APERTO, LINEARE, AREA, BLOCCO, SINGOLO, CAMPO, MURO, PORTA, FINESTRA, INTERNO, MURO_FORZA }
const NOMI_TERRENO := {T.APERTO: "terreno aperto", T.LINEARE: "ostacolo lineare (muretto, barricata): si scavalca con 1\" in più, dà copertura",
	T.AREA: "area (vegetazione, macerie): difficile, blocca la vista", T.BLOCCO: "blocco (masso, container, edificio chiuso): si scala pagando l'altezza",
	T.SINGOLO: "elemento singolo (barile, albero): invalicabile, non blocca la vista, dà copertura", T.CAMPO: "campo (fango, acqua): difficile, nessuna copertura",
	T.MURO: "muro di un edificio: invalicabile, blocca la vista", T.PORTA: "porta: aprirla costa 1\"", T.FINESTRA: "finestra: passarci costa 2\", dà copertura",
	T.INTERNO: "interno di un edificio", T.MURO_FORZA: "muro di forza: invalicabile, non blocca la vista ma ferma i colpi"}
## Altezze convenzionali (pollici) per la linea di vista
const H_LINEARE := 1.0
const H_SINGOLO := 2.0
const H_AREA := 2.0
const H_MURO := 3.0
const H_FIGURA := 1.2

const EQ := "eq"
const NEM := "nem"
const MOSTRI := "mostri"   # «Bestiacce!»: ostili a tutti

var W := 24
var H := 24
var celle := PackedInt32Array()
var alt := PackedInt32Array()   # altezza della superficie su cui si sta (0 = suolo)
var impraticabili := {}         # caselle di campo invalicabili (pozze tossiche)
var porte_aperte := {}
var elementi: Array = []   # {id, nome, tipo, celle: [Vector2i], grande: bool, altezza: int, interno: bool}
var unita: Array = []      # figure (Dictionary)
var dadi: Dadi
var round_n := 0
var fase := "preparazione"  # preparazione, iniziativa, reazioni, rapida, nemici, lenta, fine, finita
var log_righe: Array = []
var eventi: Array = []     # eventi grafici per l'animazione: {tipo, ...}
var setup: Dictionary = {}
var obiettivo := "respingere"
var par_obiettivo: Dictionary = {}
var cond: Dictionary = {}  # effetti della condizione di schieramento
var centro := Vector2i(12, 12)
var stato_obj := {}
var perdite_round := 0
var perdite_totali := 0
var morale_extra := 0
var esito_finale := {}
var visibilita := 0        # 0 = illimitata
var nebbia := {}           # {"centro": Vector2i, "raggio": 6, "vis": 2}
var primo_colpo := ""
var unico_ucciso := ""
var ia_script = null
var eventi_battaglia := true
var ambiente := "frontiera"
var tratti_mondo: Array = []
var ultimo_evento := {}
var dadi_reazione: Array = []   # dadi del tiro delle reazioni da assegnare
var effetti_round := {}         # effetti degli eventi validi per un round: {round: {chiave: valore}}
var effetti_battaglia := {}     # effetti degli eventi validi per il resto della battaglia
var segnalini: Array = []       # segnalini sul campo: {tipo, pos, ...}
var ritardati: Array = []       # personaggi che arrivano dopo (condizione «In ritardo»)
var riserve: Array = []         # personaggi non schierati (evento «Rinforzi»)
var risse_in_attesa: Array = [] # risse dello Sciame da risolvere a fine fase nemica
var guadagni := {"crediti": 0, "bottino": 0, "xp": {}, "persi": [], "oggetti_usati": {}, "note": []}
var auto_decisioni := false     # true nelle partite automatiche: le scelte del giocatore le fa il motore
var _id := 0

func _init(seme := 0) -> void:
	Dati.carica()
	dadi = Dadi.new(seme)
	ia_script = load("res://scripts/core/ia.gd")

func scrivi(t: String, tipo := "") -> void:
	log_righe.append({"round": round_n, "testo": t, "tipo": tipo})

## ===================== griglia =====================

func dentro(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < W and p.y < H

func t_at(p: Vector2i) -> int:
	if not dentro(p):
		return T.MURO
	return celle[p.y * W + p.x]

func a_at(p: Vector2i) -> int:
	if not dentro(p) or alt.size() != celle.size():
		return 0
	return alt[p.y * W + p.x]

func set_t(p: Vector2i, t: int, h := -1) -> void:
	if dentro(p):
		if alt.size() != celle.size():
			alt = PackedInt32Array()
			alt.resize(celle.size())
			alt.fill(0)
		celle[p.y * W + p.x] = t
		if h >= 0:
			alt[p.y * W + p.x] = h
		elif t != T.BLOCCO:
			alt[p.y * W + p.x] = 0
		elif alt[p.y * W + p.x] == 0:
			alt[p.y * W + p.x] = 2

## Casella su cui una figura può stare (fine del movimento).
func calpestabile(p: Vector2i) -> bool:
	var t := t_at(p)
	return dentro(p) and not t in [T.MURO, T.SINGOLO, T.LINEARE, T.MURO_FORZA] and not impraticabili.has(p)

## Casella attraversabile (anche senza fermarsi).
func percorribile(p: Vector2i) -> bool:
	var t := t_at(p)
	return dentro(p) and not t in [T.MURO, T.SINGOLO, T.MURO_FORZA] and not impraticabili.has(p)

func difficile(p: Vector2i) -> bool:
	var t := t_at(p)
	return t == T.AREA or (t == T.CAMPO and not impraticabili.has(p))

## Costo (mezzi pollici) per passare da p a q adiacente: 1" base, terreno difficile +1" ogni 2" (1,5),
## scavalcare un ostacolo lineare +1", porta +1", finestra +2", salire o scendere oltre 1" costa l'altezza (p.41).
func costo_passo(p: Vector2i, q: Vector2i) -> int:
	var c := 3 if difficile(q) else 2
	var tq := t_at(q)
	if tq == T.LINEARE:
		c += int(H_LINEARE * 2)
	elif tq == T.PORTA and not porte_aperte.has(q):
		c += 2
	elif tq == T.FINESTRA:
		c += 4
	var dz := a_at(q) - a_at(p)
	if dz > 0:
		c += dz * 2
	elif dz < -1:
		c += -dz * 2
	return c

## Compatibilità con il codice precedente: costo di entrata nella casella dal suolo.
func costo(p: Vector2i) -> int:
	return costo_passo(p, p)

static func dist(a: Vector2i, b: Vector2i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y))

func figura_in(p: Vector2i) -> Dictionary:
	for u in unita:
		if u.attiva and u.pos == p:
			return u
	return {}

static func _dir8() -> Array:
	return [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]

func _libera_vicina(p: Vector2i, escludi_figure := false) -> Vector2i:
	for r in max(W, H):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := p + Vector2i(dx, dy)
				if max(abs(dx), abs(dy)) == r and calpestabile(q) and a_at(q) == 0 and (not escludi_figure or figura_in(q).is_empty()):
					return q
	return p

## Elemento di terreno che contiene la casella (o {}).
func elemento_in(p: Vector2i) -> Dictionary:
	for e in elementi:
		if p in e.celle:
			return e
	return {}

## ===================== generazione del campo (p.89-90) =====================

func genera_terreno(lato := 24, tratti := []) -> void:
	W = lato
	H = lato
	centro = Vector2i(W / 2, H / 2)
	for tentativo in 40:
		celle = PackedInt32Array()
		celle.resize(W * H)
		celle.fill(T.APERTO)
		alt = PackedInt32Array()
		alt.resize(W * H)
		alt.fill(0)
		impraticabili = {}
		porte_aperte = {}
		elementi = []
		var set_std: Dictionary = Dati.f("incontri").get("terreno", {}).get("set_standard", {})
		var chiave := "2x2" if lato <= 24 else ("2.5x2.5" if lato <= 30 else "3x3")
		var n: Dictionary = set_std.get(chiave, {"grande": 2, "piccolo": 4, "lineare": 2})
		# elemento grande al centro
		_metti_grande(centro, true)
		var settori := []
		var sl: int = W / 3
		for sy in 3:
			for sx in 3:
				if sx == 1 and sy == 1:
					continue
				settori.append(Vector2i(sx * sl + sl / 2, sy * sl + sl / 2))
		settori = dadi.mescola(settori)
		var k := 0
		for i in int(n.get("grande", 2)) - 1:
			var cand := []
			for st in settori:
				if st.y == sl + sl / 2 or st.x == sl + sl / 2:
					cand.append(st)
			var c: Vector2i = cand[i % cand.size()] if not cand.is_empty() else settori[k]
			settori.erase(c)
			_metti_grande(c + Vector2i(dadi.d(3) - 2, dadi.d(3) - 2), false)
		for i in int(n.get("piccolo", 4)):
			var c: Vector2i = settori[i % settori.size()] + Vector2i(dadi.d(5) - 3, dadi.d(5) - 3)
			_metti_piccolo(c)
		for i in int(n.get("lineare", 2)):
			var c: Vector2i = settori[(i + 3) % settori.size()] + Vector2i(dadi.d(5) - 3, dadi.d(5) - 3)
			_metti_lineare(c)
		# un campo (fango, acqua, a volte una pozza tossica invalicabile)
		if dadi.d6() >= 3:
			_metti_campo(settori[(5) % settori.size()] + Vector2i(dadi.d(3) - 2, dadi.d(3) - 2))
		# tratti del mondo che cambiano il tavolo (p.72-73)
		for t in tratti:
			var tl := str(t).to_lower()
			if tl.contains("vegetazione"):
				if dadi.d6() <= 3:
					for j in dadi.d(3):
						_metti_area(Vector2i(dadi.d(W - 4) + 1, dadi.d(H - 8) + 3), 2, "Vegetazione")
				else:
					var piante := []
					for j in dadi.tira("1d6+2"):
						var q := Vector2i(dadi.d(W - 2), dadi.d(H - 6) + 2)
						if t_at(q) == T.APERTO:
							piante.append(q)
					_nuovo_elemento("Alberi", T.SINGOLO, piante)
			if tl.contains("zona di guerra"):
				for j in dadi.d(3):
					var q := Vector2i(dadi.d(W - 6) + 2, dadi.d(H - 10) + 4)
					if dadi.d6() <= 3:
						_metti_area(q, 2, "Rovine")
						_nuovo_elemento("Muro in rovina", T.BLOCCO, [q, q + Vector2i(1, 0)], false, 2)
					else:
						_metti_area(q, 1, "Cratere")
			if tl.contains("cristalli"):
				var cr := []
				for j in dadi.tira("2d6"):
					var q := Vector2i(dadi.d(W - 2), dadi.d(H - 6) + 2)
					if t_at(q) == T.APERTO:
						cr.append(q)
				_nuovo_elemento("Cristalli", T.SINGOLO, cr)
		# niente terreno sulle due file di schieramento
		for x in W:
			for y in [0, 1, H - 2, H - 1]:
				var p := Vector2i(x, y)
				if t_at(p) in [T.BLOCCO, T.SINGOLO, T.MURO, T.PORTA, T.FINESTRA, T.INTERNO] or impraticabili.has(p):
					set_t(p, T.APERTO)
					impraticabili.erase(p)
		for e in elementi:
			e.celle = e.celle.filter(func(c): return t_at(c) == e.tipo or (e.get("interno", false) and t_at(c) in [T.MURO, T.PORTA, T.FINESTRA, T.INTERNO]))
		elementi = elementi.filter(func(e): return not e.celle.is_empty())
		if _connesso():
			return
	for y in H:
		set_t(Vector2i(W / 2 - 3, y), T.APERTO)

func _libero(p: Vector2i, margine := 1) -> bool:
	for dy in range(-margine, margine + 1):
		for dx in range(-margine, margine + 1):
			var q := p + Vector2i(dx, dy)
			if dentro(q) and t_at(q) != T.APERTO:
				return false
	return dentro(p)

func _nuovo_elemento(nome: String, tipo: int, cl: Array, grande := false, altezza := 0) -> Dictionary:
	_id += 1
	var ok := []
	for c in cl:
		if dentro(c) and not c in ok:
			set_t(c, tipo, altezza if tipo == T.BLOCCO else 0)
			ok.append(c)
	var e := {"id": _id, "nome": nome, "tipo": tipo, "celle": ok, "grande": grande, "altezza": altezza}
	if not ok.is_empty():
		elementi.append(e)
	return e

func _rett(c: Vector2i, w: int, h: int) -> Array:
	var r := []
	for y in h:
		for x in w:
			r.append(c + Vector2i(x - w / 2, y - h / 2))
	return r

## Edificio con interno (p.37 «Interior»): muri, porte e finestre.
func _metti_interno(c: Vector2i, w: int, h: int, nome := "Edificio") -> void:
	var cl := _rett(c, w, h)
	var minx := 999
	var miny := 999
	var maxx := -1
	var maxy := -1
	for q in cl:
		minx = min(minx, q.x)
		miny = min(miny, q.y)
		maxx = max(maxx, q.x)
		maxy = max(maxy, q.y)
	_id += 1
	var e := {"id": _id, "nome": nome, "tipo": T.INTERNO, "celle": [], "grande": true, "altezza": 3, "interno": true}
	var bordi := []
	for q in cl:
		if not dentro(q):
			continue
		var bordo: bool = q.x == minx or q.x == maxx or q.y == miny or q.y == maxy
		set_t(q, T.MURO if bordo else T.INTERNO)
		e.celle.append(q)
		var angolo: bool = (q.x == minx or q.x == maxx) and (q.y == miny or q.y == maxy)
		if bordo and not angolo:
			bordi.append(q)
	bordi = dadi.mescola(bordi)
	# una porta per lato lungo (sopra e sotto), più finestre
	var porte := 0
	for q in bordi.duplicate():
		if porte < 2 and (q.y == miny or q.y == maxy) and (porte == 0 or q.y != bordi[0].y):
			set_t(q, T.PORTA)
			bordi.erase(q)
			porte += 1
	if porte == 0 and not bordi.is_empty():
		set_t(bordi.pop_front(), T.PORTA)
	for i in min(3, bordi.size()):
		set_t(bordi[i], T.FINESTRA)
	elementi.append(e)

func _metti_grande(c: Vector2i, al_centro: bool) -> void:
	var scelta := dadi.d(6)
	match scelta:
		1:
			# edificio con interno, muretto davanti
			var w := 5 + dadi.d(2)
			var h := 4 + dadi.d(2)
			_metti_interno(c, w, h)
			var ly := c.y + h / 2 + 2 if dadi.d6() < 4 else c.y - h / 2 - 2
			var lin := []
			for x in range(c.x - 1, c.x + 2):
				lin.append(Vector2i(x, ly))
			_nuovo_elemento("Muretto", T.LINEARE, lin)
		2:
			_metti_area(c, 4 + dadi.d(2), "Bosco", true)
		3:
			# deposito di casse (alte 1") e barili
			var cl := []
			for i in 6 + dadi.d(4):
				var q := c + Vector2i(dadi.d(6) - 4, dadi.d(6) - 4)
				if not q in cl:
					cl.append(q)
			var bar := []
			var cas := []
			for q in cl:
				if dadi.d6() <= 3:
					bar.append(q)
				else:
					cas.append(q)
			_nuovo_elemento("Deposito di casse", T.BLOCCO, cas, true, 1)
			_nuovo_elemento("Barili", T.SINGOLO, bar)
		4:
			# rovine: macerie (area) attorno a pezzi di muro alti 2"
			_metti_area(c, 4, "Rovine", true)
			var pezzi := []
			for i in 3:
				pezzi.append(c + Vector2i(dadi.d(5) - 3, dadi.d(5) - 3))
			_nuovo_elemento("Muro in rovina", T.BLOCCO, pezzi, false, 2)
		5:
			# edificio chiuso (blocco alto 3"): si può scalare
			var w := 3 + dadi.d(2)
			var h := 2 + dadi.d(2)
			_nuovo_elemento("Edificio chiuso", T.BLOCCO, _rett(c, w, h), true, 3)
		_:
			_nuovo_elemento("Navetta atterrata", T.BLOCCO, _rett(c, 5, 2), true, 2)
			_nuovo_elemento("Casse della navetta", T.SINGOLO, [c + Vector2i(-3, 2), c + Vector2i(3, -2)])

func _metti_area(c: Vector2i, r: int, nome: String, grande := false) -> void:
	var cl := []
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var q := c + Vector2i(dx, dy)
			if Vector2(dx, dy).length() <= r * 0.75 + dadi.rng.randf() * 0.8 and dentro(q) and t_at(q) == T.APERTO:
				cl.append(q)
	_nuovo_elemento(nome, T.AREA, cl, grande)

func _metti_campo(c: Vector2i) -> void:
	var cl := []
	var r := 2
	for dy in range(-r, r + 1):
		for dx in range(-r - 1, r + 2):
			var q := c + Vector2i(dx, dy)
			if Vector2(dx * 0.8, dy).length() <= r + dadi.rng.randf() * 0.6 and dentro(q) and t_at(q) == T.APERTO:
				cl.append(q)
	var tipo := dadi.d6()
	var nome := "Pozza di fango" if tipo <= 3 else ("Acqua bassa" if tipo <= 5 else "Pozza tossica")
	_nuovo_elemento(nome, T.CAMPO, cl)
	if nome == "Pozza tossica":
		for q in cl:
			impraticabili[q] = true

func _metti_piccolo(c: Vector2i) -> void:
	for t in 6:
		if _libero(c, 1):
			break
		c += Vector2i(dadi.d(3) - 2, dadi.d(3) - 2)
	match dadi.d(5):
		1:
			_nuovo_elemento("Masso", T.BLOCCO, _rett(c, 2, 1 + dadi.d(2) - 1), false, dadi.d(2))
		2:
			_nuovo_elemento("Barili", T.SINGOLO, [c, c + Vector2i(1, 0), c + Vector2i(0, 1)].slice(0, 1 + dadi.d(2)))
		3:
			_metti_area(c, 2, "Cespugli")
		4:
			_nuovo_elemento("Container", T.BLOCCO, _rett(c, 1, 3) if dadi.d6() < 4 else _rett(c, 3, 1), false, 2)
		_:
			_nuovo_elemento("Alberi", T.SINGOLO, [c, c + Vector2i(2, 1)])

func _metti_lineare(c: Vector2i) -> void:
	var l := 4 + dadi.d(5) - 1
	var cl := []
	var oriz := dadi.d6() <= 3
	for i in l:
		cl.append(c + (Vector2i(i - l / 2, 0) if oriz else Vector2i(0, i - l / 2)))
	if dadi.d6() == 6:
		var fine: Vector2i = cl[cl.size() - 1]
		for i in 3:
			cl.append(fine + (Vector2i(0, i + 1) if oriz else Vector2i(i + 1, 0)))
	var nomi := ["Barricata", "Recinzione", "Muretto", "Siepe", "Sacchi di sabbia"]
	var buoni := []
	for q in cl:
		if dentro(q) and t_at(q) == T.APERTO:
			buoni.append(q)
	_nuovo_elemento(dadi.scegli(nomi), T.LINEARE, buoni)

func _connesso() -> bool:
	var vis := {}
	var coda := []
	for x in W:
		var p := Vector2i(x, H - 1)
		if percorribile(p):
			coda.append(p)
			vis[p] = true
	while not coda.is_empty():
		var p: Vector2i = coda.pop_front()
		for d in _dir8():
			var q: Vector2i = p + d
			if percorribile(q) and not vis.has(q) and abs(a_at(q) - a_at(p)) <= 3:
				vis[q] = true
				coda.append(q)
	var arrivi := 0
	for x in W:
		if vis.has(Vector2i(x, 0)):
			arrivi += 1
	var c := _libera_vicina(centro)
	return arrivi >= W / 3 and vis.has(c)

## ===================== figure =====================

func _nuova_figura(base: Dictionary) -> Dictionary:
	_id += 1
	var u := {"uid": _id, "lato": EQ, "nome": "?", "pedina": "", "pos": Vector2i.ZERO, "reazioni": 1, "velocita": 4,
		"combattimento": 0, "robustezza": 3, "acume": 0, "salvezze": [], "salv_corazza": 0, "salv_schermo": 0,
		"arma": "", "arma_m": "", "armi": [], "oggetti": [], "consumabili": [],
		"stordito": 0, "attiva": true, "fuori": false, "ko": false, "fuggito": false, "uscito": false, "fortuna": 0,
		"ia": "tattico", "panico": [], "impavido": false, "specialista": false, "luogotenente": false, "unico": false,
		"mosso": false, "agito": false, "attivato": false, "fase": "", "pg": "", "specie": "", "speciali": {}, "monouso_usati": [],
		"porta": "", "scatto": false, "iniziale": Vector2i.ZERO, "uscito_round": 0, "vip": false, "robot": false,
		"dado_reazione": 0, "gratuite": 0, "attesa": "", "no_fuoco": false, "scariche": [], "guasti": {},
		"bonus_battaglia": {}, "bonus_round": {}, "bonus_fino": 0, "immobile_fino": 0, "doppia_vel": false,
		"fermo_ultima": false, "ultimo_bersaglio": -1, "congelato_fino": 0, "salta_attivazione": false,
		"doppia_fase_round": 0, "mossa_bonus": 0, "deflettore_usato": false, "sparato_round": 0, "salta_round": 0,
		"usati_battaglia": [], "mov_alt": "", "tele_raggio": 0, "trasportato": "", "stessi_bersagli": [],
		"padrone": -1, "fedele_difende": false, "ha_cane": false, "inizio_round_pos": Vector2i.ZERO}
	u.merge(base, true)
	return u

## Protezioni di un personaggio dall'equipaggiamento e dalla specie: [{v, tipo: corazza|schermo, esclude: [], area: n}].
static func _protezioni_pg(pg: Dictionary) -> Array:
	var r := []
	var s := Personaggio.info_specie(pg)
	if s.has("salvezza"):
		r.append({"v": int(s["salvezza"]), "tipo": "corazza", "esclude": [], "area": 0})
	for o in Personaggio.oggetti(pg):
		if o.get("danneggiato", false):
			continue
		var ogg := Dati.oggetto(str(o.get("id")))
		var e: Dictionary = ogg.get("effetto", {})
		if e.has("salvezza"):
			r.append({"v": int(e.salvezza), "tipo": "schermo" if str(ogg.get("tipo", "")) == "schermo" else "corazza",
				"esclude": e.get("salvezza_esclude", []), "area": int(e.get("salvezza_area", 0))})
	return r

## Oggetti (id) non danneggiati del personaggio.
static func _oggetti_pg(pg: Dictionary) -> Array:
	var r := []
	for o in Personaggio.oggetti(pg):
		if not o.get("danneggiato", false):
			r.append(str(o.get("id")))
	return r

func ha(u: Dictionary, id_oggetto: String) -> bool:
	return id_oggetto in u.get("oggetti", [])

## Valore di una statistica in battaglia con i bonus temporanei (sostanze, equipaggiamento).
func stat(u: Dictionary, s: String) -> int:
	var v := int(u.get(s, 0))
	v += int(u.bonus_battaglia.get(s, 0))
	if round_n <= int(u.bonus_fino):
		v += int(u.bonus_round.get(s, 0))
	if s == "reazioni" and ha(u, "corazza_battaglia") and v < 4:
		v += 1
	if s == "robustezza" and ha(u, "flex_armor") and u.fermo_ultima:
		v = min(6, v + 1)
	return v

## Aggiunge l'equipaggio (personaggi della campagna).
func aggiungi_equipaggio(pgs: Array) -> void:
	var xs := []
	var n := pgs.size()
	for i in n:
		xs.append(int(W / 2 - n + i * 2 + 1))
	for i in n:
		var u := figura_da_pg(pgs[i])
		var x: int = clampi(xs[i], 0, W - 1)
		var y := H - 1 - (i % 2)
		u.pos = _libera_vicina(Vector2i(x, y), true)
		u.iniziale = u.pos
		unita.append(u)

func figura_da_pg(pg: Dictionary) -> Dictionary:
	var ogg := _oggetti_pg(pg)
	var prot := _protezioni_pg(pg)
	var info := Personaggio.info_specie(pg)
	var cons := []
	for id in ogg:
		var e: Dictionary = Dati.oggetto(id).get("effetto", {})
		if e.has("consumabile") and not info.get("bonus", {}).get("no_consumabili", false):
			cons.append(id)
	var sv := Personaggio.salvezze(pg)
	var u := _nuova_figura({"lato": EQ, "nome": pg.nome, "pedina": str(info.get("pedina", pg.specie)),
		"reazioni": Personaggio.stat_effettiva(pg, "reazioni"), "velocita": Personaggio.stat_effettiva(pg, "velocita"),
		"combattimento": Personaggio.stat_effettiva(pg, "combattimento"), "robustezza": Personaggio.stat_effettiva(pg, "robustezza"),
		"acume": Personaggio.stat_effettiva(pg, "acume"), "salvezze": prot, "salv_corazza": sv.corazza, "salv_schermo": sv.schermo,
		"arma": Personaggio.arma_tiro(pg), "arma_m": Personaggio.arma_mischia(pg), "armi": Personaggio.armi(pg),
		"oggetti": ogg, "consumabili": cons,
		"fortuna": int(pg.get("fortuna", 0)), "pg": str(pg.id), "specie": str(pg.specie), "ia": "tattico",
		"robot": Personaggio.e_robot(pg), "speciali": info.get("bonus", {}), "tele_bonus": int(pg.get("teletrasporto_bonus", 0))})
	if "zampa_coniglio" in ogg and int(u.fortuna) < 1:
		u.fortuna = 1
	if str(pg.specie) == "engineer":
		u.robustezza = min(int(u.robustezza), 4)
	return u

## Crea i nemici a partire dal tipo, dal numero e dagli eventuali Individui Unici.
func aggiungi_nemici(id_nemico: String, numero: int, unici: Array = [], forza_impavidi := false, n_spec_forzati := -1, solo_base := false) -> Array:
	var n := Dati.nemico(id_nemico)
	var cod = n.get("armi", "1A")
	var an: Dictionary = Dati.f("armi").get("armi_nemici", {})
	var base_armi := []
	var spec_armi := []
	if cod is String and cod.length() >= 2:
		base_armi = Dadi.riga(an.get(cod.substr(0, 1), {}), dadi.d6()).get("armi", ["pistola"])
		spec_armi = Dadi.riga(an.get(cod.substr(1, 1), {}), dadi.d6()).get("armi", base_armi)
	elif cod is Array:
		base_armi = cod
		spec_armi = cod
	var sp: Dictionary = n.get("speciali", {})
	if sp.has("armi_specialisti"):
		base_armi = ["lama"]
		spec_armi = sp.armi_specialisti
	var arma_nat = n.get("arma_naturale", {})
	var spl: Dictionary = Dati.f("incontri").get("specialisti_luogotenenti", {})
	var n_spec := 0 if numero <= 2 else (1 if numero <= 6 else 2)
	if n_spec_forzati >= 0:
		n_spec = n_spec_forzati
	var ha_luog := numero >= int(spl.get("luogotenente", {}).get("minimo_nemici", 4)) and not solo_base
	var ia := str(n.get("ia", "aggressivo"))
	if ia == "null" or ia == "":
		ia = "aggressivo"
	var forzata: Dictionary = par_obiettivo.get("ia_forzata", {})
	if forzata.has(ia):
		ia = str(forzata[ia])
	var figure := []
	for i in numero:
		var spec := i < n_spec
		var luog := ha_luog and i == n_spec
		var armi: Array = (spec_armi if spec else base_armi).duplicate()
		if arma_nat is Dictionary and arma_nat.get("id") != null and armi.is_empty():
			armi.append(str(arma_nat.get("id")))
		# p.95: gli Aggressivi con Combattimento sopra +0 e i Luogotenenti hanno anche una Lama
		if ia == "aggressivo" and int(n.get("combattimento", 0) if n.get("combattimento") != null else 0) > 0 and not "lama" in armi and not armi.is_empty():
			armi.append("lama")
		if luog and not "lama" in armi and not armi.is_empty():
			armi.append("lama")
		var u := _figura_nemico(n, id_nemico, armi, ia)
		u.specialista = spec
		u.luogotenente = luog
		if luog:
			u.combattimento += 1
			u.impavido = not sp.get("luogotenenti_non_impavidi", false)
			u.nome = "Luogotenente " + str(n.get("nome", ""))
		elif spec:
			u.nome = "Specialista " + str(n.get("nome", ""))
		if forza_impavidi:
			u.impavido = true
		figure.append(u)
	for uid in unici:
		var un := Dati.nemico(str(uid))
		var armi = un.get("armi", [])
		if not (armi is Array) or armi.is_empty():
			armi = base_armi.duplicate()
		var u := _figura_nemico(un if un.get("velocita") != null else n, str(uid), armi, str(un.get("ia", ia)) if un.get("ia") != null else ia)
		u.nome = str(un.get("nome", "Individuo Unico"))
		u.pedina = str(uid).trim_prefix("unico_")
		u.unico = true
		u.impavido = true
		u.fortuna = int(un.get("fortuna", 0))
		var su: Dictionary = un.get("speciali", {})
		var sp2: Dictionary = u.speciali.duplicate()
		sp2.merge(su, true)
		u.speciali = sp2
		u.regole = str(un.get("regole", ""))
		var mods: Dictionary = un.get("modificatori", {})
		for k in mods:
			if u.has(k):
				u[k] = int(u[k]) + int(mods[k])
		figure.append(u)
	# Cane genetico: il padrone è un'altra figura (la più forte)
	for u in figure:
		if u.speciali.get("fedele", false):
			var best := {}
			for v in figure:
				if v.uid != u.uid and (best.is_empty() or int(v.combattimento) > int(best.combattimento)):
					best = v
			if not best.is_empty():
				u.padrone = best.uid
	_schiera_nemici(figure, ia)
	return figure

func _figura_nemico(n: Dictionary, id: String, armi: Array, ia: String) -> Dictionary:
	var arma := ""
	var arma_m := ""
	var bp := -99.0
	for a in armi:
		var d := Dati.arma(str(a))
		if d.is_empty():
			continue
		if int(d.get("gittata", 0)) > 0:
			var p := float(d.get("colpi", 1)) * (2 + int(d.get("danno", 0)))
			if "monouso" in d.get("tratti", []):
				p -= 3
			if p > bp:
				bp = p
				arma = str(a)
		var t: Array = d.get("tratti", [])
		if ("mischia" in t or "pistola" in t or d.get("solo_nemici", false)) and (arma_m == "" or int(d.get("danno", 0)) > int(Dati.arma(arma_m).get("danno", 0))):
			arma_m = str(a)
	var pan = n.get("panico", [])
	var sp: Dictionary = n.get("speciali", {})
	var specie := ""
	if id.contains("swift"):
		specie = "swift"
	elif id.contains("senzanima"):
		specie = "soulless"
	elif id.contains("kerin"):
		specie = "kerin"
	var prot := []
	if int(n.get("salvezza", 0)) > 0:
		prot.append({"v": int(n.get("salvezza", 0)), "tipo": "corazza", "esclude": [], "area": 0})
	return _nuova_figura({"lato": NEM, "nome": str(n.get("nome", id)), "pedina": id.trim_prefix("unico_"), "tipo": id,
		"velocita": int(n.get("velocita", 4) if n.get("velocita") != null else 4),
		"combattimento": int(n.get("combattimento", 0) if n.get("combattimento") != null else 0),
		"robustezza": int(n.get("robustezza", 3) if n.get("robustezza") != null else 3),
		"salvezze": prot, "salv_corazza": int(n.get("salvezza", 0)), "arma": arma, "arma_m": arma_m, "armi": armi, "ia": ia,
		"panico": pan if pan is Array else [], "impavido": (pan is Array and pan.is_empty()) or sp.get("impavido", false),
		"speciali": sp, "regole": str(n.get("regole", "")), "specie": specie, "robot": id.contains("robot")})

func _schiera_nemici(figure: Array, ia: String) -> void:
	var form: Dictionary = Dati.f("incontri").get("schieramento", {}).get("formazioni", {}).get(ia, {})
	var gruppi := int(form.get("gruppi", 1))
	if form.get("coppie", false):
		gruppi = 3
	var centri := []
	for g in gruppi:
		var x := int(W * (g + 1) / float(gruppi + 1)) if gruppi > 1 else W / 2 + dadi.d(5) - 3
		centri.append(Vector2i(x, 1))
	for i in figure.size():
		var u: Dictionary = figure[i]
		var c: Vector2i = centri[i % centri.size()]
		var off := Vector2i(((i / centri.size()) % 3) - 1, (i / centri.size()) / 3)
		u.pos = _libera_vicina(c + off * 2, true)
		u.iniziale = u.pos
		unita.append(u)

func aggiungi_vip() -> void:
	var v := _nuova_figura({"lato": EQ, "nome": "VIP", "pedina": "vip", "reazioni": 1, "velocita": 4, "combattimento": 0,
		"robustezza": 3, "vip": true})
	v.pos = _libera_vicina(Vector2i(W / 2, H - 1), true)
	unita.append(v)

func figure(lato: String, solo_attive := true) -> Array:
	var r := []
	for u in unita:
		if u.lato == lato and (u.attiva or not solo_attive):
			r.append(u)
	return r

## Figure ostili a u (i mostri sono ostili a tutti).
func avversari(u: Dictionary) -> Array:
	var r := []
	for v in unita:
		if v.attiva and v.lato != u.lato and not _congelato(v):
			r.append(v)
	return r

func ostili(a: Dictionary, b: Dictionary) -> bool:
	return a.lato != b.lato

func _congelato(u: Dictionary) -> bool:
	return int(u.congelato_fino) >= round_n and round_n > 0

func per_uid(uid: int) -> Dictionary:
	for u in unita:
		if u.uid == uid:
			return u
	return {}

## ===================== preparazione da una campagna =====================

static func scegli_ambiente(tratti: Array, obiettivo_: String) -> String:
	var t := " ".join(tratti).to_lower()
	if obiettivo_ == "invasione" or t.contains("zona di guerra"):
		return "zona_guerra"
	if t.contains("ghiacciato"):
		return "ghiacciato"
	if t.contains("arido"):
		return "arido"
	if t.contains("vegetazione"):
		return "rigoglioso"
	if t.contains("cristalli"):
		return "cristalli"
	if obiettivo_ in ["assalto", "incursione"]:
		return "urbano"
	return "frontiera"

## Prepara la battaglia dalla campagna: setup = Campagna.s.battaglia; pgs = personaggi schierati; riserve_ = non schierati.
func prepara(setup_: Dictionary, pgs: Array, lato := 24, opzioni := {}) -> void:
	setup = setup_
	obiettivo = str(setup.get("obiettivo", "respingere"))
	par_obiettivo = Dati.f("incontri").get("tipi_obiettivo", {}).get(obiettivo, {}).get("parametri", {})
	eventi_battaglia = bool(opzioni.get("eventi_battaglia", true))
	riserve = opzioni.get("riserve", [])
	var tratti := []
	for t in opzioni.get("tratti_mondo", []):
		tratti.append(str(t))
	tratti_mondo = tratti
	ambiente = scegli_ambiente(tratti, obiettivo)
	genera_terreno(lato, tratti)
	if obiettivo == "assalto":
		_prepara_edificio_assalto()
	cond = setup.get("condizione", {}).get("effetti", {})
	if obiettivo == "invasione":
		cond = {}
	if cond.has("visibilita"):
		visibilita = dadi.tira(cond.visibilita)
		scrivi("Visibilità ridotta a %d\"." % visibilita)
	var schierati := pgs.duplicate()
	if par_obiettivo.has("membri_mod") and schierati.size() > 1:
		schierati.resize(schierati.size() + int(par_obiettivo.membri_mod))
	if cond.has("escludi_membri_casuali") and schierati.size() > 1:
		var via: Dictionary = dadi.scegli(schierati)
		schierati.erase(via)
		scrivi("%s non partecipa allo scontro (%s)." % [via.nome, setup.condizione.get("nome", "")])
	if cond.has("ritardati") and schierati.size() > 2:
		for i in int(cond.ritardati):
			var r: Dictionary = dadi.scegli(schierati)
			schierati.erase(r)
			ritardati.append(r)
		scrivi("In ritardo: %s arriveranno più tardi." % ", ".join(ritardati.map(func(p): return str(p.nome))))
	aggiungi_equipaggio(schierati)
	var numero := int(setup.get("numero", 4)) + int(par_obiettivo.get("nemici_mod", 0))
	if cond.has("nemici_mod"):
		numero += int(cond.get("nemici_mod_se_superiori", cond.nemici_mod)) if numero > schierati.size() and cond.has("nemici_mod_se_superiori") else int(cond.nemici_mod)
	numero = max(1, numero)
	aggiungi_nemici(str(setup.get("nemico", "ganger")), numero, setup.get("unici", []), setup.get("finale_missione", false))
	if obiettivo == "proteggere":
		aggiungi_vip()
	if obiettivo == "assalto":
		_schiera_assalto()
	_prepara_obiettivo()
	var cn := Dati.nemico(str(setup.get("nemico", "")))
	scrivi("Contro: %s. %s" % [cn.get("nome", ""), cn.get("regole", "")])
	scrivi("Obiettivo: %s. %s" % [Dati.f("incontri").get("tipi_obiettivo", {}).get(obiettivo, {}).get("nome", obiettivo),
		Dati.f("incontri").get("tipi_obiettivo", {}).get(obiettivo, {}).get("testo", "")], "obiettivo")
	if not setup.get("condizione", {}).is_empty() and str(setup.condizione.get("id", "")) != "nessuna":
		scrivi("Condizione: %s - %s" % [setup.condizione.get("nome", ""), setup.condizione.get("testo", "")])
	if setup.has("regole_speciali"):
		scrivi("Regole speciali: " + str(setup.regole_speciali), "evento")
	fase = "iniziativa"

## «Assalto»: serve un edificio vicino al bordo dell'equipaggio.
func _prepara_edificio_assalto() -> void:
	var c := Vector2i(W / 2, H - 6)
	for y in range(c.y - 3, c.y + 4):
		for x in range(c.x - 4, c.x + 5):
			var p := Vector2i(x, y)
			if dentro(p):
				set_t(p, T.APERTO)
				impraticabili.erase(p)
	for e in elementi:
		e.celle = e.celle.filter(func(q): return t_at(q) != T.APERTO)
	elementi = elementi.filter(func(e): return not e.celle.is_empty())
	_metti_interno(c, 7, 5, "Edificio assediato")

func _schiera_assalto() -> void:
	var dentro_ed := []
	for e in elementi:
		if e.get("interno", false) and str(e.nome) == "Edificio assediato":
			for q in e.celle:
				if t_at(q) == T.INTERNO:
					dentro_ed.append(q)
	var i := 0
	for u in figure(EQ):
		if i < dentro_ed.size():
			u.pos = dentro_ed[i]
			u.iniziale = u.pos
			i += 1

func _prepara_obiettivo() -> void:
	centro = _libera_vicina(Vector2i(W / 2, H / 2))
	stato_obj = {"fatto": false, "fallito": false, "uscite_nemico": 0, "consecutivi": 0, "uno_naturale": 0}
	var luogo: Dictionary = setup.get("luogo", {})
	if not luogo.is_empty() and str(luogo.get("id", "niente")) != "niente":
		var dd: Vector2i = _dir8()[dadi.d(8) - 1]
		var lp: Vector2i = centro + dd * (dadi.tira("2d6+2") / (2 if abs(dd.x) + abs(dd.y) == 2 else 1))
		lp = Vector2i(clampi(lp.x, 1, W - 2), clampi(lp.y, 2, H - 3))
		stato_obj["luogo_pos"] = _libera_vicina(lp)
		if str(luogo.get("id", "")) == "bersaglio_prioritario":
			var nem := figure(NEM)
			if not nem.is_empty():
				var b: Dictionary = dadi.scegli(nem)
				b.robustezza = min(6, int(b.robustezza) + 1)
				b["taglia_luogo"] = true
				scrivi("Bersaglio prioritario: %s (Robustezza +1; se ucciso 1D3 crediti)." % b.nome)
			stato_obj.erase("luogo_pos")
	match obiettivo:
		"consegnare":
			var eq := figure(EQ)
			if not eq.is_empty():
				eq[0].porta = "pacco"
				scrivi("%s porta il pacco da consegnare al centro." % eq[0].nome)
		"acquisire":
			stato_obj["oggetto_a"] = centro
		"eliminare":
			var nem := figure(NEM)
			if not nem.is_empty():
				var b: Dictionary = dadi.scegli(nem)
				stato_obj["bersaglio"] = b.uid
				b["bersaglio"] = true
				scrivi("Bersaglio da eliminare: %s." % b.nome)
		"pattugliare":
			var gr := []
			for e in elementi:
				if e.grande or e.celle.size() >= 4:
					gr.append(e)
			gr = dadi.mescola(gr)
			stato_obj["punti"] = []
			for e in gr.slice(0, 3):
				stato_obj.punti.append({"id": e.id, "nome": e.nome, "fatto": false, "cella": e.celle[e.celle.size() / 2]})
		"perquisire":
			stato_obj["segnalini"] = []
			for e in elementi:
				if e.grande or e.celle.size() >= 3:
					stato_obj.segnalini.append({"id": e.id, "nome": e.nome, "fatto": false, "cella": e.celle[e.celle.size() / 2]})

## ===================== linea di vista e copertura (p.38-39) =====================

## Caselle attraversate dalla linea tra i centri di a e b (esclusi gli estremi), con la frazione del percorso.
func linea(a: Vector2i, b: Vector2i) -> Array:
	var r := []
	for x in _linea_t(a, b):
		r.append(x[0])
	return r

func _linea_t(a: Vector2i, b: Vector2i) -> Array:
	var r := []
	var n: int = dist(a, b) * 3
	if n == 0:
		return r
	var visti := {}
	for i in range(1, n):
		var t := float(i) / n
		var p := Vector2i(roundi(lerp(float(a.x), float(b.x), t)), roundi(lerp(float(a.y), float(b.y), t)))
		if p != a and p != b and not visti.has(p):
			visti[p] = true
			r.append([p, t])
	return r

## Distanza massima di vista per chi guarda da a verso b.
func _limite_vista(da: Dictionary, a: Vector2i, b: Vector2i, bersaglio := {}) -> int:
	var lim := 999
	if visibilita > 0:
		lim = visibilita
		var buio := str(setup.get("condizione", {}).get("id", "")) == "buio"
		if buio and not da.is_empty() and ha(da, "visore_notturno"):
			lim = 999
		if not da.is_empty() and lim < 999:
			if _ha_mod(da, "torcia"):
				lim += 3
		if not bersaglio.is_empty() and cond.get("chi_spara_visibile", false) and int(bersaglio.get("sparato_round", 0)) == round_n:
			lim = 999
	if not nebbia.is_empty():
		if dist(a, nebbia.centro) <= int(nebbia.raggio) or dist(b, nebbia.centro) <= int(nebbia.raggio):
			lim = min(lim, int(nebbia.vis))
	return lim

## Linea di vista da a verso b (terreno con altezze e figure). Restituisce {"vede", "copertura", "colpibile"}.
## osservatore/bersaglio: figure (facoltative) per visibilità ridotta, nebbia e chi ha sparato al buio.
func lds(a: Vector2i, b: Vector2i, ignora_figure := false, osservatore := {}, bersaglio := {}) -> Dictionary:
	var no := {"vede": false, "copertura": false, "colpibile": false}
	var d := dist(a, b)
	if d > _limite_vista(osservatore, a, b, bersaglio):
		return no
	var za := a_at(a) + 1.0
	var zb := b_at_occhi(b)
	var cop := false
	var colpibile := true
	var area_a := t_at(a) == T.AREA
	var area_b := t_at(b) == T.AREA
	if area_b:
		cop = true
	# bersaglio più in alto di chi spara (su un tetto, su un masso): parzialmente nascosto dal bordo
	if a_at(b) > a_at(a) and a_at(b) > 0:
		cop = true
	for x in _linea_t(a, b):
		var p: Vector2i = x[0]
		var h: float = lerp(za, zb, float(x[1]))
		var t := t_at(p)
		var ap := a_at(p)
		match t:
			T.BLOCCO:
				if float(ap) >= h - 0.05:
					return no
			T.MURO:
				return no
			T.INTERNO:
				if h >= H_MURO:
					return no   # tetto
			T.PORTA:
				if h >= H_MURO or not porte_aperte.has(p):
					return no
				if dist(p, a) > 1:
					cop = true
			T.FINESTRA:
				if h >= H_MURO:
					return no
				if dist(p, a) > 1:
					cop = true
			T.AREA:
				if h < H_AREA:
					# p.38: la vista entra in un'area fino al bordo; nella stessa area ci si vede entro 3"
					if not ((area_a or area_b) and d <= 3):
						if not (dist(p, a) <= 1 and area_a) and not (dist(p, b) <= 1 and area_b):
							return no
					if dist(p, a) > 1:
						cop = true
			T.LINEARE:
				if h < H_LINEARE + 0.6 and dist(p, a) > 1:
					cop = true
			T.SINGOLO:
				if h < H_SINGOLO and dist(p, a) > 1:
					cop = true
			T.MURO_FORZA:
				colpibile = false
		if not ignora_figure:
			var f := figura_in(p)
			if not f.is_empty() and h >= float(ap) - 0.05 and h <= float(ap) + H_FIGURA:
				return no
	# dall'interno di un'area si vede fuori solo dal bordo
	if area_a and d > 3 and za < H_AREA + 0.5:
		var bordo := false
		for dd in _dir8():
			if t_at(a + dd) != T.AREA:
				bordo = true
		if not bordo:
			return no
	return {"vede": true, "copertura": cop, "colpibile": colpibile}

func b_at_occhi(p: Vector2i) -> float:
	return a_at(p) + 1.0

## Figura vista da u (linea di vista reciproca, visibilità, nebbia).
func vede(u: Dictionary, v: Dictionary) -> bool:
	return lds(u.pos, v.pos, false, u, v).vede

## ===================== armi effettive (mod, mirini, impianti, specie) =====================

## Mod e mirino montati sull'arma principale da tiro (interpretazione: si montano sull'arma migliore che li accetta).
func _mod_arma(u: Dictionary, arma_id: String) -> Array:
	var r := []
	if u.lato != EQ or arma_id == "" or arma_id != str(u.arma):
		return r
	var a := Dati.arma(arma_id)
	var tr: Array = a.get("tratti", [])
	if "mischia" in tr and int(a.get("gittata", 0)) <= 0 or "monouso" in tr:
		return r
	var mod := ""
	var mir := ""
	for id in u.oggetti:
		var o := Dati.oggetto(id)
		var tipo := str(o.get("tipo", ""))
		if tipo != "mod_arma" and tipo != "mirino":
			continue
		var e: Dictionary = o.get("effetto", {})
		var solo := str(e.get("solo", ""))
		if solo == "pistola" and not "pistola" in tr:
			continue
		if solo == "non_pistola" and "pistola" in tr:
			continue
		if e.has("solo_armi") and not arma_id in e.solo_armi:
			continue
		if tipo == "mod_arma" and mod == "":
			mod = id
		elif tipo == "mirino" and mir == "" and not u.speciali.get("no_mirini", false):
			mir = id
	if mod != "":
		r.append(mod)
	if mir != "":
		r.append(mir)
	return r

func _ha_mod(u: Dictionary, id: String) -> bool:
	return id in _mod_arma(u, str(u.arma))

## Profilo effettivo di un'arma per u: {id, nome, gittata, colpi, danno, tratti, colpire, ritira_1, ...}.
func arma_eff(u: Dictionary, arma_id: String) -> Dictionary:
	var a := Dati.arma(arma_id)
	if a.is_empty():
		return {}
	var r := {"id": arma_id, "nome": str(a.get("nome", arma_id)), "gittata": int(a.get("gittata", 0)), "colpi": int(a.get("colpi", 1)),
		"danno": int(a.get("danno", 0)), "tratti": (a.get("tratti", []) as Array).duplicate(), "colpire": 0, "ritira_1": false,
		"ritira_1_singolo": false, "colpire_fermo": 0, "colpire_stesso": 0, "oltre": {}, "impatto_entro": 0, "surriscalda": false,
		"danno_rissa": 0, "vince_pareggio": false, "rissa": 0}
	for id in _mod_arma(u, arma_id):
		var e: Dictionary = Dati.oggetto(id).get("effetto", {})
		for t in e.get("tratti_aggiunti", []):
			if not t in r.tratti:
				r.tratti.append(t)
		r.gittata += int(e.get("gittata", 0))
		r.danno += int(e.get("danno", 0))
		r.colpire += int(e.get("colpire", 0))
		r.colpire_fermo += int(e.get("colpire_se_fermo", 0))
		r.colpire_stesso += int(e.get("colpire_stesso_bersaglio", 0))
		if e.get("ritira_1_se_colpo_singolo", false):
			r.ritira_1_singolo = true
		if e.has("colpire_oltre"):
			r.oltre = e.colpire_oltre
		if e.has("tratti_entro"):
			r.impatto_entro = int(e.tratti_entro.get("distanza", 0))
		if e.get("surriscalda_su_6", false):
			r.surriscalda = true
		r.danno_rissa += int(e.get("danno_rissa", 0))
		if e.get("vince_pareggio_rissa", false):
			r.vince_pareggio = true
		for t in e.get("ignora_tratti", []):
			r.tratti.erase(t)
	if ha(u, "visore_battaglia"):
		r.ritira_1 = true
	# Mano cibernetica: la pistola migliore è integrata (gittata dimezzata, +1 per colpire, +1 in Rissa)
	if ha(u, "mano_cibernetica") and "pistola" in r.tratti and arma_id == _pistola_migliore(u):
		r.gittata = max(1, r.gittata / 2)
		r.colpire += 1
		r.rissa += 1
	# Granate: Impianto muscolare +2" di gittata
	if ha(u, "impianto_muscoli") and arma_id.begins_with("granata"):
		r.gittata += 2
	# Primitivo: niente oltre 8"
	if u.speciali.has("gittata_max"):
		r.gittata = min(r.gittata, int(u.speciali.gittata_max))
	if u.speciali.get("mischia_elegante", false) and "mischia" in r.tratti and not "elegante" in r.tratti:
		r.tratti.append("elegante")
	# tratti ignorati (Hulker, Bot d'assalto: Goffa e Pesante)
	for t in u.speciali.get("ignora_tratti", []):
		var it: String = {"clumsy": "goffa", "heavy": "pesante"}.get(str(t), str(t))
		r.tratti.erase(it)
	return r

func _pistola_migliore(u: Dictionary) -> String:
	var best := ""
	var bd := -9
	for id in u.armi:
		var a := Dati.arma(id)
		if "pistola" in a.get("tratti", []) and int(a.get("gittata", 0)) > 0 and int(a.get("danno", 0)) > bd:
			bd = int(a.get("danno", 0))
			best = id
	return best

## Armi da tiro che u può usare ora (non scariche, non guaste, monouso non usate).
func armi_tiro(u: Dictionary) -> Array:
	var r := []
	for id in u.armi:
		var a := Dati.arma(str(id))
		if int(a.get("gittata", 0)) <= 0 or str(id) in r:
			continue
		if arma_usabile(u, str(id)):
			r.append(str(id))
	return r

func arma_usabile(u: Dictionary, id: String) -> bool:
	if id in u.scariche or str(u.guasti.get(id, "")) == "rotta":
		return false
	if "monouso" in Dati.tratti_arma(id) and id in u.monouso_usati:
		return false
	return true

## ===================== tiro: soglie e bersagli (p.44-47) =====================

## Numero da ottenere per colpire: 3+ entro 6" allo scoperto, 5+ in gittata allo scoperto o entro 6" in copertura, 6+ in copertura.
func soglia_colpire(u: Dictionary, bersaglio: Dictionary, arma_id := "", panico := false) -> Dictionary:
	if arma_id == "":
		arma_id = str(u.arma)
	var a := arma_eff(u, arma_id)
	if a.is_empty():
		return {"ok": false, "soglia": 99, "copertura": false, "distanza": 0, "mod": 0}
	var g := int(a.gittata)
	if panico:
		g = int(Dati.arma(arma_id).get("gittata", 0)) / 2
	var d := dist(u.pos, bersaglio.pos)
	var l := lds(u.pos, bersaglio.pos, false, u, bersaglio)
	if not l.vede or not l.colpibile or d > g or g <= 0 or _congelato(bersaglio):
		return {"ok": false, "soglia": 99, "copertura": l.copertura, "distanza": d, "mod": 0}
	var cop: bool = l.copertura
	var sb: Dictionary = bersaglio.get("speciali", {})
	if sb.get("sempre_in_copertura", false):
		cop = true
	if sb.has("copertura_terzo_proprio_oltre") and d > int(sb.copertura_terzo_proprio_oltre):
		var terzo: bool = bersaglio.pos.y < H / 3 if bersaglio.lato == NEM else bersaglio.pos.y >= H - H / 3
		if terzo:
			cop = true
	if ha(bersaglio, "mantello_mimetico") and d > 4 and not cop:
		for dd in _dir8():
			for k in [1, 2]:
				var q: Vector2i = bersaglio.pos + dd * k
				if t_at(q) in [T.LINEARE, T.SINGOLO, T.AREA, T.BLOCCO, T.MURO]:
					cop = true
	var s := 0
	if d <= 6:
		s = 5 if cop else 3
	else:
		s = 6 if cop else 5
	var mod := int(u.combattimento)
	if u.speciali.has("combattimento_tiro_fisso"):
		mod = int(u.speciali.combattimento_tiro_fisso)
	else:
		mod += int(u.speciali.get("combattimento_tiro", 0)) + int(a.colpire)
		if not u.mosso:
			mod += int(a.colpire_fermo)
		if int(a.colpire_stesso) > 0 and int(u.ultimo_bersaglio) == int(bersaglio.uid):
			mod += int(a.colpire_stesso)
		if not a.oltre.is_empty() and d > int(a.oltre.get("distanza", 8)) and (not u.mosso or cop):
			mod += int(a.oltre.get("bonus", 1))
		if round_n <= int(u.bonus_fino):
			mod += int(u.bonus_round.get("colpire", 0))
	var tr: Array = a.tratti
	if "tiro_rapido" in tr and d <= 6:
		mod += 1
	if "pesante" in tr and u.mosso and not u.speciali.get("sempre_fermo_sparo", false):
		mod -= 1
	mod += int(sb.get("bonus_colpire_contro", 0))
	# Equipaggiamento furtivo: -1 a chi spara da oltre 9"
	if ha(bersaglio, "equip_furtivo") and d > 9:
		mod -= 1
	# Emettitore sonico: -1 ai nemici entro 5"
	if u.lato != EQ:
		for w in figure(EQ):
			if ha(w, "emettitore_sonico") and dist(w.pos, u.pos) <= 5:
				mod -= 1
				break
	return {"ok": true, "soglia": s, "mod": mod, "copertura": cop, "distanza": d}

## Bersagli possibili per u: lista di {"u", "soglia", "mod", "copertura", "distanza", "netto"} ordinata (più facile, più vicino).
## p.44: chi ha un avversario visibile entro 3" deve sparare a uno entro 3"; gli Swift sparano al più vicino.
func bersagli(u: Dictionary, arma_id := "", panico := false) -> Array:
	var r := []
	if arma_id == "":
		arma_id = str(u.arma)
	if arma_id == "" or u.vip or not arma_usabile(u, arma_id) or u.no_fuoco:
		return r
	var vicini := false
	var avv := avversari(u)
	for v in avv:
		if dist(u.pos, v.pos) <= 3 and vede(u, v):
			vicini = true
	for v in avv:
		var s := soglia_colpire(u, v, arma_id, panico)
		if not s.ok:
			continue
		if vicini and s.distanza > 3:
			continue
		s["u"] = v
		s["netto"] = int(s.soglia) - int(s.mod)
		if u.speciali.get("colpisce_solo_6", false):
			s["netto"] = 6
		r.append(s)
	r.sort_custom(func(x, y): return x.netto < y.netto or (x.netto == y.netto and x.distanza < y.distanza))
	if (u.specie == "swift" or panico) and not r.is_empty():
		var dm := 999
		for x in r:
			dm = min(dm, int(x.distanza))
		r = r.filter(func(x): return int(x.distanza) == dm)
	# Agente segreto: preferisce il bersaglio prioritario
	if u.speciali.get("bersaglio_prioritario", false) and u.has("preda"):
		for x in r:
			if int(x.u.uid) == int(u.preda):
				r.erase(x)
				r.push_front(x)
				break
	return r

func adiacenti_nemici(u: Dictionary) -> Array:
	var r := []
	for v in avversari(u):
		if dist(u.pos, v.pos) == 1:
			r.append(v)
	return r

## ===================== movimento (p.41-42, Appendice II) =====================

var _genitori := {}

## Movimento disponibile in mezzi pollici.
func budget(u: Dictionary, scatto := false) -> int:
	var v := stat(u, "velocita")
	if ha(u, "impianto_gambe"):
		v += 1
	if u.doppia_vel:
		v *= 2
	var b := v * 2
	if scatto:
		b += 4 + (2 if ha(u, "impianto_gambe") else 0) + int(u.speciali.get("scatto_extra", 0)) * 2
	if int(cond.get("velocita_suolo", 0)) != 0 and a_at(u.pos) == 0:
		b += int(cond.velocita_suolo) * 2
	return max(0, b)

func _bloccata_da(u: Dictionary, q: Vector2i) -> bool:
	var f := figura_in(q)
	return not f.is_empty() and ostili(f, u)

## Caselle raggiungibili: {Vector2i: costo in mezzi pollici}. scatto = +2" senza azione di combattimento.
## Le figure amiche si possono attraversare (Appendice II), quelle avversarie no. Non si termina su una casella occupata,
## su un ostacolo lineare o a metà di una parete. Con lo scatto non si entra in contatto con un avversario (p.41).
func raggiungibili(u: Dictionary, scatto := false) -> Dictionary:
	if round_n > 0 and int(u.immobile_fino) >= round_n:
		return {u.pos: 0}
	var bud := budget(u, scatto)
	var extra_fuga := 4 if u.speciali.has("velocita_fuga") else 0
	var attraversa: bool = u.speciali.get("attraversa_terreno", false)
	var best := {u.pos: 0}
	_genitori = {}
	var coda := [u.pos]
	var salto_max := int(u.speciali.get("salto_varchi", 2))
	while not coda.is_empty():
		var p: Vector2i = coda.pop_front()
		var c: int = best[p]
		var passi := []
		for d in _dir8():
			var q: Vector2i = p + d
			if attraversa:
				if dentro(q):
					passi.append([q, 3 if difficile(q) else 2])
				continue
			if not percorribile(q) or _bloccata_da(u, q):
				continue
			# dal basso non si sale su un blocco più alto di 3" senza arrampicarsi oltre il movimento: lo limita il costo
			passi.append([q, costo_passo(p, q)])
		# salto di un varco (p.42): da una superficie rialzata a un'altra oltre un vuoto fino a 2" (Swift 4")
		if a_at(p) >= 1:
			for d in _dir8():
				for k in range(2, salto_max + 2):
					var q: Vector2i = p + d * k
					if not dentro(q):
						break
					var vuoto := true
					for j in range(1, k):
						if a_at(p + d * j) >= a_at(p) or t_at(p + d * j) in [T.MURO]:
							vuoto = false
					if vuoto and abs(a_at(q) - a_at(p)) <= 1 and calpestabile(q) and not _bloccata_da(u, q):
						passi.append([q, k * 2])
		for x in passi:
			var q: Vector2i = x[0]
			var nc: int = c + int(x[1])
			if nc <= bud + extra_fuga and (not best.has(q) or nc < best[q]):
				best[q] = nc
				_genitori[q] = p
				coda.append(q)
	var r := {}
	var avv := avversari(u)
	for p in best:
		var f := figura_in(p)
		if not (f.is_empty() or f.uid == u.uid):
			continue
		if not calpestabile(p):
			continue
		if int(best[p]) > bud:
			# Viaggiatore: +2" solo allontanandosi direttamente da un nemico visibile
			if not _si_allontana(u, p, avv):
				continue
		if p != u.pos and _a_contatto(u, p, avv):
			if scatto or not _puo_entrare_rissa(u):
				continue
		r[p] = best[p]
	return r

func _si_allontana(u: Dictionary, p: Vector2i, avv: Array) -> bool:
	var vicino := {}
	for v in avv:
		if vede(u, v) and (vicino.is_empty() or dist(u.pos, v.pos) < dist(u.pos, vicino.pos)):
			vicino = v
	if vicino.is_empty():
		return false
	return dist(p, vicino.pos) - dist(u.pos, vicino.pos) >= dist(u.pos, p) - 1

func _a_contatto(u: Dictionary, p: Vector2i, avv: Array) -> bool:
	for v in avv:
		if dist(p, v.pos) == 1 and abs(a_at(p) - a_at(v.pos)) <= 1:
			return true
	return false

## Può entrare volontariamente in Rissa (muovendosi a contatto).
func _puo_entrare_rissa(u: Dictionary) -> bool:
	if u.vip or u.speciali.get("no_rissa_volontaria", false) or int(u.stordito) > 0 or u.agito:
		return false
	return true

## Percorso fino a p (ultima ricerca): serve per aprire le porte attraversate.
func percorso(da: Vector2i, a: Vector2i) -> Array:
	var r := [a]
	var p := a
	var guard := 0
	while _genitori.has(p) and p != da and guard < 200:
		p = _genitori[p]
		r.push_front(p)
		guard += 1
	return r

## Muove u fino a dest. Se arriva a contatto con un avversario la Rissa si risolve subito (p.41).
func muovi(u: Dictionary, dest: Vector2i, scatto := false, rissa_auto := true) -> bool:
	if u.mosso or not u.attiva or _congelato(u):
		return false
	if u.agito and not scatto and u.lato == EQ and int(u.mossa_bonus) == 0:
		return false
	var r := raggiungibili(u, scatto)
	if not r.has(dest):
		return false
	var da: Vector2i = u.pos
	for p in percorso(da, dest):
		if t_at(p) == T.PORTA and not porte_aperte.has(p):
			porte_aperte[p] = true
			scrivi("%s apre una porta." % u.nome)
	_sposta(u, dest)
	u.mosso = dest != da
	u.scatto = scatto
	if scatto:
		u.agito = true
	if int(u.stordito) > 0:
		u.agito = true
	_dopo_movimento(u, da)
	if rissa_auto and u.attiva and not u.agito and dest != da:
		var adiac := adiacenti_nemici(u)
		if not adiac.is_empty():
			rissa(u, adiac[0])
	return true

## Spostamento fisico con eventi grafici.
func _sposta(u: Dictionary, dest: Vector2i) -> void:
	eventi.append({"tipo": "muovi", "uid": u.uid, "da": u.pos, "a": dest})
	u.pos = dest

## Dopo ogni movimento: obiettivi, segnalini, reazioni dell'equipaggio (Snap Fire e sensore automatico).
func _dopo_movimento(u: Dictionary, da: Vector2i) -> void:
	if u.lato == EQ:
		_controlla_obiettivi_posizione(u)
		for sg in segnalini.duplicate():
			if sg.tipo == "rinforzi" and dist(sg.pos, u.pos) <= 3:
				segnalini.erase(sg)
				scrivi("%s fa sgombrare un punto di arrivo dei rinforzi." % u.nome)
	elif u.lato == NEM and u.attiva:
		_reazioni_al_movimento(u, da)

func _controlla_obiettivi_posizione(u: Dictionary) -> void:
	match obiettivo:
		"pattugliare":
			for pt in stato_obj.get("punti", []):
				if not pt.fatto:
					for e in elementi:
						if e.id == pt.id:
							for c in e.celle:
								if dist(c, u.pos) <= 2:
									pt.fatto = true
					if pt.fatto:
						scrivi("%s controlla il punto di pattuglia: %s." % [u.nome, pt.nome], "obiettivo")
			var tutti := true
			for pt in stato_obj.get("punti", []):
				if not pt.fatto:
					tutti = false
			if tutti and not stato_obj.get("punti", []).is_empty():
				_obiettivo_fatto()

## Un nemico si è mosso: chi aspetta per lo Snap Fire (p.113) può sparargli; il sensore automatico spara un colpo di pistola.
func _reazioni_al_movimento(n: Dictionary, da: Vector2i) -> void:
	for w in figure(EQ):
		if not n.attiva:
			return
		# sensore automatico: inizio o fine del movimento entro 4" e in vista, colpo di pistola che colpisce solo con 6
		if ha(w, "sensore_auto") and int(w.get("sensore_round", 0)) != round_n:
			var vicino: bool = dist(w.pos, n.pos) <= 4 or dist(w.pos, da) <= 4
			var p := _pistola_migliore(w)
			if vicino and p != "" and vede(w, n):
				w["sensore_round"] = round_n
				scrivi("Sensore automatico: %s spara d'istinto a %s." % [w.nome, n.nome], "tiro")
				_risolvi_colpi(w, n, p, {"solo_6": true, "colpi": 1, "reazione": true})
	for w in figure(EQ):
		if not n.attiva:
			return
		if w.attesa == "snap" and not w.agito and not w.attivato:
			var bs := bersagli(w)
			var ok := false
			for x in bs:
				if x.u.uid == n.uid:
					ok = true
			if ok:
				scrivi("SNAP FIRE: %s apre il fuoco su %s che si muove." % [w.nome, n.nome], "tiro")
				w.attesa = ""
				spara(w, n)
				w.mosso = true    # chi spara durante il movimento nemico non può muoversi in questo round
				w.attivato = true
				if int(n.stordito) > 0 and n.attiva:
					n.no_fuoco = true
					scrivi("  %s, stordito dal fuoco, non può sparare in questo round." % n.nome)

## ---- movimenti alternativi (p.42) e salti ----

## Caselle per saltare giù (p.42): adiacenti più in basso di oltre 1".
func caselle_salto(u: Dictionary) -> Array:
	var r := []
	for d in _dir8():
		var q: Vector2i = u.pos + d
		if calpestabile(q) and figura_in(q).is_empty() and a_at(u.pos) - a_at(q) > 1:
			r.append(q)
	return r

func salta_giu(u: Dictionary, q: Vector2i) -> bool:
	if not q in caselle_salto(u):
		return false
	var caduta := a_at(u.pos) - a_at(q)
	_sposta(u, q)
	scrivi("%s salta giù di %d\"." % [u.nome, caduta])
	if u.specie == "swift" or u.speciali.get("caduta_illesa", false):
		return true
	if not ha(u, "smorzatore_grav"):
		if caduta >= 3:
			scrivi("  La caduta fa male: colpo con Danno +0.")
			colpisci({}, u, 0, [], false, "caduta")
		u.mosso = true
		u.agito = true
	elif caduta > 6:
		u.mosso = true
	return true

## Movimenti alternativi disponibili: [{id, nome}].
func movimenti_alternativi(u: Dictionary) -> Array:
	var r := []
	if u.lato != EQ or u.mosso or int(u.immobile_fino) >= round_n:
		return r
	if u.speciali.has("teletrasporto"):
		r.append({"id": "teletrasporto", "nome": "Teletrasporto (1D6\")"})
	if ha(u, "jump_belt"):
		r.append({"id": "jump_belt", "nome": "Cintura a reazione (salto fino a 9\")"})
	if ha(u, "hoverboard"):
		r.append({"id": "hoverboard", "nome": "Hoverboard (9\", poi niente combattimento)"})
	if ha(u, "dislocatore") and not "dislocatore" in u.usati_battaglia and not _usato_missione("dislocatore", u):
		r.append({"id": "dislocatore", "nome": "Dislocatore (teletrasporto mirato)"})
	if u.speciali.get("plana", false) and a_at(u.pos) > 0:
		r.append({"id": "plana", "nome": "Plana verso il basso"})
	if not u.agito and tratti_mondo.any(func(t): return str(t).to_lower().contains("ghiacciato")):
		r.append({"id": "scivolata", "nome": "Scivola sul ghiaccio (scatto di 1D6\" in linea retta)"})
	return r

func _usato_missione(id: String, u: Dictionary) -> bool:
	return id in guadagni.oggetti_usati.get(str(u.pg), [])

## Caselle d'arrivo di un movimento alternativo.
func caselle_alternative(u: Dictionary, id: String) -> Array:
	var r := []
	match id:
		"teletrasporto":
			if int(u.tele_raggio) <= 0:
				u.tele_raggio = dadi.d6() + int(u.get("tele_bonus", 0))
				scrivi("%s si prepara al teletrasporto: %d\"." % [u.nome, u.tele_raggio])
			for y in H:
				for x in W:
					var q := Vector2i(x, y)
					if dist(q, u.pos) <= int(u.tele_raggio) and calpestabile(q) and figura_in(q).is_empty():
						r.append(q)
		"jump_belt":
			for d in _dir8():
				for k in range(1, 10):
					var q: Vector2i = u.pos + d * k
					if not dentro(q):
						break
					if a_at(q) - a_at(u.pos) > 3 or t_at(q) == T.MURO:
						break
					if calpestabile(q) and figura_in(q).is_empty():
						r.append(q)
		"hoverboard":
			var best := {u.pos: 0}
			var coda := [u.pos]
			while not coda.is_empty():
				var p: Vector2i = coda.pop_front()
				for d in _dir8():
					var q: Vector2i = p + d
					if not dentro(q) or t_at(q) in [T.MURO, T.MURO_FORZA] or impraticabili.has(q) or (t_at(q) == T.BLOCCO and a_at(q) > 1) or _bloccata_da(u, q):
						continue
					var nc: int = best[p] + 2
					if nc <= 18 and (not best.has(q) or nc < best[q]):
						best[q] = nc
						coda.append(q)
			for q in best:
				if q != u.pos and calpestabile(q) and figura_in(q).is_empty() and not _a_contatto(u, q, avversari(u)):
					r.append(q)
		"plana":
			for y in H:
				for x in W:
					var q := Vector2i(x, y)
					var dz := a_at(u.pos) - a_at(q)
					if dz > 0 and dist(q, u.pos) <= dz and calpestabile(q) and figura_in(q).is_empty():
						r.append(q)
		"dislocatore":
			for y in H:
				for x in W:
					var q := Vector2i(x, y)
					if q != u.pos and lds(u.pos, q, true, u).vede:
						r.append(q)
		"scivolata":
			for d in _dir8():
				if dentro(u.pos + d):
					r.append(u.pos + d)
	return r

## Esegue un movimento alternativo verso q.
func movimento_alternativo(u: Dictionary, id: String, q: Vector2i) -> bool:
	if not q in caselle_alternative(u, id):
		return false
	var da: Vector2i = u.pos
	match id:
		"dislocatore":
			u.usati_battaglia.append("dislocatore")
			_segna_uso(u, "dislocatore")
			var dd: Vector2i = _dir8()[dadi.d(8) - 1]
			var k := dadi.d6()
			var arrivo: Vector2i = q + dd * k
			scrivi("%s usa il Dislocatore: riappare a %d\" dal punto mirato." % [u.nome, k])
			if not dentro(arrivo) or not calpestabile(arrivo) or not figura_in(arrivo).is_empty():
				scrivi("  Arriverebbe dentro un ostacolo: il dispositivo fallisce e va riparato.", "pericolo")
				guadagni.note.append("Dislocatore di %s danneggiato." % u.nome)
				guadagni["danneggiati"] = guadagni.get("danneggiati", []) + [[u.pg, "dislocatore"]]
				u.mosso = true
				return true
			_sposta(u, arrivo)
		"scivolata":
			# Ghiacciato: si percorre tutta la distanza; se si urta qualcosa, chi scivola e chi è urtato sono spinti e storditi
			var dd: Vector2i = q - u.pos
			var k := dadi.d6()
			scrivi("%s scivola sul ghiaccio per %d\"." % [u.nome, k])
			for i in k:
				var nq: Vector2i = u.pos + dd
				var f := figura_in(nq)
				if not calpestabile(nq) or abs(a_at(nq) - a_at(u.pos)) > 1 or not f.is_empty():
					scrivi("  Urta qualcosa e finisce stordito.")
					_movimento_casuale(u, 1, false)
					_stordisci(u, 1)
					if not f.is_empty():
						_movimento_casuale(f, 1, false)
						_stordisci(f, 1)
					break
				_sposta(u, nq)
			u.agito = true
			u.scatto = true
		"hoverboard":
			_sposta(u, q)
			u["no_combattimento"] = true
			scrivi("%s sfreccia sull'hoverboard." % u.nome)
		_:
			_sposta(u, q)
			scrivi("%s: %s." % [u.nome, {"teletrasporto": "si teletrasporta", "jump_belt": "salta con la cintura a reazione", "plana": "plana verso il basso"}.get(id, id)])
	u.mosso = true
	u.tele_raggio = 0
	_dopo_movimento(u, da)
	return true

func _segna_uso(u: Dictionary, id: String) -> void:
	if str(u.pg) == "":
		return
	var m: Dictionary = guadagni.oggetti_usati
	if not m.has(str(u.pg)):
		m[str(u.pg)] = []
	m[str(u.pg)].append(id)

## ===================== danni (p.46) =====================

## Applica n segnalini Stordito (con impianti, condizione «Ambiente tossico» e K.O. a 3 segnalini).
func _stordisci(v: Dictionary, n := 1) -> void:
	if not v.attiva or n <= 0:
		return
	if ha(v, "impianto_riflessi"):
		scrivi("  %s non può essere stordito (impianto dei riflessi)." % v.nome)
		return
	for i in n:
		if ha(v, "regolatore_nervi") and dadi.d6() >= 5:
			scrivi("  Il regolatore nervoso di %s evita lo stordimento." % v.nome)
			continue
		v.stordito += 1
		if cond.has("tossico"):
			var t := dadi.d6()
			var b := int(v.get("acume", 0)) if v.lato == EQ else 0
			if t + b < int(cond.tossico.get("soglia", 4)):
				scrivi("  Ambiente tossico: %s tira %d%+d e crolla." % [v.nome, t, b], "perdita")
				elimina(v, {})
				return
	_controlla_ko(v)

func _controlla_ko(v: Dictionary) -> void:
	if v.attiva and int(v.stordito) >= 3:
		scrivi("  %s ha 3 segnalini Stordito ed è messo fuori combattimento." % v.nome)
		v.ko = true
		elimina(v, {})

## Tiro salvezza (p.46): migliore tra quelli validi, migliorato di 1 se ce ne sono più di uno.
func _tiro_salvezza(v: Dictionary, perforante: bool, area := false, mischia := false, ignora_armatura := false) -> bool:
	var sv := []
	for s in v.get("salvezze", []):
		if s.tipo == "corazza" and (perforante or ignora_armatura):
			continue
		if area and "area" in s.esclude or mischia and "rissa" in s.esclude:
			continue
		var val := int(s.v)
		if area and int(s.get("area", 0)) > 0:
			val = min(val, int(s.area))
		sv.append(val)
	if sv.is_empty():
		return false
	sv.sort()
	var t: int = max(2, sv[0] - (1 if sv.size() > 1 else 0))
	var r := dadi.d6()
	if r >= t:
		scrivi("  Tiro salvezza di %s: %d (serve %d+), il colpo è deviato." % [v.nome, r, t])
		return true
	scrivi("  Tiro salvezza di %s: %d (serve %d+), fallito." % [v.nome, r, t])
	return false

## Risolve un colpo con danno dmg su v da parte di att. Restituisce true se v è eliminato.
func colpisci(att: Dictionary, v: Dictionary, dmg: int, tratti: Array, mischia := false, fonte := "") -> bool:
	if not v.attiva or _congelato(v):
		return false
	var area := "area" in tratti
	var ignora_arm: bool = att.get("speciali", {}).get("ignora_armatura", false) or fonte == "ambientale"
	if "stordente" in tratti:
		scrivi("  %s è stordito." % v.nome)
		_stordisci(v, 1)
		return not v.attiva
	# Schermo deflettore: devia il primo colpo a distanza della battaglia
	if not mischia and fonte == "" and ha(v, "schermo_deflettore") and not v.deflettore_usato and not att.is_empty():
		v.deflettore_usato = true
		scrivi("  Lo schermo deflettore di %s devia il colpo." % v.nome)
		return false
	if area and ha(v, "schermo_flak"):
		dmg = max(0, dmg - 1)
	var bonus_m := 0
	if mischia and not att.is_empty():
		bonus_m = int(att.get("speciali", {}).get("danno_mischia", 0))
	var t := dadi.d6()
	var tot := t + dmg + bonus_m
	var rob := stat(v, "robustezza")
	var fuori: bool = t == 6 or tot >= rob
	scrivi("  Danno: %d%+d = %d contro Robustezza %d%s." % [t, dmg + bonus_m, tot, rob, " (6 naturale)" if t == 6 else ""])
	var da: Vector2i = att.pos if not att.is_empty() else v.pos + Vector2i(0, 1)
	if fuori:
		if _tiro_salvezza(v, "perforante" in tratti, area, mischia, ignora_arm):
			fuori = false
		elif int(v.fortuna) > 0:
			v.fortuna -= 1
			scrivi("  %s usa la Fortuna e si getta al riparo!" % v.nome)
			_movimento_casuale(v, dadi.d6(), false)
			return false
		elif v.lato == EQ and _usa_stim(v):
			return false
	if fuori:
		elimina(v, att, mischia)
		return true
	_respingi(v, da)
	var n_st := 1
	if "impatto" in tratti:
		n_st += 1
	_stordisci(v, n_st)
	if v.attiva:
		scrivi("  %s è respinto e stordito (%d segnalini)." % [v.nome, v.stordito])
	if v.attiva and "terrificante" in tratti:
		var k := dadi.d6()
		scrivi("  %s si ritira di %d\" per il terrore." % [v.nome, k])
		for i in k:
			_respingi(v, da)
	if v.attiva and not mischia and not att.is_empty():
		if int(v.speciali.get("ritirata_se_colpito", 0)) > 0:
			scrivi("  %s se la dà a gambe." % v.nome)
			for i in int(v.speciali.ritirata_se_colpito):
				_respingi(v, da)
		if int(v.speciali.get("avanza_se_colpito", 0)) > 0:
			var dd := Vector2i(signi(da.x - v.pos.x), signi(da.y - v.pos.y))
			var q: Vector2i = v.pos + dd
			if calpestabile(q) and figura_in(q).is_empty():
				_sposta(v, q)
				scrivi("  %s, infuriato, avanza verso chi gli ha sparato." % v.nome)
	return not v.attiva

func _usa_stim(v: Dictionary) -> bool:
	if "stim" in v.consumabili and not "stim" in v.monouso_usati:
		v.monouso_usati.append("stim")
		_segna_uso(v, "stim")
		v.stordito = 1
		scrivi("  %s usa uno Stim-pack e resta in piedi." % v.nome)
		return true
	return false

func _respingi(v: Dictionary, da: Vector2i) -> void:
	if not v.attiva:
		return
	var d := Vector2i(signi(v.pos.x - da.x), signi(v.pos.y - da.y))
	if d == Vector2i.ZERO:
		d = Vector2i(0, 1 if v.lato == EQ else -1)
	var q: Vector2i = v.pos + d
	if calpestabile(q) and figura_in(q).is_empty() and a_at(q) <= a_at(v.pos):
		_sposta(v, q)

## Movimento casuale (p.42): direzione a caso, in linea retta; si ferma e viene stordito contro un ostacolo o una figura.
func _movimento_casuale(v: Dictionary, k: int, stordisce := true) -> void:
	var dd: Vector2i = _dir8()[dadi.d(8) - 1]
	var dest: Vector2i = v.pos
	for i in k:
		var q: Vector2i = dest + dd
		var f := figura_in(q)
		if not calpestabile(q) or abs(a_at(q) - a_at(dest)) > 1:
			if stordisce:
				_stordisci(v, 1)
			break
		if not f.is_empty():
			if stordisce:
				_stordisci(v, 1)
				var q2: Vector2i = q + dd
				if calpestabile(q2) and figura_in(q2).is_empty():
					_sposta(f, q2)
				_stordisci(f, 1)
			break
		dest = q
	if dest != v.pos:
		_sposta(v, dest)

func elimina(v: Dictionary, att: Dictionary, mischia := false) -> void:
	if not v.attiva:
		return
	v.attiva = false
	v.fuori = true
	scrivi("  %s è fuori combattimento!" % v.nome, "perdita")
	eventi.append({"tipo": "fuori", "uid": v.uid})
	if v.lato == NEM:
		perdite_round += 1
		perdite_totali += 1
		if not att.is_empty() and att.get("lato") == EQ and primo_colpo == "" and str(att.get("pg", "")) != "":
			primo_colpo = str(att.pg)
		if v.unico and not att.is_empty() and str(att.get("pg", "")) != "":
			unico_ucciso = str(att.pg)
		if v.get("bersaglio", false):
			_obiettivo_fatto()
		if v.get("taglia_luogo", false):
			var c := dadi.d(3)
			guadagni.crediti += c
			scrivi("  Bersaglio prioritario abbattuto: %d crediti." % c, "obiettivo")
		if v.speciali.get("morale_extra_se_ucciso", 0):
			morale_extra += int(v.speciali.morale_extra_se_ucciso)
		if v.speciali.get("bottino_se_ucciso_in_rissa", false) and mischia:
			guadagni.bottino += 1
			scrivi("  Il Freelance cade in Rissa: un tiro sul Bottino dopo la battaglia.", "obiettivo")
		if v.speciali.get("rivale_se_ucciso", "") != "":
			guadagni["rivale"] = str(v.speciali.rivale_se_ucciso)
		var rit := int(v.speciali.get("ritirata_alleati_se_ucciso", 0))
		if rit > 0:
			for w in figure(NEM):
				if dist(w.pos, v.pos) <= rit:
					var passi := int(w.velocita)
					for i in passi:
						var q: Vector2i = w.pos + Vector2i(0, -1)
						if calpestabile(q) and figura_in(q).is_empty():
							_sposta(w, q)
					scrivi("  %s si ritira verso il proprio bordo." % w.nome)
		var rig: Dictionary = v.speciali.get("rigenera", {})
		if not rig.is_empty() and dadi.d6() >= int(rig.get("soglia", 5)):
			var nuovo := _figura_nemico(Dati.nemico(str(v.tipo)), str(v.tipo), v.armi, str(v.ia))
			var dd: Vector2i = _dir8()[dadi.d(8) - 1]
			nuovo.pos = _libera_vicina(v.pos + dd * dadi.d6(), true)
			unita.append(nuovo)
			scrivi("  Il tremolio si ricompone: un altro %s appare poco lontano." % nuovo.nome, "pericolo")
		for w in figure(NEM):
			if int(w.padrone) == int(v.uid):
				w.fedele_difende = true
				scrivi("  %s resta accanto al padrone caduto, pronto ad azzannare." % w.nome)
	elif v.lato == EQ:
		if v.porta != "":
			if dadi.d6() == 1:
				scrivi("  Il %s è distrutto." % v.porta)
				stato_obj["fallito"] = true
			else:
				stato_obj["caduto"] = {"cosa": v.porta, "pos": v.pos}
				scrivi("  Il %s cade a terra: si può raccogliere con un'azione." % v.porta)
			v.porta = ""
		if v.vip:
			stato_obj["fallito"] = true

## ===================== tiro (p.44-47) =====================

## Il tiro metterebbe a rischio un alleato (arma ad Area con amici entro 2" dal bersaglio, p.44).
func _rischia_alleati(u: Dictionary, v: Dictionary, a: Dictionary) -> bool:
	if not "area" in a.get("tratti", []):
		return false
	for w in unita:
		if w.attiva and w.uid != u.uid and w.lato == u.lato and dist(w.pos, v.pos) <= 2:
			return true
	return false

## Può tirare a rischio di colpire alleati? Swift e Senz'anima sì; i Bot mai; gli altri con 5+ (i nemici no).
func _osa_rischiare(u: Dictionary) -> bool:
	if u.robot:
		return false
	if u.specie in ["swift", "soulless"]:
		return true
	if u.lato != EQ:
		return false
	if int(u.get("rifiuta_area_round", 0)) == round_n:
		return false
	var t := dadi.d6()
	if t >= 5:
		scrivi("%s si decide a sparare nonostante gli alleati vicini (%d)." % [u.nome, t])
		return true
	scrivi("%s non se la sente di sparare con gli alleati così vicini (%d): sceglie un'altra azione." % [u.nome, t])
	u["rifiuta_area_round"] = round_n
	return false

## Tiro a distanza come Azione di combattimento. opzioni: {"panico": bool, "iniziativa": bool}.
func spara(u: Dictionary, v: Dictionary, arma_id := "", iniziativa := false, panico := false) -> bool:
	if not u.attiva or _congelato(u) or u.get("no_combattimento", false) or u.no_fuoco:
		return false
	if arma_id == "":
		arma_id = str(u.arma)
	var due_pistole: bool = u.speciali.get("due_pistole", false) and "pistola" in Dati.tratti_arma(arma_id)
	var gia: Array = u.get("pistole_sparate", [])
	if u.agito and not (due_pistole and gia.size() == 1 and not arma_id in gia):
		return false
	if not arma_usabile(u, arma_id):
		return false
	var a := arma_eff(u, arma_id)
	if panico and "monouso" in a.tratti:
		return false
	var s := soglia_colpire(u, v, arma_id, panico)
	if not s.ok:
		return false
	if _rischia_alleati(u, v, a) and not _osa_rischiare(u):
		return false
	if "monouso" in a.tratti:
		u.monouso_usati.append(arma_id)
		_segna_uso(u, arma_id)
	if due_pistole and gia.size() == 0 and _altra_pistola(u, arma_id) != "":
		u["pistole_sparate"] = [arma_id]
	else:
		u.agito = true
		u["pistole_sparate"] = []
	u.sparato_round = round_n
	var colpi := int(a.colpi) + (2 if panico else 0)
	scrivi("%s %s a %s con %s (%d colpi, %d+%s)." % [u.nome, "fa fuoco nel panico" if panico else "spara", v.nome, a.nome, colpi, s.soglia,
		(" %+d" % s.mod) if s.mod != 0 else ""], "tiro")
	_risolvi_colpi(u, v, arma_id, {"colpi": colpi, "iniziativa": iniziativa, "panico": panico})
	if panico:
		for id in u.armi:
			if id == arma_id and not id in u.scariche:
				u.scariche.append(id)
		scrivi("  L'arma di %s è scarica per il resto della battaglia." % u.nome)
	u.ultimo_bersaglio = v.uid
	if str(u.guasti.get(arma_id, "")) == "un_colpo":
		u.guasti[arma_id] = "rotta"
	return true

func _altra_pistola(u: Dictionary, esclusa: String) -> String:
	for id in armi_tiro(u):
		if id != esclusa and "pistola" in Dati.tratti_arma(id):
			return id
	return ""

## Risolve i colpi di una raffica. op: colpi, iniziativa (solo 6), panico, solo_6, reazione.
func _risolvi_colpi(u: Dictionary, v: Dictionary, arma_id: String, op := {}) -> void:
	var a := arma_eff(u, arma_id)
	var tr: Array = a.tratti
	var colpi := int(op.get("colpi", a.colpi))
	var solo6: bool = op.get("iniziativa", false) or op.get("solo_6", false) or u.speciali.get("colpisce_solo_6", false)
	var in_cop := t_at(u.pos) == T.AREA or _vicino_a_terreno(u.pos)
	var mira: bool = not u.mosso and int(u.stordito) == 0 and not op.get("panico", false) and not op.get("reazione", false)
	if u.lato != EQ:
		mira = mira and str(u.ia) in ["tattico", "cauto", "difensivo"] and in_cop
	eventi.append({"tipo": "spara", "uid": u.uid, "a": v.uid, "da_pos": u.pos, "a_pos": v.pos})
	var bersaglio := v
	var orig: Vector2i = v.pos
	var surriscaldata := false
	var extra := 0
	var i := 0
	while i < colpi + extra:
		i += 1
		if op.get("panico", false) and i > 1:
			# fuoco nel panico: ogni colpo al bersaglio disponibile più vicino in quel momento
			var bs := bersagli(u, arma_id, true)
			if bs.is_empty():
				break
			bersaglio = bs[0].u
		elif not bersaglio.attiva:
			if "concentrata" in tr or "area" in tr:
				break
			var altri := []
			for w in avversari(u):
				if dist(w.pos, orig) <= 3 and soglia_colpire(u, w, arma_id).ok:
					altri.append(w)
			if altri.is_empty():
				break
			bersaglio = altri[0]
		var s := soglia_colpire(u, bersaglio, arma_id, op.get("panico", false))
		if not s.ok:
			break
		var t := dadi.d6()
		var nota := ""
		if t == 1 and (mira or a.ritira_1 or (a.ritira_1_singolo and colpi == 1)):
			t = dadi.d6()
			nota = " (ritirato)"
		var ok := (t == 6) if solo6 else (t + int(s.mod) >= int(s.soglia))
		scrivi("  Tiro per colpire contro %s: %d%s%s -> %s." % [bersaglio.nome, t, (" %+d" % s.mod) if s.mod != 0 and not solo6 else "", nota, "colpito" if ok else "mancato"])
		if t == 6 and a.surriscalda:
			surriscaldata = true
		if t == 6 and int(u.speciali.get("tiro_extra_su_6", 0)) > 0:
			extra += 1
		if not ok:
			continue
		var n_colpi := 2 if ("critica" in tr and t == 6) else 1
		var tr_c := tr.duplicate()
		if int(a.impatto_entro) > 0 and s.distanza <= int(a.impatto_entro) and not "impatto" in tr_c:
			tr_c.append("impatto")
		for k in n_colpi:
			colpisci(u, bersaglio, int(a.danno), tr_c)
	if "area" in tr:
		for w in unita.duplicate():
			if w.attiva and w.uid != v.uid and w.uid != u.uid and dist(w.pos, v.pos) <= 2 and not _congelato(w):
				var s2 := soglia_colpire(u, w, arma_id)
				var soglia := int(s2.soglia) if s2.ok else 6
				var t2 := dadi.d6()
				var ok2 := (t2 == 6) if solo6 else (t2 + int(s2.get("mod", u.combattimento)) >= soglia)
				scrivi("  Colpo bonus dell'area contro %s: %d -> %s." % [w.nome, t2, "colpito" if ok2 else "mancato"])
				if ok2:
					colpisci(u, w, int(a.danno), tr)
	if surriscaldata:
		u.guasti[arma_id] = "rotta"
		scrivi("  L'arma di %s si surriscalda: inutilizzabile per il resto dello scontro." % u.nome, "pericolo")

func _vicino_a_terreno(p: Vector2i) -> bool:
	for d in _dir8():
		var q: Vector2i = p + d
		if dentro(q) and t_at(q) in [T.LINEARE, T.SINGOLO, T.BLOCCO, T.AREA, T.MURO, T.FINESTRA, T.PORTA]:
			return true
	return false

## ===================== rissa (p.45) =====================

## Bonus di Rissa: Combattimento, +2 con un'arma da Mischia (+1 con una Pistola), e i vari modificatori.
func _bonus_rissa(u: Dictionary, avv: Dictionary, iniziatore: bool) -> int:
	var b := int(u.combattimento) + int(u.speciali.get("combattimento_rissa", 0))
	var mischia := false
	var pistola := false
	for id in u.armi:
		var t: Array = arma_eff(u, str(id)).get("tratti", [])
		if "mischia" in t:
			mischia = true
		elif "pistola" in t:
			pistola = true
	if mischia:
		b += 2
	elif pistola:
		b += 1
	var am := arma_eff(u, str(u.arma_m)) if str(u.arma_m) != "" else {}
	b += int(am.get("rissa", 0))
	if "goffa" in am.get("tratti", []) and stat(avv, "velocita") > stat(u, "velocita"):
		b -= 1
	if iniziatore:
		b += int(u.speciali.get("rissa_iniziata", 0))
	if int(u.speciali.get("rissa_vicino_terreno", 0)) > 0 and _vicino_a_terreno(u.pos):
		b += int(u.speciali.rissa_vicino_terreno)
	if round_n <= int(u.bonus_fino) or u.bonus_battaglia.has("rissa"):
		b += int(u.bonus_round.get("rissa", 0)) if round_n <= int(u.bonus_fino) else 0
		b += int(u.bonus_battaglia.get("rissa", 0))
	return b

func _dado_rissa(u: Dictionary) -> int:
	var d := dadi.d6()
	if u.speciali.get("rissa_doppio_dado", false) or u.speciali.get("mischia_doppio", false) or u.specie == "kerin":
		d = max(d, dadi.d6())
	return d

## Danno in Rissa: il più alto tra le armi da Mischia e le Pistole portate (+0 senza).
func _arma_rissa(u: Dictionary) -> Dictionary:
	var best := {"danno": 0, "tratti": [], "danno_rissa": 0, "vince_pareggio": false}
	for id in u.armi:
		var a := arma_eff(u, str(id))
		var t: Array = a.get("tratti", [])
		if not ("mischia" in t or "pistola" in t or Dati.arma(str(id)).get("solo_nemici", false)):
			continue
		if int(a.danno) + int(a.danno_rissa) > int(best.danno) + int(best.danno_rissa) or best.tratti.is_empty():
			best = a
	return best

## Rissa iniziata da u contro v (p.45), con più avversari, risse dello Sciame e mossa bonus di 2".
func rissa(u: Dictionary, v: Dictionary) -> bool:
	if u.agito or not u.attiva or not v.attiva or dist(u.pos, v.pos) != 1 or u.scatto or u.vip or _congelato(u) or _congelato(v):
		return false
	if u.get("no_combattimento", false):
		return false
	u.agito = true
	eventi.append({"tipo": "rissa", "uid": u.uid, "a": v.uid})
	if u.speciali.get("risse_fine_fase_nemica", false) and fase == "nemici":
		risse_in_attesa.append([u.uid, v.uid])
		scrivi("%s balza su %s: la Rissa si risolverà alla fine della fase nemica (cacciatori in branco)." % [u.nome, v.nome], "rissa")
		return true
	var opp := adiacenti_nemici(u).filter(func(x): return not _congelato(x))
	if opp.size() > 2:
		var via: Dictionary = dadi.scegli(opp.filter(func(x): return x.uid != v.uid))
		_respingi(via, u.pos)
		opp.erase(via)
	if opp.size() >= 2:
		opp = dadi.mescola(opp)
		scrivi("%s è a contatto con due avversari: la Rissa li affronta uno alla volta." % u.nome, "rissa")
		var vinto := _scontro(u, opp[0], true, 0, 1, false)
		if vinto and u.attiva and opp[1].attiva and dist(u.pos, opp[1].pos) == 1:
			_scontro(u, opp[1], true, 0, 0, false)
		_separa(u)
		return true
	# uno contro uno: chi è in superiorità numerica attorno al bersaglio ha +1
	var amici := 0
	for w in figure(u.lato):
		if w.uid != u.uid and dist(w.pos, v.pos) == 1:
			amici += 1
	_scontro(u, v, true, 1 if amici > 0 else 0, 0)
	_separa(u)
	return true

## Uno scontro di Rissa. Restituisce true se u ha vinto. bonus_u/bonus_v: superiorità numerica.
func _scontro(u: Dictionary, v: Dictionary, iniziatore: bool, bonus_u: int, bonus_v: int, mossa_bonus := true) -> bool:
	scrivi("%s ingaggia %s in una Rissa." % [u.nome, v.nome], "rissa")
	var bu := _bonus_rissa(u, v, iniziatore) + bonus_u
	var bv := _bonus_rissa(v, u, false) + bonus_v
	if int(v.stordito) > 0:
		bu += int(v.stordito)
		scrivi("  %s era stordito: %+d a %s." % [v.nome, int(v.stordito), u.nome])
		v.stordito = 0
	if int(u.stordito) > 0:
		bv += int(u.stordito)
		u.stordito = 0
	var du := _dado_rissa(u)
	var dv := _dado_rissa(v)
	var au := _arma_rissa(u)
	var av := _arma_rissa(v)
	if "elegante" in au.tratti and du + bu < dv + bv:
		du = max(du, dadi.d6())
	if "elegante" in av.tratti and dv + bv < du + bu:
		dv = max(dv, dadi.d6())
	var tu := du + bu
	var tv := dv + bv
	scrivi("  %s %d%+d = %d, %s %d%+d = %d." % [u.nome, du, bu, tu, v.nome, dv, bv, tv])
	var colpi_u := 0
	var colpi_v := 0
	if tu > tv or (tu == tv and au.vince_pareggio and not av.vince_pareggio):
		colpi_u += 1
	elif tv > tu or (tu == tv and av.vince_pareggio):
		colpi_v += 1
	else:
		colpi_u += 1
		colpi_v += 1
	if du == 6:
		colpi_u += 1
	if dv == 6:
		colpi_v += 1
	if du == 1:
		colpi_v += 1
	if dv == 1:
		colpi_u += 1
	var vinto: bool = tu > tv or (tu == tv and au.vince_pareggio and not av.vince_pareggio)
	var tr_u: Array = au.tratti
	var tr_v: Array = av.tratti
	for i in colpi_u:
		if v.attiva:
			colpisci(u, v, int(au.danno) + int(au.danno_rissa), tr_u, true)
	for i in colpi_v:
		if u.attiva:
			colpisci(v, u, int(av.danno) + int(av.danno_rissa), tr_v, true)
	# chi elimina l'avversario può muovere di 2" (non in una nuova Rissa)
	if mossa_bonus and not v.attiva and u.attiva:
		u.mossa_bonus = 2
		if u.lato != EQ or auto_decisioni:
			_mossa_bonus_auto(u)
	elif mossa_bonus and not u.attiva and v.attiva:
		v.mossa_bonus = 0
	return vinto

## Le figure non restano mai a contatto dopo una Rissa (p.45).
func _separa(u: Dictionary) -> void:
	if not u.attiva:
		return
	for w in adiacenti_nemici(u):
		var d := Vector2i(signi(u.pos.x - w.pos.x), signi(u.pos.y - w.pos.y))
		var q: Vector2i = u.pos + d
		if calpestabile(q) and figura_in(q).is_empty():
			_sposta(u, q)
		else:
			_respingi(w, u.pos)

## Mossa bonus di 2" dopo aver eliminato l'avversario in Rissa.
func caselle_mossa_bonus(u: Dictionary) -> Array:
	var r := []
	if int(u.mossa_bonus) <= 0:
		return r
	for y in range(-2, 3):
		for x in range(-2, 3):
			var q: Vector2i = u.pos + Vector2i(x, y)
			if q != u.pos and calpestabile(q) and figura_in(q).is_empty() and abs(a_at(q) - a_at(u.pos)) <= 1 and not _a_contatto(u, q, avversari(u)):
				r.append(q)
	return r

func mossa_bonus(u: Dictionary, q: Vector2i) -> bool:
	if not q in caselle_mossa_bonus(u):
		return false
	_sposta(u, q)
	u.mossa_bonus = 0
	scrivi("%s avanza di slancio." % u.nome)
	return true

func _mossa_bonus_auto(u: Dictionary) -> void:
	var c := caselle_mossa_bonus(u)
	if c.is_empty():
		u.mossa_bonus = 0
		return
	var best: Vector2i = c[0]
	var bs := -999.0
	for q in c:
		var s := (4.0 if _vicino_a_terreno(q) else 0.0) + dadi.rng.randf()
		if s > bs:
			bs = s
			best = q
	mossa_bonus(u, best)

## Risse dei «cacciatori in branco» rimandate alla fine della fase nemica.
func _risolvi_risse_in_attesa() -> void:
	for x in risse_in_attesa:
		var u := per_uid(int(x[0]))
		var v := per_uid(int(x[1]))
		if u.is_empty() or v.is_empty() or not u.attiva or not v.attiva or dist(u.pos, v.pos) != 1:
			continue
		var amici := 0
		for w in figure(u.lato):
			if w.uid != u.uid and dist(w.pos, v.pos) == 1:
				amici += 1
		_scontro(u, v, true, 1 if amici > 0 else 0, 0)
		_separa(u)
	risse_in_attesa = []

## ===================== azioni dell'equipaggio (p.40) =====================

## Scelta che il giocatore deve fare (eventi della battaglia, tregua...). {tipo, testo, opzioni: [{id, nome}]}
var scelta_in_attesa := {}
var _scelte_coda: Array = []

func _chiedi(tipo: String, testo: String, opzioni: Array, dati := {}) -> void:
	var s := {"tipo": tipo, "testo": testo, "opzioni": opzioni, "dati": dati}
	if auto_decisioni or opzioni.is_empty():
		_risolvi_scelta(s, _scelta_automatica(s))
		return
	if scelta_in_attesa.is_empty():
		scelta_in_attesa = s
	else:
		_scelte_coda.append(s)

## Il giocatore risponde alla scelta in attesa.
func scegli(id: String) -> void:
	if scelta_in_attesa.is_empty():
		return
	var s := scelta_in_attesa
	scelta_in_attesa = {}
	_risolvi_scelta(s, id)
	if scelta_in_attesa.is_empty() and not _scelte_coda.is_empty():
		scelta_in_attesa = _scelte_coda.pop_front()

func _scelta_automatica(s: Dictionary) -> String:
	if s.opzioni.is_empty():
		return ""
	match str(s.tipo):
		"tregua":
			return "si" if figure(EQ).size() <= 2 else "no"
		"vado_a_vedere":
			return "no"
		"doppia_fase", "colto", "esitazione", "tiro_istintivo", "rinforzo_amico":
			var best = s.opzioni[0]
			for o in s.opzioni:
				var u := per_uid(int(o.id)) if str(o.id).is_valid_int() else {}
				var b := per_uid(int(best.id)) if str(best.id).is_valid_int() else {}
				if not u.is_empty() and not b.is_empty() and int(u.combattimento) > int(b.combattimento):
					best = o
			if str(s.tipo) == "esitazione":
				for o in s.opzioni:
					var u := per_uid(int(o.id))
					if not u.is_empty() and u.specie == "feral":
						return str(o.id)
			return str(best.id)
	return str(s.opzioni[0].id)

func _risolvi_scelta(s: Dictionary, id: String) -> void:
	match str(s.tipo):
		"doppia_fase":
			var u := per_uid(int(id))
			if not u.is_empty():
				u.doppia_fase_round = round_n + 1
				scrivi("%s potrà agire sia nelle Azioni Rapide sia nelle Lente nel prossimo round." % u.nome, "evento")
		"esitazione":
			effetti_round[round_n + 1] = effetti_round.get(round_n + 1, {})
			effetti_round[round_n + 1]["unico_rapido"] = int(id)
			var u := per_uid(int(id))
			scrivi("Nel prossimo round agirà rapido solo %s." % u.get("nome", "?"), "evento")
		"tiro_istintivo":
			var u := per_uid(int(id))
			if u.is_empty():
				return
			var arma := str(u.arma)
			for a in armi_tiro(u):
				if "pistola" in Dati.tratti_arma(a):
					arma = a
					break
			var bs := bersagli(u, arma)
			if bs.is_empty():
				scrivi("%s non ha bersagli per il tiro istintivo." % u.nome)
				return
			var v: Dictionary = bs[0].u
			scrivi("Tiro istintivo: %s spara a %s." % [u.nome, v.nome], "tiro")
			if "pistola" in Dati.tratti_arma(arma):
				scrivi("  Con la pistola il colpo va a segno automaticamente.")
				colpisci(u, v, int(arma_eff(u, arma).danno), arma_eff(u, arma).tratti)
			else:
				_risolvi_colpi(u, v, arma, {"colpi": 1, "reazione": true})
		"vado_a_vedere":
			if id == "si":
				var u := per_uid(int(s.dati.get("uid", -1)))
				if not u.is_empty() and u.attiva:
					u.attiva = false
					u.uscito = true
					u["controlla"] = true
					guadagni.bottino += 1
					scrivi("%s va a controllare e sparisce tra le rovine: dopo la battaglia un tiro sul Bottino." % u.nome, "evento")
		"rinforzo_amico":
			for p in riserve:
				if str(p.id) == id:
					var u := figura_da_pg(p)
					u.pos = _libera_vicina(Vector2i(W / 2, H - 1), true)
					u.iniziale = u.pos
					u.fase = "lenta"
					unita.append(u)
					riserve.erase(p)
					scrivi("Rinforzi: %s arriva al centro del vostro bordo." % u.nome, "evento")
					break
		"tregua":
			if id == "si":
				scrivi("Accettate di chiuderla qui: nessuno Tiene il Campo.", "titolo")
				_finisci(false, true)

## Azioni disponibili per u ora: [{id, nome, tipo: movimento|combattimento|gratuita|speciale, bersaglio: cella|figura|nessuno}].
func azioni_disponibili(u: Dictionary) -> Array:
	var r := []
	if u.lato != EQ or not u.attiva or _congelato(u):
		return r
	var puo_combattere: bool = not u.agito and not u.get("no_combattimento", false) and not (int(u.stordito) > 0 and u.mosso)
	var puo_muovere: bool = not u.mosso and not (int(u.stordito) > 0 and u.agito) and int(u.immobile_fino) < round_n
	# mossa bonus dopo una Rissa vinta
	if int(u.mossa_bonus) > 0:
		r.append({"id": "mossa_bonus", "nome": "Avanza di 2\" dopo la Rissa", "tipo": "movimento", "bersaglio": "cella"})
	if puo_muovere:
		r.append({"id": "muovi", "nome": "Muovi", "tipo": "movimento", "bersaglio": "cella"})
		if not u.agito and int(u.stordito) == 0:
			r.append({"id": "scatto", "nome": "Scatta (+2\", poi niente azione di combattimento)", "tipo": "movimento", "bersaglio": "cella"})
		for m in movimenti_alternativi(u):
			r.append({"id": "alt:" + str(m.id), "nome": m.nome, "tipo": "movimento", "bersaglio": "cella"})
	if not caselle_salto(u).is_empty() and (not u.mosso or u.specie == "swift"):
		r.append({"id": "salta", "nome": "Salta giù", "tipo": "gratuita" if u.specie == "swift" else "movimento", "bersaglio": "cella"})
	if puo_combattere and not u.vip:
		for a in armi_tiro(u):
			var e := arma_eff(u, a)
			if not bersagli(u, a).is_empty():
				r.append({"id": "spara:" + a, "nome": "Spara: %s (%d\", %d colpi, danno %+d)" % [e.nome, e.gittata, e.colpi, e.danno], "tipo": "combattimento", "bersaglio": "figura"})
			if not "monouso" in e.tratti and not bersagli(u, a, true).is_empty():
				r.append({"id": "panico:" + a, "nome": "Fuoco nel panico: %s (+2 colpi, metà gittata, poi scarica)" % e.nome, "tipo": "combattimento", "bersaglio": "nessuno"})
		if not adiacenti_nemici(u).is_empty() and not u.scatto and not u.speciali.get("no_rissa_volontaria", false):
			r.append({"id": "rissa", "nome": "Rissa con un avversario a contatto", "tipo": "combattimento", "bersaglio": "figura"})
		if ha(u, "bot_distrazione") and not "bot_distrazione" in u.usati_battaglia:
			r.append({"id": "bot_distrazione", "nome": "Bot di distrazione (un nemico entro 12\" salta la prossima attivazione)", "tipo": "combattimento", "bersaglio": "figura"})
		if ha(u, "insta_muro") and not _usato_missione("insta_muro", u):
			r.append({"id": "insta_muro", "nome": "Insta-muro (muro di forza entro 3\")", "tipo": "combattimento", "bersaglio": "cella"})
		if ha(u, "multitaglio") and not _caselle_varco(u).is_empty():
			r.append({"id": "multitaglio", "nome": "Multitaglio: apri un varco", "tipo": "combattimento", "bersaglio": "cella"})
		if ha(u, "rampino") and not _caselle_rampino(u).is_empty():
			r.append({"id": "rampino", "nome": "Rampino: scala fino a 12\"", "tipo": "combattimento", "bersaglio": "cella"})
		for az in azioni_obiettivo(u):
			if az.id != "esci":
				r.append({"id": "obj:" + str(az.id), "nome": az.nome, "tipo": "combattimento", "bersaglio": "nessuno"})
	# azioni gratuite: la seconda nello stesso round costa l'azione di combattimento
	var gr_ok: bool = int(u.gratuite) == 0 or not u.agito
	if gr_ok:
		for id in u.consumabili:
			if id == "stim" or id in u.monouso_usati:
				continue
			r.append({"id": "usa:" + id, "nome": "Usa: " + Dati.nome_oggetto(id) + (" (azione gratuita)" if int(u.gratuite) == 0 else " (costa l'azione di combattimento)"), "tipo": "gratuita", "bersaglio": "nessuno"})
		if ha(u, "distorsore_temporale") and not _usato_missione("distorsore_temporale", u):
			r.append({"id": "distorsore", "nome": "Distorsore temporale (congela fino a 3 nemici)", "tipo": "gratuita", "bersaglio": "nessuno"})
		if ha(u, "lama_nascosta") and not "lama_nascosta" in u.usati_battaglia and not u.mosso and not u.agito:
			var vicino := false
			for v in avversari(u):
				if dist(u.inizio_round_pos, v.pos) <= 2:
					vicino = true
			if vicino:
				r.append({"id": "lama_nascosta", "nome": "Lancia la lama nascosta (azione gratuita)", "tipo": "gratuita", "bersaglio": "figura"})
		if ha(u, "impianto_muscoli") and not _caselle_issarsi(u).is_empty():
			r.append({"id": "issati", "nome": "Issati su un ostacolo basso (azione gratuita)", "tipo": "gratuita", "bersaglio": "cella"})
	for s in segnalini:
		if s.tipo in ["trovato", "prezioso"] and dist(s.pos, u.pos) <= 1 and not u.agito:
			r.append({"id": "segnalino:%d" % int(s.id), "nome": "Esamina il segnalino (azione non di combattimento)", "tipo": "combattimento", "bersaglio": "nessuno"})
	if u.pos.y == 0 or u.pos.y == H - 1 or u.pos.x == 0 or u.pos.x == W - 1:
		r.append({"id": "esci", "nome": "Esci dal campo di battaglia", "tipo": "speciale", "bersaglio": "nessuno"})
	return r

## Celle valide per un'azione che richiede una casella.
func celle_azione(u: Dictionary, id: String) -> Array:
	if id == "muovi" or id == "scatto":
		return raggiungibili(u, id == "scatto").keys()
	if id == "salta":
		return caselle_salto(u)
	if id == "mossa_bonus":
		return caselle_mossa_bonus(u)
	if id.begins_with("alt:"):
		return caselle_alternative(u, id.substr(4))
	if id == "insta_muro":
		var r := []
		for y in range(-3, 4):
			for x in range(-3, 4):
				var q: Vector2i = u.pos + Vector2i(x, y)
				if q != u.pos and calpestabile(q) and figura_in(q).is_empty() and t_at(q) in [T.APERTO, T.INTERNO, T.CAMPO]:
					r.append(q)
		return r
	if id == "multitaglio":
		return _caselle_varco(u)
	if id == "rampino":
		return _caselle_rampino(u)
	if id == "issati":
		return _caselle_issarsi(u)
	return []

## Figure bersaglio valide per un'azione.
func figure_azione(u: Dictionary, id: String) -> Array:
	if id.begins_with("spara:"):
		return bersagli(u, id.substr(6)).map(func(x): return x.u)
	if id == "rissa":
		return adiacenti_nemici(u)
	if id == "bot_distrazione":
		return figure(NEM).filter(func(v): return dist(u.pos, v.pos) <= 12)
	if id == "lama_nascosta":
		return avversari(u).filter(func(v): return dist(u.pos, v.pos) <= 2 and vede(u, v))
	return []

func _caselle_varco(u: Dictionary) -> Array:
	var r := []
	for d in _dir8():
		var q: Vector2i = u.pos + d
		if dentro(q) and t_at(q) in [T.MURO, T.LINEARE, T.FINESTRA]:
			r.append(q)
	return r

func _caselle_rampino(u: Dictionary) -> Array:
	var r := []
	for d in _dir8():
		var q: Vector2i = u.pos + d
		if t_at(q) == T.BLOCCO and a_at(q) - a_at(u.pos) >= 1 and a_at(q) <= 12 and figura_in(q).is_empty():
			r.append(q)
	return r

func _caselle_issarsi(u: Dictionary) -> Array:
	var r := []
	for d in _dir8():
		var q: Vector2i = u.pos + d
		if t_at(q) == T.BLOCCO and a_at(q) - a_at(u.pos) == 1 and figura_in(q).is_empty():
			r.append(q)
	return r

func _usa_gratuita(u: Dictionary) -> void:
	u.gratuite = int(u.gratuite) + 1
	if int(u.gratuite) >= 2:
		u.agito = true

## Esegue un'azione dell'equipaggio. param: Vector2i (cella), int (uid) o null.
func esegui(u: Dictionary, id: String, param = null) -> bool:
	if not u.attiva:
		return false
	if id == "muovi" or id == "scatto":
		return muovi(u, param, id == "scatto")
	if id == "salta":
		var ok := salta_giu(u, param)
		if ok and u.specie != "swift":
			u.mosso = true
		return ok
	if id == "mossa_bonus":
		return mossa_bonus(u, param)
	if id.begins_with("alt:"):
		return movimento_alternativo(u, id.substr(4), param)
	if id.begins_with("spara:"):
		return spara(u, per_uid(int(param)), id.substr(6))
	if id.begins_with("panico:"):
		var a := id.substr(7)
		var bs := bersagli(u, a, true)
		if bs.is_empty():
			return false
		return spara(u, bs[0].u, a, false, true)
	if id == "rissa":
		return rissa(u, per_uid(int(param)))
	if id.begins_with("obj:"):
		azione(u, id.substr(4))
		return true
	if id == "esci":
		azione(u, "esci")
		return true
	if id.begins_with("usa:"):
		return _usa_consumabile(u, id.substr(4))
	if id.begins_with("segnalino:"):
		return _esamina_segnalino(u, int(id.split(":")[1]))
	match id:
		"bot_distrazione":
			var v := per_uid(int(param))
			if v.is_empty():
				return false
			v.salta_attivazione = true
			u.usati_battaglia.append("bot_distrazione")
			u.agito = true
			scrivi("%s lancia il bot di distrazione: %s perderà la prossima attivazione." % [u.nome, v.nome])
			return true
		"insta_muro":
			var q: Vector2i = param
			var d := Vector2i(signi(q.x - u.pos.x), signi(q.y - u.pos.y))
			var perp := Vector2i(-d.y, d.x) if d != Vector2i.ZERO else Vector2i(1, 0)
			var cl := [q]
			if calpestabile(q + perp) and figura_in(q + perp).is_empty():
				cl.append(q + perp)
			var e := _nuovo_elemento("Muro di forza", T.MURO_FORZA, cl)
			e["muro_forza"] = true
			_segna_uso(u, "insta_muro")
			u.agito = true
			scrivi("%s attiva l'insta-muro: un muro di forza blocca i colpi." % u.nome)
			return true
		"multitaglio":
			var q: Vector2i = param
			set_t(q, T.PORTA)
			porte_aperte[q] = true
			u.agito = true
			scrivi("%s apre un varco con il multitaglio." % u.nome)
			return true
		"rampino":
			_sposta(u, param)
			u.agito = true
			scrivi("%s si arrampica con il rampino." % u.nome)
			return true
		"issati":
			_sposta(u, param)
			_usa_gratuita(u)
			scrivi("%s si issa sull'ostacolo." % u.nome)
			return true
		"distorsore":
			var nem := figure(NEM)
			nem.sort_custom(func(a, b): return dist(a.pos, u.pos) < dist(b.pos, u.pos))
			var scelti: Array = param if param is Array else nem.slice(0, 3).map(func(x): return x.uid)
			for uid in scelti.slice(0, 3):
				var v := per_uid(int(uid))
				if not v.is_empty():
					v.congelato_fino = round_n + 1
			_segna_uso(u, "distorsore_temporale")
			_usa_gratuita(u)
			scrivi("%s attiva il distorsore temporale: %d nemici congelati fino alla fine del prossimo round." % [u.nome, min(3, scelti.size())], "evento")
			return true
		"lama_nascosta":
			var v := per_uid(int(param))
			if v.is_empty():
				return false
			u.usati_battaglia.append("lama_nascosta")
			_usa_gratuita(u)
			var l := lds(u.pos, v.pos, false, u, v)
			var soglia := 5 if l.copertura else 3
			var t := dadi.d6()
			scrivi("%s lancia la lama nascosta a %s: %d%+d (serve %d+)." % [u.nome, v.nome, t, int(u.combattimento), soglia], "tiro")
			if t + int(u.combattimento) >= soglia:
				colpisci(u, v, 0, [])
			return true
	return false

func _usa_consumabile(u: Dictionary, id: String) -> bool:
	if not id in u.consumabili or id in u.monouso_usati:
		return false
	u.monouso_usati.append(id)
	_segna_uso(u, id)
	_usa_gratuita(u)
	var e: Dictionary = Dati.oggetto(id).get("effetto", {})
	scrivi("%s usa %s." % [u.nome, Dati.nome_oggetto(id)])
	match str(e.get("consumabile", id)):
		"booster":
			u.stordito = 0
			u.doppia_vel = true
		"siero":
			for k in e.get("bonus_battaglia", {}):
				u.bonus_battaglia[k] = int(u.bonus_battaglia.get(k, 0)) + int(e.bonus_battaglia[k])
		"furia":
			if u.specie == "kerin":
				for k in e.get("bonus_round", {}):
					u.bonus_battaglia[k] = int(u.bonus_battaglia.get(k, 0)) + int(e.bonus_round[k])
			else:
				u.bonus_round = e.get("bonus_round", {}).duplicate()
				u.bonus_fino = round_n + 1
		"still":
			u.bonus_round = e.get("bonus_round", {}).duplicate()
			u.bonus_fino = round_n + 1
			u.immobile_fino = round_n + 1
		"kiranin":
			for w in unita:
				if w.attiva and w.uid != u.uid and dist(w.pos, u.pos) <= 4 and not w.attivato:
					_stordisci(w, 1)
					w.salta_attivazione = true
					scrivi("  %s è ipnotizzato dalle luci e non agirà in questo round." % w.nome)
	return true

func _esamina_segnalino(u: Dictionary, sid: int) -> bool:
	for s in segnalini:
		if int(s.id) == sid:
			segnalini.erase(s)
			u.agito = true
			if s.tipo == "trovato":
				guadagni.bottino += 1
				scrivi("%s trova qualcosa: un tiro sul Bottino dopo la battaglia." % u.nome, "obiettivo")
			else:
				var c := dadi.d(3)
				guadagni.crediti += c
				scrivi("%s trova qualcosa di valore: %d crediti." % [u.nome, c], "obiettivo")
			return true
	return false

## ===================== azioni di obiettivo =====================

func azioni_obiettivo(u: Dictionary) -> Array:
	var r := []
	if u.lato != EQ or u.agito or not u.attiva:
		return r
	if (u.pos.y == 0 or u.pos.y == H - 1 or u.pos.x == 0 or u.pos.x == W - 1):
		r.append({"id": "esci", "nome": "Esci dal campo"})
	if stato_obj.get("fatto", false) or stato_obj.get("fallito", false):
		return r
	match obiettivo:
		"consegnare":
			if u.porta == "pacco" and dist(u.pos, centro) <= 1:
				r.append({"id": "consegna", "nome": "Consegna il pacco"})
		"accedere":
			var dmax := 6 if u.specie == "soulless" else 1
			if dist(u.pos, centro) <= dmax and int(stato_obj.get("tentativi_round", 0)) < 2:
				r.append({"id": "accedi", "nome": "Tenta l'accesso alla console"})
		"acquisire":
			if stato_obj.has("oggetto_a") and dist(u.pos, stato_obj.oggetto_a) <= 1:
				r.append({"id": "prendi", "nome": "Prendi l'oggetto"})
		"perquisire":
			for sg in stato_obj.get("segnalini", []):
				if not sg.fatto:
					for e in elementi:
						if e.id == sg.id:
							for c in e.celle:
								if dist(c, u.pos) <= 1:
									r.append({"id": "perquisisci:%d" % sg.id, "nome": "Perquisisci: " + sg.nome})
									break
	if stato_obj.has("caduto") and dist(u.pos, stato_obj.caduto.pos) <= 1:
		r.append({"id": "raccogli", "nome": "Raccogli il " + str(stato_obj.caduto.cosa)})
	if stato_obj.has("luogo_pos") and not stato_obj.get("luogo_preso", false) and dist(u.pos, stato_obj.luogo_pos) <= 1:
		r.append({"id": "luogo", "nome": "Esamina: " + str(setup.get("luogo", {}).get("nome", "luogo notevole"))})
	var visti := {}
	var out := []
	for a in r:
		if not visti.has(a.id):
			visti[a.id] = true
			out.append(a)
	return out

func azione(u: Dictionary, id: String) -> void:
	if u.agito and id != "esci":
		return
	if id == "esci":
		u.attiva = false
		u.uscito = true
		u.uscito_round = round_n
		eventi.append({"tipo": "esce", "uid": u.uid})
		if obiettivo == "invasione" and round_n < 6:
			u.fuori = true
			scrivi("%s lascia il campo prima del sesto round: conta come una perdita." % u.nome, "perdita")
		else:
			scrivi("%s esce dal campo di battaglia." % u.nome)
		if u.pos.y == 0:
			stato_obj["uscite_nemico"] = int(stato_obj.get("uscite_nemico", 0)) + 1
			if obiettivo == "attraversare" and int(stato_obj.uscite_nemico) >= 2:
				_obiettivo_fatto()
		if obiettivo == "acquisire" and u.porta == "oggetto":
			_obiettivo_fatto()
		_controlla_fine()
		return
	u.agito = true
	if id == "consegna":
		u.porta = ""
		scrivi("%s consegna il pacco al centro." % u.nome, "obiettivo")
		_obiettivo_fatto()
	elif id == "accedi":
		stato_obj["tentativi_round"] = int(stato_obj.get("tentativi_round", 0)) + 1
		var t := dadi.d6()
		if ha(u, "compagno_ia"):
			t = max(t, dadi.d6())
		var b := int(u.get("acume", 0)) + (1 if u.specie in ["engineer", "bot", "bot_assalto"] else 0)
		scrivi("%s tenta l'accesso: %d%+d (serve 6+)." % [u.nome, t, b], "obiettivo")
		if t == 1 and u.specie != "engineer":
			stato_obj["uno_naturale"] = int(stato_obj.uno_naturale) + 1
			if int(stato_obj.uno_naturale) >= 2:
				scrivi("Il sistema si blocca: l'accesso è impossibile.", "pericolo")
				stato_obj["fallito"] = true
			else:
				scrivi("Il sistema si protegge: un altro 1 naturale lo bloccherà.")
		elif t + b >= 6:
			_obiettivo_fatto()
	elif id == "prendi":
		u.porta = "oggetto"
		stato_obj.erase("oggetto_a")
		scrivi("%s prende l'oggetto: ora deve uscire dal campo." % u.nome, "obiettivo")
	elif id == "raccogli":
		u.porta = str(stato_obj.caduto.cosa)
		stato_obj.erase("caduto")
		scrivi("%s raccoglie il %s." % [u.nome, u.porta])
	elif id.begins_with("perquisisci:"):
		var eid := int(id.split(":")[1])
		var resta := false
		for sg in stato_obj.get("segnalini", []):
			if sg.id == eid:
				sg.fatto = true
				var t := dadi.d6()
				scrivi("%s perquisisce %s: %d (serve 5+)." % [u.nome, sg.nome, t], "obiettivo")
				if t >= 5:
					_obiettivo_fatto()
		for sg in stato_obj.get("segnalini", []):
			if not sg.fatto:
				resta = true
		if not resta and not stato_obj.fatto:
			stato_obj["fallito"] = true
			scrivi("L'oggetto cercato non è sul campo di battaglia.", "pericolo")
	elif id == "luogo":
		stato_obj["luogo_preso"] = true
		var l: Dictionary = setup.get("luogo", {})
		scrivi("%s esamina %s: %s" % [u.nome, l.get("nome", ""), l.get("testo", "")], "obiettivo")
		stato_obj["luogo_preso_da"] = u.pg

func _obiettivo_fatto() -> void:
	if not stato_obj.get("fatto", false):
		stato_obj["fatto"] = true
		scrivi("OBIETTIVO RAGGIUNTO!", "obiettivo")

## ===================== round (p.112-114) =====================

## Prendere l'iniziativa (p.112): 2D6 + Acume più alto + modificatori. Restituisce il totale (10+ = riuscita).
func tira_iniziativa() -> int:
	var n := Dati.nemico(str(setup.get("nemico", "")))
	var sp: Dictionary = n.get("speciali", {})
	var bot_spia := ""
	for u in figure(EQ):
		if ha(u, "bot_spia"):
			bot_spia = u.nome
	var annullata: bool = par_obiettivo.get("niente_iniziativa", false) or sp.get("niente_iniziativa", false)
	if annullata and bot_spia == "":
		scrivi("Non potete prendere l'iniziativa%s." % (" (imboscata)" if par_obiettivo.get("niente_iniziativa", false) else " (preveggenza dei Precursori)"))
		return 0
	var t := dadi.tira("2d6")
	var acume := -9
	var ferale := false
	var bonus_eq := 0
	var oggetti_visti := {}
	for u in figure(EQ):
		acume = max(acume, int(u.get("acume", 0)))
		if u.specie == "feral":
			ferale = true
		for id in ["motion_tracker", "scanner_bot"]:
			if ha(u, id) and not oggetti_visti.has(id):
				oggetti_visti[id] = true
				bonus_eq += 1
	var mod := acume + bonus_eq
	var mn := int(sp.get("iniziativa_giocatore", 0))
	if str(n.get("categoria", "")) == "forza_mercenaria":
		mn -= 1
	if figure(NEM).size() > figure(EQ).size():
		mod += 1
	var diff := str(setup.get("difficolta", ""))
	var md := -2 if diff == "hardcore" else (-3 if diff == "follia" else 0)
	if (ferale or bot_spia != "") and mn < 0:
		mn = 0
	if bot_spia != "" and (md < 0 or annullata):
		scrivi("Il bot spia di %s annulla la penalità all'iniziativa." % bot_spia)
		md = 0
		if dadi.d6() == 1:
			guadagni.note.append("Il bot spia è stato danneggiato.")
			guadagni["danneggiati"] = guadagni.get("danneggiati", []) + [["", "bot_spia"]]
	mod += mn + md
	if sp.get("iniziativa_non_modificata", false):
		mod = 0
	var tot := t + mod
	scrivi("Prendere l'iniziativa: %d%+d = %d (serve 10+)%s" % [t, mod, tot, ": riuscita! Ogni membro può muovere o sparare (colpisce solo con 6)." if tot >= 10 else "."], "titolo")
	return tot

## Inizio di un round: effetti a inizio round e tiro delle reazioni (i dadi si assegnano poi con assegna_dadi).
func inizia_round() -> void:
	round_n += 1
	perdite_round = 0
	morale_extra = 0
	stato_obj["tentativi_round"] = 0
	eventi = []
	for u in unita:
		u.mosso = false
		u.agito = false
		u.attivato = false
		u.scatto = false
		u.gratuite = 0
		u.attesa = ""
		u.no_fuoco = false
		u.doppia_vel = false
		u.mossa_bonus = 0
		u.tele_raggio = 0
		u.erase("no_combattimento")
		u["pistole_sparate"] = []
		u.inizio_round_pos = u.pos
	# muri di forza: con 6 svaniscono
	for e in elementi.duplicate():
		if e.get("muro_forza", false) and dadi.d6() == 6:
			for c in e.celle:
				set_t(c, T.APERTO)
			elementi.erase(e)
			scrivi("Il muro di forza svanisce.")
	if cond.get("visibilita_ritira_ogni_round", false) and round_n > 1:
		visibilita = dadi.tira(cond.visibilita)
		scrivi("La visibilità cambia: %d\"." % visibilita)
	var er: Dictionary = effetti_round.get(round_n, {})
	if er.has("salta_membro"):
		var u := per_uid(int(er.salta_membro))
		if not u.is_empty():
			u.salta_round = round_n
	# tiro delle reazioni
	var eq := figure(EQ)
	var n_dadi := eq.size()
	var extra := 0
	for u in eq:
		if ha(u, "comunicatore"):
			extra = 1
	dadi_reazione = []
	for i in n_dadi + extra:
		dadi_reazione.append(dadi.d6())
	dadi_reazione.sort()
	if extra > 0 and dadi_reazione.size() > n_dadi:
		var scartato = dadi_reazione.pop_back()
		scrivi("Comunicatore: si tira un dado in più e si scarta il %d." % scartato)
	for u in eq:
		u.dado_reazione = 0
	fase = "reazioni"
	if er.get("scelta_libera", false):
		scrivi("ROUND %d - Piano astuto: scegliete voi chi agisce rapido e chi lento." % round_n, "titolo")
		dadi_reazione = []
	else:
		scrivi("ROUND %d - Tiro delle reazioni: %s." % [round_n, ", ".join(dadi_reazione.map(func(x): return str(x)))], "titolo")
	auto_assegna()

## Assegnazione automatica (consigliata) dei dadi delle reazioni: più figure possibile nella fase rapida.
func auto_assegna() -> void:
	var eq := figure(EQ)
	if dadi_reazione.is_empty():
		for u in eq:
			u.fase = "rapida"
		return
	var dd: Array = dadi_reazione.duplicate()
	var liberi := eq.duplicate()
	liberi.sort_custom(func(a, b): return stat(a, "reazioni") < stat(b, "reazioni"))
	var assegnati := {}
	if dd.count(1) == 1:
		for u in liberi:
			if u.specie == "feral":
				assegnati[u.uid] = 1
				liberi.erase(u)
				dd.erase(1)
				break
	for d in dd.duplicate():
		for u in liberi:
			if d <= stat(u, "reazioni"):
				assegnati[u.uid] = d
				liberi.erase(u)
				dd.erase(d)
				break
	for u in liberi:
		assegnati[u.uid] = dd.pop_front() if not dd.is_empty() else 6
	for u in eq:
		u.dado_reazione = assegnati.get(u.uid, 6)
	_fasi_dai_dadi()

## Assegnazione scelta dal giocatore: {uid: dado}. Restituisce "" se valida, altrimenti il motivo.
func assegna_dadi(mappa: Dictionary) -> String:
	var eq := figure(EQ)
	var usati: Array = []
	for u in eq:
		if not mappa.has(u.uid):
			return "Ogni personaggio deve ricevere un dado."
		usati.append(int(mappa[u.uid]))
	var a: Array = usati.duplicate()
	a.sort()
	var b: Array = dadi_reazione.duplicate()
	b.sort()
	if a != b:
		return "I dadi assegnati non corrispondono a quelli tirati."
	if dadi_reazione.count(1) == 1:
		var ferali := eq.filter(func(x): return x.specie == "feral")
		if not ferali.is_empty():
			var ok := false
			for f in ferali:
				if int(mappa[f.uid]) == 1:
					ok = true
			if not ok:
				return "C'è un solo 1: va assegnato a un Feral (impetuosità)."
	for u in eq:
		u.dado_reazione = int(mappa[u.uid])
	_fasi_dai_dadi()
	return ""

## Con «Piano astuto» il giocatore sceglie direttamente la fase.
func imposta_fase(u: Dictionary, f: String) -> void:
	if fase == "reazioni" and f in ["rapida", "lenta"]:
		u.fase = f

func _fasi_dai_dadi() -> void:
	var er: Dictionary = effetti_round.get(round_n, {})
	for u in figure(EQ):
		u.fase = "rapida" if int(u.dado_reazione) <= stat(u, "reazioni") else "lenta"
		if round_n == 1 and int(cond.get("tutti_lenti_round", 0)) >= 1:
			u.fase = "lenta"
		if er.has("unico_rapido"):
			u.fase = "rapida" if int(er.unico_rapido) == u.uid else "lenta"

## Conferma le reazioni e apre la fase rapida (dopo gli eventuali nemici che agiscono prima).
func conferma_reazioni() -> void:
	if fase != "reazioni":
		return
	var rapidi := []
	var lenti := []
	for u in figure(EQ):
		if int(u.doppia_fase_round) == round_n:
			u.fase = "rapida"
		(rapidi if u.fase == "rapida" else lenti).append(u.nome)
	scrivi("Rapidi: %s. Lenti: %s." % [", ".join(rapidi) if not rapidi.is_empty() else "nessuno", ", ".join(lenti) if not lenti.is_empty() else "nessuno"])
	# «Uno col Flusso»: agisce prima della fase rapida
	for u in figure(NEM):
		if u.speciali.get("agisce_prima_azioni_rapide", false) and not _nemici_bloccati():
			scrivi("%s si muove prima di tutti." % u.nome)
			attiva_nemico(u)
			u.attivato = false
			u["agito_prima"] = true
	fase = "rapida"
	if da_attivare().is_empty():
		avanza_fase()

## Figure dell'equipaggio che possono ancora agire nella fase corrente.
func da_attivare() -> Array:
	var r := []
	if fase != "rapida" and fase != "lenta":
		return r
	for u in figure(EQ):
		if u.attivato or int(u.salta_round) == round_n or _congelato(u):
			continue
		if u.fase == fase or (int(u.doppia_fase_round) == round_n and fase in ["rapida", "lenta"]):
			r.append(u)
	return r

## Attesa nella fase rapida (p.113): «snap» = Snap Fire sul primo nemico che si muove in vista, «lenta» = rimanda.
func attendi(u: Dictionary, modo: String) -> void:
	if fase != "rapida" or u.mosso or u.agito:
		return
	u.attesa = modo
	u.fase = "lenta"
	u.attivato = true
	scrivi("%s %s." % [u.nome, "resta in attesa con l'arma puntata (Snap Fire)" if modo == "snap" else "rimanda l'azione alla fase lenta"])

## Fine dell'attivazione di una figura: toglie un segnalino Stordito, segna se è rimasta ferma.
func fine_attivazione(u: Dictionary) -> void:
	u.attivato = true
	u.fermo_ultima = not u.mosso
	if u.salta_attivazione and not u.mosso and not u.agito:
		u.salta_attivazione = false
	if int(u.stordito) > 0 and u.attiva:
		u.stordito -= 1
	if int(u.doppia_fase_round) == round_n and fase == "rapida":
		# agirà anche nella fase lenta
		u.attivato = false
		u.mosso = false
		u.agito = false
		u.fase = "lenta"
		u.doppia_fase_round = 0

## Passa alla fase successiva.
func avanza_fase() -> void:
	if fase == "reazioni":
		conferma_reazioni()
		return
	if fase == "rapida":
		for u in da_attivare():
			fine_attivazione(u)
		# chi aspettava torna disponibile per la fase lenta
		for u in figure(EQ):
			if u.attesa != "" and not u.agito:
				u.attivato = false
		fase = "nemici"
		_inizio_fase_nemici()
	elif fase == "nemici":
		_risolvi_risse_in_attesa()
		_sforzi_rinnovati()
		for u in figure(EQ):
			if u.attesa == "snap":
				u.attesa = ""
				if not u.agito:
					u.attivato = false
		fase = "lenta"
		if da_attivare().is_empty():
			avanza_fase()
	elif fase == "lenta":
		for u in da_attivare():
			fine_attivazione(u)
		fase = "fine"
		fine_round()

func _nemici_bloccati() -> bool:
	return round_n == 1 and int(cond.get("nemico_salta_round", 0)) >= 1

## Inizio della fase nemica: possibili rinforzi e bestiacce.
func _inizio_fase_nemici() -> void:
	var rinf := segnalini.filter(func(s): return s.tipo == "rinforzi")
	if not rinf.is_empty() and effetti_battaglia.get("rinforzi_da", 999) <= round_n:
		var s: Dictionary = dadi.scegli(rinf)
		var t := dadi.d6()
		if t >= 5:
			var nuovi := aggiungi_nemici(str(setup.get("nemico", "")), 1, [], false, 0, true)
			for nn in nuovi:
				nn.pos = _libera_vicina(s.pos, true)
			scrivi("Dal punto di arrivo dei rinforzi (%d) compare un nuovo nemico!" % t, "pericolo")
		else:
			scrivi("Il punto di arrivo dei rinforzi resta vuoto (%d)." % t)
		segnalini.erase(s)
	for m in figure(MOSTRI):
		_mostro_agisce(m)

## Gli Striscianti dell'evento «Bestiacce!» si muovono verso la figura più vicina e la attaccano.
func _mostro_agisce(m: Dictionary) -> void:
	if not m.attiva:
		return
	m.agito = false
	m.mosso = false
	var avv := avversari(m)
	if avv.is_empty():
		return
	var v: Dictionary = avv[0]
	for w in avv:
		if dist(w.pos, m.pos) < dist(v.pos, m.pos):
			v = w
	var r := raggiungibili(m, false)
	var best: Vector2i = m.pos
	for p in r:
		if dist(p, v.pos) < dist(best, v.pos):
			best = p
	if best != m.pos:
		muovi(m, best, false, false)
	if dist(m.pos, v.pos) == 1 and v.attiva:
		m.agito = false
		rissa(m, v)

## «Sforzi rinnovati»: dopo la fase nemica una figura nemica casuale agisce di nuovo.
func _sforzi_rinnovati() -> void:
	if not effetti_battaglia.get("sforzi", false) or _nemici_bloccati():
		return
	var nem := figure(NEM)
	if nem.is_empty():
		return
	var u: Dictionary = dadi.scegli(nem)
	scrivi("Sforzi rinnovati: %s agisce di nuovo." % u.nome, "evento")
	u.attivato = false
	u.mosso = false
	u.agito = false
	attiva_nemico(u)

## Ordine dei nemici (p.113): dai più vicini al bordo del giocatore, da sinistra.
func ordine_nemici() -> Array:
	var n := figure(NEM)
	n.sort_custom(func(a, b): return a.pos.y > b.pos.y or (a.pos.y == b.pos.y and a.pos.x < b.pos.x))
	return n

## Esegue l'attivazione di un nemico con l'IA.
func attiva_nemico(u: Dictionary) -> void:
	if not u.attiva or u.attivato or _congelato(u):
		return
	if _nemici_bloccati():
		u.attivato = true
		return
	if u.get("agito_prima", false):
		u.erase("agito_prima")
		u.attivato = true
		return
	if u.salta_attivazione:
		u.salta_attivazione = false
		scrivi("%s è distratto e non agisce." % u.nome)
		fine_attivazione(u)
		return
	ia_script.agisci(self, u)
	if u.speciali.get("due_bersagli", false) and u.attiva:
		# IA di puntamento: un secondo colpo al secondo bersaglio visibile più vicino
		var bs := bersagli(u)
		bs = bs.filter(func(x): return int(x.u.uid) != int(u.ultimo_bersaglio))
		if not bs.is_empty():
			u.agito = false
			spara(u, bs[0].u)
	fine_attivazione(u)

func esegui_fase_nemici() -> void:
	if fase != "nemici":
		return
	if _nemici_bloccati():
		scrivi("Il nemico, colto di sorpresa, non agisce in questo round.")
	for u in ordine_nemici():
		attiva_nemico(u)
		if _controlla_fine():
			return
	avanza_fase()

## ===================== fine del round =====================

func fine_round() -> void:
	_morale()
	_controlla_obiettivi_fine_round()
	# eventi della battaglia (fine dei round 2 e 4)
	if eventi_battaglia and round_n in [2, 4]:
		var tab: Dictionary = Dati.f("incontri").get("eventi_battaglia", {})
		if not tab.is_empty():
			var r := dadi.su_tabella(tab)
			scrivi("Evento della battaglia (%d): %s - %s" % [r.tiro, r.riga.get("nome", ""), r.riga.get("testo", "")], "evento")
			ultimo_evento = r.riga
			_applica_evento(r.riga)
	# il nemico «scoraggiato» se ne va
	if effetti_round.get(round_n, {}).get("nemico_si_ritira", false):
		scrivi("Il nemico, scoraggiato, lascia il campo.", "titolo")
		for u in figure(NEM):
			u.attiva = false
			u.fuggito = true
	# spia e cane: fuggono se restano soli
	var nem := figure(NEM)
	var soli := nem.filter(func(x): return x.speciali.get("fugge_se_solo", false))
	if not nem.is_empty() and soli.size() == nem.size() and perdite_totali > 0:
		for u in soli:
			u.attiva = false
			u.fuggito = true
			scrivi("%s, rimasto solo, fugge." % u.nome, "perdita")
	# resa del nemico dopo l'obiettivo
	if stato_obj.get("fatto", false) and not figure(NEM).is_empty():
		var ia := str(figure(NEM)[0].ia)
		if not ia in ["furia", "bestia"]:
			var n := 2 if ia in ["cauto", "difensivo", "tattico"] else 1
			var uno := false
			for i in n:
				if dadi.d6() == 1:
					uno = true
			if uno:
				scrivi("Raggiunto l'obiettivo, il nemico si ritira!", "titolo")
				for u in figure(NEM):
					u.attiva = false
					u.fuggito = true
	# arrivi in ritardo
	if not ritardati.is_empty() and dadi.d6() <= round_n:
		for p in ritardati:
			var u := figura_da_pg(p)
			u.pos = _libera_vicina(Vector2i(W / 2 + dadi.d(7) - 4, H - 1), true)
			u.iniziale = u.pos
			unita.append(u)
			scrivi("%s arriva finalmente sul campo." % u.nome, "evento")
		ritardati = []
	if _controlla_fine():
		return
	# fine improvvisa: scontro breve e tempo che scade
	if cond.has("fine_se_tiro_max_round"):
		var t := dadi.tira(cond.fine_se_tiro_max_round)
		if t <= round_n:
			scrivi("Scontro breve: %d, la battaglia finisce senza esito." % t, "titolo")
			_finisci(false, true)
			return
	if effetti_battaglia.get("tempo_da", 999) <= round_n:
		if dadi.d6() == 6:
			scrivi("Il tempo è scaduto: la partita finisce subito.", "titolo")
			_finisci(false, true)
			return
	# tregua dei Mercenari sconosciuti
	var tr := int(Dati.nemico(str(setup.get("nemico", ""))).get("speciali", {}).get("tregua_se_figure_max", 0))
	if tr > 0 and figure(NEM).size() <= tr and fase != "finita":
		_chiedi("tregua", "I mercenari, ridotti a %d, propongono di chiuderla qui (nessuno Tiene il Campo). Accettate?" % figure(NEM).size(),
			[{"id": "si", "nome": "Accetta la tregua"}, {"id": "no", "nome": "Continua a combattere"}])
	if fase != "finita":
		fase = "fine"

## Morale nemico (p.114).
func _morale() -> void:
	var nem := figure(NEM)
	if nem.is_empty():
		return
	var n_dadi := perdite_round + morale_extra
	var sp: Dictionary = Dati.nemico(str(setup.get("nemico", ""))).get("speciali", {})
	if sp.get("ignora_prima_perdita", false) and perdite_round > 0 and not stato_obj.get("prima_perdita_ignorata", false):
		stato_obj["prima_perdita_ignorata"] = true
		n_dadi -= 1
		scrivi("Testardi: il nemico ignora la prima perdita nel test di Morale.")
	if n_dadi <= 0:
		return
	var p: Array = []
	for u in nem:
		if not u.panico.is_empty():
			p = u.panico.duplicate()
			break
	if p.size() != 2:
		scrivi("Il nemico non conosce la paura.")
		return
	var lo := int(p[0])
	var hi := int(p[1])
	for u in nem:
		hi += int(u.speciali.get("panico_gruppo_mod", 0))
	hi -= int(cond.get("morale_nemico", 0))
	var ostinati := int(sp.get("impavidi_se_figure_max", 0)) > 0 and nem.size() <= int(sp.get("impavidi_se_figure_max", 0))
	var fuggono := 0
	var tiri := []
	for i in n_dadi:
		var t := dadi.d6()
		tiri.append(t)
		if hi >= lo and t >= lo and t <= hi:
			fuggono += 1
	scrivi("Morale nemico: %s (panico %s): %d fuggono." % [str(tiri), ("%d-%d" % [lo, hi]) if hi >= lo else "nessuno", fuggono])
	if ostinati:
		if fuggono > 0:
			scrivi("Ridotti a pochi, diventano ostinati e non fuggono.")
		return
	var cand := nem.filter(func(x): return not x.impavido and not _congelato(x))
	cand.sort_custom(func(a, b): return a.pos.y < b.pos.y)
	for i in min(fuggono, cand.size()):
		var u: Dictionary = cand[i]
		if u.get("bersaglio", false) and obiettivo == "eliminare":
			u["bloccato"] = true
			u.immobile_fino = round_n + 1
			scrivi("%s vorrebbe fuggire, ma resta bloccato per un round." % u.nome)
			continue
		u.attiva = false
		u.fuggito = true
		eventi.append({"tipo": "fugge", "uid": u.uid})
		scrivi("%s fugge dal campo." % u.nome, "perdita")

func _controlla_obiettivi_fine_round() -> void:
	if obiettivo == "assicurare" and not stato_obj.fatto:
		var ok := false
		for u in figure(EQ):
			if dist(u.pos, centro) <= 2:
				var lontani := true
				for v in figure(NEM):
					if dist(u.pos, v.pos) <= 6:
						lontani = false
				if lontani:
					ok = true
		stato_obj["consecutivi"] = int(stato_obj.consecutivi) + 1 if ok else 0
		if ok:
			scrivi("Il centro è sotto controllo (%d/2 round)." % stato_obj.consecutivi)
		if int(stato_obj.consecutivi) >= 2:
			_obiettivo_fatto()
	if obiettivo == "proteggere" and not stato_obj.fatto:
		for u in figure(EQ):
			if u.vip:
				if dist(u.pos, centro) <= 3:
					stato_obj["consecutivi"] = int(stato_obj.consecutivi) + 1
					if int(stato_obj.consecutivi) >= 2:
						_obiettivo_fatto()
						stato_obj["entro_4"] = round_n <= 5
				else:
					stato_obj["consecutivi"] = 0
	if obiettivo == "eliminare":
		for u in figure(NEM):
			if u.get("bloccato", false):
				u["bloccato_round"] = int(u.get("bloccato_round", 0)) + 1
				if int(u.bloccato_round) >= 2:
					u.attiva = false
					u.fuggito = true
					stato_obj["fallito"] = true
					scrivi("Il bersaglio %s riesce a fuggire: missione fallita." % u.nome, "pericolo")

## ===================== eventi della battaglia (p.116-117) =====================

func _eq_casuale() -> Dictionary:
	var eq := figure(EQ).filter(func(x): return not x.vip)
	return dadi.scegli(eq) if not eq.is_empty() else {}

func _opzioni_eq() -> Array:
	return figure(EQ).filter(func(x): return not x.vip).map(func(x): return {"id": str(x.uid), "nome": str(x.nome)})

func _applica_evento(r: Dictionary) -> void:
	var prossimo := round_n + 1
	if not effetti_round.has(prossimo):
		effetti_round[prossimo] = {}
	match str(r.get("id", "")):
		"sforzi_rinnovati":
			effetti_battaglia["sforzi"] = true
		"rinforzi_nemici":
			var nuovi := aggiungi_nemici(str(setup.get("nemico", "")), 2, [], false, 1, true)
			for i in nuovi.size():
				nuovi[i].pos = _libera_vicina(Vector2i(W / 2 + i, 0), true)
			scrivi("Arrivano 2 nemici al centro del loro bordo.", "pericolo")
		"cambio_piani":
			for u in figure(NEM):
				if str(u.arma) == "":
					continue
				u.ia = "tattico" if str(u.ia) == "cauto" else "cauto"
			scrivi("Il nemico cambia tattica.")
		"scoraggiati":
			effetti_round[prossimo]["nemico_si_ritira"] = true
		"colto_il_momento":
			_chiedi("doppia_fase", "Colto il momento: chi agirà sia nelle Azioni Rapide sia nelle Lente nel prossimo round?", _opzioni_eq())
		"bestiacce":
			var n := dadi.d(3)
			var bestie := aggiungi_nemici("striscianti_condotti", n, [], false, 0, true)
			var gia: bool = str(setup.get("nemico", "")) == "striscianti_condotti"
			for m in bestie:
				m.pos = _libera_vicina(centro, true)
				_movimento_casuale(m, dadi.d6(), false)
				if not gia:
					m.lato = MOSTRI
					m.impavido = true
			scrivi("%d Striscianti dei condotti sbucano al centro del campo%s!" % [n, "" if gia else ", ostili a tutti"], "pericolo")
		"guasto_munizioni":
			var u := _eq_casuale()
			if not u.is_empty():
				if int(u.sparato_round) >= round_n - 1 and int(u.sparato_round) > 0 and str(u.arma) != "":
					u.guasti[str(u.arma)] = "rotta"
					scrivi("Guasto: l'arma di %s non funziona più." % u.nome, "pericolo")
				elif not u.armi.is_empty():
					var a := str(dadi.scegli(u.armi))
					u.guasti[a] = "un_colpo"
					scrivi("Guasto: %s potrà usare %s una sola volta." % [u.nome, Dati.nome_oggetto(a)], "pericolo")
		"cambio_visibilita":
			if visibilita > 0:
				visibilita += dadi.d6()
			else:
				visibilita = dadi.tira("1d6+6")
			scrivi("Visibilità ora %d\"." % visibilita)
		"piu_duro_del_previsto":
			var nem := figure(NEM)
			if not nem.is_empty():
				var u: Dictionary = dadi.scegli(nem)
				u.robustezza = min(6, int(u.robustezza) + 1)
				u.stordito = 0
				scrivi("%s si rivela più duro del previsto (Robustezza %d)." % [u.nome, u.robustezza])
		"tiro_istintivo":
			_chiedi("tiro_istintivo", "Tiro istintivo: chi spara subito?", _opzioni_eq())
		"piano_astuto":
			effetti_round[prossimo]["scelta_libera"] = true
		"possibili_rinforzi":
			for i in 3:
				_id += 1
				segnalini.append({"id": _id, "tipo": "rinforzi", "pos": Vector2i(int(W * (i + 1) / 4.0), 0)})
			effetti_battaglia["rinforzi_da"] = prossimo
		"tempo_scade":
			effetti_battaglia["tempo_da"] = prossimo
		"rischio_ambientale":
			var cand := elementi.filter(func(e): return not e.get("muro_forza", false))
			if not cand.is_empty():
				var e: Dictionary = dadi.scegli(cand)
				scrivi("Rischio ambientale in: %s." % e.nome, "pericolo")
				for u in unita.duplicate():
					if not u.attiva:
						continue
					var vicino := false
					for c in e.celle:
						if dist(c, u.pos) <= 1:
							vicino = true
					if not vicino:
						continue
					var t := dadi.d6()
					var b := int(u.get("acume", 0)) if u.lato == EQ else 0
					var soglia := 5 if u.lato == EQ else 4
					if ha(u, "tuta_ambientale") and dadi.d6() >= 5:
						continue
					if t + b < soglia:
						scrivi("  %s non evita il pericolo (%d%+d)." % [u.nome, t, b])
						colpisci({}, u, 1, [], false, "ambientale")
		"piano_disperato":
			var u := _eq_casuale()
			if not u.is_empty():
				effetti_round[prossimo]["salta_membro"] = u.uid
				scrivi("%s non potrà agire nel prossimo round." % u.nome)
				var opz := _opzioni_eq().filter(func(o): return int(o.id) != int(u.uid))
				_chiedi("doppia_fase", "Un piano disperato: chi agirà in entrambe le fasi nel prossimo round?", opz)
		"momento_esitazione":
			var opz := _opzioni_eq()
			var ferali := figure(EQ).filter(func(x): return x.specie == "feral")
			if not ferali.is_empty():
				opz = ferali.map(func(x): return {"id": str(x.uid), "nome": str(x.nome)})
			_chiedi("esitazione", "Un momento di esitazione: chi sarà l'unico ad agire nelle Azioni Rapide?", opz)
		"granata_sfuggita":
			var nem := figure(NEM).filter(func(x): return x.armi.any(func(a): return str(a).begins_with("granata")))
			if nem.is_empty():
				scrivi("Il nemico non usa granate: nessun effetto.")
			else:
				var u: Dictionary = dadi.scegli(nem)
				var p0: Vector2i = u.pos
				_movimento_casuale(u, 6, false)
				_stordisci(u, 1)
				for w in unita:
					if w.attiva and w.uid != u.uid and dist(w.pos, p0) <= 4:
						for i in 4:
							_respingi(w, p0)
				scrivi("A %s sfugge una granata: tutti si buttano al riparo, ma esplode senza danni." % u.nome)
		"rinforzi_amici":
			if riserve.is_empty():
				scrivi("Nessun membro di riserva disponibile.")
			else:
				_chiedi("rinforzo_amico", "Rinforzi: chi arriva dal vostro bordo?", riserve.map(func(p): return {"id": str(p.id), "nome": str(p.nome)}))
		"vip_nemico":
			var tab: Dictionary = Dati.f("incontri").get("individui_unici", {}).get("tabella", {})
			if not tab.is_empty():
				var idu := str(dadi.su_tabella(tab).riga.get("nemico", ""))
				if idu != "":
					var nuovi := aggiungi_nemici(str(setup.get("nemico", "")), 0, [idu])
					for nn in nuovi:
						nn.pos = _libera_vicina(Vector2i(W / 2, 0), true)
						scrivi("Si unisce al nemico: %s." % nn.nome, "pericolo")
		"banco_nebbia":
			nebbia = {"centro": centro, "raggio": 6, "vis": 2}
		"perso":
			if figure(EQ).size() < figure(NEM).size():
				scrivi("Siete in inferiorità numerica: l'evento si ignora.")
			else:
				var u := _eq_casuale()
				if not u.is_empty():
					u.attiva = false
					u.uscito = true
					u["perso"] = true
					guadagni.persi.append(str(u.pg))
					scrivi("%s si perde e salta il resto della battaglia (tornerà sano e salvo)." % u.nome, "evento")
		"ho_trovato_qualcosa", "sembra_prezioso":
			var u := _eq_casuale()
			if not u.is_empty():
				var dd: Vector2i = _dir8()[dadi.d(8) - 1]
				var p := _libera_vicina(u.pos + dd * dadi.d6())
				_id += 1
				segnalini.append({"id": _id, "tipo": "trovato" if str(r.id) == "ho_trovato_qualcosa" else "prezioso", "pos": p})
		"vado_a_vedere":
			var u := _eq_casuale()
			if not u.is_empty():
				_chiedi("vado_a_vedere", "%s giura di aver visto qualcosa: lo lasci andare a controllare? (esce dalla battaglia, poi un tiro sul Bottino)" % u.nome,
					[{"id": "si", "nome": "Sì, vai"}, {"id": "no", "nome": "No, resta qui"}], {"uid": u.uid})

## ===================== fine della battaglia =====================

func _controlla_fine() -> bool:
	if fase == "finita":
		return true
	var nem := figure(NEM)
	var eq := []
	for u in figure(EQ):
		if not u.vip:
			eq.append(u)
	if nem.is_empty():
		_finisci(true)
		return true
	if eq.is_empty() and ritardati.is_empty():
		_finisci(false)
		return true
	return false

## L'equipaggio abbandona il campo: tutti escono.
func ritirata() -> void:
	for u in figure(EQ):
		u.attiva = false
		u.uscito = true
		u.uscito_round = round_n
		if obiettivo == "invasione" and round_n < 6:
			u.fuori = true
	scrivi("L'equipaggio si ritira dal campo.")
	_finisci(false)

func _finisci(campo: bool, senza_esito := false) -> void:
	if fase == "finita":
		return
	fase = "finita"
	if campo and not senza_esito and not stato_obj.get("fatto", false) and not stato_obj.get("fallito", false):
		match obiettivo:
			"accedere":
				for u in figure(EQ):
					var t := dadi.d6()
					if t + int(u.get("acume", 0)) >= 6:
						_obiettivo_fatto()
						break
			"perquisire":
				for sg in stato_obj.get("segnalini", []):
					if not sg.fatto and dadi.d6() >= 5:
						_obiettivo_fatto()
				if not stato_obj.fatto:
					scrivi("L'oggetto cercato non era sul campo.")
			"attraversare":
				if figure(EQ).size() + int(stato_obj.get("uscite_nemico", 0)) >= 2:
					_obiettivo_fatto()
			"eliminare":
				pass
			_:
				if not obiettivo in ["invasione"]:
					_obiettivo_fatto()
	var vinto: bool = stato_obj.get("fatto", false) and not stato_obj.get("fallito", false) and not senza_esito
	if obiettivo in ["respingere", "difendere", "resa_dei_conti", "imboscata", "rinforzi_amici", "assalto", "incursione"]:
		vinto = campo and not senza_esito
	if obiettivo == "invasione":
		vinto = false
	var perdite := []
	var partecipanti := []
	var presto := []
	for u in figure(EQ, false):
		if str(u.pg) == "":
			continue
		if u.get("perso", false):
			continue
		partecipanti.append(u.pg)
		if u.fuori and not u.ko:
			perdite.append(u.pg)
		if u.uscito and int(u.uscito_round) <= 2 and obiettivo != "attraversare" and not u.get("controlla", false):
			presto.append(u.pg)
	var uccisi := 0
	for u in figure(NEM, false):
		if u.fuori:
			uccisi += 1
	var usati := {}
	for u in figure(EQ, false):
		if str(u.pg) != "" and not u.monouso_usati.is_empty():
			usati[str(u.pg)] = u.monouso_usati.duplicate()
	esito_finale = {"vinto": vinto, "campo": campo and not senza_esito, "perdite": perdite, "partecipanti": partecipanti, "primo": primo_colpo,
		"unico_ucciso": unico_ucciso, "fuggiti_presto": presto, "nemici_uccisi": uccisi, "round": round_n,
		"luogo": stato_obj.get("luogo_preso_da", ""), "senza_esito": senza_esito, "guadagni": guadagni, "monouso_usati": usati,
		"luogotenente_ucciso": figure(NEM, false).any(func(x): return x.luogotenente and x.fuori)}
	scrivi("FINE DELLA BATTAGLIA: %s%s." % ["vittoria" if vinto else ("nessun esito" if senza_esito else "nessuna vittoria"), ", campo tenuto" if campo and not senza_esito else ""], "titolo")

## ===================== automatico (prove e «gioca per me») =====================

func auto_equipaggio(u: Dictionary) -> void:
	ia_script.agisci(self, u)
	fine_attivazione(u)

## Iniziativa presa: l'equipaggio muove o spara (automatico).
func iniziativa_auto() -> void:
	for u in figure(EQ):
		var b := bersagli(u)
		if not b.is_empty():
			spara(u, b[0].u, "", true)
		u.agito = false
		u.mosso = false

## Gioca un'intera battaglia in automatico. Restituisce l'esito.
func gioca_automatica(max_round := 12) -> Dictionary:
	auto_decisioni = true
	var ini := tira_iniziativa()
	if ini >= 10:
		iniziativa_auto()
	while fase != "finita" and round_n < max_round:
		inizia_round()
		conferma_reazioni()
		var guard := 0
		while fase in ["rapida", "nemici", "lenta"] and guard < 10:
			guard += 1
			if fase == "rapida" or fase == "lenta":
				for u in da_attivare():
					if fase == "finita":
						break
					auto_equipaggio(u)
				if _controlla_fine():
					break
				avanza_fase()
			elif fase == "nemici":
				esegui_fase_nemici()
		if fase == "finita":
			break
	if fase != "finita":
		ritirata()
	return esito_finale
