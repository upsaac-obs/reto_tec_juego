@tool
class_name TunnelDecor
extends Node2D
## Túnel del nivel 7 visto desde arriba (solo decoración, sin colisiones ni grupos).
## El origen va sobre el centro de la calle. Entre start_x y end_x el cerro tapa las
## banquetas, la calle tiene muros de concreto con lámparas y en cada punta hay un
## portal de cantera (tunel_portal.png) que el auto cruza por debajo.
## La oscuridad y la regla de las luces siguen siendo de DarkZone.

const Palette := preload("res://autoload/game_state.gd")
const PORTAL := preload("res://assets/sprites/city/tunel_portal.png")
const TILES := preload("res://assets/tiles/street_v2.png")
## Tile de cerro de street_v2.png (el mismo que pone CityDresser detrás).
const HILL_REGION := Rect2(6 * 64, 4 * 64, 64, 64)
## x de la cara de cantera dentro de tunel_portal.png (tools/art/tunel_v3.py).
const FACE_X := 30.0

@export var start_x: float = 0.0:
	set(value):
		start_x = value
		_refresh()
@export var end_x: float = 1400.0:
	set(value):
		end_x = value
		_refresh()
## Media calle (carriles), igual que DarkZone.road_width / 2.
@export var road_half: float = 64.0:
	set(value):
		road_half = value
		queue_redraw()
## Hasta dónde tapa el cerro a cada lado (orilla de afuera de la banqueta).
@export var cover_half: float = 192.0:
	set(value):
		cover_half = value
		queue_redraw()
@export var wall_width: float = 20.0:
	set(value):
		wall_width = value
		queue_redraw()
@export var wall_color: Color = Palette.COLOR_SIDEWALK_JOINT:
	set(value):
		wall_color = value
		queue_redraw()
@export var wall_edge_color: Color = Palette.COLOR_OUTLINE:
	set(value):
		wall_edge_color = value
		queue_redraw()
@export var lamp_every: float = 160.0:
	set(value):
		lamp_every = value
		_refresh()
@export var lamp_color: Color = Palette.COLOR_WARM_LIGHT:
	set(value):
		lamp_color = value
		_refresh()
## z de los portales: encima del auto (pasa por debajo del techo).
@export var portal_z_index: int = 5
## z de las lámparas: encima de la sombra de DarkZone para que se vean prendidas.
@export var lamp_z_index: int = 1

var _portals: Array[Sprite2D] = []
var _lamps: Node2D


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if not is_inside_tree():
		return
	for portal in _portals:
		portal.queue_free()
	_portals.clear()
	if _lamps != null:
		_lamps.queue_free()
	var half_w := PORTAL.get_width() / 2.0
	for side: int in [-1, 1]:
		var portal := Sprite2D.new()
		portal.texture = PORTAL
		portal.z_index = portal_z_index
		portal.flip_h = side > 0
		# La cara de cantera cae justo en start_x (entrada) o end_x (salida, espejo).
		portal.position = Vector2(start_x - FACE_X + half_w if side < 0 else end_x + FACE_X - half_w, 0.0)
		add_child(portal, false, Node.INTERNAL_MODE_BACK)
		_portals.append(portal)
	_lamps = Node2D.new()
	_lamps.z_index = lamp_z_index
	_lamps.draw.connect(_draw_lamps)
	add_child(_lamps, false, Node.INTERNAL_MODE_BACK)
	queue_redraw()


func _draw() -> void:
	var length := end_x - start_x
	if length <= 0.0:
		return
	for side: float in [-1.0, 1.0]:
		# Cerro sobre la banqueta.
		var top := road_half + wall_width if side > 0 else -cover_half
		var cover := Rect2(start_x, top, length, cover_half - road_half - wall_width)
		var x := start_x
		while x < end_x:
			var w := minf(64.0, end_x - x)
			var y := cover.position.y
			while y < cover.end.y:
				var h := minf(64.0, cover.end.y - y)
				draw_texture_rect_region(TILES, Rect2(x, y, w, h), Rect2(HILL_REGION.position, Vector2(w, h)))
				y += 64.0
			x += 64.0
		# Muro de concreto con juntas y contorno.
		var wy := road_half if side > 0 else -road_half - wall_width
		var wall := Rect2(start_x, wy, length, wall_width)
		draw_rect(wall, wall_color)
		var jx := start_x + 32.0
		while jx < end_x:
			draw_line(Vector2(jx, wy + 2.0), Vector2(jx, wy + wall_width - 2.0), wall_edge_color.lerp(wall_color, 0.6), 1.5)
			jx += 64.0
		draw_line(Vector2(start_x, wy), Vector2(end_x, wy), wall_edge_color, 2.0)
		draw_line(Vector2(start_x, wy + wall_width), Vector2(end_x, wy + wall_width), wall_edge_color, 2.0)


func _draw_lamps() -> void:
	if lamp_every <= 0.0:
		return
	var x := start_x + lamp_every / 2.0
	while x < end_x:
		for side: float in [-1.0, 1.0]:
			var y := side * (road_half + wall_width / 2.0)
			_lamps.draw_circle(Vector2(x, y), 9.0, Color(lamp_color, 0.25))
			_lamps.draw_circle(Vector2(x, y), 4.5, lamp_color)
		x += lamp_every
