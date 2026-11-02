extends TestCase
## Distancia con la bici (nivel 8) en levels/level_08.tscn. Cyclist1 dispara en
## x = 1450 (progreso 1386) y su bici sale en x = 1898 a 80 px/s. Cyclist2
## (x = 8600) suelta una bici por detrás, rápida, que luego baja la velocidad.
## Carriles: 0 = ciclovía, 1 = pegado, 2 y 3 = separados. El auto empieza en el 1.

var level: Node
var rm: RuleManager
var car: PlayerCar
var bike: CyclistDistance
var driver: TestDriver


func open_level() -> void:
	level = await open_scene("res://levels/level_08.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	car = rm.car
	car.seatbelt_on = true
	bike = level.get_node("Rules/Cyclist1") as CyclistDistance
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


func until(cond: Callable, limit: float) -> bool:
	var t := 0.0
	while not cond.call() and t < limit:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	return cond.call()


func distance_faults() -> int:
	return rm.infractions.get(&"distance", 0)


## Rebasa a Cyclist1 desde el progreso 1000 cambiándose `steps` carriles.
func overtake(steps: int, label: String) -> void:
	await open_level()
	await place(1000.0, steps)
	driver.target = 150.0
	await until(func() -> bool: return bike.is_done(), 20.0)
	await wait_unpaused()
	check(bike.is_done() and bike.was_rewarded() and rm.points == 10 and distance_faults() == 0,
		"%s: rebasar a la bici separado da +10 (distance) sin falta" % label)
	await close_level()


func run() -> void:
	GameState.mode = GameState.MODE_GRANDE
	Engine.time_scale = 2.0

	# 1 y 3. Separado (carril 2 o 3) da +10
	await overtake(1, "carril 2")
	await overtake(2, "carril 3")

	# 2. Pegado (carril 1) da falta, una sola aunque siga a la par
	await open_level()
	await place(1000.0, 0)
	driver.target = 150.0
	await until(func() -> bool: return distance_faults() > 0, 20.0)
	await wait_unpaused()
	check(distance_faults() == 1 and bike.has_faulted(), "rebasar pegado a la bici (carril 1) es falta distance")
	driver.target = 80.0
	await wait(2.0)
	driver.target = 150.0
	await until(func() -> bool: return bike.is_done(), 10.0)
	check(distance_faults() == 1 and rm.points == 0 and not bike.was_rewarded(), "una sola falta y sin +10 aunque siga a la par")
	await close_level()

	# 4. Cambiarse a tiempo: flecha derecha 400 px detrás de la bici
	await open_level()
	await place(1000.0, 0)
	driver.target = 150.0
	await until(func() -> bool: return bike.is_active() and bike.cyclist_global_x() - car.global_position.x <= 400.0, 20.0)
	await tap(&"car_right")
	await until(func() -> bool: return bike.is_done(), 20.0)
	check(car.lane_index == 2 and bike.was_rewarded() and distance_faults() == 0, "cambiarse al carril 2 antes de llegar a la bici da +10 sin falta")
	await close_level()

	# 5. Ir detrás, más lento que la bici: no se evalúa
	await open_level()
	await place(1000.0, 0)
	driver.target = 40.0
	await until(func() -> bool: return bike.is_active(), 20.0)
	await until(func() -> bool: return not bike.is_active(), 60.0)
	check(not bike.is_active() and rm.faults == 0 and rm.points == 0 and not bike.is_done(), "detrás de la bici, más lento, no hay falta ni puntos")
	await close_level()

	# 6. La bici rebasa al auto detenido (Cyclist2) y luego el auto la rebasa separado
	await open_level()
	var bike2 := level.get_node("Rules/Cyclist2") as CyclistDistance
	await place(8450.0, 0)
	driver.target = 150.0
	driver.brake_after = 8640.0
	await until(func() -> bool: return bike2.is_active() and bike2.cyclist_global_x() > car.global_position.x + 200.0, 20.0)
	check(bike2.is_active() and rm.faults == 0, "la bici rebasa al auto detenido en el carril 1 sin falta")
	await tap(&"car_right")
	await wait(1.6)
	driver.brake_after = INF
	await until(func() -> bool: return bike2.is_done(), 30.0)
	check(bike2.was_rewarded() and rm.faults == 0, "luego el auto la rebasa por el carril 2 (+10)")
	await close_level()

	# 7. Dentro de la ciclovía: la falta es bike_lane y nadie se encima
	await open_level()
	await place(1000.0, -1)
	driver.target = 200.0
	var min_dx := INF
	var t := 0.0
	while t < 12.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if bike.is_active():
			min_dx = minf(min_dx, absf(bike.cyclist_global_x() - car.global_position.x))
	check(min_dx >= 64.0, "en la ciclovía el auto no se encima en la bici (mínimo %.0f px)" % min_dx)
	check(rm.infractions.has(&"bike_lane") and not rm.infractions.has(&"distance"), "la falta es bike_lane, no distance")
	await close_level()

	# 8. grande_only: en Peque Cyclist1b no sale
	GameState.mode = GameState.MODE_PEQUE
	await open_level()
	var bike1b := level.get_node("Rules/Cyclist1b") as CyclistDistance
	await place(2500.0, 1)
	var ever_active := false
	t = 0.0
	while car.global_position.x < 3600.0 and t < 20.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		ever_active = ever_active or bike1b.is_active()
	check(car.global_position.x >= 3600.0 and not ever_active, "en Peque la bici de Cyclist1b nunca sale")
	await close_level()
	GameState.mode = GameState.MODE_GRANDE

	# 9. Reinicio: la bici se borra y la evaluación se repite
	await open_level()
	await place(1000.0, 1)
	driver.target = 150.0
	await until(func() -> bool: return bike.is_active(), 20.0)
	rm.checkpoint_restored.emit(0.0)
	await frames(2)
	check(not bike.is_active() and not bike.is_done(), "al reiniciar la bici se borra")
	await place(1000.0, 0)
	await until(func() -> bool: return bike.is_done(), 20.0)
	check(bike.was_rewarded() and rm.points == 10, "al volver a pasar, la bici sale otra vez y se evalúa")
	await close_level()
	Engine.time_scale = 1.0
