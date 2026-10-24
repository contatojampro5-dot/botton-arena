extends Node
## Mede o custo dos scripts por quadro (lógica da luta e desenhos) com CPU contra CPU lutando.

func _ready() -> void:
	Game.modo = "versus"
	Game.ai_both = true
	Game.opcoes.cpu = 2
	for i in Game.ARENAS.size():
		Game.escolha = [i % 12, (i + 5) % 12]
		Game.arena = i
		Game.goto("res://scripts/fight.gd")
		await get_tree().process_frame
		await get_tree().process_frame
		var f = Game._current
		f.set_physics_process(false)
		var n := 600
		var fis_tot := 0
		var fis_max := 0
		var picos := []
		var quadro_max := 0
		for k in n:
			var t0 := Time.get_ticks_usec()
			f._physics_process(1.0 / 60.0)
			var dt := Time.get_ticks_usec() - t0
			fis_tot += dt
			fis_max = maxi(fis_max, dt)
			for x in f.fighters:
				x.nucleo = maxf(x.nucleo, 60.0)
				if x.hp < 200: x.hp = x.max_hp
			await get_tree().process_frame
			var q := dt
			if q > quadro_max:
				quadro_max = q
			if q > 2000:
				picos.append("%d us (lógica %d) %s/%s %s/%s ents %d" % [q, dt, f.fighters[0].state, f.fighters[0].move, f.fighters[1].state, f.fighters[1].move, f.entities.size()])
		var txt := "%-24s lógica %4d us (pior %5d)" % [Game.ARENAS[i].nome, fis_tot / n, fis_max]
		txt += "  fundo %4d us/quadro" % (f.bg.draw_us / maxi(1, f.bg.draw_n))
		print(txt)
		for p in picos.slice(0, 4): print("     pico: ", p)
	get_tree().quit()
