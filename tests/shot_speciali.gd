extends SceneTree
## Screenshot delle battaglie speciali (Zona Nera e Traccia della Storia). xvfb-run godot --path . -s res://tests/shot_speciali.gd

var main

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots")
	main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()

func wait(f := 10) -> void:
	for i in range(f):
		await process_frame

func shot(nome: String) -> void:
	await wait(6)
	root.get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/sp_%s.png" % nome)
	print("shot ", nome)

func _campagna(seme: int) -> Campagna:
	var c := Campagna.new({}, seme)
	c.nuova({"nome": "Prova", "storia": true})
	var eq := []
	for k in 6:
		eq.append(c.crea_personaggio())
	c.completa_creazione(eq, 0)
	c.inizia_turno()
	return c

func _run() -> void:
	await wait(10)
	var casi := [["zona_nera", -1], ["storia", 4], ["storia", 5], ["storia", 6]]
	for caso in casi:
		var c := _campagna(31)
		main.campagna = c
		c.s["schierati"] = c.disponibili().map(func(p): return p.id)
		if caso[0] == "zona_nera":
			c.accetta_lavoro_nero()
			c.prepara_battaglia("zona_nera")
		else:
			c.s.storia.evento = caso[1]
			c.s.storia.orologio = 0
			c.s.storia["trovato"] = true
			c.prepara_battaglia_storia()
		main.mostra_battaglia()
		await wait(12)
		var bv = main.vista
		var b: Battaglia = bv.b
		if bv.iniziativa_libera:
			bv.iniziativa_libera = false
			bv._reset_iniziativa()
			b.inizia_round()
		b.conferma_reazioni()
		bv._prossimo()
		await shot("%s_%d" % [caso[0], caso[1]])
	quit()
