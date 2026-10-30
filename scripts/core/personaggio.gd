## Personaggi dell'equipaggio: creazione con le tabelle del regolamento e statistiche effettive.
## Un personaggio è un Dictionary (si salva così com'è in JSON).
class_name Personaggio
extends RefCounted

const STAT := ["reazioni", "velocita", "combattimento", "robustezza", "acume", "fortuna"]
const NOMI_STAT := {"reazioni": "Reazioni", "velocita": "Velocità", "combattimento": "Combattimento",
	"robustezza": "Robustezza", "acume": "Acume", "fortuna": "Fortuna", "xp": "Esperienza"}

static var _contatore := 0

static func nuovo_id() -> String:
	_contatore += 1
	return "pg%d_%d" % [Time.get_ticks_usec() % 1000000, _contatore]

## Personaggio con il profilo base della specie (senza tiri sulle tabelle).
static func da_specie(id_specie: String, nome: String) -> Dictionary:
	var s := Dati.specie(id_specie)
	var pg := {
		"id": nuovo_id(), "nome": nome, "specie": id_specie,
		"reazioni": int(s.get("reazioni", 1)), "velocita": int(s.get("velocita", 4)),
		"combattimento": int(s.get("combattimento", 0)), "robustezza": int(s.get("robustezza", 3)),
		"acume": int(s.get("acume", 0)), "fortuna": int(s.get("fortuna", 0)), "xp": 0,
		"background": "", "motivazione": "", "classe": "", "leader": false,
		"oggetti": [], "infermeria": 0, "morto": false, "potenziamenti": [],
		"battaglie": 0, "uccisioni": 0, "storia": [], "aumento_acume": false,
	}
	return pg

static func info_specie(pg: Dictionary) -> Dictionary:
	return Dati.specie(str(pg.get("specie", "umano")))

static func e_robot(pg: Dictionary) -> bool:
	return bool(info_specie(pg).get("robot", false))

static func bonus(pg: Dictionary, chiave: String, predef = null):
	return info_specie(pg).get("bonus", {}).get(chiave, predef)

static func nome_specie(pg: Dictionary) -> String:
	return str(info_specie(pg).get("nome", pg.get("specie", "")))

static func usa_tabelle(pg: Dictionary) -> bool:
	return bool(bonus(pg, "tabelle_creazione", not e_robot(pg)))

## Massimo di una statistica per questo personaggio.
static func massimo(pg: Dictionary, stat: String) -> int:
	var lim: Dictionary = Dati.f("creazione").get("limiti_stat", {})
	var m := int(lim.get(stat, 99))
	var s := info_specie(pg)
	if stat == "fortuna":
		if s.has("fortuna_max"):
			m = int(s["fortuna_max"])
		elif str(pg.get("specie")) == "umano":
			m = int(lim.get("fortuna_umani", 3))
	if stat == "robustezza" and s.has("robustezza_max"):
		m = int(s["robustezza_max"])
	if bonus(pg, "robustezza_max") != null and stat == "robustezza":
		m = int(bonus(pg, "robustezza_max"))
	return m

static func modifica_stat(pg: Dictionary, stat: String, n: int) -> void:
	if stat == "xp":
		if not bonus(pg, "no_xp", false):
			pg["xp"] = int(pg.get("xp", 0)) + n
		return
	if not pg.has(stat):
		return
	pg[stat] = clampi(int(pg[stat]) + n, -3, massimo(pg, stat))
	if stat == "acume" and n > 0:
		pg["aumento_acume"] = true

## ---- equipaggiamento ----

static func oggetti(pg: Dictionary) -> Array:
	return pg.get("oggetti", [])

static func ha_oggetto(pg: Dictionary, id: String) -> bool:
	for o in oggetti(pg):
		if o.get("id") == id and not o.get("danneggiato", false):
			return true
	return false

static func armi(pg: Dictionary, anche_danneggiate := false) -> Array:
	var r := []
	for o in oggetti(pg):
		if Dati.e_arma(str(o.get("id"))) and (anche_danneggiate or not o.get("danneggiato", false)):
			r.append(str(o["id"]))
	return r

## Arma da tiro migliore (gittata > 0).
static func arma_tiro(pg: Dictionary) -> String:
	var best := ""
	var punteggio := -999.0
	for id in armi(pg):
		var a := Dati.arma(id)
		if int(a.get("gittata", 0)) <= 0:
			continue
		var p := float(a.get("colpi", 1)) * (2.0 + float(a.get("danno", 0))) + float(a.get("gittata", 0)) / 12.0
		if "monouso" in a.get("tratti", []):
			p -= 3.0
		if p > punteggio:
			punteggio = p
			best = id
	return best

## Arma per la Rissa: la migliore con tratto Mischia o Pistola (danno più alto, a parità Mischia).
static func arma_mischia(pg: Dictionary) -> String:
	var best := ""
	var punteggio := -999
	for id in armi(pg):
		var a := Dati.arma(id)
		var t: Array = a.get("tratti", [])
		if not ("mischia" in t or "pistola" in t):
			continue
		var p := int(a.get("danno", 0)) * 10 + (5 if "mischia" in t else 0)
		if p > punteggio:
			punteggio = p
			best = id
	return best

## Tiro salvezza dalle protezioni (corazza: false = schermo). Restituisce {"corazza": n, "schermo": n} (0 = nessuno).
static func salvezze(pg: Dictionary) -> Dictionary:
	var cor := []
	var sch := []
	var s := info_specie(pg)
	if s.has("salvezza"):
		cor.append(int(s["salvezza"]))
	for o in oggetti(pg):
		if o.get("danneggiato", false):
			continue
		var ogg := Dati.oggetto(str(o.get("id")))
		var e: Dictionary = ogg.get("effetto", {})
		if e.has("salvezza"):
			if str(ogg.get("tipo", "")) == "schermo":
				sch.append(int(e["salvezza"]))
			else:
				cor.append(int(e["salvezza"]))
	return {"corazza": _combina(cor), "schermo": _combina(sch), "tutte": _combina(cor + sch)}

## Più tiri salvezza: si usa il migliore migliorato di 1 (p.46).
static func _combina(v: Array) -> int:
	if v.is_empty():
		return 0
	v.sort()
	var b: int = v[0]
	if v.size() > 1:
		b -= 1
	return max(2, b)

## Statistica effettiva in battaglia (impianti e oggetti con bonus).
static func stat_effettiva(pg: Dictionary, stat: String) -> int:
	var v := int(pg.get(stat, 0))
	for o in oggetti(pg):
		if o.get("danneggiato", false):
			continue
		var e: Dictionary = Dati.oggetto(str(o.get("id"))).get("effetto", {})
		var b: Dictionary = e.get("stat", {})
		if b.has(stat):
			v += int(b[stat])
	return v

static func disponibile(pg: Dictionary) -> bool:
	return not pg.get("morto", false) and int(pg.get("infermeria", 0)) <= 0 and not pg.get("assente", false)

static func descrizione_breve(pg: Dictionary) -> String:
	var t := "%s (%s)" % [pg.get("nome", "?"), nome_specie(pg)]
	if pg.get("leader", false):
		t += " - Capo"
	return t

static func profilo(pg: Dictionary) -> String:
	return "Reaz %d  Vel %d\"  Comb %+d  Rob %d  Acume %+d  Fort %d  XP %d" % [
		int(pg.reazioni), int(pg.velocita), int(pg.combattimento), int(pg.robustezza), int(pg.acume), int(pg.fortuna), int(pg.xp)]

static func nome_stat(s: String) -> String:
	return NOMI_STAT.get(s, s)
