extends Node
## Teste automático: CPU contra CPU em várias lutas (personagens e arenas aleatórios),
## passa pelas telas de seleção, arena e VS, e testa o Arcade e o Treino.

var max_fights := 4
var fights_done := 0
var t := 0.0
var step := 0
var stats := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fights="): max_fights = int(a.substr(9))
	Engine.time_scale = 1.0
	Game.opcoes.tempo = 1
	Game.opcoes.rounds = 1
	_proxima()

func _proxima() -> void:
	Game.modo = "versus"
	Game.ai_both = true
	Game.escolha = [randi() % Game.ROSTER.size(), randi() % Game.ROSTER.size()]
	Game.arena = randi() % Game.ARENAS.size()
	Game.opcoes.cpu = randi() % 3
	print("Luta %d: %s x %s em %s (CPU %s)" % [fights_done + 1, Game.ROSTER[Game.escolha[0]].nome, Game.ROSTER[Game.escolha[1]].nome,
		Game.ARENAS[Game.arena].nome, Game.CPU_NOMES[Game.opcoes.cpu]])
	Game.goto("res://scripts/versus.gd")
	t = 0.0
	step = 1

func _process(delta: float) -> void:
	t += delta
	var cur = Game._current
	match step:
		1:
			if cur and cur.get_script().resource_path.ends_with("fight.gd"):
				step = 2
				t = 0.0
		2:
			# conta supremos e especiais usados
			for f in cur.fighters:
				if f.state == "attack" and f.move_f == 1:
					var k: String = f.move
					stats[k] = stats.get(k, 0) + 1
			if cur.menu_open and cur.menu_kind == "end":
				print("   fim: rounds %s  vida %d / %d" % [str(cur.round_wins), cur.fighters[0].hp, cur.fighters[1].hp])
				fights_done += 1
				if fights_done >= max_fights:
					step = 3
					_arcade()
				else:
					_proxima()
			elif t > 200.0:
				print("TIMEOUT na luta"); get_tree().quit(1)
		4:
			# arcade: espera a primeira luta começar e força vitória do jogador
			if cur and cur.get_script().resource_path.ends_with("fight.gd") and cur.phase == "fight":
				cur.fighters[1].hp = 0.0
				step = 5
				t = 0.0
		5:
			if cur and cur.get_script().resource_path.ends_with("fight.gd") and cur.phase == "fight":
				cur.fighters[1].hp = 0.0
			if Game.arcade.get("etapa", 0) == 1 and cur and cur.get_script().resource_path.ends_with("versus.gd"):
				print("   arcade avançou para a luta 2 contra ", Game.ROSTER[Game.escolha[1]].nome)
				step = 6
				_treino()
			elif t > 30.0:
				print("ARCADE NÃO AVANÇOU"); get_tree().quit(1)
		7:
			if cur and cur.get_script().resource_path.ends_with("fight.gd") and t > 3.0:
				var d = cur.fighters[1]
				var p = cur.fighters[0]
				print("   treino: boneco hp %d, núcleo do jogador %d, tempo %s" % [d.hp, p.nucleo, "infinito" if cur.round_time == 0.0 else str(cur.round_time)])
				print("Usos de golpes: ", stats)
				print("AUTOTEST OK")
				get_tree().quit()

func _arcade() -> void:
	Game.ai_both = false
	Game.arcade_iniciar(3)
	print("Arcade: escada ", Game.arcade.escada.map(func(i): return Game.ROSTER[i].id))
	Game.goto("res://scripts/versus.gd")
	step = 4
	t = 0.0

func _treino() -> void:
	Game.modo = "treino"
	Game.escolha = [6, 9]
	Game.arena = 3
	Game.goto("res://scripts/fight.gd")
	step = 7
	t = 0.0
