@tool
class_name TutorialHint
extends RulePiece
## Consejo del copiloto: cuando el auto llega aquí, el copiloto dice un mensaje
## (sin pausa y sin falta). Se dice una sola vez por nivel. Para el tutorial.

@export var message_key: String
## Si no está vacío, se usa en modo peque (el auto avanza solo, sin pedal verde).
@export var peque_message_key: String
@export var depth: float = 64.0:
	set(value):
		depth = value
		_refresh()
@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()

@onready var _zone: Area2D = $Zone

var _said: bool = false


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	_zone.area_entered.connect(_on_zone_entered)


func _on_zone_entered(area: Area2D) -> void:
	if _car_from(area) == null or _said:
		return
	_said = true
	var key := message_key
	if GameState.mode == GameState.MODE_PEQUE and not peque_message_key.is_empty():
		key = peque_message_key
	Feedback.show_info(key)


func _refresh() -> void:
	if not is_node_ready():
		return
	_set_rect(_zone, Rect2(-depth / 2.0, -road_width / 2.0, depth, road_width))
	queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(-depth / 2.0, -road_width / 2.0, depth, road_width), Palette.COLOR_GLASS, false, 2.0)
