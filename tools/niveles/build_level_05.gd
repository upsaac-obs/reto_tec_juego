extends SceneTree
## Arma levels/level_05.tscn (Sin prisa). Después: python3 tools/make_inherited.py levels/level_05.tscn

const R := "res://scenes/rules/"


func _init() -> void:
	var b := LevelBuilder.new("Level05", 103, 1, 5, 95)
	var root := b.root
	b.add(R + "tutorial_hint.tscn", Vector2(256, 0), "HintIntro", {"message_key": "PRISA_INTRO"})
	b.add(R + "speed_zone.tscn", Vector2(640, 0), "SpeedZone40", {"kind": 0, "limit_kmh": 40, "zone_length": 704.0})
	b.add(R + "tutorial_hint.tscn", Vector2(1728, 0), "HintYellow", {"message_key": "PRISA_AMARILLO_AVISO", "peque_message_key": "PRISA_AMARILLO_AVISO_PEQUE"})
	b.add(R + "yellow_crossing.tscn", Vector2(2432, 0), "YellowCrossing1", {"trigger_distance": 420.0, "yellow_time": 3.0, "red_time": 4.0})
	b.add(R + "checkpoint.tscn", Vector2(2752, 0), "CheckpointAfterLight1")
	b.add(R + "tutorial_hint.tscn", Vector2(2944, 0), "HintBoard", {"message_key": "PRISA_TABLERO_AVISO"})
	b.add(R + "yellow_crossing.tscn", Vector2(3584, 0), "YellowCrossing2", {"trigger_distance": 420.0, "yellow_time": 3.0, "red_time": 4.0})
	b.add(R + "checkpoint.tscn", Vector2(3904, 0), "CheckpointAfterLight2")
	b.add(R + "speed_zone.tscn", Vector2(3968, 0), "SpeedZone30", {"kind": 0, "limit_kmh": 30, "zone_length": 1376.0})
	b.add(R + "tutorial_hint.tscn", Vector2(4000, 0), "HintBallStreet", {"message_key": "PELOTA_CALLE_AVISO"})
	b.add(R + "checkpoint.tscn", Vector2(4160, 0), "CheckpointBallStreet")
	var xs: Array[float] = [-607.0, -517.0, -427.0, -337.0, -247.0, -157.0, -67.0, 67.0, 157.0, 247.0, 337.0, 427.0, 517.0]
	b.add(R + "ball_event.tscn", Vector2(4800, 0), "BallEvent", {"trigger_distance": 280.0, "parked_car_x": xs})
	b.add(R + "checkpoint.tscn", Vector2(5408, 0), "CheckpointAfterBall")
	b.add(R + "crosswalk.tscn", Vector2(5952, 0), "CrosswalkTerminal", {"approach_length": 448.0, "start_delay": 0.3})
	b.add(R + "checkpoint.tscn", Vector2(6208, 0), "CheckpointAfterCrosswalk")
	b.add(R + "departure_board.tscn", Vector2(6304, -160), "DepartureBoard")
	# Tramo de un carril (autos estacionados a la derecha).
	var route := root.get_node("Route")
	for s: Array in [["OneLane", 4096, 1], ["TwoLanes", 5440, 2]]:
		var section := StreetSection.new()
		section.name = s[0]
		section.position = Vector2(s[1], 0)
		section.lane_count = s[2]
		route.add_child(section)
		section.owner = root
	# Decoración: la terminal y dos árboles.
	var decor := Node2D.new()
	decor.name = "Decor"
	root.add_child(decor)
	root.move_child(decor, 1)
	decor.owner = root
	var terminal := Sprite2D.new()
	terminal.name = "Terminal"
	terminal.texture = load("res://assets/sprites/city/terminal.png")
	terminal.position = Vector2(6400, -300)
	decor.add_child(terminal)
	terminal.owner = root
	for i in 2:
		var tree := Sprite2D.new()
		tree.name = "Tree%d" % (i + 1)
		tree.texture = load("res://assets/sprites/city/arboles.png")
		tree.region_enabled = true
		tree.region_rect = Rect2(64 * i, 0, 64, 64)
		tree.position = Vector2(6176 + 448 * i, -224)
		decor.add_child(tree)
		tree.owner = root
	print("save: ", b.save("res://levels/level_05.tscn"))
	quit()
