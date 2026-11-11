@tool
class_name BallEvent
extends RulePiece
## Pelota en la calle (nivel 5). Entre autos estacionados sale una pelota rodando
## y, detrás de ella, una niña que la persigue. El origen es el punto donde la
## pelota cruza el centro de la calle; el auto llega desde -x y los autos
## estacionados están a su derecha (+y). Funciona igual que Crosswalk:
## - Cuando el auto se acerca (Approach), sale la pelota; child_delay segundos
##   después sale la niña. La calle está ocupada hasta que la niña llega a la
##   otra banqueta.
## - Si el auto entra a la zona ocupada: frena solo antes de tocar a nadie, la
##   niña se asusta y es falta grave (crosswalk, la regla del peatón).
## - Si se detuvo antes y la dejó pasar, da puntos.
## La pelota y los autos estacionados se dibujan con código (sin arte nuevo).

enum State { IDLE, BALL, CHILD, CLEAR, GONE }

const PARKED_CAR := preload("res://assets/sprites/vehicles/npc_cars.png")

## Ancho de la calle.
@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()
## Ancho de la franja por donde cruzan la pelota y la niña.
@export var crossing_width: float = 64.0:
	set(value):
		crossing_width = value
		_refresh()
## Distancia antes de la franja donde el auto ya cuenta como que entró (y frena solo).
@export var fault_margin: float = 16.0:
	set(value):
		fault_margin = value
		_refresh()
## Distancia antes del origen donde el auto hace que salga la pelota.
@export var trigger_distance: float = 280.0:
	set(value):
		trigger_distance = value
		_refresh()
## Dónde aparece la pelota (en el hueco entre autos) y dónde se detiene.
@export var ball_start: Vector2 = Vector2(0.0, 90.0)
@export var ball_end: Vector2 = Vector2(0.0, -150.0)
## Velocidad de la pelota en px/s.
@export var ball_speed: float = 200.0
@export var ball_radius: float = 9.0:
	set(value):
		ball_radius = value
		queue_redraw()
## Vueltas por segundo de la raya de la pelota mientras rueda.
@export var ball_spin: float = 2.5
## Quién persigue la pelota (los textos dicen "la niña").
@export var child_frames: SpriteFrames = preload("res://assets/sprites/pedestrians/girl_frames.tres")
## Segundos entre que sale la pelota y aparece la niña.
@export var child_delay: float = 0.6
## Velocidad de la niña en px/s. Despacio a propósito: la calle sigue ocupada cuando llega el auto.
@export var child_speed: float = 60.0
## Centros (x) de los autos estacionados. Dejan un hueco en el origen.
@export var parked_car_x: Array[float] = [-427.0, -337.0, -247.0, -157.0, -67.0, 67.0, 157.0, 247.0, 337.0]:
	set(value):
		parked_car_x = value
		queue_redraw()
## Lado derecho del auto, pegados a la banqueta.
@export var parked_car_y: float = 46.0:
	set(value):
		parked_car_y = value
		queue_redraw()
## Ya no se usa desde el arte v2 (los autos de npc_cars.png vienen pintados); se queda
## para no romper escenas que lo guardaron.
@export var parked_colors: Array[Color] = [Palette.COLOR_GLASS, Palette.COLOR_GOLD, Palette.COLOR_GREEN, Palette.COLOR_SKY_MID, Palette.COLOR_WHITE]:
	set(value):
		parked_colors = value
		queue_redraw()
## Velocidad (px/s) por debajo de la cual el auto cuenta como detenido.
@export var stop_speed: float = 10.0
@export var points: int = 10

@onready var _zone: Area2D = $Zone
@onready var _approach: Area2D = $Approach
@onready var _child: Pedestrian = $Child
@onready var _child_start: Marker2D = $ChildStart
@onready var _child_end: Marker2D = $ChildEnd
@onready var _child_exit: Marker2D = $ChildExit

var _state: State = State.IDLE
var _car: PlayerCar
var _car_in_approach: bool = false
var _faulted: bool = false
var _yielded: bool = false
var _ball_position: Vector2 = Vector2.ZERO
var _ball_angle: float = 0.0
var _ball_visible: bool = false
## Sube en cada reinicio para ignorar el temporizador de una pasada anterior.
var _round: int = 0


func _ready() -> void:
	_ball_position = ball_start
	_refresh()
	if Engine.is_editor_hint():
		return
	if child_frames != null:
		_child.sprite_frames = child_frames
		(_child.get_node("Sprite") as AnimatedSprite2D).sprite_frames = child_frames
	_child.walk_speed = child_speed
	_child.reset_at(_child_start.position)
	_child.hide()
	_zone.area_entered.connect(_on_zone_entered)
	_approach.area_entered.connect(_on_approach_entered)
	_approach.area_exited.connect(_on_approach_exited)
	_child.arrived.connect(_on_child_arrived)


## La pelota o la niña están en la calle.
func is_occupied() -> bool:
	return _state == State.BALL or _state == State.CHILD


func get_state() -> State:
	return _state


func is_ball_visible() -> bool:
	return _ball_visible


func is_child_visible() -> bool:
	return _child.visible


# --- Conductor cuidadoso (tests/test_levels.gd) ---

## x del nivel donde el conductor cuidadoso se detiene si la calle está ocupada.
func careful_stop_x() -> float:
	return global_position.x - crossing_width / 2.0 - fault_margin - 40.0


func must_wait() -> bool:
	return is_occupied()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _ball_visible and _state != State.IDLE:
		var before := _ball_position
		_ball_position = _ball_position.move_toward(ball_end, ball_speed * delta)
		if not before.is_equal_approx(_ball_position):
			_ball_angle += TAU * ball_spin * delta
			queue_redraw()
	if _car != null and _car_in_approach and is_occupied() and not _faulted and _car.speed <= stop_speed:
		_yielded = true


func _on_approach_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null:
		return
	_car = car
	_car_in_approach = true
	if _state == State.IDLE:
		_release_ball()


func _on_approach_exited(area: Area2D) -> void:
	if _car_from(area) != null:
		_car_in_approach = false


func _release_ball() -> void:
	_state = State.BALL
	_ball_position = ball_start
	_ball_angle = 0.0
	_ball_visible = true
	queue_redraw()
	get_tree().create_timer(child_delay, false).timeout.connect(_release_child.bind(_round))


func _release_child(round_id: int) -> void:
	if round_id != _round or _state != State.BALL:
		return
	_start_child()


func _start_child() -> void:
	_state = State.CHILD
	_child.show()
	_child.walk_to(_child_end.position)


func _on_zone_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null or not is_occupied() or _faulted:
		return
	_car = car
	_faulted = true
	car.emergency_stop()
	car.add_stop_request(self)
	if _state == State.BALL:
		_start_child()
	_child.scare()
	_report_infraction(&"crosswalk", "FALTA_PELOTA", true)


func _on_child_arrived() -> void:
	match _state:
		State.CHILD:
			_state = State.CLEAR
			# Ya recogió su pelota.
			_ball_visible = false
			queue_redraw()
			if _faulted:
				if _car != null:
					_car.remove_stop_request(self)
			elif _yielded:
				_report_good_action(&"crosswalk", "BIEN_PELOTA", points)
			_child.walk_to(_child_exit.position)
		State.CLEAR:
			_state = State.GONE
			_child.fade_out()


## Todo vuelve a empezar: la pelota y la niña esperan escondidas entre los autos.
func _on_car_restarted() -> void:
	_round += 1
	if _car != null:
		_car.remove_stop_request(self)
	_state = State.IDLE
	_faulted = false
	_yielded = false
	_car_in_approach = false
	_ball_position = ball_start
	_ball_angle = 0.0
	_ball_visible = false
	_child.reset_at(_child_start.position)
	_child.hide()
	queue_redraw()


func _refresh() -> void:
	if not is_node_ready():
		return
	var half := crossing_width / 2.0
	_set_rect(_zone, Rect2(-half - fault_margin, -road_width / 2.0, crossing_width + fault_margin, road_width))
	_set_rect(_approach, Rect2(-trigger_distance, -road_width / 2.0, trigger_distance - half - fault_margin, road_width))
	queue_redraw()


func _draw() -> void:
	# Autos estacionados: uno distinto de npc_cars.png cada vez (ya vienen pintados).
	var size := NpcCar.CAR_SIZE
	for i in parked_car_x.size():
		var region := Rect2(Vector2((i * 3 + 1) % NpcCar.CAR_COLORS.size() * size.x, 0.0), size)
		draw_texture_rect_region(PARKED_CAR, Rect2(Vector2(parked_car_x[i], parked_car_y) - size / 2.0, size), region)
	if Engine.is_editor_hint():
		var half := crossing_width / 2.0
		draw_rect(Rect2(-trigger_distance, -road_width / 2.0, trigger_distance - half - fault_margin, road_width),
			Palette.COLOR_GOLD, false, 2.0)
		draw_rect(Rect2(-half - fault_margin, -road_width / 2.0, crossing_width + fault_margin, road_width),
			Palette.COLOR_ADO_RED, false, 2.0)
		_draw_ball(ball_start)
		return
	if _ball_visible:
		_draw_ball(_ball_position)


## Pelota dorada con una raya roja que gira, contorno y sombra.
func _draw_ball(at: Vector2) -> void:
	draw_circle(at + Vector2(2.0, 3.0), ball_radius, Color(Palette.COLOR_SHADOW, 0.5))
	draw_circle(at, ball_radius + 1.5, Palette.COLOR_OUTLINE)
	draw_circle(at, ball_radius, Palette.COLOR_GOLD)
	var stripe := Vector2.from_angle(_ball_angle) * ball_radius
	draw_line(at - stripe, at + stripe, Palette.COLOR_ADO_RED, 3.0)
