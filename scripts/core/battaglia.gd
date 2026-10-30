## Battaglia su griglia (Appendice II: 1 casella = 1 pollice, diagonale = 1).
## Motore senza interfaccia: terreno, figure, round (reazioni, fasi rapida/nemici/lenta/fine), movimento,
## linea di vista, copertura, tiro, rissa, danni, morale, obiettivi ed esito. L'IA dei nemici è in ia.gd.
class_name Battaglia
extends RefCounted

## Tipi di terreno
enum T { APERTO, LINEARE, AREA, BLOCCO, SINGOLO, CAMPO }
const NOMI_TERRENO := {T.APERTO: "terreno aperto", T.LINEARE: "ostacolo lineare (muretto, barricata)",
	T.AREA: "area (vegetazione, macerie): difficile, blocca la vista", T.BLOCCO: "blocco (edificio, container): invalicabile",
	T.SINGOLO: "elemento singolo (barile, albero, roccia): invalicabile, dà copertura", T.CAMPO: "campo (fango, acqua): difficile"}

const EQ := "eq"
const NEM := "nem"

var W := 24
var H := 24
var celle := PackedInt32Array()
var elementi: Array = []   # {id, nome, tipo, celle: [Vector2i], grande: bool}
var unita: Array = []      # figure (Dictionary)
var dadi: Dadi
var round_n := 0
var fase := "preparazione"  # preparazione, iniziativa, rapida, nemici, lenta, fine, finita
var log_righe: Array = []
var eventi: Array = []     # eventi grafici per l'animazione: {tipo, ...}
var setup: Dictionary = {}
var obiettivo := "respingere"
var par_obiettivo: Dictionary = {}
var centro := Vector2i(12, 12)
var stato_obj := {}        # stato dell'obiettivo (pacchi, segnalini, round consecutivi...)
var perdite_round := 0     # nemici eliminati in combattimento in questo round (per il morale)
var esito_finale := {}
var visibilita := 0        # 0 = illimitata
var primo_colpo := ""      # id della prima figura dell'equipaggio che ha messo fuori combattimento un nemico
var unico_ucciso := ""
var ia_script = null
var eventi_battaglia := true
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
		return T.BLOCCO
	return celle[p.y * W + p.x]

func set_t(p: Vector2i, t: int) -> void:
	if dentro(p):
		celle[p.y * W + p.x] = t

func percorribile(p: Vector2i) -> bool:
	var t := t_at(p)
	return dentro(p) and t != T.BLOCCO and t != T.SINGOLO

## Costo di una casella in mezze unità: normale 2, difficile 3 (+1" ogni 2" nel terreno difficile).
func costo(p: Vector2i) -> int:
	var t := t_at(p)
	return 3 if (t == T.AREA or t == T.CAMPO or t == T.LINEARE) else 2

static func dist(a: Vector2i, b: Vector2i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y))

func figura_in(p: Vector2i) -> Dictionary:
	for u in unita:
		if u.attiva and u.pos == p:
			return u
	return {}

## ===================== generazione del campo =====================

func genera_terreno(lato := 24, tratti := []) -> void:
	W = lato
	H = lato
	centro = Vector2i(W / 2, H / 2)
	for tentativo in 40:
		celle = PackedInt32Array()
		celle.resize(W * H)
		celle.fill(T.APERTO)
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
			# grandi lontano dai bordi: preferisci i settori laterali di mezzo
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
		# tratti del mondo: vegetazione in più
		for t in tratti:
			if str(t).to_lower().contains("vegetazione"):
				for j in 2:
					_metti_area(Vector2i(dadi.d(W - 4) + 1, dadi.d(H - 8) + 3), 3, "Vegetazione")
		# niente terreno sulle due file di schieramento
		for x in W:
			for y in [0, 1, H - 2, H - 1]:
				if t_at(Vector2i(x, y)) in [T.BLOCCO, T.SINGOLO]:
					set_t(Vector2i(x, y), T.APERTO)
		if _connesso():
			return
	# in caso estremo, tavolo senza blocchi lungo una colonna
	for y in H:
		set_t(Vector2i(W / 2 - 3, y), T.APERTO)

func _libero(p: Vector2i, margine := 1) -> bool:
	for dy in range(-margine, margine + 1):
		for dx in range(-margine, margine + 1):
			var q := p + Vector2i(dx, dy)
			if dentro(q) and t_at(q) != T.APERTO:
				return false
	return dentro(p)

func _nuovo_elemento(nome: String, tipo: int, cl: Array, grande := false) -> void:
	_id += 1
	var ok := []
	for c in cl:
		if dentro(c):
			set_t(c, tipo if not (c is Dictionary) else tipo)
			ok.append(c)
	if not ok.is_empty():
		elementi.append({"id": _id, "nome": nome, "tipo": tipo, "celle": ok, "grande": grande})

func _rett(c: Vector2i, w: int, h: int) -> Array:
	var r := []
	for y in h:
		for x in w:
			r.append(c + Vector2i(x - w / 2, y - h / 2))
	return r

func _metti_grande(c: Vector2i, al_centro: bool) -> void:
	var scelta := dadi.d(5)
	match scelta:
		1:
			# edificio con muretto davanti
			var w := 3 + dadi.d(2)
			var h := 2 + dadi.d(2)
			_nuovo_elemento("Edificio", T.BLOCCO, _rett(c, w, h), true)
			var ly := c.y + h / 2 + 2 if dadi.d6() < 4 else c.y - h / 2 - 2
			var lin := []
			for x in range(c.x - 1, c.x + 2):
				lin.append(Vector2i(x, ly))
			_nuovo_elemento("Muretto", T.LINEARE, lin)
		2:
			_metti_area(c, 4 + dadi.d(2), "Bosco", true)
		3:
			# deposito di casse e barili
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
			_nuovo_elemento("Deposito di casse", T.BLOCCO, cas, true)
			_nuovo_elemento("Barili", T.SINGOLO, bar)
		4:
			# rovine: macerie (area) attorno a pezzi di muro
			_metti_area(c, 4, "Rovine", true)
			for i in 3:
				var q := c + Vector2i(dadi.d(5) - 3, dadi.d(5) - 3)
				set_t(q, T.BLOCCO)
		_:
			# navetta atterrata
			_nuovo_elemento("Navetta atterrata", T.BLOCCO, _rett(c, 5, 2), true)
			_nuovo_elemento("Casse della navetta", T.SINGOLO, [c + Vector2i(-3, 2), c + Vector2i(3, -2)])

func _metti_area(c: Vector2i, r: int, nome: String, grande := false) -> void:
	var cl := []
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var q := c + Vector2i(dx, dy)
			if Vector2(dx, dy).length() <= r * 0.75 + dadi.rng.randf() * 0.8 and dentro(q) and t_at(q) == T.APERTO:
				cl.append(q)
	_nuovo_elemento(nome, T.AREA, cl, grande)

func _metti_piccolo(c: Vector2i) -> void:
	for t in 6:
		if _libero(c, 1):
			break
		c += Vector2i(dadi.d(3) - 2, dadi.d(3) - 2)
	match dadi.d(5):
		1:
			_nuovo_elemento("Masso", T.BLOCCO, _rett(c, 2, 1 + dadi.d(2) - 1))
		2:
			_nuovo_elemento("Barili", T.SINGOLO, [c, c + Vector2i(1, 0), c + Vector2i(0, 1)].slice(0, 1 + dadi.d(2)))
		3:
			_metti_area(c, 2, "Cespugli")
		4:
			_nuovo_elemento("Container", T.BLOCCO, _rett(c, 1, 3) if dadi.d6() < 4 else _rett(c, 3, 1))
		_:
			_nuovo_elemento("Alberi", T.SINGOLO, [c, c + Vector2i(2, 1)])

func _metti_lineare(c: Vector2i) -> void:
	var l := 4 + dadi.d(5) - 1
	var cl := []
	var oriz := dadi.d6() <= 3
	for i in l:
		cl.append(c + (Vector2i(i - l / 2, 0) if oriz else Vector2i(0, i - l / 2)))
	if dadi.d6() == 6:
		# a forma di L
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
	# deve esserci un percorso dal bordo dell'equipaggio a quello nemico e al centro
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
			if percorribile(q) and not vis.has(q):
				vis[q] = true
				coda.append(q)
	var arrivi := 0
	for x in W:
		if vis.has(Vector2i(x, 0)):
			arrivi += 1
	var c := _libera_vicina(centro)
	return arrivi >= W / 3 and vis.has(c)

static func _dir8() -> Array:
	return [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]

func _libera_vicina(p: Vector2i, escludi_figure := false) -> Vector2i:
	for r in max(W, H):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := p + Vector2i(dx, dy)
				if max(abs(dx), abs(dy)) == r and percorribile(q) and (not escludi_figure or figura_in(q).is_empty()):
					return q
	return p

## ===================== figure =====================

func _nuova_figura(base: Dictionary) -> Dictionary:
	_id += 1
	var u := {"uid": _id, "lato": EQ, "nome": "?", "pedina": "", "pos": Vector2i.ZERO, "reazioni": 1, "velocita": 4,
		"combattimento": 0, "robustezza": 3, "salv_corazza": 0, "salv_schermo": 0, "arma": "", "arma_m": "", "armi": [],
		"stordito": 0, "attiva": true, "fuori": false, "ko": false, "fuggito": false, "uscito": false, "fortuna": 0,
		"ia": "tattico", "panico": [], "impavido": false, "specialista": false, "luogotenente": false, "unico": false,
		"mosso": false, "agito": false, "attivato": false, "fase": "", "pg": "", "specie": "", "speciali": {}, "monouso_usati": [],
		"porta": "", "scatto": false, "iniziale": Vector2i.ZERO, "uscito_round": 0, "vip": false}
	u.merge(base, true)
	return u

## Aggiunge l'equipaggio (personaggi della campagna).
func aggiungi_equipaggio(pgs: Array) -> void:
	var xs := []
	var n := pgs.size()
	for i in n:
		xs.append(int(W / 2 - n + i * 2 + 1))
	for i in n:
		var pg: Dictionary = pgs[i]
		var sv := Personaggio.salvezze(pg)
		var u := _nuova_figura({"lato": EQ, "nome": pg.nome, "pedina": str(Personaggio.info_specie(pg).get("pedina", pg.specie)),
			"reazioni": Personaggio.stat_effettiva(pg, "reazioni"), "velocita": Personaggio.stat_effettiva(pg, "velocita"),
			"combattimento": Personaggio.stat_effettiva(pg, "combattimento"), "robustezza": Personaggio.stat_effettiva(pg, "robustezza"),
			"acume": Personaggio.stat_effettiva(pg, "acume"), "salv_corazza": sv.corazza, "salv_schermo": sv.schermo,
			"arma": Personaggio.arma_tiro(pg), "arma_m": Personaggio.arma_mischia(pg), "armi": Personaggio.armi(pg),
			"fortuna": int(pg.get("fortuna", 0)), "pg": str(pg.id), "specie": str(pg.specie), "ia": "tattico",
			"robot": Personaggio.e_robot(pg), "speciali": Personaggio.info_specie(pg).get("bonus", {})})
		var x: int = clampi(xs[i], 0, W - 1)
		var y := H - 1 - (i % 2)
		u.pos = _libera_vicina(Vector2i(x, y), true)
		u.iniziale = u.pos
		unita.append(u)

## Crea i nemici a partire dal tipo, dal numero e dagli eventuali Individui Unici.
func aggiungi_nemici(id_nemico: String, numero: int, unici: Array = [], forza_impavidi := false) -> void:
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
	var arma_nat = n.get("arma_naturale", {})
	var spl: Dictionary = Dati.f("incontri").get("specialisti_luogotenenti", {})
	var n_spec := 0 if numero <= 2 else (1 if numero <= 6 else 2)
	var ha_luog := numero >= int(spl.get("luogotenente", {}).get("minimo_nemici", 4))
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
		if ia == "aggressivo" and int(n.get("combattimento", 0)) > 0 and not "lama" in armi and not armi.is_empty():
			armi.append("lama")
		if luog and not "lama" in armi and not armi.is_empty():
			armi.append("lama")
		var u := _figura_nemico(n, id_nemico, armi, ia)
		u.specialista = spec
		u.luogotenente = luog
		if luog:
			u.combattimento += 1
			u.impavido = true
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
		u.unico = true
		u.impavido = true
		u.fortuna = int(un.get("fortuna", 0))
		var mods: Dictionary = un.get("modificatori", {})
		for k in mods:
			if u.has(k):
				u[k] = int(u[k]) + int(mods[k])
		figure.append(u)
	_schiera_nemici(figure, ia)

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
			if p > bp:
				bp = p
				arma = str(a)
		var t: Array = d.get("tratti", [])
		if ("mischia" in t or "pistola" in t) and (arma_m == "" or int(d.get("danno", 0)) > int(Dati.arma(arma_m).get("danno", 0))):
			arma_m = str(a)
	var pan = n.get("panico", [])
	return _nuova_figura({"lato": NEM, "nome": str(n.get("nome", id)), "pedina": id.trim_prefix("unico_"), "tipo": id,
		"velocita": int(n.get("velocita", 4) if n.get("velocita") != null else 4),
		"combattimento": int(n.get("combattimento", 0) if n.get("combattimento") != null else 0),
		"robustezza": int(n.get("robustezza", 3) if n.get("robustezza") != null else 3),
		"salv_corazza": int(n.get("salvezza", 0)), "arma": arma, "arma_m": arma_m, "armi": armi, "ia": ia,
		"panico": pan if pan is Array else [], "impavido": (pan is Array and pan.is_empty()) or n.get("speciali", {}).get("impavido", false),
		"speciali": n.get("speciali", {}), "regole": str(n.get("regole", ""))})

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

func per_uid(uid: int) -> Dictionary:
	for u in unita:
		if u.uid == uid:
			return u
	return {}

## ===================== preparazione da una campagna =====================

## Prepara la battaglia dalla campagna: setup = Campagna.s.battaglia; pgs = personaggi schierati.
func prepara(setup_: Dictionary, pgs: Array, lato := 24, opzioni := {}) -> void:
	setup = setup_
	obiettivo = str(setup.get("obiettivo", "respingere"))
	par_obiettivo = Dati.f("incontri").get("tipi_obiettivo", {}).get(obiettivo, {}).get("parametri", {})
	eventi_battaglia = bool(opzioni.get("eventi_battaglia", true))
	var tratti := []
	for t in opzioni.get("tratti_mondo", []):
		tratti.append(str(t))
	genera_terreno(lato, tratti)
	var cond: Dictionary = setup.get("condizione", {}).get("effetti", {})
	if cond.has("visibilita"):
		visibilita = dadi.tira(cond.visibilita)
		scrivi("Visibilità ridotta a %d caselle." % visibilita)
	var schierati := pgs.duplicate()
	if par_obiettivo.has("membri_mod") and schierati.size() > 1:
		schierati.resize(schierati.size() + int(par_obiettivo.membri_mod))
	if cond.has("escludi_membri_casuali") and schierati.size() > 1:
		var via: Dictionary = dadi.scegli(schierati)
		schierati.erase(via)
		scrivi("%s non partecipa allo scontro (%s)." % [via.nome, setup.condizione.get("nome", "")])
	aggiungi_equipaggio(schierati)
	aggiungi_nemici(str(setup.get("nemico", "ganger")), int(setup.get("numero", 4)) + int(par_obiettivo.get("nemici_mod", 0)),
		setup.get("unici", []), setup.get("finale_missione", false))
	if obiettivo == "proteggere":
		aggiungi_vip()
	_prepara_obiettivo()
	var cn := Dati.nemico(str(setup.get("nemico", "")))
	scrivi("Contro: %s. %s" % [cn.get("nome", ""), cn.get("regole", "")])
	scrivi("Obiettivo: %s. %s" % [Dati.f("incontri").get("tipi_obiettivo", {}).get(obiettivo, {}).get("nome", obiettivo),
		Dati.f("incontri").get("tipi_obiettivo", {}).get(obiettivo, {}).get("testo", "")], "obiettivo")
	if not setup.get("condizione", {}).is_empty() and str(setup.condizione.get("id", "")) != "nessuna":
		scrivi("Condizione: %s - %s" % [setup.condizione.get("nome", ""), setup.condizione.get("testo", "")])
	fase = "iniziativa"

func _prepara_obiettivo() -> void:
	centro = _libera_vicina(Vector2i(W / 2, H / 2))
	stato_obj = {"fatto": false, "fallito": false, "uscite_nemico": 0, "consecutivi": 0, "uno_naturale": 0}
	var luogo: Dictionary = setup.get("luogo", {})
	if not luogo.is_empty() and str(luogo.get("id", "niente")) != "niente":
		var dd: Vector2i = _dir8()[dadi.d(8) - 1]
		var lp: Vector2i = centro + dd * (dadi.tira("2d6+2") / (2 if abs(dd.x) + abs(dd.y) == 2 else 1))
		lp = Vector2i(clampi(lp.x, 1, W - 2), clampi(lp.y, 2, H - 3))
		stato_obj["luogo_pos"] = _libera_vicina(lp)
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

## ===================== linea di vista e copertura =====================

## Caselle attraversate dalla linea tra i centri di a e b (esclusi gli estremi).
func linea(a: Vector2i, b: Vector2i) -> Array:
	var r := []
	var n: int = dist(a, b) * 3
	if n == 0:
		return r
	var prev := a
	for i in range(1, n):
		var t := float(i) / n
		var p := Vector2i(roundi(lerp(float(a.x), float(b.x), t)), roundi(lerp(float(a.y), float(b.y), t)))
		if p != prev and p != a and p != b and not p in r:
			r.append(p)
		prev = p
	return r

## Linea di vista da a verso b (figure e terreno). Restituisce {"vede": bool, "copertura": bool}.
func lds(a: Vector2i, b: Vector2i, ignora_figure := false) -> Dictionary:
	var d := dist(a, b)
	if visibilita > 0 and d > visibilita:
		return {"vede": false, "copertura": false}
	var cop := false
	var area_a := t_at(a) == T.AREA
	var area_b := t_at(b) == T.AREA
	if area_b:
		cop = true
	var cl := linea(a, b)
	var aree := 0
	for p in cl:
		var t := t_at(p)
		if t == T.BLOCCO:
			return {"vede": false, "copertura": false}
		if t == T.AREA:
			aree += 1
			# dentro la stessa area ci si vede entro 3"; una linea che entra in un'area si ferma al bordo
			if not ((area_a or area_b) and d <= 3):
				if not (dist(p, a) <= 1 and area_a) and not (dist(p, b) <= 1 and area_b):
					return {"vede": false, "copertura": false}
		if (t == T.LINEARE or t == T.SINGOLO or t == T.AREA) and dist(p, a) > 1:
			cop = true
		if not ignora_figure and not figura_in(p).is_empty():
			return {"vede": false, "copertura": false}
	# dall'interno di un'area si vede fuori solo dal bordo
	if area_a and d > 3:
		var bordo := false
		for dd in _dir8():
			if t_at(a + dd) != T.AREA:
				bordo = true
		if not bordo:
			return {"vede": false, "copertura": false}
	return {"vede": true, "copertura": cop}

## Numero da ottenere per colpire (p.44): 3+ entro 6" allo scoperto, 5+ in gittata allo scoperto o entro 6" in copertura, 6+ in copertura.
func soglia_colpire(u: Dictionary, bersaglio: Dictionary, arma_id := "") -> Dictionary:
	if arma_id == "":
		arma_id = str(u.arma)
	var a := Dati.arma(arma_id)
	var g := int(a.get("gittata", 0))
	var d := dist(u.pos, bersaglio.pos)
	var l := lds(u.pos, bersaglio.pos)
	if not l.vede or d > g or g <= 0:
		return {"ok": false, "soglia": 99, "copertura": l.copertura, "distanza": d}
	var cop: bool = l.copertura
	var s := 0
	if d <= 6:
		s = 5 if cop else 3
	else:
		s = 6 if cop else 5
	var mod := int(u.combattimento)
	var tr: Array = a.get("tratti", [])
	if "tiro_rapido" in tr and d <= 6:
		mod += 1
	if "pesante" in tr and u.mosso and not u.speciali.get("sempre_fermo_sparo", false) and not ("pesante" in u.speciali.get("ignora_tratti", [])):
		mod -= 1
	return {"ok": true, "soglia": s, "mod": mod, "copertura": cop, "distanza": d}

## Bersagli possibili per u: lista di {"u": figura, "soglia", "mod", "copertura", "distanza", "netto"} ordinata (più facile, più vicino).
func bersagli(u: Dictionary, arma_id := "") -> Array:
	var r := []
	if arma_id == "":
		arma_id = str(u.arma)
	if arma_id == "" or u.vip:
		return r
	var nemico := NEM if u.lato == EQ else EQ
	var vicini := false
	for v in figure(nemico):
		if dist(u.pos, v.pos) <= 3 and lds(u.pos, v.pos).vede:
			vicini = true
	for v in figure(nemico):
		var s := soglia_colpire(u, v, arma_id)
		if not s.ok:
			continue
		if vicini and s.distanza > 3:
			continue
		s["u"] = v
		s["netto"] = int(s.soglia) - int(s.mod)
		r.append(s)
	r.sort_custom(func(x, y): return x.netto < y.netto or (x.netto == y.netto and x.distanza < y.distanza))
	return r

func adiacenti_nemici(u: Dictionary) -> Array:
	var r := []
	var nemico := NEM if u.lato == EQ else EQ
	for v in figure(nemico):
		if dist(u.pos, v.pos) == 1:
			r.append(v)
	return r

## ===================== movimento =====================

## Caselle raggiungibili: {Vector2i: costo in mezze unità}. scatto = +2" (senza azione di combattimento).
func raggiungibili(u: Dictionary, scatto := false) -> Dictionary:
	var budget: int = (int(u.velocita) + (2 if scatto else 0)) * 2
	if u.speciali.get("velocita_bonus_round", 0):
		budget += int(u.speciali.velocita_bonus_round) * 2
	var best := {u.pos: 0}
	var coda := [u.pos]
	var nemico := NEM if u.lato == EQ else EQ
	while not coda.is_empty():
		var p: Vector2i = coda.pop_front()
		var c: int = best[p]
		for d in _dir8():
			var q: Vector2i = p + d
			if not percorribile(q):
				continue
			var f := figura_in(q)
			if not f.is_empty() and f.lato == nemico:
				continue
			var nc := c + costo(q)
			if nc <= budget and (not best.has(q) or nc < best[q]):
				best[q] = nc
				coda.append(q)
	# non si termina su una casella occupata
	var r := {}
	for p in best:
		var f := figura_in(p)
		if f.is_empty() or f.uid == u.uid:
			r[p] = best[p]
	return r

func muovi(u: Dictionary, dest: Vector2i, scatto := false) -> bool:
	if u.mosso or not u.attiva:
		return false
	var r := raggiungibili(u, scatto)
	if not r.has(dest):
		return false
	var da: Vector2i = u.pos
	u.pos = dest
	u.mosso = dest != da
	u.scatto = scatto
	if scatto:
		u.agito = true
	eventi.append({"tipo": "muovi", "uid": u.uid, "da": da, "a": dest})
	if u.stordito > 0:
		u.agito = true
	_dopo_movimento(u)
	return true

func _dopo_movimento(u: Dictionary) -> void:
	if u.lato != EQ:
		return
	# obiettivi legati alla posizione
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
		"acquisire":
			pass

## ===================== combattimento =====================

func _tiro_salvezza(v: Dictionary, perforante: bool) -> bool:
	var sv := []
	if v.salv_corazza > 0 and not perforante:
		sv.append(int(v.salv_corazza))
	if v.salv_schermo > 0:
		sv.append(int(v.salv_schermo))
	if sv.is_empty():
		return false
	sv.sort()
	var t: int = sv[0] - (1 if sv.size() > 1 else 0)
	var r := dadi.d6()
	if r >= t:
		scrivi("  Tiro salvezza di %s: %d (serve %d+), il colpo è deviato." % [v.nome, r, t])
		return true
	return false

## Risolve un colpo con danno dmg su v da parte di att. Restituisce true se v è eliminato.
func colpisci(att: Dictionary, v: Dictionary, dmg: int, tratti: Array, mischia := false) -> bool:
	if not v.attiva:
		return false
	if "stordente" in tratti:
		v.stordito += 1
		scrivi("  %s è stordito." % v.nome)
		_controlla_ko(v)
		return not v.attiva
	var t := dadi.d6()
	var bonus_m := int(att.get("speciali", {}).get("danno_mischia", 0)) if mischia else 0
	var tot := t + dmg + bonus_m
	var fuori: bool = t == 6 or tot >= int(v.robustezza)
	scrivi("  Danno: %d%+d = %d contro Robustezza %d%s." % [t, dmg + bonus_m, tot, v.robustezza, " (6 naturale)" if t == 6 else ""])
	if fuori:
		if _tiro_salvezza(v, "perforante" in tratti):
			fuori = false
		elif int(v.fortuna) > 0:
			v.fortuna -= 1
			scrivi("  %s usa la Fortuna e si getta al riparo!" % v.nome)
			var dd: Vector2i = _dir8()[dadi.d(8) - 1]
			var dest: Vector2i = v.pos
			for i in dadi.d6():
				var q: Vector2i = dest + dd
				if percorribile(q) and figura_in(q).is_empty():
					dest = q
			v.pos = dest
			return false
		elif v.lato == EQ and _usa_stim(v):
			return false
	if fuori:
		elimina(v, att)
		return true
	# respinto di 1 e stordito
	_respingi(v, att.pos)
	v.stordito += 1
	if "impatto" in tratti:
		v.stordito += 1
	if "terrificante" in tratti:
		for i in dadi.d6():
			_respingi(v, att.pos)
	scrivi("  %s è respinto e stordito (%d segnalini)." % [v.nome, v.stordito])
	_controlla_ko(v)
	if v.attiva and v.speciali.get("ritirata_se_colpito", 0) and not mischia:
		for i in int(v.speciali.ritirata_se_colpito):
			_respingi(v, att.pos)
	return not v.attiva

func _usa_stim(v: Dictionary) -> bool:
	if v.pg == "" or "stim" in v.monouso_usati:
		return false
	if "stim" in v.get("consumabili", []):
		v.monouso_usati.append("stim")
		v.stordito = 1
		scrivi("  %s usa uno Stim-pack e resta in piedi." % v.nome)
		return true
	return false

func _controlla_ko(v: Dictionary) -> void:
	if v.attiva and v.stordito >= 3:
		scrivi("  %s ha 3 segnalini Stordito ed è messo fuori combattimento." % v.nome)
		v.ko = true
		elimina(v, {})

func _respingi(v: Dictionary, da: Vector2i) -> void:
	var d := Vector2i(signi(v.pos.x - da.x), signi(v.pos.y - da.y))
	if d == Vector2i.ZERO:
		d = Vector2i(0, 1 if v.lato == EQ else -1)
	var q: Vector2i = v.pos + d
	if percorribile(q) and figura_in(q).is_empty():
		eventi.append({"tipo": "muovi", "uid": v.uid, "da": v.pos, "a": q})
		v.pos = q

func elimina(v: Dictionary, att: Dictionary) -> void:
	v.attiva = false
	v.fuori = true
	scrivi("  %s è fuori combattimento!" % v.nome, "perdita")
	eventi.append({"tipo": "fuori", "uid": v.uid})
	if v.lato == NEM:
		perdite_round += 1
		if not att.is_empty() and att.get("lato") == EQ and primo_colpo == "" and att.pg != "":
			primo_colpo = str(att.pg)
		if v.unico and not att.is_empty() and att.get("pg", "") != "":
			unico_ucciso = str(att.pg)
		if v.get("bersaglio", false):
			_obiettivo_fatto()
	else:
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

## Tiro a distanza: risolve tutti i colpi dell'arma contro il bersaglio.
func spara(u: Dictionary, v: Dictionary, arma_id := "", iniziativa := false) -> bool:
	if u.agito or not u.attiva:
		return false
	if arma_id == "":
		arma_id = str(u.arma)
	var a := Dati.arma(arma_id)
	var s := soglia_colpire(u, v, arma_id)
	if not s.ok:
		return false
	var tr: Array = a.get("tratti", [])
	if "monouso" in tr:
		if arma_id in u.monouso_usati:
			return false
		u.monouso_usati.append(arma_id)
	u.agito = true
	var colpi := int(a.get("colpi", 1))
	var mira: bool = not u.mosso and u.stordito == 0 and (u.lato == EQ or u.ia in ["tattico", "cauto", "difensivo"])
	scrivi("%s spara a %s con %s (%d colpi, %d+%s%s)." % [u.nome, v.nome, a.get("nome", arma_id), colpi, s.soglia,
		(" %+d" % s.mod) if s.mod != 0 else "", ", mirando" if mira else ""], "tiro")
	eventi.append({"tipo": "spara", "uid": u.uid, "a": v.uid, "da_pos": u.pos, "a_pos": v.pos})
	var bersaglio := v
	var orig: Vector2i = v.pos
	for i in colpi:
		if not bersaglio.attiva:
			if "concentrata" in tr:
				break
			var altri := []
			for w in figure(v.lato):
				if dist(w.pos, orig) <= 3 and soglia_colpire(u, w, arma_id).ok:
					altri.append(w)
			if altri.is_empty():
				break
			bersaglio = altri[0]
			s = soglia_colpire(u, bersaglio, arma_id)
		var t := dadi.d6()
		if mira and t == 1:
			t = dadi.d6()
		var ok := (t == 6) if iniziativa else (t + int(s.mod) >= int(s.soglia))
		scrivi("  Tiro per colpire: %d%s -> %s." % [t, (" %+d" % s.mod) if s.mod != 0 else "", "colpito" if ok else "mancato"])
		if not ok:
			continue
		var n_colpi := 2 if ("critica" in tr and t == 6) else 1
		for k in n_colpi:
			colpisci(u, bersaglio, int(a.get("danno", 0)), tr)
		if "area" in tr:
			for w in unita.duplicate():
				if w.attiva and w.uid != bersaglio.uid and dist(w.pos, bersaglio.pos) <= 2:
					scrivi("  L'esplosione coinvolge %s." % w.nome)
					colpisci(u, w, int(a.get("danno", 0)), tr)
	return true

func _bonus_rissa(u: Dictionary, avv: Dictionary) -> int:
	var b := int(u.combattimento)
	var a := Dati.arma(str(u.arma_m))
	var t: Array = a.get("tratti", [])
	if "mischia" in t:
		b += 2
	elif "pistola" in t:
		b += 1
	if "goffa" in t and int(avv.velocita) > int(u.velocita) and not ("goffa" in u.speciali.get("ignora_tratti", [])):
		b -= 1
	return b

## Rissa tra u (attaccante) e v (p.45).
func rissa(u: Dictionary, v: Dictionary) -> bool:
	if u.agito or not u.attiva or not v.attiva or dist(u.pos, v.pos) != 1 or u.scatto:
		return false
	if u.vip:
		return false
	u.agito = true
	scrivi("%s ingaggia %s in una Rissa." % [u.nome, v.nome], "rissa")
	eventi.append({"tipo": "rissa", "uid": u.uid, "a": v.uid})
	var bu := _bonus_rissa(u, v)
	var bv := _bonus_rissa(v, u)
	if v.stordito > 0:
		bu += v.stordito
		v.stordito = 0
	if u.stordito > 0:
		bv += u.stordito
		u.stordito = 0
	# più avversari
	var amici_u := 0
	for w in figure(u.lato):
		if w.uid != u.uid and dist(w.pos, v.pos) == 1:
			amici_u += 1
	if amici_u > 0:
		bu += 1
	var du := _dado_rissa(u)
	var dv := _dado_rissa(v)
	if "elegante" in Dati.tratti_arma(str(u.arma_m)) and du + bu < dv + bv:
		du = max(du, dadi.d6())
	if "elegante" in Dati.tratti_arma(str(v.arma_m)) and dv + bv < du + bu:
		dv = max(dv, dadi.d6())
	var tu := du + bu
	var tv := dv + bv
	scrivi("  %s %d%+d = %d, %s %d%+d = %d." % [u.nome, du, bu, tu, v.nome, dv, bv, tv])
	var colpi_u := 0  # colpi che u infligge a v
	var colpi_v := 0
	if tu > tv:
		colpi_u += 1
	elif tv > tu:
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
	var dmg_u := int(Dati.arma(str(u.arma_m)).get("danno", 0)) if u.arma_m != "" else 0
	var dmg_v := int(Dati.arma(str(v.arma_m)).get("danno", 0)) if v.arma_m != "" else 0
	var tr_u: Array = Dati.tratti_arma(str(u.arma_m))
	var tr_v: Array = Dati.tratti_arma(str(v.arma_m))
	for i in colpi_u:
		if v.attiva:
			colpisci(u, v, dmg_u, tr_u, true)
	for i in colpi_v:
		if u.attiva:
			colpisci(v, u, dmg_v, tr_v, true)
	return true

func _dado_rissa(u: Dictionary) -> int:
	var d := dadi.d6()
	if u.speciali.get("rissa_doppio_dado", false) or u.speciali.get("mischia_doppio", false):
		d = max(d, dadi.d6())
	return d

## ===================== azioni di obiettivo =====================

## Azioni speciali disponibili per u (come azione di combattimento): lista di {"id", "nome"}.
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
	# luogo notevole
	if stato_obj.has("luogo_pos") and not stato_obj.get("luogo_preso", false) and dist(u.pos, stato_obj.luogo_pos) <= 1 and not u.mosso:
		r.append({"id": "luogo", "nome": "Esamina: " + str(setup.get("luogo", {}).get("nome", "luogo notevole"))})
	# r.filter dei duplicati
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
	u.agito = true
	if id == "esci":
		u.attiva = false
		u.uscito = true
		u.uscito_round = round_n
		eventi.append({"tipo": "esce", "uid": u.uid})
		scrivi("%s esce dal campo di battaglia." % u.nome)
		if u.pos.y == 0:
			stato_obj["uscite_nemico"] = int(stato_obj.get("uscite_nemico", 0)) + 1
			if obiettivo == "attraversare" and int(stato_obj.uscite_nemico) >= 2:
				_obiettivo_fatto()
		if obiettivo == "acquisire" and u.porta == "oggetto":
			_obiettivo_fatto()
		return
	if id == "consegna":
		u.porta = ""
		scrivi("%s consegna il pacco al centro." % u.nome, "obiettivo")
		_obiettivo_fatto()
	elif id == "accedi":
		stato_obj["tentativi_round"] = int(stato_obj.get("tentativi_round", 0)) + 1
		var t := dadi.d6()
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
		for sg in stato_obj.get("segnalini", []):
			if sg.id == eid:
				sg.fatto = true
				var t := dadi.d6()
				scrivi("%s perquisisce %s: %d (serve 5+)." % [u.nome, sg.nome, t], "obiettivo")
				if t >= 5:
					_obiettivo_fatto()
		var resta := false
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

## ===================== round =====================

## Prendere l'iniziativa (p.112): 2D6 + Acume più alto + modificatori. Restituisce il totale (10+ = riuscita).
func tira_iniziativa() -> int:
	if par_obiettivo.get("niente_iniziativa", false):
		scrivi("Imboscata: non potete prendere l'iniziativa.")
		return 0
	var t := dadi.tira("2d6")
	var acume := -9
	var ferale := false
	for u in figure(EQ):
		acume = max(acume, int(u.get("acume", 0)))
		if u.specie == "feral":
			ferale = true
	var mod := acume
	var n := Dati.nemico(str(setup.get("nemico", "")))
	var mn := int(n.get("speciali", {}).get("iniziativa_giocatore", 0))
	if str(n.get("categoria", "")) == "forza_mercenaria":
		mn -= 1
	if ferale and mn < 0:
		mn = 0
	mod += mn
	if figure(NEM).size() > figure(EQ).size():
		mod += 1
	var diff := str(setup.get("difficolta", ""))
	if diff == "hardcore":
		mod -= 2
	elif diff == "follia":
		mod -= 3
	var tot := t + mod
	scrivi("Prendere l'iniziativa: %d%+d = %d (serve 10+)%s" % [t, mod, tot, ": riuscita! Ogni membro può muovere o sparare (colpisce solo con 6)." if tot >= 10 else "."], "titolo")
	return tot

## Tiro delle reazioni: assegna i dadi in modo da far agire nella fase rapida più figure possibile.
func inizia_round() -> void:
	round_n += 1
	perdite_round = 0
	stato_obj["tentativi_round"] = 0
	eventi = []
	for u in unita:
		u.mosso = false
		u.agito = false
		u.attivato = false
		u.scatto = false
	var eq := figure(EQ)
	var dd := []
	for i in eq.size():
		dd.append(dadi.d6())
	dd.sort()
	var ordinati := eq.duplicate()
	ordinati.sort_custom(func(a, b): return int(a.reazioni) < int(b.reazioni))
	var liberi := ordinati.duplicate()
	var assegnati := {}
	# Feral: un singolo 1 va a un Feral
	if dd.count(1) == 1:
		for u in liberi:
			if u.specie == "feral":
				assegnati[u.uid] = 1
				liberi.erase(u)
				dd.erase(1)
				break
	for d in dd.duplicate():
		for u in liberi:
			if d <= int(u.reazioni):
				assegnati[u.uid] = d
				liberi.erase(u)
				dd.erase(d)
				break
	for u in liberi:
		assegnati[u.uid] = dd.pop_front() if not dd.is_empty() else 6
	var rapidi := []
	var lenti := []
	for u in eq:
		u.dado_reazione = assegnati.get(u.uid, 6)
		u.fase = "rapida" if int(u.dado_reazione) <= int(u.reazioni) else "lenta"
		if u.vip:
			u.fase = "lenta"
		(rapidi if u.fase == "rapida" else lenti).append(u.nome)
	scrivi("ROUND %d - Reazioni: rapidi %s; lenti %s." % [round_n, ", ".join(rapidi) if not rapidi.is_empty() else "nessuno", ", ".join(lenti) if not lenti.is_empty() else "nessuno"], "titolo")
	fase = "rapida"
	if rapidi.is_empty():
		fase = "nemici"

## Scambia la fase di due figure dell'equipaggio (assegnazione manuale dei dadi delle reazioni).
func scambia_dadi(a: Dictionary, b: Dictionary) -> void:
	var t = a.dado_reazione
	a.dado_reazione = b.dado_reazione
	b.dado_reazione = t
	for u in [a, b]:
		u.fase = "rapida" if int(u.dado_reazione) <= int(u.reazioni) else "lenta"

## Figure dell'equipaggio che possono ancora agire nella fase corrente.
func da_attivare() -> Array:
	var r := []
	if fase != "rapida" and fase != "lenta":
		return r
	for u in figure(EQ):
		if u.fase == fase and not u.attivato:
			r.append(u)
	return r

## Fine dell'attivazione di una figura: toglie un segnalino Stordito.
func fine_attivazione(u: Dictionary) -> void:
	u.attivato = true
	if u.stordito > 0 and u.attiva:
		u.stordito -= 1

## Passa alla fase successiva quando tutti hanno agito.
func avanza_fase() -> void:
	if fase == "rapida":
		for u in da_attivare():
			fine_attivazione(u)
		fase = "nemici"
	elif fase == "nemici":
		fase = "lenta"
		if da_attivare().is_empty():
			avanza_fase()
	elif fase == "lenta":
		for u in da_attivare():
			fine_attivazione(u)
		fase = "fine"
		fine_round()

## Ordine dei nemici: dai più vicini al bordo del giocatore.
func ordine_nemici() -> Array:
	var n := figure(NEM)
	n.sort_custom(func(a, b): return a.pos.y > b.pos.y or (a.pos.y == b.pos.y and a.pos.x < b.pos.x))
	return n

## Esegue l'attivazione di un nemico con l'IA.
func attiva_nemico(u: Dictionary) -> void:
	if not u.attiva or u.attivato:
		return
	ia_script.agisci(self, u)
	fine_attivazione(u)

func esegui_fase_nemici() -> void:
	for u in ordine_nemici():
		attiva_nemico(u)
		if _controlla_fine():
			return
	avanza_fase()

## Fase finale: morale, eventi della battaglia, obiettivi, fine della battaglia.
func fine_round() -> void:
	# morale
	if perdite_round > 0:
		var nem := figure(NEM)
		if not nem.is_empty():
			var p: Array = nem[0].panico
			var fuggono := 0
			var tiri := []
			for i in perdite_round:
				var t := dadi.d6()
				tiri.append(t)
				if p.size() == 2 and t >= int(p[0]) and t <= int(p[1]):
					fuggono += 1
			scrivi("Morale nemico: %s (panico %s): %d fuggono." % [str(tiri), "%d-%d" % [p[0], p[1]] if p.size() == 2 else "nessuno", fuggono])
			var cand := nem.filter(func(x): return not x.impavido)
			cand.sort_custom(func(a, b): return a.pos.y < b.pos.y)
			for i in min(fuggono, cand.size()):
				var u: Dictionary = cand[i]
				if u.get("bersaglio", false) and obiettivo == "eliminare":
					u["bloccato"] = true
					scrivi("%s vorrebbe fuggire, ma resta bloccato per un round." % u.nome)
					continue
				u.attiva = false
				u.fuggito = true
				eventi.append({"tipo": "fugge", "uid": u.uid})
				scrivi("%s fugge dal campo." % u.nome, "perdita")
	# obiettivi a fine round
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
	# eventi della battaglia
	if eventi_battaglia and round_n in [2, 4]:
		var tab: Dictionary = Dati.f("incontri").get("eventi_battaglia", {})
		if not tab.is_empty():
			var r := dadi.su_tabella(tab)
			scrivi("Evento della battaglia (%d): %s - %s" % [r.tiro, r.riga.get("nome", ""), r.riga.get("testo", "")], "evento")
			_applica_evento(r.riga)
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
	_controlla_fine()
	if fase != "finita":
		fase = "fine"

func _applica_evento(r: Dictionary) -> void:
	var e: Dictionary = r.get("effetti", {})
	if e.has("rinforzi"):
		var nem := Dati.nemico(str(setup.get("nemico", "")))
		var prima := unita.size()
		aggiungi_nemici(str(setup.get("nemico", "")), int(e.rinforzi))
		for i in range(prima, unita.size()):
			unita[i].pos = _libera_vicina(Vector2i(W / 2, 0), true)
		scrivi("Arrivano %d rinforzi nemici." % int(e.rinforzi))
	if e.has("visibilita"):
		visibilita = dadi.tira(e.visibilita)

## Verifica se la battaglia è finita. Restituisce true in quel caso.
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
	if eq.is_empty():
		_finisci(false)
		return true
	return false

## L'equipaggio abbandona il campo: tutti escono.
func ritirata() -> void:
	for u in figure(EQ):
		u.attiva = false
		u.uscito = true
		u.uscito_round = round_n
	scrivi("L'equipaggio si ritira dal campo.")
	_finisci(false)

func _finisci(campo: bool) -> void:
	fase = "finita"
	# con il campo tenuto, gli obiettivi si completano con calma
	if campo and not stato_obj.get("fatto", false) and not stato_obj.get("fallito", false):
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
	var vinto: bool = stato_obj.get("fatto", false) and not stato_obj.get("fallito", false)
	if obiettivo in ["respingere", "difendere", "resa_dei_conti", "imboscata", "rinforzi_amici", "assalto", "incursione"]:
		vinto = campo
	if obiettivo == "invasione":
		vinto = false
	var perdite := []
	var partecipanti := []
	var presto := []
	for u in figure(EQ, false):
		if u.pg == "":
			continue
		partecipanti.append(u.pg)
		if u.fuori and not u.ko:
			perdite.append(u.pg)
		if u.uscito and int(u.uscito_round) <= 2 and obiettivo != "attraversare":
			presto.append(u.pg)
	var uccisi := 0
	for u in figure(NEM, false):
		if u.fuori:
			uccisi += 1
	esito_finale = {"vinto": vinto, "campo": campo, "perdite": perdite, "partecipanti": partecipanti, "primo": primo_colpo,
		"unico_ucciso": unico_ucciso, "fuggiti_presto": presto, "nemici_uccisi": uccisi, "round": round_n,
		"luogo": stato_obj.get("luogo_preso_da", "")}
	scrivi("FINE DELLA BATTAGLIA: %s%s." % ["vittoria" if vinto else "nessuna vittoria", ", campo tenuto" if campo else ""], "titolo")

## ===================== automatico (per le prove e per «gioca per me») =====================

## Fa agire una figura dell'equipaggio con l'IA tattica.
func auto_equipaggio(u: Dictionary) -> void:
	ia_script.agisci(self, u)
	fine_attivazione(u)

## Gioca un'intera battaglia in automatico. Restituisce l'esito.
func gioca_automatica(max_round := 12) -> Dictionary:
	var ini := tira_iniziativa()
	if ini >= 10:
		for u in figure(EQ):
			var b := bersagli(u)
			if not b.is_empty():
				spara(u, b[0].u, "", true)
			u.agito = false
	while fase != "finita" and round_n < max_round:
		inizia_round()
		if fase == "rapida":
			for u in da_attivare():
				if fase == "finita":
					break
				auto_equipaggio(u)
			if _controlla_fine():
				break
			avanza_fase()
		if fase == "nemici":
			esegui_fase_nemici()
		if fase == "finita":
			break
		if fase == "lenta":
			for u in da_attivare():
				if fase == "finita":
					break
				auto_equipaggio(u)
			if _controlla_fine():
				break
			avanza_fase()
	if fase != "finita":
		ritirata()
	return esito_finale
