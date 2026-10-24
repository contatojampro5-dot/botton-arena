extends Node2D
## Tela inicial: "aperte para começar" e menu principal.

var bg: Node2D
var t := 0.0
var etapa := 0           # 0 = aperte iniciar, 1 = menu, 2 = controles
var sel := 0
const OPCOES := ["2 JOGADORES", "CONTRA CPU", "CONTROLES", "SAIR"]
var sprites: Array[Sprite2D] = []

func _ready() -> void:
	bg = preload("res://scripts/arena_bg.gd").new()
	add_child(bg)
	bg.dim = 0.25
	bg.z_index = -2
	# desfile de bottons ao fundo
	var n := Game.ROSTER.size()
	for i in n:
		var s := Sprite2D.new()
		s.texture = Game.tex(i)
		s.scale = Vector2.ONE * 0.36
		s.modulate = Color(1, 1, 1, 0.95)
		s.z_index = -1
		add_child(s)
		sprites.append(s)

func _process(delta: float) -> void:
	t += delta
	var n := sprites.size()
	for i in n:
		var s := sprites[i]
		var x := fposmod(i * (1280.0 + 200.0) / n + t * 40.0, 1280.0 + 200.0) - 100.0
		s.position = Vector2(x, 560 + 12 * sin(t * 2.0 + i))
		s.flip_h = false
	_input_logic()
	queue_redraw()

func _just(a: String) -> bool:
	return Input.is_action_just_pressed("p1_" + a) or Input.is_action_just_pressed("p2_" + a)

func _input_logic() -> void:
	match etapa:
		0:
			if _just("confirm") or Input.is_action_just_pressed("ui_accept"):
				etapa = 1
				Game.play("confirm")
		1:
			if _just("up"):
				sel = wrapi(sel - 1, 0, OPCOES.size()); Game.play("select")
			elif _just("down"):
				sel = wrapi(sel + 1, 0, OPCOES.size()); Game.play("select")
			elif _just("confirm"):
				Game.play("confirm")
				match sel:
					0:
						Game.modo = "versus"; Game.goto("res://scripts/select.gd")
					1:
						Game.modo = "cpu"; Game.goto("res://scripts/select.gd")
					2:
						etapa = 2
					3:
						get_tree().quit()
			elif _just("back"):
				etapa = 0
		2:
			if _just("confirm") or _just("back"):
				etapa = 1; Game.play("select")

func _draw() -> void:
	# logo
	var bob := 6 * sin(t * 1.6)
	Game.text(self, "BOTTON", Vector2(0, 205 + bob), 120, Color("fff6e0"), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 22, Color("2a1250"))
	Game.text(self, "ARENA", Vector2(0, 315 + bob), 120, Color("6fd0ff"), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 22, Color("10224a"))
	Game.text(self, "A BATALHA DOS NÚCLEOS", Vector2(0, 365), 30, Color("ffd36b"), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 8, Color("2a1250"))
	match etapa:
		0:
			var a := 0.55 + 0.45 * sin(t * 4.0)
			Game.text(self, "APERTE ENTER PARA COMEÇAR", Vector2(0, 450), 34, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 8)
		1:
			draw_rect(Rect2(470, 395, 340, 190), Color(0.05, 0.03, 0.12, 0.75))
			draw_rect(Rect2(470, 395, 340, 190), Color("6fd0ff"), false, 2)
			for i in OPCOES.size():
				var y := 435 + i * 42
				var on := i == sel
				if on:
					draw_rect(Rect2(486, y - 30, 308, 38), Color("6fd0ff", 0.22))
					Game.text(self, "▶", Vector2(498, y), 26, Color("ffd36b"))
				Game.text(self, OPCOES[i], Vector2(470, y), 30, Color("ffd36b") if on else Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 340)
		2:
			_draw_controles()
	Game.text(self, "v0.1 • protótipo", Vector2(16, 706), 16, Color(1, 1, 1, 0.4), HORIZONTAL_ALIGNMENT_LEFT, -1, false)

func _draw_controles() -> void:
	var r := Rect2(140, 385, 1000, 300)
	draw_rect(r, Color(0.04, 0.02, 0.1, 0.92))
	draw_rect(r, Color("6fd0ff"), false, 2)
	var linhas := [
		["", "JOGADOR 1", "JOGADOR 2"],
		["Andar / pular", "A  D  /  W", "←  →  /  ↑"],
		["Ataque leve", "F", "K"],
		["Ataque pesado", "G", "L"],
		["Especial", "H", "Ç"],
		["Defesa (segure)", "R", "O"],
		["Dash", "Shift esquerdo", "I"],
		["Supremo (Núcleo cheio)", "T", "P"],
	]
	for i in linhas.size():
		var y := 420 + i * 30
		var cor := Color("ffd36b") if i == 0 else Color.WHITE
		Game.text(self, linhas[i][0], Vector2(180, y), 22, cor, HORIZONTAL_ALIGNMENT_LEFT, -1, i == 0)
		Game.text(self, linhas[i][1], Vector2(560, y), 22, cor, HORIZONTAL_ALIGNMENT_CENTER, 260, i == 0)
		Game.text(self, linhas[i][2], Vector2(840, y), 22, cor, HORIZONTAL_ALIGNMENT_CENTER, 260, i == 0)
	Game.text(self, "Controles de videogame também funcionam (1º controle = J1, 2º = J2).  Enter ou F para voltar.", Vector2(140, 672), 17, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 1000, false)
