extends TestCase
## Velocímetro: solo aparece en niveles con zona de velocidad y refleja la velocidad del auto.


const Palette := preload("res://autoload/game_state.gd")


func run() -> void:
	var previous_mode := GameState.mode
	GameState.mode = GameState.MODE_PEQUE
	var level := await open_scene("res://levels/test_street.tscn")
	var meter: Node = level.get_node("SpeedometerLayer/Speedometer")
	var car := (level.get_node("RuleManager") as RuleManager).car
	check(meter.visible, "con zona de velocidad el velocímetro se ve")
	check(meter.car == car, "el velocímetro apunta al auto del nivel")

	car.restart_at(1300.0)
	car.seatbelt_on = true
	await wait(2.5)
	check(car.speed > 0.0, "el auto avanza")
	check(absf(meter.speed_kmh() - car.speed / Palette.PX_PER_KMH) < 0.01, "speed_kmh() sigue la velocidad del auto")
	check(absf(meter.shown_kmh - meter.speed_kmh()) < 1.0, "la aguja se acerca a la velocidad (%.1f)" % meter.shown_kmh)

	var zone := level.get_node("Rules/SchoolZone") as SpeedZone
	car.restart_at(zone.position.x - 64.0 + 100.0)
	await wait(0.2)
	car.speed = car.current_limit() + 50.0
	check(meter.is_over_limit(), "sobre el límite de la zona is_over_limit() es true")
	check(meter.limit_kmh() <= zone.limit_kmh + 0.01, "el límite mostrado es el de la zona")
	await wait_unpaused()
	await close_scene(level)

	var plain := await open_scene("res://levels/level_00.tscn")
	var plain_meter: Node = plain.get_node("SpeedometerLayer/Speedometer")
	check(not plain_meter.visible, "sin zona de velocidad el velocímetro no se ve")
	await close_scene(plain)
	GameState.mode = previous_mode
