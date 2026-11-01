## Atmosfera della battaglia per la grafica (2D e 3D): nebbia, polvere, gas o buio, dalla condizione di
## schieramento, dagli eventi e dai tratti del mondo. Solo aspetto: le regole (visibilità) sono nel motore.
class_name Atmosfera
extends RefCounted

static func tipo(b: Battaglia) -> String:
	var cond := str(b.setup.get("condizione", {}).get("nome", ""))
	var ev := str(b.ultimo_evento.get("nome", ""))
	var tratti := " ".join(b.tratti_mondo).to_lower()
	if cond == "Buio" or tratti.contains("oscurità"):
		return "buio"
	if cond == "Scarsa visibilità":
		return "polvere"
	if cond == "Ambiente tossico":
		return "gas"
	if (ev == "Cambio di visibilità" and b.visibilita > 0) or tratti.contains("nebbia") or tratti.contains("foschia"):
		return "nebbia"
	return ""

## Texture morbida e rotonda per le particelle (sbuffi, scintille, lucciole).
static var _morbida: Texture2D

static func morbida() -> Texture2D:
	if _morbida == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_morbida = t
	return _morbida

## Gradiente da un colore al trasparente (per far sfumare le particelle).
static func sfuma(col: Color, inizio_alfa := 1.0) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(col.r, col.g, col.b, col.a * inizio_alfa))
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	g.add_point(0.2, col)
	return g

## Colori dell'esplosione per genere: [lampo, scintille, fumo].
static func colori_esplosione(genere: String) -> Array:
	match genere:
		"accecante":
			return [Color(1, 1, 1), Color(0.85, 0.95, 1.0), Color(0.85, 0.88, 0.95, 0.5)]
		"fiamma":
			return [Color(1.0, 0.6, 0.15), Color(1.0, 0.45, 0.1), Color(0.25, 0.22, 0.2, 0.55)]
		"cariche":
			return [Color(1.0, 0.85, 0.5), Color(1.0, 0.55, 0.15), Color(0.2, 0.18, 0.17, 0.7)]
	return [Color(1.0, 0.85, 0.45), Color(1.0, 0.6, 0.2), Color(0.3, 0.28, 0.26, 0.6)]
