extends CanvasLayer
## Medidor de rendimiento para el A15 (docs/plan_visual.md, fase 0): fps, fps mínimo de
## los últimos 10 s, draw calls, objetos dibujados y memoria. También lo escribe en el
## log cada log_interval segundos (adb logcat -s godot) con el prefijo "PERF".
##
## Solo en builds de depuración y apagado por defecto. Se prende con
## Proyecto → Ajustes del proyecto → rutakids/debug/perf_overlay = true, o con
## `-- --perf` en la línea de comandos. Es una herramienta de medición, no texto del
## juego: por eso sus números no pasan por tr().

const SETTING := "rutakids/debug/perf_overlay"

@export var sample_interval: float = 0.5
@export var min_window: float = 10.0
@export var log_interval: float = 5.0

var _label: Label
var _samples: Array[Vector2] = []
var _elapsed: float = 0.0
var _since_sample: float = 0.0
var _since_log: float = 0.0


func _ready() -> void:
	var wanted := bool(ProjectSettings.get_setting(SETTING, false)) or "--perf" in OS.get_cmdline_user_args()
	if not OS.is_debug_build() or not wanted:
		queue_free()
		return
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(8.0, 76.0)
	_label.add_theme_font_size_override(&"font_size", 14)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 4)
	add_child(_label)


func _process(delta: float) -> void:
	_elapsed += delta
	_since_sample += delta
	_since_log += delta
	if _since_sample < sample_interval:
		return
	_since_sample = 0.0
	var fps := Performance.get_monitor(Performance.TIME_FPS)
	_samples.append(Vector2(_elapsed, fps))
	while not _samples.is_empty() and _samples[0].x < _elapsed - min_window:
		_samples.pop_front()
	var low := fps
	for sample in _samples:
		low = minf(low, sample.y)
	var line := "fps %d  min %d  draw %d  obj %d  ms %.1f  mem %.0f MB" % [
		fps, low,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0]
	_label.text = line
	if _since_log >= log_interval:
		_since_log = 0.0
		print("PERF ", get_tree().current_scene.scene_file_path.get_file() if get_tree().current_scene else "", " ", line)
