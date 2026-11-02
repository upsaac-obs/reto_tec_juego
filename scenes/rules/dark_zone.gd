@tool
class_name DarkZone
extends RulePiece
## Tramo oscuro (nivel 7): atardecer, túnel o lluvia. El origen es el inicio del
## tramo sobre el centro de la calle y el auto avanza hacia +x.
## - Falta (lights) si el auto pasa más de grace_time seguidos dentro con las
##   luces apagadas. Como máximo una falta por pasada.
## - +10 (lights) si lleva las luces prendidas confirm_time seguidos sin haber
##   tenido falta. Como máximo uno por pasada.
## La oscuridad es una sombra en el mundo (3 Polygon2D, sin shaders) que queda
## encima de la calle y debajo del auto. Los ciclistas del tramo van debajo de la
## sombra y solo pasan encima (se "iluminan") cuando el auto lleva las luces.
## Está en el grupo needs_headlights: el botón de luces del HUD parpadea mientras
## el auto está dentro con las luces apagadas.

enum Kind { DUSK, TUNNEL, RAIN }

const CYCLIST_SCENE := preload("res://scenes/actors/cyclist.tscn")
const MESSAGES := {
	Kind.DUSK: ["FALTA_LUCES", "BIEN_LUCES"],
	Kind.TUNNEL: ["FALTA_LUCES_TUNEL", "BIEN_LUCES_TUNEL"],
	Kind.RAIN: ["FALTA_LUCES_LLUVIA", "BIEN_LUCES_LLUVIA"],
}

## Cambia los mensajes de falta y de acierto.
@export var kind: Kind = Kind.DUSK
@export var length: float = 1000.0:
	set(value):
		length = value
		_refresh()
@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()
## Alfa de la sombra: 0 = nada, 1 = negro.
@export_range(0.0, 1.0) var darkness: float = 0.55:
	set(value):
		darkness = value
		_refresh()
## Color de la sombra; se le aplica darkness como alfa.
@export var shade_color: Color = Palette.COLOR_OUTLINE:
	set(value):
		shade_color = value
		_refresh()
## Degradado antes y después del tramo.
@export var fade_length: float = 160.0:
	set(value):
		fade_length = value
		_refresh()
## Alto de la sombra: cubre la pantalla aunque la cámara suba o baje.
@export var cover_height: float = 1600.0:
	set(value):
		cover_height = value
		_refresh()
## Segundos SEGUIDOS sin luces dentro antes de la falta.
@export var grace_time: float = 2.0
## Segundos seguidos con luces dentro para dar los puntos.
@export var confirm_time: float = 0.5
@export var points: int = 10
## Paredes de túnel a los lados de la calle.
@export var walls: bool = false:
	set(value):
		walls = value
		queue_redraw()
@export var wall_width: float = 24.0:
	set(value):
		wall_width = value
		queue_redraw()
@export var wall_color: Color = Palette.COLOR_SIDEWALK:
	set(value):
		wall_color = value
		queue_redraw()
@export var wall_edge_color: Color = Palette.COLOR_OUTLINE:
	set(value):
		wall_edge_color = value
		queue_redraw()

@export_group("Ciclistas")
## x relativas al origen donde aparecen los ciclistas al entrar el auto.
@export var cyclist_starts: PackedFloat32Array = PackedFloat32Array()
## En Peque solo salen los primeros N.
@export var peque_cyclist_count: int = 1
@export var cyclist_speed: float = 80.0
## y del carril de bici (igual al side_offset de la BikeLane).
@export var cyclist_offset: float = 32.0
## El ciclista se borra al llegar a length + cyclist_end_margin.
@export var cyclist_end_margin: float = 600.0
## Si el auto va por la ciclovía y un ciclista queda a menos de esto delante, el
## auto se detiene; si queda detrás, el ciclista espera. Nunca se tocan.
@export var safety_gap: float = 110.0
## Distancia lateral (y) a la que se considera que auto y ciclista van por el mismo carril.
@export var lateral_gap: float = 48.0
## z de Riders con luces (encima de Shade).
@export var lit_z_index: int = 1

@export_group("Reflejantes")
@export var vest_color: Color = Palette.COLOR_GOLD
@export var stripe_color: Color = Palette.COLOR_WHITE
@export var tail_light_color: Color = Palette.COLOR_ADO_RED
@export var vest_rect: Rect2 = Rect2(-6.0, -9.0, 10.0, 18.0)
@export var stripe_ys: PackedFloat32Array = PackedFloat32Array([-5.0, 3.0])
@export var stripe_height: float = 2.0
@export var tail_light_rect: Rect2 = Rect2(-29.0, -3.0, 3.0, 6.0)

@export_group("Lluvia")
@export var rain: bool = false:
	set(value):
		rain = value
		_refresh()
@export var rain_amount: int = 120:
	set(value):
		rain_amount = value
		_refresh()
## Alto de la franja donde caen gotas (la cámara ve ~720 px).
@export var rain_height: float = 800.0:
	set(value):
		rain_height = value
		_refresh()
@export var rain_color: Color = Palette.COLOR_GLASS:
	set(value):
		rain_color = value
		_refresh()
## Suena el bucle "rain" de AudioManager mientras el auto está dentro.
@export var rain_sound: bool = true

@onready var _zone: Area2D = $Zone
@onready var _riders_node: Node2D = $Riders
@onready var _fade_in: Polygon2D = $Shade/FadeIn
@onready var _body: Polygon2D = $Shade/Body
@onready var _fade_out: Polygon2D = $Shade/FadeOut
@onready var _rain: CPUParticles2D = $Rain

var _car: PlayerCar
var _off_time: float = 0.0
var _on_time: float = 0.0
var _faulted: bool = false
var _rewarded: bool = false
var _riders: Array[Cyclist] = []
var _stopping: bool = false


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	add_to_group(&"needs_headlights")
	_rain.emitting = false
	_zone.area_entered.connect(_on_zone_entered)
	_zone.area_exited.connect(_on_zone_exited)


func is_car_inside() -> bool:
	return _car != null


func are_riders_lit() -> bool:
	return _riders_node.z_index > 0


func get_riders() -> Array[Cyclist]:
	var alive: Array[Cyclist] = []
	for rider in _riders:
		if is_instance_valid(rider) and not rider.is_queued_for_deletion():
			alive.append(rider)
	_riders = alive
	return _riders


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _car != null:
		_check_lights(delta)
	_keep_riders_safe()


func _check_lights(delta: float) -> void:
	if _car.headlights_on:
		_on_time += delta
		_off_time = 0.0
		if _on_time >= confirm_time and not _faulted and not _rewarded:
			_rewarded = true
			_report_good_action(&"lights", MESSAGES[kind][1], points)
	else:
		_off_time += delta
		_on_time = 0.0
		if _off_time > grace_time and not _faulted:
			_faulted = true
			_report_infraction(&"lights", MESSAGES[kind][0])


## Nunca se toca a nadie: si el auto va por la ciclovía con un ciclista justo
## delante, el auto se detiene; si el ciclista viene justo detrás, el ciclista espera.
## No da otra falta: meterse a la ciclovía ya es falta de bike_lane.
func _keep_riders_safe() -> void:
	var riders := get_riders()
	if riders.is_empty():
		_set_stopping(false)
		return
	var car := _car if _car != null else _rule_manager_car()
	var car_pos := to_local(car.global_position) if car != null else Vector2.INF
	var stop := false
	for rider in riders:
		var dx := rider.position.x - car_pos.x
		var same_lane := absf(rider.position.y - car_pos.y) < lateral_gap
		var hold := same_lane and dx < 0.0 and dx >= -safety_gap
		rider.speed = 0.0 if hold else cyclist_speed
		if same_lane and dx >= 0.0 and dx <= safety_gap:
			stop = true
	_set_stopping(stop)


## El auto cerca de los ciclistas aunque ya salió de la zona (siguen en la ciclovía).
func _rule_manager_car() -> PlayerCar:
	var manager := _rule_manager()
	return manager.car if manager != null else null


func _set_stopping(on: bool) -> void:
	if on == _stopping:
		return
	var car := _car if _car != null else _rule_manager_car()
	if car == null:
		_stopping = false
		return
	_stopping = on
	if on:
		car.add_stop_request(self)
	else:
		car.remove_stop_request(self)


func _on_zone_entered(area: Area2D) -> void:
	var car := _car_from(area)
	if car == null:
		return
	_disconnect_car()
	_car = car
	_off_time = 0.0
	_on_time = 0.0
	_faulted = false
	_rewarded = false
	car.headlights_changed.connect(_on_headlights_changed)
	_spawn_riders()
	if rain:
		_rain.emitting = true
		if rain_sound:
			AudioManager.start_loop(&"rain")
	_update_visuals()


func _on_zone_exited(area: Area2D) -> void:
	if _car_from(area) == null or _car == null:
		return
	_leave()


## Sale del tramo: la luz regresa sola porque la sombra está en el mundo.
func _leave() -> void:
	_set_stopping(false)
	_disconnect_car()
	_car = null
	_rain.emitting = false
	if rain and rain_sound:
		AudioManager.stop_loop(&"rain")
	_update_visuals()


func _on_headlights_changed(_on: bool) -> void:
	_update_visuals()


func _update_visuals() -> void:
	var lit := _car != null and _car.headlights_on
	_riders_node.z_index = lit_z_index if lit else 0


func _on_car_restarted() -> void:
	_leave()
	_off_time = 0.0
	_on_time = 0.0
	_faulted = false
	_rewarded = false
	_clear_riders()


func _disconnect_car() -> void:
	if _car != null and _car.headlights_changed.is_connected(_on_headlights_changed):
		_car.headlights_changed.disconnect(_on_headlights_changed)


func _clear_riders() -> void:
	_set_stopping(false)
	for rider in _riders:
		if is_instance_valid(rider):
			rider.queue_free()
	_riders.clear()


func _spawn_riders() -> void:
	_clear_riders()
	var count := cyclist_starts.size()
	if GameState.mode == GameState.MODE_PEQUE:
		count = mini(count, peque_cyclist_count)
	for i in count:
		var rider := CYCLIST_SCENE.instantiate() as Cyclist
		rider.position = Vector2(cyclist_starts[i], cyclist_offset)
		rider.speed = cyclist_speed
		rider.end_x = length + cyclist_end_margin
		_add_reflectors(rider)
		_riders_node.add_child(rider)
		_riders.append(rider)


## Chaleco y luz trasera: debajo de la sombra se ven apagados; con luces, brillan.
func _add_reflectors(rider: Node2D) -> void:
	_add_rect(rider, vest_rect, vest_color)
	for y in stripe_ys:
		_add_rect(rider, Rect2(vest_rect.position.x, y, vest_rect.size.x, stripe_height), stripe_color)
	_add_rect(rider, tail_light_rect, tail_light_color)


func _add_rect(parent: Node, rect: Rect2, color: Color) -> void:
	var r := ColorRect.new()
	r.position = rect.position
	r.size = rect.size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)


func _refresh() -> void:
	if not is_node_ready():
		return
	_set_rect(_zone, Rect2(0.0, -road_width / 2.0, length, road_width))
	var half := cover_height / 2.0
	var dark := Color(shade_color, darkness)
	var clear := Color(shade_color, 0.0)
	_body.polygon = PackedVector2Array([
		Vector2(0.0, -half), Vector2(length, -half), Vector2(length, half), Vector2(0.0, half)])
	_body.vertex_colors = PackedColorArray()
	_body.color = dark
	_fade_in.polygon = PackedVector2Array([
		Vector2(-fade_length, -half), Vector2(0.0, -half), Vector2(0.0, half), Vector2(-fade_length, half)])
	_fade_in.color = Color.WHITE
	_fade_in.vertex_colors = PackedColorArray([clear, dark, dark, clear])
	_fade_out.polygon = PackedVector2Array([
		Vector2(length, -half), Vector2(length + fade_length, -half), Vector2(length + fade_length, half), Vector2(length, half)])
	_fade_out.color = Color.WHITE
	_fade_out.vertex_colors = PackedColorArray([dark, clear, clear, dark])
	_rain.visible = rain
	_rain.amount = maxi(rain_amount, 1)
	_rain.position = Vector2(length / 2.0, 0.0)
	_rain.emission_rect_extents = Vector2(length / 2.0 + fade_length, rain_height / 2.0)
	_rain.color = rain_color
	_rain.z_index = lit_z_index + 1
	queue_redraw()


func _draw() -> void:
	if walls:
		for side: float in [-1.0, 1.0]:
			var y := side * (road_width / 2.0 + wall_width / 2.0) - wall_width / 2.0
			var wall := Rect2(0.0, y, length, wall_width)
			draw_rect(wall, wall_color)
			draw_rect(wall, wall_edge_color, false, 2.0)
	if Engine.is_editor_hint():
		draw_rect(Rect2(0.0, -road_width / 2.0, length, road_width), Palette.COLOR_GOLD, false, 2.0)
