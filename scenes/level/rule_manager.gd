class_name RuleManager
extends Node
## Cuenta faltas y puntos del nivel y calcula las estrellas.
## Versión inicial para el prototipo: todavía no regresa al punto de control
## ni pausa con el copiloto (eso llega con las tareas RuleManager y Feedback).

signal infraction_reported(rule_id: StringName, grave: bool)
signal good_action_reported(action_id: StringName, points: int)
signal level_finished(stars: int)
## Provisional: el HUD muestra el mensaje hasta que exista el autoload Feedback.
signal feedback_requested(message_key: String, good: bool)

var faults: int = 0
var points: int = 0
var _checkpoint: float = 0.0


func _ready() -> void:
	add_to_group(&"rule_manager")


func report_infraction(rule_id: StringName, message_key: String, grave := false) -> void:
	faults += 1
	print("Falta%s (%s): %s" % [" grave" if grave else "", rule_id, tr(message_key)])
	infraction_reported.emit(rule_id, grave)
	feedback_requested.emit(message_key, false)


func report_good_action(action_id: StringName, message_key: String, action_points := 10) -> void:
	points += action_points
	print("+%d (%s): %s" % [action_points, action_id, tr(message_key)])
	good_action_reported.emit(action_id, action_points)
	feedback_requested.emit(message_key, true)


func set_checkpoint(progress: float) -> void:
	_checkpoint = progress


func get_checkpoint() -> float:
	return _checkpoint


## 0 faltas = 3 estrellas, 1 o 2 = 2, 3 o más = 1.
func get_stars() -> int:
	if faults == 0:
		return 3
	if faults <= 2:
		return 2
	return 1


func finish_level() -> void:
	level_finished.emit(get_stars())
