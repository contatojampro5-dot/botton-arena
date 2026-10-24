extends Node2D
## Galeria: a ficha original de cada botton, com especial, supremo e atributos.

var bg: Node2D
var t := 0.0
var sel := 0
var fichas := {}
var troca := 0.0

func _ready() -> void:
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.arena = "santuario"
	bg.dim = 0.7
	bg.z_index = -2
	add_child(bg)
	for c in Game.ROSTER:
		var p := "res://assets/galeria/%s.jpg" % c.id
		if ResourceLoader.exists(p):
			fichas[c.id] = load(p)

func _process(delta: float) -> void:
	t += delta
	troca = maxf(0.0, troca - delta * 5.0)
	var n := Game.ROSTER.size()
	if Game.just("left") or Game.just("up"):
		sel = wrapi(sel - 1, 0, n); troca = 1.0; Game.play("select")
	elif Game.just("right") or Game.just("down"):
		sel = wrapi(sel + 1, 0, n); troca = 1.0; Game.play("select")
	elif Game.just("back") or Game.just("confirm"):
		Game.play("select")
		Game.goto("res://scripts/title.gd")
	queue_redraw()

func _draw() -> void:
	var c: Dictionary = Game.ROSTER[sel]
	var cor: Color = c.cor
	Game.text(self, "GALERIA DOS BOTTONS", Vector2(0, 52), 40, Color("fff6e0"), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 10, Color("2a1250"))
	# ficha original
	var r := Rect2(40, 75, 620, 620)
	draw_rect(r.grow(6), Color(cor, 0.6))
	if fichas.has(c.id):
		var off := Vector2(30.0 * troca, 0)
		draw_texture_rect(fichas[c.id], Rect2(r.position + off, r.size), false, Color(1, 1, 1, 1.0 - troca * 0.6))
	else:
		Game.draw_char(self, sel, r.get_center(), 500.0)
	# informações
	var x := 700.0
	var w := 540.0
	draw_rect(Rect2(x - 20, 75, w + 40, 620), Color(0.04, 0.02, 0.1, 0.88))
	draw_rect(Rect2(x - 20, 75, w + 40, 5), cor)
	Game.text(self, c.nome, Vector2(x, 128), 38, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, w, true, 8)
	Game.text(self, "Núcleo de %s" % c.nucleo, Vector2(x, 162), 22, cor.lightened(0.35), HORIZONTAL_ALIGNMENT_LEFT, w, false)
	Game.text_wrap(self, "“%s”" % c.frase, Vector2(x, 200), w, 20, Color(1, 1, 1, 0.8))
	var labels := [["VELOCIDADE", c.vel], ["FORÇA", c.forca], ["DEFESA", c.def]]
	for k in 3:
		Game.text(self, labels[k][0], Vector2(x, 270 + k * 28), 18, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_LEFT, -1, false)
		Game.stat_bar(self, Vector2(x + 150, 258 + k * 28), labels[k][1], cor)
	if c.pulo_duplo:
		Game.text(self, "Pulo duplo", Vector2(x + 300, 298), 18, cor.lightened(0.4), HORIZONTAL_ALIGNMENT_LEFT, -1, true, 3)
	Game.text(self, "ESPECIAL", Vector2(x, 380), 18, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_LEFT, -1, true, 3)
	Game.text(self, c.especial_nome, Vector2(x, 410), 28, cor.lightened(0.35), HORIZONTAL_ALIGNMENT_LEFT, w, true, 5)
	Game.text_wrap(self, c.especial_desc, Vector2(x, 438), w, 18, Color(1, 1, 1, 0.85))
	Game.text(self, "SUPREMO", Vector2(x, 510), 18, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_LEFT, -1, true, 3)
	Game.text(self, c.supremo_nome, Vector2(x, 540), 28, Color("ffd36b"), HORIZONTAL_ALIGNMENT_LEFT, w, true, 5)
	Game.text_wrap(self, c.supremo_desc, Vector2(x, 568), w, 18, Color(1, 1, 1, 0.85))
	var arena_nome: String = Game.ARENAS[Game.arena_index(c.casa)].nome
	Game.text(self, "Arena: " + arena_nome, Vector2(x, 650), 17, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_LEFT, w, false)
	Game.text(self, "%d / %d" % [sel + 1, Game.ROSTER.size()], Vector2(x, 650), 17, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_RIGHT, w, false)
	Game.text(self, "◀ ▶ trocar de botton   •   Enter ou Esc para voltar", Vector2(0, 712), 16, Color(1, 1, 1, 0.55), HORIZONTAL_ALIGNMENT_CENTER, 1280, false)
