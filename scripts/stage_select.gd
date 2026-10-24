extends Node2D
## Escolha da arena (com prévia ao vivo do cenário) — vidro líquido.

var bg: Node2D
var t := 0.0
var sel := 0
var sel_y := 0.0
var saindo := -1.0
var g_lista: Node2D
var g_pill: Node2D
var g_desc: Node2D
var g_vs: Node2D
var _bg_id := ""
const ALEATORIA := "ALEATÓRIA"
const LISTA := Rect2(40, 140, 420, 0)
const ITEM := 50.0

func _ready() -> void:
	sel = clampi(Game.arena, 0, Game.ARENAS.size() - 1) if Game.arena >= 0 else Game.ARENAS.size()
	sel_y = sel * ITEM
	_trocar_fundo()
	var n := _opcoes()
	g_lista = Game.glass(self, Rect2(LISTA.position, Vector2(LISTA.size.x, 28 + n * ITEM)), 28, Color(1, 1, 1, 0.08))
	g_pill = Game.glass(self, Rect2(), 22, Color(1, 1, 1, 0.22))
	g_pill.glow = 0.7
	g_pill.margin = 18
	g_desc = Game.glass(self, Rect2(40, 636, 1200, 52), 26, Color(1, 1, 1, 0.08))
	g_vs = Game.glass(self, Rect2(700, 380, 520, 230), 30, Color(1, 1, 1, 0.06))

func _opcoes() -> int:
	return Game.ARENAS.size() + 1

func _trocar_fundo() -> void:
	var id: String = Game.ARENAS[sel].id if sel < Game.ARENAS.size() else Game.ARENAS[int(t * 2.0) % Game.ARENAS.size()].id
	if id == _bg_id:
		return
	_bg_id = id
	if bg and is_instance_valid(bg):
		bg.queue_free()
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.arena = id
	bg.z_index = -3
	add_child(bg)

func _process(delta: float) -> void:
	t += delta
	sel_y = lerpf(sel_y, sel * ITEM, minf(1.0, delta * 16.0))
	var cor: Color = Game.ARENAS[sel].cor if sel < Game.ARENAS.size() else Color.WHITE
	g_pill.glow_color = cor
	g_pill.set_rect(Rect2(LISTA.position.x + 12, LISTA.position.y + 14 + sel_y, LISTA.size.x - 24, ITEM - 6))
	if saindo >= 0.0:
		saindo += delta
		if saindo > 0.5:
			Game.goto("res://scripts/versus.gd")
		queue_redraw()
		return
	var nv := Game.nav()
	if nv.y != 0:
		sel = wrapi(sel + nv.y, 0, _opcoes()); Game.play("select"); _trocar_fundo()
	elif Game.just("confirm"):
		Game.play("confirm")
		Game.arena = sel if sel < Game.ARENAS.size() else randi() % Game.ARENAS.size()
		saindo = 0.0
	elif Game.just("back"):
		Game.play("select")
		Game.goto("res://scripts/select.gd")
	if sel == Game.ARENAS.size() and int(t * 2.0) != int((t - delta) * 2.0):
		_trocar_fundo()
	queue_redraw()

func _draw() -> void:
	Game.text_soft(self, "ESCOLHA A ARENA", Vector2(0, 80), 42, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1280, "ui")
	for i in _opcoes():
		var y := LISTA.position.y + 14 + i * ITEM + 32
		var on := i == sel
		var nome: String = Game.ARENAS[i].nome if i < Game.ARENAS.size() else ALEATORIA
		var cor: Color = Game.ARENAS[i].cor if i < Game.ARENAS.size() else Color.WHITE
		draw_circle(Vector2(LISTA.position.x + 36, y - 7), 6, cor)
		Game.text_soft(self, nome, Vector2(LISTA.position.x + 54, y), 21 if on else 19, Color.WHITE if on else Color(1, 1, 1, 0.78), HORIZONTAL_ALIGNMENT_LEFT, -1, "ui", 0.35)
	var desc = "Uma arena surpresa." if sel >= Game.ARENAS.size() else Game.ARENAS[sel].desc
	Game.text(self, desc, Vector2(40, 669), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1200, "bold")
	Game.draw_char(self, Game.escolha[0], Vector2(830, 500), 180.0, false)
	Game.draw_char(self, Game.escolha[1], Vector2(1090, 500), 180.0, true)
	Game.text_soft(self, "VS", Vector2(910, 520), 46, Color("ffe2a0"), HORIZONTAL_ALIGNMENT_CENTER, 100, "logo")
	Game.prompts(self, Vector2(250, 112), [["confirm", "Lutar"], ["back", "Voltar"]], 0, 24.0)
	if saindo >= 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, clampf(saindo * 2.4, 0.0, 1.0)))
