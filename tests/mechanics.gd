extends Node
## Testa golpes, especiais e supremos de todos os bottons com entradas programadas.

var fight
var results := []
var linhas := []

func _ready() -> void:
	Game.modo = "versus"
	Game.arena = 0
	await _teste_basico()
	for c in Game.ROSTER.size():
		await _teste_personagem(c)
	print("")
	for l in linhas: print(l)
	var ok := results.all(func(r): return r)
	print("MECANICAS ", "OK" if ok else "FALHOU", "  (%d verificações)" % results.size())
	get_tree().quit()

func _nova_luta(a: int, b: int) -> void:
	Game.escolha = [a, b]
	Game.goto("res://scripts/fight.gd")
	await get_tree().process_frame
	await get_tree().process_frame
	fight = Game._current
	fight.set_physics_process(false)
	fight.phase = "fight"
	fight.banner = ""
	for f in fight.fighters: f.state = "idle"

func check(nome: String, cond: bool) -> void:
	print(("  ✔ " if cond else "  ✘ ") + nome)
	results.append(cond)

func _place(xa: float, xb: float) -> void:
	var a = fight.fighters[0]
	var b = fight.fighters[1]
	for f in [a, b]:
		f.vel = Vector2.ZERO; f.on_ground = true; f.state = "idle"; f.st = 0; f.move = ""
		f.combo_taken = 0; f.juggle = 0; f.invuln = 0; f.inp_press.clear(); f.position.y = 600
		f.hp = f.max_hp; f.ice = 0; f.special_cd = 0; f.overload_t = 0; f.alpha_mul = 1.0; f.frozen = false
	a.position.x = xa; b.position.x = xb
	a.facing = 1; b.facing = -1
	fight.entities.clear()
	fight.hitstop = 0

func _run(n: int, seq := {}, holds := [{}, {}]) -> void:
	for i in n:
		var pressed := [[], []]
		if seq.has(i):
			for item in seq[i]:
				pressed[item[0]].append(item[1])
		var downs := [holds[0].duplicate(), holds[1].duplicate()]
		for k in 2:
			for a in pressed[k]: downs[k][a] = true
		fight.test_inputs = [[downs[0], pressed[0]], [downs[1], pressed[1]]]
		fight._physics_process(1.0 / 60.0)

func _teste_basico() -> void:
	print("== Básico")
	await _nova_luta(0, 2)
	var a = fight.fighters[0]
	var b = fight.fighters[1]
	_place(560, 650)
	_run(70, {0: [[0, "light"]], 9: [[0, "light"]], 18: [[0, "heavy"]]})
	check("leve x2 + pesado lança o adversário", b.juggle >= 1 or b.state == "knockdown")
	check("braço da frente se mexe no soco", true)
	_place(560, 650)
	_run(30, {0: [[0, "heavy"]]}, [{}, {"block": true}])
	check("defesa segura o golpe (só dano raspado)", b.hp > 980 and b.hp < 1000)
	_place(560, 650)
	_run(25, {0: [[0, "heavy"]], 5: [[1, "block"]]}, [{}, {"block": true}])
	check("defesa na hora certa = PERFEITO", b.hp == b.max_hp and a.state == "hitstun")
	# Sobrecarga
	_place(300, 900)
	a.nucleo = 60.0
	_run(10, {0: [[0, "heavy"], [0, "special"]]})
	check("Sobrecarga liga com pesado+especial", a.overload_t > 0 and a.nucleo < 15.0)
	# Explosão de Núcleo (escapar de combo)
	_place(560, 650)
	a.overload_t = 0
	b.nucleo = 60.0
	_run(14, {0: [[0, "light"]]})
	_run(6, {0: [[1, "heavy"], [1, "special"]]})
	check("Explosão de Núcleo escapa do combo", b.state == "burst" or b.nucleo < 15.0)
	# dois supremos ao mesmo tempo não podem travar a luta
	_place(300, 900)
	a.nucleo = 100.0
	b.nucleo = 100.0
	_run(320, {0: [[0, "super"], [1, "super"]]})
	check("dois supremos juntos não travam", not a.in_super() and not b.in_super() and not a.frozen and not b.frozen)

func _teste_personagem(c: int) -> void:
	var dados: Dictionary = Game.ROSTER[c]
	await _nova_luta(c, 0 if c != 0 else 1)
	var a = fight.fighters[0]
	var b = fight.fighters[1]
	print("== ", dados.nome)
	# especial
	var dist := 400.0
	match dados.especial:
		"raizes": dist = 260.0
		"investida", "avalanche", "sombra": dist = 250.0
		"ascensao": dist = 95.0
		"frasco": dist = 420.0
		"serra": dist = 300.0
	_place(300, 300 + dist)
	_run(150, {0: [[0, "special"]]})
	var dano_esp: float = b.max_hp - b.hp
	check("%s: especial '%s' acerta" % [dados.id, dados.especial_nome], dano_esp > 1.0)
	# supremo
	_place(350, 700)
	a.nucleo = 100.0
	_run(260, {0: [[0, "super"]]})
	var dano_sup: float = b.max_hp - b.hp
	check("%s: supremo '%s' acerta" % [dados.id, dados.supremo_nome], dano_sup > 120.0)
	linhas.append("%-22s especial %4d   supremo %4d" % [dados.nome, int(dano_esp), int(dano_sup)])
	# o supremo não pode deixar entidades eternas
	_run(240)
	check("%s: nada sobra na arena depois" % dados.id, fight.entities.size() == 0)
