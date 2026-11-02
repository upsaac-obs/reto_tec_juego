@tool
class_name DepartureBoard
extends RulePiece
## Tablero de salidas de la terminal (nivel 5). No es una regla: solo se muestra.
## Dice siempre "A tiempo": nunca cuenta hacia atrás ni muestra números u horas,
## así que no se puede perder por tiempo.
## - Widget en pantalla (CanvasLayer propio) debajo de la barra superior.
## - Letrero en el mundo, en la banqueta frente a la terminal. El origen es el
##   pie del letrero.
## - Al terminar el nivel, el copiloto dice arrival_message_key ("¡Llegamos a
##   tiempo!") en lugar del mensaje de meta y el widget hace un "pop".

## Muestra el widget en pantalla.
@export var show_widget: bool = true
## En modo peque también se muestra el widget (el copiloto lo explica por voz).
@export var show_in_peque: bool = true
@export var widget_position: Vector2 = Vector2(16.0, 88.0)
@export var widget_min_width: float = 200.0
## Arriba del HUD y abajo de la burbuja del copiloto (capa 10).
@export var widget_layer: int = 2
## Segundos de cada medio latido del punto verde.
@export var blink_interval: float = 0.8
@export var dot_size: float = 12.0
@export var title_font_size: int = 16
@export var row_font_size: int = 20
## Escala del "pop" al llegar y cuánto dura.
@export var pop_scale: float = 1.15
@export var pop_time: float = 0.2
@export var arrival_message_key: String = "LLEGADA_A_TIEMPO"
@export_group("Letrero")
@export var board_size: Vector2 = Vector2(144.0, 64.0):
	set(value):
		board_size = value
		queue_redraw()
## Largo de las patas, del tablero al piso.
@export var leg_length: float = 16.0:
	set(value):
		leg_length = value
		queue_redraw()
@export var border_width: float = 3.0
@export var board_title_size: int = 12
@export var board_row_size: int = 13

var _layer: CanvasLayer
var _panel: PanelContainer
var _labels: Array[Label] = []
var _blink: Tween


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if show_widget and (show_in_peque or GameState.mode != GameState.MODE_PEQUE):
		_build_widget()


func _connect_rule_manager() -> void:
	super()
	var manager := _rule_manager()
	if manager != null and not manager.level_finished.is_connected(_on_level_finished):
		manager.level_finished.connect(_on_level_finished)


func has_widget() -> bool:
	return _panel != null


## Textos que se ven en el widget (para las pruebas).
func widget_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	for label in _labels:
		texts.append(label.text)
	return texts


func _on_level_finished(_stars: int) -> void:
	Feedback.show_good_action(arrival_message_key, 0)
	if _panel != null:
		_panel.pivot_offset = _panel.size / 2.0
		_panel.scale = Vector2.ONE * pop_scale
		create_tween().tween_property(_panel, ^"scale", Vector2.ONE, pop_time)


func _build_widget() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "Widget"
	_layer.layer = widget_layer
	add_child(_layer)
	_panel = PanelContainer.new()
	_panel.theme = preload("res://assets/ui/theme.tres")
	_panel.theme_type_variation = &"TopBarPill"
	_panel.position = widget_position
	_panel.custom_minimum_size.x = widget_min_width
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(column)
	column.add_child(_make_label("TABLERO_TITULO", title_font_size, Palette.COLOR_GOLD))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	row.add_child(_make_label("TABLERO_AUTOBUS", row_font_size, Palette.COLOR_WHITE))
	var dot := ColorRect.new()
	dot.color = Palette.COLOR_GREEN
	dot.custom_minimum_size = Vector2(dot_size, dot_size)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(dot)
	row.add_child(_make_label("TABLERO_A_TIEMPO", row_font_size, Palette.COLOR_GREEN))
	_blink = dot.create_tween().set_loops()
	_blink.tween_property(dot, ^"modulate:a", 0.5, blink_interval)
	_blink.tween_property(dot, ^"modulate:a", 1.0, blink_interval)


func _make_label(key: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = tr(key)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_labels.append(label)
	return label


## Letrero en la banqueta: el mismo tablero que el widget, en grande.
func _draw() -> void:
	var rect := Rect2(-board_size.x / 2.0, -board_size.y - leg_length, board_size.x, board_size.y)
	for x: float in [rect.position.x + 16.0, rect.end.x - 20.0]:
		draw_rect(Rect2(x, rect.end.y, 4.0, leg_length), Palette.COLOR_SHADOW)
	draw_rect(rect, Palette.COLOR_ADO_RED)
	draw_rect(rect.grow(-border_width), Palette.COLOR_DARK_PURPLE)
	var font := ThemeDB.fallback_font
	var left := rect.position.x + 10.0
	var width := rect.size.x - 20.0
	var line := rect.position.y + border_width + font.get_ascent(board_title_size) + 4.0
	draw_string(font, Vector2(left, line), tr("TABLERO_TITULO"), HORIZONTAL_ALIGNMENT_LEFT, width, board_title_size, Palette.COLOR_GOLD)
	line += font.get_height(board_row_size) + 2.0
	draw_string(font, Vector2(left, line), tr("TABLERO_AUTOBUS"), HORIZONTAL_ALIGNMENT_LEFT, width, board_row_size, Palette.COLOR_WHITE)
	line += font.get_height(board_row_size) + 2.0
	var dot := board_row_size * 0.4
	draw_circle(Vector2(left + dot, line - dot), dot, Palette.COLOR_GREEN)
	draw_string(font, Vector2(left + dot * 3.0, line), tr("TABLERO_A_TIEMPO"), HORIZONTAL_ALIGNMENT_LEFT, width, board_row_size, Palette.COLOR_GREEN)
