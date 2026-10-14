class_name HostBridge
extends Node
## Puente para apps que incrustan Godot y le hablan a un nodo del árbol en vez
## de registrar un singleton (iOS con SwiftGodotKit). Mismo contrato que el
## plugin de Android y el FakeBridge (docs/arquitectura.md, sección 3):
## - Nativo → Godot: la app llama receive_packet("comando|json"). Comandos:
##   connect, start_level, pause_level, resume_level, abort_level y set_muted
##   (json "true" o "false").
## - Godot → nativo: se emite message("evento|json"), que la app escucha.
## Todo va en un solo texto "nombre|json" para que del lado de Swift baste con
## pasar y recibir un String (como el ejemplo de SwiftGodotKit).
## Godot manda engine_ready antes de que la app alcance a conectarse, así que los
## mensajes se guardan hasta que la app manda "connect|".

signal start_level(json: String)
signal pause_level
signal resume_level
signal abort_level
signal set_muted(muted: bool)
## Lo escucha la app nativa: "evento|json".
signal message(packet: String)

var _connected: bool = false
var _pending: Array[PackedStringArray] = []


func notify(event: String, json: String) -> void:
	if _connected:
		message.emit(event + "|" + json)
	else:
		_pending.append(PackedStringArray([event, json]))


## Lo llama la app nativa con "comando|json".
func receive_packet(packet: String) -> void:
	var cut := packet.find("|")
	if cut < 0:
		receive(packet, "")
	else:
		receive(packet.left(cut), packet.substr(cut + 1))


func receive(command: String, json: String) -> void:
	match command:
		"connect":
			_connected = true
			for pending in _pending:
				message.emit(pending[0] + "|" + pending[1])
			_pending.clear()
		"start_level":
			start_level.emit(json)
		"pause_level":
			pause_level.emit()
		"resume_level":
			resume_level.emit()
		"abort_level":
			abort_level.emit()
		"set_muted":
			set_muted.emit(json == "true")
		_:
			notify("bridge_error", JSON.stringify({"v": 1, "code": "unknown_command", "detail": command}))
