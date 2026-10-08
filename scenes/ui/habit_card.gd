class_name HabitCard
extends CanvasLayer
## Tarjeta del hábito al terminar el nivel: ilustración, nombre del nivel, punto
## del decálogo, frase final (con voz si existe) y estrellas que aparecen una
## por una. Se abre sola con level_finished del RuleManager y pausa el juego.
## Repetir y Continuar pasan por BridgeClient (Continuar cierra el nivel y
## avisa al nativo). Los datos salen del LevelData del nivel (data/level_XX.tres).

@export var rule_manager: RuleManager
@export var star_full: Texture2D
@export var star_empty: Texture2D
## Segundos entre llegar a la meta y abrir la tarjeta (deja ver el mensaje de meta).
@export var open_delay: float = 1.2
@export var appear_time: float = 0.25
@export var star_interval: float = 0.4

@onready var _panel: Control = %CardPanel
@onready var _illustration: TextureRect = %Illustration
@onready var _level_name: Label = %LevelName
@onready var _decalogo: Label = %Decalogo
@onready var _phrase: Label = %Phrase
@onready var _stars: HBoxContainer = %Stars
@onready var _star_sound: AudioStreamPlayer = %StarSound


func _ready() -> void:
	hide()
	%Retry.pressed.connect(_on_retry_pressed)
	%Continue.pressed.connect(_on_continue_pressed)
	if rule_manager != null:
		rule_manager.level_finished.connect(open)


func open(stars: int) -> void:
	await get_tree().create_timer(open_delay).timeout
	Feedback.clear()
	get_tree().paused = true
	var level := LevelData.of(self)
	if level == null:
		push_warning("HabitCard: el nivel no tiene LevelData en data/")
		level = LevelData.new()
	_illustration.texture = level.illustration
	_level_name.text = tr(level.name_key)
	_decalogo.text = tr(level.decalogo_key)
	_decalogo.visible = not level.decalogo_key.is_empty()
	_phrase.text = tr(level.phrase_key)
	for star: TextureRect in _stars.get_children():
		star.texture = star_empty
	show()
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2(0.8, 0.8)
	_panel.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(_panel, ^"scale", Vector2.ONE, appear_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, ^"modulate:a", 1.0, appear_time)
	await tween.finished
	Feedback.play_voice(level.phrase_key)
	for i in mini(stars, _stars.get_child_count()):
		await get_tree().create_timer(star_interval).timeout
		_pop_star(_stars.get_child(i) as TextureRect)
	%Continue.grab_focus()


func _pop_star(star: TextureRect) -> void:
	star.texture = star_full
	star.pivot_offset = star.size / 2.0
	star.scale = Vector2(1.4, 1.4)
	create_tween().tween_property(star, ^"scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_star_sound.play()


func _on_retry_pressed() -> void:
	BridgeClient.retry_level()


func _on_continue_pressed() -> void:
	BridgeClient.exit_level(true)
