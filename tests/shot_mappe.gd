extends SceneTree
## Screenshot del campo di battaglia in ogni ambiente grafico (serve un display: xvfb-run).
## xvfb-run godot --path . -s res://tests/shot_mappe.gd
## Salva in user://shots/mappa_<ambiente>.png; la condizione di schieramento cambia per mostrare le sovrapposizioni.

const CASI := [
	["frontiera", [], "Nessuna condizione", "pattugliare"],
	["arido", ["Arido"], "Scarsa visibilità", "perquisire"],
	["ghiacciato", ["Ghiacciato"], "Nessuna condizione", "accedere"],
	["rigoglioso", ["Vegetazione rigogliosa"], "Ambiente tossico", "consegnare"],
	["cristalli", ["Cristalli"], "Buio", "acquisire"],
	["zona_guerra", ["Zona di guerra"], "Nessuna condizione", "respingere"],
	["urbano", [], "Nessuna condizione", "assalto"],
]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir() + "/shots")
	_run.call_deferred()

func _run() -> void:
	Dati.carica()
	var pgs := []
	for i in 6:
		pgs.append({"id": "p%d" % i, "nome": "Prova %d" % i, "specie": ["umano", "bot", "kerin", "swift", "feral", "hulker"][i],
			"reazioni": 1, "velocita": 4, "combattimento": 0, "robustezza": 3, "acume": 0, "fortuna": 0, "xp": 0, "oggetti": [{"id": "fucile_militare"}]})
	for i in CASI.size():
		var caso: Array = CASI[i]
		var b := Battaglia.new(1000 + i * 17)
		var setup := {"tipo": "opportunita", "obiettivo": caso[3], "nemico": "ganger", "numero": 5, "unici": [],
			"condizione": {"nome": caso[2], "effetti": {}}, "luogo": {}}
		b.prepara(setup, pgs, 24, {"eventi_battaglia": false, "tratti_mondo": caso[1]})
		if b.ambiente != caso[0]:
			push_error("ambiente atteso %s, ottenuto %s" % [caso[0], b.ambiente])
		var t = load("res://scripts/ui/tavolo.gd").new()
		t.b = b
		t.size = Vector2(1080, 1080)
		root.add_child(t)
		t._calcola()
		for f in 6:
			await process_frame
		var img := root.get_viewport().get_texture().get_image()
		img.crop(1080, 1080)
		img.save_png(OS.get_user_data_dir() + "/shots/mappa_%s.png" % caso[0])
		print("mappa ", caso[0], ": ", b.elementi.map(func(e): return e.nome))
		t.queue_free()
		await process_frame
	quit()
