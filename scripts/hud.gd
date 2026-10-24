extends Node2D
## Interface da luta: vida, Núcleo, Sobrecarga, tempo, rounds, avisos, câmera do supremo, treino e menus.

var fight: Node
var t := 0.0
var combo_show := [0, 0]
var combo_t := [0.0, 0.0]
var frase := ""

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
	if fight.cutin.size() > 0:
		_cutin()
	for i in 2:
		_player_bar(i)
	# tempo
	var c := Vector2(640, 52)
	draw_circle(c, 40, Color(0.05, 0.03, 0.12, 0.9))
	draw_arc(c, 40, 0, TAU, 40, Color("ffd36b"), 3)
	if fight.round_time > 0.0:
		var tempo := int(ceil(fight.time_left))
		Game.text(self, str(tempo), Vector2(590, 68), 44, Color("fff6e0") if tempo > 10 else Color("ff5a5a"), HORIZONTAL_ALIGNMENT_CENTER, 100, true, 6)
	else:
		Game.text(self, "--", Vector2(590, 66), 40, Color("fff6e0"), HORIZONTAL_ALIGNMENT_CENTER, 100, true, 6)
	if Game.modo == "arcade" and not Game.arcade.is_empty():
		var etapa: int = Game.arcade.etapa + 1
		var total: int = Game.arcade.escada.size()
		Game.text(self, "LUTA %d/%d" % [mini(etapa, total), total], Vector2(540, 112), 20, Color("ffd36b"), HORIZONTAL_ALIGNMENT_CENTER, 200, true, 5)
	# combos
	for i in 2:
		if combo_t[i] > 0.0:
			var a := clampf(combo_t[i] * 3.0, 0.0, 1.0)
			var x := 70.0 if i == 0 else 960.0
			Game.text(self, "%d GOLPES" % combo_show[i], Vector2(x, 210), 40, Color(1, 0.85, 0.3, a), HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT, 250, true, 8, Color(0.25, 0.05, 0.05, a))
	if Game.modo == "treino":
		_treino_panel()
	# avisos centrais
	if fight.banner != "":
		var a2 := clampf(fight.banner_t * 4.0, 0.0, 1.0)
		var sz := 96 if fight.banner.length() < 10 else (72 if fight.banner.length() < 18 else 52)
		var dy := -170.0 if fight.menu_open and fight.menu_kind in ["end", "continue"] else 0.0
		draw_rect(Rect2(0, 300 + dy, 1280, 130), Color(0, 0, 0, 0.45 * a2))
		Game.text(self, fight.banner, Vector2(0, 395 + dy), sz, Color(fight.banner_cor, a2), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 16, Color(0.1, 0.03, 0.15, a2))
		if fight.banner_sub != "":
			Game.text(self, fight.banner_sub, Vector2(0, 448 + dy), 28, Color(1, 1, 1, a2), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 6)
		if frase != "" and dy != 0.0:
			Game.text(self, "“%s”" % frase, Vector2(0, 480 + dy), 20, Color(1, 1, 1, 0.75 * a2), HORIZONTAL_ALIGNMENT_CENTER, 1280, false, 4)
	if fight.menu_open:
		if fight.menu_kind == "golpes":
			_golpes()
		else:
			_menu()

func _player_bar(i: int) -> void:
	var f: Node2D = fight.fighters[i]
	var left := i == 0
	var cor: Color = f.data.cor
	# retrato
	var pc := Vector2(62 if left else 1218, 58)
	draw_circle(pc, 48, Color(0.05, 0.03, 0.12, 0.95))
	draw_circle(pc, 44, Color(cor, 0.35))
	var tx: Texture2D = Game.textures[f.data.id]
	var s := tx.get_size()
	var k := 92.0 / maxf(s.x, s.y)
	var sz := s * k
	draw_set_transform(pc, 0.0, Vector2(1.0 if left else -1.0, 1.0))
	draw_texture_rect(tx, Rect2(-sz / 2, sz), false, Color(0.55, 0.3, 0.7) if f.eco else Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_arc(pc, 47, 0, TAU, 40, Color("4aa8ff") if left else Color("ff4a5a"), 4)
	# barra de vida
	var bw := 460.0
	var x0 := 118.0 if left else 1280.0 - 118.0 - bw
	var y0 := 30.0
	draw_rect(Rect2(x0 - 3, y0 - 3, bw + 6, 32), Color(0.05, 0.03, 0.12, 0.95))
	draw_rect(Rect2(x0, y0, bw, 26), Color(0.25, 0.08, 0.12))
	var ratio_shown: float = clampf(f.hp_shown / f.max_hp, 0.0, 1.0)
	var ratio: float = clampf(f.hp / f.max_hp, 0.0, 1.0)
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
	if f.eco: nome = "ECO SOMBRIO"
	elif (Game.modo in ["cpu", "arcade"] and i == 1): nome += "  (CPU)"
	elif Game.modo == "treino" and i == 1: nome += "  (BONECO)"
	Game.text(self, nome, Vector2(x0, y0 + 56), 22, Color.WHITE if not f.eco else Color("ff7ab0"), HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT, bw, true, 6)
	# rounds vencidos
	if Game.modo != "treino":
		for k2 in fight.rounds_to_win:
			var pp := Vector2((560.0 - k2 * 26.0) if left else (720.0 + k2 * 26.0), 82)
			var won: bool = fight.round_wins[i] > k2
			draw_circle(pp, 9, Color(0.05, 0.03, 0.12, 0.9))
			draw_circle(pp, 6, Color("ffd36b") if won else Color(1, 1, 1, 0.15))
	# Núcleo (barra de energia)
	var nw := 300.0
	var nx := 40.0 if left else 1280.0 - 40.0 - nw
	var ny := 672.0
	draw_rect(Rect2(nx - 3, ny - 3, nw + 6, 22), Color(0.05, 0.03, 0.12, 0.9))
	var nr: float = clampf(f.nucleo / 100.0, 0.0, 1.0)
	var full: bool = nr >= 1.0
	var ncol := cor.lightened(0.2) if not full else cor.lightened(0.2 + 0.3 * (0.5 + 0.5 * sin(t * 10.0)))
	if left: draw_rect(Rect2(nx, ny, nw * nr, 16), ncol)
	else: draw_rect(Rect2(nx + nw * (1.0 - nr), ny, nw * nr, 16), ncol)
	for q in range(1, 4):
		draw_line(Vector2(nx + nw * q / 4.0, ny), Vector2(nx + nw * q / 4.0, ny + 16), Color(0, 0, 0, 0.5), 2)
	draw_line(Vector2(nx + nw * 0.5, ny - 3), Vector2(nx + nw * 0.5, ny + 19), Color(1, 1, 1, 0.6), 2)
	var lbl := "NÚCLEO"
	if full: lbl = "SUPREMO PRONTO!  [%s]" % ("T" if left else "P")
	elif nr >= 0.5: lbl = "NÚCLEO  •  SOBRECARGA [%s]" % ("G+H" if left else "L+Ç")
	Game.text(self, lbl, Vector2(nx, ny - 8), 19, Color("ffd36b") if full else Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT, nw, true, 5)
	# Sobrecarga ativa
	if f.overload_t > 0:
		var ow = nw * f.overload_t / 360.0
		var oy := ny + 22
		draw_rect(Rect2(nx, oy, nw, 5), Color(0, 0, 0, 0.5))
		if left: draw_rect(Rect2(nx, oy, ow, 5), Color("ffffff"))
		else: draw_rect(Rect2(nx + nw - ow, oy, ow, 5), Color("ffffff"))
		Game.text(self, "SOBRECARGA", Vector2(nx, ny - 32), 22, cor.lightened(0.5 + 0.3 * sin(t * 12.0)), HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT, nw, true, 6)

## Faixa cinematográfica do supremo (estilo anime)
func _cutin() -> void:
	var f: Node2D = fight.cutin.f
	var k: float = fight.cutin.t / float(f.SUPER_STARTUP)
	var open := clampf(fight.cutin.t / 8.0, 0.0, 1.0)
	var close := clampf((f.SUPER_STARTUP - fight.cutin.t) / 8.0, 0.0, 1.0)
	var a := minf(open, close)
	if a <= 0.01:
		return
	var hgt := 190.0 * a
	var cy := 330.0
	var cor: Color = f.data.cor if not f.eco else Color("ff3a8a")
	draw_rect(Rect2(0, cy - hgt / 2.0, 1280, hgt), Color(cor.darkened(0.6), 0.92))
	# linhas de velocidade
	for i in 22:
		var y := cy - hgt / 2.0 + fmod(i * 37.0, hgt)
		var x := fmod(i * 233.0 - fight.cutin.t * 60.0 * (1 if f.facing == 1 else -1), 1500.0) - 100.0
		draw_line(Vector2(x, y), Vector2(x + 220.0, y), Color(cor.lightened(0.4), 0.35 * a), 3)
	draw_rect(Rect2(0, cy - hgt / 2.0, 1280, 4), Color(cor.lightened(0.5), a))
	draw_rect(Rect2(0, cy + hgt / 2.0 - 4, 1280, 4), Color(cor.lightened(0.5), a))
	# retrato entrando pelo lado
	var side: float = -1.0 if f.position.x < 640 else 1.0
	var px := 640.0 + side * (380.0 + 300.0 * (1.0 - open))
	var idx_r: int = Game.escolha[f.idx]
	Game.draw_char(self, idx_r, Vector2(px, cy + 10), 260.0 * a, side > 0, Color(0.55, 0.3, 0.7) if f.eco else Color.WHITE)
	# nome do supremo
	var nome: String = f.data.supremo_nome
	var tx := 640.0 - side * 120.0
	Game.text(self, "SUPREMO", Vector2(tx - 400, cy - 30), 26, Color(1, 1, 1, 0.8 * a), HORIZONTAL_ALIGNMENT_CENTER, 800, true, 5)
	var esc := 1.0 + 0.08 * sin(k * PI)
	Game.text(self, nome, Vector2(tx - 400, cy + 40), int(64 * esc), Color(cor.lightened(0.45), a), HORIZONTAL_ALIGNMENT_CENTER, 800, true, 14, Color(0.05, 0.02, 0.08, a))

func _treino_panel() -> void:
	var r := Rect2(500, 120, 280, 92)
	draw_rect(r, Color(0.05, 0.03, 0.12, 0.75))
	draw_rect(r, Color("6fd0ff", 0.6), false, 2)
	var info: Dictionary = fight.treino_info
	Game.text(self, "TREINO  •  BONECO: %s" % Game.TREINO_BONECO[Game.treino.boneco], Vector2(r.position.x, r.position.y + 24), 18, Color("6fd0ff"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, true, 4)
	Game.text(self, "Combo: %d golpes  •  %d de dano" % [info.hits, int(info.dano)], Vector2(r.position.x, r.position.y + 50), 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, false)
	Game.text(self, "Recorde: %d golpes  •  %d de dano" % [info.max_hits, int(info.max_dano)], Vector2(r.position.x, r.position.y + 74), 16, Color("ffd36b"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, false)

func _menu() -> void:
	var opts: Array = fight.menu_opts
	var h := 80 + opts.size() * 50
	var cy := 360.0
	var w := 460.0
	if fight.menu_kind == "pause":
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.55))
	else:
		cy = 500.0
	var r := Rect2(640 - w / 2, cy - h / 2.0, w, h)
	draw_rect(r, Color(0.05, 0.03, 0.12, 0.95))
	draw_rect(r, Color("6fd0ff"), false, 2)
	Game.text(self, fight.menu_title, Vector2(r.position.x, r.position.y + 50), 36, Color("ffd36b"), HORIZONTAL_ALIGNMENT_CENTER, w, true, 6)
	for i in opts.size():
		var y := r.position.y + 100 + i * 50
		var on: bool = i == fight.menu_sel
		if on:
			draw_rect(Rect2(r.position.x + 20, y - 32, w - 40, 42), Color("6fd0ff", 0.22))
		Game.text(self, opts[i], Vector2(r.position.x, y), 28, Color("ffd36b") if on else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, w)

func _golpes() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.02, 0.01, 0.06, 0.92))
	Game.text(self, "LISTA DE GOLPES", Vector2(0, 60), 44, Color("ffd36b"), HORIZONTAL_ALIGNMENT_CENTER, 1280, true, 8)
	for i in 2:
		var f: Node2D = fight.fighters[i]
		var x := 60.0 + i * 600.0
		var cor: Color = f.data.cor
		var k1 := "F" if i == 0 else "K"
		var k2 := "G" if i == 0 else "L"
		var k3 := "H" if i == 0 else "Ç"
		var k4 := "T" if i == 0 else "P"
		var k5 := "R" if i == 0 else "O"
		draw_rect(Rect2(x, 90, 560, 560), Color(cor.darkened(0.7), 0.6))
		draw_rect(Rect2(x, 90, 560, 4), cor)
		Game.text(self, ("J1  •  " if i == 0 else "J2  •  ") + f.data.nome, Vector2(x + 20, 132), 26, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, true, 5)
		var linhas := [
			["Ataque leve", k1, ""],
			["Ataque pesado", k2, ""],
			["Combo lançador", "%s, %s, %s" % [k1, k1, k2], "Lança o rival para o ar"],
			["Defesa / Perfeito", k5, "Defender bem na hora: PERFEITO!"],
			["ESPECIAL: " + f.data.especial_nome, k3, f.data.especial_desc],
			["SUPREMO: " + f.data.supremo_nome.capitalize(), k4, f.data.supremo_desc + " (Núcleo cheio)"],
			["Sobrecarga", "%s + %s" % [k2, k3], "50% de Núcleo: +20% de dano e velocidade por 6 s"],
			["Explosão de Núcleo", "%s + %s" % [k2, k3], "Apanhando: escapa do combo (50% de Núcleo)"],
		]
		for j in linhas.size():
			var y := 175.0 + j * 58.0
			var destaque: bool = j in [4, 5]
			Game.text(self, linhas[j][0], Vector2(x + 20, y), 20, cor.lightened(0.4) if destaque else Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 400, true, 4)
			Game.text(self, linhas[j][1], Vector2(x + 380, y), 20, Color("ffd36b"), HORIZONTAL_ALIGNMENT_RIGHT, 160, true, 4)
			if linhas[j][2] != "":
				Game.text(self, linhas[j][2], Vector2(x + 20, y + 22), 15, Color(1, 1, 1, 0.65), HORIZONTAL_ALIGNMENT_LEFT, 520, false)
	Game.text(self, "Enter ou Esc para voltar", Vector2(0, 690), 18, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 1280, false)
