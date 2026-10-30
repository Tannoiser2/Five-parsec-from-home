## Tema grafico «frontiera» e piccoli costruttori di controlli.
## Regola: solo testo e disegni, nessun simbolo Unicode fuori dai font (vedi tools/controlla_glifi.py).
class_name UI
extends RefCounted

const SFONDO := Color(0.043, 0.055, 0.075)
const PANNELLO := Color(0.075, 0.09, 0.12, 0.96)
const PANNELLO_2 := Color(0.10, 0.12, 0.16, 0.96)
const BORDO := Color(0.85, 0.58, 0.22)
const AMBRA := Color(0.95, 0.68, 0.28)
const TESTO := Color(0.91, 0.89, 0.82)
const TENUE := Color(0.62, 0.64, 0.66)
const ACQUA := Color(0.36, 0.78, 0.80)
const ROSSO := Color(0.88, 0.33, 0.30)
const VERDE := Color(0.45, 0.80, 0.45)
const VIOLA := Color(0.70, 0.55, 0.90)

static var font_testo: Font
static var font_titoli: Font
static var tema: Theme

static func carica_font() -> void:
	if font_testo != null:
		return
	font_testo = _font("res://assets/fonts/Exo2.ttf", 420)
	font_titoli = _font("res://assets/fonts/Oxanium.ttf", 650)

static func _font(path: String, peso: int) -> Font:
	var base: FontFile = load(path)
	var v := FontVariation.new()
	v.base_font = base
	v.variation_opentype = {"wght": peso}
	return v

static func crea_tema() -> Theme:
	carica_font()
	if tema != null:
		return tema
	var t := Theme.new()
	t.default_font = font_testo
	t.default_font_size = 20
	t.set_color("font_color", "Label", TESTO)
	t.set_color("default_color", "RichTextLabel", TESTO)
	t.set_font("normal_font", "RichTextLabel", font_testo)
	t.set_font("bold_font", "RichTextLabel", font_titoli)
	t.set_font_size("normal_font_size", "RichTextLabel", 19)
	t.set_font_size("bold_font_size", "RichTextLabel", 19)
	for tipo in ["Button", "OptionButton", "CheckBox", "MenuButton"]:
		t.set_color("font_color", tipo, TESTO)
		t.set_color("font_hover_color", tipo, Color.WHITE)
		t.set_color("font_pressed_color", tipo, SFONDO)
		t.set_color("font_disabled_color", tipo, Color(0.45, 0.45, 0.45))
		t.set_font(tipo if tipo != "MenuButton" else "MenuButton", tipo, font_titoli)
		t.set_font("font", tipo, font_titoli)
		t.set_font_size("font_size", tipo, 19)
	t.set_stylebox("normal", "Button", stile(PANNELLO_2, BORDO.darkened(0.35), 1, 4))
	t.set_stylebox("hover", "Button", stile(Color(0.16, 0.18, 0.22), AMBRA, 2, 4))
	t.set_stylebox("pressed", "Button", stile(AMBRA, AMBRA, 2, 4))
	t.set_stylebox("disabled", "Button", stile(Color(0.08, 0.09, 0.1), Color(0.25, 0.25, 0.25), 1, 4))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for k in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(k, "OptionButton", t.get_stylebox(k, "Button"))
	t.set_stylebox("panel", "PanelContainer", stile(PANNELLO, BORDO.darkened(0.45), 1, 6))
	t.set_stylebox("panel", "PopupMenu", stile(PANNELLO_2, BORDO, 1, 4))
	t.set_color("font_color", "PopupMenu", TESTO)
	t.set_font("font", "PopupMenu", font_testo)
	t.set_font_size("font_size", "PopupMenu", 19)
	t.set_stylebox("normal", "LineEdit", stile(Color(0.05, 0.06, 0.08), BORDO.darkened(0.3), 1, 3))
	t.set_stylebox("focus", "LineEdit", stile(Color(0.05, 0.06, 0.08), AMBRA, 1, 3))
	t.set_color("font_color", "LineEdit", TESTO)
	t.set_font_size("font_size", "LineEdit", 20)
	t.set_stylebox("panel", "TabContainer", stile(PANNELLO, BORDO.darkened(0.45), 1, 4))
	t.set_stylebox("tab_selected", "TabContainer", stile(PANNELLO_2, AMBRA, 2, 4))
	t.set_stylebox("tab_unselected", "TabContainer", stile(Color(0.06, 0.07, 0.09), BORDO.darkened(0.5), 1, 4))
	t.set_stylebox("tab_hovered", "TabContainer", stile(Color(0.12, 0.13, 0.16), AMBRA, 1, 4))
	t.set_font("font", "TabContainer", font_titoli)
	t.set_font_size("font_size", "TabContainer", 18)
	t.set_color("font_selected_color", "TabContainer", AMBRA)
	t.set_color("font_unselected_color", "TabContainer", TENUE)
	t.set_stylebox("panel", "PopupPanel", stile(PANNELLO_2, AMBRA, 2, 6))
	t.set_constant("separation", "VBoxContainer", 6)
	t.set_constant("separation", "HBoxContainer", 8)
	t.set_color("font_color", "CheckBox", TESTO)
	t.set_stylebox("grabber_area", "HSlider", stile(AMBRA, AMBRA, 0, 2))
	t.set_stylebox("slider", "HSlider", stile(Color(0.2, 0.2, 0.22), Color(0.2, 0.2, 0.22), 0, 2))
	t.set_stylebox("normal", "TooltipPanel", stile(PANNELLO_2, AMBRA, 1, 3))
	t.set_stylebox("panel", "TooltipPanel", stile(PANNELLO_2, AMBRA, 1, 3))
	t.set_color("font_color", "TooltipLabel", TESTO)
	t.set_font_size("font_size", "TooltipLabel", 17)
	tema = t
	return t

static func stile(fondo: Color, bordo: Color, spessore := 1, raggio := 4, margine := 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = bordo
	s.set_border_width_all(spessore)
	s.set_corner_radius_all(raggio)
	s.content_margin_left = margine + 2
	s.content_margin_right = margine + 2
	s.content_margin_top = margine - 2
	s.content_margin_bottom = margine - 2
	return s

static func etichetta(testo: String, dim := 20, colore := TESTO, titolo := false) -> Label:
	carica_font()
	var l := Label.new()
	l.text = testo
	l.add_theme_font_size_override("font_size", dim)
	l.add_theme_color_override("font_color", colore)
	if titolo:
		l.add_theme_font_override("font", font_titoli)
	# a capo solo per i testi lunghi: le etichette brevi dentro le righe non devono restringersi
	if testo.length() > 48:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.x = 220
	return l

static func titolo(testo: String, dim := 30) -> Label:
	return etichetta(testo.to_upper(), dim, AMBRA, true)

static func bottone(testo: String, azione: Callable, suggerimento := "") -> Button:
	var b := Button.new()
	b.text = testo
	b.tooltip_text = suggerimento
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(azione)
	return b

static func testo_ricco(bb: String, dim := 19) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = bb
	r.add_theme_font_size_override("normal_font_size", dim)
	r.add_theme_font_size_override("bold_font_size", dim)
	r.selection_enabled = false
	return r

static func pannello(contenuto: Control = null, fondo := PANNELLO, bordo := Color(0, 0, 0, 0)) -> PanelContainer:
	var p := PanelContainer.new()
	if bordo.a > 0:
		p.add_theme_stylebox_override("panel", stile(fondo, bordo, 1, 6))
	if contenuto != null:
		p.add_child(contenuto)
	return p

static func vbox(sep := 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func scorrimento(contenuto: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	contenuto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(contenuto)
	return s

static func svuota(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()

static func colore_tipo(tipo: String) -> String:
	match tipo:
		"titolo":
			return "#f2ad48"
		"pericolo", "morte", "perdita":
			return "#e05a52"
		"ferita":
			return "#e08a52"
		"evento":
			return "#9fd0d2"
		"manuale":
			return "#c8a0f0"
		"missione", "obiettivo":
			return "#7fd17f"
		"rivale":
			return "#e07a6a"
		"patrono":
			return "#8fc8ff"
		"tiro":
			return "#d8d2c2"
	return "#e8e2d0"

## Riga di diario in BBCode (i testi vengono dai dati: si tolgono le parentesi quadre).
static func riga_bb(r: Dictionary) -> String:
	var t := str(r.get("testo", "")).replace("[", "(").replace("]", ")")
	var tipo := str(r.get("tipo", ""))
	if tipo == "titolo":
		return "[b][color=%s]%s[/color][/b]" % [colore_tipo(tipo), t]
	if tipo == "manuale":
		return "[color=%s]Regola da applicare a mano: %s[/color]" % [colore_tipo(tipo), t]
	return "[color=%s]%s[/color]" % [colore_tipo(tipo), t]
