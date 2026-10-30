## IA dei nemici secondo i comportamenti del regolamento (p.43): Aggressivo, Cauto, Tattico, Difensivo,
## Furia (Rampaging), Bestia, Guardiano. Usata anche per l'equipaggio nelle partite automatiche (come Tattico).
extends RefCounted

static func agisci(b: Battaglia, u: Dictionary) -> void:
	if not u.attiva or b.fase == "finita":
		return
	var nemico := Battaglia.NEM if u.lato == Battaglia.EQ else Battaglia.EQ
	var avversari := b.figure(nemico)
	if avversari.is_empty():
		return
	var ia := str(u.ia)
	if u.lato == Battaglia.EQ:
		ia = "equipaggio"
	# Storditi: sparano al più vicino visibile, altrimenti cercano copertura; niente risse
	if u.stordito > 0:
		var bs := b.bersagli(u)
		if not bs.is_empty():
			b.spara(u, _piu_vicino(bs).u)
		else:
			var dest := _miglior_cella(b, u, avversari, "riparo", false)
			b.muovi(u, dest)
		return
	if u.lato == Battaglia.EQ and _obiettivo_equipaggio(b, u):
		return
	match ia:
		"furia", "bestia":
			_carica(b, u, avversari, ia == "bestia")
		"aggressivo":
			_aggressivo(b, u, avversari)
		"cauto":
			_tiratore(b, u, avversari, "cauto")
		"difensivo":
			_tiratore(b, u, avversari, "difensivo")
		"guardiano":
			_guardiano(b, u, avversari)
		_:
			_tiratore(b, u, avversari, "tattico" if ia != "equipaggio" else "equipaggio")

static func _piu_vicino(bs: Array) -> Dictionary:
	var m: Dictionary = bs[0]
	for x in bs:
		if x.distanza < m.distanza:
			m = x
	return m

static func _vicino(b: Battaglia, pos: Vector2i, avversari: Array) -> Dictionary:
	var best := {}
	var bd := 999
	for v in avversari:
		var d := Battaglia.dist(pos, v.pos)
		if d < bd:
			bd = d
			best = v
	return best

static func _ha_pesante(u: Dictionary) -> bool:
	return "pesante" in Dati.tratti_arma(str(u.arma))

## Valuta le caselle raggiungibili secondo un criterio e restituisce la migliore.
static func _miglior_cella(b: Battaglia, u: Dictionary, avversari: Array, modo: String, scatto: bool, max_passi := 99) -> Vector2i:
	var r := b.raggiungibili(u, scatto)
	var best: Vector2i = u.pos
	var bp := -99999.0
	var vicino := _vicino(b, u.pos, avversari)
	var amici := b.figure(u.lato)
	var g := int(Dati.arma(str(u.arma)).get("gittata", 0))
	for p in r:
		if r[p] > max_passi * 2:
			continue
		var punteggio := 0.0
		var dmin := 999
		var vede := false
		var in_cop := false
		var colpo := false
		for v in avversari:
			var d := Battaglia.dist(p, v.pos)
			dmin = min(dmin, d)
			var l := b.lds(v.pos, p, true)
			if l.vede:
				vede = true
				if l.copertura:
					in_cop = true
			if g > 0 and d <= g:
				var l2 := b.lds(p, v.pos)
				if l2.vede:
					colpo = true
		var esposto := vede and not in_cop
		var t := b.t_at(p)
		var riparo := t == Battaglia.T.AREA or _vicino_a_terreno(b, p)
		match modo:
			"avanza":
				punteggio = -dmin * 3.0 + (4.0 if riparo else 0.0) + (3.0 if colpo else 0.0) - (2.0 if esposto else 0.0)
			"riparo":
				punteggio = (6.0 if riparo else 0.0) - (8.0 if esposto else 0.0) + (3.0 if colpo else 0.0) + dmin * 0.3
			"cauto":
				punteggio = (5.0 if riparo else 0.0) + (8.0 if colpo else 0.0) - (6.0 if esposto else 0.0) - abs(dmin - max(12, g - 2)) * 0.5
				if dmin < 12:
					punteggio -= (12 - dmin) * 1.5
			"tattico":
				punteggio = (6.0 if riparo else 0.0) + (8.0 if colpo else 0.0) - (5.0 if esposto else 0.0) - max(0, dmin - 12) * 1.0
				var vic_amico := false
				for a in amici:
					if a.uid != u.uid and Battaglia.dist(a.pos, p) <= 3:
						vic_amico = true
				if vic_amico:
					punteggio += 1.5
			"difensivo":
				var meta: bool = p.y <= b.H / 2 if u.lato == Battaglia.NEM else p.y >= b.H / 2
				punteggio = (6.0 if riparo else 0.0) + (8.0 if colpo else 0.0) - (5.0 if esposto else 0.0) - (50.0 if not meta else 0.0) - max(0, dmin - g) * 0.5
			"equipaggio":
				punteggio = (6.0 if riparo else 0.0) + (9.0 if colpo else 0.0) - (6.0 if esposto else 0.0) - max(0, dmin - g + 2) * 0.8
				var obj = b.stato_obj
				if b.obiettivo in ["consegnare", "accedere", "acquisire", "assicurare", "perquisire"] or u.vip:
					var cd: int = Battaglia.dist(p, b.centro)
					punteggio -= cd * (2.0 if (u.porta != "" or u.vip or b.obiettivo == "assicurare") else 0.6)
				if b.obiettivo == "attraversare":
					punteggio -= p.y * 0.8
				if b.obiettivo == "pattugliare":
					for pt in obj.get("punti", []):
						if not pt.fatto:
							punteggio -= Battaglia.dist(p, pt.cella) * 0.7
							break
			"verso":
				punteggio = -dmin * 4.0 + (2.0 if riparo else 0.0)
		punteggio += b.dadi.rng.randf() * 0.3
		if punteggio > bp:
			bp = punteggio
			best = p
	return best

static func _vicino_a_terreno(b: Battaglia, p: Vector2i) -> bool:
	for d in Battaglia._dir8():
		var t := b.t_at(p + d)
		if t == Battaglia.T.LINEARE or t == Battaglia.T.SINGOLO or t == Battaglia.T.BLOCCO or t == Battaglia.T.AREA:
			if b.dentro(p + d):
				return true
	return false

## Cella libera adiacente al bersaglio raggiungibile (per entrare in Rissa), o Vector2i(-1,-1).
static func _cella_rissa(b: Battaglia, u: Dictionary, v: Dictionary) -> Vector2i:
	if Battaglia.dist(u.pos, v.pos) == 1:
		return u.pos
	var r := b.raggiungibili(u, false)
	var best := Vector2i(-1, -1)
	var bc := 999
	for p in r:
		if Battaglia.dist(p, v.pos) == 1 and r[p] < bc:
			bc = r[p]
			best = p
	return best

static func _spara_migliore(b: Battaglia, u: Dictionary) -> bool:
	var bs := b.bersagli(u)
	if bs.is_empty():
		return false
	return b.spara(u, bs[0].u)

static func _prova_rissa(b: Battaglia, u: Dictionary, avversari: Array, solo_se_migliore := false, pari_ok := false) -> bool:
	if u.arma_m == "" and u.arma != "" and not solo_se_migliore:
		pass
	var cand := []
	for v in avversari:
		if solo_se_migliore:
			if int(v.combattimento) > int(u.combattimento):
				continue
			if not pari_ok and int(v.combattimento) == int(u.combattimento):
				continue
		var c := _cella_rissa(b, u, v)
		if c.x >= 0:
			cand.append([v, c])
	if cand.is_empty():
		return false
	cand.sort_custom(func(x, y): return Battaglia.dist(u.pos, x[1]) < Battaglia.dist(u.pos, y[1]))
	var v: Dictionary = cand[0][0]
	if cand[0][1] != u.pos:
		b.muovi(u, cand[0][1])
	return b.rissa(u, v)

static func _carica(b: Battaglia, u: Dictionary, avversari: Array, bestia: bool) -> void:
	if _ha_pesante(u) and not bestia and not b.bersagli(u).is_empty():
		_spara_migliore(b, u)
		return
	if _prova_rissa(b, u, avversari):
		return
	# corre verso il più vicino (scatto), le bestie cercando copertura
	var dest := _miglior_cella(b, u, avversari, "avanza" if bestia else "verso", true)
	b.muovi(u, dest, true)

static func _aggressivo(b: Battaglia, u: Dictionary, avversari: Array) -> void:
	var bs := b.bersagli(u)
	var v := _vicino(b, u.pos, avversari)
	var dmin := Battaglia.dist(u.pos, v.pos)
	if _ha_pesante(u) and not bs.is_empty():
		_spara_migliore(b, u)
		return
	var vede := false
	for a in avversari:
		if b.lds(u.pos, a.pos).vede:
			vede = true
	if not vede or dmin <= 12:
		if _prova_rissa(b, u, avversari, true, true):
			return
		var dest := _miglior_cella(b, u, avversari, "verso", bs.is_empty())
		b.muovi(u, dest, bs.is_empty() and Battaglia.dist(dest, v.pos) > 1)
		_spara_migliore(b, u)
		return
	# avanza di almeno mezzo movimento restando in copertura
	var dest := _miglior_cella(b, u, avversari, "avanza", false)
	b.muovi(u, dest)
	_spara_migliore(b, u)

static func _tiratore(b: Battaglia, u: Dictionary, avversari: Array, modo: String) -> void:
	var bs := b.bersagli(u)
	var in_cop := b.t_at(u.pos) == Battaglia.T.AREA or _vicino_a_terreno(b, u.pos)
	# tattici e equipaggio: rissa se più forti e vicini
	if modo in ["tattico", "equipaggio"]:
		var forte := false
		for v in avversari:
			if Battaglia.dist(u.pos, v.pos) <= int(u.velocita) and int(u.combattimento) > int(v.combattimento) and u.arma_m != "":
				forte = true
		if forte and _prova_rissa(b, u, avversari, true):
			return
	if modo == "difensivo":
		for v in b.adiacenti_nemici(u):
			if int(u.combattimento) >= int(v.combattimento):
				b.rissa(u, v)
				return
	if not bs.is_empty() and (in_cop or modo == "cauto") and int(bs[0].netto) <= 6:
		# resta fermo e mira
		b.spara(u, bs[0].u)
		return
	var passi := 99
	if modo == "tattico":
		passi = max(1, int(u.velocita) / 2)
	var dest := _miglior_cella(b, u, avversari, modo, false, passi)
	var prima: Vector2i = u.pos
	b.muovi(u, dest)
	if not _spara_migliore(b, u) and dest == prima and bs.is_empty():
		# nessun colpo possibile: scatto verso una posizione migliore
		u.mosso = false
		var d2 := _miglior_cella(b, u, avversari, "avanza" if modo != "cauto" else "cauto", true)
		b.muovi(u, d2, true)

static func _guardiano(b: Battaglia, u: Dictionary, avversari: Array) -> void:
	var protetto := {}
	for a in b.figure(u.lato):
		if a.luogotenente or (a.unico and a.uid != u.uid):
			protetto = a
	if protetto.is_empty():
		_tiratore(b, u, avversari, "tattico")
		return
	var r := b.raggiungibili(u, false)
	var best: Vector2i = u.pos
	var bp := -999.0
	for p in r:
		if Battaglia.dist(p, protetto.pos) > 3:
			continue
		var s := (5.0 if _vicino_a_terreno(b, p) else 0.0)
		for v in avversari:
			if b.lds(p, v.pos).vede:
				s += 2.0
		if s > bp:
			bp = s
			best = p
	b.muovi(u, best)
	_spara_migliore(b, u)

## Azioni di obiettivo dell'equipaggio automatico. Restituisce true se ha agito.
static func _obiettivo_equipaggio(b: Battaglia, u: Dictionary) -> bool:
	for a in b.azioni_obiettivo(u):
		if a.id != "esci" and a.id != "luogo":
			b.azione(u, a.id)
			return true
	var serve_centro: bool = (u.porta == "pacco") or (b.obiettivo == "accedere" and not b.stato_obj.get("fatto", false)) or (b.obiettivo == "acquisire" and b.stato_obj.has("oggetto_a"))
	if serve_centro and Battaglia.dist(u.pos, b.centro) > 1:
		var r := b.raggiungibili(u, false)
		var best: Vector2i = u.pos
		var bd := Battaglia.dist(u.pos, b.centro)
		for p in r:
			var d := Battaglia.dist(p, b.centro)
			if d < bd:
				bd = d
				best = p
		if best != u.pos:
			b.muovi(u, best)
			for a in b.azioni_obiettivo(u):
				if a.id != "esci":
					b.azione(u, a.id)
					return true
			_spara_migliore(b, u)
			return true
	if u.porta == "oggetto" or (b.obiettivo == "attraversare" and u.pos.y <= 3):
		# verso l'uscita (bordo nemico per attraversare, il proprio per portare via l'oggetto)
		var r := b.raggiungibili(u, true)
		var best: Vector2i = u.pos
		for p in r:
			if (b.obiettivo == "attraversare" and p.y < best.y) or (b.obiettivo != "attraversare" and p.y > best.y):
				best = p
		b.muovi(u, best, true)
		for a in b.azioni_obiettivo(u):
			if a.id == "esci" and (b.obiettivo != "attraversare" or u.pos.y == 0):
				u.agito = false
				b.azione(u, "esci")
		return true
	return false
