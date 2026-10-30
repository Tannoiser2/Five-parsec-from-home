## Radice del gioco: sfondo stellato e passaggio tra le viste (menu, creazione, campagna, battaglia, regole).
extends Control

var net: Net
var campagna: Campagna
var vista: Control
var sfondo: Control
var avviso: Label

func _ready() -> void:
	Dati.carica()
	theme = UI.crea_tema()
	sfondo = preload("res://scripts/ui/sfondo.gd").new()
	sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sfondo)
	net = Net.new()
	add_child(net)
	avviso = UI.etichetta("", 20, UI.AMBRA, true)
	avviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	avviso.position.y -= 70
	avviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avviso.z_index = 50
	mostra_menu()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_F11:
		var w := get_window()
		w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN

func _cambia(v: Control) -> void:
	if vista != null:
		remove_child(vista)
		vista.queue_free()
	vista = v
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(v)
	if avviso.get_parent() == null:
		add_child(avviso)
	move_child(avviso, get_child_count() - 1)

func mostra_menu() -> void:
	sfondo.pianeta = true
	var m = preload("res://scripts/ui/menu.gd").new()
	m.main = self
	_cambia(m)

func mostra_creazione() -> void:
	sfondo.pianeta = false
	var v = preload("res://scripts/ui/creazione_view.gd").new()
	v.main = self
	_cambia(v)

func mostra_campagna(c: Campagna = null) -> void:
	sfondo.pianeta = false
	if c != null:
		campagna = c
	var v = preload("res://scripts/ui/campagna_view.gd").new()
	v.main = self
	v.c = campagna
	_cambia(v)

func mostra_battaglia() -> void:
	sfondo.pianeta = false
	var v = preload("res://scripts/ui/battaglia_view.gd").new()
	v.main = self
	v.c = campagna
	_cambia(v)

func mostra_regole() -> void:
	var r = preload("res://scripts/ui/regole_view.gd").new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(r)

## Salva in locale (sempre) e, se richiesto, nel cloud.
func salva(cloud := false) -> void:
	if campagna == null:
		return
	var st := campagna.salva()
	Salvataggi.salva_locale(st)
	if cloud:
		mostra_avviso("Salvataggio nel cloud...")
		var ok: bool = await net.salva_campagna(str(st.get("codice", "")), st)
		mostra_avviso("Campagna salvata nel cloud: codice %s" % st.codice if ok else "Salvataggio nel cloud non riuscito: " + net.last_error, 6.0)
	else:
		mostra_avviso("Campagna salvata (codice %s)." % st.get("codice", ""))

func mostra_avviso(t: String, durata := 3.0) -> void:
	avviso.text = t
	avviso.size.x = size.x
	avviso.position = Vector2(0, size.y - 80)
	var tw := create_tween()
	avviso.modulate.a = 1.0
	tw.tween_interval(durata)
	tw.tween_property(avviso, "modulate:a", 0.0, 0.6)
