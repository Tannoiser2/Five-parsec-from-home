## Creazione dell'equipaggio: opzioni della campagna, specie, background, motivazione e classe tirati o scelti, capo e nave.
extends Control

var main
var anteprima := Campagna.new()
var slot := []         # [{specie, nome, background, motivazione, classe}]
var opzioni := {"nome": "", "dimensione": 6, "difficolta": "normale", "storia": false, "eventi_battaglia": true, "tavolo": 24}
var capo := 0
var nave := -1
var lista: VBoxContainer
var nome_eq: LineEdit
var info: RichTextLabel

const DIFF := ["facile", "normale", "impegnativo", "hardcore", "follia"]
const NOMI_DIFF := ["Facile", "Normale", "Impegnativa", "Hardcore", "Follia"]

func _ready() -> void:
	anteprima.nuova({})
	var radice := UI.hbox(16)
	radice.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.offset_left = 24
	radice.offset_top = 20
	radice.offset_right = -24
	radice.offset_bottom = -20
	add_child(radice)
	# colonna sinistra: opzioni
	var sx := UI.vbox(10)
	sx.custom_minimum_size = Vector2(430, 0)
	var ps := UI.pannello(sx)
	radice.add_child(ps)
	sx.add_child(UI.titolo("Nuova campagna", 30))
	sx.add_child(UI.etichetta("Nome dell'equipaggio", 18, UI.TENUE))
	nome_eq = LineEdit.new()
	nome_eq.text = _nome_casuale_equipaggio()
	sx.add_child(nome_eq)
	sx.add_child(_scelta("Dimensione dell'equipaggio", ["6 (standard)", "5", "4"], 0, func(i): opzioni.dimensione = [6, 5, 4][i]; _ricrea_slot()))
	sx.add_child(_scelta("Difficoltà", NOMI_DIFF, 1, func(i): opzioni.difficolta = DIFF[i]))
	sx.add_child(_scelta("Tavolo di battaglia", ["2 x 2 piedi (24 caselle)", "2,5 x 2,5 piedi (30 caselle)", "3 x 3 piedi (36 caselle)"], 0, func(i): opzioni.tavolo = [24, 30, 36][i]))
	var navi: Array = Dati.f("nave").get("navi", {}).get("righe", [])
	var nomi_navi := ["Tira a caso"]
	for n in navi:
		nomi_navi.append("%s (Scafo %d)" % [n.nome, int(n.scafo)])
	sx.add_child(_scelta("Astronave", nomi_navi, 0, func(i): nave = i - 1))
	var cb1 := CheckBox.new()
	cb1.text = "Traccia della Storia (Appendice V)"
	cb1.toggled.connect(func(v): opzioni.storia = v)
	sx.add_child(cb1)
	var cb2 := CheckBox.new()
	cb2.text = "Eventi della battaglia (facoltativi)"
	cb2.button_pressed = true
	cb2.toggled.connect(func(v): opzioni.eventi_battaglia = v)
	sx.add_child(cb2)
	sx.add_child(HSeparator.new())
	sx.add_child(UI.bottone("Tira tutto l'equipaggio", _tira_tutti))
	sx.add_child(UI.bottone("Metodo standard: 3 Umani, 2 Umani o Alieni, 1 Umano o Bot", _metodo_standard))
	sx.add_child(UI.bottone("Solo Umani (metodo per principianti)", _solo_umani))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sx.add_child(sp)
	info = UI.testo_ricco("", 16)
	sx.add_child(info)
	var bi := UI.bottone("INIZIA LA CAMPAGNA", _inizia)
	bi.custom_minimum_size.y = 56
	bi.add_theme_font_size_override("font_size", 24)
	sx.add_child(bi)
	sx.add_child(UI.bottone("Torna al menu", func(): main.mostra_menu()))
	# colonna destra: equipaggio
	var dx := UI.vbox(8)
	dx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	radice.add_child(dx)
	dx.add_child(UI.titolo("Equipaggio", 30))
	dx.add_child(UI.etichetta("Per ogni membro puoi tirare o scegliere specie, background, motivazione e classe. I crediti, i punti Storia, i Patroni, i Rivali e l'equipaggiamento dei risultati si ottengono all'inizio della campagna.", 17, UI.TENUE))
	lista = UI.vbox(8)
	dx.add_child(UI.scorrimento(lista))
	dx.get_child(2).size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ricrea_slot()
	_tira_tutti()

func _nome_casuale_equipaggio() -> String:
	var a := ["Corvi", "Lame", "Lupi", "Spettri", "Cani", "Falchi", "Ombre", "Vagabondi", "Randagi", "Segugi"]
	var b := ["di Rashor", "del Vuoto", "della Frontiera", "di Kessel", "Erranti", "Senza Bandiera", "del Margine", "di Ferro"]
	return "%s %s" % [a[randi() % a.size()], b[randi() % b.size()]]

func _scelta(etichetta: String, voci: Array, sel: int, cb: Callable) -> Control:
	var v := UI.vbox(2)
	v.add_child(UI.etichetta(etichetta, 17, UI.TENUE))
	var o := OptionButton.new()
	for x in voci:
		o.add_item(str(x))
	o.select(sel)
	o.item_selected.connect(cb)
	o.fit_to_longest_item = false
	v.add_child(o)
	return v

func _ricrea_slot() -> void:
	var n := int(opzioni.dimensione)
	while slot.size() < n:
		slot.append({"specie": "umano", "nome": anteprima.nome_casuale(slot.map(func(x): return x.nome)), "background": -1, "motivazione": -1, "classe": -1})
	slot.resize(n)
	capo = min(capo, n - 1)
	_aggiorna()

func _indice_casuale(quale: String) -> int:
	var righe: Array = Dati.f("creazione").get(quale, {}).get("righe", [])
	var r := anteprima.dadi.su_tabella(Dati.f("creazione").get(quale, {}))
	return righe.find(r.riga)

func _tira_slot(i: int, specie := "") -> void:
	var s: Dictionary = slot[i]
	s.specie = specie if specie != "" else anteprima.tira_specie()
	for q in ["background", "motivazione", "classe"]:
		s[q] = _indice_casuale(q)

func _tira_tutti() -> void:
	for i in slot.size():
		_tira_slot(i)
	_aggiorna()

func _metodo_standard() -> void:
	var tipi := ["umano", "umano", "umano"]
	var prim := ["engineer", "kerin", "soulless", "precursor", "feral", "swift"]
	tipi.append("umano" if randf() < 0.4 else prim[randi() % prim.size()])
	tipi.append("umano" if randf() < 0.4 else prim[randi() % prim.size()])
	tipi.append("bot" if randf() < 0.5 else "umano")
	for i in slot.size():
		_tira_slot(i, tipi[i % tipi.size()])
	_aggiorna()

func _solo_umani() -> void:
	for i in slot.size():
		_tira_slot(i, "umano")
	_aggiorna()

func _aggiorna() -> void:
	UI.svuota(lista)
	var specie_ids: Array = Dati.f("specie").get("specie", {}).keys()
	for i in slot.size():
		var s: Dictionary = slot[i]
		var pg := anteprima.crea_personaggio(s.specie, s.nome, {"background": s.background, "motivazione": s.motivazione, "classe": s.classe}, false)
		var riga := UI.hbox(10)
		var pc := UI.pannello(riga, UI.PANNELLO_2 if i != capo else Color(0.16, 0.13, 0.08), UI.AMBRA if i == capo else UI.BORDO.darkened(0.5))
		lista.add_child(pc)
		var ped = preload("res://scripts/ui/pedina_control.gd").new()
		ped.chiave = str(Dati.specie(s.specie).get("pedina", s.specie))
		ped.nome = s.nome
		ped.custom_minimum_size = Vector2(84, 84)
		riga.add_child(ped)
		var c := UI.vbox(4)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		riga.add_child(c)
		var h := UI.hbox()
		var ne := LineEdit.new()
		ne.text = s.nome
		ne.custom_minimum_size.x = 200
		ne.text_changed.connect(func(t): s.nome = t)
		h.add_child(ne)
		var os := OptionButton.new()
		for k in specie_ids:
			os.add_item(str(Dati.specie(k).get("nome", k)))
		os.select(specie_ids.find(s.specie))
		os.item_selected.connect(func(j): s.specie = specie_ids[j]; _aggiorna())
		h.add_child(os)
		h.add_child(UI.bottone("Tira", func(): _tira_slot(i); _aggiorna(), "Tira di nuovo specie e tabelle"))
		h.add_child(UI.bottone("Capo" if i != capo else "CAPO", func(): capo = i; _aggiorna(), "Il Capo riceve +1 Fortuna"))
		c.add_child(h)
		var h2 := UI.hbox(6)
		if Personaggio.usa_tabelle(pg):
			for q in ["background", "motivazione", "classe"]:
				h2.add_child(_tendina(s, q))
		else:
			h2.add_child(UI.etichetta("Profilo base senza tabelle di creazione.", 16, UI.TENUE))
		c.add_child(h2)
		c.add_child(UI.etichetta(Personaggio.profilo(pg), 17, UI.ACQUA))
		var reg := str(Personaggio.info_specie(pg).get("regole", ""))
		c.add_child(UI.etichetta(reg.substr(0, 240) + ("..." if reg.length() > 240 else ""), 15, UI.TENUE))
	_info_risorse()

func _tendina(s: Dictionary, q: String) -> Control:
	var righe: Array = Dati.f("creazione").get(q, {}).get("righe", [])
	var o := OptionButton.new()
	o.custom_minimum_size.x = 250
	o.clip_text = true
	for r in righe:
		o.add_item(str(r.nome))
		o.set_item_tooltip(o.item_count - 1, str(r.get("testo", "")))
	if int(s[q]) >= 0:
		o.select(int(s[q]))
	o.tooltip_text = str(righe[int(s[q])].get("testo", "")) if int(s[q]) >= 0 and int(s[q]) < righe.size() else ""
	o.item_selected.connect(func(j): s[q] = j; _aggiorna())
	return o

func _info_risorse() -> void:
	var t := "[b]Dai risultati delle tabelle:[/b] "
	var cr := []
	var altri := {"punti_storia": 0, "patrono": 0, "rivale": 0, "dicerie": 0}
	var ogg := 0
	for s in slot:
		for q in ["background", "motivazione", "classe"]:
			var righe: Array = Dati.f("creazione").get(q, {}).get("righe", [])
			if int(s[q]) < 0 or int(s[q]) >= righe.size():
				continue
			var e: Dictionary = righe[int(s[q])].get("effetti", {})
			if e.has("crediti"):
				cr.append(str(e.crediti))
			for k in altri:
				altri[k] += int(e.get(k, 0))
			ogg += e.get("oggetti", []).size()
	t += "crediti %s; punti Storia +%d; Patroni %d; Rivali %d; Dicerie %d; oggetti %d (più 8 tiri di equipaggiamento iniziale)." % [
		"+".join(cr) if not cr.is_empty() else "0", altri.punti_storia, altri.patrono, altri.rivale, altri.dicerie, ogg]
	info.text = t

func _inizia() -> void:
	opzioni.nome = nome_eq.text.strip_edges() if nome_eq.text.strip_edges() != "" else "Equipaggio senza nome"
	var c := Campagna.new()
	c.nuova(opzioni)
	var eq := []
	for s in slot:
		eq.append(c.crea_personaggio(s.specie, s.nome, {"background": s.background, "motivazione": s.motivazione, "classe": s.classe}, true))
	c.completa_creazione(eq, capo, nave)
	main.campagna = c
	Salvataggi.salva_locale(c.salva())
	main.mostra_campagna(c)
