@tool
class_name Crosswalk
extends RulePiece
## Paso peatonal con un peatón. El origen es el centro de la cebra y el auto llega
## desde -x (gira el nodo para otras direcciones).
## - El peatón espera en la banqueta (Start) y empieza a cruzar cuando el auto se acerca.
## - Mientras alguien espera o cruza, el paso está ocupado.
## - Si el auto entra a la cebra ocupada: frena solo, el peatón se asusta y es falta grave.
## - Si el auto se detuvo antes y dejó cruzar, da puntos.

enum State { WAITING, CROSSING, LEAVING, GONE }

@export var crosswalk_width: float = 64.0:
	set(value):
		crosswalk_width = value
		_refresh()
@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()
## Zona antes de la cebra donde el auto hace que el peatón empiece a cruzar.
@export var approach_length: float = 448.0:
	set(value):
		approach_length = value
		_refresh()
## Distancia antes de la cebra donde el auto ya cuenta como que entró (y frena solo).
@export var fault_margin: float = 16.0:
	set(value):
		fault_margin = value
		_refresh()
@export var stop_speed: float = 10.0
@export var points: int = 10
## Segundos entre que el auto se acerca y el peatón empieza a cruzar.
@export var start_delay: float = 0.3
@export var stripe_height: float = 14.0
@export var stripe_gap: float = 10.0

@onready var _zone: Area2D = $Zone
@onready var _approach: Area2D = $Approach
@onready var _start: Marker2D = $Start
@onready var _end: Marker2D = $End
@onready var _exit: Marker2D = $Exit

var _state: State = State.WAITING
var _pedestrian: Pedestrian
var _car: PlayerCar
var _car_in_approach: bool = false
var _start_pending: bool = false
var _faulted: bool = false
var _yielded: bool = false


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	_pedestrian = $Pedestrian as Pedestrian
	_pedestrian.position = _start.position
	_zone.area_entered.connect(_on_zone_entered)
	_approach.area_entered.connect(_on_approach_entered)
	_approach.area_exited.connect(_on_approach_exited)
	_pedestrian.arrived.connect(_on_pedestrian_arrived)


func is_occupied() -> bool:
	return _state == State.WAITING or _state == State.CROSSING


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or _car == null:
		return
	if _car_in_approach and is_occupied() and not _faulted and _car.speed <= stop_speed:
		_yielded = true


func _on_approach_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null:
		return
	_car = car
	_car_in_approach = true
	if _state == State.WAITING and not _start_pending:
		_start_pending = true
		get_tree().create_timer(start_delay, false).timeout.connect(_start_crossing)


func _on_approach_exited(area: Area2D) -> void:
	if _car_from(area) != null:
		_car_in_approach = false


func _start_crossing() -> void:
	_state = State.CROSSING
	_pedestrian.walk_to(_end.position)


func _on_zone_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null or not is_occupied() or _faulted:
		return
	_faulted = true
	car.emergency_stop()
	car.add_stop_request(self)
	_pedestrian.scare()
	_report_infraction(&"crosswalk", "FALTA_PEATON", true)


func _on_pedestrian_arrived() -> void:
	match _state:
		State.WAITING, State.CROSSING:
			_state = State.LEAVING
			if _faulted and _car != null:
				_car.remove_stop_request(self)
			elif _yielded:
				_report_good_action(&"crosswalk", "BIEN_PEATON", points)
			_pedestrian.walk_to(_exit.position)
		State.LEAVING:
			_state = State.GONE
			_pedestrian.fade_out()


func _refresh() -> void:
	if not is_node_ready():
		return
	var half := Vector2(crosswalk_width, road_width) / 2.0
	_set_rect(_zone, Rect2(-half.x - fault_margin, -half.y, crosswalk_width + fault_margin, road_width))
	_set_rect(_approach, Rect2(-half.x - approach_length, -half.y, approach_length, road_width))
	queue_redraw()


## Cebra: barras paralelas al tráfico, de banqueta a banqueta.
func _draw() -> void:
	# Tapa las rayas de carril bajo la cebra
	draw_rect(Rect2(-crosswalk_width / 2.0 - 4.0, -road_width / 2.0, crosswalk_width + 8.0, road_width), Palette.COLOR_ASPHALT)
	var y := -road_width / 2.0 + stripe_gap / 2.0
	while y + stripe_height <= road_width / 2.0:
		draw_rect(Rect2(-crosswalk_width / 2.0, y, crosswalk_width, stripe_height), Palette.COLOR_WHITE)
		y += stripe_height + stripe_gap
	if Engine.is_editor_hint():
		draw_rect(Rect2(-crosswalk_width / 2.0 - approach_length, -road_width / 2.0, approach_length, road_width),
			Palette.COLOR_GOLD, false, 2.0)
