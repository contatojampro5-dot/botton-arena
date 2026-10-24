extends Node2D
## Seleção de personagens (vidro líquido): 2 jogadores, contra CPU, treino ou arcade.

const COLS := 4
const CARD := 100.0
const GAP := 12.0
var bg: Node2D
var t := 0.0
var cur := [0, 1]
var pronto := [false, false]
var saindo := -1.0
var anim := [0.0, 0.0]
var tiles: Array = []
var g_info: Array = []
var g_sub: Node2D

func _ready() -> void:
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.arena = "santuario"
	bg.dim = 0.45
	bg.z_index = -3
	add_child(bg)
	cur = Game.escolha.duplicate()
	Game.eco = [false, false]
	Game.music("selecao")
	if Game.modo == "arcade":
		pronto[1] = true
	for i in Game.ROSTER.size():
		var g := Game.glass(self, _card_rect(i), 22, Color(Game.ROSTER[i].cor, 0.10))
		g.margin = 16
		tiles.append(g)
	for p in 2:
		var px := 200.0 if p == 0 else 1080.0
		g_info.append(Game.glass(self, Rect2(px - 185, 452, 370, 250), 26, Color(1, 1, 1, 0.08)))
	g_sub = Game.glass(self, Rect2(540, 96, 200, 36), 18, Color(1, 1, 1, 0.12))

func _grid_origin() -> Vector2:
	var w := COLS * CARD + (COLS - 1) * GAP
	return Vector2(640 - w / 2.0, 160)

func _card_rect(i: int) -> Rect2:
	var o := _grid_origin()
	return Rect2(o + Vector2((i % COLS) * (CARD + GAP), (i / COLS) * (CARD + GAP)), Vector2(CARD, CARD))

func _um_jogador() -> bool:
	return Game.modo in ["cpu", "treino", "arcade"]

func _process(delta: float) -> void:
	t += delta
	for i in 2:
		anim[i] = max(0.0, anim[i] - delta * 4.0)
	for i in tiles.size():
		var g: Node2D = tiles[i]
		var on0: bool = cur[0] == i
		var on1: bool = cur[1] == i and not (Game.modo == "arcade")
		g.glow = 0.0
		if on0 or on1:
			g.glow = 0.9 if (pronto[0] and on0) or (pronto[1] and on1) else 0.55 + 0.25 * sin(t * 6.0)
			g.glow_color = Color("4aa8ff") if on0 else Color("ff4a5a")
			if on0 and on1: g.glow_color = Color("c07aff")
		g.tint = Color(Game.ROSTER[i].cor, 0.22 if (on0 or on1) else 0.08)
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
		var alvo := 0 if not pronto[0] else 1
		_controle(alvo, "p1", true)
	if pronto[0] and pronto[1] and saindo < 0.0:
		saindo = 0.0
		Game.play("round")
	queue_redraw()

func _controle(i: int, p: String, qualquer := false) -> void:
	var n := Game.ROSTER.size()
	var back := Game.just("back") if qualquer else Input.is_action_just_pressed(p + "_back")
	if back:
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
	if qualquer:
		var nv := Game.nav()
		mv = nv.x + nv.y * COLS
	else:
		if Input.is_action_just_pressed(p + "_left"): mv = -1
		elif Input.is_action_just_pressed(p + "_right"): mv = 1
		elif Input.is_action_just_pressed(p + "_up"): mv = -COLS
		elif Input.is_action_just_pressed(p + "_down"): mv = COLS
	if mv != 0:
		cur[i] = wrapi(cur[i] + mv, 0, n)
		anim[i] = 1.0
		Game.play("select", 1.0 + i * 0.1)
	var ok := Game.just("confirm") if qualquer else Input.is_action_just_pressed(p + "_confirm")
	if ok:
		pronto[i] = true
		anim[i] = 1.0
		Game.play("confirm")

func _draw() -> void:
	Game.text_soft(self, "ESCOLHA SEU BOTTON", Vector2(0, 74), 44, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1280, "ui")
	var sub: String = {"versus": "2 JOGADORES", "cpu": "CONTRA CPU", "treino": "TREINO", "arcade": "ARCADE"}.get(Game.modo, "")
	Game.text(self, sub, Vector2(540, 120), 17, Color("ffe2a0"), HORIZONTAL_ALIGNMENT_CENTER, 200, "ui")
	_preview(0, Vector2(200, 300))
	if Game.modo == "arcade":
		_misterio(Vector2(1080, 300))
	else:
		_preview(1, Vector2(1080, 300))
	for i in Game.ROSTER.size():
		var r := _card_rect(i)
		var lift := 0.0
		if cur[0] == i or (cur[1] == i and Game.modo != "arcade"):
			lift = -3.0 - 2.0 * sin(t * 4.0)
		Game.draw_char(self, i, r.get_center() + Vector2(0, 2 + lift), CARD - 12)
		Game.tipo_selo(self, r.position + Vector2(6, r.size.y - 11), Game.ROSTER[i].tipo, 16)
	for p in 2:
		if Game.modo == "arcade" and p == 1: continue
		var r2 := _card_rect(cur[p])
		var col := Color("4aa8ff") if p == 0 else Color("ff4a5a")
		var tag := "1P"
		if p == 1:
			tag = {"cpu": "CPU", "treino": "BONECO"}.get(Game.modo, "2P")
		var tw := Game.text_width(tag, 15, "ui") + 16
		var tp := r2.position + (Vector2(-6, -12) if p == 0 else Vector2(r2.size.x - tw + 6, -12))
		Game.rounded(self, Rect2(tp, Vector2(tw, 22)), 11, col)
		Game.text(self, tag, tp + Vector2(8, 16), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, "ui")
	var itens := [["confirm", "Escolher"], ["back", "Voltar"]]
	Game.prompts(self, Vector2(640, 702), itens)
	if saindo >= 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, clampf(saindo * 2.0, 0.0, 1.0)))

func _preview(p: int, centro: Vector2) -> void:
	var i: int = cur[p]
	var c: Dictionary = Game.ROSTER[i]
	var col := Color("4aa8ff") if p == 0 else Color("ff4a5a")
	draw_texture_rect(Game.dot_tex, Rect2(centro - Vector2(190, 170), Vector2(380, 340)), false, Color(c.cor, 0.3))
	var esc: float = 250.0 * (1.0 + 0.1 * anim[p])
	var bob := 7 * sin(t * 2.2 + p)
	Game.draw_char(self, i, centro + Vector2(0, -10 + bob), esc, p == 1)
	var px := centro.x - 185
	var py := 452.0
	Game.text_soft(self, c.nome, Vector2(px, py + 34), 23 if c.nome.length() < 18 else 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 370, "ui")
	var tw := Game.text_width(Game.tipo_nome(c.tipo).to_upper(), 12, "ui") + 22
	Game.tipo_selo(self, Vector2(centro.x - tw / 2.0, py + 54), c.tipo, 22)
	var labels := [["VELOCIDADE", c.vel], ["FORÇA", c.forca], ["DEFESA", c.def]]
	for k in 3:
		Game.text(self, labels[k][0], Vector2(px + 28, py + 92 + k * 19), 13, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_LEFT, -1, "bold")
		Game.capsula(self, Rect2(px + 140, py + 82 + k * 19, 130, 10), labels[k][1] / 5.0, c.cor.darkened(0.1), c.cor.lightened(0.35))
		Game.rounded_line(self, Rect2(px + 140, py + 82 + k * 19, 130, 10), 5, Color(1, 1, 1, 0.18), 1.0)
	for k in 4:
		var pid: String = c.poderes[k]
		var nome: String = Game.poder(pid).get("nome", pid)
		var xx := px + 28 + (k % 2) * 172
		var yy := py + 160 + (k / 2) * 26
		Game.poder_icone(self, Vector2(xx + 9, yy - 5), k, c.cor, 9.0)
		Game.text(self, nome, Vector2(xx + 24, yy), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 148, "bold")
	Game.text(self, "SUPREMO: " + c.supremo_nome, Vector2(px, py + 232), 14, Color("ffe2a0"), HORIZONTAL_ALIGNMENT_CENTER, 370, "ui")
	if pronto[p] and not (Game.modo == "arcade" and p == 1):
		Game.text_soft(self, "PRONTO!", Vector2(centro.x - 150, 150), 34, col, HORIZONTAL_ALIGNMENT_CENTER, 300, "ui")

func _misterio(centro: Vector2) -> void:
	draw_texture_rect(Game.dot_tex, Rect2(centro - Vector2(190, 170), Vector2(380, 340)), false, Color(0.8, 0.2, 0.6, 0.25))
	Game.text_soft(self, "?", Vector2(centro.x - 100, centro.y + 50), 160, Color(1, 1, 1, 0.35 + 0.1 * sin(t * 3.0)), HORIZONTAL_ALIGNMENT_CENTER, 200, "logo")
	var px := centro.x - 185
	var py := 452.0
	Game.text_soft(self, "6 RIVAIS + ???", Vector2(px, py + 44), 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 370, "ui")
	Game.text_wrap(self, "Vença 6 bottons em sequência, cada um na sua arena. A CPU fica mais forte a cada luta. No fim, algo sombrio espera por você…", Vector2(px + 24, py + 86), 322, 16, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER)
