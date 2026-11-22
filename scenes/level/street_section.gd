# Creación y desarrollo: Dylan Isaac Mancilla López, Angel Mael Vera Carpio
@tool
class_name StreetSection
extends Node2D
## Marca dónde cambia el número de carriles. Se coloca como hijo de DrivingRoute;
## desde este punto en adelante la calle tiene lane_count carriles.
## lane_shift mueve de lado todos los carriles de la sección, en px: positivo es
## hacia la derecha del auto y negativo hacia la izquierda. Sirve para alinear un
## carril único con uno de los carriles dibujados en el suelo (nivel 5: -32 lo
## pone en el carril izquierdo, lejos de los autos estacionados).

@export_range(1, 4) var lane_count: int = 2:
	set(value):
		lane_count = value
		if get_parent() is CanvasItem:
			(get_parent() as CanvasItem).queue_redraw()
@export var lane_shift: float = 0.0:
	set(value):
		lane_shift = value
		if get_parent() is CanvasItem:
			(get_parent() as CanvasItem).queue_redraw()
