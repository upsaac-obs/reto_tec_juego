@tool
class_name BusStop
extends RulePiece
## Parada de camión (nivel 8). El origen es el punto de la línea central de la
## ruta donde se detiene el centro del camión; el auto llega desde -x (gira el
## nodo para otras direcciones). Todo se calcula en coordenadas locales.
## - Al cruzar Trigger, el camión aparece atrás de la parada, llega y se detiene
##   en x = 0. Baja y sube gente (solo entre la puerta y la banqueta).
## - Falta (distance, FALTA_CAMION) si, con el camión detenido, el frente del auto
##   rebasa la parte de atrás del camión por otro carril. Una por pasada.
## - +10 (distance, BIEN_CAMION) si el auto esperó detrás, detenido por su cuenta,
##   hasta que el camión arrancó.
## - Si el auto va en el carril del camión, frena solo antes de tocarlo (no es
##   falta ni da puntos).

enum State { IDLE, ARRIVING, STOPPED, DEPARTING, GONE }

const PEDESTRIAN_SCENE := preload("res://scenes/actors/pedestrian.tscn")

@export var road_width: float = 256.0:
	set(value):
		road_width = value
		_refresh()
## Centro del carril del camión, desde la línea central de la ruta (+y = derecha del auto).
@export var lane_y: float = 96.0:
	set(value):
		lane_y = value
		_refresh()
## Distancia antes del origen donde el auto, al cruzarla, hace aparecer el camión.
@export var trigger_distance: float = 1400.0:
	set(value):
		trigger_distance = value
		_refresh()
## Dónde aparece el camión (x local; negativa = antes de la parada). Tiene que
## quedar fuera de la cámara cuando el auto cruza Trigger.
@export var bus_start_x: float = -460.0:
	set(value):
		bus_start_x = value
		_refresh()
## Al llegar aquí el camión se desvanece (fade_time) y se oculta.
@export var bus_end_x: float = 1100.0
@export var bus_cruise_speed: float = 200.0
@export var bus_acceleration: float = 120.0
## Frenado del camión (px/s²): llega a x = 0 sin pasarse.
@export var bus_braking: float = 260.0
@export var bus_half_length: float = 70.0
## Distancia mínima (px) que el camión deja con el auto si el auto está adelante en su carril.
@export var bus_sensor: float = 40.0
## Puerta, relativa al centro del camión (del lado de la banqueta).
@export var door_offset: Vector2 = Vector2(30.0, 44.0)
@export var shelter_offset: Vector2 = Vector2(0.0, 168.0):
	set(value):
		shelter_offset = value
		_refresh()
@export var sign_offset: Vector2 = Vector2(-90.0, 150.0):
	set(value):
		sign_offset = value
		_refresh()
## Quiénes bajan y quiénes suben, un SpriteFrames por persona.
@export var passengers_off: Array[SpriteFrames] = []
@export var passengers_on: Array[SpriteFrames] = []
@export var passenger_walk_speed: float = 50.0
## Segundos entre que baja (o sube) una persona y la siguiente.
@export var passenger_interval: float = 0.6
## Separación en x entre las personas que esperan o llegan a la parada.
@export var passenger_spacing: float = 24.0
## Margen (s) tras desvanecerse una persona antes de contarla como que ya llegó.
@export var passenger_fade_margin: float = 0.1
## Segundos que el camión se queda detenido después de que el auto llegó a
## esperar (detenido a menos de wait_distance detrás del camión).
@export var min_dwell: float = 5.0
## Si el auto nunca llega, el camión arranca después de estos segundos detenido.
@export var max_dwell: float = 14.0
## Cuenta como que el auto llegó a esperar si su frente queda a esta distancia detrás del camión.
@export var wait_distance: float = 448.0
## Cuánto puede pasar el frente del auto de la parte de atrás del camión sin que sea rebasarlo.
@export var pass_margin: float = 24.0
## Medio largo del auto: de su centro al frente.
@export var car_half_length: float = 34.0
## Si el auto va en el carril del camión, frena solo a esta distancia de él (no es falta).
@export var safety_gap: float = 32.0
## Una vez frenado por seguridad, el auto sigue detenido hasta quedar esta distancia más atrás.
@export var release_margin: float = 8.0
## Diferencia en y (px) a partir de la cual el auto ya no está en el carril del camión.
@export var same_lane_tolerance: float = 48.0
## Distancia (px) que el conductor cuidadoso de las pruebas deja detrás del camión.
@export var careful_gap: float = 40.0
@export var stop_speed: float = 10.0
@export var fade_time: float = 0.3
@export var points: int = 10

@onready var _trigger: Area2D = $Trigger
@onready var _bus: Node2D = $Bus
@onready var _hitbox_shape: CollisionShape2D = $Bus/Hitbox/CollisionShape2D
@onready var _shelter: Sprite2D = $Shelter
@onready var _sign: Sprite2D = $Sign

## Solo lectura desde fuera.
var state: State = State.IDLE
var bus_speed: float = 0.0
var stopped_time: float = 0.0
var close_time: float = 0.0
var _car: PlayerCar
var _faulted: bool = false
var _rewarded: bool = false
var _auto_stopped: bool = false
var _waited: bool = false
## El frente del auto estuvo detrás del camión detenido (solo así rebasarlo es falta).
var _car_was_behind: bool = false
var _stop_requested: bool = false
var _off: Array[Pedestrian] = []
var _on: Array[Pedestrian] = []
var _arrived: int = 0
var _boarding: bool = false
var _fade: Tween
## Sube en cada reinicio para ignorar los temporizadores de una pasada anterior.
var _round: int = 0


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	for frames in passengers_off:
		_off.append(_make_passenger(frames))
	for frames in passengers_on:
		_on.append(_make_passenger(frames))
	_reset()
	_trigger.area_entered.connect(_on_trigger_entered)


func is_stopped() -> bool:
	return state == State.STOPPED


## Verdadero mientras el auto debe quedarse detrás: el camión va llegando o está detenido.
func must_wait() -> bool:
	return state == State.ARRIVING or state == State.STOPPED


## x global donde el conductor cuidadoso de las pruebas deja el centro del auto.
func careful_stop_x() -> float:
	return to_global(Vector2(-bus_half_length - careful_gap - car_half_length, 0.0)).x


## Dónde termina el camión (x global de su parte de atrás).
func bus_rear_global_x() -> float:
	return to_global(Vector2(_bus.position.x - bus_half_length, lane_y)).x


func bus_front_global_x() -> float:
	return to_global(Vector2(_bus.position.x + bus_half_length, lane_y)).x


func passengers_done() -> bool:
	return _arrived >= _off.size() + _on.size()


func has_faulted() -> bool:
	return _faulted


func was_rewarded() -> bool:
	return _rewarded


func passengers() -> Array[Pedestrian]:
	return _off + _on


func _make_passenger(frames: SpriteFrames) -> Pedestrian:
	var person := PEDESTRIAN_SCENE.instantiate() as Pedestrian
	person.sprite_frames = frames
	person.walk_speed = passenger_walk_speed
	person.z_index = 1
	add_child(person)
	person.arrived.connect(_on_passenger_arrived.bind(person))
	return person


func _on_trigger_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null or state != State.IDLE:
		return
	_car = car
	state = State.ARRIVING
	bus_speed = 0.0
	_bus.show()
	_set_hitbox(true)
	_fade_bus(1.0)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	match state:
		State.ARRIVING:
			_drive_bus(delta, 0.0)
			if _bus.position.x >= -0.5:
				_bus.position.x = 0.0
				bus_speed = 0.0
				_enter_stopped()
		State.STOPPED:
			stopped_time += delta
		State.DEPARTING:
			_drive_bus(delta, INF)
			if _bus.position.x >= bus_end_x:
				state = State.GONE
				_fade_bus(0.0)
	if _car == null or state == State.IDLE:
		return
	if state == State.GONE:
		_set_stop_request(false)
		return
	_check_car(delta)
	if state == State.STOPPED and passengers_done() and \
			(close_time >= min_dwell or _faulted or stopped_time >= max_dwell):
		_depart()


func _check_car(delta: float) -> void:
	var local := to_local(_car.global_position)
	var car_front := local.x + car_half_length
	var bus_rear := _bus.position.x - bus_half_length
	var bus_front := _bus.position.x + bus_half_length
	var same_lane := absf(local.y - lane_y) < same_lane_tolerance
	# 1. Frenado de seguridad: en el carril del camión, el auto nunca lo toca.
	var next_front := car_front + _car.speed * delta
	# Ya frenado, lo suelta solo si queda release_margin más atrás (sin avanzar a saltos).
	var margin := release_margin if _stop_requested else 0.0
	var blocking := same_lane and next_front > bus_rear - safety_gap - margin and car_front < bus_front
	_set_stop_request(blocking)
	if blocking and state == State.STOPPED:
		_auto_stopped = true
	if state != State.STOPPED:
		return
	var behind := car_front <= bus_rear + pass_margin
	if behind:
		_car_was_behind = true
	# 2. Falta: pasar junto al camión detenido por otro carril.
	if _car_was_behind and not behind and not same_lane and not _faulted:
		_faulted = true
		_report_infraction(&"distance", "FALTA_CAMION")
	# 3. Esperar detrás, detenido por su cuenta.
	var close := behind and car_front >= bus_rear - wait_distance
	if close and _car.speed < stop_speed:
		close_time += delta
		if not blocking:
			_waited = true


func _drive_bus(delta: float, target_x: float) -> void:
	var limit := bus_cruise_speed
	if target_x < INF:
		limit = minf(limit, sqrt(2.0 * bus_braking * maxf(target_x - _bus.position.x, 0.0)))
	if _car != null:
		# Si el auto está adelante en el carril del camión, el camión no lo alcanza.
		var local := to_local(_car.global_position)
		var car_rear := local.x - car_half_length
		if absf(local.y - lane_y) < same_lane_tolerance and local.x > _bus.position.x:
			var room := car_rear - (_bus.position.x + bus_half_length) - bus_sensor
			limit = minf(limit, sqrt(2.0 * bus_braking * maxf(room, 0.0)))
	if bus_speed < limit:
		bus_speed = minf(bus_speed + bus_acceleration * delta, limit)
	else:
		bus_speed = maxf(bus_speed - bus_braking * delta, limit)
	_bus.position.x = minf(_bus.position.x + bus_speed * delta, target_x)


func _enter_stopped() -> void:
	state = State.STOPPED
	stopped_time = 0.0
	close_time = 0.0
	AudioManager.play_sfx(&"bus_stop")
	if _off.is_empty():
		_start_boarding()
		return
	for i in _off.size():
		_get_off_later(i, i * passenger_interval, _round)


func _get_off_later(index: int, delay: float, round_id: int) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false, true).timeout
	if round_id != _round:
		return
	var person := _off[index]
	person.reset_at(_bus.position + door_offset)
	# Se van a un lugar distinto del de quienes esperan para subir.
	person.walk_to(_spot(_on.size() + index))


func _start_boarding() -> void:
	_boarding = true
	for i in _on.size():
		_board_later(i, i * passenger_interval, _round)


func _board_later(index: int, delay: float, round_id: int) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false, true).timeout
	if round_id != _round:
		return
	_on[index].walk_to(_bus.position + door_offset)


## Al llegar se desvanece (se fue caminando o ya subió); cuenta cuando ya no se ve.
func _on_passenger_arrived(person: Pedestrian) -> void:
	var round_id := _round
	person.fade_out()
	await get_tree().create_timer(person.fade_time + passenger_fade_margin, false, true).timeout
	if round_id != _round:
		return
	_arrived += 1
	if not _boarding and _off.has(person) and _arrived >= _off.size():
		_start_boarding()


func _depart() -> void:
	state = State.DEPARTING
	if not _faulted and _waited and not _rewarded:
		_rewarded = true
		_report_good_action(&"distance", "BIEN_CAMION", points)


## Lugar en la banqueta de la persona número index.
func _spot(index: int) -> Vector2:
	return shelter_offset + Vector2(index * passenger_spacing - 24.0, 0.0)


func _set_stop_request(on: bool) -> void:
	if on == _stop_requested or _car == null:
		return
	_stop_requested = on
	if on:
		_car.add_stop_request(self)
	else:
		_car.remove_stop_request(self)


func _set_hitbox(on: bool) -> void:
	_hitbox_shape.set_deferred(&"disabled", not on)


func _fade_bus(alpha: float) -> void:
	if _fade != null:
		_fade.kill()
	if alpha > 0.0:
		_bus.modulate.a = 0.0
	_fade = create_tween()
	_fade.tween_property(_bus, ^"modulate:a", alpha, fade_time)
	if alpha <= 0.0:
		_fade.tween_callback(_bus.hide)
		_fade.tween_callback(_set_hitbox.bind(false))


func _reset() -> void:
	_round += 1
	if _fade != null:
		_fade.kill()
	state = State.IDLE
	bus_speed = 0.0
	_bus.position = Vector2(bus_start_x, lane_y)
	_bus.modulate.a = 1.0
	_bus.hide()
	_set_hitbox(false)
	for i in _off.size():
		_off[i].reset_at(_bus.position + door_offset)
		_off[i].hide()
	for i in _on.size():
		_on[i].reset_at(_spot(i))
	_arrived = 0
	_boarding = false
	_faulted = false
	_rewarded = false
	_auto_stopped = false
	_waited = false
	_car_was_behind = false
	stopped_time = 0.0
	close_time = 0.0


func _on_car_restarted() -> void:
	if _car != null:
		_set_stop_request(false)
		_car.remove_stop_request(self)
	_stop_requested = false
	_car = null
	_reset()


func _refresh() -> void:
	if not is_node_ready():
		return
	_set_rect(_trigger, Rect2(-trigger_distance - 8.0, -road_width / 2.0, 16.0, road_width))
	_shelter.position = shelter_offset
	_sign.position = sign_offset
	if Engine.is_editor_hint():
		# En el editor se ve el camión detenido en su parada.
		_bus.position = Vector2(0.0, lane_y)
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var half := road_width / 2.0
	draw_line(Vector2(-trigger_distance, -half), Vector2(-trigger_distance, half), Palette.COLOR_GOLD, 3.0)
	draw_rect(Rect2(-bus_half_length, lane_y - 30.0, bus_half_length * 2.0, 60.0), Palette.COLOR_GOLD, false, 2.0)
	var line_x := -bus_half_length + pass_margin
	draw_line(Vector2(line_x, -half), Vector2(line_x, half), Palette.COLOR_ADO_RED, 2.0)
