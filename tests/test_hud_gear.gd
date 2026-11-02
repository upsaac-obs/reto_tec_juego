extends TestCase
## Engrane del HUD: mantenerlo presionado tutor_hold_time segundos pide la
## pantalla de tutores al nativo (tutor_requested); un toque corto no hace nada.


func tutor_count() -> int:
	return fake_bridge().sent.filter(func(m: Array) -> bool: return m[0] == "tutor_requested").size()


func run() -> void:
	var level := await open_scene("res://levels/test_street.tscn")
	var hud := level.get_node("Hud") as Hud
	var gear := hud.get_node("%Gear") as TextureButton
	var emitted := [0]
	hud.tutor_requested.connect(func() -> void: emitted[0] += 1)
	fake_bridge().sent.clear()
	check(is_equal_approx(hud.tutor_hold_time, 3.0), "el engrane se mantiene 3 s por defecto")

	gear.button_down.emit()
	await wait(0.3)
	gear.button_up.emit()
	await wait(0.2)
	check(tutor_count() == 0 and emitted[0] == 0, "un toque corto no pide la pantalla de tutores")
	check(gear.rotation == 0.0 and gear.self_modulate == Color.WHITE, "al soltar, el engrane vuelve a su estado")

	gear.button_down.emit()
	await wait(1.5)
	check(gear.rotation > 0.0, "mientras se mantiene, el engrane gira (avance visible)")
	gear.button_up.emit()
	await wait(2.0)
	check(tutor_count() == 0, "soltar a la mitad no cuenta")

	# También funciona durante la pausa de una falta.
	get_tree().paused = true
	gear.button_down.emit()
	await wait(hud.tutor_hold_time + 0.2)
	check(tutor_count() == 1 and emitted[0] == 1, "mantener 3 s manda tutor_requested una vez (aun en pausa)")
	gear.button_up.emit()
	get_tree().paused = false
	check(fake_bridge().sent[-1][1].has("level_id"), "tutor_requested lleva level_id")
	await close_scene(level)
