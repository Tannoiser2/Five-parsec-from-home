## IA dei nemici secondo i comportamenti del regolamento (p.43): Aggressivo, Cauto, Tattico, Difensivo,
## Furia (Rampaging), Bestia, Guardiano, con le regole generali (p.41-47): i nemici scattano per raggiungere una copertura
## o la gittata ma non se possono sparare, i Pesanti restano fermi se hanno un bersaglio, mirano dalla copertura
## (Tattici, Cauti, Difensivi), sparano al bersaglio più facile e poi al più vicino, gli Storditi sparano al più vicino
## o cercano riparo e non entrano in Rissa. Usata anche per l'equipaggio nelle partite automatiche.
extends RefCounted

const NON_UMANI := ["bot", "bot_assalto", "soulless", "kerin", "swift", "engineer", "precursor", "feral", "hakshan", "manipolatore", "alieno_minore"]

static func agisci(b: Battaglia, u: Dictionary) -> void:
	if not u.attiva or b.fase == "finita":
		return
	var avversari := b.avversari(u)
	if avversari.is_empty():
		if u.lato == Battaglia.EQ:
			_obiettivo_equipaggio(b, u)
		return
	var ia := str(u.ia)
	if u.lato == Battaglia.EQ:
		ia = "equipaggio"
	# Storditi: muovono O agiscono; sparano al più vicino visibile, altrimenti cercano copertura; niente risse
	if int(u.stordito) > 0:
		var bs := b.bersagli(u)
		if not bs.is_empty():
			b.spara(u, _piu_vicino(bs).u)
		else:
			var dest := _miglior_cella(b, u, avversari, "riparo", false, 99, false)
			b.muovi(u, dest, false, false)
		return
	# K'Erin: se iniziano il round entro la propria velocità da un nemico raggiungibile senza scatto, devono ingaggiarlo
	if u.specie == "kerin" and u.lato == Battaglia.EQ:
		if _prova_rissa(b, u, avversari):
			return
	if u.lato == Battaglia.EQ and _obiettivo_equipaggio(b, u):
		return
	# Agente segreto: insegue il suo bersaglio prioritario
	if u.speciali.get("bersaglio_prioritario", false):
		if not u.has("preda") or b.per_uid(int(u.preda)).is_empty() or not b.per_uid(int(u.preda)).attiva:
			var eq := b.figure(Battaglia.EQ)
			if not eq.is_empty():
				u["preda"] = b.dadi.scegli(eq).uid
	# Cane genetico rimasto senza padrone: resta fermo e attacca chi si avvicina entro 8"
	if u.fedele_difende:
		for v in avversari:
			if Battaglia.dist(u.pos, v.pos) <= 8 and _prova_rissa(b, u, [v]):
				return
		return
	match ia:
		"furia":
			_furia(b, u, avversari)
		"bestia":
			_bestia(b, u, avversari)
		"aggressivo":
			_aggressivo(b, u, avversari)
		"cauto":
			_tiratore(b, u, avversari, "cauto")
		"difensivo":
			_tiratore(b, u, avversari, "difensivo")
		"guardiano":
			_guardiano(b, u, avversari)
		"dstar":
			_dstar(b, u, avversari)
		_:
			_tiratore(b, u, avversari, "tattico" if ia != "equipaggio" else "equipaggio")
	_balzo(b, u, avversari)

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

static func _ha_pesante(b: Battaglia, u: Dictionary) -> bool:
	return "pesante" in b.arma_eff(u, str(u.arma)).get("tratti", []) and not u.speciali.get("sempre_fermo_sparo", false)

static func _in_copertura(b: Battaglia, p: Vector2i) -> bool:
	return b.t_at(p) == Battaglia.T.AREA or b._vicino_a_terreno(p) or b.t_at(p) == Battaglia.T.INTERNO

## Valuta le caselle raggiungibili secondo un criterio e restituisce la migliore.
## contatto_ok: può terminare a contatto con un avversario (cioè entrare in Rissa).
static func _miglior_cella(b: Battaglia, u: Dictionary, avversari: Array, modo: String, scatto: bool, max_passi := 99, contatto_ok := false) -> Vector2i:
	var r := b.raggiungibili(u, scatto)
	var best: Vector2i = u.pos
	var bp := -99999.0
	var amici := b.figure(u.lato)
	var g := int(b.arma_eff(u, str(u.arma)).get("gittata", 0)) if str(u.arma) != "" else 0
	for p in r:
		if r[p] > max_passi * 2 and p != u.pos:
			continue
		if not contatto_ok and p != u.pos and b._a_contatto(u, p, avversari):
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
		var riparo := _in_copertura(b, p)
		var alto := float(b.a_at(p)) * 0.8
		match modo:
			"avanza":
				punteggio = -dmin * 3.0 + (4.0 if riparo else 0.0) + (3.0 if colpo else 0.0) - (2.0 if esposto else 0.0)
			"riparo":
				punteggio = (6.0 if riparo else 0.0) - (8.0 if esposto else 0.0) + (3.0 if colpo else 0.0) + dmin * 0.3
			"nascosto":
				punteggio = -dmin * 2.0 + (6.0 if not vede else 0.0) + (3.0 if riparo else 0.0)
			"cauto":
				punteggio = (5.0 if riparo else 0.0) + (8.0 if colpo else 0.0) - (6.0 if esposto else 0.0) - abs(dmin - max(12, g - 2)) * 0.5 + alto
				if dmin < 12:
					punteggio -= (12 - dmin) * 1.5
			"tattico":
				punteggio = (6.0 if riparo else 0.0) + (8.0 if colpo else 0.0) - (5.0 if esposto else 0.0) - max(0, dmin - 12) * 1.0 + alto
				var vic_amico := false
				for a in amici:
					if a.uid != u.uid and Battaglia.dist(a.pos, p) <= 3:
						vic_amico = true
				if vic_amico:
					punteggio += 1.5
			"difensivo":
				var meta: bool = p.y <= b.H / 2 if u.lato == Battaglia.NEM else p.y >= b.H / 2
				punteggio = (6.0 if riparo else 0.0) + (8.0 if colpo else 0.0) - (5.0 if esposto else 0.0) - (50.0 if not meta else 0.0) - max(0, dmin - g) * 0.5 + alto
			"equipaggio":
				punteggio = (6.0 if riparo else 0.0) + (9.0 if colpo else 0.0) - (6.0 if esposto else 0.0) - max(0, dmin - g + 2) * 0.8 + alto
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

## Cella libera a contatto con il bersaglio raggiungibile senza scatto (per entrare in Rissa), o Vector2i(-1,-1).
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
	if u.agito:
		return false
	var bs := b.bersagli(u)
	# i nemici non sparano mettendo a rischio gli alleati (tranne Swift e Senz'anima)
	if u.lato != Battaglia.EQ and not u.specie in ["swift", "soulless"]:
		var a := b.arma_eff(u, str(u.arma))
		bs = bs.filter(func(x): return not b._rischia_alleati(u, x.u, a))
	if bs.is_empty():
		# un'altra arma da tiro (es. granate) se la principale non ha bersagli
		for id in b.armi_tiro(u):
			if id != str(u.arma):
				var bs2 := b.bersagli(u, id)
				if not bs2.is_empty():
					return b.spara(u, bs2[0].u, id)
		return false
	# Guardiano: stesso bersaglio della figura protetta, se possibile
	if u.has("bersaglio_guardia"):
		for x in bs:
			if int(x.u.uid) == int(u.bersaglio_guardia):
				return b.spara(u, x.u)
	return b.spara(u, bs[0].u)

## Prova a entrare in Rissa. solo_se_migliore: niente Rissa contro chi ha Combattimento più alto (pari_ok: anche pari).
static func _prova_rissa(b: Battaglia, u: Dictionary, avversari: Array, solo_se_migliore := false, pari_ok := false) -> bool:
	if u.speciali.get("no_rissa_volontaria", false) or u.vip or u.agito:
		return false
	var cand := []
	for v in avversari:
		if solo_se_migliore:
			if int(v.combattimento) > int(u.combattimento):
				continue
			if not pari_ok and int(v.combattimento) == int(u.combattimento):
				continue
		var c := _cella_rissa(b, u, v)
		if c.x >= 0:
			var gruppo := 0
			if u.speciali.get("attacco_di_gruppo", false):
				for w in b.figure(u.lato):
					if w.uid != u.uid and Battaglia.dist(w.pos, v.pos) == 1:
						gruppo += 1
			cand.append([v, c, gruppo])
	if cand.is_empty():
		return false
	cand.sort_custom(func(x, y): return x[2] > y[2] or (x[2] == y[2] and Battaglia.dist(u.pos, x[1]) < Battaglia.dist(u.pos, y[1])))
	var v: Dictionary = cand[0][0]
	if cand[0][1] != u.pos:
		b.muovi(u, cand[0][1], false, false)
	if not u.attiva or not v.attiva:
		return true
	return b.rissa(u, v)

## Furia (Rampaging): verso l'avversario più vicino il più velocemente possibile, sempre in Rissa; i Pesanti sparano da fermi.
static func _furia(b: Battaglia, u: Dictionary, avversari: Array) -> void:
	if _ha_pesante(b, u) and not b.bersagli(u).is_empty():
		_spara_migliore(b, u)
		return
	var v := _vicino(b, u.pos, avversari)
	if _prova_rissa(b, u, [v]) or _prova_rissa(b, u, avversari):
		return
	var dest := _miglior_cella(b, u, avversari, "verso", true)
	b.muovi(u, dest, true, false)

## Bestia: verso il più vicino restando in copertura; esce allo scoperto solo se può entrare in Rissa entro due movimenti.
static func _bestia(b: Battaglia, u: Dictionary, avversari: Array) -> void:
	# resta entro 2" da un alleato attaccando lo stesso bersaglio
	if _prova_rissa(b, u, avversari):
		return
	var v := _vicino(b, u.pos, avversari)
	var due_mosse: bool = Battaglia.dist(u.pos, v.pos) <= (int(u.velocita) + 1) * 2
	var dest := _miglior_cella(b, u, avversari, "verso" if due_mosse else "nascosto", true)
	b.muovi(u, dest, true, false)

## Aggressivo (p.43).
static func _aggressivo(b: Battaglia, u: Dictionary, avversari: Array) -> void:
	var bs := b.bersagli(u)
	var v := _vicino(b, u.pos, avversari)
	var dmin := Battaglia.dist(u.pos, v.pos)
	if _ha_pesante(b, u) and not bs.is_empty():
		_spara_migliore(b, u)
		return
	var vede := false
	for a in avversari:
		if b.vede(u, a):
			vede = true
	if not vede or dmin <= 12:
		# il più velocemente possibile verso il più vicino, cercando la Rissa (non con chi ha Combattimento più alto)
		if _prova_rissa(b, u, avversari, true, true):
			return
		var puo_sparare := not bs.is_empty()
		var dest := _miglior_cella(b, u, avversari, "verso", not puo_sparare)
		b.muovi(u, dest, not puo_sparare and dest != u.pos, false)
		_spara_migliore(b, u)
		return
	# con avversari in vista: avanza di almeno mezzo movimento restando in copertura, poi spara
	var meta: int = max(1, int(u.velocita) / 2)
	var dest := _miglior_cella(b, u, avversari, "avanza", false)
	if Battaglia.dist(dest, u.pos) < meta:
		var d2 := _miglior_cella(b, u, avversari, "verso", false)
		if Battaglia.dist(d2, u.pos) >= meta:
			dest = d2
	b.muovi(u, dest, false, false)
	_spara_migliore(b, u)

## Cauto, Tattico, Difensivo ed equipaggio automatico.
static func _tiratore(b: Battaglia, u: Dictionary, avversari: Array, modo: String) -> void:
	var bs := b.bersagli(u)
	var in_cop := _in_copertura(b, u.pos)
	# Tattici (e equipaggio): Rissa se entro un movimento e con Combattimento più alto
	if modo in ["tattico", "equipaggio"]:
		var forte := false
		for v in avversari:
			if Battaglia.dist(u.pos, v.pos) <= int(u.velocita) + 1 and int(u.combattimento) > int(v.combattimento):
				forte = true
		if forte and _prova_rissa(b, u, avversari, true):
			return
	# Difensivi: Rissa se l'avversario entra nel loro elemento di terreno e hanno Combattimento pari o migliore
	if modo == "difensivo":
		var mio := b.elemento_in(u.pos)
		for v in avversari:
			if not mio.is_empty() and v.pos in mio.celle and int(u.combattimento) >= int(v.combattimento):
				if _prova_rissa(b, u, [v]):
					return
	# con un colpo pulito dalla copertura restano fermi a mirare (i Cauti anche fuori copertura)
	if not bs.is_empty() and (in_cop or modo == "cauto") and int(bs[0].netto) <= 6:
		_spara_migliore(b, u)
		return
	var passi := 99
	if modo == "tattico":
		passi = max(1, int(u.velocita) / 2)
		# attraversano lo scoperto a piena velocità se serve
		if not in_cop:
			passi = 99
	var dest := _miglior_cella(b, u, avversari, modo, false, passi)
	var prima: Vector2i = u.pos
	b.muovi(u, dest, false, false)
	if not _spara_migliore(b, u) and dest == prima and bs.is_empty() and not u.agito:
		# nessun colpo possibile: scatto verso una posizione migliore (copertura o gittata)
		u.mosso = false
		var d2 := _miglior_cella(b, u, avversari, "avanza" if modo != "cauto" else "cauto", true)
		b.muovi(u, d2, true, false)

## Guardiano: resta entro 3" dalla figura protetta, alla stessa andatura, attaccando gli stessi bersagli.
static func _guardiano(b: Battaglia, u: Dictionary, avversari: Array) -> void:
	var protetto := {}
	if int(u.padrone) >= 0:
		protetto = b.per_uid(int(u.padrone))
	if protetto.is_empty() or not protetto.attiva:
		protetto = {}
		for a in b.figure(u.lato):
			if a.uid != u.uid and (a.luogotenente or a.unico):
				protetto = a
	if protetto.is_empty():
		_tiratore(b, u, avversari, "tattico")
		return
	if int(protetto.get("ultimo_bersaglio", -1)) >= 0:
		u["bersaglio_guardia"] = protetto.ultimo_bersaglio
		var bers := b.per_uid(int(protetto.ultimo_bersaglio))
		if not bers.is_empty() and bers.attiva and Battaglia.dist(bers.pos, protetto.pos) <= 3 and _prova_rissa(b, u, [bers]):
			return
	var r := b.raggiungibili(u, false)
	var best: Vector2i = u.pos
	var bp := -999.0
	for p in r:
		if Battaglia.dist(p, protetto.pos) > 3 or b._a_contatto(u, p, avversari):
			continue
		var s := (5.0 if b._vicino_a_terreno(p) else 0.0)
		for v in avversari:
			if b.lds(p, v.pos).vede:
				s += 2.0
		if s > bp:
			bp = s
			best = p
	b.muovi(u, best, false, false)
	_spara_migliore(b, u)

## Corridori delle sabbie: se terminano un movimento entro 3" da un Umano, balzano a contatto (azione gratuita).
static func _balzo(b: Battaglia, u: Dictionary, avversari: Array) -> void:
	var r := int(u.speciali.get("balzo_su_umani", 0))
	if r <= 0 or not u.attiva or u.agito:
		return
	for v in avversari:
		if v.lato == Battaglia.EQ and not v.specie in NON_UMANI and Battaglia.dist(u.pos, v.pos) <= r and Battaglia.dist(u.pos, v.pos) > 1:
			for d in Battaglia._dir8():
				var q: Vector2i = v.pos + d
				if b.calpestabile(q) and b.figura_in(q).is_empty():
					b._sposta(u, q)
					b.scrivi("%s balza su %s!" % [u.nome, v.nome])
					b.rissa(u, v)
					return

## Azioni di obiettivo dell'equipaggio automatico. Restituisce true se ha agito.
static func _obiettivo_equipaggio(b: Battaglia, u: Dictionary) -> bool:
	for a in b.azioni_obiettivo(u):
		if a.id != "esci" and a.id != "luogo":
			b.azione(u, a.id)
			return true
	# cariche del caposaldo: si fanno esplodere quando nessuno dell'equipaggio è vicino al centro
	if b.stato_obj.get("cariche", false) and not b.stato_obj.get("esploso", false):
		if not b.figure(Battaglia.EQ).any(func(w): return Battaglia.dist(w.pos, b.centro) <= 9):
			b.esegui(u, "detona")
	var meta := Vector2i(-1, -1)
	if b.storia == "rapimento":
		for sg in b.stato_obj.get("segnalini_storia", []):
			if not sg.rivelato and (meta.x < 0 or Battaglia.dist(u.pos, sg.pos) < Battaglia.dist(u.pos, meta)):
				meta = sg.pos
	elif b.storia == "stiamo_arrivando" and not b.stato_obj.get("liberato", false):
		var pr := b.per_uid(int(b.stato_obj.get("prigioniero", -1)))
		if not pr.is_empty():
			meta = pr.pos
	elif (b.storia == "sabotare_il_piano" and not b.stato_obj.get("sabotaggio", false)) or (b.obiettivo == "nera:distruggi_caposaldo" and not b.stato_obj.get("cariche", false)):
		meta = b.centro
	if meta.x >= 0 and Battaglia.dist(u.pos, meta) > 1 and (u.porta == "" ):
		var r := b.raggiungibili(u, false)
		var best: Vector2i = u.pos
		for p in r:
			if Battaglia.dist(p, meta) < Battaglia.dist(best, meta) and not b._a_contatto(u, p, b.avversari(u)):
				best = p
		if best != u.pos:
			b.muovi(u, best, false, false)
			for a in b.azioni_obiettivo(u):
				if a.id != "esci":
					b.azione(u, a.id)
					return true
			_spara_migliore(b, u)
			return true
	var serve_centro: bool = (u.porta == "pacco") or (b.obiettivo == "accedere" and not b.stato_obj.get("fatto", false)) or (b.obiettivo == "acquisire" and b.stato_obj.has("oggetto_a"))
	if serve_centro and Battaglia.dist(u.pos, b.centro) > 1:
		var r := b.raggiungibili(u, false)
		var best: Vector2i = u.pos
		var bd := Battaglia.dist(u.pos, b.centro)
		for p in r:
			var d := Battaglia.dist(p, b.centro)
			if d < bd and not b._a_contatto(u, p, b.avversari(u)):
				bd = d
				best = p
		if best != u.pos:
			b.muovi(u, best, false, false)
			for a in b.azioni_obiettivo(u):
				if a.id != "esci":
					b.azione(u, a.id)
					return true
			_spara_migliore(b, u)
			return true
	if u.porta == "oggetto" or ((b.obiettivo == "attraversare" or b.obiettivo == "nera:sfonda_linee") and u.pos.y <= 3):
		var r := b.raggiungibili(u, true)
		var best: Vector2i = u.pos
		for p in r:
			if b._a_contatto(u, p, b.avversari(u)):
				continue
			var verso_nemico: bool = b.obiettivo == "attraversare" or b.obiettivo == "nera:sfonda_linee"
			if (verso_nemico and p.y < best.y) or (not verso_nemico and p.y > best.y):
				best = p
		b.muovi(u, best, true, false)
		for a in b.azioni_obiettivo(u):
			if a.id == "esci" and (not (b.obiettivo == "attraversare" or b.obiettivo == "nera:sfonda_linee") or u.pos.y == 0):
				b.azione(u, "esci")
		return true
	return false

## IA D* («Sabotare il piano»): Difensiva se c'è l'equipaggio entro 12", altrimenti prima raggiunge il centro del campo.
static func _dstar(b: Battaglia, u: Dictionary, avversari: Array) -> void:
	var vicino := false
	for v in avversari:
		if Battaglia.dist(u.pos, v.pos) <= 12:
			vicino = true
	if vicino or u.get("al_centro", false) or Battaglia.dist(u.pos, b.centro) <= 2:
		u["al_centro"] = true
		_tiratore(b, u, avversari, "difensivo")
		return
	var r := b.raggiungibili(u, false)
	var best: Vector2i = u.pos
	for p in r:
		if Battaglia.dist(p, b.centro) < Battaglia.dist(best, b.centro) and not b._a_contatto(u, p, avversari):
			best = p
	b.muovi(u, best, false, false)
	_spara_migliore(b, u)
