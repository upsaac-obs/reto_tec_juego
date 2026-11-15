extends TestCase
## La pausa de una falta dura lo que dure su voz (mínimo pause_time) y el
## mensaje se queda al menos lo mismo. Sin voz, todo sigue igual (2 s).
## Los consejos (show_info) y acciones buenas duran la voz más message_time.


## Voz falsa de `seconds` segundos (silencio de 8 bits a 8 kHz).
func fake_voice(seconds: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	var data := PackedByteArray()
	data.resize(int(8000 * seconds))
	wav.data = data
	return wav


func run() -> void:
	var box := Feedback._bubble.get_node("%Box") as Control
	var played: Array = []
	var on_voice := func(key: String, length: float) -> void: played.append([key, length])
	Feedback.voice_played.connect(on_voice)

	# Sin voz: pause_time.
	Feedback._voices["FALTA_ALTO"] = null
	check(is_equal_approx(Feedback.infraction_pause_time("FALTA_ALTO"), Feedback.pause_time), "sin voz la pausa dura pause_time")

	# Voz corta: no baja de pause_time.
	Feedback._voices["FALTA_ALTO"] = fake_voice(1.0)
	check(is_equal_approx(Feedback.infraction_pause_time("FALTA_ALTO"), Feedback.pause_time), "con voz corta la pausa sigue siendo pause_time")

	# Voz muy larga: la pausa tiene tope (la voz sigue con el juego en marcha).
	Feedback._voices["FALTA_ALTO"] = fake_voice(8.0)
	check(is_equal_approx(Feedback.infraction_pause_time("FALTA_ALTO"), Feedback.max_infraction_pause), "con voz de 8 s la pausa se queda en max_infraction_pause")

	# Voz algo larga: la pausa y el mensaje la esperan.
	Feedback._voices["FALTA_ALTO"] = fake_voice(2.5)
	var expected := 2.5 + Feedback.voice_margin
	check(is_equal_approx(Feedback.infraction_pause_time("FALTA_ALTO"), expected), "con voz de 2.5 s la pausa dura la voz más el margen")
	Feedback.show_infraction("FALTA_ALTO")
	await frames(1)
	check(played.size() == 1 and played[0][0] == "FALTA_ALTO" and is_equal_approx(played[0][1], 2.5), "voice_played avisa la clave y lo que dura la voz")
	await wait(expected - 0.3)
	check(get_tree().paused and box.visible, "sigue en pausa y con mensaje mientras habla")
	await wait(0.5)
	check(not get_tree().paused, "al terminar la voz (más el margen) se quita la pausa")
	await wait(Feedback.message_time)
	check(not box.visible, "el mensaje se va después")

	# Consejos y acciones buenas: duran la voz más message_time.
	Feedback._voices["TUTO_PRUEBA"] = null
	check(is_equal_approx(Feedback.message_duration("TUTO_PRUEBA"), Feedback.message_time), "sin voz el consejo dura message_time")
	Feedback._voices["TUTO_PRUEBA"] = fake_voice(3.0)
	check(is_equal_approx(Feedback.message_duration("TUTO_PRUEBA"), 3.0 + Feedback.message_time), "con voz de 3 s el consejo dura la voz más message_time")

	# Regresión: antes el consejo se escondía a los message_time aunque la voz siguiera.
	Feedback._voices["TUTO_PRUEBA"] = fake_voice(1.0)
	var info_time := 1.0 + Feedback.message_time
	Feedback.show_info("TUTO_PRUEBA")
	await frames(1)
	check(box.visible and not get_tree().paused, "el consejo aparece sin pausar")
	await wait(info_time - 0.3)
	check(box.visible, "el consejo sigue visible mientras dura la voz más message_time")
	await wait(0.5)
	check(not box.visible, "el consejo se va al terminar la voz más message_time")

	Feedback.voice_played.disconnect(on_voice)
	Feedback._voices.clear()
	Feedback.clear()
	get_tree().paused = false
