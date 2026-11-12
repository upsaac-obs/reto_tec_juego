extends Node
## Arma levels/level_07.tscn. Después: python3 tools/make_inherited.py levels/level_07.tscn


func _ready() -> void:
	var b := LevelBuilder.new("Level07", 140, 0, 707)
	var root := b.root
	var decor := Node2D.new()
	decor.name = "Decor"
	root.add_child(decor)
	root.move_child(decor, 1)
	decor.owner = root
	# Túnel visto desde arriba: portales sobre la calle en los extremos de DarkTunnel.
	var tunnel := Node2D.new()
	tunnel.name = "Tunnel"
	tunnel.set_script(load("res://scenes/level/tunnel_decor.gd"))
	tunnel.set("start_x", 3800.0)
	tunnel.set("end_x", 5200.0)
	decor.add_child(tunnel)
	tunnel.owner = root
	var casa := _sprite(decor, root, "Casa", "res://assets/sprites/city/casas.png", Vector2(8760, -200))
	casa.region_enabled = true
	casa.region_rect = Rect2(0, 0, 128, 128)
	var dusk := CanvasModulate.new()
	dusk.name = "Dusk"
	dusk.set_script(load("res://levels/level_07_dusk.gd"))
	root.add_child(dusk)
	dusk.owner = root

	const HINT := "res://scenes/rules/tutorial_hint.tscn"
	const BIKE := "res://scenes/rules/bike_lane.tscn"
	const CP := "res://scenes/rules/checkpoint.tscn"
	const SPEED := "res://scenes/rules/speed_zone.tscn"
	const DARK := "res://scenes/rules/dark_zone.tscn"
	b.add(HINT, Vector2(500, 0), "HintLuces", {"message_key": "LUCES_INTRO"})
	b.add(BIKE, Vector2(900, 0), "BikeLane1", {"side_offset": 32.0, "length": 1200.0})
	b.add(HINT, Vector2(1650, 0), "HintReflejante", {"message_key": "LUCES_REFLEJANTE"})
	b.add(CP, Vector2(2300, 0), "CheckpointAfterDusk")
	b.add(HINT, Vector2(3250, 0), "HintTunel", {"message_key": "LUCES_TUNEL"})
	b.add(SPEED, Vector2(3500, 0), "SpeedTunnel", {"limit_kmh": 30, "zone_length": 1900.0})
	b.add(BIKE, Vector2(3700, 0), "BikeLane2", {"side_offset": 32.0, "length": 1600.0})
	b.add(CP, Vector2(5600, 0), "CheckpointAfterTunnel")
	b.add(HINT, Vector2(6300, 0), "HintLluvia", {"message_key": "LUCES_LLUVIA"})
	b.add(BIKE, Vector2(6500, 0), "BikeLane3", {"side_offset": 32.0, "length": 1600.0})
	b.add(DARK, Vector2(1000, 0), "DarkDusk", {"kind": DarkZone.Kind.DUSK, "length": 1000.0, "darkness": 0.5,
		"cyclist_starts": PackedFloat32Array([350.0, 750.0]), "cyclist_speed": 80.0})
	b.add(DARK, Vector2(3800, 0), "DarkTunnel", {"kind": DarkZone.Kind.TUNNEL, "length": 1400.0, "darkness": 0.65,
		"cyclist_starts": PackedFloat32Array([250.0, 700.0]), "cyclist_speed": 50.0})
	b.add(DARK, Vector2(6600, 0), "DarkRain", {"kind": DarkZone.Kind.RAIN, "length": 1400.0, "darkness": 0.55,
		"rain": true, "cyclist_starts": PackedFloat32Array([400.0, 900.0]), "cyclist_speed": 80.0})
	(root.get_node("Hud") as Node).set("show_lights_button", true)
	var err := b.save("res://levels/level_07.tscn")
	print("guardado: ", err)
	get_tree().quit(err)


func _sprite(parent: Node, root: Node, node_name: String, path: String, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = node_name
	s.texture = load(path)
	s.position = pos
	parent.add_child(s)
	s.owner = root
	return s
