@tool
class_name TurnPoint
extends Node2D
## Giro en un cruce. Se coloca como hijo de DrivingRoute justo donde empieza la curva.
## El auto se detiene antes de este punto hasta que el niño toca la flecha que
## marca el piso. Las otras flechas no hacen nada aquí.

const Palette := preload("res://autoload/game_state.gd")

enum Direction { LEFT = -1, RIGHT = 1 }

@export var direction: Direction = Direction.RIGHT:
	set(value):
		direction = value
		queue_redraw()
## Antes de esta distancia las flechas cambian de carril; dentro de ella, giran.
@export var approach_distance: float = 320.0
## Cuánto antes del giro se detiene el auto si no se ha tocado la flecha.
@export var stop_margin: float = 16.0
## Distancia después del giro en la que se apaga la direccional.
@export var exit_distance: float = 128.0
@export var arrow_back_distance: float = 80.0

## Distancia sobre la ruta. La calcula DrivingRoute.
var progress: float = 0.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED or what == NOTIFICATION_PARENTED:
		queue_redraw()


func _ready() -> void:
	set_notify_transform(true)


## Flecha en el piso, en el carril de llegada, apuntando hacia el giro.
func _draw() -> void:
	var route := get_parent() as DrivingRoute
	if route == null or route.curve == null or route.curve.point_count < 2:
		return
	var turn_progress := route.progress_of(self)
	var base := route.curve.sample_baked_with_rotation(maxf(turn_progress - arrow_back_distance, 0.0))
	var forward := base.x.normalized()
	var side := base.y.normalized() * float(direction)
	var start := base.origin - position - forward * 24.0
	var corner := base.origin - position + forward * 16.0
	var tip := corner + side * 28.0
	draw_polyline(PackedVector2Array([start, corner, tip]), Palette.COLOR_GOLD, 8.0)
	draw_colored_polygon(PackedVector2Array([
		tip + side * 12.0,
		tip - forward * 12.0,
		tip + forward * 12.0,
	]), Palette.COLOR_GOLD)
