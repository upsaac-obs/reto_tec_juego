extends TestCase
## Todo mensaje dura lo que su voz más message_time (sin voz, solo
## message_time). En una falta, la pausa dura lo mismo que el mensaje y no
## tiene tope.


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

	# Sin voz: message_time.
	Feedback._voices["FALTA_ALTO"] = null
	check(is_equal_approx(Feedback.message_duration("FALTA_ALTO"), Feedback.message_time), "sin voz la falta dura message_time")

	# Con voz: la voz más message_time.
	Feedback._voices["FALTA_ALTO"] = fake_voice(3.0)
	check(is_equal_approx(Feedback.message_duration("FALTA_ALTO"), 3.0 + Feedback.message_time), "con voz de 3 s la falta dura la voz más message_time")

	# Voz muy larga: ya no hay tope.
	Feedback._voices["FALTA_ALTO"] = fake_voice(8.0)
	check(is_equal_approx(Feedback.message_duration("FALTA_ALTO"), 8.0 + Feedback.message_time), "con voz de 8 s la falta dura la voz más message_time (sin tope)")

	# La pausa y el mensaje de la falta duran lo mismo y se van juntos.
	Feedback._voices["FALTA_ALTO"] = fake_voice(1.0)
	var expected := 1.0 + Feedback.message_time
	Feedback.show_infraction("FALTA_ALTO")
	await frames(1)
	check(played.size() == 1 and played[0][0] == "FALTA_ALTO" and is_equal_approx(played[0][1], 1.0), "voice_played avisa la clave y lo que dura la voz")
	await wait(expected - 0.3)
	check(get_tree().paused and box.visible, "sigue en pausa y con mensaje mientras dura la voz más message_time")
	await wait(0.5)
	check(not get_tree().paused and not Feedback.is_pausing(), "al terminar la voz más message_time se quita la pausa")
	check(not box.visible, "el mensaje se va junto con la pausa")

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
