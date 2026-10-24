extends Node2D
## Efeitos visuais: faíscas, anéis, fumaça, textos e o desenho de todos os ataques soltos (entidades).

const FLOOR_Y := 600.0
var fight: Node
var sparks: Array = []   # [pos, vel, vida, cor, tamanho]
var rings: Array = []    # [pos, raio, vida, cor, crescimento]
var texts: Array = []    # [texto, pos, vida, cor, tamanho]
var puffs: Array = []    # [pos, vel, raio, vida, vida_max, cor]
var bits: Array = []     # pedrinhas: [pos, vel, vida, cor, tamanho, giro]
var flames: Array = []   # [pos, vel, vida, vida_max, cor, tamanho]
var portals: Array = []  # [pos, vida, cor]
var ghosts: Array = []   # rastro do dash: [pos, facing, id, vida, cor]
var t := 0.0

func burst(p: Vector2, cor: Color, n := 12, forca := 1.0) -> void:
	for i in n:
		var a := randf() * TAU
		var v := Vector2(cos(a), sin(a)) * randf_range(200, 650) * forca
		sparks.append([p, v, randf_range(0.18, 0.4), cor.lightened(randf() * 0.5), randf_range(2.0, 5.0) * forca])
	rings.append([p, 10.0, 0.25, cor, 900.0 * forca])

func ring(p: Vector2, cor: Color, forca := 1.0) -> void:
	rings.append([p, 20.0, 0.35, cor, 1100.0 * forca])
	rings.append([p, 10.0, 0.3, cor.lightened(0.5), 700.0 * forca])

func pop(s: String, p: Vector2, cor: Color, size := 34) -> void:
	texts.append([s, p, 0.9, cor, size])

func puff(p: Vector2, cor: Color, n := 6) -> void:
	for i in n:
		var a := randf() * TAU
		puffs.append([p + Vector2(randf_range(-10, 10), randf_range(-6, 6)), Vector2(cos(a) * randf_range(20, 90), -randf_range(10, 60)),
			randf_range(8, 16), 0.6, 0.6, cor])

func debris(p: Vector2, cor: Color) -> void:
	for i in 7:
		bits.append([p + Vector2(randf_range(-20, 20), -5), Vector2(randf_range(-260, 260), -randf_range(250, 600)), 0.9, cor.darkened(randf() * 0.3), randf_range(5, 11), randf() * TAU])

func flame_trail(p: Vector2, cor: Color) -> void:
	for i in 3:
		flames.append([p + Vector2(randf_range(-25, 25), randf_range(-40, 40)), Vector2(randf_range(-30, 30), -randf_range(60, 160)), 0.45, 0.45, cor, randf_range(10, 20)])

func portal(p: Vector2, cor: Color) -> void:
	portals.append([p, 0.45, cor])

func afterimage(f: Node2D) -> void:
	ghosts.append([f.position + f.rig.position, f.facing, f.data.id, 0.25, f.data.cor])

func _process(delta: float) -> void:
	t += delta
	var dt := delta
	for s in sparks:
		s[0] += s[1] * dt
		s[1] *= 0.9
		s[2] -= dt
	sparks = sparks.filter(func(s): return s[2] > 0.0)
	for r in rings:
		r[1] += r[4] * dt
		r[2] -= dt
	rings = rings.filter(func(r): return r[2] > 0.0)
	for x in texts:
		x[1].y -= 50 * dt
		x[2] -= dt
	texts = texts.filter(func(x): return x[2] > 0.0)
	for p in puffs:
		p[0] += p[1] * dt
		p[1] *= 0.95
		p[2] += 30 * dt
		p[3] -= dt
	puffs = puffs.filter(func(p): return p[3] > 0.0)
	for b in bits:
		b[1].y += 1600 * dt
		b[0] += b[1] * dt
		b[2] -= dt
		b[5] += dt * 8.0
		if b[0].y > FLOOR_Y + 8:
			b[0].y = FLOOR_Y + 8
			b[1] *= Vector2(0.5, -0.3)
	bits = bits.filter(func(b): return b[2] > 0.0)
	for f in flames:
		f[0] += f[1] * dt
		f[2] -= dt
	flames = flames.filter(func(f): return f[2] > 0.0)
	for p in portals:
		p[1] -= dt
	portals = portals.filter(func(p): return p[1] > 0.0)
	for g in ghosts:
		g[3] -= dt
	ghosts = ghosts.filter(func(g): return g[3] > 0.0)
	queue_redraw()

# ===================================================================== desenho
func _draw() -> void:
	for g in ghosts:
		_draw_ghost(g)
	if fight:
		for e in fight.entities:
			_draw_entity(e)
		for f in fight.fighters:
			_draw_fighter_overlay(f)
	for p in portals:
		var k: float = 1.0 - p[1] / 0.45
		for i in 3:
			var rr := 30.0 + i * 18.0 + 50.0 * sin(k * PI)
			draw_set_transform(p[0], t * (3.0 + i), Vector2(1.0, 1.6))
			draw_arc(Vector2.ZERO, rr * 0.6, 0, TAU * 0.8, 24, Color(p[2], (1.0 - k) * 0.8), 4 - i)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	for f in flames:
		var a: float = f[2] / f[3]
		var c: Color = f[4]
		draw_circle(f[0], f[5] * a, Color(c, 0.5 * a))
		draw_circle(f[0], f[5] * a * 0.55, Color(c.lightened(0.5), 0.7 * a))
	for p in puffs:
		var a2: float = p[3] / p[4]
		draw_circle(p[0], p[2], Color(p[5], p[5].a * a2))
	for b in bits:
		var pts := PackedVector2Array()
		for i in 5:
			var ang: float = b[5] + i * TAU / 5.0
			pts.append(b[0] + Vector2(cos(ang), sin(ang)) * b[4] * (0.7 + 0.3 * ((i * 7) % 3) / 2.0))
		draw_colored_polygon(pts, b[3])
	for r in rings:
		draw_arc(r[0], r[1], 0, TAU, 32, Color(r[3], clampf(r[2] * 3.0, 0.0, 1.0)), 4)
	for s in sparks:
		var tail: Vector2 = s[1] * 0.03
		draw_line(s[0], s[0] - tail, Color(s[3], min(1.0, s[2] * 4.0)), s[4])
	for x in texts:
		var a3: float = clampf(x[2] * 2.0, 0.0, 1.0)
		Game.text(self, x[0], x[1] - Vector2(250, 0), x[4], Color(x[3], a3), HORIZONTAL_ALIGNMENT_CENTER, 500, true, 8, Color(0, 0, 0, 0.8 * a3))

func _draw_ghost(g: Array) -> void:
	var tx: Texture2D = Game.rig_tex[g[2]].body
	var rd: Dictionary = Game.rig_data[g[2]]
	var s: float = 185.0 / rd.H
	var sz := Vector2(rd.W, rd.H) * s
	draw_set_transform(g[0], 0.0, Vector2(g[1], 1.0))
	draw_texture_rect(tx, Rect2(Vector2(-sz.x / 2.0, -sz.y), sz), false, Color(g[4].lightened(0.3), g[3] * 2.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_fighter_overlay(f: Node2D) -> void:
	# rastro do punho
	var tr: Array = f.fist_trail
	if tr.size() >= 2:
		for i in range(1, tr.size()):
			var k := float(i) / tr.size()
			draw_line(tr[i - 1], tr[i], Color(f.data.cor.lightened(0.4), 0.7 * k), 3.0 + 12.0 * k)
			draw_line(tr[i - 1], tr[i], Color(1, 1, 1, 0.6 * k), 1.0 + 4.0 * k)
	var c: Vector2 = f.position + Vector2(0, -85)
	# congelado: cristais em volta
	if f.ice > 0 and f.state != "ko":
		var a := clampf(f.ice / 12.0, 0.0, 1.0)
		for i in 7:
			var ang := i * TAU / 7.0 + 0.3
			var p := c + Vector2(cos(ang) * 62, sin(ang) * 78)
			var tip := c + Vector2(cos(ang) * 105, sin(ang) * 125)
			var side := Vector2(-sin(ang), cos(ang)) * 16
			draw_colored_polygon(PackedVector2Array([p + side, tip, p - side, p.lerp(c, 0.3)]), Color(0.75, 0.93, 1.0, 0.55 * a))
			draw_line(p, tip, Color(1, 1, 1, 0.8 * a), 2)
		draw_circle(c, 70, Color(0.6, 0.85, 1.0, 0.18 * a))
	# veneno: bolhas
	if f.poison_t > 0:
		for i in 5:
			var ph := fmod(t * 1.3 + i * 0.37, 1.0)
			var p2 := c + Vector2(sin(i * 2.3 + t * 3.0) * 45, 60 - ph * 150)
			draw_arc(p2, 5 + i % 3 * 2, 0, TAU, 10, Color(0.6, 1.0, 0.3, 0.7 * (1.0 - ph)), 2)

func _glow(p: Vector2, r: float, cor: Color, a := 1.0) -> void:
	draw_circle(p, r * 1.8, Color(cor, 0.12 * a))
	draw_circle(p, r * 1.35, Color(cor, 0.25 * a))
	draw_circle(p, r, Color(cor.lightened(0.25), 0.8 * a))
	draw_circle(p, r * 0.55, Color(1, 1, 1, 0.9 * a))

## progresso 0..1 da fase ativa e transparência de saída
func _phase(e: Dictionary) -> Array:
	var act: int = e.t - e.delay
	var k := clampf(float(act) / maxf(1.0, e.life), 0.0, 1.0)
	var fade := clampf(float(e.delay + e.life - e.t) / 8.0, 0.0, 1.0)
	return [act, k, fade]

func _draw_entity(e: Dictionary) -> void:
	var cor: Color = e.cor
	var warn: bool = e.t <= e.delay
	var ph := _phase(e)
	var act: int = ph[0]
	var fade: float = ph[2]
	var p: Vector2 = e.pos
	var d: int = e.dir
	match e.kind:
		"orb":
			for k in 6:
				var tp: Vector2 = p - e.vel.normalized() * k * 14.0
				draw_circle(tp, 20.0 - k * 2.6, Color(cor, 0.35 - k * 0.05))
			draw_circle(p, 26.0 + 3 * sin(e.t * 0.5), Color(cor, 0.4))
			draw_circle(p, 17.0, cor.lightened(0.3))
			draw_circle(p, 9.0, Color(1, 1, 1, 0.95))
			for k in 3:
				var a: float = e.t * 0.2 + k * TAU / 3.0
				draw_arc(p, 23.0, a, a + 1.2, 10, Color(cor.lightened(0.5), 0.8), 2.5)
		"beam":
			var k2: float = clampf(act / 6.0, 0.0, 1.0)
			var x0: float = p.x
			var x1: float = x0 + d * 1400.0 * k2
			var th := 70.0 + 10.0 * sin(e.t * 1.3)
			var r := Rect2(minf(x0, x1), p.y - th, absf(x1 - x0), th * 2)
			draw_rect(r, Color(cor, 0.3 * fade))
			draw_rect(r.grow_individual(0, -th * 0.4, 0, -th * 0.4), Color(cor.lightened(0.3), 0.7 * fade))
			draw_rect(r.grow_individual(0, -th * 0.75, 0, -th * 0.75), Color(1, 1, 1, 0.95 * fade))
			for i in 8:
				var lx := fmod(e.t * 40.0 + i * 180.0, 1400.0) * k2
				draw_line(Vector2(x0 + d * lx, p.y - th * 0.9 + i * 22.0), Vector2(x0 + d * (lx + 120.0), p.y - th * 0.9 + i * 22.0), Color(1, 1, 1, 0.4 * fade), 2)
			draw_circle(Vector2(x0, p.y), th * 0.8, Color(cor.lightened(0.4), 0.7 * fade))
			draw_circle(Vector2(x0, p.y), th * 0.45, Color(1, 1, 1, 0.9 * fade))
		"firepillar":
			if warn:
				_floor_warn(p, 60.0, cor, e)
			else:
				_draw_column(p, e.size.x, e.size.y * minf(1.0, act / 4.0), Color("ff5a1f"), Color("ffd23a"), fade, e.seed)
		"shadowslash":
			if warn:
				var k3 := 1.0 - float(e.delay - e.t) / maxf(1.0, e.delay)
				draw_arc(p, 120.0 * (1.0 - k3) + 20.0, 0, TAU, 24, Color(cor, 0.35 * k3), 3)
			else:
				var ang: float = e.seed + d * 0.5
				var dirv := Vector2(cos(ang), sin(ang))
				var lk := clampf(act / 3.0, 0.0, 1.0)
				var a2 := p - dirv * 150.0
				var b2 := a2 + dirv * 300.0 * lk
				draw_line(a2, b2, Color(0.1, 0.0, 0.15, 0.9 * fade), 22)
				draw_line(a2, b2, Color(cor.lightened(0.3), fade), 8)
				draw_line(a2, b2, Color(1, 1, 1, fade), 2)
				draw_arc(p, 90, ang - 1.0, ang + 1.0, 16, Color(cor, 0.6 * fade), 6)
		"vine":
			if warn:
				_cracks(p, cor, e)
			else:
				_draw_spike(p, e.size.x * 0.6, e.size.y * minf(1.0, act / 3.0), Color("6b4a2a"), Color("6bd13b"), fade, e.seed)
		"bigvine":
			if warn:
				_floor_warn(p, 95.0, cor, e)
				_cracks(p, cor, e)
			else:
				var hh: float = e.size.y * minf(1.0, act / 6.0)
				_draw_spike(p + Vector2(-50, 0), 70.0, hh * 0.7, Color("5a3d22"), Color("6bd13b"), fade, e.seed)
				_draw_spike(p + Vector2(50, 0), 70.0, hh * 0.75, Color("5a3d22"), Color("6bd13b"), fade, e.seed + 2.0)
				_draw_spike(p, 120.0, hh, Color("6b4a2a"), Color("8fe05a"), fade, e.seed + 4.0)
				for i in 8:
					var ly: float = p.y - hh * (0.2 + 0.1 * i)
					var lx: float = p.x + sin(e.t * 0.2 + i) * 50.0
					_leaf(Vector2(lx, ly), 14.0, e.t * 0.1 + i, Color("8fe05a", fade))
		"tornado", "cyclone":
			var big: bool = e.kind == "cyclone"
			var hgt: float = e.size.y
			var layers := 14 if big else 9
			var wbase: float = e.size.x
			for i in layers:
				var k4 := float(i) / (layers - 1)
				var y: float = p.y - k4 * hgt
				var w: float = wbase * (0.25 + 0.75 * k4)
				var off := sin(e.t * 0.25 + i * 0.7) * 14.0 * k4
				draw_set_transform(Vector2(p.x + off, y), 0.0, Vector2(1.0, 0.28))
				draw_arc(Vector2.ZERO, w * 0.5, e.t * 0.3 + i, e.t * 0.3 + i + PI * 1.4, 18, Color(cor.lightened(0.4), 0.55 * fade), 6 if big else 4)
				draw_arc(Vector2.ZERO, w * 0.35, -e.t * 0.25 + i, -e.t * 0.25 + i + PI, 14, Color(1, 1, 1, 0.35 * fade), 3)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for i in (10 if big else 5):
				var a3: float = e.t * 0.15 + i * 1.3
				var rr: float = wbase * 0.45
				var lp := Vector2(p.x + cos(a3) * rr, p.y - fmod(i * 47.0 + e.t * 3.0, hgt))
				_leaf(lp, 7.0, a3, Color(0.75, 0.9, 1.0, 0.8 * fade))
		"wave":
			_draw_wave(p, d, e.size.x, e.size.y, cor, fade, e.t)
		"tsunami":
			_draw_wave(p, d, e.size.x * 1.4, e.size.y, cor, fade, e.t)
			draw_rect(Rect2(minf(p.x, p.x - d * 900.0), FLOOR_Y - 40, 900, 40), Color(cor.darkened(0.3), 0.5 * fade))
		"ice":
			var tip := p + Vector2(d * 46, 0)
			var back := p - Vector2(d * 46, 0)
			draw_colored_polygon(PackedVector2Array([tip, p + Vector2(-d * 6, -16), back, p + Vector2(-d * 6, 16)]), Color(0.75, 0.95, 1.0, 0.9))
			draw_line(back, tip, Color(1, 1, 1, 0.95), 3)
			for k in 4:
				var sp := back - Vector2(d * (12 + k * 16), sin(e.t * 0.7 + k) * 10)
				draw_circle(sp, 3.0 - k * 0.5, Color(0.85, 0.97, 1.0, 0.8 - k * 0.18))
		"icespike":
			if warn:
				_floor_warn(p, 55.0, Color(0.7, 0.9, 1.0), e)
			else:
				var hh2: float = e.size.y * minf(1.0, act / 3.0)
				_crystal(p + Vector2(-28, 0), 34.0, hh2 * 0.6, fade, -0.25)
				_crystal(p + Vector2(26, 0), 30.0, hh2 * 0.7, fade, 0.2)
				_crystal(p, 44.0, hh2, fade, 0.0)
		"shatter":
			var k5 := clampf(act / 6.0, 0.0, 1.0)
			draw_circle(p, 140 * k5, Color(1, 1, 1, 0.6 * (1.0 - k5)))
			for i in 12:
				var ang2 := i * TAU / 12.0
				var a4 := p + Vector2(cos(ang2), sin(ang2)) * 40.0 * k5
				var b4 := p + Vector2(cos(ang2), sin(ang2)) * 170.0 * k5
				draw_line(a4, b4, Color(0.8, 0.95, 1.0, 1.0 - k5), 8)
		"sunbeam":
			if warn:
				var k6 := 1.0 - float(e.delay - e.t) / maxf(1.0, e.delay)
				draw_line(Vector2(p.x, 0), Vector2(p.x, FLOOR_Y), Color(cor, 0.25 + 0.3 * k6), 2)
				_floor_warn(p, 50.0, cor, e)
			else:
				var w2: float = e.size.x * (0.5 + 0.5 * minf(1.0, act / 3.0))
				draw_rect(Rect2(p.x - w2, 0, w2 * 2, FLOOR_Y), Color(cor, 0.25 * fade))
				draw_rect(Rect2(p.x - w2 * 0.6, 0, w2 * 1.2, FLOOR_Y), Color(cor.lightened(0.4), 0.6 * fade))
				draw_rect(Rect2(p.x - w2 * 0.25, 0, w2 * 0.5, FLOOR_Y), Color(1, 1, 1, 0.9 * fade))
				draw_set_transform(Vector2(p.x, FLOOR_Y), 0, Vector2(1.0, 0.25))
				draw_circle(Vector2.ZERO, w2 * 1.4, Color(cor.lightened(0.5), 0.6 * fade))
				draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"quake":
			var k7 := clampf(act / 8.0, 0.0, 1.0)
			for s in [-1, 1]:
				for i in 6:
					var x = 640.0 + s * k7 * 650.0 * (0.4 + i * 0.12)
					draw_line(Vector2(640 + s * 40 * i, FLOOR_Y + 4), Vector2(x, FLOOR_Y + 4 + (i % 3) * 6), Color(cor, 0.8 * (1.0 - k7 * 0.5)), 4)
			draw_rect(Rect2(0, FLOOR_Y - 30 * (1.0 - k7), 1280, 30 * (1.0 - k7)), Color(cor, 0.3 * (1.0 - k7)))
		"rock":
			var rot: float = e.t * 0.15 + e.seed
			var pts := PackedVector2Array()
			for i in 7:
				var ang3 := rot + i * TAU / 7.0
				var rr2: float = 40.0 * (0.75 + 0.25 * sin(e.seed * 3.0 + i * 1.7))
				pts.append(p + Vector2(cos(ang3), sin(ang3)) * rr2)
			draw_line(p - e.vel.normalized() * 30, p - e.vel.normalized() * 90, Color(1, 0.8, 0.4, 0.3), 14)
			draw_colored_polygon(pts, Color("7a6a55"))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color("3a3028"), 3)
			draw_circle(p + Vector2(-8, -8), 8, Color(1, 1, 1, 0.15))
		"gear":
			_gear(p, 32.0, e.t * 0.5 * d, cor, Color("b07a3a"))
			draw_arc(p, 38, e.t * 0.5, e.t * 0.5 + 2.0, 12, Color(cor, 0.4), 3)
		"cannonball":
			for k in 4:
				draw_circle(p - Vector2(d * (18 + k * 16), 0), 14.0 - k * 2.5, Color(0.85, 0.85, 0.8, 0.4 - k * 0.08))
			draw_circle(p, 26, Color("3a2e26"))
			_gear(p, 18.0, e.t * 0.3, Color("b07a3a"), Color("6a4a2a"))
			draw_arc(p, 26, 0, TAU, 20, cor, 3)
		"meteor":
			var vd: Vector2 = e.vel.normalized()
			var tail := PackedVector2Array([p + Vector2(-vd.y, vd.x) * 30, p - vd * 150, p - Vector2(-vd.y, vd.x) * 30])
			if not warn:
				draw_colored_polygon(tail, Color(cor, 0.45))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-vd.y, vd.x) * 16, p - vd * 90, p - Vector2(-vd.y, vd.x) * 16]), Color(cor.lightened(0.5), 0.7))
				draw_circle(p, 34, Color(cor, 0.5))
				draw_circle(p, 26, Color("4a3a6a"))
				draw_circle(p + Vector2(-6, -6), 10, Color(cor.lightened(0.6), 0.8))
		"blast":
			var k8 := clampf(act / 8.0, 0.0, 1.0)
			draw_circle(p + Vector2(0, -50), 110 * k8, Color(cor, 0.45 * (1.0 - k8)))
			draw_circle(p + Vector2(0, -50), 70 * k8, Color(cor.lightened(0.5), 0.7 * (1.0 - k8)))
			draw_circle(p + Vector2(0, -50), 35 * k8, Color(1, 1, 1, 0.9 * (1.0 - k8)))
		"flask":
			draw_set_transform(p, e.t * 0.35 * d, Vector2.ONE)
			draw_rect(Rect2(-14, -12, 28, 26), Color("2a2a30"))
			draw_rect(Rect2(-12, -2, 24, 15), Color(cor, 0.95))
			draw_rect(Rect2(-6, -24, 12, 12), Color("8a7a6a"))
			draw_circle(Vector2(-6, 4), 3, Color(1, 1, 1, 0.7))
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"poison":
			var k9 := clampf(act / 10.0, 0.0, 1.0)
			for i in 9:
				var ox: float = sin(e.seed + i * 1.9) * 80.0
				var oy: float = -20.0 - absf(cos(e.seed + i * 1.3)) * 70.0
				var rr3: float = (34.0 + 12.0 * sin(e.t * 0.08 + i)) * k9
				draw_circle(p + Vector2(ox, oy), rr3, Color(cor.darkened(0.2), 0.22 * fade))
				draw_circle(p + Vector2(ox * 0.8, oy + 4), rr3 * 0.6, Color(Color("7a3ac8"), 0.12 * fade))
			for i in 4:
				var bph := fmod(e.t * 0.02 + i * 0.25, 1.0)
				draw_arc(p + Vector2(sin(i * 2.0) * 60, -bph * 110), 6, 0, TAU, 10, Color(cor.lightened(0.3), 0.7 * (1.0 - bph) * fade), 2)
		"circle":
			var rr4 := 120.0
			var ka := clampf(float(e.t) / maxf(1.0, e.delay), 0.0, 1.0)
			draw_set_transform(Vector2(p.x, FLOOR_Y + 4), 0, Vector2(1.0, 0.3))
			draw_arc(Vector2.ZERO, rr4 * ka, 0, TAU, 48, Color(cor, 0.9), 4)
			draw_arc(Vector2.ZERO, rr4 * 0.8 * ka, 0, TAU, 40, Color("b44dff", 0.8), 3)
			var tri := PackedVector2Array()
			for i in 4:
				var ang4: float = e.t * 0.05 + i * TAU / 3.0
				tri.append(Vector2(cos(ang4), sin(ang4)) * rr4 * 0.78 * ka)
			draw_polyline(tri, Color(cor, 0.9), 3)
			var tri2 := PackedVector2Array()
			for i in 4:
				var ang5: float = -e.t * 0.05 + PI + i * TAU / 3.0
				tri2.append(Vector2(cos(ang5), sin(ang5)) * rr4 * 0.78 * ka)
			draw_polyline(tri2, Color("b44dff", 0.9), 3)
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			if not warn:
				_draw_column(p, e.size.x, e.size.y * minf(1.0, act / 5.0), Color("7a3ac8"), cor, fade, e.seed)
		"burst":
			var kb := clampf(act / 6.0, 0.0, 1.0)
			draw_arc(p, 150 * kb, 0, TAU, 40, Color(cor, 1.0 - kb), 10)

# ---------------------------------------------------------------- peças de desenho
func _floor_warn(p: Vector2, r: float, cor: Color, e: Dictionary) -> void:
	var k := 1.0 - float(e.delay - e.t) / maxf(1.0, e.delay)
	var pulse := 0.5 + 0.5 * sin(e.t * 0.6)
	draw_set_transform(Vector2(p.x, FLOOR_Y + 3), 0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, r * (0.6 + 0.4 * k), Color(cor, 0.25 + 0.25 * pulse))
	draw_arc(Vector2.ZERO, r * (0.6 + 0.4 * k), 0, TAU, 32, Color(cor.lightened(0.4), 0.8), 3)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _cracks(p: Vector2, cor: Color, e: Dictionary) -> void:
	for i in 5:
		var a := -PI + (i + 0.5) * PI / 5.0
		var l := 30.0 + 10.0 * sin(e.seed + i)
		draw_line(Vector2(p.x, FLOOR_Y + 2), Vector2(p.x + cos(a) * l * 1.6, FLOOR_Y + 2 - sin(a) * l * 0.25), Color(cor, 0.8), 3)

func _draw_column(p: Vector2, w: float, h: float, c1: Color, c2: Color, fade: float, sd: float) -> void:
	if h <= 1.0: return
	var steps := 10
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in steps + 1:
		var k := float(i) / steps
		var y := p.y - h * k
		var wob := sin(sd + k * 9.0 + t * 14.0) * 10.0
		var ww := w * 0.5 * (1.0 - 0.35 * k)
		left.append(Vector2(p.x - ww + wob, y))
		right.append(Vector2(p.x + ww + wob, y))
	right.reverse()
	draw_colored_polygon(left + right, Color(c1, 0.75 * fade))
	var inner := PackedVector2Array()
	var inner_r := PackedVector2Array()
	for i in steps + 1:
		var k := float(i) / steps
		var y := p.y - h * k * 0.95
		var wob := sin(sd + k * 9.0 + t * 14.0) * 10.0
		var ww := w * 0.25 * (1.0 - 0.5 * k)
		inner.append(Vector2(p.x - ww + wob, y))
		inner_r.append(Vector2(p.x + ww + wob, y))
	inner_r.reverse()
	draw_colored_polygon(inner + inner_r, Color(c2, 0.85 * fade))
	draw_circle(Vector2(p.x, p.y - h), w * 0.35, Color(c2.lightened(0.4), 0.6 * fade))

func _draw_spike(p: Vector2, w: float, h: float, c1: Color, c2: Color, fade: float, sd: float) -> void:
	if h <= 1.0: return
	var bend := sin(sd) * 18.0
	var pts := PackedVector2Array([Vector2(p.x - w / 2.0, p.y), Vector2(p.x - w * 0.18 + bend * 0.5, p.y - h * 0.55),
		Vector2(p.x + bend, p.y - h), Vector2(p.x + w * 0.2 + bend * 0.5, p.y - h * 0.55), Vector2(p.x + w / 2.0, p.y)])
	draw_colored_polygon(pts, Color(c1, fade))
	draw_polyline(pts, Color(c1.darkened(0.5), fade), 3)
	draw_line(Vector2(p.x, p.y), Vector2(p.x + bend, p.y - h), Color(c2, 0.8 * fade), 4)
	_leaf(Vector2(p.x + bend * 0.5 + 10, p.y - h * 0.5), 12.0, sd, Color(c2, fade))
	_leaf(Vector2(p.x + bend * 0.3 - 12, p.y - h * 0.3), 10.0, sd + 2.0, Color(c2, fade))

func _leaf(p: Vector2, s: float, ang: float, cor: Color) -> void:
	var d := Vector2(cos(ang), sin(ang)) * s
	var n := Vector2(-d.y, d.x) * 0.45
	draw_colored_polygon(PackedVector2Array([p - d, p + n, p + d, p - n]), cor)

func _crystal(p: Vector2, w: float, h: float, fade: float, lean: float) -> void:
	if h <= 1.0: return
	var top := p + Vector2(lean * h, -h)
	var pts := PackedVector2Array([p + Vector2(-w / 2.0, 0), p + Vector2(-w * 0.4, -h * 0.75) + Vector2(lean * h * 0.75, 0), top,
		p + Vector2(w * 0.4, -h * 0.75) + Vector2(lean * h * 0.75, 0), p + Vector2(w / 2.0, 0)])
	draw_colored_polygon(pts, Color(0.65, 0.88, 1.0, 0.8 * fade))
	draw_colored_polygon(PackedVector2Array([p, top, p + Vector2(w * 0.4, -h * 0.75) + Vector2(lean * h * 0.75, 0), p + Vector2(w / 2.0, 0)]), Color(0.45, 0.7, 0.95, 0.6 * fade))
	draw_polyline(pts, Color(1, 1, 1, 0.9 * fade), 2)

func _draw_wave(p: Vector2, d: int, w: float, h: float, cor: Color, fade: float, tt: int) -> void:
	# contorno simples: base de trás -> crista (sobe para a frente) -> lábio da onda -> base da frente
	var back := p.x - d * w * 0.5
	var pts := PackedVector2Array([Vector2(back, p.y)])
	var n := 12
	for i in n + 1:
		var k := float(i) / n
		var x := back + d * w * 0.85 * k
		var y := p.y - h * (0.12 + 0.88 * pow(sin(k * PI * 0.5), 1.6)) - 4.0 * sin(tt * 0.3 + k * 8.0)
		pts.append(Vector2(x, y))
	var tip := Vector2(back + d * w * 1.0, p.y - h * 0.78)
	pts.append(tip)
	pts.append(Vector2(back + d * w * 0.93, p.y - h * 0.55))
	pts.append(Vector2(back + d * w * 0.9, p.y))
	draw_colored_polygon(pts, Color(cor.darkened(0.15), 0.8 * fade))
	# faixa clara interna
	var inner := PackedVector2Array([Vector2(back + d * w * 0.2, p.y)])
	for i in 9:
		var k2 := float(i) / 8.0
		inner.append(Vector2(back + d * w * (0.2 + 0.6 * k2), p.y - h * 0.6 * pow(sin(k2 * PI * 0.5), 1.5)))
	inner.append(Vector2(back + d * w * 0.8, p.y))
	draw_colored_polygon(inner, Color(cor.lightened(0.35), 0.35 * fade))
	# espuma no topo
	var foam := PackedVector2Array()
	for i in range(1, n + 2):
		foam.append(pts[i] + Vector2(0, 4))
	foam.append(tip + Vector2(0, 4))
	draw_polyline(foam, Color(1, 1, 1, 0.85 * fade), 5)
	draw_circle(tip, h * 0.09, Color(1, 1, 1, 0.7 * fade))
	for i in 6:
		var sx := tip.x + d * (6 + i * 8) + sin(tt * 0.5 + i) * 6
		var sy := tip.y + 10 + fmod(tt * 2.0 + i * 13.0, 40.0)
		draw_circle(Vector2(sx, sy), 3.5, Color(0.85, 0.95, 1.0, 0.8 * fade))

func _gear(p: Vector2, r: float, rot: float, c1: Color, c2: Color) -> void:
	var pts := PackedVector2Array()
	var teeth := 10
	for i in teeth * 2:
		var a := rot + i * PI / teeth
		var rr := r if i % 2 == 0 else r * 0.78
		pts.append(p + Vector2(cos(a - 0.12), sin(a - 0.12)) * rr)
		pts.append(p + Vector2(cos(a + 0.12), sin(a + 0.12)) * rr)
	draw_colored_polygon(pts, c2)
	draw_circle(p, r * 0.65, c1.darkened(0.2))
	draw_circle(p, r * 0.3, Color("2a2420"))
	draw_arc(p, r * 0.5, rot, rot + PI, 10, c1.lightened(0.4), 2)
