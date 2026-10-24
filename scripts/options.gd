extends Node2D
## Opções (vidro líquido): volumes, qualidade, CPU, tempo, rounds, tela cheia, vibração e controles.

var bg: Node2D
var t := 0.0
var sel := 0
var sel_y := 0.0
var g_card: Node2D
var g_pill: Node2D
var g_dica: Node2D
const ITENS := ["MÚSICA", "EFEITOS", "QUALIDADE", "DIFICULDADE DA CPU", "TEMPO DO ROUND", "ROUNDS", "TELA CHEIA", "VIBRAÇÃO DO CONTROLE", "CONTROLES J1 / J2", "VOLTAR"]
const DICAS := ["Volume da música.", "Volume dos efeitos sonoros.",
	"Automática: o jogo fica leve sozinho se o computador não der conta. Leve: menos efeitos, vidro simples.",
	"Força da CPU no modo Contra CPU.", "Tempo de cada round.", "Quantos rounds para vencer a luta.", "Tela cheia ou janela.",
	"O controle treme ao bater e apanhar.", "Trocado: o 2º controle vira o Jogador 1 (no modo de 2 jogadores).", "Voltar ao menu."]
const CARD := Rect2(250, 120, 780, 10 * 48.0 + 24)
const ITEM := 48.0

func _ready() -> void:
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.arena = "santuario"
	bg.dim = 0.5
	bg.z_index = -3
	add_child(bg)
	g_card = Game.glass(self, CARD, 30, Color(1, 1, 1, 0.08))
	g_pill = Game.glass(self, Rect2(), 20, Color(1, 1, 1, 0.2))
	g_pill.glow = 0.6
	g_pill.glow_color = Color("7fd8ff")
	g_pill.margin = 16
	g_dica = Game.glass(self, Rect2(150, 636, 980, 48), 24, Color(1, 1, 1, 0.08))

func _valor(i: int) -> String:
	var o: Dictionary = Game.opcoes
	match i:
		0: return "%d" % o.musica
		1: return "%d" % o.efeitos
		2:
			var q: String = Game.QUALIDADE_NOMES[o.qualidade]
			if o.qualidade == 0 and o.auto_leve: q += " (LEVE)"
			return q
		3: return Game.CPU_NOMES[o.cpu]
		4: return "INFINITO" if Game.TEMPO_OPCOES[o.tempo] == 0 else "%d s" % Game.TEMPO_OPCOES[o.tempo]
		5: return ["1 ROUND", "MELHOR DE 3", "MELHOR DE 5"][o.rounds]
		6: return "SIM" if o.tela_cheia else "NÃO"
		7: return "SIM" if o.vibracao else "NÃO"
		8: return "TROCADO" if o.troca_controles else "NORMAL"
	return ""

func _mudar(i: int, d: int) -> void:
	var o: Dictionary = Game.opcoes
	match i:
		0: o.musica = clampi(o.musica + d, 0, 10)
		1: o.efeitos = clampi(o.efeitos + d, 0, 10)
		2:
			o.qualidade = wrapi(o.qualidade + d, 0, 3)
			o.auto_leve = false
		3: o.cpu = wrapi(o.cpu + d, 0, 3)
		4: o.tempo = wrapi(o.tempo + d, 0, 3)
		5: o.rounds = wrapi(o.rounds + d, 0, 3)
		6: o.tela_cheia = not o.tela_cheia
		7:
			o.vibracao = not o.vibracao
			if o.vibracao: Game.vibrar(0, 0.6, 0.4, 0.25)
		8: o.troca_controles = not o.troca_controles
		_: return
	Game.salvar_opcoes()
	Game.aplicar_controles()
	Game.play("hit_light" if i == 1 else "select")

func _process(delta: float) -> void:
	t += delta
	sel_y = lerpf(sel_y, sel * ITEM, minf(1.0, delta * 16.0))
	g_pill.set_rect(Rect2(CARD.position.x + 12, CARD.position.y + 12 + sel_y, CARD.size.x - 24, ITEM - 4))
	var nv := Game.nav()
	if nv.y != 0:
		sel = wrapi(sel + nv.y, 0, ITENS.size()); Game.play("select")
	elif nv.x != 0:
		_mudar(sel, nv.x)
	elif Game.just("confirm"):
		if sel == ITENS.size() - 1:
			Game.play("confirm")
			Game.goto("res://scripts/title.gd")
		else:
			_mudar(sel, 1)
	elif Game.just("back"):
		Game.play("select")
		Game.goto("res://scripts/title.gd")
	queue_redraw()

func _draw() -> void:
	Game.text_soft(self, "OPÇÕES", Vector2(0, 90), 46, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1280, "ui")
	for i in ITENS.size():
		var y := CARD.position.y + 12 + i * ITEM + 31
		var on := i == sel
		Game.text_soft(self, ITENS[i], Vector2(CARD.position.x + 34, y), 19, Color.WHITE if on else Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT, -1, "ui", 0.35)
		if i < ITENS.size() - 1:
			var vx := CARD.end.x - 34
			if i <= 1:
				var nv: int = Game.opcoes.musica if i == 0 else Game.opcoes.efeitos
				var r := Rect2(vx - 240, y - 16, 240, 14)
				Game.rounded(self, r, 7, Color(1, 1, 1, 0.12))
				Game.capsula(self, r, nv / 10.0, Color("3a8cff"), Color("7fe8ff"))
			else:
				var v := _valor(i)
				Game.text(self, v, Vector2(vx - 400, y), 18, Color("bfefff") if on else Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_RIGHT, 400 - (34 if on else 0), "ui")
				if on:
					Game.text(self, "◀", Vector2(vx - 30 - Game.text_width(v, 18, "ui") - 26, y), 16, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT, -1, "ui")
					Game.text(self, "▶", Vector2(vx - 20, y), 16, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT, -1, "ui")
	var linhas_dica := 2 if Game.text_width(DICAS[sel], 16, "bold") > 930.0 else 1
	Game.text_wrap(self, DICAS[sel], Vector2(170, 666 - (9 if linhas_dica == 2 else 0)), 940, 16, Color(1, 1, 1, 0.92), HORIZONTAL_ALIGNMENT_CENTER, "bold")
	Game.prompts(self, Vector2(640, 706), [["lr", "Mudar"], ["confirm", "OK"], ["back", "Voltar"]], 0, 22.0)
