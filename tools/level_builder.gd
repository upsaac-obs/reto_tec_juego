class_name LevelBuilder
extends RefCounted
## Ayuda para armar niveles por script con el estilo de la calle de prueba.
## Después de guardar, correr: python3 tools/make_inherited.py levels/level_XX.tscn
## (Godot guarda los niveles armados así como copia completa de level.tscn).

const ROAD_ROWS := {-3: Vector2i(3, 0), -2: Vector2i(4, 0), -1: Vector2i(0, 1), 0: Vector2i(1, 1), 1: Vector2i(5, 0), 2: Vector2i(3, 0)}
const GRASS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(7, 1)]
const HOUSES: Array[Vector2i] = [Vector2i(0, 2), Vector2i(2, 2)]
const PLANTS: Array[Vector2i] = [Vector2i(5, 1), Vector2i(6, 1)]
const FINISH := Vector2i(4, 1)

var root: Node
var rng := RandomNumberGenerator.new()


## Nivel nuevo heredado de level.tscn con una calle recta de `tiles` tiles.
func _init(level_name: String, tiles: int, start_lane: int, seed_value: int, houses_until := 9999) -> void:
	rng.seed = seed_value
	root = (load("res://scenes/level/level.tscn") as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN_INHERITED)
	root.name = level_name
	_paint(root.get_node("Ground") as TileMapLayer, tiles, houses_until)
	var curve := Curve2D.new()
	curve.add_point(Vector2(64, 0))
	curve.add_point(Vector2(tiles * 64 - 32, 0))
	(root.get_node("Route") as Path2D).curve = curve
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
			ground.set_cell(Vector2i(x, y), 0, ROAD_ROWS[y] if ROAD_ROWS.has(y) else GRASS[rng.randi() % GRASS.size()])
	var x := -12
	while x < tiles + 12:
		for row: int in [-6, 4]:
			if x < houses_until and rng.randf() < 0.7:
				var house := HOUSES[rng.randi() % HOUSES.size()]
				for dx in 2:
					for dy in 2:
						ground.set_cell(Vector2i(x + dx, row + dy), 0, house + Vector2i(dx, dy))
		for row: int in [-4, 3]:
			if rng.randf() < 0.5:
				ground.set_cell(Vector2i(x + rng.randi() % 3, row), 0, PLANTS[rng.randi() % 2])
		x += 3
	for y: int in [-1, 0]:
		ground.set_cell(Vector2i(tiles - 1, y), 0, FINISH)
