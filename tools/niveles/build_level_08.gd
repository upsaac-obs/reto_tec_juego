extends SceneTree
## Arma levels/level_08.tscn. Después: python3 tools/make_inherited.py levels/level_08.tscn


func _initialize() -> void:
	var W := LevelBuilder.ROAD_WIDTH_AVENUE
	var BIKE := LevelBuilder.BIKE_LANE_OFFSET
	var adult := load("res://assets/sprites/pedestrians/adult_frames.tres") as SpriteFrames
	var elder := load("res://assets/sprites/pedestrians/elder_frames.tres") as SpriteFrames
	var girl := load("res://assets/sprites/pedestrians/girl_frames.tres") as SpriteFrames
	var b := LevelBuilder.new("Level08", 172, 1, 8, 9999, 4, true)
	var hint := "res://scenes/rules/tutorial_hint.tscn"
	var lane := "res://scenes/rules/bike_lane.tscn"
	var cyc := "res://scenes/rules/cyclist_distance.tscn"
	var bus := "res://scenes/rules/bus_stop.tscn"
	var cp := "res://scenes/rules/checkpoint.tscn"
	b.add(hint, Vector2(320, 0), "HintStart", {"message_key": "L08_INICIO", "road_width": W})
	b.add(hint, Vector2(1000, 0), "HintCyclist", {"message_key": "L08_BICI", "road_width": W})
	b.add(lane, Vector2(128, 0), "BikeLane1", {"side_offset": BIKE, "length": 2944.0, "road_width": W})
	b.add(cyc, Vector2(1450, 0), "Cyclist1", {"cyclist_start_x": 448.0, "cyclist_speed": 80.0, "cyclist_end_x": 2800.0, "bike_side_offset": BIKE, "road_width": W})
	b.add(cyc, Vector2(2700, 0), "Cyclist1b", {"grande_only": true, "cyclist_start_x": 448.0, "cyclist_speed": 80.0, "cyclist_end_x": 1900.0, "bike_side_offset": BIKE, "road_width": W})
	b.add(lane, Vector2(3072, 0), "BikeLane2", {"side_offset": BIKE, "length": 3328.0, "road_width": W})
	b.add(cp, Vector2(3700, 0), "Checkpoint1", {"road_width": W})
	b.add(hint, Vector2(3750, 0), "HintBus", {"message_key": "L08_CAMION", "peque_message_key": "L08_CAMION_PEQUE", "road_width": W})
	var off1: Array[SpriteFrames] = [adult]
	var on1: Array[SpriteFrames] = [elder]
	b.add(bus, Vector2(5200, 0), "BusStop1", {"trigger_distance": 1400.0, "bus_end_x": 1100.0, "passengers_off": off1, "passengers_on": on1, "min_dwell": 4.0, "road_width": W})
	b.add(lane, Vector2(6400, 0), "BikeLane3", {"side_offset": BIKE, "length": 4224.0, "road_width": W})
	b.add("res://scenes/rules/traffic_light.tscn", Vector2(7000, 0), "TrafficLight", {"start_light": 2, "red_time": 5.0, "green_time": 5.0, "yellow_time": 3.0, "reaction_time": 1.0, "check_yellow": true, "road_width": W, "light_offset": Vector2(-28, 260)})
	b.add(cp, Vector2(7300, 0), "Checkpoint2", {"road_width": W})
	b.add(hint, Vector2(7900, 0), "HintClimax", {"message_key": "L08_CLIMAX", "peque_message_key": "L08_CLIMAX_PEQUE", "road_width": W})
	b.add(cyc, Vector2(8600, 0), "Cyclist2", {"cyclist_start_x": -560.0, "cyclist_speed": 180.0, "cyclist_slow_x": 1000.0, "cyclist_slow_speed": 70.0, "cyclist_end_x": 2600.0, "bike_side_offset": BIKE, "road_width": W})
	var off2: Array[SpriteFrames] = [elder, girl]
	var on2: Array[SpriteFrames] = [adult, girl]
	b.add(bus, Vector2(9200, 0), "BusStop2", {"trigger_distance": 1400.0, "bus_end_x": 1300.0, "passengers_off": off2, "passengers_on": on2, "min_dwell": 5.0, "road_width": W})
	# Decoración: la biblioteca (edificio naranja) abajo a la derecha.
	var decor := Node2D.new()
	decor.name = "Decor"
	b.root.add_child(decor)
	b.root.move_child(decor, 1)
	decor.owner = b.root
	var library := Sprite2D.new()
	library.name = "Library"
	library.texture = load("res://assets/sprites/city/edificios.png")
	library.region_enabled = true
	library.region_rect = Rect2(284, 0, 142, 160)
	library.position = Vector2(10850, 340)
	decor.add_child(library)
	library.owner = b.root
	# Motos (las crea el script; las de Grande no salen en Peque).
	var traffic := Node2D.new()
	traffic.name = "Traffic"
	traffic.set_script(load("res://levels/level_08_traffic.gd"))
	b.root.add_child(traffic)
	traffic.owner = b.root
	traffic.set("traffic_light", b.root.get_node("Rules/TrafficLight"))
	var err := b.save("res://levels/level_08.tscn")
	print("guardado: ", err)
	quit(err)
