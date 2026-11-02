extends TestCase
## Tablero de salidas (nivel 5) en levels/level_05.tscn: siempre dice "A
## tiempo", no se puede perder por tiempo y al llegar el copiloto dice
## "¡Llegamos a tiempo!".

const BOARD_SCENE := preload("res://scenes/rules/departure_board.tscn")

var level: Node
var rm: RuleManager
var car: PlayerCar
var board: DepartureBoard
var driver: TestDriver


func run() -> void:
	# 1 y 2. Manejando muy despacio todo el nivel: el tablero nunca cambia y se gana igual
	level = await open_scene("res://levels/level_05.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	car = rm.car
	car.seatbelt_on = true
	board = level.get_node("Rules/DepartureBoard") as DepartureBoard
	var finished := [false, 0]
	rm.level_finished.connect(func(stars: int) -> void:
		finished[0] = true
		finished[1] = stars)
	driver = TestDriver.new()
	driver.car = car
	add_child(driver)
	driver.target = 40.0
	var digits := RegEx.create_from_string("\\d")
	var always_on_time := board.has_widget()
	var no_digits := true
	Engine.time_scale = 4.0
	var t := 0.0
	var next_check := 0.0
	while not finished[0] and t < 400.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if t >= next_check:
			next_check += 1.0
			var texts := board.widget_texts()
			always_on_time = always_on_time and texts.has(tr("TABLERO_A_TIEMPO"))
			for text in texts:
				no_digits = no_digits and digits.search(text) == null
	Engine.time_scale = 1.0
	check(always_on_time, "el tablero siempre dice A tiempo")
	check(no_digits, "el tablero no muestra números ni horas")
	check(finished[0] and finished[1] == 3 and rm.faults == 0, "manejando muy despacio se termina con 3 estrellas y sin faltas (%.0f s de juego)" % t)

	# 3. Al llegar el copiloto dice "¡Llegamos a tiempo!"
	await frames(2)
	var label := Feedback._bubble.get_node("%MessageLabel") as Label
	check(label.text == tr("LLEGADA_A_TIEMPO"), "al llegar el copiloto dice Llegamos a tiempo")
	driver.stop_driving()
	driver.queue_free()
	release_inputs()
	await close_scene(level)

	# 4. Widget en peque
	GameState.mode = GameState.MODE_PEQUE
	for show in [true, false]:
		var piece := BOARD_SCENE.instantiate() as DepartureBoard
		piece.show_in_peque = show
		add_child(piece)
		await frames(1)
		check(piece.has_widget() == show, "peque con show_in_peque = %s: widget %s" % [show, "sí" if show else "no"])
		piece.queue_free()
	GameState.mode = GameState.MODE_GRANDE
	await frames(2)
