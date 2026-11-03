extends Node2D
## Brillo de frenos y direccionales del auto (plan visual, fase 0): los cuadritos que
## dibuja PlayerCar casi no se ven en el teléfono, así que aquí se les pone un halo
## aditivo. Solo lee el estado público del auto; no cambia nada de él.

const Palette := preload("res://autoload/game_state.gd")

@export var glow_radius: float = 11.0
@export var brake_color: Color = Color(Palette.COLOR_SKY_HORIZON, 0.85)
@export var signal_color: Color = Color(Palette.COLOR_GOLD, 0.9)

var _car: PlayerCar
var _blink_time: float = 0.0
var _was_lit: bool = false


func _ready() -> void:
	_car = get_parent() as PlayerCar
	if _car == null:
		set_process(false)
		return
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = glow
	# Mismo ritmo que el parpadeo del auto: los dos empiezan de cero al cambiar la direccional.
	_car.turn_signal_changed.connect(func(_direction: int) -> void: _blink_time = 0.0)


func _process(delta: float) -> void:
	_blink_time += delta
	var lit := _car.is_braking or _car.turn_signal != 0
	if lit or _was_lit:
		queue_redraw()
	_was_lit = lit


func _draw() -> void:
	if _car.is_braking:
		for rect in _car.brake_lights:
			_glow(rect.get_center(), brake_color)
	var interval := _car.blink_interval
	if _car.turn_signal != 0 and fmod(_blink_time, interval * 2.0) < interval:
		for rect in (_car.right_signal_lights if _car.turn_signal > 0 else _car.left_signal_lights):
			_glow(rect.get_center(), signal_color)


func _glow(center: Vector2, color: Color) -> void:
	draw_circle(center, glow_radius, Color(color, color.a * 0.25))
	draw_circle(center, glow_radius * 0.6, Color(color, color.a * 0.45))
	draw_circle(center, glow_radius * 0.3, color)
