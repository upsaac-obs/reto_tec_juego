extends Node
## Pausa el juego 2 segundos, muestra al copiloto con el texto y reproduce
## assets/audio/voz/<CLAVE>.ogg si existe. Se implementa en la tarea Feedback.


func _init() -> void:
	# Tiene que seguir corriendo mientras el árbol está en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
