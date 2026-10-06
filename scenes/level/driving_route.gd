@tool
class_name DrivingRoute
extends Path2D
## Ruta guiada que sigue el auto del jugador.
## Sus hijos TurnPoint marcan los giros en los cruces y sus hijos StreetSection
## cambian el número de carriles desde donde están colocados.

const Palette := preload("res://autoload/game_state.gd")

## Carriles al inicio de la ruta, hasta el primer StreetSection.
@export_range(1, 4) var default_lane_count: int = 2:
	set(value):
		default_lane_count = value
		queue_redraw()
@export var lane_width: float = 32.0:
	set(value):
		lane_width = value
		queue_redraw()
## Dibuja la calle con colores planos mientras no hay tiles.
@export var debug_draw: bool = true:
	set(value):
		debug_draw = value
		queue_redraw()
@export var debug_dash_length: float = 12.0


func _ready() -> void:
	if curve and not curve.changed.is_connected(queue_redraw):
		curve.changed.connect(queue_redraw)


func get_length() -> float:
	return curve.get_baked_length()


## Distancia sobre la ruta del punto más cercano a un hijo.
func progress_of(marker: Node2D) -> float:
	return curve.get_closest_offset(marker.position)


## Giros ordenados por su posición en la ruta.
func get_turn_points() -> Array[TurnPoint]:
	var turns: Array[TurnPoint] = []
	for child in get_children():
		if child is TurnPoint:
			var turn := child as TurnPoint
			turn.progress = progress_of(turn)
			turns.append(turn)
	turns.sort_custom(func(a: TurnPoint, b: TurnPoint) -> bool: return a.progress < b.progress)
	return turns


func lane_count_at(progress: float) -> int:
	var count := default_lane_count
	var best := -1.0
	for child in get_children():
		if child is StreetSection:
			var section_progress := progress_of(child as Node2D)
			if section_progress <= progress and section_progress > best:
				best = section_progress
				count = (child as StreetSection).lane_count
	return count


## Desplazamiento lateral del centro de un carril. El carril 0 es el de la izquierda.
func lane_offset(index: int, count: int) -> float:
	return (index - (count - 1) / 2.0) * lane_width


func _draw() -> void:
	if not debug_draw or curve == null or curve.point_count < 2:
		return
	var length := get_length()
	var step := 8.0
	var progress := 0.0
	while progress < length:
		var next := minf(progress + step, length)
		var lanes := lane_count_at(progress)
		var a := curve.sample_baked_with_rotation(progress)
		var b := curve.sample_baked_with_rotation(next)
		draw_line(a.origin, b.origin, Palette.COLOR_ASPHALT, lanes * lane_width + 2.0)
		# Líneas punteadas entre carriles
		if int(progress / debug_dash_length) % 2 == 0:
			for k in range(1, lanes):
				var side := (k - lanes / 2.0) * lane_width
				draw_line(a.origin + a.y.normalized() * side, b.origin + b.y.normalized() * side, Palette.COLOR_WHITE, 2.0)
		progress = next
