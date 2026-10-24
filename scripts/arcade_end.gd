extends Node2D
## Final do modo Arcade (vidro líquido).

var bg: Node2D
var t := 0.0
var tempo_txt := ""
var g_card: Node2D

func _ready() -> void:
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.arena = "santuario"
	bg.dim = 0.3
	bg.z_index = -3
	add_child(bg)
	Game.music("fim")
	var ms: int = Time.get_ticks_msec() - int(Game.arcade.get("inicio", Time.get_ticks_msec()))
	var s := ms / 1000
	tempo_txt = "%d:%02d" % [s / 60, s % 60]
	g_card = Game.glass(self, Rect2(660, 110, 560, 540), 32, Color(1, 1, 1, 0.08))

func _process(delta: float) -> void:
	t += delta
	g_card.modulate.a = clampf(t / 0.8, 0.0, 1.0)
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
		draw_colored_polygon(PackedVector2Array([Vector2(360, 380), Vector2(360, 380) + Vector2(cos(a - 0.12), sin(a - 0.12)) * 900.0, Vector2(360, 380) + Vector2(cos(a + 0.12), sin(a + 0.12)) * 900.0]), Color(c.cor, 0.08 * e))
	draw_texture_rect(Game.dot_tex, Rect2(Vector2(360, 380) - Vector2(300, 300), Vector2(600, 600)), false, Color(c.cor, 0.35 * e))
	Game.draw_char(self, i, Vector2(360, 390 + 8 * sin(t * 2.0)), 440.0 * e, false)
	Game.text_soft(self, "CAMPEÃO DOS NÚCLEOS", Vector2(660, 170), 40, Color(1, 0.88, 0.45, e), HORIZONTAL_ALIGNMENT_CENTER, 560, "ui")
	Game.text_soft(self, c.nome, Vector2(660, 212), 26, Color(c.cor.lightened(0.45), e), HORIZONTAL_ALIGNMENT_CENTER, 560, "ui")
	Game.text_wrap(self, "O Eco Sombrio se desfez em luz. O Núcleo de %s brilha mais forte do que nunca, e a arena reconhece um novo campeão." % c.nucleo, Vector2(700, 256), 480, 19, Color(1, 1, 1, 0.88 * e), HORIZONTAL_ALIGNMENT_CENTER)
	var linhas := [["PONTOS", str(Game.arcade.get("pontos", 0))], ["TEMPO", tempo_txt], ["CONTINUES", str(Game.arcade.get("continues", 0))]]
	for k in linhas.size():
		var y := 430 + k * 50
		Game.rounded(self, Rect2(700, y - 32, 480, 44), 22, Color(1, 1, 1, 0.06 * e))
		Game.text(self, linhas[k][0], Vector2(726, y), 22, Color(1, 1, 1, 0.75 * e), HORIZONTAL_ALIGNMENT_LEFT, -1, "ui")
		Game.text(self, linhas[k][1], Vector2(900, y), 24, Color(1, 0.88, 0.45, e), HORIZONTAL_ALIGNMENT_RIGHT, 254, "ui")
	Game.text(self, "“%s”" % c.frase, Vector2(660, 610), 17, Color(1, 1, 1, 0.7 * e), HORIZONTAL_ALIGNMENT_CENTER, 560, "corpo")
	if t > 2.0:
		Game.prompts(self, Vector2(940, 690), [["confirm", "Continuar"]], 0, 24.0)
