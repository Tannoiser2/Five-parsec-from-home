## Menu principale: nuova campagna, campagne salvate, campagna dal cloud, regole.
extends Control

var main

func _ready() -> void:
	var col := UI.vbox(14)
	col.position = Vector2(110, 110)
	col.custom_minimum_size = Vector2(760, 0)
	add_child(col)
	col.add_child(UI.etichetta("FIVE PARSECS", 92, UI.AMBRA, true))
	col.add_child(UI.etichetta("FROM HOME", 54, UI.TESTO, true))
	col.add_child(UI.etichetta("Avventure in solitario sulla Frontiera - di Ivan Sorensen (Modiphius), terza edizione. Versione digitale per la ludoteca.", 20, UI.TENUE))
	col.add_child(Control.new())
	var b1 := UI.bottone("NUOVA CAMPAGNA", func(): main.mostra_creazione())
	b1.custom_minimum_size = Vector2(420, 58)
	b1.add_theme_font_size_override("font_size", 24)
	col.add_child(b1)
	var b3 := UI.bottone("REGOLE IN ITALIANO", func(): main.mostra_regole())
	b3.custom_minimum_size = Vector2(420, 50)
	col.add_child(b3)
	# campagne locali
	var el := Salvataggi.elenco_locale()
	if not el.is_empty():
		col.add_child(UI.titolo("Campagne salvate", 24))
		var lista := UI.vbox(6)
		for e in el.slice(0, 6):
			var h := UI.hbox()
			var b := UI.bottone("%s  -  turno %d, %d membri" % [e.nome, e.turno, e.vivi], _carica_locale.bind(e.codice))
			b.custom_minimum_size = Vector2(560, 44)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			h.add_child(b)
			h.add_child(UI.etichetta("codice " + str(e.codice), 16, UI.TENUE))
			lista.add_child(h)
		col.add_child(lista)
	# cloud
	col.add_child(UI.titolo("Campagna dal cloud", 24))
	var h2 := UI.hbox()
	var codice := LineEdit.new()
	codice.placeholder_text = "Codice (6 lettere)"
	codice.max_length = 6
	codice.custom_minimum_size = Vector2(260, 44)
	h2.add_child(codice)
	h2.add_child(UI.bottone("Apri", func(): _carica_cloud(codice.text.strip_edges().to_upper())))
	col.add_child(h2)
	col.add_child(UI.etichetta("Ogni campagna ha un codice: salvandola nel cloud la si riapre da qualsiasi dispositivo.", 16, UI.TENUE))
	var piede := UI.etichetta("F11: schermo intero.  Five Parsecs from Home è un gioco di Ivan Sorensen pubblicato da Modiphius Entertainment: questa è una conversione per uso personale.", 15, UI.TENUE)
	piede.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	piede.offset_left = 110
	piede.offset_top = -56
	piede.offset_right = -110
	add_child(piede)

func _carica_locale(codice: String) -> void:
	var st := Salvataggi.carica_locale(codice)
	if st.is_empty():
		main.mostra_avviso("Salvataggio non leggibile.")
		return
	main.mostra_campagna(Campagna.new(st))

func _carica_cloud(codice: String) -> void:
	if codice.length() != 6:
		main.mostra_avviso("Il codice ha 6 lettere.")
		return
	main.mostra_avviso("Caricamento dal cloud...")
	var st: Dictionary = await main.net.carica_campagna(codice)
	if st.is_empty():
		main.mostra_avviso("Campagna non trovata: " + main.net.last_error, 5.0)
		return
	Salvataggi.salva_locale(st)
	main.mostra_campagna(Campagna.new(st))
