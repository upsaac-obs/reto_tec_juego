extends TestCase
## HostBridge (iOS con SwiftGodotKit): la app llama receive_packet("comando|json")
## y escucha message("evento|json").
## Aquí se hace de app nativa con una función conectada a message.


func run() -> void:
	var host := HostBridge.new()
	add_child(host)
	var got: Array = []
	var starts: Array = []
	host.start_level.connect(func(json: String) -> void: starts.append(json))

	host.notify("engine_ready", '{"v":1}')
	host.notify("level_started", '{"level_id":1,"v":1}')
	host.message.connect(func(packet: String) -> void:
		var cut := packet.find("|")
		got.append([packet.left(cut), packet.substr(cut + 1)]))
	check(got.is_empty(), "antes de connect no se manda nada (se guarda)")
	host.receive_packet("connect|")
	check(got.size() == 2 and got[0][0] == "engine_ready" and got[1][0] == "level_started", "connect entrega los mensajes guardados en orden")
	host.notify("level_finished", '{"v":1}')
	check(got.size() == 3 and got[2][0] == "level_finished", "después de connect se manda al momento")

	host.receive_packet('start_level|{"v":1,"level_id":99,"note":"a|b"}')
	check(starts == ['{"v":1,"level_id":99,"note":"a|b"}'], "start_level|json emite start_level con el JSON completo (aunque traiga |)")
	var flags := {"pause": 0, "resume": 0, "abort": 0, "muted": []}
	host.pause_level.connect(func() -> void: flags["pause"] += 1)
	host.resume_level.connect(func() -> void: flags["resume"] += 1)
	host.abort_level.connect(func() -> void: flags["abort"] += 1)
	host.set_muted.connect(func(m: bool) -> void: flags["muted"].append(m))
	host.receive_packet("pause_level|")
	host.receive_packet("resume_level")
	host.receive_packet("abort_level|")
	host.receive_packet("set_muted|true")
	host.receive_packet("set_muted|false")
	check(flags["pause"] == 1 and flags["resume"] == 1 and flags["abort"] == 1, "pause, resume y abort llegan como señales")
	check(flags["muted"] == [true, false], "set_muted convierte \"true\"/\"false\" en booleano")
	host.receive_packet("volar|")
	check(got[-1][0] == "bridge_error" and JSON.parse_string(got[-1][1])["code"] == "unknown_command", "comando desconocido → bridge_error unknown_command")
	host.queue_free()
