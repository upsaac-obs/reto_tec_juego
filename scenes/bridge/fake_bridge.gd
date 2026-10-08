class_name FakeBridge
extends Node
## Hace de app nativa cuando Godot corre solo (editor o escritorio).
## Imprime cada mensaje que manda Godot y, como el menú nativo, abre un nivel al
## recibir engine_ready y otra vez después de level_exited.
## Nivel a abrir: argumento --fake-level=N (por defecto el 1).
##   godot --path . -- --fake-level=99

signal start_level(json: String)
signal pause_level
signal resume_level
signal abort_level
signal set_muted(muted: bool)

## Para las pruebas: todo lo que ha mandado Godot, como [evento, Dictionary].
var sent: Array = []
## Si es false, no abre niveles solo (lo usan las pruebas).
var auto_start: bool = true
var level_id: int = 1
var mode: String = GameState.MODE_GRANDE

## Segundos que tarda el "menú" en abrir el nivel.
@export var menu_delay: float = 0.5


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fake-level="):
			level_id = int(arg.trim_prefix("--fake-level="))


func notify(event: String, json: String) -> void:
	print("[FakeBridge] ← %s %s" % [event, json])
	sent.append([event, JSON.parse_string(json)])
	if auto_start and (event == "engine_ready" or event == "level_exited"):
		await get_tree().create_timer(menu_delay).timeout
		send_start(level_id)


func send_start(id: int, kiosk := false, muted := false) -> void:
	var json := JSON.stringify({"v": 1, "level_id": id, "mode": mode, "kiosk": kiosk, "muted": muted})
	print("[FakeBridge] → start_level %s" % json)
	start_level.emit(json)
