# Creación y desarrollo: Angel Mael Vera Carpio
extends TestCase
## Gente de la zona de paciencia (nivel 4): cada persona a su paso (walker_speeds)
## y cruces en fila (chain_spacing). La lógica de faltas y puntos está en test_patience.gd.

const ZONE_SCENE := preload("res://scenes/rules/patience_zone.tscn")
const ELDER := preload("res://assets/sprites/pedestrians/elder_frames.tres")
const SHOPPER := preload("res://assets/sprites/pedestrians/shopper_frames.tres")
const DAD := preload("res://assets/sprites/pedestrians/dad_stroller_frames.tres")
const WHEEL := preload("res://assets/sprites/pedestrians/wheelchair_frames.tres")
## y de la orilla de afuera de la banqueta de arriba en el nivel 4 (filas -3 y -2 de
## LevelBuilder): ahí empiezan las fachadas. La fila tiene que esperar más abajo.
const SIDEWALK_OUTER_Y := -192.0


## Zona suelta (sin nivel) con la gente ya creada.
func make_zone(sprites: Array[SpriteFrames], speeds: Array[float], chain: float) -> PatienceZone:
	var zone := ZONE_SCENE.instantiate() as PatienceZone
	zone.walkers = sprites
	zone.walk_speed = 20.0
	zone.walker_speeds = speeds
	zone.chain_spacing = chain
	add_child(zone)
	return zone


func check_speeds() -> void:
	var zone := make_zone([ELDER, SHOPPER] as Array[SpriteFrames], [30.0, 64.0] as Array[float], 0.0)
	check(zone._pedestrians[0].walk_speed == 30.0 and zone._pedestrians[1].walk_speed == 64.0,
		"walker_speeds le da a cada persona su velocidad")
	zone.free()
	zone = make_zone([ELDER, SHOPPER] as Array[SpriteFrames], [] as Array[float], 0.0)
	check(zone._pedestrians[0].walk_speed == 20.0 and zone._pedestrians[1].walk_speed == 20.0,
		"sin walker_speeds todas caminan a walk_speed")
	zone.free()
	zone = make_zone([ELDER, SHOPPER, DAD] as Array[SpriteFrames], [0.0, 50.0] as Array[float], 0.0)
	var got: Array[float] = []
	for p in zone._pedestrians:
		got.append(p.walk_speed)
	var expected: Array[float] = [20.0, 50.0, 20.0]
	check(got == expected, "una entrada en 0 o que falta usa walk_speed (%s)" % str(got))
	zone.free()


func check_layout() -> void:
	var zone := make_zone([ELDER, SHOPPER, DAD] as Array[SpriteFrames], [] as Array[float], 0.0)
	var start := zone._start.position
	var p := zone._pedestrians
	check(p[0].position.y == start.y and p[1].position.y == start.y and p[2].position.y == start.y,
		"con chain_spacing = 0 esperan lado a lado, en la misma y")
	check(is_equal_approx(p[1].position.x - p[0].position.x, zone.walker_spacing)
		and is_equal_approx(p[1].position.x, start.x), "lado a lado, separadas walker_spacing y centradas en la cebra")
	zone.free()
	zone = make_zone([DAD, WHEEL, ELDER] as Array[SpriteFrames], [] as Array[float], 30.0)
	start = zone._start.position
	p = zone._pedestrians
	var row := true
	for i in p.size():
		row = row and p[i].position.x == start.x and is_equal_approx(start.y - p[i].position.y, i * 30.0)
	check(row, "con chain_spacing esperan en fila: mismo x y cada una chain_spacing más atrás")
	check(zone.y_sort_enabled, "la gente se dibuja por su y: la de adelante queda encima")
	zone.free()


## Los tres cruces del nivel 4 a la vez, sin auto: se arrancan a mano.
func check_level() -> void:
	GameState.mode = GameState.MODE_GRANDE
	var level := await open_scene("res://levels/level_04.tscn")
	var c1 := level.get_node("Rules/PatienceCrossing1") as PatienceZone
	var c2 := level.get_node("Rules/PatienceCrossing2") as PatienceZone
	var c3 := level.get_node("Rules/PatienceCrossing3") as PatienceZone
	var elder := c1._pedestrians[0]
	var shopper := c1._pedestrians[1]
	check(c1.chain_spacing == 0.0 and elder.position.y == shopper.position.y, "cruce 1: lado a lado, sin fila")
	check(elder.walk_speed == 30.0 and shopper.walk_speed == 64.0, "cruce 1: la persona mayor a 30 px/s y la compradora a 64 px/s")
	check(c2.walkers[0] == DAD and c2.walkers[1] == WHEEL, "cruce 2: el papá va adelante y la silla de ruedas detrás")
	check(c2._pedestrians[0].walk_speed == c2._pedestrians[1].walk_speed, "cruce 2: los dos al mismo paso")
	check(c3._pedestrians.size() == 4 and c3.chain_spacing > 0.0, "cruce 3: las cuatro niñas en fila")
	for c: PatienceZone in [c2, c3]:
		var last := c._pedestrians[c._pedestrians.size() - 1]
		check(c.chain_spacing > 0.0 and last.position.y > SIDEWALK_OUTER_Y,
			"%s: la última de la fila espera sobre la banqueta, antes de las fachadas (y = %d)" % [c.name, int(last.position.y)])

	for c: PatienceZone in [c1, c2, c3]:
		c._start_crossing()
	var t := 0.0
	var green_at := -1.0
	var elder_on_street_at_green := false
	var shopper_at := -1.0
	var elder_at := -1.0
	var kept_row := {c2: true, c3: true}
	while (c1.is_occupied() or c2.is_occupied() or c3.is_occupied()) and t < 15.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if green_at < 0.0 and c1._light.light == TrafficLight.Light.GREEN:
			green_at = t
			elder_on_street_at_green = c1.is_trap() and elder not in c1._crossed
		if shopper_at < 0.0 and shopper in c1._crossed:
			shopper_at = t
		if elder_at < 0.0 and elder in c1._crossed:
			elder_at = t
		# Mientras nadie llega al otro lado, la fila no se estira ni se encoge.
		for c: PatienceZone in [c2, c3]:
			if not c._crossed.is_empty():
				continue
			var p := c._pedestrians
			for i in range(1, p.size()):
				if absf(p[i - 1].position.y - p[i].position.y - c.chain_spacing) > 0.5 or p[i].position.x != p[0].position.x:
					kept_row[c] = false
	check(not c1.is_occupied() and not c2.is_occupied() and not c3.is_occupied(), "todos terminan de cruzar")
	check(shopper_at > 0.0 and elder_at > shopper_at, "cruce 1: la compradora llega antes que la persona mayor (%.1f s y %.1f s)" % [shopper_at, elder_at])
	check(absf(shopper_at - green_at) < 0.15, "cruce 1: la compradora llega cuando el semáforo se pone en verde (%.2f s, verde a %.2f s)" % [shopper_at, green_at])
	check(elder_on_street_at_green, "cruce 1: con el verde la persona mayor sigue en la calle (trampa de paciencia)")
	for c: PatienceZone in [c2, c3]:
		check(kept_row[c], "%s: la fila mantiene la distancia mientras cruzan" % c.name)
		check(c._crossed == c._pedestrians, "%s: llegan en el orden de la fila (la primera de walkers primero)" % c.name)

	# Al volver a un punto de control la fila se arma otra vez en la banqueta.
	await wait(0.5)
	for c: PatienceZone in [c2, c3]:
		c._on_car_restarted()
	await get_tree().physics_frame
	await get_tree().physics_frame
	for c: PatienceZone in [c2, c3]:
		var back := true
		for i in c._pedestrians.size():
			var p := c._pedestrians[i]
			back = back and p.position.is_equal_approx(c._walker_start(i)) and p.visible and p.modulate.a == 1.0
		check(back and c.is_occupied() and c._light.light == TrafficLight.Light.RED,
			"%s: tras el reinicio la fila vuelve a su lugar con la luz en rojo" % c.name)
	await close_scene(level)


func run() -> void:
	check_speeds()
	check_layout()
	await check_level()
