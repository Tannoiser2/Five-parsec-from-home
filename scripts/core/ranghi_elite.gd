## Ranghi d'élite (p.65): restano al giocatore tra una campagna e l'altra, salvati sul dispositivo.
## Si guadagna un Rango concludendo una campagna dopo averne raggiunto la condizione di vittoria,
## una sola volta per condizione, fino a un massimo di 17.
class_name RanghiElite
extends RefCounted

const FILE := "user://ranghi_elite.json"
const MASSIMO := 17

static func carica() -> Dictionary:
	var d := {"ranghi": 0, "condizioni": []}
	if not FileAccess.file_exists(FILE):
		return d
	var f := FileAccess.open(FILE, FileAccess.READ)
	if f == null:
		return d
	var j = JSON.parse_string(f.get_as_text())
	if j is Dictionary:
		d["ranghi"] = clampi(int(j.get("ranghi", 0)), 0, MASSIMO)
		d["condizioni"] = j.get("condizioni", []) if j.get("condizioni", []) is Array else []
	return d

static func salva(d: Dictionary) -> void:
	var f := FileAccess.open(FILE, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d, " "))

static func ranghi() -> int:
	return int(carica().ranghi)

## Assegna il Rango per la condizione. Restituisce true se è un Rango nuovo.
static func premia(condizione: String) -> bool:
	var d := carica()
	if condizione == "" or condizione in d.condizioni or int(d.ranghi) >= MASSIMO:
		return false
	d.condizioni.append(condizione)
	d["ranghi"] = int(d.ranghi) + 1
	salva(d)
	return true
