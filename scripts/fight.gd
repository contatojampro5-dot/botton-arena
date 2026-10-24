extends Node2D
## A luta: rounds, colisões, ataques soltos (orbes, pilares, ondas...), câmera, CPU, modos e menus.

const FighterScript := preload("res://scripts/fighter.gd")
const AIScript := preload("res://scripts/ai.gd")
const ACTIONS := ["left", "right", "up", "down", "light", "heavy", "special", "block", "super", "dash"]
const FLOOR_Y := 600.0

var world: Node2D
var bg: Node2D
var fx: Node2D
var hud: Node2D
var cam: Camera2D
var fighters: Array = []
var entities: Array = []
var ais: Array = []
var round_wins := [0, 0]
var round_n := 0
var round_time := 99.0
var rounds_to_win := 2
var time_left := 99.0
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
var menu_t := 0
var cutin := {}              # câmera do supremo: {"f": lutador, "t": quadros}
var treino_info := {"hits": 0, "dano": 0.0, "max_hits": 0, "max_dano": 0.0}
var _win_index := -1
var _regen := [0, 0]
var _dummy_t := 0

func _ready() -> void:
	round_time = Game.tempo_round()
	rounds_to_win = Game.rounds_para_vencer()
	if Game.modo == "treino":
		round_time = 0.0
	world = Node2D.new()
	add_child(world)
	if Game.arena < 0:
		Game.arena = randi() % Game.ARENAS.size()
	bg = preload("res://scripts/arena_bg.gd").new()
	bg.arena = Game.ARENAS[Game.arena].id
	world.add_child(bg)
	for i in 2:
		var f: Node2D = FighterScript.new()
		f.setup(i, Game.escolha[i], self, Game.eco[i] if Game.modo == "arcade" else false)
		world.add_child(f)
		fighters.append(f)
		var a = AIScript.new()
		a.nivel = Game.arcade_nivel_cpu() if Game.modo == "arcade" else Game.opcoes.cpu
		if Game.eco[i] and Game.modo == "arcade": a.nivel = 2
		ais.append(a)
	fighters[0].opp = fighters[1]
	fighters[1].opp = fighters[0]
	fx = preload("res://scripts/fx.gd").new()
	fx.fight = self
	fx.z_index = 2
	world.add_child(fx)
	cam = Camera2D.new()
	cam.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	cam.position = Vector2(640, 360)
	world.add_child(cam)
	cam.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = preload("res://scripts/hud.gd").new()
	hud.fight = self
	layer.add_child(hud)
	Game.music(Game.ARENAS[Game.arena].musica)
	Game.monitorar = true
	_start_round()

func _start_round() -> void:
	round_n += 1
	time_left = round_time
	entities.clear()
	for f in fighters:
		f.reset_round()
		f.state = "intro"
	phase = "intro"
	phase_t = 0.0
	if Game.modo == "treino":
		_banner("TREINO", Color("6fd0ff"), "Esc: pausa e opções do boneco")
		phase_t = 1.3
	else:
		var ultimo = round_wins[0] == rounds_to_win - 1 and round_wins[1] == rounds_to_win - 1 and rounds_to_win > 1
		_banner("ROUND FINAL" if ultimo else "ROUND %d" % round_n, Color("ffd36b"))
		if Game.modo == "arcade" and Game.eco[1] and round_n == 1:
			banner_sub = "O ECO SOMBRIO DESPERTOU"
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
				banner = "" if Game.modo != "treino" else banner
				banner_t = 1.5
				phase = "fight"
				for f in fighters: f.state = "idle"
		"fight":
			if round_time > 0.0:
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
	# câmera do supremo: congela o adversário (e tudo que voa) durante a preparação
	var cine := false
	var dim := 0.0
	var em_cine := fighters.filter(func(x): return x.in_super_cinematic())
	for f in fighters:
		if f.in_super_cinematic():
			# dois supremos ao mesmo tempo: ninguém congela (evita travar a luta)
			if em_cine.size() == 1:
				f.opp.frozen = true
			cine = true
			cam.zoom = cam.zoom.lerp(Vector2.ONE * 1.35, 0.15)
			var target: Vector2 = f.position + Vector2(0, -120)
			target.x = clampf(target.x, 640.0 / 1.35, 1280.0 - 640.0 / 1.35)
			target.y = clampf(target.y, 360.0 / 1.35, 720.0 - 360.0 / 1.35)
			cam.position = cam.position.lerp(target, 0.15)
			dim = 0.6
		elif f.in_super() and f.data.supremo == "ilusao" and f.move_f < f.SUPER_STARTUP + 56:
			dim = 0.7
		elif f.in_super():
			dim = maxf(dim, 0.25)
	if cutin.size() > 0:
		cutin.t += 1
		if cutin.t > FighterScript.SUPER_STARTUP: cutin = {}
	if not cine:
		for f in fighters: f.frozen = false
		cam.zoom = cam.zoom.lerp(Vector2.ONE, 0.2)
		cam.position = cam.position.lerp(Vector2(640, 360), 0.2)
	bg.dim = lerpf(bg.dim, dim, 0.15)
	for f in fighters:
		f.step()
	# quem está atacando fica na frente (para o soco aparecer por cima do rival)
	for f in fighters:
		f.z_index = 1 if (f.state == "attack" or f.state == "win") else 0
	_push_apart()
	_check_hits()
	if not cine:
		_update_entities()
	if Game.modo == "treino":
		_treino_update()
	elif phase == "fight":
		for i in 2:
			if fighters[i].hp <= 0.0:
				_end_round(false)
				break

func on_super_start(f: Node2D) -> void:
	cutin = {"f": f, "t": 0}
	fx.pop("SUPREMO!", f.position + Vector2(0, -230), f.data.cor, 48)

var test_inputs = null   # usado só pelos testes automáticos: [[segurando, apertou], [segurando, apertou]]

func _gather_inputs() -> void:
	if test_inputs != null:
		for i in 2:
			fighters[i].set_input(test_inputs[i][0], test_inputs[i][1])
		return
	for i in 2:
		var f: Node2D = fighters[i]
		if phase != "fight" and phase != "ko":
			f.set_input({}, [])
			continue
		var cpu: bool = (Game.modo in ["cpu", "arcade"] and i == 1) or Game.ai_both
		if Game.modo == "treino" and i == 1:
			_dummy(f)
			continue
		if cpu:
			var r: Array = ais[i].think(f, f.opp, self)
			f.set_input(r[0], r[1])
			continue
		var p := "p%d_" % (i + 1)
		var down := {}
		var pressed := []
		for a in ACTIONS:
			down[a] = Input.is_action_pressed(p + a)
			if Input.is_action_just_pressed(p + a): pressed.append(a)
		f.set_input(down, pressed)

# ---------------------------------------------------------------- treino
func _dummy(f: Node2D) -> void:
	_dummy_t += 1
	match Game.treino.boneco:
		0:
			f.set_input({}, [])
		1:
			f.set_input({"block": true}, ["block"] if _dummy_t % 30 == 0 else [])
		2:
			f.set_input({}, ["up"] if _dummy_t % 50 == 0 else [])
		3:
			var r: Array = ais[1].think(f, f.opp, self)
			f.set_input(r[0], r[1])

func _treino_update() -> void:
	var p: Node2D = fighters[0]
	var d: Node2D = fighters[1]
	if Game.treino.nucleo_inf and not p.in_super():
		p.nucleo = 100.0
	# combo do jogador
	if d.combo_taken > 0:
		treino_info.hits = d.combo_taken
		treino_info.dano = d.combo_dmg
		treino_info.max_hits = maxi(treino_info.max_hits, d.combo_taken)
		treino_info.max_dano = maxf(treino_info.max_dano, d.combo_dmg)
	for i in 2:
		var f: Node2D = fighters[i]
		if f.hp < 1.0:
			f.hp = 1.0
		if f.state in ["hitstun", "knockdown", "blockstun"]:
			_regen[i] = 0
		else:
			_regen[i] += 1
			if _regen[i] > 50 and f.hp < f.max_hp:
				f.hp = f.max_hp
				f.hp_shown = f.max_hp
			if _regen[i] == 2:
				f.combo_dmg = 0.0
		if f.state == "ko":
			f.state = "idle"

# ---------------------------------------------------------------- colisões
func _push_apart() -> void:
	var a: Node2D = fighters[0]
	var b: Node2D = fighters[1]
	if a.is_down() or b.is_down(): return
	if a.alpha_mul < 0.3 or b.alpha_mul < 0.3: return
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
		var res: String = o.take_hit(f, m, dir)
		if res != "":
			f.on_attack_hit()
		_on_hit_result(f, o, m, res, r[2])

func _on_hit_result(f: Node2D, o: Node2D, m: Dictionary, res: String, at: Vector2) -> void:
	var cor: Color = f.data.cor
	match res:
		"hit":
			f.nucleo = min(100.0, f.nucleo + m.get("gain", 8.0) * 0.8)
			var heavy: bool = m.get("dmg", 0.0) >= 70.0
			hitstop = 7 if heavy else 4
			if m.get("super", false): hitstop = 3
			fx.burst(at, cor, 16 if heavy else 9, 1.3 if heavy else 0.9)
			Game.play(m.get("sfx", "hit_heavy"), randf_range(0.92, 1.08))
			if m.get("freeze", 0) > 0: Game.play("ice", 1.2, -4)
			if o.efetivo and o.frame - o.ultimo_efetivo > 50:
				o.ultimo_efetivo = o.frame
				fx.pop("É SUPER EFETIVO!", o.position + Vector2(0, -235), Game.tipo_cor(f.data.tipo).lightened(0.35), 30)
			_vibrar(o.idx, 0.4 if not heavy else 0.7, 0.2 if not heavy else 0.6, 0.12 if not heavy else 0.22)
			_vibrar(f.idx, 0.25, 0.0, 0.06)
			if o.state == "ko":
				hitstop = 14
				_vibrar(o.idx, 1.0, 1.0, 0.5)
		"block":
			hitstop = 3
			fx.burst(at, Color(0.8, 0.9, 1.0), 6, 0.6)
			Game.play("block", randf_range(0.95, 1.05))
		"perfect":
			hitstop = 12
			_vibrar(o.idx, 0.6, 0.3, 0.2)
			fx.burst(at, Color("fff6a0"), 20, 1.4)
			fx.pop("PERFEITO!", o.position + Vector2(0, -200), Color("fff6a0"), 40)
			Game.play("perfect")
		"armor":
			hitstop = 6
			fx.burst(at, o.data.cor2, 10, 1.0)
			fx.pop("ARMADURA!", o.position + Vector2(0, -200), o.data.cor.lightened(0.3), 30)
			Game.play("block", 0.6)

# ---------------------------------------------------------------- ataques soltos (entidades)
const ENT_DEFAULTS := {"kind": "", "owner": null, "pos": Vector2.ZERO, "vel": Vector2.ZERO, "accel": Vector2.ZERO, "grav": 0.0,
	"size": Vector2(40, 40), "anchor": "c", "delay": 0, "life": 60, "t": 0, "hits": 1, "interval": 10, "last_hit": -999,
	"hit_count": 0, "dmg": 50.0, "kb": Vector2(200, -100), "kb_last": null, "hitstun": 18, "blockstun": 12, "freeze": 0,
	"poison": false, "ground_only": false, "projectile": false, "super": false, "destroy_on_hit": false, "boomerang": false,
	"track": false, "track_lock": 8, "on_ground": "", "on_death": "", "dir": 1, "cor": Color.WHITE, "sfx": "hit_heavy",
	"gain": 8.0, "dead": false, "seed": 0.0, "visual_only": false, "unblockable": false}

func spawn(e: Dictionary) -> Dictionary:
	var d: Dictionary = ENT_DEFAULTS.duplicate()
	d.merge(e, true)
	if d.seed == 0.0: d.seed = randf() * 100.0
	if d.get("wave_amp", 0.0) > 0.0:
		d["base_y"] = d.pos.y
	if d.get("single", false):
		# armadilhas e zonas: só uma de cada por lutador
		for x in entities:
			if x.owner == d.owner and x.kind == d.kind and not x.dead:
				x.dead = true
				fx.puff(x.pos, Color(d.cor, 0.5), 5)
	entities.append(d)
	return d

func _vibrar(pi: int, fraca: float, forte: float, dur: float) -> void:
	if Game.ai_both: return
	if Game.modo in ["cpu", "arcade", "treino"] and pi == 1: return
	Game.vibrar(pi, fraca, forte, dur)

func ent_rect(e: Dictionary) -> Rect2:
	var sz: Vector2 = e.size
	match e.anchor:
		"b": return Rect2(e.pos - Vector2(sz.x / 2.0, sz.y), sz)
		"beam":
			var x0: float = e.pos.x if e.dir == 1 else e.pos.x - sz.x
			return Rect2(Vector2(x0, e.pos.y - sz.y / 2.0), sz)
	return Rect2(e.pos - sz / 2.0, sz)

func ent_active(e: Dictionary) -> bool:
	return e.t > e.delay and e.t <= e.delay + e.life

func _update_entities() -> void:
	var dt := 1.0 / 60.0
	for e in entities:
		if e.dead: continue
		e.t += 1
		var owner: Node2D = e.owner
		var o: Node2D = owner.opp if owner else null
		if e.t <= e.delay:
			# aviso: segue o alvo até travar a posição
			if e.get("track_x", false) and o:
				e.pos.x = lerpf(e.pos.x, clampf(o.position.x, 60.0, 1220.0), 0.4)
			if e.track and o and e.delay - e.t > e.track_lock:
				if e.anchor == "c":
					e.pos = e.pos.lerp(o.position + Vector2(0, -80), 0.5)
				else:
					e.pos.x = lerpf(e.pos.x, clampf(o.position.x, 60.0, 1220.0), 0.35)
			continue
		if e.t == e.delay + 1:
			_ent_start_fx(e)
		e.vel += e.accel * dt
		e.vel.y += e.grav * dt
		e.pos += e.vel * dt
		if e.has("follow") and owner:
			var fo: Vector2 = e.follow
			e.pos = owner.position + Vector2(fo.x * owner.facing, fo.y)
			e.dir = owner.facing
		if e.has("base_y"):
			e.base_y += e.vel.y * dt
			e.pos.y = e.base_y + sin(e.t * e.wave_freq) * e.wave_amp
		# armadilha: espera o rival pisar/chegar perto
		if e.get("trap", false) and o:
			if e.t - e.delay < e.get("arm", 15):
				continue
			var tg: Vector2 = e.trigger
			var tr := Rect2(e.pos - Vector2(tg.x / 2.0, tg.y), tg)
			var hu0: Rect2 = o.hurtbox()
			var ok_chao: bool = not e.get("trigger_ground", false) or o.on_ground
			if hu0.size != Vector2.ZERO and ok_chao and tr.intersects(hu0):
				_disparar_armadilha(e, o)
				continue
			if e.t > e.delay + e.life:
				e.dead = true
				fx.puff(e.pos, Color(e.cor, 0.4), 4)
			continue
		# torreta: atira sozinha
		if e.kind == "turret" and o and (e.t - e.delay) % int(e.fire_every) == 20:
			var dd := 1 if o.position.x >= e.pos.x else -1
			spawn({"kind": "bolt", "owner": owner, "pos": e.pos + Vector2(dd * 40, -58), "vel": Vector2(dd * 700, 0), "size": Vector2(34, 18),
				"life": 120, "dmg": 34.0, "kb": Vector2(180, -100), "hitstun": 16, "blockstun": 10, "projectile": true, "destroy_on_hit": true,
				"dir": dd, "cor": e.cor, "power": true, "gain": 4.0, "sfx": "hit_light"})
			e.dir = dd
			Game.play("gear", 1.6, -8)
		# puxa (buraco negro) e empurra (vento, vapor)
		if o and e.get("pull", 0.0) > 0.0 and o.state not in ["ko"] and o.invuln <= 0:
			var dv: Vector2 = e.pos + Vector2(0, 80) - o.position
			if dv.length() < e.pull:
				o.position.x += signf(dv.x) * minf(absf(dv.x), 3.2)
				if not o.on_ground:
					o.vel.y = lerpf(o.vel.y, signf(dv.y) * 120.0, 0.08)
		if o and e.get("slow", false):
			var hu3: Rect2 = o.hurtbox()
			if hu3.size != Vector2.ZERO and ent_rect(e).intersects(hu3) and o.on_ground:
				o.slow_t = 12
		if e.boomerang and owner and signf(e.vel.x) == -e.dir and absf(e.pos.x - owner.position.x) < 60.0:
			e.dead = true
			continue
		# bateu no chão
		if e.on_ground != "":
			var bottom: float = e.pos.y + (e.size.y / 2.0 if e.anchor == "c" else 0.0)
			if bottom >= FLOOR_Y:
				e.pos.y = FLOOR_Y - (e.size.y / 2.0 if e.anchor == "c" else 0.0)
				_ent_die(e)
				continue
		# acerto
		if not e.visual_only and o and e.hit_count < e.hits and e.t - e.last_hit >= e.interval and e.t <= e.delay + e.life:
			if not (e.ground_only and not o.on_ground):
				var hu: Rect2 = o.hurtbox()
				var r := ent_rect(e)
				if hu.size != Vector2.ZERO and r.intersects(hu):
					var last: bool = e.hit_count == e.hits - 1
					var m := {"dmg": e.dmg, "kb": e.kb_last if (last and e.kb_last != null) else e.kb, "hitstun": e.hitstun,
						"blockstun": e.blockstun, "super": e.super, "freeze": e.freeze, "poison": e.poison, "gain": e.gain,
						"sfx": e.sfx, "melee": false, "unblockable": e.unblockable, "power": e.get("power", false)}
					var res: String = o.take_hit(owner, m, e.dir)
					if res != "":
						e.hit_count += 1
						e.last_hit = e.t
						_on_hit_result(owner, o, m, res, r.intersection(hu).get_center())
						if e.destroy_on_hit:
							_ent_die(e)
							continue
		# empurra (vento, vapor): depois do acerto, para o golpe sair antes do empurrão
		if o and e.get("push", 0.0) > 0.0 and o.state not in ["ko"] and e.t > e.delay:
			var corpo := Rect2(o.position + o.HURT.position, o.HURT.size)
			if ent_rect(e).intersects(corpo):
				var fator := 0.35 if o.state in ["block", "blockstun"] else 1.0
				o.position.x = clampf(o.position.x + e.dir * e.push * dt * fator, o.LEFT_WALL, o.RIGHT_WALL)
		if e.t > e.delay + e.life or e.pos.x < -400 or e.pos.x > 1680 or e.pos.y > 1000:
			e.dead = true
	# choque de poderes
	var proj := entities.filter(func(x): return x.projectile and not x.dead and ent_active(x))
	for i in proj.size():
		for j in range(i + 1, proj.size()):
			var a: Dictionary = proj[i]
			var b: Dictionary = proj[j]
			if a.owner == b.owner or a.dead or b.dead: continue
			if ent_rect(a).intersects(ent_rect(b)):
				var mid: Vector2 = (a.pos + b.pos) / 2.0
				if a.super and not b.super: b.dead = true
				elif b.super and not a.super: a.dead = true
				else:
					a.dead = true
					b.dead = true
					fx.pop("CHOQUE DE PODERES!", mid + Vector2(0, -70), Color.WHITE, 30)
				fx.burst(mid, Color(a.cor).lerp(b.cor, 0.5), 24, 1.6)
				fx.ring(mid, Color(a.cor).lerp(b.cor, 0.5), 1.2)
				Game.play("explode", 1.1)
	entities = entities.filter(func(x): return not x.dead)

func _ent_start_fx(e: Dictionary) -> void:
	match e.kind:
		"firepillar": Game.play("fire", randf_range(0.9, 1.2), -6)
		"icespike": Game.play("ice", randf_range(0.9, 1.2), -8)
		"sunbeam": Game.play("zap", randf_range(0.9, 1.1), -4)
		"vine", "bigvine": Game.play("quake", 1.6, -10)
		"shadowslash": Game.play("whoosh", 1.4, -2)
		"circle": Game.play("explode", 0.7, -2)

func _disparar_armadilha(e: Dictionary, o: Node2D) -> void:
	e.dead = true
	var dir: int = 1 if o.position.x >= e.pos.x else -1
	var kind := "blast"
	match e.kind:
		"icefloor": kind = "icecrack"
		"rune": kind = "acidgeyser"
		"mine": kind = "blast"
	var alt := 300.0 if kind == "acidgeyser" else 140.0
	spawn({"kind": kind, "owner": e.owner, "pos": Vector2(e.pos.x, FLOOR_Y), "anchor": "b", "size": Vector2(170, alt), "life": 10,
		"dmg": e.dmg, "kb": e.kb, "freeze": e.freeze, "poison": e.poison, "hitstun": e.hitstun, "blockstun": e.blockstun,
		"dir": dir, "cor": e.cor, "power": true, "gain": e.gain})
	fx.burst(Vector2(e.pos.x, FLOOR_Y - 30), e.cor, 18, 1.3)
	fx.ring(Vector2(e.pos.x, FLOOR_Y - 20), e.cor, 1.0)
	Game.play("explode" if kind == "blast" else ("ice" if kind == "icecrack" else "poison"), 1.0, -2)

func _ent_die(e: Dictionary) -> void:
	e.dead = true
	match e.on_death:
		"thorns":
			spawn({"kind": "thorns", "owner": e.owner, "pos": Vector2(e.pos.x, FLOOR_Y), "anchor": "b", "size": Vector2(130, 80), "life": 220,
				"trap": true, "arm": 10, "trigger": Vector2(130, 90), "trigger_ground": false, "dmg": 70.0, "kb": Vector2(120, -640),
				"hitstun": 26, "blockstun": 12, "dir": e.dir, "cor": e.cor, "power": true, "gain": 8.0, "single": true})
			fx.debris(Vector2(e.pos.x, FLOOR_Y), Color("6b4a2a"))
			Game.play("quake", 1.8, -8)
		"splash":
			fx.burst(e.pos, Color(0.7, 0.9, 1.0), 12, 0.8)
			Game.play("water", 1.8, -10)
		"poison":
			spawn({"kind": "poison", "owner": e.owner, "pos": Vector2(e.pos.x, FLOOR_Y), "anchor": "b", "size": Vector2(210, 125),
				"life": 160, "hits": 6, "interval": 25, "dmg": 14.0, "kb": Vector2(0, 0), "hitstun": 8, "blockstun": 5, "poison": true,
				"dir": e.dir, "cor": e.cor, "gain": 2.0, "sfx": "hit_light"})
			fx.burst(Vector2(e.pos.x, FLOOR_Y - 20), e.cor, 12, 0.8)
			Game.play("poison")
		"blast":
			spawn({"kind": "blast", "owner": e.owner, "pos": Vector2(e.pos.x, FLOOR_Y), "anchor": "b", "size": Vector2(175, 125),
				"life": 8, "dmg": 24.0, "kb": Vector2(120, -520), "hitstun": 26, "blockstun": 10, "super": true, "dir": e.dir, "cor": e.cor})
			fx.burst(Vector2(e.pos.x, FLOOR_Y - 30), e.cor, 18, 1.3)
			fx.ring(Vector2(e.pos.x, FLOOR_Y - 20), e.cor, 0.9)
			Game.play("explode", randf_range(0.9, 1.1), -4)
		"dust":
			fx.debris(Vector2(e.pos.x, FLOOR_Y), e.cor)
			fx.puff(Vector2(e.pos.x, FLOOR_Y - 10), Color(0.75, 0.68, 0.6, 0.7), 10)
			Game.play("hit_heavy", 0.6, -6)
		"pop":
			fx.burst(e.pos, e.cor, 10, 0.9)
			fx.puff(e.pos, Color(0.9, 0.9, 0.85, 0.6), 6)

# ---------------------------------------------------------------- rounds
func _end_round(timeout: bool) -> void:
	phase = "ko"
	phase_t = 0.0
	var a: Node2D = fighters[0]
	var b: Node2D = fighters[1]
	var winner := -1
	var ra: float = a.hp / a.max_hp
	var rb: float = b.hp / b.max_hp
	if ra > rb: winner = 0
	elif rb > ra: winner = 1
	if winner >= 0:
		round_wins[winner] += 1
	if timeout:
		_banner("TEMPO!", Color("ffd36b"))
	elif a.hp <= 0 and b.hp <= 0:
		_banner("K.O. DUPLO!", Color("ff5a5a"))
	else:
		var perfeito: bool = winner >= 0 and fighters[winner].hp >= fighters[winner].max_hp
		_banner("K.O.!", Color("ff5a5a"), "VITÓRIA PERFEITA!" if perfeito else "")
		Game.play("ko")
		Engine.time_scale = 0.35
		get_tree().create_timer(0.35, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	_win_index = winner

func _after_round() -> void:
	Engine.time_scale = 1.0
	if _win_index >= 0:
		var w: Node2D = fighters[_win_index]
		if w.state != "ko": w.state = "win"
	if round_wins[0] >= rounds_to_win or round_wins[1] >= rounds_to_win:
		var wi := 0 if round_wins[0] > round_wins[1] else 1
		phase = "end"
		fighters[wi].state = "win"
		Game.music("vitoria")
		if Game.modo == "arcade":
			_arcade_fim(wi)
			return
		Game.vitorias[wi] += 1
		var quem := "JOGADOR 1" if wi == 0 else ("CPU" if Game.modo == "cpu" else "JOGADOR 2")
		_banner(fighters[wi].data.nome, fighters[wi].data.cor.lightened(0.3), "%s VENCE!   •   Placar: %d x %d" % [quem, Game.vitorias[0], Game.vitorias[1]])
		hud.frase = fighters[wi].data.frase
		get_tree().create_timer(1.8).timeout.connect(func(): _open_menu("end"))
	else:
		if _win_index >= 0:
			_banner("%s VENCE O ROUND" % ("J1" if _win_index == 0 else ("CPU" if Game.modo in ["cpu", "arcade"] else "J2")), Color("ffd36b"))
		phase = "end"
		get_tree().create_timer(1.4).timeout.connect(_start_round)

func _arcade_fim(wi: int) -> void:
	if wi == 0:
		var p: Node2D = fighters[0]
		Game.arcade.pontos += 1000 + int(p.hp / p.max_hp * 2000.0) + int(time_left * 10.0)
		Game.arcade.etapa += 1
		if Game.arcade.etapa >= Game.arcade.escada.size():
			_banner("VOCÊ VENCEU O ECO SOMBRIO!", Color("ffd36b"), "")
			get_tree().create_timer(2.2).timeout.connect(func(): Game.goto("res://scripts/arcade_end.gd"))
		else:
			_banner("VITÓRIA!", Color("ffd36b"), "Luta %d de %d concluída" % [Game.arcade.etapa, Game.arcade.escada.size()])
			get_tree().create_timer(2.0).timeout.connect(func():
				Game.arcade_preparar()
				Game.goto("res://scripts/versus.gd"))
	else:
		_banner("DERROTA", Color("ff5a5a"), "")
		get_tree().create_timer(1.6).timeout.connect(func(): _open_menu("continue"))

# ---------------------------------------------------------------- menus
func _open_menu(kind: String) -> void:
	menu_open = true
	menu_kind = kind
	menu_sel = 0
	menu_t = 0 if kind in ["end", "continue"] else 30
	match kind:
		"pause":
			menu_title = "PAUSA"
			match Game.modo:
				"treino":
					menu_opts = ["CONTINUAR", "LISTA DE GOLPES", "BONECO: %s" % Game.TREINO_BONECO[Game.treino.boneco],
						"NÚCLEO INFINITO: %s" % ("SIM" if Game.treino.nucleo_inf else "NÃO"), "TROCAR PERSONAGEM", "MENU PRINCIPAL"]
				"arcade":
					menu_opts = ["CONTINUAR", "LISTA DE GOLPES", "DESISTIR"]
				_:
					menu_opts = ["CONTINUAR", "LISTA DE GOLPES", "TROCAR PERSONAGEM", "MENU PRINCIPAL"]
		"end":
			menu_title = "FIM DE LUTA"
			menu_opts = ["REVANCHE", "TROCAR PERSONAGEM", "TROCAR ARENA", "MENU PRINCIPAL"]
		"continue":
			menu_title = "CONTINUAR?"
			menu_opts = ["SIM, TENTAR DE NOVO", "NÃO"]
		"golpes":
			menu_title = "LISTA DE GOLPES"
			menu_opts = ["VOLTAR"]
	Game.play("select")

func _menu_input() -> void:
	menu_t += 1
	var up := Game.just("up")
	var dn := Game.just("down")
	var ok := Game.just("confirm")
	if up: menu_sel = wrapi(menu_sel - 1, 0, menu_opts.size()); Game.play("select")
	if dn: menu_sel = wrapi(menu_sel + 1, 0, menu_opts.size()); Game.play("select")
	if Input.is_action_just_pressed("pause") or Game.just("back"):
		if menu_kind == "pause":
			menu_open = false
			return
		if menu_kind == "golpes":
			_open_menu("pause")
			return
	if not ok or menu_t < 24:
		return
	Game.play("confirm")
	var opt: String = menu_opts[menu_sel]
	if menu_kind == "golpes":
		_open_menu("pause")
		menu_sel = 1
		return
	if opt == "CONTINUAR":
		menu_open = false
	elif opt == "LISTA DE GOLPES":
		_open_menu("golpes")
	elif opt.begins_with("BONECO"):
		Game.treino.boneco = (Game.treino.boneco + 1) % Game.TREINO_BONECO.size()
		menu_opts[menu_sel] = "BONECO: %s" % Game.TREINO_BONECO[Game.treino.boneco]
	elif opt.begins_with("NÚCLEO"):
		Game.treino.nucleo_inf = not Game.treino.nucleo_inf
		menu_opts[menu_sel] = "NÚCLEO INFINITO: %s" % ("SIM" if Game.treino.nucleo_inf else "NÃO")
	elif opt == "REVANCHE":
		Game.goto("res://scripts/fight.gd")
	elif opt == "TROCAR PERSONAGEM":
		Game.goto("res://scripts/select.gd")
	elif opt == "TROCAR ARENA":
		Game.goto("res://scripts/stage_select.gd")
	elif opt == "SIM, TENTAR DE NOVO":
		Game.arcade.continues += 1
		Game.goto("res://scripts/versus.gd")
	elif opt in ["MENU PRINCIPAL", "DESISTIR", "NÃO"]:
		Game.arcade = {}
		Game.goto("res://scripts/title.gd")
