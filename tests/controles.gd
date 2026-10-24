extends Node
## Confere o mapeamento dos controles de videogame (simulando botões e analógicos).
var ok := true
func _btn(dev: int, b: int, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = dev
	e.button_index = b
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func _eixo(dev: int, ax: int, v: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = dev
	e.axis = ax
	e.axis_value = v
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func check(nome: String, c: bool) -> void:
	print(("  ✔ " if c else "  ✘ ") + nome)
	if not c: ok = false
func _ready() -> void:
	await get_tree().process_frame
	Game.modo = "versus"
	Game.opcoes.troca_controles = false
	Game.aplicar_controles()
	_btn(0, JOY_BUTTON_X, true)
	check("2 jogadores: controle 1, X = leve do J1", Input.is_action_pressed("p1_light") and not Input.is_action_pressed("p2_light"))
	_btn(0, JOY_BUTTON_X, false)
	_btn(1, JOY_BUTTON_B, true)
	check("2 jogadores: controle 2, B = poder do J2", Input.is_action_pressed("p2_special") and not Input.is_action_pressed("p1_special"))
	_btn(1, JOY_BUTTON_B, false)
	_eixo(0, JOY_AXIS_LEFT_X, -1.0)
	check("analógico do controle 1 para a esquerda anda o J1", Input.is_action_pressed("p1_left") and not Input.is_action_pressed("p2_left"))
	_eixo(0, JOY_AXIS_LEFT_X, 0.0)
	check("analógico solto para de andar", not Input.is_action_pressed("p1_left"))
	_eixo(1, JOY_AXIS_TRIGGER_RIGHT, 1.0)
	check("gatilho RT do controle 2 = supremo do J2", Input.is_action_pressed("p2_super"))
	_eixo(1, JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_btn(0, JOY_BUTTON_DPAD_UP, true)
	check("direcional para cima = pular J1", Input.is_action_pressed("p1_up"))
	_btn(0, JOY_BUTTON_DPAD_UP, false)
	Game.opcoes.troca_controles = true
	Game.aplicar_controles()
	_btn(0, JOY_BUTTON_Y, true)
	check("trocado: controle 1 vira o J2", Input.is_action_pressed("p2_heavy") and not Input.is_action_pressed("p1_heavy"))
	_btn(0, JOY_BUTTON_Y, false)
	Game.opcoes.troca_controles = false
	Game.modo = "cpu"
	Game.aplicar_controles()
	_btn(3, JOY_BUTTON_A, true)
	check("1 jogador: qualquer controle comanda o J1", Input.is_action_pressed("p1_confirm") and not Input.is_action_pressed("p2_confirm"))
	_btn(3, JOY_BUTTON_A, false)
	_btn(2, JOY_BUTTON_START, true)
	check("Start pausa (qualquer controle)", Input.is_action_pressed("pause"))
	_btn(2, JOY_BUTTON_START, false)
	check("teclado continua funcionando depois de trocar", InputMap.action_get_events("p1_light").any(func(ev): return ev is InputEventKey))
	Game.usando_controle = true
	check("rótulos mostram botões do controle", Game.rotulo("special", 0) == "B" and Game.rotulo("super", 1) == "RT")
	Game.usando_controle = false
	check("rótulos mostram teclas do teclado", Game.rotulo("special", 0) == "H" and Game.rotulo("special", 1) == "Ç")
	print("CONTROLES ", "OK" if ok else "FALHOU")
	get_tree().quit()
