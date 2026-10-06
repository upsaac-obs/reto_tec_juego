@tool
class_name Checkpoint
extends RulePiece
## Punto de control. Cuando el auto pasa, el RuleManager guarda su posición;
## tras una falta grave, el auto regresa aquí. No se ve en el juego.

@export var road_width: float = 128.0:
	set(value):
		road_width = value
		_refresh()

@onready var _zone: Area2D = $Zone


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	_zone.area_entered.connect(_on_zone_entered)


func _on_zone_entered(area: Area2D) -> void:
	var car := _car_from(area)
	var manager := _rule_manager()
	if car != null and manager != null:
		manager.set_checkpoint(car.progress)


func _refresh() -> void:
	if not is_node_ready():
		return
	_set_rect(_zone, Rect2(-4.0, -road_width / 2.0, 8.0, road_width))
	queue_redraw()


## Solo en el editor: bandera para ubicarlo.
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_line(Vector2(0.0, -road_width / 2.0), Vector2(0.0, road_width / 2.0), Palette.COLOR_GOLD, 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -road_width / 2.0), Vector2(22.0, -road_width / 2.0 + 8.0), Vector2(0.0, -road_width / 2.0 + 16.0),
	]), Palette.COLOR_GOLD)
