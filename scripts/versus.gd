extends Node2D
## Tela "VS" antes da luta (aproveita para preparar o cenário da arena).

var t := 0.0
const DURACAO := 3.0
var g_n1: Node2D
var g_n2: Node2D
var g_vs: Node2D
var g_topo: Node2D
var fundo: Node2D

func _ready() -> void:
	# o fundo e os bottons ficam numa camada atrás do vidro (para o vidro desfocar o fundo)
	fundo = preload("res://scripts/draw_proxy.gd").new()
	fundo.alvo = self
	fundo.metodo = "_draw_fundo"
	fundo.z_index = -2
	add_child(fundo)
	Game.play("round", 0.9)
	Game.play("whoosh", 0.7)
	if Game.modo == "arcade":
		Game.music("selecao")
	if Game.arena >= 0:
		Game.bake_arena(Game.ARENAS[Game.arena].id)
	g_n1 = Game.glass(self, Rect2(30, 560, 600, 120), 30, Color(Game.ROSTER[Game.escolha[0]].cor, 0.16))
	g_n2 = Game.glass(self, Rect2(650, 560, 600, 120), 30, Color(Game.ROSTER[Game.escolha[1]].cor, 0.16))
	g_vs = Game.glass(self, Rect2(560, 280, 160, 160), 80, Color(1, 1, 1, 0.16))
	g_vs.glow = 0.8
	g_vs.glow_color = Color("ffd36b")
	g_topo = Game.glass(self, Rect2(340, 22, 600, 46), 23, Color(1, 1, 1, 0.12))

func _process(delta: float) -> void:
	t += delta
	if t > 0.6 and (Game.just("confirm") or t > DURACAO):
		set_process(false)
		Game.goto("res://scripts/fight.gd")
	var ta := clampf((t - 0.25) / 0.3, 0.0, 1.0)
	g_n1.modulate.a = ta
	g_n2.modulate.a = ta
	g_vs.modulate.a = clampf((t - 0.2) / 0.2, 0.0, 1.0)
	queue_redraw()

func _draw_fundo(ci: CanvasItem) -> void:
	var c1: Color = Game.ROSTER[Game.escolha[0]].cor
	var eco: bool = Game.modo == "arcade" and Game.eco[1]
	var c2: Color = Game.ROSTER[Game.escolha[1]].cor if not eco else Color("ff3a8a")
	var k := clampf(t / 0.35, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 3.0)
	ci.draw_polygon(PackedVector2Array([Vector2(-200, -50), Vector2(760 * e, -50), Vector2(520 * e, 770), Vector2(-200, 770)]),
		PackedColorArray([c1.darkened(0.75), c1.darkened(0.45), c1.darkened(0.55), c1.darkened(0.8)]))
	ci.draw_polygon(PackedVector2Array([Vector2(1480, -50), Vector2(1480 - 920 * e, -50), Vector2(1480 - 960 * e, 770), Vector2(1480, 770)]),
		PackedColorArray([c2.darkened(0.75), c2.darkened(0.45), c2.darkened(0.55), c2.darkened(0.8)]))
	for i in 18:
		var y := fmod(i * 41.0, 720.0)
		var x := fmod(t * 900.0 + i * 170.0, 1700.0) - 200.0
		ci.draw_line(Vector2(x, y), Vector2(x - 260, y), Color(1, 1, 1, 0.07), 3)
	ci.draw_texture_rect(Game.dot_tex, Rect2(Vector2(330, 330) - Vector2(300, 260), Vector2(600, 520)), false, Color(c1, 0.35))
	ci.draw_texture_rect(Game.dot_tex, Rect2(Vector2(950, 330) - Vector2(300, 260), Vector2(600, 520)), false, Color(c2, 0.35))
	var bob := 6.0 * sin(t * 3.0)
	var x1 := lerpf(-300.0, 330.0, e)
	var x2 := lerpf(1580.0, 950.0, e)
	Game.draw_char(ci, Game.escolha[0], Vector2(x1, 330 + bob), 400.0, false)
	Game.draw_char(ci, Game.escolha[1], Vector2(x2, 330 - bob), 400.0, true, Color(0.55, 0.3, 0.7) if eco else Color.WHITE)

func _draw() -> void:
	var eco: bool = Game.modo == "arcade" and Game.eco[1]
	var d1: Dictionary = Game.ROSTER[Game.escolha[0]]
	var d2: Dictionary = Game.ROSTER[Game.escolha[1]]
	var n1: String = d1.nome
	var n2: String = d2.nome if not eco else "ECO SOMBRIO"
	var f2: String = d2.frase if not eco else "Eu sou tudo o que você teme em si mesmo."
	var ta := clampf((t - 0.3) / 0.3, 0.0, 1.0)
	Game.text_soft(self, n1, Vector2(60, 612), 32, Color(1, 1, 1, ta), HORIZONTAL_ALIGNMENT_LEFT, 560, "ui")
	Game.tipo_selo(self, Vector2(60, 638), d1.tipo, 22)
	Game.text(self, "“%s”" % d1.frase, Vector2(60, 666), 15, Color(1, 1, 1, 0.75 * ta), HORIZONTAL_ALIGNMENT_LEFT, 560, "corpo")
	Game.text_soft(self, n2, Vector2(660, 612), 32, Color(1, 1, 1, ta), HORIZONTAL_ALIGNMENT_RIGHT, 560, "ui")
	Game.tipo_selo(self, Vector2(1220 - Game.tipo_selo_w(d2.tipo, 22), 638), d2.tipo, 22)
	Game.text(self, "“%s”" % f2, Vector2(660, 666), 15, Color(1, 1, 1, 0.75 * ta), HORIZONTAL_ALIGNMENT_RIGHT, 560, "corpo")
	var vs := clampf((t - 0.25) / 0.2, 0.0, 1.0)
	var esc := 1.0 + 1.2 * (1.0 - vs) + 0.04 * sin(t * 8.0)
	Game.text_scaled(self, "VS", Vector2(640, 350), 96, esc, Color(1, 0.88, 0.4, vs), "logo", 10, Color(0.2, 0.05, 0.1, 0.6 * vs))
	var topo = Game.ARENAS[Game.arena].nome if Game.arena >= 0 else "ARENA ALEATÓRIA"
	if Game.modo == "arcade" and not Game.arcade.is_empty():
		topo = "LUTA %d DE %d  •  %s" % [Game.arcade.etapa + 1, Game.arcade.escada.size(), topo]
		if eco: topo = "LUTA FINAL  •  O ECO SOMBRIO"
	Game.text(self, topo, Vector2(340, 53), 21, Color(1, 0.93, 0.75, ta), HORIZONTAL_ALIGNMENT_CENTER, 600, "ui")
	if t > DURACAO - 0.3:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, clampf((t - DURACAO + 0.3) / 0.3, 0.0, 1.0)))
