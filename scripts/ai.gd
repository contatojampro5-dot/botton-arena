extends RefCounted
## CPU: decide o que o botton faz a cada quadro. nivel 0 = fácil, 1 = normal, 2 = difícil.
## Usa os 4 poderes: neutro de longe, frente de média distância, cima contra pulos, baixo para armar o chão.

var nivel := 1
var plan := ""
var hold := 0
var t := 0
var combo_step := 0
var poder_slot := 0

const BLOCK_CH := [0.12, 0.35, 0.6]      # chance de defender quando atacado de perto
const THINK := [16, 10, 6]               # de quantos em quantos quadros muda de plano
const DODGE_CH := [0.15, 0.45, 0.75]     # chance de reagir a projéteis
const POWER_CH := [0.24, 0.4, 0.55]      # vontade de usar poderes
const WAVE_KINDS := ["wave", "vine", "tornado", "quake", "firepillar", "icespike", "shock", "embers", "gust"]
# poderes do slot "frente" que são de chegar perto (o resto é de média distância)
const FRENTE_PERTO := ["investida", "sombra", "avalanche", "portal", "rajada_glacial", "vapor"]

func think(f: Node2D, o: Node2D, fight: Node) -> Array:
	var down := {}
	var pressed := []
	t += 1
	var dx: float = o.position.x - f.position.x
	var dist: float = absf(dx)
	var toward := "right" if dx > 0 else "left"
	var away := "left" if dx > 0 else "right"
	var lv := clampi(nivel, 0, 2)

	# escapar de combo com a Explosão de Núcleo
	if f.state == "hitstun" and f.nucleo >= 50.0 and f.combo_taken >= 3 and f.ice <= 0 and randf() < [0.0, 0.04, 0.1][lv]:
		pressed.append("heavy"); pressed.append("special")
		return [down, pressed]
	if f.state in ["hitstun", "knockdown", "ko", "burst"]:
		plan = ""
		hold = 0
		return [down, pressed]

	# ameaças: projéteis e golpes vindo na direção da CPU
	if hold <= 0 or plan in ["walk", "back", "wait"]:
		for e in fight.entities:
			if e.owner == f or e.get("visual_only", false) or e.get("trap", false): continue
			if e.t < e.delay - 10: continue
			var ex: float = e.pos.x
			var vx: float = e.vel.x
			var vem: bool = (vx > 0 and ex < f.position.x) or (vx < 0 and ex > f.position.x) or absf(vx) < 1.0
			if vem and absf(ex - f.position.x) < 280.0 and randf() < DODGE_CH[lv] * 0.25:
				if e.kind in WAVE_KINDS and f.on_ground:
					plan = "jumpaway"; hold = 24
				elif f.on_ground:
					plan = "block"; hold = 22
				break

	if hold > 0:
		hold -= 1
	else:
		var r := randf()
		plan = "wait"
		hold = THINK[lv]
		var opp_hurt = o.hurtbox().size != Vector2.ZERO
		var poder := _escolher_poder(f, o, dist, lv)
		if o.is_attacking() and dist < 220 and r < BLOCK_CH[lv] and f.on_ground:
			plan = "block"; hold = 16 + lv * 4
		elif f.nucleo >= 100.0 and opp_hurt and o.on_ground and r < [0.15, 0.3, 0.45][lv]:
			plan = "super"; hold = 2
		elif f.nucleo >= 50.0 and f.nucleo < 100.0 and f.overload_t <= 0 and dist < 320 and lv >= 1 and r < 0.04:
			plan = "overload"; hold = 3
		elif poder >= 0 and randf() < POWER_CH[lv] * (1.6 if dist > 330 else 1.0):
			plan = "power"; poder_slot = poder; hold = 4
		elif o.is_down():
			plan = "walk" if dist > 200 else "wait"; hold = 12
		elif dist > 330:
			if r < 0.25:
				plan = "jumpin"; hold = 30
			elif r < 0.38:
				plan = "dash"; hold = 10
			else:
				plan = "walk"; hold = 12 + randi() % 8
		elif dist > 125:
			if r < 0.5: plan = "walk"; hold = 10
			elif r < 0.62: plan = "back"; hold = 12
			elif r < 0.8: plan = "jumpin"; hold = 26
			else: plan = "wait"; hold = 10
		else:
			if r < 0.55 + lv * 0.1:
				plan = "combo"; hold = 34; combo_step = 0
			elif r < 0.7: plan = "heavy"; hold = 22
			elif r < 0.9: plan = "block"; hold = 16
			else: plan = "back"; hold = 12
		if f.eco and plan == "wait" and randf() < 0.5:
			plan = "walk"

	match plan:
		"block":
			down["block"] = true
		"walk":
			down[toward] = true
		"back":
			down[away] = true
		"wait":
			pass
		"dash":
			if hold == 9: pressed.append("dash")
			down[toward] = true
		"jumpaway":
			if hold == 23: pressed.append("up")
			down[away] = true
		"jumpin":
			down[toward] = true
			if hold == 29 or hold == 25: pressed.append("up")
			if not f.on_ground and dist < 150 and t % 6 == 0: pressed.append("light" if randf() < 0.6 else "heavy")
		"combo":
			# leve, leve, pesado (lança) e, no ar, poder/supremo quando dá
			if t % 6 == 0:
				combo_step += 1
				if combo_step <= 2: pressed.append("light")
				elif combo_step == 3: pressed.append("heavy")
				elif combo_step == 4 and lv >= 1 and f.cds[0] <= 0:
					pressed.append("special")
				elif combo_step == 4 and f.nucleo >= 100.0 and lv == 2:
					pressed.append("super")
		"heavy":
			if hold == 21: pressed.append("heavy")
		"power":
			match poder_slot:
				1: down[toward] = true
				2: down["up"] = true
				3: down["down"] = true
			if hold >= 2:
				pressed.append("special")
				if poder_slot == 2: pressed.append("up")
				hold = 1
		"super":
			pressed.append("super")
		"overload":
			pressed.append("heavy")
			pressed.append("special")
			plan = "wait"
	return [down, pressed]

## escolhe o melhor poder pronto para a situação (-1 se nenhum)
func _escolher_poder(f: Node2D, o: Node2D, dist: float, lv: int) -> int:
	var cds: Array = f.cds
	var frente: String = f.data.poderes[1]
	var op := []
	if o.is_airborne() and dist < 260 and cds[2] <= 0:
		op.append(2)
	if dist > 300 and cds[0] <= 0:
		op.append(0)
		op.append(0)
	elif dist > 190 and cds[0] <= 0:
		op.append(0)
	if cds[1] <= 0:
		if frente in FRENTE_PERTO:
			if dist > 160 and dist < 420: op.append(1)
		elif dist > 200:
			op.append(1)
	if cds[3] <= 0 and dist > 220 and (lv >= 1 or randf() < 0.5):
		op.append(3)
	if dist < 300 and cds[2] <= 0 and o.is_airborne():
		op.append(2)
	if op.is_empty():
		return -1
	return op[randi() % op.size()]
