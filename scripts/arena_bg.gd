extends Node2D
## Cenários das arenas, desenhados por código.
## A parte parada de cada arena é desenhada UMA vez numa imagem (Game.bake_arena) e depois só
## a imagem é mostrada; por cima vão poucos elementos animados (brilhos, partículas, engrenagens).
## arena: "santuario", "vulcao", "floresta", "glacial", "recife", "cosmos", "oficina"

const FLOOR_Y := 600.0
const DrawProxy := preload("res://scripts/draw_proxy.gd")
var arena := "santuario"
var static_mode := false      # true = só a parte parada (usado para gerar a imagem)
var baked: Texture2D = null
var t := 0.0
var dim := 0.0                # escurece o cenário durante o supremo
var core_color := Color("6fb8ff")
var stars: Array = []
var motes: Array = []
var islands: Array = []
var rng := RandomNumberGenerator.new()
var glow: Node2D
var draw_us := 0
var draw_n := 0

func _ready() -> void:
	rng.seed = 7
	core_color = Game.ARENAS[Game.arena_index(arena)].cor
	for i in 260:
		stars.append([Vector2(rng.randf() * 1280, rng.randf() * 460), rng.randf_range(0.5, 2.0), rng.randf() * TAU])
	for i in 40:
		motes.append([Vector2(rng.randf() * 1280, rng.randf_range(0, 700)), rng.randf_range(8, 30), rng.randf() * TAU, rng.randf_range(1.5, 3.5)])
	islands = [[Vector2(170, 250), 90.0, 0.0], [Vector2(1110, 210), 110.0, 1.7], [Vector2(400, 150), 55.0, 3.1], [Vector2(900, 130), 45.0, 4.2]]
	if static_mode:
		return
	glow = DrawProxy.new()
	glow.alvo = self
	glow.metodo = "_draw_glow"
	glow.material = DrawProxy.aditivo()
	add_child(glow)
	_bake()

func _bake() -> void:
	var tx: Texture2D = await Game.bake_arena(arena)
	if tx and is_instance_valid(self):
		baked = tx
		queue_redraw()

func _process(delta: float) -> void:
	if static_mode:
		return
	t += delta
	queue_redraw()

func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	if static_mode:
		_draw_static()
	else:
		if baked:
			draw_texture(baked, Vector2.ZERO)
		else:
			_draw_static()
		_draw_dynamic()
	draw_us += Time.get_ticks_usec() - t0
	draw_n += 1

func _draw_static() -> void:
	match arena:
		"vulcao": _vulcao_s()
		"floresta": _floresta_s()
		"glacial": _glacial_s()
		"recife": _recife_s()
		"cosmos": _cosmos_s()
		"oficina": _oficina_s()
		_: _santuario_s()
	_vinheta()

func _draw_dynamic() -> void:
	match arena:
		"vulcao": _vulcao_d()
		"recife": _recife_d()
		"oficina": _oficina_d()
		"glacial": _glacial_d()
	if dim > 0.0:
		draw_rect(Rect2(-200, -200, 1680, 1120), Color(0, 0, 0, dim))

## brilhos com luz somada (na camada aditiva)
func _draw_glow(ci: CanvasItem) -> void:
	if dim > 0.6:
		return
	var a := 1.0 - dim
	match arena:
		"vulcao": _vulcao_g(ci, a)
		"floresta": _floresta_g(ci, a)
		"glacial": _glacial_g(ci, a)
		"recife": _recife_g(ci, a)
		"cosmos": _cosmos_g(ci, a)
		"oficina": _oficina_g(ci, a)
		_: _santuario_g(ci, a)

# ------------------------------------------------------------------ utilidades
func _grad(y0: float, y1: float, c0: Color, c1: Color) -> void:
	draw_polygon(PackedVector2Array([Vector2(-200, y0), Vector2(1480, y0), Vector2(1480, y1), Vector2(-200, y1)]), PackedColorArray([c0, c0, c1, c1]))

func _stars(a := 1.0, limite := 460.0) -> void:
	for s in stars:
		if s[0].y > limite: continue
		var al: float = (0.25 + 0.5 * absf(sin(s[2] * 3.0))) * a
		draw_rect(Rect2(s[0], Vector2(s[1], s[1])), Color(1, 1, 1, al))

func _dot(ci: CanvasItem, p: Vector2, r: float, cor: Color) -> void:
	ci.draw_texture_rect(Game.dot_tex, Rect2(p - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), false, cor)

func _mountains(base: float, amp: float, freq: float, ph: float, cor: Color, jag := false) -> void:
	var pts := PackedVector2Array([Vector2(-200, FLOOR_Y + 10)])
	var n := 34
	for i in n + 1:
		var x := -200.0 + i * 1680.0 / n
		var y := base - amp * (0.5 + 0.5 * sin(i * freq + ph)) - amp * 0.4 * (0.5 + 0.5 * cos(i * freq * 2.3 + ph))
		if jag and i % 2 == 1: y -= amp * 0.35
		pts.append(Vector2(x, y))
	pts.append(Vector2(1480, FLOOR_Y + 10))
	draw_colored_polygon(pts, cor)

func _floor_base(c_top: Color, c_bottom: Color, linha: Color) -> void:
	draw_polygon(PackedVector2Array([Vector2(-200, FLOOR_Y), Vector2(1480, FLOOR_Y), Vector2(1480, 920), Vector2(-200, 920)]), PackedColorArray([c_top, c_top, c_bottom, c_bottom]))
	draw_rect(Rect2(-200, FLOOR_Y, 1680, 5), linha)
	draw_rect(Rect2(-200, FLOOR_Y + 5, 1680, 10), Color(linha, 0.18))

func _perspective_lines(cor: Color) -> void:
	for i in 9:
		var y := FLOOR_Y + 22 + i * i * 1.6
		draw_line(Vector2(-200, y), Vector2(1480, y), cor, 1)
	for i in 25:
		var x := 640 + (i - 12) * 70.0
		draw_line(Vector2(640 + (i - 12) * 40.0, FLOOR_Y + 6), Vector2(x + (x - 640) * 0.9, 760), cor, 1)

func _vinheta() -> void:
	# cantos levemente mais escuros (dá profundidade)
	for i in 6:
		var a := 0.05
		draw_rect(Rect2(0, 0, 1280, 18 + i * 10), Color(0, 0, 0, a))
		draw_rect(Rect2(0, 0, 14 + i * 10, 720), Color(0, 0, 0, a))
		draw_rect(Rect2(1280 - 14 - i * 10, 0, 14 + i * 10, 720), Color(0, 0, 0, a))

# ------------------------------------------------------------------ 1. Santuário dos Núcleos
func _santuario_s() -> void:
	_grad(-200, 330, Color("120c2a"), Color("3a2468"))
	_grad(330, 560, Color("3a2468"), Color("c4567a"))
	_stars()
	var c := Vector2(640, 250)
	for i in 6:
		draw_circle(c, 150 - i * 18, Color(core_color, 0.05 + i * 0.03))
	draw_circle(c, 48, Color(core_color.lightened(0.5), 0.9))
	draw_circle(c, 30, Color(1, 1, 1, 0.95))
	_mountains(500, 50, 1.1, 2.0, Color("3a2458"))
	_mountains(470, 60, 1.7, 0.0, Color("2a1a48"))
	for isl in islands:
		var p: Vector2 = isl[0]
		var w: float = isl[1]
		var poly := PackedVector2Array([p + Vector2(-w, 0), p + Vector2(w, 0), p + Vector2(w * 0.45, w * 0.55), p + Vector2(0, w * 0.9), p + Vector2(-w * 0.5, w * 0.5)])
		draw_colored_polygon(poly, Color("1d1236"))
		draw_rect(Rect2(p + Vector2(-w, -6), Vector2(w * 2, 8)), Color("3d2a66"))
		draw_circle(p + Vector2(0, -14), 5, Color(core_color, 0.8))
	for x in [120.0, 1160.0]:
		draw_rect(Rect2(x - 26, 330, 52, 270), Color("1e1438"))
		draw_rect(Rect2(x - 36, 320, 72, 18), Color("2e2052"))
		draw_rect(Rect2(x - 4, 360, 8, 200), Color(core_color, 0.35))
	_floor_base(Color("1a1230"), Color("0e0a1c"), Color(core_color, 0.9))
	_perspective_lines(Color(1, 1, 1, 0.04))
	var rc := Vector2(640, FLOOR_Y + 40)
	draw_arc(rc, 150, 0, TAU, 64, Color(core_color, 0.25), 2)
	draw_arc(rc, 120, 0, TAU * 0.8, 48, Color(core_color, 0.2), 2)

func _santuario_g(ci: CanvasItem, a: float) -> void:
	var c := Vector2(640, 250)
	var pulse := 0.5 + 0.5 * sin(t * 2.0)
	_dot(ci, c, 170 + 20 * pulse, Color(core_color, 0.22 * a))
	_dot(ci, c, 70, Color(1, 1, 1, (0.25 + 0.2 * pulse) * a))
	for i in 3:
		var r := 95.0 + i * 38.0
		var ang := t * (0.4 + i * 0.25) * (1 if i % 2 == 0 else -1)
		ci.draw_arc(c, r, ang, ang + PI * 1.3, 40, Color(core_color, (0.4 - i * 0.1) * a), 3.0 - i * 0.6)
	for x in [120.0, 1160.0]:
		ci.draw_rect(Rect2(x - 4, 360, 8, 200), Color(core_color, (0.15 + 0.15 * sin(t * 2 + x)) * a))
	if Game.leve():
		return
	for m in motes:
		var y: float = fmod(m[0].y - t * m[1], 380.0) + 230.0
		var x2: float = m[0].x + 10 * sin(t + m[2])
		_dot(ci, Vector2(x2, y), 6.0, Color(core_color.lightened(0.4), 0.55 * a))
	for i in 24:
		var s: Array = stars[i * 7]
		_dot(ci, s[0], 5.0, Color(1, 1, 1, (0.4 + 0.4 * sin(t * 2.0 + s[2])) * a))

# ------------------------------------------------------------------ 2. Cratera Ardente
func _vulcao_s() -> void:
	_grad(-200, 250, Color("140405"), Color("3a0c08"))
	_grad(250, 470, Color("3a0c08"), Color("b8401a"))
	_grad(470, 600, Color("b8401a"), Color("ff7a2a"))
	for i in 7:
		var px := 640.0 + sin(i * 1.3) * 40.0 + i * 12.0
		var py := 190.0 - i * 34.0
		draw_circle(Vector2(px, py), 50 + i * 9, Color(0.12, 0.06, 0.06, 0.3))
	var crater := 205.0
	draw_colored_polygon(PackedVector2Array([Vector2(330, 520), Vector2(570, crater), Vector2(710, crater), Vector2(960, 520)]), Color("2a0d0a"))
	draw_set_transform(Vector2(640, crater), 0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 62, Color(1.0, 0.65, 0.2, 0.9))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	for s in [[600.0, -1.0], [680.0, 1.0], [640.0, 0.3]]:
		var pts := PackedVector2Array()
		for k in 9:
			var y := crater + 8 + k * 36.0
			pts.append(Vector2(s[0] + s[1] * k * 18.0 + sin(k * 1.3 + s[0]) * 10.0, y))
		draw_polyline(pts, Color(1.0, 0.5, 0.1, 0.35), 14)
		draw_polyline(pts, Color(1.0, 0.75, 0.25, 0.9), 5)
	_mountains(500, 90, 2.3, 1.0, Color("1d0807"), true)
	for x in [90.0, 1190.0]:
		var pts2 := PackedVector2Array([Vector2(x - 70, FLOOR_Y), Vector2(x - 30, 330), Vector2(x + 10, 300), Vector2(x + 60, FLOOR_Y)])
		draw_colored_polygon(pts2, Color("140606"))
		draw_line(Vector2(x - 20, 560), Vector2(x, 380), Color(1, 0.45, 0.1, 0.6), 3)
	_floor_base(Color("2a1210"), Color("120606"), Color(1.0, 0.5, 0.15, 0.95))
	for i in 9:
		var cx := 80.0 + i * 140.0
		var pts3 := PackedVector2Array([Vector2(cx, FLOOR_Y + 8), Vector2(cx + 20, FLOOR_Y + 30), Vector2(cx - 10, FLOOR_Y + 55), Vector2(cx + 25, FLOOR_Y + 90)])
		draw_polyline(pts3, Color(1.0, 0.45, 0.1, 0.6), 3)
	draw_rect(Rect2(-200, 690, 1680, 40), Color("ff6a1a"))

func _vulcao_d() -> void:
	if Game.leve():
		return
	for i in 14:
		var bx := fmod(i * 97.0 + t * 30.0, 1400.0) - 60.0
		draw_circle(Vector2(bx, 695 + sin(t * 3 + i) * 3), 6 + (i % 3) * 3, Color("ffc23a"))

func _vulcao_g(ci: CanvasItem, a: float) -> void:
	var glow_k := 0.6 + 0.4 * sin(t * 3.0)
	ci.draw_set_transform(Vector2(640, 205), 0, Vector2(1.0, 0.3))
	_dot(ci, Vector2.ZERO, 160, Color(1.0, 0.45, 0.1, 0.45 * glow_k * a))
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	_dot(ci, Vector2(640, 705), 300, Color(1.0, 0.4, 0.1, 0.12 * a))
	if Game.leve():
		return
	for m in motes:
		var y: float = 700.0 - fmod(t * m[1] * 3.0 + m[0].y, 700.0)
		var x: float = m[0].x + 14 * sin(t * 1.2 + m[2])
		_dot(ci, Vector2(x, y), m[3] * 2.4, Color(1.0, 0.55 + 0.3 * sin(m[2]), 0.15, 0.85 * a))

# ------------------------------------------------------------------ 3. Floresta Ancestral
func _floresta_s() -> void:
	_grad(-200, 240, Color("0a2424"), Color("2a5e48"))
	_grad(240, 560, Color("2a5e48"), Color("e8c271"))
	for i in 5:
		var x0 := 700.0 + i * 120.0
		draw_colored_polygon(PackedVector2Array([Vector2(x0, -200), Vector2(x0 + 60, -200), Vector2(x0 - 240, 600), Vector2(x0 - 380, 600)]), Color(1.0, 0.95, 0.7, 0.05))
	var camadas := [[Color("1a4038"), 0.55, 330.0], [Color("173a2c"), 0.75, 380.0], [Color("12301f"), 1.0, 430.0]]
	for li in camadas.size():
		var cor: Color = camadas[li][0]
		var esc: float = camadas[li][1]
		var topo: float = camadas[li][2]
		var r2 := RandomNumberGenerator.new()
		r2.seed = 100 + li
		var x := -150.0 + r2.randf() * 80.0
		while x < 1430.0:
			var w := r2.randf_range(14.0, 30.0) * esc * 1.4
			var copa := r2.randf_range(60.0, 95.0) * esc * 1.3
			var cy := topo - r2.randf_range(0.0, 70.0) * esc
			draw_colored_polygon(PackedVector2Array([Vector2(x - w, FLOOR_Y), Vector2(x - w * 0.55, cy), Vector2(x + w * 0.55, cy), Vector2(x + w, FLOOR_Y)]), cor.darkened(0.25))
			for k in 5:
				var ang := -PI * 0.9 + k * PI * 0.45
				draw_circle(Vector2(x + cos(ang) * copa * 0.6, cy - copa * 0.35 + sin(ang) * copa * 0.35), copa * (0.6 + 0.12 * (k % 2)), cor)
			draw_circle(Vector2(x, cy - copa * 0.6), copa * 0.7, cor)
			draw_circle(Vector2(x - copa * 0.2, cy - copa * 0.75), copa * 0.35, cor.lightened(0.06))
			x += r2.randf_range(130.0, 230.0) * esc
		_grad(topo + 60.0, FLOOR_Y, Color(0.75, 0.9, 0.7, 0.0), Color(0.75, 0.9, 0.7, 0.1))
	var tx := 640.0
	var tronco := PackedVector2Array([Vector2(tx - 110, FLOOR_Y), Vector2(tx - 70, FLOOR_Y - 60), Vector2(tx - 52, 300), Vector2(tx - 80, 230),
		Vector2(tx - 20, 270), Vector2(tx + 30, 225), Vector2(tx + 48, 300), Vector2(tx + 70, FLOOR_Y - 60), Vector2(tx + 115, FLOOR_Y)])
	draw_colored_polygon(tronco, Color("3a2818"))
	draw_line(Vector2(tx - 20, FLOOR_Y - 20), Vector2(tx - 10, 320), Color("2a1c10"), 4)
	draw_line(Vector2(tx + 22, FLOOR_Y - 30), Vector2(tx + 12, 330), Color("2a1c10"), 3)
	for k in 7:
		draw_circle(Vector2(tx + sin(k * 1.7) * 150.0, 200.0 + cos(k * 2.1) * 55.0), 105.0 - k * 6.0, Color("24502a"))
	for k in 5:
		draw_circle(Vector2(tx + sin(k * 2.3 + 1.0) * 110.0, 170.0 + cos(k * 1.4) * 40.0), 60.0, Color("2e6232"))
	draw_circle(Vector2(tx, 400), 20, Color(core_color.lightened(0.5), 0.9))
	_floor_base(Color("2a3d1e"), Color("121c0c"), Color(core_color, 0.7))
	for i in 140:
		var gx := -100.0 + i * 11.0
		var sway := sin(i * 0.4) * 4.0
		draw_line(Vector2(gx, FLOOR_Y + 2), Vector2(gx + sway, FLOOR_Y - 10 - (i * 7) % 9), Color("5a8a3a"), 2)
	for i in 6:
		var mx := 90.0 + i * 220.0
		draw_rect(Rect2(mx - 3, FLOOR_Y + 30, 6, 14), Color("e8e0c8"))
		draw_circle(Vector2(mx, FLOOR_Y + 30), 12, Color(core_color.lightened(0.2), 0.75))

func _floresta_g(ci: CanvasItem, a: float) -> void:
	var pulse := 0.6 + 0.4 * sin(t * 2.0)
	_dot(ci, Vector2(640, 400), 70, Color(core_color, 0.45 * pulse * a))
	for i in 6:
		_dot(ci, Vector2(90.0 + i * 220.0, FLOOR_Y + 30), 30, Color(core_color, (0.15 + 0.12 * sin(t * 2 + i)) * a))
	if Game.leve():
		return
	for m in motes:
		var fx = m[0].x + sin(t * 0.7 + m[2]) * 60.0
		var fy := 250.0 + fmod(m[0].y, 330.0) + cos(t * 0.9 + m[2]) * 30.0
		var al := 0.5 + 0.5 * sin(t * m[3] + m[2])
		_dot(ci, Vector2(fx, fy), 10, Color(0.75, 1.0, 0.35, 0.55 * al * a))

# ------------------------------------------------------------------ 4. Pico Congelado
func _glacial_s() -> void:
	_grad(-200, 300, Color("050d24"), Color("0f2c58"))
	_grad(300, 560, Color("0f2c58"), Color("4a7ab8"))
	_stars(0.9, 330.0)
	var cores := [Color(0.3, 1.0, 0.6), Color(0.3, 0.8, 1.0), Color(0.75, 0.4, 1.0)]
	for b in 3:
		var prev := Vector2.ZERO
		var prev_h := 0.0
		for i in 43:
			var x := -200.0 + i * 40.0
			var y := 80.0 + b * 50.0 + sin(x * 0.006 + b) * 40.0 + sin(x * 0.017) * 12.0
			var hgt := 110.0 + 40.0 * sin(x * 0.01 + b)
			var cur := Vector2(x, y)
			if i > 0:
				var c: Color = cores[b]
				var a1 := 0.16 + 0.08 * sin(x * 0.02 + b * 2.0)
				draw_polygon(PackedVector2Array([prev, cur, cur + Vector2(0, hgt), prev + Vector2(0, prev_h)]),
					PackedColorArray([Color(c, a1), Color(c, a1), Color(c, 0.0), Color(c, 0.0)]))
				draw_line(prev, cur, Color(c.lightened(0.4), a1 * 1.6), 2)
			prev = cur
			prev_h = hgt
	_mountains(430, 150, 0.9, 0.4, Color("2a4a78"), true)
	_mountains(470, 110, 1.3, 2.0, Color("3a5f92"), true)
	for i in 8:
		var px := -40.0 + i * 190.0
		var py := 330.0 + (i % 3) * 30.0
		draw_colored_polygon(PackedVector2Array([Vector2(px - 50, py + 40), Vector2(px, py), Vector2(px + 55, py + 45), Vector2(px + 20, py + 34), Vector2(px - 10, py + 46)]), Color(0.92, 0.96, 1.0, 0.85))
	for i in 6:
		var px2 := 60.0 + i * 240.0 + (i % 2) * 60.0
		for k in 3:
			var w := 46.0 - k * 12.0
			var y := 560.0 - k * 26.0
			draw_colored_polygon(PackedVector2Array([Vector2(px2 - w, y), Vector2(px2, y - 46), Vector2(px2 + w, y)]), Color("16304a"))
			draw_colored_polygon(PackedVector2Array([Vector2(px2 - w * 0.5, y - 23), Vector2(px2, y - 46), Vector2(px2 + w * 0.5, y - 23)]), Color(0.9, 0.95, 1.0, 0.8))
	_floor_base(Color("7aa8d8"), Color("2a4a78"), Color(1, 1, 1, 0.9))
	for i in 7:
		var rx := 60.0 + i * 190.0
		draw_line(Vector2(rx, FLOOR_Y + 20), Vector2(rx + 120, FLOOR_Y + 60), Color(1, 1, 1, 0.25), 3)
		draw_line(Vector2(rx + 40, FLOOR_Y + 70), Vector2(rx + 90, FLOOR_Y + 100), Color(1, 1, 1, 0.18), 2)
	draw_colored_polygon(PackedVector2Array([Vector2(-200, FLOOR_Y + 2), Vector2(120, FLOOR_Y + 2), Vector2(60, FLOOR_Y - 18), Vector2(-200, FLOOR_Y - 26)]), Color(0.93, 0.97, 1.0))
	draw_colored_polygon(PackedVector2Array([Vector2(1480, FLOOR_Y + 2), Vector2(1160, FLOOR_Y + 2), Vector2(1220, FLOOR_Y - 20), Vector2(1480, FLOOR_Y - 26)]), Color(0.93, 0.97, 1.0))

func _glacial_d() -> void:
	var n := 20 if Game.leve() else 40
	for i in n:
		var m: Array = motes[i]
		var sx: float = fmod(m[0].x + sin(t * 0.8 + m[2]) * 40.0, 1400.0) - 60.0
		var sy: float = fmod(m[0].y + t * m[1] * 2.0, 760.0) - 30.0
		draw_rect(Rect2(Vector2(sx, sy), Vector2(m[3], m[3])), Color(1, 1, 1, 0.85))

func _glacial_g(ci: CanvasItem, a: float) -> void:
	if Game.leve():
		return
	# brilho da aurora que passeia
	var x := fmod(t * 120.0, 1800.0) - 260.0
	_dot(ci, Vector2(x, 150), 160, Color(0.3, 1.0, 0.7, 0.10 * a))
	_dot(ci, Vector2(1280 - x * 0.7, 190), 140, Color(0.6, 0.4, 1.0, 0.08 * a))

# ------------------------------------------------------------------ 5. Costa das Marés
func _recife_s() -> void:
	_grad(-200, 200, Color("2a1a5a"), Color("8a3a7a"))
	_grad(200, 400, Color("8a3a7a"), Color("ffb070"))
	draw_circle(Vector2(640, 400), 110, Color(1.0, 0.75, 0.4, 0.25))
	draw_circle(Vector2(640, 400), 80, Color(1.0, 0.85, 0.5))
	for i in 5:
		var cx := i * 300.0 - 40.0
		for k in 4:
			draw_circle(Vector2(cx + k * 34, 150 + i * 22 + sin(k * 1.4) * 8), 26 + k * 4, Color(1.0, 0.75, 0.75, 0.35))
	_grad(400, 560, Color("ff9a6a"), Color("1a4a8a"))
	draw_rect(Rect2(-200, 400, 1680, 160), Color("1a3a7a", 0.55))
	for i in 10:
		var y := 410.0 + i * 15.0
		var pts := PackedVector2Array()
		for k in 30:
			var x := -200.0 + k * 58.0
			pts.append(Vector2(x, y + sin(x * 0.02 + i) * (2.0 + i * 0.4)))
		draw_polyline(pts, Color(1, 1, 1, 0.08 + i * 0.01), 2)
	draw_colored_polygon(PackedVector2Array([Vector2(160, 402), Vector2(230, 372), Vector2(320, 380), Vector2(380, 402)]), Color("3a1a4a"))
	draw_colored_polygon(PackedVector2Array([Vector2(900, 402), Vector2(980, 382), Vector2(1040, 402)]), Color("3a1a4a"))
	for side in [[70.0, 1.0], [1210.0, -1.0]]:
		var bx: float = side[0]
		var s: float = side[1]
		var top := Vector2(bx + s * 70, 300)
		draw_polyline(PackedVector2Array([Vector2(bx, FLOOR_Y), Vector2(bx + s * 30, 450), top]), Color("2a1420"), 16)
		for k in 6:
			var ang := -PI / 2 + (k - 2.5) * 0.55
			var tip := top + Vector2(cos(ang) * 110, sin(ang) * 60 + 50)
			draw_polyline(PackedVector2Array([top, top.lerp(tip, 0.5) + Vector2(0, -20), tip]), Color("1f1030"), 9)
	_floor_base(Color("c99a62"), Color("6a4a2a"), Color(1, 0.95, 0.85, 0.9))
	for i in 8:
		var sx := 80.0 + i * 160.0
		draw_circle(Vector2(sx, FLOOR_Y + 70 + (i % 3) * 18), 6, Color("f2d6b0"))

func _recife_d() -> void:
	var foam_y := FLOOR_Y + 14.0 + sin(t * 0.8) * 8.0
	var fp := PackedVector2Array()
	for k in 32:
		var x := -200.0 + k * 55.0
		fp.append(Vector2(x, foam_y + sin(x * 0.03 + t * 2.0) * 4.0))
	draw_polyline(fp, Color(1, 1, 1, 0.75), 4)
	if Game.leve():
		return
	for i in 4:
		var gx := fmod(i * 330.0 + t * 40.0, 1500.0) - 100.0
		var gy := 120.0 + i * 30.0 + sin(t * 2 + i) * 8.0
		var flap := sin(t * 8.0 + i) * 6.0
		draw_polyline(PackedVector2Array([Vector2(gx - 14, gy - flap), Vector2(gx, gy), Vector2(gx + 14, gy - flap)]), Color("2a1a3a"), 2)

func _recife_g(ci: CanvasItem, a: float) -> void:
	_dot(ci, Vector2(640, 400), 200, Color(1.0, 0.6, 0.3, 0.18 * a))
	for i in 12:
		var w := 60.0 - i * 4.0
		ci.draw_line(Vector2(640 - w + sin(t * 3 + i) * 10, 405 + i * 12), Vector2(640 + w + sin(t * 3 + i) * 10, 405 + i * 12), Color(1.0, 0.75, 0.4, 0.35 * a), 3)

# ------------------------------------------------------------------ 6. Órbita Estelar
func _cosmos_s() -> void:
	_grad(-200, 920, Color("05030f"), Color("120a2a"))
	for n in [[Vector2(300, 200), 260.0, Color(0.6, 0.25, 0.9)], [Vector2(950, 320), 300.0, Color(0.2, 0.4, 1.0)], [Vector2(640, 120), 200.0, Color(1.0, 0.3, 0.6)]]:
		for k in 6:
			draw_circle(n[0] + Vector2(sin(k) * 20, cos(k * 1.3) * 15), n[1] * (1.0 - k * 0.13), Color(n[2], 0.05))
	_stars(1.2, 720.0)
	var pc := Vector2(1030, 170)
	draw_set_transform(pc, -0.3, Vector2(1.0, 0.28))
	draw_arc(Vector2.ZERO, 150, PI, TAU, 48, Color("f2d6a0", 0.8), 10)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_circle(pc, 92, Color("e8a24a"))
	draw_circle(pc + Vector2(-20, -20), 70, Color("f2c27a", 0.6))
	for k in 4:
		draw_line(pc + Vector2(-88, -30 + k * 20), pc + Vector2(88, -30 + k * 20), Color("c47a2a", 0.4), 6)
	draw_circle(pc + Vector2(30, 28), 70, Color(0, 0, 0, 0.18))
	draw_set_transform(pc, -0.3, Vector2(1.0, 0.28))
	draw_arc(Vector2.ZERO, 150, 0, PI, 48, Color("f2d6a0", 0.8), 10)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_circle(Vector2(230, 120), 34, Color("b8b8d8"))
	draw_circle(Vector2(240, 112), 28, Color("05030f", 0.35))
	draw_polygon(PackedVector2Array([Vector2(-200, FLOOR_Y), Vector2(1480, FLOOR_Y), Vector2(1480, 668), Vector2(-200, 668)]), PackedColorArray([Color("2a2a48"), Color("2a2a48"), Color("15152a"), Color("15152a")]))
	draw_rect(Rect2(-200, FLOOR_Y, 1680, 4), Color(core_color, 0.95))
	for i in 18:
		var x := -100.0 + i * 90.0
		draw_line(Vector2(x, FLOOR_Y + 4), Vector2(x - 20, 668), Color(1, 1, 1, 0.06), 2)
	draw_rect(Rect2(-200, 668, 1680, 14), Color("3a3a60"))
	for i in 20:
		draw_circle(Vector2(-100.0 + i * 80.0, 675), 4, Color(core_color.lightened(0.4), 0.3))
	draw_rect(Rect2(-200, 682, 1680, 60), Color("05030f"))

func _cosmos_g(ci: CanvasItem, a: float) -> void:
	var ct := fmod(t * 0.25, 1.0)
	var cp := Vector2(-200 + ct * 1700, 60 + ct * 180)
	ci.draw_line(cp, cp - Vector2(160, 40), Color(0.6, 0.8, 1.0, 0.35 * a), 6)
	_dot(ci, cp, 16, Color(0.8, 0.9, 1.0, 0.9 * a))
	for i in 20:
		var on := int(t * 3.0 + i) % 4 == 0
		if on:
			_dot(ci, Vector2(-100.0 + i * 80.0, 675), 12, Color(core_color, 0.9 * a))
	if Game.leve():
		return
	for i in 30:
		var s: Array = stars[i * 8]
		_dot(ci, s[0], 5.0, Color(1, 1, 1, (0.35 + 0.35 * sin(t * 1.7 + s[2])) * a))

# ------------------------------------------------------------------ 7. Fábrica a Vapor
func _oficina_s() -> void:
	_grad(-200, 600, Color("24160e"), Color("5a3a1e"))
	for row in 14:
		var y := row * 44.0
		draw_line(Vector2(-200, y), Vector2(1480, y), Color(0, 0, 0, 0.15), 2)
		for col in 18:
			var x := col * 90.0 + (45.0 if row % 2 == 1 else 0.0)
			draw_line(Vector2(x, y), Vector2(x, y + 44), Color(0, 0, 0, 0.12), 2)
	for x in [330.0, 760.0, 1180.0]:
		draw_line(Vector2(x, -200), Vector2(x, 190), Color("2a1a10"), 3)
	_floor_base(Color("3a2e26"), Color("18120e"), Color(core_color, 0.85))
	for i in 15:
		var x2 := -100.0 + i * 100.0
		draw_line(Vector2(x2, FLOOR_Y + 5), Vector2(x2, 720), Color(0, 0, 0, 0.35), 3)
		for k in 3:
			draw_circle(Vector2(x2 + 12, FLOOR_Y + 22 + k * 32), 3, Color("8a6a4a"))
	for i in 34:
		var sx := -200.0 + i * 50.0
		draw_colored_polygon(PackedVector2Array([Vector2(sx, 700), Vector2(sx + 25, 700), Vector2(sx + 45, 720), Vector2(sx + 20, 720)]), Color("e8b030") if i % 2 == 0 else Color("1a1410"))
	for x in [280.0, 1000.0]:
		draw_rect(Rect2(x - 50, FLOOR_Y + 40, 100, 26), Color("1a0e08"))
		draw_rect(Rect2(x - 44, FLOOR_Y + 44, 88, 18), Color(1.0, 0.5, 0.1, 0.8))

func _oficina_d() -> void:
	var vel := 0.0 if Game.leve() else 1.0
	_big_gear(Vector2(240, 230), 150.0, t * 0.25 * vel, Color("6a4a2a"))
	_big_gear(Vector2(445, 120), 90.0, -t * 0.42 * vel, Color("5a3e22"))
	_big_gear(Vector2(980, 260), 180.0, -t * 0.2 * vel, Color("6a4a2a"))
	_big_gear(Vector2(1190, 470), 80.0, t * 0.45 * vel, Color("5a3e22"))
	draw_rect(Rect2(-200, 430, 1680, 26), Color("8a5a2a"))
	draw_rect(Rect2(-200, 434, 1680, 6), Color(1, 0.8, 0.5, 0.25))
	for x in [160.0, 620.0, 1080.0]:
		draw_rect(Rect2(x - 14, 456, 28, 144), Color("7a4e24"))
		draw_rect(Rect2(x - 22, 422, 44, 42), Color("a06a32"))
		draw_circle(Vector2(x, 443), 9, Color("3a2a1a"))
		if not Game.leve():
			for k in 3:
				var ph := fmod(t * 0.7 + k * 0.33 + x * 0.001, 1.0)
				draw_circle(Vector2(x + sin(ph * 6.0 + x) * 14.0, 420.0 - ph * 160.0), 14.0 + ph * 34.0, Color(0.95, 0.92, 0.88, 0.3 * (1.0 - ph)))
	for x in [330.0, 760.0, 1180.0]:
		var lp := Vector2(x, 200)
		draw_colored_polygon(PackedVector2Array([lp + Vector2(-20, -12), lp + Vector2(20, -12), lp + Vector2(10, 4), lp + Vector2(-10, 4)]), Color("3a2a1a"))

func _oficina_g(ci: CanvasItem, a: float) -> void:
	for x in [330.0, 760.0, 1180.0]:
		var lp := Vector2(x, 200)
		var fl := 0.85 + 0.15 * sin(t * 13.0 + x)
		ci.draw_colored_polygon(PackedVector2Array([lp + Vector2(-12, 4), lp + Vector2(12, 4), lp + Vector2(120, FLOOR_Y - 200), lp + Vector2(-120, FLOOR_Y - 200)]), Color(1.0, 0.7, 0.3, 0.06 * fl * a))
		_dot(ci, lp + Vector2(0, 8), 30, Color(1.0, 0.75, 0.4, 0.8 * fl * a))
	for x in [280.0, 1000.0]:
		_dot(ci, Vector2(x, FLOOR_Y + 53), 70, Color(1.0, 0.4, 0.1, (0.3 + 0.1 * sin(t * 4 + x)) * a))

func _big_gear(p: Vector2, r: float, rot: float, cor: Color) -> void:
	var pts := PackedVector2Array()
	var teeth := int(r / 9.0)
	for i in teeth * 2:
		var a := rot + i * PI / teeth
		var rr := r if i % 2 == 0 else r * 0.86
		pts.append(p + Vector2(cos(a - 0.08), sin(a - 0.08)) * rr)
		pts.append(p + Vector2(cos(a + 0.08), sin(a + 0.08)) * rr)
	draw_colored_polygon(pts, cor)
	draw_circle(p, r * 0.7, cor.darkened(0.2))
	for k in 5:
		var a2 := rot + k * TAU / 5.0
		draw_line(p, p + Vector2(cos(a2), sin(a2)) * r * 0.7, cor, r * 0.12)
	draw_circle(p, r * 0.22, cor.lightened(0.15))
	draw_circle(p, r * 0.09, Color("1a1008"))
	draw_arc(p, r * 0.93, rot, rot + 1.2, 16, Color(1, 0.85, 0.5, 0.18), 4)
