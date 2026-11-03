extends Node2D
## Sombra ovalada bajo un vehículo (plan visual, fase 0). Cae abajo a la derecha, como
## las sombras pintadas de los edificios. Va como primer hijo para quedar debajo del
## sprite; con show_behind_parent también queda debajo de lo que dibuja el padre (PlayerCar).

const Palette := preload("res://autoload/game_state.gd")

@export var size: Vector2 = Vector2(66.0, 34.0)
@export var shadow_offset: Vector2 = Vector2(4.0, 6.0)
@export_range(0.0, 1.0) var opacity: float = 0.55
@export var points: int = 16


func _ready() -> void:
	show_behind_parent = true


func _draw() -> void:
	var outline := PackedVector2Array()
	for i in points:
		var angle := TAU * i / points
		outline.append(shadow_offset + Vector2(cos(angle) * size.x, sin(angle) * size.y) / 2.0)
	draw_colored_polygon(outline, Color(Palette.COLOR_SHADOW, opacity))
