extends Node2D
## Painel de vidro líquido. Crie com Game.glass(pai, retângulo, raio).
## Fica atrás do desenho do pai (z_index -1) e desfoca o que está atrás dele.

var rect := Rect2(0, 0, 100, 40)
var radius := 22.0
var tint := Color(1, 1, 1, 0.10)
var glow := 0.0
var glow_color := Color(0.5, 0.8, 1.0)
var shadow := 0.35
var sheen := 1.0
var margin := 26.0
var _mat: ShaderMaterial
var _last := {}

func _init() -> void:
	z_index = -1
	_mat = ShaderMaterial.new()
	_mat.shader = Game.glass_shader()
	material = _mat

func set_rect(r: Rect2) -> void:
	if r != rect:
		rect = r
		queue_redraw()

func _process(_d: float) -> void:
	_sync()

func _sync() -> void:
	var sh: Shader = Game.glass_shader()
	if _mat.shader != sh:
		_mat.shader = sh
		_last.clear()
	_param("size", rect.size)
	_param("margin", margin)
	_param("radius", radius)
	_param("tint", tint)
	_param("glow", glow)
	_param("glow_color", glow_color)
	_param("shadow", shadow)
	_param("sheen", sheen)

func _param(k: String, v) -> void:
	if _last.get(k) != v:
		_last[k] = v
		_mat.set_shader_parameter(k, v)
		queue_redraw()

func _ready() -> void:
	_sync()

func _draw() -> void:
	if not visible or rect.size.x < 2.0 or rect.size.y < 2.0:
		return
	draw_texture_rect(Game.white_tex, rect.grow(margin), false)
