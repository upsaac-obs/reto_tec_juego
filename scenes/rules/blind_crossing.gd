@tool
class_name BlindCrossing
extends RulePiece
## Cruce sin vista (nivel 3). Una calle atraviesa la ruta del auto; sobre ella,
## un poco antes de la esquina, hay portales (techos de arcos, como en el centro
## de Puebla) que tapan los autos que vienen hasta que ya están cerca.
## El origen es el centro del cruce y el auto llega desde -x (gira el nodo para
## otras direcciones).
## - Antes del cruce hay dos ojos pintados (la marca de "mira"). Falta (look) si
##   el auto llega al cruce sin haberse detenido en la marca.
## - Falta (look) si arrancó de los ojos cuando un auto que ya se veía venía
##   hacia el cruce o estaba dentro. Si el auto apareció después de que arrancó,
##   no es falta. En los dos casos, si al llegar al cruce está ocupado, el auto
##   del jugador frena solo y espera; nunca choca. Los autos todavía tapados por
##   los portales no cuentan.
## - Si se detuvo y cruzó con el cruce libre, da puntos.
## - Genera tráfico en la calle que cruza (menos en modo peque).

const NPC_SCENE := preload("res://scenes/actors/npc_car.tscn")
const NPC_COLORS: Array[Color] = [Palette.COLOR_GLASS, Palette.COLOR_GOLD, Palette.COLOR_GREEN, Palette.COLOR_SKY_MID, Palette.COLOR_WHITE]

@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()
@export var cross_width: float = 128.0:
	set(value):
		cross_width = value
		_refresh()
## Qué tan lejos se dibuja la calle que cruza, hacia cada lado.
@export var cross_length: float = 900.0:
	set(value):
		cross_length = value
		_refresh()
## Distancia del centro del cruce a donde empiezan los portales.
@export var portal_start: float = 190.0:
	set(value):
		portal_start = value
		_refresh()
@export var portal_length: float = 360.0:
	set(value):
		portal_length = value
		_refresh()
## Largo de la zona antes del cruce donde cuenta detenerse (los ojos).
@export var look_length: float = 160.0:
	set(value):
		look_length = value
		_refresh()
@export var stop_speed: float = 10.0
@export var points: int = 10
@export_group("Tráfico")
@export var traffic: bool = true
@export var npc_speed: float = 110.0
@export var spawn_interval_min: float = 2.5
@export var spawn_interval_max: float = 5.0
## En modo peque hay menos tráfico: los intervalos se multiplican por esto.
@export var peque_traffic_factor: float = 1.8

@onready var _look: Area2D = $Look
@onready var _entry: Area2D = $Entry
@onready var _danger: Area2D = $Danger
@onready var _roofs: Node2D = $Roofs

var _car: PlayerCar
var _in_look: bool = false
## Se detuvo en los ojos en esta pasada.
var _looked: bool = false
## Si el cruce estaba libre la última vez que estuvo detenido en los ojos.
var _clear_when_stopped: bool = true
var _evaluated: bool = false
var _holding: bool = false
var _busy: Array[Area2D] = []
var _paths: Array[Path2D] = []
var _spawn_left: float = 1.0


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	_look.area_entered.connect(_on_look_entered)
	_look.area_exited.connect(func(area: Area2D) -> void:
		if _car_from(area) != null:
			_in_look = false)
	_entry.area_entered.connect(_on_entry_entered)
	_entry.area_exited.connect(_on_entry_exited)
	_danger.area_entered.connect(func(area: Area2D) -> void:
		if area.is_in_group(&"traffic"):
			_busy.append(area))
	_danger.area_exited.connect(func(area: Area2D) -> void: _busy.erase(area))
	_build_traffic_paths()


## true si un auto que ya se ve viene hacia el cruce o está dentro.
func is_busy() -> bool:
	return not _busy.is_empty()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _car != null and _in_look and not _evaluated and _car.speed <= stop_speed:
		_looked = true
		_clear_when_stopped = not is_busy()
	if _holding and not is_busy():
		_holding = false
		_car.remove_stop_request(self)
	if traffic:
		_spawn_left -= delta
		if _spawn_left <= 0.0:
			_spawn()


func _on_look_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null or _evaluated:
		return
	_car = car
	_in_look = true


func _on_entry_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null or _evaluated:
		return
	_car = car
	_evaluated = true
	if is_busy():
		# Frena solo y espera a que se libere; nunca entra con un auto en el cruce.
		car.emergency_stop()
		car.add_stop_request(self)
		_holding = true
	if not _looked:
		_report_infraction(&"look", "FALTA_MIRA")
	elif not _clear_when_stopped:
		_report_infraction(&"look", "FALTA_MIRA_OCUPADO")
	elif not _holding:
		_report_good_action(&"look", "BIEN_MIRA", points)


## Cuando el auto ya cruzó, se prepara para otra pasada (punto de control).
func _on_entry_exited(area: Area2D) -> void:
	if _car_from(area) == null or _holding:
		return
	_evaluated = false
	_looked = false
	_clear_when_stopped = true


func _on_car_restarted() -> void:
	if _holding and _car != null:
		_car.remove_stop_request(self)
	_holding = false
	_evaluated = false
	_looked = false
	_clear_when_stopped = true
	_in_look = false
	_car = null


# --- Tráfico ---

## Se maneja por la derecha: hacia +y por el carril x < 0 y hacia -y por x > 0.
func _build_traffic_paths() -> void:
	for direction: int in [1, -1]:
		var path := Path2D.new()
		var curve := Curve2D.new()
		var x := -cross_width / 4.0 * direction
		curve.add_point(Vector2(x, -cross_length * direction))
		curve.add_point(Vector2(x, cross_length * direction))
		path.curve = curve
		add_child(path)
		_paths.append(path)


func _spawn() -> void:
	var factor := peque_traffic_factor if GameState.mode == GameState.MODE_PEQUE else 1.0
	_spawn_left = randf_range(spawn_interval_min, spawn_interval_max) * factor
	spawn_car(randi() % _paths.size())


## Pone un auto en un carril de la calle que cruza (0: baja hacia +y, 1: sube).
## Devuelve null si acaba de salir otro auto por ese carril.
func spawn_car(lane: int, start_progress := 0.0) -> NpcCar:
	var path := _paths[lane]
	for child in path.get_children():
		if child is NpcCar and absf((child as NpcCar).progress - start_progress) < 120.0:
			return null
	var npc := NPC_SCENE.instantiate() as NpcCar
	npc.cruise_speed = npc_speed
	npc.body_color = NPC_COLORS[randi() % NPC_COLORS.size()]
	path.add_child(npc)
	npc.progress = start_progress
	return npc


# --- Formas y dibujo ---

func _refresh() -> void:
	if not is_node_ready():
		return
	var half := cross_width / 2.0
	_set_rect(_look, Rect2(-half - look_length, -road_width / 2.0, look_length, road_width))
	_set_rect(_entry, Rect2(-half - 8.0, -road_width / 2.0, 8.0, road_width))
	# Peligro: el cruce y los tramos visibles de cada carril que viene hacia él.
	var shapes := _danger.get_children()
	_set_shape(shapes[0], Rect2(-half, -road_width / 2.0, cross_width, road_width))
	_set_shape(shapes[1], Rect2(-half, -portal_start, half, portal_start - road_width / 2.0))
	_set_shape(shapes[2], Rect2(0.0, road_width / 2.0, half, portal_start - road_width / 2.0))
	_roofs.queue_redraw()
	queue_redraw()


func _set_shape(shape_node: CollisionShape2D, rect: Rect2) -> void:
	(shape_node.shape as RectangleShape2D).size = rect.size
	shape_node.position = rect.get_center()


func _draw() -> void:
	var half := cross_width / 2.0
	var walk := 64.0
	# Banquetas y calle que cruza (encima de los tiles de la calle principal).
	draw_rect(Rect2(-half - walk, -cross_length, cross_width + walk * 2.0, cross_length * 2.0), Palette.COLOR_SIDEWALK)
	draw_rect(Rect2(-half, -cross_length, cross_width, cross_length * 2.0), Palette.COLOR_ASPHALT)
	# La banqueta de la calle que cruza no tapa la calle principal.
	draw_rect(Rect2(-half - walk, -road_width / 2.0, cross_width + walk * 2.0, road_width), Palette.COLOR_ASPHALT)
	# Guarniciones de la calle que cruza (sin cortar la calle principal).
	for side: float in [-1.0, 1.0]:
		for y_sign: float in [-1.0, 1.0]:
			var y0 := road_width / 2.0 * y_sign
			var y1 := cross_length * y_sign
			var x := half * side
			draw_line(Vector2(x, y0), Vector2(x, y1), Palette.COLOR_WHITE, 4.0)
	# Raya punteada al centro de la calle que cruza.
	var y := road_width / 2.0 + 12.0
	while y < cross_length:
		for y_sign: float in [-1.0, 1.0]:
			draw_line(Vector2(0.0, y * y_sign), Vector2(0.0, (y + 24.0) * y_sign), Palette.COLOR_WHITE, 4.0)
		y += 48.0
	# Línea de "mira" punteada y los ojos pintados antes del cruce.
	var line_x := -half - 8.0
	var dash := -road_width / 2.0
	while dash < road_width / 2.0:
		draw_rect(Rect2(line_x, dash, 8.0, 12.0), Palette.COLOR_WHITE)
		dash += 20.0
	_draw_eyes(Vector2(-half - look_length / 2.0, 0.0))
	if Engine.is_editor_hint():
		draw_rect(Rect2(-half - look_length, -road_width / 2.0, look_length, road_width), Palette.COLOR_GOLD, false, 2.0)


## Dos ojos grandes pintados en el piso, mirando a los lados.
func _draw_eyes(center: Vector2) -> void:
	for y_sign: float in [-1.0, 1.0]:
		var eye := center + Vector2(0.0, 22.0 * y_sign)
		draw_circle(eye, 17.0, Palette.COLOR_OUTLINE)
		draw_circle(eye, 15.0, Palette.COLOR_WHITE)
		draw_circle(eye + Vector2(0.0, 7.0 * y_sign), 7.0, Palette.COLOR_OUTLINE)
		draw_circle(eye + Vector2(-2.0, 4.0 * y_sign), 2.0, Palette.COLOR_WHITE)
