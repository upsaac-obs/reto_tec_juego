extends TestCase
## Archivos data/level_XX.tres: claves en textos.csv, ilustración y escena.


func has_key(key: String) -> bool:
	return key.is_empty() or tr(key) != key


func run() -> void:
	for id in LevelData.IDS:
		var data := LevelData.load_by_id(id)
		check(data != null and data.id == id, "data/level_%02d.tres carga con id %d" % [id, id])
		if data == null:
			continue
		var keys_ok := not data.name_key.is_empty() and has_key(data.name_key) and has_key(data.decalogo_key) \
				and not data.phrase_key.is_empty() and has_key(data.phrase_key) and has_key(data.destination_key)
		check(keys_ok, "  nivel %d: todas sus claves existen en textos.csv" % id)
		check(data.illustration != null, "  nivel %d: tiene ilustración" % id)
		check(data.scene_path.is_empty() or data.is_built(), "  nivel %d: la escena existe o está vacía" % id)
	for id in [0, 1, 2]:
		var data := LevelData.load_by_id(id)
		check(data.is_built() and not data.destination_key.is_empty(), "nivel %d está construido y tiene destino" % id)
		var packed := load(data.scene_path) as PackedScene
		check(packed.get_state().get_base_scene_state() != null, "nivel %d hereda de level.tscn" % id)
	check(LevelData.load_by_id(50) == null, "el nivel 50 no existe")
	check(LevelData.find_by_scene("res://levels/level_01.tscn").id == 1, "find_by_scene encuentra el nivel 1")
