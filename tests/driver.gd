class_name TestDriver
extends Node
## "Conductor" para las pruebas: mantiene una velocidad objetivo pisando y
## soltando los pedales de verdad (acciones car_accelerate y car_brake).

var car: PlayerCar
## px/s; negativo = no tocar los pedales.
var target: float = -1.0
## A partir de esta distancia sobre la ruta frena hasta detenerse.
var brake_after: float = INF


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(_delta: float) -> void:
	if car == null or target < 0.0 or get_tree().paused:
		return
	var stop := car.progress >= brake_after
	_set(&"car_accelerate", not stop and car.speed < target)
	_set(&"car_brake", stop or car.speed > target + 8.0)


func stop_driving() -> void:
	target = -1.0
	_set(&"car_accelerate", false)
	_set(&"car_brake", false)


func _set(action: StringName, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)
