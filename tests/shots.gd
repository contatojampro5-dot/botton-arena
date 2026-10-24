extends Node
## Tira prints de todas as telas, arenas, especiais e supremos (precisa de tela, rodar com xvfb).

var dir := ""
var so := ""   # filtro opcional: "telas", "arenas", "golpes"

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): dir = a.substr(8)
		if a.begins_with("--so="): so = a.substr(5)
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
	await espera(70)
	await shot("t08_vs")
	Game.arcade_iniciar(5)
	Game.arcade.etapa = 6
	Game.arcade_preparar()
	Game.goto("res://scripts/versus.gd")
	await espera(70)
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
	for c in Game.ROSTER.size():
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
		a.position.x = 330.0
		b.position.x = 330.0 + (430.0 if dados.especial not in ["raizes", "investida", "avalanche", "sombra", "ascensao"] else 260.0)
		if dados.especial == "ascensao": b.position.x = 430.0
		# especial
		var quadro_esp := {"orbe": 30, "raizes": 24, "tornado": 40, "onda": 32, "lanca": 20, "serra": 30, "frasco": 40,
			"investida": 14, "sombra": 12, "ascensao": 9, "avalanche": 16, "portal": 22}
		for i in 120:
			fight.test_inputs = [[{}, ["special"] if i == 0 else []], [{}, []]]
			fight._physics_process(1.0 / 60.0)
			await get_tree().process_frame
			if i == quadro_esp.get(dados.especial, 20):
				await shot("g%02d_%s_especial" % [c, dados.id])
		# soco (braços)
		a.position.x = 560.0; b.position.x = 690.0
		a.state = "idle"; b.state = "idle"; b.hp = b.max_hp
		for i in 9:
			fight.test_inputs = [[{}, ["heavy"] if i == 0 else []], [{}, []]]
			fight._physics_process(1.0 / 60.0)
			await get_tree().process_frame
		await shot("g%02d_%s_soco" % [c, dados.id])
		for i in 60:
			fight.test_inputs = [[{}, []], [{}, []]]
			fight._physics_process(1.0 / 60.0)
		# supremo
		a.position.x = 330.0; b.position.x = 760.0
		a.state = "idle"; b.state = "idle"; b.hp = b.max_hp
		b.position.y = 600.0; b.on_ground = true; b.vel = Vector2.ZERO
		fight.entities.clear()
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
			a.special_cd = 0
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
					a._start_move(Game.ROSTER[c].especial)
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
