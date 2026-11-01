extends TestCase
## Modo peque: el auto avanza solo al 70 % del límite; el niño solo frena.


func run() -> void:
	var previous_mode := GameState.mode
	GameState.mode = GameState.MODE_PEQUE
	var level := await open_scene("res://levels/test_street.tscn")
	var rm := level.get_node("RuleManager") as RuleManager
	var car := rm.car
	check(car.auto_drive, "en modo peque el auto se maneja solo")
	check(not level.get_node("Hud/%Gas").visible and level.get_node("Hud/%Brake").visible, "HUD: sin pedal verde, con freno")

	car.restart_at(1300.0)
	await wait(1.0)
	check(car.speed == 0.0, "sin cinturón no avanza")
	car.seatbelt_on = true
	await wait(2.5)
	var target := car.max_speed * car.auto_drive_factor
	check(absf(car.speed - target) < 1.0, "acelera solo hasta el 70 %% del límite (%.0f px/s)" % car.speed)
	check(not car.is_accelerating, "acelerar solo no cuenta como pisar el pedal")

	var light := level.get_node("Rules/TrafficLight") as TrafficLight
	light.check_yellow = true
	light.yellow_time = 100.0
	light.set_light(TrafficLight.Light.YELLOW)
	car.restart_at(1750.0)
	await wait(2.5)
	check(not rm.infractions.has(&"yellow"), "en amarillo no hay falta por la aceleración automática")
	light.set_light(TrafficLight.Light.GREEN)

	var zone := level.get_node("Rules/SchoolZone") as SpeedZone
	var max_in_zone := 0.0
	car.restart_at(2650.0)
	var t := 0.0
	while t < 14.0 and car.progress < 3500.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if car.progress > zone.position.x - 64.0 + 40.0 and car.progress < zone.position.x - 64.0 + zone.zone_length:
			max_in_zone = maxf(max_in_zone, car.speed)
	await wait_unpaused()
	check(max_in_zone <= zone.get_limit_speed(), "en la zona escolar baja solo y no pasa el límite (máx. %.0f px/s)" % max_in_zone)
	check(not rm.infractions.has(&"speed"), "sin falta de velocidad en la zona escolar")
	await close_scene(level)
	GameState.mode = previous_mode
