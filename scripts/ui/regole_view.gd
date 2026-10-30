## Regole in italiano consultabili: indice dei capitoli a sinistra, testo a destra.
extends Control

var testo: RichTextLabel

func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.7)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.stile(UI.PANNELLO, UI.AMBRA, 2, 8, 16))
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 80
	p.offset_top = 50
	p.offset_right = -80
	p.offset_bottom = -50
	add_child(p)
	var h := UI.hbox(16)
	p.add_child(h)
	var indice := UI.vbox(6)
	indice.custom_minimum_size.x = 380
	h.add_child(indice)
	indice.add_child(UI.titolo("Regole", 30))
	var caps: Array = Dati.f("regole").get("capitoli", [])
	for cap in caps:
		var b := UI.bottone(str(cap.titolo), func(): _mostra(cap))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		indice.add_child(b)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	indice.add_child(sp)
	indice.add_child(UI.bottone("Chiudi", func(): queue_free()))
	testo = RichTextLabel.new()
	testo.bbcode_enabled = true
	testo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	testo.add_theme_font_size_override("normal_font_size", 19)
	testo.add_theme_font_size_override("bold_font_size", 21)
	h.add_child(testo)
	if not caps.is_empty():
		_mostra(caps[0])

func _pulito(s: String) -> String:
	return s.replace("[", "(").replace("]", ")")

func _mostra(cap: Dictionary) -> void:
	var t := "[b][color=#f2ad48]%s[/color][/b]\n\n" % str(cap.titolo).to_upper()
	if cap.has("testo"):
		t += _pulito(str(cap.testo))
	match str(cap.get("genera", "")):
		"comportamenti_ia":
			for k in Dati.f("incontri").get("comportamenti_ia", {}):
				var v = Dati.f("incontri").comportamenti_ia[k]
				if k.begins_with("_") or not (v is Dictionary) or not v.has("testo"):
					continue
				t += "[b]%s[/b] (%s)\n%s\n\n" % [v.nome, v.get("en", ""), _pulito(str(v.testo))]
		"obiettivi":
			for k in Dati.f("incontri").get("tipi_obiettivo", {}):
				var v = Dati.f("incontri").tipi_obiettivo[k]
				if k.begins_with("_"):
					continue
				t += "[b]%s[/b] (%s)\n%s\n\n" % [v.nome, v.get("en", ""), _pulito(str(v.testo))]
		"armi":
			t += "[b]Tratti[/b]\n"
			for k in Dati.f("armi").get("tratti", {}):
				t += "- %s\n" % _pulito(str(Dati.f("armi").tratti[k]))
			t += "\n[b]Armi[/b] (gittata in caselle, colpi, danno)\n"
			for k in Dati.f("armi").get("armi", {}):
				var a: Dictionary = Dati.arma(k)
				if a.get("solo_nemici", false):
					continue
				var g := "rissa" if int(a.get("gittata", 0)) == 0 else "%d" % int(a.gittata)
				t += "- %s (%s): %s, %d, %+d  %s\n" % [a.nome, a.get("en", ""), g, int(a.get("colpi", 0)), int(a.get("danno", 0)), ", ".join(a.get("tratti", []))]
		"nemici":
			var per_cat := {}
			for k in Dati.f("incontri").get("nemici", {}):
				var n: Dictionary = Dati.nemico(k)
				var cat := str(n.get("categoria", ""))
				if not per_cat.has(cat):
					per_cat[cat] = []
				per_cat[cat].append(n)
			for cat in per_cat:
				t += "[b][color=#9fd0d2]%s[/color][/b]\n" % cat.replace("_", " ").capitalize()
				for n in per_cat[cat]:
					t += "[b]%s[/b] (%s) - Vel %s, Comb %s, Rob %s, IA %s, Panico %s. %s\n" % [n.nome, n.get("en", ""), str(n.get("velocita", "-")), str(n.get("combattimento", "-")), str(n.get("robustezza", "-")), str(n.get("ia", "-")), str(n.get("panico", [])), _pulito(str(n.get("regole", "")))]
				t += "\n"
		"storia":
			var st: Dictionary = Dati.f("storia")
			for k in st.get("regole", {}):
				var v = st.regole[k]
				if v is String:
					t += _pulito(v) + "\n\n"
				elif v is Dictionary and v.has("testo"):
					t += _pulito(str(v.testo)) + "\n\n"
			for ev in st.get("eventi", []):
				t += "[b]%s[/b]\n%s\n\n" % [ev.get("nome", ""), _pulito(str(ev.get("testo", ev.get("riassunto", ""))))]
		"zone":
			var z: Dictionary = Dati.f("zone")
			for sez in ["requisiti", "red_zone", "black_zone"]:
				var v = z.get(sez, {})
				t += "[b]%s[/b]\n" % sez.replace("_", " ").capitalize()
				if v is Dictionary:
					for k in v:
						if v[k] is String and not k.begins_with("_"):
							t += _pulito(str(v[k])) + "\n"
						elif v[k] is Dictionary and v[k].has("testo"):
							t += _pulito(str(v[k].testo)) + "\n"
				t += "\n"
	testo.text = t
	testo.scroll_to_line(0)
