extends CanvasModulate
## Tinte cálido de atardecer del nivel 7: una sola multiplicación de color sobre
## el mundo, sin shaders. El HUD y el copiloto no se tiñen (son CanvasLayer).
## El color se pone por código para no escribir colores sueltos en la escena.

const Palette := preload("res://autoload/game_state.gd")

@export var tint: Color = Palette.COLOR_WARM_LIGHT


func _ready() -> void:
	color = tint
