extends TestCase
## Cruce sin vista (nivel 3) manejando el auto en levels/level_03.tscn.
## El primer cruce está en x = 1300 (la ruta empieza en x = 64).

var level: Node
var rm: RuleManager
var car: PlayerCar
var crossing: BlindCrossing
var driver: TestDriver


func clear_traffic() -> void:
	for path in crossing._paths:
		for child in path.get_children():
			child.queue_free()
	await frames(2)


## Del inicio a la marca de los ojos, se detiene ahí `stop_time` segundos.
func approach_and_stop(stop_time: float) -> void:
	car.restart_at(700.0)
	driver.target = 150.0
	driver.brake_after = 1070.0
	while car.progress < 1060.0 or car.speed > 1.0:
		await get_tree().physics_frame
	await wait(stop_time)


func pass_crossing() -> void:
	driver.brake_after = 1700.0
	driver.target = 150.0
	while car.progress < 1550.0:
		await get_tree().physics_frame
	driver.target = 0.0
	await wait(1.0)
	await wait_unpaused()


func run() -> void:
	level = await open_scene("res://levels/level_03.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	car = rm.car
	car.seatbelt_on = true
	crossing = level.get_node("Rules/BlindCrossing1") as BlindCrossing
	for c in level.get_node("Rules").get_children():
		if c is BlindCrossing:
			(c as BlindCrossing).traffic = false
	await clear_traffic()
	driver = TestDriver.new()
	driver.car = car
	add_child(driver)

	# 1. Sin detenerse en los ojos
	car.restart_at(700.0)
	await pass_crossing()
	check(rm.infractions.get(&"look", 0) == 1, "pasar la marca sin detenerse es falta look")

	# 2. Se detiene, mira y cruza libre
	var points := rm.points
	await approach_and_stop(0.6)
	await pass_crossing()
	check(rm.infractions.get(&"look", 0) == 1 and rm.points == points + 10, "detenerse en los ojos y cruzar libre da +10")

	# 3. Se detiene pero arranca con un auto visible que viene
	await approach_and_stop(0.4)
	var npc := crossing.spawn_car(0, 680.0)
	await wait(0.6)
	check(crossing.is_busy(), "el auto que viene ya se ve y el cruce cuenta como ocupado")
	driver.brake_after = 1700.0
	driver.target = 150.0
	var overlapped := false
	var held := false
	var t := 0.0
	while t < 12.0 and car.progress < 1550.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if is_instance_valid(npc) and (car.get_node("Hitbox") as Area2D).overlaps_area(npc.get_node("Hitbox")):
			overlapped = true
		if crossing._holding:
			held = true
	driver.target = 0.0
	await wait(1.0)
	await wait_unpaused()
	check(rm.infractions.get(&"look", 0) == 2, "arrancar con un auto viniendo es falta look")
	check(held, "el auto del jugador frena solo y espera a que pase")
	check(not overlapped, "los autos nunca se tocan")
	check(car.progress >= 1500.0, "cuando se libera el cruce, el auto sigue")

	# 3b. Miró con el cruce libre y el auto apareció después: espera, pero sin falta
	await clear_traffic()
	await approach_and_stop(0.5)
	driver.brake_after = 1700.0
	driver.target = 150.0
	await wait(0.15)
	npc = crossing.spawn_car(0, 700.0)
	held = false
	t = 0.0
	while t < 12.0 and car.progress < 1550.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if crossing._holding:
			held = true
	driver.target = 0.0
	await wait(1.0)
	await wait_unpaused()
	check(rm.infractions.get(&"look", 0) == 2, "si el auto apareció después de arrancar, no es falta")
	check(held, "aun así frena solo y deja pasar al auto")

	# 4. Un auto que viene se detiene si el jugador está en el cruce
	await clear_traffic()
	car.restart_at(1200.0)
	driver.stop_driving()
	await wait(0.3)
	# Aparecer dentro del cruce cuenta como no detenerse en los ojos: esperar la pausa.
	await wait_unpaused()
	check(car.speed == 0.0, "el jugador está parado dentro del cruce")
	npc = crossing.spawn_car(0, 650.0)
	await wait(3.0)
	var touching := (car.get_node("Hitbox") as Area2D).overlaps_area(npc.get_node("Hitbox"))
	check(is_instance_valid(npc) and npc.is_stopped() and not touching, "el auto que cruza se detiene antes de tocar al jugador")

	# 5. Menos tráfico en modo peque
	var interval_grande := 0.0
	var interval_peque := 0.0
	GameState.mode = GameState.MODE_GRANDE
	crossing._spawn()
	interval_grande = crossing._spawn_left
	GameState.mode = GameState.MODE_PEQUE
	crossing._spawn()
	interval_peque = crossing._spawn_left
	GameState.mode = GameState.MODE_GRANDE
	check(interval_peque >= crossing.spawn_interval_min * crossing.peque_traffic_factor and interval_grande <= crossing.spawn_interval_max, "en modo peque los autos salen menos seguido")

	driver.stop_driving()
	driver.queue_free()
	release_inputs()
	await close_scene(level)
