extends Node2D
## Motos del nivel 8: van por el carril del camión (+y), salen muy atrás del
## auto al cargar el nivel y se pierden más allá del final del mapa.
## - Las que dicen grande_only no salen en modo Peque (más tráfico en Grande).
## - Frenan detrás del camión detenido y del auto (el sensor de NpcCar) y
##   también en el semáforo cuando no está en verde.
## - El auto del jugador frena solo antes de alcanzar una moto en su carril:
##   nunca se encima en nadie.

const NPC_SCENE := preload("res://scenes/actors/npc_car.tscn")
const Palette := preload("res://autoload/game_state.gd")

@export var moto_texture: Texture2D = preload("res://assets/sprites/vehicles/motorcycle.png")
## Centro del carril de las motos desde la línea central de la ruta.
@export var lane_y: float = 96.0
## x global donde sale cada moto, su velocidad y si solo sale en Grande.
@export var start_x: PackedFloat32Array = [-1000.0, -3000.0, -7000.0]
@export var speeds: PackedFloat32Array = [230.0, 220.0, 240.0]
@export var grande_only: Array[bool] = [false, true, true]
## x global donde termina la ruta de las motos (fuera del mapa).
@export var end_x: float = 12200.0
## Semáforo donde las motos se detienen si no está en verde.
@export var traffic_light: TrafficLight
## Distancia antes del semáforo donde se detienen (frente de la moto).
@export var light_stop_margin: float = 48.0
@export var moto_half_length: float = 30.0
@export var npc_braking: float = 420.0
## Para el auto del jugador: medio largo y distancia que deja con la moto.
@export var car_half_length: float = 34.0
@export var safety_gap: float = 24.0
## Una vez frenado, el auto sigue detenido hasta que la moto le saca esta distancia de más.
@export var release_margin: float = 8.0
@export var same_lane_tolerance: float = 48.0

var _motos: Array[NpcCar] = []
var _car: PlayerCar
var _car_stopped: bool = false


func _ready() -> void:
	for i in start_x.size():
		if grande_only[i] and GameState.mode == GameState.MODE_PEQUE:
			continue
		var path := Path2D.new()
		path.name = "Moto%dPath" % (i + 1)
		var curve := Curve2D.new()
		curve.add_point(Vector2(start_x[i], lane_y))
		curve.add_point(Vector2(end_x, lane_y))
		path.curve = curve
		add_child(path)
		var moto := NPC_SCENE.instantiate() as NpcCar
		moto.name = "Moto%d" % (i + 1)
		moto.cruise_speed = speeds[i]
		moto.braking = npc_braking
		moto.body_color = Palette.COLOR_WHITE
		(moto.get_node(^"Sprite") as Sprite2D).texture = moto_texture
		path.add_child(moto)
		_motos.append(moto)


func motos() -> Array[NpcCar]:
	for i in range(_motos.size() - 1, -1, -1):
		if not is_instance_valid(_motos[i]):
			_motos.remove_at(i)
	return _motos


func _physics_process(delta: float) -> void:
	if _car == null:
		var manager := get_tree().get_first_node_in_group(&"rule_manager") as RuleManager
		_car = manager.car if manager != null else null
	var block_car := false
	for moto in motos():
		_check_light(moto)
		if _car != null:
			block_car = block_car or _car_reaches(moto, delta)
	if _car != null and block_car != _car_stopped:
		_car_stopped = block_car
		if block_car:
			_car.add_stop_request(self)
		else:
			_car.remove_stop_request(self)


## En rojo o amarillo la moto se detiene antes de la línea si le da tiempo.
func _check_light(moto: NpcCar) -> void:
	if traffic_light == null:
		return
	var line := traffic_light.global_position.x - light_stop_margin
	var front := moto.global_position.x + moto_half_length
	var stopping := moto.speed * moto.speed / (2.0 * npc_braking)
	var must_stop := traffic_light.light != TrafficLight.Light.GREEN and front < line \
		and front + stopping + 16.0 >= line
	if must_stop and (moto.is_stopped() or front + stopping <= line + 8.0):
		moto.add_stop_request(self)
	else:
		moto.remove_stop_request(self)


## El auto va detrás de la moto en su carril y la alcanzaría en este paso.
func _car_reaches(moto: NpcCar, delta: float) -> bool:
	var diff := moto.global_position - _car.global_position
	if absf(diff.y) >= same_lane_tolerance or diff.x <= 0.0:
		return false
	var gap := diff.x - moto_half_length - car_half_length
	var margin := release_margin if _car_stopped else 0.0
	return gap - (_car.speed - moto.speed) * delta < safety_gap + margin
