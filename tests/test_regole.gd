## Prove automatiche delle regole: godot --headless --path . -s tests/test_regole.gd
extends SceneTree

var errori := 0

func ok(cond: bool, msg: String) -> void:
	if not cond:
		errori += 1
		print("ERRORE: ", msg)

func _init() -> void:
	Dati.carica()
	var d := Dadi.new(42)
	# dadi
	for i in 200:
		var v := d.tira("2d6+1")
		ok(v >= 3 and v <= 13, "2d6+1 fuori intervallo: %d" % v)
		var m := d.tira("2d6_max")
		ok(m >= 1 and m <= 6, "2d6_max")
	ok(d.tira("-1d3") <= -1, "-1d3")
	ok(d.tira(5) == 5, "intero")
	# tabelle d100 complete
	for f in ["creazione", "armi", "equipaggiamento", "nave", "bottino", "campagna", "incontri", "post_battaglia", "specie"]:
		_controlla_tabelle(Dati.f(f), f)
	# riferimenti: armi e oggetti citati
	for k in Dati.f("armi").get("tabelle", {}):
		for r in Dati.f("armi").tabelle[k].righe:
			ok(not Dati.arma(str(r.arma)).is_empty(), "arma mancante %s" % r.arma)
	for k in Dati.f("equipaggiamento").get("tabelle", {}):
		for r in Dati.f("equipaggiamento").tabelle[k].righe:
			ok(not Dati.oggetto(str(r.oggetto)).is_empty(), "oggetto mancante %s" % r.oggetto)
	for k in Dati.f("incontri").get("tabelle_nemici", {}):
		for r in Dati.f("incontri").tabelle_nemici[k].righe:
			ok(not Dati.nemico(str(r.nemico)).is_empty(), "nemico mancante %s" % r.nemico)
	# creazione dell'equipaggio
	var c := Campagna.new({}, 7)
	c.nuova({"nome": "Prova", "dimensione": 6})
	var eq := []
	for i in 6:
		eq.append(c.crea_personaggio())
	c.completa_creazione(eq, 0)
	ok(c.s.equipaggio.size() == 6, "equipaggio di 6")
	ok(not c.s.nave.is_empty(), "nave")
	for p in c.s.equipaggio:
		ok(int(p.reazioni) >= 0 and int(p.velocita) >= 3, "profilo %s" % p.nome)
	# soglie per colpire (p.44)
	var b := Battaglia.new(3)
	b.W = 20
	b.H = 20
	b.celle = PackedInt32Array()
	b.celle.resize(400)
	b.celle.fill(Battaglia.T.APERTO)
	var a := b._nuova_figura({"lato": "eq", "nome": "A", "arma": "fucile_militare", "pos": Vector2i(2, 10)})
	var t := b._nuova_figura({"lato": "nem", "nome": "B", "pos": Vector2i(7, 10)})
	b.unita = [a, t]
	ok(b.soglia_colpire(a, t).soglia == 3, "entro 6 allo scoperto = 3+")
	t.pos = Vector2i(15, 10)
	ok(b.soglia_colpire(a, t).soglia == 5, "in gittata allo scoperto = 5+")
	b.set_t(Vector2i(14, 10), Battaglia.T.LINEARE)
	ok(b.soglia_colpire(a, t).soglia == 6, "dietro un muretto = 6+")
	b.set_t(Vector2i(10, 10), Battaglia.T.BLOCCO)
	ok(not b.lds(a.pos, t.pos).vede, "un edificio blocca la vista")
	b.set_t(Vector2i(10, 10), Battaglia.T.APERTO)
	var m := b._nuova_figura({"lato": "eq", "nome": "M", "pos": Vector2i(8, 10)})
	b.unita.append(m)
	ok(not b.lds(a.pos, t.pos).vede, "una figura in mezzo blocca la vista")
	b.unita.erase(m)
	t.pos = Vector2i(2, 4)
	ok(b.soglia_colpire(a, t).soglia == 3, "6 caselle in verticale = entro 6")
	# movimento: velocità 4 = 4 caselle anche in diagonale, terreno difficile costa di più
	a.velocita = 4
	var r := b.raggiungibili(a)
	ok(r.has(Vector2i(6, 14)), "diagonale 4")
	ok(not r.has(Vector2i(7, 10)), "oltre 4")
	ok(b.raggiungibili(a, true).has(Vector2i(8, 10)), "scatto +2")
	# rissa e danni
	var vinti := 0
	for i in 300:
		var x := b._nuova_figura({"lato": "eq", "nome": "X", "pos": Vector2i(5, 5), "arma_m": "lama", "combattimento": 1, "robustezza": 3})
		var y := b._nuova_figura({"lato": "nem", "nome": "Y", "pos": Vector2i(6, 5), "robustezza": 3})
		b.unita = [x, y]
		b.rissa(x, y)
		if not y.attiva:
			vinti += 1
	ok(vinti > 100, "la lama con Combattimento +1 vince spesso: %d" % vinti)
	_prove_regole_battaglia()
	# battaglie automatiche complete
	var vittorie := 0
	for i in 20:
		var c2 := Campagna.new({}, 100 + i)
		c2.nuova({"nome": "Auto %d" % i})
		var e2 := []
		for k in 6:
			e2.append(c2.crea_personaggio())
		c2.completa_creazione(e2, 0)
		c2.inizia_turno()
		var setup := c2.prepara_battaglia("opportunita")
		var bb := Battaglia.new(500 + i)
		bb.prepara(setup, c2.disponibili(), 24)
		var es := bb.gioca_automatica(14)
		ok(es.has("vinto"), "esito")
		if es.vinto:
			vittorie += 1
		c2.dopo_battaglia(es)
		print("Battaglia %d: %s contro %d %s -> %s, round %d, nemici fuori %d, perdite %d" % [i, setup.obiettivo, setup.numero, setup.nemico, "VITTORIA" if es.vinto else "sconfitta", es.round, es.nemici_uccisi, es.perdite.size()])
	print("Vittorie automatiche: %d/20" % vittorie)
	print("PROVE: %s (%d errori)" % ["OK" if errori == 0 else "FALLITE", errori])
	quit(1 if errori > 0 else 0)

## Campo vuoto per le prove.
func _campo(n := 20) -> Battaglia:
	var b := Battaglia.new(11)
	b.W = n
	b.H = n
	b.celle = PackedInt32Array()
	b.celle.resize(n * n)
	b.celle.fill(Battaglia.T.APERTO)
	b.alt = PackedInt32Array()
	b.alt.resize(n * n)
	b.alt.fill(0)
	b.round_n = 1
	return b

func _prove_regole_battaglia() -> void:
	# altezze: dall'alto di un edificio il muretto non dà copertura; salire costa l'altezza
	var b := _campo()
	var a := b._nuova_figura({"lato": "eq", "nome": "A", "arma": "fucile_militare", "armi": ["fucile_militare"], "pos": Vector2i(2, 10), "velocita": 4})
	var t := b._nuova_figura({"lato": "nem", "nome": "T", "pos": Vector2i(14, 10)})
	b.unita = [a, t]
	b.set_t(Vector2i(13, 10), Battaglia.T.LINEARE)
	ok(b.soglia_colpire(a, t).copertura, "muretto vicino al bersaglio: copertura")
	b.set_t(Vector2i(2, 10), Battaglia.T.BLOCCO, 4)
	ok(not b.soglia_colpire(a, t).copertura, "dall'alto il muretto non copre")
	b.set_t(Vector2i(2, 10), Battaglia.T.APERTO)
	b.set_t(Vector2i(3, 10), Battaglia.T.BLOCCO, 2)
	var r := b.raggiungibili(a)
	ok(r.has(Vector2i(3, 10)) and int(r[Vector2i(3, 10)]) == 6, "salire su un blocco alto 2 costa 3 pollici")
	b.set_t(Vector2i(3, 10), Battaglia.T.APERTO)
	# edificio: muro blocca, finestra dà copertura, porta chiusa blocca
	b.set_t(Vector2i(8, 10), Battaglia.T.MURO)
	ok(not b.lds(a.pos, t.pos).vede, "il muro blocca la vista")
	b.set_t(Vector2i(8, 10), Battaglia.T.FINESTRA)
	ok(b.lds(a.pos, t.pos).vede and b.lds(a.pos, t.pos).copertura, "dalla finestra si vede, con copertura")
	b.set_t(Vector2i(8, 10), Battaglia.T.PORTA)
	ok(not b.lds(a.pos, t.pos).vede, "porta chiusa")
	b.porte_aperte[Vector2i(8, 10)] = true
	ok(b.lds(a.pos, t.pos).vede, "porta aperta")
	b.set_t(Vector2i(8, 10), Battaglia.T.APERTO)
	b.set_t(Vector2i(13, 10), Battaglia.T.APERTO)
	# elemento singolo: non blocca, dà copertura
	b.set_t(Vector2i(9, 10), Battaglia.T.SINGOLO)
	ok(b.lds(a.pos, t.pos).vede and b.lds(a.pos, t.pos).copertura, "barile: si vede, copertura")
	b.set_t(Vector2i(9, 10), Battaglia.T.APERTO)
	# le figure amiche si attraversano (Appendice II), le nemiche no
	var amico := b._nuova_figura({"lato": "eq", "nome": "Amico", "pos": Vector2i(3, 10)})
	b.unita.append(amico)
	ok(b.raggiungibili(a).has(Vector2i(4, 10)), "si passa attraverso un amico")
	ok(not b.raggiungibili(a).has(Vector2i(3, 10)), "non ci si ferma su un amico")
	b.unita.erase(amico)
	# dadi delle reazioni: un solo 1 va al Feral
	var c2 := _campo()
	var f1 := c2._nuova_figura({"lato": "eq", "nome": "F", "specie": "feral", "reazioni": 1, "pos": Vector2i(1, 19)})
	var f2 := c2._nuova_figura({"lato": "eq", "nome": "U", "reazioni": 2, "pos": Vector2i(3, 19)})
	c2.unita = [f1, f2]
	c2.dadi_reazione = [1, 5]
	ok(c2.assegna_dadi({f1.uid: 5, f2.uid: 1}) != "", "il singolo 1 deve andare al Feral")
	ok(c2.assegna_dadi({f1.uid: 1, f2.uid: 5}) == "", "assegnazione valida")
	ok(f1.fase == "rapida" and f2.fase == "lenta", "fasi dai dadi")
	# fuoco nel panico: poi l'arma è scarica
	var c3 := _campo()
	var s1 := c3._nuova_figura({"lato": "eq", "nome": "S", "arma": "pistola", "armi": ["pistola"], "pos": Vector2i(5, 10)})
	var n1 := c3._nuova_figura({"lato": "nem", "nome": "N", "pos": Vector2i(8, 10), "robustezza": 6})
	c3.unita = [s1, n1]
	ok(c3.spara(s1, n1, "pistola", false, true), "fuoco nel panico")
	ok("pistola" in s1.scariche and c3.bersagli(s1, "pistola").is_empty(), "arma scarica dopo il panico")
	# Snap Fire: il nemico che si muove in vista subisce il tiro
	var c4 := _campo()
	var w := c4._nuova_figura({"lato": "eq", "nome": "W", "arma": "fucile_militare", "armi": ["fucile_militare"], "pos": Vector2i(10, 18), "fase": "rapida"})
	var m := c4._nuova_figura({"lato": "nem", "nome": "M", "pos": Vector2i(10, 2), "velocita": 6, "robustezza": 6})
	c4.unita = [w, m]
	c4.fase = "rapida"
	c4.attendi(w, "snap")
	c4.fase = "nemici"
	c4.muovi(m, Vector2i(10, 7), false, false)
	ok(w.agito and w.attivato, "Snap Fire eseguito")
	# Bot: non spara ad area con alleati vicini
	var c5 := _campo()
	var bot := c5._nuova_figura({"lato": "eq", "nome": "Bot", "robot": true, "arma": "granata_frakk", "armi": ["granata_frakk"], "pos": Vector2i(5, 10)})
	var al := c5._nuova_figura({"lato": "eq", "nome": "Al", "pos": Vector2i(9, 11)})
	var en := c5._nuova_figura({"lato": "nem", "nome": "En", "pos": Vector2i(9, 10)})
	c5.unita = [bot, al, en]
	ok(not c5.spara(bot, en, "granata_frakk"), "il Bot non rischia gli alleati")
	# rissa contro due avversari e stordimento a 3 segnalini
	var c6 := _campo()
	var x := c6._nuova_figura({"lato": "eq", "nome": "X", "arma_m": "lama", "armi": ["lama"], "combattimento": 2, "robustezza": 6, "pos": Vector2i(5, 5)})
	var y1 := c6._nuova_figura({"lato": "nem", "nome": "Y1", "pos": Vector2i(6, 5), "robustezza": 3})
	var y2 := c6._nuova_figura({"lato": "nem", "nome": "Y2", "pos": Vector2i(6, 6), "robustezza": 3})
	c6.unita = [x, y1, y2]
	ok(c6.rissa(x, y1), "rissa con due avversari")
	ok(c6.adiacenti_nemici(x).is_empty() or not x.attiva, "nessuno resta a contatto")
	var z := c6._nuova_figura({"lato": "nem", "nome": "Z", "pos": Vector2i(15, 15)})
	c6.unita.append(z)
	c6._stordisci(z, 3)
	ok(not z.attiva, "3 segnalini Stordito = fuori combattimento")
	# eventi della battaglia: ognuno si applica senza errori
	var righe: Array = Dati.f("incontri").eventi_battaglia.righe
	for i in righe.size():
		var cc := Campagna.new({}, 300 + i)
		cc.nuova({"nome": "E"})
		var eq := []
		for k in 6:
			eq.append(cc.crea_personaggio())
		cc.completa_creazione(eq, 0)
		cc.inizia_turno()
		var st := cc.prepara_battaglia("opportunita")
		var bb := Battaglia.new(900 + i)
		bb.auto_decisioni = true
		bb.prepara(st, cc.disponibili().slice(0, 5), 24, {"riserve": cc.disponibili().slice(5)})
		bb.inizia_round()
		bb.conferma_reazioni()
		bb._applica_evento(righe[i])
		var es := bb.gioca_automatica(8)
		ok(es.has("vinto"), "evento %s" % righe[i].id)
	# condizioni di schieramento: ognuna si gioca
	for rr in Dati.f("incontri").condizioni_schieramento.opportunita.righe:
		var cc := Campagna.new({}, 77)
		cc.nuova({"nome": "C"})
		var eq := []
		for k in 6:
			eq.append(cc.crea_personaggio())
		cc.completa_creazione(eq, 0)
		cc.inizia_turno()
		var st := cc.prepara_battaglia("opportunita")
		st["condizione"] = rr
		var bb := Battaglia.new(55)
		bb.prepara(st, cc.disponibili(), 24)
		var es := bb.gioca_automatica(10)
		ok(es.has("vinto"), "condizione %s" % rr.id)
	# ogni tipo di nemico combatte senza errori
	for idn in Dati.f("incontri").nemici:
		if str(idn).begins_with("unico_"):
			continue
		var cc := Campagna.new({}, 5)
		cc.nuova({"nome": "N"})
		var eq := []
		for k in 6:
			eq.append(cc.crea_personaggio())
		cc.completa_creazione(eq, 0)
		cc.inizia_turno()
		var st := cc.prepara_battaglia("opportunita")
		st.nemico = idn
		st.unici = ["unico_capo"] if idn == "ganger" else []
		var bb := Battaglia.new(66)
		bb.prepara(st, cc.disponibili(), 24)
		var es := bb.gioca_automatica(10)
		ok(es.has("vinto"), "nemico %s" % idn)
	print("Regole della battaglia: provate")
	_prove_zone_e_storia()
	_prove_voci_speciali()

func _campagna_prova(seme: int) -> Campagna:
	var cc := Campagna.new({}, seme)
	cc.nuova({"nome": "Z", "storia": true})
	var eq := []
	for k in 7:
		eq.append(cc.crea_personaggio())
	cc.completa_creazione(eq, 0)
	cc.inizia_turno()
	return cc

func _gioca(cc: Campagna, setup: Dictionary, seme: int, max_r := 14) -> Dictionary:
	var bb := Battaglia.new(seme)
	var men: Array = setup.get("menomati_pg", [])
	bb.prepara(setup, cc.disponibili().filter(func(p): return not p in men).slice(0, 6), 24)
	var es := bb.gioca_automatica(max_r)
	cc.dopo_battaglia(es)
	return es

func _prove_zone_e_storia() -> void:
	# Zona Rossa: un mondo in Zona Rossa, condizione di minaccia e vincolo di tempo
	for i in 6:
		var cc := _campagna_prova(400 + i)
		cc.s.zona_rossa.licenza = true
		cc.s.mondo["zona_rossa"] = true
		var st := cc.prepara_battaglia("opportunita")
		ok(st.zona_rossa and st.has("minaccia"), "Zona Rossa: minaccia")
		ok(int(st.numero) >= 7, "Zona Rossa: almeno 7 nemici (%d)" % int(st.numero))
		var es := _gioca(cc, st, 410 + i, 12)
		ok(es.has("vinto"), "Zona Rossa giocata")
	# Zona Nera: ogni missione
	for i in 10:
		var cc := _campagna_prova(500 + i)
		cc.accetta_lavoro_nero()
		var st := cc.prepara_battaglia("zona_nera")
		ok(str(st.obiettivo).begins_with("nera:"), "Lavoro Nero")
		var es := _gioca(cc, st, 520 + i, 16)
		ok(es.has("vinto"), "Lavoro Nero %s giocato" % st.obiettivo)
		print("Lavoro Nero %s: %s, round %d, nemici fuori %d" % [st.obiettivo, "vinto" if es.vinto else "fallito", es.round, es.nemici_uccisi])
	# Traccia della Storia: tutti gli eventi in sequenza
	var cs := _campagna_prova(600)
	for n in 7:
		cs.s.storia.evento = n
		cs.s.storia.orologio = 0
		cs.s.storia.erase("richiede_viaggio")
		cs.s.storia["trovato"] = true
		if cs.vivi().size() < 5:
			for k in 3:
				cs.recluta("prova")
		var st := cs.prepara_battaglia_storia()
		var es := _gioca(cs, st, 700 + n, 14)
		ok(es.has("vinto"), "Storia %s" % st.storia)
		print("Storia %s: %s, round %d, nemici fuori %d, indizi %d" % [st.storia, "vinto" if es.vinto else "perso", es.round, es.nemici_uccisi, int(es.get("indizi", 0))])
		cs.fine_turno()
		cs.inizia_turno()
	ok(not cs.s.storia.attiva, "la storia si conclude con il finale")

func _prove_voci_speciali() -> void:
	var nomi := ["Problemi di navigazione", "Nave di pattuglia", "Chiuso di notte nell'archivio dati", "Ordigni", "Occasione per liberarsi di roba",
		"Fai una nuova amicizia", "Possibile affare", "Mercante alieno", "Non ho un problema col gioco d'azzardo!", "Una brutta rissa",
		"Il fisco si interessa a voi", "Dov'è finito?", "Non sei più la stessa persona", "Affari altrove", "Cibo e alcolici di qualità",
		"Merci di scambio", "Pezzi di ricambio", "Mappe locali", "Qualcuno vuole far consegnare un pacco", "Questo posto è proprio carino",
		"Ti offrono un lavoretto", "Ti offrono una ricompensa", "Assicurazione sanitaria", "Una vecchia nemesi vi ha trovato",
		"Un nuovo capo", "Notati da chi era meglio evitare", "È ora di andarsene?", "Rissa con un compagno"]
	for i in nomi.size():
		var cc := _campagna_prova(800 + i)
		cc.s.deposito.append({"id": "pistola"})
		var pg: Dictionary = cc.vivi()[0]
		pg["infermeria"] = 2
		var prima: int = cc.s.diario.size() if cc.s.has("diario") else 0
		cc.applica({"manuale": true}, pg, nomi[i])
		while cc.ha_scelte():
			cc.risolvi_scelta(0)
		var manuale := false
		for r in cc.s.get("diario", []).slice(prima):
			if str(r.get("tipo", "")) == "manuale":
				manuale = true
		ok(not manuale, "voce speciale ancora manuale: " + nomi[i])
		# un viaggio e una battaglia dopo la voce
		cc.passo_viaggio(true)
		var st := cc.prepara_battaglia("opportunita")
		_gioca(cc, st, 850 + i, 10)
		cc.fine_turno()
	print("Voci speciali della campagna: provate")

func _controlla_tabelle(x, nome: String) -> void:
	if x is Dictionary:
		if x.has("righe") and x.get("_dado", "") == "d100":
			var cop := []
			cop.resize(101)
			cop.fill(0)
			for r in x.righe:
				for v in range(int(r.get("da", 0)), int(r.get("a", 0)) + 1):
					if v >= 1 and v <= 100:
						cop[v] += 1
			for v in range(1, 101):
				if cop[v] != 1:
					ok(false, "tabella d100 in %s: valore %d coperto %d volte" % [nome, v, cop[v]])
					break
		for k in x:
			_controlla_tabelle(x[k], nome + "." + str(k))
	elif x is Array:
		for v in x:
			_controlla_tabelle(v, nome)
