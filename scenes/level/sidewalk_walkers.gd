class_name SidewalkWalkers
extends Node2D
## Gente que camina por las banquetas para darle vida a la calle. Solo decoración:
## no tiene colisiones ni grupos, nunca pisa la calle y no interactúa con el auto.
## Lo crea CityDresser con LevelTheme.sidewalk_walkers personas.
## - Solo existen cerca de la cámara: al salir de la vista reaparecen en otra orilla.
## - Dan la vuelta antes de llegar a un cruce o a una pieza con peatones (avoid_x),
##   para no confundirse con los peatones de las reglas.

const FRAMES: Array[SpriteFrames] = [
	preload("res://assets/sprites/pedestrians/child_frames.tres"),
	preload("res://assets/sprites/pedestrians/girl_frames.tres"),
	preload("res://assets/sprites/pedestrians/adult_frames.tres"),
	preload("res://assets/sprites/pedestrians/elder_frames.tres"),
	preload("res://assets/sprites/pedestrians/wheelchair_frames.tres"),
	preload("res://assets/sprites/pedestrians/dad_stroller_frames.tres"),
	preload("res://assets/sprites/pedestrians/teen_frames.tres"),
	preload("res://assets/sprites/pedestrians/shopper_frames.tres"),
]

## Velocidad de paso (px/s), al azar entre estos dos.
@export var min_speed: float = 26.0
@export var max_speed: float = 44.0
## Velocidad a la que la animación de caminar va a 1×.
@export var anim_speed_ref: float = 40.0
## Margen fuera de la vista donde aparecen y desaparecen.
@export var spawn_margin: float = 80.0
## Probabilidad de reaparecer delante del auto (+x) y no detrás.
@export_range(0.0, 1.0) var ahead_chance: float = 0.7

## Franjas de y (pies) donde se camina: una por banqueta (x = y mínima, y = y máxima).
var lanes: Array[Vector2] = []
## Zonas prohibidas en x: centro y radio (x, radio).
var avoid: Array[Vector2] = []
## Límites en x del nivel.
var min_x: float = 0.0
var max_x: float = 0.0

var _rng := RandomNumberGenerator.new()
var _walkers: Array[AnimatedSprite2D] = []
var _dirs: Array[float] = []
var _speeds: Array[float] = []


## Crea count personas repartidas en la vista inicial.
func setup(count: int, seed_value: int) -> void:
	_rng.seed = seed_value
	if lanes.is_empty():
		return
	var view := _view_range()
	for i in count:
		var walker := AnimatedSprite2D.new()
		walker.name = "Walker%d" % i
		walker.sprite_frames = FRAMES[i % FRAMES.size()]
		walker.animation = &"walk"
		var size := walker.sprite_frames.get_frame_texture(&"walk", 0).get_size()
		walker.offset = Vector2(0.0, -size.y / 2.0)
		add_child(walker)
		_walkers.append(walker)
		_dirs.append(1.0)
		_speeds.append(min_speed)
		_respawn(i, _rng.randf_range(view.x, view.y))


func is_avoided(x: float) -> bool:
	for zone in avoid:
		if absf(x - zone.x) < zone.y:
			return true
	return false


func _process(delta: float) -> void:
	if _walkers.is_empty():
		return
	var view := _view_range()
	for i in _walkers.size():
		var walker := _walkers[i]
		var next := walker.position.x + _dirs[i] * _speeds[i] * delta
		if is_avoided(next) or next < min_x or next > max_x:
			_turn(i, -_dirs[i])
			continue
		walker.position.x = next
		if next < view.x - spawn_margin * 2.0 or next > view.y + spawn_margin * 2.0:
			var ahead := _rng.randf() < ahead_chance
			_respawn(i, view.y + spawn_margin if ahead else view.x - spawn_margin)


## Pone a la persona i en x (o cerca, si x cae en una zona prohibida) con rumbo y paso nuevos.
func _respawn(i: int, x: float) -> void:
	var walker := _walkers[i]
	var spot := x
	for attempt in 8:
		if not is_avoided(spot) and spot >= min_x and spot <= max_x:
			break
		spot = x + _rng.randf_range(-400.0, 400.0)
	walker.visible = not is_avoided(spot) and spot >= min_x and spot <= max_x
	var lane := lanes[_rng.randi() % lanes.size()]
	walker.position = Vector2(spot, _rng.randf_range(lane.x, lane.y))
	_speeds[i] = _rng.randf_range(min_speed, max_speed)
	walker.speed_scale = _speeds[i] / anim_speed_ref
	_turn(i, 1.0 if _rng.randf() < 0.5 else -1.0)
	walker.play(&"walk")
	walker.frame = _rng.randi() % walker.sprite_frames.get_frame_count(&"walk")


func _turn(i: int, dir: float) -> void:
	_dirs[i] = dir
	_walkers[i].flip_h = dir < 0.0


## x mínima y máxima que ve la cámara (o todo el nivel si no hay cámara).
func _view_range() -> Vector2:
	var camera := get_viewport().get_camera_2d() if is_inside_tree() else null
	if camera == null:
		return Vector2(min_x, max_x)
	var half := get_viewport_rect().size.x / camera.zoom.x / 2.0
	var center := camera.get_screen_center_position().x
	return Vector2(center - half, center + half)
