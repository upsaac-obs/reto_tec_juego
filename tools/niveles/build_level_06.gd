extends SceneTree
## Arma levels/level_06.tscn. Luego: python3 tools/make_inherited.py levels/level_06.tscn

const R := "res://scenes/rules/%s.tscn"


func _initialize() -> void:
	await process_frame
	var b := LevelBuilder.new("Level06", 125, 1, 6)
	b.add(R % "tutorial_hint", Vector2(400, 0), "HintIntro", {"message_key": "CELULAR_INTRO", "peque_message_key": "", "depth": 64.0, "road_width": 128.0})
	b.add(R % "phone_event", Vector2(1000, 0), "Phone1", {"ring_time": 5.0, "ring_distance": 900.0})
	b.add(R % "checkpoint", Vector2(2000, 0), "CheckpointAfterPhone1")
	b.add(R % "crosswalk", Vector2(2900, 0), "Crosswalk1")
	b.add(R % "checkpoint", Vector2(3300, 0), "CheckpointAfterCrosswalk")
	b.add(R % "phone_event", Vector2(3500, 0), "Phone2", {"ring_time": 6.0, "ring_distance": 700.0})
	b.add(R % "traffic_light", Vector2(4900, 0), "TrafficLight1", {"check_yellow": true, "green_time": 6.0, "yellow_time": 3.0, "red_time": 5.0, "start_light": 0, "reaction_time": 1.0})
	b.add(R % "checkpoint", Vector2(5300, 0), "CheckpointAfterLight")
	var phone3 := b.add(R % "phone_event", Vector2(5900, 0), "Phone3", {"vibrate_angle": 12.0})
	b.add(R % "tutorial_hint", Vector2(5930, 0), "HintPark", {"message_key": "CELULAR_ESTACIONAR", "depth": 64.0})
	var spot := b.add(R % "parking_spot", Vector2(6400, 0), "ParkingSpot", {"bay_offset": 32.0, "approach_length": 320.0, "show_finish_line": false, "parked_message_key": ""})
	phone3.set("spot", spot)
	b.add(R % "checkpoint", Vector2(6800, 0), "CheckpointAfterPark")
	b.add(R % "speed_zone", Vector2(6900, 0), "SpeedZone1", {"kind": 0, "limit_kmh": 30, "zone_length": 768.0, "grace_time": 2.0})

	var decor := Node2D.new()
	decor.name = "Decor"
	b.root.add_child(decor)
	b.root.move_child(decor, 1)
	decor.owner = b.root
	_sprite(b.root, decor, "PrimosHouse", "res://assets/sprites/city/casas.png", Vector2(7900, 300), Rect2(128, 0, 128, 128), true)
	_sprite(b.root, decor, "Buildings", "res://assets/sprites/city/edificios.png", Vector2(6400, -330), Rect2(142, 0, 142, 160), false)
	var traffic := Path2D.new()
	traffic.name = "TrafficLeft"
	traffic.set_script(load("res://levels/level_06_traffic.gd"))
	b.root.add_child(traffic)
	traffic.owner = b.root
	print(b.save("res://levels/level_06.tscn"))
	quit()


func _sprite(root: Node, parent: Node, node_name: String, path: String, pos: Vector2, region: Rect2, flip: bool) -> void:
	var s := Sprite2D.new()
	s.name = node_name
	s.texture = load(path)
	s.position = pos
	s.region_enabled = true
	s.region_rect = region
	s.flip_v = flip
	parent.add_child(s)
	s.owner = root
