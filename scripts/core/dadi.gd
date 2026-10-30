## Dadi del gioco: un generatore con seme (le campagne si possono salvare e riprendere con lo stesso stato).
## Le espressioni sono quelle dei dati: "1d6", "2d6+1", "1d3", "d100", "2d6_max" (il più alto di 2d6), "2d6_min", "-1d6".
class_name Dadi
extends RefCounted

var rng := RandomNumberGenerator.new()
## Ultimi tiri, per mostrarli nel diario
var ultimo: Array = []

func _init(seme: int = 0) -> void:
	if seme == 0:
		rng.randomize()
	else:
		rng.seed = seme

func stato() -> Dictionary:
	return {"seme": str(rng.seed), "stato": str(rng.state)}

func ripristina(d: Dictionary) -> void:
	if d.has("seme"):
		rng.seed = int(d["seme"])
	if d.has("stato"):
		rng.state = int(d["stato"])

func d(facce: int) -> int:
	return rng.randi_range(1, max(1, facce))

func d6() -> int:
	return d(6)

func d10() -> int:
	return d(10)

func d100() -> int:
	return d(100)

## Tira un'espressione di dadi. Accetta anche numeri interi.
func tira(espr) -> int:
	ultimo = []
	if espr == null:
		return 0
	if espr is int or espr is float:
		return int(espr)
	var s := str(espr).strip_edges().to_lower().replace(" ", "")
	if s == "":
		return 0
	if s.is_valid_int():
		return int(s)
	var segno := 1
	if s.begins_with("-"):
		segno = -1
		s = s.substr(1)
	elif s.begins_with("+"):
		s = s.substr(1)
	var modo := ""
	if s.ends_with("_max"):
		modo = "max"
		s = s.trim_suffix("_max")
	elif s.ends_with("_min"):
		modo = "min"
		s = s.trim_suffix("_min")
	var bonus := 0
	var p := s.find("+")
	if p > 0:
		bonus = int(s.substr(p + 1))
		s = s.substr(0, p)
	else:
		p = s.find("-")
		if p > 0:
			bonus = -int(s.substr(p + 1))
			s = s.substr(0, p)
	var dpos := s.find("d")
	if dpos < 0:
		return segno * (int(s) + bonus)
	var n := 1 if dpos == 0 else int(s.substr(0, dpos))
	var f := int(s.substr(dpos + 1))
	var tot := 0
	var best := -1
	var worst := 999
	for i in n:
		var r := d(f)
		ultimo.append(r)
		tot += r
		best = max(best, r)
		worst = min(worst, r)
	if modo == "max":
		tot = best
	elif modo == "min":
		tot = worst
	return segno * (tot + bonus)

## Tipo di dado di una tabella dei dati ({"_dado": "d100", "righe": [...]}) e tiro sulla tabella.
static func facce_tabella(tab) -> int:
	if tab is Dictionary:
		var s := str(tab.get("_dado", "d100"))
		if s == "2d6":
			return -12
		return int(s.trim_prefix("1").trim_prefix("d"))
	return 100

func tira_tabella(tab) -> int:
	var f := facce_tabella(tab)
	if f == -12:
		return d6() + d6()
	return d(f)

## Riga di una tabella per un risultato.
static func riga(tab, tiro: int) -> Dictionary:
	var righe = tab.get("righe", []) if tab is Dictionary else tab
	for r in righe:
		if tiro >= int(r.get("da", 0)) and tiro <= int(r.get("a", 0)):
			return r
	if righe.size() > 0:
		return righe[0] if tiro < int(righe[0].get("da", 0)) else righe[righe.size() - 1]
	return {}

## Tira e restituisce {"tiro": n, "riga": {...}}.
func su_tabella(tab, mod: int = 0) -> Dictionary:
	var t := tira_tabella(tab) + mod
	return {"tiro": t, "riga": riga(tab, t)}

func scegli(arr: Array):
	if arr.is_empty():
		return null
	return arr[rng.randi_range(0, arr.size() - 1)]

func mescola(arr: Array) -> Array:
	var a := arr.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
	return a
