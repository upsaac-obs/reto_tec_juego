extends TestCase
## Puente del lado de Godot (BridgeClient) con el FakeBridge: contrato de
## docs/arquitectura.md, sección 3.


func last(event: String) -> Variant:
	var sent := fake_bridge().sent
	for i in range(sent.size() - 1, -1, -1):
		if sent[i][0] == event:
			return sent[i][1]
	return null


func count(event: String) -> int:
	return fake_bridge().sent.filter(func(m: Array) -> bool: return m[0] == event).size()


func scene() -> String:
	return get_tree().current_scene.scene_file_path if get_tree().current_scene else ""


func run() -> void:
	var fake := fake_bridge()
	fake.sent.clear()
	BridgeClient._engine_ready_sent = false
	BridgeClient._go_idle()
	await frames()
	check(count("engine_ready") == 1 and scene() == BridgeClient.IDLE_SCENE, "idle.tscn manda engine_ready")

	fake.start_level.emit("{malo")
	check(last("bridge_error") != null and last("bridge_error")["code"] == "invalid_json", "JSON inválido → invalid_json")
	fake.start_level.emit('{"v":2,"level_id":99,"mode":"peque","kiosk":false,"muted":false}')
	check(last("bridge_error")["code"] == "unsupported_version", "v=2 → unsupported_version")
	fake.start_level.emit('{"v":1,"level_id":50,"mode":"peque","kiosk":false,"muted":false}')
	check(last("bridge_error")["code"] == "unknown_level", "nivel 50 → unknown_level")
	fake.start_level.emit('{"v":1,"level_id":3,"mode":"peque","kiosk":false,"muted":false}')
	check(last("bridge_error")["code"] == "level_not_built", "nivel 3 (sin escena) → level_not_built")
	fake.start_level.emit('{"v":1,"level_id":99,"mode":"mediano","kiosk":false,"muted":false}')
	check(last("bridge_error")["code"] == "invalid_field", "modo inválido → invalid_field")
	check(BridgeClient.state == BridgeClient.State.IDLE and count("level_started") == 0, "después de los errores sigue en idle")

	fake.send_start(99)
	await frames()
	check(scene() == "res://scenes/bridge/level_test.tscn" and last("level_started")["level_id"] == 99, "start_level 99 → level_started")
	check(GameState.level != null and GameState.level.id == 99, "GameState.level = 99")
	var rm := get_tree().get_first_node_in_group(&"rule_manager") as RuleManager
	rm.report_infraction(&"stop", "FALTA_ALTO")
	await wait(0.3)
	fake.pause_level.emit()
	await wait(2.2)
	check(get_tree().paused, "pause_level durante la pausa de una falta: sigue en pausa después de 2 s")
	fake.resume_level.emit()
	check(not get_tree().paused, "resume_level quita la pausa")
	await wait_unpaused()
	await wait(1.0)  # un segundo jugando, para que duration_s tenga qué contar
	rm.report_infraction(&"stop", "FALTA_ALTO")
	await wait(2.1)
	rm.report_infraction(&"speed", "FALTA_ALTO")
	await wait(2.1)
	rm.finish_level()
	await frames()
	var fin: Variant = last("level_finished")
	check(fin != null and fin["stars"] == 1 and fin["level_id"] == 99, "level_finished con 1 estrella (3 faltas)")
	check(fin != null and fin["infractions"] == {"stop": 2.0, "speed": 1.0}, "infractions por regla")
	check(fin != null and fin["duration_s"] >= 1 and fin["duration_s"] <= 3, "duration_s sin contar pausas (%s s)" % str(fin["duration_s"] if fin else "?"))
	check(BridgeClient.state == BridgeClient.State.PLAYING and count("level_exited") == 0, "la vista sigue abierta para la tarjeta")
	await wait(1.6)
	var card := get_tree().current_scene.get_node("HabitCard") as HabitCard
	check(card.visible and get_tree().paused, "tarjeta de hábito abierta y juego en pausa")
	fake.pause_level.emit()
	fake.resume_level.emit()
	check(get_tree().paused, "pausa y regreso con la tarjeta abierta: sigue en pausa")

	var started := count("level_started")
	card.get_node("%Retry").pressed.emit()
	await frames()
	check(count("level_started") == started + 1 and not get_tree().paused, "Repetir → level_started otra vez, sin pausa")
	rm = get_tree().get_first_node_in_group(&"rule_manager") as RuleManager
	check(rm.faults == 0 and rm.infractions.is_empty(), "Repetir empieza de cero")

	get_tree().current_scene.get_node("%Exit").pressed.emit()
	await frames()
	check(last("level_exited") == {"v": 1.0, "level_id": 99.0, "completed": false}, "Salir → level_exited completed false")
	check(scene() == BridgeClient.IDLE_SCENE and count("engine_ready") == 1, "vuelve a idle sin repetir engine_ready")
	check(GameState.level == null, "GameState.level = null en idle")

	fake.send_start(99)
	await frames()
	(get_tree().get_first_node_in_group(&"rule_manager") as RuleManager).finish_level()
	await wait(1.6)
	get_tree().current_scene.get_node("HabitCard/%Continue").pressed.emit()
	await frames()
	check(last("level_exited")["completed"] == true and scene() == BridgeClient.IDLE_SCENE, "Continuar → level_exited completed true e idle")

	fake.send_start(99)
	await frames()
	var exited := count("level_exited")
	fake.send_start(1)
	await frames()
	check(count("level_exited") == exited + 1 and last("level_exited")["level_id"] == 99, "start_level encima de otro: cierra el anterior")
	check(last("level_started")["level_id"] == 1, "abre el nivel 1")
	fake.abort_level.emit()
	await frames()
	check(last("level_exited")["level_id"] == 1 and last("level_exited")["completed"] == false and scene() == BridgeClient.IDLE_SCENE, "abort_level → level_exited e idle")

	var limit := BridgeClient.inactivity_limit
	BridgeClient.inactivity_limit = 1.0
	fake.send_start(99, true, true)
	await frames()
	check(GameState.kiosk and AudioServer.is_bus_mute(0), "kiosk y muted se aplican")
	await wait(1.4)
	check(count("inactivity_timeout") == 1, "kiosco: inactivity_timeout sin tocar la pantalla")
	await wait(1.4)
	check(count("inactivity_timeout") == 1, "inactivity_timeout solo una vez hasta que vuelvan a tocar")
	fake.set_muted.emit(false)
	check(not AudioServer.is_bus_mute(0), "set_muted(false)")
	BridgeClient.inactivity_limit = limit
	BridgeClient.exit_level(false)
	GameState.kiosk = false
	await frames()
