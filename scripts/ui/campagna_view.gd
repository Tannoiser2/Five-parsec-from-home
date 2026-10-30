## Vista della campagna: equipaggio a sinistra, passo del turno al centro, diario e schede a destra.
extends Control

var main
var c: Campagna
var barra: HBoxContainer
var colonna_eq: VBoxContainer
var centro: VBoxContainer
var diario: RichTextLabel
var schede: TabContainer
var scelta_popup: PopupPanel
var rivali_controllati := false
var rivale_attacca := {}
var schierati := {}

func _ready() -> void:
	var radice := UI.vbox(10)
	radice.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.offset_left = 16
	radice.offset_top = 12
	radice.offset_right = -16
	radice.offset_bottom = -12
	add_child(radice)
	barra = UI.hbox(18)
	radice.add_child(UI.pannello(barra))
	var corpo := UI.hbox(12)
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	radice.add_child(corpo)
	colonna_eq = UI.vbox(6)
	var sc := UI.scorrimento(colonna_eq)
	var pe := UI.pannello(sc)
	pe.custom_minimum_size.x = 400
	corpo.add_child(pe)
	centro = UI.vbox(10)
	var scc := UI.scorrimento(centro)
	var pc := UI.pannello(scc)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	corpo.add_child(pc)
	schede = TabContainer.new()
	schede.custom_minimum_size.x = 560
	corpo.add_child(schede)
	diario = RichTextLabel.new()
	diario.bbcode_enabled = true
	diario.scroll_following = true
	diario.name = "Diario"
	diario.add_theme_font_size_override("normal_font_size", 17)
	diario.add_theme_font_size_override("bold_font_size", 18)
	schede.add_child(diario)
	for n in ["Nave", "Deposito", "Contatti", "Mondo"]:
		var s := ScrollContainer.new()
		s.name = n
		s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var v := UI.vbox(6)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.add_child(v)
		schede.add_child(s)
	aggiorna()

func aggiorna() -> void:
	_barra()
	_equipaggio()
	_diario()
	_schede()
	_passo()
	if c.ha_scelte():
		_mostra_scelta()

## ---------------- barra superiore ----------------
func _barra() -> void:
	UI.svuota(barra)
	barra.add_child(UI.etichetta(str(c.s.nome).to_upper(), 24, UI.AMBRA, true))
	var nave: Dictionary = c.s.nave
	var info := "Turno %d   Mondo: %s   Crediti %d   Punti Storia %d   Dicerie %d" % [int(c.s.turno), c.s.mondo.get("nome", "-"), int(c.s.crediti), int(c.s.punti_storia), int(c.s.dicerie)]
	if not c.s.missione.is_empty():
		info += "   Missione in corso (%d indizi)%s" % [int(c.s.dicerie_missione), ", finale" if c.s.missione.get("finale", false) else ""]
	if not nave.is_empty():
		info += "   Scafo %d/%d   Debito %d" % [int(nave.scafo), int(nave.scafo_max), int(nave.debito)]
	else:
		info += "   Senza nave"
	if c.s.storia.get("attiva", false):
		info += "   Orologio della Storia %d" % int(c.s.storia.orologio)
	var l := UI.etichetta(info, 19)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.add_child(l)
	barra.add_child(UI.etichetta("codice " + str(c.s.get("codice", "")), 16, UI.TENUE))
	barra.add_child(UI.bottone("Salva", func(): main.salva(false)))
	barra.add_child(UI.bottone("Salva nel cloud", func(): main.salva(true)))
	barra.add_child(UI.bottone("Regole", func(): main.mostra_regole()))
	barra.add_child(UI.bottone("Menu", func(): main.salva(false); main.mostra_menu()))

## ---------------- equipaggio ----------------
func _equipaggio() -> void:
	UI.svuota(colonna_eq)
	colonna_eq.add_child(UI.titolo("Equipaggio", 24))
	for p in c.s.equipaggio:
		if p.get("morto", false):
			continue
		colonna_eq.add_child(_scheda_breve(p))
	var morti: Array = c.s.equipaggio.filter(func(p): return p.get("morto", false))
	if not morti.is_empty():
		colonna_eq.add_child(UI.etichetta("Caduti: " + ", ".join(morti.map(func(p): return p.nome)), 15, UI.TENUE))

func _scheda_breve(p: Dictionary) -> Control:
	var h := UI.hbox(8)
	var ped = preload("res://scripts/ui/pedina_control.gd").new()
	ped.chiave = str(Personaggio.info_specie(p).get("pedina", p.specie))
	ped.nome = p.nome
	ped.attenuata = not Personaggio.disponibile(p)
	ped.custom_minimum_size = Vector2(64, 64)
	h.add_child(ped)
	var v := UI.vbox(1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var stato := ""
	if int(p.get("infermeria", 0)) > 0:
		stato = "  [Infermeria %d]" % int(p.infermeria)
	elif p.get("assente", false):
		stato = "  [Assente]"
	v.add_child(UI.etichetta("%s%s%s" % [p.nome, "  (Capo)" if p.get("leader", false) else "", stato], 19, UI.AMBRA if p.get("leader", false) else UI.TESTO, true))
	v.add_child(UI.etichetta(Personaggio.nome_specie(p) + "   XP " + str(p.xp), 15, UI.TENUE))
	v.add_child(UI.etichetta("R%d  V%d  C%+d  T%d  A%+d  F%d" % [int(p.reazioni), int(p.velocita), int(p.combattimento), int(p.robustezza), int(p.acume), int(p.fortuna)], 16, UI.ACQUA))
	var armi := []
	for o in p.get("oggetti", []):
		armi.append(Dati.nome_oggetto(str(o.id)) + (" (rotto)" if o.get("danneggiato", false) else ""))
	v.add_child(UI.etichetta(", ".join(armi) if not armi.is_empty() else "Disarmato", 14, UI.TENUE))
	var b := Button.new()
	b.flat = true
	b.custom_minimum_size = Vector2(0, 0)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var pan := UI.pannello(h, UI.PANNELLO_2, UI.BORDO.darkened(0.55))
	pan.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: _apri_scheda(p))
	pan.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pan.tooltip_text = "Clic per la scheda completa"
	return pan

func _apri_scheda(p: Dictionary) -> void:
	var pop := PopupPanel.new()
	var v := UI.vbox(8)
	v.custom_minimum_size = Vector2(780, 0)
	pop.add_child(v)
	var h := UI.hbox(14)
	var ped = preload("res://scripts/ui/pedina_control.gd").new()
	ped.chiave = str(Personaggio.info_specie(p).get("pedina", p.specie))
	ped.nome = p.nome
	ped.custom_minimum_size = Vector2(140, 140)
	h.add_child(ped)
	var col := UI.vbox(4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(col)
	var ne := LineEdit.new()
	ne.text = p.nome
	ne.text_submitted.connect(func(t): p.nome = t; aggiorna())
	ne.focus_exited.connect(func(): p.nome = ne.text; aggiorna())
	col.add_child(ne)
	col.add_child(UI.etichetta(Personaggio.nome_specie(p) + ("   Capo dell'equipaggio" if p.get("leader", false) else ""), 18, UI.AMBRA, true))
	col.add_child(UI.etichetta(Personaggio.profilo(p), 19, UI.ACQUA))
	if str(p.get("background", "")) != "":
		col.add_child(UI.etichetta("Background: %s   Motivazione: %s   Classe: %s" % [p.background, p.motivazione, p.classe], 16))
	if p.has("corso"):
		col.add_child(UI.etichetta("Addestramento avanzato: " + str(p.corso), 16, UI.VERDE))
	col.add_child(UI.etichetta("Battaglie %d   Infermeria %d turni" % [int(p.get("battaglie", 0)), int(p.get("infermeria", 0))], 15, UI.TENUE))
	v.add_child(h)
	v.add_child(UI.etichetta(str(Personaggio.info_specie(p).get("regole", "")), 16, UI.TENUE))
	v.add_child(UI.titolo("Equipaggiamento", 20))
	var ogg: Array = p.get("oggetti", [])
	for i in ogg.size():
		var o: Dictionary = ogg[i]
		var hh := UI.hbox()
		hh.add_child(UI.etichetta(_descr_oggetto(o), 16))
		hh.get_child(0).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hh.add_child(UI.bottone("Al deposito", func(): c.sposta_oggetto(p.id, i, ""); pop.hide(); aggiorna()))
		v.add_child(hh)
	var possibili := c.miglioramenti_possibili(p)
	if not possibili.is_empty():
		v.add_child(UI.titolo("Miglioramenti", 20))
		var hm := UI.hbox()
		for st in possibili:
			var costo := int(Dati.f("post_battaglia").aumenti.statistiche[st].costo_xp)
			hm.add_child(UI.bottone("%s +1 (%d %s)" % [Personaggio.nome_stat(st), costo, "crediti" if Personaggio.e_robot(p) else "XP"], func(): c.migliora(p, st); pop.hide(); aggiorna()))
		v.add_child(hm)
	v.add_child(UI.bottone("Chiudi", func(): pop.hide()))
	add_child(pop)
	pop.reset_size()
	pop.popup_centered()
	pop.popup_hide.connect(func(): pop.queue_free())

func _descr_oggetto(o: Dictionary) -> String:
	var id := str(o.get("id", ""))
	var t := Dati.nome_oggetto(id)
	if o.has("nome") and not Dati.e_arma(id) and Dati.oggetto(id).is_empty():
		t = str(o.nome)
	var a := Dati.arma(id)
	if not a.is_empty():
		if int(a.get("gittata", 0)) > 0:
			t += "  (%d\", %d colpi, danno %+d%s)" % [int(a.gittata), int(a.colpi), int(a.danno), (", " + ", ".join(a.get("tratti", []))) if not a.get("tratti", []).is_empty() else ""]
		else:
			t += "  (rissa, danno %+d%s)" % [int(a.danno), (", " + ", ".join(a.get("tratti", []))) if not a.get("tratti", []).is_empty() else ""]
	else:
		var ob := Dati.oggetto(id)
		if not ob.is_empty():
			t += "  - " + str(ob.get("testo", "")).substr(0, 110)
	if o.get("danneggiato", false):
		t += "  [DANNEGGIATO]"
	return t

## ---------------- diario e schede ----------------
func _diario() -> void:
	var t := ""
	for r in c.diario_recente(160):
		t += UI.riga_bb(r) + "\n"
	diario.text = t

func _schede() -> void:
	var nv: VBoxContainer = schede.get_node("Nave").get_child(0)
	UI.svuota(nv)
	var n: Dictionary = c.s.nave
	if n.is_empty():
		nv.add_child(UI.etichetta("L'equipaggio non ha una nave.", 18))
	else:
		nv.add_child(UI.titolo(str(n.get("nome", "")) if str(n.get("nome", "")) != "Senza nome" else str(n.tipo), 22))
		var ne := LineEdit.new()
		ne.placeholder_text = "Nome della nave"
		ne.text = str(n.get("nome", "")) if str(n.get("nome", "")) != "Senza nome" else ""
		ne.text_submitted.connect(func(t): n.nome = t; _schede())
		nv.add_child(ne)
		nv.add_child(UI.etichetta("Tipo: %s\nScafo: %d / %d\nDebito: %d crediti" % [n.tipo, int(n.scafo), int(n.scafo_max), int(n.debito)], 18))
		for tr in n.get("tratti", []):
			nv.add_child(UI.etichetta(str(Dati.f("nave").get("tratti_nave", {}).get(tr, tr)), 16, UI.TENUE))
		for k in n.get("componenti", []):
			nv.add_child(UI.etichetta("Componente: " + str(k), 16))
	var dv: VBoxContainer = schede.get_node("Deposito").get_child(0)
	UI.svuota(dv)
	dv.add_child(UI.etichetta("Oggetti in comune. Si assegnano nel passo «Assegnare l'equipaggiamento» (o in qualsiasi momento qui).", 15, UI.TENUE))
	var dep: Array = c.s.deposito
	for i in dep.size():
		var h := UI.hbox()
		var l := UI.etichetta(_descr_oggetto(dep[i]), 15)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		var o := OptionButton.new()
		o.add_item("Dai a...")
		var ids := []
		for p in c.vivi():
			o.add_item(p.nome)
			ids.append(p.id)
		o.item_selected.connect(func(j): if j > 0: c.sposta_oggetto("", i, ids[j - 1]); aggiorna())
		h.add_child(o)
		dv.add_child(h)
	var cv: VBoxContainer = schede.get_node("Contatti").get_child(0)
	UI.svuota(cv)
	cv.add_child(UI.titolo("Rivali", 20))
	for r in c.s.rivali:
		cv.add_child(UI.etichetta("%s%s" % [r.nome, " (rintracciato)" if r.get("rintracciato", false) else ""], 17, UI.ROSSO))
	if c.s.rivali.is_empty():
		cv.add_child(UI.etichetta("Nessuno.", 16, UI.TENUE))
	cv.add_child(UI.titolo("Patroni", 20))
	for p in c.s.patroni:
		cv.add_child(UI.etichetta(str(p.nome) + (" (persistente)" if p.get("persistente", false) else ""), 17, UI.ACQUA))
	if c.s.patroni.is_empty():
		cv.add_child(UI.etichetta("Nessuno.", 16, UI.TENUE))
	if not c.s.lavoro.is_empty():
		cv.add_child(UI.titolo("Lavoro accettato", 20))
		cv.add_child(UI.etichetta(_descr_lavoro(c.s.lavoro), 16))
	var mv: VBoxContainer = schede.get_node("Mondo").get_child(0)
	UI.svuota(mv)
	var m: Dictionary = c.s.mondo
	mv.add_child(UI.titolo(str(m.get("nome", "")), 22))
	for tr in m.get("tratti", []):
		mv.add_child(UI.etichetta("%s: %s" % [tr.nome, tr.testo], 16))
	if m.get("licenza_richiesta", false):
		mv.add_child(UI.etichetta("Licenza richiesta (%d crediti): %s" % [int(m.get("costo_licenza", 0)), "posseduta" if m.get("licenza", false) else "da acquistare"], 16, UI.AMBRA))
	if m.get("invasione_imminente", false):
		mv.add_child(UI.etichetta("INVASIONE IMMINENTE: al prossimo turno dovete fuggire.", 18, UI.ROSSO, true))
	mv.add_child(UI.etichetta("Mondi visitati: %d. Battaglie: %d, vittorie %d. Caduti: %d." % [int(c.s.mondi_visitati), int(c.s.statistiche.battaglie), int(c.s.statistiche.vittorie), int(c.s.statistiche.morti)], 16, UI.TENUE))

func _descr_lavoro(l: Dictionary) -> String:
	var t := "%s: obiettivo %s. Paga di pericolo %s. %s." % [l.patrono, c.nome_obiettivo(str(l.obiettivo)), Campagna.testo_valore(l.paga_pericolo), str(l.tempistica)]
	for e in l.get("extra", []):
		t += "\n%s - %s: %s" % [str(e.categoria).capitalize(), e.nome, e.testo]
	return t

## ---------------- scelte in sospeso ----------------
func _mostra_scelta() -> void:
	if scelta_popup != null and is_instance_valid(scelta_popup):
		return
	var sc: Dictionary = c.s.scelte[0]
	scelta_popup = PopupPanel.new()
	scelta_popup.exclusive = true
	var v := UI.vbox(10)
	v.custom_minimum_size = Vector2(700, 0)
	scelta_popup.add_child(v)
	v.add_child(UI.titolo("Una decisione: " + str(sc.get("testo", "")), 22))
	var ops: Array = sc.get("opzioni", [])
	for i in ops.size():
		var b := UI.bottone(str(ops[i].get("testo", "Opzione %d" % (i + 1))), func(): scelta_popup.hide(); scelta_popup.queue_free(); scelta_popup = null; c.risolvi_scelta(i); aggiorna())
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(b)
	add_child(scelta_popup)
	scelta_popup.reset_size()
	scelta_popup.popup_centered()

## ---------------- passo del turno ----------------
func _passo() -> void:
	UI.svuota(centro)
	var f := str(c.s.fase)
	if c.finita():
		centro.add_child(UI.titolo("La campagna è finita", 34))
		centro.add_child(UI.etichetta("Non resta nessuno dell'equipaggio. Le loro storie restano nel diario.", 20))
		centro.add_child(UI.bottone("Torna al menu", func(): main.mostra_menu()))
		return
	var nomi := Campagna.NOMI_FASI
	centro.add_child(UI.titolo(nomi.get(f, "Turno di campagna") if f != "inizio_turno" else "Turno %d" % (int(c.s.turno) + 1), 30))
	match f:
		"inizio_turno":
			centro.add_child(UI.etichetta("Ogni turno di campagna: viaggio, passi del mondo (mantenimento, incarichi, lavori, equipaggiamento, Dicerie), battaglia, sequenza dopo la battaglia ed eventi.", 18, UI.TENUE))
			_bottone_grande("Inizia il turno %d" % (int(c.s.turno) + 1), func(): c.inizia_turno(); rivali_controllati = false; rivale_attacca = {}; aggiorna())
		"viaggio":
			if c.s.mondo.get("invasione_imminente", false):
				centro.add_child(UI.etichetta("Il mondo sta per essere invaso! Bisogna tentare la fuga: 2D6, serve 8+.", 20, UI.ROSSO))
				_bottone_grande("Tenta la fuga", func(): c.passo_viaggio(true); aggiorna())
			else:
				var costo := int(Dati.f("nave").get("parametri", {}).get("costo_viaggio", 5))
				centro.add_child(UI.etichetta("Potete restare su %s oppure partire per un nuovo mondo (%d crediti di carburante, evento di viaggio, Rivali che vi seguono, nuovi Patroni e tratti del mondo)." % [c.s.mondo.nome, costo], 18))
				_bottone_grande("Restare su " + str(c.s.mondo.nome), func(): c.passo_viaggio(false); aggiorna())
				var b := _bottone_grande("Viaggiare verso un nuovo mondo (%d crediti)" % costo, func(): c.passo_viaggio(true); aggiorna())
				b.disabled = int(c.s.crediti) < costo or c.s.nave.is_empty()
		"mantenimento":
			_passo_mantenimento()
		"incarichi":
			_passo_incarichi()
		"lavori":
			_passo_lavori()
		"equipaggiamento":
			centro.add_child(UI.etichetta("Assegna armi e oggetti dal deposito (scheda Deposito a destra) o dalle schede dei personaggi. Ognuno può portare quello che vuole; il gioco usa la migliore arma da tiro e la migliore arma da rissa.", 18))
			_bottone_grande("Distribuisci automaticamente", func(): c.distribuisci_automatico(); aggiorna())
			_bottone_grande("Continua", func(): c.passo_equipaggiamento_fine(); aggiorna())
		"dicerie":
			centro.add_child(UI.etichetta("Dicerie: %d. Se non avete una Missione, tirate 1D6: con un risultato pari o inferiore al numero di Dicerie ne nasce una." % int(c.s.dicerie), 18))
			_bottone_grande("Controlla le Dicerie", func(): c.passo_dicerie(); aggiorna())
		"scelta_battaglia":
			_passo_scelta_battaglia()
		"battaglia":
			_passo_battaglia()
		"acquisti":
			_passo_acquisti()
		"eventi":
			_bottone_grande("Tira gli eventi di fine turno", func(): c.passo_eventi(); aggiorna())
		"fine":
			centro.add_child(UI.etichetta("Turno concluso. La campagna viene salvata sul dispositivo.", 18))
			_bottone_grande("Chiudi il turno", func(): c.fine_turno(); main.salva(false); aggiorna())
		_:
			_bottone_grande("Continua", func(): c.s.fase = "inizio_turno"; aggiorna())

func _bottone_grande(t: String, cb: Callable) -> Button:
	var b := UI.bottone(t, cb)
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 21)
	centro.add_child(b)
	return b

func _spin(min_v: int, max_v: int, val: int) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = min_v
	s.max_value = max(min_v, max_v)
	s.value = val
	s.custom_minimum_size.x = 130
	return s

func _passo_mantenimento() -> void:
	var costo := c.costo_mantenimento()
	centro.add_child(UI.etichetta("Mantenimento: %d crediti (1 per 4-6 membri, +1 per ogni membro oltre il sesto). Lo scafo si ripara di 1 punto gratis; ogni altro punto costa 1 credito. Il debito aumenta di 1 (2 se è di 31 o più) dopo i pagamenti; a 75 i creditori possono sequestrare la nave." % costo, 18))
	var n: Dictionary = c.s.nave
	var h := UI.hbox()
	h.add_child(UI.etichetta("Pagamento del debito", 18))
	var sd := _spin(0, min(int(c.s.crediti) - costo, int(n.get("debito", 0))), 0)
	h.add_child(sd)
	h.add_child(UI.etichetta("Riparazioni extra dello scafo", 18))
	var sr := _spin(0, max(0, int(n.get("scafo_max", 0)) - int(n.get("scafo", 0)) - 1), 0)
	h.add_child(sr)
	centro.add_child(h)
	_bottone_grande("Paga e continua", func(): c.passo_mantenimento(int(sd.value), int(sr.value)); aggiorna())

func _passo_incarichi() -> void:
	centro.add_child(UI.etichetta("Assegna un incarico a ogni membro disponibile (al massimo 2 per incarico, tranne addestrarsi, commerciare ed esplorare). Chi è in Infermeria o appena dimesso non lavora.", 18))
	var ass := {}
	var testi: Dictionary = Dati.f("campagna").get("incarichi", {})
	for p in c.vivi():
		var h := UI.hbox()
		var l := UI.etichetta(p.nome, 19, UI.TESTO, true)
		l.custom_minimum_size.x = 200
		h.add_child(l)
		if not c.puo_lavorare(p):
			h.add_child(UI.etichetta("non disponibile", 17, UI.TENUE))
		else:
			var o := OptionButton.new()
			for k in Campagna.INCARICHI:
				o.add_item(Campagna.NOMI_INCARICHI[k])
				o.set_item_tooltip(o.item_count - 1, str(testi.get(k, {}).get("testo", "")))
			var pred := "addestrarsi"
			if c.s.patroni.size() < 2 and c.s.lavoro.is_empty():
				pred = "trova_patrono"
			o.select(Campagna.INCARICHI.find(pred))
			ass[p.id] = pred
			o.item_selected.connect(func(j): ass[p.id] = Campagna.INCARICHI[j])
			o.custom_minimum_size.x = 300
			h.add_child(o)
		centro.add_child(h)
	var h2 := UI.hbox()
	h2.add_child(UI.etichetta("Crediti per cercare Patroni (+1 ciascuno)", 17))
	var sp := _spin(0, int(c.s.crediti), 0)
	h2.add_child(sp)
	h2.add_child(UI.etichetta("Tiri extra di commercio (3 crediti)", 17))
	var st := _spin(0, int(c.s.crediti) / 3, 0)
	h2.add_child(st)
	centro.add_child(h2)
	var h3 := UI.hbox()
	h3.add_child(UI.etichetta("Crediti per rintracciare (+1)", 17))
	var sr := _spin(0, int(c.s.crediti), 0)
	h3.add_child(sr)
	h3.add_child(UI.etichetta("Crediti in ricambi per riparare (+1)", 17))
	var sri := _spin(0, int(c.s.crediti), 0)
	h3.add_child(sri)
	centro.add_child(h3)
	_bottone_grande("Risolvi gli incarichi", func(): c.passo_incarichi(ass, {"crediti_patrono": int(sp.value), "tiri_commercio_extra": int(st.value), "crediti_rintraccia": int(sr.value), "crediti_riparare": int(sri.value)}); aggiorna())

func _passo_lavori() -> void:
	if c.s.offerte.is_empty():
		centro.add_child(UI.etichetta("Nessuna nuova offerta di lavoro in questo turno." + (" Avete già un lavoro: " + _descr_lavoro(c.s.lavoro) if not c.s.lavoro.is_empty() else ""), 18))
		_bottone_grande("Continua", func(): c.passo_lavori_fine(); aggiorna())
		return
	if c.s.mondo.get("licenza_richiesta", false) and not c.s.mondo.get("licenza", false):
		centro.add_child(UI.etichetta("Su questo mondo serve una Licenza (%d crediti): verrà acquistata accettando un lavoro." % int(c.s.mondo.get("costo_licenza", 0)), 17, UI.AMBRA))
	for i in c.s.offerte.size():
		var l: Dictionary = c.s.offerte[i]
		var v := UI.vbox(4)
		v.add_child(UI.etichetta(_descr_lavoro(l), 17))
		var b := UI.bottone("Accetta il lavoro di " + str(l.patrono), func(): c.accetta_lavoro(i); aggiorna())
		v.add_child(b)
		centro.add_child(UI.pannello(v, UI.PANNELLO_2, UI.ACQUA.darkened(0.4)))
	_bottone_grande("Rifiuta le offerte", func(): c.passo_lavori_fine(); aggiorna())

func _passo_scelta_battaglia() -> void:
	if not rivali_controllati:
		rivali_controllati = true
		rivale_attacca = c.controllo_rivali()
		_diario()
	var ops := c.opzioni_battaglia()
	if not rivale_attacca.is_empty():
		centro.add_child(UI.etichetta("Il Rivale %s vi ha trovati: dovete combattere!" % rivale_attacca.nome, 20, UI.ROSSO))
		ops = [{"tipo": "rivale", "nome": "Difendersi da " + str(rivale_attacca.nome), "rivale": rivale_attacca.id}]
	if c.s.storia.get("attiva", false) and int(c.s.storia.orologio) <= 0 and rivale_attacca.is_empty():
		var ev: Array = Dati.f("storia").get("eventi", [])
		var n := int(c.s.storia.evento)
		if n < ev.size():
			ops.push_front({"tipo": "storia", "nome": "Evento della Storia: " + str(ev[n].get("nome", ""))})
	centro.add_child(UI.etichetta("Scegli la battaglia di questo turno e chi schierare (al massimo %d)." % int(c.s.dimensione), 18))
	var disp := c.disponibili()
	schierati = {}
	var hs := HFlowContainer.new()
	for i in disp.size():
		var p: Dictionary = disp[i]
		var cb := CheckBox.new()
		cb.text = p.nome
		cb.button_pressed = i < int(c.s.dimensione) and int(p.get("salta_battaglia_turni", 0)) <= 0
		schierati[p.id] = cb.button_pressed
		cb.toggled.connect(func(v): schierati[p.id] = v)
		hs.add_child(cb)
	centro.add_child(hs)
	for o in ops:
		var b := _bottone_grande(str(o.nome), func(): _scegli(o))
		if o.tipo == "nessuna":
			b.add_theme_color_override("font_color", UI.TENUE)

func _scegli(o: Dictionary) -> void:
	if o.tipo == "nessuna":
		c.scrivi("Nessuna battaglia in questo turno.")
		c.s["fase"] = "acquisti"
		aggiorna()
		return
	var ids := []
	for k in schierati:
		if schierati[k]:
			ids.append(k)
	if ids.is_empty():
		main.mostra_avviso("Scegli almeno un membro da schierare.")
		return
	if ids.size() > int(c.s.dimensione):
		main.mostra_avviso("Al massimo %d membri in battaglia." % int(c.s.dimensione))
		return
	c.s["schierati"] = ids
	if o.tipo == "storia":
		var ev: Dictionary = Dati.f("storia").get("eventi", [])[int(c.s.storia.evento)]
		c.s["storia"]["in_corso"] = true
		c.scrivi("Evento della Storia: %s. %s" % [ev.get("nome", ""), str(ev.get("testo", ev.get("riassunto", "")))], "missione")
		var b := c.prepara_battaglia("missione")
		b["storia"] = ev
		c.scrivi("Regole della battaglia della Storia: " + JSON.stringify(ev.get("battaglia", {})).substr(0, 600).replace("{", "").replace("}", "").replace("\"", ""), "manuale")
	else:
		c.prepara_battaglia(o.tipo, o)
	aggiorna()

func _passo_battaglia() -> void:
	var b: Dictionary = c.s.battaglia
	centro.add_child(UI.etichetta(str(b.get("descrizione", "")), 20))
	var nem := Dati.nemico(str(b.get("nemico", "")))
	var info := "%s: Velocità %d\", Combattimento %+d, Robustezza %d, IA %s, Panico %s.\n%s" % [nem.get("nome", ""), int(nem.get("velocita", 4)), int(nem.get("combattimento", 0)), int(nem.get("robustezza", 3)), str(nem.get("ia", "")), str(nem.get("panico", [])), nem.get("regole", "")]
	centro.add_child(UI.etichetta(info, 17, UI.TENUE))
	if not b.get("condizione", {}).is_empty():
		centro.add_child(UI.etichetta("Condizione di schieramento: %s - %s" % [b.condizione.get("nome", ""), b.condizione.get("testo", "")], 17))
	if not b.get("luogo", {}).is_empty():
		centro.add_child(UI.etichetta("Luogo notevole: %s - %s" % [b.luogo.get("nome", ""), b.luogo.get("testo", "")], 17))
	_bottone_grande("Al campo di battaglia!", func(): main.salva(false); main.mostra_battaglia())
	_bottone_grande("Risolvi la battaglia in automatico", _auto_battaglia)

func _auto_battaglia() -> void:
	var bt := Battaglia.new(c.dadi.d(999999))
	bt.prepara(c.s.battaglia, pgs_schierati(), int(c.s.opzioni.get("celle_tavolo", 24)), {"eventi_battaglia": c.s.opzioni.get("eventi_battaglia", true), "tratti_mondo": c.s.mondo.get("tratti", []).map(func(t): return t.nome)})
	var es := bt.gioca_automatica(14)
	for r in bt.log_righe:
		if r.tipo in ["titolo", "perdita", "obiettivo"]:
			c.scrivi(str(r.testo), "tiro")
	c.dopo_battaglia(es)
	aggiorna()

func pgs_schierati() -> Array:
	var r := []
	for id in c.s.get("schierati", []):
		var p := c.trova(str(id))
		if not p.is_empty() and Personaggio.disponibile(p):
			r.append(p)
	if r.is_empty():
		r = c.disponibili().slice(0, int(c.s.dimensione))
	return r

func _passo_acquisti() -> void:
	centro.add_child(UI.etichetta("Crediti: %d. Un tiro sulle tabelle Armi militari, Equipaggiamento o Gadget costa 3 crediti; Pistola, Lama, Fucile coloniale e Fucile a pompa costano 1 credito. Si possono vendere oggetti integri a 1 credito (dal Deposito)." % int(c.s.crediti), 18))
	var h := HFlowContainer.new()
	for t in [["arma_militare", "Tiro armi militari (3)"], ["equip", "Tiro equipaggiamento (3)"], ["gadget", "Tiro gadget (3)"], ["pistola", "Pistola (1)"], ["lama", "Lama (1)"], ["fucile_coloniale", "Fucile coloniale (1)"], ["fucile_pompa", "Fucile a pompa (1)"]]:
		var b := UI.bottone(t[1], func(): c.compra(t[0]); aggiorna())
		b.disabled = int(c.s.crediti) < (3 if t[1].ends_with("(3)") else 1)
		h.add_child(b)
	centro.add_child(h)
	var dep: Array = c.s.deposito
	if not dep.is_empty():
		var hv := HFlowContainer.new()
		for i in dep.size():
			if not dep[i].get("danneggiato", false):
				hv.add_child(UI.bottone("Vendi " + Dati.nome_oggetto(str(dep[i].id)), func(): c.vendi("", i); aggiorna()))
		centro.add_child(UI.etichetta("Vendere:", 17, UI.TENUE))
		centro.add_child(hv)
	# miglioramenti
	var mg := UI.vbox(4)
	for p in c.vivi():
		var poss := c.miglioramenti_possibili(p)
		if poss.is_empty():
			continue
		var hh := HFlowContainer.new()
		hh.add_child(UI.etichetta(p.nome + " (XP %d): " % int(p.xp), 17))
		for st in poss:
			hh.add_child(UI.bottone(Personaggio.nome_stat(st) + " +1", func(): c.migliora(p, st); aggiorna()))
		mg.add_child(hh)
	if mg.get_child_count() > 0:
		centro.add_child(UI.titolo("Miglioramenti con l'esperienza", 20))
		centro.add_child(mg)
	# addestramento avanzato
	var corsi: Array = Dati.f("post_battaglia").get("addestramento_avanzato", {}).get("corsi", [])
	if not corsi.is_empty():
		centro.add_child(UI.titolo("Addestramento avanzato", 20))
		var ha := UI.hbox()
		var op := OptionButton.new()
		var cand := c.vivi().filter(func(p): return not p.has("corso"))
		for p in cand:
			op.add_item(p.nome)
		var oc := OptionButton.new()
		for k in corsi:
			oc.add_item("%s (%d)" % [k.nome, int(k.costo)])
			oc.set_item_tooltip(oc.item_count - 1, str(k.get("testo", "")))
		ha.add_child(op)
		ha.add_child(oc)
		ha.add_child(UI.bottone("Iscriviti (1 credito, 2D6 4+)", func(): if not cand.is_empty(): c.addestramento(cand[op.selected], str(corsi[oc.selected].id)); aggiorna()))
		centro.add_child(ha)
	# zona rossa
	var zr: Dictionary = Dati.f("zone").get("requisiti", {})
	if not c.s.zona_rossa.get("licenza", false) and int(c.s.turno) >= 10:
		var b := _bottone_grande("Licenza per i lavori in Zona Rossa (15 crediti, servono 10 turni e 7 membri)", func(): _licenza_zona())
		b.disabled = int(c.s.crediti) < 15 or c.vivi().size() < 7
	_bottone_grande("Continua", func(): c.s["fase"] = "eventi"; aggiorna())

func _licenza_zona() -> void:
	c.s["crediti"] = int(c.s.crediti) - 15
	c.s["zona_rossa"]["licenza"] = true
	c.scrivi("Licenza per la Zona Rossa ottenuta: lavori più pericolosi e meglio pagati.", "titolo")
	aggiorna()
