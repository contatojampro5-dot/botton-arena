extends Node
## Tira prints de todas as telas, arenas, especiais e supremos (precisa de tela, rodar com xvfb).

var dir := ""
var so := ""   # filtro opcional: "telas", "arenas", "golpes"

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): dir = a.substr(8)
		if a.begins_with("--so="): so = a.substr(5)
	# prints sempre na qualidade alta (o computador de teste é lento e ligaria o modo leve sozinho)
	Game.opcoes.qualidade = 2 if "--leve" in OS.get_cmdline_user_args() else 1
	Game.opcoes.auto_leve = false
	if so == "" or so == "telas": await _telas()
	if so == "" or so == "arenas": await _arenas()
	if so == "" or so == "golpes": await _golpes()
	if so == "rig": await _rig()
	print("SHOTS OK")
	get_tree().quit()

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])
	print("SHOT ", name)

func espera(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _telas() -> void:
	Game.goto("res://scripts/title.gd")
	await espera(40)
	await shot("t01_titulo")
	Game._current.etapa = 1
	Game._current.sel = 0
	await espera(10)
	await shot("t02_menu")
	Game._current.etapa = 2
	await espera(5)
	await shot("t03_controles")
	Game.goto("res://scripts/options.gd")
	await espera(10)
	await shot("t04_opcoes")
	Game.goto("res://scripts/gallery.gd")
	await espera(10)
	Game._current.sel = 9
	await espera(10)
	await shot("t04b_galeria")
	Game.modo = "versus"
	Game.escolha = [1, 2]
	Game.goto("res://scripts/select.gd")
	await espera(20)
	await shot("t05_selecao")
	Game.modo = "arcade"
	Game.goto("res://scripts/select.gd")
	await espera(20)
	await shot("t06_selecao_arcade")
	Game.modo = "versus"
	Game.escolha = [3, 9]
	Game.arena = 2
	Game.goto("res://scripts/stage_select.gd")
	await espera(20)
	await shot("t07_arena")
	Game.goto("res://scripts/versus.gd")
	await espera(8)
	Game._current.t = 1.0
	await espera(4)
	await shot("t08_vs")
	Game.arcade_iniciar(5)
	Game.arcade.etapa = 6
	Game.arcade_preparar()
	Game.goto("res://scripts/versus.gd")
	await espera(8)
	Game._current.t = 1.0
	await espera(4)
	await shot("t09_vs_eco")
	Game.goto("res://scripts/fight.gd")
	await espera(140)
	await shot("t10_luta_eco")
	Game.modo = "versus"
	Game.escolha = [10, 10]
	Game.arena = 5
	Game.goto("res://scripts/fight.gd")
	await espera(140)
	await shot("t10b_espelho")
	# fim de luta: faixa com o vencedor + menu de vidro
	var fl = Game._current
	fl.phase = "end"
	fl._banner(fl.fighters[0].data.nome, fl.fighters[0].data.cor.lightened(0.3), "JOGADOR 1 VENCE!   •   Placar: 1 x 0")
	fl.hud.frase = fl.fighters[0].data.frase
	fl._open_menu("end")
	await espera(30)
	await shot("t10c_fim_luta")
	Game.modo = "treino"
	Game.escolha = [7, 0]
	Game.arena = 3
	Game.goto("res://scripts/fight.gd")
	await espera(30)
	var f = Game._current
	f._open_menu("pause")
	await espera(5)
	await shot("t11_pausa_treino")
	f._open_menu("golpes")
	await espera(5)
	await shot("t12_lista_golpes")
	Game.arcade = {"char": 4, "pontos": 18650, "continues": 1, "inicio": Time.get_ticks_msec() - 400000, "escada": [], "etapa": 7}
	Game.goto("res://scripts/arcade_end.gd")
	await espera(90)
	await shot("t13_arcade_fim")

func _arenas() -> void:
	Game.modo = "versus"
	for i in Game.ARENAS.size():
		Game.escolha = [i % 12, (i * 5 + 3) % 12]
		Game.arena = i
		Game.goto("res://scripts/fight.gd")
		await espera(130)
		await shot("a%d_%s" % [i, Game.ARENAS[i].id])

func _golpes() -> void:
	Game.modo = "versus"
	# quadro (depois de apertar) em que o print é tirado, para cada poder
	var quando := {"propulsor": 12, "rajada_asc": 12, "ascensao": 12, "martelo": 13, "investida": 16, "avalanche": 18, "sombra": 14,
		"portal": 26, "coluna_fogo": 22, "broto": 19, "pico": 19, "pilar": 21, "geiser_acido": 24, "garra": 36, "geiser": 42,
		"rajada_glacial": 18, "vapor": 18, "clarao": 11, "aneis": 20, "raio_luz": 20, "raizes": 26, "pisao": 30, "corrente": 34,
		"brasas": 30, "poco": 30, "mina": 40, "chao_gelo": 36, "runa": 40, "torreta": 50, "buraco_negro": 40, "pedra": 40,
		"frasco": 46, "semente": 46, "estrela": 34, "bolhas": 50, "tornado": 40, "onda": 34, "serra": 30, "folha": 32}
	var dist := {"propulsor": 90.0, "rajada_asc": 90.0, "ascensao": 90.0, "martelo": 90.0, "investida": 330.0, "avalanche": 330.0,
		"rajada_glacial": 170.0, "vapor": 170.0, "clarao": 150.0, "aneis": 160.0, "coluna_fogo": 300.0, "broto": 300.0, "pico": 300.0,
		"pilar": 300.0, "geiser_acido": 300.0}
	var so_c := -1
	for a2 in OS.get_cmdline_user_args():
		if a2.begins_with("--char="): so_c = int(a2.substr(7))
	for c in Game.ROSTER.size():
		if so_c >= 0 and c != so_c: continue
		var dados: Dictionary = Game.ROSTER[c]
		Game.escolha = [c, 0 if c != 0 else 1]
		Game.arena = Game.arena_index(dados.casa)
		Game.goto("res://scripts/fight.gd")
		await espera(3)
		var fight = Game._current
		fight.set_physics_process(false)
		fight.phase = "fight"
		fight.banner = ""
		var a = fight.fighters[0]
		var b = fight.fighters[1]
		for x in fight.fighters: x.state = "idle"
		for sl in 4:
			var pid: String = dados.poderes[sl]
			_reset(fight, 300.0, 300.0 + dist.get(pid, 480.0))
			var hold := {}
			match sl:
				1: hold = {"right": true}
				2: hold = {"up": true}
				3: hold = {"down": true}
			var q: int = quando.get(pid, 26)
			for i in q + 1:
				var h: Dictionary = hold.duplicate() if i == 0 else {}
				if i == 0: h["special"] = true
				fight.test_inputs = [[h, ["special"] if i == 0 else []], [{}, []]]
				fight._physics_process(1.0 / 60.0)
				await get_tree().process_frame
			await shot("g%02d_%s_%d_%s" % [c, dados.id, sl, pid])
		# soco (braços)
		_reset(fight, 560.0, 690.0)
		for i in 9:
			fight.test_inputs = [[{}, ["heavy"] if i == 0 else []], [{}, []]]
			fight._physics_process(1.0 / 60.0)
			await get_tree().process_frame
		await shot("g%02d_%s_soco" % [c, dados.id])
		# supremo
		_reset(fight, 330.0, 760.0)
		a.nucleo = 100.0
		var quadro_sup := {"raio": 62, "erupcao": 92, "ilusao": 80, "furia": 80, "ciclone": 80, "tsunami": 70, "era_glacial": 80,
			"julgamento": 90, "terremoto": 92, "canhao": 72, "meteoros": 82, "transmutacao": 90}
		for i in 130:
			fight.test_inputs = [[{}, ["super"] if i == 0 else []], [{}, []]]
			fight._physics_process(1.0 / 60.0)
			await get_tree().process_frame
			if i == 26 and c < 3:
				await shot("g%02d_%s_cutin" % [c, dados.id])
			if i == quadro_sup.get(dados.supremo, 80):
				await shot("g%02d_%s_supremo" % [c, dados.id])

func _reset(fight, xa: float, xb: float) -> void:
	fight.entities.clear()
	fight.cutin = {}
	fight.hitstop = 0
	for f in fight.fighters:
		f.vel = Vector2.ZERO; f.on_ground = true; f._go("idle"); f.move = ""; f.slot = -1; f.position.y = 600.0
		f.hp = f.max_hp; f.hp_shown = f.max_hp; f.cds = [0, 0, 0, 0]; f.ice = 0; f.slow_t = 0; f.poison_t = 0; f.invuln = 0
		f.combo_taken = 0; f.juggle = 0; f.alpha_mul = 1.0; f.frozen = false; f.inp_press.clear(); f.nucleo = 0.0
	fight.fighters[0].position.x = xa
	fight.fighters[1].position.x = xb
	fight.fighters[0].facing = 1
	fight.fighters[1].facing = -1
	for k in 4:
		fight.fighters[0].fist_trail.clear()

## Folha de poses: cada botton sozinho em várias poses, recortado em volta dele
func _rig() -> void:
	Game.modo = "versus"
	Game.arena = 0
	var poses := [["idle", 0, 20], ["light", 6, 0], ["heavy", 12, 0], ["launcher", 10, 0], ["block", 8, 0], ["special", 0, 0], ["hit", 6, 0], ["win", 30, 0]]
	for c in Game.ROSTER.size():
		Game.escolha = [c, 0 if c != 0 else 1]
		Game.goto("res://scripts/fight.gd")
		await espera(3)
		var fight = Game._current
		fight.set_physics_process(false)
		fight.phase = "fight"
		fight.banner = ""
		fight.hud.visible = false
		var a = fight.fighters[0]
		var b = fight.fighters[1]
		b.position.x = 1150.0
		b.visible = false
		var k := 0
		for p in poses:
			a.state = "idle"; a.st = 0; a.move = ""; a.position = Vector2(640, 600); a.vel = Vector2.ZERO; a.on_ground = true; a.facing = 1
			a.cds = [0, 0, 0, 0]
			var nome: String = p[0]
			var quadros: int = p[1]
			match nome:
				"idle":
					for i in 20:
						fight.test_inputs = [[{}, []], [{}, []]]
						fight._physics_process(1.0 / 60.0)
				"light", "heavy", "launcher":
					a._start_move(nome)
					for i in quadros:
						fight.test_inputs = [[{}, []], [{}, []]]
						fight._physics_process(1.0 / 60.0)
				"block":
					for i in quadros:
						fight.test_inputs = [[{"block": true}, []], [{}, []]]
						fight._physics_process(1.0 / 60.0)
				"special":
					a._start_move(Game.ROSTER[c].poderes[0])
					var su: int = a.current_move().startup
					for i in su + 2:
						fight.test_inputs = [[{}, []], [{}, []]]
						fight._physics_process(1.0 / 60.0)
				"hit":
					a.take_hit(b, {"dmg": 1.0, "kb": Vector2(100, 0), "hitstun": 20, "blockstun": 10}, -1)
					for i in quadros:
						fight.test_inputs = [[{}, []], [{}, []]]
						fight._physics_process(1.0 / 60.0)
				"win":
					a.state = "win"
					for i in quadros:
						fight.test_inputs = [[{}, []], [{}, []]]
						fight._physics_process(1.0 / 60.0)
			fight.entities.clear()
			await espera(1)
			await RenderingServer.frame_post_draw
			var img: Image = get_viewport().get_texture().get_image()
			var rect := Rect2i(int(a.position.x) - 160, int(a.position.y) - 250, 320, 270)
			img.get_region(rect).save_png("%s/r%02d_%d_%s.png" % [dir, c, k, nome])
			k += 1
	print("RIG OK")
