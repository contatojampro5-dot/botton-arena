extends Node2D
## Camada auxiliar de desenho: chama `alvo.metodo(self)` a cada quadro.
## Usada para as camadas de brilho com mistura aditiva (luz somada), que ficam bem mais bonitas.

var alvo: Object
var metodo := ""
var sempre := true

func _process(_d: float) -> void:
	if sempre:
		queue_redraw()

func _draw() -> void:
	if alvo and is_instance_valid(alvo):
		alvo.call(metodo, self)

static func aditivo() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m
