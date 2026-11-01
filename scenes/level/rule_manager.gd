class_name RuleManager
extends Node
## Cuenta faltas y puntos del nivel, guarda el último punto de control y
## calcula las estrellas al llegar a la meta.
## - Una falta grave cuenta como falta, detiene el auto y, tras grave_return_delay,
##   lo regresa al último punto de control. Las piezas se reinician con
##   checkpoint_restored para que la situación se pueda repetir.
## - Al terminar la ruta del auto se llama finish_level() solo.

signal infraction_reported(rule_id: StringName, grave: bool)
signal good_action_reported(action_id: StringName, points: int)
signal level_finished(stars: int)
## El auto regresó al punto de control (distancia sobre la ruta).
signal checkpoint_restored(progress: float)

@export var car: PlayerCar
## Segundos entre la falta grave y el regreso al punto de control. Se cuentan
## después de la pausa de Feedback, que ya deja ver el susto y el mensaje.
@export var grave_return_delay: float = 0.5

var faults: int = 0
## Faltas por regla (rule_id → cuántas). Se manda al nativo en level_finished.
var infractions: Dictionary[StringName, int] = {}
var points: int = 0
var _checkpoint: float = 0.0
var _returning: bool = false
var _finished: bool = false


func _ready() -> void:
	add_to_group(&"rule_manager")
	if car != null:
		_checkpoint = car.progress
		car.route_finished.connect(finish_level)


func report_infraction(rule_id: StringName, message_key: String, grave := false) -> void:
	if _finished:
		return
	faults += 1
	infractions[rule_id] = infractions.get(rule_id, 0) + 1
	infraction_reported.emit(rule_id, grave)
	Feedback.show_infraction(message_key)
	if grave:
		_return_to_checkpoint()


func report_good_action(action_id: StringName, message_key: String, action_points := 10) -> void:
	if _finished:
		return
	points += action_points
	good_action_reported.emit(action_id, action_points)
	Feedback.show_good_action(message_key, action_points)


## Solo avanza: pasar otra vez por un punto anterior no lo mueve hacia atrás.
func set_checkpoint(progress: float) -> void:
	_checkpoint = maxf(_checkpoint, progress)


func get_checkpoint() -> float:
	return _checkpoint


## 0 faltas = 3 estrellas, 1 o 2 = 2, 3 o más = 1. Llegar a la meta siempre da al menos 1.
func get_stars() -> int:
	if faults == 0:
		return 3
	if faults <= 2:
		return 2
	return 1


func finish_level() -> void:
	if _finished:
		return
	_finished = true
	Feedback.show_good_action("META_LLEGASTE", 0)
	level_finished.emit(get_stars())


func _return_to_checkpoint() -> void:
	if _returning or car == null:
		return
	_returning = true
	car.add_stop_request(self)
	await get_tree().create_timer(grave_return_delay, false).timeout
	car.remove_stop_request(self)
	car.restart_at(_checkpoint)
	_returning = false
	checkpoint_restored.emit(_checkpoint)
