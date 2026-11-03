class_name Speedometer
extends Control
## Velocímetro de aguja. Solo se ve si el nivel tiene alguna SpeedZone
## (grupo speed_zone). Lee la velocidad y el límite del auto cada frame.

const Palette := preload("res://autoload/game_state.gd")

@export var car: PlayerCar
@export var max_kmh := 60.0
@export var arc_start_deg := 150.0
@export var arc_end_deg := 390.0
@export var dial_radius := 70.0
@export var needle_smoothing := 10.0
@export var blink_period := 0.4
@export var tick_step_kmh := 10.0

var shown_kmh := 0.0
var _blink_time := 0.0

@onready var _limit_label: Label = $LimitLabel


func _ready() -> void:
	visible = not get_tree().get_nodes_in_group(&"speed_zone").is_empty()
	set_process(visible)


func speed_kmh() -> float:
	return car.speed / Palette.PX_PER_KMH if car else 0.0


func limit_kmh() -> float:
	return car.current_limit() / Palette.PX_PER_KMH if car else max_kmh


func is_over_limit() -> bool:
	return car != null and car.speed > car.current_limit()


func _process(delta: float) -> void:
	shown_kmh = lerpf(shown_kmh, speed_kmh(), clampf(needle_smoothing * delta, 0.0, 1.0))
	_blink_time = _blink_time + delta if is_over_limit() else 0.0
	_limit_label.text = str(roundi(limit_kmh()))
	queue_redraw()


func _angle_for(kmh: float) -> float:
	var t := clampf(kmh / max_kmh, 0.0, 1.0)
	return deg_to_rad(lerpf(arc_start_deg, arc_end_deg, t))


func _draw() -> void:
	var c := size / 2.0
	draw_circle(c, dial_radius + 4.0, Palette.COLOR_ADO_RED)
	draw_circle(c, dial_radius, Palette.COLOR_DARK_PURPLE)
	var arc_r := dial_radius - 10.0
	var lim_a := _angle_for(limit_kmh())
	draw_arc(c, arc_r, _angle_for(0.0), lim_a, 32, Palette.COLOR_GREEN, 8.0)
	var red_on := _blink_time == 0.0 or fmod(_blink_time, blink_period) < blink_period / 2.0
	if red_on:
		draw_arc(c, arc_r, lim_a, _angle_for(max_kmh), 32, Palette.COLOR_ADO_RED, 8.0)
	var kmh := 0.0
	while kmh <= max_kmh:
		var dir := Vector2.from_angle(_angle_for(kmh))
		draw_line(c + dir * (arc_r - 10.0), c + dir * (arc_r - 18.0), Palette.COLOR_WHITE, 3.0)
		kmh += tick_step_kmh
	var needle := Vector2.from_angle(_angle_for(shown_kmh))
	draw_line(c, c + needle * (arc_r - 4.0), Palette.COLOR_GOLD, 5.0)
	draw_circle(c, 7.0, Palette.COLOR_GOLD)
