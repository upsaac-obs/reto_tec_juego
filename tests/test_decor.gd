extends TestCase
## Decorado de la ciudad (CityDresser, docs/plan_visual.md): solo adorna. No tiene
## colisiones ni grupos, no pisa los carriles, deja libre la zona de cada pieza de
## Rules y pone el ícono del destino. Recorre los niveles 0 a 8.

## Presupuesto de sprites del decorado por nivel (A15).
const MAX_SPRITES := 320


func run() -> void:
	for id in range(9):
		var path := "res://levels/level_%02d.tscn" % id
		var level := await open_scene(path)
		await frames(2)
		var dresser := level.get_node_or_null(^"CityDresser") as CityDresser
		var city := level.get_node_or_null(^"CityDecor") as Node2D
		check(dresser != null and dresser.theme != null and city != null, "nivel %d: CityDresser viste la ciudad" % id)
		if city == null:
			await close_scene(level)
			continue
		var sprites: Array[Sprite2D] = []
		var clean := true
		for node in _descendants(city):
			if node is CollisionObject2D or not node.get_groups().is_empty():
				clean = false
			if node is Sprite2D:
				sprites.append(node)
		check(clean, "  nivel %d: el decorado no tiene colisiones ni grupos" % id)
		check(sprites.size() <= MAX_SPRITES, "  nivel %d: %d sprites de decorado (máximo %d)" % [id, sprites.size(), MAX_SPRITES])
		var route := level.get_node(^"Route") as DrivingRoute
		var half_road := route.default_lane_count * 32.0
		var on_road := 0
		for sprite in sprites:
			var rect := sprite.get_global_transform() * sprite.get_rect()
			if rect.end.y > -half_road + 1.0 and rect.position.y < half_road - 1.0:
				on_road += 1
		check(on_road == 0, "  nivel %d: nada del decorado pisa los carriles" % id)
		var calm_x: Array[float] = []
		for piece in level.get_node(^"Rules").get_children():
			if piece is Node2D:
				calm_x.append((piece as Node2D).global_position.x)
		var too_close := 0
		var sidewalk := city.get_node_or_null(^"Sidewalk")
		if sidewalk != null:
			for sprite: Sprite2D in sidewalk.get_children():
				var center_x := (sprite.get_global_transform() * sprite.get_rect()).get_center().x
				for x in calm_x:
					if absf(center_x - x) < dresser.theme.calm_radius:
						too_close += 1
		check(too_close == 0, "  nivel %d: nada en la banqueta cerca de una pieza de Rules" % id)
		if dresser.theme.destination_icon != LevelTheme.Icon.NONE:
			var marker := city.get_node_or_null(^"Destination/DestinationMarker") as Node2D
			var end_x := route.curve.get_point_position(route.curve.point_count - 1).x
			check(marker != null and marker.global_position.x > end_x * 0.5, "  nivel %d: el destino tiene su ícono en la segunda mitad del camino" % id)
		await close_scene(level)


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_descendants(child))
	return out
