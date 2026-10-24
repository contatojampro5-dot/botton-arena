extends Node
## Estado global do BOTTON ARENA: elenco, controles, troca de telas e sons.

const W := 1280.0
const H := 720.0

# ---------------------------------------------------------------------------
# ELENCO — para mudar nome, frase, cor ou atributos, edite aqui.
# atributos de 1 a 5: vel (velocidade), forca (dano), def (defesa)
# especial: "orbe" (projétil), "investida" (avanço com golpe),
#           "ascensao" (golpe para cima, bom contra pulo), "sombra" (teleporte)
# pulo_duplo: pode pular de novo no ar
# ---------------------------------------------------------------------------
const ROSTER := [
	{"id": "prototipo", "nome": "PROTÓTIPO", "nucleo": "Energia", "cor": Color("2f8cff"), "cor2": Color("e8eef7"),
		"frase": "Todo núcleo começa em algum lugar.", "vel": 3, "forca": 3, "def": 3, "especial": "orbe", "pulo_duplo": false},
	{"id": "chamas", "nome": "GUARDIÃO DAS CHAMAS", "nucleo": "Fogo", "cor": Color("ff5a1f"), "cor2": Color("ffc23a"),
		"frase": "O fogo não destrói apenas… ele também renova.", "vel": 3, "forca": 5, "def": 2, "especial": "investida", "pulo_duplo": false},
	{"id": "sombras", "nome": "ENTIDADE DAS SOMBRAS", "nucleo": "Sombra", "cor": Color("b44dff"), "cor2": Color("2a1640"),
		"frase": "A escuridão também é uma forma de luz.", "vel": 5, "forca": 3, "def": 2, "especial": "sombra", "pulo_duplo": false},
	{"id": "floresta", "nome": "GUARDIÃO DA FLORESTA", "nucleo": "Natureza", "cor": Color("6bd13b"), "cor2": Color("8a5a2b"),
		"frase": "A natureza também tem seus guerreiros.", "vel": 2, "forca": 3, "def": 4, "especial": "ascensao", "pulo_duplo": false},
	{"id": "ventos", "nome": "ESPÍRITO DOS VENTOS", "nucleo": "Vento", "cor": Color("8fd0ff"), "cor2": Color("f1f4f8"),
		"frase": "O vento não se vê, mas sempre está por perto.", "vel": 5, "forca": 2, "def": 2, "especial": "orbe", "pulo_duplo": true},
	{"id": "mares", "nome": "NÚCLEO DAS MARÉS", "nucleo": "Água", "cor": Color("3aa0ff"), "cor2": Color("d9b25a"),
		"frase": "O mar é vida, movimento e equilíbrio.", "vel": 3, "forca": 3, "def": 3, "especial": "orbe", "pulo_duplo": false},
	{"id": "glacial", "nome": "CORAÇÃO GLACIAL", "nucleo": "Gelo", "cor": Color("9fe6ff"), "cor2": Color("2a6fd6"),
		"frase": "O frio também é uma forma de proteção.", "vel": 2, "forca": 3, "def": 5, "especial": "orbe", "pulo_duplo": false},
	{"id": "solar", "nome": "RELÍQUIA SOLAR", "nucleo": "Luz", "cor": Color("ffc83a"), "cor2": Color("fff3c4"),
		"frase": "A luz não apenas ilumina o caminho… ela guia o coração.", "vel": 3, "forca": 3, "def": 3, "especial": "ascensao", "pulo_duplo": false},
	{"id": "colosso", "nome": "COLOSSO DE PEDRA", "nucleo": "Terra", "cor": Color("f0a33a"), "cor2": Color("7a6a55"),
		"frase": "A força da terra não se move com pressa, mas nunca falha.", "vel": 1, "forca": 5, "def": 5, "especial": "investida", "pulo_duplo": false},
	{"id": "steampunk", "nome": "AUTÔMATO STEAMPUNK", "nucleo": "Engrenagem", "cor": Color("3fe0b0"), "cor2": Color("b07a3a"),
		"frase": "Engrenagens também têm sonhos.", "vel": 2, "forca": 4, "def": 4, "especial": "orbe", "pulo_duplo": false},
	{"id": "cosmico", "nome": "VIAJANTE CÓSMICO", "nucleo": "Cosmos", "cor": Color("7a7cff"), "cor2": Color("e8c27a"),
		"frase": "O universo também tem um lar. E eu vou conhecê-lo.", "vel": 4, "forca": 3, "def": 2, "especial": "sombra", "pulo_duplo": true},
	{"id": "alquimista", "nome": "ALQUIMISTA PROIBIDO", "nucleo": "Alquimia", "cor": Color("8cff3a"), "cor2": Color("7a3ac8"),
		"frase": "O que é proibido nem sempre é mau.", "vel": 3, "forca": 4, "def": 2, "especial": "orbe", "pulo_duplo": false},
]

const ESPECIAL_NOME := {"orbe": "Orbe de Núcleo", "investida": "Investida", "ascensao": "Ascensão", "sombra": "Passo Sombrio"}

var modo := "versus"          # "versus" (2 jogadores) ou "cpu"
var escolha := [0, 1]          # índice no ROSTER de cada jogador
var vitorias := [0, 0]         # placar da sessão
var ai_both := false           # só para testes automáticos
var textures := {}
var font_title: Font
var font_body: Font
var _sfx := {}
var _players: Array[AudioStreamPlayer] = []
var _current: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	font_title = load("res://assets/fonts/LilitaOne-Regular.ttf")
	font_body = load("res://assets/fonts/Nunito.ttf")
	for c in ROSTER:
		textures[c.id] = load("res://assets/chars/%s.png" % c.id)
	for n in ["hit_light", "hit_heavy", "block", "whoosh", "special", "super", "select", "confirm", "ko", "perfect", "jump", "round"]:
		_sfx[n] = load("res://assets/sfx/%s.wav" % n)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_setup_input()

func tex(i: int) -> Texture2D:
	return textures[ROSTER[i].id]

func play(name: String, pitch := 1.0, vol_db := 0.0) -> void:
	if not _sfx.has(name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _sfx[name]
			p.pitch_scale = pitch
			p.volume_db = vol_db
			p.play()
			return

## Troca de tela. `script_path` é um script que estende Node/Node2D/Control.
func goto(script_path: String) -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	var root := get_tree().current_scene
	if _current and is_instance_valid(_current):
		_current.queue_free()
	var s: Script = load(script_path)
	_current = s.new()
	root.add_child.call_deferred(_current)

# ---------------------------------------------------------------------------
# CONTROLES — teclas físicas (funcionam igual no teclado ABNT2)
# Jogador 1: WASD andar/pular, F leve, G pesado, H especial, R defesa, T supremo, Shift esquerdo dash
# Jogador 2: setas andar/pular, K leve, L pesado, Ç especial, O defesa, P supremo, I dash
# Controle: o 1º controle é do Jogador 1, o 2º do Jogador 2.
# ---------------------------------------------------------------------------
const KEYS := {
	"p1": {"left": [KEY_A], "right": [KEY_D], "up": [KEY_W], "down": [KEY_S],
		"light": [KEY_F], "heavy": [KEY_G], "special": [KEY_H], "block": [KEY_R], "super": [KEY_T], "dash": [KEY_SHIFT],
		"confirm": [KEY_F, KEY_ENTER, KEY_SPACE], "back": [KEY_R, KEY_ESCAPE]},
	"p2": {"left": [KEY_LEFT], "right": [KEY_RIGHT], "up": [KEY_UP], "down": [KEY_DOWN],
		"light": [KEY_K], "heavy": [KEY_L], "special": [KEY_SEMICOLON], "block": [KEY_O], "super": [KEY_P], "dash": [KEY_I],
		"confirm": [KEY_K, KEY_KP_ENTER], "back": [KEY_O, KEY_BACKSPACE]},
}
const PAD := {"light": JOY_BUTTON_X, "heavy": JOY_BUTTON_Y, "special": JOY_BUTTON_B, "dash": JOY_BUTTON_RIGHT_SHOULDER,
	"block": JOY_BUTTON_LEFT_SHOULDER, "confirm": JOY_BUTTON_A, "back": JOY_BUTTON_B,
	"left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT, "up": JOY_BUTTON_DPAD_UP, "down": JOY_BUTTON_DPAD_DOWN}

func _setup_input() -> void:
	for pi in 2:
		var p := "p%d" % (pi + 1)
		for act in KEYS[p]:
			var a := "%s_%s" % [p, act]
			if not InputMap.has_action(a):
				InputMap.add_action(a, 0.4)
			for k in KEYS[p][act]:
				var e := InputEventKey.new()
				if k == KEY_SHIFT:
					e.physical_keycode = KEY_SHIFT
					e.location = KEY_LOCATION_LEFT
				else:
					e.physical_keycode = k
				InputMap.action_add_event(a, e)
			if PAD.has(act):
				var j := InputEventJoypadButton.new()
				j.button_index = PAD[act]
				j.device = pi
				InputMap.action_add_event(a, j)
		# analógico esquerdo e gatilho direito (supremo)
		for pair in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0], ["up", JOY_AXIS_LEFT_Y, -1.0], ["down", JOY_AXIS_LEFT_Y, 1.0], ["super", JOY_AXIS_TRIGGER_RIGHT, 1.0]]:
			var m := InputEventJoypadMotion.new()
			m.axis = pair[1]
			m.axis_value = pair[2]
			m.device = pi
			InputMap.action_add_event("%s_%s" % [p, pair[0]], m)
	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
		var e := InputEventKey.new()
		e.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("pause", e)
		for d in 2:
			var j := InputEventJoypadButton.new()
			j.button_index = JOY_BUTTON_START
			j.device = d
			InputMap.action_add_event("pause", j)

# ---------------------------------------------------------------------------
# Utilidades de desenho
# ---------------------------------------------------------------------------
static func stat_bar(ci: CanvasItem, pos: Vector2, valor: int, cor: Color) -> void:
	for i in 5:
		var r := Rect2(pos + Vector2(i * 26, 0), Vector2(22, 10))
		ci.draw_rect(r, cor if i < valor else Color(1, 1, 1, 0.12))

func text(ci: CanvasItem, s: String, pos: Vector2, size: int, cor := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, title := true, outline := 0, ocor := Color(0, 0, 0, 0.8)) -> void:
	var f: Font = font_title if title else font_body
	if outline > 0:
		ci.draw_string_outline(f, pos, s, align, width, size, outline, ocor)
	ci.draw_string(f, pos, s, align, width, size, cor)
