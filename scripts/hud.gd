extends Node2D
## Interface da luta (vidro líquido): vida, Núcleo, poderes com recarga, tempo, rounds, avisos,
## faixa do supremo, treino, pausa, fim de luta e lista de golpes.

var fight: Node
var t := 0.0
var combo_show := [0, 0]
var combo_t := [0.0, 0.0]
var frase := ""
var menu_y := 0.0
var g := {}
var veu: ColorRect
var _cd_antes := [[0, 0, 0, 0], [0, 0, 0, 0]]
var _pronto_t := [[0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0]]

const BASE_W := 440.0

func _ready() -> void:
	veu = ColorRect.new()
	veu.color = Color(0.0, 0.0, 0.03, 0.42)
	veu.size = Vector2(1280, 720)
	veu.z_index = -2
	veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veu.visible = false
	add_child(veu)
	var c0: Color = fight.fighters[0].data.cor
	var c1: Color = fight.fighters[1].data.cor
	g.vida0 = Game.glass(self, Rect2(112, 24, 470, 36), 18, Color(1, 1, 1, 0.08))
	g.vida1 = Game.glass(self, Rect2(1280 - 112 - 470, 24, 470, 36), 18, Color(1, 1, 1, 0.08))
	g.ret0 = Game.glass(self, Rect2(14, 10, 96, 96), 48, Color(c0, 0.2))
	g.ret1 = Game.glass(self, Rect2(1170, 10, 96, 96), 48, Color(c1, 0.2))
	g.tempo = Game.glass(self, Rect2(598, 10, 84, 84), 42, Color(1, 1, 1, 0.12))
	g.base0 = Game.glass(self, Rect2(24, 632, BASE_W, 70), 30, Color(1, 1, 1, 0.07))
	g.base1 = Game.glass(self, Rect2(1280 - 24 - BASE_W, 632, BASE_W, 70), 30, Color(1, 1, 1, 0.07))
	g.combo0 = Game.glass(self, Rect2(40, 182, 220, 50), 25, Color(1, 0.8, 0.3, 0.12))
	g.combo1 = Game.glass(self, Rect2(1020, 182, 220, 50), 25, Color(1, 0.8, 0.3, 0.12))
	g.faixa = Game.glass(self, Rect2(-40, 300, 1360, 130), 0, Color(0.05, 0.03, 0.12, 0.32))
	g.faixa.margin = 10
	g.cutin = Game.glass(self, Rect2(-40, 235, 1360, 190), 0, Color(0.2, 0.2, 0.3, 0.4))
	g.cutin.margin = 10
	g.treino = Game.glass(self, Rect2(470, 112, 340, 92), 26, Color(1, 1, 1, 0.08))
	g.menu = Game.glass(self, Rect2(), 30, Color(0.1, 0.1, 0.2, 0.22))
	g.pill = Game.glass(self, Rect2(), 20, Color(1, 1, 1, 0.22))
	g.pill.glow = 0.6
	g.pill.glow_color = Color("7fd8ff")
	g.pill.margin = 16
	g.golpes = Game.glass(self, Rect2(30, 30, 1220, 660), 34, Color(0.04, 0.03, 0.1, 0.6))
	g.col0 = Game.glass(self, Rect2(60, 96, 565, 552), 26, Color(c0.darkened(0.75), 0.62))
	g.col1 = Game.glass(self, Rect2(655, 96, 565, 552), 26, Color(c1.darkened(0.75), 0.62))
	for k in ["combo0", "combo1", "faixa", "cutin", "menu", "pill", "golpes", "col0", "col1", "treino"]:
		g[k].visible = false

func _process(delta: float) -> void:
	if fight == null:
		return
	t += delta
	for i in 2:
		var tgt: Node2D = fight.fighters[1 - i]
		if tgt.combo_taken >= 2:
			combo_show[i] = tgt.combo_taken
			combo_t[i] = 1.2
		else:
			combo_t[i] = max(0.0, combo_t[i] - delta)
		# poder que acabou de recarregar pisca
		var f: Node2D = fight.fighters[i]
		for k in 4:
			var cd: int = f.cds[k]
			if cd == 0 and _cd_antes[i][k] > 0:
				_pronto_t[i][k] = 1.0
			_pronto_t[i][k] = maxf(0.0, _pronto_t[i][k] - delta * 2.5)
			_cd_antes[i][k] = cd
	var menu: bool = fight.menu_open
	var golpes: bool = menu and fight.menu_kind == "golpes"
	veu.visible = menu and fight.menu_kind == "pause"
	for k in ["vida0", "vida1", "ret0", "ret1", "tempo", "base0", "base1"]:
		g[k].visible = not golpes
	g.combo0.visible = combo_t[0] > 0.0 and not menu
	g.combo1.visible = combo_t[1] > 0.0 and not menu
	g.combo0.modulate.a = clampf(combo_t[0] * 3.0, 0.0, 1.0)
	g.combo1.modulate.a = clampf(combo_t[1] * 3.0, 0.0, 1.0)
	g.faixa.visible = _mostra_banner()
	if g.faixa.visible:
		var dy := _banner_dy()
		g.faixa.modulate.a = clampf(fight.banner_t * 4.0, 0.0, 1.0)
		g.faixa.set_rect(Rect2(-40, 300 + dy, 1360, 170.0 if (frase != "" and dy != 0.0) else 130.0))
	g.treino.visible = Game.modo == "treino" and not menu
	g.menu.visible = menu and not golpes
	g.pill.visible = menu and not golpes
	g.golpes.visible = golpes
	g.col0.visible = golpes
	g.col1.visible = golpes
	for i in 2:
		var f: Node2D = fight.fighters[i]
		var bar: Node2D = g["vida%d" % i]
		if f.hp / f.max_hp < 0.25 and f.state != "ko" and f.hp > 0.0:
			bar.glow = 0.35 + 0.25 * sin(t * 8.0)
			bar.glow_color = Color("ff4a4a")
		else:
			bar.glow = 0.0
		var base: Node2D = g["base%d" % i]
		if f.nucleo >= 100.0 or f.overload_t > 0:
			base.glow = 0.45 + 0.25 * sin(t * 9.0)
			base.glow_color = f.data.cor if not f.eco else Color("ff3a8a")
		else:
			base.glow = 0.0
	if g.menu.visible:
		var r := _menu_rect()
		g.menu.set_rect(r)
		menu_y = lerpf(menu_y, fight.menu_sel * 50.0, minf(1.0, delta * 16.0))
		g.pill.set_rect(Rect2(r.position.x + 18, r.position.y + 72 + menu_y, r.size.x - 36, 44))
	g.cutin.visible = fight.cutin.size() > 0
	if g.cutin.visible:
		var f2: Node2D = fight.cutin.f
		var a := _cutin_a()
		g.cutin.tint = Color(f2.data.cor.darkened(0.35), 0.42) if not f2.eco else Color(0.55, 0.08, 0.3, 0.5)
		g.cutin.set_rect(Rect2(-40, 330 - 95.0 * a, 1360, maxf(2.0, 190.0 * a)))
		g.cutin.modulate.a = a
	queue_redraw()

## o aviso central some enquanto a pausa ou a lista de golpes estão abertas
func _mostra_banner() -> bool:
	return fight.banner != "" and not (fight.menu_open and fight.menu_kind in ["pause", "golpes"])

func _banner_dy() -> float:
	return -170.0 if fight.menu_open and fight.menu_kind in ["end", "continue"] else 0.0

func _cutin_a() -> float:
	var f: Node2D = fight.cutin.f
	var open := clampf(fight.cutin.t / 8.0, 0.0, 1.0)
	var close := clampf((f.SUPER_STARTUP - fight.cutin.t) / 8.0, 0.0, 1.0)
	return minf(open, close)

func _menu_rect() -> Rect2:
	var h = 96.0 + fight.menu_opts.size() * 50.0
	var w := 480.0
	var cy := 360.0 if fight.menu_kind == "pause" else 500.0
	return Rect2(640 - w / 2.0, cy - h / 2.0, w, h)

func _draw() -> void:
	if fight == null:
		return
	var golpes: bool = fight.menu_open and fight.menu_kind == "golpes"
	if golpes:
		_golpes()
		return
	if fight.cutin.size() > 0:
		_cutin()
	for i in 2:
		_player_bar(i)
	_relogio()
	if Game.modo == "arcade" and not Game.arcade.is_empty():
		var etapa: int = Game.arcade.etapa + 1
		var total: int = Game.arcade.escada.size()
		Game.text_soft(self, "LUTA %d/%d" % [mini(etapa, total), total], Vector2(540, 140), 15, Color("ffe2a0"), HORIZONTAL_ALIGNMENT_CENTER, 200, "ui")
	for i in 2:
		if combo_t[i] > 0.0 and not fight.menu_open:
			var a := clampf(combo_t[i] * 3.0, 0.0, 1.0)
			var x := 40.0 if i == 0 else 1020.0
			Game.text_soft(self, "%d GOLPES" % combo_show[i], Vector2(x, 216), 24, Color(1, 0.88, 0.45, a), HORIZONTAL_ALIGNMENT_CENTER, 220, "ui")
	if Game.modo == "treino" and not fight.menu_open:
		_treino_panel()
	if _mostra_banner():
		_banner()
	if fight.menu_open:
		_menu()

func _relogio() -> void:
	var c := Vector2(640, 52)
	if fight.round_time > 0.0:
		var tempo := int(ceil(fight.time_left))
		var cor := Color.WHITE if tempo > 10 else Color("ff6a6a")
		var tw := Game.text_width(str(tempo), 34, "ui")
		Game.text_soft(self, str(tempo), Vector2(c.x - tw / 2.0, c.y + 12), 34, cor, HORIZONTAL_ALIGNMENT_LEFT, -1, "ui")
	else:
		var tw2 := Game.text_width("∞", 36, "ui")
		Game.text_soft(self, "∞", Vector2(c.x - tw2 / 2.0, c.y + 13), 36, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, "ui")
	if Game.modo == "treino":
		return
	# rounds vencidos: bolinhas embaixo do relógio
	for i in 2:
		for k in fight.rounds_to_win:
			var pp := Vector2((626.0 - k * 16.0) if i == 0 else (654.0 + k * 16.0), 112)
			var won: bool = fight.round_wins[i] > k
			draw_circle(pp, 6.0, Color(0.03, 0.02, 0.08, 0.45))
			if won:
				draw_texture_rect(Game.dot_tex, Rect2(pp - Vector2(13, 13), Vector2(26, 26)), false, Color(1, 0.85, 0.3, 0.55))
				draw_circle(pp, 4.5, Color("ffd36b"))
			else:
				draw_arc(pp, 4.5, 0, TAU, 16, Color(1, 1, 1, 0.45), 1.5, true)

func _banner() -> void:
	var a := clampf(fight.banner_t * 4.0, 0.0, 1.0)
	var n: int = fight.banner.length()
	var sz := 92 if n < 10 else (68 if n < 18 else 50)
	var dy := _banner_dy()
	var y := 395.0 + dy - (14.0 if fight.banner_sub != "" else 0.0)
	Game.text(self, fight.banner, Vector2(0, y), sz, Color(fight.banner_cor, a), HORIZONTAL_ALIGNMENT_CENTER, 1280, "logo", 12, Color(0.06, 0.02, 0.12, 0.6 * a))
	if fight.banner_sub != "":
		Game.text_soft(self, fight.banner_sub, Vector2(0, 418 + dy), 22, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 1280, "ui")
	if frase != "" and dy != 0.0:
		Game.text(self, "“%s”" % frase, Vector2(0, 452 + dy), 17, Color(1, 1, 1, 0.8 * a), HORIZONTAL_ALIGNMENT_CENTER, 1280, "corpo")

func _player_bar(i: int) -> void:
	var f: Node2D = fight.fighters[i]
	var left := i == 0
	var cor: Color = f.data.cor if not f.eco else Color("ff3a8a")
	# retrato no círculo de vidro
	var pc := Vector2(62 if left else 1218, 58)
	var tx: Texture2D = Game.textures[f.data.id]
	var s := tx.get_size()
	var k := 86.0 / maxf(s.x, s.y)
	var sz := s * k
	draw_set_transform(pc, 0.0, Vector2(1.0 if left else -1.0, 1.0))
	draw_texture_rect(tx, Rect2(-sz / 2, sz), false, Color(0.55, 0.3, 0.7) if f.eco else Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_arc(pc, 47, 0, TAU, 48, Color(Color("4aa8ff") if left else Color("ff4a5a"), 0.85), 2.5, true)
	# vida: líquido dentro do vidro
	var bw := 456.0
	var x0 := 119.0 if left else 1280.0 - 119.0 - bw
	var bar := Rect2(x0, 31, bw, 22)
	var shown: float = clampf(f.hp_shown / f.max_hp, 0.0, 1.0)
	var ratio: float = clampf(f.hp / f.max_hp, 0.0, 1.0)
	Game.rounded(self, bar, 11, Color(0.04, 0.02, 0.1, 0.62))
	Game.capsula(self, bar, shown, Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.85), left)
	var cv := Color("39e07a").lerp(Color("ffcf3a"), clampf(1.0 - ratio * 1.7, 0.0, 1.0)).lerp(Color("ff4a4a"), clampf(1.0 - ratio * 3.6, 0.0, 1.0))
	Game.capsula(self, bar, ratio, cv.darkened(0.2), cv.lightened(0.2), left)
	# nome + selo do tipo
	var nome: String = f.data.nome
	if f.eco: nome = "ECO SOMBRIO"
	elif Game.modo in ["cpu", "arcade"] and i == 1: nome += "  •  CPU"
	elif Game.modo == "treino" and i == 1: nome += "  •  BONECO"
	var nw := Game.text_width(nome, 17, "ui")
	var sw := Game.tipo_selo_w(f.data.tipo, 18)
	var nx := x0 + 6.0 if left else x0 + bw - 6.0 - nw
	Game.text_soft(self, nome, Vector2(nx, 82), 17, Color.WHITE if not f.eco else Color("ff9ac8"), HORIZONTAL_ALIGNMENT_LEFT, -1, "ui")
	Game.tipo_selo(self, Vector2(nx + nw + 10.0 if left else nx - 10.0 - sw, 76), f.data.tipo, 18)
	# base: poderes + Núcleo
	var bx := 24.0 if left else 1280.0 - 24.0 - BASE_W
	var nr: float = clampf(f.nucleo / 100.0, 0.0, 1.0)
	var cheio: bool = nr >= 1.0
	var nucleo_r := Rect2(bx + (196.0 if left else 18.0), 652, 226, 14)
	Game.rounded(self, nucleo_r, 7, Color(0.04, 0.02, 0.1, 0.66))
	var ncor := cor.lightened(0.2) if not cheio else cor.lightened(0.25 + 0.3 * (0.5 + 0.5 * sin(t * 10.0)))
	Game.capsula(self, nucleo_r, nr, cor.darkened(0.15), ncor, not left)
	var meio := nucleo_r.position.x + nucleo_r.size.x * 0.5
	draw_line(Vector2(meio, nucleo_r.position.y - 2), Vector2(meio, nucleo_r.end.y + 2), Color(1, 1, 1, 0.55), 2.0)
	var lbl := "NÚCLEO"
	var lcor := Color(1, 1, 1, 0.8)
	if f.overload_t > 0:
		lbl = "SOBRECARGA ATIVA"
		lcor = cor.lightened(0.5 + 0.25 * sin(t * 12.0))
	elif cheio:
		lbl = "SUPREMO PRONTO!  [%s]" % Game.rotulo("super", i)
		lcor = Color("ffe2a0")
	elif nr >= 0.5:
		lbl = "SOBRECARGA  [%s + %s]" % [Game.rotulo("heavy", i), Game.rotulo("special", i)]
	Game.text(self, lbl, Vector2(nucleo_r.position.x, 688), 13, lcor, HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT, nucleo_r.size.x, "ui")
	if f.overload_t > 0:
		var ow := nucleo_r.size.x * clampf(f.overload_t / 360.0, 0.0, 1.0)
		var orr := Rect2(nucleo_r.position.x if left else nucleo_r.end.x - ow, 669, ow, 3)
		Game.rounded(self, orr, 1.5, Color(1, 1, 1, 0.9))
	# poderes (neutro, frente, cima, baixo) com recarga em forma de relógio
	var meia := 0.5 if f.overload_t > 0 else 1.0
	for k2 in 4:
		var px := (bx + 34.0 + k2 * 42.0) if left else (bx + BASE_W - 34.0 - (3 - k2) * 42.0)
		var pcen := Vector2(px, 664)
		var cd: int = f.cds[k2]
		var pid: String = f.data.poderes[k2]
		var cdmax: float = maxf(1.0, float(Game.poder(pid).get("cd", 60)) * meia)
		var pr: float = _pronto_t[i][k2]
		if pr > 0.0:
			draw_texture_rect(Game.dot_tex, Rect2(pcen - Vector2(30, 30), Vector2(60, 60)), false, Color(cor.lightened(0.4), 0.7 * pr))
		Game.poder_icone(self, pcen, k2, cor, 16.0, cd > 0)
		if cd > 0:
			var frac := clampf(cd / cdmax, 0.0, 1.0)
			# pizza escura do tempo restante (arco grosso = setor sem triangulação)
			draw_arc(pcen, 7.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 24, Color(0.02, 0.01, 0.06, 0.55), 14.0)
		else:
			draw_arc(pcen, 16.5, 0, TAU, 32, Color(1, 1, 1, 0.35 + 0.5 * pr), 1.5, true)

## Faixa cinematográfica do supremo
func _cutin() -> void:
	var f: Node2D = fight.cutin.f
	var k: float = fight.cutin.t / float(f.SUPER_STARTUP)
	var open := clampf(fight.cutin.t / 8.0, 0.0, 1.0)
	var a := _cutin_a()
	if a <= 0.01:
		return
	var hgt := 190.0 * a
	var cy := 330.0
	var cor: Color = f.data.cor if not f.eco else Color("ff3a8a")
	var dirx := 1.0 if f.facing == 1 else -1.0
	for i in 22:
		var y := cy - hgt / 2.0 + fmod(i * 37.0, hgt)
		var x := fmod(i * 233.0 - fight.cutin.t * 60.0 * dirx, 1500.0) - 100.0
		draw_line(Vector2(x, y), Vector2(x + 220.0, y), Color(cor.lightened(0.5), 0.28 * a), 3.0)
	draw_rect(Rect2(0, cy - hgt / 2.0, 1280, 2), Color(1, 1, 1, 0.7 * a))
	draw_rect(Rect2(0, cy + hgt / 2.0 - 2, 1280, 2), Color(1, 1, 1, 0.45 * a))
	var side: float = -1.0 if f.position.x < 640 else 1.0
	var px := 640.0 + side * (380.0 + 300.0 * (1.0 - open))
	draw_texture_rect(Game.dot_tex, Rect2(Vector2(px, cy) - Vector2(220, 150), Vector2(440, 300)), false, Color(cor, 0.5 * a))
	Game.draw_char(self, Game.escolha[f.idx], Vector2(px, cy + 10), 250.0 * a, side > 0, Color(0.55, 0.3, 0.7) if f.eco else Color.WHITE)
	var tx := 640.0 - side * 120.0
	Game.text_soft(self, "SUPREMO", Vector2(tx - 400, cy - 36), 20, Color(1, 1, 1, 0.85 * a), HORIZONTAL_ALIGNMENT_CENTER, 800, "ui")
	var esc := 1.0 + 0.06 * sin(k * PI)
	Game.text_scaled(self, f.data.supremo_nome, Vector2(tx, cy + 14), 58, esc, Color(cor.lightened(0.55), a), "logo", 12, Color(0.04, 0.02, 0.08, 0.7 * a))

func _treino_panel() -> void:
	var r := Rect2(470, 112, 340, 92)
	var info: Dictionary = fight.treino_info
	Game.text(self, "TREINO  •  BONECO: %s" % Game.TREINO_BONECO[Game.treino.boneco], Vector2(r.position.x, r.position.y + 28), 15, Color("bfefff"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, "ui")
	Game.text(self, "Combo: %d golpes  •  %d de dano" % [info.hits, int(info.dano)], Vector2(r.position.x, r.position.y + 54), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, "bold")
	Game.text(self, "Recorde: %d golpes  •  %d de dano" % [info.max_hits, int(info.max_dano)], Vector2(r.position.x, r.position.y + 78), 15, Color("ffe2a0"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, "bold")

func _menu() -> void:
	var opts: Array = fight.menu_opts
	var r := _menu_rect()
	Game.text_soft(self, fight.menu_title, Vector2(r.position.x, r.position.y + 50), 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, "ui")
	for i in opts.size():
		var y := r.position.y + 72.0 + i * 50.0 + 29.0
		var on: bool = i == fight.menu_sel
		Game.text_soft(self, opts[i], Vector2(r.position.x, y), 20 if on else 19, Color.WHITE if on else Color(1, 1, 1, 0.78), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, "ui", 0.3)
	Game.prompts(self, Vector2(640, r.end.y + 28), [["confirm", "OK"], ["back", "Voltar"]], 0, 22.0)

func _golpes() -> void:
	Game.text_soft(self, "LISTA DE GOLPES", Vector2(0, 76), 32, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1280, "ui")
	var dirs := ["", "→ + ", "↑ + ", "↓ + "]
	for i in 2:
		var f: Node2D = fight.fighters[i]
		var x := 84.0 + i * 595.0
		var w := 520.0
		var cor: Color = f.data.cor
		var titulo: String = ("J1  •  " if i == 0 else "J2  •  ") + (f.data.nome if not f.eco else "ECO SOMBRIO")
		Game.text_soft(self, titulo, Vector2(x, 134), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, w - 110, "ui")
		Game.tipo_selo(self, Vector2(x + w - Game.tipo_selo_w(f.data.tipo, 20), 127), f.data.tipo, 20)
		var lt := Game.rotulo("light", i)
		var hv := Game.rotulo("heavy", i)
		var sp := Game.rotulo("special", i)
		var linhas := [
			["Leve / Pesado", "%s / %s" % [lt, hv], "%s, %s, %s: combo que lança o rival para o ar" % [lt, lt, hv], -1],
			["Defesa", Game.rotulo("block", i), "Defenda na hora certa para um PERFEITO!", -1],
		]
		for k in 4:
			var pd: Dictionary = Game.poder(f.data.poderes[k])
			linhas.append([pd.get("nome", "?"), dirs[k] + sp, pd.get("desc", ""), k])
		linhas.append(["SUPREMO: " + f.data.supremo_nome, Game.rotulo("super", i), f.data.supremo_desc + " (Núcleo cheio)", -2])
		linhas.append(["Sobrecarga / Explosão", "%s + %s" % [hv, sp], "Com 50% de Núcleo: mais força, ou escapa de um combo", -1])
		for j in linhas.size():
			var y := 178.0 + j * 57.0
			var slot: int = linhas[j][3]
			var xi := x
			if slot >= 0:
				Game.poder_icone(self, Vector2(x + 11, y - 6), slot, cor, 11.0)
				xi = x + 28.0
			var cor_nome := Color.WHITE
			if slot >= 0: cor_nome = cor.lightened(0.45)
			elif slot == -2: cor_nome = Color("ffe2a0")
			Game.text(self, linhas[j][0], Vector2(xi, y), 17, cor_nome, HORIZONTAL_ALIGNMENT_LEFT, 340, "ui")
			Game.text(self, linhas[j][1], Vector2(x + w - 170, y), 17, Color("bfefff"), HORIZONTAL_ALIGNMENT_RIGHT, 170, "ui")
			Game.text(self, linhas[j][2], Vector2(xi, y + 21), 14, Color(1, 1, 1, 0.72), HORIZONTAL_ALIGNMENT_LEFT, w - (xi - x), "corpo")
	Game.prompts(self, Vector2(640, 672), [["back", "Voltar"]], 0, 22.0)
