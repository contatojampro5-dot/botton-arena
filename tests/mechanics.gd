extends Node
## Testa os golpes com entradas programadas (sem CPU).

var fight
var results := []

func _ready() -> void:
	Game.modo = "versus"
	Game.escolha = [0, 2]
	Game.goto("res://scripts/fight.gd")
	await get_tree().create_timer(0.3).timeout
	fight = Game._current
	fight.set_physics_process(false)  # nós avançamos os quadros manualmente
	fight.phase = "fight"
	for f in fight.fighters: f.state = "idle"
	var a = fight.fighters[0]
	var b = fight.fighters[1]
	# 1) combo leve-leve-pesado vira lançador
	_place(a, b, 560, 650)
	_seq(a, [["light", 0], ["light", 9], ["heavy", 9]], 60)
	check("leve x2 + pesado lança o adversário", b.juggle >= 1 or b.state == "knockdown")
	check("dano do combo aplicado", b.hp < 1000)
	print("   hp após combo: %.0f, golpes: %d" % [b.hp, b.combo_taken])
	_wait(120)
	# 2) defesa
	_place(a, b, 560, 650)
	b.hp = 1000
	_hold(b, "block", 10)
	_seq(a, [["heavy", 0]], 25, b, "block")
	check("defesa segura o golpe (só dano raspado)", b.hp > 980 and b.hp < 1000)
	_wait(40)
	# 3) contra-ataque perfeito
	_place(a, b, 560, 650)
	b.hp = 1000
	_seq(a, [["heavy", 0]], 1)
	var f0 = Game.ROSTER  # placeholder
	_seq(b, [["block", 5]], 20, b, "block")
	check("defesa no momento certo = PERFEITO (sem dano, atacante atordoado)", b.hp == 1000 and a.state == "hitstun")
	_wait(60)
	# 4) especiais de cada tipo
	for tipo in ["orbe", "investida", "ascensao", "sombra"]:
		var ix := -1
		for i in Game.ROSTER.size():
			if Game.ROSTER[i].especial == tipo: ix = i; break
		a.data = Game.ROSTER[ix]
		_place(a, b, 400 if tipo != "ascensao" else 590, 660)
		b.hp = 1000
		a.special_cd = 0
		_seq(a, [["special", 0]], 90)
		check("especial '%s' acerta" % tipo, b.hp < 1000)
		_wait(80)
	# 5) supremo
	a.data = Game.ROSTER[1]
	_place(a, b, 300, 900)
	b.hp = 1000
	a.nucleo = 100
	_seq(a, [["super", 0]], 120)
	check("supremo acerta à distância", b.hp < 800)
	print("   dano do supremo: %.0f" % (1000 - b.hp))
	# 6) dash e pulo
	_place(a, b, 300, 900)
	var x0: float = a.position.x
	_seq(a, [["dash", 0]], 20)
	check("dash anda pra frente", a.position.x - x0 > 80)
	_seq(a, [["up", 0]], 10)
	check("pulo sai do chão", not a.on_ground)
	_wait(60)
	var ok := results.all(func(r): return r)
	print("MECANICAS ", "OK" if ok else "FALHOU")
	get_tree().quit()

func check(nome: String, cond: bool) -> void:
	print(("  ✔ " if cond else "  ✘ ") + nome)
	results.append(cond)

func _place(a, b, xa, xb) -> void:
	for f in [a, b]:
		f.vel = Vector2.ZERO; f.on_ground = true; f.state = "idle"; f.st = 0
		f.combo_taken = 0; f.juggle = 0; f.invuln = 0; f.inp_press.clear(); f.position.y = 600
	a.position.x = xa; b.position.x = xb
	a.facing = 1; b.facing = -1
	fight.projectiles.clear()

func _tick(downs := [{}, {}], presses := [[], []]) -> void:
	for i in 2:
		fight.fighters[i].set_input(downs[i], presses[i])
	if fight.hitstop > 0:
		fight.hitstop -= 1
		return
	for f in fight.fighters: f.step()
	fight._push_apart()
	fight._check_hits()
	fight._update_projectiles()

func _wait(n: int) -> void:
	for i in n: _tick()

func _hold(f, act: String, n: int) -> void:
	for i in n:
		var d := [{}, {}]; d[f.idx][act] = true
		_tick(d)

## seq: [[ação, quadros de espera antes]], total de quadros; opcionalmente segura uma ação em outro lutador
func _seq(f, seq: Array, total: int, hold_f = null, hold_act := "") -> void:
	var timeline := {}
	var acc := 0
	for s in seq:
		acc += s[1]
		timeline[acc] = s[0]
	for i in total:
		var d := [{}, {}]
		var p := [[], []]
		if timeline.has(i):
			p[f.idx].append(timeline[i])
			d[f.idx][timeline[i]] = true
		if hold_f != null: d[hold_f.idx][hold_act] = true
		_tick(d, p)
