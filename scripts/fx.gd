extends Node2D
## Efeitos visuais: faíscas, anéis, textos, orbes e o raio do supremo.

var fight: Node
var sparks: Array = []   # [pos, vel, vida, cor, tamanho]
var rings: Array = []    # [pos, raio, vida, cor, crescimento]
var texts: Array = []    # [texto, pos, vida, cor, tamanho]

func burst(p: Vector2, cor: Color, n := 12, forca := 1.0) -> void:
	for i in n:
		var a := randf() * TAU
		var v := Vector2(cos(a), sin(a)) * randf_range(200, 650) * forca
		sparks.append([p, v, randf_range(0.18, 0.4), cor.lightened(randf() * 0.5), randf_range(2.0, 5.0) * forca])
	rings.append([p, 10.0, 0.25, cor, 900.0 * forca])

func pop(s: String, p: Vector2, cor: Color, size := 34) -> void:
	texts.append([s, p, 0.9, cor, size])

func _process(delta: float) -> void:
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
	for t in texts:
		t[1].y -= 50 * dt
		t[2] -= dt
	texts = texts.filter(func(t): return t[2] > 0.0)
	queue_redraw()

func _draw() -> void:
	# orbes (projéteis)
	if fight:
		for pr in fight.projectiles:
			var cor: Color = pr.cor
			for k in 6:
				var tp: Vector2 = pr.pos - pr.vel.normalized() * k * 14.0
				draw_circle(tp, 20.0 - k * 2.6, Color(cor, 0.35 - k * 0.05))
			draw_circle(pr.pos, 24.0 + 3 * sin(pr.t * 30.0), Color(cor, 0.4))
			draw_circle(pr.pos, 16.0, cor.lightened(0.3))
			draw_circle(pr.pos, 8.0, Color(1, 1, 1, 0.95))
			for k in 3:
				var a: float = pr.t * 12.0 + k * TAU / 3.0
				draw_arc(pr.pos, 22.0, a, a + 1.2, 10, Color(cor.lightened(0.5), 0.8), 2.5)
		# raio do supremo
		for f in fight.fighters:
			if f.state == "attack" and f.move == "supremo":
				var m: Dictionary = f.current_move()
				var su: int = m.startup
				if f.move_f > su and f.move_f <= su + m.active + 8:
					var k: float = clampf(float(f.move_f - su) / 6.0, 0.0, 1.0)
					var fade: float = clampf(1.0 - float(f.move_f - su - m.active) / 8.0, 0.0, 1.0)
					var y: float = f.position.y - 90.0
					var x0: float = f.position.x + f.facing * 80.0
					var x1: float = x0 + f.facing * 1400.0 * k
					var th := 70.0 + 10.0 * sin(f.move_f * 1.3)
					var cor: Color = f.data.cor
					draw_rect(Rect2(min(x0, x1), y - th, abs(x1 - x0), th * 2), Color(cor, 0.35 * fade))
					draw_rect(Rect2(min(x0, x1), y - th * 0.6, abs(x1 - x0), th * 1.2), Color(cor.lightened(0.3), 0.7 * fade))
					draw_rect(Rect2(min(x0, x1), y - th * 0.25, abs(x1 - x0), th * 0.5), Color(1, 1, 1, 0.95 * fade))
					draw_circle(Vector2(x0, y), th * 0.75, Color(cor.lightened(0.4), 0.7 * fade))
	for r in rings:
		draw_arc(r[0], r[1], 0, TAU, 32, Color(r[3], r[2] * 3.0), 4)
	for s in sparks:
		var tail: Vector2 = s[1] * 0.03
		draw_line(s[0], s[0] - tail, Color(s[3], min(1.0, s[2] * 4.0)), s[4])
	for t in texts:
		var a: float = clampf(t[2] * 2.0, 0.0, 1.0)
		Game.text(self, t[0], t[1] - Vector2(200, 0), t[4], Color(t[3], a), HORIZONTAL_ALIGNMENT_CENTER, 400, true, 8, Color(0, 0, 0, 0.8 * a))
