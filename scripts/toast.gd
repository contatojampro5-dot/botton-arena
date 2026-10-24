extends Node2D
## Avisos rápidos no topo da tela (controle conectado, modo leve...).

func _process(delta: float) -> void:
	var vivos := []
	for t in Game.toasts:
		t.t += delta
		if t.t < 3.2:
			vivos.append(t)
	Game.toasts = vivos
	queue_redraw()

func _draw() -> void:
	var y := 24.0
	for t in Game.toasts:
		var k: float = t.t
		var a := clampf(k * 5.0, 0.0, 1.0) * clampf((3.2 - k) * 3.0, 0.0, 1.0)
		var fs := 18
		var w := Game.text_width(t.msg, fs, "bold") + 48.0
		var r := Rect2(640 - w / 2.0, y - 8.0 * (1.0 - a), w, 38)
		Game.rounded(self, r.grow(2), 21, Color(1, 1, 1, 0.25 * a))
		Game.rounded(self, r, 19, Color(0.08, 0.07, 0.16, 0.86 * a))
		Game.rounded(self, Rect2(r.position + Vector2(6, 4), Vector2(r.size.x - 12, 12)), 6, Color(1, 1, 1, 0.08 * a))
		Game.text(self, t.msg, Vector2(r.position.x, r.position.y + 25), fs, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, w, "bold")
		y += 46.0
