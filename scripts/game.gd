extends Node
## Estado global do BOTTON ARENA: elenco, tipos, arenas, controles (teclado e controle),
## opções, qualidade, música, vidro líquido, troca de telas e utilidades de desenho.

const W := 1280.0
const H := 720.0
const VERSAO := "v0.3"
const Powers := preload("res://scripts/powers.gd")

# ---------------------------------------------------------------------------
# TIPOS (estilo Pokémon): cada tipo é forte contra outros dois.
# Poder de um tipo forte contra o tipo do rival causa +25% de dano: "É SUPER EFETIVO!"
# ---------------------------------------------------------------------------
const TIPOS := {
	"energia": {"nome": "Energia", "cor": Color("3aa8ff"), "forte": ["agua", "metal"]},
	"fogo": {"nome": "Fogo", "cor": Color("ff6a2a"), "forte": ["planta", "gelo"]},
	"sombra": {"nome": "Sombra", "cor": Color("b45cff"), "forte": ["luz", "cosmos"]},
	"planta": {"nome": "Planta", "cor": Color("6bd13b"), "forte": ["agua", "pedra"]},
	"vento": {"nome": "Vento", "cor": Color("9fdcff"), "forte": ["veneno", "sombra"]},
	"agua": {"nome": "Água", "cor": Color("3a8cff"), "forte": ["fogo", "pedra"]},
	"gelo": {"nome": "Gelo", "cor": Color("aef0ff"), "forte": ["planta", "vento"]},
	"luz": {"nome": "Luz", "cor": Color("ffd23a"), "forte": ["sombra", "veneno"]},
	"pedra": {"nome": "Pedra", "cor": Color("d8a060"), "forte": ["energia", "fogo"]},
	"metal": {"nome": "Metal", "cor": Color("3fe0b0"), "forte": ["gelo", "pedra"]},
	"cosmos": {"nome": "Cosmos", "cor": Color("8a7cff"), "forte": ["luz", "energia"]},
	"veneno": {"nome": "Veneno", "cor": Color("9cff4a"), "forte": ["planta", "agua"]},
}

# ---------------------------------------------------------------------------
# ELENCO — para mudar nome, frase, cor, atributos ou poderes, edite aqui.
# atributos de 1 a 5: vel (velocidade), forca (dano), def (defesa)
# poderes: [neutro (H), frente (→+H), cima (↑+H), baixo (↓+H)] — veja scripts/powers.gd
# ---------------------------------------------------------------------------
const ROSTER := [
	{"id": "prototipo", "nome": "PROTÓTIPO", "nucleo": "Energia", "tipo": "energia", "cor": Color("2f8cff"), "cor2": Color("e8eef7"),
		"frase": "Todo núcleo começa em algum lugar.", "vel": 3, "forca": 3, "def": 3, "pulo_duplo": false, "casa": "santuario",
		"poderes": ["orbe", "rajada", "propulsor", "mina"],
		"supremo": "raio", "supremo_nome": "SOBRECARGA TOTAL", "supremo_desc": "Um raio de energia que atravessa a arena inteira."},
	{"id": "chamas", "nome": "GUARDIÃO DAS CHAMAS", "nucleo": "Fogo", "tipo": "fogo", "cor": Color("ff5a1f"), "cor2": Color("ffc23a"),
		"frase": "O fogo não destrói apenas… ele também renova.", "vel": 3, "forca": 5, "def": 2, "pulo_duplo": false, "casa": "vulcao",
		"poderes": ["bola_fogo", "investida", "coluna_fogo", "brasas"],
		"supremo": "erupcao", "supremo_nome": "ERUPÇÃO", "supremo_desc": "Colunas de fogo explodem do chão até o rival."},
	{"id": "sombras", "nome": "ENTIDADE DAS SOMBRAS", "nucleo": "Sombra", "tipo": "sombra", "cor": Color("b44dff"), "cor2": Color("2a1640"),
		"frase": "A escuridão também é uma forma de luz.", "vel": 5, "forca": 3, "def": 2, "pulo_duplo": false, "casa": "cosmos",
		"poderes": ["esfera_sombria", "sombra", "garra", "poco"],
		"supremo": "ilusao", "supremo_nome": "MIL SOMBRAS", "supremo_desc": "Sombras atacam o rival de todos os lados."},
	{"id": "floresta", "nome": "GUARDIÃO DA FLORESTA", "nucleo": "Natureza", "tipo": "planta", "cor": Color("6bd13b"), "cor2": Color("8a5a2b"),
		"frase": "A natureza também tem seus guerreiros.", "vel": 2, "forca": 3, "def": 4, "pulo_duplo": false, "casa": "floresta",
		"poderes": ["folha", "raizes", "broto", "semente"],
		"supremo": "furia", "supremo_nome": "FÚRIA DA FLORESTA", "supremo_desc": "Uma árvore colossal nasce embaixo do rival."},
	{"id": "ventos", "nome": "ESPÍRITO DOS VENTOS", "nucleo": "Vento", "tipo": "vento", "cor": Color("8fd0ff"), "cor2": Color("f1f4f8"),
		"frase": "O vento não se vê, mas sempre está por perto.", "vel": 5, "forca": 2, "def": 2, "pulo_duplo": true, "casa": "glacial",
		"poderes": ["lamina_ar", "tornado", "rajada_asc", "corrente"],
		"supremo": "ciclone", "supremo_nome": "CICLONE", "supremo_desc": "Um ciclone gigante varre a arena."},
	{"id": "mares", "nome": "NÚCLEO DAS MARÉS", "nucleo": "Água", "tipo": "agua", "cor": Color("3aa0ff"), "cor2": Color("d9b25a"),
		"frase": "O mar é vida, movimento e equilíbrio.", "vel": 3, "forca": 3, "def": 3, "pulo_duplo": false, "casa": "recife",
		"poderes": ["hidro_jato", "onda", "geiser", "bolhas"],
		"supremo": "tsunami", "supremo_nome": "TSUNAMI", "supremo_desc": "Uma onda enorme cobre a arena inteira."},
	{"id": "glacial", "nome": "CORAÇÃO GLACIAL", "nucleo": "Gelo", "tipo": "gelo", "cor": Color("9fe6ff"), "cor2": Color("2a6fd6"),
		"frase": "O frio também é uma forma de proteção.", "vel": 2, "forca": 3, "def": 5, "pulo_duplo": false, "casa": "glacial",
		"poderes": ["lanca", "rajada_glacial", "pico", "chao_gelo"],
		"supremo": "era_glacial", "supremo_nome": "ERA GLACIAL", "supremo_desc": "Cristais brotam pelo chão, congelam e estilhaçam."},
	{"id": "solar", "nome": "RELÍQUIA SOLAR", "nucleo": "Luz", "tipo": "luz", "cor": Color("ffc83a"), "cor2": Color("fff3c4"),
		"frase": "A luz não apenas ilumina o caminho… ela guia o coração.", "vel": 3, "forca": 3, "def": 3, "pulo_duplo": false, "casa": "santuario",
		"poderes": ["disco", "raio_luz", "ascensao", "clarao"],
		"supremo": "julgamento", "supremo_nome": "JULGAMENTO SOLAR", "supremo_desc": "Raios de luz caem do céu sobre o rival."},
	{"id": "colosso", "nome": "COLOSSO DE PEDRA", "nucleo": "Terra", "tipo": "pedra", "cor": Color("f0a33a"), "cor2": Color("7a6a55"),
		"frase": "A força da terra não se move com pressa, mas nunca falha.", "vel": 1, "forca": 5, "def": 5, "pulo_duplo": false, "casa": "vulcao",
		"poderes": ["pedra", "avalanche", "pilar", "pisao"],
		"supremo": "terremoto", "supremo_nome": "TERREMOTO", "supremo_desc": "Abala o chão inteiro (pule!) e faz chover pedras."},
	{"id": "steampunk", "nome": "AUTÔMATO STEAMPUNK", "nucleo": "Engrenagem", "tipo": "metal", "cor": Color("3fe0b0"), "cor2": Color("b07a3a"),
		"frase": "Engrenagens também têm sonhos.", "vel": 2, "forca": 4, "def": 4, "pulo_duplo": false, "casa": "oficina",
		"poderes": ["serra", "vapor", "martelo", "torreta"],
		"supremo": "canhao", "supremo_nome": "CANHÃO A VAPOR", "supremo_desc": "Uma rajada de balas de engrenagem."},
	{"id": "cosmico", "nome": "VIAJANTE CÓSMICO", "nucleo": "Cosmos", "tipo": "cosmos", "cor": Color("7a7cff"), "cor2": Color("e8c27a"),
		"frase": "O universo também tem um lar. E eu vou conhecê-lo.", "vel": 4, "forca": 3, "def": 2, "pulo_duplo": true, "casa": "cosmos",
		"poderes": ["estrela", "portal", "aneis", "buraco_negro"],
		"supremo": "meteoros", "supremo_nome": "CHUVA DE METEOROS", "supremo_desc": "Meteoros despencam do céu."},
	{"id": "alquimista", "nome": "ALQUIMISTA PROIBIDO", "nucleo": "Alquimia", "tipo": "veneno", "cor": Color("8cff3a"), "cor2": Color("7a3ac8"),
		"frase": "O que é proibido nem sempre é mau.", "vel": 3, "forca": 4, "def": 2, "pulo_duplo": false, "casa": "oficina",
		"poderes": ["frasco", "acido", "geiser_acido", "runa"],
		"supremo": "transmutacao", "supremo_nome": "TRANSMUTAÇÃO", "supremo_desc": "Um círculo alquímico explode sob o rival."},
]

# ---------------------------------------------------------------------------
# ARENAS — desenhadas por código em arena_bg.gd (a parte parada vira uma imagem só)
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
var opcoes := {"musica": 7, "efeitos": 8, "cpu": 1, "tempo": 1, "rounds": 1, "tela_cheia": false,
	"qualidade": 0, "auto_leve": false, "vibracao": true, "troca_controles": false}
const CPU_NOMES := ["FÁCIL", "NORMAL", "DIFÍCIL"]
const TEMPO_OPCOES := [60, 99, 0]         # 0 = infinito
const ROUNDS_OPCOES := [1, 2, 3]          # rounds para vencer
const QUALIDADE_NOMES := ["AUTOMÁTICA", "ALTA", "LEVE"]

var textures := {}
var rig_tex := {}
var rig_data := {}
var font_logo: Font
var font_ui: Font
var font_bold: Font
var font_body: Font
var white_tex: Texture2D
var dot_tex: Texture2D
var _glass_full: Shader
var _glass_lite: Shader
var _sfx := {}
var _players: Array[AudioStreamPlayer] = []
var _music: Array[AudioStreamPlayer] = []
var _music_cur := ""
var _music_slot := 0
var _music_tracks := {}
var _current: Node = null
var bg_cache := {}
var _baking := {}

# controles
var usando_controle := false
var ultimo_controle := 0
var _nav := Vector2i.ZERO
var _nav_hold := {"x": 0.0, "y": 0.0}
var _nav_dir := Vector2i.ZERO

# desempenho
var monitorar := false
var _fps_t := 0.0
var _fps_n := 0
var _fps_ruim := 0

# avisos
var _toast_layer: CanvasLayer
var _toast: Node2D
var toasts: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_fonts()
	_setup_textures()
	_glass_full = load("res://assets/shaders/glass.gdshader")
	_glass_lite = load("res://assets/shaders/glass_lite.gdshader")
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
	aplicar_controles()
	Input.joy_connection_changed.connect(_on_joy)
	_toast_layer = CanvasLayer.new()
	_toast_layer.layer = 100
	add_child(_toast_layer)
	_toast = Node2D.new()
	_toast.set_script(load("res://scripts/toast.gd"))
	_toast_layer.add_child(_toast)

func _setup_fonts() -> void:
	# setas e símbolos (← → ▲ ○ ∞ ...) vêm de uma fonte pequena junto com o jogo:
	# assim o jogo não precisa procurar fontes no Windows no meio da luta (isso podia dar travadinhas)
	var simbolos: Font = load("res://assets/fonts/BottonSimbolos.ttf")
	font_logo = load("res://assets/fonts/LilitaOne-Regular.ttf")
	font_logo.fallbacks = [simbolos]
	var base: Font = load("res://assets/fonts/Nunito.ttf")
	base.fallbacks = [simbolos]
	var tag := TextServerManager.get_primary_interface().name_to_tag("wght")
	font_ui = _variacao(base, tag, 900)
	font_bold = _variacao(base, tag, 800)
	font_body = _variacao(base, tag, 600)
	for f in [font_ui, font_bold, font_body]:
		f.fallbacks = [simbolos]
	_aquecer_fontes()

## Prepara as letras mais usadas de uma vez na abertura do jogo (em vez de no meio da luta)
func _aquecer_fontes() -> void:
	var letras := "ABCDEFGHIJKLMNOPQRSTUVWXYZÁÃÂÇÉÊÍÓÔÕÚabcdefghijklmnopqrstuvwxyzáãâçéêíóôõú0123456789 .,:;!?%+-/()“”•…←↑→↓∞"
	# letreiros grandes (fonte do logo, com campo de distância: um tamanho serve para todos)
	font_logo.get_string_size(letras, HORIZONTAL_ALIGNMENT_LEFT, -1, 48)
	# tamanhos usados na interface da luta
	for sz in [13, 14, 15, 17, 18, 20, 22, 24]:
		font_ui.get_string_size(letras, HORIZONTAL_ALIGNMENT_LEFT, -1, sz)
	for sz in [14, 15, 17]:
		font_bold.get_string_size(letras, HORIZONTAL_ALIGNMENT_LEFT, -1, sz)
		font_body.get_string_size(letras, HORIZONTAL_ALIGNMENT_LEFT, -1, sz)

func _variacao(base: Font, tag: int, peso: int) -> Font:
	var v := FontVariation.new()
	v.base_font = base
	v.variation_opentype = {tag: peso}
	return v

func _setup_textures() -> void:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	white_tex = ImageTexture.create_from_image(img)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.55))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	dot_tex = gt

func tex(i: int) -> Texture2D:
	return textures[ROSTER[i].id]

func arena_index(id: String) -> int:
	for i in ARENAS.size():
		if ARENAS[i].id == id: return i
	return 0

func poder(id: String) -> Dictionary:
	return Powers.get_def(id)

func tipo_cor(tipo: String) -> Color:
	return TIPOS.get(tipo, {}).get("cor", Color.WHITE)

func tipo_nome(tipo: String) -> String:
	return TIPOS.get(tipo, {}).get("nome", "?")

## true se um poder do tipo `atk` é super efetivo contra o tipo `alvo`
func super_efetivo(atk: String, alvo: String) -> bool:
	return alvo in TIPOS.get(atk, {}).get("forte", [])

func fraquezas(tipo: String) -> Array:
	var r := []
	for k in TIPOS.keys():
		if tipo in TIPOS[k].forte: r.append(k)
	return r

# ---------------------------------------------------------------------------
# QUALIDADE E DESEMPENHO
# ---------------------------------------------------------------------------
func leve() -> bool:
	return opcoes.qualidade == 2 or (opcoes.qualidade == 0 and opcoes.auto_leve)

func glass_shader() -> Shader:
	return _glass_lite if leve() else _glass_full

func _process(delta: float) -> void:
	_update_nav(delta)
	if monitorar and opcoes.qualidade == 0 and not opcoes.auto_leve:
		_fps_t += delta
		_fps_n += 1
		if _fps_t >= 2.0:
			var fps := _fps_n / _fps_t
			_fps_t = 0.0
			_fps_n = 0
			if fps < 54.0:
				_fps_ruim += 1
				if _fps_ruim >= 2:
					opcoes.auto_leve = true
					salvar_opcoes()
					toast("Modo leve ligado para o jogo rodar liso")
			else:
				_fps_ruim = 0

# ---------------------------------------------------------------------------
# FUNDOS: a parte parada de cada arena é desenhada uma vez numa imagem
# ---------------------------------------------------------------------------
func bake_arena(id: String) -> Texture2D:
	if bg_cache.has(id):
		return bg_cache[id]
	if DisplayServer.get_name() == "headless":
		return null
	if _baking.has(id):
		await _baking[id].pronto
		return bg_cache.get(id)
	var sinal := BakeSignal.new()
	_baking[id] = sinal
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var d: Node2D = load("res://scripts/arena_bg.gd").new()
	d.arena = id
	d.static_mode = true
	vp.add_child(d)
	add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	if img and not img.is_empty():
		bg_cache[id] = ImageTexture.create_from_image(img)
	vp.queue_free()
	_baking.erase(id)
	sinal.pronto.emit()
	return bg_cache.get(id)

class BakeSignal:
	signal pronto

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
			s.loop = name != "vitoria"
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
	monitorar = false
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
# CONTROLES — teclas físicas (funcionam igual no teclado ABNT2) + controles de videogame
# Jogador 1: WASD andar/pular, F leve, G pesado, H especial, R defesa, T supremo, Shift esquerdo dash
# Jogador 2: setas andar/pular, K leve, L pesado, Ç especial, O defesa, P supremo, I dash
# Poderes: especial sozinho, ou especial + direção (frente, cima, baixo)
# Sobrecarga: pesado + especial juntos (com 50% de Núcleo)
# Controle (Xbox/PlayStation): X leve, Y pesado, B especial, LB defesa, RB dash, RT supremo, Start pausa
# No modo de 1 jogador, qualquer controle comanda o Jogador 1.
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
const PAD_AXES := [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0], ["up", JOY_AXIS_LEFT_Y, -1.0],
	["down", JOY_AXIS_LEFT_Y, 1.0], ["super", JOY_AXIS_TRIGGER_RIGHT, 1.0], ["block", JOY_AXIS_TRIGGER_LEFT, 1.0]]
# nomes das teclas/botões para mostrar na tela
const KEY_LABEL := {
	"p1": {"left": "A", "right": "D", "up": "W", "down": "S", "light": "F", "heavy": "G", "special": "H", "block": "R",
		"super": "T", "dash": "SHIFT", "confirm": "ENTER", "back": "ESC", "pause": "ESC", "lr": "◀ ▶", "ud": "▲ ▼"},
	"p2": {"left": "←", "right": "→", "up": "↑", "down": "↓", "light": "K", "heavy": "L", "special": "Ç", "block": "O",
		"super": "P", "dash": "I", "confirm": "K", "back": "O", "pause": "ESC", "lr": "◀ ▶", "ud": "▲ ▼"},
}
const PAD_LABEL := {"light": "X", "heavy": "Y", "special": "B", "block": "LB", "super": "RT", "dash": "RB", "confirm": "A",
	"back": "B", "pause": "START", "left": "◀", "right": "▶", "up": "▲", "down": "▼", "lr": "◀ ▶", "ud": "▲ ▼"}
const PAD_COR := {"A": Color("4cc95b"), "B": Color("ff5a5a"), "X": Color("3a9bff"), "Y": Color("ffc93a")}

func _setup_input() -> void:
	for pi in 2:
		var p := "p%d" % (pi + 1)
		for act in KEYS[p]:
			var a := "%s_%s" % [p, act]
			if not InputMap.has_action(a):
				InputMap.add_action(a, 0.45)
			for k in KEYS[p][act]:
				var e := InputEventKey.new()
				if k == KEY_SHIFT:
					e.physical_keycode = KEY_SHIFT
					e.location = KEY_LOCATION_LEFT
				else:
					e.physical_keycode = k
				InputMap.action_add_event(a, e)
	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
		var e2 := InputEventKey.new()
		e2.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("pause", e2)
		var j := InputEventJoypadButton.new()
		j.button_index = JOY_BUTTON_START
		j.device = -1
		InputMap.action_add_event("pause", j)

func um_jogador() -> bool:
	return modo != "versus"

## Liga os controles de videogame aos jogadores.
## 1 jogador: qualquer controle comanda o J1. 2 jogadores: 1º controle = J1, 2º = J2 (ou trocado nas opções).
func aplicar_controles() -> void:
	var dev := [0, 1]
	if opcoes.troca_controles:
		dev = [1, 0]
	if um_jogador():
		dev = [-1, -2]
	for pi in 2:
		var p := "p%d" % (pi + 1)
		for act in KEYS[p]:
			var a := "%s_%s" % [p, act]
			for ev in InputMap.action_get_events(a):
				if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
					InputMap.action_erase_event(a, ev)
			if dev[pi] == -2:
				continue
			if PAD.has(act):
				var j := InputEventJoypadButton.new()
				j.button_index = PAD[act]
				j.device = dev[pi]
				InputMap.action_add_event(a, j)
		if dev[pi] == -2:
			continue
		for pair in PAD_AXES:
			var m := InputEventJoypadMotion.new()
			m.axis = pair[1]
			m.axis_value = pair[2]
			m.device = dev[pi]
			InputMap.action_add_event("%s_%s" % [p, pair[0]], m)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		usando_controle = true
		ultimo_controle = event.device
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
		usando_controle = true
		ultimo_controle = event.device
	elif event is InputEventKey and event.pressed:
		usando_controle = false

func _on_joy(device: int, connected: bool) -> void:
	var nome := Input.get_joy_name(device)
	if connected:
		toast("Controle %d conectado%s" % [device + 1, (": " + nome) if nome != "" else ""])
		usando_controle = true
	else:
		toast("Controle %d desconectado" % (device + 1))

## Dispositivo de controle de cada jogador (-1 = nenhum)
func controle_do_jogador(pi: int) -> int:
	if um_jogador():
		return ultimo_controle if pi == 0 else -1
	var dev := [0, 1] if not opcoes.troca_controles else [1, 0]
	return dev[pi]

func vibrar(pi: int, fraca: float, forte: float, dur: float) -> void:
	if not opcoes.vibracao:
		return
	var d := controle_do_jogador(pi)
	if d < 0 or d >= 8:
		return
	if d in Input.get_connected_joypads():
		Input.start_joy_vibration(d, clampf(fraca, 0, 1), clampf(forte, 0, 1), dur)

func just(a: String) -> bool:
	return Input.is_action_just_pressed("p1_" + a) or Input.is_action_just_pressed("p2_" + a)

## Navegação de menu com repetição ao segurar (setas, WASD, direcional ou analógico)
func nav() -> Vector2i:
	return _nav

func _update_nav(delta: float) -> void:
	_nav = Vector2i.ZERO
	var dx := int(_held_any("right")) - int(_held_any("left"))
	var dy := int(_held_any("down")) - int(_held_any("up"))
	for eixo in ["x", "y"]:
		var v := dx if eixo == "x" else dy
		var antes := _nav_dir.x if eixo == "x" else _nav_dir.y
		if v == 0:
			_nav_hold[eixo] = 0.0
		elif v != antes:
			_nav_hold[eixo] = 0.0
			if eixo == "x": _nav.x = v
			else: _nav.y = v
		else:
			_nav_hold[eixo] += delta
			if _nav_hold[eixo] > 0.38:
				_nav_hold[eixo] -= 0.09
				if eixo == "x": _nav.x = v
				else: _nav.y = v
	_nav_dir = Vector2i(dx, dy)

func _held_any(a: String) -> bool:
	return Input.is_action_pressed("p1_" + a) or Input.is_action_pressed("p2_" + a)

## nome da tecla/botão para mostrar (muda sozinho entre teclado e controle)
func rotulo(acao: String, pi := 0) -> String:
	if usando_controle:
		return PAD_LABEL.get(acao, acao.to_upper())
	return KEY_LABEL["p%d" % (pi + 1)].get(acao, acao.to_upper())

# ---------------------------------------------------------------------------
# AVISOS (toasts)
# ---------------------------------------------------------------------------
func toast(msg: String) -> void:
	toasts.append({"msg": msg, "t": 0.0})
	if toasts.size() > 3:
		toasts.pop_front()

# ---------------------------------------------------------------------------
# DESENHO
# ---------------------------------------------------------------------------
## Cria um painel de vidro líquido como filho de `pai` (fica atrás do desenho do pai)
func glass(pai: Node, r: Rect2, raio := 22.0, tint := Color(1, 1, 1, 0.10)) -> Node2D:
	var g: Node2D = load("res://scripts/glass.gd").new()
	g.rect = r
	g.radius = raio
	g.tint = tint
	pai.add_child(g)
	return g

func _fonte(estilo) -> Font:
	if typeof(estilo) == TYPE_BOOL:
		return font_ui if estilo else font_body
	match estilo:
		"logo": return font_logo
		"bold": return font_bold
		"corpo": return font_body
	return font_ui

func text(ci: CanvasItem, s: String, pos: Vector2, size: int, cor := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, estilo = "ui", outline := 0, ocor := Color(0, 0, 0, 0.55)) -> void:
	var f := _fonte(estilo)
	if outline > 0:
		ci.draw_string_outline(f, pos, s, align, width, size, outline, ocor)
	ci.draw_string(f, pos, s, align, width, size, cor)

## Texto com sombra suave (estilo vidro: sem contorno pesado)
func text_soft(ci: CanvasItem, s: String, pos: Vector2, size: int, cor := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, estilo = "ui", sombra := 0.45) -> void:
	var f := _fonte(estilo)
	ci.draw_string(f, pos + Vector2(0, maxf(2.0, size * 0.06)), s, align, width, size, Color(0.02, 0.01, 0.08, sombra * cor.a))
	ci.draw_string(f, pos, s, align, width, size, cor)

## Texto com quebra de linha automática (para descrições)
func text_wrap(ci: CanvasItem, s: String, pos: Vector2, width: float, size: int, cor := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT, estilo = "corpo") -> void:
	ci.draw_multiline_string(_fonte(estilo), pos, s, align, width, size, -1, cor)

func text_width(s: String, size: int, estilo = "ui") -> float:
	return _fonte(estilo).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

## Texto grande com tamanho "animado": desenha num tamanho fixo e escala (sem travar o jogo)
func text_scaled(ci: CanvasItem, s: String, centro: Vector2, size: int, esc: float, cor := Color.WHITE, estilo = "logo", outline := 0, ocor := Color(0, 0, 0, 0.55)) -> void:
	var f := _fonte(estilo)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_set_transform(centro, 0.0, Vector2.ONE * esc)
	var p := Vector2(-w / 2.0, size * 0.35)
	if outline > 0:
		ci.draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, ocor)
	ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, cor)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Desenha a arte de um botton (espelhada se flip)
func draw_char(ci: CanvasItem, i: int, centro: Vector2, altura: float, flip := false, mod := Color.WHITE) -> void:
	if altura < 2.0:
		return
	var t := tex(i)
	var s := t.get_size()
	var k := altura / s.y
	var sz := s * k
	ci.draw_set_transform(centro, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
	ci.draw_texture_rect(t, Rect2(-sz / 2, sz), false, mod)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Retângulo de cantos arredondados (cor sólida)
func rounded(ci: CanvasItem, r: Rect2, raio: float, cor: Color) -> void:
	if r.size.x <= 0.5 or r.size.y <= 0.5:
		return
	ci.draw_colored_polygon(_round_pts(r, raio), cor)

func rounded_line(ci: CanvasItem, r: Rect2, raio: float, cor: Color, w := 2.0) -> void:
	var pts := _round_pts(r, raio)
	pts.append(pts[0])
	ci.draw_polyline(pts, cor, w, true)

func _round_pts(r: Rect2, raio: float) -> PackedVector2Array:
	var rr := minf(raio, minf(r.size.x, r.size.y) * 0.5)
	var pts := PackedVector2Array()
	var cs := [r.position + Vector2(r.size.x - rr, rr), r.position + Vector2(r.size.x - rr, r.size.y - rr),
		r.position + Vector2(rr, r.size.y - rr), r.position + Vector2(rr, rr)]
	var a0 := [-PI / 2, 0.0, PI / 2, PI]
	for k in 4:
		for i in 7:
			var a: float = a0[k] + i * (PI / 2) / 6.0
			pts.append(cs[k] + Vector2(cos(a), sin(a)) * rr)
	return pts

## Barra "líquida" em cápsula: preenchimento com degradê e brilho
func capsula(ci: CanvasItem, r: Rect2, frac: float, c1: Color, c2: Color, da_direita := false) -> void:
	frac = clampf(frac, 0.0, 1.0)
	if frac <= 0.001:
		return
	var w := r.size.x * frac
	var fr := Rect2(r.position + Vector2(r.size.x - w if da_direita else 0.0, 0), Vector2(w, r.size.y))
	var pts := _round_pts(fr, r.size.y * 0.5)
	var cores := PackedColorArray()
	for p in pts:
		var k := (p.x - r.position.x) / r.size.x
		if da_direita: k = 1.0 - k
		cores.append(c1.lerp(c2, clampf(k, 0, 1)))
	ci.draw_polygon(pts, cores)
	var brilho := Rect2(fr.position + Vector2(r.size.y * 0.3, r.size.y * 0.14), Vector2(maxf(0.0, fr.size.x - r.size.y * 0.6), r.size.y * 0.28))
	rounded(ci, brilho, brilho.size.y * 0.5, Color(1, 1, 1, 0.35))

## Ícone de tecla ou botão do controle. Devolve a largura usada.
func glyph(ci: CanvasItem, pos: Vector2, acao: String, pi := 0, alt := 30.0) -> float:
	var s := rotulo(acao, pi)
	var fs := int(alt * 0.5)
	if usando_controle and PAD_COR.has(s):
		var c: Vector2 = pos + Vector2(alt * 0.5, 0)
		ci.draw_circle(c, alt * 0.5, PAD_COR[s].darkened(0.25))
		ci.draw_circle(c, alt * 0.42, PAD_COR[s])
		var tw := text_width(s, fs)
		text(ci, s, c + Vector2(-tw / 2.0, fs * 0.36), fs, Color.WHITE)
		return alt
	var tw2 := text_width(s, fs)
	var w := maxf(alt, tw2 + alt * 0.6)
	var r := Rect2(pos - Vector2(0, alt * 0.5), Vector2(w, alt))
	rounded(ci, r, alt * 0.28, Color(1, 1, 1, 0.92))
	rounded(ci, Rect2(r.position + Vector2(0, alt * 0.82), Vector2(w, alt * 0.18)), alt * 0.1, Color(0.6, 0.62, 0.7, 0.9))
	text(ci, s, Vector2(r.position.x + (w - tw2) / 2.0, pos.y + fs * 0.36), fs, Color(0.12, 0.1, 0.2))
	return w

## Linha de ajuda: [[ação, texto], ...] centralizada em `centro`
func prompts(ci: CanvasItem, centro: Vector2, itens: Array, pi := 0, alt := 26.0) -> void:
	var fs := int(alt * 0.62)
	var total := 0.0
	var larg := []
	for it in itens:
		var gw := glyph_w(it[0], pi, alt)
		var tw := text_width(it[1], fs, "bold")
		larg.append([gw, tw])
		total += gw + 8.0 + tw + 26.0
	total -= 26.0
	var x := centro.x - total / 2.0
	for i in itens.size():
		glyph(ci, Vector2(x, centro.y), itens[i][0], pi, alt)
		x += larg[i][0] + 8.0
		text(ci, itens[i][1], Vector2(x, centro.y + fs * 0.36), fs, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_LEFT, -1, "bold")
		x += larg[i][1] + 26.0

func glyph_w(acao: String, pi := 0, alt := 30.0) -> float:
	var s := rotulo(acao, pi)
	if usando_controle and PAD_COR.has(s):
		return alt
	return maxf(alt, text_width(s, int(alt * 0.5)) + alt * 0.6)

static func stat_bar(ci: CanvasItem, pos: Vector2, valor: int, cor: Color) -> void:
	for i in 5:
		var r := Rect2(pos + Vector2(i * 26, 0), Vector2(22, 10))
		Game.rounded(ci, r, 5.0, cor if i < valor else Color(1, 1, 1, 0.14))

## Selo do tipo (pílula colorida)
func tipo_selo(ci: CanvasItem, pos: Vector2, tipo: String, alt := 26.0) -> float:
	var nome := tipo_nome(tipo).to_upper()
	var fs := int(alt * 0.55)
	var tw := text_width(nome, fs)
	var r := Rect2(pos - Vector2(0, alt * 0.5), Vector2(tw + alt * 0.9, alt))
	var c := tipo_cor(tipo)
	rounded(ci, r, alt * 0.5, Color(c, 0.85))
	rounded(ci, Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, alt * 0.35)), alt * 0.2, Color(1, 1, 1, 0.25))
	text(ci, nome, Vector2(r.position.x + alt * 0.45, pos.y + fs * 0.36), fs, Color.WHITE if c.get_luminance() < 0.6 else Color(0.1, 0.08, 0.18))
	return r.size.x

func tipo_selo_w(tipo: String, alt := 26.0) -> float:
	return text_width(tipo_nome(tipo).to_upper(), int(alt * 0.55)) + alt * 0.9

## Ícone simples de um poder (círculo com seta da direção)
func poder_icone(ci: CanvasItem, c: Vector2, slot: int, cor: Color, r := 16.0, apagado := false) -> void:
	var base := Color(cor, 0.35 if apagado else 0.9)
	ci.draw_circle(c, r, Color(0.05, 0.04, 0.12, 0.6))
	ci.draw_circle(c, r * 0.86, base)
	var w := Color(1, 1, 1, 0.5 if apagado else 1.0)
	match slot:
		0:
			ci.draw_circle(c, r * 0.32, w)
		1:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.45, 0), c + Vector2(-r * 0.3, -r * 0.4), c + Vector2(-r * 0.3, r * 0.4)]), w)
		2:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.45), c + Vector2(r * 0.4, r * 0.3), c + Vector2(-r * 0.4, r * 0.3)]), w)
		3:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, r * 0.45), c + Vector2(r * 0.4, -r * 0.3), c + Vector2(-r * 0.4, -r * 0.3)]), w)
