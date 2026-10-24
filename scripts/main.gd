extends Node

func _ready() -> void:
	if "--mechtest" in OS.get_cmdline_user_args():
		add_child(load("res://tests/mechanics.gd").new())
		return
	if "--autotest" in OS.get_cmdline_user_args():
		add_child(load("res://tests/autotest.gd").new())
		return
	Game.goto("res://scripts/title.gd")
