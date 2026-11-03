extends Node2D
## Ícono redondo y dorado que flota sobre el edificio del destino (sin texto), para que
## una niña o un niño que todavía no lee vea a dónde va. Lo pone CityDresser.
## Dibujo con primitivas hasta tener la hoja de íconos de docs/plan_visual.md (§4, #5).

const Palette := preload("res://autoload/game_state.gd")

## LevelTheme.Icon
@export var icon: int = 0
@export var radius: float = 26.0
## Cuánto sube y baja, en px, y en cuántos segundos.
@export var bob_height: float = 4.0
@export var bob_time: float = 0.9
## z_index: encima del edificio y de las piezas, debajo de los portales del cruce ciego (10).
@export var draw_above: int = 5

var _base_y: float


func _ready() -> void:
	# CityDecor va antes que Decor: sin esto el edificio del destino taparía el ícono.
	z_index = draw_above
	_base_y = position.y
	var tween := create_tween().set_loops()
	tween.tween_property(self, ^"position:y", _base_y - bob_height, bob_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, ^"position:y", _base_y, bob_time).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	draw_circle(Vector2(3.0, 4.0), radius, Color(Palette.COLOR_SHADOW, 0.45))
	draw_circle(Vector2.ZERO, radius, Palette.COLOR_OUTLINE)
	draw_circle(Vector2.ZERO, radius - 2.0, Palette.COLOR_GOLD)
	draw_circle(Vector2.ZERO, radius - 6.0, Palette.COLOR_DARK_PURPLE)
	match icon:
		LevelTheme.Icon.TREE:
			draw_rect(Rect2(-3, 2, 6, 11), Palette.COLOR_SKIN_DARK)
			draw_circle(Vector2(0, -4), 11.0, Palette.COLOR_LEAF_LIGHT)
			draw_circle(Vector2(-3, -7), 4.0, Palette.COLOR_GREEN)
		LevelTheme.Icon.BOOK:
			draw_rect(Rect2(-13, -9, 12, 18), Palette.COLOR_WHITE)
			draw_rect(Rect2(1, -9, 12, 18), Palette.COLOR_WHITE)
			draw_line(Vector2(0, -10), Vector2(0, 10), Palette.COLOR_ADO_RED, 2.0)
			for y in [-4, 0, 4]:
				draw_line(Vector2(-10, y), Vector2(-4, y), Palette.COLOR_SIDEWALK_JOINT, 1.0)
				draw_line(Vector2(4, y), Vector2(10, y), Palette.COLOR_SIDEWALK_JOINT, 1.0)
		LevelTheme.Icon.FRUIT:
			draw_circle(Vector2(0, 3), 10.0, Palette.COLOR_ADO_RED)
			draw_circle(Vector2(-3, 0), 3.0, Palette.COLOR_SKY_HORIZON)
			draw_rect(Rect2(-1, -11, 2, 6), Palette.COLOR_SKIN_DARK)
			draw_colored_polygon(PackedVector2Array([Vector2(1, -8), Vector2(10, -12), Vector2(6, -5)]), Palette.COLOR_LEAF_LIGHT)
		LevelTheme.Icon.HOUSE:
			draw_colored_polygon(PackedVector2Array([Vector2(-14, -1), Vector2(0, -14), Vector2(14, -1)]), Palette.COLOR_ADO_RED)
			draw_rect(Rect2(-10, -1, 20, 13), Palette.COLOR_WHITE)
			draw_rect(Rect2(-3, 3, 6, 9), Palette.COLOR_GOLD)
		LevelTheme.Icon.BELL:
			draw_circle(Vector2(0, -3), 9.0, Palette.COLOR_GOLD)
			draw_rect(Rect2(-9, -3, 18, 10), Palette.COLOR_GOLD)
			draw_rect(Rect2(-12, 6, 24, 3), Palette.COLOR_GOLD)
			draw_circle(Vector2(0, 11), 3.0, Palette.COLOR_WHITE)
		LevelTheme.Icon.CROSS:
			draw_rect(Rect2(-4, -12, 8, 24), Palette.COLOR_LEAF_LIGHT)
			draw_rect(Rect2(-12, -4, 24, 8), Palette.COLOR_LEAF_LIGHT)
		LevelTheme.Icon.BUS:
			draw_rect(Rect2(-14, -8, 28, 15), Palette.COLOR_WHITE)
			for x in [-11, -4, 3]:
				draw_rect(Rect2(x, -5, 6, 5), Palette.COLOR_GLASS)
			draw_circle(Vector2(-8, 8), 3.0, Palette.COLOR_OUTLINE)
			draw_circle(Vector2(8, 8), 3.0, Palette.COLOR_OUTLINE)
