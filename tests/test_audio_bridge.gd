extends TestCase
## Audio al abrir y cerrar niveles por el puente, como en las apps nativas: el
## motor suena dentro del nivel, y al salir no se queda ni la música ni el motor
## sonando sobre el menú nativo (Godot nunca se cierra entre niveles).


func run() -> void:
	var fake := fake_bridge()
	BridgeClient._go_idle()
	await frames()

	fake.start_level.emit('{"v":1,"level_id":1,"mode":"grande","kiosk":false,"muted":false}')
	await frames(6)
	check(AudioManager.is_loop_playing(&"engine"), "al abrir un nivel por el puente el motor suena")
	check(AudioManager.is_music_playing(), "al abrir un nivel por el puente suena la música")

	fake.pause_level.emit()
	check(AudioManager._music.stream_paused, "pause_level detiene la música")
	fake.resume_level.emit()
	check(not AudioManager._music.stream_paused, "resume_level la sigue")

	BridgeClient.retry_level()
	await frames(6)
	check(AudioManager.is_loop_playing(&"engine"), "al repetir el nivel el motor vuelve a sonar")
	check(AudioManager.is_music_playing(), "al repetir el nivel la música vuelve a sonar")

	fake.abort_level.emit()
	await frames(6)
	check(not AudioManager.is_music_playing(), "al salir del nivel la música se apaga")
	check(not AudioManager.is_loop_playing(&"engine"), "al salir del nivel el motor se apaga")

	# La pausa de una falta tiene tope aunque la voz dure más.
	var longest := 0.0
	for key in ["FALTA_PACIENCIA", "FALTA_PELOTA", "FALTA_MIRA"]:
		longest = maxf(longest, Feedback.infraction_pause_time(key))
	check(longest <= Feedback.max_infraction_pause + 0.001, "la pausa de una falta nunca pasa de max_infraction_pause")
	check(longest >= Feedback.pause_time, "la pausa de una falta dura al menos pause_time")
