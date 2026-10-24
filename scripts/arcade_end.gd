extends Node2D
## Final do modo Arcade.

var bg: Node2D
var t := 0.0
var tempo_txt := ""

func _ready() -> void:
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.arena = "santuario"
	bg.dim = 0.35
	bg.z_index = -2
	add_child(bg)
	Game.music("fim")
	var ms: int = Time.get_ticks_msec() - int(Game.arcade.get("inicio", Time.get_ticks_msec()))
	var s := ms / 1000
	tempo_txt = "%d:%02d" % [s / 60, s % 60]

func _process(delta: float) -> void:
	t += delta
	if t > 2.0 and Game.just("confirm"):
		Game.arcade = {}
		Game.goto("res://scripts/title.gd")
	queue_redraw()

func _draw() -> void:
	var i: int = Game.arcade.get("char", 0)
	var c: Dictionary = Game.ROSTER[i]
	var e := clampf(t / 1.2, 0.0, 1.0)
	for k in 8:
		var a := t * 0.4 + k * TAU / 8.0
		draw_colored_polygon(PackedVector2Array([Vector2(400, 360), Vector2(400, 360) + Vector2(cos(a - 0.12), sin(a - 0.12)) * 900.0, Vector2(400, 360) + Vector2(cos(a + 0.12), sin(a + 0.12)) * 900.0]), Color(c.cor, 0.08 * e))
	Game.draw_char(self, i, Vector2(400, 380 + 8 * sin(t * 2.0)), 460.0 * e, false)
	Game.text(self, "CAMPEÃO DOS NÚCLEOS", Vector2(640, 150), 54, Color(1, 0.85, 0.3, e), HORIZONTAL_ALIGNMENT_CENTER, 600, true, 12, Color(0.2, 0.05, 0.1, e))
	Game.text(self, c.nome, Vector2(640, 215), 34, Color(c.cor.lightened(0.4), e), HORIZONTAL_ALIGNMENT_CENTER, 600, true, 8)
	Game.text_wrap(self, "O Eco Sombrio se desfez em luz. O Núcleo de %s brilha mais forte do que nunca, e a arena reconhece um novo campeão." % c.nucleo, Vector2(680, 270), 520, 22, Color(1, 1, 1, 0.85 * e), HORIZONTAL_ALIGNMENT_CENTER)
	var linhas := [["PONTOS", str(Game.arcade.get("pontos", 0))], ["TEMPO", tempo_txt], ["CONTINUES", str(Game.arcade.get("continues", 0))]]
	for k in linhas.size():
		var y := 450 + k * 46
		Game.text(self, linhas[k][0], Vector2(700, y), 28, Color(1, 1, 1, 0.7 * e), HORIZONTAL_ALIGNMENT_LEFT, -1, true, 5)
		Game.text(self, linhas[k][1], Vector2(900, y), 30, Color(1, 0.85, 0.3, e), HORIZONTAL_ALIGNMENT_RIGHT, 260, true, 5)
	Game.text(self, "“%s”" % c.frase, Vector2(640, 620), 20, Color(1, 1, 1, 0.7 * e), HORIZONTAL_ALIGNMENT_CENTER, 600, false, 3)
	if t > 2.0:
		Game.text(self, "Aperte Enter", Vector2(0, 690), 20, Color(1, 1, 1, 0.5 + 0.4 * sin(t * 4.0)), HORIZONTAL_ALIGNMENT_CENTER, 1280, false)
