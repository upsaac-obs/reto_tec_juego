class_name TestCase
extends Node
## Base de las pruebas automáticas. Cada archivo tests/test_*.gd extiende esta
## clase y escribe sus casos en run(). Las corre tests/run_tests.tscn.

var passed: int = 0
var failed: int = 0
var failures: PackedStringArray = []


## Se sobrescribe en cada prueba.
func run() -> void:
	pass


func check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("  OK    " + description)
	else:
		failed += 1
		failures.append(description)
		print("  FALLA " + description)


## Espera en segundos de juego; sigue contando aunque el árbol esté en pausa.
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func frames(count := 3) -> void:
	for i in count:
		await get_tree().process_frame


func wait_unpaused() -> void:
	while get_tree().paused:
		await get_tree().process_frame


func fake_bridge() -> FakeBridge:
	return BridgeClient._bridge as FakeBridge


## Abre un nivel suelto (sin el puente), como F6 en el editor.
func open_scene(path: String) -> Node:
	var level: Node = load(path).instantiate()
	get_tree().root.add_child(level)
	await get_tree().process_frame
	return level


func close_scene(level: Node) -> void:
	Feedback.clear()
	get_tree().paused = false
	level.queue_free()
	await frames(2)


func release_inputs() -> void:
	for action in [&"car_accelerate", &"car_brake", &"car_left", &"car_right", &"car_seatbelt"]:
		Input.action_release(action)


func tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)
