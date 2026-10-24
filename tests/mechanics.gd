extends Node
## Testa golpes, os 4 poderes, tipos, armadilhas e supremos de todos os bottons com entradas programadas.

var fight
var results := []
var linhas := []
var falhas := []

# distância até o rival para cada poder acertar (padrão: 400)
const DIST := {
	"propulsor": 70.0, "rajada_asc": 70.0, "ascensao": 70.0, "martelo": 70.0,
	"investida": 250.0, "avalanche": 250.0, "serra": 300.0, "pedra": 430.0, "frasco": 420.0, "semente": 380.0,
	"coluna_fogo": 170.0, "broto": 120.0, "pico": 150.0, "pilar": 150.0, "geiser_acido": 170.0,
	"rajada_glacial": 150.0, "vapor": 140.0, "clarao": 110.0, "aneis": 100.0, "raizes": 260.0,
	"pisao": 300.0, "corrente": 300.0, "bolhas": 300.0, "brasas": 220.0, "poco": 190.0, "mina": 130.0,
	"chao_gelo": 170.0, "runa": 180.0, "buraco_negro": 260.0,
}
# quantos quadros esperar
const QUADROS := {"bolhas": 220, "torreta": 160, "buraco_negro": 160, "poco": 140, "brasas": 110, "mina": 90,
	"chao_gelo": 90, "runa": 90, "semente": 120, "frasco": 130, "corrente": 110, "tornado": 130}

func _ready() -> void:
	Game.modo = "versus"
	Game.arena = 0
	await _teste_basico()
	await _teste_tipos()
	for c in Game.ROSTER.size():
		await _teste_personagem(c)
	print("")
	for l in linhas: print(l)
	var ok := results.all(func(r): return r)
	if not ok:
		print("FALHAS:")
		for f in falhas: print("  ", f)
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
	if not cond: falhas.append(nome)

func _place(xa: float, xb: float) -> void:
	var a = fight.fighters[0]
	var b = fight.fighters[1]
	for f in [a, b]:
		f.vel = Vector2.ZERO; f.on_ground = true; f._go("idle"); f.move = ""; f.slot = -1
		f.combo_taken = 0; f.juggle = 0; f.invuln = 0; f.inp_press.clear(); f.last_press.clear(); f.position.y = 600
		f.hp = f.max_hp; f.hp_shown = f.max_hp; f.ice = 0; f.cds = [0, 0, 0, 0]; f.overload_t = 0; f.alpha_mul = 1.0
		f.frozen = false; f.slow_t = 0; f.poison_t = 0; f.armor = false; f.efetivo = false; f.nucleo = 0.0
	a.position.x = xa; b.position.x = xb
	a.facing = 1 if xb >= xa else -1
	b.facing = -a.facing
	fight.entities.clear()
	fight.hitstop = 0
	fight.cutin = {}

## n quadros; seq = {quadro: [[jogador, ação], ...]}; holds = teclas seguradas; hold_n = por quantos quadros segurar (-1 = sempre)
func _run(n: int, seq := {}, holds := [{}, {}], hold_n := -1) -> void:
	for i in n:
		var pressed := [[], []]
		if seq.has(i):
			for item in seq[i]:
				pressed[item[0]].append(item[1])
		var downs := [{}, {}]
		if hold_n < 0 or i < hold_n:
			downs = [holds[0].duplicate(), holds[1].duplicate()]
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
	# direção escolhe o poder
	_place(300, 700)
	_run(2, {0: [[0, "special"]]}, [{"right": true}, {}], 1)
	check("frente + especial = poder da frente", a.slot == 1 and a.move == a.data.poderes[1])
	_place(300, 700)
	_run(2, {0: [[0, "special"]]}, [{"down": true}, {}], 1)
	check("baixo + especial = poder de baixo", a.slot == 3 and a.move == a.data.poderes[3])
	_place(300, 700)
	_run(2, {0: [[0, "special"]]}, [{"up": true}, {}], 1)
	check("cima + especial = poder de cima", a.slot == 2 and a.move == a.data.poderes[2])
	_place(300, 700)
	_run(4, {0: [[0, "up"]], 2: [[0, "special"]]}, [{"up": true}, {}], 1)
	check("cima e logo depois especial também sai o poder de cima (sem pular antes)", a.slot == 2 and a.move == a.data.poderes[2])
	_place(300, 700)
	_run(2, {0: [[0, "special"]]})
	check("especial sozinho = poder neutro", a.slot == 0 and a.move == a.data.poderes[0])
	var cd0: int = a.cds[0]
	check("poder entra em recarga", cd0 > 0)
	_run(34)
	_run(2, {0: [[0, "special"]]})
	check("em recarga o mesmo poder não sai de novo", a.cds[0] > 0 and a.state != "attack")
	# poder lento (Poço Sombrio) e veneno
	await _nova_luta(2, 0)
	a = fight.fighters[0]
	b = fight.fighters[1]
	_place(300, 490)
	_run(40, {0: [[0, "special"]]}, [{"down": true}, {}], 1)
	check("Poço Sombrio deixa o rival lento", b.slow_t > 0)

func _teste_tipos() -> void:
	print("== Tipos")
	check("Fogo é forte contra Planta", Game.super_efetivo("fogo", "planta"))
	check("Água é forte contra Fogo", Game.super_efetivo("agua", "fogo"))
	check("Fogo não é forte contra Água", not Game.super_efetivo("fogo", "agua"))
	# todo tipo é forte contra 2 e fraco contra pelo menos 1
	var ok_tipos := true
	for k in Game.TIPOS.keys():
		if Game.TIPOS[k].forte.size() != 2 or Game.fraquezas(k).size() < 1:
			ok_tipos = false
	check("todo tipo tem 2 vantagens e alguma fraqueza", ok_tipos)
	# Guardião das Chamas (fogo) x Guardião da Floresta (planta): bola de fogo é super efetiva
	await _nova_luta(1, 3)
	var a = fight.fighters[0]
	var b = fight.fighters[1]
	_place(300, 700)
	_run(80, {0: [[0, "special"]]})
	var dano_efetivo: float = b.max_hp - b.hp
	var flag: bool = b.efetivo
	check("bola de fogo na Floresta é SUPER EFETIVA", flag and dano_efetivo > 1.0)
	# contra o Núcleo das Marés (água) não é
	await _nova_luta(1, 5)
	a = fight.fighters[0]
	b = fight.fighters[1]
	_place(300, 700)
	_run(80, {0: [[0, "special"]]})
	check("bola de fogo nas Marés não é super efetiva", not b.efetivo and b.hp < b.max_hp)
	# investida (poder do corpo) também conta o tipo
	await _nova_luta(1, 3)
	a = fight.fighters[0]
	b = fight.fighters[1]
	_place(300, 550)
	_run(60, {0: [[0, "special"]]}, [{"right": true}, {}], 1)
	check("Investida Ígnea (poder do corpo) também é super efetiva", b.efetivo and b.hp < b.max_hp)
	linhas.append("Bola de fogo na Floresta: %d de dano (super efetivo)" % int(dano_efetivo))

func _teste_personagem(c: int) -> void:
	var dados: Dictionary = Game.ROSTER[c]
	var rival := 0 if c != 0 else 1
	await _nova_luta(c, rival)
	var a = fight.fighters[0]
	var b = fight.fighters[1]
	print("== ", dados.nome, "  (tipo ", Game.tipo_nome(dados.tipo), ")")
	var danos := []
	for sl in 4:
		var pid: String = dados.poderes[sl]
		var pd: Dictionary = Game.poder(pid)
		var dist: float = DIST.get(pid, 400.0)
		_place(300, 300 + dist)
		var holds := [{}, {}]
		match sl:
			1: holds[0] = {"right": true}
			2: holds[0] = {"up": true}
			3: holds[0] = {"down": true}
		_run(2, {0: [[0, "special"]]}, holds, 1)
		var saiu: bool = a.move == pid and a.slot == sl
		_run(QUADROS.get(pid, 100))
		var dano: float = b.max_hp - b.hp
		danos.append(int(dano))
		check("%s: poder %d '%s' sai com a direção certa" % [dados.id, sl, pd.get("nome", pid)], saiu)
		check("%s: '%s' acerta o rival" % [dados.id, pd.get("nome", pid)], dano > 1.0)
		check("%s: '%s' tem nome, descrição e recarga" % [dados.id, pid], pd.get("nome", "") != "" and pd.get("desc", "") != "" and int(pd.get("cd", 0)) > 0)
	# supremo
	_place(350, 700)
	a.nucleo = 100.0
	_run(260, {0: [[0, "super"]]})
	var dano_sup: float = b.max_hp - b.hp
	check("%s: supremo '%s' acerta" % [dados.id, dados.supremo_nome], dano_sup > 120.0)
	linhas.append("%-22s %-7s poderes %4d %4d %4d %4d   supremo %4d" % [dados.nome, Game.tipo_nome(dados.tipo), danos[0], danos[1], danos[2], danos[3], int(dano_sup)])
	# o supremo não pode deixar entidades eternas
	_run(240)
	check("%s: nada sobra na arena depois" % dados.id, fight.entities.size() == 0)
	# CPU usa os poderes
	_place(300, 800)
	Game.ai_both = true
	fight.test_inputs = null
	var usados := {}
	for i in 1200:
		a.nucleo = minf(a.nucleo, 40.0)
		b.nucleo = minf(b.nucleo, 40.0)
		fight.time_left = 99.0
		fight._physics_process(1.0 / 60.0)
		if a.state == "attack" and a.move_f == 1 and a.is_power():
			usados[a.move] = true
		if a.hp < 500 or b.hp < 500:
			a.hp = a.max_hp; b.hp = b.max_hp
	Game.ai_both = false
	check("%s: CPU usa vários poderes (%d de 4)" % [dados.id, usados.size()], usados.size() >= 2)
