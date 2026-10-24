extends Node
## Filma uma luta CPU x CPU: salva um print a cada 2 segundos.

var dir := ""
var t := 0.0
var n := 0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): dir = a.substr(8)
	Game.modo = "versus"
	Game.ai_both = true
	Game.opcoes.cpu = 2
	Game.escolha = [randi() % 12, randi() % 12]
	Game.arena = randi() % Game.ARENAS.size()
	Game.goto("res://scripts/fight.gd")

func _process(delta: float) -> void:
	t += delta
	if t >= 2.0:
		t = 0.0
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/f%02d.png" % [dir, n])
		n += 1
		if n >= 24:
			get_tree().quit()
