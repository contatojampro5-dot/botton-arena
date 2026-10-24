extends Node2D
## Seleção de personagens para 2 jogadores (ou jogador contra CPU).

const COLS := 4
const CARD := 104.0
const GAP := 10.0
var bg: Node2D
var t := 0.0
var cur := [0, 1]
var pronto := [false, false]
var saindo := -1.0
var anim := [0.0, 0.0]   # "pulinho" ao trocar de personagem
var cpu_escolhendo := false

func _ready() -> void:
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.dim = 0.55
	bg.z_index = -2
	add_child(bg)
	cur = Game.escolha.duplicate()

func _grid_origin() -> Vector2:
	var w := COLS * CARD + (COLS - 1) * GAP
	return Vector2(640 - w / 2.0, 150)

func _card_rect(i: int) -> Rect2:
	var o := _grid_origin()
	return Rect2(o + Vector2((i % COLS) * (CARD + GAP), (i / COLS) * (CARD + GAP)), Vector2(CARD, CARD))

func _process(delta: float) -> void:
	t += delta
	for i in 2:
		anim[i] = max(0.0, anim[i] - delta * 4.0)
	if saindo >= 0.0:
		saindo += delta
		if saindo > 1.1:
			Game.escolha = cur.duplicate()
			Game.vitorias = [0, 0]
			Game.goto("res://scripts/fight.gd")
		queue_redraw()
		return
	if Game.modo == "versus":
		_controle(0, "p1")
		_controle(1, "p2")
	else:
		# contra CPU: o Jogador 1 escolhe o próprio botton e depois o adversário
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
		elif Game.modo == "cpu" and i == 1:
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
	var sub := "2 JOGADORES" if Game.modo == "versus" else "CONTRA CPU"
	Game.text(self, sub, Vector2(0, 108), 24, Color("ffd36b"), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 6)
	_preview(0, Vector2(200, 380))
	_preview(1, Vector2(1080, 380))
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
		var r := _card_rect(cur[p]).grow(4 + p * 5)
		var col := Color("4aa8ff") if p == 0 else Color("ff4a5a")
		var a := 1.0 if pronto[p] else 0.6 + 0.4 * sin(t * 8.0)
		draw_rect(r, Color(col, a), false, 5)
		var tag := "1P" if p == 0 else ("CPU" if Game.modo == "cpu" else "2P")
		var tp := r.position + (Vector2(-4, -6) if p == 0 else Vector2(r.size.x - (52 if tag == "CPU" else 34), -6))
		Game.text(self, tag, tp, 22, col, HORIZONTAL_ALIGNMENT_LEFT, -1, true, 6)
	# dicas
	var dica := "J1: WASD + F confirma, R volta    •    J2: setas + K confirma, O volta"
	if Game.modo == "cpu":
		dica = "Escolha o seu botton e depois o adversário (WASD + F, R volta)"
	Game.text(self, dica, Vector2(0, 700), 18, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 1280, false)
	if saindo >= 0.0:
		var a := clampf(saindo * 3.0, 0.0, 1.0)
		draw_rect(Rect2(0, 300, 1280, 120), Color(0, 0, 0, 0.6 * a))
		Game.text(self, "PREPAREM-SE!", Vector2(0, 385), 72, Color(1, 0.85, 0.3, a), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 14, Color(0.2, 0.05, 0.1, a))
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, clampf((saindo - 0.7) * 2.5, 0.0, 1.0)))

func _preview(p: int, centro: Vector2) -> void:
	var i: int = cur[p]
	var c: Dictionary = Game.ROSTER[i]
	var col := Color("4aa8ff") if p == 0 else Color("ff4a5a")
	# aura
	for k in 5:
		draw_circle(centro + Vector2(0, -40), 150 - k * 22, Color(c.cor, 0.05 + k * 0.03))
	var tx := Game.tex(i)
	var s := tx.get_size()
	var esc: float = 300.0 / maxf(s.x, s.y) * (1.0 + 0.12 * anim[p])
	var sz := s * esc
	var bob := 8 * sin(t * 2.2 + p)
	var cpos := centro + Vector2(0, -40 + bob)
	# o jogador 2 olha para a esquerda (espelhado)
	draw_set_transform(cpos, 0.0, Vector2(-1.0 if p == 1 else 1.0, 1.0))
	draw_texture_rect(tx, Rect2(-sz / 2, sz), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# painel de informações
	var px := centro.x - 175
	var py := 520.0
	draw_rect(Rect2(px, py, 350, 160), Color(0.04, 0.02, 0.1, 0.85))
	draw_rect(Rect2(px, py, 350, 4), col)
	Game.text(self, c.nome, Vector2(px, py + 34), 26 if c.nome.length() < 18 else 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 350, true, 6)
	Game.text(self, "Núcleo: %s  •  %s" % [c.nucleo, Game.ESPECIAL_NOME[c.especial]], Vector2(px, py + 58), 16, c.cor.lightened(0.3), HORIZONTAL_ALIGNMENT_CENTER, 350, false)
	var labels := [["VELOCIDADE", c.vel], ["FORÇA", c.forca], ["DEFESA", c.def]]
	for k in 3:
		Game.text(self, labels[k][0], Vector2(px + 40, py + 88 + k * 20), 15, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_LEFT, -1, false)
		Game.stat_bar(self, Vector2(px + 170, py + 77 + k * 20), labels[k][1], c.cor)
	Game.text(self, "“%s”" % c.frase, Vector2(px + 10, py + 150), 14, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 330, false)
	if pronto[p]:
		Game.text(self, "PRONTO!", Vector2(centro.x - 150, 140), 40, col, HORIZONTAL_ALIGNMENT_CENTER, 300, true, 10)
