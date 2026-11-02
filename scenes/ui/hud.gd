class_name Hud
extends CanvasLayer
## HUD provisional del nivel, como el mockup: barra con nombre, puntos, estrellas
## y destino; engrane; cinturón y flechas a la izquierda; pedales a la derecha.
## Los botones son TouchScreenButton con las acciones del auto (car_*), así
## funcionan con varios dedos a la vez y también con el teclado.
## - Engrane: mantenerlo presionado tutor_hold_time segundos pide la pantalla de
##   tutores al nativo (BridgeClient.request_tutor). Un toque corto no hace nada.
##   Mientras se mantiene, el engrane gira y se pinta de dorado poco a poco.

## Se completó la presión larga del engrane (ya se llamó a BridgeClient.request_tutor).
signal tutor_requested

const Palette := preload("res://autoload/game_state.gd")

@export var car: PlayerCar
@export var rule_manager: RuleManager
@export var star_full: Texture2D
@export var star_empty: Texture2D
## Oscurece el botón mientras se presiona.
@export var pressed_tint: Color = Color(0.75, 0.75, 0.75)
## El cinturón parpadea hasta que se lo ponen.
@export var seatbelt_pulse_time: float = 0.5
@export var seatbelt_done_tint: Color = Color(0.55, 0.55, 0.6, 1.0)
## Botón de luces (nivel 7). Un nivel lo muestra poniendo esta propiedad en true
## en su nodo Hud (escena heredada). Prende y apaga las luces del auto (car_lights).
## Parpadea (como el cinturón) hasta que se prenden la primera vez y otra vez
## mientras las luces están apagadas y alguna pieza del grupo "needs_headlights"
## dice que el auto está dentro (is_car_inside() -> bool o wants_lights() -> bool).
@export var show_lights_button: bool = false
## Color del botón de luces mientras están encendidas.
@export var lights_on_tint: Color = Palette.COLOR_GOLD
## Segundos que hay que mantener el engrane para abrir la pantalla de tutores.
@export var tutor_hold_time: float = 3.0
## Color al que llega el engrane al completar la presión larga.
@export var gear_hold_tint: Color = Palette.COLOR_GOLD

@onready var _level_name: Label = %LevelName
@onready var _points: Label = %Points
@onready var _stars: HBoxContainer = %Stars
@onready var _destination: Label = %Destination
@onready var _seatbelt: TouchScreenButton = %Seatbelt
@onready var _gear: TextureButton = %Gear
@onready var _lights: TouchScreenButton = %Lights

var _pulse: Tween
var _gear_hold: Tween
var _lights_pulse: Tween
var _lights_used: bool = false


func _ready() -> void:
	var level := LevelData.of(self)
	_level_name.text = tr(level.name_key) if level != null else ""
	var destination := level.destination_key if level != null else ""
	_destination.text = tr(destination)
	# Sin destino decidido todavía, no se muestra la pastilla vacía.
	_destination.get_parent().visible = not destination.is_empty()
	for button: TouchScreenButton in [%Seatbelt, %ArrowLeft, %ArrowRight, %Brake, %Gas, %Lights]:
		button.pressed.connect(func() -> void: button.self_modulate = pressed_tint)
		button.released.connect(func() -> void: button.self_modulate = Color.WHITE)
	# Sigue recibiendo toques durante la pausa de una falta: si no, se pierde el
	# soltar y el engrane abriría Tutores solo.
	_gear.process_mode = Node.PROCESS_MODE_ALWAYS
	_gear.button_down.connect(_on_gear_down)
	_gear.button_up.connect(_cancel_gear_hold)
	if rule_manager != null:
		rule_manager.infraction_reported.connect(func(_id: StringName, _grave: bool) -> void: _refresh_score())
		rule_manager.good_action_reported.connect(func(_id: StringName, _points_won: int) -> void: _refresh_score())
	if car != null:
		car.seatbelt_fastened.connect(_on_seatbelt_fastened)
		car.blocked_without_seatbelt.connect(Feedback.show_info.bind("PONTE_CINTURON"))
		car.headlights_changed.connect(_on_headlights_changed)
	_lights.visible = show_lights_button
	# Modo peque: el auto avanza solo; el niño solo tiene freno y flechas.
	%Gas.visible = GameState.mode != GameState.MODE_PEQUE
	_refresh_score()
	_pulse = _start_pulse(_seatbelt)
	set_process(show_lights_button and car != null)


func _process(_delta: float) -> void:
	var wanted := _lights_should_pulse()
	if wanted == (_lights_pulse != null):
		return
	if wanted:
		_lights_pulse = _start_pulse(_lights)
	else:
		_lights_pulse.kill()
		_lights_pulse = null
		_lights.modulate.a = 1.0


## true si el botón de luces tiene que llamar la atención.
func _lights_should_pulse() -> bool:
	if car.headlights_on:
		return false
	if not _lights_used:
		return true
	for node in get_tree().get_nodes_in_group(&"needs_headlights"):
		if node.has_method(&"is_car_inside") and node.call(&"is_car_inside"):
			return true
		if node.has_method(&"wants_lights") and node.call(&"wants_lights"):
			return true
	return false


## true mientras el botón de luces parpadea (lo usan las pruebas).
func is_lights_pulsing() -> bool:
	return _lights_pulse != null


func _refresh_score() -> void:
	var points := rule_manager.points if rule_manager != null else 0
	var stars := rule_manager.get_stars() if rule_manager != null else 3
	_points.text = str(points)
	for i in _stars.get_child_count():
		(_stars.get_child(i) as TextureRect).texture = star_full if i < stars else star_empty


func _on_headlights_changed(on: bool) -> void:
	if on:
		_lights_used = true
	_lights.modulate = lights_on_tint if on else Color.WHITE


## Parpadeo para pedir que toquen un botón (cinturón, luces).
func _start_pulse(node: CanvasItem) -> Tween:
	var pulse := create_tween().set_loops()
	pulse.tween_property(node, ^"modulate:a", 0.45, seatbelt_pulse_time)
	pulse.tween_property(node, ^"modulate:a", 1.0, seatbelt_pulse_time)
	return pulse


func _on_seatbelt_fastened() -> void:
	if _pulse != null:
		_pulse.kill()
	_seatbelt.modulate = seatbelt_done_tint
	Feedback.show_good_action("CINTURON_LISTO", 0)


## Empieza a contar la presión larga. Corre aunque el juego esté en pausa (falta).
func _on_gear_down() -> void:
	_cancel_gear_hold()
	_gear.pivot_offset = _gear.size / 2.0
	_gear_hold = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	_gear_hold.tween_property(_gear, ^"rotation", TAU / 2.0, tutor_hold_time)
	_gear_hold.tween_property(_gear, ^"self_modulate", gear_hold_tint, tutor_hold_time)
	_gear_hold.chain().tween_callback(_on_gear_held)


func _cancel_gear_hold() -> void:
	if _gear_hold != null:
		_gear_hold.kill()
		_gear_hold = null
	_gear.rotation = 0.0
	_gear.self_modulate = Color.WHITE


func _on_gear_held() -> void:
	_gear_hold = null
	_gear.rotation = 0.0
	_gear.self_modulate = Color.WHITE
	BridgeClient.request_tutor()
	tutor_requested.emit()
