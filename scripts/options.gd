extends Node2D
## Opções: volumes, dificuldade da CPU, tempo, rounds e tela cheia (salvas automaticamente).

var bg: Node2D
var t := 0.0
var sel := 0
const ITENS := ["MÚSICA", "EFEITOS", "DIFICULDADE DA CPU", "TEMPO DO ROUND", "ROUNDS", "TELA CHEIA", "VOLTAR"]

func _ready() -> void:
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.arena = "santuario"
	bg.dim = 0.6
	bg.z_index = -2
	add_child(bg)

func _valor(i: int) -> String:
	var o: Dictionary = Game.opcoes
	match i:
		0: return "%d" % o.musica
		1: return "%d" % o.efeitos
		2: return Game.CPU_NOMES[o.cpu]
		3: return "INFINITO" if Game.TEMPO_OPCOES[o.tempo] == 0 else "%d s" % Game.TEMPO_OPCOES[o.tempo]
		4: return ["1 ROUND", "MELHOR DE 3", "MELHOR DE 5"][o.rounds]
		5: return "SIM" if o.tela_cheia else "NÃO"
	return ""

func _mudar(i: int, d: int) -> void:
	var o: Dictionary = Game.opcoes
	match i:
		0: o.musica = clampi(o.musica + d, 0, 10)
		1:
			o.efeitos = clampi(o.efeitos + d, 0, 10)
		2: o.cpu = wrapi(o.cpu + d, 0, 3)
		3: o.tempo = wrapi(o.tempo + d, 0, 3)
		4: o.rounds = wrapi(o.rounds + d, 0, 3)
		5: o.tela_cheia = not o.tela_cheia
		_: return
	Game.salvar_opcoes()
	Game.play("hit_light" if i == 1 else "select")

func _process(delta: float) -> void:
	t += delta
	if Game.just("up"):
		sel = wrapi(sel - 1, 0, ITENS.size()); Game.play("select")
	elif Game.just("down"):
		sel = wrapi(sel + 1, 0, ITENS.size()); Game.play("select")
	elif Game.just("left"):
		_mudar(sel, -1)
	elif Game.just("right"):
		_mudar(sel, 1)
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
	Game.text(self, "OPÇÕES", Vector2(0, 110), 64, Color("fff6e0"), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 14, Color("2a1250"))
	var r := Rect2(290, 160, 700, 60 + ITENS.size() * 58)
	draw_rect(r, Color(0.04, 0.02, 0.1, 0.85))
	draw_rect(r, Color("6fd0ff"), false, 2)
	for i in ITENS.size():
		var y := 215 + i * 58
		var on := i == sel
		if on:
			draw_rect(Rect2(306, y - 36, 668, 50), Color("6fd0ff", 0.2))
		Game.text(self, ITENS[i], Vector2(330, y), 28, Color("ffd36b") if on else Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, true, 5)
		if i < ITENS.size() - 1:
			var v := _valor(i)
			if i <= 1:
				var nv: int = Game.opcoes.musica if i == 0 else Game.opcoes.efeitos
				for k in 10:
					draw_rect(Rect2(720 + k * 22, y - 22, 16, 22), Color("6fd0ff") if k < nv else Color(1, 1, 1, 0.12))
			else:
				Game.text(self, "◀  %s  ▶" % v if on else v, Vector2(640, y), 26, Color("6fd0ff") if on else Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_RIGHT, 320, true, 4)
	Game.text(self, "Setas ou A/D mudam o valor  •  As opções são salvas sozinhas", Vector2(0, 680), 18, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 1280, false)
