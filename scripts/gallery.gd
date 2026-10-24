extends Node2D
## Galeria (vidro líquido): a ficha original de cada botton, tipo, poderes e supremo.

var bg: Node2D
var t := 0.0
var sel := 0
var fichas := {}
var troca := 0.0
var g_frame: Node2D
var g_info: Node2D

func _ready() -> void:
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.arena = "santuario"
	bg.dim = 0.55
	bg.z_index = -3
	add_child(bg)
	for c in Game.ROSTER:
		var p := "res://assets/galeria/%s.jpg" % c.id
		if ResourceLoader.exists(p):
			fichas[c.id] = load(p)
	g_frame = Game.glass(self, Rect2(30, 70, 610, 610), 30, Color(1, 1, 1, 0.1))
	g_info = Game.glass(self, Rect2(668, 70, 582, 610), 30, Color(1, 1, 1, 0.08))

func _process(delta: float) -> void:
	t += delta
	troca = maxf(0.0, troca - delta * 5.0)
	var n := Game.ROSTER.size()
	var nv := Game.nav()
	if nv.x != 0 or nv.y != 0:
		sel = wrapi(sel + (nv.x if nv.x != 0 else nv.y), 0, n); troca = 1.0; Game.play("select")
	elif Game.just("back") or Game.just("confirm"):
		Game.play("select")
		Game.goto("res://scripts/title.gd")
	var c: Dictionary = Game.ROSTER[sel]
	g_frame.glow = 0.5
	g_frame.glow_color = c.cor
	queue_redraw()

func _draw() -> void:
	var c: Dictionary = Game.ROSTER[sel]
	var cor: Color = c.cor
	Game.text_soft(self, "GALERIA DOS BOTTONS", Vector2(0, 50), 32, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1280, "ui")
	var r := Rect2(45, 85, 580, 580)
	if fichas.has(c.id):
		var off := Vector2(24.0 * troca, 0)
		draw_texture_rect(fichas[c.id], Rect2(r.position + off, r.size), false, Color(1, 1, 1, 1.0 - troca * 0.6))
	else:
		Game.draw_char(self, sel, r.get_center(), 480.0)
	var x := 700.0
	var w := 520.0
	Game.text_soft(self, c.nome, Vector2(x, 122), 32, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, w, "ui")
	var sw := Game.tipo_selo(self, Vector2(x, 150), c.tipo, 26)
	Game.text(self, "Núcleo de %s" % c.nucleo, Vector2(x + sw + 12, 156), 17, cor.lightened(0.35), HORIZONTAL_ALIGNMENT_LEFT, -1, "bold")
	Game.text_wrap(self, "“%s”" % c.frase, Vector2(x, 194), w, 17, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT, "corpo")
	var fortes: Array = Game.TIPOS[c.tipo].forte
	var fracos: Array = Game.fraquezas(c.tipo)
	Game.text(self, "FORTE CONTRA", Vector2(x, 248), 13, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_LEFT, -1, "ui")
	var xx := x + 112
	for tp in fortes:
		xx += Game.tipo_selo(self, Vector2(xx, 243), tp, 20) + 6
	Game.text(self, "FRACO CONTRA", Vector2(x, 274), 13, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_LEFT, -1, "ui")
	xx = x + 112
	for tp in fracos:
		xx += Game.tipo_selo(self, Vector2(xx, 269), tp, 20) + 6
	var labels := [["VELOCIDADE", c.vel], ["FORÇA", c.forca], ["DEFESA", c.def]]
	for k in 3:
		Game.text(self, labels[k][0], Vector2(x + 300, 236 + k * 18), 12, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_LEFT, -1, "bold")
		Game.rounded(self, Rect2(x + 400, 227 + k * 18, 110, 9), 4.5, Color(0.03, 0.02, 0.08, 0.55))
		Game.capsula(self, Rect2(x + 400, 227 + k * 18, 110, 9), labels[k][1] / 5.0, cor.darkened(0.1), cor.lightened(0.35))
	Game.text(self, "PODERES", Vector2(x, 316), 15, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_LEFT, -1, "ui")
	var entradas := ["H", "→ + H", "↑ + H", "↓ + H"]
	for k in 4:
		var pid: String = c.poderes[k]
		var pd: Dictionary = Game.poder(pid)
		var y := 350.0 + k * 62.0
		Game.rounded(self, Rect2(x - 8, y - 26, w + 16, 56), 18, Color(1, 1, 1, 0.05))
		Game.poder_icone(self, Vector2(x + 16, y - 2), k, cor, 15.0)
		Game.text(self, pd.get("nome", pid), Vector2(x + 42, y), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 330, "ui")
		Game.text(self, entradas[k], Vector2(x + w - 90, y), 15, Color("bfefff"), HORIZONTAL_ALIGNMENT_RIGHT, 90, "ui")
		Game.text(self, pd.get("desc", ""), Vector2(x + 42, y + 21), 14, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_LEFT, w - 50, "corpo")
	Game.text(self, "SUPREMO  •  " + c.supremo_nome, Vector2(x, 612), 18, Color("ffe2a0"), HORIZONTAL_ALIGNMENT_LEFT, w, "ui")
	Game.text(self, c.supremo_desc, Vector2(x, 636), 14, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT, w, "corpo")
	Game.text(self, "%d / %d" % [sel + 1, Game.ROSTER.size()], Vector2(x, 664), 14, Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_RIGHT, w, "bold")
	Game.prompts(self, Vector2(640, 704), [["lr", "Trocar"], ["back", "Voltar"]], 0, 22.0)
