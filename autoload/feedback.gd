extends Node
## Mensajes del copiloto. Tres tipos:
## - show_infraction: pausa el juego con el copiloto asustado. La pausa dura
##   pause_time o, si la clave tiene voz, lo que dure la voz más voice_margin (lo
##   que sea mayor); el mensaje se queda al menos lo mismo.
## - show_good_action: copiloto feliz, sonido alegre y "+10". No pausa.
## - show_info: el copiloto habla (instrucciones como el cinturón). No pausa.
## Siempre reproduce assets/audio/voz/<CLAVE>.ogg si existe.

const BUBBLE_SCENE := preload("res://scenes/ui/copilot_bubble.tscn")
const GOOD_SOUND := preload("res://assets/audio/sfx/good.wav")
const VOICE_PATH := "res://assets/audio/voz/%s.ogg"

## Empezó a sonar una voz del copiloto (para que AudioManager baje la música, por ejemplo).
signal voice_played(message_key: String, length: float)

## Segundos que el juego queda en pausa después de una falta.
@export var pause_time: float = 2.0
## Segundos que el mensaje queda en pantalla.
@export var message_time: float = 2.5
## Segundos extra después de la voz antes de quitar la pausa de una falta.
@export var voice_margin: float = 0.3

var _bubble: CopilotBubble
var _voice: AudioStreamPlayer
var _sfx: AudioStreamPlayer
## Cada mensaje nuevo invalida el temporizador del anterior.
var _message_id: int = 0
## Igual para la pausa: clear() la suelta sin despausar.
var _pause_id: int = 0
var _pausing: bool = false
## Voces ya buscadas: clave → AudioStream (o null si no hay archivo).
var _voices: Dictionary = {}


func _init() -> void:
	# Tiene que seguir corriendo mientras el árbol está en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_bubble = BUBBLE_SCENE.instantiate()
	add_child(_bubble)
	_voice = AudioStreamPlayer.new()
	add_child(_voice)
	_sfx = AudioStreamPlayer.new()
	_sfx.stream = GOOD_SOUND
	add_child(_sfx)


func show_infraction(message_key: String) -> void:
	var hold := infraction_pause_time(message_key)
	_show(message_key, CopilotBubble.Mood.BAD, maxf(message_time, hold))
	_pause_game(hold)


## Segundos que pausa una falta con esta clave: pause_time, o la voz más
## voice_margin si dura más.
func infraction_pause_time(message_key: String) -> float:
	var voice := _voice_for(message_key)
	if voice == null:
		return pause_time
	return maxf(pause_time, voice.get_length() + voice_margin)


func show_good_action(message_key: String, points := 10) -> void:
	_show(message_key, CopilotBubble.Mood.GOOD)
	_sfx.play()
	if points > 0:
		_bubble.pop_points(points)


func show_info(message_key: String) -> void:
	_show(message_key, CopilotBubble.Mood.INFO)


## Quita el mensaje al instante (al cambiar de escena o al abrir el menú de
## pausa). Si había una pausa por falta, la deja como está y ya no la quita.
func clear() -> void:
	_message_id += 1
	_pause_id += 1
	_pausing = false
	_bubble.hide_message()
	_voice.stop()


## true mientras dura la pausa de una falta (la quita él solo).
func is_pausing() -> bool:
	return _pausing


func _show(message_key: String, mood: CopilotBubble.Mood, duration := -1.0) -> void:
	_message_id += 1
	var id := _message_id
	_bubble.show_message(tr(message_key), mood)
	play_voice(message_key)
	await get_tree().create_timer(duration if duration > 0.0 else message_time).timeout
	if id == _message_id:
		_bubble.hide_message()


## Reproduce assets/audio/voz/<CLAVE>.ogg si existe (también la usa la tarjeta de hábito).
func play_voice(message_key: String) -> void:
	_voice.stop()
	var voice := _voice_for(message_key)
	if voice != null:
		_voice.stream = voice
		_voice.play()
		voice_played.emit(message_key, voice.get_length())


func _voice_for(message_key: String) -> AudioStream:
	if not _voices.has(message_key):
		var path := VOICE_PATH % message_key
		_voices[message_key] = load(path) as AudioStream if ResourceLoader.exists(path) else null
	return _voices[message_key]


## Solo quita la pausa que puso él.
func _pause_game(duration: float) -> void:
	if _pausing or get_tree().paused:
		return
	_pause_id += 1
	var id := _pause_id
	_pausing = true
	get_tree().paused = true
	await get_tree().create_timer(duration).timeout
	if id == _pause_id:
		get_tree().paused = false
		_pausing = false
