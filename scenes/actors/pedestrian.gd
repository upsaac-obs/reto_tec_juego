class_name Pedestrian
extends Node2D
## Peatón que camina en línea recta hacia un punto. El origen del nodo son sus pies.
## Animaciones en sprite_frames: "idle", "walk" y "scared" (sin repetir).

signal arrived

## Pasos por segundo en px/s. Más lento para personas mayores o silla de ruedas.
@export var walk_speed: float = 70.0
@export var sprite_frames: SpriteFrames
@export var fade_time: float = 0.4

@onready var _sprite: AnimatedSprite2D = $Sprite

var _target: Vector2 = Vector2.ZERO
var _walking: bool = false
var _scared: bool = false
var _fade: Tween


func _ready() -> void:
	if sprite_frames != null:
		_sprite.sprite_frames = sprite_frames
	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.play(&"idle")


## Camina hasta target (en coordenadas del padre) y emite arrived al llegar.
func walk_to(target: Vector2) -> void:
	_target = target
	_walking = true
	if not _scared:
		_sprite.play(&"walk")


## Se asusta un momento y luego sigue con lo que estaba haciendo.
func scare() -> void:
	_scared = true
	_sprite.play(&"scared")


func fade_out() -> void:
	_fade = create_tween()
	_fade.tween_property(self, ^"modulate:a", 0.0, fade_time)
	_fade.tween_callback(hide)


## Vuelve a estar quieto y visible en otra posición (al regresar a un punto de control).
func reset_at(target: Vector2) -> void:
	if _fade != null:
		_fade.kill()
	_walking = false
	_scared = false
	position = target
	modulate.a = 1.0
	show()
	_sprite.play(&"idle")


func _physics_process(delta: float) -> void:
	if not _walking or _scared:
		return
	position = position.move_toward(_target, walk_speed * delta)
	if position.is_equal_approx(_target):
		_walking = false
		_sprite.play(&"idle")
		arrived.emit()


func _on_animation_finished() -> void:
	if _sprite.animation == &"scared":
		_scared = false
		_sprite.play(&"walk" if _walking else &"idle")
