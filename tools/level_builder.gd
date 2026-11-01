class_name LevelBuilder
extends RefCounted
## Ayuda para armar niveles por script con el estilo de la calle de prueba.
## Después de guardar, correr: python3 tools/make_inherited.py levels/level_XX.tscn
## (Godot guarda los niveles armados así como copia completa de level.tscn).
##
## Uso (desde un script con `godot --headless --path . -s mi_script.gd`):
##   var b := LevelBuilder.new("Level05", 120, 1, 5)            # calle de 2 carriles
##   b.add("res://scenes/rules/traffic_light.tscn", Vector2(2000, 0), "TrafficLight")
##   b.save("res://levels/level_05.tscn")
##
## Calle normal (lanes = 2, por defecto): carriles en las filas -1 y 0, ruta en y = 0.
## Es exactamente lo que generaba antes, así que los niveles 0 a 4 no cambian.
##
## Avenida (lanes = 4): 4 carriles en las filas -2 a 1 (2 por sentido, raya del
## centro en y = 0), banquetas en las filas -3 y 2, meta en los 4 carriles. La
## ruta va en y = 0 con default_lane_count = 4 (offsets -96, -32, 32, 96). Las
## piezas sobre la avenida usan road_width = 256 (ROAD_WIDTH_AVENUE).
##   var b := LevelBuilder.new("Level08", 140, 2, 8, 9999, 4, true)
## Con bike_lane = true el carril 0 (fila -2, arriba) queda liso, sin raya, para
## poner encima una pieza BikeLane con side_offset = BIKE_LANE_OFFSET.

## Calle de 2 carriles (niveles 0 a 4).
const ROAD_ROWS := {-3: Vector2i(3, 0), -2: Vector2i(4, 0), -1: Vector2i(0, 1), 0: Vector2i(1, 1), 1: Vector2i(5, 0), 2: Vector2i(3, 0)}
## Avenida de 4 carriles: raya punteada entre carriles y raya doble en el centro.
const AVENUE_ROWS := {-3: Vector2i(4, 0), -2: Vector2i(0, 1), -1: Vector2i(0, 1), 0: Vector2i(1, 1), 1: Vector2i(1, 1), 2: Vector2i(5, 0)}
## Asfalto liso para la ciclovía (carril 0 de la avenida).
const PLAIN_ASPHALT := Vector2i(6, 0)
const ROAD_WIDTH_AVENUE := 256.0
## Centro de la ciclovía respecto a la ruta (carril 0 de 4).
const BIKE_LANE_OFFSET := -96.0
const GRASS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(7, 1)]
const HOUSES: Array[Vector2i] = [Vector2i(0, 2), Vector2i(2, 2)]
const PLANTS: Array[Vector2i] = [Vector2i(5, 1), Vector2i(6, 1)]
const FINISH := Vector2i(4, 1)

var root: Node
var rng := RandomNumberGenerator.new()
## Filas pintadas como calle (fila → tile) y filas de los carriles (para la meta).
var road_rows: Dictionary = ROAD_ROWS
var lane_rows: Array[int] = [-1, 0]


## Nivel nuevo heredado de level.tscn con una calle recta de `tiles` tiles.
## lanes: 2 (calle) o 4 (avenida). bike_lane: solo en avenida, carril 0 liso.
func _init(level_name: String, tiles: int, start_lane: int, seed_value: int, houses_until := 9999,
		lanes := 2, bike_lane := false) -> void:
	assert(lanes == 2 or lanes == 4, "LevelBuilder: lanes tiene que ser 2 o 4")
	rng.seed = seed_value
	if lanes == 4:
		road_rows = AVENUE_ROWS.duplicate()
		lane_rows = [-2, -1, 0, 1]
		if bike_lane:
			road_rows[-2] = PLAIN_ASPHALT
	root = (load("res://scenes/level/level.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN_INHERITED)
	root.name = level_name
	_paint(root.get_node("Ground") as TileMapLayer, tiles, houses_until)
	var curve := Curve2D.new()
	curve.add_point(Vector2(64, 0))
	curve.add_point(Vector2(tiles * 64 - 32, 0))
	var route := root.get_node("Route") as DrivingRoute
	route.curve = curve
	if lanes != 2:
		route.default_lane_count = lanes
	root.get_node("Route/PlayerCar").set("start_lane", start_lane)


func add(scene_path: String, pos: Vector2, node_name: String, props := {}) -> Node:
	var node := (load(scene_path) as PackedScene).instantiate()
	node.name = node_name
	node.position = pos
	for key: String in props:
		node.set(key, props[key])
	root.get_node("Rules").add_child(node)
	node.owner = root
	return node


func save(path: String) -> Error:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	root.free()
	return err


func _paint(ground: TileMapLayer, tiles: int, houses_until: int) -> void:
	for x in range(-14, tiles + 14):
		for y in range(-12, 12):
			ground.set_cell(Vector2i(x, y), 0, road_rows[y] if road_rows.has(y) else GRASS[rng.randi() % GRASS.size()])
	# Casas dos filas afuera de la calle y plantas pegadas a la banqueta.
	var top: int = road_rows.keys().min()
	var bottom: int = road_rows.keys().max()
	var x := -12
	while x < tiles + 12:
		for row: int in [top - 3, bottom + 2]:
			if x < houses_until and rng.randf() < 0.7:
				var house := HOUSES[rng.randi() % HOUSES.size()]
				for dx in 2:
					for dy in 2:
						ground.set_cell(Vector2i(x + dx, row + dy), 0, house + Vector2i(dx, dy))
		for row: int in [top - 1, bottom + 1]:
			if rng.randf() < 0.5:
				ground.set_cell(Vector2i(x + rng.randi() % 3, row), 0, PLANTS[rng.randi() % 2])
		x += 3
	for y in lane_rows:
		ground.set_cell(Vector2i(tiles - 1, y), 0, FINISH)
