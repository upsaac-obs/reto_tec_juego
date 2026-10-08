class_name Hud
extends CanvasLayer
## HUD provisional del nivel, como el mockup: barra con nombre, puntos, estrellas
## y destino; engrane; cinturón y flechas a la izquierda; pedales a la derecha.
## Los botones son TouchScreenButton con las acciones del auto (car_*), así
## funcionan con varios dedos a la vez y también con el teclado.

signal settings_pressed

@export var car: PlayerCar
@export var rule_manager: RuleManager
@export var star_full: Texture2D
@export var star_empty: Texture2D
## Oscurece el botón mientras se presiona.
@export var pressed_tint: Color = Color(0.75, 0.75, 0.75)
## El cinturón parpadea hasta que se lo ponen.
@export var seatbelt_pulse_time: float = 0.5
@export var seatbelt_done_tint: Color = Color(0.55, 0.55, 0.6, 1.0)

@onready var _level_name: Label = %LevelName
@onready var _points: Label = %Points
@onready var _stars: HBoxContainer = %Stars
@onready var _destination: Label = %Destination
@onready var _seatbelt: TouchScreenButton = %Seatbelt
@onready var _gear: TextureButton = %Gear

var _pulse: Tween


func _ready() -> void:
	var level := LevelData.of(self)
	_level_name.text = tr(level.name_key) if level != null else ""
	var destination := level.destination_key if level != null else ""
	_destination.text = tr(destination)
	# Sin destino decidido todavía, no se muestra la pastilla vacía.
	_destination.get_parent().visible = not destination.is_empty()
	for button: TouchScreenButton in [%Seatbelt, %ArrowLeft, %ArrowRight, %Brake, %Gas]:
		button.pressed.connect(func() -> void: button.self_modulate = pressed_tint)
		button.released.connect(func() -> void: button.self_modulate = Color.WHITE)
	_gear.pressed.connect(settings_pressed.emit)
	if rule_manager != null:
		rule_manager.infraction_reported.connect(func(_id: StringName, _grave: bool) -> void: _refresh_score())
		rule_manager.good_action_reported.connect(func(_id: StringName, _points_won: int) -> void: _refresh_score())
	if car != null:
		car.seatbelt_fastened.connect(_on_seatbelt_fastened)
		car.blocked_without_seatbelt.connect(Feedback.show_info.bind("PONTE_CINTURON"))
	_refresh_score()
	_start_seatbelt_pulse()


func _refresh_score() -> void:
	var points := rule_manager.points if rule_manager != null else 0
	var stars := rule_manager.get_stars() if rule_manager != null else 3
	_points.text = str(points)
	for i in _stars.get_child_count():
		(_stars.get_child(i) as TextureRect).texture = star_full if i < stars else star_empty


func _start_seatbelt_pulse() -> void:
	_pulse = create_tween().set_loops()
	_pulse.tween_property(_seatbelt, ^"modulate:a", 0.45, seatbelt_pulse_time)
	_pulse.tween_property(_seatbelt, ^"modulate:a", 1.0, seatbelt_pulse_time)


func _on_seatbelt_fastened() -> void:
	if _pulse != null:
		_pulse.kill()
	_seatbelt.modulate = seatbelt_done_tint
	Feedback.show_good_action("CINTURON_LISTO", 0)
