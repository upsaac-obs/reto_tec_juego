extends TestCase
## Pelota en la calle (nivel 5) en levels/level_05.tscn: Rules/BallEvent en
## x = 4800. Las distancias son progreso sobre la ruta (la ruta empieza en
## x = 64) y el Hitbox del auto llega HALF_CAR px delante de su centro.

## Progreso del auto cuando su frente llega al disparo (x = 4520).
const TRIGGER := 4423.0
## Progreso del inicio de la zona de falta (x = 4752).
const ZONE := 4688.0
const HALF_CAR := 33.0
## Antes del punto de control de la calle de los autos estacionados (x = 4160).
const START := 4050.0

var level: Node
var rm: RuleManager
var car: PlayerCar
var ball: BallEvent
var driver: TestDriver


func open_level() -> void:
	level = await open_scene("res://levels/level_05.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	car = rm.car
	car.seatbelt_on = true
	ball = level.get_node("Rules/BallEvent") as BallEvent
	driver = TestDriver.new()
	driver.car = car
	add_child(driver)


func close_level() -> void:
	driver.stop_driving()
	driver.queue_free()
	release_inputs()
	await close_scene(level)


func wait_until(condition: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while not condition.call() and elapsed < timeout:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	return condition.call()


func child_animation() -> StringName:
	return (ball.get_node("Child/Sprite") as AnimatedSprite2D).animation


## Maneja a 110 px/s y frena en cuanto sale la pelota. Devuelve el progreso máximo.
func drive_and_yield() -> float:
	driver.brake_after = INF
	driver.target = 110.0
	await wait_until(func() -> bool: return ball.is_occupied(), 20.0)
	driver.brake_after = car.progress
	var max_progress := car.progress
	while ball.is_occupied():
		await get_tree().physics_frame
		max_progress = maxf(max_progress, car.progress)
	return max_progress


func run() -> void:
	# 0. Estructura del nivel 5
	var data := LevelData.load_by_id(5)
	check(data.scene_path == "res://levels/level_05.tscn" and data.decalogo_key == "DECALOGO_02", "data/level_05.tres apunta a su escena y usa DECALOGO_02")
	await open_level()
	for path in ["Rules/YellowCrossing1", "Rules/YellowCrossing2"]:
		var light := (level.get_node(path) as YellowCrossing).get_light()
		check(light.check_yellow and is_equal_approx(light.reaction_time, 1.0), "%s revisa el amarillo con 1 s de reacción" % path)
	var zone30 := level.get_node("Rules/SpeedZone30") as SpeedZone
	check(zone30.limit_kmh == 30 and zone30.position.x < 4800.0 and zone30.position.x + zone30.zone_length > 4800.0, "la pelota está dentro de la zona de 30")
	var missing: Array[String] = []
	for key in ["PRISA_INTRO", "PRISA_AMARILLO_AVISO", "PRISA_AMARILLO_AVISO_PEQUE", "BIEN_AMARILLO", "PRISA_TABLERO_AVISO",
			"PELOTA_CALLE_AVISO", "FALTA_PELOTA", "BIEN_PELOTA", "LLEGADA_A_TIEMPO", "TABLERO_TITULO", "TABLERO_AUTOBUS", "TABLERO_A_TIEMPO"]:
		if tr(key) == key:
			missing.append(key)
	check(missing.is_empty(), "las 12 claves nuevas del nivel 5 existen en textos.csv %s" % str(missing))

	# 1. Frenar a tiempo da +10
	car.restart_at(START)
	var max_progress := await drive_and_yield()
	check(max_progress + HALF_CAR < ZONE, "frenando al ver la pelota el auto no entra a la zona (%d)" % int(max_progress))
	check(ball.get_state() == BallEvent.State.CLEAR or ball.get_state() == BallEvent.State.GONE, "la niña llega a la otra banqueta")
	await wait(0.2)
	check(rm.points == 10 and rm.faults == 0, "frenar a tiempo da +10 sin faltas")
	driver.brake_after = INF
	await wait_until(func() -> bool: return car.progress >= 4836.0, 15.0)
	check(car.progress >= 4836.0 and rm.faults == 0 and rm.points == 10, "con la calle libre el auto sigue sin más faltas")
	await close_level()

	# 2. La pelota sale primero y la calle queda ocupada
	await open_level()
	car.restart_at(START)
	driver.target = 110.0
	var early_occupied := false
	while not ball.is_occupied() and car.progress < ZONE:
		await get_tree().physics_frame
		early_occupied = early_occupied or (ball.is_occupied() and car.progress < TRIGGER - 6.0)
	check(not early_occupied and absf(car.progress - TRIGGER) < 6.0, "la calle está libre hasta que el auto llega al disparo (%d)" % int(car.progress))
	check(ball.is_occupied() and ball.is_ball_visible() and not ball.is_child_visible(), "primero sale la pelota sola")
	driver.brake_after = car.progress
	await wait(ball.child_delay + 0.1)
	check(ball.is_child_visible() and ball.is_occupied(), "a los child_delay s sale la niña y la calle sigue ocupada")
	await close_level()

	# 3. Ir rápido: frena solo y es falta grave
	await open_level()
	car.restart_at(START)
	driver.target = 240.0
	await wait_until(func() -> bool: return rm.infractions.get(&"crosswalk", 0) > 0, 15.0)
	var fault_front := car.progress + HALF_CAR
	check(rm.infractions.get(&"crosswalk", 0) == 1, "ir rápido entre autos estacionados es falta grave (crosswalk)")
	check(fault_front < ZONE + 8.0 and car.speed == 0.0, "el auto frena solo al entrar a la zona, antes de la niña (%d)" % int(fault_front))
	check(child_animation() == &"scared", "la niña se asusta")

	# 5. Una sola falta por pasada, aunque el auto siga en la zona
	var restored := [false]
	rm.checkpoint_restored.connect(func(_p: float) -> void: restored[0] = true)
	var single := true
	while not restored[0]:
		await get_tree().physics_frame
		single = single and rm.infractions.get(&"crosswalk", 0) == 1
	check(single, "una sola falta por pasada")

	# 4. Después de la falta grave se repite desde el punto de control
	await wait_unpaused()
	await frames(2)
	var checkpoint := rm.get_checkpoint()
	check(absf(car.progress - checkpoint) < 2.0 and checkpoint > 4030.0 and checkpoint < 4110.0, "regresa al punto de control de la calle (%d)" % int(car.progress))
	check(ball.get_state() == BallEvent.State.IDLE and not ball.is_ball_visible() and not ball.is_child_visible() and not ball.is_occupied(), "la pelota y la niña vuelven a esconderse")
	max_progress = await drive_and_yield()
	await wait(0.2)
	check(max_progress + HALF_CAR < ZONE and rm.points == 10 and rm.infractions.get(&"crosswalk", 0) == 1, "la segunda vez frena a tiempo: +10 y sigue con 1 falta grave")
	await close_level()

	# 6. Peque: frenar a tiempo da +10
	GameState.mode = GameState.MODE_PEQUE
	await open_level()
	car.restart_at(START)
	await wait_until(func() -> bool: return ball.is_occupied(), 20.0)
	Input.action_press(&"car_brake")
	max_progress = car.progress
	while ball.is_occupied():
		await get_tree().physics_frame
		max_progress = maxf(max_progress, car.progress)
	Input.action_release(&"car_brake")
	await wait(0.2)
	check(max_progress + HALF_CAR < ZONE and rm.points == 10 and rm.faults == 0, "peque: frenar al ver la pelota da +10 sin faltas")
	await close_level()

	# 7. Peque: sin frenar, frena solo y es falta grave
	await open_level()
	car.restart_at(START)
	await wait_until(func() -> bool: return rm.infractions.get(&"crosswalk", 0) > 0, 20.0)
	check(rm.infractions.get(&"crosswalk", 0) == 1 and car.progress + HALF_CAR < ZONE + 8.0, "peque: sin frenar el auto frena solo y es falta grave")
	await close_level()
	GameState.mode = GameState.MODE_GRANDE
