extends TestCase
## Recorridos completos de los niveles 0, 1 y 2 por el puente (FakeBridge):
## - Un conductor cuidadoso los termina con 3 estrellas y sin faltas.
## - Uno que corre en la zona escolar saca menos estrellas.

var car: PlayerCar
var stops: Array = []
var zones: Array = []
var stopped_at := {}
var cruise := 150.0
var respect_limits := true
var respect_signals := true


func must_wait(piece: Node) -> bool:
	if piece is Crosswalk:
		return (piece as Crosswalk).is_occupied()
	if not respect_signals:
		return false
	if piece is StopZone:
		return stopped_at.get(piece, 0.0) < 0.6
	if piece is TrafficLight:
		return (piece as TrafficLight).light != TrafficLight.Light.GREEN
	return false


func _physics_process(delta: float) -> void:
	if car == null or get_tree().paused:
		return
	var p := car.progress
	var target := cruise
	if respect_limits:
		for z: SpeedZone in zones:
			var start := z.position.x - 64.0 - 120.0
			if p > start and p < z.position.x - 64.0 + z.zone_length:
				target = minf(target, z.get_limit_speed() * 0.8)
	for s in stops:
		var at: float = s[0]
		var piece: Node = s[1]
		if p > at + 5.0 or p < at - 600.0:
			continue
		if absf(p - at) < 6.0 and car.speed < 5.0:
			stopped_at[piece] = stopped_at.get(piece, 0.0) + delta
		if must_wait(piece):
			target = minf(target, sqrt(maxf(0.0, 2.0 * 220.0 * (at - p))))
		break
	if car.speed < target - 4.0:
		Input.action_press(&"car_accelerate")
	else:
		Input.action_release(&"car_accelerate")
	if car.speed > target + 4.0:
		Input.action_press(&"car_brake")
	else:
		Input.action_release(&"car_brake")


func play(id: int) -> Variant:
	var fake := fake_bridge()
	fake.send_start(id)
	await frames()
	var level := get_tree().current_scene
	var rm := level.get_node("RuleManager") as RuleManager
	stops.clear()
	zones.clear()
	stopped_at.clear()
	for piece in level.get_node("Rules").get_children():
		var x: float = piece.position.x - 64.0
		if piece is Crosswalk:
			stops.append([x - piece.crosswalk_width / 2.0 - piece.fault_margin - 40.0, piece])
		elif piece is StopZone or piece is TrafficLight:
			stops.append([x - 45.0, piece])
		elif piece is SpeedZone:
			zones.append(piece)
	stops.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var done := [false]
	rm.level_finished.connect(func(_stars: int) -> void: done[0] = true)
	await tap(&"car_seatbelt")
	car = rm.car
	var t := 0.0
	while not done[0] and t < 240.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	car = null
	release_inputs()
	var result: Variant = null
	for m in fake.sent:
		if m[0] == "level_finished" and m[1]["level_id"] == id:
			result = m[1]
	await wait(1.5)
	BridgeClient.exit_level(true)
	await frames()
	return result


func run() -> void:
	fake_bridge().auto_start = false
	Engine.time_scale = 3.0
	BridgeClient._go_idle()
	await frames()
	for id in [0, 1, 2]:
		fake_bridge().sent.clear()
		var result: Variant = await play(id)
		print("    nivel %d: %s" % [id, str(result)])
		check(result != null and result["stars"] == 3 and result["infractions"].is_empty(), "nivel %d: el conductor cuidadoso lo termina con 3 estrellas y sin faltas" % id)
	# Modo peque: el auto avanza solo; el conductor solo frena.
	fake_bridge().mode = GameState.MODE_PEQUE
	for id in [0, 1, 2]:
		fake_bridge().sent.clear()
		var result: Variant = await play(id)
		print("    nivel %d (peque): %s" % [id, str(result)])
		check(result != null and result["stars"] == 3 and result["infractions"].is_empty(), "nivel %d en modo peque: frenando a tiempo se termina con 3 estrellas" % id)
	fake_bridge().mode = GameState.MODE_GRANDE
	respect_limits = false
	cruise = 240.0
	fake_bridge().sent.clear()
	var fast: Variant = await play(1)
	print("    nivel 1 corriendo: %s" % str(fast))
	check(fast != null and fast["stars"] < 3 and fast["infractions"].has("speed"), "nivel 1: correr en la zona escolar da falta speed y menos estrellas")
	respect_limits = true
	cruise = 150.0
	Engine.time_scale = 1.0
