# Creación y desarrollo: Dylan Isaac Mancilla López
extends TestCase
## Garaje (Vehicles): el vehículo que manda el nativo cambia el sprite del auto; en la
## moto el botón y los mensajes del cinturón son los del casco y se arranca igual.


func run() -> void:
	var previous := GameState.vehicle
	for id in Vehicles.IDS:
		check(id == Vehicles.DEFAULT or ResourceLoader.exists(Vehicles.TEXTURE_PATH % id), "vehículo %s: tiene sprite" % id)

	var keys: Array[String] = []
	Feedback.voice_played.connect(func(key: String, _length: float) -> void: keys.append(key))

	GameState.vehicle = "deportivo"
	var level := await open_scene("res://levels/test_street.tscn")
	var car := (level.get_node("RuleManager") as RuleManager).car
	check(car.texture.resource_path == Vehicles.TEXTURE_PATH % "deportivo", "deportivo: el auto usa su sprite")
	check(level.get_node("Hud/%Seatbelt").texture_normal.resource_path.ends_with("seatbelt.png"), "deportivo: botón del cinturón")
	await close_scene(level)

	GameState.vehicle = Vehicles.MOTO
	level = await open_scene("res://levels/test_street.tscn")
	car = (level.get_node("RuleManager") as RuleManager).car
	check(car.texture.resource_path == Vehicles.TEXTURE_PATH % Vehicles.MOTO, "moto: el auto usa el sprite de la moto")
	check(car.brake_lights.size() == 1 and car.left_signal_lights.size() == 2, "moto: una calavera y direccionales adelante y atrás")
	var button := level.get_node("Hud/%Seatbelt") as TouchScreenButton
	check(button.texture_normal.resource_path.ends_with("helmet.png"), "moto: el botón del cinturón es el del casco")
	car.restart_at(300.0)
	keys.clear()
	await tap(&"car_accelerate")
	await wait(0.2)
	check(car.speed == 0.0 and keys.has("PONTE_CASCO"), "moto: sin casco no arranca y el copiloto pide el casco")
	await tap(&"car_seatbelt")
	await wait(0.2)
	check(car.seatbelt_on and keys.has("CASCO_LISTO"), "moto: tocar el casco deja arrancar")
	await close_scene(level)

	GameState.vehicle = previous
