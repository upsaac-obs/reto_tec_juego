extends TestCase
## Semáforo, límite de velocidad y ciclovía manejando el auto en la calle de
## prueba (levels/test_street.tscn).

var level: Node
var rm: RuleManager
var car: PlayerCar
var driver: TestDriver


## Maneja a speed px/s desde start hasta frenar en brake_after.
func drive(start: float, speed: float, brake_after: float, seconds: float) -> void:
	car.restart_at(start)
	driver.brake_after = brake_after
	driver.target = speed
	await wait(seconds)
	driver.target = 0.0
	driver.brake_after = 0.0
	await wait(1.0)
	driver.stop_driving()
	await wait_unpaused()


func run() -> void:
	level = await open_scene("res://levels/test_street.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	car = rm.car
	car.seatbelt_on = true
	driver = TestDriver.new()
	driver.car = car
	add_child(driver)
	await traffic_light()
	await speed_zone()
	await bike_lane()
	driver.stop_driving()
	driver.queue_free()
	release_inputs()
	await close_scene(level)


func traffic_light() -> void:
	var tl := level.get_node("Rules/TrafficLight") as TrafficLight
	tl.green_time = 100.0
	tl.yellow_time = 100.0
	tl.red_time = 100.0
	check(tl.light == TrafficLight.Light.RED, "semáforo: empieza en rojo")
	var points := rm.points
	tl.set_light(TrafficLight.Light.RED)
	car.restart_at(1850.0)
	driver.target = 0.0
	await wait(0.5)
	tl.set_light(TrafficLight.Light.GREEN)
	await drive(car.progress, 150.0, 2150.0, 2.0)
	check(rm.points == points + 10 and not rm.infractions.has(&"red_light"), "semáforo: esperar en rojo y cruzar en verde da +10")

	tl.set_light(TrafficLight.Light.RED)
	await drive(1700.0, 240.0, 2150.0, 3.0)
	check(rm.infractions.get(&"red_light", 0) == 1, "semáforo: pasarse el rojo es falta red_light")

	tl.check_yellow = true
	tl.set_light(TrafficLight.Light.YELLOW)
	await drive(1700.0, 240.0, 2150.0, 3.0)
	check(rm.infractions.get(&"yellow", 0) == 1, "semáforo: acelerar en amarillo con check_yellow es falta yellow")
	check(rm.infractions.get(&"red_light", 0) == 1, "semáforo: cruzar en amarillo no cuenta como rojo")
	tl.check_yellow = false
	tl.set_light(TrafficLight.Light.YELLOW)
	await drive(1700.0, 240.0, 2150.0, 3.0)
	check(rm.infractions.get(&"yellow", 0) == 1, "semáforo: sin check_yellow, acelerar en amarillo no es falta")

	var seen: Array = []
	var record := func(light: TrafficLight.Light) -> void: seen.append(light)
	tl.light_changed.connect(record)
	tl.green_time = 0.3
	tl.yellow_time = 0.2
	tl.red_time = 0.3
	tl._elapsed = 0.0
	tl.set_light(TrafficLight.Light.GREEN)
	seen.clear()
	await wait(0.95)
	check(seen.slice(0, 3) == [TrafficLight.Light.YELLOW, TrafficLight.Light.RED, TrafficLight.Light.GREEN], "semáforo: ciclo verde → amarillo → rojo → verde")
	tl.light_changed.disconnect(record)
	tl.green_time = 100.0
	tl.set_light(TrafficLight.Light.GREEN)


func speed_zone() -> void:
	var zone := level.get_node("Rules/SchoolZone") as SpeedZone
	check(is_equal_approx(zone.get_limit_speed(), 80.0), "límite: 20 km/h = 80 px/s")
	var faults: int = rm.infractions.get(&"speed", 0)
	var points := rm.points
	await drive(2650.0, 240.0, 3480.0, 4.5)
	check(rm.infractions.get(&"speed", 0) == faults + 1 and rm.points == points, "límite: rápido por la zona escolar es falta y sin puntos")
	await drive(2650.0, 70.0, 3480.0, 12.0)
	check(rm.infractions.get(&"speed", 0) == faults + 1 and rm.points == points + 10, "límite: despacio todo el tramo da +10")
	car.restart_at(2780.0)
	driver.brake_after = 3480.0
	driver.target = 110.0
	await wait(1.5)
	await drive(car.progress, 70.0, 3480.0, 10.0)
	check(rm.infractions.get(&"speed", 0) == faults + 1 and rm.points == points + 20, "límite: pasarse menos de 2 s no es falta")
	car.restart_at(2900.0)
	driver.target = 60.0
	await wait(1.0)
	driver.stop_driving()
	car.restart_at(2650.0)
	await wait(0.3)
	check(rm.points == points + 20, "límite: regresar hacia atrás no cuenta como pasar el tramo")


func bike_lane() -> void:
	var faults: int = rm.infractions.get(&"bike_lane", 0)
	if car.lane_index != 1:
		car.restart_at(200.0)
		await tap(&"car_right")
		await wait(1.6)
	check(car.lane_index == 1, "ciclovía: el auto va en el carril derecho")
	var points := rm.points
	await drive(200.0, 100.0, 1130.0, 12.0)
	check(rm.points == points + 10 and rm.infractions.get(&"bike_lane", 0) == faults, "ciclovía: respetarla da +10")
	car.restart_at(200.0)
	driver.brake_after = 1130.0
	driver.target = 100.0
	while car.progress < 600.0:
		await get_tree().physics_frame
	await tap(&"car_left")
	while car.progress < 1125.0:
		await get_tree().physics_frame
	driver.target = 0.0
	await wait(1.0)
	driver.stop_driving()
	await wait_unpaused()
	check(car.lane_index == 0 and rm.infractions.get(&"bike_lane", 0) == faults + 1 and rm.points == points + 10, "ciclovía: cambiarse a medio tramo es falta y sin puntos")
	await drive(200.0, 100.0, 1130.0, 12.0)
	check(rm.infractions.get(&"bike_lane", 0) == faults + 2 and rm.points == points + 10, "ciclovía: llegar ya dentro es falta y sin puntos")
