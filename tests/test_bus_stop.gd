extends TestCase
## Parada de camión (nivel 8) en levels/level_08.tscn. BusStop1 tiene su origen
## en x = 5200 (parte de atrás del camión detenido en 5130) y su disparo en
## x = 3800 (progreso 3736; la ruta empieza en x = 64). La falta y el +10 usan la
## regla "distance"; el camión se distingue por has_faulted() / was_rewarded().
## Al final, el clímax: BusStop2 (9200) con la bici de Cyclist2 (8600).

const START := 3300.0
## Con freno desde aquí a 150 px/s el auto queda ~40 px detrás del camión.
const BRAKE_AT := 4930.0

var level: Node
var rm: RuleManager
var car: PlayerCar
var bus: BusStop
var driver: TestDriver


func open_level(keep_traffic := false) -> void:
	level = await open_scene("res://levels/level_08.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	car = rm.car
	car.seatbelt_on = true
	bus = level.get_node("Rules/BusStop1") as BusStop
	if not keep_traffic:
		level.get_node("Traffic").queue_free()
	driver = TestDriver.new()
	driver.car = car
	add_child(driver)


func close_level() -> void:
	driver.stop_driving()
	driver.queue_free()
	release_inputs()
	await close_scene(level)


## Pone el auto en `progress` y lo cambia `steps` carriles (+ derecha, - izquierda).
func place(progress: float, steps: int) -> void:
	car.restart_at(progress)
	for i in absi(steps):
		await tap(&"car_right" if steps > 0 else &"car_left")
		await wait(1.6)


func car_front_x() -> float:
	return car.global_position.x + bus.car_half_length


func distance_faults() -> int:
	return rm.infractions.get(&"distance", 0)


## Avanza la física hasta que cond() sea verdadero o pasen `limit` segundos de juego.
func until(cond: Callable, limit: float) -> bool:
	var t := 0.0
	while not cond.call() and t < limit:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	return cond.call()


func run() -> void:
	GameState.mode = GameState.MODE_GRANDE
	Engine.time_scale = 2.0

	# 1, 2 y 8. Ciclo de estados; esperar detrás en el carril 2 da +10
	await open_level()
	await place(START, 1)
	check(bus.state == BusStop.State.IDLE and not bus.get_node("Bus").visible, "antes del disparo el camión está oculto (IDLE)")
	driver.target = 150.0
	driver.brake_after = BRAKE_AT
	var seen: Array[int] = [bus.state]
	var stop_x := INF
	var car_stopped_at := -1.0
	var departed_at := -1.0
	var passengers_ok := false
	var t := 0.0
	while bus.state != BusStop.State.GONE and t < 40.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if seen.back() != bus.state:
			seen.append(bus.state)
			if bus.state == BusStop.State.STOPPED:
				stop_x = (bus.get_node("Bus") as Node2D).position.x
			if bus.state == BusStop.State.DEPARTING:
				departed_at = t
				passengers_ok = bus.passengers_done()
				for p in bus.passengers():
					passengers_ok = passengers_ok and (not p.visible or p.modulate.a <= 0.01)
		if car_stopped_at < 0.0 and bus.state == BusStop.State.STOPPED and car.speed < bus.stop_speed:
			car_stopped_at = t
	check(str(seen) == "[0, 1, 2, 3, 4]", "estados IDLE → ARRIVING → STOPPED → DEPARTING → GONE (%s)" % str(seen))
	check(absf(stop_x) <= 2.0, "el camión se detiene en x = 0 (%.1f)" % stop_x)
	await wait(bus.fade_time + 0.1)
	check(not bus.get_node("Bus").visible, "en GONE el camión se desvanece y ya no se ve")
	check(car_stopped_at >= 0.0 and departed_at - car_stopped_at >= bus.min_dwell - 0.1,
		"el camión no arranca antes de min_dwell desde que el auto llegó a esperar (%.1f s)" % (departed_at - car_stopped_at))
	check(passengers_ok, "al arrancar, todos los pasajeros terminaron y ya no se ven")
	check(bus.was_rewarded() and not bus.has_faulted() and rm.points == 10 and distance_faults() == 0,
		"esperar detrás en el carril 2 da +10 (distance) y ninguna falta")
	await close_level()

	# 3 y 5. Detenido por su cuenta en el carril 3; cambiarse al 2 sin avanzar no es falta
	await open_level()
	await place(START, 2)
	driver.target = 150.0
	driver.brake_after = BRAKE_AT
	await until(func() -> bool: return bus.is_stopped() and car.speed < 1.0, 30.0)
	check(car.lane_index == 3 and car_front_x() <= bus.bus_rear_global_x(), "el auto se detiene detrás del camión en su carril")
	check(car._stop_requests.is_empty(), "frenó por su cuenta, no por el frenado de seguridad")
	await tap(&"car_left")
	await wait(1.6)
	check(car.lane_index == 2, "se cambia al carril 2 detenido")
	await until(func() -> bool: return bus.state == BusStop.State.DEPARTING, 20.0)
	check(not bus.has_faulted() and distance_faults() == 0, "cambiarse de carril sin avanzar no es falta")
	check(bus.was_rewarded() and rm.points == 10, "esperar detrás del camión (carril 3 y luego 2) da +10")
	await close_level()

	# 4. Pasar junto al camión detenido: una falta, sin +10 y menos estrellas
	await open_level()
	await place(START, 1)
	driver.target = 150.0
	await until(func() -> bool: return car.global_position.x > 5600.0, 40.0)
	await wait_unpaused()
	await until(func() -> bool: return car.global_position.x > 5800.0, 10.0)
	check(bus.has_faulted() and distance_faults() == 1, "pasar junto al camión detenido es falta distance (%d)" % distance_faults())
	await until(func() -> bool: return bus.state == BusStop.State.GONE, 20.0)
	check(not bus.was_rewarded() and rm.points == 0 and distance_faults() == 1, "una sola falta y sin +10 aunque pase todo el camión")
	check(rm.get_stars() < 3, "sin esperar detrás del camión no se sacan 3 estrellas")
	await close_level()

	# 6. Rebasar mientras el camión va llegando no es falta
	await open_level()
	bus.bus_cruise_speed = 60.0
	await place(START, 1)
	driver.target = 240.0
	await until(func() -> bool: return bus.state == BusStop.State.STOPPED or car.global_position.x > 7000.0, 40.0)
	var passed_first := car.global_position.x > bus.bus_front_global_x()
	await wait(1.0)
	check(passed_first and bus.state != BusStop.State.IDLE, "el auto rebasó al camión mientras llegaba")
	check(not bus.has_faulted() and distance_faults() == 0, "rebasar al camión en ARRIVING no es falta")
	await close_level()

	# 7. Frenado de seguridad en el carril del camión: no lo toca, sin falta ni puntos
	await open_level()
	await place(START, 2)
	driver.target = 150.0
	var max_front := -INF
	var limit := 0.0
	t = 0.0
	while bus.state != BusStop.State.DEPARTING and t < 40.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if bus.is_stopped():
			max_front = maxf(max_front, car_front_x() - bus.bus_rear_global_x())
	limit = -bus.safety_gap + 2.0
	check(bus.state == BusStop.State.DEPARTING, "el camión arranca aunque el auto no frenó")
	check(max_front <= limit, "el auto frena solo antes del camión (frente a %.1f px de su parte de atrás)" % max_front)
	await wait(0.5)
	check(not bus.has_faulted() and not bus.was_rewarded() and rm.faults == 0 and rm.points == 0,
		"el frenado de seguridad no da falta ni puntos (%s, %d pts)" % [str(rm.infractions), rm.points])
	await until(func() -> bool: return bus.state == BusStop.State.GONE, 20.0)
	check(car._stop_requests.is_empty(), "al irse el camión el auto queda libre")
	await close_level()

	# 9. El camión está en el grupo traffic: una moto (NpcCar) frena detrás
	await open_level()
	await place(START, 1)
	driver.target = 150.0
	driver.brake_after = BRAKE_AT
	await until(func() -> bool: return bus.is_stopped(), 30.0)
	var path := Path2D.new()
	var curve := Curve2D.new()
	curve.add_point(Vector2(4700.0, 96.0))
	curve.add_point(Vector2(6500.0, 96.0))
	path.curve = curve
	level.add_child(path)
	var npc := (load("res://scenes/actors/npc_car.tscn") as PackedScene).instantiate() as NpcCar
	npc.cruise_speed = 200.0
	path.add_child(npc)
	await wait(2.5)
	check(bus.is_stopped() and npc.is_stopped(), "un NpcCar en el carril del camión se detiene detrás de él")
	check(npc.global_position.x + 33.0 < bus.bus_rear_global_x(), "el NpcCar no se encima en el camión")
	await close_level()

	# 10. Reinicio: el camión vuelve a IDLE y los pasajeros a su lugar
	await open_level()
	await place(START, 1)
	driver.target = 150.0
	driver.brake_after = BRAKE_AT
	await until(func() -> bool: return bus.is_stopped() and bus.passengers()[0].visible, 30.0)
	rm.checkpoint_restored.emit(0.0)
	await get_tree().physics_frame
	var off := bus.passengers()[0]
	var on := bus.passengers()[1]
	check(bus.state == BusStop.State.IDLE and not bus.get_node("Bus").visible, "al reiniciar el camión vuelve a IDLE y se oculta")
	check(not off.visible and on.visible and on.modulate.a >= 0.99, "los que bajan se ocultan y los que suben esperan en la parada")
	check(not bus.must_wait(), "en IDLE el conductor cuidadoso no espera")
	await close_level()

	# Clímax: la bici pasa el frente del camión detenido antes de que arranque
	for mode in [GameState.MODE_GRANDE, GameState.MODE_PEQUE]:
		GameState.mode = mode
		await open_level()
		var bus2 := level.get_node("Rules/BusStop2") as BusStop
		var bike := level.get_node("Rules/Cyclist2") as CyclistDistance
		await place(7400.0, 1)
		driver.target = 150.0
		driver.brake_after = 8930.0
		await until(func() -> bool: return bus2.state == BusStop.State.DEPARTING, 40.0)
		var bike_x := bike.cyclist_global_x()
		check(bike.is_active() and bike_x > bus2.bus_front_global_x() + 20.0,
			"%s: la bici pasa el frente del camión antes de que arranque (bici %.0f, frente %.0f)" % [mode, bike_x, bus2.bus_front_global_x()])
		check(bus2.was_rewarded(), "%s: esperar detrás del camión en el clímax da +10" % mode)
		driver.brake_after = INF
		await until(func() -> bool: return bike.is_done() or car.progress > 10800.0, 30.0)
		check(bike.was_rewarded() and rm.faults == 0, "%s: luego el auto rebasa a la bici por el carril separado (+10)" % mode)
		await close_level()
	GameState.mode = GameState.MODE_GRANDE
	Engine.time_scale = 1.0
