extends Node
## Estado global do BOTTON ARENA: elenco, arenas, controles, opções, música, troca de telas e sons.

const W := 1280.0
const H := 720.0
const VERSAO := "v0.2"

# ---------------------------------------------------------------------------
# ELENCO — para mudar nome, frase, cor ou atributos, edite aqui.
# atributos de 1 a 5: vel (velocidade), forca (dano), def (defesa)
# especial / supremo: o golpe próprio de cada botton (programado em fighter.gd)
# alcance: onde o especial funciona melhor (a CPU usa isso)
# casa: arena do personagem no modo Arcade
# ---------------------------------------------------------------------------
const ROSTER := [
	{"id": "prototipo", "nome": "PROTÓTIPO", "nucleo": "Energia", "cor": Color("2f8cff"), "cor2": Color("e8eef7"),
		"frase": "Todo núcleo começa em algum lugar.", "vel": 3, "forca": 3, "def": 3, "pulo_duplo": false, "casa": "santuario",
		"especial": "orbe", "especial_nome": "Orbe de Núcleo", "especial_desc": "Dispara uma esfera de energia em linha reta.", "alcance": "longe",
		"supremo": "raio", "supremo_nome": "SOBRECARGA TOTAL", "supremo_desc": "Um raio de energia que atravessa a arena inteira."},
	{"id": "chamas", "nome": "GUARDIÃO DAS CHAMAS", "nucleo": "Fogo", "cor": Color("ff5a1f"), "cor2": Color("ffc23a"),
		"frase": "O fogo não destrói apenas… ele também renova.", "vel": 3, "forca": 5, "def": 2, "pulo_duplo": false, "casa": "vulcao",
		"especial": "investida", "especial_nome": "Investida Ígnea", "especial_desc": "Avança envolto em chamas e arremessa o rival.", "alcance": "medio",
		"supremo": "erupcao", "supremo_nome": "ERUPÇÃO", "supremo_desc": "Colunas de fogo explodem do chão até o rival."},
	{"id": "sombras", "nome": "ENTIDADE DAS SOMBRAS", "nucleo": "Sombra", "cor": Color("b44dff"), "cor2": Color("2a1640"),
		"frase": "A escuridão também é uma forma de luz.", "vel": 5, "forca": 3, "def": 2, "pulo_duplo": false, "casa": "cosmos",
		"especial": "sombra", "especial_nome": "Passo Sombrio", "especial_desc": "Some e reaparece atrás do rival com um golpe.", "alcance": "medio",
		"supremo": "ilusao", "supremo_nome": "MIL SOMBRAS", "supremo_desc": "Sombras atacam o rival de todos os lados."},
	{"id": "floresta", "nome": "GUARDIÃO DA FLORESTA", "nucleo": "Natureza", "cor": Color("6bd13b"), "cor2": Color("8a5a2b"),
		"frase": "A natureza também tem seus guerreiros.", "vel": 2, "forca": 3, "def": 4, "pulo_duplo": false, "casa": "floresta",
		"especial": "raizes", "especial_nome": "Raízes Presas", "especial_desc": "Raízes brotam do chão à frente e lançam o rival.", "alcance": "medio",
		"supremo": "furia", "supremo_nome": "FÚRIA DA FLORESTA", "supremo_desc": "Uma árvore colossal nasce embaixo do rival."},
	{"id": "ventos", "nome": "ESPÍRITO DOS VENTOS", "nucleo": "Vento", "cor": Color("8fd0ff"), "cor2": Color("f1f4f8"),
		"frase": "O vento não se vê, mas sempre está por perto.", "vel": 5, "forca": 2, "def": 2, "pulo_duplo": true, "casa": "glacial",
		"especial": "tornado", "especial_nome": "Tornado", "especial_desc": "Um redemoinho lento que levanta o rival várias vezes.", "alcance": "longe",
		"supremo": "ciclone", "supremo_nome": "CICLONE", "supremo_desc": "Um ciclone gigante varre a arena."},
	{"id": "mares", "nome": "NÚCLEO DAS MARÉS", "nucleo": "Água", "cor": Color("3aa0ff"), "cor2": Color("d9b25a"),
		"frase": "O mar é vida, movimento e equilíbrio.", "vel": 3, "forca": 3, "def": 3, "pulo_duplo": false, "casa": "recife",
		"especial": "onda", "especial_nome": "Onda", "especial_desc": "Uma onda corre pelo chão (dá para pular por cima).", "alcance": "longe",
		"supremo": "tsunami", "supremo_nome": "TSUNAMI", "supremo_desc": "Uma onda enorme cobre a arena inteira."},
	{"id": "glacial", "nome": "CORAÇÃO GLACIAL", "nucleo": "Gelo", "cor": Color("9fe6ff"), "cor2": Color("2a6fd6"),
		"frase": "O frio também é uma forma de proteção.", "vel": 2, "forca": 3, "def": 5, "pulo_duplo": false, "casa": "glacial",
		"especial": "lanca", "especial_nome": "Lança de Gelo", "especial_desc": "Projétil rápido que congela o rival por um instante.", "alcance": "longe",
		"supremo": "era_glacial", "supremo_nome": "ERA GLACIAL", "supremo_desc": "Cristais brotam pelo chão, congelam e estilhaçam."},
	{"id": "solar", "nome": "RELÍQUIA SOLAR", "nucleo": "Luz", "cor": Color("ffc83a"), "cor2": Color("fff3c4"),
		"frase": "A luz não apenas ilumina o caminho… ela guia o coração.", "vel": 3, "forca": 3, "def": 3, "pulo_duplo": false, "casa": "santuario",
		"especial": "ascensao", "especial_nome": "Ascensão Solar", "especial_desc": "Golpe para cima, invencível no início. Ótimo contra pulos.", "alcance": "anti_aereo",
		"supremo": "julgamento", "supremo_nome": "JULGAMENTO SOLAR", "supremo_desc": "Raios de luz caem do céu sobre o rival."},
	{"id": "colosso", "nome": "COLOSSO DE PEDRA", "nucleo": "Terra", "cor": Color("f0a33a"), "cor2": Color("7a6a55"),
		"frase": "A força da terra não se move com pressa, mas nunca falha.", "vel": 1, "forca": 5, "def": 5, "pulo_duplo": false, "casa": "vulcao",
		"especial": "avalanche", "especial_nome": "Avalanche", "especial_desc": "Investida pesada que aguenta um golpe sem parar.", "alcance": "medio",
		"supremo": "terremoto", "supremo_nome": "TERREMOTO", "supremo_desc": "Abala o chão inteiro (pule!) e faz chover pedras."},
	{"id": "steampunk", "nome": "AUTÔMATO STEAMPUNK", "nucleo": "Engrenagem", "cor": Color("3fe0b0"), "cor2": Color("b07a3a"),
		"frase": "Engrenagens também têm sonhos.", "vel": 2, "forca": 4, "def": 4, "pulo_duplo": false, "casa": "oficina",
		"especial": "serra", "especial_nome": "Engrenagem Serra", "especial_desc": "Lança uma serra que vai e volta como bumerangue.", "alcance": "medio",
		"supremo": "canhao", "supremo_nome": "CANHÃO A VAPOR", "supremo_desc": "Uma rajada de balas de engrenagem."},
	{"id": "cosmico", "nome": "VIAJANTE CÓSMICO", "nucleo": "Cosmos", "cor": Color("7a7cff"), "cor2": Color("e8c27a"),
		"frase": "O universo também tem um lar. E eu vou conhecê-lo.", "vel": 4, "forca": 3, "def": 2, "pulo_duplo": true, "casa": "cosmos",
		"especial": "portal", "especial_nome": "Portal Estelar", "especial_desc": "Entra num portal e cai em cima do rival.", "alcance": "longe",
		"supremo": "meteoros", "supremo_nome": "CHUVA DE METEOROS", "supremo_desc": "Meteoros despencam do céu."},
	{"id": "alquimista", "nome": "ALQUIMISTA PROIBIDO", "nucleo": "Alquimia", "cor": Color("8cff3a"), "cor2": Color("7a3ac8"),
		"frase": "O que é proibido nem sempre é mau.", "vel": 3, "forca": 4, "def": 2, "pulo_duplo": false, "casa": "oficina",
		"especial": "frasco", "especial_nome": "Frasco Tóxico", "especial_desc": "Arremessa um frasco que deixa uma nuvem venenosa.", "alcance": "medio",
		"supremo": "transmutacao", "supremo_nome": "TRANSMUTAÇÃO", "supremo_desc": "Um círculo alquímico explode sob o rival."},
]

# ---------------------------------------------------------------------------
# ARENAS — desenhadas por código em arena_bg.gd
# ---------------------------------------------------------------------------
const ARENAS := [
	{"id": "santuario", "nome": "SANTUÁRIO DOS NÚCLEOS", "desc": "O templo onde os Núcleos despertam.", "musica": "luta1", "cor": Color("6fb8ff")},
	{"id": "vulcao", "nome": "CRATERA ARDENTE", "desc": "Rios de lava e brasas que nunca se apagam.", "musica": "luta2", "cor": Color("ff7a2a")},
	{"id": "floresta", "nome": "FLORESTA ANCESTRAL", "desc": "Árvores antigas guardam a luz dos vaga-lumes.", "musica": "luta3", "cor": Color("8fe05a")},
	{"id": "glacial", "nome": "PICO CONGELADO", "desc": "Neve eterna sob a aurora boreal.", "musica": "luta4", "cor": Color("9fe6ff")},
	{"id": "recife", "nome": "COSTA DAS MARÉS", "desc": "Um pôr do sol à beira do oceano.", "musica": "luta3", "cor": Color("5ad0ff")},
	{"id": "cosmos", "nome": "ÓRBITA ESTELAR", "desc": "Uma plataforma flutuando entre planetas.", "musica": "luta5", "cor": Color("9a7cff")},
	{"id": "oficina", "nome": "FÁBRICA A VAPOR", "desc": "Engrenagens gigantes que nunca param.", "musica": "luta6", "cor": Color("ffb347")},
]

# modo: "versus" (2 jogadores), "cpu", "treino", "arcade"
var modo := "versus"
var escolha := [0, 1]          # índice no ROSTER de cada jogador
var arena := 0                 # índice em ARENAS (-1 = aleatória)
var vitorias := [0, 0]         # placar da sessão
var ai_both := false           # só para testes automáticos
var eco := [false, false]      # chefe "Eco Sombrio" do Arcade
var arcade := {}               # estado do modo Arcade
var treino := {"boneco": 0, "nucleo_inf": true}
const TREINO_BONECO := ["PARADO", "DEFENDE", "PULA", "CPU"]

# opções (salvas em user://opcoes.cfg)
var opcoes := {"musica": 7, "efeitos": 8, "cpu": 1, "tempo": 1, "rounds": 1, "tela_cheia": false}
const CPU_NOMES := ["FÁCIL", "NORMAL", "DIFÍCIL"]
const TEMPO_OPCOES := [60, 99, 0]         # 0 = infinito
const ROUNDS_OPCOES := [1, 2, 3]          # rounds para vencer

var textures := {}
var rig_tex := {}
var rig_data := {}
var font_title: Font
var font_body: Font
var _sfx := {}
var _players: Array[AudioStreamPlayer] = []
var _music: Array[AudioStreamPlayer] = []
var _music_cur := ""
var _music_slot := 0
var _music_tracks := {}
var _current: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	font_title = load("res://assets/fonts/LilitaOne-Regular.ttf")
	font_body = load("res://assets/fonts/Nunito.ttf")
	var f := FileAccess.open("res://assets/rig/rig.json", FileAccess.READ)
	rig_data = JSON.parse_string(f.get_as_text())
	for c in ROSTER:
		textures[c.id] = load("res://assets/chars/%s.png" % c.id)
		rig_tex[c.id] = {
			"body": load("res://assets/rig/%s_body.png" % c.id),
			"armL": load("res://assets/rig/%s_armL.png" % c.id),
			"armR": load("res://assets/rig/%s_armR.png" % c.id)}
	for n in ["hit_light", "hit_heavy", "block", "whoosh", "special", "super", "select", "confirm", "ko", "perfect", "jump", "round",
			"fire", "ice", "wind", "water", "quake", "zap", "poison", "gear", "portal", "shadow", "explode", "overload", "beam"]:
		var p := "res://assets/sfx/%s.wav" % n
		if ResourceLoader.exists(p):
			_sfx[n] = load(p)
	_setup_audio()
	_setup_input()
	carregar_opcoes()

func tex(i: int) -> Texture2D:
	return textures[ROSTER[i].id]

func arena_index(id: String) -> int:
	for i in ARENAS.size():
		if ARENAS[i].id == id: return i
	return 0

# ---------------------------------------------------------------------------
# ÁUDIO
# ---------------------------------------------------------------------------
func _setup_audio() -> void:
	for bus in ["Musica", "Efeitos"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = "Efeitos"
		add_child(p)
		_players.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.bus = "Musica"
		m.volume_db = -60.0
		add_child(m)
		_music.append(m)

func play(name: String, pitch := 1.0, vol_db := 0.0) -> void:
	if not _sfx.has(name):
		return
	var best: AudioStreamPlayer = null
	for p in _players:
		if not p.playing:
			best = p
			break
	if best == null:
		best = _players[randi() % _players.size()]
	best.stream = _sfx[name]
	best.pitch_scale = pitch
	best.volume_db = vol_db
	best.play()

## Toca uma música (com transição suave). "" para silêncio.
func music(name: String, fade := 0.6) -> void:
	if name == _music_cur:
		return
	_music_cur = name
	var old := _music[_music_slot]
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -60.0, fade)
		tw.tween_callback(old.stop)
	if name == "":
		return
	var path := "res://assets/music/%s.ogg" % name
	if not ResourceLoader.exists(path):
		return
	if not _music_tracks.has(name):
		var s: AudioStream = load(path)
		if s is AudioStreamOggVorbis:
			s.loop = name != "vitoria" and name != "fim"
		_music_tracks[name] = s
	_music_slot = 1 - _music_slot
	var nw := _music[_music_slot]
	nw.stream = _music_tracks[name]
	nw.volume_db = -40.0
	nw.play()
	var tw2 := create_tween()
	tw2.tween_property(nw, "volume_db", 0.0, fade)

func aplicar_volumes() -> void:
	var mi := AudioServer.get_bus_index("Musica")
	var ei := AudioServer.get_bus_index("Efeitos")
	AudioServer.set_bus_volume_db(mi, linear_to_db(maxf(0.0001, opcoes.musica / 10.0)) - 4.0)
	AudioServer.set_bus_mute(mi, opcoes.musica == 0)
	AudioServer.set_bus_volume_db(ei, linear_to_db(maxf(0.0001, opcoes.efeitos / 10.0)))
	AudioServer.set_bus_mute(ei, opcoes.efeitos == 0)

func carregar_opcoes() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://opcoes.cfg") == OK:
		for k in opcoes.keys():
			opcoes[k] = cfg.get_value("opcoes", k, opcoes[k])
	aplicar_volumes()
	aplicar_tela()

func salvar_opcoes() -> void:
	var cfg := ConfigFile.new()
	for k in opcoes.keys():
		cfg.set_value("opcoes", k, opcoes[k])
	cfg.save("user://opcoes.cfg")
	aplicar_volumes()
	aplicar_tela()

func aplicar_tela() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var alvo := DisplayServer.WINDOW_MODE_FULLSCREEN if opcoes.tela_cheia else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != alvo:
		DisplayServer.window_set_mode(alvo)

func tempo_round() -> float:
	return float(TEMPO_OPCOES[opcoes.tempo])

func rounds_para_vencer() -> int:
	return ROUNDS_OPCOES[opcoes.rounds]

# ---------------------------------------------------------------------------
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
# ARCADE
# ---------------------------------------------------------------------------
func arcade_iniciar(personagem: int) -> void:
	var outros := []
	for i in ROSTER.size():
		if i != personagem: outros.append(i)
	outros.shuffle()
	var escada: Array = outros.slice(0, 6)
	escada.append(personagem)   # luta final: o Eco Sombrio
	arcade = {"char": personagem, "escada": escada, "etapa": 0, "continues": 0, "inicio": Time.get_ticks_msec(), "pontos": 0}
	modo = "arcade"
	arcade_preparar()

func arcade_preparar() -> void:
	var etapa: int = arcade.etapa
	var rival: int = arcade.escada[etapa]
	escolha = [arcade.char, rival]
	eco = [false, etapa == arcade.escada.size() - 1]
	arena = arena_index(ROSTER[rival].casa) if not eco[1] else arena_index("cosmos")

func arcade_nivel_cpu() -> int:
	if arcade.is_empty(): return opcoes.cpu
	var etapa: int = arcade.etapa
	return clampi(etapa / 2, 0, 2) if etapa < 6 else 2

# ---------------------------------------------------------------------------
# CONTROLES — teclas físicas (funcionam igual no teclado ABNT2)
# Jogador 1: WASD andar/pular, F leve, G pesado, H especial, R defesa, T supremo, Shift esquerdo dash
# Jogador 2: setas andar/pular, K leve, L pesado, Ç especial, O defesa, P supremo, I dash
# Sobrecarga: pesado + especial juntos (com 50% de Núcleo)
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

func just(a: String) -> bool:
	return Input.is_action_just_pressed("p1_" + a) or Input.is_action_just_pressed("p2_" + a)

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

## Texto com quebra de linha automática (para descrições)
func text_wrap(ci: CanvasItem, s: String, pos: Vector2, width: float, size: int, cor := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT, title := false) -> void:
	var f: Font = font_title if title else font_body
	ci.draw_multiline_string(f, pos, s, align, width, size, -1, cor)

## Desenha a arte de um botton (espelhada se flip)
func draw_char(ci: CanvasItem, i: int, centro: Vector2, altura: float, flip := false, mod := Color.WHITE) -> void:
	if altura < 2.0:
		return
	var tx := tex(i)
	var s := tx.get_size()
	var k := altura / s.y
	var sz := s * k
	ci.draw_set_transform(centro, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
	ci.draw_texture_rect(tx, Rect2(-sz / 2, sz), false, mod)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
