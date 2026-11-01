extends TestCase
## La pausa de una falta dura lo que dure su voz (mínimo pause_time) y el
## mensaje se queda al menos lo mismo. Sin voz, todo sigue igual (2 s).


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

	# Voz larga: la pausa y el mensaje la esperan.
	Feedback._voices["FALTA_ALTO"] = fake_voice(3.5)
	var expected := 3.5 + Feedback.voice_margin
	check(is_equal_approx(Feedback.infraction_pause_time("FALTA_ALTO"), expected), "con voz de 3.5 s la pausa dura la voz más el margen")
	Feedback.show_infraction("FALTA_ALTO")
	await frames(1)
	check(played.size() == 1 and played[0][0] == "FALTA_ALTO" and is_equal_approx(played[0][1], 3.5), "voice_played avisa la clave y lo que dura la voz")
	await wait(expected - 0.3)
	check(get_tree().paused and box.visible, "sigue en pausa y con mensaje mientras habla")
	await wait(0.5)
	check(not get_tree().paused, "al terminar la voz (más el margen) se quita la pausa")
	await wait(Feedback.message_time)
	check(not box.visible, "el mensaje se va después")

	Feedback.voice_played.disconnect(on_voice)
	Feedback._voices.clear()
	Feedback.clear()
	get_tree().paused = false
