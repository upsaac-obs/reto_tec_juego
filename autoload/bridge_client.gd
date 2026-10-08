extends Node
## Puente con la app nativa (contrato en docs/arquitectura.md).
## - Nativo → Godot: el singleton RutaBridge emite señales (start_level, pause_level,
##   resume_level, abort_level, set_muted) y aquí se escuchan.
## - Godot → nativo: se llama RutaBridge.notify(evento, json). Todo JSON lleva "v".
## Sin app nativa (editor, escritorio) se usa FakeBridge, que imprime en consola.
## Godot no guarda nada: recibe todo en start_level y entrega todo en level_finished.

enum State { IDLE, PLAYING }

const PROTOCOL_VERSION := 1
const IDLE_SCENE := "res://scenes/bridge/idle.tscn"
const MODES: Array[String] = [GameState.MODE_PEQUE, GameState.MODE_GRANDE]

## Segundos sin tocar la pantalla dentro de un nivel en kiosco antes de avisar.
@export var inactivity_limit: float = 60.0

var state: State = State.IDLE
var level_id: int = -1

var _bridge: Object
var _finished: bool = false
var _engine_ready_sent: bool = false
## Segundos jugados del intento actual, sin contar pausas.
var _played: float = 0.0
var _idle_time: float = 0.0
var _inactivity_sent: bool = false
var _bridge_paused: bool = false
var _paused_before: bool = false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	if Engine.has_singleton("RutaBridge"):
		_bridge = Engine.get_singleton("RutaBridge")
	else:
		var fake := FakeBridge.new()
		add_child(fake)
		_bridge = fake
	_bridge.connect(&"start_level", _on_start_level)
	_bridge.connect(&"pause_level", _on_pause_level)
	_bridge.connect(&"resume_level", _on_resume_level)
	_bridge.connect(&"abort_level", _on_abort_level)
	_bridge.connect(&"set_muted", _on_set_muted)
	get_tree().scene_changed.connect(_on_scene_changed)
	_adopt_first_scene.call_deferred()


func _notification(what: int) -> void:
	# Por si acaso el nativo no avisa (sección 4, paso 5).
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_on_pause_level()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_on_resume_level()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey:
		_idle_time = 0.0
		_inactivity_sent = false


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	if not get_tree().paused:
		_played += delta
	if GameState.kiosk and not _inactivity_sent:
		_idle_time += delta
		if _idle_time >= inactivity_limit:
			_inactivity_sent = true
			_send(&"inactivity_timeout", {})


## Lo llama la tarjeta de hábito (Continuar) y el menú de pausa (Salir).
func exit_level(completed: bool) -> void:
	if state != State.PLAYING:
		return
	_send(&"level_exited", {"level_id": level_id, "completed": completed})
	_go_idle()


## Repetir en la tarjeta de hábito: el mismo nivel desde el principio.
func retry_level() -> void:
	if state != State.PLAYING:
		return
	_load_level(GameState.level)


## Mantener presionado el engrane: el nativo abre la pantalla de tutores.
func request_tutor() -> void:
	_send(&"tutor_requested", {"level_id": level_id})


# --- Nativo → Godot ---

func _on_start_level(json: String) -> void:
	var parser := JSON.new()
	if parser.parse(json) != OK:
		_error(&"invalid_json", "línea %d: %s" % [parser.get_error_line(), parser.get_error_message()])
		return
	var data: Variant = parser.data
	if not data is Dictionary:
		_error(&"invalid_json", "se esperaba un objeto")
		return
	if data.get("v") != float(PROTOCOL_VERSION):
		_error(&"unsupported_version", str(data.get("v")))
		return
	var id: Variant = data.get("level_id")
	var level: LevelData = LevelData.load_by_id(int(id)) if id is float and id == floorf(id) else null
	if level == null:
		_error(&"unknown_level", str(id))
		return
	if not level.is_built():
		_error(&"level_not_built", str(int(id)))
		return
	var mode: Variant = data.get("mode")
	if not (mode is String and MODES.has(mode)):
		_error(&"invalid_field", "mode: %s" % str(mode))
		return
	if not (data.get("kiosk") is bool and data.get("muted") is bool):
		_error(&"invalid_field", "kiosk y muted deben ser true o false")
		return
	# Cada nivel que empieza termina con level_exited, aunque lo reemplace otro.
	if state == State.PLAYING:
		_send(&"level_exited", {"level_id": level_id, "completed": _finished})
	GameState.mode = mode
	GameState.kiosk = data["kiosk"]
	_on_set_muted(data["muted"])
	_load_level(level)


func _on_pause_level() -> void:
	if _bridge_paused:
		return
	_bridge_paused = true
	# La pausa de una falta se quitaría sola a los 2 s; aquí se toma esta pausa.
	_paused_before = get_tree().paused and not Feedback.is_pausing()
	Feedback.clear()
	get_tree().paused = true


func _on_resume_level() -> void:
	if not _bridge_paused:
		return
	_bridge_paused = false
	get_tree().paused = _paused_before


func _on_abort_level() -> void:
	exit_level(_finished)


func _on_set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(0, muted)


# --- Internos ---

func _load_level(level: LevelData) -> void:
	state = State.PLAYING
	level_id = level.id
	GameState.level = level
	_reset_attempt()
	get_tree().change_scene_to_file(level.scene_path)


func _go_idle() -> void:
	state = State.IDLE
	level_id = -1
	GameState.level = null
	_reset_attempt()
	get_tree().change_scene_to_file(IDLE_SCENE)


func _reset_attempt() -> void:
	_finished = false
	_played = 0.0
	_idle_time = 0.0
	_inactivity_sent = false
	_bridge_paused = false
	Feedback.clear()
	get_tree().paused = false


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if state == State.IDLE and scene.scene_file_path == IDLE_SCENE:
		# Solo una vez por sesión: Godot no se destruye entre niveles (H1).
		if not _engine_ready_sent:
			_engine_ready_sent = true
			_send(&"engine_ready", {})
	elif state == State.PLAYING:
		_connect_level()
		_send(&"level_started", {"level_id": level_id})


## Al arrancar: si es idle.tscn avisa engine_ready; si es un nivel abierto con F6
## desde el editor, lo toma como si el nativo lo hubiera abierto.
func _adopt_first_scene() -> void:
	var path := get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	var level := LevelData.find_by_scene(path)
	if level != null:
		state = State.PLAYING
		level_id = level.id
		GameState.level = level
		_reset_attempt()
	_on_scene_changed()


func _connect_level() -> void:
	var manager := get_tree().get_first_node_in_group(&"rule_manager") as RuleManager
	if manager == null:
		_error(&"no_rule_manager", GameState.level.scene_path)
		return
	manager.level_finished.connect(_on_level_finished.bind(manager))


func _on_level_finished(stars: int, manager: RuleManager) -> void:
	_finished = true
	_send(&"level_finished", {
		"level_id": level_id,
		"stars": stars,
		"points": manager.points,
		"infractions": manager.infractions,
		"duration_s": roundi(_played),
	})


func _error(code: StringName, detail: String) -> void:
	push_warning("RutaBridge: %s (%s)" % [code, detail])
	_send(&"bridge_error", {"code": code, "detail": detail})


func _send(event: StringName, data: Dictionary) -> void:
	var message := {"v": PROTOCOL_VERSION}
	message.merge(data)
	_bridge.call(&"notify", String(event), JSON.stringify(message))
