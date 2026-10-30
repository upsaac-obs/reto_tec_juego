class_name DoorExit
extends RulePiece
## Salida del auto en el destino (nivel 3). El origen es el centro del cajón y
## la puerta del niño está del lado derecho del auto (+y).
## - Cuando el auto queda estacionado (ParkingSpot.parked) aparece el botón
##   "Abrir puerta" y empiezan a pasar ciclistas por la orilla, hacia +x.
## - Abrir con un ciclista cerca es falta (look): el copiloto explica y la puerta
##   se queda cerrada hasta que el ciclista se aleje.
## - Abrir cuando no hay ciclistas cerca da puntos y termina el nivel.
## - Modo peque: pasa un solo ciclista. Modo grande: pasan varios, cada pocos segundos.

const CYCLIST_SCENE := preload("res://scenes/actors/cyclist.tscn")

@export var spot: ParkingSpot
## Distancia (px, hacia adelante o hacia atrás de la puerta) a la que un ciclista
## cuenta como "cerca". Con 150 px/s son unos 3 segundos de peligro por ciclista.
@export var near_distance: float = 220.0
@export var points: int = 10
## Posición del carril de bicis respecto al origen (+y = lado de la puerta).
@export var bike_offset: float = 76.0
@export var bike_speed: float = 150.0
## Qué tan atrás de la puerta aparece el ciclista y qué tan adelante desaparece.
@export var start_distance: float = 700.0
@export var end_distance: float = 500.0
## El primer ciclista sale ya cerca de la puerta, para que abrir sin mirar al
## estacionarse sea falta (si no, bastaría tocar el botón rápido).
## Debe ser menor que near_distance.
@export var first_start_distance: float = 200.0
@export_group("Modo grande")
@export var interval_min: float = 4.0
@export var interval_max: float = 7.0
## Segundos entre que se abre la puerta bien y termina el nivel (para ver el mensaje).
@export var finish_delay: float = 1.5

@onready var _layer: CanvasLayer = $Layer
@onready var _button: Button = $Layer/OpenButton

var _parked: bool = false
var _done: bool = false
var _locked: bool = false
var _spawn_left: float = 0.0
var _cyclists: Array[Cyclist] = []


func _ready() -> void:
	_layer.visible = false
	_button.text = tr("BOTON_ABRIR_PUERTA")
	if Engine.is_editor_hint():
		return
	_button.pressed.connect(open_door)
	if spot == null:
		spot = get_tree().get_first_node_in_group(&"parking_spot") as ParkingSpot
	if spot != null:
		spot.parked.connect(_on_parked)


func _physics_process(delta: float) -> void:
	if not _parked or _done:
		return
	_forget_gone_cyclists()
	_spawn_left -= delta
	# En modo peque _spawn_left es INF: después del primero no sale otro.
	if _spawn_left <= 0.0:
		_spawn_cyclist()
		_spawn_left = randf_range(interval_min, interval_max)
	if _locked and not is_cyclist_near():
		_locked = false
		_button.disabled = false


## true si hay un ciclista a menos de near_distance de la puerta.
func is_cyclist_near() -> bool:
	_forget_gone_cyclists()
	for cyclist in _cyclists:
		if absf(cyclist.position.x) < near_distance:
			return true
	return false


## Lo llama el botón "Abrir puerta".
func open_door() -> void:
	if not _parked or _done or _locked:
		return
	if is_cyclist_near():
		_report_infraction(&"look", "FALTA_PUERTA")
		# La puerta se cierra otra vez hasta que el ciclista se aleje.
		_locked = true
		_button.disabled = true
		return
	_done = true
	_layer.visible = false
	_report_good_action(&"look", "BIEN_PUERTA", points)
	await get_tree().create_timer(finish_delay).timeout
	var manager := _rule_manager()
	if manager != null:
		manager.finish_level()


func _on_parked() -> void:
	_parked = true
	_layer.visible = true
	_spawn_cyclist(first_start_distance)
	if GameState.mode == GameState.MODE_PEQUE:
		_spawn_left = INF
	else:
		_spawn_left = randf_range(interval_min, interval_max)


func _spawn_cyclist(distance: float = start_distance) -> void:
	var cyclist := CYCLIST_SCENE.instantiate() as Cyclist
	cyclist.speed = bike_speed
	cyclist.end_x = end_distance
	cyclist.position = Vector2(-distance, bike_offset)
	add_child(cyclist)
	_cyclists.append(cyclist)


func _forget_gone_cyclists() -> void:
	var alive: Array[Cyclist] = []
	for cyclist in _cyclists:
		if is_instance_valid(cyclist) and not cyclist.is_queued_for_deletion():
			alive.append(cyclist)
	_cyclists = alive
