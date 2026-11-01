extends TestCase
## AudioManager: buses, efectos, bucles y música (los .wav/.ogg de tools/gen_*.py).


func run() -> void:
	check(AudioServer.get_bus_index(AudioManager.BUS_MUSIC) != -1, "existe el bus de música")
	check(AudioServer.get_bus_index(AudioManager.BUS_SFX) != -1, "existe el bus de efectos")

	var missing: PackedStringArray = []
	for sfx in ["brake", "horn", "celebration", "fault", "phone_ring", "phone_vibrate",
			"lights_on", "door_open", "bus_stop", "coin", "good"]:
		if not ResourceLoader.exists(AudioManager.SFX_PATH % sfx):
			missing.append(sfx)
	check(missing.is_empty(), "existen todos los efectos %s" % missing)

	var no_loop: PackedStringArray = []
	for loop_name: StringName in AudioManager.LOOPS:
		var wav := load(AudioManager.SFX_PATH % AudioManager.LOOPS[loop_name]) as AudioStreamWAV
		if wav == null or wav.loop_mode != AudioStreamWAV.LOOP_FORWARD:
			no_loop.append(loop_name)
	check(no_loop.is_empty(), "los .wav de bucle se importan en bucle %s" % no_loop)

	var music := load(AudioManager.MUSIC_LEVEL) as AudioStreamOggVorbis
	check(music != null and music.loop, "la música del nivel se importa en bucle")
	var length := music.get_length() if music else 0.0
	check(length >= 60.0 and length <= 90.0, "la música dura entre 60 y 90 s (%.1f)" % length)

	AudioManager.play_sfx(&"horn")
	AudioManager.start_loop(&"engine")
	AudioManager.start_loop(&"engine")
	check(AudioManager.is_loop_playing(&"engine"), "el motor suena en bucle")
	AudioManager.set_loop_pitch(&"engine", 1.4)
	AudioManager.stop_loop(&"engine")
	check(not AudioManager.is_loop_playing(&"engine"), "stop_loop lo para")
	AudioManager.start_loop(&"rain")
	AudioManager.start_loop(&"turn_signal")
	AudioManager.stop_all_loops()
	check(not AudioManager.is_loop_playing(&"rain") and not AudioManager.is_loop_playing(&"turn_signal"),
			"stop_all_loops para todos")

	AudioManager.play_music()
	check(AudioManager.is_music_playing(), "play_music empieza la música")
	AudioManager.set_music_enabled(false)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(AudioManager.BUS_MUSIC)), "set_music_enabled(false) apaga la música")
	AudioManager.set_music_enabled(true)
	AudioManager.stop_music()
	await wait(AudioManager.music_fade + 0.2)
	check(not AudioManager.is_music_playing(), "stop_music la para con fundido")

	# Voces del copiloto: si falta alguna solo se avisa (otras ramas agregan
	# claves a textos.csv; se generan con python3 tools/gen_voces.py).
	var f := FileAccess.open("res://i18n/textos.csv", FileAccess.READ)
	var sin_voz: PackedStringArray = []
	f.get_csv_line()
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() > 0 and row[0] != "" and not ResourceLoader.exists("res://assets/audio/voz/%s.ogg" % row[0]):
			sin_voz.append(row[0])
	if not sin_voz.is_empty():
		print("  AVISO claves sin voz (corre tools/gen_voces.py): %s" % ", ".join(sin_voz))
	check(ResourceLoader.exists("res://assets/audio/voz/FALTA_ALTO.ogg"), "hay voces generadas")
