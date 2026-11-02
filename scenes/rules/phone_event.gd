@tool
class_name PhoneEvent
extends RulePiece
## Celular que suena (nivel 6). Cuando el auto pasa por el Trigger, el celular
## aparece en la esquina, vibra y suena.
## - Tocarlo con el auto en movimiento es falta (phone): el celular crece y tapa
##   la calle cover_time segundos SIN pausar el juego (el auto sigue avanzando)
##   y la falta se reporta al terminar la tapa.
## - Modo ignorar (spot vacío): si se deja sonar hasta que se calla (ring_time o
##   ring_distance, lo primero), +points.
## - Modo contestar (spot = un ParkingSpot con release_after_park apagado): suena
##   hasta que el auto se estaciona en el cajón; contestar ahí da +points y luego
##   la pieza suelta al auto con spot.release(). Si no contesta en answer_timeout,
##   el auto sigue sin puntos ni falta (el nivel nunca se traba).
## - Tocarlo detenido sin estar estacionado no es falta ni puntos: solo un aviso.
## - Como máximo una falta por pasada.
## El celular es un TouchScreenButton en su propio CanvasLayer (como DoorExit):
## así funciona con un dedo en el pedal y otro en el celular.

signal ring_started
## Al pasar a DONE por cualquier camino.
signal ring_finished

enum State { IDLE, RINGING, COVERING, WAITING_PARK, ANSWERABLE, IN_CALL, DONE }

## Vacío = modo ignorar. Con un cajón = modo contestar.
@export var spot: ParkingSpot
@export_group("Sonar")
## Modo ignorar: segundos que suena como máximo.
@export var ring_time: float = 5.0
## Modo ignorar: px de ruta desde el trigger. Se calla con lo primero que se cumpla.
@export var ring_distance: float = 900.0
## px/s. Por encima de esto el auto está en movimiento (igual que stop_speed).
@export var moving_speed: float = 10.0
## Efecto de AudioManager al empezar las ráfagas que tocan timbre.
@export var ring_sfx: StringName = &"phone_ring"
## Efecto de AudioManager en las demás ráfagas. Vacío = ninguno.
@export var vibrate_sfx: StringName = &"phone_vibrate"
## Cada cuántas ráfagas suena el timbre (las otras solo vibran).
@export var ring_every: int = 2
@export_group("Tapar la calle")
## Segundos que el celular tapa la calle.
@export var cover_time: float = 2.0
## Segundos que tarda en crecer y en encogerse.
@export var grow_time: float = 0.25
## Centro del celular chico en la pantalla (esquina superior izquierda).
@export var small_center: Vector2 = Vector2(66.0, 176.0)
@export var small_scale: float = 0.5
## Centro del celular grande: la calle delante del auto, sin tapar los pedales.
@export var cover_center: Vector2 = Vector2(720.0, 330.0)
## Múltiplo entero para no deformar el pixel art.
@export var cover_scale: float = 2.0
@export_group("Vibrar")
## Grados de la sacudida.
@export var vibrate_angle: float = 8.0
## Segundos de cada medio ciclo de la sacudida.
@export var vibrate_step: float = 0.06
## Segundos que vibra en cada ráfaga.
@export var burst_time: float = 0.6
## Segundos quieto entre ráfagas.
@export var burst_pause: float = 0.6
## Modo contestar, ya estacionado: pulso de brillo para que se note que ahora sí.
@export var pulse_speed: float = 6.0
@export var pulse_amount: float = 0.35
@export_group("Contestar")
@export var points: int = 10
## Segundos estacionado sin contestar antes de seguir sin puntos.
@export var answer_timeout: float = 8.0
## Duración de la "llamada" después de tocar.
@export var call_time: float = 2.5
## Segundos entre el mensaje de los primos y soltar el auto.
@export var release_delay: float = 2.0
@export_group("Trigger")
@export var depth: float = 64.0:
	set(value):
		depth = value
		_refresh()
@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()

@onready var _trigger: Area2D = $Trigger
@onready var _layer: CanvasLayer = $Layer
@onready var _holder: Node2D = $Layer/Holder
@onready var _button: TouchScreenButton = $Layer/Holder/Phone

var _state: State = State.IDLE
var _car: PlayerCar
var _touched_moving: bool = false
var _said_wait: bool = false
## Segundos sonando (modo ignorar) o esperando a que conteste (ANSWERABLE).
var _elapsed: float = 0.0
## Reloj de la vibración (ráfagas).
var _burst_clock: float = 0.0
var _burst_index: int = 0
var _trigger_progress: float = 0.0
var _grow_tween: Tween
## Sube en cada reinicio para ignorar los await de una pasada anterior.
var _round: int = 0


func _ready() -> void:
	_refresh()
	_layer.visible = false
	if Engine.is_editor_hint():
		return
	_reset_phone()
	_trigger.area_entered.connect(_on_trigger_entered)
	_button.pressed.connect(touch_phone)
	if spot != null:
		spot.parked.connect(_on_spot_parked)
	_connect_level_finished.call_deferred()


func get_state() -> State:
	return _state


func is_ringing() -> bool:
	return _state == State.RINGING or _state == State.ANSWERABLE


func is_covering() -> bool:
	return _state == State.COVERING


func is_answerable() -> bool:
	return _state == State.ANSWERABLE


func is_car_moving() -> bool:
	return _car != null and _car.speed > moving_speed


## Lo llama el celular al tocarlo (y las pruebas).
func touch_phone() -> void:
	match _state:
		State.RINGING:
			if is_car_moving():
				_cover()
			elif spot != null and spot.is_parked():
				_answer()
			elif not _said_wait:
				# Detenerse no es manejar distraído, pero tampoco es contestar.
				_said_wait = true
				Feedback.show_info("CELULAR_ESPERA_CAJON")
		State.ANSWERABLE:
			_answer()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	match _state:
		State.RINGING:
			_vibrate(delta)
			if spot == null:
				_elapsed += delta
				if _elapsed >= ring_time or _car.progress >= _trigger_progress + ring_distance:
					_stop_ringing()
		State.ANSWERABLE:
			_vibrate(delta)
			_elapsed += delta
			var glow := 1.0 + pulse_amount * (0.5 + 0.5 * sin(_elapsed * pulse_speed))
			_holder.modulate = Color(glow, glow, glow)
			if _elapsed >= answer_timeout:
				_give_up()


func _on_trigger_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null or _state != State.IDLE:
		return
	_car = car
	_trigger_progress = _progress_on_route(car)
	_start_ringing(State.RINGING)
	ring_started.emit()


func _start_ringing(state: State) -> void:
	_state = state
	_elapsed = 0.0
	_burst_clock = 0.0
	_burst_index = 0
	_holder.position = small_center
	_holder.scale = Vector2.ONE * small_scale
	_holder.rotation_degrees = 0.0
	_holder.modulate = Color.WHITE
	_layer.visible = true
	_play_burst_sound()


## Sacude el celular a ráfagas: burst_time vibrando, burst_pause quieto.
func _vibrate(delta: float) -> void:
	_burst_clock += delta
	var cycle := burst_time + burst_pause
	if _burst_clock >= cycle:
		_burst_clock -= cycle
		_burst_index += 1
		_play_burst_sound()
	if _burst_clock < burst_time:
		var half := int(_burst_clock / maxf(vibrate_step, 0.01))
		_holder.rotation_degrees = vibrate_angle if half % 2 == 0 else -vibrate_angle
	else:
		_holder.rotation_degrees = 0.0


func _play_burst_sound() -> void:
	var sfx := ring_sfx if _burst_index % maxi(ring_every, 1) == 0 else vibrate_sfx
	if sfx != &"":
		AudioManager.play_sfx(sfx)


## Modo ignorar: se calló sin que lo tocaran.
func _stop_ringing() -> void:
	_hide_phone()
	if not _touched_moving:
		_report_good_action(&"phone", "BIEN_CELULAR", points)
	_finish()


## Toque en movimiento: tapa la calle sin pausar y luego reporta la falta.
func _cover() -> void:
	var round_id := _round
	_touched_moving = true
	_state = State.COVERING
	_holder.rotation_degrees = 0.0
	_holder.modulate = Color.WHITE
	Feedback.show_info("CELULAR_TAPA")
	_grow_to(cover_center, cover_scale)
	await get_tree().create_timer(grow_time + cover_time, false).timeout
	if round_id != _round or _state != State.COVERING:
		return
	_grow_to(small_center, small_scale)
	await get_tree().create_timer(grow_time, false).timeout
	if round_id != _round or _state != State.COVERING:
		return
	# Se reporta al terminar la tapa: la pausa de la falta congelaría la calle tapada.
	_hide_phone()
	_report_infraction(&"phone", "FALTA_CELULAR")
	if spot == null:
		_finish()
	elif spot.is_parked():
		_start_ringing(State.ANSWERABLE)
	else:
		_state = State.WAITING_PARK


## Contestar estacionado: +points, la llamada y después suelta el auto.
func _answer() -> void:
	var round_id := _round
	_state = State.IN_CALL
	_holder.rotation_degrees = 0.0
	_holder.modulate = Color.WHITE
	_report_good_action(&"phone", "BIEN_CONTESTAR", points)
	await get_tree().create_timer(call_time, false).timeout
	if round_id != _round or _state != State.IN_CALL:
		return
	Feedback.show_info("CELULAR_PRIMOS")
	await get_tree().create_timer(release_delay, false).timeout
	if round_id != _round or _state != State.IN_CALL:
		return
	_hide_phone()
	spot.release()
	_finish()


## Estacionado sin contestar durante answer_timeout: sigue sin puntos ni falta.
func _give_up() -> void:
	Feedback.show_info("CELULAR_LUEGO")
	_hide_phone()
	spot.release()
	_finish()


func _on_spot_parked() -> void:
	if _state == State.RINGING or _state == State.WAITING_PARK:
		_start_ringing(State.ANSWERABLE)
		Feedback.show_info("CELULAR_CONTESTA")


func _finish() -> void:
	_state = State.DONE
	ring_finished.emit()


func _grow_to(center: Vector2, phone_scale: float) -> void:
	if _grow_tween != null:
		_grow_tween.kill()
	_grow_tween = create_tween().set_parallel()
	_grow_tween.tween_property(_holder, "position", center, grow_time)
	_grow_tween.tween_property(_holder, "scale", Vector2.ONE * phone_scale, grow_time)


func _hide_phone() -> void:
	_layer.visible = false
	_reset_phone()


func _reset_phone() -> void:
	if _grow_tween != null:
		_grow_tween.kill()
		_grow_tween = null
	_holder.position = small_center
	_holder.scale = Vector2.ONE * small_scale
	_holder.rotation_degrees = 0.0
	_holder.modulate = Color.WHITE


func _connect_level_finished() -> void:
	var manager := _rule_manager()
	if manager != null:
		manager.level_finished.connect(_on_level_finished)


func _on_level_finished(_stars: int) -> void:
	_round += 1
	_hide_phone()
	if _state != State.DONE:
		_state = State.DONE


func _on_car_restarted() -> void:
	# Una tapa cancelada a la mitad no reporta la falta.
	_round += 1
	_hide_phone()
	_state = State.IDLE
	_touched_moving = false
	_said_wait = false
	_elapsed = 0.0
	_car = null


func _refresh() -> void:
	if not is_node_ready():
		return
	_set_rect(_trigger, Rect2(-depth / 2.0, -road_width / 2.0, depth, road_width))
	queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(-depth / 2.0, -road_width / 2.0, depth, road_width), Palette.COLOR_GOLD, false, 2.0)
