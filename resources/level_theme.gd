class_name LevelTheme
extends Resource
## Cómo se viste la ciudad de un nivel (docs/plan_visual.md). Lo lee CityDresser
## desde data/themes/theme_XX.tres, con el mismo número que levels/level_XX.tscn.
## Solo es decoración: no cambia reglas, piezas ni la ruta.

enum Backfill { ROOFS, GRASS, HILL }
enum Icon { NONE, TREE, BOOK, FRUIT, HOUSE, BELL, CROSS, BUS }

## Apaga todo el decorado de este nivel (respaldo si algo se ve mal).
@export var enabled: bool = true
## Semilla propia del decorado: no mueve el aleatorio de las piezas.
@export var seed_value: int = 1
@export_group("Manzanas")
## Peso de cada lote: casas 1-4 de casas.png, edificios 1-3, casas 5-6, edificios 4-6 y
## casas 7-12 (lote 09).
## 0 = ese lote no sale en este nivel.
@export var lot_weights: Array[float] = [1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
## Probabilidad de dejar un hueco de un tile con árbol entre dos lotes.
@export_range(0.0, 1.0) var gap_chance: float = 0.15
## Sin lotes (por ejemplo, el cerro del nivel 7): solo árboles sueltos.
@export var no_lots: bool = false
## Qué hay detrás de las casas.
@export var backfill: Backfill = Backfill.ROOFS
@export_group("Banqueta")
## Cada cuántos tiles va un árbol en la orilla de la banqueta (0 = ninguno).
@export var sidewalk_tree_every: int = 6
## Regiones de arboles.png que salen en la banqueta y en los huecos (0 fresno, 1 jacaranda, 2 arbustos,
## 3 maceta, 4 laurel, 5 palma, 6 buganvilia, 7 jardinera de talavera, 8 nopal, 9 seto).
@export var tree_kinds: Array[int] = [0, 1, 3, 4, 6, 7, 8]
## Cada cuántos tiles va un objeto de banqueta (0 = ninguno), entre los árboles.
@export var sidewalk_prop_every: int = 5
## Objetos de mobiliario.png que salen: 0 farol, 1 banca, 2 bote, 3 carrito de elotes,
## 4 puesto de fruta.
@export var prop_kinds: Array[int] = [0, 0, 1, 2, 3, 4]
## Distancia libre de decoración alrededor de cada pieza de Rules (x).
@export var calm_radius: float = 192.0
## Personas que caminan por las banquetas sin interactuar con el auto (0 = nadie).
## Dan la vuelta antes de los cruces y de las piezas con peatones.
@export var sidewalk_walkers: int = 6
@export_group("Destino")
## Nodos de Decor que forman el destino ("*" = todos). Vacío = el de más a la derecha.
@export var destination_nodes: PackedStringArray = []
## Nodos de Decor que se esconden (relleno viejo que ahora pone el CityDresser).
@export var hide_decor: PackedStringArray = []
@export var destination_icon: Icon = Icon.NONE
@export_group("Hora del día")
## Tinte de todo el nivel con un CanvasModulate (blanco = sin tinte). No se aplica
## si el nivel ya trae su propio CanvasModulate (nivel 7).
@export var tint: Color = Color.WHITE
