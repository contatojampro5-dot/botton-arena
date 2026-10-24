extends Node2D
## Efeitos visuais: faíscas, anéis, fumaça, textos e o desenho de todos os poderes (entidades).
## Duas camadas: a normal (formas sólidas) e a de brilho com luz somada (camada "add").

const FLOOR_Y := 600.0
const DrawProxy := preload("res://scripts/draw_proxy.gd")
var fight: Node
var add: Node2D
var sparks: Array = []   # [pos, vel, vida, cor, tamanho]
var rings: Array = []    # [pos, raio, vida, cor, crescimento]
var texts: Array = []    # [texto, pos, vida, cor, tamanho]
var puffs: Array = []    # [pos, vel, raio, vida, vida_max, cor]
var bits: Array = []     # pedrinhas: [pos, vel, vida, cor, tamanho, giro]
var flames: Array = []   # [pos, vel, vida, vida_max, cor, tamanho]
var portals: Array = []  # [pos, vida, cor]
var ghosts: Array = []   # rastro do dash: [pos, facing, id, vida, cor]
var charges: Array = []  # brilho de carga do poder: [lutador, vida]
var t := 0.0

func _ready() -> void:
	add = DrawProxy.new()
	add.alvo = self
	add.metodo = "_draw_add"
	add.material = DrawProxy.aditivo()
	add_child(add)

func _n(k: int) -> int:
	return maxi(1, k / 2) if Game.leve() else k

func burst(p: Vector2, cor: Color, n := 12, forca := 1.0) -> void:
	for i in _n(n):
		var a := randf() * TAU
		var v := Vector2(cos(a), sin(a)) * randf_range(200, 650) * forca
		sparks.append([p, v, randf_range(0.18, 0.4), cor.lightened(randf() * 0.5), randf_range(2.0, 5.0) * forca])
	rings.append([p, 10.0, 0.25, cor, 900.0 * forca])

func ring(p: Vector2, cor: Color, forca := 1.0) -> void:
	rings.append([p, 20.0, 0.35, cor, 1100.0 * forca])
	rings.append([p, 10.0, 0.3, cor.lightened(0.5), 700.0 * forca])

func pop(s: String, p: Vector2, cor: Color, size := 34) -> void:
	# não deixa o texto sair pela borda da tela (ex.: "EXPLOSÃO DE NÚCLEO!" encostado na parede)
	var meia := Game.text_width(s, size, "logo") * 0.5 * 1.15 + 12.0
	p.x = clampf(p.x, meia, 1280.0 - meia) if meia < 640.0 else 640.0
	p.y = maxf(p.y, 150.0)
	texts.append([s, p, 0.95, cor, size])

func puff(p: Vector2, cor: Color, n := 6) -> void:
	for i in _n(n):
		var a := randf() * TAU
		puffs.append([p + Vector2(randf_range(-10, 10), randf_range(-6, 6)), Vector2(cos(a) * randf_range(20, 90), -randf_range(10, 60)),
			randf_range(8, 16), 0.6, 0.6, cor])

func debris(p: Vector2, cor: Color) -> void:
	for i in _n(7):
		bits.append([p + Vector2(randf_range(-20, 20), -5), Vector2(randf_range(-260, 260), -randf_range(250, 600)), 0.9, cor.darkened(randf() * 0.3), randf_range(5, 11), randf() * TAU])

func flame_trail(p: Vector2, cor: Color) -> void:
	for i in _n(3):
		flames.append([p + Vector2(randf_range(-25, 25), randf_range(-40, 40)), Vector2(randf_range(-30, 30), -randf_range(60, 160)), 0.45, 0.45, cor, randf_range(10, 20)])

func portal(p: Vector2, cor: Color) -> void:
	portals.append([p, 0.45, cor])

func afterimage(f: Node2D) -> void:
	ghosts.append([f.position + f.rig.position, f.facing, f.data.id, 0.25, f.data.cor])

func charge(f: Node2D) -> void:
	charges.append([f, 0.22])

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
	for c in charges:
		c[1] -= dt
	charges = charges.filter(func(c): return c[1] > 0.0 and is_instance_valid(c[0]))
	queue_redraw()

# ===================================================================== utilidades de desenho
func _glow(ci: CanvasItem, p: Vector2, r: float, cor: Color) -> void:
	ci.draw_texture_rect(Game.dot_tex, Rect2(p - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), false, cor)

func _glow_ellipse(ci: CanvasItem, p: Vector2, rx: float, ry: float, cor: Color) -> void:
	ci.draw_texture_rect(Game.dot_tex, Rect2(p - Vector2(rx, ry), Vector2(rx * 2.0, ry * 2.0)), false, cor)

func _trail(ci: CanvasItem, e: Dictionary, n: int, step: float, r0: float, cor: Color) -> void:
	var v: Vector2 = e.vel
	if v.length() < 1.0: return
	var d := v.normalized()
	for k in n:
		var a := 1.0 - float(k) / n
		_glow(ci, e.pos - d * k * step, r0 * (0.4 + 0.6 * a), Color(cor, 0.55 * a))

## progresso da fase ativa e transparência de saída
func _phase(e: Dictionary) -> Array:
	var act: int = e.t - e.delay
	var k := clampf(float(act) / maxf(1.0, e.life), 0.0, 1.0)
	var fade := clampf(float(e.delay + e.life - e.t) / 8.0, 0.0, 1.0)
	return [act, k, fade]

# ===================================================================== camada normal
func _draw() -> void:
	for g in ghosts:
		_draw_ghost(g)
	if fight:
		for e in fight.entities:
			_ent(self, e)
		for f in fight.fighters:
			_draw_fighter_overlay(f)
	for p in puffs:
		var a2: float = p[3] / p[4]
		draw_circle(p[0], p[2], Color(p[5], p[5].a * a2))
	for b in bits:
		var pts := PackedVector2Array()
		for i in 5:
			var ang: float = b[5] + i * TAU / 5.0
			pts.append(b[0] + Vector2(cos(ang), sin(ang)) * b[4] * (0.7 + 0.3 * ((i * 7) % 3) / 2.0))
		draw_colored_polygon(pts, b[3])
	for x in texts:
		var a3: float = clampf(x[2] * 2.0, 0.0, 1.0)
		var esc := 1.0 + 0.25 * clampf((x[2] - 0.75) * 5.0, 0.0, 1.0)
		Game.text_scaled(self, x[0], x[1], x[4], esc, Color(x[3], a3), "logo", 8, Color(0.05, 0.02, 0.1, 0.85 * a3))

# ===================================================================== camada de brilho (luz somada)
func _draw_add(ci: CanvasItem) -> void:
	if fight:
		for e in fight.entities:
			_ent_glow(ci, e)
		for f in fight.fighters:
			_fighter_glow(ci, f)
	for c in charges:
		var f: Node2D = c[0]
		var k: float = c[1] / 0.22
		var hp: Vector2 = f.fist_pos()
		_glow(ci, hp, 50.0 * (1.0 - k) + 10.0, Color(f.data.cor, 0.8 * k))
	for p in portals:
		var k2: float = 1.0 - p[1] / 0.45
		for i in 3:
			var rr := 30.0 + i * 18.0 + 50.0 * sin(k2 * PI)
			ci.draw_set_transform(p[0], t * (3.0 + i), Vector2(1.0, 1.6))
			ci.draw_arc(Vector2.ZERO, rr * 0.6, 0, TAU * 0.8, 24, Color(p[2], (1.0 - k2) * 0.8), 4 - i)
		ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		_glow(ci, p[0], 70, Color(p[2], 0.5 * (1.0 - k2)))
	for f in flames:
		var a: float = f[2] / f[3]
		_glow(ci, f[0], f[5] * 1.6 * a, Color(f[4], 0.6 * a))
		_glow(ci, f[0], f[5] * 0.7 * a, Color(f[4].lightened(0.5), 0.8 * a))
	for r in rings:
		ci.draw_arc(r[0], r[1], 0, TAU, 32, Color(r[3], clampf(r[2] * 3.0, 0.0, 1.0)), 4)
	for s in sparks:
		var tail: Vector2 = s[1] * 0.03
		var al: float = minf(1.0, s[2] * 4.0)
		ci.draw_line(s[0], s[0] - tail, Color(s[3], al), s[4])
		_glow(ci, s[0], s[4] * 3.0, Color(s[3], 0.4 * al))

func _draw_ghost(g: Array) -> void:
	var tx: Texture2D = Game.rig_tex[g[2]].body
	var rd: Dictionary = Game.rig_data[g[2]]
	var s: float = 185.0 / rd.H
	var sz := Vector2(rd.W, rd.H) * s
	draw_set_transform(g[0], 0.0, Vector2(g[1], 1.0))
	draw_texture_rect(tx, Rect2(Vector2(-sz.x / 2.0, -sz.y), sz), false, Color(g[4].lightened(0.3), g[3] * 2.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_fighter_overlay(f: Node2D) -> void:
	var c: Vector2 = f.position + Vector2(0, -85)
	if f.ice > 0 and f.state != "ko":
		var a := clampf(f.ice / 12.0, 0.0, 1.0)
		for i in 7:
			var ang := i * TAU / 7.0 + 0.3
			var p := c + Vector2(cos(ang) * 62, sin(ang) * 78)
			var tip := c + Vector2(cos(ang) * 105, sin(ang) * 125)
			var side := Vector2(-sin(ang), cos(ang)) * 16
			draw_colored_polygon(PackedVector2Array([p + side, tip, p - side, p.lerp(c, 0.3)]), Color(0.75, 0.93, 1.0, 0.55 * a))
			draw_line(p, tip, Color(1, 1, 1, 0.8 * a), 2)
	if f.poison_t > 0:
		for i in 5:
			var ph := fmod(t * 1.3 + i * 0.37, 1.0)
			var p2 := c + Vector2(sin(i * 2.3 + t * 3.0) * 45, 60 - ph * 150)
			draw_arc(p2, 5 + i % 3 * 2, 0, TAU, 10, Color(0.6, 1.0, 0.3, 0.7 * (1.0 - ph)), 2)
	if f.slow_t > 0:
		for i in 4:
			var ph2 := fmod(t * 0.9 + i * 0.25, 1.0)
			draw_arc(f.position + Vector2(0, -6), 30 + ph2 * 40, PI, TAU, 16, Color(0.6, 0.2, 0.9, 0.6 * (1.0 - ph2)), 3)

func _fighter_glow(ci: CanvasItem, f: Node2D) -> void:
	var tr: Array = f.fist_trail
	if tr.size() >= 2:
		for i in range(1, tr.size()):
			var k := float(i) / tr.size()
			ci.draw_line(tr[i - 1], tr[i], Color(f.data.cor.lightened(0.3), 0.6 * k), 4.0 + 14.0 * k)
			ci.draw_line(tr[i - 1], tr[i], Color(1, 1, 1, 0.5 * k), 1.0 + 4.0 * k)
		_glow(ci, tr[tr.size() - 1], 26, Color(f.data.cor, 0.5))
	if f.ice > 0 and f.state != "ko":
		_glow(ci, f.position + Vector2(0, -85), 110, Color(0.5, 0.8, 1.0, 0.25))
	if f.overload_t > 0 and f.state != "ko":
		_glow(ci, f.position + Vector2(0, -85), 140 + 10 * sin(t * 9.0), Color(f.data.cor, 0.22))

# ===================================================================== entidades: parte sólida
func _ent(ci: CanvasItem, e: Dictionary) -> void:
	var cor: Color = e.cor
	var warn: bool = e.t <= e.delay
	var ph := _phase(e)
	var act: int = ph[0]
	var fade: float = ph[2]
	var p: Vector2 = e.pos
	var d: int = e.dir
	match e.kind:
		"fireball":
			if warn: return
			var r := 22.0
			for k in 5:
				var a := t * 9.0 + k * TAU / 5.0
				var fp := p + Vector2(-d * (14.0 + 6.0 * sin(a)), 9.0 * cos(a))
				ci.draw_circle(fp, r * 0.55, Color(1.0, 0.4, 0.08, 0.8))
			ci.draw_circle(p, r, Color(1.0, 0.5, 0.1))
			ci.draw_circle(p + Vector2(d * 4, -3), r * 0.62, Color(1.0, 0.85, 0.3))
			ci.draw_circle(p + Vector2(d * 6, -5), r * 0.3, Color(1, 1, 0.85))
		"shadowball":
			if warn: return
			ci.draw_circle(p, 27, Color(0.12, 0.02, 0.2))
			for k in 6:
				var a2 := t * 5.0 + k * TAU / 6.0
				ci.draw_circle(p + Vector2(cos(a2), sin(a2)) * 22.0, 11.0, Color(0.25, 0.05, 0.4, 0.8))
			ci.draw_circle(p, 16, Color(0.05, 0.0, 0.08))
		"leaf":
			if warn: return
			var ang: float = e.t * 0.5 * d
			var dv := Vector2(cos(ang), sin(ang)) * 17.0
			var nv := Vector2(-dv.y, dv.x) * 0.45
			ci.draw_colored_polygon(PackedVector2Array([p - dv, p + nv, p + dv, p - nv]), Color("7ad63a"))
			ci.draw_line(p - dv, p + dv, Color("2e6a1a"), 2)
		"airblade":
			if warn: return
			var pts := PackedVector2Array()
			for k in 13:
				var a3 := -1.25 + k * 2.5 / 12.0
				pts.append(p + Vector2(cos(a3) * 30.0 * d, sin(a3) * 42.0))
			for k in 13:
				var a4 := 1.25 - k * 2.5 / 12.0
				pts.append(p + Vector2(cos(a4) * 18.0 * d - d * 6.0, sin(a4) * 34.0))
			ci.draw_colored_polygon(pts, Color(0.85, 0.95, 1.0, 0.85))
		"waterjet":
			if warn: return
			var bp := p - Vector2(d * 30, 0)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(d * 34, 0), bp + Vector2(0, -15), bp - Vector2(d * 40, -2), bp + Vector2(0, 15)]), Color(0.35, 0.7, 1.0, 0.9))
			ci.draw_circle(p + Vector2(d * 18, 0), 13, Color(0.8, 0.95, 1.0))
		"ice":
			if warn: return
			var tip := p + Vector2(d * 46, 0)
			var back := p - Vector2(d * 46, 0)
			ci.draw_colored_polygon(PackedVector2Array([tip, p + Vector2(-d * 6, -16), back, p + Vector2(-d * 6, 16)]), Color(0.75, 0.95, 1.0, 0.95))
			ci.draw_line(back, tip, Color(1, 1, 1, 0.95), 3)
		"sundisc":
			if warn: return
			ci.draw_circle(p, 26, Color(1.0, 0.82, 0.3))
			for k in 8:
				var a5: float = e.t * 0.4 + k * TAU / 8.0
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(cos(a5), sin(a5)) * 36.0, p + Vector2(cos(a5 + 0.25), sin(a5 + 0.25)) * 22.0,
					p + Vector2(cos(a5 - 0.25), sin(a5 - 0.25)) * 22.0]), Color(1.0, 0.9, 0.5))
			ci.draw_circle(p, 13, Color(1, 1, 0.9))
		"acid":
			if warn: return
			ci.draw_circle(p, 18, Color(0.45, 0.95, 0.2))
			ci.draw_circle(p + Vector2(d * 5, -4), 8, Color(0.85, 1.0, 0.6))
			for k in 3:
				ci.draw_circle(p - Vector2(d * (20 + k * 12), sin(e.t * 0.6 + k) * 6), 7 - k * 2, Color(0.5, 0.9, 0.2, 0.7))
		"miniorb", "orb", "bolt":
			if warn: return
			var rr := 16.0 if e.kind == "orb" else (10.0 if e.kind == "miniorb" else 8.0)
			ci.draw_circle(p, rr, cor.lightened(0.3))
			ci.draw_circle(p, rr * 0.5, Color(1, 1, 1, 0.95))
			if e.kind == "bolt":
				ci.draw_line(p - Vector2(d * 20, 0), p + Vector2(d * 6, 0), Color(1, 1, 1, 0.9), 4)
		"star":
			if warn: return
			var spts := PackedVector2Array()
			for k in 10:
				var a6: float = e.t * 0.3 + k * TAU / 10.0
				var rr2 := 26.0 if k % 2 == 0 else 11.0
				spts.append(p + Vector2(cos(a6), sin(a6)) * rr2)
			ci.draw_colored_polygon(spts, Color(1.0, 0.92, 0.55))
		"gear":
			_gear(ci, p, 32.0, e.t * 0.5 * d, cor, Color("b07a3a"))
		"cannonball":
			ci.draw_circle(p, 26, Color("3a2e26"))
			_gear(ci, p, 18.0, e.t * 0.3, Color("b07a3a"), Color("6a4a2a"))
			ci.draw_arc(p, 26, 0, TAU, 20, cor, 3)
		"rock", "boulder":
			if warn: return
			var rot: float = e.t * 0.15 + e.seed
			var pts2 := PackedVector2Array()
			var rad := 40.0
			for i in 8:
				var ang3 := rot + i * TAU / 8.0
				pts2.append(p + Vector2(cos(ang3), sin(ang3)) * rad * (0.78 + 0.22 * sin(e.seed * 3.0 + i * 1.7)))
			ci.draw_colored_polygon(pts2, Color("7a6a55"))
			ci.draw_polyline(pts2 + PackedVector2Array([pts2[0]]), Color("3a3028"), 3)
			ci.draw_circle(p + Vector2(-9, -9), 9, Color(1, 1, 1, 0.15))
			ci.draw_line(p + Vector2(-12, 8), p + Vector2(10, 14), Color("4a3e30"), 3)
		"flask":
			ci.draw_set_transform(p, e.t * 0.35 * d, Vector2.ONE)
			ci.draw_rect(Rect2(-14, -12, 28, 26), Color("2a2a30"))
			ci.draw_rect(Rect2(-12, -2, 24, 15), Color(cor, 0.95))
			ci.draw_rect(Rect2(-6, -24, 12, 12), Color("8a7a6a"))
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"seed":
			ci.draw_circle(p, 13, Color("6b4a2a"))
			ci.draw_circle(p + Vector2(-3, -4), 5, Color("9a7a4a"))
			ci.draw_line(p + Vector2(0, -12), p + Vector2(6, -22), Color("6bd13b"), 3)
		"bubble":
			if warn: return
			ci.draw_circle(p, 22, Color(0.5, 0.8, 1.0, 0.25))
			ci.draw_arc(p, 22, 0, TAU, 24, Color(0.85, 0.95, 1.0, 0.9), 2.5)
			ci.draw_arc(p, 15, -2.4, -1.4, 8, Color(1, 1, 1, 0.9), 3)
		"meteor":
			if warn: return
			ci.draw_circle(p, 28, Color("4a3a6a"))
			ci.draw_circle(p + Vector2(-8, -8), 10, Color(cor.lightened(0.5), 0.8))
		# ---------------- erupções
		"firepillar":
			if warn:
				_floor_warn(ci, p, 60.0, cor, e)
			else:
				_draw_column(ci, p, e.size.x, e.size.y * minf(1.0, act / 4.0), Color("ff5a1f"), Color("ffd23a"), fade, e.seed)
		"acidgeyser":
			if warn:
				_floor_warn(ci, p, 60.0, cor, e)
			else:
				_draw_column(ci, p, e.size.x, e.size.y * minf(1.0, act / 4.0), Color("4ab81a"), Color("c8ff6a"), fade, e.seed)
		"geyser":
			if warn:
				_floor_warn(ci, p, 60.0, Color(0.5, 0.8, 1.0), e)
				_bubbles_warn(ci, p, e)
			else:
				_draw_column(ci, p, e.size.x, e.size.y * minf(1.0, act / 4.0), Color("2a7ae0"), Color("bfe8ff"), fade, e.seed)
		"claw":
			if warn:
				_floor_warn(ci, p, 60.0, cor, e)
			else:
				var hh: float = e.size.y * minf(1.0, act / 3.0)
				for k in 3:
					var bx: float = p.x + (k - 1) * 34.0
					var tipo2 := Vector2(bx + (k - 1) * 22.0, p.y - hh * (0.8 + 0.2 * (k % 2)))
					ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 16, p.y), tipo2, Vector2(bx + 16, p.y)]), Color(0.12, 0.02, 0.2, fade))
					ci.draw_line(Vector2(bx, p.y), tipo2, Color(0.75, 0.35, 1.0, fade), 3)
		"vine":
			if warn:
				_cracks(ci, p, cor, e)
			else:
				_draw_spike(ci, p, e.size.x * 0.6, e.size.y * minf(1.0, act / 3.0), Color("6b4a2a"), Color("6bd13b"), fade, e.seed)
		"sprout":
			if warn:
				_cracks(ci, p, cor, e)
			else:
				_draw_sprout(ci, p, e.size.x, e.size.y * minf(1.0, act / 3.0), fade, e.seed)
		"bigvine":
			if warn:
				_floor_warn(ci, p, 95.0, cor, e)
				_cracks(ci, p, cor, e)
			else:
				var hh2: float = e.size.y * minf(1.0, act / 6.0)
				_draw_spike(ci, p + Vector2(-50, 0), 70.0, hh2 * 0.7, Color("5a3d22"), Color("6bd13b"), fade, e.seed)
				_draw_spike(ci, p + Vector2(50, 0), 70.0, hh2 * 0.75, Color("5a3d22"), Color("6bd13b"), fade, e.seed + 2.0)
				_draw_spike(ci, p, 120.0, hh2, Color("6b4a2a"), Color("8fe05a"), fade, e.seed + 4.0)
				for i in 8:
					_leaf(ci, Vector2(p.x + sin(e.t * 0.2 + i) * 50.0, p.y - hh2 * (0.2 + 0.1 * i)), 14.0, e.t * 0.1 + i, Color("8fe05a", fade))
		"thorns":
			var arm2: bool = e.t - e.delay >= e.get("arm", 10)
			for k in 7:
				var bx2: float = p.x - 56 + k * 18.0
				var hh3 := 30.0 + 26.0 * absf(sin(k * 1.7 + e.seed))
				var tp := Vector2(bx2 + sin(k + e.seed) * 6.0, p.y - hh3)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(bx2 - 8, p.y), tp, Vector2(bx2 + 8, p.y)]), Color("3e6a22") if arm2 else Color("5a7a3a"))
				ci.draw_line(Vector2(bx2, p.y), tp, Color("8fe05a"), 2)
		"icespike":
			if warn:
				_floor_warn(ci, p, 55.0, Color(0.7, 0.9, 1.0), e)
			else:
				var hh4: float = e.size.y * minf(1.0, act / 3.0)
				_crystal(ci, p + Vector2(-28, 0), 34.0, hh4 * 0.6, fade, -0.25)
				_crystal(ci, p + Vector2(26, 0), 30.0, hh4 * 0.7, fade, 0.2)
				_crystal(ci, p, 44.0, hh4, fade, 0.0)
		"pillar":
			if warn:
				_cracks(ci, p, cor, e)
			else:
				var hh5: float = e.size.y * minf(1.0, act / 3.0)
				_draw_pillar(ci, p, e.size.x * 0.5, hh5, fade, e.seed)
		"icecrack":
			var k7 := clampf(act / 6.0, 0.0, 1.0)
			_crystal(ci, p + Vector2(-40, 0), 40.0, 120.0 * k7, 1.0 - k7 * 0.5, -0.3)
			_crystal(ci, p + Vector2(40, 0), 40.0, 110.0 * k7, 1.0 - k7 * 0.5, 0.3)
			_crystal(ci, p, 50.0, 150.0 * k7, 1.0 - k7 * 0.5, 0.0)
		"sunbeam":
			if warn:
				var k6 := 1.0 - float(e.delay - e.t) / maxf(1.0, e.delay)
				ci.draw_line(Vector2(p.x, 0), Vector2(p.x, FLOOR_Y), Color(cor, 0.25 + 0.3 * k6), 2)
				_floor_warn(ci, p, 50.0, cor, e)
		"shadowslash":
			if warn:
				var k3 := 1.0 - float(e.delay - e.t) / maxf(1.0, e.delay)
				ci.draw_arc(p, 120.0 * (1.0 - k3) + 20.0, 0, TAU, 24, Color(cor, 0.35 * k3), 3)
			else:
				var ang4: float = e.seed + d * 0.5
				var dirv := Vector2(cos(ang4), sin(ang4))
				var lk := clampf(act / 3.0, 0.0, 1.0)
				var a7 := p - dirv * 150.0
				ci.draw_line(a7, a7 + dirv * 300.0 * lk, Color(0.1, 0.0, 0.15, 0.9 * fade), 22)
		"circle":
			var rr4 := 120.0
			var ka := clampf(float(e.t) / maxf(1.0, e.delay), 0.0, 1.0)
			ci.draw_set_transform(Vector2(p.x, FLOOR_Y + 4), 0, Vector2(1.0, 0.3))
			ci.draw_arc(Vector2.ZERO, rr4 * ka, 0, TAU, 48, Color(cor, 0.9), 4)
			ci.draw_arc(Vector2.ZERO, rr4 * 0.8 * ka, 0, TAU, 40, Color("b44dff", 0.8), 3)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			if not warn:
				_draw_column(ci, p, e.size.x, e.size.y * minf(1.0, act / 5.0), Color("7a3ac8"), cor, fade, e.seed)
		# ---------------- pelo chão
		"wave":
			_draw_wave(ci, p, d, e.size.x, e.size.y, cor, fade, e.t)
		"tsunami":
			_draw_wave(ci, p, d, e.size.x * 1.4, e.size.y, cor, fade, e.t)
			ci.draw_rect(Rect2(minf(p.x, p.x - d * 900.0), FLOOR_Y - 40, 900, 40), Color(cor.darkened(0.3), 0.5 * fade))
		"shock":
			var w3 := 34.0
			var hh6 := 40.0 + 8.0 * sin(e.t * 0.8)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - w3, p.y), Vector2(p.x - w3 * 0.3, p.y - hh6), Vector2(p.x + w3 * 0.4, p.y - hh6 * 0.7), Vector2(p.x + w3, p.y)]), Color("8a7a62", fade))
		"rings", "frost", "steam", "flash", "gust", "tornado", "cyclone", "beam", "lightray", "blast", "burst", "shatter", "quake":
			pass
		# ---------------- zonas e armadilhas
		"embers":
			var r5 := ent_rect(e)
			ci.draw_rect(Rect2(r5.position.x, p.y - 8, r5.size.x, 8), Color(0.25, 0.05, 0.02, 0.7 * fade))
		"darkpool":
			ci.draw_set_transform(Vector2(p.x, p.y - 4), 0, Vector2(1.0, 0.22))
			ci.draw_circle(Vector2.ZERO, e.size.x * 0.5, Color(0.08, 0.0, 0.14, 0.9 * fade))
			ci.draw_circle(Vector2.ZERO, e.size.x * 0.36, Color(0.18, 0.02, 0.3, 0.9 * fade))
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"poison":
			var k9 := clampf(act / 10.0, 0.0, 1.0)
			for i in 9:
				var ox: float = sin(e.seed + i * 1.9) * 80.0
				var oy: float = -20.0 - absf(cos(e.seed + i * 1.3)) * 70.0
				var rr3: float = (34.0 + 12.0 * sin(e.t * 0.08 + i)) * k9
				ci.draw_circle(p + Vector2(ox, oy), rr3, Color(cor.darkened(0.2), 0.2 * fade))
				ci.draw_circle(p + Vector2(ox * 0.8, oy + 4), rr3 * 0.6, Color(Color("7a3ac8"), 0.12 * fade))
		"mine":
			var armada: bool = e.t - e.delay >= e.get("arm", 15)
			var pisca := armada and int(e.t / 10) % 2 == 0
			# base, cúpula com pontas e a luz que pisca quando está armada
			Game.rounded(ci, Rect2(p.x - 34, p.y - 12, 68, 12), 5, Color("23232f"))
			for k in 5:
				var ang := PI + (k + 0.5) * PI / 5.0
				var dv := Vector2(cos(ang), sin(ang))
				ci.draw_line(Vector2(p.x, p.y - 12) + dv * 20.0, Vector2(p.x, p.y - 12) + dv * 30.0, Color("5a5a72"), 5)
			ci.draw_circle(Vector2(p.x, p.y - 12), 22, Color("3a3a4e"))
			ci.draw_arc(Vector2(p.x, p.y - 12), 22, PI, TAU, 16, Color("6a6a86"), 3)
			ci.draw_rect(Rect2(p.x - 30, p.y - 12, 60, 12), Color("2a2a38"))
			ci.draw_circle(Vector2(p.x, p.y - 24), 8, cor.lightened(0.3) if pisca else Color(cor, 0.4))
			ci.draw_circle(Vector2(p.x - 3, p.y - 27), 3, Color(1, 1, 1, 0.8 if pisca else 0.3))
		"icefloor":
			var r6 := ent_rect(e)
			Game.rounded(ci, Rect2(r6.position.x, p.y - 12, r6.size.x, 12), 6, Color(0.75, 0.92, 1.0, 0.8))
			ci.draw_line(Vector2(r6.position.x + 20, p.y - 8), Vector2(r6.end.x - 30, p.y - 4), Color(1, 1, 1, 0.9), 2)
		"rune":
			var rr5 = e.size.x * 0.5
			ci.draw_set_transform(Vector2(p.x, p.y - 2), 0, Vector2(1.0, 0.3))
			ci.draw_arc(Vector2.ZERO, rr5, 0, TAU, 40, Color(cor, 0.9), 4)
			var tri := PackedVector2Array()
			for i in 4:
				var ang5: float = e.t * 0.04 + i * TAU / 3.0
				tri.append(Vector2(cos(ang5), sin(ang5)) * rr5 * 0.8)
			ci.draw_polyline(tri, Color("b44dff", 0.9), 3)
			ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"turret":
			ci.draw_rect(Rect2(p.x - 26, p.y - 30, 52, 30), Color("6a4a2a"))
			ci.draw_rect(Rect2(p.x - 20, p.y - 34, 40, 6), Color("b07a3a"))
			ci.draw_circle(Vector2(p.x, p.y - 52), 20, Color("8a6a3a"))
			ci.draw_line(Vector2(p.x, p.y - 56), Vector2(p.x + d * 38, p.y - 58), Color("3a2a1a"), 10)
			_gear(ci, Vector2(p.x, p.y - 52), 12.0, e.t * 0.1, Color("3fe0b0"), Color("b07a3a"))
		"blackhole":
			ci.draw_circle(p, 34 + 3 * sin(e.t * 0.3), Color(0.0, 0.0, 0.0, fade))

# ===================================================================== entidades: parte brilhante
func _ent_glow(ci: CanvasItem, e: Dictionary) -> void:
	var cor: Color = e.cor
	var warn: bool = e.t <= e.delay
	var ph := _phase(e)
	var act: int = ph[0]
	var fade: float = ph[2]
	var p: Vector2 = e.pos
	var d: int = e.dir
	match e.kind:
		"orb":
			if warn: return
			_trail(ci, e, 7, 13.0, 22.0, cor)
			_glow(ci, p, 46, Color(cor, 0.7))
			_glow(ci, p, 20, Color(1, 1, 1, 0.8))
			for k in 3:
				var a: float = e.t * 0.2 + k * TAU / 3.0
				ci.draw_arc(p, 25.0, a, a + 1.2, 10, Color(cor.lightened(0.5), 0.8), 2.5)
		"miniorb", "bolt":
			if warn: return
			_trail(ci, e, 5, 10.0, 14.0, cor)
			_glow(ci, p, 28, Color(cor, 0.7))
		"fireball":
			if warn: return
			_trail(ci, e, 8, 12.0, 26.0, Color(1.0, 0.45, 0.1))
			_glow(ci, p, 58, Color(1.0, 0.45, 0.1, 0.65))
			_glow(ci, p, 24, Color(1.0, 0.9, 0.5, 0.7))
		"shadowball":
			if warn: return
			_trail(ci, e, 6, 12.0, 28.0, Color(0.6, 0.2, 1.0))
			_glow(ci, p, 60, Color(0.55, 0.15, 0.95, 0.6))
			_glow(ci, p + Vector2(-8, -8), 10, Color(0.9, 0.6, 1.0, 0.6))
		"leaf":
			if warn: return
			_glow(ci, p, 22, Color(0.5, 1.0, 0.3, 0.4))
		"airblade":
			if warn: return
			_trail(ci, e, 6, 14.0, 26.0, Color(0.6, 0.9, 1.0))
			_glow_ellipse(ci, p, 30, 50, Color(0.6, 0.9, 1.0, 0.45))
		"waterjet":
			if warn: return
			_trail(ci, e, 8, 12.0, 18.0, Color(0.3, 0.6, 1.0))
			_glow(ci, p, 34, Color(0.4, 0.75, 1.0, 0.5))
		"ice":
			if warn: return
			_trail(ci, e, 6, 14.0, 14.0, Color(0.6, 0.9, 1.0))
			_glow(ci, p, 36, Color(0.6, 0.9, 1.0, 0.5))
		"sundisc":
			if warn: return
			_trail(ci, e, 6, 12.0, 24.0, Color(1.0, 0.8, 0.3))
			_glow(ci, p, 60, Color(1.0, 0.8, 0.3, 0.6))
		"acid":
			if warn: return
			_trail(ci, e, 6, 12.0, 18.0, Color(0.5, 1.0, 0.2))
			_glow(ci, p, 38, Color(0.5, 1.0, 0.2, 0.55))
		"star":
			if warn: return
			_trail(ci, e, 9, 16.0, 26.0, Color(1.0, 0.85, 0.5))
			_glow(ci, p, 56, Color(1.0, 0.9, 0.55, 0.7))
		"gear":
			_glow(ci, p, 46, Color(cor, 0.3))
		"cannonball":
			_trail(ci, e, 5, 14.0, 16.0, Color(1.0, 0.7, 0.4))
		"meteor":
			if warn: return
			_trail(ci, e, 10, 16.0, 34.0, cor)
			_glow(ci, p, 70, Color(cor, 0.6))
		"bubble":
			if warn: return
			_glow(ci, p, 30, Color(0.5, 0.8, 1.0, 0.25))
		"seed":
			_glow(ci, p, 18, Color(0.5, 1.0, 0.3, 0.3))
		"boulder", "rock":
			if warn: return
			_trail(ci, e, 5, 16.0, 22.0, Color(1.0, 0.7, 0.4, 0.5))
		"firepillar", "acidgeyser", "geyser":
			if warn: return
			var hh: float = e.size.y * minf(1.0, act / 4.0)
			var c2 := Color(1.0, 0.5, 0.1) if e.kind == "firepillar" else (Color(0.5, 1.0, 0.2) if e.kind == "acidgeyser" else Color(0.4, 0.75, 1.0))
			_glow_ellipse(ci, p - Vector2(0, hh * 0.5), e.size.x * 0.9, hh * 0.65, Color(c2, 0.35 * fade))
			_glow_ellipse(ci, p, e.size.x * 1.2, 30, Color(c2, 0.5 * fade))
			_glow(ci, p - Vector2(0, hh), e.size.x * 0.8, Color(c2.lightened(0.3), 0.45 * fade))
			# fagulhas / gotas subindo da ponta
			var ng := 4 if Game.leve() else 8
			for i in ng:
				var kk := fmod(t * 1.6 + i * 0.137 + e.seed, 1.0)
				var gp := p - Vector2(sin(e.seed + i * 2.3) * e.size.x * 0.5 * kk, hh + 20.0 + 110.0 * kk)
				_glow(ci, gp, 14.0 * (1.0 - kk) + 4.0, Color(c2.lightened(0.4), 0.8 * (1.0 - kk) * fade))
		"claw":
			if warn: return
			_glow_ellipse(ci, p - Vector2(0, 80), 90, 140, Color(0.6, 0.2, 1.0, 0.35 * fade))
		"icespike", "icecrack":
			if warn: return
			_glow_ellipse(ci, p - Vector2(0, 80), 90, 120, Color(0.6, 0.9, 1.0, 0.3 * fade))
		"sprout", "vine", "bigvine":
			if warn: return
			_glow_ellipse(ci, p, e.size.x, 26, Color(0.5, 1.0, 0.3, 0.35 * fade))
		"pillar", "shock":
			_glow_ellipse(ci, p, 90, 20, Color(1.0, 0.75, 0.4, 0.35 * fade))
		"sunbeam":
			if warn: return
			var w2: float = e.size.x * (0.5 + 0.5 * minf(1.0, act / 3.0))
			ci.draw_rect(Rect2(p.x - w2, 0, w2 * 2, FLOOR_Y), Color(cor, 0.22 * fade))
			ci.draw_rect(Rect2(p.x - w2 * 0.6, 0, w2 * 1.2, FLOOR_Y), Color(cor.lightened(0.4), 0.45 * fade))
			ci.draw_rect(Rect2(p.x - w2 * 0.25, 0, w2 * 0.5, FLOOR_Y), Color(1, 1, 1, 0.8 * fade))
			_glow_ellipse(ci, Vector2(p.x, FLOOR_Y), w2 * 1.8, 40, Color(cor.lightened(0.5), 0.7 * fade))
		"beam", "lightray":
			if warn: return
			var k2: float = clampf(act / 5.0, 0.0, 1.0)
			var x0: float = p.x
			var x1: float = x0 + d * e.size.x * k2
			var th: float = e.size.y * 0.5 + 6.0 * sin(e.t * 1.3)
			var r := Rect2(minf(x0, x1), p.y - th, absf(x1 - x0), th * 2)
			ci.draw_rect(r, Color(cor, 0.3 * fade))
			ci.draw_rect(r.grow_individual(0, -th * 0.4, 0, -th * 0.4), Color(cor.lightened(0.3), 0.6 * fade))
			ci.draw_rect(r.grow_individual(0, -th * 0.75, 0, -th * 0.75), Color(1, 1, 1, 0.9 * fade))
			_glow(ci, Vector2(x0, p.y), th * 1.8, Color(cor.lightened(0.4), 0.8 * fade))
			if e.kind == "beam":
				for i in 8:
					var lx := fmod(e.t * 40.0 + i * 180.0, 1400.0) * k2
					ci.draw_line(Vector2(x0 + d * lx, p.y - th * 0.9 + i * 22.0), Vector2(x0 + d * (lx + 120.0), p.y - th * 0.9 + i * 22.0), Color(1, 1, 1, 0.35 * fade), 2)
		"shadowslash":
			if warn: return
			var ang: float = e.seed + d * 0.5
			var dirv := Vector2(cos(ang), sin(ang))
			var lk := clampf(act / 3.0, 0.0, 1.0)
			var a2 := p - dirv * 150.0
			ci.draw_line(a2, a2 + dirv * 300.0 * lk, Color(cor.lightened(0.3), fade), 8)
			ci.draw_line(a2, a2 + dirv * 300.0 * lk, Color(1, 1, 1, fade), 2)
			_glow(ci, p, 90, Color(cor, 0.4 * fade))
		"circle":
			if warn: return
			_glow_ellipse(ci, p - Vector2(0, 150), 150, 220, Color(cor, 0.3 * fade))
		"tornado", "cyclone":
			var big: bool = e.kind == "cyclone"
			var hgt: float = e.size.y
			var layers := 12 if big else 8
			var wbase: float = e.size.x
			for i in layers:
				var k4 := float(i) / (layers - 1)
				var y: float = p.y - k4 * hgt
				var w: float = wbase * (0.25 + 0.75 * k4)
				var off := sin(e.t * 0.25 + i * 0.7) * 14.0 * k4
				ci.draw_set_transform(Vector2(p.x + off, y), 0.0, Vector2(1.0, 0.28))
				ci.draw_arc(Vector2.ZERO, w * 0.5, e.t * 0.3 + i, e.t * 0.3 + i + PI * 1.4, 18, Color(cor.lightened(0.4), 0.5 * fade), 6 if big else 4)
				ci.draw_arc(Vector2.ZERO, w * 0.35, -e.t * 0.25 + i, -e.t * 0.25 + i + PI, 14, Color(1, 1, 1, 0.3 * fade), 3)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_glow_ellipse(ci, p - Vector2(0, hgt * 0.5), wbase * 0.8, hgt * 0.6, Color(cor, 0.18 * fade))
		"gust":
			for i in 6:
				var yy := p.y - 20 - i * 32.0
				var xx := p.x + sin(e.t * 0.4 + i) * 10.0
				ci.draw_line(Vector2(xx - d * 50, yy), Vector2(xx + d * 40, yy - 6), Color(0.8, 0.95, 1.0, 0.45 * fade), 3)
			_glow_ellipse(ci, p - Vector2(0, 100), 60, 110, Color(0.7, 0.9, 1.0, 0.18 * fade))
		"wave", "tsunami":
			_glow_ellipse(ci, p - Vector2(0, e.size.y * 0.4), e.size.x * 0.8, e.size.y * 0.6, Color(cor, 0.2 * fade))
		"frost":
			if warn: return
			for i in 12:
				var pp: Vector2 = p + Vector2(d * (-100 + fmod(e.t * 14.0 + i * 19.0, 200.0)), sin(i * 2.1 + e.t * 0.3) * 40.0)
				_glow(ci, pp, 22, Color(0.7, 0.95, 1.0, 0.45 * fade))
			_glow_ellipse(ci, p, 130, 70, Color(0.6, 0.9, 1.0, 0.3 * fade))
		"steam":
			if warn: return
			for i in 10:
				var pp2: Vector2 = p + Vector2(d * (-100 + fmod(e.t * 14.0 + i * 23.0, 200.0)), sin(i * 1.7) * 36.0)
				_glow(ci, pp2, 30, Color(1, 1, 1, 0.3 * fade))
		"flash":
			var kf := clampf(act / 8.0, 0.0, 1.0)
			_glow(ci, p, 60 + 180 * kf, Color(1.0, 0.95, 0.7, 0.9 * (1.0 - kf)))
			for k in 12:
				var ang2 := k * TAU / 12.0
				ci.draw_line(p + Vector2(cos(ang2), sin(ang2)) * 40.0, p + Vector2(cos(ang2), sin(ang2)) * (60.0 + 140.0 * kf), Color(1.0, 0.9, 0.5, 0.8 * (1.0 - kf)), 4)
		"rings":
			for k in 3:
				var rr := 70.0 + k * 22.0
				ci.draw_set_transform(p, e.t * (0.12 + k * 0.05) * (1 if k % 2 == 0 else -1), Vector2(1.0, 0.45))
				ci.draw_arc(Vector2.ZERO, rr, 0, TAU, 40, Color(Color("e8c27a") if k == 1 else cor, 0.8 * fade), 5)
				ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
				var pa: float = e.t * (0.12 + k * 0.05) * 1.6 + k * 2.0
				_glow(ci, p + Vector2(cos(pa) * rr, sin(pa) * rr * 0.45), 16, Color(cor.lightened(0.4), 0.9 * fade))
		"embers":
			var r5 := ent_rect(e)
			var n := 10 if Game.leve() else 18
			for i in n:
				var x2: float = r5.position.x + fmod(i * 37.0 + e.seed * 10.0, r5.size.x)
				var hh2 := 20.0 + 18.0 * absf(sin(e.t * 0.25 + i))
				_glow_ellipse(ci, Vector2(x2, p.y - hh2 * 0.5), 14, hh2, Color(1.0, 0.45 + 0.2 * sin(i), 0.1, 0.6 * fade))
		"darkpool":
			for i in 5:
				var ph2 := fmod(e.t * 0.02 + i * 0.2, 1.0)
				_glow(ci, p + Vector2(sin(i * 2.0) * 70.0, -10 - ph2 * 70.0), 10, Color(0.6, 0.2, 1.0, 0.5 * (1.0 - ph2) * fade))
		"poison":
			for i in 4:
				var bph := fmod(e.t * 0.02 + i * 0.25, 1.0)
				ci.draw_arc(p + Vector2(sin(i * 2.0) * 60, -bph * 110), 6, 0, TAU, 10, Color(cor.lightened(0.3), 0.7 * (1.0 - bph) * fade), 2)
		"mine":
			if e.t - e.delay >= e.get("arm", 15):
				if int(e.t / 10) % 2 == 0:
					_glow(ci, Vector2(p.x, p.y - 24), 34, Color(cor, 0.95))
				# onda no chão mostrando a área da mina
				var kp := fmod(e.t / 45.0, 1.0)
				ci.draw_set_transform(Vector2(p.x, p.y), 0, Vector2(1.0, 0.22))
				ci.draw_arc(Vector2.ZERO, 30.0 + 60.0 * kp, 0, TAU, 32, Color(cor, 0.7 * (1.0 - kp)), 3)
				ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		"icefloor":
			_glow_ellipse(ci, p - Vector2(0, 6), e.size.x * 0.6, 18, Color(0.6, 0.9, 1.0, 0.35))
		"rune":
			_glow_ellipse(ci, p - Vector2(0, 4), e.size.x * 0.6, 22, Color(cor, 0.35 + 0.15 * sin(e.t * 0.2)))
		"thorns":
			_glow_ellipse(ci, p, 70, 16, Color(0.5, 1.0, 0.3, 0.25))
		"turret":
			_glow(ci, Vector2(p.x, p.y - 52), 24, Color(cor, 0.4))
		"blackhole":
			var pulse := 0.5 + 0.5 * sin(e.t * 0.2)
			_glow(ci, p, 150, Color(0.45, 0.2, 1.0, 0.35 * fade))
			for k in 4:
				var a3: float = -e.t * (0.08 + k * 0.03) + k * 1.6
				ci.draw_arc(p, 46.0 + k * 18.0 + pulse * 6.0, a3, a3 + 2.4, 20, Color(0.75, 0.5, 1.0, (0.6 - k * 0.1) * fade), 3)
		"blast":
			var k8 := clampf(act / 8.0, 0.0, 1.0)
			_glow(ci, p + Vector2(0, -50), 40 + 140 * k8, Color(cor, 0.8 * (1.0 - k8)))
			_glow(ci, p + Vector2(0, -50), 20 + 60 * k8, Color(1, 1, 1, 0.9 * (1.0 - k8)))
		"burst":
			var kb := clampf(act / 6.0, 0.0, 1.0)
			ci.draw_arc(p, 150 * kb, 0, TAU, 40, Color(cor, 1.0 - kb), 10)
		"shatter":
			var k5 := clampf(act / 6.0, 0.0, 1.0)
			_glow(ci, p, 160 * k5 + 20, Color(0.8, 0.95, 1.0, 0.8 * (1.0 - k5)))
			for i in 12:
				var ang6 := i * TAU / 12.0
				ci.draw_line(p + Vector2(cos(ang6), sin(ang6)) * 40.0 * k5, p + Vector2(cos(ang6), sin(ang6)) * 170.0 * k5, Color(0.8, 0.95, 1.0, 1.0 - k5), 8)
		"quake":
			var k7 := clampf(act / 8.0, 0.0, 1.0)
			for s in [-1, 1]:
				for i in 6:
					var x3 = 640.0 + s * k7 * 650.0 * (0.4 + i * 0.12)
					ci.draw_line(Vector2(640 + s * 40 * i, FLOOR_Y + 4), Vector2(x3, FLOOR_Y + 4 + (i % 3) * 6), Color(cor, 0.8 * (1.0 - k7 * 0.5)), 4)
			ci.draw_rect(Rect2(0, FLOOR_Y - 30 * (1.0 - k7), 1280, 30 * (1.0 - k7)), Color(cor, 0.3 * (1.0 - k7)))

func ent_rect(e: Dictionary) -> Rect2:
	return fight.ent_rect(e) if fight else Rect2()

# ---------------------------------------------------------------- peças de desenho
func _floor_warn(ci: CanvasItem, p: Vector2, r: float, cor: Color, e: Dictionary) -> void:
	var k := 1.0 - float(e.delay - e.t) / maxf(1.0, e.delay)
	var pulse := 0.5 + 0.5 * sin(e.t * 0.6)
	ci.draw_set_transform(Vector2(p.x, FLOOR_Y + 3), 0, Vector2(1.0, 0.25))
	ci.draw_circle(Vector2.ZERO, r * (0.6 + 0.4 * k), Color(cor, 0.25 + 0.25 * pulse))
	ci.draw_arc(Vector2.ZERO, r * (0.6 + 0.4 * k), 0, TAU, 32, Color(cor.lightened(0.4), 0.8), 3)
	ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _bubbles_warn(ci: CanvasItem, p: Vector2, e: Dictionary) -> void:
	for i in 4:
		var ph := fmod(e.t * 0.05 + i * 0.25, 1.0)
		ci.draw_arc(p + Vector2(sin(i * 2.0) * 30.0, -6 - ph * 40.0), 4 + i, 0, TAU, 8, Color(0.8, 0.95, 1.0, 1.0 - ph), 2)

func _cracks(ci: CanvasItem, p: Vector2, cor: Color, e: Dictionary) -> void:
	for i in 5:
		var a := -PI + (i + 0.5) * PI / 5.0
		var l := 30.0 + 10.0 * sin(e.seed + i)
		ci.draw_line(Vector2(p.x, FLOOR_Y + 2), Vector2(p.x + cos(a) * l * 1.6, FLOOR_Y + 2 - sin(a) * l * 0.25), Color(cor, 0.8), 3)

## Coluna que explode do chão (fogo, ácido, água): corpo ondulando, núcleo claro e uma coroa de línguas na ponta
func _draw_column(ci: CanvasItem, p: Vector2, w: float, h: float, c1: Color, c2: Color, fade: float, sd: float) -> void:
	if h <= 1.0: return
	_coluna_camada(ci, p, w * 0.5, h, c1, 0.85 * fade, sd, 1.0)
	_coluna_camada(ci, p, w * 0.3, h * 0.93, c2, 0.92 * fade, sd + 1.3, 0.7)
	_coluna_camada(ci, p, w * 0.12, h * 0.8, c2.lightened(0.6), 0.85 * fade, sd + 2.1, 0.45)

func _coluna_camada(ci: CanvasItem, p: Vector2, meia: float, h: float, cor: Color, a: float, sd: float, lingua: float) -> void:
	var steps := 9
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in steps + 1:
		var k := float(i) / steps
		var y := p.y - h * k
		var wob := sin(sd + k * 7.0 + t * 15.0) * 7.0 * (0.25 + k)
		var ww := meia * (1.0 - 0.3 * k) * (1.0 + 0.1 * sin(t * 21.0 + k * 10.0 + sd))
		left.append(Vector2(p.x - ww + wob, y))
		right.append(Vector2(p.x + ww + wob, y))
	# coroa: línguas que sobem e descem na ponta
	var lt: Vector2 = left[steps]
	var rt: Vector2 = right[steps]
	var coroa := PackedVector2Array()
	var n := 7
	for j in range(1, n):
		var k2 := float(j) / n
		var x := lerpf(lt.x, rt.x, k2)
		var alto := (j % 2 == 1)
		var hl := meia * 1.3 * lingua * (0.65 + 0.35 * sin(t * 18.0 + j * 1.9 + sd))
		coroa.append(Vector2(x, lt.y - (hl if alto else hl * 0.15)))
	right.reverse()
	var pts := left + coroa + right
	ci.draw_colored_polygon(pts, Color(cor, a))

func _draw_spike(ci: CanvasItem, p: Vector2, w: float, h: float, c1: Color, c2: Color, fade: float, sd: float) -> void:
	if h <= 1.0: return
	var bend := sin(sd) * 18.0
	var pts := PackedVector2Array([Vector2(p.x - w / 2.0, p.y), Vector2(p.x - w * 0.18 + bend * 0.5, p.y - h * 0.55),
		Vector2(p.x + bend, p.y - h), Vector2(p.x + w * 0.2 + bend * 0.5, p.y - h * 0.55), Vector2(p.x + w / 2.0, p.y)])
	ci.draw_colored_polygon(pts, Color(c1, fade))
	ci.draw_polyline(pts, Color(c1.darkened(0.5), fade), 3)
	ci.draw_line(Vector2(p.x, p.y), Vector2(p.x + bend, p.y - h), Color(c2, 0.8 * fade), 4)
	_leaf(ci, Vector2(p.x + bend * 0.5 + 10, p.y - h * 0.5), 12.0, sd, Color(c2, fade))
	_leaf(ci, Vector2(p.x + bend * 0.3 - 12, p.y - h * 0.3), 10.0, sd + 2.0, Color(c2, fade))

## Broto Gigante: caule verde que sobe com duas folhas grandes e um botão na ponta
func _draw_sprout(ci: CanvasItem, p: Vector2, w: float, h: float, fade: float, sd: float) -> void:
	if h <= 1.0: return
	var bend := sin(sd) * 16.0
	var steps := 8
	var l := PackedVector2Array()
	var r := PackedVector2Array()
	for i in steps + 1:
		var k := float(i) / steps
		var x := p.x + bend * k * k + sin(t * 6.0 + k * 3.0) * 3.0 * k
		var ww := lerpf(w * 0.26, w * 0.09, k)
		l.append(Vector2(x - ww, p.y - h * k))
		r.append(Vector2(x + ww, p.y - h * k))
	r.reverse()
	var caule := l + r
	ci.draw_colored_polygon(caule, Color("3f8f2a", fade))
	ci.draw_polyline(caule, Color("1f4a14", fade), 2)
	ci.draw_line(Vector2(p.x, p.y), Vector2(p.x + bend, p.y - h), Color("8fe05a", 0.7 * fade), 3)
	var topo := Vector2(p.x + bend, p.y - h)
	var balanco := sin(t * 5.0 + sd) * 0.12
	for lado in [-1.0, 1.0]:
		var base := topo + Vector2(0, h * 0.22)
		var ang: float = (-PI * 0.5 + lado * 0.95) + balanco
		var dv := Vector2(cos(ang), sin(ang))
		var cen: Vector2 = base + dv * w * 0.42
		_leaf(ci, cen, w * 0.46, ang, Color("5fc23a", fade))
		ci.draw_line(base, base + dv * w * 0.8, Color("2f6a1c", fade), 2)
	ci.draw_circle(topo, w * 0.17, Color("8fe05a", fade))
	ci.draw_circle(topo + Vector2(-w * 0.05, -w * 0.06), w * 0.07, Color(1, 1, 1, 0.5 * fade))
	# terra levantada na base
	for k in 5:
		var dx := (k - 2) * w * 0.28
		ci.draw_circle(Vector2(p.x + dx, p.y - 4), 7.0 + 3.0 * absf(sin(sd + k)), Color("5a3d22", fade))

## Pilar de Pedra: obelisco com duas faces (luz e sombra), rachaduras e pedrinhas na base
func _draw_pillar(ci: CanvasItem, p: Vector2, meia: float, h: float, fade: float, sd: float) -> void:
	if h <= 1.0: return
	var topo_l := Vector2(p.x - meia * 0.78, p.y - h * 0.9)
	var topo := Vector2(p.x - meia * 0.1, p.y - h)
	var topo_r := Vector2(p.x + meia * 0.8, p.y - h * 0.93)
	var face_l := PackedVector2Array([Vector2(p.x - meia, p.y), topo_l, topo, Vector2(p.x + meia * 0.15, p.y - h * 0.97), Vector2(p.x + meia * 0.2, p.y)])
	var face_r := PackedVector2Array([Vector2(p.x + meia * 0.2, p.y), Vector2(p.x + meia * 0.15, p.y - h * 0.97), topo_r, Vector2(p.x + meia, p.y)])
	ci.draw_colored_polygon(face_l, Color("9c8a6c", fade))
	ci.draw_colored_polygon(face_r, Color("6e604c", fade))
	ci.draw_polyline(PackedVector2Array([Vector2(p.x - meia, p.y), topo_l, topo, topo_r, Vector2(p.x + meia, p.y)]), Color("3a3028", fade), 3)
	ci.draw_line(topo_l, topo, Color(1, 1, 1, 0.35 * fade), 3)
	for k in 4:
		var yy := p.y - h * (0.18 + 0.19 * k)
		var x0 := p.x - meia * (0.85 - 0.05 * sin(sd + k))
		ci.draw_polyline(PackedVector2Array([Vector2(x0, yy), Vector2(x0 + meia * 0.5, yy + 6), Vector2(x0 + meia * 0.9, yy + 2)]), Color("4a3e30", fade), 2)
	for k in 6:
		var dx := (k - 2.5) * meia * 0.5
		ci.draw_circle(Vector2(p.x + dx, p.y - 5), 6.0 + 3.0 * absf(sin(sd * 2.0 + k)), Color("7a6a55", fade))

func _leaf(ci: CanvasItem, p: Vector2, s: float, ang: float, cor: Color) -> void:
	var d := Vector2(cos(ang), sin(ang)) * s
	var n := Vector2(-d.y, d.x) * 0.45
	ci.draw_colored_polygon(PackedVector2Array([p - d, p + n, p + d, p - n]), cor)

func _crystal(ci: CanvasItem, p: Vector2, w: float, h: float, fade: float, lean: float) -> void:
	if h <= 1.0: return
	var top := p + Vector2(lean * h, -h)
	var pts := PackedVector2Array([p + Vector2(-w / 2.0, 0), p + Vector2(-w * 0.4, -h * 0.75) + Vector2(lean * h * 0.75, 0), top,
		p + Vector2(w * 0.4, -h * 0.75) + Vector2(lean * h * 0.75, 0), p + Vector2(w / 2.0, 0)])
	ci.draw_colored_polygon(pts, Color(0.65, 0.88, 1.0, 0.85 * fade))
	ci.draw_colored_polygon(PackedVector2Array([p, top, p + Vector2(w * 0.4, -h * 0.75) + Vector2(lean * h * 0.75, 0), p + Vector2(w / 2.0, 0)]), Color(0.45, 0.7, 0.95, 0.6 * fade))
	ci.draw_polyline(pts, Color(1, 1, 1, 0.9 * fade), 2)

func _draw_wave(ci: CanvasItem, p: Vector2, d: int, w: float, h: float, cor: Color, fade: float, tt: int) -> void:
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
	ci.draw_colored_polygon(pts, Color(cor.darkened(0.15), 0.85 * fade))
	var inner := PackedVector2Array([Vector2(back + d * w * 0.2, p.y)])
	for i in 9:
		var k2 := float(i) / 8.0
		inner.append(Vector2(back + d * w * (0.2 + 0.6 * k2), p.y - h * 0.6 * pow(sin(k2 * PI * 0.5), 1.5)))
	inner.append(Vector2(back + d * w * 0.8, p.y))
	ci.draw_colored_polygon(inner, Color(cor.lightened(0.35), 0.35 * fade))
	var foam := PackedVector2Array()
	for i in range(1, n + 2):
		foam.append(pts[i] + Vector2(0, 4))
	foam.append(tip + Vector2(0, 4))
	ci.draw_polyline(foam, Color(1, 1, 1, 0.85 * fade), 5)
	ci.draw_circle(tip, h * 0.09, Color(1, 1, 1, 0.7 * fade))
	for i in 6:
		var sx := tip.x + d * (6 + i * 8) + sin(tt * 0.5 + i) * 6
		var sy := tip.y + 10 + fmod(tt * 2.0 + i * 13.0, 40.0)
		ci.draw_circle(Vector2(sx, sy), 3.5, Color(0.85, 0.95, 1.0, 0.8 * fade))

func _gear(ci: CanvasItem, p: Vector2, r: float, rot: float, c1: Color, c2: Color) -> void:
	var pts := PackedVector2Array()
	var teeth := 10
	for i in teeth * 2:
		var a := rot + i * PI / teeth
		var rr := r if i % 2 == 0 else r * 0.78
		pts.append(p + Vector2(cos(a - 0.12), sin(a - 0.12)) * rr)
		pts.append(p + Vector2(cos(a + 0.12), sin(a + 0.12)) * rr)
	ci.draw_colored_polygon(pts, c2)
	ci.draw_circle(p, r * 0.65, c1.darkened(0.2))
	ci.draw_circle(p, r * 0.3, Color("2a2420"))
	ci.draw_arc(p, r * 0.5, rot, rot + PI, 10, c1.lightened(0.4), 2)
