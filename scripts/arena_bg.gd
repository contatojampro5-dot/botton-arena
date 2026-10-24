extends Node2D
## Cenário "Santuário dos Núcleos", desenhado por código (leve para placa integrada).

const FLOOR_Y := 600.0
var t := 0.0
var stars: Array = []
var motes: Array = []
var islands: Array = []
var dim := 0.0            # escurece o cenário durante o supremo
var core_color := Color("6fb8ff")

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 90:
		stars.append([Vector2(rng.randf() * 1280, rng.randf() * 380), rng.randf_range(0.6, 2.0), rng.randf() * TAU])
	for i in 28:
		motes.append([Vector2(rng.randf() * 1280, rng.randf_range(250, 600)), rng.randf_range(8, 22), rng.randf() * TAU])
	islands = [[Vector2(170, 250), 90.0, 0.0], [Vector2(1110, 210), 110.0, 1.7], [Vector2(400, 150), 55.0, 3.1], [Vector2(900, 130), 45.0, 4.2]]

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	# céu em degradê
	var top := Color("120c2a")
	var mid := Color("3a2468")
	var low := Color("c4567a")
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 330), Vector2(0, 330)]), PackedColorArray([top, top, mid, mid]))
	draw_polygon(PackedVector2Array([Vector2(0, 330), Vector2(1280, 330), Vector2(1280, 560), Vector2(0, 560)]), PackedColorArray([mid, mid, low, low]))
	for s in stars:
		var a := 0.35 + 0.35 * sin(t * 1.3 + s[2])
		draw_circle(s[0], s[1], Color(1, 1, 1, a))
	# núcleo gigante ao fundo
	var c := Vector2(640, 250)
	var pulse := 1.0 + 0.04 * sin(t * 2.0)
	for i in 6:
		draw_circle(c, (150 - i * 18) * pulse, Color(core_color, 0.05 + i * 0.03))
	draw_circle(c, 48 * pulse, Color(core_color.lightened(0.5), 0.9))
	draw_circle(c, 30 * pulse, Color(1, 1, 1, 0.95))
	for i in 3:
		var r := 95.0 + i * 38.0
		var ang := t * (0.4 + i * 0.25) * (1 if i % 2 == 0 else -1)
		draw_arc(c, r, ang, ang + PI * 1.3, 48, Color(core_color, 0.45 - i * 0.1), 3.0 - i * 0.6)
	# montanhas distantes
	var mcol := Color("2a1a48")
	var pts := PackedVector2Array([Vector2(0, 560)])
	for i in 17:
		var x := i * 80.0
		pts.append(Vector2(x, 430 + 50 * sin(i * 1.7) + 30 * cos(i * 0.9)))
	pts.append(Vector2(1280, 560))
	draw_colored_polygon(pts, mcol)
	# ilhas flutuantes
	for isl in islands:
		var p: Vector2 = isl[0] + Vector2(0, 8 * sin(t * 0.8 + isl[2]))
		var w: float = isl[1]
		var poly := PackedVector2Array([p + Vector2(-w, 0), p + Vector2(w, 0), p + Vector2(w * 0.45, w * 0.55), p + Vector2(0, w * 0.9), p + Vector2(-w * 0.5, w * 0.5)])
		draw_colored_polygon(poly, Color("1d1236"))
		draw_rect(Rect2(p + Vector2(-w, -6), Vector2(w * 2, 8)), Color("3d2a66"))
		draw_circle(p + Vector2(0, -14), 5, Color(core_color, 0.8))
	# pilares do santuário
	for x in [120.0, 1160.0]:
		draw_rect(Rect2(x - 26, 330, 52, 270), Color("1e1438"))
		draw_rect(Rect2(x - 36, 320, 72, 18), Color("2e2052"))
		draw_rect(Rect2(x - 4, 360, 8, 200), Color(core_color, 0.35 + 0.2 * sin(t * 2 + x)))
	# chão
	draw_rect(Rect2(0, FLOOR_Y, 1280, 120), Color("1a1230"))
	draw_rect(Rect2(0, FLOOR_Y, 1280, 6), Color(core_color, 0.9))
	draw_rect(Rect2(0, FLOOR_Y + 6, 1280, 10), Color(core_color, 0.18))
	for i in 9:
		var y := FLOOR_Y + 22 + i * i * 1.6
		draw_line(Vector2(0, y), Vector2(1280, y), Color(1, 1, 1, 0.04), 1)
	for i in 21:
		var x := 640 + (i - 10) * 70.0
		draw_line(Vector2(640 + (i - 10) * 40.0, FLOOR_Y + 6), Vector2(x * 1.0 + (x - 640) * 0.9, 720), Color(1, 1, 1, 0.04), 1)
	# círculo rúnico central
	var rc := Vector2(640, FLOOR_Y + 40)
	draw_arc(rc, 150, 0, TAU, 64, Color(core_color, 0.25), 2)
	draw_arc(rc, 120, t * 0.3, t * 0.3 + TAU * 0.8, 48, Color(core_color, 0.2), 2)
	# partículas de energia subindo
	for m in motes:
		var y: float = fmod(m[0].y - t * m[1], 380.0) + 230.0
		var x: float = m[0].x + 10 * sin(t + m[2])
		draw_circle(Vector2(x, y), 2.0, Color(core_color.lightened(0.4), 0.5))
	if dim > 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, dim))
