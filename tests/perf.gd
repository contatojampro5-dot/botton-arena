extends Node
## Mede o custo de processamento por quadro (scripts + desenho) em cada arena, com CPU contra CPU lutando.

func _ready() -> void:
	Game.modo = "versus"
	Game.ai_both = true
	Game.opcoes.cpu = 2
	for i in Game.ARENAS.size():
		Game.escolha = [i % 12, (i + 5) % 12]
		Game.arena = i
		Game.goto("res://scripts/fight.gd")
		for k in 200:
			await get_tree().process_frame
		var f = Game._current
		var bg = f.bg
		var proc := 0.0
		var fis := 0.0
		var pior := 0.0
		var n := 240
		var ents := 0
		for k in n:
			await get_tree().process_frame
			var p: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			var ph: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			proc += p
			fis += ph
			pior = maxf(pior, p + ph)
			if p + ph > 4.0 and "--detalhe" in OS.get_cmdline_user_args():
				var fx = f.fx
				var kinds := []
				for e in f.entities: kinds.append(e.kind)
				print("   pico %.2f ms (proc %.2f fis %.2f) quadro %d  lutadores %s/%s/%d  %s/%s/%d  ents %s  fx sparks %d rings %d texts %d puffs %d bits %d flames %d" % [p + ph, p, ph, k,
					f.fighters[0].state, f.fighters[0].move, f.fighters[0].move_f, f.fighters[1].state, f.fighters[1].move, f.fighters[1].move_f,
					str(kinds), fx.sparks.size(), fx.rings.size(), fx.texts.size(), fx.puffs.size(), fx.bits.size(), fx.flames.size()])
			ents = maxi(ents, f.entities.size())
			# sempre com Núcleo para soltar supremos e encher a tela de efeitos
			for x in f.fighters:
				x.nucleo = maxf(x.nucleo, 60.0)
				if x.hp < 200: x.hp = x.max_hp
		print("%-24s processo %5.2f ms  física %5.2f ms  pior %5.2f ms  fundo %4d us  entidades até %d" % [Game.ARENAS[i].nome, proc / n, fis / n, pior, bg.draw_us / maxi(1, bg.draw_n), ents])
	get_tree().quit()
