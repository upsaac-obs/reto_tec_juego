# Creación y desarrollo: Dylan Isaac Mancilla López
extends TestCase
## Créditos al terminar el último nivel (scenes/ui/credits.gd): solo el nivel 8 los tiene,
## salen al tocar Continuar en la tarjeta, se saltan con un toque y después el nivel
## se cierra como siempre (level_exited completed true).


func run() -> void:
	for id in LevelData.IDS:
		var data := LevelData.load_by_id(id)
		if data != null:
			check(data.show_credits == (id == 8), "nivel %d: créditos %s" % [id, "sí" if id == 8 else "no"])

	# La escena sola: textos de textos.csv y finished al saltarla.
	var credits := Credits.new()
	get_tree().root.add_child(credits)
	await frames(3)
	var texts: Array[String] = []
	for node in credits.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	check(tr("CREDITOS_INTEGRANTE_1") in texts and tr("CREDITOS_DIRECTOR") in texts and tr("CREDITOS_FUNDACION") in texts,
		"los créditos muestran al equipo, la dirección y la fundación")
	check(not texts.has("CREDITOS_DIRECTOR"), "los textos están traducidos (no se ve la clave)")
	var done := [false]
	credits.finished.connect(func() -> void: done[0] = true)
	credits.skip()
	await frames(2)
	check(done[0] and not is_instance_valid(credits), "saltar los créditos emite finished y los quita")

	# Nivel 8 por el puente: Continuar abre los créditos y el nivel se cierra al terminar.
	var fake := fake_bridge()
	fake.sent.clear()
	fake.send_start(8)
	await frames()
	(get_tree().get_first_node_in_group(&"rule_manager") as RuleManager).finish_level()
	await wait(1.6)
	get_tree().current_scene.get_node("HabitCard/%Continue").pressed.emit()
	await frames(3)
	var shown := get_tree().root.find_children("*", "Credits", false, false)
	var exited := fake.sent.filter(func(m: Array) -> bool: return m[0] == "level_exited").size()
	check(shown.size() == 1 and exited == 0, "Continuar en el nivel 8 abre los créditos sin cerrar el nivel")
	if shown.size() == 1:
		(shown[0] as Credits).skip()
	await frames(3)
	exited = fake.sent.filter(func(m: Array) -> bool: return m[0] == "level_exited").size()
	check(exited == 1 and get_tree().current_scene.scene_file_path == BridgeClient.IDLE_SCENE,
		"al terminar los créditos el nivel se cierra (level_exited) y vuelve a idle")
	get_tree().paused = false
