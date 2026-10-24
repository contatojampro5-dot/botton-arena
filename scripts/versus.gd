extends Node2D
## Tela "VS" antes da luta.

var t := 0.0
const DURACAO := 3.0

func _ready() -> void:
	Game.play("round", 0.9)
	Game.play("whoosh", 0.7)
	if Game.modo == "arcade":
		Game.music("selecao")

func _process(delta: float) -> void:
	t += delta
	if t > 0.6 and (Game.just("confirm") or t > DURACAO):
		set_process(false)
		Game.goto("res://scripts/fight.gd")
	queue_redraw()

func _draw() -> void:
	var c1: Color = Game.ROSTER[Game.escolha[0]].cor
	var eco: bool = Game.modo == "arcade" and Game.eco[1]
	var c2: Color = Game.ROSTER[Game.escolha[1]].cor if not eco else Color("ff3a8a")
	var k := clampf(t / 0.35, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 3.0)
	# metades diagonais
	draw_colored_polygon(PackedVector2Array([Vector2(-200, -50), Vector2(760 * e - 200 + 200, -50), Vector2(520 * e, 770), Vector2(-200, 770)]), c1.darkened(0.55))
	draw_colored_polygon(PackedVector2Array([Vector2(1480, -50), Vector2(1480 - 920 * e, -50), Vector2(1480 - 960 * e - 200 + 200, 770), Vector2(1480, 770)]), c2.darkened(0.55))
	# linhas de velocidade
	for i in 18:
		var y := fmod(i * 41.0, 720.0)
		var x := fmod(t * 900.0 + i * 170.0, 1700.0) - 200.0
		draw_line(Vector2(x, y), Vector2(x - 260, y), Color(1, 1, 1, 0.08), 3)
	# lutadores
	var bob := 6.0 * sin(t * 3.0)
	var x1 := lerpf(-300.0, 330.0, e)
	var x2 := lerpf(1580.0, 950.0, e)
	Game.draw_char(self, Game.escolha[0], Vector2(x1, 350 + bob), 420.0, false)
	Game.draw_char(self, Game.escolha[1], Vector2(x2, 350 - bob), 420.0, true, Color(0.55, 0.3, 0.7) if eco else Color.WHITE)
	# nomes e frases
	var n1: String = Game.ROSTER[Game.escolha[0]].nome
	var n2: String = Game.ROSTER[Game.escolha[1]].nome if not eco else "ECO SOMBRIO"
	var f1: String = Game.ROSTER[Game.escolha[0]].frase
	var f2: String = Game.ROSTER[Game.escolha[1]].frase if not eco else "Eu sou tudo o que você teme em si mesmo."
	var ta := clampf((t - 0.3) / 0.3, 0.0, 1.0)
	Game.text(self, n1, Vector2(40, 600), 40, Color(1, 1, 1, ta), HORIZONTAL_ALIGNMENT_LEFT, 600, true, 10)
	Game.text(self, "“%s”" % f1, Vector2(40, 636), 18, Color(1, 1, 1, 0.75 * ta), HORIZONTAL_ALIGNMENT_LEFT, 560, false, 3)
	Game.text(self, n2, Vector2(640, 600), 40, Color(1, 1, 1, ta), HORIZONTAL_ALIGNMENT_RIGHT, 600, true, 10)
	Game.text(self, "“%s”" % f2, Vector2(680, 636), 18, Color(1, 1, 1, 0.75 * ta), HORIZONTAL_ALIGNMENT_RIGHT, 560, false, 3)
	# VS
	var vs := clampf((t - 0.25) / 0.2, 0.0, 1.0)
	var esc := 1.0 + 1.5 * (1.0 - vs) + 0.05 * sin(t * 8.0)
	Game.text(self, "VS", Vector2(440, 400), int(150 * esc), Color(1, 0.85, 0.3, vs), HORIZONTAL_ALIGNMENT_CENTER, 400, true, 20, Color(0.2, 0.05, 0.1, vs))
	# arena e etapa
	var topo = Game.ARENAS[Game.arena].nome if Game.arena >= 0 else "ARENA ALEATÓRIA"
	if Game.modo == "arcade" and not Game.arcade.is_empty():
		topo = "LUTA %d DE %d  •  %s" % [Game.arcade.etapa + 1, Game.arcade.escada.size(), topo]
		if eco: topo = "LUTA FINAL  •  O ECO SOMBRIO"
	draw_rect(Rect2(0, 18, 1280, 50), Color(0, 0, 0, 0.45 * ta))
	Game.text(self, topo, Vector2(0, 54), 28, Color(1, 0.9, 0.6, ta), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 6)
	if t > DURACAO - 0.3:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, clampf((t - DURACAO + 0.3) / 0.3, 0.0, 1.0)))
