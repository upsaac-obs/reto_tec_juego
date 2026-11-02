extends TestCase
## Cruce que se pone en amarillo al llegar el auto (nivel 5) en
## levels/level_05.tscn: Rules/YellowCrossing1 con la línea en x = 2432.
## Las distancias son progreso sobre la ruta (la ruta empieza en x = 64) y el
## Hitbox del auto llega HALF_CAR px delante de su centro.

## Progreso del auto cuando su frente llega al disparo (x = 2012).
const TRIGGER := 1915.0
## Progreso de la línea de alto.
const LINE := 2368.0
const HALF_CAR := 33.0
const START := 1600.0

var level: Node
var rm: RuleManager
var car: PlayerCar
var crossing: YellowCrossing
var light: TrafficLight
var driver: TestDriver
var good: Array[StringName] = []


func open_level() -> void:
	level = await open_scene("res://levels/level_05.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	car = rm.car
	car.seatbelt_on = true
	crossing = level.get_node("Rules/YellowCrossing1") as YellowCrossing
	light = crossing.get_light()
	good.clear()
	rm.good_action_reported.connect(func(id: StringName, _p: int) -> void: good.append(id))
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


func is_state(state: YellowCrossing.State) -> Callable:
	return func() -> bool: return crossing.get_state() == state


## Llega a 168 px/s y frena en cuanto se pone el amarillo.
func drive_and_stop_at_yellow() -> void:
	driver.brake_after = INF
	driver.target = 168.0
	await wait_until(is_state(YellowCrossing.State.YELLOW), 20.0)
	driver.brake_after = car.progress


func run() -> void:
	# 1. La luz espera al auto
	await open_level()
	car.restart_at(START)
	# wait() cuenta segundos reales: 5 s a 4x son 20 s de juego.
	Engine.time_scale = 4.0
	await wait(5.0)
	Engine.time_scale = 1.0
	check(light.light == TrafficLight.Light.GREEN and crossing.get_state() == YellowCrossing.State.ARMED, "sin el auto la luz se queda en verde aunque pasen 20 s")
	driver.target = 168.0
	await wait_until(is_state(YellowCrossing.State.YELLOW), 20.0)
	check(light.light == TrafficLight.Light.YELLOW and absf(car.progress - TRIGGER) < 6.0, "al llegar al disparo la luz se pone en amarillo (%d)" % int(car.progress))
	driver.brake_after = car.progress
	var t := 0.0
	while light.light == TrafficLight.Light.YELLOW and t < 10.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	check(light.light == TrafficLight.Light.RED and absf(t - crossing.yellow_time) < 0.1, "a los 3 s pasa a rojo (%.2f s)" % t)
	t = 0.0
	while light.light == TrafficLight.Light.RED and t < 20.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	check(light.light == TrafficLight.Light.GREEN and t >= crossing.red_time - 0.05 and not crossing.is_busy(), "el verde llega tras red_time y con el cruce libre (%.2f s)" % t)
	await close_level()

	# 2. Frenar en amarillo y esperar da +10
	await open_level()
	car.restart_at(START)
	driver.target = 168.0
	driver.brake_after = 2250.0
	var max_progress := 0.0
	while light.light != TrafficLight.Light.GREEN or crossing.get_state() != YellowCrossing.State.GREEN_DONE:
		await get_tree().physics_frame
		max_progress = maxf(max_progress, car.progress)
		if max_progress > LINE + 200.0:
			break
	check(max_progress + HALF_CAR < LINE, "el auto se detiene antes de la línea (%d)" % int(max_progress))
	driver.brake_after = INF
	await wait_until(func() -> bool: return car.progress > LINE + 100.0, 10.0)
	await wait(0.2)
	check(good.has(&"yellow") and rm.points == 10 and rm.faults == 0, "frenar en amarillo y cruzar con verde da +10 (yellow) sin faltas")
	await close_level()

	# 3. Seguir acelerando en amarillo es falta yellow
	await open_level()
	car.restart_at(START)
	# Pisa el pedal verde todo el tiempo, también con la luz en amarillo.
	Input.action_press(&"car_accelerate")
	await wait_until(func() -> bool: return rm.infractions.get(&"yellow", 0) > 0, 15.0)
	await wait_unpaused()
	await wait_until(func() -> bool: return car.progress > LINE + 100.0, 15.0)
	await wait_unpaused()
	await wait(0.3)
	check(rm.infractions.get(&"yellow", 0) == 1 and not good.has(&"yellow"), "acelerar en amarillo es falta yellow y no da +10")
	await close_level()

	# 4. Soltar los pedales en amarillo no es falta
	await open_level()
	car.restart_at(START)
	driver.target = 168.0
	await wait_until(is_state(YellowCrossing.State.YELLOW), 20.0)
	driver.stop_driving()
	await wait_until(is_state(YellowCrossing.State.RED), 10.0)
	await wait(1.0)
	check(rm.infractions.get(&"yellow", 0) == 0, "soltar los pedales en amarillo no es falta")
	await close_level()

	# 5. Pasarse el rojo con tráfico: falta red_light y nunca hay choque
	await open_level()
	crossing.red_time = 10.0
	car.restart_at(START)
	await drive_and_stop_at_yellow()
	await wait_until(is_state(YellowCrossing.State.RED), 10.0)
	await wait_until(func() -> bool: return not crossing.get_cross_cars().is_empty(), 5.0)
	driver.brake_after = INF
	driver.target = 240.0
	var hitbox := car.get_node("Hitbox") as Area2D
	var touched := false
	t = 0.0
	while car.progress < LINE + 300.0 and t < 25.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		for npc in crossing.get_cross_cars():
			touched = touched or hitbox.overlaps_area(npc.get_node("Hitbox") as Area2D)
	await wait_unpaused()
	check(rm.infractions.get(&"red_light", 0) == 1, "pasarse el rojo es falta red_light")
	check(not touched, "el auto nunca toca a los autos que cruzan")
	await close_level()

	# 6. Tráfico por modo
	for mode in [GameState.MODE_GRANDE, GameState.MODE_PEQUE]:
		GameState.mode = mode
		await open_level()
		car.restart_at(START)
		await drive_and_stop_at_yellow()
		var seen: Array[NpcCar] = []
		t = 0.0
		while crossing.get_state() != YellowCrossing.State.GREEN_DONE and t < 20.0:
			await get_tree().physics_frame
			t += get_physics_process_delta_time()
			for npc in crossing.get_cross_cars():
				if not seen.has(npc):
					seen.append(npc)
		var expected := 2 if mode == GameState.MODE_GRANDE else 1
		check(seen.size() == expected, "%s: en el rojo cruzan %d autos (%d)" % [mode, expected, seen.size()])
		await close_level()

	# 7. Peque: no frenar en amarillo es falta, frenar da +10
	GameState.mode = GameState.MODE_PEQUE
	await open_level()
	car.restart_at(START)
	await wait_until(func() -> bool: return rm.infractions.get(&"yellow", 0) > 0, 15.0)
	check(rm.infractions.get(&"yellow", 0) == 1, "peque: no frenar en amarillo es falta yellow")
	await close_level()
	await open_level()
	car.restart_at(START)
	await wait_until(is_state(YellowCrossing.State.YELLOW), 20.0)
	Input.action_press(&"car_brake")
	await wait_until(is_state(YellowCrossing.State.GREEN_DONE), 20.0)
	Input.action_release(&"car_brake")
	await wait_until(func() -> bool: return car.progress > LINE + 100.0, 15.0)
	await wait(0.2)
	check(good.has(&"yellow") and rm.faults == 0, "peque: frenar en amarillo y esperar el verde da +10")
	await close_level()
	GameState.mode = GameState.MODE_GRANDE

	# 8. El punto de control rearma el cruce
	await open_level()
	car.restart_at(START)
	await drive_and_stop_at_yellow()
	await wait_until(func() -> bool: return not crossing.get_cross_cars().is_empty(), 10.0)
	car.restart_at(1500.0)
	rm.checkpoint_restored.emit(1500.0)
	await frames(2)
	check(light.light == TrafficLight.Light.GREEN and crossing.get_state() == YellowCrossing.State.ARMED and crossing.get_cross_cars().is_empty(), "al volver al punto de control: verde, armado y sin autos cruzando")
	check(crossing.careful_stop_x() < crossing.global_position.x - light.zone_length and crossing.careful_stop_x() > crossing.global_position.x - crossing.trigger_distance, "el conductor cuidadoso se detiene antes de la zona del amarillo y después del disparo")
	await close_level()
