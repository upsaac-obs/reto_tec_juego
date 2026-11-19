@tool
class_name LaneMerge
extends RulePiece
## La calle se angosta más adelante (nivel 5: autos estacionados a la derecha) y
## hay que ir en required_lane antes de llegar. El origen es donde se revisa el
## frente del auto; el auto avanza hacia +x (gira el nodo para otras direcciones).
## - Si el frente del auto llega aquí y no va en required_lane, ni lo está pidiendo
##   con la direccional, es falta no grave (lane, message_key). Una vez por pasada.
##   El cambio de carril lo hace después solo el StreetSection de un carril que va
##   un poco más adelante (la falta pausa el juego antes de que empiece).
## - Si ya va en required_lane o ya puso la direccional hacia él (el cambio está
##   en marcha), no pasa nada: ni mensaje, ni puntos, ni sonido.
## - Conductor cuidadoso de las pruebas: careful_lane() y careful_range().

## Carril que hay que llevar al llegar aquí. El 0 es el de la izquierda.
@export var required_lane: int = 0
@export var message_key: String = "FALTA_CARRIL"
## Largo de la zona de revisión a lo largo de la ruta.
@export var zone_depth: float = 16.0:
	set(value):
		zone_depth = value
		_refresh()
@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()
## Distancia del origen al primer obstáculo (borde del primer auto estacionado).
## Solo se usa para careful_range() y para el dibujo en el editor.
@export var obstacle_distance: float = 222.0:
	set(value):
		obstacle_distance = value
		_refresh()

@onready var _zone: Area2D = $Zone

var _evaluated: bool = false
var _faulted: bool = false


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	_zone.area_entered.connect(_on_zone_entered)


## Ya se revisó al auto en esta pasada.
func is_evaluated() -> bool:
	return _evaluated


func has_faulted() -> bool:
	return _faulted


## true si el auto ya va en required_lane o su direccional apunta hacia ese carril
## (el niño ya pidió el cambio con la flecha y está por hacerse o haciéndose).
func is_car_ready(car: PlayerCar) -> bool:
	if car.lane_index == required_lane:
		return true
	return car.turn_signal != 0 and car.turn_signal == signi(required_lane - car.lane_index)


## Conductor cuidadoso de las pruebas: se cambia a required_lane antes de llegar.
func careful_lane() -> int:
	return required_lane


func careful_range() -> Vector2:
	return Vector2(global_position.x, to_global(Vector2(obstacle_distance, 0.0)).x)


func _on_zone_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null or _evaluated:
		return
	_evaluated = true
	if is_car_ready(car):
		return
	_faulted = true
	_report_infraction(&"lane", message_key)


func _on_car_restarted() -> void:
	_evaluated = false
	_faulted = false


func _refresh() -> void:
	if not is_node_ready():
		return
	_set_rect(_zone, Rect2(0.0, -road_width / 2.0, zone_depth, road_width))
	queue_redraw()


## Solo en el editor: la zona de revisión y una flecha hasta el primer obstáculo
## por el carril que se pide (con dos carriles: 0 arriba, 1 abajo).
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var half := road_width / 2.0
	draw_rect(Rect2(0.0, -half, zone_depth, road_width), Palette.COLOR_GOLD, false, 2.0)
	var lane_y := -road_width / 4.0 if required_lane == 0 else road_width / 4.0
	var tip := Vector2(obstacle_distance, lane_y)
	draw_line(Vector2(zone_depth, lane_y), tip, Palette.COLOR_GOLD, 2.0)
	draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-14.0, -8.0), tip + Vector2(-14.0, 8.0)]), Palette.COLOR_GOLD)
	draw_line(Vector2(obstacle_distance, -half), Vector2(obstacle_distance, half), Palette.COLOR_ADO_RED, 2.0)
