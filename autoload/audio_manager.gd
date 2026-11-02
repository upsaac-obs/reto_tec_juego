extends Node
## Reproduce música, efectos cortos y efectos en bucle (motor, direccional, lluvia).
##
## Silencio: BridgeClient silencia el bus Master (set_muted del nativo). Todo lo
## de aquí sale por los buses "Musica" y "Efectos", que mandan a Master, así que
## el silencio ya se respeta sin revisar nada aquí.
##
## Los archivos se generan con tools/gen_sfx.py y tools/gen_music.py.
## API:
##   play_sfx(&"horn")                 efecto corto (sigue sonando en pausa)
##   start_loop(&"engine") / stop_loop(&"engine") / stop_all_loops()
##   set_loop_pitch(&"engine", 1.3)    p. ej. el motor según la velocidad
##   play_music() / stop_music()       música del nivel en bucle
##   set_music_enabled(false)          apaga solo la música

const SFX_PATH := "res://assets/audio/sfx/%s.wav"
const MUSIC_LEVEL := "res://assets/audio/musica/nivel.ogg"
const MUSIC_MENU_JINGLE := "res://assets/audio/musica/menu_jingle.ogg"
const BUS_MUSIC := &"Musica"
const BUS_SFX := &"Efectos"
## Nombre del bucle → archivo en assets/audio/sfx/.
const LOOPS := {
	&"engine": &"engine_loop",
	&"turn_signal": &"turn_signal_loop",
	&"rain": &"rain_loop",
}

## Volumen de la música (bajito para que la voz del copiloto se entienda).
@export var music_volume_db: float = -14.0
## Volumen de los efectos.
@export var sfx_volume_db: float = -4.0
## Volumen de cada bucle (el motor suena todo el nivel: va más bajo).
@export var loop_volume_db := {&"engine": -12.0, &"turn_signal": -8.0, &"rain": -10.0}
## Cuántos efectos cortos pueden sonar a la vez.
@export var sfx_channels: int = 6
## Segundos de fundido al empezar o parar la música.
@export var music_fade: float = 0.6

var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx: int = 0
var _loops: Dictionary[StringName, AudioStreamPlayer] = {}
var _music: AudioStreamPlayer
var _music_tween: Tween
var _cache: Dictionary[StringName, AudioStream] = {}


func _init() -> void:
	# Los efectos cortos y la música siguen en pausa (la falta pausa 2 s y
	# suena el "uy"). Los bucles sí se pausan: ver start_loop().
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_ensure_bus(BUS_MUSIC, music_volume_db)
	_ensure_bus(BUS_SFX, sfx_volume_db)
	for i in sfx_channels:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = BUS_MUSIC
	add_child(_music)
	# Los bucles y la música del nivel los apaga BridgeClient con
	# stop_level_audio() ANTES de cambiar de escena. No se usa scene_changed:
	# llega después del _ready del nivel nuevo y apagaría el motor recién prendido.


# --- Efectos cortos -----------------------------------------------------------

## Efectos: brake, horn, celebration, fault, phone_ring, phone_vibrate,
## lights_on, door_open, bus_stop, coin, good.
func play_sfx(sfx_name: StringName, volume_db := 0.0, pitch := 1.0) -> void:
	var stream := _sfx_stream(sfx_name)
	if stream == null:
		return
	var p := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


# --- Bucles -------------------------------------------------------------------

## Empieza un bucle (engine, turn_signal o rain). Si ya suena, no hace nada.
## Se pausa solo cuando el árbol está en pausa.
func start_loop(loop_name: StringName, pitch := 1.0) -> void:
	if is_loop_playing(loop_name):
		return
	if not LOOPS.has(loop_name):
		push_warning("AudioManager: no hay bucle '%s'" % loop_name)
		return
	var stream := _sfx_stream(LOOPS[loop_name])
	if stream == null:
		return
	var p: AudioStreamPlayer = _loops.get(loop_name)
	if p == null:
		p = AudioStreamPlayer.new()
		p.bus = BUS_SFX
		p.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(p)
		_loops[loop_name] = p
	p.stream = _as_loop(stream)
	p.volume_db = loop_volume_db.get(loop_name, 0.0)
	p.pitch_scale = pitch
	p.play()


func stop_loop(loop_name: StringName) -> void:
	var p: AudioStreamPlayer = _loops.get(loop_name)
	if p:
		p.stop()


func stop_all_loops() -> void:
	for p: AudioStreamPlayer in _loops.values():
		p.stop()


func is_loop_playing(loop_name: StringName) -> bool:
	var p: AudioStreamPlayer = _loops.get(loop_name)
	return p != null and p.playing


## Cambia el tono de un bucle que ya suena (el motor sube con la velocidad).
func set_loop_pitch(loop_name: StringName, pitch: float) -> void:
	var p: AudioStreamPlayer = _loops.get(loop_name)
	if p:
		p.pitch_scale = clampf(pitch, 0.5, 2.0)


# --- Música -------------------------------------------------------------------

## Pone una música (por defecto la del nivel). Si ya suena esa misma, la deja.
func play_music(path := MUSIC_LEVEL, loop := true) -> void:
	if _music.playing and _music.stream and _music.stream.resource_path == path:
		return
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: no existe la música %s" % path)
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop
	_kill_music_tween()
	_music.stream = stream
	_music.volume_db = -40.0
	_music.play()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", 0.0, music_fade)


func stop_music() -> void:
	if not _music.playing:
		return
	_kill_music_tween()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", -40.0, music_fade)
	_music_tween.tween_callback(_music.stop)


## Al salir de un nivel (o antes de cargar otro): silencio inmediato, sin
## desvanecer, para que la música del siguiente nivel arranque limpia.
func stop_level_audio() -> void:
	stop_all_loops()
	_kill_music_tween()
	_music.stop()
	_music.stream_paused = false


## La app pasó a segundo plano o abrió Tutores: la música se detiene donde va
## (los efectos y bucles ya se pausan con el árbol).
func set_paused(paused: bool) -> void:
	_music.stream_paused = paused


func is_music_playing() -> bool:
	return _music.playing


## Ajuste "Música" de los tutores: apaga solo la música (el resto sigue).
func set_music_enabled(enabled: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_MUSIC), not enabled)


# --- Internos -----------------------------------------------------------------

func _sfx_stream(file_name: StringName) -> AudioStream:
	if _cache.has(file_name):
		return _cache[file_name]
	var path := SFX_PATH % file_name
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: no existe el efecto %s" % path)
		return null
	var stream: AudioStream = load(path)
	_cache[file_name] = stream
	return stream


## Los .wav de bucle traen el punto de bucle en el archivo; por si alguien los
## reimporta sin él, aquí se fuerza el bucle completo.
func _as_loop(stream: AudioStream) -> AudioStream:
	var wav := stream as AudioStreamWAV
	if wav == null or wav.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		return stream
	var copy := wav.duplicate() as AudioStreamWAV
	copy.loop_mode = AudioStreamWAV.LOOP_FORWARD
	copy.loop_begin = 0
	copy.loop_end = roundi(wav.get_length() * wav.mix_rate)
	return copy


func _ensure_bus(bus_name: StringName, volume_db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, &"Master")
	AudioServer.set_bus_volume_db(idx, volume_db)


func _kill_music_tween() -> void:
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
