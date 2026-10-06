class_name FollowCamera
extends Camera2D
## Cámara que sigue al auto desde arriba y mira un poco hacia adelante,
## para que el niño vea lo que viene. No se sale del mapa.

@export var target: Node2D
## Capa del mapa que define los bordes de la cámara.
@export var bounds_layer: TileMapLayer
## Cuánto se adelanta la cámara en la dirección del auto.
@export var look_ahead: float = 120.0
## Qué tan rápido se acomoda la vista al girar (más alto = más rápido).
@export var look_ahead_smoothing: float = 3.0

var _look_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Se mueve en el mismo paso de física que el auto para que no tiemble.
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	ignore_rotation = true
	if bounds_layer != null:
		_apply_limits()
	if target != null:
		_look_offset = target.global_transform.x.normalized() * look_ahead
		global_position = target.global_position + _look_offset
		reset_smoothing()


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var wanted := target.global_transform.x.normalized() * look_ahead
	_look_offset = _look_offset.lerp(wanted, clampf(look_ahead_smoothing * delta, 0.0, 1.0))
	global_position = target.global_position + _look_offset


func _apply_limits() -> void:
	var used := bounds_layer.get_used_rect()
	var tile_size := Vector2(bounds_layer.tile_set.tile_size)
	var top_left := bounds_layer.to_global(Vector2(used.position) * tile_size)
	var bottom_right := bounds_layer.to_global(Vector2(used.end) * tile_size)
	limit_left = int(top_left.x)
	limit_top = int(top_left.y)
	limit_right = int(bottom_right.x)
	limit_bottom = int(bottom_right.y)
