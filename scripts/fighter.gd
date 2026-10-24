extends Node2D
## Um lutador (botton). A luta (fight.gd) chama step() a cada quadro (60 por segundo).
## O corpo e os dois braços são peças separadas (assets/rig), animadas por código.

const FLOOR_Y := 600.0
const GRAVITY := 2800.0
const JUMP_V := -1050.0
const DASH_V := 720.0
const MAX_HP := 1000.0
const BODY_H := 185.0          # altura do botton na tela
const HURT := Rect2(-52, -160, 104, 160)
const LEFT_WALL := 95.0
const RIGHT_WALL := 1185.0
const SUPER_STARTUP := 45      # duração da câmera cinematográfica do supremo

# Golpes: quadros de preparação (startup), ativos e recuperação.
# box = área do golpe relativa aos pés, olhando para a direita. kb = empurrão (x para frente, y negativo = para cima)
const MOVES := {
	"light":     {"startup": 4,  "active": 3,  "recovery": 9,  "dmg": 45.0,  "hitstun": 15, "blockstun": 10, "kb": Vector2(160, 0),    "box": Rect2(20, -125, 85, 70),   "sfx": "hit_light", "lunge": 14.0, "gain": 7.0},
	"heavy":     {"startup": 10, "active": 4,  "recovery": 18, "dmg": 90.0,  "hitstun": 22, "blockstun": 14, "kb": Vector2(380, 0),    "box": Rect2(25, -145, 100, 110), "sfx": "hit_heavy", "lunge": 26.0, "gain": 11.0},
	"launcher":  {"startup": 8,  "active": 4,  "recovery": 18, "dmg": 70.0,  "hitstun": 30, "blockstun": 14, "kb": Vector2(120, -980), "box": Rect2(10, -175, 95, 165),  "sfx": "hit_heavy", "lunge": 18.0, "gain": 10.0},
	"air_light": {"startup": 4,  "active": 4,  "recovery": 8,  "dmg": 40.0,  "hitstun": 16, "blockstun": 9,  "kb": Vector2(140, -380), "box": Rect2(0, -115, 95, 115),   "sfx": "hit_light", "lunge": 10.0, "gain": 6.0},
	"air_heavy": {"startup": 8,  "active": 4,  "recovery": 14, "dmg": 75.0,  "hitstun": 24, "blockstun": 12, "kb": Vector2(320, 520),  "box": Rect2(0, -95, 105, 125),   "sfx": "hit_heavy", "lunge": 16.0, "gain": 10.0, "spike": true},
}
const Powers := preload("res://scripts/powers.gd")
# quanto tempo cada supremo mantém o lutador ocupado depois da câmera
const SUPER_DUR := {"raio": 44, "erupcao": 56, "ilusao": 62, "furia": 66, "ciclone": 34, "tsunami": 34,
	"era_glacial": 82, "julgamento": 74, "terremoto": 60, "canhao": 48, "meteoros": 56, "transmutacao": 70}

var idx := 0
var data: Dictionary
var fight: Node
var opp: Node2D
var vel := Vector2.ZERO
var facing := 1
var on_ground := true
var hp := MAX_HP
var max_hp := MAX_HP
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
var cds := [0, 0, 0, 0]         # recarga de cada poder (neutro, frente, cima, baixo)
var slot := -1                  # poder em uso
var slow_t := 0                 # lento (Poço Sombrio)
var ultimo_efetivo := -99
var efetivo := false             # o último golpe recebido foi super efetivo
var combo_taken := 0            # golpes seguidos recebidos (para escalonar dano e limitar combo)
var combo_dmg := 0.0            # dano do combo atual (modo Treino)
var juggle := 0
var invuln := 0
var frozen := false             # parado durante a câmera do supremo do outro
var block_press_f := -99        # para o contra-ataque perfeito
var frame := 0
var last_dir_tap := [0, -99]    # para dash com toque duplo
var last_press := {}            # ação -> quadro em que foi apertada
var flash := 0.0
var shake := 0.0
var inp_down := {}
var inp_press := {}             # ação -> quadros restantes no buffer
var ice := 0                    # congelado (quadros)
var poison_t := 0               # efeito visual de veneno
var armor := false              # Avalanche: aguenta um golpe
var overload_t := 0             # Sobrecarga ativa (quadros)
var alpha_mul := 1.0            # some no Passo Sombrio / Portal / Mil Sombras
var eco := false                # chefe Eco Sombrio do Arcade
var alt_cor := Color.WHITE      # cor alternativa (mesmo botton dos dois lados)
var alt := false
var super_flag := {}
var _stun_len := 0
var _portal_hit := false

var walk_speed := 260.0
var dmg_mult := 1.0
var def_mult := 1.0

# rig (corpo + braços)
var rig: Node2D
var body: Sprite2D
var arm_back: Node2D
var arm_front: Node2D
var hand_front := Vector2.ZERO
var hand_back := Vector2.ZERO
var mat: ShaderMaterial
var rig_h := 440.0
var pose := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var arm_back_front := false
var fist_trail: Array = []

func setup(i: int, roster_index: int, f: Node, eco_mode := false) -> void:
	idx = i
	fight = f
	eco = eco_mode
	data = Game.ROSTER[roster_index]
	walk_speed = 200.0 + 38.0 * data.vel
	dmg_mult = 0.8 + 0.1 * data.forca
	def_mult = 1.2 - 0.08 * data.def
	if eco:
		max_hp = MAX_HP * 1.25
		dmg_mult *= 1.1
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform float flash = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float alpha = 1.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float tint_amt = 0.0;
uniform float dark = 0.0;
void fragment(){
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(lum) * tint.rgb * 1.35, tint_amt);
	vec3 sombra = vec3(lum * 0.30, lum * 0.10, lum * 0.42) + vec3(0.55, 0.0, 0.25) * smoothstep(0.55, 0.9, lum);
	c.rgb = mix(c.rgb, sombra, dark);
	c.rgb = mix(c.rgb, flash_color.rgb, flash);
	c.a *= alpha;
	COLOR = c;
}"""
	mat = ShaderMaterial.new()
	mat.shader = sh
	if eco:
		mat.set_shader_parameter("dark", 0.85)
	elif i == 1 and Game.escolha[0] == Game.escolha[1]:
		alt = true
		var c: Color = data.cor
		alt_cor = Color.from_hsv(fposmod(c.h + 0.45, 1.0), maxf(0.6, c.s), 1.0)
	_build_rig()
	position = Vector2(400 if i == 0 else 880, FLOOR_Y)
	facing = 1 if i == 0 else -1
	hp = max_hp
	hp_shown = max_hp

func _build_rig() -> void:
	var id: String = data.id
	var rd: Dictionary = Game.rig_data[id]
	var tx: Dictionary = Game.rig_tex[id]
	var w: float = rd.W
	var h: float = rd.H
	rig_h = h
	rig = Node2D.new()
	add_child(rig)
	arm_back = _make_arm(rd.armL, tx.armL, w, h)
	body = Sprite2D.new()
	body.texture = tx.body
	body.centered = false
	body.position = Vector2(-w / 2.0, -h)
	body.material = mat
	arm_front = _make_arm(rd.armR, tx.armR, w, h)
	rig.add_child(arm_back)
	rig.add_child(body)
	rig.add_child(arm_front)
	arm_front.z_index = 1
	hand_front = Vector2(rd.armR.hx - rd.armR.px, rd.armR.hy - rd.armR.py)
	hand_back = Vector2(rd.armL.hx - rd.armL.px, rd.armL.hy - rd.armL.py)

func _make_arm(a: Dictionary, t: Texture2D, w: float, h: float) -> Node2D:
	var piv := Node2D.new()
	piv.position = Vector2(a.px - w / 2.0, a.py - h)
	piv.set_meta("base", piv.position)
	var s := Sprite2D.new()
	s.texture = t
	s.centered = false
	s.position = Vector2(a.x - a.px, a.y - a.py)
	s.material = mat
	piv.add_child(s)
	return piv

func reset_round() -> void:
	hp = max_hp
	hp_shown = max_hp
	vel = Vector2.ZERO
	position = Vector2(400 if idx == 0 else 880, FLOOR_Y)
	facing = 1 if idx == 0 else -1
	on_ground = true
	_go("idle")
	combo_taken = 0
	combo_dmg = 0.0
	juggle = 0
	invuln = 0
	cds = [0, 0, 0, 0]
	slot = -1
	slow_t = 0
	frozen = false
	ice = 0
	poison_t = 0
	armor = false
	overload_t = 0
	alpha_mul = 1.0
	move = ""
	fist_trail.clear()
	reset_physics_interpolation()

# ---------------------------------------------------------------- entrada
func set_input(down: Dictionary, pressed: Array) -> void:
	inp_down = down
	for a in pressed:
		inp_press[a] = 7
		last_press[a] = frame
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

## pesado + especial apertados juntos (Sobrecarga / Explosão de Núcleo)
func _combo_overload() -> bool:
	var h: int = last_press.get("heavy", -99)
	var s: int = last_press.get("special", -99)
	return frame - h <= 5 and frame - s <= 5 and (_pressed("heavy") or _pressed("special"))

# ---------------------------------------------------------------- estados
func _go(s: String) -> void:
	state = s
	st = 0

func is_airborne() -> bool:
	return not on_ground

func is_attacking() -> bool:
	return state == "attack"

func is_down() -> bool:
	return state in ["knockdown", "ko"]

func in_super() -> bool:
	return state == "attack" and move == "supremo"

func in_super_cinematic() -> bool:
	return in_super() and move_f <= SUPER_STARTUP

func current_move() -> Dictionary:
	if move == "supremo":
		return {"startup": SUPER_STARTUP, "active": SUPER_DUR.get(data.supremo, 50), "recovery": 14, "box": Rect2()}
	if MOVES.has(move):
		return MOVES[move]
	return Powers.get_def(move)

## tipo de poder "do corpo" do golpe atual ("rush", "rise", "tp", "portal" ou "")
func self_tipo() -> String:
	if move == "" or MOVES.has(move) or move == "supremo":
		return ""
	return Powers.get_def(move).get("self", "")

func is_power() -> bool:
	return move != "" and not MOVES.has(move) and move != "supremo"

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
	for k in 4:
		if cds[k] > 0: cds[k] -= 1
	if slow_t > 0: slow_t -= 1
	if invuln > 0: invuln -= 1
	if ice > 0: ice -= 1
	if poison_t > 0:
		poison_t -= 1
		if poison_t % 12 == 0 and state != "ko" and hp > 1.0:
			hp = maxf(1.0, hp - 3.0)
	if overload_t > 0:
		overload_t -= 1
		if overload_t == 0 and fight:
			fight.fx.pop("SOBRECARGA ACABOU", position + Vector2(0, -210), Color(1, 1, 1, 0.8), 22)
	flash = max(0.0, flash - 0.12)
	shake = max(0.0, shake - 0.6)
	hp_shown = move_toward(hp_shown, hp, 6.0) if state != "hitstun" else hp_shown
	alpha_mul = move_toward(alpha_mul, 1.0, 0.1) if not (state == "attack" and (self_tipo() in ["tp", "portal"] or move == "supremo")) else alpha_mul
	match state:
		"idle", "walk": _ground_neutral()
		"jump": _air_neutral()
		"prejump": _prejump()
		"dash": _dash()
		"block": _block()
		"blockstun":
			vel.x = move_toward(vel.x, 0, 40.0)
			if st >= _stun_len: _go("idle")
		"attack": _attack()
		"hitstun": _hitstun()
		"knockdown": _knockdown()
		"burst":
			vel = vel.lerp(Vector2.ZERO, 0.2)
			if st >= 20:
				_go("jump" if not on_ground else "idle")
		"ko":
			if on_ground: vel.x = move_toward(vel.x, 0, 30.0)
		"win", "intro": pass
	_physics()
	_animate()

func _face_opp() -> void:
	if opp and abs(opp.position.x - position.x) > 4:
		facing = 1 if opp.position.x > position.x else -1

func _try_actions() -> bool:
	# ordem de prioridade: sobrecarga, supremo, especial, pesado, leve, dash
	if _combo_overload() and nucleo >= 50.0 and overload_t <= 0:
		_consume("heavy"); _consume("special")
		_start_overload()
		return true
	if _pressed("super") and nucleo >= 100.0:
		_consume("super")
		nucleo = 0.0
		_start_move("supremo")
		return true
	if _pressed("special") and _try_power():
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
		vel = Vector2((d if d != 0 else facing) * DASH_V * (1.12 if overload_t > 0 else 1.0), 0)
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
		_go("prejump")
		vel.x = 0.0
		return
	var d := _dir()
	vel.x = d * walk_speed * (1.12 if overload_t > 0 else 1.0) * (0.5 if slow_t > 0 else 1.0)
	if d != 0 and state != "walk": _go("walk")
	elif d == 0 and state != "idle": _go("idle")

## Antes do pulo há 3 quadros: se o especial for apertado nesse tempo, sai o poder "cima" (↑ + especial).
func _prejump() -> void:
	if _pressed("special") and _try_power(2):
		return
	if st >= 3:
		_jump()

## Escolhe o poder pela direção segurada. forcar_slot >= 0 força um poder.
func _try_power(forcar_slot := -1) -> bool:
	var sl := forcar_slot
	if sl < 0:
		if _held("up"):
			sl = 2
		elif _held("down"):
			sl = 3
		elif _dir() != 0 and _dir() == _frente():
			sl = 1
		else:
			sl = 0
	if cds[sl] > 0:
		if fight and forcar_slot < 0 and st % 6 == 0:
			pass
		return false
	_consume("special")
	slot = sl
	_start_move(data.poderes[sl])
	return true

## direção "para frente" (para o rival)
func _frente() -> int:
	if opp == null:
		return facing
	return 1 if opp.position.x >= position.x else -1

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
		if fight: fight.fx.puff(position + Vector2(0, -10), Color(1, 1, 1, 0.7), 8)
		return
	_try_actions()
	vel.x = move_toward(vel.x, _dir() * walk_speed, 1400.0 / 60.0)

func _dash() -> void:
	if fight and st % 2 == 0: fight.fx.afterimage(self)
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

func _start_overload() -> void:
	nucleo -= 50.0
	overload_t = 360
	invuln = 12
	flash = 1.0
	Game.play("overload")
	if fight:
		fight.fx.pop("SOBRECARGA!", position + Vector2(0, -230), data.cor.lightened(0.3), 40)
		fight.fx.burst(position + Vector2(0, -90), data.cor, 26, 1.6)
		fight.fx.ring(position + Vector2(0, -90), data.cor, 1.6)
	_go("burst")
	vel = Vector2.ZERO

## Explosão de Núcleo: escapa de um combo gastando 50% do Núcleo
func _start_burst() -> void:
	nucleo -= 50.0
	invuln = 24
	ice = 0
	flash = 1.0
	combo_taken = 0
	juggle = 0
	Game.play("overload", 0.8)
	if fight:
		fight.fx.pop("EXPLOSÃO DE NÚCLEO!", position + Vector2(0, -230), data.cor.lightened(0.3), 34)
		fight.fx.ring(position + Vector2(0, -90), data.cor, 2.2)
		fight.spawn({"kind": "burst", "owner": self, "pos": position + Vector2(0, -90), "size": Vector2(320, 300), "anchor": "c",
			"life": 6, "dmg": 0.0, "kb": Vector2(620, -320), "hitstun": 22, "blockstun": 18, "cor": data.cor,
			"dir": 1 if opp.position.x >= position.x else -1, "gain": 0.0, "sfx": "hit_heavy", "unblockable": true})
	_go("burst")
	vel = Vector2(0, -200) if not on_ground else Vector2.ZERO

func _start_move(m: String) -> void:
	move = m
	move_f = 0
	hits_done = 0
	armor = false
	_portal_hit = false
	fist_trail.clear()
	_go("attack")
	if m in ["light", "heavy", "launcher"]:
		_face_opp()
		vel.x = 0
	if m == "supremo":
		_face_opp()
		vel = Vector2.ZERO
		super_flag = {}
		invuln = SUPER_STARTUP + 2
		Game.play("super")
		if fight: fight.on_super_start(self)
	elif is_power():
		var pd := Powers.get_def(m)
		var sl: int = data.poderes.find(m)
		slot = sl
		if sl >= 0:
			cds[sl] = int(pd.get("cd", 60) * (0.5 if overload_t > 0 else 1.0))
		_face_opp()
		var st_tipo: String = pd.get("self", "")
		if st_tipo != "tp" and st_tipo != "portal":
			Game.play("special", randf_range(0.95, 1.05), -3)
		if pd.get("armor", false): armor = true
		if st_tipo in ["tp", "portal"]:
			Game.play("shadow" if st_tipo == "tp" else "portal")
			if fight: fight.fx.portal(position + Vector2(0, -90), data.cor)
		if fight: fight.fx.charge(self)
	else:
		Game.play("whoosh", randf_range(0.9, 1.15), -4)

func _attack() -> void:
	var m := current_move()
	move_f += 1
	var su: int = m.startup
	var ac: int = m.active
	# Sobrecarga cancelando o começo de um golpe pesado/especial
	if move_f <= 5 and move != "supremo" and _combo_overload() and nucleo >= 50.0 and overload_t <= 0:
		_consume("heavy"); _consume("special")
		_start_overload()
		return
	# cancelamentos: leve -> leve/pesado/especial; pesado -> especial; qualquer acerto -> supremo
	if hits_done > 0 and move_f > su:
		if move in ["light", "air_light"]:
			if _pressed("light") and chain < 2:
				_consume("light"); chain += 1; _start_move(move); return
			if _pressed("heavy"):
				_consume("heavy")
				chain += 1
				_start_move("launcher" if (move == "light" and chain >= 2) else ("air_heavy" if is_airborne() else "heavy"))
				return
		if move in ["light", "heavy", "launcher", "air_light", "air_heavy"] and _pressed("special"):
			chain = 0
			if _try_power(): return
		if _pressed("super") and nucleo >= 100.0 and move != "supremo":
			_consume("super"); nucleo = 0.0; chain = 0; _start_move("supremo"); return
	var tipo := self_tipo()
	match tipo:
		"rush":
			if move_f > su and move_f <= su + ac:
				vel.x = facing * float(m.get("speed", 700.0))
				if fight:
					if armor or m.get("armor", false):
						if move_f % 3 == 0: fight.fx.debris(position + Vector2(-facing * 20, -10), data.cor2)
					elif move_f % 2 == 0:
						fight.fx.flame_trail(position + Vector2(-facing * 30, -80), data.cor)
			else:
				vel.x = move_toward(vel.x, 0, 50.0)
				if move_f > su + ac: armor = false
		"rise":
			if move_f <= int(m.get("invuln", 6)): invuln = 2
			if move_f == su + 1:
				vel = Vector2(facing * 140.0, -980.0)
				on_ground = false
				if fight: fight.fx.ring(position + Vector2(0, -60), data.cor, 1.2)
			if fight and move_f > su and move_f <= su + ac and move_f % 2 == 0:
				fight.fx.flame_trail(position + Vector2(0, -60), data.cor)
		"tp":
			alpha_mul = clampf(1.0 - float(move_f) / (su - 2), 0.0, 1.0) if move_f < su - 2 else minf(1.0, alpha_mul + 0.34)
			if move_f == su - 2 and opp:
				var side := 1 if position.x < opp.position.x else -1
				var nx := clampf(opp.position.x + side * 75.0, LEFT_WALL, RIGHT_WALL)
				if absf(nx - opp.position.x) < 40.0:   # encostado na parede: aparece do outro lado
					side = -side
					nx = clampf(opp.position.x + side * 75.0, LEFT_WALL, RIGHT_WALL)
				position.x = nx
				position.y = min(position.y, opp.position.y)
				facing = -side
				invuln = 4
				reset_physics_interpolation()
				if fight: fight.fx.portal(position + Vector2(0, -90), data.cor)
		"portal":
			_portal_update(su, ac)
		_:
			match move:
				"supremo":
					if on_ground or move_f <= su: vel.x = move_toward(vel.x, 0, 50.0)
					if move_f <= su:
						vel.y = 0.0
					else:
						_super_frame(move_f - su)
				"air_light", "air_heavy":
					pass
				_:
					if on_ground: vel.x = move_toward(vel.x, 0, 50.0)
					if is_power() and move_f == su:
						Powers.spawn(move, self, fight)
	var total: int = su + ac + m.recovery
	if move in ["air_light", "air_heavy"] and on_ground and move_f > su:
		total = min(total, move_f + 4)
	if tipo == "rise" and move_f > su + ac and not on_ground:
		total = move_f + 1
	if move_f >= total:
		chain = 0
		armor = false
		_go("jump" if not on_ground else "idle")

func _portal_update(su: int, ac: int) -> void:
	if move_f < su:
		alpha_mul = clampf(1.0 - float(move_f) / su, 0.0, 1.0)
		invuln = 2
		vel = Vector2.ZERO
	elif move_f == su and opp:
		var tx := clampf(opp.position.x - facing * 10.0, LEFT_WALL, RIGHT_WALL)
		position = Vector2(tx, FLOOR_Y - 330.0)
		on_ground = false
		vel = Vector2.ZERO
		invuln = 4
		reset_physics_interpolation()
		if fight: fight.fx.portal(position + Vector2(0, -90), data.cor)
	elif move_f <= su + 5:
		alpha_mul = minf(1.0, alpha_mul + 0.25)
		vel = Vector2.ZERO
	elif move_f <= su + ac:
		alpha_mul = 1.0
		if not on_ground and not _portal_hit:
			vel = Vector2(0, 1500.0)
		if on_ground and move_f < su + ac:
			# aterrissou: termina o golpe
			move_f = su + ac
			if fight:
				fight.fx.ring(position + Vector2(0, -10), data.cor, 1.0)
				fight.fx.debris(position, data.cor)

func on_attack_hit() -> void:
	if self_tipo() == "portal":
		_portal_hit = true
		vel = Vector2(-facing * 180.0, -620.0)

# ---------------------------------------------------------------- supremos (k = quadro depois da câmera)
func _super_frame(k: int) -> void:
	if fight == null or opp == null: return
	var d := facing
	var cor: Color = data.cor
	var ox: float = opp.position.x
	match data.supremo:
		"raio":
			if k == 1:
				fight.spawn({"kind": "beam", "owner": self, "pos": position + Vector2(d * 80, -95), "anchor": "beam",
					"size": Vector2(1400, 150), "life": 38, "hits": 6, "interval": 6, "dmg": 44.0, "kb": Vector2(80, 0),
					"kb_last": Vector2(520, -620), "hitstun": 16, "blockstun": 10, "super": true, "dir": d, "cor": cor})
				Game.play("beam")
		"erupcao":
			if k == 1:
				var x0 := position.x + d * 120.0
				for i in 5:
					var x := clampf(lerpf(x0, ox, i / 4.0), 50.0, 1230.0)
					fight.spawn({"kind": "firepillar", "owner": self, "pos": Vector2(x, FLOOR_Y), "anchor": "b", "size": Vector2(115, 330),
						"delay": 6 + i * 6, "life": 18, "hits": 2, "interval": 8, "dmg": 28.0, "kb": Vector2(40, 0), "kb_last": Vector2(40, 0),
						"hitstun": 30, "blockstun": 10, "super": true, "dir": d, "cor": cor, "sfx": "hit_light"})
				fight.spawn({"kind": "firepillar", "owner": self, "pos": Vector2(ox, FLOOR_Y), "anchor": "b", "size": Vector2(170, 430),
					"track": true, "track_lock": 6, "delay": 40, "life": 22, "hits": 2, "interval": 8, "dmg": 55.0, "kb": Vector2(60, -500),
					"kb_last": Vector2(220, -980), "hitstun": 34, "blockstun": 12, "super": true, "dir": d, "cor": cor})
				Game.play("fire")
		"ilusao":
			if k == 1:
				alpha_mul = 0.0
				for i in 6:
					var sd := d if i % 2 == 0 else -d
					fight.spawn({"kind": "shadowslash", "owner": self, "pos": opp.position + Vector2(0, -80), "anchor": "c", "track": true,
						"track_lock": 2, "size": Vector2(200, 200), "delay": 4 + i * 8, "life": 6, "dmg": 34.0 if i < 5 else 80.0,
						"kb": Vector2(70, 0), "kb_last": Vector2(360, -820) if i == 5 else Vector2(70, 0), "hitstun": 34, "blockstun": 10,
						"super": true, "dir": sd, "cor": cor, "sfx": "hit_heavy" if i == 5 else "hit_light"})
				Game.play("shadow")
			if k < 56:
				alpha_mul = 0.0
				invuln = 3
			if k == 56:
				var side := 1 if position.x < ox else -1
				position.x = clampf(ox + side * 80.0, LEFT_WALL, RIGHT_WALL)
				facing = -side
				alpha_mul = 1.0
				fight.fx.portal(position + Vector2(0, -90), cor)
		"furia":
			if k == 1:
				fight.spawn({"kind": "bigvine", "owner": self, "pos": Vector2(ox, FLOOR_Y), "anchor": "b", "track": true, "track_lock": 8,
					"size": Vector2(175, 440), "delay": 24, "life": 40, "hits": 6, "interval": 6, "dmg": 38.0, "kb": Vector2(0, -430),
					"kb_last": Vector2(150, -1050), "hitstun": 30, "blockstun": 10, "super": true, "dir": d, "cor": cor})
				Game.play("quake")
		"ciclone":
			if k == 1:
				fight.spawn({"kind": "cyclone", "owner": self, "pos": Vector2(position.x + d * 130, FLOOR_Y), "anchor": "b",
					"vel": Vector2(d * 300, 0), "size": Vector2(210, 450), "life": 150, "hits": 8, "interval": 9, "dmg": 32.0,
					"kb": Vector2(40, -480), "kb_last": Vector2(350, -950), "hitstun": 32, "blockstun": 10, "super": true, "dir": d, "cor": cor, "sfx": "hit_light"})
				Game.play("wind", 0.7)
		"tsunami":
			if k == 1:
				fight.spawn({"kind": "tsunami", "owner": self, "pos": Vector2(position.x - d * 160, FLOOR_Y), "anchor": "b",
					"vel": Vector2(d * 760, 0), "size": Vector2(250, 410), "life": 160, "hits": 5, "interval": 5, "dmg": 50.0,
					"kb": Vector2(620, -150), "kb_last": Vector2(700, -720), "hitstun": 30, "blockstun": 10, "super": true, "dir": d, "cor": cor})
				Game.play("water", 0.7)
		"era_glacial":
			if k == 1:
				for i in 8:
					var x := clampf(position.x + d * (110 + i * 120), 50.0, 1230.0)
					fight.spawn({"kind": "icespike", "owner": self, "pos": Vector2(x, FLOOR_Y), "anchor": "b", "size": Vector2(130, 235),
						"delay": 4 + i * 5, "life": 26, "dmg": 40.0, "freeze": 80, "kb": Vector2(0, 0), "hitstun": 26, "blockstun": 10,
						"super": true, "dir": d, "cor": cor, "sfx": "hit_light"})
				Game.play("ice", 0.8)
			if k == 58 and opp.ice > 0:
				fight.spawn({"kind": "shatter", "owner": self, "pos": opp.position + Vector2(0, -85), "anchor": "c", "size": Vector2(270, 270),
					"life": 6, "dmg": 140.0, "kb": Vector2(420, -860), "hitstun": 30, "blockstun": 14, "super": true, "dir": d, "cor": cor, "unblockable": true})
				Game.play("explode", 1.3)
		"julgamento":
			if k == 1:
				var offs := [-170.0, 130.0, 0.0, -60.0, 210.0, -230.0, 0.0]
				for i in 7:
					var trk: bool = i in [2, 4, 6]
					fight.spawn({"kind": "sunbeam", "owner": self, "pos": Vector2(clampf(ox + (0.0 if trk else offs[i]), 50.0, 1230.0), FLOOR_Y),
						"anchor": "b", "track": trk, "track_lock": 7, "size": Vector2(105, 760), "delay": 16 + i * 8, "life": 12,
						"dmg": 42.0 if i < 6 else 85.0, "kb": Vector2(0, -420), "kb_last": Vector2(200, -900) if i == 6 else Vector2(0, -420),
						"hitstun": 34, "blockstun": 10, "super": true, "dir": d, "cor": cor})
				Game.play("zap", 0.7)
		"terremoto":
			if k == 1:
				vel = Vector2(0, -1050.0)
				on_ground = false
			if not super_flag.has("quake") and k > 4 and on_ground:
				super_flag["quake"] = true
				fight.spawn({"kind": "quake", "owner": self, "pos": Vector2(640, FLOOR_Y), "anchor": "b", "size": Vector2(1300, 70),
					"life": 8, "dmg": 60.0, "kb": Vector2(0, 0), "hitstun": 46, "blockstun": 14, "ground_only": true,
					"super": true, "dir": d if ox >= position.x else -d, "cor": cor})
				Game.play("quake")
				fight.fx.ring(position + Vector2(0, -5), cor, 2.4)
				for i in 5:
					var last := i == 4
					fight.spawn({"kind": "rock", "owner": self, "pos": Vector2(ox, 100.0), "anchor": "c", "track_x": true, "vel": Vector2(0, 500),
						"grav": 2400.0, "size": Vector2(84, 84), "delay": 4 + i * 6, "life": 200, "dmg": 28.0 if not last else 48.0,
						"kb": Vector2(40, 0) if not last else Vector2(220, -720), "hitstun": 30, "blockstun": 12, "on_ground": "die",
						"on_death": "dust", "destroy_on_hit": true, "super": true, "dir": d, "cor": data.cor2, "seed": randf() * 10.0})
		"canhao":
			if k >= 1 and k <= 36 and (k - 1) % 7 == 0:
				var i := (k - 1) / 7
				var last := i == 5
				fight.spawn({"kind": "cannonball", "owner": self, "pos": position + Vector2(d * 95, -100 + (i % 2) * 22), "anchor": "c",
					"vel": Vector2(d * 950, 0), "size": Vector2(58, 58), "life": 120, "dmg": 38.0 if not last else 62.0,
					"kb": Vector2(90, 0) if not last else Vector2(520, -660), "hitstun": 26, "blockstun": 12, "projectile": true,
					"destroy_on_hit": true, "on_death": "pop", "super": true, "dir": d, "cor": cor})
				Game.play("explode", 1.5, -4)
				fight.fx.puff(position + Vector2(d * 110, -100), Color(0.9, 0.9, 0.85, 0.7), 6)
		"meteoros":
			if k == 1:
				var spread := [0.0, -130.0, 150.0, 0.0, -220.0, 230.0, 70.0, 0.0]
				for i in 8:
					var tx := clampf(ox + spread[i], 60.0, 1220.0)
					var y0 := -90.0 - i * 10.0
					var vy0 := 420.0
					var g := 900.0
					var dist := FLOOR_Y - 40.0 - y0
					var tt := (-vy0 + sqrt(vy0 * vy0 + 2.0 * g * dist)) / g
					var sx := tx - d * 320.0
					fight.spawn({"kind": "meteor", "owner": self, "pos": Vector2(sx, y0), "anchor": "c", "vel": Vector2((tx - sx) / tt, vy0),
						"grav": g, "size": Vector2(78, 78), "delay": 4 + i * 7, "life": 240, "dmg": 34.0, "kb": Vector2(160, -420),
						"hitstun": 28, "blockstun": 12, "on_ground": "die", "on_death": "blast", "destroy_on_hit": true,
						"super": true, "dir": d, "cor": cor, "seed": randf() * 10.0})
				Game.play("portal", 0.6)
		"transmutacao":
			if k == 1:
				fight.spawn({"kind": "circle", "owner": self, "pos": Vector2(ox, FLOOR_Y), "anchor": "b", "track": true, "track_lock": 10,
					"size": Vector2(235, 470), "delay": 34, "life": 42, "hits": 6, "interval": 7, "dmg": 36.0, "kb": Vector2(0, -380),
					"kb_last": Vector2(200, -1000), "poison": true, "hitstun": 30, "blockstun": 10, "super": true, "dir": d, "cor": cor})
				Game.play("poison", 0.8)

# ---------------------------------------------------------------- caixas de golpe
func active_hitbox() -> Rect2:
	if state != "attack": return Rect2()
	var m := current_move()
	if m.is_empty() or not m.has("box") or m.box.size == Vector2.ZERO: return Rect2()
	if is_power() and m.get("self", "") == "": return Rect2()
	var su: int = m.startup
	if move_f <= su or move_f > su + m.active: return Rect2()
	if hits_done >= 1: return Rect2()
	if self_tipo() == "portal" and (move_f <= su + 5 or _portal_hit): return Rect2()
	var b: Rect2 = m.box
	var x0 := b.position.x if facing == 1 else -b.position.x - b.size.x
	return Rect2(position + Vector2(x0, b.position.y), b.size)

func hurtbox() -> Rect2:
	if invuln > 0 or state in ["ko", "burst"] or (state == "knockdown" and on_ground): return Rect2()
	return Rect2(position + HURT.position, HURT.size)

# ---------------------------------------------------------------- receber golpe
## Retorna "hit", "block", "perfect", "armor" ou "" (não acertou)
func take_hit(atk: Node2D, m: Dictionary, from_dir: int, scaled := true) -> String:
	if state == "ko": return ""
	var is_super: bool = m.get("super", false)
	var mult: float = atk.dmg_mult * (1.2 if atk.overload_t > 0 else 1.0)
	efetivo = false
	var de_poder: bool = m.get("power", false) or (m.get("melee", true) and atk.is_power())
	if (de_poder or is_super) and Game.super_efetivo(atk.data.tipo, data.tipo):
		mult *= 1.25
		efetivo = true
	var blocking = state in ["block", "blockstun"] and on_ground and not m.get("unblockable", false)
	if blocking and frame - block_press_f <= 8 and not is_super:
		# CONTRA-ATAQUE PERFEITO
		nucleo = min(100.0, nucleo + 20.0)
		if m.get("melee", true):
			atk.stun_attacker(30)
		block_press_f = -99
		return "perfect"
	if blocking:
		var chip: float = m.dmg * mult * (0.2 if is_super else 0.1)
		hp = max(1.0, hp - chip)
		_stun_len = m.blockstun
		_go("blockstun")
		vel.x = from_dir * m.kb.x * 0.6
		nucleo = min(100.0, nucleo + 3.0)
		return "block"
	if armor and not is_super and m.dmg > 0.0:
		# Avalanche: aguenta o golpe sem parar
		armor = false
		hp = max(1.0, hp - m.dmg * mult * def_mult * 0.5)
		flash = 0.8
		return "armor"
	var dscale := 1.0
	if scaled and not is_super: dscale = max(0.3, 1.0 - 0.1 * combo_taken)
	var dmg: float = m.dmg * mult * def_mult * dscale
	hp = max(0.0, hp - dmg)
	combo_taken += 1
	combo_dmg += dmg
	nucleo = min(100.0, nucleo + 4.0)
	flash = 1.0
	shake = 6.0
	armor = false
	if m.get("poison", false): poison_t = 120
	var kb: Vector2 = m.kb
	if not on_ground or kb.y < 0:
		juggle += 1
	if hp <= 0.0 and Game.modo == "treino":
		hp = 1.0
	if hp <= 0.0:
		vel = Vector2(from_dir * 520.0, -700.0)
		on_ground = false
		ice = 0
		_go("ko")
		return "hit"
	if juggle > 6 and not on_ground and not is_super:
		# limite de combo aéreo: cai direto
		vel = Vector2(from_dir * 260.0, 200.0)
		_go("knockdown")
		return "hit"
	if m.get("spike", false) and not on_ground:
		vel = Vector2(from_dir * kb.x, kb.y)
		_go("knockdown")
		return "hit"
	_stun_len = m.hitstun
	var fr: int = m.get("freeze", 0)
	if fr > 0:
		ice = fr
		_stun_len += fr
	if kb.y < 0 or not on_ground:
		vel = Vector2(from_dir * kb.x, kb.y if kb.y < 0 else -320.0)
		if fr > 0 and on_ground: vel = Vector2(from_dir * kb.x * 0.3, 0)
		else: on_ground = false
		_go("hitstun")
	else:
		vel = Vector2(from_dir * kb.x, 0)
		_go("hitstun")
	return "hit"

func stun_attacker(f: int) -> void:
	_stun_len = f
	vel.x = -facing * 200.0
	flash = 0.6
	armor = false
	_go("hitstun")

func _hitstun() -> void:
	if _combo_overload() and nucleo >= 50.0 and ice <= 0:
		_consume("heavy"); _consume("special")
		_start_burst()
		return
	if ice > 0:
		vel.x = move_toward(vel.x, 0, 30.0)
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
	if state == "burst" and not on_ground: g = GRAVITY * 0.3
	if state == "hitstun" and not on_ground: g = GRAVITY * (0.85 if ice <= 0 else 1.1)
	if in_super_cinematic(): g = 0.0
	if state == "attack" and self_tipo() == "portal" and move_f <= int(current_move().get("startup", 14)) + 5: g = 0.0
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
					if fight: fight.fx.puff(position, Color(0.8, 0.8, 0.8, 0.5), 6)
				elif st >= _stun_len:
					_go("idle")
			elif state == "ko":
				vel.x *= 0.4
				Game.play("hit_heavy", 0.5, -4)
				if fight: fight.fx.puff(position, Color(0.8, 0.8, 0.8, 0.5), 10)
	position.x = clampf(position.x, LEFT_WALL, RIGHT_WALL)

# ---------------------------------------------------------------- visual
var spr_squash := 0.0
var t_anim := 0.0

## Pose dos braços: [giro frente, x frente, y frente, giro trás, x trás, y trás]  (giro em radianos; x/y em pixels da arte)
const P_NEUTRO := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
const P_SOCO := [-1.15, 70.0, -35.0, 0.25, 0.0, 0.0]
const P_SOCO_PREP := [0.35, -20.0, 0.0, 0.2, 0.0, 0.0]
const P_GANCHO := [0.4, -10.0, 0.0, -1.35, 215.0, -45.0]
const P_GANCHO_PREP := [0.3, -10.0, 0.0, 0.75, -30.0, 0.0]
const P_UPPER := [-2.55, 40.0, -60.0, 0.4, 0.0, 0.0]
const P_UPPER_PREP := [0.6, -10.0, 20.0, 0.3, 0.0, 0.0]
const P_AR_SOCO := [-0.75, 70.0, 0.0, 0.3, 0.0, 0.0]
const P_MARTELO_PREP := [-2.4, 0.0, -50.0, 2.2, 0.0, -50.0]
const P_MARTELO := [-0.3, 60.0, 40.0, -0.6, 150.0, 40.0]
const P_EMPURRA_PREP := [0.5, -30.0, 0.0, 0.5, -20.0, 0.0]
const P_EMPURRA := [-1.35, 60.0, -30.0, -1.15, 195.0, -30.0]
const P_CHAO_PREP := [-2.2, 0.0, -40.0, 2.2, 0.0, -40.0]
const P_CHAO := [-0.2, 40.0, 40.0, 0.2, -40.0, 40.0]
const P_ARREMESSO_PREP := [-2.9, -20.0, -40.0, 0.3, 0.0, 0.0]
const P_ARREMESSO := [-1.0, 60.0, -40.0, 0.3, 0.0, 0.0]
const P_INVESTIDA := [-1.45, 50.0, -20.0, 0.9, -20.0, 0.0]
const P_ABERTO := [-1.0, 0.0, -20.0, 1.0, 0.0, -20.0]
const P_CARGA := [-2.2, 0.0, -30.0, 2.2, 0.0, -30.0]
const P_CEU := [-2.9, 10.0, -60.0, 2.9, -10.0, -60.0]
const P_DEFESA := [-1.55, 25.0, -55.0, -1.25, 175.0, -55.0]
const P_APANHA := [-0.8, 0.0, 0.0, 0.8, 0.0, 0.0]
const P_CAIDO := [-0.3, 0.0, 0.0, 0.3, 0.0, 0.0]
const P_PULO := [-0.5, 0.0, -10.0, 0.5, 0.0, -10.0]
const P_DASH := [0.6, -10.0, 0.0, 0.9, -10.0, 0.0]

func _lerp_pose(a: Array, b: Array, k: float) -> Array:
	var r := []
	for i in 6:
		r.append(lerpf(a[i], b[i], k))
	return r

## Calcula a pose dos braços para o estado atual. Retorna [pose, braço de trás na frente do corpo?, suavização]
func _target_pose() -> Array:
	var t := t_anim
	match state:
		"idle", "intro":
			var s := sin(t * 3.0)
			return [[0.07 * sin(t * 3.0 - 0.6), 0.0, 4.0 * s, -0.07 * sin(t * 3.0 - 0.6), 0.0, 4.0 * s], false, 0.2]
		"walk":
			var s2 := sin(t * 9.0)
			return [[0.3 * s2, 0.0, 0.0, -0.3 * s2, 0.0, 0.0], false, 0.3]
		"jump":
			return [P_PULO, false, 0.25]
		"dash":
			return [P_DASH, false, 0.4]
		"block", "blockstun":
			return [P_DEFESA, true, 0.5]
		"hitstun":
			var j := randf_range(-0.15, 0.15) if shake > 0.0 else 0.0
			return [[P_APANHA[0] + j, 0.0, 0.0, P_APANHA[3] - j, 0.0, 0.0], false, 0.5]
		"knockdown", "ko":
			return [P_CAIDO, false, 0.3]
		"burst":
			return [P_CEU, false, 0.5]
		"win":
			var w := 0.25 * sin(t * 8.0)
			return [[-2.7 + w, 0.0, -40.0, 2.7 - w, 0.0, -40.0], false, 0.3]
		"attack":
			return _attack_pose()
	return [P_NEUTRO, false, 0.2]

func _attack_pose() -> Array:
	var m := current_move()
	var su: int = m.startup
	var ac: int = m.active
	var rec: int = m.recovery
	var prep: Array = P_SOCO_PREP
	var hit: Array = P_SOCO
	var front := false
	var tipo := self_tipo()
	match move:
		"light": prep = P_SOCO_PREP; hit = P_SOCO
		"heavy": prep = P_GANCHO_PREP; hit = P_GANCHO; front = true
		"launcher": prep = P_UPPER_PREP; hit = P_UPPER
		"air_light": prep = P_SOCO_PREP; hit = P_AR_SOCO
		"air_heavy": prep = P_MARTELO_PREP; hit = P_MARTELO; front = true
		_:
			if is_power():
				match tipo:
					"rise": prep = P_UPPER_PREP; hit = P_UPPER
					"rush": prep = P_EMPURRA_PREP; hit = P_INVESTIDA
					"tp": prep = P_GANCHO_PREP; hit = P_GANCHO; front = true
					"portal": prep = P_CARGA; hit = P_MARTELO; front = true
					_:
						match slot:
							2: prep = P_CHAO_PREP; hit = P_CEU
							3: prep = P_CHAO_PREP; hit = P_CHAO
							_:
								if move in ["pedra", "frasco", "semente"]:
									prep = P_ARREMESSO_PREP; hit = P_ARREMESSO
								elif move in ["clarao", "aneis"]:
									prep = P_CARGA; hit = P_ABERTO
								else:
									prep = P_EMPURRA_PREP; hit = P_EMPURRA; front = true
		"supremo":
			if move_f <= su:
				var tremor := sin(t_anim * 50.0) * 0.08
				var p: Array = P_CARGA.duplicate()
				p[0] += tremor
				p[3] -= tremor
				return [p, false, 0.3]
			match data.supremo:
				"erupcao", "furia", "era_glacial", "terremoto": return [P_CHAO, false, 0.4]
				"julgamento", "meteoros": return [P_CEU, false, 0.3]
				"canhao":
					var k := (move_f - su - 1) % 7
					return [P_EMPURRA if k < 3 else P_EMPURRA_PREP, true, 0.6]
				_: return [P_EMPURRA, true, 0.4]
	if move_f <= su:
		return [_lerp_pose(P_NEUTRO, prep, clampf(float(move_f) / maxf(1.0, su - 1), 0.0, 1.0)), false, 1.0]
	if move_f <= su + ac + 2:
		return [hit, front, 1.0]
	var r := clampf(float(move_f - su - ac - 2) / maxf(1.0, rec), 0.0, 1.0)
	return [_lerp_pose(hit, P_NEUTRO, r * r), front and r < 0.5, 1.0]

func _animate() -> void:
	t_anim += 1.0 / 60.0
	spr_squash = max(0.0, spr_squash - 0.08)
	var off := Vector2.ZERO
	var rot := 0.0
	var sc := Vector2.ONE
	var alpha := alpha_mul
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
			alpha *= 0.85
		"block", "blockstun":
			rot = -0.1
			sc = Vector2(0.95, 1.0)
		"burst":
			sc = Vector2.ONE * (1.0 + 0.1 * sin(st * 0.8))
		"attack":
			var m := current_move()
			var su: int = m.startup
			if move_f <= su:
				rot = -0.12
				off.x = -6.0
				if move == "supremo":
					off.y = -20.0 * minf(1.0, float(move_f) / 12.0)
					sc = Vector2.ONE * (1.0 + 0.12 * minf(1.0, float(move_f) / 12.0))
					rot = -0.05
			elif move_f <= su + m.active:
				rot = 0.18
				off.x = m.get("lunge", 0.0)
				var tp2 := self_tipo()
				if move == "launcher" or tp2 == "rise": rot = -0.3
				if tp2 == "rush": rot = 0.3; sc = Vector2(1.12, 0.92)
				if tp2 == "portal": rot = 0.5
				if move == "supremo": off.y = -12.0; sc = Vector2.ONE * 1.08; rot = 0.05
			else:
				rot = 0.05
		"hitstun":
			rot = -0.2
			off.x = randf_range(-shake, shake)
			if ice > 0: off.x = 0.0; rot = -0.08
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
	var base := BODY_H / rig_h
	rig.position = Vector2(off.x * facing, off.y)
	rig.rotation = rot * facing
	rig.scale = Vector2(base * sc.x * (1 if facing == 1 else -1), base * sc.y)
	# braços
	var tp: Array = _target_pose()
	var target: Array = tp[0]
	var k: float = tp[2]
	if ice > 0 and state == "hitstun":
		k = 0.0
	for i in 6:
		pose[i] = lerpf(pose[i], target[i], k)
	arm_back_front = tp[1]
	arm_front.rotation = pose[0]
	arm_front.position = arm_front.get_meta("base") + Vector2(pose[1], pose[2])
	arm_back.rotation = pose[3]
	arm_back.position = arm_back.get_meta("base") + Vector2(pose[4], pose[5])
	arm_back.z_index = 2 if arm_back_front else 0
	# rastro do punho durante o golpe
	if state == "attack" and move != "supremo":
		var m2 := current_move()
		var su2: int = m2.startup
		if move_f > su2 and move_f <= su2 + m2.active + 2:
			var hand_arm: Node2D = arm_back if arm_back_front else arm_front
			var hl: Vector2 = hand_back if arm_back_front else hand_front
			fist_trail.append(hand_arm.global_transform * hl)
			if fist_trail.size() > 6: fist_trail.pop_front()
		elif fist_trail.size() > 0:
			fist_trail.pop_front()
	elif fist_trail.size() > 0:
		fist_trail.pop_front()
	# shader: brilho ao apanhar, gelo, veneno, transparência
	mat.set_shader_parameter("flash", flash)
	mat.set_shader_parameter("alpha", alpha)
	if ice > 0:
		mat.set_shader_parameter("tint", Color(0.6, 0.85, 1.0))
		mat.set_shader_parameter("tint_amt", 0.55)
	elif poison_t > 0:
		mat.set_shader_parameter("tint", Color(0.6, 1.0, 0.4))
		mat.set_shader_parameter("tint_amt", 0.25 + 0.15 * sin(t_anim * 10.0))
	elif alt:
		mat.set_shader_parameter("tint", alt_cor)
		mat.set_shader_parameter("tint_amt", 0.4)
	else:
		mat.set_shader_parameter("tint_amt", 0.0)
	queue_redraw()

func fist_pos() -> Vector2:
	return arm_front.global_transform * hand_front

func _draw() -> void:
	# sombra no chão
	var h := FLOOR_Y - position.y
	var w := 60.0 * clampf(1.0 - h / 500.0, 0.4, 1.0)
	draw_set_transform(Vector2(0, h + 2), 0, Vector2(1, 0.22))
	draw_circle(Vector2.ZERO, w, Color(0, 0, 0, 0.35 * alpha_mul))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var cor: Color = data.cor
	if eco: cor = Color("ff3a8a")
	# aura da Sobrecarga (atrás do corpo)
	if overload_t > 0 and state != "ko":
		for i in 5:
			var a := t_anim * 6.0 + i * TAU / 5.0
			var r := 85.0 + 10.0 * sin(t_anim * 9.0 + i)
			var p := Vector2(cos(a) * r * 0.75, -85 + sin(a) * r)
			draw_circle(p, 16.0 + 6.0 * sin(t_anim * 12.0 + i), Color(cor, 0.25))
		draw_arc(Vector2(0, -85), 100 + 6 * sin(t_anim * 10.0), 0, TAU, 40, Color(cor.lightened(0.4), 0.55), 4)
	# escudo de defesa
	if state in ["block", "blockstun"]:
		var c := Vector2(facing * 60, -80)
		var pts := PackedVector2Array()
		for i in 7:
			var a2 := -PI / 2 + i * TAU / 6
			pts.append(c + Vector2(cos(a2) * 34, sin(a2) * 74))
		draw_colored_polygon(pts, Color(cor, 0.22 if state == "block" else 0.45))
		draw_polyline(pts, Color(cor.lightened(0.4), 0.9), 3)
	# aura do Núcleo cheio
	if nucleo >= 100.0 and state != "ko":
		var pp := 0.5 + 0.5 * sin(t_anim * 8.0)
		draw_arc(Vector2(0, -85), 96 + pp * 6, 0, TAU, 40, Color(cor, 0.35 + 0.25 * pp), 3)
	# carga do supremo
	if in_super_cinematic():
		var k2: float = float(move_f) / SUPER_STARTUP
		for i in 3:
			draw_arc(Vector2(0, -95), 160.0 * (1.0 - k2) + i * 22, 0, TAU, 40, Color(cor, 0.7 * k2), 4)
