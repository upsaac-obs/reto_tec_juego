# Creación y desarrollo: Dylan Isaac Mancilla López
extends TestCase
## Todo mensaje dura lo que su voz más message_time (sin voz, solo
## message_time). En una falta, la pausa dura lo mismo que el mensaje y no
## tiene tope. Si la falta es saltable, un toque tras skip_pause_delay quita la
## pausa (el mensaje sigue).


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

	await _skip_pause(box)

	Feedback.voice_played.disconnect(on_voice)
	Feedback._voices.clear()
	Feedback.clear()
	get_tree().paused = false


## Clic izquierdo (Godot lo emula de un toque en el celular, y al revés en la PC).
func click(pressed := true) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	# push_input recibe coordenadas de ventana (en headless la ventana es de 64 px).
	event.position = get_tree().root.get_final_transform() * Vector2(50.0, 50.0)
	event.global_position = event.position
	event.pressed = pressed
	get_tree().root.push_input(event)


## Toque para saltar la pausa: solo en faltas saltables y tras skip_pause_delay.
func _skip_pause(box: Control) -> void:
	check(is_equal_approx(Feedback.skip_pause_delay, 0.5), "la espera mínima para saltar la pausa es 0.5 s por defecto")
	Feedback._voices["FALTA_ALTO"] = fake_voice(1.0)
	var hold := Feedback.message_duration("FALTA_ALTO")

	# La primera vez (no saltable): tocar no quita la pausa.
	Feedback.show_infraction("FALTA_ALTO")
	await wait(Feedback.skip_pause_delay + 0.1)
	touch()
	touch(false)
	check(get_tree().paused and Feedback.is_pausing(), "falta no saltable: el toque no quita la pausa")
	Feedback.clear()
	get_tree().paused = false
	await frames(1)

	# Saltable: antes de skip_pause_delay el toque no hace nada.
	Feedback.show_infraction("FALTA_ALTO", true)
	await frames(1)
	touch()
	touch(false)
	check(get_tree().paused and Feedback.is_pausing(), "falta saltable: un toque antes de skip_pause_delay no quita la pausa")
	# wait() cuenta en cuadros de física; el margen cubre la diferencia con el reloj real.
	await wait(Feedback.skip_pause_delay + 0.1)
	BridgeClient._idle_time = 30.0
	touch()
	check(not get_tree().paused and not Feedback.is_pausing(), "falta saltable: el toque tras skip_pause_delay quita la pausa")
	check(BridgeClient._idle_time == 0.0, "el toque que salta la pausa reinicia el reloj de inactividad del kiosco")
	check(box.visible, "al saltar la pausa el mensaje sigue en pantalla")
	touch(false)
	await wait(hold - Feedback.skip_pause_delay - 0.5)
	check(box.visible, "el mensaje sigue hasta su duración normal")
	await wait(0.6)
	check(not box.visible, "el mensaje se va a la voz más message_time, como siempre")

	# El toque que salta no llega a la interfaz (ni el clic que Godot emula de él).
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	var button := Button.new()
	button.position = Vector2.ZERO
	button.size = Vector2(300.0, 300.0)
	layer.add_child(button)
	add_child(layer)
	var downs := [0]
	button.button_down.connect(func() -> void: downs[0] += 1)
	await frames(1)
	click()
	click(false)
	check(downs[0] == 1, "sin pausa, el clic llega al botón (control de la prueba)")
	Feedback.show_infraction("FALTA_ALTO", true)
	await wait(Feedback.skip_pause_delay + 0.1)
	touch()
	click()
	check(not get_tree().paused, "el toque quita la pausa")
	check(downs[0] == 1, "el toque que quita la pausa no aprieta el botón de abajo")
	touch(false)
	click(false)
	# wait() termina en la física: frames(1) podría seguir en el mismo cuadro.
	await frames(2)
	click()
	click(false)
	check(downs[0] == 2, "el siguiente toque ya llega normal a la interfaz")
	layer.queue_free()
	Feedback.clear()
	get_tree().paused = false
