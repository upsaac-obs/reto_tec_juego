extends TestCase
## Zona de paciencia (nivel 4) en levels/level_04.tscn. El primer cruce está en
## x = 1400: la línea del semáforo en progreso 1248 y la cebra desde 1288
## (la ruta empieza en x = 64).

const LINE := 1248.0
const ZONE := 1288.0

var level: Node
var rm: RuleManager
var car: PlayerCar
var crossing: PatienceZone
var driver: TestDriver


func open_level() -> void:
	level = await open_scene("res://levels/level_04.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	car = rm.car
	car.seatbelt_on = true
	crossing = level.get_node("Rules/PatienceCrossing1") as PatienceZone
	driver = TestDriver.new()
	driver.car = car
	add_child(driver)


func close_level() -> void:
	driver.stop_driving()
	driver.queue_free()
	release_inputs()
	await close_scene(level)


## Espera a que la gente termine de cruzar (máximo `limit` segundos de juego).
func wait_until_clear(limit: float) -> float:
	var t := 0.0
	while crossing.is_occupied() and t < limit:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	return t


func run() -> void:
	# 1. Esperar hasta que termine de cruzar, aunque la luz ya esté en verde
	await open_level()
	car.restart_at(500.0)
	driver.target = 150.0
	driver.brake_after = 1150.0
	var saw_trap := false
	var max_progress := 0.0
	var t := 0.0
	while crossing.is_occupied() and t < 20.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		saw_trap = saw_trap or crossing.is_trap()
		max_progress = maxf(max_progress, car.progress)
	check(saw_trap, "el semáforo de autos se pone en verde con gente todavía cruzando")
	check(not crossing.is_occupied(), "la gente termina de cruzar")
	check(max_progress < LINE, "esperando, el auto no pasa la línea del semáforo (%d)" % int(max_progress))
	await wait(0.2)
	check(rm.faults == 0 and rm.points == 10, "esperar a que terminen de cruzar da +10 y ninguna falta")
	driver.brake_after = INF
	driver.target = 150.0
	t = 0.0
	while car.progress < 1500.0 and t < 15.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	check(car.progress >= 1500.0 and rm.faults == 0 and rm.points == 10, "con el cruce libre el auto sigue sin más puntos ni faltas")
	await close_level()

	# 2. Avanzar con la luz en verde y gente cruzando: falta, se queda quieto hasta que terminen
	await open_level()
	car.restart_at(500.0)
	driver.target = 120.0
	t = 0.0
	while rm.infractions.get(&"patience", 0) == 0 and t < 15.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	check(rm.infractions.get(&"patience", 0) == 1, "pasar la línea en verde con gente cruzando es falta patience")
	check(rm.infractions.get(&"red_light", 0) == 0, "con la luz en verde no es pasarse el rojo")
	await wait_unpaused()
	var held_back := true
	t = 0.0
	while crossing.is_occupied() and t < 20.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		held_back = held_back and car.progress < ZONE
	check(held_back, "tras la falta el auto espera quieto antes de la cebra")
	await wait(0.3)
	check(rm.faults == 1 and rm.points == 0, "una sola falta, sin puntos")
	driver.brake_after = INF
	driver.target = 120.0
	t = 0.0
	while car.progress < 1500.0 and t < 10.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	check(car.progress >= 1500.0, "cuando termina de cruzar la gente, el auto sigue")
	await close_level()

	# 3. Pasarse el rojo y entrar a la cebra ocupada: falta grave, nunca toca a nadie
	await open_level()
	car.restart_at(500.0)
	driver.target = 240.0
	t = 0.0
	while rm.infractions.get(&"crosswalk", 0) == 0 and t < 10.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	check(rm.infractions.get(&"red_light", 0) == 1, "pasarse el rojo es falta red_light")
	check(rm.infractions.get(&"crosswalk", 0) == 1, "entrar a la cebra ocupada es falta grave")
	check(car.progress < 1400.0, "el auto frena solo antes de llegar a la gente")
	await close_level()

	# 4. Modo peque: el auto avanza solo, soltar el freno antes de tiempo es avanzar
	GameState.mode = GameState.MODE_PEQUE
	await open_level()
	car.restart_at(1150.0)
	Input.action_press(&"car_brake")
	t = 0.0
	while not crossing.is_trap() and t < 10.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	check(crossing.is_trap() and rm.faults == 0, "en peque, frenando, esperar no tiene falta")
	Input.action_release(&"car_brake")
	t = 0.0
	while rm.infractions.get(&"patience", 0) == 0 and t < 10.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	check(rm.infractions.get(&"patience", 0) == 1, "en peque, soltar el freno antes de que terminen es falta patience")
	GameState.mode = GameState.MODE_GRANDE
	await close_level()
