extends TestCase
## engine_ready manda la marca del build (build_info.gd, "dev" en el repositorio).


func run() -> void:
	check(BridgeClient.build_stamp() == "dev", "en el repositorio build_info.gd dice dev")
	var fake := fake_bridge()
	fake.sent.clear()
	BridgeClient._engine_ready_sent = false
	BridgeClient._go_idle()
	await frames()
	var ready: Array = fake.sent.filter(func(m: Array) -> bool: return m[0] == "engine_ready")
	check(ready.size() == 1 and ready[0][1].get("build") == "dev" and ready[0][1].get("v") == 1.0, "engine_ready lleva {\"v\":1, \"build\":\"dev\"}")
