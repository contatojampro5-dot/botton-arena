extends Node2D
## A luta: rounds, colisões de golpes, orbes, câmera, CPU e menus.

const FighterScript := preload("res://scripts/fighter.gd")
const ROUND_TIME := 99.0
const ROUNDS_TO_WIN := 2
const ACTIONS := ["left", "right", "up", "down", "light", "heavy", "special", "block", "super", "dash"]

var world: Node2D
var bg: Node2D
var fx: Node2D
var hud: Node2D
var cam: Camera2D
var fighters: Array = []
var projectiles: Array = []
var round_wins := [0, 0]
var round_n := 0
var time_left := ROUND_TIME
var phase := "intro"         # intro, fight, ko, end
var phase_t := 0.0
var hitstop := 0
var banner := ""
var banner_sub := ""
var banner_t := 0.0
var banner_cor := Color.WHITE
var menu_open := false
var menu_title := ""
var menu_opts: Array = []
var menu_sel := 0
var menu_kind := ""
var ai_states := [{"t": 0, "plan": "", "hold": 0}, {"t": 0, "plan": "", "hold": 0}]

func _ready() -> void:
	world = Node2D.new()
	add_child(world)
	bg = preload("res://scripts/arena_bg.gd").new()
	world.add_child(bg)
	for i in 2:
		var f: Node2D = FighterScript.new()
		f.setup(i, Game.escolha[i])
		world.add_child(f)
		fighters.append(f)
	fighters[0].opp = fighters[1]
	fighters[1].opp = fighters[0]
	bg.core_color = Color(fighters[0].data.cor).lerp(fighters[1].data.cor, 0.5).lightened(0.2)
	fx = preload("res://scripts/fx.gd").new()
	fx.fight = self
	world.add_child(fx)
	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	world.add_child(cam)
	cam.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = preload("res://scripts/hud.gd").new()
	hud.fight = self
	layer.add_child(hud)
	_start_round()

func _start_round() -> void:
	round_n += 1
	time_left = ROUND_TIME
	projectiles.clear()
	for f in fighters:
		f.reset_round()
		f.state = "intro"
	phase = "intro"
	phase_t = 0.0
	_banner("ROUND %d" % round_n if round_wins[0] + round_wins[1] < 2 or round_wins[0] != round_wins[1] else "ROUND FINAL", Color("ffd36b"))
	Game.play("round")

func _banner(s: String, cor := Color.WHITE, sub := "") -> void:
	banner = s
	banner_sub = sub
	banner_cor = cor
	banner_t = 1.0

# ---------------------------------------------------------------- laço principal
func _physics_process(_dt: float) -> void:
	if menu_open:
		_menu_input()
		return
	if Input.is_action_just_pressed("pause") and phase in ["fight", "intro"]:
		_open_menu("pause")
		return
	phase_t += 1.0 / 60.0
	match phase:
		"intro":
			if phase_t > 1.3 and banner.begins_with("ROUND"):
				_banner("LUTEM!", Color("ff6a3a"))
				Game.play("confirm", 0.8)
			if phase_t > 1.9:
				banner = ""
				phase = "fight"
				for f in fighters: f.state = "idle"
		"fight":
			time_left -= 1.0 / 60.0
			if time_left <= 0.0:
				time_left = 0.0
				_end_round(true)
		"ko":
			if phase_t > 2.6:
				_after_round()
		"end":
			pass
	if banner != "" and phase == "fight":
		banner_t -= 1.0 / 60.0
		if banner_t <= 0.0: banner = ""
	_gather_inputs()
	if hitstop > 0:
		hitstop -= 1
		return
	# câmera do supremo: congela o adversário durante a preparação
	var cine := false
	for f in fighters:
		var o: Node2D = f.opp
		if f.state == "attack" and f.move == "supremo" and f.move_f <= f.current_move().startup:
			o.frozen = true
			cine = true
			cam.zoom = cam.zoom.lerp(Vector2.ONE * 1.35, 0.15)
			var target: Vector2 = f.position + Vector2(0, -120)
			target.x = clampf(target.x, 640.0 / 1.35, 1280.0 - 640.0 / 1.35)
			target.y = clampf(target.y, 360.0 / 1.35, 720.0 - 360.0 / 1.35)
			cam.position = cam.position.lerp(target, 0.15)
			if f.move_f == 2:
				fx.pop("SUPREMO!", f.position + Vector2(0, -220), f.data.cor, 52)
	if not cine:
		for f in fighters: f.frozen = false
		cam.zoom = cam.zoom.lerp(Vector2.ONE, 0.2)
		cam.position = cam.position.lerp(Vector2(640, 360), 0.2)
	bg.dim = lerpf(bg.dim, 0.55 if cine else 0.0, 0.2)
	for f in fighters:
		f.step()
	_push_apart()
	_check_hits()
	_update_projectiles()
	if phase == "fight":
		for i in 2:
			if fighters[i].hp <= 0.0:
				_end_round(false)
				break

func _gather_inputs() -> void:
	for i in 2:
		var f: Node2D = fighters[i]
		if phase != "fight" and phase != "ko":
			f.set_input({}, [])
			continue
		if (Game.modo == "cpu" and i == 1) or Game.ai_both:
			_ai(f)
			continue
		var p := "p%d_" % (i + 1)
		var down := {}
		var pressed := []
		for a in ACTIONS:
			down[a] = Input.is_action_pressed(p + a)
			if Input.is_action_just_pressed(p + a): pressed.append(a)
		f.set_input(down, pressed)

# ---------------------------------------------------------------- colisões
func _push_apart() -> void:
	var a: Node2D = fighters[0]
	var b: Node2D = fighters[1]
	if a.is_down() or b.is_down(): return
	if abs(a.position.y - b.position.y) > 120: return
	var dx: float = b.position.x - a.position.x
	var min_d := 78.0
	if abs(dx) < min_d:
		var push: float = (min_d - abs(dx)) / 2.0
		var s := 1.0 if dx >= 0 else -1.0
		if dx == 0: s = 1.0 if a.facing == 1 else -1.0
		a.position.x -= s * push
		b.position.x += s * push
		for f in fighters:
			f.position.x = clampf(f.position.x, f.LEFT_WALL, f.RIGHT_WALL)
		# encostado na parede: empurra o outro
		if a.position.x <= a.LEFT_WALL + 0.1 or a.position.x >= a.RIGHT_WALL - 0.1:
			b.position.x = clampf(a.position.x + s * min_d, b.LEFT_WALL, b.RIGHT_WALL)
		elif b.position.x <= b.LEFT_WALL + 0.1 or b.position.x >= b.RIGHT_WALL - 0.1:
			a.position.x = clampf(b.position.x - s * min_d, a.LEFT_WALL, a.RIGHT_WALL)

func _check_hits() -> void:
	var results := []
	for f in fighters:
		var hb: Rect2 = f.active_hitbox()
		if hb.size == Vector2.ZERO: continue
		var o: Node2D = f.opp
		var hu: Rect2 = o.hurtbox()
		if hu.size == Vector2.ZERO or not hb.intersects(hu): continue
		results.append([f, o, hb.intersection(hu).get_center()])
	for r in results:
		var f: Node2D = r[0]
		var o: Node2D = r[1]
		var m: Dictionary = f.current_move()
		f.hits_done += 1
		var dir: int = 1 if o.position.x >= f.position.x else -1
		if f.move == "supremo": dir = f.facing
		var res: String = o.take_hit(f, m, dir, f.move != "supremo")
		_on_hit_result(f, o, m, res, r[2])

func _on_hit_result(f: Node2D, o: Node2D, m: Dictionary, res: String, at: Vector2) -> void:
	var cor: Color = f.data.cor
	match res:
		"hit":
			f.nucleo = min(100.0, f.nucleo + m.gain)
			var heavy: bool = m.dmg >= 70.0
			hitstop = 7 if heavy else 4
			if f.move == "supremo": hitstop = 3
			fx.burst(at, cor, 16 if heavy else 9, 1.3 if heavy else 0.9)
			Game.play(m.sfx, randf_range(0.92, 1.08))
			if o.state == "ko":
				hitstop = 14
		"block":
			hitstop = 3
			fx.burst(at, Color(0.8, 0.9, 1.0), 6, 0.6)
			Game.play("block", randf_range(0.95, 1.05))
		"perfect":
			hitstop = 12
			fx.burst(at, Color("fff6a0"), 20, 1.4)
			fx.pop("PERFEITO!", o.position + Vector2(0, -190), Color("fff6a0"), 40)
			Game.play("perfect")

func spawn_projectile(f: Node2D) -> void:
	var m: Dictionary = f.MOVES["orbe"]
	projectiles.append({"pos": f.position + Vector2(f.facing * 70, -85), "vel": Vector2(f.facing * 640, 0), "owner": f,
		"cor": Color(f.data.cor), "t": 0.0, "dmg": m.dmg, "move": m})

func _update_projectiles() -> void:
	var dt := 1.0 / 60.0
	var dead := []
	for p in projectiles:
		p.t += dt
		p.pos += p.vel * dt
		if p.pos.x < -60 or p.pos.x > 1340: dead.append(p); continue
		var o: Node2D = p.owner.opp
		var hu: Rect2 = o.hurtbox()
		var box := Rect2(p.pos - Vector2(18, 18), Vector2(36, 36))
		if hu.size != Vector2.ZERO and box.intersects(hu):
			var dir: int = 1 if p.vel.x > 0 else -1
			var res: String = o.take_hit(p.owner, p.move, dir)
			_on_hit_result(p.owner, o, p.move, res, p.pos)
			dead.append(p)
	# choque de poderes: orbes se anulam
	for i in projectiles.size():
		for j in range(i + 1, projectiles.size()):
			var a: Dictionary = projectiles[i]
			var b: Dictionary = projectiles[j]
			if a.owner != b.owner and a.pos.distance_to(b.pos) < 36:
				dead.append(a); dead.append(b)
				fx.burst((a.pos + b.pos) / 2, a.cor.lerp(b.cor, 0.5), 22, 1.5)
				fx.pop("CHOQUE!", (a.pos + b.pos) / 2 + Vector2(0, -60), Color.WHITE, 34)
				Game.play("hit_heavy", 0.8)
	for d in dead:
		projectiles.erase(d)

# ---------------------------------------------------------------- rounds
func _end_round(timeout: bool) -> void:
	phase = "ko"
	phase_t = 0.0
	var a: Node2D = fighters[0]
	var b: Node2D = fighters[1]
	var winner := -1
	if a.hp > b.hp: winner = 0
	elif b.hp > a.hp: winner = 1
	if winner >= 0:
		round_wins[winner] += 1
	if timeout:
		_banner("TEMPO!", Color("ffd36b"))
	elif a.hp <= 0 and b.hp <= 0:
		_banner("K.O. DUPLO!", Color("ff5a5a"))
	else:
		_banner("K.O.!", Color("ff5a5a"))
		Game.play("ko")
		Engine.time_scale = 0.35
		get_tree().create_timer(0.35, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	_win_index = winner

var _win_index := -1

func _after_round() -> void:
	Engine.time_scale = 1.0
	if _win_index >= 0:
		var w: Node2D = fighters[_win_index]
		if w.state != "ko": w.state = "win"
	if round_wins[0] >= ROUNDS_TO_WIN or round_wins[1] >= ROUNDS_TO_WIN:
		var wi := 0 if round_wins[0] > round_wins[1] else 1
		Game.vitorias[wi] += 1
		phase = "end"
		var quem := "JOGADOR 1" if wi == 0 else ("CPU" if Game.modo == "cpu" else "JOGADOR 2")
		_banner(fighters[wi].data.nome, fighters[wi].data.cor.lightened(0.3), "%s VENCE!   •   Placar: %d x %d" % [quem, Game.vitorias[0], Game.vitorias[1]])
		fighters[wi].state = "win"
		get_tree().create_timer(1.6).timeout.connect(func(): _open_menu("end"))
	else:
		if _win_index >= 0:
			_banner("%s VENCE O ROUND" % ("J1" if _win_index == 0 else ("CPU" if Game.modo == "cpu" else "J2")), Color("ffd36b"))
		phase = "end"
		get_tree().create_timer(1.4).timeout.connect(_start_round)

# ---------------------------------------------------------------- menus
func _open_menu(kind: String) -> void:
	menu_open = true
	menu_kind = kind
	menu_sel = 0
	if kind == "pause":
		menu_title = "PAUSA"
		menu_opts = ["CONTINUAR", "TROCAR PERSONAGEM", "MENU PRINCIPAL"]
	else:
		menu_title = "FIM DE LUTA"
		menu_opts = ["REVANCHE", "TROCAR PERSONAGEM", "MENU PRINCIPAL"]
	Game.play("select")

func _menu_input() -> void:
	var up := Input.is_action_just_pressed("p1_up") or Input.is_action_just_pressed("p2_up")
	var dn := Input.is_action_just_pressed("p1_down") or Input.is_action_just_pressed("p2_down")
	var ok := Input.is_action_just_pressed("p1_confirm") or Input.is_action_just_pressed("p2_confirm")
	if up: menu_sel = wrapi(menu_sel - 1, 0, menu_opts.size()); Game.play("select")
	if dn: menu_sel = wrapi(menu_sel + 1, 0, menu_opts.size()); Game.play("select")
	if Input.is_action_just_pressed("pause") and menu_kind == "pause":
		menu_open = false
		return
	if ok:
		Game.play("confirm")
		match menu_sel:
			0:
				menu_open = false
				if menu_kind == "end":
					Game.goto("res://scripts/fight.gd")
			1: Game.goto("res://scripts/select.gd")
			2: Game.goto("res://scripts/title.gd")

# ---------------------------------------------------------------- CPU
func _ai(f: Node2D) -> void:
	var ai_state: Dictionary = ai_states[f.idx]
	var o: Node2D = f.opp
	var down := {}
	var pressed := []
	var dx: float = o.position.x - f.position.x
	var dist: float = abs(dx)
	var toward := "right" if dx > 0 else "left"
	var away := "left" if dx > 0 else "right"
	ai_state.t += 1
	if ai_state.hold > 0:
		ai_state.hold -= 1
	else:
		var r := randf()
		ai_state.plan = ""
		if o.is_attacking() and dist < 200 and r < 0.4 and f.on_ground:
			ai_state.plan = "block"; ai_state.hold = 18
		elif f.nucleo >= 100.0 and dist < 700 and r < 0.3:
			ai_state.plan = "super"; ai_state.hold = 2
		elif o.is_airborne() and dist < 160 and f.data.especial == "ascensao" and r < 0.5:
			ai_state.plan = "special"; ai_state.hold = 4
		elif dist > 330:
			if r < 0.12 and f.data.especial in ["orbe", "investida", "sombra"]:
				ai_state.plan = "special"; ai_state.hold = 30
			elif r < 0.22:
				ai_state.plan = "jumpin"; ai_state.hold = 30
			elif r < 0.32:
				ai_state.plan = "dash"; ai_state.hold = 10
			else:
				ai_state.plan = "walk"; ai_state.hold = 14
		elif dist > 120:
			if r < 0.5: ai_state.plan = "walk"; ai_state.hold = 10
			elif r < 0.65: ai_state.plan = "back"; ai_state.hold = 12
			elif r < 0.8: ai_state.plan = "jumpin"; ai_state.hold = 26
			else: ai_state.plan = "wait"; ai_state.hold = 10
		else:
			if r < 0.55: ai_state.plan = "combo"; ai_state.hold = 26
			elif r < 0.7: ai_state.plan = "heavy"; ai_state.hold = 20
			elif r < 0.8: ai_state.plan = "special"; ai_state.hold = 20
			elif r < 0.9: ai_state.plan = "block"; ai_state.hold = 16
			else: ai_state.plan = "back"; ai_state.hold = 12
	match ai_state.plan:
		"block": down["block"] = true
		"walk": down[toward] = true
		"back": down[away] = true
		"dash":
			if ai_state.hold == 9: pressed.append("dash")
			down[toward] = true
		"jumpin":
			down[toward] = true
			if ai_state.hold == 29 or ai_state.hold == 25: pressed.append("up")
			if not f.on_ground and dist < 140 and ai_state.t % 6 == 0: pressed.append("light" if randf() < 0.6 else "heavy")
		"combo":
			if ai_state.t % 5 == 0: pressed.append("light")
			if ai_state.hold < 8 and ai_state.t % 5 == 2: pressed.append("heavy")
		"heavy":
			if ai_state.hold == 19: pressed.append("heavy")
		"special":
			if ai_state.hold >= 2: pressed.append("special"); ai_state.hold = 1
		"super":
			pressed.append("super")
	f.set_input(down, pressed)
