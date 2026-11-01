## Linea di vista per l'interfaccia (2D e 3D): esito, colore, punto in cui si interrompe e testo da mostrare.
class_name LineaVista
extends RefCounted

const VERDE := Color(0.45, 0.95, 0.5, 0.95)
const GIALLO := Color(1.0, 0.85, 0.3, 0.95)
const ROSSO := Color(1.0, 0.3, 0.25, 0.95)

## Da una figura u alla casella p. Restituisce {vede, copertura, colore, blocco (Vector2i o null), testo}.
static func vista(b: Battaglia, u: Dictionary, p: Vector2i) -> Dictionary:
	var f := b.figura_in(p)
	var r := b.lds(u.pos, p, false, u, f)
	var d := Battaglia.dist(u.pos, p)
	var out := {"vede": bool(r.vede), "copertura": bool(r.copertura), "blocco": null, "colore": VERDE, "testo": ""}
	if r.vede:
		out.colore = GIALLO if r.copertura else VERDE
		out.testo = "In vista, in copertura" if r.copertura else "In vista"
	else:
		out.colore = ROSSO
		if r.has("dove"):
			out.blocco = r.dove
			out.testo = "Vista bloccata"
		else:
			out.testo = "Fuori vista (visibilità)"
	out.testo += "  -  %d\"" % d
	return out
