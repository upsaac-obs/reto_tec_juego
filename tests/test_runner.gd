# Creación y desarrollo: Dylan Isaac Mancilla López
extends Node
## Corre las pruebas tests/test_*.gd en orden alfabético y cierra Godot con
## código 0 si todas pasan. Uso: tests/run_tests.sh [--only=a,b] [--fast]
## (o tests/run_tests.tscn con F6, que corre todo).
##
## Argumentos (los que van después de "--"):
##   --only=a,b  solo los archivos cuyo nombre contiene alguno de esos textos.
##   --fast      salta los archivos que declaran `const SLOW := true`.
##   --level=N, --mode=grande|peque|fast-run   los lee test_levels.gd (corre solo
##               ese nivel / modo; úsalos con --only=levels). El runner solo los
##               deja pasar sin avisar de "desconocido"; los demás archivos los ignoran.
## Un archivo que no compila cuenta como falla siempre, con o sin filtros (con
## --fast no se puede saber si era SLOW, así que tampoco se salta).
## Si el filtro no deja ninguna prueba (errata, `--only=` vacío o todo SLOW con
## --fast), la corrida falla (código 1): no debe parecer "todo bien".

## Segundos de reloj de pared a partir de los cuales una prueba sin SLOW avisa.
const SLOW_WARNING_SECONDS := 10.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run_all()


func _run_all() -> void:
	(BridgeClient._bridge as FakeBridge).auto_start = false
	var only: PackedStringArray = []
	var fast := false
	var only_given := false
	var test_args: PackedStringArray = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only_given = true
			for part: String in arg.trim_prefix("--only=").split(",", false):
				only.append(part.strip_edges())
		elif arg == "--fast":
			fast = true
		elif arg.begins_with("--level=") or arg.begins_with("--mode="):
			# Los lee test_levels.gd directo de OS.get_cmdline_user_args(); el
			# runner solo evita avisarlos como desconocidos.
			test_args.append(arg)
		else:
			print("AVISO: argumento desconocido '%s' (se ignora)" % arg)
	if only.is_empty() and not fast and not only_given and test_args.is_empty():
		print("Filtro: ninguno (corre todo)")
	else:
		var filtro: PackedStringArray = []
		if only_given:
			filtro.append("--only=" + ",".join(only))
		if fast:
			filtro.append("--fast (sin los SLOW)")
		if not test_args.is_empty():
			filtro.append(" ".join(test_args) + " (para test_levels)")
		print("Filtro: " + " ".join(filtro))

	var files := Array(DirAccess.get_files_at("res://tests"))
	files.sort()
	var total_passed := 0
	var total_failed := 0
	var ran := 0
	var matched := 0
	var failures: PackedStringArray = []
	var skipped: PackedStringArray = []
	var warnings: PackedStringArray = []
	for file: String in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file in ["test_case.gd", "test_runner.gd"]:
			continue
		if only_given:
			var matches := false
			for part: String in only:
				if part in file:
					matches = true
					break
			if not matches:
				continue
		matched += 1
		var script := load("res://tests/" + file) as GDScript
		var compiles := script != null and script.can_instantiate()
		var slow := compiles and bool(script.get_script_constant_map().get("SLOW", false))
		if fast and slow:
			skipped.append(file)
			continue
		print("
== %s" % file)
		ran += 1
		if not compiles:
			# Un archivo de prueba que no compila cuenta como falla, no se salta.
			total_failed += 1
			failures.append("%s: no compila" % file)
			print("  FALLA el archivo no compila")
			continue
		var started := Time.get_ticks_msec()
		var test := Node.new()
		test.set_script(script)
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
		var seconds := (Time.get_ticks_msec() - started) / 1000.0
		print("== %s (%.1f s)%s" % [file, seconds, " [SLOW]" if slow else ""])
		if not slow and seconds > SLOW_WARNING_SECONDS:
			warnings.append("AVISO: %s tardó %.0f s y no está marcada SLOW" % [file, seconds])
	if not skipped.is_empty():
		print("
Saltadas por --fast (SLOW): %s" % ", ".join(skipped))
	for w in warnings:
		print(w)
	if ran == 0:
		total_failed += 1
		if matched == 0:
			failures.append("ninguna prueba corrió: el filtro no coincide con ningún archivo")
		else:
			failures.append("ninguna prueba corrió: --fast saltó todas las que coinciden con el filtro")
	print("
== RESULTADO: %d pasan, %d fallan" % [total_passed, total_failed])
	for f in failures:
		print("   FALLA " + f)
	get_tree().quit(1 if total_failed > 0 else 0)
