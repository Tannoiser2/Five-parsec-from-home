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
