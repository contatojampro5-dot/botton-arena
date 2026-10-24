extends Node2D
## Escolha da arena (com prévia ao vivo do cenário).

var bg: Node2D
var t := 0.0
var sel := 0
var saindo := -1.0
const ALEATORIA := "ALEATÓRIA"

func _ready() -> void:
	sel = clampi(Game.arena, 0, Game.ARENAS.size() - 1) if Game.arena >= 0 else Game.ARENAS.size()
	_trocar_fundo()

func _opcoes() -> int:
	return Game.ARENAS.size() + 1

func _trocar_fundo() -> void:
	if bg and is_instance_valid(bg):
		bg.queue_free()
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.arena = Game.ARENAS[sel].id if sel < Game.ARENAS.size() else Game.ARENAS[int(t * 2.0) % Game.ARENAS.size()].id
	bg.z_index = -2
	add_child(bg)

func _process(delta: float) -> void:
	t += delta
	if saindo >= 0.0:
		saindo += delta
		if saindo > 0.5:
			Game.goto("res://scripts/versus.gd")
		queue_redraw()
		return
	if Game.just("up"):
		sel = wrapi(sel - 1, 0, _opcoes()); Game.play("select"); _trocar_fundo()
	elif Game.just("down"):
		sel = wrapi(sel + 1, 0, _opcoes()); Game.play("select"); _trocar_fundo()
	elif Game.just("confirm"):
		Game.play("confirm")
		Game.arena = sel if sel < Game.ARENAS.size() else randi() % Game.ARENAS.size()
		saindo = 0.0
	elif Game.just("back"):
		Game.play("select")
		Game.goto("res://scripts/select.gd")
	# aleatória: o fundo fica trocando
	if sel == Game.ARENAS.size() and int(t * 2.0) != int((t - delta) * 2.0):
		_trocar_fundo()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 120), Color(0, 0, 0, 0.45))
	Game.text(self, "ESCOLHA A ARENA", Vector2(0, 75), 52, Color("fff6e0"), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 12, Color("2a1250"))
	var r := Rect2(40, 150, 420, 60 + _opcoes() * 50)
	draw_rect(r, Color(0.04, 0.02, 0.1, 0.82))
	draw_rect(r, Color("6fd0ff"), false, 2)
	for i in _opcoes():
		var y := 195 + i * 50
		var on := i == sel
		var nome: String = Game.ARENAS[i].nome if i < Game.ARENAS.size() else ALEATORIA
		var cor: Color = Game.ARENAS[i].cor if i < Game.ARENAS.size() else Color.WHITE
		if on:
			draw_rect(Rect2(52, y - 32, 396, 44), Color(cor, 0.25))
			draw_rect(Rect2(52, y - 32, 6, 44), cor)
		Game.text(self, nome, Vector2(75, y), 26, Color("ffd36b") if on else Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_LEFT, -1, true, 5)
	var desc = "Uma arena surpresa." if sel >= Game.ARENAS.size() else Game.ARENAS[sel].desc
	draw_rect(Rect2(40, 640, 1200, 50), Color(0.04, 0.02, 0.1, 0.75))
	Game.text(self, desc, Vector2(40, 673), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1200, false, 3)
	# lutadores escolhidos no canto
	Game.draw_char(self, Game.escolha[0], Vector2(820, 520), 170.0, false)
	Game.draw_char(self, Game.escolha[1], Vector2(1080, 520), 170.0, true)
	Game.text(self, "VS", Vector2(900, 540), 48, Color("ffd36b"), HORIZONTAL_ALIGNMENT_CENTER, 100, true, 10)
	if saindo >= 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, clampf(saindo * 2.4, 0.0, 1.0)))
