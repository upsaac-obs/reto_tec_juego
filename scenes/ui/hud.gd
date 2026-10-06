class_name Hud
extends CanvasLayer
## HUD provisional del nivel, como el mockup: barra con nombre, puntos, estrellas
## y destino; engrane; cinturón y flechas a la izquierda; pedales a la derecha.
## Los botones son TouchScreenButton con las acciones del auto (car_*), así
## funcionan con varios dedos a la vez y también con el teclado.

signal settings_pressed

@export var car: PlayerCar
@export var rule_manager: RuleManager
@export var level_name_key: String = "HUD_NIVEL_PRUEBA"
@export var destination_key: String = "HUD_DESTINO_PRUEBA"
@export var star_full: Texture2D
@export var star_empty: Texture2D
@export var message_time: float = 2.5
## Oscurece el botón mientras se presiona.
@export var pressed_tint: Color = Color(0.75, 0.75, 0.75)
## El cinturón parpadea hasta que se lo ponen.
@export var seatbelt_pulse_time: float = 0.5
@export var seatbelt_done_tint: Color = Color(0.55, 0.55, 0.6, 1.0)

@onready var _level_name: Label = %LevelName
@onready var _points: Label = %Points
@onready var _stars: HBoxContainer = %Stars
@onready var _destination: Label = %Destination
@onready var _message: PanelContainer = %Message
@onready var _message_label: Label = %MessageLabel
@onready var _seatbelt: TouchScreenButton = %Seatbelt
@onready var _gear: TextureButton = %Gear

var _message_timer: SceneTreeTimer
var _pulse: Tween


func _ready() -> void:
	_level_name.text = tr(level_name_key)
	_destination.text = tr(destination_key)
	_message.hide()
	for button: TouchScreenButton in [%Seatbelt, %ArrowLeft, %ArrowRight, %Brake, %Gas]:
		button.pressed.connect(func() -> void: button.self_modulate = pressed_tint)
		button.released.connect(func() -> void: button.self_modulate = Color.WHITE)
	_gear.pressed.connect(settings_pressed.emit)
	if rule_manager != null:
		rule_manager.infraction_reported.connect(func(_id: StringName, _grave: bool) -> void: _refresh_score())
		rule_manager.good_action_reported.connect(func(_id: StringName, _points_won: int) -> void: _refresh_score())
		rule_manager.feedback_requested.connect(show_message)
	if car != null:
		car.seatbelt_fastened.connect(_on_seatbelt_fastened)
		car.blocked_without_seatbelt.connect(show_message.bind("PONTE_CINTURON", false))
	_refresh_score()
	_start_seatbelt_pulse()


func show_message(message_key: String, good: bool) -> void:
	_message_label.text = tr(message_key)
	_message.theme_type_variation = &"MessageGood" if good else &"MessageBad"
	_message.show()
	var timer := get_tree().create_timer(message_time)
	_message_timer = timer
	timer.timeout.connect(func() -> void:
		if _message_timer == timer:
			_message.hide())


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
	show_message("CINTURON_LISTO", true)
