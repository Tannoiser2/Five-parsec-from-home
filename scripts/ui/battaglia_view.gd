## Vista della battaglia su griglia: il giocatore muove e fa agire l'equipaggio, l'IA muove i nemici.
extends Control

var main
var c: Campagna
var b: Battaglia
var tavolo
var info_fase: Label
var info_sel: RichTextLabel
var azioni: HFlowContainer
var registro: RichTextLabel
var sopra_lbl: Label
var sel: Dictionary = {}
var iniziativa_libera := false
var occupato := false
var log_visti := 0

func _ready() -> void:
	b = Battaglia.new(c.dadi.d(999999))
	var pgs := _schierati()
	b.prepara(c.s.battaglia, pgs, int(c.s.opzioni.get("celle_tavolo", 24)),
		{"eventi_battaglia": c.s.opzioni.get("eventi_battaglia", true), "tratti_mondo": c.s.mondo.get("tratti", []).map(func(t): return str(t.nome))})
	b.setup["difficolta"] = c.s.difficolta
	# consumabili dei personaggi
	for u in b.figure(Battaglia.EQ):
		var pg := c.trova(str(u.pg))
		var cons := []
		for o in pg.get("oggetti", []):
			var e: Dictionary = Dati.oggetto(str(o.id)).get("effetto", {})
			if e.has("consumabile"):
				cons.append(str(e.consumabile))
		u["consumabili"] = cons
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
	var dx := UI.vbox(8)
	dx.custom_minimum_size.x = 620
	radice.add_child(UI.pannello(dx))
	info_fase = UI.etichetta("", 24, UI.AMBRA, true)
	dx.add_child(info_fase)
	dx.add_child(UI.etichetta(str(c.s.battaglia.get("descrizione", "")), 16, UI.TENUE))
	info_sel = UI.testo_ricco("", 17)
	dx.add_child(info_sel)
	sopra_lbl = UI.etichetta("", 15, UI.ACQUA)
	sopra_lbl.custom_minimum_size.y = 44
	dx.add_child(sopra_lbl)
	azioni = HFlowContainer.new()
	dx.add_child(azioni)
	registro = RichTextLabel.new()
	registro.bbcode_enabled = true
	registro.scroll_following = true
	registro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	registro.add_theme_font_size_override("normal_font_size", 16)
	registro.add_theme_font_size_override("bold_font_size", 17)
	dx.add_child(registro)
	var leg := UI.etichetta("Clic su un tuo personaggio per selezionarlo, clic su una casella evidenziata per muovere (in arancio: scatto, senza poi agire), clic su un nemico per sparare (il numero è il tiro da ottenere) o, se è adiacente, per la Rissa. Tasto destro: deseleziona.", 14, UI.TENUE)
	dx.add_child(leg)
	var tot := b.tira_iniziativa()
	if tot >= 10:
		iniziativa_libera = true
		b.fase = "iniziativa"
	else:
		b.inizia_round()
	aggiorna()

func _schierati() -> Array:
	var r := []
	for id in c.s.get("schierati", []):
		var p := c.trova(str(id))
		if not p.is_empty() and Personaggio.disponibile(p):
			r.append(p)
	if r.is_empty():
		r = c.disponibili().slice(0, int(c.s.dimensione))
	return r

func aggiorna() -> void:
	var nomi := {"iniziativa": "Prendere l'iniziativa", "rapida": "Fase rapida", "nemici": "Fase dei nemici", "lenta": "Fase lenta", "fine": "Fine del round", "finita": "Battaglia conclusa"}
	info_fase.text = "ROUND %d - %s" % [b.round_n, nomi.get(b.fase, b.fase)] if b.round_n > 0 else nomi.get(b.fase, "")
	_registro()
	_info_sel()
	_azioni()
	tavolo.selezionata = sel.get("uid", -1)
	tavolo.raggiungibili = {}
	tavolo.raggiungibili_scatto = {}
	tavolo.bersagli = {}
	if not sel.is_empty() and sel.attiva and _puo_agire(sel):
		if not sel.mosso and not (iniziativa_libera and sel.agito):
			tavolo.raggiungibili = b.raggiungibili(sel, false)
			if not iniziativa_libera and not sel.agito and sel.stordito == 0:
				tavolo.raggiungibili_scatto = b.raggiungibili(sel, true)
		if not sel.agito and not (iniziativa_libera and sel.mosso):
			for t in b.bersagli(sel):
				tavolo.bersagli[t.u.uid] = int(t.netto) if not iniziativa_libera else 6
	tavolo.queue_redraw()
	if b.fase == "finita":
		_fine()

func _registro() -> void:
	var t := ""
	for r in b.log_righe.slice(max(0, b.log_righe.size() - 120)):
		t += UI.riga_bb(r) + "\n"
	registro.text = t

func _puo_agire(u: Dictionary) -> bool:
	if u.lato != Battaglia.EQ or not u.attiva or u.attivato:
		return false
	if iniziativa_libera:
		return not (u.mosso or u.agito)
	return u.fase == b.fase

func _info_sel() -> void:
	if sel.is_empty() or not sel.attiva:
		var att := b.da_attivare()
		info_sel.text = "Da attivare: " + (", ".join(att.map(func(u): return u.nome)) if not att.is_empty() else "nessuno")
		return
	var a := Dati.arma(str(sel.arma))
	var am := Dati.arma(str(sel.arma_m))
	var t := "[b]%s[/b]  R%d  V%d  C%+d  T%d%s%s\n" % [sel.nome, int(sel.reazioni), int(sel.velocita), int(sel.combattimento), int(sel.robustezza),
		("  salvezza %d+" % int(sel.salv_corazza)) if int(sel.salv_corazza) > 0 else "", ("  Fortuna %d" % int(sel.fortuna)) if int(sel.fortuna) > 0 else ""]
	t += "Tiro: %s   Rissa: %s\n" % [("%s (%d\", %d colpi, danno %+d)" % [a.nome, int(a.gittata), int(a.colpi), int(a.danno)]) if not a.is_empty() else "nessuna", str(am.get("nome", "a mani nude"))]
	t += "Fase %s.  %s, %s.%s" % [sel.fase, "si è mosso" if sel.mosso else "può muovere", "ha agito" if sel.agito else "può agire", ("  Stordito (%d): solo movimento o azione." % int(sel.stordito)) if int(sel.stordito) > 0 else ""]
	info_sel.text = t

func _azioni() -> void:
	UI.svuota(azioni)
	if occupato:
		return
	if b.fase == "finita":
		return
	if iniziativa_libera:
		azioni.add_child(UI.bottone("Fine dell'iniziativa: inizia il round 1", func(): iniziativa_libera = false; sel = {}; _reset_iniziativa(); b.inizia_round(); aggiorna()))
	elif b.fase in ["rapida", "lenta"]:
		if not sel.is_empty() and _puo_agire(sel):
			for az in b.azioni_obiettivo(sel):
				azioni.add_child(UI.bottone(az.nome, func(): b.azione(sel, az.id); _dopo_azione()))
			azioni.add_child(UI.bottone("Fine attivazione di " + str(sel.nome), func(): b.fine_attivazione(sel); sel = {}; _prossimo()))
		azioni.add_child(UI.bottone("Termina la fase", func(): sel = {}; _termina_fase()))
	elif b.fase == "fine":
		azioni.add_child(UI.bottone("Round successivo", func(): b.inizia_round(); sel = {}; _prossimo()))
	azioni.add_child(UI.bottone("Gioca il resto in automatico", _automatico, "L'equipaggio viene mosso dall'IA tattica fino alla fine"))
	azioni.add_child(UI.bottone("Ritirata", func(): b.ritirata(); aggiorna(), "Tutto l'equipaggio abbandona il campo"))

func _reset_iniziativa() -> void:
	for u in b.unita:
		u.mosso = false
		u.agito = false

func _sopra(p: Vector2i) -> void:
	if not b.dentro(p):
		sopra_lbl.text = ""
		return
	var t := str(Battaglia.NOMI_TERRENO.get(b.t_at(p), ""))
	for e in b.elementi:
		if p in e.celle:
			t = str(e.nome) + ": " + t
	var f := b.figura_in(p)
	if not f.is_empty():
		var a := Dati.arma(str(f.arma))
		t = "%s  (V%d C%+d T%d%s, %s%s)  -  %s" % [f.nome, int(f.velocita), int(f.combattimento), int(f.robustezza), (" salv. %d+" % int(f.salv_corazza)) if int(f.salv_corazza) > 0 else "", a.get("nome", "senza arma da tiro"), (", IA " + str(f.ia)) if f.lato == Battaglia.NEM else "", t]
		if not sel.is_empty() and f.lato == Battaglia.NEM:
			var s := b.soglia_colpire(sel, f)
			if s.ok:
				t += "  -  Per colpire: %d+%s, distanza %d%s" % [s.soglia, (" (mod %+d)" % s.mod) if s.mod != 0 else "", s.distanza, ", in copertura" if s.copertura else ""]
			else:
				t += "  -  Fuori tiro o non visibile (distanza %d)" % Battaglia.dist(sel.pos, f.pos)
	sopra_lbl.text = t

func _clic(p: Vector2i, destro: bool) -> void:
	if occupato or b.fase == "finita":
		return
	if destro:
		sel = {}
		aggiorna()
		return
	var f := b.figura_in(p)
	if not f.is_empty() and f.lato == Battaglia.EQ:
		if _puo_agire(f):
			sel = f
		aggiorna()
		return
	if sel.is_empty() or not _puo_agire(sel):
		return
	if not f.is_empty() and f.lato == Battaglia.NEM:
		if Battaglia.dist(sel.pos, f.pos) == 1 and not iniziativa_libera:
			if not sel.agito and not sel.scatto and (sel.stordito == 0 or not sel.mosso):
				b.rissa(sel, f)
				_dopo_azione()
			return
		if tavolo.bersagli.has(f.uid):
			tavolo.linea_tiro = [sel.pos, f.pos]
			b.spara(sel, f, "", iniziativa_libera)
			_dopo_azione()
		return
	if tavolo.raggiungibili.has(p) or tavolo.raggiungibili_scatto.has(p):
		var scatto: bool = not tavolo.raggiungibili.has(p)
		var da: Vector2i = sel.pos
		if b.muovi(sel, p, scatto):
			_anima(sel, da, p)
			if iniziativa_libera:
				sel.agito = true
			_dopo_azione()

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
		var finito: bool = (sel.mosso and sel.agito) or not sel.attiva or (sel.stordito > 0 and (sel.mosso or sel.agito)) or (iniziativa_libera and (sel.mosso or sel.agito))
		if finito and not iniziativa_libera:
			b.fine_attivazione(sel)
			sel = {}
			_prossimo()
			return
		if finito:
			sel = {}
	aggiorna()

## Seleziona il prossimo personaggio da attivare o passa alla fase successiva.
func _prossimo() -> void:
	if b.fase in ["rapida", "lenta"] and b.da_attivare().is_empty():
		_termina_fase()
		return
	if b.fase in ["rapida", "lenta"] and sel.is_empty():
		var att := b.da_attivare()
		if not att.is_empty():
			sel = att[0]
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
	if b.fase == "iniziativa":
		b.inizia_round()
	var guardia := 0
	while b.fase != "finita" and guardia < 60:
		guardia += 1
		if b.fase in ["rapida", "lenta"]:
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

var _fine_mostrata := false

func _fine() -> void:
	if _fine_mostrata:
		return
	_fine_mostrata = true
	var es: Dictionary = b.esito_finale
	var pop := PanelContainer.new()
	pop.add_theme_stylebox_override("panel", UI.stile(UI.PANNELLO_2, UI.AMBRA, 2, 8, 18))
	var v := UI.vbox(10)
	v.custom_minimum_size = Vector2(640, 0)
	pop.add_child(v)
	v.add_child(UI.titolo("Vittoria!" if es.get("vinto", false) else "Battaglia conclusa", 36))
	var t := "Campo tenuto." if es.get("campo", false) else "Non avete tenuto il campo."
	t += "\nNemici fuori combattimento: %d. Membri dell'equipaggio diventati vittime: %d (tireranno sulla tabella delle ferite)." % [int(es.get("nemici_uccisi", 0)), es.get("perdite", []).size()]
	v.add_child(UI.etichetta(t, 19))
	v.add_child(UI.bottone("Torna alla campagna: sequenza dopo la battaglia", _torna))
	add_child(pop)
	pop.set_anchors_preset(Control.PRESET_CENTER)
	pop.position = (size - Vector2(680, 260)) / 2.0

func _torna() -> void:
	for r in b.log_righe:
		if r.tipo in ["titolo", "perdita", "obiettivo", "evento"]:
			c.scrivi(str(r.testo), "tiro")
	c.dopo_battaglia(b.esito_finale)
	main.salva(false)
	main.mostra_campagna()
