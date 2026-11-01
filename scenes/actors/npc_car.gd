class_name NpcCar
extends PathFollow2D
## Auto del tráfico. Sigue su Path2D (el padre) a cruise_speed y frena si tiene
## algo enfrente: el auto del jugador (grupo "player") u otro auto del tráfico
## (grupo "traffic"). Nunca choca. Al llegar al final de su ruta se borra.
## Sprite: assets/sprites/vehicles/npc_car.png (auto blanco) pintado con body_color.

signal left_route

const Palette := preload("res://autoload/game_state.gd")

@export var cruise_speed: float = 110.0
@export var acceleration: float = 160.0
@export var braking: float = 420.0
@export var body_color: Color = Palette.COLOR_GLASS:
	set(value):
		body_color = value
		if is_node_ready():
			$Sprite.self_modulate = value

@onready var _sensor: Area2D = $Sensor
@onready var _hitbox: Area2D = $Hitbox

var speed: float = 0.0
var _blockers: Array[Area2D] = []
var _stop_requests: Array[Object] = []


func _ready() -> void:
	loop = false
	rotates = true
	$Sprite.self_modulate = body_color
	speed = cruise_speed
	_sensor.area_entered.connect(_on_sensor_entered)
	_sensor.area_exited.connect(_on_sensor_exited)


func _physics_process(delta: float) -> void:
	var blocked := not _blockers.is_empty() or not _stop_requests.is_empty()
	if blocked:
		speed = move_toward(speed, 0.0, braking * delta)
	else:
		speed = move_toward(speed, cruise_speed, acceleration * delta)
	progress += speed * delta
	if progress_ratio >= 1.0:
		left_route.emit()
		queue_free()


## Detiene el auto hasta que se quite la petición (por ejemplo, un cruce ocupado).
func add_stop_request(source: Object) -> void:
	if not _stop_requests.has(source):
		_stop_requests.append(source)


func remove_stop_request(source: Object) -> void:
	_stop_requests.erase(source)


func is_stopped() -> bool:
	return speed < 1.0


func _on_sensor_entered(area: Area2D) -> void:
	if area == _hitbox:
		return
	if area.is_in_group(&"player") or area.is_in_group(&"traffic"):
		_blockers.append(area)


func _on_sensor_exited(area: Area2D) -> void:
	_blockers.erase(area)
