extends SceneTree
## Screenshot automatici dell'interfaccia (serve un display: xvfb-run).
## xvfb-run godot --path . -s res://tests/shot.gd
## Percorre menu, creazione, regole, un turno di campagna e una battaglia (giocata in parte a mano e in parte dall'IA).

var main
var n := 0

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots")
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()

func shot(nome: String) -> void:
	for i in 5:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	n += 1
	img.save_png(OS.get_user_data_dir() + "/shots/%02d_%s.png" % [n, nome])
	print("shot ", nome)

func wait(f := 10) -> void:
	for i in range(f):
		await process_frame

func _run() -> void:
	await wait(10)
	await shot("menu")
	main.mostra_regole()
	await wait(5)
	await shot("regole")
	var rv = main.get_child(main.get_child_count() - 1)
	rv._mostra(Dati.f("regole").capitoli[4])
	await shot("regole_round")
	rv.queue_free()
	main.mostra_creazione()
	await wait(10)
	await shot("creazione")
	var cv = main.vista
	cv._metodo_standard()
	await wait(5)
	cv._inizia()
	await wait(10)
	await shot("campagna_inizio")
	var v = main.vista
	var c: Campagna = main.campagna
	c.inizia_turno()
	v.aggiorna()
	await shot("viaggio")
	c.passo_viaggio(false)
	v.aggiorna()
	await shot("mantenimento")
	c.passo_mantenimento(0, 0)
	v.aggiorna()
	await wait(4)
	await shot("incarichi")
	var ass := {}
	for p in c.vivi():
		ass[p.id] = "trova_patrono" if ass.size() < 2 else "esplorare"
	c.passo_incarichi(ass)
	v.aggiorna()
	await shot("lavori")
	while c.ha_scelte():
		c.risolvi_scelta(0)
	if c.s.offerte.is_empty():
		c.passo_lavori_fine()
	else:
		c.accetta_lavoro(0)
	v.aggiorna()
	await shot("equipaggiamento")
	c.passo_equipaggiamento_fine()
	if c.s.fase == "dicerie":
		c.passo_dicerie()
	v.aggiorna()
	await shot("scelta_battaglia")
	c.s["schierati"] = c.disponibili().map(func(p): return p.id)
	c.prepara_battaglia("opportunita")
	v.aggiorna()
	await shot("battaglia_preparazione")
	v._apri_scheda(c.s.equipaggio[0])
	await wait(4)
	await shot("scheda")
	main.mostra_battaglia()
	await wait(12)
	await shot("battaglia_inizio")
	var bv = main.vista
	var b: Battaglia = bv.b
	if bv.iniziativa_libera:
		bv.iniziativa_libera = false
		bv._reset_iniziativa()
		b.inizia_round()
	bv.aggiorna()
	# seleziona il primo da attivare e mostra le caselle raggiungibili
	var att := b.da_attivare()
	if not att.is_empty():
		bv.sel = att[0]
		bv.aggiorna()
		await shot("battaglia_selezione")
	await bv._automatico()
	await wait(10)
	await shot("battaglia_fine")
	bv._torna()
	await wait(10)
	await shot("dopo_battaglia")
	var v2 = main.vista
	await shot("acquisti")
	c.s.fase = "eventi"
	v2.aggiorna()
	c.passo_eventi()
	v2.aggiorna()
	await shot("eventi")
	quit()
