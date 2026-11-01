class_name CopilotBubble
extends CanvasLayer
## Copiloto ajolote con su globo de texto y el "+10" de las acciones correctas.
## Lo maneja el autoload Feedback; no se pone a mano en los niveles.

enum Mood { GOOD, BAD, INFO }

## Segundos que tarda el globo en aparecer.
@export var appear_time: float = 0.15
## Pixeles que sube el "+10" mientras se desvanece.
@export var points_rise: float = 40.0
@export var points_time: float = 1.0

@onready var _box: Control = %Box
@onready var _copilot: AnimatedSprite2D = %Copilot
@onready var _message: PanelContainer = %Message
@onready var _label: Label = %MessageLabel
@onready var _points: Label = %PointsPopup

var _points_start: Vector2
var _box_tween: Tween
var _points_tween: Tween


func _ready() -> void:
	_box.hide()
	_points.hide()
	_points_start = _points.position
	_copilot.animation_finished.connect(_on_copilot_animation_finished)


func show_message(text: String, mood: Mood) -> void:
	_label.text = text
	_message.theme_type_variation = &"MessageBad" if mood == Mood.BAD else &"MessageGood"
	match mood:
		Mood.GOOD:
			_copilot.play(&"happy")
		Mood.BAD:
			_copilot.play(&"surprised")
		_:
			_copilot.play(&"talk")
	if _box_tween != null:
		_box_tween.kill()
	_box.show()
	_box.modulate.a = 0.0
	_box_tween = create_tween()
	_box_tween.tween_property(_box, ^"modulate:a", 1.0, appear_time)


func hide_message() -> void:
	if _box_tween != null:
		_box_tween.kill()
	_box.hide()
	_copilot.stop()


func pop_points(points: int) -> void:
	if _points_tween != null:
		_points_tween.kill()
	_points.text = "+%d" % points
	_points.position = _points_start
	_points.modulate.a = 1.0
	_points.show()
	_points_tween = create_tween().set_parallel()
	_points_tween.tween_property(_points, ^"position:y", _points_start.y - points_rise, points_time) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_points_tween.tween_property(_points, ^"modulate:a", 0.0, points_time * 0.5).set_delay(points_time * 0.5)
	_points_tween.chain().tween_callback(_points.hide)


## Tras el susto, el copiloto se queda pensando mientras dura el mensaje.
func _on_copilot_animation_finished() -> void:
	if _copilot.animation == &"surprised":
		_copilot.play(&"thinking")
