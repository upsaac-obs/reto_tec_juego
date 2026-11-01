@tool
class_name TrafficLight
extends RulePiece
## Semáforo. El origen es el centro de la línea de alto y el auto llega desde -x
## (gira el nodo para otras direcciones; el semáforo se sigue dibujando derecho).
## - Falta si el auto cruza la línea con luz roja (red_light).
## - Si check_yellow (nivel 5 en adelante): falta si sigue acelerando con luz
##   amarilla dentro de la zona después de reaction_time (yellow). Cruzar en
##   amarillo no es falta: a veces ya no da tiempo de frenar.
## - Da puntos si el auto se detuvo en rojo o amarillo y cruza con verde.
## Las luces se distinguen por posición (rojo arriba, amarillo en medio, verde
## abajo) y no solo por color: las apagadas se siguen viendo.

signal light_changed(light: Light)

enum Light { GREEN, YELLOW, RED }

const SPRITE := preload("res://assets/sprites/signals/traffic_light.png")
## Centros de las tres luces en el sprite (48 × 128), de arriba abajo.
const LAMP_CENTERS := {Light.RED: Vector2(24, 16), Light.YELLOW: Vector2(24, 42), Light.GREEN: Vector2(24, 65)}
const LAMP_RADIUS := 9.0

@export var green_time: float = 6.0
@export var yellow_time: float = 2.0
@export var red_time: float = 5.0
@export var start_light: Light = Light.GREEN:
	set(value):
		start_light = value
		if not is_node_ready() or Engine.is_editor_hint():
			light = value
		queue_redraw()
## Revisa que no acelere en amarillo. Se activa desde el nivel 5.
@export var check_yellow: bool = false
## Segundos para reaccionar cuando cambia a amarillo antes de contar la falta.
@export var reaction_time: float = 0.6
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
## Falso cuando otra pieza (patience_zone) decide si hay puntos al cruzar con verde.
@export var give_points: bool = true
@export var line_width: float = 8.0
## Dónde va la base del poste, del lado derecho del auto (+y).
@export var light_offset: Vector2 = Vector2(-28.0, 196.0):
	set(value):
		light_offset = value
		queue_redraw()

@onready var _zone: Area2D = $Zone
@onready var _line: Area2D = $Line

var light: Light = Light.GREEN
var _elapsed: float = 0.0
var _car: PlayerCar
var _in_zone: bool = false
var _waited: bool = false
var _yellow_gas_time: float = 0.0
var _faulted_yellow: bool = false
var _evaluated: bool = false


func _ready() -> void:
	light = start_light
	_refresh()
	if Engine.is_editor_hint():
		return
	_zone.area_entered.connect(_on_zone_entered)
	_zone.area_exited.connect(_on_zone_exited)
	_line.area_entered.connect(_on_line_entered)
	_line.area_exited.connect(_on_line_exited)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_elapsed += delta
	if _elapsed >= _duration(light):
		_elapsed = 0.0
		set_light(_next(light))


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not _in_zone or _car == null or _evaluated:
		return
	if light != Light.GREEN and _car.speed <= stop_speed:
		_waited = true
	if check_yellow and light == Light.YELLOW and _car.is_accelerating and not _faulted_yellow:
		_yellow_gas_time += delta
		if _yellow_gas_time >= reaction_time:
			_faulted_yellow = true
			_report_infraction(&"yellow", "FALTA_AMARILLO")


func set_light(value: Light) -> void:
	light = value
	_yellow_gas_time = 0.0
	queue_redraw()
	light_changed.emit(light)


func _on_zone_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null:
		return
	_car = car
	_in_zone = true


func _on_zone_exited(area: Area2D) -> void:
	if _car_from(area) != null:
		_in_zone = false


func _on_line_entered(area: Area2D) -> void:
	if _car_from(area) == null or _evaluated:
		return
	_evaluated = true
	if light == Light.RED:
		_report_infraction(&"red_light", "FALTA_ROJO")
	elif light == Light.GREEN and _waited and give_points:
		_report_good_action(&"red_light", "BIEN_ROJO", points)


## Cuando el auto ya pasó completo, se prepara para otra pasada (punto de control).
func _on_line_exited(area: Area2D) -> void:
	if _car_from(area) != null:
		_reset_pass()


func _on_car_restarted() -> void:
	_in_zone = false
	_reset_pass()


func _reset_pass() -> void:
	_evaluated = false
	_waited = false
	_faulted_yellow = false
	_yellow_gas_time = 0.0


func _duration(value: Light) -> float:
	match value:
		Light.GREEN:
			return green_time
		Light.YELLOW:
			return yellow_time
	return red_time


func _next(value: Light) -> Light:
	match value:
		Light.GREEN:
			return Light.YELLOW
		Light.YELLOW:
			return Light.RED
	return Light.GREEN


func _lamp_color(value: Light) -> Color:
	match value:
		Light.GREEN:
			return Palette.COLOR_GREEN
		Light.YELLOW:
			return Palette.COLOR_GOLD
	return Palette.COLOR_ADO_RED


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
	# El semáforo siempre se dibuja derecho, aunque el nodo esté girado.
	draw_set_transform(light_offset, -global_rotation)
	var top_left := Vector2(-SPRITE.get_width() / 2.0, -SPRITE.get_height())
	draw_texture(SPRITE, top_left)
	var lamp: Vector2 = top_left + LAMP_CENTERS[light]
	var color := _lamp_color(light)
	draw_circle(lamp, LAMP_RADIUS + 5.0, Color(color, 0.35))
	draw_circle(lamp, LAMP_RADIUS, color)
	draw_circle(lamp + Vector2(-3.0, -3.0), 2.0, Palette.COLOR_WHITE)
	draw_set_transform(Vector2.ZERO)
