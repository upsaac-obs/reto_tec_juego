# Creación y desarrollo: Dylan Isaac Mancilla López
class_name Vehicles
## Vehículos del garaje (docs/arte_v2/codex/lotes/11_garaje.md). El nativo elige uno
## y lo manda en start_level ("vehicle"); aquí solo se cambia cómo se ve el auto del
## jugador. Los precios y la compra viven en las apps nativas.
## Todos los autos tienen la huella del auto rojo (69 × 41) y usan sus luces; la moto
## es más angosta y en ella el casco ocupa el lugar del cinturón.

const DEFAULT := "clasico"
const MOTO := "moto"
const IDS: Array[String] = ["clasico", "burbuja", "todoterreno", "convertible", "deportivo", "futuro", "moto"]
const TEXTURE_PATH := "res://assets/sprites/garage/car_%s.png"


static func is_valid(id: String) -> bool:
	return IDS.has(id)


static func uses_helmet(id: String) -> bool:
	return id == MOTO


## Pone el sprite (y en la moto, sus luces) del vehículo id en el auto del jugador.
## El clásico, o un id desconocido, deja el auto como está en la escena.
static func apply(car: PlayerCar, id: String) -> void:
	if id == DEFAULT or not is_valid(id):
		return
	var texture := load(TEXTURE_PATH % id) as Texture2D
	car.texture = texture
	car.texture_offset = -texture.get_size() / 2.0
	if id == MOTO:
		# Medidas sacadas de garaje_moto.png reducida a 66 × 34 (frente hacia +x).
		car.brake_lights = [Rect2(-32.0, -2.0, 3.0, 4.0)]
		car.headlight_lamps = [Rect2(29.0, -3.0, 4.0, 6.0)]
		car.headlight_origin = Vector2(31.0, 0.0)
		car.left_signal_lights = [Rect2(24.0, -9.0, 5.0, 3.0), Rect2(-27.0, -9.0, 5.0, 3.0)]
		car.right_signal_lights = [Rect2(24.0, 6.0, 5.0, 3.0), Rect2(-27.0, 6.0, 5.0, 3.0)]
