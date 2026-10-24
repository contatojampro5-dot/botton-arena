extends Node2D
## Um lutador (botton). A luta (fight.gd) chama step() a cada quadro (60 por segundo).

signal hit_landed(attacker, target, info)

const FLOOR_Y := 600.0
const GRAVITY := 2800.0
const JUMP_V := -1050.0
const DASH_V := 720.0
const MAX_HP := 1000.0
const BODY_H := 185.0          # altura do sprite na tela
const HURT := Rect2(-52, -160, 104, 160)
const LEFT_WALL := 95.0
const RIGHT_WALL := 1185.0

# Golpes: quadros de preparação (startup), ativos e recuperação.
# box = área do golpe relativa aos pés, olhando para a direita.
const MOVES := {
	"light":    {"startup": 4,  "active": 3, "recovery": 9,  "dmg": 45.0,  "hitstun": 15, "blockstun": 10, "kb": Vector2(160, 0),    "box": Rect2(20, -120, 80, 70),  "sfx": "hit_light", "lunge": 14.0, "gain": 7.0},
	"heavy":    {"startup": 10, "active": 4, "recovery": 18, "dmg": 90.0,  "hitstun": 22, "blockstun": 14, "kb": Vector2(380, 0),    "box": Rect2(25, -140, 95, 110), "sfx": "hit_heavy", "lunge": 26.0, "gain": 11.0},
	"launcher": {"startup": 8,  "active": 4, "recovery": 18, "dmg": 70.0,  "hitstun": 30, "blockstun": 14, "kb": Vector2(120, -980), "box": Rect2(10, -170, 90, 160), "sfx": "hit_heavy", "lunge": 18.0, "gain": 10.0},
	"air_light":{"startup": 4,  "active": 4, "recovery": 8,  "dmg": 40.0,  "hitstun": 16, "blockstun": 9,  "kb": Vector2(140, -380), "box": Rect2(0, -110, 90, 110),  "sfx": "hit_light", "lunge": 10.0, "gain": 6.0},
	"air_heavy":{"startup": 8,  "active": 4, "recovery": 14, "dmg": 75.0,  "hitstun": 24, "blockstun": 12, "kb": Vector2(320, 520),  "box": Rect2(0, -90, 100, 120),  "sfx": "hit_heavy", "lunge": 16.0, "gain": 10.0, "spike": true},
	# especiais
	"orbe":      {"startup": 14, "active": 1,  "recovery": 20, "dmg": 80.0,  "hitstun": 20, "blockstun": 14, "kb": Vector2(300, -120), "box": Rect2(), "sfx": "hit_heavy", "lunge": 0.0, "gain": 9.0},
	"investida": {"startup": 8,  "active": 16, "recovery": 16, "dmg": 95.0,  "hitstun": 24, "blockstun": 16, "kb": Vector2(460, -260), "box": Rect2(10, -140, 90, 130), "sfx": "hit_heavy", "lunge": 0.0, "gain": 11.0},
	"ascensao":  {"startup": 5,  "active": 14, "recovery": 18, "dmg": 100.0, "hitstun": 28, "blockstun": 16, "kb": Vector2(90, -900),  "box": Rect2(-10, -210, 100, 210), "sfx": "hit_heavy", "lunge": 0.0, "gain": 11.0},
	"sombra":    {"startup": 12, "active": 4,  "recovery": 14, "dmg": 85.0,  "hitstun": 22, "blockstun": 14, "kb": Vector2(320, -200), "box": Rect2(10, -140, 100, 120), "sfx": "hit_heavy", "lunge": 20.0, "gain": 10.0},
	"supremo":   {"startup": 50, "active": 36, "recovery": 24, "dmg": 48.0,  "hitstun": 14, "blockstun": 10, "kb": Vector2(60, 0),     "box": Rect2(40, -150, 1300, 120), "sfx": "hit_heavy", "lunge": 0.0, "gain": 0.0, "multi": 6},
}

var idx := 0
var data: Dictionary
var opp: Node2D
var vel := Vector2.ZERO
var facing := 1
var on_ground := true
var hp := MAX_HP
var hp_shown := MAX_HP
var nucleo := 0.0
var state := "idle"
var st := 0                     # quadros no estado atual
var move := ""
var move_f := 0
var hits_done := 0
var chain := 0
var air_jumps := 0
var air_dash := true
var special_cd := 0
var combo_taken := 0            # golpes seguidos recebidos (para escalonar dano e limitar combo)
var juggle := 0
var invuln := 0
var frozen := false             # parado durante a câmera do supremo do outro
var block_press_f := -99        # para o contra-ataque perfeito
var frame := 0
var last_dir_tap := [0, -99]    # para dash com toque duplo
var flash := 0.0
var shake := 0.0
var inp_down := {}
var inp_press := {}             # ação -> quadros restantes no buffer

var spr: Sprite2D
var mat: ShaderMaterial
var walk_speed := 260.0
var dmg_mult := 1.0
var def_mult := 1.0

func setup(i: int, roster_index: int) -> void:
	idx = i
	data = Game.ROSTER[roster_index]
	walk_speed = 200.0 + 38.0 * data.vel
	dmg_mult = 0.8 + 0.1 * data.forca
	def_mult = 1.2 - 0.08 * data.def
	spr = Sprite2D.new()
	spr.texture = Game.tex(roster_index)
	var s := spr.texture.get_size()
	spr.scale = Vector2.ONE * (BODY_H / s.y)
	spr.offset = Vector2(0, -s.y / 2.0)
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nuniform float flash = 0.0;\nuniform vec4 flash_color : source_color = vec4(1.0);\nuniform float alpha = 1.0;\nvoid fragment(){ vec4 c = texture(TEXTURE, UV) * COLOR; c.rgb = mix(c.rgb, flash_color.rgb, flash); c.a *= alpha; COLOR = c; }"
	mat = ShaderMaterial.new()
	mat.shader = sh
	spr.material = mat
	add_child(spr)
	position = Vector2(400 if i == 0 else 880, FLOOR_Y)
	facing = 1 if i == 0 else -1

func reset_round() -> void:
	hp = MAX_HP
	hp_shown = MAX_HP
	vel = Vector2.ZERO
	position = Vector2(400 if idx == 0 else 880, FLOOR_Y)
	facing = 1 if idx == 0 else -1
	_go("idle")
	combo_taken = 0
	juggle = 0
	invuln = 0
	special_cd = 0
	frozen = false

# ---------------------------------------------------------------- entrada
func set_input(down: Dictionary, pressed: Array) -> void:
	inp_down = down
	for a in pressed:
		inp_press[a] = 7
		if a == "block":
			block_press_f = frame
		if a == "left" or a == "right":
			var d := -1 if a == "left" else 1
			if last_dir_tap[0] == d and frame - last_dir_tap[1] < 14:
				inp_press["dash"] = 7
			last_dir_tap = [d, frame]

func _pressed(a: String) -> bool:
	return inp_press.get(a, 0) > 0

func _consume(a: String) -> void:
	inp_press.erase(a)

func _held(a: String) -> bool:
	return inp_down.get(a, false)

func _dir() -> int:
	return int(_held("right")) - int(_held("left"))

# ---------------------------------------------------------------- estados
func _go(s: String) -> void:
	state = s
	st = 0

func is_airborne() -> bool:
	return not on_ground

func can_act() -> bool:
	return state in ["idle", "walk", "jump", "block"]

func is_attacking() -> bool:
	return state == "attack"

func is_down() -> bool:
	return state in ["knockdown", "ko"]

func current_move() -> Dictionary:
	return MOVES.get(move, {})

func step() -> void:
	frame += 1
	for k in inp_press.keys():
		inp_press[k] -= 1
		if inp_press[k] <= 0:
			inp_press.erase(k)
	if frozen:
		_animate()
		return
	st += 1
	if special_cd > 0: special_cd -= 1
	if invuln > 0: invuln -= 1
	flash = max(0.0, flash - 0.12)
	shake = max(0.0, shake - 0.6)
	hp_shown = move_toward(hp_shown, hp, 6.0) if state != "hitstun" else hp_shown
	match state:
		"idle", "walk": _ground_neutral()
		"jump": _air_neutral()
		"dash": _dash()
		"block": _block()
		"blockstun":
			vel.x = move_toward(vel.x, 0, 2400 * get_physics_process_delta_time())
			if st >= _stun_len: _go("idle")
		"attack": _attack()
		"hitstun": _hitstun()
		"knockdown": _knockdown()
		"ko":
			if on_ground: vel.x = move_toward(vel.x, 0, 1800.0 / 60.0)
		"win", "intro": pass
	_physics()
	_animate()

var _stun_len := 0

func _face_opp() -> void:
	if opp and abs(opp.position.x - position.x) > 4:
		facing = 1 if opp.position.x > position.x else -1

func _try_actions() -> bool:
	# ordem de prioridade: supremo, especial, pesado, leve, dash, pulo
	if _pressed("super") and nucleo >= 100.0:
		_consume("super")
		nucleo = 0.0
		_start_move("supremo")
		return true
	if _pressed("special") and special_cd <= 0:
		_consume("special")
		_start_move(data.especial)
		return true
	if _pressed("heavy"):
		_consume("heavy")
		_start_move("air_heavy" if is_airborne() else "heavy")
		return true
	if _pressed("light"):
		_consume("light")
		_start_move("air_light" if is_airborne() else "light")
		return true
	if _pressed("dash") and (on_ground or air_dash):
		_consume("dash")
		if not on_ground: air_dash = false
		var d := _dir()
		vel = Vector2((d if d != 0 else facing) * DASH_V, 0)
		_go("dash")
		Game.play("whoosh", 1.2)
		return true
	return false

func _ground_neutral() -> void:
	_face_opp()
	if _held("block"):
		_go("block")
		vel.x = 0
		return
	if _try_actions(): return
	if _pressed("up"):
		_consume("up")
		_jump()
		return
	var d := _dir()
	vel.x = d * walk_speed
	if d != 0 and state != "walk": _go("walk")
	elif d == 0 and state != "idle": _go("idle")

func _jump() -> void:
	vel.y = JUMP_V
	vel.x = _dir() * walk_speed * 1.05
	on_ground = false
	air_dash = true
	air_jumps = 1 if data.pulo_duplo else 0
	_go("jump")
	Game.play("jump", randf_range(0.95, 1.1), -6)

func _air_neutral() -> void:
	if _pressed("up") and air_jumps > 0 and st > 4:
		_consume("up")
		air_jumps -= 1
		vel.y = JUMP_V * 0.85
		vel.x = _dir() * walk_speed
		Game.play("jump", 1.3, -6)
		return
	_try_actions()
	vel.x = move_toward(vel.x, _dir() * walk_speed, 1400.0 / 60.0)

func _dash() -> void:
	if st >= 12:
		vel.x *= 0.3
		_go("jump" if not on_ground else "idle")
	else:
		vel.y = 0.0 if not on_ground else vel.y

func _block() -> void:
	_face_opp()
	vel.x = 0
	if not _held("block"):
		_go("idle")
	elif _try_actions():
		pass

func _start_move(m: String) -> void:
	move = m
	move_f = 0
	hits_done = 0
	_go("attack")
	if m in ["light", "heavy", "launcher"]:
		_face_opp()
		vel.x = 0
	if m == "supremo":
		_face_opp()
		vel = Vector2.ZERO
		Game.play("super")
	elif m in MOVES and m in ["orbe", "investida", "ascensao", "sombra"]:
		special_cd = 40
		Game.play("special", randf_range(0.95, 1.05))
	else:
		Game.play("whoosh", randf_range(0.9, 1.15), -4)

func _attack() -> void:
	var m := current_move()
	move_f += 1
	var su: int = m.startup
	var ac: int = m.active
	# cancelamentos: leve -> leve/pesado/especial; pesado -> especial
	if hits_done > 0 and move_f > su:
		if move in ["light", "air_light"]:
			if _pressed("light") and chain < 2:
				_consume("light"); chain += 1; _start_move(move); return
			if _pressed("heavy"):
				_consume("heavy")
				chain += 1
				_start_move("launcher" if (move == "light" and chain >= 2) else ("air_heavy" if is_airborne() else "heavy"))
				return
		if move in ["light", "heavy", "launcher", "air_light", "air_heavy"] and _pressed("special") and special_cd <= 0:
			_consume("special"); chain = 0; _start_move(data.especial); return
		if _pressed("super") and nucleo >= 100.0 and move != "supremo":
			_consume("super"); nucleo = 0.0; chain = 0; _start_move("supremo"); return
	match move:
		"investida":
			if move_f > su and move_f <= su + ac:
				vel.x = facing * 760.0
			else:
				vel.x = move_toward(vel.x, 0, 3000.0 / 60.0)
		"ascensao":
			if move_f <= 6: invuln = 2
			if move_f == su + 1:
				vel = Vector2(facing * 140.0, -980.0)
				on_ground = false
		"sombra":
			if move_f == su - 2 and opp:
				# some e reaparece atrás do adversário
				var side := 1 if position.x < opp.position.x else -1
				var nx := clampf(opp.position.x + side * 75.0, LEFT_WALL, RIGHT_WALL)
				if absf(nx - opp.position.x) < 40.0:   # encostado na parede: aparece do outro lado
					side = -side
					nx = clampf(opp.position.x + side * 75.0, LEFT_WALL, RIGHT_WALL)
				position.x = nx
				position.y = min(position.y, opp.position.y)
				facing = -side
				invuln = 4
		"orbe":
			if move_f == su:
				get_parent().get_parent().spawn_projectile(self)
		"air_light", "air_heavy":
			pass
		_:
			if on_ground: vel.x = move_toward(vel.x, 0, 3000.0 / 60.0)
	var total: int = su + ac + m.recovery
	if move in ["air_light", "air_heavy"] and on_ground and move_f > su:
		total = min(total, move_f + 4)
	if move == "ascensao" and move_f > su + ac and not on_ground:
		total = move_f + 1
	if move_f >= total:
		chain = 0
		_go("jump" if not on_ground else "idle")

func active_hitbox() -> Rect2:
	if state != "attack": return Rect2()
	var m := current_move()
	if m.is_empty() or m.box.size == Vector2.ZERO: return Rect2()
	var su: int = m.startup
	if move_f <= su or move_f > su + m.active: return Rect2()
	var multi: int = m.get("multi", 1)
	if hits_done >= multi: return Rect2()
	if multi > 1 and (move_f - su) % int(m.active / multi) != 1 and hits_done > 0: return Rect2()
	var b: Rect2 = m.box
	var x0 := b.position.x if facing == 1 else -b.position.x - b.size.x
	return Rect2(position + Vector2(x0, b.position.y), b.size)

func hurtbox() -> Rect2:
	if invuln > 0 or state in ["ko"] or (state == "knockdown" and on_ground): return Rect2()
	return Rect2(position + HURT.position, HURT.size)

# ---------------------------------------------------------------- receber golpe
## Retorna "hit", "block", "perfect" ou "" (não acertou)
func take_hit(atk: Node2D, m: Dictionary, from_dir: int, scaled := true) -> String:
	if state == "ko": return ""
	var blocking := state in ["block", "blockstun"] and on_ground
	if blocking and frame - block_press_f <= 8 and atk.move != "supremo":
		# CONTRA-ATAQUE PERFEITO
		nucleo = min(100.0, nucleo + 20.0)
		atk.stun_attacker(30)
		block_press_f = -99
		return "perfect"
	if blocking:
		var chip: float = m.dmg * atk.dmg_mult * (0.2 if atk.move == "supremo" else 0.1)
		hp = max(1.0, hp - chip)
		_stun_len = m.blockstun
		_go("blockstun")
		vel.x = from_dir * m.kb.x * 0.6
		nucleo = min(100.0, nucleo + 3.0)
		return "block"
	var dscale := 1.0
	if scaled: dscale = max(0.3, 1.0 - 0.1 * combo_taken)
	var dmg: float = m.dmg * atk.dmg_mult * def_mult * dscale
	hp = max(0.0, hp - dmg)
	combo_taken += 1
	nucleo = min(100.0, nucleo + 5.0)
	flash = 1.0
	shake = 6.0
	var kb: Vector2 = m.kb
	if not on_ground or kb.y < 0:
		juggle += 1
	if hp <= 0.0:
		vel = Vector2(from_dir * 520.0, -700.0)
		on_ground = false
		_go("ko")
		return "hit"
	if juggle > 5 and not on_ground:
		# limite de combo aéreo: cai direto
		vel = Vector2(from_dir * 260.0, 200.0)
		_go("knockdown")
		return "hit"
	if m.get("spike", false) and not on_ground:
		vel = Vector2(from_dir * kb.x, kb.y)
		_go("knockdown")
		return "hit"
	if kb.y < 0 or not on_ground:
		vel = Vector2(from_dir * kb.x, kb.y if kb.y < 0 else -320.0)
		on_ground = false
		_stun_len = m.hitstun
		_go("hitstun")
	else:
		vel = Vector2(from_dir * kb.x, 0)
		_stun_len = m.hitstun
		_go("hitstun")
	return "hit"

func stun_attacker(f: int) -> void:
	_stun_len = f
	vel.x = -facing * 200.0
	flash = 0.6
	_go("hitstun")

func _hitstun() -> void:
	if on_ground:
		vel.x = move_toward(vel.x, 0, 2200.0 / 60.0)
		if st >= _stun_len:
			combo_taken = 0
			juggle = 0
			_go("idle")
	# no ar continua em hitstun até cair; ao cair vira knockdown (ver _physics)

func _knockdown() -> void:
	if on_ground:
		vel.x = move_toward(vel.x, 0, 2400.0 / 60.0)
		if st >= 46:
			combo_taken = 0
			juggle = 0
			invuln = 20
			_go("idle")

# ---------------------------------------------------------------- física
func _physics() -> void:
	var dt := 1.0 / 60.0
	var g := GRAVITY
	if state == "dash" and not on_ground: g = 0.0
	if state == "hitstun" and not on_ground: g = GRAVITY * 0.85
	if state == "attack" and move == "supremo": g = 0.0 if move_f < 90 else GRAVITY
	if not on_ground:
		vel.y += g * dt
	position += vel * dt
	if position.y >= FLOOR_Y:
		position.y = FLOOR_Y
		if not on_ground:
			on_ground = true
			vel.y = 0
			air_dash = true
			if state == "jump" or state == "dash":
				_go("idle")
				spr_squash = 1.0
			elif state == "hitstun":
				if juggle > 0:
					_go("knockdown")
					Game.play("hit_light", 0.6, -6)
				elif st >= _stun_len:
					_go("idle")
			elif state == "attack" and move in ["air_light", "air_heavy", "ascensao"]:
				pass
			elif state == "ko":
				vel.x *= 0.4
				Game.play("hit_heavy", 0.5, -4)
	position.x = clampf(position.x, LEFT_WALL, RIGHT_WALL)

# ---------------------------------------------------------------- visual
var spr_squash := 0.0
var t_anim := 0.0

func _animate() -> void:
	t_anim += 1.0 / 60.0
	spr_squash = max(0.0, spr_squash - 0.08)
	var off := Vector2.ZERO
	var rot := 0.0
	var sc := Vector2.ONE
	var alpha := 1.0
	match state:
		"idle", "intro":
			off.y = -6.0 * (0.5 + 0.5 * sin(t_anim * 3.0)) - 4.0
			sc = Vector2(1.0 + 0.015 * sin(t_anim * 3.0), 1.0 - 0.015 * sin(t_anim * 3.0))
		"walk":
			off.y = -abs(sin(t_anim * 9.0)) * 10.0 - 4.0
			rot = 0.09 * sign(vel.x) * facing
		"jump":
			rot = clampf(vel.y / 4000.0, -0.25, 0.25) * -1.0
			sc = Vector2(1.0 - 0.06 * sign(-vel.y), 1.0 + 0.06 * sign(-vel.y))
		"dash":
			rot = 0.25 * sign(vel.x) * facing
			sc = Vector2(1.15, 0.9)
			alpha = 0.85
		"block", "blockstun":
			rot = -0.1
			sc = Vector2(0.95, 1.0)
		"attack":
			var m := current_move()
			var su: int = m.startup
			if move_f <= su:
				rot = -0.12
				off.x = -6.0
				if move == "sombra":
					alpha = 1.0 - float(move_f) / su
				if move == "supremo":
					off.y = -20.0 * float(move_f) / su
					sc = Vector2.ONE * (1.0 + 0.15 * float(move_f) / su)
			elif move_f <= su + m.active:
				rot = 0.18
				off.x = m.lunge
				if move == "ascensao": rot = -0.35
				if move == "investida": rot = 0.3; sc = Vector2(1.12, 0.92)
				if move == "supremo": off.y = -20.0; sc = Vector2.ONE * 1.15; rot = 0.05
			else:
				rot = 0.05
		"hitstun":
			rot = -0.2
			off.x = randf_range(-shake, shake)
		"knockdown", "ko":
			rot = -1.35 if on_ground else -0.6
			off.y = 18.0 if on_ground else 0.0
			if state == "knockdown" and on_ground and st > 30:
				rot = lerpf(-1.35, 0.0, (st - 30) / 16.0)
		"win":
			off.y = -abs(sin(t_anim * 5.0)) * 30.0
			sc = Vector2(1.0, 1.0 + 0.05 * sin(t_anim * 10.0))
	if spr_squash > 0.0:
		sc *= Vector2(1.0 + 0.2 * spr_squash, 1.0 - 0.2 * spr_squash)
	if invuln > 0 and state == "idle" and int(t_anim * 20) % 2 == 0:
		alpha *= 0.5
	spr.position = Vector2(off.x * facing, off.y)
	spr.rotation = rot * facing
	var base := BODY_H / spr.texture.get_size().y
	spr.scale = Vector2(base * sc.x * (1 if facing == 1 else -1), base * sc.y)
	mat.set_shader_parameter("flash", flash)
	mat.set_shader_parameter("alpha", alpha)
	queue_redraw()

func _draw() -> void:
	# sombra no chão
	var h := FLOOR_Y - position.y
	var w := 60.0 * clampf(1.0 - h / 500.0, 0.4, 1.0)
	draw_set_transform(Vector2(0, h + 2), 0, Vector2(1, 0.22))
	draw_circle(Vector2.ZERO, w, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var cor: Color = data.cor
	# escudo de defesa
	if state in ["block", "blockstun"]:
		var c := Vector2(facing * 52, -75)
		var pts := PackedVector2Array()
		for i in 7:
			var a := -PI / 2 + i * TAU / 6
			pts.append(c + Vector2(cos(a) * 34, sin(a) * 70))
		draw_colored_polygon(pts, Color(cor, 0.25 if state == "block" else 0.5))
		draw_polyline(pts, Color(cor.lightened(0.4), 0.9), 3)
	# rastro do golpe
	if state == "attack":
		var m := current_move()
		var su: int = m.startup
		if move_f > su and move_f <= su + m.active + 2 and move not in ["orbe", "supremo"]:
			var k: float = float(move_f - su) / (m.active + 2)
			var center := Vector2(facing * 45, -80)
			var rad := 70.0
			var thick := 10.0
			if move in ["heavy", "air_heavy", "launcher", "investida", "sombra"]: rad = 90.0; thick = 16.0
			var a0 := -1.2 if move != "ascensao" else -2.6
			var a1 := 1.0 if move != "launcher" and move != "ascensao" else -0.2
			if move == "air_heavy": a0 = -0.4; a1 = 1.6
			if facing == -1:
				var tmp := PI - a1
				a1 = PI - a0
				a0 = tmp
			draw_arc(center, rad, a0, a0 + (a1 - a0) * min(1.0, k * 1.6), 24, Color(cor.lightened(0.3), 0.9 * (1.0 - k * 0.6)), thick)
			draw_arc(center, rad, a0, a0 + (a1 - a0) * min(1.0, k * 1.6), 24, Color(1, 1, 1, 0.7 * (1.0 - k)), thick * 0.35)
		if move == "supremo" and move_f <= su:
			var k2: float = float(move_f) / su
			for i in 3:
				draw_arc(Vector2(0, -100), 140.0 * (1.0 - k2) + i * 20, 0, TAU, 40, Color(cor, 0.6 * k2), 4)
	# aura do Núcleo cheio
	if nucleo >= 100.0 and state != "ko":
		var p := 0.5 + 0.5 * sin(t_anim * 8.0)
		draw_arc(Vector2(0, -80), 90 + p * 6, 0, TAU, 40, Color(cor, 0.35 + 0.25 * p), 3)
