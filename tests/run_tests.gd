extends Node
## Escena de entrada de las pruebas (tests/run_tests.tscn). Las pruebas cambian
## de escena (el puente vuelve a idle.tscn), y eso libera esta escena; por eso
## las pruebas corren en un nodo aparte colgado de la raíz (tests/test_runner.gd).


func _ready() -> void:
	var runner := Node.new()
	runner.name = "TestRunner"
	runner.set_script(load("res://tests/test_runner.gd"))
	get_tree().root.add_child.call_deferred(runner)
