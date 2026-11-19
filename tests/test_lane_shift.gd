extends TestCase
## StreetSection.lane_shift en levels/level_05.tscn: la calle de los autos
## estacionados (Route/OneLane, x = 4096 a 5440) es de un carril, pero el suelo
## tiene dos dibujados; con lane_shift = -32 el auto va en el carril izquierdo y
## no sobre la raya. La ruta es recta y empieza en x = 64: progreso = x - 64.

## Progreso del inicio (x = 4096) y del fin (x = 5440) de la sección de un carril.
const ONE_LANE := 4032.0
const TWO_LANES := 5376.0
## Punto de control CheckpointBallStreet (x = 4160).
const CHECKPOINT := 4096.0
## Medio ancho del auto (Hitbox de 66 × 32).
const HALF_CAR_WIDTH := 16.0

var level: Node
var car: PlayerCar
var route: DrivingRoute
var driver: TestDriver


func open_level() -> void:
	level = await open_scene("res://levels/level_05.tscn")
	var rm := level.get_node("RuleManager") as RuleManager
	car = rm.car
	car.seatbelt_on = true
	route = level.get_node("Route") as DrivingRoute
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


## Lleva al auto hasta ese progreso a velocidad de calle y lo deja detenido.
func drive_to(stop_progress: float) -> void:
	driver.brake_after = stop_progress
	driver.target = 100.0
	await wait_until(func() -> bool: return car.progress >= stop_progress and car.speed == 0.0, 20.0)
	driver.stop_driving()


func run() -> void:
	await open_level()

	# 1. La ruta: el desplazamiento solo aplica dentro de la sección
	var one_lane := level.get_node("Route/OneLane") as StreetSection
	check(one_lane.lane_count == 1 and is_equal_approx(one_lane.lane_shift, -32.0), "OneLane es de un carril con lane_shift = -32")
	check(is_equal_approx(route.lane_shift_at(ONE_LANE - 20.0), 0.0), "antes de la sección no hay desplazamiento")
	check(is_equal_approx(route.lane_shift_at(ONE_LANE + 100.0), -32.0), "dentro de la sección el desplazamiento es -32")
	check(is_equal_approx(route.lane_shift_at(TWO_LANES + 20.0), 0.0), "después de la sección vuelve a 0")
	check(is_equal_approx(route.lane_offset(0, 1, 4200.0), -32.0), "el carril único va en y = -32 (carril izquierdo dibujado)")
	check(is_equal_approx(route.lane_offset(0, 2, 5500.0), -32.0) and is_equal_approx(route.lane_offset(1, 2, 5500.0), 32.0), "después, dos carriles en -32 y +32")
	check(is_equal_approx(route.lane_offset(0, 1), 0.0) and is_equal_approx(route.lane_offset(1, 2), 32.0), "sin progreso lane_offset da lo de siempre")

	# 2. Viniendo del carril derecho, al entrar se pasa al carril izquierdo
	car.lane_index = 1
	car.restart_at(ONE_LANE - 120.0)
	check(car.lane_index == 1 and is_equal_approx(car.v_offset, 32.0), "antes de la sección el auto va en el carril derecho")
	await drive_to(ONE_LANE + 150.0)
	await wait(car.lane_change_time + 0.1)
	check(car.lane_index == 0 and absf(car.v_offset + 32.0) < 0.5, "dentro de la sección queda en el carril izquierdo (%.1f)" % car.v_offset)

	# 3. Las flechas no lo mueven dentro de la sección
	for action in [&"car_right", &"car_left"]:
		await tap(action)
		await wait(car.signal_time + car.lane_change_time + 0.2)
	check(car.lane_index == 0 and absf(car.v_offset + 32.0) < 0.5, "las flechas no cambian el carril en la sección (%.1f)" % car.v_offset)

	# 4. Separación con los autos estacionados de la derecha
	var ball := level.get_node("Rules/BallEvent") as BallEvent
	var parked_top := ball.parked_car_y - NpcCar.CAR_SIZE.y / 2.0
	check(car.v_offset + HALF_CAR_WIDTH < parked_top, "el auto (borde %.0f) no toca a los autos estacionados (borde %.0f)" % [car.v_offset + HALF_CAR_WIDTH, parked_top])

	# 5. El punto de control de la calle deja al auto en el carril izquierdo
	car.lane_index = 1
	car.restart_at(CHECKPOINT)
	check(car.lane_index == 0 and is_equal_approx(car.v_offset, -32.0), "restart_at en CheckpointBallStreet deja al auto en -32")
	await close_level()

	# 6. Al salir a dos carriles se queda en el carril 0 sin brincar y puede cambiarse
	await open_level()
	car.restart_at(TWO_LANES - 80.0)
	check(car.lane_index == 0 and is_equal_approx(car.v_offset, -32.0), "al final de la sección va en -32")
	var jumped := [false]
	var watch := func() -> void:
		jumped[0] = jumped[0] or absf(car.v_offset + 32.0) > 0.5
	get_tree().physics_frame.connect(watch)
	await drive_to(TWO_LANES + 40.0)
	await wait(car.lane_change_time + 0.1)
	get_tree().physics_frame.disconnect(watch)
	check(not jumped[0] and car.lane_index == 0 and absf(car.v_offset + 32.0) < 0.5, "al salir sigue en el carril 0 sin moverse (%.1f)" % car.v_offset)
	await tap(&"car_right")
	await wait(car.signal_time + car.lane_change_time + 0.2)
	check(car.lane_index == 1 and absf(car.v_offset - 32.0) < 0.5, "con dos carriles puede cambiarse al carril 1 (%.1f)" % car.v_offset)
	await close_level()
