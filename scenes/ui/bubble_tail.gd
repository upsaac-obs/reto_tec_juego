class_name BubbleTail
extends Control
## Colita del globo del copiloto: un triángulo que sale del lado izquierdo del
## mensaje y apunta al medallión. CopilotBubble la coloca con attach_to() y le pasa
## los colores del panel (relleno y borde) para que se vea pegada al globo, sin la
## línea del borde en la base.

## Largo de la colita (hacia la izquierda) y ancho de su base.
@export var length: float = 28.0
@export var base_width: float = 44.0
## Cuánto baja la punta respecto al centro de la base (apunta a la cara del copiloto).
@export var tip_drop: float = 8.0

var fill_color: Color = Color.WHITE
var border_color: Color = Color.WHITE
var border_width: float = 6.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Pone la base sobre la orilla izquierda de panel, a media altura, con sus colores.
func attach_to(panel: Control) -> void:
	var style := panel.get_theme_stylebox(&"panel") as StyleBoxFlat
	if style != null:
		fill_color = style.bg_color
		border_color = style.border_color
		border_width = style.border_width_left
	var rect := panel.get_global_rect()
	global_position = Vector2(rect.position.x, rect.get_center().y)
	queue_redraw()


func _draw() -> void:
	var half := base_width / 2.0
	var tip := Vector2(-length, tip_drop)
	# La base entra en el panel lo que mide su borde, para tapar esa línea.
	var inner := border_width + 1.0
	var top := Vector2(inner, -half)
	var bottom := Vector2(inner, half)
	draw_colored_polygon(PackedVector2Array([top, tip, bottom]), border_color)
	# Relleno un borde más adentro: queda el contorno en los dos lados de afuera.
	var shrink := border_width * 1.15
	var fill_tip := tip + (Vector2(inner, 0.0) - tip).normalized() * shrink * 1.8
	draw_colored_polygon(PackedVector2Array([
		Vector2(inner, -half + shrink), fill_tip, Vector2(inner, half - shrink)]), fill_color)
