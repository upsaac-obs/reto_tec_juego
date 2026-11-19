extends TestCase
## LaneMerge en levels/level_05.tscn (Rules/LaneMerge, x = 4150): a ras del primer
## auto estacionado (borde en x = 4158) hay que ir en el carril izquierdo (0).
## - En el carril derecho: falta no grave (lane, FALTA_CARRIL) y después el auto
##   se pasa solo al carril izquierdo (Route/OneLane, x = 4126), empezando justo
##   cuando su frente llega al primer auto estacionado.
## - Ya en el carril izquierdo, o cambiándose con la flecha antes: nada (sin
##   mensaje, puntos, pausa ni movimiento raro).
## Las distancias son progreso sobre la ruta (la ruta empieza en x = 64); el
## frente del auto va HALF_CAR px delante de su centro.

const HALF_CAR := 33.0
## Progreso cuando el frente del auto llega a LaneMerge (x = 4150).
const MERGE := 4053.0
## Progreso del inicio de OneLane (x = 4126).
const ONE_LANE := 4062.0
## Progreso cuando el frente del auto llega al primer auto estacionado (x = 4158).
const PARKED_FRONT := 4061.0
## Hasta dónde puede terminar el cambio automático: lane_change_time a 240 px/s
## (lo más rápido que se llega en la calle) más un margen.
const MERGE_END := PARKED_FRONT + 0.4 * 240.0 + 10.0
## Arranque de las pruebas: después de CheckpointAfterLight2 (x = 3904) y antes de LaneMerge.
const START := 3760.0
## Lejos antes de LaneMerge, para cambiarse con calma (pasa CheckpointAfterLight2).
const START_EARLY := 3560.0
const LEFT := -32.0
const RIGHT := 32.0

var level: Node
var rm: RuleManager
var car: PlayerCar
var merge: LaneMerge
var driver: TestDriver
## Lo que se vio en cada cuadro de física (lo llena watch()).
var seen := {}


func open_level() -> void:
	level = await open_scene("res://levels/level_05.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	car = rm.car
	car.seatbelt_on = true
	merge = level.get_node("Rules/LaneMerge") as LaneMerge
	driver = TestDriver.new()
	driver.car = car
	add_child(driver)
	seen = {"paused": false, "bad_bubble": false, "fault_progress": -1.0, "fault_v_offset": 0.0,
		"fault_grave": false, "good": 0, "merged_progress": -1.0, "max_left_dev": 0.0, "signal": false,
		"moved_before_fault": false}
	rm.infraction_reported.connect(_on_infraction)
	rm.good_action_reported.connect(func(_id: StringName, _points: int) -> void: seen["good"] += 1)
	get_tree().physics_frame.connect(watch)


func close_level() -> void:
	get_tree().physics_frame.disconnect(watch)
	driver.stop_driving()
	driver.queue_free()
	release_inputs()
	await close_scene(level)


func _on_infraction(rule_id: StringName, grave: bool) -> void:
	if rule_id == &"lane" and seen["fault_progress"] < 0.0:
		seen["fault_progress"] = car.progress
		seen["fault_v_offset"] = car.v_offset
		seen["fault_grave"] = grave


func watch() -> void:
	if car == null:
		return
	var bubble: CopilotBubble = Feedback._bubble
	seen["paused"] = seen["paused"] or get_tree().paused
	seen["bad_bubble"] = seen["bad_bubble"] or (bubble._box.visible and bubble._message.theme_type_variation == &"MessageBad")
	if seen["merged_progress"] < 0.0 and absf(car.v_offset - LEFT) < 0.5:
		seen["merged_progress"] = car.progress
	if seen["fault_progress"] < 0.0 and car.v_offset < RIGHT - 0.5 and car.lane_index == 1:
		seen["moved_before_fault"] = true
	if car.progress > START_EARLY + 260.0:
		seen["max_left_dev"] = maxf(seen["max_left_dev"], absf(car.v_offset - LEFT))
	seen["signal"] = seen["signal"] or car.turn_signal != 0


func wait_until(condition: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while not condition.call() and elapsed < timeout:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	return condition.call()


## Pone el auto en ese carril y progreso, ya a speed px/s.
func place(lane: int, at: float, speed: float) -> void:
	car.lane_index = lane
	car.restart_at(at)
	car.speed = speed
	driver.brake_after = INF
	driver.target = speed


## Maneja hasta pasar ese progreso (las pausas de las faltas se esperan).
func drive_past(until: float) -> void:
	await wait_until(func() -> bool: return car.progress >= until, 30.0)


func run() -> void:
	# 1. En el carril derecho: falta no grave, y después se pasa solo al carril izquierdo
	for speed in [120.0, 240.0]:
		await open_level()
		place(1, START, speed)
		check(car.lane_index == 1 and is_equal_approx(car.v_offset, RIGHT), "%d px/s: arranca en el carril derecho" % speed)
		await wait_until(func() -> bool: return seen["fault_progress"] >= 0.0, 10.0)
		check(rm.infractions.get(&"lane", 0) == 1 and rm.faults == 1 and not seen["fault_grave"], "%d px/s: en el carril derecho hay 1 falta lane no grave" % speed)
		check(get_tree().paused and Feedback.is_pausing(), "%d px/s: la falta pausa el juego" % speed)
		var label := Feedback._bubble.get_node("%MessageLabel") as Label
		check(label.text == tr("FALTA_CARRIL") and tr("FALTA_CARRIL") != "FALTA_CARRIL", "%d px/s: el copiloto dice FALTA_CARRIL" % speed)
		var fault_front: float = seen["fault_progress"] + HALF_CAR
		check(seen["fault_progress"] < ONE_LANE and absf(fault_front - (MERGE + HALF_CAR)) < 8.0, "%d px/s: la falta llega con el frente en LaneMerge (%.0f), antes de OneLane" % [speed, fault_front + 64.0])
		check(is_equal_approx(seen["fault_v_offset"], RIGHT) and not seen["moved_before_fault"], "%d px/s: el auto no empezó a cambiarse antes de la falta" % speed)
		await wait_unpaused()
		await drive_past(PARKED_FRONT + 120.0)
		check(seen["merged_progress"] >= ONE_LANE and seen["merged_progress"] < MERGE_END, "%d px/s: el cambio empieza al llegar al primer auto estacionado y termina enseguida (frente en x = %.0f)" % [speed, seen["merged_progress"] + HALF_CAR + 64.0])
		check(rm.infractions.get(&"lane", 0) == 1 and merge.has_faulted(), "%d px/s: la falta no se repite en la misma pasada" % speed)
		check(rm.get_stars() == 2, "%d px/s: la falta cuenta para las estrellas (2)" % speed)
		await close_level()

	# 2. Ya en el carril izquierdo: nada de nada
	await open_level()
	place(0, START, 120.0)
	await drive_past(PARKED_FRONT + 120.0)
	check(merge.is_evaluated() and not merge.has_faulted(), "en el carril izquierdo LaneMerge revisa y no marca falta")
	check(rm.faults == 0 and rm.points == 0 and seen["good"] == 0, "en el carril izquierdo: 0 faltas y 0 puntos")
	check(not seen["paused"] and not seen["bad_bubble"], "en el carril izquierdo no hay pausa ni mensaje de falta")
	check(seen["max_left_dev"] < 0.5 and not seen["signal"], "en el carril izquierdo el auto no se mueve ni pone direccional al entrar a OneLane (%.2f)" % seen["max_left_dev"])
	# Conductor cuidadoso de test_levels.gd: se pasa al carril 0 antes de LaneMerge.
	var span: Vector2 = merge.careful_range()
	check(merge.careful_lane() == 0 and is_equal_approx(span.x, 4150.0) and is_equal_approx(span.y, 4158.0), "careful_lane() = 0 y careful_range() = (4150, 4158)")
	await close_level()

	# 3. Cambio preventivo con la flecha, con tiempo
	await open_level()
	place(1, START_EARLY, 120.0)
	await drive_past(START_EARLY + 20.0)
	await tap(&"car_left")
	await drive_past(PARKED_FRONT + 120.0)
	check(not merge.has_faulted() and rm.faults == 0 and rm.points == 0 and seen["good"] == 0, "cambiarse antes con la flecha: 0 faltas y 0 puntos")
	check(not seen["paused"] and not seen["bad_bubble"], "cambiarse antes: sin pausa ni mensaje de falta")
	check(seen["max_left_dev"] < 0.5 and car.lane_index == 0, "cambiarse antes: al entrar a OneLane no hay movimiento (%.2f)" % seen["max_left_dev"])
	await close_level()

	# 4. Flecha justo antes de LaneMerge: la direccional ya está puesta, no es falta
	await open_level()
	place(1, START, 120.0)
	await drive_past(MERGE - 90.0)
	await tap(&"car_left")
	await drive_past(MERGE + 8.0)
	check(merge.is_evaluated() and car.turn_signal == -1 and car.lane_index == 1, "la direccional sigue puesta al llegar a LaneMerge (cambio en marcha)")
	await drive_past(PARKED_FRONT + 120.0)
	check(not merge.has_faulted() and rm.faults == 0 and rm.points == 0 and not seen["paused"] and not seen["bad_bubble"], "con el cambio en marcha no hay falta, puntos, pausa ni mensaje")
	check(seen["merged_progress"] > 0.0 and seen["merged_progress"] < MERGE_END, "con el cambio en marcha también queda en el carril izquierdo junto al primer auto")
	await close_level()

	# 5. Puntos de control: el de antes la vuelve a revisar; el de la calle no
	await open_level()
	place(1, START, 120.0)
	await wait_until(func() -> bool: return seen["fault_progress"] >= 0.0, 10.0)
	await wait_unpaused()
	await drive_past(PARKED_FRONT + 120.0)
	check(rm.infractions.get(&"lane", 0) == 1, "primera pasada: 1 falta")
	# CheckpointBallStreet (x = 4160) va después de LaneMerge: no la reinicia.
	var street_checkpoint := 4096.0
	car.restart_at(street_checkpoint)
	rm.checkpoint_restored.emit(street_checkpoint)
	await frames(2)
	check(merge.is_evaluated() and car.lane_index == 0 and is_equal_approx(car.v_offset, LEFT), "regresar a CheckpointBallStreet no reinicia LaneMerge y deja al auto en el carril izquierdo")
	# Un punto de control anterior (antes de LaneMerge) en el carril derecho: se vuelve a revisar.
	# El auto reapareció encima de la zona de LaneMerge: se espera a que la física
	# termine de avisar su entrada antes de reiniciar.
	await wait(0.2)
	driver.stop_driving()
	seen["fault_progress"] = -1.0
	car.lane_index = 1
	car.restart_at(START)
	rm.checkpoint_restored.emit(START)
	await frames(2)
	check(not merge.is_evaluated(), "regresar a un punto de control anterior reinicia LaneMerge")
	place(1, START, 120.0)
	await wait_until(func() -> bool: return seen["fault_progress"] >= 0.0, 10.0)
	check(rm.infractions.get(&"lane", 0) == 2, "después del punto de control anterior la falta se vuelve a marcar")
	await wait_unpaused()
	await close_level()

	# 6. Peque: las mismas reglas (el auto avanza solo, sin pedales)
	GameState.mode = GameState.MODE_PEQUE
	for lane in [1, 0]:
		await open_level()
		car.lane_index = lane
		car.restart_at(START)
		await wait_until(func() -> bool: return car.progress >= PARKED_FRONT + 120.0 and not get_tree().paused, 30.0)
		if lane == 1:
			check(rm.infractions.get(&"lane", 0) == 1 and seen["merged_progress"] >= ONE_LANE and seen["merged_progress"] < MERGE_END, "peque en el carril derecho: falta lane y se cambia solo al llegar al primer auto")
		else:
			check(rm.faults == 0 and not seen["paused"] and not seen["bad_bubble"] and seen["max_left_dev"] < 0.5, "peque en el carril izquierdo: sin falta, pausa ni movimiento")
		await close_level()
	GameState.mode = GameState.MODE_GRANDE

	# 7. Textos (la voz FALTA_CARRIL.ogg puede faltar: sin ella el mensaje dura message_time)
	check(tr("FALTA_CARRIL") != "FALTA_CARRIL" and tr("REGLA_LANE") != "REGLA_LANE", "FALTA_CARRIL y REGLA_LANE están en textos.csv")
