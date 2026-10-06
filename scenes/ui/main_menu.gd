extends Control
## Menú principal provisional. Por ahora solo muestra el título y el botón Jugar
## para comprobar el tema, los textos y el viewport.

@onready var _background: TextureRect = $Background


func _ready() -> void:
	_background.texture = _make_sky_texture()


## Gradiente del cielo de arriba a abajo, con los colores de GameState.
func _make_sky_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([
		GameState.COLOR_SKY_TOP,
		GameState.COLOR_SKY_MID,
		GameState.COLOR_SKY_HORIZON,
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	return texture
