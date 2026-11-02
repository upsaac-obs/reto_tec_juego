extends TestCase
## Cajón reutilizable (nivel 6): ParkingSpot puede soltar al auto después de
## estacionarse y DoorExit usa su propio cajón. Se prueba sobre levels/level_03.tscn
## (cajón en progress = 5436, la ruta sigue unos px más).

const SPOT_PROGRESS := 5436.0

var level: Node
var rm: RuleManager
var car: PlayerCar
var spot: ParkingSpot
var door: DoorExit
var finished: bool = false


func open_level() -> void:
	GameState.mode = GameState.MODE_PEQUE
	finished = false
	level = await open_scene("res://levels/level_03.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	rm.level_finished.connect(func(_stars: int) -> void: finished = true)
	car = rm.car
	car.seatbelt_on = true
	spot = level.get_node("Rules/ParkingSpot") as ParkingSpot
	door = level.get_node("Rules/DoorExit") as DoorExit


func close_level() -> void:
	release_inputs()
	await close_scene(level)
	GameState.mode = GameState.MODE_GRANDE


func wait_until(condition: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while not condition.call() and elapsed < timeout:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	return condition.call()


func run() -> void:
	# 1. El nivel 3 sigue igual: DoorExit apunta a su cajón y no lo suelta solo
	await open_level()
	check(door.spot == spot, "DoorExit del nivel 3 usa su propio cajón (spot asignado)")
	check(not spot.release_after_park and door.finish_level_on_open, "nivel 3: el cajón no suelta el auto y la puerta termina el nivel")
	car.restart_at(5000.0)
	await wait_until(func() -> bool: return spot.is_parked(), 30.0)
	await wait(2.5)
	check(spot.is_parked() and not spot.is_released() and car.speed == 0.0, "sin release_after_park el auto se queda en el cajón")
	await close_level()

	# 2. release_after_park: se estaciona, espera release_delay y sigue la ruta
	await open_level()
	spot.release_after_park = true
	spot.release_delay = 1.0
	spot.parked_message_key = ""
	var bubble_box := Feedback._bubble.get_node("%Box") as Control
	var released := [false]
	spot.released.connect(func() -> void: released[0] = true)
	car.restart_at(5000.0)
	await wait_until(func() -> bool: return spot.is_parked(), 30.0)
	check(absf(car.progress - SPOT_PROGRESS) <= 4.0, "se estaciona en el centro del cajón")
	await frames(1)
	check(not bubble_box.visible, "con parked_message_key vacía el copiloto no dice nada al estacionarse")
	await wait(0.5)
	check(not released[0] and car.speed == 0.0, "antes de release_delay sigue detenido")
	await wait(0.8)
	check(released[0] and spot.is_released(), "después de release_delay emite released")
	var left := await wait_until(func() -> bool: return car.progress > SPOT_PROGRESS + 20.0, 5.0)
	check(left, "el auto sigue la ruta después de soltarlo")
	await wait(0.5)
	check(spot.is_released() and car.speed > 0.0, "el cajón no vuelve a atrapar al auto en la misma pasada")
	await close_level()

	# 3. release() a mano: solo funciona estacionado y una vez
	await open_level()
	spot.release()
	check(not spot.is_released(), "release() antes de estacionarse no hace nada")
	car.restart_at(5000.0)
	await wait_until(func() -> bool: return spot.is_parked(), 30.0)
	var count := [0]
	spot.released.connect(func() -> void: count[0] += 1)
	spot.release()
	spot.release()
	check(count[0] == 1, "release() suelta al auto una sola vez")
	left = await wait_until(func() -> bool: return car.progress > SPOT_PROGRESS + 20.0, 5.0)
	check(left, "con release() el auto sigue")
	# Regresar a un punto de control anterior deja el cajón como nuevo.
	rm.checkpoint_restored.emit(1000.0)
	check(not spot.is_parked() and not spot.is_released(), "un punto de control anterior reinicia el cajón")
	await close_level()

	# 4. DoorExit con finish_level_on_open = false: abrir bien suelta el auto
	await open_level()
	door.finish_level_on_open = false
	car.restart_at(5000.0)
	await wait_until(func() -> bool: return spot.is_parked(), 30.0)
	await wait_until(func() -> bool: return not door.is_cyclist_near(), 20.0)
	await wait(0.5)
	var opened := [false]
	door.door_opened.connect(func() -> void: opened[0] = true)
	door.open_door()
	check(opened[0], "abrir sin ciclistas emite door_opened")
	await wait(door.finish_delay + 0.3)
	check(spot.is_released() and not finished, "la puerta suelta al auto de su cajón y no termina el nivel")
	left = await wait_until(func() -> bool: return car.progress > SPOT_PROGRESS + 20.0, 5.0)
	check(left, "después de abrir la puerta el auto sigue la ruta")
	await close_level()

	# 5. Sin spot asignado, DoorExit toma el ParkingSpot más cercano
	await open_level()
	var far := (load("res://scenes/rules/parking_spot.tscn") as PackedScene).instantiate() as ParkingSpot
	far.position = spot.position + Vector2(-3000.0, 0.0)
	level.get_node("Rules").add_child(far)
	level.get_node("Rules").move_child(far, 0)
	var loose := (load("res://scenes/rules/door_exit.tscn") as PackedScene).instantiate() as DoorExit
	loose.position = spot.position
	level.get_node("Rules").add_child(loose)
	await frames(1)
	check(loose.spot == spot, "sin spot asignado usa el cajón más cercano, no el primero del grupo")
	await close_level()
