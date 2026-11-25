# Creación y desarrollo: Dylan Isaac Mancilla López
extends SceneTree
## Arma levels/level_06.tscn. Luego: python3 tools/make_inherited.py levels/level_06.tscn
## Las x respetan la regla de espacio de docs/niveles/nivel_06.md (§2):
## trigger + ring_distance + cover_duration() × 240 ≤ inicio de la zona siguiente.
## La tapa dura lo que el aviso CELULAR_TAPA (4.32 s), así que cada celular que tapa
## empuja lo que sigue: +560 px después de Phone1 y +1136 px después de Phone2.

const R := "res://scenes/rules/%s.tscn"


func _initialize() -> void:
	await process_frame
	var b := LevelBuilder.new("Level06", 142, 1, 6)
	b.add(R % "tutorial_hint", Vector2(400, 0), "HintIntro", {"message_key": "CELULAR_INTRO", "peque_message_key": "", "depth": 64.0, "road_width": 128.0})
	b.add(R % "phone_event", Vector2(1000, 0), "Phone1", {"ring_time": 5.0, "ring_distance": 900.0})
	b.add(R % "checkpoint", Vector2(2000, 0), "CheckpointAfterPhone1")
	b.add(R % "crosswalk", Vector2(3460, 0), "Crosswalk1")
	b.add(R % "checkpoint", Vector2(3860, 0), "CheckpointAfterCrosswalk")
	b.add(R % "phone_event", Vector2(4060, 0), "Phone2", {"ring_time": 6.0, "ring_distance": 700.0})
	b.add(R % "traffic_light", Vector2(6036, 0), "TrafficLight1", {"check_yellow": true, "green_time": 6.0, "yellow_time": 3.0, "red_time": 5.0, "start_light": 0, "reaction_time": 1.0})
	b.add(R % "checkpoint", Vector2(6436, 0), "CheckpointAfterLight")
	var phone3 := b.add(R % "phone_event", Vector2(7036, 0), "Phone3", {"vibrate_angle": 12.0})
	b.add(R % "tutorial_hint", Vector2(7066, 0), "HintPark", {"message_key": "CELULAR_ESTACIONAR", "depth": 64.0})
	var spot := b.add(R % "parking_spot", Vector2(7536, 0), "ParkingSpot", {"bay_offset": 32.0, "approach_length": 320.0, "show_finish_line": false, "parked_message_key": ""})
	phone3.set("spot", spot)
	b.add(R % "checkpoint", Vector2(7936, 0), "CheckpointAfterPark")
	b.add(R % "speed_zone", Vector2(8036, 0), "SpeedZone1", {"kind": 0, "limit_kmh": 30, "zone_length": 768.0, "grace_time": 2.0})

	var decor := Node2D.new()
	decor.name = "Decor"
	b.root.add_child(decor)
	b.root.move_child(decor, 1)
	decor.owner = b.root
	# Casa de los primos junto a la meta (la última columna de tiles empieza en 9024).
	_sprite(b.root, decor, "PrimosHouse", "res://assets/sprites/city/casa_primos.png", Vector2(8988, 292))
	_sprite(b.root, decor, "Buildings", "res://assets/sprites/city/edificios.png", Vector2(7536, -330), Rect2(142, 0, 142, 160))
	var traffic := Path2D.new()
	traffic.name = "TrafficLeft"
	traffic.set_script(load("res://levels/level_06_traffic.gd"))
	b.root.add_child(traffic)
	traffic.owner = b.root
	print(b.save("res://levels/level_06.tscn"))
	quit()


## Sin region (Rect2 vacío) usa la textura completa.
func _sprite(root: Node, parent: Node, node_name: String, path: String, pos: Vector2, region := Rect2(), flip := false) -> void:
	var s := Sprite2D.new()
	s.name = node_name
	s.texture = load(path)
	s.position = pos
	if region.has_area():
		s.region_enabled = true
		s.region_rect = region
	s.flip_v = flip
	parent.add_child(s)
	s.owner = root
