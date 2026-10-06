@tool
class_name StopZone
extends RulePiece
## Alto. El origen es el centro de la línea de alto y el auto llega desde -x
## (gira el nodo para otras direcciones). Es falta si el auto cruza la línea
## sin haber bajado de stop_speed dentro de la zona; si se detuvo, da puntos.

@export var zone_length: float = 192.0:
	set(value):
		zone_length = value
		_refresh()
@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()
## Velocidad (px/s) por debajo de la cual el auto cuenta como detenido.
@export var stop_speed: float = 10.0
@export var points: int = 10
@export var line_width: float = 8.0
## Dónde va el letrero, del lado derecho del auto (+y).
@export var sign_offset: Vector2 = Vector2(-28.0, 116.0):
	set(value):
		sign_offset = value
		queue_redraw()
@export var sign_radius: float = 32.0
@export var sign_font_size: int = 18

@onready var _zone: Area2D = $Zone
@onready var _line: Area2D = $Line

var _car: PlayerCar
var _min_speed: float = INF
var _tracking: bool = false
var _evaluated: bool = false


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	_zone.area_entered.connect(_on_zone_entered)
	_line.area_entered.connect(_on_line_entered)
	_line.area_exited.connect(_on_line_exited)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or not _tracking or _car == null:
		return
	_min_speed = minf(_min_speed, _car.speed)


func _on_zone_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null or _evaluated:
		return
	_car = car
	_min_speed = car.speed
	_tracking = true


func _on_line_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null or _evaluated:
		return
	_evaluated = true
	_tracking = false
	if _min_speed <= stop_speed:
		_report_good_action(&"stop", "BIEN_ALTO", points)
	else:
		_report_infraction(&"stop", "FALTA_ALTO")


## Cuando el auto ya pasó completo, se prepara para otra pasada (punto de control).
func _on_line_exited(area: Area2D) -> void:
	if _car_from(area) == null:
		return
	_evaluated = false
	_min_speed = INF


func _refresh() -> void:
	if not is_node_ready():
		return
	_set_rect(_zone, Rect2(-zone_length, -road_width / 2.0, zone_length, road_width))
	_set_rect(_line, Rect2(-line_width, -road_width / 2.0, line_width, road_width))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-line_width, -road_width / 2.0, line_width, road_width), Palette.COLOR_WHITE)
	if Engine.is_editor_hint():
		draw_rect(Rect2(-zone_length, -road_width / 2.0, zone_length, road_width), Palette.COLOR_GOLD, false, 2.0)
	_draw_sign()


## Letrero de ALTO: poste, sombra y octágono rojo con borde blanco.
func _draw_sign() -> void:
	var center := sign_offset
	draw_rect(Rect2(center.x - 3.0, center.y, 6.0, sign_radius + 10.0), Palette.COLOR_OUTLINE)
	draw_rect(Rect2(center.x - 2.0, center.y, 4.0, sign_radius + 9.0), Palette.COLOR_ASPHALT)
	draw_colored_polygon(_octagon(center + Vector2(3.0, 4.0), sign_radius + 2.0), Palette.COLOR_SHADOW)
	draw_colored_polygon(_octagon(center, sign_radius + 2.0), Palette.COLOR_OUTLINE)
	draw_colored_polygon(_octagon(center, sign_radius), Palette.COLOR_WHITE)
	draw_colored_polygon(_octagon(center, sign_radius - 3.0), Palette.COLOR_ADO_RED)
	var font := ThemeDB.fallback_font
	var text := tr("SENAL_ALTO")
	var ascent := font.get_ascent(sign_font_size)
	draw_string(font, center + Vector2(-sign_radius, ascent / 2.0 - 1.0), text,
		HORIZONTAL_ALIGNMENT_CENTER, sign_radius * 2.0, sign_font_size, Palette.COLOR_WHITE)


func _octagon(center: Vector2, radius: float) -> PackedVector2Array:
	var points_out := PackedVector2Array()
	for i in 8:
		points_out.append(center + Vector2.from_angle(PI / 8.0 + i * PI / 4.0) * radius)
	return points_out
