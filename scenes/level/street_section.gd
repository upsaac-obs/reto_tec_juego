@tool
class_name StreetSection
extends Node2D
## Marca dónde cambia el número de carriles. Se coloca como hijo de DrivingRoute;
## desde este punto en adelante la calle tiene lane_count carriles.

@export_range(1, 4) var lane_count: int = 2:
	set(value):
		lane_count = value
		if get_parent() is CanvasItem:
			(get_parent() as CanvasItem).queue_redraw()
