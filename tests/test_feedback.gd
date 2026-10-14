extends TestCase
## Copiloto (Feedback) conectado al RuleManager del nivel.


func run() -> void:
	var level := await open_scene("res://levels/test_street.tscn")
	var rm := level.get_node("RuleManager") as RuleManager
	var bubble: CopilotBubble = Feedback._bubble
	var box := bubble.get_node("%Box") as Control
	var label := bubble.get_node("%MessageLabel") as Label
	var points := bubble.get_node("%PointsPopup") as Label
	var copilot := bubble.get_node("%Copilot") as AnimatedSprite2D

	rm.report_good_action(&"stop", "BIEN_ALTO", 10)
	await frames(1)
	check(box.visible and label.text == "¡Bien, alto completo!", "acción buena muestra el texto traducido")
	check(points.visible and points.text == "+10", "aparece +10")
	check(copilot.animation == &"happy" and not get_tree().paused, "copiloto feliz y sin pausa")
	await wait(2.6)
	check(not box.visible and not points.visible, "el mensaje y el +10 se van solos")

	rm.report_infraction(&"stop", "FALTA_ALTO")
	await frames(1)
	check(get_tree().paused and copilot.animation == &"surprised", "falta: pausa y copiloto asustado")
	await wait(1.9)
	check(get_tree().paused, "sigue en pausa a los 1.9 s")
	await wait(0.2)
	check(not get_tree().paused and copilot.animation == &"thinking", "a los 2 s se quita la pausa y queda pensando")

	rm.set_checkpoint(100.0)
	rm.car.progress = 400.0
	rm.report_infraction(&"crosswalk", "FALTA_PEATON", true)
	await wait(2.2)
	check(absf(rm.car.progress - 400.0) < 50.0, "falta grave: todavía no regresa al terminar la pausa")
	await wait(0.6)
	check(absf(rm.car.progress - 100.0) < 1.0, "falta grave: regresa al punto de control")

	Feedback.show_infraction("FALTA_ALTO")
	await frames(1)
	Feedback.clear()
	get_tree().paused = true
	await wait(2.2)
	check(get_tree().paused and not box.visible, "clear() no quita una pausa ajena (menú de pausa)")
	get_tree().paused = false
	await close_scene(level)
