@tool
class_name SpeedZone
extends RulePiece
## Tramo con límite de velocidad. El origen es el inicio del tramo (donde va el
## letrero) y el auto avanza hacia +x (gira el nodo para otras direcciones).
## - Falta (speed) si el auto va más rápido que el límite por más de grace_time
##   seguidos. Como máximo una falta por pasada.
## - Si sale del tramo sin falta, da puntos.
## kind cambia el letrero y los mensajes: calle normal (nivel 2), zona escolar
## u hospital (nivel 1).

enum Kind { STREET, SCHOOL, HOSPITAL }

const SIGNS := preload("res://assets/sprites/signals/signs.png")
## Cuadros de 72 × 112 en signs.png: 1 = límite de velocidad, 2 = zona escolar.
const SIGN_SIZE := Vector2(72, 112)
const LIMIT_FRAME := 1
const SCHOOL_FRAME := 2
## Centro del círculo blanco del letrero de límite, dentro de su cuadro.
const LIMIT_CENTER := Vector2(35.5, 52.0)
const MESSAGES := {
	Kind.STREET: ["FALTA_VELOCIDAD", "BIEN_VELOCIDAD"],
	Kind.SCHOOL: ["FALTA_ZONA_ESCOLAR", "BIEN_ZONA_ESCOLAR"],
	Kind.HOSPITAL: ["FALTA_ZONA_HOSPITAL", "BIEN_ZONA_HOSPITAL"],
}

@export var kind: Kind = Kind.STREET:
	set(value):
		kind = value
		queue_redraw()
## Límite en km/h, como en el letrero (60 km/h = velocidad máxima del auto).
@export var limit_kmh: int = 30:
	set(value):
		limit_kmh = value
		queue_redraw()
## Segundos seguidos arriba del límite antes de contar la falta.
@export var grace_time: float = 2.0
@export var zone_length: float = 640.0:
	set(value):
		zone_length = value
		_refresh()
@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()
@export var points: int = 10
## Dónde va la base del poste, del lado derecho del auto (+y).
@export var sign_offset: Vector2 = Vector2(0.0, 196.0):
	set(value):
		sign_offset = value
		queue_redraw()
@export var number_font_size: int = 26

@onready var _zone: Area2D = $Zone

var _car: PlayerCar
var _over_time: float = 0.0
var _faulted: bool = false


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	_zone.area_entered.connect(_on_zone_entered)
	_zone.area_exited.connect(_on_zone_exited)


func get_limit_speed() -> float:
	return limit_kmh * Palette.PX_PER_KMH


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _car == null or _faulted:
		return
	if _car.speed > get_limit_speed():
		_over_time += delta
		if _over_time > grace_time:
			_faulted = true
			_report_infraction(&"speed", MESSAGES[kind][0])
	else:
		_over_time = 0.0


func _on_zone_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null:
		return
	_car = car
	_over_time = 0.0
	_faulted = false


func _on_zone_exited(area: Area2D) -> void:
	if _car_from(area) == null or _car == null:
		return
	# Salir hacia atrás (regreso a un punto de control) no cuenta como pasar.
	if _car.global_position.distance_to(_exit_point()) < _car.global_position.distance_to(global_position) \
			and not _faulted:
		_report_good_action(&"speed", MESSAGES[kind][1], points)
	_car = null


func _on_car_restarted() -> void:
	_car = null
	_over_time = 0.0
	_faulted = false


func _exit_point() -> Vector2:
	return to_global(Vector2(zone_length, 0.0))


func _refresh() -> void:
	if not is_node_ready():
		return
	_set_rect(_zone, Rect2(0.0, -road_width / 2.0, zone_length, road_width))
	queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(0.0, -road_width / 2.0, zone_length, road_width), Palette.COLOR_GOLD, false, 2.0)
	# Los letreros siempre se dibujan derechos, aunque el nodo esté girado.
	draw_set_transform(sign_offset, -global_rotation)
	var x := -SIGN_SIZE.x / 2.0
	if kind == Kind.SCHOOL:
		_draw_frame(SCHOOL_FRAME, Vector2(x - SIGN_SIZE.x + 8.0, -SIGN_SIZE.y))
	_draw_frame(LIMIT_FRAME, Vector2(x, -SIGN_SIZE.y))
	var center := Vector2(x, -SIGN_SIZE.y) + LIMIT_CENTER
	if kind == Kind.HOSPITAL:
		_draw_hospital_mark(center + Vector2(0.0, -40.0))
	var font := ThemeDB.fallback_font
	var ascent := font.get_ascent(number_font_size)
	draw_string(font, center + Vector2(-27.0, ascent / 2.0 - 2.0), str(limit_kmh),
		HORIZONTAL_ALIGNMENT_CENTER, 54.0, number_font_size, Palette.COLOR_OUTLINE)
	draw_set_transform(Vector2.ZERO)


func _draw_frame(frame: int, top_left: Vector2) -> void:
	draw_texture_rect_region(SIGNS, Rect2(top_left, SIGN_SIZE), Rect2(Vector2(frame * SIGN_SIZE.x, 0.0), SIGN_SIZE))


## Placa de hospital arriba del límite: cuadro azul con una H blanca.
func _draw_hospital_mark(center: Vector2) -> void:
	draw_rect(Rect2(center - Vector2(13, 13), Vector2(26, 26)), Palette.COLOR_OUTLINE)
	draw_rect(Rect2(center - Vector2(11, 11), Vector2(22, 22)), Palette.COLOR_GLASS)
	draw_rect(Rect2(center + Vector2(-7, -7), Vector2(4, 14)), Palette.COLOR_WHITE)
	draw_rect(Rect2(center + Vector2(3, -7), Vector2(4, 14)), Palette.COLOR_WHITE)
	draw_rect(Rect2(center + Vector2(-3, -2), Vector2(6, 4)), Palette.COLOR_WHITE)
