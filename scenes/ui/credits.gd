class_name Credits
extends CanvasLayer
## Créditos tipo película al terminar el último nivel (LevelData.show_credits; los abre
## HabitCard al tocar Continuar). El texto sube despacio sobre la ilustración de
## "Hábito de campeón"; al final aparece el copiloto con "¡Gracias por manejar con cuidado!".
## Un toque los salta (después de skip_delay). Emite finished y se borra.
## Todos los textos salen de i18n/textos.csv (claves CREDITOS_*, sin voz).

signal finished

const Palette := preload("res://autoload/game_state.gd")
const BACKGROUND := preload("res://assets/ui/habit_cards/card_10.png")
const COPILOT := preload("res://assets/sprites/copilot/copilot_frames.tres")

## Pantallas de texto en orden: [tipo, clave]. "title" grande, "head" encabezado dorado,
## "name" nombre, "gap" espacio. El director va solo y más grande, después del equipo.
const LINES: Array = [
	["title", "CREDITOS_TITULO"],
	["gap", ""],
	["name", "CREDITOS_INTEGRANTE_1"],
	["name", "CREDITOS_INTEGRANTE_2"],
	["name", "CREDITOS_INTEGRANTE_3"],
	["name", "CREDITOS_INTEGRANTE_4"],
	["gap", ""],
	["head", "CREDITOS_DIRECCION"],
	["lead", "CREDITOS_DIRECTOR"],
	["gap", ""],
	["head", "CREDITOS_AGRADECIMIENTOS"],
	["name", "CREDITOS_FUNDACION"],
	["gap", ""],
	["head", "CREDITOS_TECNOLOGIA"],
	["small", "CREDITOS_GODOT"],
	["small", "CREDITOS_FUENTE"],
	["small", "CREDITOS_VOZ"],
]

## Píxeles por segundo que sube el texto.
@export var scroll_speed: float = 55.0
## Segundos antes de que un toque los pueda saltar (evita saltarlos sin querer).
@export var skip_delay: float = 1.0
## Segundos que se queda el agradecimiento final antes de cerrar solo.
@export var end_hold: float = 3.5
@export var font_sizes: Dictionary = {"title": 76, "lead": 46, "head": 26, "name": 36, "small": 22, "gap": 40}

var _column: VBoxContainer
var _ending: Control
var _elapsed: float = 0.0
var _done: bool = false
var _ending_shown: bool = false


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.gui_input.connect(_on_input)
	add_child(root)

	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(Palette.COLOR_OUTLINE, 0.62)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	# La columna mide el ancho de la pantalla desde antes de llenarla: si no, el texto se
	# mide con ancho 0 (una letra por renglón) y la columna sale altísima.
	var view := get_viewport().get_visible_rect().size
	_column = VBoxContainer.new()
	_column.custom_minimum_size.x = view.x
	_column.add_theme_constant_override(&"separation", 10)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_column)
	for line: Array in LINES:
		_column.add_child(_make_line(line[0], line[1]))
	_column.reset_size()
	_column.position = Vector2(0.0, view.y)

	_ending = _make_ending()
	_ending.modulate.a = 0.0
	root.add_child(_ending)

	AudioManager.play_sfx(&"celebration")


func _make_line(kind: String, key: String) -> Control:
	if kind == "gap":
		var gap := Control.new()
		gap.custom_minimum_size.y = font_sizes["gap"]
		return gap
	var label := Label.new()
	label.text = tr(key)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font_sizes[kind])
	var gold := kind in ["title", "head", "lead"]
	label.add_theme_color_override(&"font_color", Palette.COLOR_GOLD if gold else Palette.COLOR_WHITE)
	label.add_theme_color_override(&"font_outline_color", Palette.COLOR_OUTLINE)
	label.add_theme_constant_override(&"outline_size", 10 if kind in ["title", "lead"] else 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_ending() -> Control:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(210, 212)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var copilot := AnimatedSprite2D.new()
	copilot.sprite_frames = COPILOT
	copilot.position = Vector2(105, 106)
	copilot.scale = Vector2(2, 2)
	copilot.play(&"happy")
	holder.add_child(copilot)
	box.add_child(holder)
	var thanks := Label.new()
	thanks.text = tr("CREDITOS_GRACIAS")
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thanks.add_theme_font_size_override(&"font_size", 44)
	thanks.add_theme_color_override(&"font_color", Palette.COLOR_GOLD)
	thanks.add_theme_color_override(&"font_outline_color", Palette.COLOR_OUTLINE)
	thanks.add_theme_constant_override(&"outline_size", 10)
	thanks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(thanks)
	return box


func _process(delta: float) -> void:
	if _done or _column == null:
		return
	_elapsed += delta
	_column.position.y -= scroll_speed * delta
	if not _ending_shown and _column.position.y + _column.size.y < 0.0:
		_show_ending()


func _show_ending() -> void:
	_ending_shown = true
	var view := get_viewport().get_visible_rect().size
	_ending.position = (view - _ending.get_combined_minimum_size()) / 2.0
	var tween := create_tween()
	tween.tween_property(_ending, ^"modulate:a", 1.0, 0.6)
	tween.tween_interval(end_hold)
	tween.tween_callback(_finish)


func _on_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	if tapped and _elapsed >= skip_delay:
		_finish()


## Cierra los créditos (al terminar o con un toque). Solo una vez.
func skip() -> void:
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	queue_free()
