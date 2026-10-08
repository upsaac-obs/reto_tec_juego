@tool
class_name PlayerCar
extends PathFollow2D
## Auto del jugador. Sigue la DrivingRoute que es su padre.
## - Sin cinturón no avanza.
## - Pedal verde acelera, pedal rojo frena y sin pedales baja poco a poco.
## - Las flechas cambian de carril o, cerca de un TurnPoint, giran.
##   Siempre pone la direccional signal_time segundos antes de moverse.
## Las piezas de reglas lo detectan por su Hitbox (grupo "player"); el auto es su owner.

signal seatbelt_fastened
signal blocked_without_seatbelt
signal turn_signal_changed(direction: int)
signal lane_changed(lane_index: int)
signal route_finished

const Palette := preload("res://autoload/game_state.gd")

enum Maneuver { NONE, LANE_CHANGE, TURN }

@export var max_speed: float = 240.0
@export var acceleration: float = 120.0
@export var braking: float = 300.0
@export var coast_deceleration: float = 60.0
## Segundos con la direccional encendida antes de cambiar de carril o girar.
@export var signal_time: float = 1.0
@export var lane_change_time: float = 0.4
## Carril inicial. El 0 es el de la izquierda.
@export var start_lane: int = 0
@export_group("Dibujo")
## Sprite visto desde arriba con el frente hacia +x. El tráfico usa el mismo con modulate.
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
@export var texture_offset: Vector2 = Vector2(-34.0, -20.0)
@export var blink_interval: float = 0.3
## Rectángulos en coordenadas del auto que se encienden al frenar.
@export var brake_lights: Array[Rect2] = [Rect2(-32.0, -12.0, 3.0, 5.0), Rect2(-32.0, 8.0, 3.0, 5.0)]
@export var left_signal_lights: Array[Rect2] = [Rect2(22.0, -16.0, 6.0, 3.0), Rect2(-29.0, -16.0, 6.0, 3.0)]
@export var right_signal_lights: Array[Rect2] = [Rect2(22.0, 14.0, 6.0, 3.0), Rect2(-29.0, 14.0, 6.0, 3.0)]

var speed: float = 0.0
var seatbelt_on: bool = false
var lane_index: int = 0
## -1 izquierda, 0 apagada, 1 derecha.
var turn_signal: int = 0
var is_braking: bool = false
## true mientras el niño pisa el pedal verde (lo revisa el semáforo en amarillo).
var is_accelerating: bool = false

var _route: DrivingRoute
var _turns: Array[TurnPoint] = []
var _next_turn: int = 0
var _turn_unlocked: bool = false
var _lane_count: int = 1
var _lane_tween: Tween
var _maneuver: Maneuver = Maneuver.NONE
var _maneuver_lane: int = 0
var _signal_elapsed: float = 0.0
var _blink_time: float = 0.0
var _finished: bool = false
## Piezas que piden que el auto no avance (por ejemplo, un peatón cruzando).
var _stop_requests: Array[Object] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_route = get_parent() as DrivingRoute
	assert(_route != null, "PlayerCar tiene que ser hijo de un DrivingRoute")
	loop = false
	rotates = true
	_turns = _route.get_turn_points()
	_lane_count = _route.lane_count_at(progress)
	lane_index = clampi(start_lane, 0, _lane_count - 1)
	v_offset = _route.lane_offset(lane_index, _lane_count)


## Frena en seco. Lo usan las piezas de reglas para no tocar a nadie.
func emergency_stop() -> void:
	speed = 0.0
	is_braking = true


func add_stop_request(source: Object) -> void:
	if not _stop_requests.has(source):
		_stop_requests.append(source)


func remove_stop_request(source: Object) -> void:
	_stop_requests.erase(source)


## Pone el auto detenido en otro punto de la ruta (por ejemplo, el último punto de control).
## No cambies progress directamente: así se recalcula cuál es el siguiente giro.
func restart_at(new_progress: float) -> void:
	progress = clampf(new_progress, 0.0, _route.get_length())
	speed = 0.0
	is_braking = false
	_finished = false
	_maneuver = Maneuver.NONE
	_turn_unlocked = false
	_set_turn_signal(0)
	_next_turn = 0
	while _next_turn < _turns.size() and progress > _turns[_next_turn].progress:
		_next_turn += 1
	if _lane_tween != null:
		_lane_tween.kill()
	_lane_count = _route.lane_count_at(progress)
	lane_index = clampi(lane_index, 0, _lane_count - 1)
	v_offset = _route.lane_offset(lane_index, _lane_count)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _finished:
		return
	_read_input()
	_update_maneuver(delta)
	_update_speed(delta)
	_move(delta)
	_update_turn_passed()
	_update_lane_count()
	if progress >= _route.get_length():
		_finished = true
		speed = 0.0
		is_braking = false
		_set_turn_signal(0)
		route_finished.emit()
	_blink_time += delta
	queue_redraw()


func _read_input() -> void:
	if Input.is_action_just_pressed(&"car_seatbelt") and not seatbelt_on:
		seatbelt_on = true
		seatbelt_fastened.emit()
	if Input.is_action_just_pressed(&"car_accelerate") and not seatbelt_on:
		blocked_without_seatbelt.emit()
	if Input.is_action_just_pressed(&"car_left"):
		_on_arrow(-1)
	if Input.is_action_just_pressed(&"car_right"):
		_on_arrow(1)


func _on_arrow(direction: int) -> void:
	var turn := _upcoming_turn()
	if turn != null and progress >= turn.progress - turn.approach_distance:
		# Cerca del cruce las flechas sirven para girar, solo hacia donde marca el piso.
		if _turn_unlocked or _maneuver == Maneuver.TURN or direction != turn.direction:
			return
		_start_maneuver(Maneuver.TURN, direction)
		return
	if _maneuver != Maneuver.NONE:
		return
	var target := lane_index + direction
	if target < 0 or target >= _lane_count:
		return
	_maneuver_lane = target
	_start_maneuver(Maneuver.LANE_CHANGE, direction)


func _start_maneuver(kind: Maneuver, direction: int) -> void:
	_maneuver = kind
	_signal_elapsed = 0.0
	_set_turn_signal(direction)


func _update_maneuver(delta: float) -> void:
	if _maneuver == Maneuver.NONE:
		return
	_signal_elapsed += delta
	if _signal_elapsed < signal_time:
		return
	match _maneuver:
		Maneuver.LANE_CHANGE:
			_maneuver = Maneuver.NONE
			_move_to_lane(_maneuver_lane, true)
		Maneuver.TURN:
			# La direccional se queda encendida hasta salir del giro.
			_maneuver = Maneuver.NONE
			_turn_unlocked = true


func _update_speed(delta: float) -> void:
	is_accelerating = Input.is_action_pressed(&"car_accelerate") and seatbelt_on
	is_braking = Input.is_action_pressed(&"car_brake")
	if is_braking:
		speed -= braking * delta
	elif is_accelerating:
		speed += acceleration * delta
	else:
		speed -= coast_deceleration * delta
	speed = clampf(speed, 0.0, max_speed)
	if not _stop_requests.is_empty():
		speed = 0.0
		is_braking = true
		return

	# Frena solo antes de un giro que todavía no se ha indicado con la flecha.
	var stop := _stop_progress()
	if stop >= 0.0:
		var limit := sqrt(2.0 * braking * maxf(stop - progress, 0.0))
		if speed > limit:
			speed = limit
			is_braking = true


func _move(delta: float) -> void:
	progress = minf(progress + speed * delta, _route.get_length())
	var stop := _stop_progress()
	if stop >= 0.0 and progress >= stop:
		progress = maxf(stop, 0.0)
		speed = 0.0


## Dónde tiene que detenerse el auto, o -1 si puede seguir.
func _stop_progress() -> float:
	var turn := _upcoming_turn()
	if turn == null or _turn_unlocked:
		return -1.0
	return turn.progress - turn.stop_margin


func _update_turn_passed() -> void:
	var turn := _upcoming_turn()
	if turn == null or progress < turn.progress + turn.exit_distance:
		return
	_next_turn += 1
	_turn_unlocked = false
	if _maneuver == Maneuver.NONE:
		_set_turn_signal(0)


func _upcoming_turn() -> TurnPoint:
	if _next_turn < _turns.size():
		return _turns[_next_turn]
	return null


## Al cambiar el número de carriles, se queda en el carril más cercano sin brincar.
func _update_lane_count() -> void:
	var count := _route.lane_count_at(progress)
	if count == _lane_count:
		return
	_lane_count = count
	if _maneuver == Maneuver.LANE_CHANGE and _maneuver_lane >= count:
		_maneuver = Maneuver.NONE
		_set_turn_signal(0)
	var nearest := 0
	for i in count:
		var distance := absf(_route.lane_offset(i, count) - v_offset)
		var best := absf(_route.lane_offset(nearest, count) - v_offset)
		# En empate se queda del mismo lado de la calle, no en el centro.
		var same_side := absf(_route.lane_offset(i, count)) > absf(_route.lane_offset(nearest, count))
		if distance < best or (is_equal_approx(distance, best) and same_side):
			nearest = i
	if _lane_tween != null and _lane_tween.is_running():
		_lane_tween.kill()
	_move_to_lane(nearest, false)


func _move_to_lane(index: int, signal_off_after: bool) -> void:
	lane_index = index
	if _lane_tween != null:
		_lane_tween.kill()
	_lane_tween = create_tween()
	_lane_tween.tween_property(self, ^"v_offset", _route.lane_offset(index, _lane_count), lane_change_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if signal_off_after:
		_lane_tween.tween_callback(_on_lane_change_finished)
	lane_changed.emit(index)


func _on_lane_change_finished() -> void:
	# Si mientras tanto empezó otra maniobra, su direccional se respeta.
	if _maneuver == Maneuver.NONE and not _turn_unlocked:
		_set_turn_signal(0)


func _set_turn_signal(direction: int) -> void:
	if direction == turn_signal:
		return
	turn_signal = direction
	_blink_time = 0.0
	turn_signal_changed.emit(direction)


## El sprite ya trae carrocería y faros; aquí solo se encienden frenos y direccionales.
func _draw() -> void:
	if texture != null:
		draw_texture(texture, texture_offset)
	if is_braking:
		for rect in brake_lights:
			draw_rect(rect, Palette.COLOR_SKY_HORIZON)
	if turn_signal != 0 and fmod(_blink_time, blink_interval * 2.0) < blink_interval:
		for rect in (right_signal_lights if turn_signal > 0 else left_signal_lights):
			draw_rect(rect, Palette.COLOR_GOLD)
