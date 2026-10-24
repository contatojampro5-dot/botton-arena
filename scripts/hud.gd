extends Node2D
## Interface da luta: vida, Núcleo, tempo, rounds, avisos e menus.

var fight: Node
var t := 0.0
var combo_show := [0, 0]
var combo_t := [0.0, 0.0]

func _process(delta: float) -> void:
	t += delta
	for i in 2:
		var tgt: Node2D = fight.fighters[1 - i]
		if tgt.combo_taken >= 2:
			combo_show[i] = tgt.combo_taken
			combo_t[i] = 1.2
		else:
			combo_t[i] = max(0.0, combo_t[i] - delta)
	queue_redraw()

func _draw() -> void:
	if fight == null: return
	for i in 2:
		_player_bar(i)
	# tempo
	var c := Vector2(640, 52)
	draw_circle(c, 40, Color(0.05, 0.03, 0.12, 0.9))
	draw_arc(c, 40, 0, TAU, 40, Color("ffd36b"), 3)
	var tempo := int(ceil(fight.time_left))
	Game.text(self, str(tempo), Vector2(590, 68), 44, Color("fff6e0") if tempo > 10 else Color("ff5a5a"), HORIZONTAL_ALIGNMENT_CENTER, 100, true, 6)
	# combos
	for i in 2:
		if combo_t[i] > 0.0:
			var a := clampf(combo_t[i] * 3.0, 0.0, 1.0)
			var x := 70.0 if i == 0 else 960.0
			Game.text(self, "%d GOLPES" % combo_show[i], Vector2(x, 210), 40, Color(1, 0.85, 0.3, a), HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT, 250, true, 8, Color(0.25, 0.05, 0.05, a))
	# avisos centrais
	if fight.banner != "":
		var a2 := clampf(fight.banner_t * 4.0, 0.0, 1.0)
		var sz := 96 if fight.banner.length() < 10 else 64
		var dy := -150.0 if fight.menu_open and fight.menu_kind == "end" else 0.0
		draw_rect(Rect2(0, 300 + dy, 1280, 130), Color(0, 0, 0, 0.45 * a2))
		Game.text(self, fight.banner, Vector2(0, 395 + dy), sz, Color(fight.banner_cor, a2), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 16, Color(0.1, 0.03, 0.15, a2))
		if fight.banner_sub != "":
			Game.text(self, fight.banner_sub, Vector2(0, 448 + dy), 28, Color(1, 1, 1, a2), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 6)
	if fight.menu_open:
		_menu()

func _player_bar(i: int) -> void:
	var f: Node2D = fight.fighters[i]
	var left := i == 0
	var cor: Color = f.data.cor
	# retrato
	var pc := Vector2(62 if left else 1218, 58)
	draw_circle(pc, 48, Color(0.05, 0.03, 0.12, 0.95))
	draw_circle(pc, 44, Color(cor, 0.35))
	var tx: Texture2D = f.spr.texture
	var s := tx.get_size()
	var k := 92.0 / maxf(s.x, s.y)
	var sz := s * k
	draw_set_transform(pc, 0.0, Vector2(1.0 if left else -1.0, 1.0))
	draw_texture_rect(tx, Rect2(-sz / 2, sz), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_arc(pc, 47, 0, TAU, 40, Color("4aa8ff") if left else Color("ff4a5a"), 4)
	# barra de vida
	var bw := 460.0
	var x0 := 118.0 if left else 1280.0 - 118.0 - bw
	var y0 := 30.0
	draw_rect(Rect2(x0 - 3, y0 - 3, bw + 6, 32), Color(0.05, 0.03, 0.12, 0.95))
	draw_rect(Rect2(x0, y0, bw, 26), Color(0.25, 0.08, 0.12))
	var ratio_shown: float = f.hp_shown / f.MAX_HP
	var ratio: float = f.hp / f.MAX_HP
	var chip_w := bw * ratio_shown
	var fill_w := bw * ratio
	var fill_col := Color("ffd23a").lerp(Color("ff4a3a"), clampf(1.0 - ratio * 2.0, 0.0, 1.0))
	if left:
		draw_rect(Rect2(x0 + bw - chip_w, y0, chip_w, 26), Color(1, 1, 1, 0.85))
		draw_rect(Rect2(x0 + bw - fill_w, y0, fill_w, 26), fill_col)
		draw_rect(Rect2(x0 + bw - fill_w, y0, fill_w, 8), Color(1, 1, 1, 0.3))
	else:
		draw_rect(Rect2(x0, y0, chip_w, 26), Color(1, 1, 1, 0.85))
		draw_rect(Rect2(x0, y0, fill_w, 26), fill_col)
		draw_rect(Rect2(x0, y0, fill_w, 8), Color(1, 1, 1, 0.3))
	# nome
	var nome: String = f.data.nome
	if Game.modo == "cpu" and i == 1: nome += "  (CPU)"
	Game.text(self, nome, Vector2(x0, y0 + 56), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT, bw, true, 6)
	# rounds vencidos
	for k2 in 2:
		var pp := Vector2((560.0 - k2 * 26.0) if left else (720.0 + k2 * 26.0), 82)
		var won: bool = fight.round_wins[i] > k2
		draw_circle(pp, 9, Color(0.05, 0.03, 0.12, 0.9))
		draw_circle(pp, 6, Color("ffd36b") if won else Color(1, 1, 1, 0.15))
	# Núcleo (barra de energia)
	var nw := 300.0
	var nx := 40.0 if left else 1280.0 - 40.0 - nw
	var ny := 672.0
	draw_rect(Rect2(nx - 3, ny - 3, nw + 6, 22), Color(0.05, 0.03, 0.12, 0.9))
	var nr: float = f.nucleo / 100.0
	var full: bool = nr >= 1.0
	var ncol := cor.lightened(0.2) if not full else cor.lightened(0.2 + 0.3 * (0.5 + 0.5 * sin(t * 10.0)))
	if left: draw_rect(Rect2(nx, ny, nw * nr, 16), ncol)
	else: draw_rect(Rect2(nx + nw * (1.0 - nr), ny, nw * nr, 16), ncol)
	for q in range(1, 4):
		draw_line(Vector2(nx + nw * q / 4.0, ny), Vector2(nx + nw * q / 4.0, ny + 16), Color(0, 0, 0, 0.5), 2)
	var lbl := "NÚCLEO"
	if full: lbl = "SUPREMO PRONTO!  [%s]" % ("T" if left else "P")
	Game.text(self, lbl, Vector2(nx, ny - 8), 20, Color("ffd36b") if full else Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT, nw, true, 5)

func _menu() -> void:
	var opts: Array = fight.menu_opts
	var h := 80 + opts.size() * 50
	var cy := 360.0
	if fight.menu_kind == "pause":
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.55))
	else:
		cy = 480.0
	var r := Rect2(440, cy - h / 2.0, 400, h)
	draw_rect(r, Color(0.05, 0.03, 0.12, 0.95))
	draw_rect(r, Color("6fd0ff"), false, 2)
	Game.text(self, fight.menu_title, Vector2(r.position.x, r.position.y + 50), 36, Color("ffd36b"), HORIZONTAL_ALIGNMENT_CENTER, 400, true, 6)
	for i in opts.size():
		var y := r.position.y + 100 + i * 50
		var on: bool = i == fight.menu_sel
		if on:
			draw_rect(Rect2(r.position.x + 20, y - 32, 360, 42), Color("6fd0ff", 0.22))
		Game.text(self, opts[i], Vector2(r.position.x, y), 30, Color("ffd36b") if on else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 400)
