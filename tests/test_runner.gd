extends Node
## Corre todas las pruebas tests/test_*.gd en orden alfabético y cierra Godot con
## código 0 si todas pasan. Uso: tests/run_tests.sh (o tests/run_tests.tscn con F6).


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run_all()


func _run_all() -> void:
	(BridgeClient._bridge as FakeBridge).auto_start = false
	var files := Array(DirAccess.get_files_at("res://tests"))
	files.sort()
	var total_passed := 0
	var total_failed := 0
	var failures: PackedStringArray = []
	for file: String in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file in ["test_case.gd", "test_runner.gd"]:
			continue
		print("\n== %s" % file)
		var test := Node.new()
		test.set_script(load("res://tests/" + file))
		test.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(test)
		await test.run()
		total_passed += test.passed
		total_failed += test.failed
		for f in test.failures:
			failures.append("%s: %s" % [file, f])
		test.queue_free()
		for action in [&"car_accelerate", &"car_brake", &"car_left", &"car_right", &"car_seatbelt"]:
			Input.action_release(action)
		get_tree().paused = false
		Engine.time_scale = 1.0
	print("\n== RESULTADO: %d pasan, %d fallan" % [total_passed, total_failed])
	for f in failures:
		print("   FALLA " + f)
	get_tree().quit(1 if total_failed > 0 else 0)
