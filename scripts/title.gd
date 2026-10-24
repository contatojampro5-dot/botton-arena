extends Node2D
## Tela inicial: "aperte para começar", menu principal e controles — visual de vidro líquido.

var bg: Node2D
var t := 0.0
var etapa := 0           # 0 = aperte iniciar, 1 = menu, 2 = controles
var sel := 0
var sel_y := 0.0
const OPCOES := ["ARCADE", "2 JOGADORES", "CONTRA CPU", "TREINO", "GALERIA", "OPÇÕES", "CONTROLES", "SAIR"]
const DICAS := ["Enfrente 6 rivais e o misterioso Eco Sombrio.", "Dois jogadores no mesmo teclado ou com controles.",
	"Escolha seu botton e o rival da CPU.", "Teste combos e poderes contra um boneco.", "As fichas originais de cada botton.",
	"Volume, qualidade, dificuldade, tempo, rounds e controles.", "Teclas do teclado e botões do controle.", "Fechar o jogo."]
const ITEM_H := 42.0
const CARD := Rect2(480, 286, 320, 8 * 42.0 + 24)
var menu_k := 0.0        # 0 = tela inicial, 1 = menu aberto (desfila os bottons mais para baixo)
var sprites: Array[Sprite2D] = []
var g_card: Node2D
var g_pill: Node2D
var g_start: Node2D
var g_dica: Node2D
var g_ctrl: Node2D

func _ready() -> void:
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.arena = "santuario"
	add_child(bg)
	bg.dim = 0.15
	bg.z_index = -3
	Game.modo = "versus"
	Game.arcade = {}
	Game.eco = [false, false]
	Game.aplicar_controles()
	Game.music("menu")
	var n := Game.ROSTER.size()
	for i in n:
		var s := Sprite2D.new()
		s.texture = Game.tex(i)
		s.scale = Vector2.ONE * 0.34
		s.z_index = -2
		s.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(s)
		sprites.append(s)
	g_start = Game.glass(self, Rect2(400, 412, 480, 64), 32, Color(1, 1, 1, 0.12))
	g_card = Game.glass(self, CARD, 30, Color(1, 1, 1, 0.08))
	g_pill = Game.glass(self, Rect2(CARD.position.x + 14, CARD.position.y + 14, CARD.size.x - 28, ITEM_H - 4), 20, Color(1, 1, 1, 0.22))
	g_pill.glow = 0.7
	g_pill.glow_color = Color("7fd8ff")
	g_pill.margin = 18
	g_dica = Game.glass(self, Rect2(290, 662, 700, 40), 20, Color(1, 1, 1, 0.1))
	g_ctrl = Game.glass(self, Rect2(90, 120, 1100, 560), 30, Color(0.1, 0.1, 0.2, 0.25))
	sel_y = 0.0
	_visibilidade()

func _visibilidade() -> void:
	g_start.visible = etapa == 0
	g_card.visible = etapa == 1
	g_pill.visible = etapa == 1
	g_dica.visible = etapa == 1
	g_ctrl.visible = etapa == 2

func _process(delta: float) -> void:
	t += delta
	menu_k = move_toward(menu_k, 1.0 if etapa >= 1 else 0.0, delta * 4.0)
	var mk := menu_k * menu_k * (3.0 - 2.0 * menu_k)
	var n := sprites.size()
	for i in n:
		var s := sprites[i]
		var x := fposmod(i * (1280.0 + 200.0) / n + t * 40.0, 1280.0 + 200.0) - 100.0
		s.position = Vector2(x, 575 + 70.0 * mk + 10 * sin(t * 2.0 + i))
		s.modulate.a = 1.0 - 0.45 * mk
		s.visible = etapa != 2
	_input_logic()
	_visibilidade()
	sel_y = lerpf(sel_y, sel * ITEM_H, minf(1.0, delta * 16.0))
	g_pill.set_rect(Rect2(CARD.position.x + 12, CARD.position.y + 12 + sel_y, CARD.size.x - 24, ITEM_H - 4))
	g_start.glow = 0.35 + 0.25 * sin(t * 3.0)
	queue_redraw()

func _input_logic() -> void:
	var nv := Game.nav()
	match etapa:
		0:
			if Game.just("confirm") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("pause"):
				etapa = 1
				Game.play("confirm")
				_visibilidade()
		1:
			if nv.y != 0:
				sel = wrapi(sel + nv.y, 0, OPCOES.size()); Game.play("select")
			elif Game.just("confirm"):
				Game.play("confirm")
				match OPCOES[sel]:
					"ARCADE": _ir("arcade", "res://scripts/select.gd")
					"2 JOGADORES": _ir("versus", "res://scripts/select.gd")
					"CONTRA CPU": _ir("cpu", "res://scripts/select.gd")
					"TREINO": _ir("treino", "res://scripts/select.gd")
					"GALERIA": Game.goto("res://scripts/gallery.gd")
					"OPÇÕES": Game.goto("res://scripts/options.gd")
					"CONTROLES":
						etapa = 2
						_visibilidade()
					"SAIR": get_tree().quit()
			elif Game.just("back"):
				etapa = 0
				_visibilidade()
		2:
			if Game.just("confirm") or Game.just("back"):
				etapa = 1; Game.play("select")
				_visibilidade()

func _ir(modo: String, cena: String) -> void:
	Game.modo = modo
	Game.aplicar_controles()
	Game.goto(cena)

func _draw() -> void:
	if etapa != 2:
		_logo(-38.0 * menu_k * menu_k * (3.0 - 2.0 * menu_k))
	match etapa:
		0:
			var a := 0.75 + 0.25 * sin(t * 3.0)
			var txt := "PRESSIONE"
			var w1 := Game.text_width(txt, 24, "ui")
			var gw := Game.glyph_w("confirm", 0, 34.0)
			var w2 := Game.text_width("PARA COMEÇAR", 24, "ui")
			var x := 640.0 - (w1 + gw + w2 + 28.0) / 2.0
			Game.text_soft(self, txt, Vector2(x, 452), 24, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_LEFT, -1, "ui")
			Game.glyph(self, Vector2(x + w1 + 14.0, 444), "confirm", 0, 34.0)
			Game.text_soft(self, "PARA COMEÇAR", Vector2(x + w1 + gw + 28.0, 452), 24, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_LEFT, -1, "ui")
		1:
			for i in OPCOES.size():
				var y := CARD.position.y + 12 + i * ITEM_H + 28
				var on := i == sel
				Game.text_soft(self, OPCOES[i], Vector2(CARD.position.x, y), 22 if on else 20, Color.WHITE if on else Color(1, 1, 1, 0.78), HORIZONTAL_ALIGNMENT_CENTER, CARD.size.x, "ui", 0.35)
			Game.text(self, DICAS[sel], Vector2(290, 688), 17, Color(1, 1, 1, 0.92), HORIZONTAL_ALIGNMENT_CENTER, 700, "bold")
		2:
			_draw_controles()
	Game.text(self, Game.VERSAO, Vector2(18, 708), 15, Color(1, 1, 1, 0.45), HORIZONTAL_ALIGNMENT_LEFT, -1, "bold")

func _logo(dy: float) -> void:
	var bob := 5.0 * sin(t * 1.6)
	var c := Vector2(640, 175 + dy + bob)
	draw_texture_rect(Game.dot_tex, Rect2(c - Vector2(420, 150), Vector2(840, 300)), false, Color(0.45, 0.7, 1.0, 0.22))
	Game.text(self, "BOTTON", Vector2(0, 168 + dy + bob), 108, Color("fff7ea"), HORIZONTAL_ALIGNMENT_CENTER, 1280, "logo", 10, Color(0.1, 0.05, 0.25, 0.55))
	Game.text(self, "ARENA", Vector2(0, 262 + dy + bob), 108, Color("7fd8ff"), HORIZONTAL_ALIGNMENT_CENTER, 1280, "logo", 10, Color(0.03, 0.1, 0.25, 0.55))
	Game.text_soft(self, "A BATALHA DOS NÚCLEOS", Vector2(0, 302 + dy), 22, Color("ffe2a0"), HORIZONTAL_ALIGNMENT_CENTER, 1280, "ui", 0.5)

func _draw_controles() -> void:
	Game.text_soft(self, "CONTROLES", Vector2(0, 92), 40, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1280, "ui")
	var linhas := [
		["Andar / pular", "A  D  /  W", "←  →  /  ↑", "Direcional ou analógico"],
		["Ataque leve", "F", "K", "X  (□ no PlayStation)"],
		["Ataque pesado", "G", "L", "Y  (△)"],
		["Poder (especial)", "H", "Ç", "B  (○)"],
		["Poder + direção", "H + D / W / S", "Ç + → / ↑ / ↓", "B + direção"],
		["Defesa (segure)", "R", "O", "LB ou LT"],
		["Dash", "Shift esquerdo", "I", "RB"],
		["Supremo (Núcleo cheio)", "T", "P", "RT"],
		["Sobrecarga (50% Núcleo)", "G + H", "L + Ç", "Y + B"],
		["Pausa", "Esc", "Esc", "Start"],
	]
	var cols := [130.0, 470.0, 690.0, 910.0]
	var cab := ["", "TECLADO J1", "TECLADO J2", "CONTROLE"]
	for k in 4:
		Game.text(self, cab[k], Vector2(cols[k], 162), 17, Color("ffe2a0"), HORIZONTAL_ALIGNMENT_LEFT, -1, "ui")
	for i in linhas.size():
		var y := 202 + i * 40
		if i % 2 == 0:
			Game.rounded(self, Rect2(112, y - 27, 1056, 38), 14, Color(1, 1, 1, 0.05))
		for k in 4:
			Game.text(self, linhas[i][k], Vector2(cols[k], y), 18, Color.WHITE if k > 0 else Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_LEFT, -1, "bold" if k > 0 else "corpo")
	var pads := Input.get_connected_joypads()
	var txt := "Nenhum controle conectado" if pads.is_empty() else "Controles conectados: %d" % pads.size()
	if not pads.is_empty():
		txt += "   •   1 jogador: qualquer controle   •   2 jogadores: 1º controle = J1, 2º = J2" + (" (trocado)" if Game.opcoes.troca_controles else "")
	Game.text(self, txt, Vector2(0, 618), 16, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER, 1280, "bold")
	Game.prompts(self, Vector2(640, 654), [["back", "Voltar"]])
