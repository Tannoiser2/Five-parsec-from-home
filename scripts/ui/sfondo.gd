## Sfondo: cielo stellato della Frontiera, con un pianeta nel menu.
extends Control

var stelle := []
var pianeta := false:
	set(v):
		pianeta = v
		queue_redraw()
var t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r := RandomNumberGenerator.new()
	r.seed = 5150
	for i in 420:
		stelle.append([Vector2(r.randf(), r.randf()), r.randf_range(0.5, 2.2), r.randf_range(0.25, 1.0), r.randf() * TAU])

func _process(d: float) -> void:
	t += d
	if Engine.get_frames_drawn() % 6 == 0:
		queue_redraw()

func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), UI.SFONDO)
	# nebulosa
	for i in 6:
		var c := Vector2(s.x * (0.15 + 0.14 * i), s.y * (0.3 + 0.25 * sin(i * 1.7)))
		draw_circle(c, s.y * 0.35, Color(0.25, 0.12, 0.30, 0.035))
		draw_circle(c + Vector2(80, 40), s.y * 0.22, Color(0.10, 0.22, 0.32, 0.04))
	for st in stelle:
		var p: Vector2 = st[0] * s
		var a: float = st[2] * (0.7 + 0.3 * sin(t * 1.3 + st[3]))
		draw_circle(p, st[1], Color(0.95, 0.92, 0.85, a))
	if pianeta:
		var c := Vector2(s.x * 0.78, s.y * 0.72)
		var r := s.y * 0.42
		draw_circle(c, r * 1.06, Color(0.95, 0.6, 0.25, 0.08))
		draw_circle(c, r, Color(0.42, 0.24, 0.16))
		for i in 7:
			var y := c.y - r + r * 2.0 * (i + 0.5) / 7.0
			var w := sqrt(max(0.0, r * r - (y - c.y) * (y - c.y)))
			draw_line(Vector2(c.x - w * 0.97, y), Vector2(c.x + w * 0.97, y), Color(0.55, 0.32, 0.2, 0.35), r * 0.07)
		# terminatore
		draw_circle(c + Vector2(r * 0.35, r * 0.2), r * 0.92, Color(0, 0, 0, 0.35))
		draw_arc(c, r, -2.4, 0.2, 64, Color(1.0, 0.75, 0.45, 0.8), 3.0, true)
		# anello
		draw_arc(c, r * 1.45, PI * 0.92, PI * 2.05, 80, Color(0.85, 0.7, 0.5, 0.35), 4.0, true)
