extends TestCase
## Luces del auto (nivel 7): set_headlights, la acción car_lights, el cono de luz
## y el botón del HUD, que solo aparece si el nivel pone show_lights_button.


func run() -> void:
	var level := await open_scene("res://levels/test_street.tscn")
	var rm := level.get_node("RuleManager") as RuleManager
	var car := rm.car
	var hud := level.get_node("Hud") as Hud
	var button := hud.get_node("%Lights") as TouchScreenButton
	var cone := car.get_node("HeadlightCone") as Node2D
	var changes: Array = []
	car.headlights_changed.connect(func(on: bool) -> void: changes.append(on))

	check(not car.headlights_on and not cone.visible, "las luces empiezan apagadas y sin cono")
	check(not hud.show_lights_button and not button.visible, "sin pedirlo el nivel, el HUD no muestra el botón de luces")
	check(button.action == "car_lights", "el botón de luces usa la acción car_lights")

	car.set_headlights(true)
	car.set_headlights(true)
	check(car.headlights_on and cone.visible and changes == [true], "set_headlights(true) las prende y avisa una sola vez")
	check(button.modulate != Color.WHITE, "el botón se pinta mientras están prendidas")
	car.restart_at(500.0)
	check(car.headlights_on, "regresar a un punto de control no apaga las luces")
	await tap(&"car_lights")
	check(not car.headlights_on and not cone.visible and changes == [true, false], "la acción car_lights las apaga")
	await tap(&"car_lights")
	check(car.headlights_on and changes == [true, false, true], "y las vuelve a prender")
	car.set_headlights(false)
	await close_scene(level)

	# Un nivel que pide el botón: show_lights_button = true en su Hud.
	var packed := load("res://levels/test_street.tscn") as PackedScene
	var lit := packed.instantiate()
	(lit.get_node("Hud") as Hud).show_lights_button = true
	get_tree().root.add_child(lit)
	await frames(1)
	var lit_hud := lit.get_node("Hud") as Hud
	var lit_car := (lit.get_node("RuleManager") as RuleManager).car
	check(lit.get_node("Hud/%Lights").visible, "con show_lights_button el HUD muestra el botón de luces")
	check(lit_hud.is_lights_pulsing(), "el botón de luces parpadea hasta que las prenden la primera vez")
	lit_car.set_headlights(true)
	await frames(2)
	check(not lit_hud.is_lights_pulsing(), "con las luces prendidas deja de parpadear")
	lit_car.set_headlights(false)
	await frames(2)
	check(not lit_hud.is_lights_pulsing(), "apagadas fuera de una zona oscura ya no parpadea")
	# Zona que pide luces: cualquier nodo del grupo needs_headlights con is_car_inside().
	var zone := Node.new()
	var zone_script := GDScript.new()
	zone_script.source_code = "extends Node\nvar inside := true\nfunc is_car_inside() -> bool:\n\treturn inside\n"
	zone_script.reload()
	zone.set_script(zone_script)
	zone.add_to_group(&"needs_headlights")
	lit.add_child(zone)
	await frames(2)
	check(lit_hud.is_lights_pulsing(), "dentro de una zona que pide luces, apagadas, parpadea otra vez")
	lit_car.set_headlights(true)
	await frames(2)
	check(not lit_hud.is_lights_pulsing(), "al prenderlas en la zona deja de parpadear")
	lit_car.set_headlights(false)
	zone.set(&"inside", false)
	await frames(2)
	check(not lit_hud.is_lights_pulsing() and lit.get_node("Hud/%Lights").modulate.a == 1.0, "al salir de la zona deja de parpadear")
	await close_scene(lit)
