extends TestCase
## Tramo oscuro (nivel 7) en levels/level_07.tscn. DarkDusk empieza en x = 1000
## (progreso 936, la ruta empieza en x = 64) y termina en x = 2000; DarkTunnel va
## de 3800 a 5200 (límite de 30 km/h) y DarkRain de 6600 a 8000.

const DUSK_START := 936.0
const DUSK_PAST := 2100.0
const CHECKPOINT_AFTER_DUSK := 2236.0

var level: Node
var rm: RuleManager
var car: PlayerCar
var driver: TestDriver
var goods: Array = []


func open_level() -> void:
	level = await open_scene("res://levels/level_07.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	car = rm.car
	car.seatbelt_on = true
	goods.clear()
	rm.good_action_reported.connect(func(id: StringName, pts: int) -> void: goods.append([id, pts, car.progress]))
	driver = TestDriver.new()
	driver.car = car
	add_child(driver)


func close_level() -> void:
	driver.stop_driving()
	driver.queue_free()
	release_inputs()
	car.set_headlights(false)
	await close_scene(level)


func zone(zone_name: String) -> DarkZone:
	return level.get_node("Rules/" + zone_name) as DarkZone


func light_goods() -> Array:
	return goods.filter(func(g: Array) -> bool: return g[0] == &"lights")


func lights_faults() -> int:
	return rm.infractions.get(&"lights", 0)


## Avanza (con el driver) hasta que se cumpla `done` o pasen `limit` segundos de juego.
func drive_until(done: Callable, limit := 30.0) -> void:
	var t := 0.0
	while not done.call() and t < limit:
		await get_tree().physics_frame
		if not get_tree().paused:
			t += get_physics_process_delta_time()


func run() -> void:
	GameState.mode = GameState.MODE_GRANDE

	# 1 y 2. Sin luces: una falta después de grace_time dentro, y solo una por pasada
	await open_level()
	check(zone("DarkDusk").is_in_group(&"needs_headlights"), "el tramo oscuro está en el grupo needs_headlights")
	check((level.get_node("Hud") as Hud).show_lights_button, "el nivel 7 muestra el botón de luces")
	car.restart_at(700.0)
	driver.target = 150.0
	await drive_until(func() -> bool: return lights_faults() > 0)
	var fault_progress := car.progress
	check(lights_faults() == 1, "entrar al tramo oscuro sin luces es falta lights")
	check(fault_progress > DUSK_START + 200.0, "la falta llega después de más de 2 s dentro (progreso %d)" % int(fault_progress))
	await drive_until(func() -> bool: return car.progress > DUSK_PAST)
	check(lights_faults() == 1 and light_goods().is_empty(), "sin luces todo el tramo: una sola falta y ningún +10 de luces")
	check(not zone("DarkDusk").is_car_inside(), "al salir, is_car_inside() es false")
	await close_level()

	# 3. Prender las luces al entrar: +10 y ninguna falta
	await open_level()
	car.restart_at(700.0)
	driver.target = 150.0
	await drive_until(func() -> bool: return car.progress >= DUSK_START + 4.0)
	car.set_headlights(true)
	await drive_until(func() -> bool: return car.progress > DUSK_PAST)
	var good := light_goods()
	check(good.size() == 1 and good[0][1] == 10, "prender las luces al entrar da +10 de luces")
	check(lights_faults() == 0, "y ninguna falta lights")
	await close_level()

	# 4. Entrar ya con las luces prendidas: +10 tras confirm_time
	await open_level()
	car.set_headlights(true)
	car.restart_at(700.0)
	driver.target = 150.0
	var lit_zone := zone("DarkDusk")
	await drive_until(func() -> bool: return lit_zone.is_car_inside())
	var inside_time := 0.0
	while light_goods().is_empty() and inside_time < 5.0:
		await get_tree().physics_frame
		inside_time += get_physics_process_delta_time()
	check(inside_time >= lit_zone.confirm_time - 0.05, "el +10 llega después de confirm_time dentro (%.2f s)" % inside_time)
	await drive_until(func() -> bool: return car.progress > DUSK_PAST)
	good = light_goods()
	check(good.size() == 1 and lights_faults() == 0, "entrar con las luces ya prendidas da +10 sin falta")
	await close_level()

	# 5. Prender tarde (después de la falta) no premia en esa pasada
	await open_level()
	car.restart_at(700.0)
	driver.target = 150.0
	await drive_until(func() -> bool: return lights_faults() > 0)
	await wait_unpaused()
	car.set_headlights(true)
	await drive_until(func() -> bool: return car.progress > DUSK_PAST)
	check(lights_faults() == 1 and light_goods().is_empty(), "prender las luces después de la falta no da +10")
	await close_level()

	# 6. Los ciclistas solo se ven (encima de la sombra) con luces
	await open_level()
	var dusk := zone("DarkDusk")
	car.restart_at(800.0)
	driver.target = 150.0
	await drive_until(func() -> bool: return car.progress > DUSK_START + 80.0)
	check(dusk.is_car_inside(), "dentro del tramo, is_car_inside() es true")
	check(dusk.get_riders().size() == 2, "en grande salen 2 ciclistas en el atardecer")
	check(not dusk.are_riders_lit(), "sin luces los ciclistas quedan debajo de la sombra")
	car.set_headlights(true)
	check(dusk.are_riders_lit(), "al prender las luces se iluminan en el mismo cuadro")
	car.set_headlights(false)
	check(not dusk.are_riders_lit(), "al apagarlas vuelven a la sombra")
	car.set_headlights(true)
	await drive_until(func() -> bool: return car.progress > DUSK_PAST)
	check(not dusk.are_riders_lit(), "al salir del tramo ya no se marcan iluminados")
	await close_level()

	# 7. Peque: un ciclista por tramo y la misma falta sin luces
	GameState.mode = GameState.MODE_PEQUE
	await open_level()
	dusk = zone("DarkDusk")
	car.restart_at(800.0)
	await drive_until(func() -> bool: return car.progress > DUSK_START + 80.0)
	check(dusk.get_riders().size() == 1, "en peque sale un solo ciclista")
	await drive_until(func() -> bool: return lights_faults() > 0)
	check(lights_faults() == 1, "en peque, sin luces, también es falta lights")
	await close_level()
	GameState.mode = GameState.MODE_GRANDE

	# 8. Lluvia: gotas solo dentro; salir devuelve todo
	await open_level()
	var wet := zone("DarkRain")
	var rain := wet.get_node("Rain") as CPUParticles2D
	check(not rain.emitting, "la lluvia no cae antes de llegar")
	car.set_headlights(true)
	car.restart_at(6400.0)
	driver.target = 150.0
	await drive_until(func() -> bool: return car.progress > 6536.0 + 100.0)
	check(wet.is_car_inside() and rain.emitting, "dentro del tramo de lluvia caen gotas")
	check(AudioManager.is_loop_playing(&"rain"), "y suena la lluvia")
	await drive_until(func() -> bool: return car.progress > 8150.0)
	check(not wet.is_car_inside() and not rain.emitting, "al salir deja de llover")
	check(not AudioManager.is_loop_playing(&"rain"), "y deja de sonar la lluvia")
	check(light_goods().size() == 1 and lights_faults() == 0, "con luces en la lluvia: +10 y sin falta")
	await close_level()

	# 9. Punto de control: la pieza vuelve a su estado inicial
	await open_level()
	var tunnel := zone("DarkTunnel")
	car.restart_at(3500.0)
	driver.target = 100.0
	await drive_until(func() -> bool: return lights_faults() > 0)
	await wait_unpaused()
	check(lights_faults() == 1 and tunnel.is_car_inside(), "en el túnel sin luces hay falta")
	check(tunnel.get_riders().size() == 2, "en el túnel hay 2 ciclistas")
	driver.stop_driving()
	car.restart_at(CHECKPOINT_AFTER_DUSK)
	rm.checkpoint_restored.emit(CHECKPOINT_AFTER_DUSK)
	await frames(3)
	check(not tunnel.is_car_inside() and tunnel.get_riders().is_empty(), "al volver al punto de control el túnel queda sin ciclistas ni estado")
	driver.target = 150.0
	await drive_until(func() -> bool: return lights_faults() > 1, 40.0)
	check(lights_faults() == 2, "al volver a entrar sin luces hay otra falta")
	await close_level()

	# 10. Nunca toca a un ciclista: por la ciclovía, el auto se detiene detrás
	await open_level()
	dusk = zone("DarkDusk")
	car.set_headlights(true)
	car.lane_index = 1
	car.restart_at(700.0)
	driver.target = 150.0
	var min_gap := INF
	var t := 0.0
	while car.progress < DUSK_PAST + 200.0 and t < 40.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		for rider in dusk.get_riders():
			if rider.global_position.x > car.global_position.x - 40.0:
				min_gap = minf(min_gap, absf(rider.global_position.x - car.global_position.x))
	check(car.lane_index == 1, "el auto fue por la ciclovía")
	check(min_gap > 40.0, "el auto nunca queda a menos de 40 px de un ciclista (mínimo %d)" % int(min_gap))
	check(rm.infractions.keys() == [&"bike_lane"] and rm.infractions[&"bike_lane"] == 1, "solo hay la falta de ciclovía: %s" % str(rm.infractions))
	await close_level()
