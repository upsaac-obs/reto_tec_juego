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
		_check_walkers(id, dresser, city, half_road)
		if dresser.theme.destination_icon != LevelTheme.Icon.NONE:
			var marker := city.get_node_or_null(^"Destination/DestinationMarker") as Node2D
			var end_x := route.curve.get_point_position(route.curve.point_count - 1).x
			check(marker != null and marker.global_position.x > end_x * 0.5, "  nivel %d: el destino tiene su ícono en la segunda mitad del camino" % id)
		await close_scene(level)


## Gente de la banqueta: las que pide el tema, siempre en la banqueta (ni el dibujo
## pisa los carriles) y nunca visibles dentro de una zona de cruce, también tras caminar.
func _check_walkers(id: int, dresser: CityDresser, city: Node2D, half_road: float) -> void:
	var layer := city.get_node_or_null(^"Walkers") as SidewalkWalkers
	var expected := dresser.theme.sidewalk_walkers
	if expected <= 0:
		check(layer == null, "  nivel %d: sin gente en la banqueta" % id)
		return
	check(layer != null and layer.get_child_count() == expected, "  nivel %d: %d personas en la banqueta" % [id, expected])
	if layer == null:
		return
	var bad_road := 0
	var bad_zone := 0
	for step in 3:
		for walker: AnimatedSprite2D in layer.get_children():
			# El dibujo ocupa el 80 % de alto del cuadro, apoyado abajo (tools/art/integrar_v2.py).
			var feet := walker.global_position.y
			var head := feet - walker.sprite_frames.get_frame_texture(&"walk", 0).get_height() * 0.8
			if feet > -half_road and head < half_road:
				bad_road += 1
			if walker.visible and layer.is_avoided(walker.global_position.x):
				bad_zone += 1
		# Un segundo de caminata cada vez, sin esperar en tiempo real.
		layer._process(1.0)
	check(bad_road == 0, "  nivel %d: la gente de la banqueta no pisa los carriles" % id)
	check(bad_zone == 0, "  nivel %d: la gente de la banqueta no entra a los cruces" % id)


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child in node.get_children():
		out.append(child)
		out.append_array(_descendants(child))
	return out
