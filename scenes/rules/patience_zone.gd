@tool
class_name PatienceZone
extends RulePiece
## Cruce con semáforo y gente que necesita más tiempo (nivel 4). El origen es el
## centro de la cebra y el auto llega desde -x (gira el nodo para otras direcciones).
## - Cuando el auto se acerca, la luz de peatones se pone verde y el grupo empieza a cruzar despacio.
## - A los green_after segundos el semáforo de autos se pone en verde, aunque
##   todavía haya gente en el cruce: esa es la prueba de paciencia.
## - Si el auto pasa la línea del semáforo mientras alguien cruza: falta "patience"
##   (no grave) y se queda quieto hasta que termine de cruzar.
## - Si entra a la cebra ocupada: frena solo, la gente se asusta y es falta grave (crosswalk).
## - Si esperó hasta que todos terminaron de cruzar, da puntos.
## El semáforo de autos (hijo Light) no cambia solo: lo cambia esta pieza.

enum State { IDLE, CROSSING }

const PEDESTRIAN := preload("res://scenes/actors/pedestrian.tscn")
const PED_LIGHT := preload("res://assets/sprites/signals/pedestrian_light.png")
## Cuadros de la luz de peatones (129 × 104): apagado, rojo y verde.
const PED_LIGHT_FRAME := Vector2(43, 104)
enum PedLight { OFF, RED, GREEN }

@export var crosswalk_width: float = 64.0:
	set(value):
		crosswalk_width = value
		_refresh()
@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()
## Distancia entre la línea del semáforo y la orilla de la cebra.
@export var light_gap: float = 56.0:
	set(value):
		light_gap = value
		_refresh()
## Zona antes de la línea donde el auto hace que la gente empiece a cruzar.
@export var approach_length: float = 448.0:
	set(value):
		approach_length = value
		_refresh()
## Distancia antes de la cebra donde el auto ya cuenta como que entró (y frena solo).
@export var fault_margin: float = 16.0:
	set(value):
		fault_margin = value
		_refresh()
@export var line_width: float = 8.0
## Segundos desde que empiezan a cruzar hasta que el semáforo de autos se pone en verde.
@export var green_after: float = 3.0
## Segundos entre que el auto se acerca y la gente empieza a cruzar.
@export var start_delay: float = 0.3
## Quién cruza, una persona por cuadro de animación. Caminan juntas, en grupo.
@export var walkers: Array[SpriteFrames] = []
## Velocidad de caminata en px/s: más lenta que la de un peatón normal.
@export var walk_speed: float = 30.0
@export var walker_spacing: float = 18.0
@export var stop_speed: float = 10.0
@export var points: int = 10
@export var stripe_height: float = 14.0
@export var stripe_gap: float = 10.0

@onready var _zone: Area2D = $Zone
@onready var _approach: Area2D = $Approach
@onready var _line: Area2D = $Line
@onready var _light: TrafficLight = $Light
@onready var _start: Marker2D = $Start
@onready var _end: Marker2D = $End
@onready var _exit: Marker2D = $Exit

var _state: State = State.IDLE
var _pedestrians: Array[Pedestrian] = []
## Quiénes ya llegaron al otro lado (dejan de estorbar y se van por la banqueta).
var _crossed: Array[Pedestrian] = []
## Cuántas personas faltan por llegar al otro lado de la calle.
var _remaining: int = 0
var _car: PlayerCar
var _car_in_approach: bool = false
var _idle_time: float = 0.0
var _crossing_time: float = 0.0
var _waited: bool = false
var _faulted_patience: bool = false
var _faulted_grave: bool = false


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	_light.light_changed.connect(_on_light_changed)
	_zone.area_entered.connect(_on_zone_entered)
	_approach.area_entered.connect(_on_approach_entered)
	_approach.area_exited.connect(_on_approach_exited)
	_line.area_entered.connect(_on_line_entered)
	_spawn_walkers()


## Hay gente que todavía no termina de cruzar (o espera en la banqueta para hacerlo).
func is_occupied() -> bool:
	return _remaining > 0


## El semáforo de autos ya está en verde pero la gente sigue cruzando.
func is_trap() -> bool:
	return _light.light == TrafficLight.Light.GREEN and is_occupied()


## Se puede pasar: luz verde y nadie cruzando.
func can_go() -> bool:
	return _light.light == TrafficLight.Light.GREEN and not is_occupied()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	match _state:
		State.IDLE:
			if _car_in_approach:
				_idle_time += delta
				if _idle_time >= start_delay:
					_start_crossing()
		State.CROSSING:
			_crossing_time += delta
			if _crossing_time >= green_after and _light.light == TrafficLight.Light.RED:
				_light.set_light(TrafficLight.Light.GREEN)
	if _car_in_approach and is_trap() and not _faulted_patience and _car.speed <= stop_speed:
		_waited = true


func _start_crossing() -> void:
	_state = State.CROSSING
	_crossing_time = 0.0
	for i in _pedestrians.size():
		_pedestrians[i].walk_to(Vector2(_walker_start(i).x, _end.position.y))
	queue_redraw()


func _spawn_walkers() -> void:
	for i in walkers.size():
		var pedestrian := PEDESTRIAN.instantiate() as Pedestrian
		pedestrian.sprite_frames = walkers[i]
		pedestrian.walk_speed = walk_speed
		pedestrian.z_index = 1
		add_child(pedestrian)
		pedestrian.position = _walker_start(i)
		pedestrian.arrived.connect(_on_pedestrian_arrived.bind(pedestrian))
		_pedestrians.append(pedestrian)
	_remaining = _pedestrians.size()


## Cada persona espera en su lugar del grupo, centrado sobre la cebra.
func _walker_start(index: int) -> Vector2:
	var offset := (index - (walkers.size() - 1) / 2.0) * walker_spacing
	return _start.position + Vector2(offset, 0.0)


func _on_approach_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null:
		return
	_car = car
	_car_in_approach = true


func _on_approach_exited(area: Area2D) -> void:
	if _car_from(area) != null:
		_car_in_approach = false


## El auto pasó la línea del semáforo con gente todavía cruzando, aunque la luz esté en verde.
func _on_line_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null or not is_trap() or _faulted_patience:
		return
	_faulted_patience = true
	car.add_stop_request(self)
	_report_infraction(&"patience", "FALTA_PACIENCIA")


func _on_zone_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null or not is_occupied() or _faulted_grave:
		return
	_faulted_grave = true
	car.emergency_stop()
	car.add_stop_request(self)
	for pedestrian in _pedestrians:
		pedestrian.scare()
	_report_infraction(&"crosswalk", "FALTA_PEATON", true)


func _on_pedestrian_arrived(pedestrian: Pedestrian) -> void:
	if pedestrian in _crossed:
		pedestrian.fade_out()
		return
	_crossed.append(pedestrian)
	_remaining -= 1
	pedestrian.walk_to(Vector2(pedestrian.position.x, _exit.position.y))
	if _remaining == 0:
		_on_everyone_crossed()


func _on_everyone_crossed() -> void:
	if _car != null:
		_car.remove_stop_request(self)
	# Si la luz seguía en rojo (el auto no esperó el verde), no había nada que esperar.
	if _light.light == TrafficLight.Light.GREEN and _waited and not _faulted_patience and not _faulted_grave:
		_report_good_action(&"patience", "BIEN_PACIENCIA", points)
	queue_redraw()


func _on_light_changed(_light_value: TrafficLight.Light) -> void:
	queue_redraw()


## Todo vuelve a empezar: la gente espera en la banqueta y la luz está en rojo.
func _on_car_restarted() -> void:
	if _car != null:
		_car.remove_stop_request(self)
	_state = State.IDLE
	_idle_time = 0.0
	_crossing_time = 0.0
	_car_in_approach = false
	_waited = false
	_faulted_patience = false
	_faulted_grave = false
	_remaining = _pedestrians.size()
	_crossed.clear()
	for i in _pedestrians.size():
		_pedestrians[i].reset_at(_walker_start(i))
	_light.set_light(TrafficLight.Light.RED)
	queue_redraw()


func _ped_light_state() -> PedLight:
	if _state == State.CROSSING and _light.light == TrafficLight.Light.RED:
		return PedLight.GREEN
	return PedLight.RED


func _refresh() -> void:
	if not is_node_ready():
		return
	var half := Vector2(crosswalk_width, road_width) / 2.0
	var line_x := -half.x - light_gap
	_set_rect(_zone, Rect2(-half.x - fault_margin, -half.y, crosswalk_width + fault_margin, road_width))
	_set_rect(_approach, Rect2(line_x - approach_length, -half.y, approach_length, road_width))
	_set_rect(_line, Rect2(line_x - line_width, -half.y, line_width, road_width))
	($Light as Node2D).position = Vector2(line_x, 0.0)
	queue_redraw()


## Cebra (barras paralelas al tráfico) y las luces de peatones a cada lado de la calle.
func _draw() -> void:
	draw_rect(Rect2(-crosswalk_width / 2.0 - 4.0, -road_width / 2.0, crosswalk_width + 8.0, road_width), Palette.COLOR_ASPHALT)
	var y := -road_width / 2.0 + stripe_gap / 2.0
	while y + stripe_height <= road_width / 2.0:
		draw_rect(Rect2(-crosswalk_width / 2.0, y, crosswalk_width, stripe_height), Palette.COLOR_WHITE)
		y += stripe_height + stripe_gap
	if Engine.is_editor_hint():
		draw_rect(Rect2(-crosswalk_width / 2.0 - light_gap - approach_length, -road_width / 2.0, approach_length, road_width),
			Palette.COLOR_GOLD, false, 2.0)
		return
	# Las luces de peatones siempre se dibujan derechas, aunque el nodo esté girado.
	var frame_index := int(_ped_light_state())
	var region := Rect2(PED_LIGHT_FRAME.x * frame_index, 0.0, PED_LIGHT_FRAME.x, PED_LIGHT_FRAME.y)
	var light_size := PED_LIGHT_FRAME
	for side: float in [-1.0, 1.0]:
		# Una a cada lado de la calle, siempre fuera del asfalto.
		var top := -(road_width / 2.0 + 20.0) - light_size.y if side < 0.0 else road_width / 2.0 + 20.0
		draw_set_transform(Vector2(-crosswalk_width / 2.0 - 24.0, top), -global_rotation)
		draw_texture_rect_region(PED_LIGHT, Rect2(-light_size.x / 2.0, 0.0, light_size.x, light_size.y), region)
	draw_set_transform(Vector2.ZERO)
