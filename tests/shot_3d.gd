extends SceneTree
## Screenshot della mappa 3D e della linea di vista/tiri in 2D (serve un display: xvfb-run).
## xvfb-run godot --path . -s res://tests/shot_3d.gd
## Salva in user://shots/3d_*.png e 2d_vista.png.

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots")
	_run.call_deferred()

func _salva(nome: String) -> void:
	for i in 8:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/%s.png" % nome)
	print("shot ", nome)

func _run() -> void:
	Dati.carica()
	UI.carica_font()
	root.size = Vector2i(1600, 1000)
	var pgs := []
	for i in 6:
		pgs.append({"id": "p%d" % i, "nome": "Prova %d" % i, "specie": ["umano", "bot", "kerin", "swift", "feral", "hulker"][i],
			"reazioni": 1, "velocita": 4, "combattimento": 0, "robustezza": 3, "acume": 0, "fortuna": 0, "xp": 0, "oggetti": [{"id": "fucile_militare"}]})
	for caso in [[3, "frontiera", []], [11, "zona_guerra", ["Zona di guerra"]], [29, "cristalli", ["Cristalli"]]]:
		var b := Battaglia.new(int(caso[0]))
		b.prepara({"tipo": "opportunita", "obiettivo": "accedere", "nemico": "predoni", "numero": 5, "unici": [], "condizione": {}, "luogo": {}},
			pgs, 24, {"eventi_battaglia": false, "tratti_mondo": caso[2]})
		var t = load("res://scripts/ui/tavolo3d.gd").new()
		t.b = b
		t.size = Vector2(1600, 1000)
		root.add_child(t)
		await process_frame
		var u: Dictionary = b.figure(Battaglia.EQ)[0]
		t.selezionata = u.uid
		t.raggiungibili = b.raggiungibili(u, false)
		var nem: Dictionary = b.figure(Battaglia.NEM)[0]
		t.sopra = nem.pos
		t.spara(nem.pos, b.figure(Battaglia.EQ)[2].pos, Battaglia.NEM, 3)
		for i in 10:
			await process_frame
		await _salva("3d_%s" % caso[1])
		t.yaw = 2.3
		t.pitch = deg_to_rad(30)
		t.distanza = 16.0
		t.fuoco = Vector3(b.centro.x, 0, b.centro.y)
		await _salva("3d_%s_vicino" % caso[1])
		t.queue_free()
		await process_frame
	# 2D: linea di vista e colpo in volo
	var b2 := Battaglia.new(3)
	b2.prepara({"tipo": "opportunita", "obiettivo": "accedere", "nemico": "predoni", "numero": 5, "unici": [], "condizione": {}, "luogo": {}}, pgs, 24, {"eventi_battaglia": false})
	var t2 = load("res://scripts/ui/tavolo.gd").new()
	t2.b = b2
	t2.size = Vector2(1000, 1000)
	root.add_child(t2)
	t2._calcola()
	var u2: Dictionary = b2.figure(Battaglia.EQ)[0]
	t2.selezionata = u2.uid
	t2.sopra = b2.figure(Battaglia.NEM)[0].pos
	t2.spara(b2.figure(Battaglia.NEM)[1].pos, b2.figure(Battaglia.EQ)[3].pos, Battaglia.NEM, 3)
	for i in 9:
		await process_frame
	await _salva("2d_vista")
	t2.queue_free()
	# civili neutrali sul campo (2D e 3D)
	var b3 := Battaglia.new(5)
	b3.prepara({"tipo": "opportunita", "obiettivo": "respingere", "nemico": "predoni", "numero": 4, "unici": [], "condizione": {}, "luogo": {},
		"neutrali": ["passante", "bottegaio", "robot_servizio"]}, pgs, 24, {"eventi_battaglia": false})
	var t3 = load("res://scripts/ui/tavolo.gd").new()
	t3.b = b3
	t3.size = Vector2(1000, 1000)
	root.add_child(t3)
	t3._calcola()
	await _salva("2d_neutrali")
	t3.queue_free()
	var t4 = load("res://scripts/ui/tavolo3d.gd").new()
	t4.b = b3
	t4.size = Vector2(1600, 1000)
	root.add_child(t4)
	for i in 10:
		await process_frame
	await _salva("3d_neutrali")
	quit()
