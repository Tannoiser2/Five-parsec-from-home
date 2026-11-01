## Campo di battaglia in 3D: plancia, elementi di scena come cartoncini spessi (sagoma ritagliata dall'immagine
## ed estrusa), edifici con muri, pedine come dischi di cartone, linea di vista e colpi animati.
## Ha la stessa interfaccia di tavolo.gd (2D), così battaglia_view usa l'uno o l'altro senza differenze.
## Scala: 1 casella = 1 pollice = 1 unità; lo spessore minimo dei cartoncini è 1 cm (0,4").
extends SubViewportContainer

signal cella_cliccata(p: Vector2i, destro: bool)
signal cella_sopra(p: Vector2i)

var b: Battaglia
var raggiungibili := {}
var raggiungibili_scatto := {}
var bersagli := {}       # uid -> soglia
var selezionata := -1
var sopra := Vector2i(-1, -1)
var linea_tiro := []     # compatibilità con il 2D (non usata)
var anim := {}           # uid -> posizione (coordinate di griglia, come centro_cella) per l'animazione
var colpi: Array = []    # animazioni in corso: {da, a, lato, n, t, rissa, nodi}
var ultimo_tiro := {}
var mostra_vista := true

const SPESSORE := 0.4    # 1 cm
const VOLO := 0.32
const RITMO := 0.11
const CARTONE := Color(0.55, 0.46, 0.34)
const CARTONE_SCURO := Color(0.42, 0.35, 0.26)
const PX := 32           # pixel per casella nella texture della griglia

var vp: SubViewport
var mondo: Node3D
var cam: Camera3D
var luce: DirectionalLight3D
var ambiente: Environment
var n_terreno: Node3D
var n_figure: Node3D
var n_segni: Node3D
var n_vista: Node3D
var n_tiro: Node3D
var n_colpi: Node3D
var griglia: MeshInstance3D
var griglia_img: Image
var griglia_tex: ImageTexture
var aiuto: Label

var _firma_terreno := 0
var _firma_griglia := 0
var _firma_vista := ""
var _firma_tiro := ""
var _pedine := {}        # uid -> {nodo, disco, anello, etichetta, ...}
var _mat_cache := {}
var _mesh_cache := {}

# camera in orbita
var yaw := 0.0
var pitch := deg_to_rad(55.0)
var distanza := 30.0
var fuoco := Vector3.ZERO
var _destro := false
var _centrale := false
var _trascinato := false
var _premuto_a := Vector2.ZERO

func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.handle_input_locally = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	mondo = Node3D.new()
	vp.add_child(mondo)
	var we := WorldEnvironment.new()
	ambiente = Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.035, 0.04, 0.055)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.75, 0.78, 0.85)
	ambiente.ambient_light_energy = 0.38
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambiente.fog_sky_affect = 0.0
	we.environment = ambiente
	mondo.add_child(we)
	luce = DirectionalLight3D.new()
	luce.light_energy = 0.85
	luce.light_color = Color(1.0, 0.95, 0.86)
	luce.shadow_enabled = true
	luce.directional_shadow_max_distance = 80.0
	luce.rotation_degrees = Vector3(-52, -38, 0)
	mondo.add_child(luce)
	cam = Camera3D.new()
	cam.fov = 38.0
	cam.near = 0.1
	cam.far = 300.0
	mondo.add_child(cam)
	for nome in ["n_terreno", "n_figure", "n_segni", "n_vista", "n_tiro", "n_colpi"]:
		var n := Node3D.new()
		n.name = nome
		mondo.add_child(n)
		set(nome, n)
	aiuto = Label.new()
	aiuto.text = "Tasto destro e trascina: ruota   Rotella: zoom   Tasto centrale (o Maiusc + destro): sposta   Doppio clic destro: vista iniziale"
	aiuto.add_theme_font_size_override("font_size", 13)
	aiuto.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8, 0.75))
	aiuto.add_theme_color_override("font_outline_color", Color.BLACK)
	aiuto.add_theme_constant_override("outline_size", 4)
	aiuto.position = Vector2(10, 6)
	aiuto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(aiuto)
	resized.connect(func(): if vp != null: vp.size = Vector2i(size))

## ---------------- interfaccia comune con il 2D ----------------

func centro_cella(p: Vector2i) -> Vector2:
	return Vector2(p) + Vector2(0.5, 0.5)

func spara(da: Vector2i, a: Vector2i, lato_: String, n := 1, genere := "proiettile") -> void:
	colpi.append({"da": da, "a": a, "lato": lato_, "n": clampi(n, 1, 6), "t": 0.0, "rissa": false, "nodi": [], "genere": genere})
	ultimo_tiro = {"da": da, "a": a, "lato": lato_, "t": 0.0}

var esplosioni: Array = []

func esplosione(pos: Vector2i, raggio: int, genere: String, ritardo := 0.0) -> void:
	esplosioni.append({"pos": pos, "raggio": raggio, "genere": genere, "t": -ritardo, "scoppiata": false, "nodi": []})

func rissa(da: Vector2i, a: Vector2i, lato_: String) -> void:
	colpi.append({"da": da, "a": a, "lato": lato_, "n": 1, "t": 0.0, "rissa": true, "nodi": []})

func vista_iniziale() -> void:
	if b == null:
		return
	yaw = 0.0
	pitch = deg_to_rad(55.0)
	distanza = float(max(b.W, b.H)) * 1.45
	fuoco = Vector3(b.W / 2.0, 0.0, b.H / 2.0 + 0.5)

## ---------------- ciclo ----------------

func _process(d: float) -> void:
	if b == null or vp == null:
		return
	if vp.size != Vector2i(size) and size.x > 0:
		vp.size = Vector2i(size)
	var ft := hash([b.celle, b.alt, b.porte_aperte.keys(), b.W, b.H, b.ambiente, b.elementi.size()])
	if ft != _firma_terreno:
		if _firma_terreno == 0:
			vista_iniziale()
		_firma_terreno = ft
		_costruisci_terreno()
		_atmosfera()
	_aggiorna_griglia()
	_aggiorna_figure()
	_aggiorna_segni()
	_aggiorna_vista()
	_aggiorna_tiro(d)
	_aggiorna_colpi(d)
	_aggiorna_esplosioni(d)
	_aggiorna_atmosfera()
	_aggiorna_camera()

func _aggiorna_camera() -> void:
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	cam.position = fuoco + dir * distanza
	cam.look_at(fuoco, Vector3.UP)

## ---------------- input: scelta della casella e camera ----------------

func _gui_input(e: InputEvent) -> void:
	if b == null:
		return
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			distanza = clampf(distanza * 0.9, 6.0, 90.0)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			distanza = clampf(distanza * 1.1, 6.0, 90.0)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_centrale = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				if mb.double_click:
					vista_iniziale()
					_destro = false
					return
				_destro = true
				_trascinato = false
				_premuto_a = mb.position
			else:
				_destro = false
				if not _trascinato:
					var p := cella_da(mb.position)
					if b.dentro(p):
						cella_cliccata.emit(p, true)
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var p := cella_da(mb.position)
			if b.dentro(p):
				cella_cliccata.emit(p, false)
	elif e is InputEventMouseMotion:
		var mm := e as InputEventMouseMotion
		if _destro and mm.position.distance_to(_premuto_a) > 4.0:
			_trascinato = true
		if _centrale or (_destro and mm.shift_pressed):
			var dx := Vector3(cos(yaw), 0, -sin(yaw))
			var dz := Vector3(sin(yaw), 0, cos(yaw))
			fuoco -= (dx * mm.relative.x + dz * mm.relative.y) * distanza * 0.0016
			fuoco.x = clampf(fuoco.x, -2.0, b.W + 2.0)
			fuoco.z = clampf(fuoco.z, -2.0, b.H + 2.0)
		elif _destro and _trascinato:
			yaw -= mm.relative.x * 0.008
			pitch = clampf(pitch + mm.relative.y * 0.006, deg_to_rad(18.0), deg_to_rad(88.0))
		var p := cella_da(mm.position)
		if p != sopra:
			sopra = p
			cella_sopra.emit(p)

## Casella sotto il punto dello schermo: prova le superfici più alte (tetti, massi) prima del suolo.
func cella_da(pos: Vector2) -> Vector2i:
	if cam == null or b == null:
		return Vector2i(-1, -1)
	var o := cam.project_ray_origin(pos)
	var dr := cam.project_ray_normal(pos)
	if absf(dr.y) < 0.0001:
		return Vector2i(-1, -1)
	var altezze := {}
	for h in b.alt:
		altezze[h] = true
	var hs := altezze.keys()
	hs.sort()
	hs.reverse()
	for h in hs:
		var t := (float(h) - o.y) / dr.y
		if t <= 0:
			continue
		var q := o + dr * t
		var c := Vector2i(floori(q.x), floori(q.z))
		if not b.dentro(c):
			continue
		if int(h) == 0 or b.a_at(c) == int(h):
			return c
	return Vector2i(-1, -1)

## ---------------- materiali e mesh ----------------

func _mat(chiave: String, col: Color, tex: Texture2D = null, emissivo := false, trasparente := false) -> StandardMaterial3D:
	var k := "%s|%s|%d|%s|%s" % [chiave, col.to_html(), tex.get_rid().get_id() if tex != null else 0, emissivo, trasparente]
	if _mat_cache.has(k):
		return _mat_cache[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.95
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if tex != null:
		m.albedo_texture = tex
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.45
	if emissivo:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.emission_enabled = true
		m.emission = col
	if trasparente:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.no_depth_test = false
	_mat_cache[k] = m
	return m

## Materiale non condiviso per effetti che sfumano (non va in cache).
func _mat_sfumato(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _mi(mesh: Mesh, mat: Material, padre: Node3D, pos := Vector3.ZERO, ombra := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if ombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mi)
	return mi

func _box(sz: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = sz
	return m

## Sagoma estrusa da un'immagine con trasparenza: base 1x1 centrata, alta 1. Superficie 0: faccia superiore con
## l'immagine; superficie 1: bordi di cartone. Senza trasparenza diventa una piastrella quadrata.
func _sagoma(tex: Texture2D, regione := Rect2(0, 0, 1, 1)) -> ArrayMesh:
	var k := "%d|%s" % [tex.get_rid().get_id(), regione]
	if _mesh_cache.has(k):
		return _mesh_cache[k]
	var img := tex.get_image()
	var poligoni: Array = []
	if img != null:
		if img.is_compressed():
			img.decompress()
		img = img.duplicate()
		img.clear_mipmaps()
		var full := img.get_size()
		var reg := Rect2i(Vector2i(int(regione.position.x * full.x), int(regione.position.y * full.y)), Vector2i(int(regione.size.x * full.x), int(regione.size.y * full.y)))
		img = img.get_region(reg)
		var lato_max := 96
		var sc := float(lato_max) / float(max(img.get_width(), img.get_height()))
		if sc < 1.0:
			img.resize(maxi(4, int(img.get_width() * sc)), maxi(4, int(img.get_height() * sc)), Image.INTERPOLATE_BILINEAR)
		if img.detect_alpha() != Image.ALPHA_NONE:
			var bm := BitMap.new()
			bm.create_from_image_alpha(img, 0.4)
			var sz := Vector2(img.get_size())
			for pol in bm.opaque_to_polygons(Rect2i(Vector2i.ZERO, img.get_size()), 1.2):
				var pts := PackedVector2Array()
				for v in pol:
					pts.append(Vector2(v) / sz)
				if absf(_area(pts)) > 0.004:
					poligoni.append(pts)
	if poligoni.is_empty():
		poligoni = [PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])]
	var sopra_st := SurfaceTool.new()
	sopra_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lati_st := SurfaceTool.new()
	lati_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for pts in poligoni:
		var tri := Geometry2D.triangulate_polygon(pts)
		if tri.is_empty():
			pts = Geometry2D.convex_hull(pts)
			tri = Geometry2D.triangulate_polygon(pts)
		for i in tri:
			var v: Vector2 = pts[i]
			sopra_st.set_normal(Vector3.UP)
			sopra_st.set_uv(regione.position + v * regione.size)
			sopra_st.add_vertex(Vector3(v.x - 0.5, 1.0, v.y - 0.5))
		for i in pts.size():
			var a: Vector2 = pts[i]
			var c: Vector2 = pts[(i + 1) % pts.size()]
			var n := Vector3(c.y - a.y, 0, -(c.x - a.x)).normalized()
			var va := Vector3(a.x - 0.5, 0, a.y - 0.5)
			var vc := Vector3(c.x - 0.5, 0, c.y - 0.5)
			for q in [va, vc, vc + Vector3.UP, va, vc + Vector3.UP, va + Vector3.UP]:
				lati_st.set_normal(n)
				lati_st.set_uv(Vector2(0, (q as Vector3).y))
				lati_st.add_vertex(q)
	var m := sopra_st.commit()
	m = lati_st.commit(m)
	_mesh_cache[k] = m
	return m

static func _area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in p.size():
		var q := p[(i + 1) % p.size()]
		a += p[i].x * q.y - q.x * p[i].y
	return a / 2.0

## Cartoncino: sagoma dell'immagine estrusa, centrata in c (x, z), larga w x d, alta h, appoggiata a quota y0.
func _cartoncino(tex: Texture2D, c: Vector2, w: float, d: float, h: float, y0 := 0.0, ruota := false, regione := Rect2(0, 0, 1, 1)) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _sagoma(tex, regione)
	mi.set_surface_override_material(0, _mat("cartoncino", Color.WHITE, tex))
	mi.set_surface_override_material(1, _mat("bordo", CARTONE))
	mi.position = Vector3(c.x, y0, c.y)
	if ruota:
		mi.rotation.y = PI / 2.0
		mi.scale = Vector3(d, h, w)
	else:
		mi.scale = Vector3(w, h, d)
	n_terreno.add_child(mi)
	return mi

## ---------------- costruzione del terreno ----------------

const ELEMENTI_IMG := {"Edificio chiuso": "edificio", "Navetta atterrata": "navetta_atterrata", "Container": "container",
	"Masso": "masso", "Bosco": "bosco", "Rovine": "rovine", "Cespugli": "cespugli", "Vegetazione": "vegetazione", "Cratere": "rovine"}
const PER_CELLA := {"Muro in rovina": "rovine_muro", "Deposito di casse": "cassa", "Barili": "barile", "Alberi": "albero", "Casse della navetta": "casse_navetta"}
const LINEARI := {"Barricata": "barricata", "Recinzione": "recinzione", "Muretto": "muretto", "Siepe": "siepe",
	"Sacchi di sabbia": "sacchi_sabbia", "Muro di forza": "muro_forza"}
const ORIENTABILI := ["edificio", "edificio_grande", "navetta_atterrata", "container", "masso"]

func _elem(nome: String) -> Texture2D:
	return Immagini.texture("mappe/elementi/" + nome)

func _bbox(celle: Array) -> Rect2:
	var a := Vector2i(999, 999)
	var z := Vector2i(-1, -1)
	for c in celle:
		a = Vector2i(min(a.x, c.x), min(a.y, c.y))
		z = Vector2i(max(z.x, c.x), max(z.y, c.y))
	return Rect2(Vector2(a), Vector2(z - a + Vector2i.ONE))

func _costruisci_terreno() -> void:
	for n in n_terreno.get_children():
		n.queue_free()
	var W := b.W
	var H := b.H
	var amb := str(b.ambiente)
	# base del tavolo: lastra di cartone con la plancia sopra
	_mi(_box(Vector3(W + 0.8, 0.6, H + 0.8)), _mat("base", Color(0.10, 0.09, 0.08)), n_terreno, Vector3(W / 2.0, -0.31, H / 2.0))
	var plancia := Immagini.texture("mappe/plancia_" + amb)
	var suolo := Immagini.texture("mappe/suolo_" + amb)
	var pm := PlaneMesh.new()
	pm.size = Vector2(W, H)
	var mat_suolo: StandardMaterial3D
	if plancia != null:
		mat_suolo = _mat("plancia", Color.WHITE, plancia)
	elif suolo != null:
		mat_suolo = _mat("suolo", Color.WHITE, suolo).duplicate()
		mat_suolo.uv1_scale = Vector3(W / 4.0, H / 4.0, 1)
	else:
		mat_suolo = _mat("suolo_tinta", Color(0.32, 0.28, 0.22))
	mat_suolo.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	var ms := _mi(pm, mat_suolo, n_terreno, Vector3(W / 2.0, 0.0, H / 2.0), false)
	ms.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# griglia ed evidenziazioni: texture trasparente appena sopra il suolo
	griglia_img = Image.create(W * PX, H * PX, false, Image.FORMAT_RGBA8)
	griglia_tex = ImageTexture.create_from_image(griglia_img)
	var gm := StandardMaterial3D.new()
	gm.albedo_texture = griglia_tex
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var gpm := PlaneMesh.new()
	gpm.size = Vector2(W, H)
	griglia = _mi(gpm, gm, n_terreno, Vector3(W / 2.0, 0.02, H / 2.0), false)
	_firma_griglia = -1
	# terreno difficile (campi)
	var campo := Immagini.texture("mappe/campo_" + amb)
	var mat_campo := _mat("campo", Color(0.25, 0.32, 0.36) if campo == null else Color.WHITE, campo)
	for y in H:
		for x in W:
			var p := Vector2i(x, y)
			if b.t_at(p) == Battaglia.T.CAMPO:
				var q := PlaneMesh.new()
				q.size = Vector2(1, 1)
				var mi := _mi(q, mat_campo, n_terreno, Vector3(x + 0.5, 0.012, y + 0.5), false)
				if campo != null:
					var m2: StandardMaterial3D = mat_campo.duplicate()
					m2.uv1_scale = Vector3(0.25, 0.25, 1)
					m2.uv1_offset = Vector3((x % 4) * 0.25, (y % 4) * 0.25, 0)
					mi.material_override = m2
				if b.impraticabili.has(p):
					mi.material_override = _mat("tossico", Color(0.35, 0.7, 0.2))
	# elementi
	var solidi := {}
	var ordinati := b.elementi.filter(func(e): return e.tipo == Battaglia.T.AREA) + b.elementi.filter(func(e): return e.tipo != Battaglia.T.AREA)
	for e in ordinati:
		var nome := str(e.nome)
		var celle: Array = e.celle
		if e.get("interno", false) or celle.is_empty():
			continue
		var tipo := int(e.tipo)
		if tipo in [Battaglia.T.BLOCCO, Battaglia.T.SINGOLO]:
			for c in celle:
				solidi[c] = true
		var h := _altezza_elemento(e)
		if _elemento_modello(e, h):
			continue
		if PER_CELLA.has(nome) and _elem(PER_CELLA[nome]) != null:
			var tex := _elem(PER_CELLA[nome])
			for c in celle:
				var cc := Vector2(c) + Vector2(0.5, 0.5)
				var y0 := 0.0
				if tipo == Battaglia.T.BLOCCO:
					h = maxf(SPESSORE, float(b.a_at(c)))
				if nome == "Alberi":
					# tronco e chioma di cartone
					var tr := CylinderMesh.new()
					tr.top_radius = 0.09
					tr.bottom_radius = 0.12
					tr.height = H_CHIOMA - 0.9
					_mi(tr, _mat("tronco", Color(0.36, 0.26, 0.17)), n_terreno, Vector3(cc.x, (H_CHIOMA - 0.9) / 2.0, cc.y))
					_cartoncino(tex, cc, 1.35, 1.35, 0.9, H_CHIOMA - 0.9)
				else:
					_cartoncino(tex, cc, 1.0, 1.0, h, y0)
		elif LINEARI.has(nome) and _elem(LINEARI[nome]) != null:
			_lineare(_elem(LINEARI[nome]), celle, nome == "Muro di forza")
		elif ELEMENTI_IMG.has(nome) and _elem(ELEMENTI_IMG[nome]) != null:
			var chiave: String = ELEMENTI_IMG[nome]
			if chiave == "edificio" and celle.size() >= 20 and _elem("edificio_grande") != null:
				chiave = "edificio_grande"
			var tex := _elem(chiave)
			var bb := _bbox(celle)
			var area := tipo == Battaglia.T.AREA or nome == "Cratere"
			if area:
				bb = bb.grow(0.15)
			var ts := tex.get_size()
			var ruota: bool = chiave in ORIENTABILI and ts.x > ts.y * 1.1 and bb.size.y > bb.size.x * 1.1
			_cartoncino(tex, bb.get_center(), bb.size.x, bb.size.y, h, 0.0, ruota)
			if area:
				_decora_area(e)
		else:
			_ripiego(e, h)
	# muri degli edifici con interno, muri di forza e blocchi isolati
	var mat_muro := _mat("muro", Color(0.52, 0.50, 0.46))
	var mat_pav := _mat("pavimento", Color(0.30, 0.27, 0.23))
	for y in H:
		for x in W:
			var p := Vector2i(x, y)
			var t := b.t_at(p)
			var cc := Vector3(x + 0.5, 0, y + 0.5)
			match t:
				Battaglia.T.INTERNO:
					_mi(_box(Vector3(1, 0.06, 1)), mat_pav, n_terreno, cc + Vector3(0, 0.03, 0), false)
				Battaglia.T.MURO, Battaglia.T.PORTA, Battaglia.T.FINESTRA:
					_muro(p, t, mat_muro)
				Battaglia.T.MURO_FORZA:
					var mf := _mat("forza", Color(0.3, 0.8, 1.0, 0.45), null, false, true)
					_mi(_box(Vector3(1, 2.0, 0.25)), mf, n_terreno, cc + Vector3(0, 1.0, 0), false)
				Battaglia.T.BLOCCO:
					if not solidi.has(p):
						var hb := maxf(SPESSORE, float(b.a_at(p)))
						var mr := _elem("rovine_muro")
						if mr != null:
							_cartoncino(mr, Vector2(cc.x, cc.z), 1.0, 1.0, hb)
						else:
							_mi(_box(Vector3(0.96, hb, 0.96)), _mat("blocco", Color(0.45, 0.46, 0.5)), n_terreno, cc + Vector3(0, hb / 2.0, 0))

const H_CHIOMA := 2.0

## Altezza del cartoncino: quella di gioco (blocchi, ostacoli lineari, elementi singoli), almeno 1 cm.
func _altezza_elemento(e: Dictionary) -> float:
	match int(e.tipo):
		Battaglia.T.BLOCCO:
			var h := int(e.get("altezza", 0))
			if h <= 0 and not e.celle.is_empty():
				h = b.a_at(e.celle[0])
			return maxf(SPESSORE, float(h))
		Battaglia.T.LINEARE:
			return Battaglia.H_LINEARE
		Battaglia.T.SINGOLO:
			return 1.2 if str(e.nome) in ["Barili", "Casse della navetta", "Cristalli"] else Battaglia.H_SINGOLO
		Battaglia.T.CAMPO:
			return 0.02
	return SPESSORE

## Elemento senza immagine: blocchetti di cartone colorati per tipo.
func _ripiego(e: Dictionary, h: float) -> void:
	var col := Color(0.45, 0.46, 0.5)
	match int(e.tipo):
		Battaglia.T.AREA:
			col = Color(0.22, 0.36, 0.2)
		Battaglia.T.SINGOLO:
			col = Color(0.55, 0.4, 0.75) if str(e.nome) == "Cristalli" else Color(0.5, 0.36, 0.22)
		Battaglia.T.LINEARE:
			col = Color(0.55, 0.42, 0.26)
		Battaglia.T.CAMPO:
			return
	var m := _mat("ripiego", col)
	for c in e.celle:
		var hh := h
		if int(e.tipo) == Battaglia.T.BLOCCO:
			hh = maxf(SPESSORE, float(b.a_at(c)))
		var lato := 0.6 if int(e.tipo) == Battaglia.T.SINGOLO else 0.98
		_mi(_box(Vector3(lato, hh, lato)), m, n_terreno, Vector3(c.x + 0.5, hh / 2.0, c.y + 0.5))

## Ostacolo lineare: un segmento di cartoncino per casella, con un quarto della striscia dell'immagine sopra.
func _lineare(tex: Texture2D, celle: Array, forza: bool) -> void:
	var h := 2.0 if forza else Battaglia.H_LINEARE
	var fascia := _fascia_opaca(tex)
	for c in celle:
		var oriz: bool = (c + Vector2i.LEFT) in celle or (c + Vector2i.RIGHT) in celle
		var vert: bool = (c + Vector2i.UP) in celle or (c + Vector2i.DOWN) in celle
		var cc := Vector2(c) + Vector2(0.5, 0.5)
		if oriz or not vert:
			var reg := Rect2(float(posmod(c.x, 4)) / 4.0, fascia.x, 0.25, fascia.y - fascia.x)
			var mi := _cartoncino(tex, cc, 1.02, maxf(0.22, (fascia.y - fascia.x) * 4.0 * tex.get_size().y / tex.get_size().x), h, 0.0, false, reg)
			if forza:
				mi.set_surface_override_material(1, _mat("forza_bordo", Color(0.3, 0.8, 1.0, 0.5), null, false, true))
		if vert:
			var reg := Rect2(float(posmod(c.y, 4)) / 4.0, fascia.x, 0.25, fascia.y - fascia.x)
			var mi := _cartoncino(tex, cc, 1.02, maxf(0.22, (fascia.y - fascia.x) * 4.0 * tex.get_size().y / tex.get_size().x), h, 0.0, true, reg)
			if forza:
				mi.set_surface_override_material(1, _mat("forza_bordo", Color(0.3, 0.8, 1.0, 0.5), null, false, true))

## Righe opache della striscia di un ostacolo lineare (frazioni dell'altezza dell'immagine).
func _fascia_opaca(tex: Texture2D) -> Vector2:
	var k := "fascia%d" % tex.get_rid().get_id()
	if _mesh_cache.has(k):
		return _mesh_cache[k]
	var r := Vector2(0.3, 0.7)
	var img := tex.get_image()
	if img != null:
		if img.is_compressed():
			img.decompress()
		var a := -1
		var z := -1
		var hh := img.get_height()
		for y in hh:
			var pieno := false
			for x in range(0, img.get_width(), 8):
				if img.get_pixel(x, y).a > 0.4:
					pieno = true
					break
			if pieno:
				if a < 0:
					a = y
				z = y
		if a >= 0:
			r = Vector2(float(a) / hh, float(z + 1) / hh)
	_mesh_cache[k] = r
	return r

## Muro di un edificio con interno: lastra lungo la direzione del muro; finestre basse con vetro, porte di legno.
func _muro(p: Vector2i, t: int, mat_muro: Material) -> void:
	var tipi := [Battaglia.T.MURO, Battaglia.T.PORTA, Battaglia.T.FINESTRA]
	var oriz: bool = b.t_at(p + Vector2i.LEFT) in tipi or b.t_at(p + Vector2i.RIGHT) in tipi
	var vert: bool = b.t_at(p + Vector2i.UP) in tipi or b.t_at(p + Vector2i.DOWN) in tipi
	var cc := Vector3(p.x + 0.5, 0, p.y + 0.5)
	var hm := Battaglia.H_MURO
	var dims: Array = []
	if oriz or not vert:
		dims.append(Vector3(1.0, 0, 0.3))
	if vert:
		dims.append(Vector3(0.3, 0, 1.0))
	for dm in dims:
		var dv: Vector3 = dm
		match t:
			Battaglia.T.MURO:
				_mi(_box(Vector3(dv.x, hm, dv.z)), mat_muro, n_terreno, cc + Vector3(0, hm / 2.0, 0))
			Battaglia.T.FINESTRA:
				_mi(_box(Vector3(dv.x, 1.0, dv.z)), mat_muro, n_terreno, cc + Vector3(0, 0.5, 0))
				_mi(_box(Vector3(dv.x, 0.5, dv.z)), mat_muro, n_terreno, cc + Vector3(0, hm - 0.25, 0))
				_mi(_box(Vector3(dv.x * 0.96, 1.5, dv.z * 0.4)), _mat("vetro", Color(0.55, 0.8, 0.95, 0.35), null, false, true), n_terreno, cc + Vector3(0, 1.75, 0), false)
			Battaglia.T.PORTA:
				_mi(_box(Vector3(dv.x, 0.4, dv.z)), mat_muro, n_terreno, cc + Vector3(0, hm - 0.2, 0))
				if not b.porte_aperte.has(p):
					_mi(_box(Vector3(dv.x * 0.9, hm - 0.4, dv.z * 0.6)), _mat("porta", Color(0.55, 0.36, 0.18)), n_terreno, cc + Vector3(0, (hm - 0.4) / 2.0, 0))

## Nebbia, buio, polvere o gas come atmosfera della scena.
func _atmosfera() -> void:
	var cond := str(b.setup.get("condizione", {}).get("nome", ""))
	var tratti := " ".join(b.tratti_mondo).to_lower()
	ambiente.fog_enabled = false
	luce.light_energy = 0.85
	luce.light_color = Color(1.0, 0.95, 0.86)
	ambiente.ambient_light_energy = 0.38
	if cond == "Buio" or tratti.contains("oscurità"):
		luce.light_energy = 0.22
		luce.light_color = Color(0.55, 0.65, 1.0)
		ambiente.ambient_light_energy = 0.16
	elif cond == "Scarsa visibilità":
		ambiente.fog_enabled = true
		ambiente.fog_light_color = Color(0.7, 0.55, 0.38)
		ambiente.fog_density = 0.006
	elif cond == "Ambiente tossico":
		ambiente.fog_enabled = true
		ambiente.fog_light_color = Color(0.55, 0.7, 0.3)
		ambiente.fog_density = 0.004
	elif tratti.contains("nebbia") or tratti.contains("foschia"):
		ambiente.fog_enabled = true
		ambiente.fog_light_color = Color(0.75, 0.78, 0.82)
		ambiente.fog_density = 0.006

## ---------------- griglia ed evidenziazioni (texture sul suolo) ----------------

func _aggiorna_griglia() -> void:
	if griglia_img == null:
		return
	var f := hash([raggiungibili.keys(), raggiungibili_scatto.keys(), sopra, b.obiettivo, b.stato_obj.get("fatto", false), b.nebbia, b.impraticabili.size()])
	if f == _firma_griglia:
		return
	_firma_griglia = f
	var img := griglia_img
	img.fill(Color(0, 0, 0, 0))
	var W := b.W
	var H := b.H
	# zone di schieramento
	img.fill_rect(Rect2i(0, (H - 1) * PX, W * PX, PX), Color(0.95, 0.68, 0.28, 0.14))
	img.fill_rect(Rect2i(0, 0, W * PX, PX), Color(0.88, 0.33, 0.30, 0.14))
	for p in raggiungibili_scatto:
		if not raggiungibili.has(p):
			img.fill_rect(Rect2i(p.x * PX + 2, p.y * PX + 2, PX - 4, PX - 4), Color(0.95, 0.68, 0.28, 0.35))
	for p in raggiungibili:
		img.fill_rect(Rect2i(p.x * PX + 2, p.y * PX + 2, PX - 4, PX - 4), Color(0.36, 0.85, 0.88, 0.45))
	# obiettivo al centro
	var cc := Vector2(b.centro) + Vector2(0.5, 0.5)
	if b.obiettivo in ["consegnare", "accedere", "acquisire", "assicurare", "proteggere"]:
		_cerchio(img, cc, 2.5 if b.obiettivo == "assicurare" else 0.7, Color(0.5, 0.95, 0.5, 0.9))
		if b.obiettivo == "proteggere":
			_cerchio(img, cc, 3.5, Color(0.5, 0.95, 0.5, 0.6))
	if not b.nebbia.is_empty():
		_cerchio(img, Vector2(b.nebbia.centro) + Vector2(0.5, 0.5), float(b.nebbia.raggio) + 0.5, Color(0.9, 0.9, 0.95, 0.7))
	# griglia
	var gc := Color(0, 0, 0, 0.28)
	for x in W + 1:
		img.fill_rect(Rect2i(clampi(x * PX - 1, 0, W * PX - 2), 0, 2, H * PX), gc)
	for y in H + 1:
		img.fill_rect(Rect2i(0, clampi(y * PX - 1, 0, H * PX - 2), W * PX, 2), gc)
	if b.dentro(sopra):
		var r := Rect2i(sopra.x * PX, sopra.y * PX, PX, PX)
		for k in 3:
			img.fill_rect(Rect2i(r.position.x, r.position.y + k, PX, 1), Color.WHITE)
			img.fill_rect(Rect2i(r.position.x, r.end.y - 1 - k, PX, 1), Color.WHITE)
			img.fill_rect(Rect2i(r.position.x + k, r.position.y, 1, PX), Color.WHITE)
			img.fill_rect(Rect2i(r.end.x - 1 - k, r.position.y, 1, PX), Color.WHITE)
	griglia_tex.update(img)
	# evidenziazioni sui tetti e sui massi (caselle rialzate)
	for n in n_segni.get_children():
		if n.has_meta("alto"):
			n.queue_free()
	for p in raggiungibili.keys() + raggiungibili_scatto.keys():
		var h := b.a_at(p)
		if h > 0:
			var q := PlaneMesh.new()
			q.size = Vector2(0.9, 0.9)
			var col := Color(0.36, 0.85, 0.88, 0.5) if raggiungibili.has(p) else Color(0.95, 0.68, 0.28, 0.45)
			var mi := _mi(q, _mat("alto", col, null, false, true), n_segni, Vector3(p.x + 0.5, h + 0.03, p.y + 0.5), false)
			mi.set_meta("alto", true)

func _cerchio(img: Image, c: Vector2, r: float, col: Color) -> void:
	var cp := c * PX
	var rp := r * PX
	var passi := int(rp * 6.0) + 24
	for i in passi:
		var a := TAU * i / passi
		var q := cp + Vector2(cos(a), sin(a)) * rp
		img.fill_rect(Rect2i(int(q.x) - 1, int(q.y) - 1, 3, 3), col)

## ---------------- pedine (dischi di cartone) ----------------

const R_PEDINA := 0.42
const H_PEDINA := 0.22
const H_BASE := 0.1                 # base della sagoma (circa 2,5 mm)
const H_FIGURA_3D := 1.2            # altezza di una figura per il regolamento (miniatura da 28 mm)
const R_SAGOMA := (H_FIGURA_3D - H_BASE) / 2.0
const SPESSORE_SAGOMA := 0.06

func _disco(r: float) -> ArrayMesh:
	var k := "disco%.2f" % r
	if _mesh_cache.has(k):
		return _mesh_cache[k]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 40
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		for v in [Vector2.ZERO, Vector2(cos(a0), sin(a0)), Vector2(cos(a1), sin(a1))]:
			var vv: Vector2 = v
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(0.5, 0.5) + vv * 0.5)
			st.add_vertex(Vector3(vv.x * r, 0, vv.y * r))
	var m := st.commit()
	_mesh_cache[k] = m
	return m

func _crea_pedina(u: Dictionary) -> Dictionary:
	var nodo := Node3D.new()
	n_figure.add_child(nodo)
	var nem: bool = u.lato != Battaglia.EQ and u.lato != "prigioniero" and u.lato != Battaglia.NEU
	var bordo := UI.ROSSO if nem else UI.AMBRA
	if u.lato == Battaglia.MOSTRI:
		bordo = Color(0.6, 0.9, 0.3)
	elif u.lato == Battaglia.NEU:
		bordo = Color(0.72, 0.80, 0.90)
	# base rotonda del colore della fazione
	var cil := CylinderMesh.new()
	cil.top_radius = R_PEDINA
	cil.bottom_radius = R_PEDINA
	cil.height = H_BASE
	cil.radial_segments = 32
	_mi(cil, _mat("bordo_pedina", bordo.darkened(0.15)), nodo, Vector3(0, H_BASE / 2.0, 0))
	# sagoma di cartoncino in piedi, alta come una miniatura, fissa e rivolta verso il lato dell'equipaggio
	# (l'immagine è su entrambe le facce)
	var sagoma := Node3D.new()
	sagoma.position = Vector3(0, H_BASE + R_SAGOMA, 0)
	nodo.add_child(sagoma)
	var bordo_sag := CylinderMesh.new()
	bordo_sag.top_radius = R_SAGOMA
	bordo_sag.bottom_radius = R_SAGOMA
	bordo_sag.height = SPESSORE_SAGOMA
	bordo_sag.radial_segments = 32
	var bs := _mi(bordo_sag, _mat("bordo_sagoma", bordo.darkened(0.1)), sagoma)
	bs.rotation_degrees = Vector3(90, 0, 0)
	var tex := Pedine.texture(str(u.pedina))
	var m := StandardMaterial3D.new()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.8
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if tex != null:
		m.albedo_texture = tex
	else:
		m.albedo_color = Pedine.colore_da_nome(str(u.pedina) if str(u.pedina) != "" else str(u.nome), nem)
	var faccia := MeshInstance3D.new()
	faccia.mesh = _disco(R_SAGOMA * 0.93)
	faccia.material_override = m
	faccia.rotation_degrees = Vector3(90, 0, 0)
	faccia.position = Vector3(0, 0, SPESSORE_SAGOMA / 2.0 + 0.003)
	sagoma.add_child(faccia)
	var retro := MeshInstance3D.new()
	retro.mesh = faccia.mesh
	retro.material_override = m
	retro.rotation_degrees = Vector3(90, 0, 0)
	retro.position = Vector3(0, 0, -SPESSORE_SAGOMA / 2.0 - 0.003)
	sagoma.add_child(retro)
	if tex == null:
		var l := _etichetta(Pedine.iniziali(str(u.nome)), 40, Color.WHITE)
		l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		l.fixed_size = false
		l.pixel_size = 0.01
		l.no_depth_test = false
		l.position = Vector3(0, 0, SPESSORE_SAGOMA / 2.0 + 0.01)
		sagoma.add_child(l)
	# anello di selezione / bersaglio (sul tavolo, sotto la pedina)
	var an := CylinderMesh.new()
	an.top_radius = 0.52
	an.bottom_radius = 0.52
	an.height = 0.04
	var anello := _mi(an, _mat("sel", Color.WHITE, null, true), nodo, Vector3(0, 0.02, 0), false)
	anello.visible = false
	var soglia := _etichetta("", 64, Color(1, 0.85, 0.5))
	soglia.position = Vector3(0, H_FIGURA_3D + 0.45, 0)
	soglia.visible = false
	nodo.add_child(soglia)
	var stato := _etichetta("", 40, Color(0.85, 0.9, 1.0))
	stato.position = Vector3(0, H_FIGURA_3D + 0.2, 0)
	nodo.add_child(stato)
	return {"nodo": nodo, "faccia": faccia, "sagoma": sagoma, "anello": anello, "soglia": soglia, "stato": stato}

func _etichetta(t: String, dim: int, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.font = UI.font_titoli
	l.font_size = dim
	l.outline_size = 12
	l.modulate = col
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.pixel_size = 0.00038
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	return l

func _aggiorna_figure() -> void:
	var visti := {}
	for u in b.unita:
		if not u.attiva:
			continue
		visti[u.uid] = true
		if not _pedine.has(u.uid):
			_pedine[u.uid] = _crea_pedina(u)
		var pd: Dictionary = _pedine[u.uid]
		var g: Vector2 = anim.get(u.uid, centro_cella(u.pos))
		var nodo: Node3D = pd.nodo
		nodo.position = Vector3(g.x, float(b.a_at(u.pos)), g.y)
		var anello: MeshInstance3D = pd.anello
		anello.visible = u.uid == selezionata or bersagli.has(u.uid)
		if bersagli.has(u.uid):
			anello.material_override = _mat("bers", Color(1, 0.3, 0.25), null, true)
		elif u.uid == selezionata:
			anello.material_override = _mat("sel", Color.WHITE, null, true)
		var soglia: Label3D = pd.soglia
		soglia.visible = bersagli.has(u.uid) and int(bersagli[u.uid]) > 0
		if soglia.visible:
			soglia.text = "%d+" % int(bersagli[u.uid])
		var att: bool = (u.lato == Battaglia.EQ and u.attivato) or u.get("passiva", false) or u.lato == "prigioniero"
		var faccia: MeshInstance3D = pd.faccia
		faccia.transparency = 0.0
		var mat := faccia.material_override as StandardMaterial3D
		if mat != null:
			mat.albedo_color = Color(0.5, 0.5, 0.5) if att else Color.WHITE
		var st: Array = []
		if int(u.stordito) > 0:
			st.append("Stordito %d" % int(u.stordito))
		if u.porta != "":
			st.append("porta il " + str(u.porta))
		if u.get("attesa", "") == "snap":
			st.append("pronto al fuoco")
		var lbl: Label3D = pd.stato
		lbl.text = ", ".join(st)
	for uid in _pedine.keys():
		if not visti.has(uid):
			var nd: Node3D = _pedine[uid].nodo
			nd.queue_free()
			_pedine.erase(uid)

## ---------------- segnalini di obiettivo ----------------

var _firma_segni := 0

func _aggiorna_segni() -> void:
	var f := hash([b.stato_obj, b.segnalini.size(), b.obiettivo])
	if f == _firma_segni:
		return
	_firma_segni = f
	for n in n_segni.get_children():
		if not n.has_meta("alto"):
			n.queue_free()
	var verde := Color(0.5, 0.9, 0.5)
	var oro := Color(0.95, 0.85, 0.3)
	var seg: String = str({"accedere": "segnalino_console", "consegnare": "obiettivo_consegna"}.get(b.obiettivo, ""))
	if seg != "" and not b.stato_obj.get("fatto", false):
		_segnalino(b.centro, seg, verde)
	if b.stato_obj.has("oggetto_a"):
		_segnalino(b.stato_obj.oggetto_a, "segnalino_pacco", oro)
	if b.stato_obj.has("caduto"):
		_segnalino(b.stato_obj.caduto.pos, "segnalino_pacco", oro)
	for pt in b.stato_obj.get("punti", []):
		_segnalino(pt.cella, "obiettivo_pattuglia", Color(0.5, 0.5, 0.5) if pt.fatto else verde)
	for sg in b.stato_obj.get("segnalini", []):
		if not sg.fatto:
			_segnalino(sg.cella, "segnalino_perquisire", verde)
	if b.stato_obj.has("luogo_pos") and not b.stato_obj.get("luogo_preso", false):
		_segnalino(b.stato_obj.luogo_pos, "segnalino_luogo", UI.ACQUA)
	for s in b.segnalini:
		_segnalino(s.pos, "segnalino_rinforzi" if s.tipo == "rinforzi" else "segnalino_bottino", UI.ROSSO if s.tipo == "rinforzi" else oro)

func _segnalino(p: Vector2i, chiave: String, col: Color) -> void:
	var nodo := Node3D.new()
	n_segni.add_child(nodo)
	nodo.position = Vector3(p.x + 0.5, float(b.a_at(p)) + 0.01, p.y + 0.5)
	var cil := CylinderMesh.new()
	cil.top_radius = 0.36
	cil.bottom_radius = 0.36
	cil.height = 0.12
	_mi(cil, _mat("bordo_seg", col.darkened(0.1)), nodo, Vector3(0, 0.06, 0))
	var tex := Pedine.texture(chiave)
	var faccia := MeshInstance3D.new()
	faccia.mesh = _disco(0.33)
	faccia.position = Vector3(0, 0.125, 0)
	var m := StandardMaterial3D.new()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if tex != null:
		m.albedo_texture = tex
	else:
		m.albedo_color = col
	faccia.material_override = m
	nodo.add_child(faccia)

## ---------------- linea di vista ----------------

func _segmento(da: Vector3, a: Vector3, col: Color, spessore: float, padre: Node3D) -> void:
	var l := da.distance_to(a)
	if l < 0.01:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = _box(Vector3(spessore, spessore, l))
	mi.material_override = _mat("linea", col, null, true)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mi)
	mi.look_at_from_position((da + a) / 2.0, a, Vector3.UP if absf((a - da).normalized().y) < 0.99 else Vector3.RIGHT)

func _aggiorna_vista() -> void:
	var f := "%d|%s|%s" % [selezionata, sopra, mostra_vista]
	var u := _unita(selezionata)
	if not u.is_empty():
		f += "|%s|%s" % [u.pos, anim.has(u.uid)]
	if f == _firma_vista:
		return
	_firma_vista = f
	for n in n_vista.get_children():
		n.queue_free()
	if not mostra_vista or u.is_empty() or not u.attiva or not b.dentro(sopra) or u.pos == sopra or anim.has(u.uid):
		return
	var info := LineaVista.vista(b, u, sopra)
	var da := Vector3(u.pos.x + 0.5, b.a_at(u.pos) + 1.0, u.pos.y + 0.5)
	var a := Vector3(sopra.x + 0.5, b.a_at(sopra) + 1.0, sopra.y + 0.5)
	var col: Color = info.colore
	if info.blocco != null:
		var bp: Vector2i = info.blocco
		var tot := Vector2(sopra - u.pos).length()
		var k := clampf(Vector2(bp - u.pos).length() / maxf(0.001, tot), 0.0, 1.0)
		var m := da.lerp(a, k)
		_segmento(da, m, LineaVista.VERDE, 0.06, n_vista)
		_segmento(m, a, Color(col.r, col.g, col.b, 1.0), 0.035, n_vista)
		var x := 0.32
		_segmento(m + Vector3(-x, 0, -x), m + Vector3(x, 0, x), col, 0.08, n_vista)
		_segmento(m + Vector3(-x, 0, x), m + Vector3(x, 0, -x), col, 0.08, n_vista)
	else:
		_segmento(da, a, col, 0.06, n_vista)
		var sf := SphereMesh.new()
		sf.radius = 0.1
		sf.height = 0.2
		_mi(sf, _mat("punta", col, null, true), n_vista, a, false)
	var l := _etichetta(str(info.testo), 44, Color.WHITE)
	l.position = a + Vector3(0, 0.5, 0)
	n_vista.add_child(l)

func _unita(uid: int) -> Dictionary:
	if uid < 0:
		return {}
	for u in b.unita:
		if u.uid == uid:
			return u
	return {}

## ---------------- colpi ----------------

static func colore_lato(l: String) -> Color:
	if l == Battaglia.EQ:
		return Color(1.0, 0.78, 0.35)
	if l == Battaglia.MOSTRI:
		return Color(0.6, 0.95, 0.35)
	return Color(1.0, 0.35, 0.3)

func _quota(p: Vector2i, h: float) -> Vector3:
	return Vector3(p.x + 0.5, float(b.a_at(p)) + h, p.y + 0.5)

## Freccia dell'ultimo tiro: da chi ha sparato a chi è stato bersagliato.
var _mat_freccia: Array = []

func _aggiorna_tiro(d: float) -> void:
	if not ultimo_tiro.is_empty():
		ultimo_tiro.t = float(ultimo_tiro.get("t", 0.0)) + d
		if ultimo_tiro.t > Tavolo2D.DURATA_FRECCIA:
			ultimo_tiro = {}
		else:
			var al := 0.6 * clampf((Tavolo2D.DURATA_FRECCIA - float(ultimo_tiro.t)) / 0.8, 0.0, 1.0)
			for m in _mat_freccia:
				(m as StandardMaterial3D).albedo_color.a = al
	var f := "" if ultimo_tiro.is_empty() else "%s|%s|%s" % [ultimo_tiro.da, ultimo_tiro.a, ultimo_tiro.lato]
	if f == _firma_tiro:
		return
	_firma_tiro = f
	for n in n_tiro.get_children():
		n.queue_free()
	_mat_freccia = []
	if ultimo_tiro.is_empty():
		return
	var da := _quota(ultimo_tiro.da, 0.7)
	var a := _quota(ultimo_tiro.a, 0.7)
	if da.distance_to(a) < 0.5:
		return
	var col := colore_lato(str(ultimo_tiro.lato))
	col.a = 0.6
	var dir := (a - da).normalized()
	var punta := a - dir * 0.5
	var mi := MeshInstance3D.new()
	var l := (punta - da).length() - 0.45
	if l > 0.05:
		_segmento(da + dir * 0.45, punta, col, 0.05, n_tiro)
		var seg := n_tiro.get_child(n_tiro.get_child_count() - 1) as MeshInstance3D
		var ms := _mat_sfumato(col)
		seg.material_override = ms
		_mat_freccia.append(ms)
	var cono := CylinderMesh.new()
	cono.top_radius = 0.0
	cono.bottom_radius = 0.16
	cono.height = 0.38
	mi.mesh = cono
	var mc := _mat_sfumato(col)
	mi.material_override = mc
	_mat_freccia.append(mc)
	n_tiro.add_child(mi)
	mi.position = punta
	var asse := dir
	var ref := Vector3.UP if absf(asse.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var x := ref.cross(asse).normalized()
	var z := x.cross(asse).normalized()
	mi.basis = Basis(x, asse, z)

func _aggiorna_colpi(d: float) -> void:
	for c in colpi:
		c.t += d
		for n in c.nodi:
			(n as Node).queue_free()
		c.nodi = []
		var col := colore_lato(str(c.lato))
		var da := _quota(c.da, 0.75)
		var a := _quota(c.a, 0.55)
		if c.rissa:
			var k: float = clampf(c.t / 0.5, 0.0, 1.0)
			var sf := SphereMesh.new()
			sf.radius = 0.2 + 0.4 * k
			sf.height = sf.radius * 2.0
			c.nodi.append(_mi(sf, _mat_sfumato(Color(col.r, col.g, col.b, 1.0 - k)), n_colpi, (da + a) / 2.0, false))
			continue
		var dir := (a - da).normalized()
		var p0 := da + dir * 0.4
		var gen := str(c.get("genere", "proiettile"))
		if gen == "granata":
			var k: float = clampf(float(c.t) / Tavolo2D.VOLO_GRANATA, 0.0, 1.0)
			if k < 1.0:
				var p := p0.lerp(a, k) + Vector3(0, sin(PI * k) * maxf(1.5, da.distance_to(a) * 0.3), 0)
				var sf := SphereMesh.new()
				sf.radius = 0.13
				sf.height = 0.26
				c.nodi.append(_mi(sf, _mat("granata", Color(0.3, 0.35, 0.25)), n_colpi, p))
			continue
		if gen == "fiamma":
			for j in 10:
				var k: float = float(c.t) / VOLO - j * 0.07
				if k >= 0.0 and k <= 1.0:
					var sf := SphereMesh.new()
					sf.radius = 0.12 + 0.35 * k
					sf.height = sf.radius * 2.0
					c.nodi.append(_mi(sf, _mat_sfumato(Color(1.0, 0.45 + 0.3 * (1.0 - k), 0.1, 0.8 * (1.0 - k * 0.6))), n_colpi, p0.lerp(a, k), false))
			continue
		for i in int(c.n):
			var k: float = (float(c.t) - RITMO * i) / VOLO
			if k >= 0.0 and k <= 1.0:
				var testa := p0.lerp(a, k)
				var coda := p0.lerp(a, maxf(0.0, k - 0.3))
				var tr := Node3D.new()
				n_colpi.add_child(tr)
				_segmento(coda, testa, col, 0.07, tr)
				var sf := SphereMesh.new()
				sf.radius = 0.08
				sf.height = 0.16
				_mi(sf, _mat("testa", Color(1, 1, 0.9), null, true), tr, testa, false)
				if k < 0.3:
					var lampo := SphereMesh.new()
					lampo.radius = 0.25 * (1.0 - k / 0.3)
					lampo.height = lampo.radius * 2.0
					_mi(lampo, _mat("lampo", Color(1, 0.95, 0.7), null, true), tr, p0, false)
				c.nodi.append(tr)
			elif k > 1.0 and k < 1.0 + 0.25 / VOLO:
				var e: float = (k - 1.0) * VOLO / 0.25
				var sf := SphereMesh.new()
				sf.radius = 0.15 + 0.4 * e
				sf.height = sf.radius * 2.0
				c.nodi.append(_mi(sf, _mat_sfumato(Color(1, 0.9, 0.6, 1.0 - e)), n_colpi, a, false))
	var finiti := colpi.filter(func(c): return c.t >= durata(c))
	for c in finiti:
		for n in c.nodi:
			(n as Node).queue_free()
	colpi = colpi.filter(func(c): return c.t < durata(c))

static func durata(c: Dictionary) -> float:
	return Tavolo2D.durata(c)

## ---------------- modelli 3D (assets/modelli/*.glb: CC0 di Kenney o modelli propri) ----------------
## Se un modello manca, l'elemento resta un cartoncino.

static var _scene_modelli := {}
static var _aabb_modelli := {}

func _scena(nome: String) -> PackedScene:
	if _scene_modelli.has(nome):
		return _scene_modelli[nome]
	var p := "res://assets/modelli/%s.glb" % nome
	var s: PackedScene = load(p) if ResourceLoader.exists(p) else null
	_scene_modelli[nome] = s
	return s

static func _aabb_nodo(n: Node, t: Transform3D) -> AABB:
	var r := AABB()
	var vuoto := true
	var tt := t * (n as Node3D).transform if n is Node3D else t
	if n is MeshInstance3D:
		r = tt * (n as MeshInstance3D).get_aabb()
		vuoto = false
	for c in n.get_children():
		var a := _aabb_nodo(c, tt)
		if a.size != Vector3.ZERO:
			r = a if vuoto else r.merge(a)
			vuoto = false
	return r

## Materiali dei modelli resi opachi e non metallici: senza riflessi d'ambiente il metallo diventa nero.
static var _mat_opachi := {}

static func _opaco(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh != null:
			for i in mi.mesh.get_surface_count():
				var m := mi.get_active_material(i)
				if m is BaseMaterial3D:
					var k := m.get_instance_id()
					if not _mat_opachi.has(k):
						var d := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
						d.metallic = 0.0
						d.metallic_specular = 0.3
						d.roughness = 0.9
						# tinta calda e meno satura, per avvicinarsi alla grafica dipinta della plancia
						d.albedo_color = d.albedo_color * Color(0.86, 0.8, 0.7)
						_mat_opachi[k] = d
					mi.set_surface_override_material(i, _mat_opachi[k])
	for c in n.get_children():
		_opaco(c)

## Primo modello disponibile tra i nomi (scelto con il seme, per variare tra caselle vicine).
func _scegli_modello(nomi: Array, seme: int) -> String:
	var ok := nomi.filter(func(n): return _scena(str(n)) != null)
	if ok.is_empty():
		return ""
	return str(ok[posmod(seme, ok.size())])

## Piazza un modello nella scatola w (x) x d (z) x h, centrata in c, appoggiata a quota y0.
## uniforme: mantiene le proporzioni (sta dentro la scatola); ruota_lungo: allinea il lato lungo del modello al lato
## lungo della scatola.
func _modello(nome: String, c: Vector2, w: float, d: float, h: float, y0 := 0.0, uniforme := false) -> Node3D:
	var sc := _scena(nome)
	if sc == null:
		return null
	var inst := sc.instantiate() as Node3D
	if not _aabb_modelli.has(nome):
		_aabb_modelli[nome] = _aabb_nodo(inst, Transform3D.IDENTITY)
	var a: AABB = _aabb_modelli[nome]
	var ax := maxf(a.size.x, 0.001)
	var ay := maxf(a.size.y, 0.001)
	var az := maxf(a.size.z, 0.001)
	var perno := Node3D.new()
	perno.position = Vector3(c.x, y0, c.y)
	# lato lungo del modello lungo il lato lungo della scatola
	if (ax > az * 1.15 and d > w * 1.15) or (az > ax * 1.15 and w > d * 1.15):
		perno.rotation.y = PI / 2.0
		var t := w
		w = d
		d = t
	var s := Vector3(w / ax, h / ay, d / az)
	if uniforme:
		var k := minf(s.x, minf(s.y, s.z))
		s = Vector3(k, k, k)
	inst.scale = s
	inst.position = Vector3(-a.get_center().x * s.x, -a.position.y * s.y, -a.get_center().z * s.z)
	_opaco(inst)
	perno.add_child(inst)
	n_terreno.add_child(perno)
	return perno

## Elementi resi con modelli 3D. Restituisce true se l'elemento è stato disegnato (niente cartoncino).
func _elemento_modello(e: Dictionary, h: float) -> bool:
	var nome := str(e.nome)
	var celle: Array = e.celle
	var bb := _bbox(celle)
	match nome:
		"Alberi":
			var n := _scegli_modello(["albero_1", "albero_2", "albero_3"], 0)
			if n == "":
				return false
			for c in celle:
				var m := _scegli_modello(["albero_1", "albero_2", "albero_3"], c.x * 7 + c.y * 3)
				_modello(m, Vector2(c) + Vector2(0.5, 0.5), 1.2, 1.2, H_CHIOMA)
			return true
		"Barili":
			if _scegli_modello(["barile"], 0) == "":
				return false
			for c in celle:
				var m := _scegli_modello(["barile", "barili"], c.x + c.y)
				_modello(m, Vector2(c) + Vector2(0.5, 0.5), 0.8, 0.8, 1.2, 0.0, true)
			return true
		"Deposito di casse", "Casse della navetta":
			if _scegli_modello(["cassa"], 0) == "":
				return false
			for c in celle:
				var hh := maxf(SPESSORE, float(b.a_at(c))) if int(e.tipo) == Battaglia.T.BLOCCO else 0.8
				_modello("cassa", Vector2(c) + Vector2(0.5, 0.5), 0.95, 0.95, hh)
			return true
		"Cristalli":
			if _scegli_modello(["cristalli_1"], 0) == "":
				return false
			for c in celle:
				_modello(_scegli_modello(["cristalli_1", "cristalli_2"], c.x * 3 + c.y), Vector2(c) + Vector2(0.5, 0.5), 1.0, 1.0, 1.2, 0.0, true)
			return true
		"Navetta atterrata":
			if _scena("navetta") == null:
				return false
			var lungo := maxf(bb.size.x, bb.size.y) * 0.98
			var a := _aabb_modelli.get("navetta", AABB()) as AABB
			var p := _modello("navetta", bb.get_center(), bb.size.x, bb.size.y, h, 0.0, true)
			# la navetta riempie la lunghezza: si allarga oltre la larghezza delle caselle (ali)
			if p != null and a.size == Vector3.ZERO:
				a = _aabb_modelli["navetta"]
			if p != null:
				var inst := p.get_child(0) as Node3D
				var k := lungo / maxf(a.size.x, a.size.z)
				inst.scale = Vector3(k, k, k)
				inst.position = Vector3(-a.get_center().x * k, -a.position.y * k, -a.get_center().z * k)
			return p != null
		"Edificio chiuso":
			return _modello("edificio", bb.get_center(), bb.size.x, bb.size.y, h) != null
		"Masso":
			return _modello(_scegli_modello(["masso_1", "masso_2"], bb.position.x as int), bb.get_center(), bb.size.x * 1.05, bb.size.y * 1.05, h) != null
		"Cratere":
			if _scena("cratere") == null:
				return false
			_modello("cratere", bb.get_center(), bb.size.x * 1.15, bb.size.y * 1.15, 0.25)
			return true
		"Recinzione", "Barricata", "Muretto":
			var m := {"Recinzione": "recinzione", "Barricata": "barricata", "Muretto": "muretto"}[nome] as String
			if _scena(m) == null:
				return false
			for c in celle:
				var oriz: bool = (c + Vector2i.LEFT) in celle or (c + Vector2i.RIGHT) in celle
				var vert: bool = (c + Vector2i.UP) in celle or (c + Vector2i.DOWN) in celle
				var cc := Vector2(c) + Vector2(0.5, 0.5)
				if oriz or not vert:
					_modello(m, cc, 1.04, 0.25, Battaglia.H_LINEARE)
				if vert:
					_modello(m, cc, 0.25, 1.04, Battaglia.H_LINEARE)
			return true
	return false

## Piante o alberi sopra le aree di vegetazione (il cartoncino resta come base).
func _decora_area(e: Dictionary) -> void:
	var nome := str(e.nome)
	var celle: Array = e.celle
	if nome == "Bosco":
		for c in celle:
			if posmod(c.x * 3 + c.y * 5, 7) == 0:
				var m := _scegli_modello(["albero_1", "albero_2", "albero_3"], c.x * 5 + c.y)
				if m != "":
					_modello(m, Vector2(c) + Vector2(0.5, 0.5), 1.15, 1.15, H_CHIOMA - SPESSORE, SPESSORE)
	elif nome in ["Cespugli", "Vegetazione"]:
		for c in celle:
			if posmod(c.x * 3 + c.y * 5, 3) == 0:
				var m := _scegli_modello(["cespuglio_1", "cespuglio_2", "cespuglio_3"], c.x + c.y * 3)
				if m != "":
					_modello(m, Vector2(c) + Vector2(0.5, 0.5), 0.95, 0.95, 0.8, SPESSORE, true)
	elif nome == "Rovine":
		for c in celle:
			if posmod(c.x * 7 + c.y * 3, 5) == 0:
				var m := _scegli_modello(["sassi"], 0)
				if m != "":
					_modello(m, Vector2(c) + Vector2(0.5, 0.5), 0.9, 0.9, 0.25, SPESSORE)

## ---------------- esplosioni e atmosfera ----------------

func _aggiorna_esplosioni(d: float) -> void:
	for e in esplosioni:
		e.t += d
		for n in e.nodi:
			(n as Node).queue_free()
		e.nodi = []
		if e.t < 0.0:
			continue
		var cols: Array = Atmosfera.colori_esplosione(str(e.genere))
		var c := _quota(e.pos, 0.3)
		if not e.scoppiata:
			e.scoppiata = true
			var r := float(e.raggio) + 0.5
			_scintille(c, cols[1], 60 if str(e.genere) == "cariche" else 40, r * 2.2, 0.6, 0.18)
			_scintille(c + Vector3(0, 0.3, 0), cols[2], 22, r * 0.6, 1.8, 0.9, true)
		var k: float = clampf(e.t / Tavolo2D.DURATA_ESPLOSIONE, 0.0, 1.0)
		var lampo: Color = cols[0]
		var r2 := (float(e.raggio) + 0.5) * minf(1.0, k * 5.0)
		var sf := SphereMesh.new()
		sf.radius = maxf(0.05, r2 * 0.55)
		sf.height = sf.radius * 1.2
		e.nodi.append(_mi(sf, _mat_sfumato(Color(lampo.r, lampo.g, lampo.b, 0.6 * (1.0 - k))), n_colpi, c, false))
		var an := CylinderMesh.new()
		an.top_radius = float(e.raggio) + 0.5
		an.bottom_radius = an.top_radius
		an.height = 0.05
		e.nodi.append(_mi(an, _mat_sfumato(Color(lampo.r, lampo.g, lampo.b, 0.35 * (1.0 - k))), n_colpi, _quota(e.pos, 0.04), false))
		var luce_e := OmniLight3D.new()
		luce_e.light_color = lampo
		luce_e.light_energy = 6.0 * (1.0 - k) * (3.0 if str(e.genere) == "accecante" else 1.0)
		luce_e.omni_range = float(e.raggio) * 3.0 + 3.0
		luce_e.position = c + Vector3(0, 1.0, 0)
		n_colpi.add_child(luce_e)
		e.nodi.append(luce_e)
	var finite := esplosioni.filter(func(e): return e.t >= Tavolo2D.DURATA_ESPLOSIONE)
	for e in finite:
		for n in e.nodi:
			(n as Node).queue_free()
	esplosioni = esplosioni.filter(func(e): return e.t < Tavolo2D.DURATA_ESPLOSIONE)

func _mat_particelle(col := Color.WHITE) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = Atmosfera.morbida()
	m.albedo_color = col
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

## Scintille o fumo di un'esplosione.
func _scintille(c: Vector3, col: Color, n: int, vel: float, vita: float, dim: float, sale := false) -> void:
	var p := CPUParticles3D.new()
	p.position = c
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = maxi(4, n)
	p.lifetime = vita
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	q.material = _mat_particelle()
	p.mesh = q
	p.direction = Vector3.UP
	p.spread = 180.0 if not sale else 60.0
	p.gravity = Vector3(0, 0.6, 0) if sale else Vector3(0, -4.0, 0)
	p.initial_velocity_min = vel * 0.35
	p.initial_velocity_max = vel
	p.damping_min = vel * 0.8
	p.damping_max = vel * 1.2
	p.scale_amount_min = dim * 0.6
	p.scale_amount_max = dim * 1.4
	p.color_ramp = Atmosfera.sfuma(col)
	n_colpi.add_child(p)
	p.emitting = true
	get_tree().create_timer(vita + 0.3).timeout.connect(p.queue_free)

var _atm_firma := "?"
var _atm_nodi: Array = []

## Nebbia, polvere, gas o lucciole notturne sopra il campo; banco di nebbia locale degli eventi.
func _aggiorna_atmosfera() -> void:
	var tipo := Atmosfera.tipo(b)
	var firma := "%s|%s|%d" % [tipo, b.nebbia, b.W]
	if firma == _atm_firma:
		return
	_atm_firma = firma
	for n in _atm_nodi:
		(n as Node).queue_free()
	_atm_nodi = []
	var c := Vector3(b.W / 2.0, 1.2, b.H / 2.0)
	var est := Vector3(b.W / 2.0, 1.0, b.H / 2.0)
	match tipo:
		"nebbia":
			_atm_nodi.append(_strato3d(c, est, Color(0.92, 0.94, 0.97, 0.22), 60, 16.0, Vector3(0.35, 0, 0.05), 5.0))
		"polvere":
			_atm_nodi.append(_strato3d(c, est, Color(0.82, 0.62, 0.38, 0.16), 40, 9.0, Vector3(1.2, 0, 0.1), 6.0))
			_atm_nodi.append(_strato3d(c, est, Color(0.9, 0.72, 0.45, 0.6), 220, 2.0, Vector3(3.0, 0.2, 0.4), 0.12))
		"gas":
			_atm_nodi.append(_strato3d(Vector3(c.x, 0.6, c.z), Vector3(est.x, 0.5, est.z), Color(0.55, 0.85, 0.25, 0.2), 55, 14.0, Vector3(0.2, 0.1, 0.1), 4.5))
		"buio":
			_atm_nodi.append(_strato3d(c, est, Color(0.85, 1.0, 0.45, 0.9), 45, 6.0, Vector3(0.25, 0.15, 0.2), 0.1, true))
	if not b.nebbia.is_empty():
		var nc: Vector2i = b.nebbia.centro
		var nr := float(b.nebbia.raggio) + 0.5
		_atm_nodi.append(_strato3d(Vector3(nc.x + 0.5, 1.0, nc.y + 0.5), Vector3(nr, 0.8, nr) * 0.8, Color(0.95, 0.96, 0.98, 0.35), 45, 10.0, Vector3(0.2, 0, 0), 3.5))

func _strato3d(c: Vector3, est: Vector3, col: Color, n: int, vita: float, vel: Vector3, dim: float, lucciole := false) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = c
	p.amount = n
	p.lifetime = vita
	p.preprocess = vita
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	q.material = _mat_particelle()
	p.mesh = q
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = est
	p.direction = vel.normalized() if vel.length() > 0 else Vector3.RIGHT
	p.spread = 25.0 if not lucciole else 180.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = vel.length() * 0.5
	p.initial_velocity_max = vel.length() * 1.2
	p.scale_amount_min = dim * 0.6
	p.scale_amount_max = dim * 1.3
	var g := Gradient.new()
	g.set_color(0, Color(col.r, col.g, col.b, 0.0))
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	g.add_point(0.3, col)
	g.add_point(0.7, col)
	p.color_ramp = g
	mondo.add_child(p)
	p.emitting = true
	return p
