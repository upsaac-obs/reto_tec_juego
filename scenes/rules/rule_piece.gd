@tool
class_name RulePiece
extends Node2D
## Base de las piezas de reglas. Detecta al auto por su Hitbox (grupo "player")
## y le avisa al RuleManager del nivel (grupo "rule_manager").

const Palette := preload("res://autoload/game_state.gd")


func _car_from(area: Area2D) -> PlayerCar:
	if area.is_in_group(&"player"):
		return area.owner as PlayerCar
	return null


func _rule_manager() -> RuleManager:
	return get_tree().get_first_node_in_group(&"rule_manager") as RuleManager


func _report_infraction(rule_id: StringName, message_key: String, grave := false) -> void:
	var manager := _rule_manager()
	if manager == null:
		push_warning("No hay RuleManager en el nivel: %s" % tr(message_key))
		return
	manager.report_infraction(rule_id, message_key, grave)


func _report_good_action(action_id: StringName, message_key: String, points := 10) -> void:
	var manager := _rule_manager()
	if manager == null:
		push_warning("No hay RuleManager en el nivel: %s" % tr(message_key))
		return
	manager.report_good_action(action_id, message_key, points)


## Ajusta el tamaño y la posición del rectángulo de colisión de un Area2D hijo.
func _set_rect(area: Area2D, rect: Rect2) -> void:
	var shape_node := area.get_child(0) as CollisionShape2D
	var shape := shape_node.shape as RectangleShape2D
	shape.size = rect.size
	shape_node.position = rect.get_center()
