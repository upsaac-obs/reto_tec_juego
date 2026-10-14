@tool
extends Node2D
## Portales sobre la calle que cruza: se dibujan encima del tráfico (z_index)
## para que los autos que vienen no se vean hasta que salen de abajo.
## Dibujo provisional hasta tener edificios_esquina.png (docs/prompts_fase2.md).

const Palette := preload("res://autoload/game_state.gd")


func _draw() -> void:
	var crossing := get_parent() as BlindCrossing
	if crossing == null:
		return
	var half := crossing.cross_width / 2.0 + 72.0
	for y_sign: float in [-1.0, 1.0]:
		var near := crossing.portal_start * y_sign
		var far := (crossing.portal_start + crossing.portal_length) * y_sign
		var rect := Rect2(-half, minf(near, far), half * 2.0, absf(far - near))
		draw_rect(Rect2(rect.position + Vector2(6.0, 6.0), rect.size), Palette.COLOR_SHADOW)
		draw_rect(rect, Palette.COLOR_OUTLINE)
		draw_rect(rect.grow(-3.0), Palette.COLOR_SKY_HORIZON)
		draw_rect(rect.grow(-11.0), Palette.COLOR_SKY_MID)
		# Arcos del portal en el lado que da al cruce.
		var arch_y := near - 6.0 * y_sign
		var x := -half + 18.0
		while x < half - 12.0:
			draw_circle(Vector2(x, arch_y), 9.0, Palette.COLOR_OUTLINE)
			draw_circle(Vector2(x, arch_y), 7.0, Palette.COLOR_SHADOW)
			x += 28.0
