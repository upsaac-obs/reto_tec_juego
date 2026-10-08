class_name LevelData
extends Resource
## Datos de un nivel. Un archivo por nivel en data/level_XX.tres, donde XX es el
## id: el nativo abre los niveles por id (start_level), así que el nombre importa.
## La voz de la frase final sale de assets/audio/voz/<phrase_key>.ogg (Feedback).

const PATH := "res://data/level_%02d.tres"
## Niveles 0 (tutorial) a 10, y el 99: nivel de prueba del puente.
const IDS: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 99]

@export var id: int
@export var name_key: String
## Punto del decálogo. Vacío en el tutorial y en el nivel de prueba.
@export var decalogo_key: String
## Frase final de la tarjeta de hábito.
@export var phrase_key: String
## Vacío mientras el equipo no decida el destino; el HUD lo oculta.
@export var destination_key: String
@export var illustration: Texture2D
## Vacío mientras el nivel no está construido. Es una ruta y no un PackedScene
## para no cargar todos los niveles al leer sus datos.
@export_file("*.tscn") var scene_path: String


static func load_by_id(level_id: int) -> LevelData:
	var path := PATH % level_id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as LevelData


static func find_by_scene(path: String) -> LevelData:
	for level_id in IDS:
		var data := load_by_id(level_id)
		if data != null and data.scene_path == path:
			return data
	return null


## Datos del nivel al que pertenece node (por ejemplo el HUD o la tarjeta de
## hábito dentro del nivel). Funciona igual si el nivel lo abrió el nativo o F6.
static func of(node: Node) -> LevelData:
	var path := node.owner.scene_file_path if node.owner != null else ""
	if GameState.level != null and GameState.level.scene_path == path:
		return GameState.level
	return find_by_scene(path)


func is_built() -> bool:
	return not scene_path.is_empty() and ResourceLoader.exists(scene_path)
