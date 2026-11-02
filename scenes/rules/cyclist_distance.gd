@tool
class_name CyclistDistance
extends RulePiece
## Distancia con la bici (nivel 8). El origen es la línea de disparo: cuando el
## auto la cruza, sale una bici en la ciclovía, en cyclist_start_x. El auto avanza
## hacia +x (gira el nodo para otras direcciones).
## - Solo se evalúa cuando el auto rebasa a la bici: viene de atrás, se pone a la
##   par y termina adelante. Una vez por pasada.
## - Falta (distance, FALTA_DISTANCIA_BICI) si va a la par en el carril pegado a
##   la ciclovía más de adjacent_grace segundos; +10 (BIEN_DISTANCIA_BICI) si la
##   rebasa con un carril libre de por medio.
## - Dentro de la ciclovía la falta la da BikeLane; aquí solo se cuida que nadie
##   se encime.

const CYCLIST_SCENE := preload("res://scenes/actors/cyclist.tscn")

@export var road_width: float = 256.0:
	set(value):
		road_width = value
		_refresh()
## Centro de la ciclovía desde la línea central de la ruta (+y = derecha), igual que BikeLane.side_offset.
@export var bike_side_offset: float = -96.0:
	set(value):
		bike_side_offset = value
		_refresh()
@export var lane_width: float = 64.0
## Dónde sale la bici (x local). Positiva = adelante del auto; negativa = llega por detrás.
@export var cyclist_start_x: float = 448.0:
	set(value):
		cyclist_start_x = value
		_refresh()
@export var cyclist_speed: float = 80.0
## Opcional: al pasar esta x local la bici baja a cyclist_slow_speed (INF = nunca).
@export var cyclist_slow_x: float = INF
@export var cyclist_slow_speed: float = 70.0
## La bici se borra al llegar aquí (x local). Tiene que quedar fuera de cámara.
@export var cyclist_end_x: float = 2400.0:
	set(value):
		cyclist_end_x = value
		_refresh()
## Distancia mínima en y entre el centro del auto y el centro de la ciclovía para ir "separado".
## 112 = dos carriles (128) menos 16 px de tolerancia. Carril pegado = 64 → falta; carril de en medio = 128 → bien.
@export var min_center_distance: float = 112.0
## Medio largo de la ventana "a la par": |x auto − x bici| ≤ pass_window.
@export var pass_window: float = 96.0
## Segundos seguidos en el carril pegado, dentro de la ventana, antes de la falta.
@export var adjacent_grace: float = 0.25
## Si el auto va DENTRO de la ciclovía detrás de la bici, frena solo a esta distancia.
@export var safety_gap: float = 24.0
## Una vez frenado, el auto sigue detenido hasta que la bici le saca esta distancia de más.
@export var release_margin: float = 8.0
@export var car_half_length: float = 34.0
@export var bike_half_length: float = 30.0
## Solo sale en modo Grande (más tráfico). En Peque la pieza no hace nada.
@export var grande_only: bool = false
## Carril de la ruta que usa el conductor cuidadoso de las pruebas para rebasar.
@export var careful_lane_index: int = 2
@export var points: int = 10

@onready var _trigger: Area2D = $Trigger

var _cyclist: Cyclist
var _car: PlayerCar
var _triggered: bool = false
var _was_behind: bool = false
var _alongside: bool = false
var _in_lane_alongside: bool = false
var _faulted: bool = false
var _rewarded: bool = false
var _done: bool = false
var _adjacent_time: float = 0.0
var _stop_requested: bool = false


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	if _disabled():
		hide()
		return
	_trigger.area_entered.connect(_on_trigger_entered)


## Hay bici en la calle.
func is_active() -> bool:
	return is_instance_valid(_cyclist)


## x global de la bici, INF si no hay bici.
func cyclist_global_x() -> float:
	return _cyclist.global_position.x if is_active() else INF


## Ya se evaluó en esta pasada.
func is_done() -> bool:
	return _done


func has_faulted() -> bool:
	return _faulted


func was_rewarded() -> bool:
	return _rewarded


func cyclist() -> Cyclist:
	return _cyclist if is_active() else null


## Conductor cuidadoso de las pruebas: rebasa por careful_lane_index.
func careful_lane() -> int:
	return careful_lane_index


func careful_range() -> Vector2:
	return Vector2(global_position.x, to_global(Vector2(cyclist_end_x, 0.0)).x)


func _disabled() -> bool:
	return grande_only and GameState.mode == GameState.MODE_PEQUE


func _on_trigger_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null or _triggered:
		return
	_triggered = true
	_car = car
	_cyclist = CYCLIST_SCENE.instantiate() as Cyclist
	_cyclist.position = Vector2(cyclist_start_x, bike_side_offset)
	_cyclist.speed = cyclist_speed
	_cyclist.end_x = cyclist_end_x
	add_child(_cyclist)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _car == null:
		return
	if not is_active():
		_set_stop_request(false)
		return
	var local := to_local(_car.global_position)
	var dx := local.x - _cyclist.position.x
	var sep := absf(local.y - bike_side_offset)
	var in_bike_lane := sep < lane_width / 2.0
	var adjacent := not in_bike_lane and sep < min_center_distance
	_keep_apart(dx, in_bike_lane, delta)
	if _done:
		return
	if dx < -pass_window:
		_was_behind = true
		_alongside = false
		_in_lane_alongside = false
		_adjacent_time = 0.0
	elif absf(dx) <= pass_window and _was_behind:
		_alongside = true
		_in_lane_alongside = _in_lane_alongside or in_bike_lane
		_adjacent_time = _adjacent_time + delta if adjacent else 0.0
		if _adjacent_time >= adjacent_grace and not _faulted:
			_faulted = true
			_report_infraction(&"distance", "FALTA_DISTANCIA_BICI")
	elif dx > pass_window and _alongside:
		_done = true
		if not _faulted and not _in_lane_alongside:
			_rewarded = true
			_report_good_action(&"distance", "BIEN_DISTANCIA_BICI", points)


## Dentro de la ciclovía nadie se encima: el auto frena detrás de la bici y la
## bici se espera detrás del auto.
func _keep_apart(dx: float, in_bike_lane: bool, delta: float) -> void:
	var touch := car_half_length + bike_half_length + safety_gap
	var speed := cyclist_speed
	if cyclist_slow_x < INF and _cyclist.position.x >= cyclist_slow_x:
		speed = cyclist_slow_speed
	# Bici adelante: se mira dónde queda el auto en el siguiente paso.
	var next_gap := -dx - (_car.speed - speed) * delta
	var margin := release_margin if _stop_requested else 0.0
	_set_stop_request(in_bike_lane and dx < 0.0 and next_gap < touch + margin)
	if in_bike_lane and dx > 0.0 and dx - speed * delta < touch + release_margin:
		speed = 0.0
	_cyclist.speed = speed


func _set_stop_request(on: bool) -> void:
	if on == _stop_requested or _car == null:
		return
	_stop_requested = on
	if on:
		_car.add_stop_request(self)
	else:
		_car.remove_stop_request(self)


func _on_car_restarted() -> void:
	if is_active():
		_cyclist.queue_free()
	_cyclist = null
	if _car != null:
		_car.remove_stop_request(self)
	_stop_requested = false
	_car = null
	_triggered = false
	_was_behind = false
	_alongside = false
	_in_lane_alongside = false
	_faulted = false
	_rewarded = false
	_done = false
	_adjacent_time = 0.0


func _refresh() -> void:
	if not is_node_ready():
		return
	_set_rect(_trigger, Rect2(-8.0, -road_width / 2.0, 16.0, road_width))
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var half := road_width / 2.0
	draw_line(Vector2(0.0, -half), Vector2(0.0, half), Palette.COLOR_GOLD, 3.0)
	draw_circle(Vector2(cyclist_start_x, bike_side_offset), 10.0, Palette.COLOR_GREEN)
	draw_line(Vector2(cyclist_start_x, bike_side_offset), Vector2(cyclist_end_x, bike_side_offset), Palette.COLOR_GREEN, 2.0)
