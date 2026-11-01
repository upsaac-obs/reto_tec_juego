extends Control
## Nivel de prueba del spike (level_id 99): sin manejo, solo botones para
## probar el puente de ida y vuelta con la tarjeta de hábito real.

@export var rule_manager: RuleManager


func _ready() -> void:
	%Fault.pressed.connect(rule_manager.report_infraction.bind(&"stop", "FALTA_ALTO"))
	%Finish.pressed.connect(rule_manager.finish_level)
	%Exit.pressed.connect(BridgeClient.exit_level.bind(false))
