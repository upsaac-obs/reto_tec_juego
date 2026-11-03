class_name CityDresser
extends Node
## Viste la ciudad de un nivel al cargarlo (docs/plan_visual.md, fase 0): quita las
## casas provisionales del tilemap, pone manzanas continuas con casas.png y
## edificios.png pegadas a la banqueta, azoteas o pasto detrás, árboles en la
## banqueta, el ícono del destino y el tinte de la hora del día.
##
## Solo es decoración: nada tiene Area2D ni grupos, nada pisa los carriles y nada va
## a menos de LevelTheme.calm_radius de una pieza de Rules (tests/test_decor.gd).
## Los ajustes de cada nivel están en data/themes/theme_XX.tres (mismo número que
## levels/level_XX.tscn). Sin tema, o con enabled = false, el nivel queda como estaba.

const CASAS := preload("res://assets/sprites/city/casas.png")
const EDIFICIOS := preload("res://assets/sprites/city/edificios.png")
const ARBOLES := preload("res://assets/sprites/city/arboles.png")
const DestinationMarkerScript := preload("res://scenes/level/destination_marker.gd")

## Lotes: 4 casas (128×128) y 3 edificios (142×160), en el orden de LevelTheme.lot_weights.
const LOTS: Array[Dictionary] = [
	{"tex": CASAS, "rect": Rect2(0, 0, 128, 128)},
	{"tex": CASAS, "rect": Rect2(128, 0, 128, 128)},
	{"tex": CASAS, "rect": Rect2(256, 0, 128, 128)},
	{"tex": CASAS, "rect": Rect2(384, 0, 128, 128)},
	{"tex": EDIFICIOS, "rect": Rect2(0, 0, 142, 160)},
	{"tex": EDIFICIOS, "rect": Rect2(142, 0, 142, 160)},
	{"tex": EDIFICIOS, "rect": Rect2(284, 0, 142, 160)},
]
const TILE := 64
## Tiles de calle, banqueta y meta (street_v2.png): marcan la franja de la calle.
const STREET_TILES: Array[Vector2i] = [
	Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1),
	Vector2i(4, 4), Vector2i(5, 4)]
const SIDEWALK_PLAIN := Vector2i(3, 0)
const SIDEWALK_VARIANTS: Array[Vector2i] = [Vector2i(4, 4), Vector2i(5, 4)]
const GRASS_TILES: Array[Vector2i] = [
	Vector2i(0, 4), Vector2i(0, 4), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]
const HILL_TILES: Array[Vector2i] = [Vector2i(6, 4), Vector2i(6, 4), Vector2i(7, 4)]
## Azoteas lisas sin borde: una por manzana de ROOF_BLOCK tiles para que se lean como azoteas grandes.
const ROOF_PLAIN: Array[Vector2i] = [Vector2i(6, 5), Vector2i(7, 5)]
## Azoteas con algo encima (tinaco, tendedero, impermeabilizante, macetas, tragaluz, antena).
const ROOF_ITEMS: Array[Vector2i] = [
	Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5)]
const ROOF_BLOCK := Vector2i(3, 2)

## Carpeta de los temas por nivel.
@export_dir var themes_dir: String = "res://data/themes"
## Variación de brillo de cada lote para que no se vean copiados (1 = sin variación).
@export_range(0.0, 0.3) var lot_shade_jitter: float = 0.08
## Probabilidad de que una losa lisa de la banqueta sea una variante (registro, grieta).
@export_range(0.0, 1.0) var sidewalk_variant_chance: float = 0.08
## Probabilidad de que un tile de azotea tenga algo encima.
@export_range(0.0, 1.0) var roof_item_chance: float = 0.15
## Probabilidad de un árbol suelto en el pasto o el cerro del fondo.
@export_range(0.0, 1.0) var backfill_tree_chance: float = 0.06

var theme: LevelTheme
## Raíz de todo lo que pone el dresser (hermano de Ground, antes de Decor y Rules).
var city: Node2D
## Fila de arriba y de abajo de la franja de la calle (banquetas incluidas).
var street_top: int = 0
var street_bottom: int = 0

var _rng := RandomNumberGenerator.new()
var _ground: TileMapLayer
var _reserved: Array[Rect2] = []
var _calm_x: Array[float] = []


func _ready() -> void:
	# El nivel todavía está armando sus hijos: se viste al final del frame (antes de dibujar).
	_dress.call_deferred()


func _dress() -> void:
	var level := get_parent() as Node2D
	if level == null:
		return
	theme = _load_theme(level.scene_file_path)
	if theme == null or not theme.enabled:
		return
	_ground = level.get_node_or_null(^"Ground") as TileMapLayer
	if _ground == null or not _find_street_rows():
		return
	_rng.seed = theme.seed_value
	city = Node2D.new()
	city.name = "CityDecor"
	level.add_child(city)
	level.move_child(city, _ground.get_index() + 1)
	_hide_old_decor(level)
	_collect_reserved(level)
	_paint_ground()
	var lots := _add_layer("Lots")
	var trees := _add_layer("Trees")
	if not theme.no_lots:
		for side: int in [-1, 1]:
			_place_lots(side, lots, trees)
	_place_backfill_trees(trees)
	_place_sidewalk_trees(_add_layer("Sidewalk"))
	_place_destination(level)
	_apply_tint(level)


## data/themes/theme_XX.tres para levels/level_XX.tscn; null si no hay.
func _load_theme(scene_path: String) -> LevelTheme:
	var base := scene_path.get_file().get_basename()
	if not base.begins_with("level_"):
		return null
	var path := "%s/theme_%s.tres" % [themes_dir, base.trim_prefix("level_")]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as LevelTheme


func _find_street_rows() -> bool:
	var used := _ground.get_used_rect()
	var column := used.position.x + 1
	var rows: Array[int] = []
	for y in range(used.position.y, used.end.y):
		if _ground.get_cell_atlas_coords(Vector2i(column, y)) in STREET_TILES:
			rows.append(y)
	if rows.is_empty():
		return false
	street_top = rows.min()
	street_bottom = rows.max()
	return true


func _add_layer(layer_name: String) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	city.add_child(layer)
	return layer


func _hide_old_decor(level: Node) -> void:
	var decor := level.get_node_or_null(^"Decor")
	if decor == null:
		return
	for node_name in theme.hide_decor:
		var node := decor.get_node_or_null(NodePath(node_name)) as CanvasItem
		if node != null:
			node.visible = false


## Lo que el dresser no puede tapar: los sprites de Decor (destinos, túnel) y las
## calles que cruzan (BlindCrossing, YellowCrossing). Más los x de calma de Rules.
func _collect_reserved(level: Node) -> void:
	for sprite in _decor_sprites(level):
		_reserved.append(_sprite_rect(sprite).grow(8.0))
	var rules := level.get_node_or_null(^"Rules")
	if rules == null:
		return
	for piece in rules.get_children():
		if not piece is Node2D:
			continue
		var x: float = (piece as Node2D).global_position.x
		_calm_x.append(x)
		if piece.has_method(&"careful_stop_x"):
			_calm_x.append(piece.call(&"careful_stop_x"))
		if "cross_width" in piece:
			var width: float = piece.get(&"cross_width")
			var center := x + (float(piece.get(&"line_gap")) + width / 2.0 if "line_gap" in piece else 0.0)
			var half := width / 2.0 + TILE * 2.0 + 16.0
			_reserved.append(Rect2(center - half, -100000.0, half * 2.0, 200000.0))


func _decor_sprites(level: Node) -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	var decor := level.get_node_or_null(^"Decor")
	if decor == null:
		return out
	for child in decor.get_children():
		if child is Sprite2D and (child as Sprite2D).visible:
			out.append(child)
	return out


func _sprite_rect(sprite: Sprite2D) -> Rect2:
	return sprite.get_global_transform() * sprite.get_rect()


func _is_reserved(rect: Rect2) -> bool:
	for r in _reserved:
		if r.intersects(rect):
			return true
	return false


func _is_calm(x: float) -> bool:
	for cx in _calm_x:
		if absf(cx - x) < theme.calm_radius:
			return true
	return false


## Losa bajo los lotes y azoteas detrás (ciudad), o pasto y cerro. La franja de la calle no se toca,
## salvo algunas losas lisas de la banqueta que pasan a variante.
func _paint_ground() -> void:
	var used := _ground.get_used_rect()
	for x in range(used.position.x, used.end.x):
		for y in range(used.position.y, used.end.y):
			var cell := Vector2i(x, y)
			if y >= street_top and y <= street_bottom:
				if (y == street_top or y == street_bottom) \
						and _ground.get_cell_atlas_coords(cell) == SIDEWALK_PLAIN \
						and _rng.randf() < sidewalk_variant_chance:
					_ground.set_cell(cell, 0, SIDEWALK_VARIANTS[_rng.randi() % SIDEWALK_VARIANTS.size()])
				continue
			var depth := street_top - y if y < street_top else y - street_bottom
			var cell_rect := Rect2(x * TILE, y * TILE, TILE, TILE)
			var tile: Vector2i
			if theme.backfill == LevelTheme.Backfill.HILL:
				tile = HILL_TILES[_rng.randi() % HILL_TILES.size()]
			elif theme.backfill == LevelTheme.Backfill.ROOFS and not _is_reserved(cell_rect):
				# En la ciudad el piso de los lotes es losa (sin franja de pasto bajo las fachadas).
				tile = _roof_tile(x, depth if y > street_bottom else -depth) if depth > 2 else SIDEWALK_PLAIN
			else:
				tile = GRASS_TILES[_rng.randi() % GRASS_TILES.size()]
			_ground.set_cell(cell, 0, tile)


func _roof_tile(x: int, depth: int) -> Vector2i:
	if _rng.randf() < roof_item_chance:
		return ROOF_ITEMS[_rng.randi() % ROOF_ITEMS.size()]
	var block := Vector2i(floori(x / float(ROOF_BLOCK.x)), floori(depth / float(ROOF_BLOCK.y)))
	return ROOF_PLAIN[absi(hash([theme.seed_value, block])) % ROOF_PLAIN.size()]


## Manzana continua a un lado de la calle (side -1 arriba, 1 abajo): lotes pegados a
## la banqueta, sin repetir el mismo dos veces seguidas, con huecos de árbol de vez en cuando.
func _place_lots(side: int, lots: Node2D, trees: Node2D) -> void:
	var used := _ground.get_used_rect()
	var x := float(used.position.x * TILE)
	var end := float(used.end.x * TILE)
	var last := -1
	while x < end:
		if _rng.randf() < theme.gap_chance:
			_add_tree(trees, Vector2(x, _lot_edge(side) + (-TILE - _rng.randf_range(0.0, 24.0) if side < 0 else _rng.randf_range(0.0, 24.0))))
			x += TILE
			continue
		var index := _pick_lot(last)
		if index < 0:
			return
		var region: Rect2 = LOTS[index]["rect"]
		var pos := Vector2(x, _lot_edge(side) - region.size.y if side < 0 else _lot_edge(side))
		if _is_reserved(Rect2(pos, region.size)):
			x += TILE
			continue
		var sprite := _make_sprite(LOTS[index]["tex"], region, pos)
		var shade := 1.0 - _rng.randf() * lot_shade_jitter
		sprite.modulate = Color(shade, shade, shade)
		lots.add_child(sprite)
		last = index
		x += region.size.x


## y de la orilla de afuera de la banqueta, donde se pegan las fachadas.
func _lot_edge(side: int) -> float:
	return float(street_top * TILE) if side < 0 else float((street_bottom + 1) * TILE)


func _pick_lot(last: int) -> int:
	var total := 0.0
	for i in theme.lot_weights.size():
		if i != last:
			total += theme.lot_weights[i]
	if total <= 0.0:
		return last if last >= 0 and theme.lot_weights[last] > 0.0 else -1
	var roll := _rng.randf() * total
	for i in theme.lot_weights.size():
		if i == last:
			continue
		roll -= theme.lot_weights[i]
		if roll <= 0.0:
			return i
	return theme.lot_weights.size() - 1


## Árboles sueltos en el pasto del fondo (colonia) o en el cerro (nivel 7).
func _place_backfill_trees(trees: Node2D) -> void:
	if theme.backfill == LevelTheme.Backfill.ROOFS:
		return
	var used := _ground.get_used_rect()
	var first_depth := 1 if theme.no_lots else 3
	for x in range(used.position.x, used.end.x):
		for y in range(used.position.y, used.end.y):
			var depth := street_top - y if y < street_top else y - street_bottom
			if y >= street_top and y <= street_bottom or depth < first_depth:
				continue
			if _rng.randf() < backfill_tree_chance:
				_add_tree(trees, Vector2(x * TILE, y * TILE))


## Un árbol (o maceta) cada sidewalk_tree_every tiles en la losa de afuera de cada banqueta.
func _place_sidewalk_trees(layer: Node2D) -> void:
	if theme.sidewalk_tree_every <= 0:
		return
	var used := _ground.get_used_rect()
	var step := theme.sidewalk_tree_every
	for side: int in [-1, 1]:
		var row := street_top if side < 0 else street_bottom
		var offset := _rng.randi_range(0, step - 1)
		for tx in range(used.position.x + offset, used.end.x, step):
			var pos := Vector2(tx * TILE, row * TILE + (-10.0 if side < 0 else 10.0))
			if _is_calm(pos.x + TILE / 2.0):
				continue
			_add_tree(layer, pos)


func _add_tree(layer: Node2D, pos: Vector2) -> void:
	if theme.tree_kinds.is_empty():
		return
	var rect := Rect2(pos, Vector2(TILE, TILE))
	if _is_reserved(rect):
		return
	var kind: int = theme.tree_kinds[_rng.randi() % theme.tree_kinds.size()]
	layer.add_child(_make_sprite(ARBOLES, Rect2(kind * TILE, 0, TILE, TILE), pos))


func _make_sprite(texture: Texture2D, region: Rect2, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.position = pos
	return sprite


## Ícono del destino flotando sobre su edificio, para que se vea sin leer el HUD.
func _place_destination(level: Node) -> void:
	if theme.destination_icon == LevelTheme.Icon.NONE:
		return
	var sprites := _decor_sprites(level)
	var chosen: Array[Sprite2D] = []
	if theme.destination_nodes.has("*"):
		chosen = sprites
	elif theme.destination_nodes.is_empty():
		var best: Sprite2D = null
		for sprite in sprites:
			if best == null or sprite.global_position.x > best.global_position.x:
				best = sprite
		if best != null:
			chosen.append(best)
	else:
		for sprite in sprites:
			if theme.destination_nodes.has(String(sprite.name)):
				chosen.append(sprite)
	if chosen.is_empty():
		return
	var area := _sprite_rect(chosen[0])
	for sprite in chosen:
		area = area.merge(_sprite_rect(sprite))
	var marker := Node2D.new()
	marker.set_script(DestinationMarkerScript)
	marker.name = "DestinationMarker"
	marker.set(&"icon", theme.destination_icon)
	marker.position = Vector2(area.get_center().x, area.position.y + 28.0)
	_add_layer("Destination").add_child(marker)


func _apply_tint(level: Node) -> void:
	if theme.tint == Color.WHITE:
		return
	for child in level.get_children():
		if child is CanvasModulate:
			return
	var modulate := CanvasModulate.new()
	modulate.name = "TimeOfDay"
	modulate.color = theme.tint
	level.add_child(modulate)
