extends Node2D
## Tela inicial: "aperte para começar" e menu principal.

var bg: Node2D
var t := 0.0
var etapa := 0           # 0 = aperte iniciar, 1 = menu, 2 = controles
var sel := 0
const OPCOES := ["ARCADE", "2 JOGADORES", "CONTRA CPU", "TREINO", "OPÇÕES", "CONTROLES", "SAIR"]
const DICAS := ["Enfrente 6 rivais e o misterioso Eco Sombrio.", "Dois jogadores no mesmo teclado ou com controles.",
	"Escolha seu botton e o rival da CPU.", "Teste combos à vontade contra um boneco.", "Volume, dificuldade da CPU, tempo e rounds.",
	"Veja as teclas de cada jogador.", "Fechar o jogo."]
var sprites: Array[Sprite2D] = []

func _ready() -> void:
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.arena = "santuario"
	add_child(bg)
	bg.dim = 0.25
	bg.z_index = -2
	Game.modo = "versus"
	Game.arcade = {}
	Game.eco = [false, false]
	Game.music("menu")
	# desfile de bottons ao fundo
	var n := Game.ROSTER.size()
	for i in n:
		var s := Sprite2D.new()
		s.texture = Game.tex(i)
		s.scale = Vector2.ONE * 0.36
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
	_input_logic()
	queue_redraw()

func _input_logic() -> void:
	match etapa:
		0:
			if Game.just("confirm") or Input.is_action_just_pressed("ui_accept"):
				etapa = 1
				Game.play("confirm")
		1:
			if Game.just("up"):
				sel = wrapi(sel - 1, 0, OPCOES.size()); Game.play("select")
			elif Game.just("down"):
				sel = wrapi(sel + 1, 0, OPCOES.size()); Game.play("select")
			elif Game.just("confirm"):
				Game.play("confirm")
				match OPCOES[sel]:
					"ARCADE":
						Game.modo = "arcade"; Game.goto("res://scripts/select.gd")
					"2 JOGADORES":
						Game.modo = "versus"; Game.goto("res://scripts/select.gd")
					"CONTRA CPU":
						Game.modo = "cpu"; Game.goto("res://scripts/select.gd")
					"TREINO":
						Game.modo = "treino"; Game.goto("res://scripts/select.gd")
					"OPÇÕES":
						Game.goto("res://scripts/options.gd")
					"CONTROLES":
						etapa = 2
					"SAIR":
						get_tree().quit()
			elif Game.just("back"):
				etapa = 0
		2:
			if Game.just("confirm") or Game.just("back"):
				etapa = 1; Game.play("select")

func _draw() -> void:
	var bob := 6 * sin(t * 1.6)
	var top := -40.0 if etapa == 1 else 0.0
	Game.text(self, "BOTTON", Vector2(0, 175 + bob + top), 112, Color("fff6e0"), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 22, Color("2a1250"))
	Game.text(self, "ARENA", Vector2(0, 278 + bob + top), 112, Color("6fd0ff"), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 22, Color("10224a"))
	Game.text(self, "A BATALHA DOS NÚCLEOS", Vector2(0, 325 + top), 28, Color("ffd36b"), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 8, Color("2a1250"))
	match etapa:
		0:
			var a := 0.55 + 0.45 * sin(t * 4.0)
			Game.text(self, "APERTE ENTER PARA COMEÇAR", Vector2(0, 430), 34, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 8)
		1:
			var r := Rect2(460, 305, 360, 330)
			draw_rect(r, Color(0.05, 0.03, 0.12, 0.82))
			draw_rect(r, Color("6fd0ff"), false, 2)
			for i in OPCOES.size():
				var y := 342 + i * 42
				var on := i == sel
				if on:
					draw_rect(Rect2(476, y - 30, 328, 38), Color("6fd0ff", 0.22))
					Game.text(self, "▶", Vector2(488, y), 24, Color("ffd36b"))
				Game.text(self, OPCOES[i], Vector2(460, y), 28, Color("ffd36b") if on else Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 360)
			draw_rect(Rect2(340, 645, 600, 34), Color(0.05, 0.03, 0.12, 0.7))
			Game.text(self, DICAS[sel], Vector2(340, 668), 18, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 600, false)
		2:
			_draw_controles()
	Game.text(self, Game.VERSAO + " • protótipo", Vector2(16, 706), 16, Color(1, 1, 1, 0.4), HORIZONTAL_ALIGNMENT_LEFT, -1, false)

func _draw_controles() -> void:
	var r := Rect2(140, 345, 1000, 340)
	draw_rect(r, Color(0.04, 0.02, 0.1, 0.94))
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
		["Sobrecarga (50% de Núcleo)", "G + H", "L + Ç"],
	]
	for i in linhas.size():
		var y := 378 + i * 30
		var cor := Color("ffd36b") if i == 0 else Color.WHITE
		Game.text(self, linhas[i][0], Vector2(180, y), 22, cor, HORIZONTAL_ALIGNMENT_LEFT, -1, i == 0)
		Game.text(self, linhas[i][1], Vector2(560, y), 22, cor, HORIZONTAL_ALIGNMENT_CENTER, 260, i == 0)
		Game.text(self, linhas[i][2], Vector2(840, y), 22, cor, HORIZONTAL_ALIGNMENT_CENTER, 260, i == 0)
	Game.text(self, "Dash também com dois toques na direção. Controles de videogame funcionam (1º = J1, 2º = J2). Esc pausa a luta.", Vector2(140, 672), 16, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 1000, false)
