@tool
class_name BikeLane
extends RulePiece
## Ciclovía: un carril pintado de verde a lo largo de un tramo. El origen es el
## inicio del tramo sobre el centro de la calle y el auto avanza hacia +x (gira
## el nodo para otras direcciones).
## - Falta (bike_lane) si el auto toca la ciclovía dentro del tramo: al cambiarse
##   de carril hacia ella o al llegar al tramo ya en ese carril. Una por pasada.
## - Si pasa el tramo completo sin tocarla, da puntos.

## Distancia del centro de la calle al centro de la ciclovía (+y = derecha del
## auto). Con 2 carriles de 64 px: 32 es el derecho y -32 el izquierdo.
@export var side_offset: float = 32.0:
	set(value):
		side_offset = value
		_refresh()
@export var lane_width: float = 64.0:
	set(value):
		lane_width = value
		_refresh()
@export var length: float = 768.0:
	set(value):
		length = value
		_refresh()
@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()
## Distancia entre los dibujos de bici pintados en el piso.
@export var icon_spacing: float = 256.0:
	set(value):
		icon_spacing = value
		queue_redraw()
@export var points: int = 10

@onready var _lane: Area2D = $Lane
@onready var _stretch: Area2D = $Stretch

var _car: PlayerCar
var _faulted: bool = false


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	_lane.area_entered.connect(_on_lane_entered)
	_stretch.area_entered.connect(_on_stretch_entered)
	_stretch.area_exited.connect(_on_stretch_exited)


func _on_stretch_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car != null:
		# _faulted no se reinicia aquí: si llega ya en la ciclovía, las dos
		# áreas avisan en el mismo cuadro y el orden no está garantizado.
		_car = car


func _on_lane_entered(area: Area2D) -> void:
	if _car_from(area) == null or _faulted:
		return
	_faulted = true
	_report_infraction(&"bike_lane", "FALTA_CICLOVIA")


func _on_stretch_exited(area: Area2D) -> void:
	if _car_from(area) == null or _car == null:
		return
	# Solo cuenta si sale por el final; regresar a un punto de control no.
	var end := to_global(Vector2(length, 0.0))
	if _car.global_position.distance_to(end) < _car.global_position.distance_to(global_position) \
			and not _faulted:
		_report_good_action(&"bike_lane", "BIEN_CICLOVIA", points)
	_car = null
	_faulted = false


func _on_car_restarted() -> void:
	_car = null
	_faulted = false


func _lane_rect() -> Rect2:
	return Rect2(0.0, side_offset - lane_width / 2.0, length, lane_width)


func _refresh() -> void:
	if not is_node_ready():
		return
	# Un poco más angosta que el carril: rozar la orilla al pasar junto no cuenta.
	_set_rect(_lane, _lane_rect().grow_individual(0.0, -4.0, 0.0, -4.0))
	_set_rect(_stretch, Rect2(0.0, -road_width / 2.0, length, road_width))
	queue_redraw()


func _draw() -> void:
	var lane := _lane_rect()
	draw_rect(lane, Palette.COLOR_GREEN)
	# Raya blanca continua del lado de los autos.
	var edge_y := lane.position.y if side_offset > 0.0 else lane.end.y
	draw_rect(Rect2(0.0, edge_y - 2.0, length, 4.0), Palette.COLOR_WHITE)
	var x := icon_spacing / 2.0
	while x < length:
		_draw_bike(Vector2(x, side_offset))
		x += icon_spacing
	if Engine.is_editor_hint():
		draw_rect(Rect2(0.0, -road_width / 2.0, length, road_width), Palette.COLOR_GOLD, false, 2.0)


## Bici pintada en el piso, vista de lado y apuntando hacia +x.
func _draw_bike(center: Vector2) -> void:
	var color := Palette.COLOR_WHITE
	var back := center + Vector2(-10.0, 4.0)
	var front := center + Vector2(10.0, 4.0)
	draw_arc(back, 7.0, 0.0, TAU, 16, color, 2.0)
	draw_arc(front, 7.0, 0.0, TAU, 16, color, 2.0)
	var seat := center + Vector2(-4.0, -6.0)
	var bars := center + Vector2(7.0, -8.0)
	draw_polyline(PackedVector2Array([back, seat, center + Vector2(2.0, 4.0), back]), color, 2.0)
	draw_line(seat, bars + Vector2(-2.0, 2.0), color, 2.0)
	draw_line(bars, front, color, 2.0)
	draw_line(seat + Vector2(-3.0, -1.0), seat + Vector2(2.0, -1.0), color, 2.0)
