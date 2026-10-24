extends Node2D
## Seleção de personagens: 2 jogadores, contra CPU, treino ou arcade.

const COLS := 4
const CARD := 104.0
const GAP := 10.0
var bg: Node2D
var t := 0.0
var cur := [0, 1]
var pronto := [false, false]
var saindo := -1.0
var anim := [0.0, 0.0]   # "pulinho" ao trocar de personagem

func _ready() -> void:
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.arena = "santuario"
	bg.dim = 0.55
	bg.z_index = -2
	add_child(bg)
	cur = Game.escolha.duplicate()
	Game.eco = [false, false]
	Game.music("selecao")
	if Game.modo == "arcade":
		pronto[1] = true

func _grid_origin() -> Vector2:
	var w := COLS * CARD + (COLS - 1) * GAP
	return Vector2(640 - w / 2.0, 150)

func _card_rect(i: int) -> Rect2:
	var o := _grid_origin()
	return Rect2(o + Vector2((i % COLS) * (CARD + GAP), (i / COLS) * (CARD + GAP)), Vector2(CARD, CARD))

func _um_jogador() -> bool:
	return Game.modo in ["cpu", "treino", "arcade"]

func _process(delta: float) -> void:
	t += delta
	for i in 2:
		anim[i] = max(0.0, anim[i] - delta * 4.0)
	if saindo >= 0.0:
		saindo += delta
		if saindo > 0.6:
			Game.escolha = cur.duplicate()
			Game.vitorias = [0, 0]
			if Game.modo == "arcade":
				Game.arcade_iniciar(cur[0])
				Game.goto("res://scripts/versus.gd")
			else:
				Game.goto("res://scripts/stage_select.gd")
		queue_redraw()
		return
	if Game.modo == "versus":
		_controle(0, "p1")
		_controle(1, "p2")
	else:
		# um jogador: escolhe o próprio botton e depois o adversário (menos no arcade)
		var alvo := 0 if not pronto[0] else 1
		_controle(alvo, "p1")
	if pronto[0] and pronto[1] and saindo < 0.0:
		saindo = 0.0
		Game.play("round")
	queue_redraw()

func _controle(i: int, p: String) -> void:
	var n := Game.ROSTER.size()
	if Input.is_action_just_pressed(p + "_back"):
		if pronto[i]:
			pronto[i] = false; Game.play("select")
		elif _um_jogador() and i == 1:
			pronto[0] = false; Game.play("select")
		else:
			Game.goto("res://scripts/title.gd")
		return
	if pronto[i]:
		return
	var mv := 0
	if Input.is_action_just_pressed(p + "_left"): mv = -1
	elif Input.is_action_just_pressed(p + "_right"): mv = 1
	elif Input.is_action_just_pressed(p + "_up"): mv = -COLS
	elif Input.is_action_just_pressed(p + "_down"): mv = COLS
	if mv != 0:
		cur[i] = wrapi(cur[i] + mv, 0, n)
		anim[i] = 1.0
		Game.play("select", 1.0 + i * 0.1)
	if Input.is_action_just_pressed(p + "_confirm"):
		pronto[i] = true
		anim[i] = 1.0
		Game.play("confirm")

func _draw() -> void:
	Game.text(self, "ESCOLHA SEU BOTTON", Vector2(0, 70), 52, Color("fff6e0"), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 12, Color("2a1250"))
	var sub: String = {"versus": "2 JOGADORES", "cpu": "CONTRA CPU", "treino": "TREINO", "arcade": "ARCADE"}.get(Game.modo, "")
	Game.text(self, sub, Vector2(0, 108), 24, Color("ffd36b"), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 6)
	_preview(0, Vector2(200, 330))
	if Game.modo == "arcade":
		_misterio(Vector2(1080, 330))
	else:
		_preview(1, Vector2(1080, 330))
	# grade
	for i in Game.ROSTER.size():
		var r := _card_rect(i)
		var c: Dictionary = Game.ROSTER[i]
		draw_rect(r, Color(0.07, 0.05, 0.15, 0.9))
		draw_rect(r.grow(-3), Color(c.cor, 0.18))
		var tx := Game.tex(i)
		var s := tx.get_size()
		var k := (CARD - 10) / maxf(s.x, s.y)
		var sz := s * k
		draw_texture_rect(tx, Rect2(r.get_center() - sz / 2 + Vector2(0, 2), sz), false)
		draw_rect(r, Color(c.cor, 0.5), false, 2)
	# cursores
	for p in 2:
		if Game.modo == "arcade" and p == 1: continue
		var r := _card_rect(cur[p]).grow(4 + p * 5)
		var col := Color("4aa8ff") if p == 0 else Color("ff4a5a")
		var a := 1.0 if pronto[p] else 0.6 + 0.4 * sin(t * 8.0)
		draw_rect(r, Color(col, a), false, 5)
		var tag := "1P"
		if p == 1:
			tag = {"cpu": "CPU", "treino": "BONECO"}.get(Game.modo, "2P")
		var tp := r.position + (Vector2(-4, -6) if p == 0 else Vector2(r.size.x - tag.length() * 17, -6))
		Game.text(self, tag, tp, 22, col, HORIZONTAL_ALIGNMENT_LEFT, -1, true, 6)
	# dicas
	var dica := "J1: WASD + F confirma, R volta    •    J2: setas + K confirma, O volta"
	if Game.modo in ["cpu", "treino"]:
		dica = "Escolha o seu botton e depois o adversário (WASD + F confirma, R volta)"
	elif Game.modo == "arcade":
		dica = "Escolha o seu botton para o Arcade (WASD + F confirma, R volta)"
	Game.text(self, dica, Vector2(0, 708), 17, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 1280, false)
	if saindo >= 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, clampf(saindo * 2.0, 0.0, 1.0)))

func _preview(p: int, centro: Vector2) -> void:
	var i: int = cur[p]
	var c: Dictionary = Game.ROSTER[i]
	var col := Color("4aa8ff") if p == 0 else Color("ff4a5a")
	for k in 5:
		draw_circle(centro + Vector2(0, -20), 140 - k * 20, Color(c.cor, 0.05 + k * 0.03))
	var esc: float = 270.0 * (1.0 + 0.12 * anim[p])
	var bob := 8 * sin(t * 2.2 + p)
	Game.draw_char(self, i, centro + Vector2(0, -20 + bob), esc, p == 1)
	# painel de informações
	var px := centro.x - 180
	var py := 478.0
	draw_rect(Rect2(px, py, 360, 222), Color(0.04, 0.02, 0.1, 0.88))
	draw_rect(Rect2(px, py, 360, 4), col)
	Game.text(self, c.nome, Vector2(px, py + 34), 26 if c.nome.length() < 18 else 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 360, true, 6)
	Game.text(self, "Núcleo: %s" % c.nucleo, Vector2(px, py + 56), 16, c.cor.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, 360, false)
	var labels := [["VELOCIDADE", c.vel], ["FORÇA", c.forca], ["DEFESA", c.def]]
	for k in 3:
		Game.text(self, labels[k][0], Vector2(px + 45, py + 84 + k * 20), 15, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_LEFT, -1, false)
		Game.stat_bar(self, Vector2(px + 175, py + 73 + k * 20), labels[k][1], c.cor)
	Game.text(self, "ESPECIAL: " + c.especial_nome, Vector2(px + 15, py + 156), 17, c.cor.lightened(0.35), HORIZONTAL_ALIGNMENT_LEFT, 330, true, 3)
	Game.text(self, "SUPREMO: " + c.supremo_nome, Vector2(px + 15, py + 180), 17, Color("ffd36b"), HORIZONTAL_ALIGNMENT_LEFT, 330, true, 3)
	Game.text(self, "“%s”" % c.frase, Vector2(px + 10, py + 208), 13, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_CENTER, 340, false)
	if pronto[p] and not (Game.modo == "arcade" and p == 1):
		Game.text(self, "PRONTO!", Vector2(centro.x - 150, 150), 40, col, HORIZONTAL_ALIGNMENT_CENTER, 300, true, 10)

func _misterio(centro: Vector2) -> void:
	for k in 5:
		draw_circle(centro + Vector2(0, -20), 140 - k * 20, Color(0.6, 0.2, 0.5, 0.04 + k * 0.03))
	Game.text(self, "?", Vector2(centro.x - 100, centro.y + 40), 180, Color(1, 1, 1, 0.25 + 0.1 * sin(t * 3.0)), HORIZONTAL_ALIGNMENT_CENTER, 200, true, 10)
	var px := centro.x - 180
	var py := 478.0
	draw_rect(Rect2(px, py, 360, 222), Color(0.04, 0.02, 0.1, 0.88))
	draw_rect(Rect2(px, py, 360, 4), Color("ff4a5a"))
	Game.text(self, "6 RIVAIS + ???", Vector2(px, py + 40), 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 360, true, 6)
	Game.text_wrap(self, "Vença 6 bottons em sequência, cada um na sua arena. A CPU fica mais forte a cada luta. No fim, algo sombrio espera por você…", Vector2(px + 20, py + 80), 320, 16, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_CENTER)
