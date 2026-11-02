@tool
class_name ParkingSpot
extends RulePiece
## Cajón de estacionamiento (nivel 3 al final de la ruta; nivel 6 a medio camino). El origen es el centro
## del cajón sobre el centro de la calle y el auto llega desde -x (gira el nodo
## para otras direcciones).
## - Al acercarse, el auto baja la velocidad solo (en modo peque también limita
##   la velocidad de avance) y se detiene con su centro en el centro del cajón.
## - Si el auto está en otro carril, se queda esperando en la marca de parada
##   hasta que el niño se cambie con la flecha al carril del cajón.
## - Cuando queda dentro del cajón emite parked. No da puntos ni faltas: en el
##   nivel 3 el nivel termina cuando se abre la puerta (DoorExit).
## - Para seguir la ruta después de estacionarse (cajón reutilizable): llamar
##   release() (por ejemplo desde otra pieza al terminar su acción) o poner
##   release_after_park = true para que suelte el auto solo tras release_delay.
##   release() quita la petición de alto del cajón y emite released.

signal parked
## El cajón soltó al auto: puede seguir la ruta.
signal released

## Distancia del centro de la calle al centro del cajón (+y = derecha del auto).
## Con 2 carriles de 64 px: 32 es el derecho y -32 el izquierdo.
@export var bay_offset: float = 32.0:
	set(value):
		bay_offset = value
		_refresh()
@export var bay_length: float = 112.0:
	set(value):
		bay_length = value
		_refresh()
@export var bay_width: float = 56.0:
	set(value):
		bay_width = value
		_refresh()
@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()
## Largo de la zona donde el auto empieza a bajar la velocidad.
@export var approach_length: float = 320.0:
	set(value):
		approach_length = value
		_refresh()
## px/s². Qué tan fuerte frena el auto solo al acercarse.
@export var brake_deceleration: float = 160.0
## Modo peque: velocidad a la que avanza solo dentro de la zona de acercamiento.
@export var approach_speed: float = 90.0
## Qué tan cerca del centro del cajón (px) cuenta como llegado.
@export var stop_tolerance: float = 3.0
## Qué tan cerca (px) del carril del cajón tiene que estar el auto.
@export var lane_tolerance: float = 3.0
@export var line_width: float = 4.0
## Cuadros de meta pintados al fondo del cajón: aquí termina el nivel.
@export var show_finish_line: bool = true:
	set(value):
		show_finish_line = value
		queue_redraw()
@export var finish_square: float = 8.0:
	set(value):
		finish_square = value
		queue_redraw()
## Clave de textos.csv que dice el copiloto al estacionarse. Vacía = no dice nada.
@export var parked_message_key: String = "ESTACIONADO_AVISO"
@export_group("Soltar el auto")
## Suelta el auto solo después de estacionarse (si es falso, alguien llama release()).
@export var release_after_park: bool = false
## Segundos detenido en el cajón antes de soltarlo cuando release_after_park.
@export var release_delay: float = 1.5

@onready var _approach: Area2D = $Approach

var _car: PlayerCar
var _stop_progress: float = 0.0
var _holding: bool = false
var _parked: bool = false
var _warned: bool = false
var _released: bool = false
## Cada pasada invalida el temporizador de release_after_park de la anterior.
var _pass_id: int = 0


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	add_to_group(&"parking_spot")
	_approach.area_entered.connect(_on_approach_entered)


func is_parked() -> bool:
	return _parked


func is_released() -> bool:
	return _released


## Deja ir al auto que está estacionado en el cajón. No hace nada si el auto
## todavía no se estaciona o si ya se soltó.
func release() -> void:
	if not _parked or _released or _car == null:
		return
	_released = true
	_car.remove_stop_request(self)
	_car.clear_speed_limit(self)
	released.emit()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or _car == null or _parked:
		return
	var remaining := _stop_progress - _car.progress
	if remaining > stop_tolerance:
		# Frena de forma pareja para llegar con velocidad casi cero al centro.
		var limit := sqrt(2.0 * brake_deceleration * remaining)
		if _car.speed > limit:
			_car.speed = limit
			_car.is_braking = true
		return
	if not _holding:
		_holding = true
		_car.speed = 0.0
		_car.add_stop_request(self)
		_car.clear_speed_limit(self)
	if absf(_car.v_offset - bay_offset) <= lane_tolerance:
		_parked = true
		parked.emit()
		if not parked_message_key.is_empty():
			Feedback.show_info(parked_message_key)
		if release_after_park:
			_release_later()
	elif not _warned:
		# Quedó en otro carril: se espera a que se cambie con la flecha.
		_warned = true
		Feedback.show_info("ESTACIONAR_CARRIL")


func _release_later() -> void:
	var id := _pass_id
	await get_tree().create_timer(release_delay, false).timeout
	if id == _pass_id:
		release()


func _on_approach_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null or car == _car:
		return
	_car = car
	_stop_progress = _progress_on_route(car)
	# Modo peque: el auto avanza solo al 70% del límite; así llega a approach_speed.
	_car.set_speed_limit(self, approach_speed / maxf(_car.auto_drive_factor, 0.1))


func _on_car_restarted() -> void:
	if _car != null:
		_car.remove_stop_request(self)
		_car.clear_speed_limit(self)
	_car = null
	_holding = false
	_parked = false
	_warned = false
	_released = false
	_pass_id += 1


func _refresh() -> void:
	if not is_node_ready():
		return
	_set_rect(_approach, Rect2(-approach_length, -road_width / 2.0, approach_length + bay_length / 2.0, road_width))
	queue_redraw()


## Cajón pintado en el piso: tres rayas, abierto del lado por donde llega el auto,
## y cuadros de meta al fondo.
func _draw() -> void:
	var left := -bay_length / 2.0
	var right := bay_length / 2.0
	var top := bay_offset - bay_width / 2.0
	var bottom := bay_offset + bay_width / 2.0
	if show_finish_line:
		var rows := int(round(bay_width / finish_square))
		for row in rows:
			for col in 2:
				var color := Palette.COLOR_WHITE if (row + col) % 2 == 0 else Palette.COLOR_DARK_PURPLE
				draw_rect(Rect2(right - finish_square * (2 - col), top + row * finish_square, finish_square, finish_square), color)
	draw_line(Vector2(left, top), Vector2(right, top), Palette.COLOR_WHITE, line_width)
	draw_line(Vector2(left, bottom), Vector2(right, bottom), Palette.COLOR_WHITE, line_width)
	draw_line(Vector2(right, top), Vector2(right, bottom), Palette.COLOR_WHITE, line_width)
	if Engine.is_editor_hint():
		draw_rect(Rect2(-approach_length, -road_width / 2.0, approach_length + bay_length / 2.0, road_width), Palette.COLOR_GOLD, false, 2.0)
