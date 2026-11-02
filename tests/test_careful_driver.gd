extends TestCase
## El conductor cuidadoso de test_levels.gd obedece a piezas nuevas sin que haya
## que editarlo: careful_stop_x() + must_wait(), careful_lane() + careful_range()
## y el grupo "needs_headlights". Se le agregan piezas falsas al nivel 0.

const STOP_X := 1600.0
const LANE_RANGE := Vector2(2400.0, 2900.0)

## Pieza que pide esperar hasta que el auto lleve 2 s detenido en STOP_X.
const WAIT_PIECE := """extends Node2D
var stop_x := 0.0
var waited := 0.0
var car: PlayerCar
func careful_stop_x() -> float:
	return stop_x
func must_wait() -> bool:
	return waited < 2.0
func _physics_process(delta: float) -> void:
	if car != null and absf(car.global_position.x - stop_x) < 40.0 and car.speed < 5.0:
		waited += delta
"""

## Pieza que pide un carril en un tramo.
const LANE_PIECE := """extends Node2D
var lane := 1
var span := Vector2.ZERO
func careful_lane() -> int:
	return lane
func careful_range() -> Vector2:
	return span
"""

var wait_piece: Node2D
var lane_piece: Node2D
var lights_node: Node
var lane_in_range: Array = []
var waited := 0.0
var wanted_lane := -1


func make(source: String) -> Node2D:
	var script := GDScript.new()
	script.source_code = source
	script.reload()
	var node := Node2D.new()
	node.set_script(script)
	return node


func _inject() -> void:
	var level := get_tree().current_scene
	if level == null or not level.has_node("Rules"):
		return
	var car := (level.get_node("RuleManager") as RuleManager).car
	wait_piece = make(WAIT_PIECE)
	wait_piece.set(&"stop_x", STOP_X)
	wait_piece.set(&"car", car)
	wait_piece.position = Vector2(STOP_X + 100.0, 0.0)
	lane_piece = make(LANE_PIECE)
	wanted_lane = 1 - car.lane_index
	lane_piece.set(&"lane", wanted_lane)
	lane_piece.set(&"span", LANE_RANGE)
	lane_piece.position = Vector2(LANE_RANGE.x, 0.0)
	lights_node = Node.new()
	lights_node.add_to_group(&"needs_headlights")
	level.get_node("Rules").add_child(wait_piece)
	level.get_node("Rules").add_child(lane_piece)
	level.add_child(lights_node)


func _physics_process(_delta: float) -> void:
	var level := get_tree().current_scene
	if lane_piece == null or not is_instance_valid(lane_piece) or level == null or not level.has_node("RuleManager"):
		return
	var car := (level.get_node("RuleManager") as RuleManager).car
	if is_instance_valid(wait_piece):
		waited = wait_piece.get(&"waited")
	var x := car.global_position.x
	if x > LANE_RANGE.x and x < LANE_RANGE.y:
		lane_in_range.append(car.lane_index)


func run() -> void:
	var driver: Node = load("res://tests/test_levels.gd").new()
	driver.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(driver)
	fake_bridge().auto_start = false
	fake_bridge().mode = GameState.MODE_GRANDE
	Engine.time_scale = 3.0
	BridgeClient._go_idle()
	await frames()
	get_tree().scene_changed.connect(_inject, CONNECT_ONE_SHOT)
	fake_bridge().sent.clear()
	var lights := [false]
	var result: Variant = null
	var watch := func() -> void:
		var level := get_tree().current_scene
		if level != null and level.has_node("RuleManager"):
			var car := (level.get_node("RuleManager") as RuleManager).car
			if car.headlights_on:
				lights[0] = true
	var timer := Timer.new()
	timer.wait_time = 0.2
	timer.timeout.connect(watch)
	add_child(timer)
	timer.start()
	result = await driver.play(0)
	timer.stop()
	Engine.time_scale = 1.0
	print("    nivel 0 con piezas falsas: %s" % str(result))
	check(result != null and result["infractions"].is_empty(), "el recorrido con piezas falsas termina sin faltas")
	check(waited >= 2.0, "careful_stop_x + must_wait: se detiene donde pide la pieza y espera")
	check(not lane_in_range.is_empty() and lane_in_range.all(func(l: int) -> bool: return l == wanted_lane), "careful_lane + careful_range: llega al tramo ya en el carril pedido")
	check(lights[0], "grupo needs_headlights: el conductor prende las luces")
	driver.queue_free()
