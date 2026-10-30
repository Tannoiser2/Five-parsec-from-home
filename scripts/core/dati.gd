## Tutte le tabelle del regolamento, caricate una volta dai file data/*.json.
class_name Dati
extends RefCounted

const FILE := ["specie", "creazione", "armi", "equipaggiamento", "nave", "bottino", "campagna", "incontri",
	"post_battaglia", "zone", "storia", "neutrali", "griglia", "regole"]

static var d := {}

static func carica() -> void:
	if not d.is_empty():
		return
	for f in FILE:
		var path := "res://data/%s.json" % f
		if not FileAccess.file_exists(path):
			d[f] = {}
			continue
		var testo := FileAccess.get_file_as_string(path)
		var v = JSON.parse_string(testo)
		if v == null:
			push_error("JSON non valido: " + path)
			v = {}
		d[f] = v

static func f(nome: String) -> Dictionary:
	carica()
	return d.get(nome, {})

static func specie(id: String) -> Dictionary:
	return f("specie").get("specie", {}).get(id, {})

static func arma(id: String) -> Dictionary:
	return f("armi").get("armi", {}).get(id, {})

static func oggetto(id: String) -> Dictionary:
	var o: Dictionary = f("equipaggiamento").get("oggetti", {}).get(id, {})
	if o.is_empty():
		o = f("armi").get("mod_armi", {}).get(id, {})
	if o.is_empty():
		o = f("armi").get("mirini", {}).get(id, {})
	return o

static func nemico(id: String) -> Dictionary:
	return f("incontri").get("nemici", {}).get(id, {})

## Nome leggibile di un oggetto o di un'arma (con l'id come ripiego).
static func nome_oggetto(id: String) -> String:
	var a := arma(id)
	if not a.is_empty():
		return str(a.get("nome", id))
	var o := oggetto(id)
	if not o.is_empty():
		return str(o.get("nome", id))
	return id.replace("_", " ").capitalize()

static func e_arma(id: String) -> bool:
	return not arma(id).is_empty()

static func tratti_arma(id: String) -> Array:
	return arma(id).get("tratti", [])

static func testo_tratto(t: String) -> String:
	return str(f("armi").get("tratti", {}).get(t, t))
