extends SceneTree
## Screenshot degli effetti: granata ed esplosione, nebbia, polvere, gas e buio, in 2D e 3D (serve xvfb-run).
## xvfb-run godot --path . -s res://tests/shot_effetti.gd  -> user://shots/eff_*.png

const CASI := [["Nessuna condizione", "granata"], ["Scarsa visibilità", "polvere"], ["Ambiente tossico", "gas"], ["Buio", "buio"]]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots")
	_run.call_deferred()

func _salva(nome: String) -> void:
	root.get_viewport().get_texture().get_image().save_png(OS.get_user_data_dir() + "/shots/eff_%s.png" % nome)
	print("shot ", nome)

func _run() -> void:
	Dati.carica()
	UI.carica_font()
	root.size = Vector2i(1600, 1000)
	var pgs := []
	for i in 6:
		pgs.append({"id": "p%d" % i, "nome": "Prova %d" % i, "specie": "umano", "reazioni": 1, "velocita": 4, "combattimento": 0,
			"robustezza": 3, "acume": 0, "fortuna": 0, "xp": 0, "oggetti": [{"id": "fucile_militare"}]})
	for tre_d in [false, true]:
		for caso in CASI:
			var b := Battaglia.new(7)
			b.prepara({"tipo": "opportunita", "obiettivo": "respingere", "nemico": "predoni", "numero": 5, "unici": [],
				"condizione": {"nome": caso[0], "effetti": {}}, "luogo": {}}, pgs, 24, {"eventi_battaglia": false})
			var t = load("res://scripts/ui/tavolo3d.gd" if tre_d else "res://scripts/ui/tavolo.gd").new()
			t.b = b
			t.size = Vector2(1600, 1000) if tre_d else Vector2(1000, 1000)
			root.add_child(t)
			if not tre_d:
				t._calcola()
			for f in 15:
				await process_frame
			var da: Vector2i = b.figure(Battaglia.EQ)[0].pos
			var a: Vector2i = b.figure(Battaglia.NEM)[0].pos
			t.spara(da, a, Battaglia.EQ, 1, "granata")
			t.esplosione(a, 2, "frammenti", Tavolo2D.VOLO_GRANATA)
			# tempi dell'animazione fissati a mano: la cattura non dipende dalla velocità della macchina
			t.colpi[0].t = 0.3
			await process_frame
			await process_frame
			_salva("%s_%s_volo" % ["3d" if tre_d else "2d", caso[1]])
			for c in t.colpi:
				c.t = 99.0
			t.esplosioni[0].t = 0.12
			await process_frame
			await process_frame
			_salva("%s_%s" % ["3d" if tre_d else "2d", caso[1]])
			t.queue_free()
			await process_frame
	quit()
