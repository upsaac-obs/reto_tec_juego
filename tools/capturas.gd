extends Node
## Capturas de los 9 niveles en modo peque para revisar el arte (docs/plan_visual.md).
## Necesita ventana (no --headless):
##   godot --path . --resolution 1280x720 res://tools/capturas.tscn -- --out=/ruta/carpeta
## Guarda nivel_N_XXs.png a 1.5, 7, 14 y 22 s de cada nivel, y nivel_N_destino.png
## con la cámara sobre el ícono del destino (CityDresser).

const TIMES: Array[float] = [1.5, 7.0, 14.0, 22.0]


class Runner extends Node:
	var out_dir: String

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		GameState.mode = GameState.MODE_PEQUE
		DirAccess.make_dir_recursive_absolute(out_dir)
		for level in range(9):
			get_tree().change_scene_to_file("res://levels/level_%02d.tscn" % level)
			var elapsed := 0.0
			for when in TIMES:
				await get_tree().create_timer(when - elapsed, true, false, true).timeout
				elapsed = when
				var image := get_viewport().get_texture().get_image()
				image.save_png(out_dir.path_join("nivel_%d_%02ds.png" % [level, int(when)]))
			var marker := get_tree().current_scene.get_node_or_null(^"CityDecor/Destination/DestinationMarker") as Node2D
			if marker != null:
				var camera := Camera2D.new()
				get_tree().current_scene.add_child(camera)
				camera.global_position = marker.global_position + Vector2(0.0, 120.0)
				camera.make_current()
				await get_tree().create_timer(0.4, true, false, true).timeout
				get_viewport().get_texture().get_image().save_png(out_dir.path_join("nivel_%d_destino.png" % level))
		get_tree().quit()


func _ready() -> void:
	var runner := Runner.new()
	runner.out_dir = OS.get_user_data_dir().path_join("capturas")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			runner.out_dir = arg.trim_prefix("--out=")
	get_tree().root.add_child.call_deferred(runner)
