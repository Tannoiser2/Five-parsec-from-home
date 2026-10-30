## Controllo che mostra una pedina (immagine o segnaposto).
extends Control

var chiave := ""
var nome := ""
var nemico := false
var attenuata := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _draw() -> void:
	var r: float = min(size.x, size.y) / 2.0 - 4.0
	Pedine.disegna(self, size / 2.0, r, chiave, nome, nemico, false, attenuata)
