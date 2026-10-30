extends TestCase
## Cajón y puerta del final del nivel 3 (levels/level_03.tscn). El cajón y la
## puerta están en x = 5500; la ruta empieza en x = 64, así que ahí el auto
## marca progress = 5436. El último cruce y su punto de control quedan atrás.

const SPOT_PROGRESS := 5436.0

var level: Node
var rm: RuleManager
var car: PlayerCar
var spot: ParkingSpot
var door: DoorExit
var driver: TestDriver
var finished: bool = false
var cyclists_seen: int = 0


func open_level(mode: String) -> void:
	GameState.mode = mode
	finished = false
	cyclists_seen = 0
	level = await open_scene("res://levels/level_03.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	rm.level_finished.connect(func(_stars: int) -> void: finished = true)
	car = rm.car
	car.seatbelt_on = true
	spot = level.get_node("Rules/ParkingSpot") as ParkingSpot
	door = level.get_node("Rules/DoorExit") as DoorExit
	door.child_entered_tree.connect(func(node: Node) -> void:
		if node is Cyclist:
			cyclists_seen += 1)
	for piece in level.get_node("Rules").get_children():
		if piece is BlindCrossing:
			(piece as BlindCrossing).traffic = false
	driver = TestDriver.new()
	driver.car = car
	add_child(driver)


func close_level() -> void:
	driver.stop_driving()
	driver.queue_free()
	release_inputs()
	await close_scene(level)
	GameState.mode = GameState.MODE_GRANDE


## Espera hasta que la condición sea verdadera o pasen `timeout` segundos de juego.
func wait_until(condition: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while not condition.call() and elapsed < timeout:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	return condition.call()


func run() -> void:
	# 1. Modo grande: llega rápido, el cajón lo frena y lo deja en el centro
	await open_level(GameState.MODE_GRANDE)
	car.restart_at(5000.0)
	driver.target = 200.0
	var arrived := await wait_until(func() -> bool: return spot.is_parked(), 25.0)
	check(arrived, "el auto se estaciona en el cajón")
	check(absf(car.progress - SPOT_PROGRESS) <= 4.0, "se detiene con el centro del auto en el centro del cajón")
	check(car.speed == 0.0 and car.progress < 5600.0, "queda detenido y no llega al final de la ruta")
	check(rm.faults == 0, "estacionarse no da faltas")
	check(not finished, "el nivel no termina solo al estacionarse")
	driver.stop_driving()
	check(door.get_node("Layer").visible, "aparece el botón Abrir puerta")

	# 2. Abrir la puerta con un ciclista cerca es falta; la puerta queda cerrada
	door.interval_min = 2.0
	door.interval_max = 2.5
	var max_at_once := 0
	var near := false
	var elapsed := 0.0
	while not near and elapsed < 15.0:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
		max_at_once = maxi(max_at_once, get_tree().get_nodes_in_group(&"cyclist").size())
		near = door.is_cyclist_near()
	check(near, "al estacionarse ya viene un ciclista cerca de la puerta")
	var points := rm.points
	door.open_door()
	check(rm.infractions.get(&"look", 0) == 1 and rm.faults == 1, "abrir con un ciclista cerca es falta look")
	check(rm.points == points and not finished, "esa falta no da puntos ni termina el nivel")
	await wait_unpaused()
	door.open_door()
	check(rm.faults == 1, "con la puerta cerrada otra vez, tocar el botón no suma otra falta")
	elapsed = 0.0
	while elapsed < 12.0 and max_at_once < 2:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
		max_at_once = maxi(max_at_once, get_tree().get_nodes_in_group(&"cyclist").size())
	check(max_at_once >= 2 or cyclists_seen >= 2, "en modo grande pasan varios ciclistas")

	# 3. Abrir después de que pasa: +10 y termina el nivel
	door.interval_min = 60.0
	door.interval_max = 60.0
	await wait_until(func() -> bool: return not door.is_cyclist_near(), 20.0)
	points = rm.points
	door.open_door()
	check(rm.points == points + 10, "abrir sin ciclistas cerca da +10")
	await wait(door.finish_delay + 0.5)
	check(finished, "al abrir la puerta termina el nivel")
	check(rm.faults == 1, "las estrellas cuentan la falta anterior (1 falta)")
	await close_level()

	# 4. Modo peque: avanza solo, se estaciona y pasa un solo ciclista
	await open_level(GameState.MODE_PEQUE)
	car.restart_at(5000.0)
	arrived = await wait_until(func() -> bool: return spot.is_parked(), 30.0)
	check(arrived and absf(car.progress - SPOT_PROGRESS) <= 4.0, "en modo peque el auto avanza solo y se estaciona en el cajón")
	await wait(14.0)
	check(cyclists_seen == 1, "en modo peque pasa un solo ciclista")
	check(not door.is_cyclist_near(), "ya pasó: la puerta se puede abrir")
	door.open_door()
	await wait(door.finish_delay + 0.5)
	check(finished and rm.faults == 0, "abrir después de que pasa termina el nivel sin faltas")
	await close_level()

	# 5. Otro carril: espera en la marca y se estaciona al cambiarse con la flecha
	await open_level(GameState.MODE_GRANDE)
	car.lane_index = 0
	car.restart_at(5000.0)
	driver.target = 150.0
	await wait_until(func() -> bool: return car.progress >= SPOT_PROGRESS - 4.0 and car.speed == 0.0, 25.0)
	driver.stop_driving()
	await wait(0.5)
	check(not spot.is_parked(), "en el carril de la izquierda no cuenta como estacionado")
	await tap(&"car_right")
	arrived = await wait_until(func() -> bool: return spot.is_parked(), 5.0)
	check(arrived, "al cambiarse al carril del cajón queda estacionado")
	await close_level()
