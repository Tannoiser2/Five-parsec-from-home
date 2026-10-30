## Salvataggi delle campagne: sul dispositivo (user://campagne) e nel cloud (Firebase, fiveparsecs/campagne).
## Nel browser user:// è conservato nel database del browser (IndexedDB) e sopravvive alla chiusura della pagina.
class_name Salvataggi
extends RefCounted

const CARTELLA := "user://campagne"

static func _assicura() -> void:
	if not DirAccess.dir_exists_absolute(CARTELLA):
		DirAccess.make_dir_recursive_absolute(CARTELLA)

static func salva_locale(stato: Dictionary) -> bool:
	_assicura()
	var codice := str(stato.get("codice", ""))
	if codice == "":
		return false
	var f := FileAccess.open("%s/%s.json" % [CARTELLA, codice], FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(stato))
	f.close()
	return true

static func carica_locale(codice: String) -> Dictionary:
	var p := "%s/%s.json" % [CARTELLA, codice]
	if not FileAccess.file_exists(p):
		return {}
	var v = JSON.parse_string(FileAccess.get_file_as_string(p))
	return v if v is Dictionary else {}

static func elimina_locale(codice: String) -> void:
	var p := "%s/%s.json" % [CARTELLA, codice]
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(p)

## Elenco delle campagne locali: [{codice, nome, turno, salvato}], dalla più recente.
static func elenco_locale() -> Array:
	_assicura()
	var r := []
	var d := DirAccess.open(CARTELLA)
	if d == null:
		return r
	for f in d.get_files():
		if not f.ends_with(".json"):
			continue
		var st := carica_locale(f.get_basename())
		if st.is_empty():
			continue
		r.append({"codice": f.get_basename(), "nome": st.get("nome", "?"), "turno": int(st.get("turno", 0)),
			"salvato": str(st.get("salvato", "")), "vivi": st.get("equipaggio", []).filter(func(p): return not p.get("morto", false)).size()})
	r.sort_custom(func(a, b): return a.salvato > b.salvato)
	return r
