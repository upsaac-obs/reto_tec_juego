# Creación y desarrollo: Dylan Isaac Mancilla López, José Paulo Vélez Ortiz, Diego Sánchez López
extends TestCase
## Recorridos completos de los niveles construidos por el puente (FakeBridge):
## - Un conductor cuidadoso los termina con 3 estrellas y sin faltas.
## - Uno que corre en la zona escolar saca menos estrellas.
## Los niveles salen solos de los LevelData construidos que heredan de level.tscn
## (levels()); un nivel nuevo entra a la prueba en cuanto tiene scene_path.
##
## Piezas nuevas sin tocar este archivo (se revisan con has_method, en Rules):
## - careful_stop_x() -> float: x (coordenadas del nivel) donde el conductor
##   cuidadoso se detiene, mientras must_wait() -> bool (o is_occupied()) sea true.
## - careful_lane() -> int y careful_range() -> Vector2 (x inicial y final): antes
##   y dentro de ese tramo el conductor se cambia a ese carril con las flechas.
## - Grupo "needs_headlights": si algún nodo del nivel está en él, el conductor
##   prende las luces al empezar.
## - DoorExit: abre la puerta de su cajón cuando no hay ciclistas cerca.

# Juega niveles enteros: run_tests.sh --fast la salta.
const SLOW := true

var car: PlayerCar
var stops: Array = []
var zones: Array = []
var stopped_at := {}
var cruise := 150.0
var respect_limits := true
var respect_signals := true
var doors: Array[DoorExit] = []
## [inicio, fin, carril] sobre la ruta, de las piezas con careful_lane().
var lanes: Array = []
var route: Path2D
## Distancia (px de ruta) antes de careful_range() a la que empieza a cambiarse.
const LANE_LEAD := 400.0


## Ids de los niveles construidos que heredan de level.tscn (el 99 no: es la
## escena de prueba del puente, sin auto).
static func levels() -> Array[int]:
	var ids: Array[int] = []
	for id in LevelData.IDS:
		var data := LevelData.load_by_id(id)
		if data == null or not data.is_built():
			continue
		var packed := load(data.scene_path) as PackedScene
		var base := packed.get_state().get_base_scene_state() if packed != null else null
		if base != null and base.get_path() == "res://scenes/level/level.tscn":
			ids.append(id)
	return ids


## Distancia sobre la ruta del punto más cercano a una posición global.
func route_progress(global_point: Vector2) -> float:
	return route.curve.get_closest_offset(route.to_local(global_point))


func must_wait(piece: Node) -> bool:
	if piece is Crosswalk:
		return (piece as Crosswalk).is_occupied()
	if piece is PatienceZone:
		return not (piece as PatienceZone).can_go()
	if not respect_signals:
		return false
	if piece is BlindCrossing:
		return stopped_at.get(piece, 0.0) < 0.6 or (piece as BlindCrossing).is_busy()
	if piece is StopZone:
		return stopped_at.get(piece, 0.0) < 0.6
	if piece is TrafficLight:
		return (piece as TrafficLight).light != TrafficLight.Light.GREEN
	if piece.has_method(&"must_wait"):
		return piece.call(&"must_wait")
	if piece.has_method(&"is_occupied"):
		return piece.call(&"is_occupied")
	return false


func _physics_process(delta: float) -> void:
	if car == null or get_tree().paused:
		return
	# Ya estacionado, el conductor cuidadoso espera a que pase la bici y abre.
	for door in doors:
		if door.spot != null and door.spot.is_parked() and not door.is_cyclist_near():
			door.open_door()
	var p := car.progress
	var target := cruise
	if respect_limits:
		for z: SpeedZone in zones:
			var start := route_progress(z.global_position) - 120.0
			if p > start and p < route_progress(z.to_global(Vector2(z.zone_length, 0.0))):
				target = minf(target, z.get_limit_speed() * 0.8)
	_keep_lane(p)
	for s in stops:
		var at: float = s[0]
		var piece: Node = s[1]
		if p > at + 5.0 or p < at - 600.0:
			continue
		if absf(p - at) < 6.0 and car.speed < 5.0:
			stopped_at[piece] = stopped_at.get(piece, 0.0) + delta
		if must_wait(piece):
			target = minf(target, sqrt(maxf(0.0, 2.0 * 220.0 * (at - p))))
			# En amarillo (regla yellow) no se deja avanzar el auto: si da tiempo,
			# frena; si ya está encima de la línea, cruza sin acelerar.
			if piece is TrafficLight and (piece as TrafficLight).light == TrafficLight.Light.YELLOW:
				target = minf(target, 0.0 if at - p > 40.0 else car.speed)
		break
	if car.speed < target - 4.0:
		Input.action_press(&"car_accelerate")
	else:
		Input.action_release(&"car_accelerate")
	# Para esperar hay que mantener el freno (en modo peque el auto avanza solo).
	if car.speed > target + 4.0 or target < 1.0:
		Input.action_press(&"car_brake")
	else:
		Input.action_release(&"car_brake")


## Se cambia al carril que piden las piezas con careful_lane(), una flecha a la vez.
func _keep_lane(p: float) -> void:
	for lane: Array in lanes:
		if p < lane[0] - LANE_LEAD or p > lane[1]:
			continue
		var wanted: int = lane[2]
		if car.lane_index != wanted and car.turn_signal == 0:
			var action := &"car_right" if wanted > car.lane_index else &"car_left"
			Input.action_press(action)
			_release_arrow.call_deferred(action)
		return


func _release_arrow(action: StringName) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)


func play(id: int) -> Variant:
	var fake := fake_bridge()
	fake.send_start(id)
	await frames()
	var level := get_tree().current_scene
	var rm := level.get_node("RuleManager") as RuleManager
	stops.clear()
	zones.clear()
	stopped_at.clear()
	doors.clear()
	lanes.clear()
	route = rm.car.get_parent() as Path2D
	for piece in level.get_node("Rules").get_children():
		if not piece is Node2D:
			continue
		var x: float = route_progress(piece.global_position)
		if piece is DoorExit:
			doors.append(piece)
		if piece.has_method(&"careful_lane") and piece.has_method(&"careful_range"):
			var span: Vector2 = piece.call(&"careful_range")
			var y: float = piece.global_position.y
			lanes.append([route_progress(Vector2(span.x, y)), route_progress(Vector2(span.y, y)), piece.call(&"careful_lane")])
		if piece is Crosswalk:
			stops.append([x - piece.crosswalk_width / 2.0 - piece.fault_margin - 40.0, piece])
		elif piece is PatienceZone:
			stops.append([x - piece.crosswalk_width / 2.0 - piece.light_gap - 45.0, piece])
		elif piece is BlindCrossing:
			# Se detiene sobre los ojos, antes de la línea de "mira".
			stops.append([x - piece.cross_width / 2.0 - 60.0, piece])
		elif piece is StopZone or piece is TrafficLight:
			stops.append([x - 45.0, piece])
		elif piece is SpeedZone:
			zones.append(piece)
		elif piece.has_method(&"careful_stop_x"):
			stops.append([route_progress(Vector2(piece.call(&"careful_stop_x"), piece.global_position.y)), piece])
	stops.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var done := [false]
	rm.level_finished.connect(func(_stars: int) -> void: done[0] = true)
	await tap(&"car_seatbelt")
	for node in get_tree().get_nodes_in_group(&"needs_headlights"):
		if level.is_ancestor_of(node):
			rm.car.set_headlights(true)
			break
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


## Modos que acepta --mode=.
const MODE_GRANDE := "grande"
const MODE_PEQUE := "peque"
const MODE_FAST_RUN := "fast-run"


## Lee --level=N y --mode=... de los argumentos de usuario (los que van tras
## "--", los mismos que recibe test_runner.gd). Devuelve {level, mode, error}:
## level = -1 y mode = "" cuando no se pidieron; error no vacío si algo no sirve.
static func parse_args(args: PackedStringArray) -> Dictionary:
	var out := {"level": -1, "mode": "", "error": ""}
	for arg: String in args:
		if arg.begins_with("--level="):
			var text := arg.trim_prefix("--level=")
			if not text.is_valid_int() or text.to_int() < 0:
				out["error"] = "--level debe ser un número de nivel, no '%s'" % text
			else:
				out["level"] = text.to_int()
		elif arg.begins_with("--mode="):
			var text := arg.trim_prefix("--mode=")
			if not text in [MODE_GRANDE, MODE_PEQUE, MODE_FAST_RUN]:
				out["error"] = "--mode debe ser grande, peque o fast-run, no '%s'" % text
			else:
				out["mode"] = text
	return out


## Un nivel en un modo: el conductor cuidadoso lo termina con 3 estrellas.
func play_level_case(id: int, peque: bool) -> void:
	fake_bridge().mode = GameState.MODE_PEQUE if peque else GameState.MODE_GRANDE
	fake_bridge().sent.clear()
	var result: Variant = await play(id)
	if peque:
		print("    nivel %d (peque): %s" % [id, str(result)])
		check(result != null and result["stars"] == 3 and result["infractions"].is_empty(), "nivel %d en modo peque: frenando a tiempo se termina con 3 estrellas" % id)
	else:
		print("    nivel %d: %s" % [id, str(result)])
		check(result != null and result["stars"] == 3 and result["infractions"].is_empty(), "nivel %d: el conductor cuidadoso lo termina con 3 estrellas y sin faltas" % id)


## Nivel 1 corriendo en grande, sin respetar límites.
func play_fast_run_case() -> void:
	fake_bridge().mode = GameState.MODE_GRANDE
	respect_limits = false
	cruise = 240.0
	fake_bridge().sent.clear()
	var fast: Variant = await play(1)
	print("    nivel 1 corriendo: %s" % str(fast))
	check(fast != null and fast["stars"] < 3 and fast["infractions"].has("speed"), "nivel 1: correr en la zona escolar da falta speed y menos estrellas")
	respect_limits = true
	cruise = 150.0


## Sin argumentos corre todo: cada nivel en grande, cada uno en peque y el caso
## corriendo. Filtros opcionales (para repartir el trabajo en paralelo):
##   --level=N   solo ese nivel (en grande y peque si no hay --mode); no aplica
##               a fast-run, que siempre es el nivel 1.
##   --mode=grande|peque|fast-run   solo ese modo (fast-run = nivel 1 corriendo).
## Un nivel inexistente o un modo inválido falla con un check, nunca pasa con 0.
## El check de la lista de niveles corre cuando no se pidió --level (todos los
## niveles están en juego): en la corrida completa y en --mode=fast-run, así que
## repartir los casos como un trabajo por nivel+modo más uno fast-run suma
## exactamente los mismos checks que la corrida sin argumentos.
func run() -> void:
	var opts := parse_args(OS.get_cmdline_user_args())
	if opts["error"] != "":
		check(false, "argumentos de test_levels: %s" % opts["error"])
		return
	var level_filter: int = opts["level"]
	var mode_filter: String = opts["mode"]
	fake_bridge().auto_start = false
	BridgeClient._go_idle()
	await frames()
	var ids := levels()
	print("    niveles: %s" % str(ids))
	if level_filter < 0:
		check(ids.size() >= 5 and not ids.has(99), "la lista de niveles sale de los LevelData construidos (sin el 99)")
	elif not ids.has(level_filter):
		check(false, "--level=%d no es un nivel construido de la prueba (niveles: %s)" % [level_filter, str(ids)])
		return
	var run_ids: Array[int] = ids
	if level_filter >= 0:
		run_ids = [level_filter]
	if mode_filter in ["", MODE_GRANDE]:
		for id in run_ids:
			await play_level_case(id, false)
	# Modo peque: el auto avanza solo; el conductor solo frena.
	if mode_filter in ["", MODE_PEQUE]:
		for id in run_ids:
			await play_level_case(id, true)
	fake_bridge().mode = GameState.MODE_GRANDE
	if mode_filter == MODE_FAST_RUN or (mode_filter == "" and level_filter < 0):
		await play_fast_run_case()
