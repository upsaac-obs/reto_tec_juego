# Creación y desarrollo: Angel Mael Vera Carpio
extends TestCase
## RuleManager: la pausa de una falta solo se puede saltar con un toque si esa
## misma falta (rule_id) ya ocurrió antes en el nivel. La primera vez se espera
## completa.


## Reporta la falta, toca la pantalla pasada la espera mínima y dice si se quitó la pausa.
func skipped_by_touch(rm: RuleManager, rule_id: StringName, grave := false) -> bool:
	rm.report_infraction(rule_id, "FALTA_ALTO", grave)
	await wait(Feedback.skip_pause_delay + 0.1)
	var was_paused := get_tree().paused
	touch()
	touch(false)
	var skipped := was_paused and not get_tree().paused and not Feedback.is_pausing()
	Feedback.clear()
	get_tree().paused = false
	await frames(1)
	return skipped


func run() -> void:
	var level := await open_scene("res://levels/test_street.tscn")
	var rm := level.get_node("RuleManager") as RuleManager

	check(not await skipped_by_touch(rm, &"stop"), "la primera falta de alto no se salta con un toque")
	check(await skipped_by_touch(rm, &"stop"), "la segunda falta de alto sí se salta con un toque")
	check(await skipped_by_touch(rm, &"stop"), "la tercera también")
	check(not await skipped_by_touch(rm, &"speed"), "una falta distinta la primera vez no se salta")
	check(await skipped_by_touch(rm, &"speed"), "esa otra falta, la segunda vez, sí se salta")
	check(rm.faults == 5, "saltar la pausa no cambia el conteo de faltas")

	# Falta grave repetida: al saltar la pausa el auto regresa igual al punto de control.
	rm.set_checkpoint(100.0)
	rm.car.progress = 400.0
	check(not await skipped_by_touch(rm, &"crosswalk", true), "la primera falta grave no se salta")
	await wait(rm.grave_return_delay + 0.2)
	rm.car.progress = 400.0
	check(await skipped_by_touch(rm, &"crosswalk", true), "la segunda falta grave sí se salta")
	await wait(rm.grave_return_delay + 0.2)
	check(absf(rm.car.progress - 100.0) < 1.0, "falta grave saltada: el auto regresa al punto de control")
	await close_scene(level)

	# Un nivel nuevo (o reintentar) empieza la cuenta de cero.
	level = await open_scene("res://levels/test_street.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	check(not await skipped_by_touch(rm, &"stop"), "al reintentar el nivel, la primera falta de alto vuelve a no saltarse")
	await close_scene(level)
