@tool
class_name YellowCrossing
extends RulePiece
## Cruce con semáforo que se pone en amarillo cuando llega el auto (nivel 5).
## Un TrafficLight normal cambia con su propio reloj y el niño podría no ver
## nunca el amarillo; este cruce lo garantiza. El origen es la línea de alto y
## el auto llega desde -x. La calle que cruza va de x = line_gap a
## line_gap + cross_width.
## - El semáforo hijo (Light) no cambia solo: esta pieza lo pone en amarillo al
##   entrar el auto a Trigger, en rojo tras yellow_time y otra vez en verde
##   cuando pasó red_time, ya cruzaron los autos y el cruce está libre.
## - Las faltas (yellow y red_light) las sigue marcando el TrafficLight hijo.
##   Esta pieza no evalúa el amarillo; solo lo pone a tiempo.
## - Si el auto se detuvo antes de la línea y cruza con verde sin faltas, da puntos.
## - En rojo cruzan autos por la otra calle (menos en modo peque). Nunca hay
##   choque: si el auto del jugador llega al cruce ocupado, se detiene solo;
##   si ya va entrando, los autos que cruzan lo esperan.

enum State { ARMED, YELLOW, RED, GREEN_DONE }

const NPC_SCENE := preload("res://scenes/actors/npc_car.tscn")
const NPC_COLORS: Array[Color] = [Palette.COLOR_GLASS, Palette.COLOR_GOLD, Palette.COLOR_GREEN, Palette.COLOR_SKY_MID, Palette.COLOR_WHITE]

@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()
## Distancia antes de la línea donde la luz pasa a amarillo.
@export var trigger_distance: float = 420.0:
	set(value):
		trigger_distance = value
		_refresh()
## Segundos en amarillo (largo, para que dé tiempo de frenar).
@export var yellow_time: float = 3.0
## Mínimo de segundos en rojo. El verde llega cuando además el cruce está libre.
@export var red_time: float = 4.0
## De la línea a la orilla de la calle que cruza.
@export var line_gap: float = 24.0:
	set(value):
		line_gap = value
		_refresh()
@export var cross_width: float = 128.0:
	set(value):
		cross_width = value
		_refresh()
## Cuánto se dibuja la calle que cruza hacia cada lado.
@export var cross_length: float = 700.0:
	set(value):
		cross_length = value
		queue_redraw()
@export var stop_speed: float = 10.0
@export var points: int = 10
@export_group("Tráfico")
@export var cross_car_speed: float = 160.0
## A qué distancia del centro de la calle aparecen (y desaparecen) los autos que cruzan.
@export var spawn_distance: float = 420.0
## Segundos después de que se pone el rojo.
@export var first_spawn_delay: float = 0.5
## Segundos entre autos del mismo rojo.
@export var spawn_spacing: float = 1.2
@export var cars_per_red_grande: int = 2
@export var cars_per_red_peque: int = 1
@export_group("Seguridad")
## Un auto que cruza cuenta como "en el cruce" desde esta distancia antes de la calle.
@export var busy_margin: float = 80.0
## Desde esta distancia antes de la línea el auto del jugador "va entrando" al cruce.
@export var guard_distance: float = 64.0:
	set(value):
		guard_distance = value
		_refresh()
## Conductor cuidadoso: cuánto antes de la zona del amarillo se detiene.
@export var careful_gap: float = 60.0

@onready var _light: TrafficLight = $Light
@onready var _trigger: Area2D = $Trigger
@onready var _line: Area2D = $Line
@onready var _box: Area2D = $Box
@onready var _guard: Area2D = $Guard

var _state: State = State.ARMED
var _car: PlayerCar
var _car_in_trigger: bool = false
var _car_in_line: bool = false
var _car_in_box: bool = false
var _car_in_guard: bool = false
var _holding_car: bool = false
var _timer: float = 0.0
var _spawn_timer: float = 0.0
var _spawned: int = 0
var _next_lane: int = 0
var _waited: bool = false
var _faulted: bool = false
var _rewarded: bool = false
var _paths: Array[Path2D] = []


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	_light.set_light(TrafficLight.Light.GREEN)
	_light.light_changed.connect(func(_value: TrafficLight.Light) -> void: queue_redraw())
	_trigger.area_entered.connect(_on_trigger_entered)
	_trigger.area_exited.connect(func(area: Area2D) -> void:
		if _car_from(area) != null:
			_car_in_trigger = false)
	_line.area_entered.connect(_on_line_entered)
	_line.area_exited.connect(func(area: Area2D) -> void:
		if _car_from(area) != null:
			_car_in_line = false)
	_box.area_entered.connect(func(area: Area2D) -> void:
		if _car_from(area) != null:
			_car_in_box = true)
	_box.area_exited.connect(func(area: Area2D) -> void:
		if _car_from(area) != null:
			_car_in_box = false)
	_guard.area_entered.connect(func(area: Area2D) -> void:
		var car := _car_from(area)
		if car != null:
			_car = car
			_car_in_guard = true)
	_guard.area_exited.connect(func(area: Area2D) -> void:
		if _car_from(area) != null:
			_car_in_guard = false)
	_build_traffic_paths()


func _connect_rule_manager() -> void:
	super()
	var manager := _rule_manager()
	if manager != null and not manager.infraction_reported.is_connected(_on_infraction_reported):
		manager.infraction_reported.connect(_on_infraction_reported)


func get_state() -> State:
	return _state


func get_light() -> TrafficLight:
	return _light


## Hay un auto de la otra calle dentro del cruce o a punto de entrar.
func is_busy() -> bool:
	for npc in get_cross_cars():
		if _in_busy_rect(npc):
			return true
	return false


func get_cross_cars() -> Array[NpcCar]:
	var cars: Array[NpcCar] = []
	for path in _paths:
		for child in path.get_children():
			if child is NpcCar and not child.is_queued_for_deletion():
				cars.append(child as NpcCar)
	return cars


func cars_per_red() -> int:
	return cars_per_red_peque if GameState.mode == GameState.MODE_PEQUE else cars_per_red_grande


# --- Conductor cuidadoso (tests/test_levels.gd) ---

## Se detiene antes de la zona del amarillo: así nunca "deja avanzar" el auto en amarillo.
func careful_stop_x() -> float:
	return global_position.x - _light.zone_length - careful_gap


func must_wait() -> bool:
	return _light.light != TrafficLight.Light.GREEN or is_busy()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	match _state:
		State.YELLOW:
			_timer += delta
			if _timer >= yellow_time:
				_state = State.RED
				_timer = 0.0
				_spawned = 0
				_spawn_timer = first_spawn_delay
				_light.set_light(TrafficLight.Light.RED)
		State.RED:
			_timer += delta
			if _spawned < cars_per_red():
				_spawn_timer -= delta
				if _spawn_timer <= 0.0 and not _car_in_box:
					spawn_car(_next_lane)
					_next_lane = (_next_lane + 1) % _paths.size()
					_spawned += 1
					_spawn_timer = spawn_spacing
			elif _timer >= red_time and not is_busy():
				_state = State.GREEN_DONE
				_light.set_light(TrafficLight.Light.GREEN)
	if (_state == State.YELLOW or _state == State.RED) and _car_in_trigger and _car.speed <= stop_speed:
		_waited = true
	_update_safety()


## Nunca hay choque: el auto que va entrando al cruce ocupado se detiene, y los
## autos que cruzan esperan al que ya va entrando.
func _update_safety() -> void:
	if _car == null:
		return
	var busy := is_busy()
	var hold := _car_in_guard and busy and not _car_in_box
	if hold and not _holding_car:
		_holding_car = true
		_car.add_stop_request(self)
	elif not hold and _holding_car:
		_holding_car = false
		_car.remove_stop_request(self)
	var car_entering := _car_in_box or (_car_in_guard and _car.speed > stop_speed)
	for npc in get_cross_cars():
		if car_entering and not _in_busy_rect(npc):
			npc.add_stop_request(self)
		else:
			npc.remove_stop_request(self)


func _on_trigger_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null:
		return
	_car = car
	_car_in_trigger = true
	if _state == State.ARMED:
		_state = State.YELLOW
		_timer = 0.0
		_light.set_light(TrafficLight.Light.YELLOW)


func _on_line_entered(area: Area2D) -> void:
	if _car_from(area) == null:
		return
	_car_in_line = true
	if _light.light == TrafficLight.Light.GREEN and _waited and not _faulted and not _rewarded:
		_rewarded = true
		_report_good_action(&"yellow", "BIEN_AMARILLO", points)


func _on_infraction_reported(rule_id: StringName, _grave: bool) -> void:
	if _state == State.ARMED or not (rule_id == &"yellow" or rule_id == &"red_light"):
		return
	if _car_in_trigger or _car_in_line:
		_faulted = true


## El cruce vuelve a esperar al auto: luz en verde y sin autos cruzando.
func _on_car_restarted() -> void:
	for npc in get_cross_cars():
		npc.queue_free()
	if _car != null:
		_car.remove_stop_request(self)
	_holding_car = false
	_state = State.ARMED
	_timer = 0.0
	_spawn_timer = 0.0
	_spawned = 0
	_waited = false
	_faulted = false
	_rewarded = false
	_light.set_light(TrafficLight.Light.GREEN)


# --- Tráfico ---

func _cross_center() -> float:
	return line_gap + cross_width / 2.0


## Se maneja por la derecha: hacia +y del lado izquierdo de la calle y hacia -y del derecho.
func _build_traffic_paths() -> void:
	for direction: int in [1, -1]:
		var path := Path2D.new()
		var curve := Curve2D.new()
		var x := _cross_center() - cross_width / 4.0 * direction
		curve.add_point(Vector2(x, -spawn_distance * direction))
		curve.add_point(Vector2(x, spawn_distance * direction))
		path.curve = curve
		add_child(path)
		_paths.append(path)


## Pone un auto en un carril de la calle que cruza (0: baja hacia +y, 1: sube).
func spawn_car(lane: int) -> NpcCar:
	var npc := NPC_SCENE.instantiate() as NpcCar
	npc.cruise_speed = cross_car_speed
	npc.body_color = NPC_COLORS[randi() % NPC_COLORS.size()]
	_paths[lane].add_child(npc)
	npc.progress = 0.0
	return npc


func _in_busy_rect(npc: NpcCar) -> bool:
	var rect := Rect2(line_gap, -road_width / 2.0 - busy_margin, cross_width, road_width + busy_margin * 2.0)
	return rect.has_point(to_local(npc.global_position))


# --- Formas y dibujo ---

func _refresh() -> void:
	if not is_node_ready():
		return
	var half := road_width / 2.0
	_set_rect(_trigger, Rect2(-trigger_distance, -half, trigger_distance, road_width))
	_set_rect(_line, Rect2(-8.0, -half, 8.0, road_width))
	_set_rect(_box, Rect2(line_gap, -half, cross_width, road_width))
	_set_rect(_guard, Rect2(-guard_distance, -half, guard_distance + line_gap + cross_width, road_width))
	queue_redraw()


## Calle que cruza con banquetas, guarniciones y raya al centro (como en BlindCrossing).
func _draw() -> void:
	var cx := _cross_center()
	var half := cross_width / 2.0
	var walk := 64.0
	draw_rect(Rect2(cx - half - walk, -cross_length, cross_width + walk * 2.0, cross_length * 2.0), Palette.COLOR_SIDEWALK)
	draw_rect(Rect2(cx - half, -cross_length, cross_width, cross_length * 2.0), Palette.COLOR_ASPHALT)
	draw_rect(Rect2(cx - half - walk, -road_width / 2.0, cross_width + walk * 2.0, road_width), Palette.COLOR_ASPHALT)
	for side: float in [-1.0, 1.0]:
		for y_sign: float in [-1.0, 1.0]:
			var x := cx + half * side
			draw_line(Vector2(x, road_width / 2.0 * y_sign), Vector2(x, cross_length * y_sign), Palette.COLOR_WHITE, 4.0)
	var y := road_width / 2.0 + 12.0
	while y < cross_length:
		for y_sign: float in [-1.0, 1.0]:
			draw_line(Vector2(cx, y * y_sign), Vector2(cx, (y + 24.0) * y_sign), Palette.COLOR_WHITE, 4.0)
		y += 48.0
	if Engine.is_editor_hint():
		draw_rect(Rect2(-trigger_distance, -road_width / 2.0, trigger_distance, road_width), Palette.COLOR_GOLD, false, 2.0)
