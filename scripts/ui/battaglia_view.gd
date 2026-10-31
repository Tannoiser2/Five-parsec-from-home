## Vista della battaglia su griglia: barra delle fasi del round (p.112), tiro e assegnazione dei dadi delle reazioni,
## squadra con lo stato di ogni personaggio, pannello delle azioni del personaggio selezionato (movimento,
## combattimento, azioni gratuite), scelte degli eventi, registro. L'IA muove i nemici.
extends Control

var main
var c: Campagna
var b: Battaglia
var tavolo
var barra_fasi: HBoxContainer
var info_round: Label
var squadra_box: VBoxContainer
var dadi_box: HFlowContainer
var info_sel: RichTextLabel
var azioni_box: VBoxContainer
var comandi: HFlowContainer
var registro: RichTextLabel
var sopra_lbl: Label
var guida: Label
var sel: Dictionary = {}
var modo := ""               # azione in corso per il personaggio selezionato
var iniziativa_libera := false
var occupato := false
var dado_sel := -1           # indice del dado delle reazioni selezionato
var banner: TextureRect
var banner_testo: Label
var banner_evento := ""
var popup_scelta: PanelContainer = null

const FASI := [["reazioni", "Reazioni"], ["rapida", "Azioni rapide"], ["nemici", "Azioni nemiche"], ["lenta", "Azioni lente"], ["fine", "Fine round"]]

func _ready() -> void:
	b = Battaglia.new(c.dadi.d(999999))
	var pgs := _schierati()
	var riserve := []
	for p in c.disponibili():
		if not p in pgs:
			riserve.append(p)
	b.prepara(c.s.battaglia, pgs, int(c.s.opzioni.get("celle_tavolo", 24)),
		{"eventi_battaglia": c.s.opzioni.get("eventi_battaglia", true), "tratti_mondo": c.s.mondo.get("tratti", []).map(func(t): return str(t.nome)),
		"riserve": riserve})
	b.setup["difficolta"] = c.s.difficolta
	_costruisci()
	var tot := b.tira_iniziativa()
	if tot >= 10:
		iniziativa_libera = true
		b.fase = "iniziativa"
	else:
		b.inizia_round()
	aggiorna()

func _costruisci() -> void:
	var radice := UI.hbox(12)
	radice.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.offset_left = 10
	radice.offset_top = 10
	radice.offset_right = -10
	radice.offset_bottom = -10
	add_child(radice)
	tavolo = preload("res://scripts/ui/tavolo.gd").new()
	tavolo.b = b
	tavolo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tavolo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tavolo.cella_cliccata.connect(_clic)
	tavolo.cella_sopra.connect(_sopra)
	radice.add_child(tavolo)
	var dx := UI.vbox(6)
	dx.custom_minimum_size.x = 660
	var scorri := UI.scorrimento(dx)
	scorri.custom_minimum_size.x = 680
	scorri.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	radice.add_child(UI.pannello(scorri))
	# intestazione: round e fasi
	info_round = UI.etichetta("", 26, UI.AMBRA, true)
	dx.add_child(info_round)
	barra_fasi = UI.hbox(4)
	dx.add_child(barra_fasi)
	guida = UI.etichetta("", 15, UI.TENUE)
	guida.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dx.add_child(guida)
	# obiettivo
	banner = Immagini.illustrazione(Immagini.obiettivo(b.obiettivo), 110)
	if banner != null:
		banner_testo = UI.etichetta("", 15, UI.AMBRA, true)
		var vb := UI.vbox(2)
		vb.add_child(banner)
		vb.add_child(banner_testo)
		dx.add_child(vb)
	var desc := UI.etichetta(str(c.s.battaglia.get("descrizione", "")), 15, UI.TENUE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dx.add_child(desc)
	# dadi delle reazioni e squadra
	dadi_box = HFlowContainer.new()
	dx.add_child(dadi_box)
	dx.add_child(UI.etichetta("SQUADRA", 17, UI.AMBRA, true))
	squadra_box = UI.vbox(3)
	dx.add_child(squadra_box)
	# personaggio selezionato e azioni
	info_sel = UI.testo_ricco("", 16)
	dx.add_child(info_sel)
	azioni_box = UI.vbox(4)
	dx.add_child(azioni_box)
	sopra_lbl = UI.etichetta("", 14, UI.ACQUA)
	sopra_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sopra_lbl.custom_minimum_size.y = 40
	dx.add_child(sopra_lbl)
	comandi = HFlowContainer.new()
	dx.add_child(comandi)
	dx.add_child(UI.etichetta("REGISTRO", 17, UI.AMBRA, true))
	registro = RichTextLabel.new()
	registro.bbcode_enabled = true
	registro.scroll_following = true
	registro.custom_minimum_size = Vector2(0, 300)
	registro.add_theme_font_size_override("normal_font_size", 15)
	registro.add_theme_font_size_override("bold_font_size", 16)
	dx.add_child(registro)

func _schierati() -> Array:
	var r := []
	for id in c.s.get("schierati", []):
		var p := c.trova(str(id))
		if not p.is_empty() and Personaggio.disponibile(p):
			r.append(p)
	if r.is_empty():
		r = c.disponibili().slice(0, int(c.s.dimensione))
	return r

## ---------------- aggiornamento ----------------

func aggiorna() -> void:
	if b.fase == "finita":
		_registro()
		_fine()
		return
	_intestazione()
	_registro()
	_banner()
	_dadi()
	_squadra()
	_info_sel()
	_azioni()
	_comandi()
	_evidenzia()
	_scelta()

func _intestazione() -> void:
	if b.fase == "iniziativa":
		info_round.text = "PRENDERE L'INIZIATIVA"
	else:
		info_round.text = "ROUND %d" % b.round_n
	UI.svuota(barra_fasi)
	for f in FASI:
		var attiva: bool = b.fase == f[0]
		var l := UI.etichetta(str(f[1]), 15, UI.SFONDO if attiva else UI.TENUE, attiva)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UI.stile(UI.AMBRA if attiva else UI.PANNELLO_2, UI.BORDO if attiva else UI.BORDO.darkened(0.5), 1, 4, 5))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_child(l)
		barra_fasi.add_child(p)
	var g := ""
	match b.fase:
		"iniziativa":
			g = "Avete preso l'iniziativa: ogni personaggio può muovere OPPURE sparare (colpisce solo con un 6) prima del primo round."
		"reazioni":
			if b.dadi_reazione.is_empty():
				g = "Piano astuto: per ogni personaggio scegliete se agisce nella fase rapida o in quella lenta, poi confermate."
			else:
				g = "Assegnate un dado a ogni personaggio: con un risultato pari o inferiore alle sue Reazioni agisce nella fase rapida, altrimenti in quella lenta. Clic su un dado, poi su un personaggio (è già proposta l'assegnazione migliore)."
		"rapida":
			g = "Fase delle azioni rapide: agiscono i personaggi segnati RAPIDO, in qualsiasi ordine. Ognuno può muovere e poi fare un'azione di combattimento (mai il contrario). Chi è rapido può anche restare in attesa per lo Snap Fire o rimandare alla fase lenta."
		"nemici":
			g = "Fase delle azioni nemiche: i nemici agiscono dal più vicino al vostro bordo."
		"lenta":
			g = "Fase delle azioni lente: agiscono i personaggi segnati LENTO e chi aveva rimandato."
		"fine":
			g = "Fine del round: morale nemico, obiettivi ed eventi sono stati risolti. Passate al round successivo."
	guida.text = g

func _registro() -> void:
	var t := ""
	for r in b.log_righe.slice(max(0, b.log_righe.size() - 150)):
		t += UI.riga_bb(r) + "\n"
	registro.text = t

func _banner() -> void:
	if banner == null:
		return
	var ev := str(b.ultimo_evento.get("nome", ""))
	if ev == "":
		banner_testo.text = "Obiettivo: " + str(Dati.f("incontri").get("tipi_obiettivo", {}).get(b.obiettivo, {}).get("nome", b.obiettivo))
		return
	if ev == banner_evento:
		return
	banner_evento = ev
	var tex := Immagini.evento(ev)
	if tex != null:
		banner.texture = tex
	banner_testo.text = "Evento: " + ev

func _dadi() -> void:
	UI.svuota(dadi_box)
	if b.fase != "reazioni":
		return
	if b.dadi_reazione.is_empty():
		return
	dadi_box.add_child(UI.etichetta("Dadi delle reazioni:", 16, UI.TESTO))
	for i in b.dadi_reazione.size():
		var d: int = b.dadi_reazione[i]
		var bt := UI.bottone(" %d " % d, func(): dado_sel = i if dado_sel != i else -1; aggiorna(), "Seleziona il dado, poi clicca su un personaggio")
		bt.custom_minimum_size = Vector2(44, 40)
		if i == dado_sel:
			bt.add_theme_color_override("font_color", UI.SFONDO)
			bt.add_theme_stylebox_override("normal", UI.stile(UI.AMBRA, UI.BORDO, 2, 6, 4))
		dadi_box.add_child(bt)

## Valore del dado i-esimo assegnato a u (cerca la prima occorrenza libera).
func _assegna_dado(u: Dictionary) -> void:
	if dado_sel < 0:
		return
	var valore: int = b.dadi_reazione[dado_sel]
	# chi ha già quel dado prende il dado di u
	var vecchio := int(u.dado_reazione)
	var mappa := {}
	for w in b.figure(Battaglia.EQ):
		mappa[w.uid] = int(w.dado_reazione)
	for w in b.figure(Battaglia.EQ):
		if w.uid != u.uid and int(mappa[w.uid]) == valore:
			mappa[w.uid] = vecchio
			break
	mappa[u.uid] = valore
	var err := b.assegna_dadi(mappa)
	if err != "":
		main.mostra_avviso(err)
	dado_sel = -1

func _squadra() -> void:
	UI.svuota(squadra_box)
	for u in b.figure(Battaglia.EQ, false):
		var riga := UI.hbox(6)
		var stato := ""
		var col := UI.TESTO
		if not u.attiva:
			stato = "fuori combattimento" if u.fuori else ("uscito dal campo" if u.uscito else "assente")
			col = UI.TENUE
		elif b.fase == "reazioni":
			if b.dadi_reazione.is_empty():
				stato = "RAPIDO" if u.fase == "rapida" else "LENTO"
			else:
				stato = "dado %d (Reazioni %d): %s" % [int(u.dado_reazione), b.stat(u, "reazioni"), "RAPIDO" if u.fase == "rapida" else "LENTO"]
			col = UI.VERDE if u.fase == "rapida" else UI.AMBRA
		else:
			var parti := []
			if b.fase in ["rapida", "nemici", "lenta"]:
				parti.append("RAPIDO" if u.fase == "rapida" else "LENTO")
			if u.attesa == "snap":
				parti.append("in attesa (Snap Fire)")
			if u.attivato:
				parti.append("ha agito")
			else:
				if u.mosso:
					parti.append("si è mosso")
				if u.agito:
					parti.append("ha usato l'azione")
			if int(u.stordito) > 0:
				parti.append("stordito %d" % int(u.stordito))
			if b._congelato(u):
				parti.append("congelato")
			stato = ", ".join(parti)
			if b.da_attivare().has(u):
				col = UI.VERDE
		var nome := UI.bottone(str(u.nome), func(): _seleziona(u))
		nome.custom_minimum_size.x = 170
		riga.add_child(nome)
		var l := UI.etichetta(stato, 15, col)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		riga.add_child(l)
		if b.fase == "reazioni" and b.dadi_reazione.is_empty() and u.attiva:
			riga.add_child(UI.bottone("Rapido" if u.fase != "rapida" else "Lento", func(): b.imposta_fase(u, "rapida" if u.fase != "rapida" else "lenta"); aggiorna()))
		squadra_box.add_child(riga)

func _seleziona(u: Dictionary) -> void:
	if b.fase == "reazioni":
		if dado_sel >= 0 and u.attiva:
			_assegna_dado(u)
		aggiorna()
		return
	if not u.attiva:
		return
	sel = u
	modo = ""
	if _puo_agire(u):
		modo = _modo_predefinito(u)
	aggiorna()

func _modo_predefinito(u: Dictionary) -> String:
	if iniziativa_libera:
		return "muovi"
	for a in b.azioni_disponibili(u):
		if a.id in ["mossa_bonus", "muovi"]:
			return a.id
	return ""

func _puo_agire(u: Dictionary) -> bool:
	if u.lato != Battaglia.EQ or not u.attiva:
		return false
	if iniziativa_libera:
		return not (u.mosso or u.agito)
	if int(u.mossa_bonus) > 0:
		return true
	return u in b.da_attivare()

func _info_sel() -> void:
	if sel.is_empty() or not sel.attiva:
		if b.fase in ["rapida", "lenta"]:
			var att := b.da_attivare()
			info_sel.text = "[color=#%s]Da attivare in questa fase:[/color] %s" % [UI.AMBRA.to_html(false), ", ".join(att.map(func(u): return u.nome)) if not att.is_empty() else "nessuno"]
		else:
			info_sel.text = ""
		return
	var t := "[b]%s[/b]  Reazioni %d  Velocità %d\"  Combattimento %+d  Robustezza %d%s%s\n" % [sel.nome, b.stat(sel, "reazioni"), b.stat(sel, "velocita"),
		int(sel.combattimento), b.stat(sel, "robustezza"), ("  salvezza %d+" % int(sel.salv_corazza if int(sel.salv_corazza) > 0 else sel.salv_schermo)) if int(sel.salv_corazza) + int(sel.salv_schermo) > 0 else "",
		("  Fortuna %d" % int(sel.fortuna)) if int(sel.fortuna) > 0 else ""]
	var armi := []
	for id in sel.armi:
		var e := b.arma_eff(sel, str(id))
		if e.is_empty():
			continue
		var s := "%s" % e.nome
		if int(e.gittata) > 0:
			s += " (%d\", %d colpi, %+d)" % [e.gittata, e.colpi, e.danno]
		if not b.arma_usabile(sel, str(id)):
			s += " [inutilizzabile]"
		armi.append(s)
	t += "Armi: %s\n" % (", ".join(armi) if not armi.is_empty() else "nessuna")
	if b.a_at(sel.pos) > 0:
		t += "In alto: %d\" sul terreno.\n" % b.a_at(sel.pos)
	if _puo_agire(sel):
		t += "Movimento: %s.  Azione di combattimento: %s.%s" % ["usato" if sel.mosso else "disponibile", "usata" if sel.agito else "disponibile",
			("  Azioni gratuite usate: %d." % int(sel.gratuite)) if int(sel.gratuite) > 0 else ""]
		if int(sel.stordito) > 0:
			t += "\n[color=#%s]Stordito (%d): in questa attivazione può muovere OPPURE agire.[/color]" % [UI.ROSSO.to_html(false), int(sel.stordito)]
	info_sel.text = t

## Pannello delle azioni del personaggio selezionato.
func _azioni() -> void:
	UI.svuota(azioni_box)
	if occupato or sel.is_empty() or not _puo_agire(sel):
		return
	if iniziativa_libera:
		var r := UI.hbox(6)
		r.add_child(_bt_modo("Muovi", "muovi"))
		var a := str(sel.arma)
		if a != "" and not b.bersagli(sel, a).is_empty():
			r.add_child(_bt_modo("Spara (colpisce solo con 6)", "spara:" + a))
		azioni_box.add_child(r)
		return
	var gruppi := {"movimento": [], "combattimento": [], "gratuita": [], "speciale": []}
	for a in b.azioni_disponibili(sel):
		gruppi[str(a.tipo)].append(a)
	var titoli := {"movimento": "MOVIMENTO", "combattimento": "AZIONE DI COMBATTIMENTO", "gratuita": "AZIONI GRATUITE", "speciale": "ALTRO"}
	for k in ["movimento", "combattimento", "gratuita", "speciale"]:
		if gruppi[k].is_empty():
			continue
		azioni_box.add_child(UI.etichetta(titoli[k], 14, UI.AMBRA, true))
		var f := HFlowContainer.new()
		for a in gruppi[k]:
			f.add_child(_bt_azione(a))
		azioni_box.add_child(f)
	var f2 := HFlowContainer.new()
	if b.fase == "rapida" and not sel.mosso and not sel.agito and sel.fase == "rapida":
		f2.add_child(UI.bottone("Attendi: Snap Fire", func(): b.attendi(sel, "snap"); sel = {}; _prossimo(), "Resta fermo con l'arma puntata: sparerà al primo nemico che si muove in vista; poi non potrà muovere in questo round. Se non spara, agisce nella fase lenta."))
		f2.add_child(UI.bottone("Rimanda alla fase lenta", func(): b.attendi(sel, "lenta"); sel = {}; _prossimo()))
	f2.add_child(UI.bottone("Fine attivazione di " + str(sel.nome), func(): _fine_attivazione()))
	azioni_box.add_child(f2)

func _bt_modo(nome: String, id: String) -> Button:
	var bt := UI.bottone(nome, func(): modo = id; aggiorna())
	if modo == id:
		bt.add_theme_stylebox_override("normal", UI.stile(UI.AMBRA.darkened(0.45), UI.AMBRA, 2, 6, 6))
	return bt

func _bt_azione(a: Dictionary) -> Button:
	var id := str(a.id)
	if str(a.bersaglio) == "nessuno":
		return UI.bottone(str(a.nome), func(): _esegui(id, null))
	return _bt_modo(str(a.nome), id)

func _esegui(id: String, param) -> void:
	if sel.is_empty():
		return
	var da: Vector2i = sel.pos
	var ok := b.esegui(sel, id, param)
	if not ok:
		main.mostra_avviso("Azione non possibile.")
	if sel.pos != da:
		_anima(sel, da, sel.pos)
	modo = ""
	_dopo_azione()

func _comandi() -> void:
	UI.svuota(comandi)
	if occupato:
		return
	match b.fase:
		"iniziativa":
			comandi.add_child(UI.bottone("Fine dell'iniziativa: inizia il round 1", func(): iniziativa_libera = false; sel = {}; _reset_iniziativa(); b.inizia_round(); aggiorna()))
		"reazioni":
			if not b.dadi_reazione.is_empty():
				comandi.add_child(UI.bottone("Assegnazione consigliata", func(): b.auto_assegna(); dado_sel = -1; aggiorna()))
			comandi.add_child(UI.bottone("Conferma: inizia la fase rapida", func(): b.conferma_reazioni(); sel = {}; _dopo_conferma()))
		"rapida", "lenta":
			comandi.add_child(UI.bottone("Termina la fase", func(): sel = {}; _termina_fase()))
		"fine":
			comandi.add_child(UI.bottone("Round successivo", func(): b.inizia_round(); sel = {}; dado_sel = -1; aggiorna()))
	comandi.add_child(UI.bottone("Gioca il resto in automatico", _automatico, "L'equipaggio viene mosso dall'IA tattica fino alla fine"))
	comandi.add_child(UI.bottone("Ritirata", func(): b.ritirata(); aggiorna(), "Tutto l'equipaggio abbandona il campo"))

func _dopo_conferma() -> void:
	if b.fase == "nemici":
		await _fase_nemici()
	_prossimo()

## Caselle e bersagli evidenziati sul tavolo secondo l'azione in corso.
func _evidenzia() -> void:
	tavolo.selezionata = sel.get("uid", -1)
	tavolo.raggiungibili = {}
	tavolo.raggiungibili_scatto = {}
	tavolo.bersagli = {}
	if not sel.is_empty() and sel.attiva and _puo_agire(sel) and modo != "":
		if iniziativa_libera:
			if modo == "muovi":
				tavolo.raggiungibili = b.raggiungibili(sel, false)
			elif modo.begins_with("spara:"):
				for t in b.bersagli(sel, modo.substr(6)):
					tavolo.bersagli[t.u.uid] = 6
		elif modo.begins_with("spara:"):
			for t in b.bersagli(sel, modo.substr(6)):
				tavolo.bersagli[t.u.uid] = int(t.netto)
		elif modo in ["rissa", "bot_distrazione", "lama_nascosta"]:
			for v in b.figure_azione(sel, modo):
				tavolo.bersagli[v.uid] = 0
		else:
			var celle := b.celle_azione(sel, modo)
			var d := {}
			for p in celle:
				d[p] = 1
			if modo == "scatto":
				tavolo.raggiungibili_scatto = d
			else:
				tavolo.raggiungibili = d
	tavolo.queue_redraw()

func _reset_iniziativa() -> void:
	for u in b.unita:
		u.mosso = false
		u.agito = false

func _sopra(p: Vector2i) -> void:
	if not b.dentro(p):
		sopra_lbl.text = ""
		return
	var t := str(Battaglia.NOMI_TERRENO.get(b.t_at(p), ""))
	var e := b.elemento_in(p)
	if not e.is_empty():
		t = str(e.nome) + ": " + t
	if b.a_at(p) > 0:
		t += " (alto %d\")" % b.a_at(p)
	var f := b.figura_in(p)
	if not f.is_empty():
		var a := Dati.arma(str(f.arma))
		t = "%s  (V%d C%+d T%d%s, %s%s)  -  %s" % [f.nome, int(f.velocita), int(f.combattimento), b.stat(f, "robustezza"), (" salv. %d+" % int(f.salv_corazza)) if int(f.salv_corazza) > 0 else "", a.get("nome", "senza arma da tiro"), (", IA " + str(f.ia)) if f.lato != Battaglia.EQ else "", t]
		if f.lato != Battaglia.EQ and str(f.get("regole", "")) != "":
			t += "\n" + str(f.regole)
		if not sel.is_empty() and f.lato != Battaglia.EQ:
			var arma := modo.substr(6) if modo.begins_with("spara:") else ""
			var s := b.soglia_colpire(sel, f, arma)
			if s.ok:
				t += "\nPer colpire: %d+%s, distanza %d\"%s" % [s.soglia, (" (mod %+d)" % s.mod) if s.mod != 0 else "", s.distanza, ", in copertura" if s.copertura else ""]
			else:
				t += "\nFuori tiro o non visibile (distanza %d\")" % Battaglia.dist(sel.pos, f.pos)
	sopra_lbl.text = t

func _clic(p: Vector2i, destro: bool) -> void:
	if occupato or b.fase == "finita" or not b.scelta_in_attesa.is_empty():
		return
	if destro:
		sel = {}
		modo = ""
		aggiorna()
		return
	var f := b.figura_in(p)
	if not f.is_empty() and f.lato == Battaglia.EQ and (sel.is_empty() or f.uid != sel.uid) and not (modo in ["rissa"]):
		_seleziona(f)
		return
	if sel.is_empty() or not _puo_agire(sel):
		return
	if iniziativa_libera:
		if not f.is_empty() and tavolo.bersagli.has(f.uid):
			tavolo.linea_tiro = [sel.pos, f.pos]
			b.spara(sel, f, "", true)
			sel.mosso = true
			sel = {}
			aggiorna()
		elif tavolo.raggiungibili.has(p):
			var da: Vector2i = sel.pos
			if b.muovi(sel, p, false, false):
				_anima(sel, da, p)
				sel.agito = true
				sel = {}
			aggiorna()
		return
	# bersaglio di un'azione su figura
	if not f.is_empty() and f.lato != Battaglia.EQ:
		if modo == "" or not tavolo.bersagli.has(f.uid):
			# scorciatoia: sparare con l'arma principale o la Rissa se a contatto
			if Battaglia.dist(sel.pos, f.pos) == 1 and not b.figure_azione(sel, "rissa").is_empty():
				_esegui("rissa", f.uid)
				return
			var a := str(sel.arma)
			if a != "" and b.bersagli(sel, a).any(func(x): return x.u.uid == f.uid):
				tavolo.linea_tiro = [sel.pos, f.pos]
				_esegui("spara:" + a, f.uid)
			return
		if modo.begins_with("spara:"):
			tavolo.linea_tiro = [sel.pos, f.pos]
		_esegui(modo, f.uid)
		return
	if tavolo.raggiungibili.has(p) or tavolo.raggiungibili_scatto.has(p):
		_esegui(modo, p)

func _anima(u: Dictionary, da: Vector2i, a: Vector2i) -> void:
	tavolo.anim[u.uid] = tavolo.centro_cella(da)
	var tw := create_tween()
	tw.tween_method(func(v): tavolo.anim[u.uid] = v; tavolo.queue_redraw(), tavolo.centro_cella(da), tavolo.centro_cella(a), 0.22)
	tw.tween_callback(func(): tavolo.anim.erase(u.uid); tavolo.queue_redraw())

func _dopo_azione() -> void:
	if b._controlla_fine():
		aggiorna()
		return
	if not sel.is_empty():
		if not sel.attiva:
			sel = {}
		else:
			var fatto: bool = (sel.mosso and sel.agito) or (int(sel.stordito) > 0 and (sel.mosso or sel.agito))
			var bonus := int(sel.mossa_bonus) > 0
			if fatto and not bonus and b.azioni_disponibili(sel).filter(func(a): return a.tipo == "gratuita").is_empty():
				_fine_attivazione()
				return
			modo = _modo_predefinito(sel) if not sel.mosso else ""
	aggiorna()

func _fine_attivazione() -> void:
	if sel.is_empty():
		return
	sel.mossa_bonus = 0
	b.fine_attivazione(sel)
	sel = {}
	modo = ""
	_prossimo()

## Seleziona il prossimo personaggio da attivare o passa alla fase successiva.
func _prossimo() -> void:
	if b.fase in ["rapida", "lenta"] and b.da_attivare().is_empty():
		_termina_fase()
		return
	if b.fase in ["rapida", "lenta"] and sel.is_empty():
		var att := b.da_attivare()
		if not att.is_empty():
			sel = att[0]
			modo = _modo_predefinito(sel)
	aggiorna()

func _termina_fase() -> void:
	if b.fase == "rapida":
		b.avanza_fase()
		await _fase_nemici()
	elif b.fase == "lenta":
		b.avanza_fase()
	elif b.fase == "nemici":
		await _fase_nemici()
	if b.fase == "lenta" and b.da_attivare().is_empty():
		b.avanza_fase()
	_prossimo()

func _fase_nemici() -> void:
	if b.fase != "nemici":
		return
	occupato = true
	aggiorna()
	if b._nemici_bloccati():
		b.scrivi("Il nemico, colto di sorpresa, non agisce in questo round.")
	for u in b.ordine_nemici():
		if b.fase == "finita":
			break
		var prima: Vector2i = u.pos
		b.attiva_nemico(u)
		if u.pos != prima:
			_anima(u, prima, u.pos)
		for e in b.eventi:
			if e.tipo == "spara":
				tavolo.linea_tiro = [e.da_pos, e.a_pos]
		b.eventi = []
		aggiorna()
		await get_tree().create_timer(0.35).timeout
		if b._controlla_fine():
			break
	occupato = false
	if b.fase == "nemici":
		b.avanza_fase()
	aggiorna()

func _automatico() -> void:
	iniziativa_libera = false
	occupato = true
	b.auto_decisioni = true
	if not b.scelta_in_attesa.is_empty():
		b.scegli(b._scelta_automatica(b.scelta_in_attesa))
	if b.fase == "iniziativa":
		_reset_iniziativa()
		b.inizia_round()
	var guardia := 0
	while b.fase != "finita" and guardia < 80:
		guardia += 1
		if b.fase == "reazioni":
			b.conferma_reazioni()
		elif b.fase in ["rapida", "lenta"]:
			for u in b.da_attivare():
				if b.fase == "finita":
					break
				b.auto_equipaggio(u)
			if b.fase != "finita":
				b.avanza_fase()
		elif b.fase == "nemici":
			b.esegui_fase_nemici()
		elif b.fase == "fine":
			if b.round_n >= 14:
				b.ritirata()
			else:
				b.inizia_round()
		aggiorna()
		await get_tree().create_timer(0.05).timeout
	occupato = false
	aggiorna()

## ---------------- scelte degli eventi ----------------

func _scelta() -> void:
	if popup_scelta != null:
		popup_scelta.queue_free()
		popup_scelta = null
	var s := b.scelta_in_attesa
	if s.is_empty():
		return
	var pop := PanelContainer.new()
	pop.add_theme_stylebox_override("panel", UI.stile(UI.PANNELLO_2, UI.AMBRA, 2, 8, 16))
	var v := UI.vbox(10)
	v.custom_minimum_size = Vector2(560, 0)
	pop.add_child(v)
	var l := UI.etichetta(str(s.testo), 19)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var fl := HFlowContainer.new()
	for o in s.opzioni:
		var id := str(o.id)
		fl.add_child(UI.bottone(str(o.nome), func(): b.scegli(id); aggiorna()))
	v.add_child(fl)
	add_child(pop)
	popup_scelta = pop
	pop.position = Vector2(size.x * 0.3, size.y * 0.3)

## ---------------- fine ----------------

var _fine_mostrata := false

func _fine() -> void:
	if _fine_mostrata:
		return
	_fine_mostrata = true
	_intestazione()
	var es: Dictionary = b.esito_finale
	var pop := PanelContainer.new()
	pop.add_theme_stylebox_override("panel", UI.stile(UI.PANNELLO_2, UI.AMBRA, 2, 8, 18))
	var v := UI.vbox(10)
	v.custom_minimum_size = Vector2(640, 0)
	pop.add_child(v)
	v.add_child(UI.titolo("Vittoria!" if es.get("vinto", false) else "Battaglia conclusa", 36))
	var t := "Campo tenuto." if es.get("campo", false) else ("Nessun esito." if es.get("senza_esito", false) else "Non avete tenuto il campo.")
	t += "\nNemici fuori combattimento: %d. Membri dell'equipaggio diventati vittime: %d (tireranno sulla tabella delle ferite)." % [int(es.get("nemici_uccisi", 0)), es.get("perdite", []).size()]
	var l := UI.etichetta(t, 19)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	v.add_child(UI.bottone("Torna alla campagna: sequenza dopo la battaglia", _torna))
	add_child(pop)
	pop.position = (size - Vector2(680, 260)) / 2.0

func _torna() -> void:
	for r in b.log_righe:
		if r.tipo in ["titolo", "perdita", "obiettivo", "evento"]:
			c.scrivi(str(r.testo), "tiro")
	c.dopo_battaglia(b.esito_finale)
	main.salva(false)
	main.mostra_campagna()
