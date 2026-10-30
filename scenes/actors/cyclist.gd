class_name Cyclist
extends Node2D
## Ciclista que pasa pedaleando en línea recta hacia +x (la misma dirección del
## auto del jugador). El origen es el centro de la bici. Se borra solo al llegar
## a end_x (coordenadas del padre). Animación "ride" en cyclist_frames.tres.

signal left_route

@export var speed: float = 150.0
@export var end_x: float = 600.0
## Marca esto si en el editor la bici se ve mirando hacia atrás.
@export var flip: bool = false

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group(&"cyclist")
	_sprite.flip_h = flip
	_sprite.play(&"ride")


func _physics_process(delta: float) -> void:
	position.x += speed * delta
	if position.x >= end_x:
		left_route.emit()
		queue_free()
