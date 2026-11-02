extends Path2D
## Tráfico del carril izquierdo del nivel 6 (no es una pieza de regla: no da
## faltas ni puntos). Mientras el niño contesta estacionado, los autos pasan a
## su lado: el cajón es el lugar seguro para usar el celular.
## - Genera autos (NpcCar) cuando el jugador está entre activate_x y stop_x.
## - Empieza después del semáforo: NpcCar no respeta semáforos.
## - Aparecen detrás del auto, fuera de la pantalla, y se borran si se quedan lejos.
## - En modo peque sale menos tráfico (intervalos × peque_traffic_factor).

const NPC_SCENE := preload("res://scenes/actors/npc_car.tscn")
const Palette := preload("res://autoload/game_state.gd")
const NPC_COLORS: Array[Color] = [Palette.COLOR_GLASS, Palette.COLOR_GOLD, Palette.COLOR_GREEN, Palette.COLOR_SKY_MID, Palette.COLOR_WHITE]

## Inicio y fin del carril izquierdo (coordenadas del nivel, hacia +x).
@export var start_point: Vector2 = Vector2(5100.0, -32.0)
@export var end_point: Vector2 = Vector2(8900.0, -32.0)
## Empieza a generar cuando el auto del jugador pasa este x.
@export var activate_x: float = 5600.0
## Deja de generar después de este x.
@export var stop_x: float = 7400.0
## px/s: más lento que los 120 px/s de la zona de 30 km/h.
@export var npc_speed: float = 100.0
@export var interval_min: float = 4.0
@export var interval_max: float = 6.0
## Modo peque: los intervalos se multiplican por esto (menos tráfico).
@export var peque_traffic_factor: float = 1.8
## Qué tan atrás del auto aparece cada auto del tráfico (fuera de la pantalla).
@export var spawn_behind: float = 520.0
## Se borra si queda más de esto detrás del auto del jugador.
@export var despawn_behind: float = 1500.0

var _car: PlayerCar
var _spawn_left: float = 0.0


func _ready() -> void:
	var line := Curve2D.new()
	line.add_point(to_local(start_point))
	line.add_point(to_local(end_point))
	curve = line
	_find_car.call_deferred()


func _find_car() -> void:
	var manager := get_tree().get_first_node_in_group(&"rule_manager") as RuleManager
	if manager != null:
		_car = manager.car


func _physics_process(delta: float) -> void:
	if _car == null:
		return
	var car_x := _car.global_position.x
	_forget_far_cars(car_x)
	if car_x < activate_x:
		# Antes de la zona (o de regreso a un punto de control): el primero sale enseguida.
		_spawn_left = 0.0
		return
	if car_x > stop_x:
		return
	_spawn_left -= delta
	if _spawn_left <= 0.0:
		var factor := peque_traffic_factor if GameState.mode == GameState.MODE_PEQUE else 1.0
		_spawn_left = randf_range(interval_min, interval_max) * factor
		_spawn(maxf(car_x - spawn_behind, start_point.x))


func _spawn(x: float) -> void:
	var at := curve.get_closest_offset(to_local(Vector2(x, start_point.y)))
	for child in get_children():
		if child is NpcCar and absf((child as NpcCar).progress - at) < 120.0:
			return
	var npc := NPC_SCENE.instantiate() as NpcCar
	npc.cruise_speed = npc_speed
	npc.body_color = NPC_COLORS[randi() % NPC_COLORS.size()]
	add_child(npc)
	npc.progress = at


func _forget_far_cars(car_x: float) -> void:
	for child in get_children():
		var npc := child as NpcCar
		if npc != null and npc.global_position.x < car_x - despawn_behind:
			npc.queue_free()
