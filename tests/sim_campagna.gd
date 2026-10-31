## Campagne automatiche complete: godot --headless --path . -s tests/sim_campagna.gd
extends SceneTree

func _init() -> void:
	Dati.carica()
	var tot_turni := 0
	for k in 6:
		var c := Campagna.new({}, 1000 + k)
		c.nuova({"nome": "Sim %d" % k, "difficolta": ["normale", "facile", "impegnativo", "hardcore", "normale", "follia"][k], "storia": k % 2 == 0})
		var eq := []
		for i in 6:
			eq.append(c.crea_personaggio())
		c.completa_creazione(eq, 0)
		for t in 15:
			if c.finita():
				break
			gioca_turno(c)
			tot_turni += 1
		# salvataggio e ripresa
		var js := JSON.stringify(c.salva())
		var c2 := Campagna.new(JSON.parse_string(js))
		gioca_turno(c2)
		print("Campagna %d (%s): turno %d, vivi %d, crediti %d, PS %d, rivali %d, patroni %d, battaglie %d/%d, morti %d, deposito %d" % [k, c.s.difficolta, c2.s.turno, c2.vivi().size(), c2.s.crediti, c2.s.punti_storia, c2.s.rivali.size(), c2.s.patroni.size(), c2.s.statistiche.vittorie, c2.s.statistiche.battaglie, c2.s.statistiche.morti, c2.s.deposito.size()])
	var manuali := 0
	print("Turni giocati: %d" % tot_turni)
	quit(0)

func scelte(c: Campagna) -> void:
	while c.ha_scelte():
		c.risolvi_scelta(c.dadi.d(2) - 1)

func gioca_turno(c: Campagna) -> void:
	c.inizia_turno()
	if int(c.s.turno) >= 6 and not c.s.zona_rossa.get("licenza", false):
		c.s.zona_rossa.licenza = true
		c.s.zona_rossa["turni"] = 8
	c.passo_viaggio(c.dadi.d6() >= 5 or c.s.mondo.get("invasione_imminente", false), c.dadi.d6() >= 4)
	scelte(c)
	if c.s.fase == "mantenimento":
		c.passo_mantenimento(c.dadi.d(3), 1)
		var ass := {}
		for p in c.vivi():
			ass[p.id] = c.dadi.scegli(Campagna.INCARICHI)
		c.passo_incarichi(ass, {"crediti_patrono": 0})
		scelte(c)
		if not c.s.offerte.is_empty():
			c.accetta_lavoro(0)
		else:
			c.passo_lavori_fine()
	c.distribuisci_automatico()
	c.passo_equipaggiamento_fine()
	if c.s.fase == "dicerie":
		c.passo_dicerie()
	var riv := c.controllo_rivali()
	var setup := {}
	if not c.evento_storia_pronto().is_empty():
		setup = c.prepara_battaglia_storia()
	elif not riv.is_empty():
		setup = c.prepara_battaglia("rivale", {"rivale": riv.id})
	else:
		var ops := c.opzioni_battaglia()
		var o: Dictionary = ops[c.dadi.d(max(1, ops.size() - 1)) - 1]
		if o.tipo == "zona_nera":
			c.accetta_lavoro_nero()
		setup = c.prepara_battaglia(o.tipo, o)
	var b := Battaglia.new(c.dadi.d(99999))
	var pgs := c.disponibili().slice(0, c.s.dimensione)
	if pgs.is_empty():
		c.s.fase = "acquisti"
	else:
		var men: Array = setup.get("menomati_pg", [])
		b.prepara(setup, pgs.filter(func(p): return not p in men), 24)
		var es := b.gioca_automatica(12)
		c.dopo_battaglia(es)
	scelte(c)
	for p in c.vivi():
		for st in c.miglioramenti_possibili(p):
			c.migliora(p, st)
			break
	if c.s.crediti > 8:
		c.compra("arma_militare")
	c.distribuisci_automatico()
	c.passo_eventi()
	scelte(c)
	c.fine_turno()
