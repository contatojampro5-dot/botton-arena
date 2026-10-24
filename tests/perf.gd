extends Node
## Mede o custo de desenhar cada arena (em microssegundos por quadro).

func _ready() -> void:
	Game.modo = "versus"
	Game.ai_both = true
	for i in Game.ARENAS.size():
		Game.escolha = [i % 12, (i + 5) % 12]
		Game.arena = i
		Game.goto("res://scripts/fight.gd")
		for k in 240:
			await get_tree().process_frame
		var f = Game._current
		var bg = f.bg
		var t0 := Time.get_ticks_usec()
		var fr0 := Engine.get_process_frames()
		for k in 120:
			await get_tree().process_frame
		var dt := (Time.get_ticks_usec() - t0) / 120.0
		print("%-24s fundo %5d us/quadro   quadro total %6.0f us   entidades %d" % [Game.ARENAS[i].nome, bg.draw_us / maxi(1, bg.draw_n), dt, f.entities.size()])
	get_tree().quit()
