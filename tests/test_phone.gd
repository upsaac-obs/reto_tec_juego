extends TestCase
## Celular del nivel 6 (levels/level_06.tscn, pieza PhoneEvent).
## La ruta empieza en x = 64: progress = x - 64. Phone1 en x = 1000 (ignorar,
## 5 s / 900 px), Phone2 en 3500 (ignorar, 6 s / 700 px), Phone3 en 5900 (contestar
## en el ParkingSpot de x = 6400, progress 6336).

const SPOT_PROGRESS := 6336.0

var level: Node
var rm: RuleManager
var car: PlayerCar
var phone1: PhoneEvent
var phone2: PhoneEvent
var phone3: PhoneEvent
var spot: ParkingSpot
var driver: TestDriver


func open_level(mode: String) -> void:
	GameState.mode = mode
	level = await open_scene("res://levels/level_06.tscn")
	rm = level.get_node("RuleManager") as RuleManager
	car = rm.car
	car.seatbelt_on = true
	phone1 = level.get_node("Rules/Phone1") as PhoneEvent
	phone2 = level.get_node("Rules/Phone2") as PhoneEvent
	phone3 = level.get_node("Rules/Phone3") as PhoneEvent
	spot = level.get_node("Rules/ParkingSpot") as ParkingSpot
	for phone in [phone1, phone2, phone3]:
		# Sin sonido para no llenar los canales de efectos durante las pruebas.
		(phone as PhoneEvent).ring_sfx = &""
		(phone as PhoneEvent).vibrate_sfx = &""
	driver = TestDriver.new()
	driver.car = car
	add_child(driver)


func close_level() -> void:
	driver.stop_driving()
	driver.queue_free()
	release_inputs()
	await close_scene(level)
	GameState.mode = GameState.MODE_GRANDE


func wait_until(condition: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while not condition.call() and elapsed < timeout:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	return condition.call()


func layer_of(phone: PhoneEvent) -> CanvasLayer:
	return phone.get_node("Layer") as CanvasLayer


func run() -> void:
	Engine.time_scale = 2.0
	await _structure()
	await _ignore()
	await _ignore_by_distance()
	await _touch_moving()
	await _touch_stopped()
	await _answer_parked()
	await _touch_entering_spot()
	await _no_answer()
	await _peque()
	await _checkpoint()
	await _traffic()
	Engine.time_scale = 1.0


# 0. Estructura del nivel
func _structure() -> void:
	await open_level(GameState.MODE_GRANDE)
	var phones := level.get_node("Rules").get_children().filter(func(n: Node) -> bool: return n is PhoneEvent)
	check(phones.size() == 3, "el nivel 6 tiene 3 celulares")
	check(phone1.spot == null and phone2.spot == null, "Phone1 y Phone2 están en modo ignorar")
	check(phone3.spot == spot, "Phone3 contesta en el ParkingSpot del nivel")
	check(not spot.show_finish_line and not spot.release_after_park, "el cajón no es meta y no suelta el auto solo")
	var data := LevelData.load_by_id(6)
	check(data.destination_key == "DESTINO_CASA_PRIMOS" and data.scene_path == "res://levels/level_06.tscn", "LevelData 6 apunta a la escena y a la casa de los primos")
	var ground := level.get_node("Ground") as TileMapLayer
	var finish := ground.get_used_cells_by_id(0, Vector2i(4, 1))
	check(not finish.is_empty() and finish.all(func(c: Vector2i) -> bool: return c.x == 124), "las losas de meta siguen al final de la calle")
	check(not layer_of(phone1).visible and phone1.get_state() == PhoneEvent.State.IDLE, "al empezar el celular no se ve")
	await close_level()


# 1. Dejarlo sonar da +10
func _ignore() -> void:
	await open_level(GameState.MODE_GRANDE)
	car.restart_at(700.0)
	driver.target = 170.0
	var rang := await wait_until(func() -> bool: return phone1.is_ringing(), 5.0)
	check(rang and layer_of(phone1).visible, "Phone1 suena y se ve al pasar por su trigger")
	var points := rm.points
	var done := await wait_until(func() -> bool: return phone1.get_state() == PhoneEvent.State.DONE, phone1.ring_time + 1.0)
	check(done, "se calla en ring_time")
	check(rm.points == points + 10 and rm.faults == 0, "dejarlo sonar da +10 y sin faltas")
	check(not layer_of(phone1).visible, "al callarse se oculta")
	await close_level()


# 2. Se calla por distancia si el auto va rápido
func _ignore_by_distance() -> void:
	await open_level(GameState.MODE_GRANDE)
	car.restart_at(700.0)
	driver.target = 240.0
	await wait_until(func() -> bool: return phone1.is_ringing(), 5.0)
	var elapsed := [0.0]
	var done := false
	while not done and elapsed[0] < phone1.ring_time + 1.0:
		await get_tree().physics_frame
		elapsed[0] += get_physics_process_delta_time()
		done = phone1.get_state() == PhoneEvent.State.DONE
	check(done and elapsed[0] < phone1.ring_time, "a 240 px/s se calla antes de ring_time")
	check(car.progress >= 936.0 + phone1.ring_distance - 10.0, "se calla al recorrer ring_distance")
	await close_level()


# 3 y 4. Tocar en movimiento: tapa la calle sin pausa y luego es falta, una por pasada
func _touch_moving() -> void:
	await open_level(GameState.MODE_GRANDE)
	car.restart_at(700.0)
	driver.target = 170.0
	await wait_until(func() -> bool: return phone1.is_ringing(), 5.0)
	var points := rm.points
	phone1.touch_phone()
	check(phone1.is_covering() and rm.faults == 0 and not get_tree().paused, "al tocarlo en movimiento tapa la calle sin pausar ni reportar todavía")
	await wait(1.0)
	var holder := phone1.get_node("Layer/Holder") as Node2D
	check(car.speed > 10.0, "mientras tapa, el auto sigue avanzando")
	check(absf(holder.scale.x - phone1.cover_scale) < 0.01 and layer_of(phone1).visible, "el celular está grande (cover_scale)")
	phone1.touch_phone()
	var faulted := await wait_until(func() -> bool: return rm.faults > 0, phone1.cover_time + phone1.grow_time)
	check(faulted and rm.faults == 1 and rm.infractions.get(&"phone", 0) == 1, "al terminar la tapa se reporta la falta phone")
	check(rm.points == points, "la falta no da puntos")
	await wait_unpaused()
	check(not layer_of(phone1).visible and phone1.get_state() == PhoneEvent.State.DONE, "después de la falta el celular se va (DONE)")
	phone1.touch_phone()
	phone1.touch_phone()
	check(rm.faults == 1, "tocar otra vez no suma otra falta en la pasada")
	await wait(phone1.ring_time)
	check(rm.points == points, "si lo tocó en movimiento no hay +10 de ignorar")
	await close_level()


# 5. Tocarlo detenido no es falta
func _touch_stopped() -> void:
	await open_level(GameState.MODE_GRANDE)
	car.restart_at(3300.0)
	driver.target = 170.0
	await wait_until(func() -> bool: return phone2.is_ringing(), 5.0)
	driver.target = 0.0
	await wait_until(func() -> bool: return car.speed == 0.0, 3.0)
	var points := rm.points
	phone2.touch_phone()
	check(rm.faults == 0 and phone2.is_ringing() and not phone2.is_covering(), "tocarlo detenido no es falta y sigue sonando")
	driver.target = 170.0
	var done := await wait_until(func() -> bool: return phone2.get_state() == PhoneEvent.State.DONE, phone2.ring_time + 1.0)
	check(done and rm.points == points + 10 and rm.faults == 0, "al callarse da el +10 de ignorar")
	await close_level()


# 6. Contestar estacionado
func _answer_parked() -> void:
	await open_level(GameState.MODE_GRANDE)
	car.restart_at(5500.0)
	driver.target = 170.0
	var parked := await wait_until(func() -> bool: return spot.is_parked(), 25.0)
	check(parked and phone3.is_answerable(), "al estacionarse el celular se puede contestar")
	var points := rm.points
	phone3.touch_phone()
	check(rm.points == points + 10 and rm.faults == 0, "contestar estacionado da +10")
	await wait(1.0)
	check(car.speed == 0.0 and spot.is_parked() and not spot.is_released(), "durante la llamada sigue estacionado aunque pise el pedal")
	var left := await wait_until(func() -> bool: return car.progress > SPOT_PROGRESS + 100.0, phone3.call_time + phone3.release_delay + 5.0)
	check(left and phone3.get_state() == PhoneEvent.State.DONE, "después de la llamada el auto sigue la ruta")
	await close_level()


# 7. Tocar mientras entra al cajón es falta; después contesta estacionado
func _touch_entering_spot() -> void:
	await open_level(GameState.MODE_GRANDE)
	car.restart_at(5500.0)
	driver.target = 170.0
	await wait_until(func() -> bool: return phone3.is_ringing() and car.speed > 10.0, 10.0)
	phone3.touch_phone()
	check(phone3.is_covering(), "tocar Phone3 rodando tapa la calle")
	await wait_until(func() -> bool: return rm.faults > 0, phone3.cover_time + phone3.grow_time + 0.5)
	check(rm.infractions.get(&"phone", 0) == 1, "tocarlo mientras entra al cajón es falta phone")
	await wait_unpaused()
	check(phone3.get_state() == PhoneEvent.State.WAITING_PARK and not layer_of(phone3).visible, "después de la tapa el celular espera al cajón")
	var parked := await wait_until(func() -> bool: return spot.is_parked(), 20.0)
	check(parked and phone3.is_answerable() and layer_of(phone3).visible, "ya estacionado vuelve a sonar y se puede contestar")
	var points := rm.points
	phone3.touch_phone()
	check(rm.points == points + 10 and rm.faults == 1, "contestar después de la falta también da +10")
	var left := await wait_until(func() -> bool: return car.progress > SPOT_PROGRESS + 100.0, phone3.call_time + phone3.release_delay + 5.0)
	check(left, "y el auto sale del cajón")
	await close_level()


# 8. Sin contestar, sigue solo
func _no_answer() -> void:
	await open_level(GameState.MODE_GRANDE)
	car.restart_at(5500.0)
	driver.target = 170.0
	await wait_until(func() -> bool: return spot.is_parked(), 25.0)
	var points := rm.points
	await wait(phone3.answer_timeout + 0.5)
	check(phone3.get_state() == PhoneEvent.State.DONE and spot.is_released(), "sin contestar, a answer_timeout suelta el auto")
	check(rm.points == points and rm.faults == 0, "sin contestar no hay puntos ni falta")
	var left := await wait_until(func() -> bool: return car.progress > SPOT_PROGRESS + 100.0, 5.0)
	check(left, "el auto sigue al dar gas")
	await close_level()


# 9 y 10. Peque: mismas reglas
func _peque() -> void:
	await open_level(GameState.MODE_PEQUE)
	car.restart_at(700.0)
	await wait_until(func() -> bool: return phone1.is_ringing(), 5.0)
	phone1.touch_phone()
	await wait_until(func() -> bool: return rm.faults > 0, phone1.cover_time + phone1.grow_time + 0.5)
	check(rm.infractions.get(&"phone", 0) == 1, "peque: tocarlo con el auto avanzando solo es falta")
	await wait_unpaused()
	# Otra pasada sin tocarlo.
	car.restart_at(600.0)
	rm.checkpoint_restored.emit(600.0)
	check(phone1.get_state() == PhoneEvent.State.IDLE, "un punto de control anterior reinicia el celular")
	var points := rm.points
	await wait_until(func() -> bool: return phone1.is_ringing(), 5.0)
	await wait_until(func() -> bool: return phone1.get_state() == PhoneEvent.State.DONE, phone1.ring_time + 1.0)
	check(rm.points == points + 10, "peque: dejarlo sonar da +10")
	await close_level()

	await open_level(GameState.MODE_PEQUE)
	car.restart_at(5500.0)
	var parked := await wait_until(func() -> bool: return spot.is_parked(), 30.0)
	check(parked and phone3.is_answerable(), "peque: se estaciona solo y el celular se puede contestar")
	points = rm.points
	phone3.touch_phone()
	check(rm.points == points + 10, "peque: contestar estacionado da +10")
	await wait(phone3.call_time + phone3.release_delay + 0.3)
	var left := await wait_until(func() -> bool: return car.progress > SPOT_PROGRESS + 50.0, 5.0)
	check(left and rm.faults == 0, "peque: después de la llamada el auto sigue solo")
	await close_level()


# 11. Punto de control
func _checkpoint() -> void:
	await open_level(GameState.MODE_GRANDE)
	car.restart_at(700.0)
	driver.target = 240.0
	await wait_until(func() -> bool: return phone1.get_state() == PhoneEvent.State.DONE, 8.0)
	car.restart_at(3300.0)
	var starts := [0]
	phone2.ring_started.connect(func() -> void: starts[0] += 1)
	await wait_until(func() -> bool: return phone2.is_ringing(), 5.0)
	car.restart_at(3236.0)
	rm.checkpoint_restored.emit(3236.0)
	check(phone2.get_state() == PhoneEvent.State.IDLE and not layer_of(phone2).visible, "volver a un punto de control anterior reinicia Phone2")
	check(phone1.get_state() == PhoneEvent.State.DONE, "Phone1 (antes del punto de control) no se reinicia")
	await wait_until(func() -> bool: return phone2.is_ringing(), 5.0)
	check(starts[0] == 2, "al manejar otra vez vuelve a sonar")
	await close_level()


# 12. Tráfico del carril izquierdo según el modo
func _traffic() -> void:
	if not ResourceLoader.exists("res://levels/level_06_traffic.gd"):
		return
	var counts := {}
	for mode in [GameState.MODE_GRANDE, GameState.MODE_PEQUE]:
		await open_level(mode)
		var traffic := level.get_node("TrafficLeft") as Path2D
		var seen := {}
		var behind := false
		car.restart_at(5500.0)
		driver.target = 170.0
		var elapsed := 0.0
		while elapsed < 12.0:
			await get_tree().physics_frame
			elapsed += get_physics_process_delta_time()
			for child in traffic.get_children():
				if child is NpcCar:
					seen[child.get_instance_id()] = true
					if (child as NpcCar).global_position.x < 5100.0 - 1.0:
						behind = true
		counts[mode] = seen.size()
		check(not behind, "%s: ningún auto del tráfico aparece antes de x = 5100" % mode)
		await close_level()
	check(counts[GameState.MODE_GRANDE] >= 2, "grande: pasan varios autos por el carril izquierdo")
	check(counts[GameState.MODE_PEQUE] <= counts[GameState.MODE_GRANDE], "peque: igual o menos tráfico que grande")
