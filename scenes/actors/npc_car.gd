class_name NpcCar
extends PathFollow2D
## Auto del tráfico. Sigue su Path2D (el padre) a cruise_speed y frena si tiene
## algo enfrente: el auto del jugador (grupo "player") u otro auto del tráfico
## (grupo "traffic"). Nunca choca. Al llegar al final de su ruta se borra.
## Sprite: assets/sprites/vehicles/npc_cars.png, 8 autos ya pintados (arte v2). body_color
## elige el auto de color más parecido (entre los 2 más cercanos, para variar). Si el
## Sprite trae otra textura (la moto del nivel 8), body_color la tiñe como antes.

signal left_route

const Palette := preload("res://autoload/game_state.gd")
const CARS := preload("res://assets/sprites/vehicles/npc_cars.png")
## Color de cada auto de npc_cars.png, en orden (docs/arte_v2/codex/lotes/04_vehiculos.md).
const CAR_COLORS: Array[Color] = [Color("#7FC8E8"), Color("#9CC9A7"), Color("#3FB8AF"), Color("#BFB0D2"),
		Color("#E86F56"), Color("#7C8DA6"), Color("#F3CFAA"), Color("#F6F1EA")]
const CAR_SIZE := Vector2(70, 38)

@export var cruise_speed: float = 110.0
@export var acceleration: float = 160.0
@export var braking: float = 420.0
@export var body_color: Color = Palette.COLOR_GLASS:
	set(value):
		body_color = value
		if is_node_ready():
			_apply_body_color()

@onready var _sensor: Area2D = $Sensor
@onready var _hitbox: Area2D = $Hitbox

var speed: float = 0.0
var _blockers: Array[Area2D] = []
var _stop_requests: Array[Object] = []


func _ready() -> void:
	loop = false
	rotates = true
	_apply_body_color()
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


func _apply_body_color() -> void:
	var sprite := $Sprite as Sprite2D
	if sprite.texture != CARS:
		sprite.region_enabled = false
		sprite.self_modulate = body_color
		return
	var order := range(CAR_COLORS.size())
	order.sort_custom(func(a: int, b: int) -> bool: return _distance(CAR_COLORS[a]) < _distance(CAR_COLORS[b]))
	var index: int = order[randi() % 2]
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2(index * CAR_SIZE.x, 0.0), CAR_SIZE)
	sprite.self_modulate = Color.WHITE


func _distance(color: Color) -> float:
	return Vector3(color.r - body_color.r, color.g - body_color.g, color.b - body_color.b).length()
