extends Node
## Teste automático: CPU contra CPU em várias lutas, tira prints e registra problemas.

var shots_dir := ""
var log_lines := []
var t := 0.0
var step := 0
var fights_done := 0
var max_fights := 4

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--shots="): shots_dir = a.substr(8)
		if a.begins_with("--fights="): max_fights = int(a.substr(9))
	Game.goto("res://scripts/title.gd")

func shot(name: String) -> void:
	if shots_dir == "" or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [shots_dir, name])
	print("SHOT ", name)

func _process(delta: float) -> void:
	t += delta
	match step:
		0:
			if t > 1.0:
				await shot("01_titulo"); step = 1; t = 0
				Game._current.etapa = 1
		1:
			if t > 0.6:
				await shot("02_menu"); step = 2; t = 0
				Game.modo = "versus"
				Game.goto("res://scripts/select.gd")
		2:
			if t > 0.8:
				var sel = Game._current
				sel.cur = [1, 2]
				await shot("03_selecao"); step = 3; t = 0
				sel.pronto = [true, true]
		3:
			if Game._current and Game._current.get_script().resource_path.ends_with("fight.gd"):
				Game.ai_both = true
				step = 4; t = 0
		4:
			var f = Game._current
			if t > 0.9 and t < 1.0: await shot("04_round"); t = 1.0
			if t > 6.0 and t < 6.1: await shot("05_luta"); t = 6.1
			if f.phase == "fight":
				for fi in f.fighters:
					if fi.state == "attack" and fi.move == "supremo" and fi.move_f == 30 and not has_meta("sup"):
						set_meta("sup", true); await shot("06_supremo")
					if fi.state == "attack" and fi.move == "supremo" and fi.move_f == 62 and not has_meta("sup2"):
						set_meta("sup2", true); await shot("07_supremo_raio")
				# força núcleo cheio uma vez para testar o supremo
				if t > 8.0 and not has_meta("forcou"):
					set_meta("forcou", true); f.fighters[0].nucleo = 100.0
			if f.menu_open and f.menu_kind == "end":
				print("FIM DA LUTA %d: placar %s  hp %d/%d" % [fights_done + 1, str(f.round_wins), f.fighters[0].hp, f.fighters[1].hp])
				if fights_done == 0: await shot("08_fim")
				fights_done += 1
				if fights_done >= max_fights:
					print("AUTOTEST OK"); get_tree().quit(); return
				# próxima luta com outros personagens
				Game.escolha = [randi() % Game.ROSTER.size(), randi() % Game.ROSTER.size()]
				print("Nova luta: ", Game.ROSTER[Game.escolha[0]].nome, " x ", Game.ROSTER[Game.escolha[1]].nome)
				Game.goto("res://scripts/fight.gd")
				step = 3; t = 0
			if t > 400: print("TIMEOUT"); get_tree().quit()
