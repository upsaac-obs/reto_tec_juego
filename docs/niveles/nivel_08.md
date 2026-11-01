# Nivel 8 · Comparte el camino — ficha de diseño

Esta ficha sigue `docs/plan_cierre.md` y `CLAUDE.md`. En resumen: Peque tiene las mismas reglas que Grande, no hay reglas nuevas fuera del diseño y el destino usa arte que ya existe. Lo único que cambia entre modos es el tráfico. Si algo no se puede hacer como dice aquí, se pregunta antes de inventar.

- **Decálogo:** 5 · Comparte el camino.
- **Diseño:** "Avenida con ciclovía, motos y un camión que se detiene en su parada. Se evalúa: dejar distancia con el ciclista y no rebasar el camión detenido."
- **Frase final:** `FRASE_08` = "La calle es de todos."

---

## 1. Resumen y objetivo

El niño maneja por una avenida de un solo sentido con 4 carriles: la ciclovía junto al camellón y 3 carriles para autos. La avenida se comparte con bicis, motos y camiones. La lección es que en la calle no vamos solos:

1. **Distancia con la bici (`cyclist_distance`, rule_id `distance`).** Para rebasar a un ciclista, el auto deja un carril libre entre él y la ciclovía. Si pasa por el carril pegado a la ciclovía es falta; si va separado, +10.
2. **Camión detenido (`bus_stop`, rule_id `bus`).** Cuando el camión está detenido en su parada, no se pasa junto a él, por ningún carril: de un camión detenido baja gente que puede salir por enfrente sin que la veamos. Esperar detrás hasta que arranque da +10. Cambiarse de carril, por sí solo, no es falta.
3. **Repaso:** la ciclovía (`bike_lane`, nivel 2) está en todo el recorrido, y hay un semáforo (`traffic_light`, rojo y amarillo con `check_yellow`, nivel 5).

**Clímax:** en la segunda parada el camión está detenido y la gente sube y baja. Al mismo tiempo, una bici llega por detrás en la ciclovía y pasa junto al auto y el camión. Lo correcto es esperar detrás del camión, dejar pasar la bici y, cuando el camión arranca, rebasar a la bici por el carril separado.

**Destino:** la biblioteca (clave nueva `DESTINO_BIBLIOTECA`). El arte es el edificio naranja de `assets/sprites/city/edificios.png`. No se repite la terminal del nivel 5, y el nivel 6 usa el edificio de en medio de esa hoja como adorno.

**Duración:** de 80 a 95 s en Peque, sin faltas. El primer +10 llega a los 14 s, aproximadamente.

**Datos (`data/level_08.tres`):**

- `scene_path = "res://levels/level_08.tscn"`
- `destination_key = "DESTINO_BIBLIOTECA"`
- `name_key = "NIVEL_08_NOMBRE"` y `phrase_key = "FRASE_08"` se quedan como están.
- **`decalogo_key`: hay un error.** Hoy dice `"DECALOGO_08"`, que es "Decálogo 8 · Paciencia", pero este nivel es el **decálogo 5**. Debe decir `decalogo_key = "DECALOGO_05"` ("Decálogo 5 · Comparte el camino"). El mismo problema existe en otros niveles: según la tabla del diseño, el nivel 2 es el decálogo 4, el nivel 4 es el 8 y el nivel 5 es el 2. Lo debe revisar quien integra, porque son archivos de otros niveles.

---

## 2. Recorrido

### 2.1 La avenida (vista desde arriba, el auto va hacia +x)

La ruta (`Route`) es una recta en y = 0 con `default_lane_count = 4`. `DrivingRoute.lane_offset(i, 4)` da los centros −96, −32, +32 y +96. El carril 0 es el de la izquierda del auto, que en pantalla queda arriba.

| Fila de tiles (y) | Rango en px (y) | Qué es | Carril de la ruta |
| --- | --- | --- | --- |
| −5 y menos | ≤ −320 | Pasto con casas y edificios | — |
| −4 | −256 … −192 | Orilla o pasto (`(3,0)`) | — |
| −3 | −192 … −128 | Camellón o banqueta de arriba (`(4,0)`) | — |
| −2 | −128 … −64 | **Ciclovía** (asfalto; la pinta la pieza `BikeLane`) | 0 (centro −96) |
| −1 | −64 … 0 | **Carril izquierdo, pegado a la ciclovía** | 1 (centro −32) |
| 0 | 0 … 64 | **Carril central** | 2 (centro +32) |
| 1 | 64 … 128 | **Carril derecho, el del camión** | 3 (centro +96) |
| 2 | 128 … 192 | Banqueta de abajo, donde va la parada (`(5,0)`) | — |
| 3 | 192 … 256 | Orilla o pasto (`(3,0)`) | — |
| 4 y más | ≥ 256 | Pasto con casas y edificios | — |

- **Por qué la ciclovía va a la izquierda**, junto al camellón (como en varios bulevares de Puebla): así la bici y la parada del camión quedan en lados distintos y cada regla se lee sola. A la derecha está la banqueta con la parada.
- **Carril inicial:** `PlayerCar.start_lane = 1`, el que va pegado a la ciclovía. El niño aprende la regla de la bici al tener que cambiarse de carril con la flecha derecha.
- **Separación con la ciclovía:** el carril 1 está pegado (64 px entre centros); los carriles 2 y 3 están separados (128 y 192 px).
- **Largo:** 172 tiles = 11 008 px. La curva va de (64, 0) a (10 976, 0), así que `get_length()` ≈ 10 912. Las losas de meta van en la última columna (x = 171), filas −2 … 1.
- **Piezas de ancho completo:** todas las piezas que tienen `road_width` usan **256**. Los letreros que van del lado derecho bajan 64 px: `light_offset = (−28, 260)`.

### 2.2 Segmentos en orden

Las x son globales. Para convertirlas a progreso en la ruta se resta 64. Los tiempos son para Peque (168 px/s, el 70 % de 240) e incluyen arrancar y esperar.

| # | x (px) | Tramo | Qué pasa | Tiempo |
| --- | --- | --- | --- | --- |
| A | 64 – 1 450 | Arranque | Cinturón. A la derecha, la banqueta y el pasto; a la izquierda, la ciclovía verde. Hint de inicio en 320. Moto 1 por el carril 3. | 0 – 9 s |
| B | 1 450 – 3 072 | Primera bici | Hint de la bici en 1000. La bici sale en 1898; el auto la rebasa cerca de 2300. Si va separado, +10. En 3072 termina la ciclovía 1 (+10). | 9 – 20 s |
| B′ | 2 700 – 3 700 | Segunda bici (solo Grande) | Otra bici, ahora sin aviso. | 17 – 23 s |
| C | 3 700 | Punto de control 1 | — | — |
| D | 3 800 – 6 300 | Primera parada (enseña) | El camión aparece adelante en el carril 3, llega a su parada en 5200, baja 1 persona y sube 1. Se espera detrás y el camión arranca. +10. | 21 – 37 s |
| E | 6 400 | Fin de la ciclovía 2 | +10 | ≈ 40 s |
| F | 7 000 | Semáforo (repaso) | Empieza en rojo y tiene `check_yellow`. | 44 – 50 s |
| G | 7 300 | Punto de control 2 | — | — |
| H | 7 800 – 9 900 | **Clímax: segunda parada con bici** | Camión en 9200; bajan 2 personas y suben 2. Una bici llega por detrás, pasa junto al auto y al camión detenidos y luego baja la velocidad. Cuando el camión arranca, el auto rebasa a la bici por el carril separado. | 55 – 75 s |
| I | 9 900 – 10 976 | Llegada | Fin de la ciclovía 3 en 10 624 (+10). La biblioteca abajo a la derecha. Meta. | 75 – 85 s |

### 2.3 Piezas con sus valores

Todas van dentro de `Rules`, con y = 0 y sin girar. Si un valor no aparece, se deja el que trae la pieza por defecto.

| Nodo | Escena | Posición | Valores exportados |
| --- | --- | --- | --- |
| `HintStart` | `tutorial_hint.tscn` | (320, 0) | `message_key = "L08_INICIO"`, `road_width = 256` |
| `HintCyclist` | `tutorial_hint.tscn` | (1000, 0) | `message_key = "L08_BICI"`, `road_width = 256` |
| `BikeLane1` | `bike_lane.tscn` | (128, 0) | `side_offset = -96`, `length = 2944`, `road_width = 256` |
| `Cyclist1` | `cyclist_distance.tscn` (nueva) | (1450, 0) | `cyclist_start_x = 448`, `cyclist_speed = 80`, `cyclist_end_x = 2800`, `bike_side_offset = -96`, `road_width = 256` |
| `Cyclist1b` | `cyclist_distance.tscn` | (2700, 0) | `grande_only = true`, `cyclist_start_x = 448`, `cyclist_speed = 80`, `cyclist_end_x = 1900`, `bike_side_offset = -96`, `road_width = 256` |
| `Checkpoint1` | `checkpoint.tscn` | (3700, 0) | `road_width = 256` |
| `HintBus` | `tutorial_hint.tscn` | (3900, 0) | `message_key = "L08_CAMION"`, `peque_message_key = "L08_CAMION_PEQUE"`, `road_width = 256` |
| `BusStop1` | `bus_stop.tscn` (nueva) | (5200, 0) | `trigger_distance = 1400`, `bus_start_x = -500`, `bus_end_x = 1100`, `passengers_off = [adult_frames]`, `passengers_on = [elder_frames]`, `min_dwell = 4.0`, `road_width = 256` |
| `BikeLane2` | `bike_lane.tscn` | (3072, 0) | `side_offset = -96`, `length = 3328`, `road_width = 256` |
| `TrafficLight` | `traffic_light.tscn` | (7000, 0) | `start_light = 2` (rojo), `red_time = 5.0`, `green_time = 5.0`, `yellow_time = 2.5`, `check_yellow = true`, `road_width = 256`, `light_offset = (-28, 260)` |
| `Checkpoint2` | `checkpoint.tscn` | (7300, 0) | `road_width = 256` |
| `HintClimax` | `tutorial_hint.tscn` | (7900, 0) | `message_key = "L08_CLIMAX"`, `peque_message_key = "L08_CLIMAX_PEQUE"`, `road_width = 256` |
| `BusStop2` | `bus_stop.tscn` | (9200, 0) | `trigger_distance = 1400`, `bus_start_x = -500`, `bus_end_x = 1300`, `passengers_off = [elder_frames, girl_frames]`, `passengers_on = [adult_frames, girl_frames]`, `min_dwell = 7.0`, `road_width = 256` |
| `Cyclist2` | `cyclist_distance.tscn` | (8400, 0) | `cyclist_start_x = -400`, `cyclist_speed = 140`, `cyclist_slow_x = 1000`, `cyclist_slow_speed = 70`, `cyclist_end_x = 2600`, `bike_side_offset = -96`, `road_width = 256` |
| `BikeLane3` | `bike_lane.tscn` | (6400, 0) | `side_offset = -96`, `length = 4224`, `road_width = 256` |

Las tres ciclovías se tocan (128 → 3072 → 6400 → 10 624), así que la franja verde se ve continua. Partirla en tres sirve para repartir los +10 de repaso en momentos tranquilos y para que entrar a la ciclovía en un tramo no quite los puntos de los demás.

**Decoración (`Decor`, como en los niveles 2 y 4):**

- `Library`: `Sprite2D` con `edificios.png`, `region_enabled = true`, `region_rect = Rect2(284, 0, 142, 160)` (el edificio naranja), en (10 850, 340). Queda abajo a la derecha, del lado de la banqueta.
- Las casas las pinta el constructor (sección 5).

**Tráfico decorativo (`Traffic`, un `Node2D` bajo la raíz del nivel; opcional, ver la sección 7):**

| Nodo | Ruta (`Path2D`, puntos) | Hijo `NpcCar` | Modo |
| --- | --- | --- | --- |
| `Moto1Path` | (−1400, 96) → (6600, 96) | `cruise_speed = 230`, `body_color = Color.WHITE`, `Sprite.texture = motorcycle.png` | Peque y Grande |
| `Moto2Path` | (−4200, 96) → (6600, 96) | `cruise_speed = 220`, mismo sprite | Solo Grande |
| `Moto3Path` | (−9000, 96) → (11 400, 96) | `cruise_speed = 240`, mismo sprite | Solo Grande |

- Las motos van solo por el carril 3, el del camión. El camión tiene un `Hitbox` en el grupo `traffic`, así que una moto que lo alcanza en su parada **frena y espera detrás** (lo hace el sensor de `NpcCar`). Sin que nadie lo diga, la moto le pone el ejemplo al niño.
- `NpcCar` arranca al cargar la escena, por eso las rutas empiezan muy atrás.
- **Reglas al ajustar:** ninguna moto aparece ni desaparece dentro de la cámara (ve unos 880 px adelante del auto), y ninguna cruza la línea del semáforo en x = 7000. El semáforo no detiene a los `NpcCar`; por eso Moto1 y Moto2 terminan en 6600. Moto3 es tan rápida que pasa el semáforo mucho antes que el auto.
- Si en 30 minutos de prueba no se logra que se vean bien, **se cortan las motos**.

---

## 3. Pieza nueva `bus_stop`

**Archivos:** `scenes/rules/bus_stop.gd` y `scenes/rules/bus_stop.tscn`, con `class_name BusStop extends RulePiece` y `@tool`.

**Origen:** el punto de la línea central de la ruta donde se detiene **el centro del camión**. El auto llega desde −x. Para otras direcciones se gira el nodo; todos los cálculos se hacen en coordenadas locales con `to_local(car.global_position)`.

### 3.1 Nodos de la escena

| Nodo | Tipo | Qué es |
| --- | --- | --- |
| `Trigger` | `Area2D` (rect de 16 × `road_width`, centrado en x = −`trigger_distance`) | El auto lo cruza y el camión aparece |
| `Bus` | `Node2D` en (`bus_start_x`, `lane_y`) | El camión. Lo mueve la pieza, no es un `NpcCar` |
| `Bus/Sprite` | `Sprite2D`, `bus.png` (139 × 80), centrado | El frente (la cabina) mira a +x y la puerta queda del lado +y |
| `Bus/Hitbox` | `Area2D` en el grupo `traffic`, rect de 132 × 60 | Para que las motos frenen detrás |
| `Shelter` | `Sprite2D`, `bus_stop.png` (97 × 80), en `shelter_offset` | El techito de la parada, en la banqueta |
| `Sign` | `Sprite2D`, `bus_stop_sign.png` (28 × 52), en `sign_offset` | El letrero de la parada |
| Pasajeros | `pedestrian.tscn`, creados en `_ready` | Uno por cada `SpriteFrames` de `passengers_off` y `passengers_on` |

### 3.2 Valores exportados

```gdscript
@export var road_width: float = 256.0
## Centro del carril del camión, desde la línea central de la ruta (+y = derecha del auto).
@export var lane_y: float = 96.0
## Distancia antes del origen donde el auto, al cruzarla, hace aparecer el camión.
@export var trigger_distance: float = 1400.0
## Dónde aparece el camión (x local; negativa = antes de la parada).
@export var bus_start_x: float = -500.0
## Al llegar aquí el camión se desvanece (fade_time) y se oculta.
@export var bus_end_x: float = 1100.0
@export var bus_cruise_speed: float = 200.0
@export var bus_acceleration: float = 120.0
## Frenado del camión (px/s²). Empieza a frenar cuando v²/(2·bus_braking) ≥ la distancia que le falta a x = 0.
@export var bus_braking: float = 260.0
@export var bus_half_length: float = 70.0
## Distancia mínima (px) que el camión deja con el auto si el auto está adelante en su carril.
@export var bus_sensor: float = 40.0
## Puerta, relativa al centro del camión (del lado de la banqueta).
@export var door_offset: Vector2 = Vector2(30.0, 44.0)
@export var shelter_offset: Vector2 = Vector2(0.0, 168.0)
@export var sign_offset: Vector2 = Vector2(-90.0, 150.0)
## Quiénes bajan y quiénes suben, un SpriteFrames por persona.
@export var passengers_off: Array[SpriteFrames] = []
@export var passengers_on: Array[SpriteFrames] = []
@export var passenger_walk_speed: float = 50.0
## Segundos entre que baja (o sube) una persona y la siguiente.
@export var passenger_interval: float = 0.6
## Separación en x entre las personas que esperan o llegan a la parada.
@export var passenger_spacing: float = 24.0
## Segundos que el camión se queda detenido después de que el auto llegó a esperar.
@export var min_dwell: float = 5.0
## Si el auto nunca llega, el camión arranca después de estos segundos detenido.
@export var max_dwell: float = 14.0
## Cuenta como que el auto llegó a esperar si su frente queda a esta distancia detrás del camión.
@export var wait_distance: float = 448.0
## Cuánto puede pasar el frente del auto de la parte de atrás del camión sin que sea rebasarlo.
@export var pass_margin: float = 24.0
## Medio largo del auto: de su centro al frente.
@export var car_half_length: float = 34.0
## Si el auto va en el carril del camión, frena solo a esta distancia de él (no es falta).
@export var safety_gap: float = 32.0
## Diferencia en y (px) a partir de la cual el auto ya no está en el carril del camión.
@export var same_lane_tolerance: float = 48.0
@export var stop_speed: float = 10.0
@export var fade_time: float = 0.3
@export var points: int = 10
```

### 3.3 Estados del camión

```gdscript
enum State { IDLE, ARRIVING, STOPPED, DEPARTING, GONE }
```

| Estado | Qué pasa | Cuándo termina |
| --- | --- | --- |
| `IDLE` | El camión está oculto en `bus_start_x`. Los que van a subir esperan quietos (`idle`) en la parada; los que van a bajar están ocultos. | El auto entra a `Trigger` (solo una vez por pasada) |
| `ARRIVING` | El camión se muestra y avanza en `lane_y`: acelera hasta `bus_cruise_speed` y frena a tiempo para quedar **exactamente en x = 0**. Si el auto está adelante en su carril, a menos de `bus_sensor` de su frente, el camión baja a 0 y espera. | `Bus.position.x` llega a 0 y `speed` vale 0 (se ajusta a x = 0) |
| `STOPPED` | Los pasajeros bajan y suben (3.4). Se cuenta `stopped_time`, y `close_time` solo mientras el auto está dentro de `wait_distance` detrás del camión. | Terminaron los pasajeros **y** además `close_time ≥ min_dwell`, o el auto ya rebasó (falta), o `stopped_time ≥ max_dwell` |
| `DEPARTING` | El camión acelera hacia +x con el mismo sensor. Al llegar a `bus_end_x` se desvanece en `fade_time` y se oculta. | Llega a `bus_end_x` |
| `GONE` | Oculto. La pieza ya no evalúa nada. | — |

Al pasar de `STOPPED` a `DEPARTING` se evalúa el +10 (3.5).

### 3.4 Pasajeros

- **Al entrar a `STOPPED`, primero bajan.** Cada persona de `passengers_off` aparece en `door_offset + Bus.position`, con `reset_at()` y luego `show()`, una cada `passenger_interval`. Camina con `walk_to()` hasta su lugar en la banqueta: `shelter_offset + (i * passenger_spacing - 24, 0)`. Al llegar (`arrived`) hace `fade_out()`, porque ya se fue caminando.
- **Cuando bajaron todos, suben los demás.** Cada persona de `passengers_on` camina de su lugar en la parada a la puerta, una cada `passenger_interval`. Al llegar hace `fade_out()`, porque ya subió.
- `passengers_done()` es verdadero cuando todos llegaron. Si las dos listas están vacías, es verdadero desde el principio.
- **Nadie camina por el arroyo.** Los pasajeros solo van de la puerta a la banqueta (y de 128 a 190), nunca cruzan la calle. El auto no puede acercarse a ninguna persona: las reglas de no violencia se cumplen sin frenado de emergencia.
- Todos usan `walk_speed = passenger_walk_speed`.

### 3.5 Falta, puntos y frenado de seguridad

En cada `_physics_process`, si conoce al auto (`_car`, que se guarda al entrar a `Trigger`) y el estado no es `IDLE` ni `GONE`:

```
local     = to_local(_car.global_position)
car_front = local.x + car_half_length
bus_rear  = Bus.position.x - bus_half_length
same_lane = absf(local.y - lane_y) < same_lane_tolerance
```

1. **Frenado de seguridad (no es falta ni da puntos).** Mientras `same_lane` y `car_front > bus_rear - safety_gap` y `car_front < Bus.position.x + bus_half_length`, la pieza llama `_car.add_stop_request(self)`; si no, `remove_stop_request(self)`. Si esto pasó mientras el camión estaba `STOPPED`, se marca `_auto_stopped = true`. El auto nunca se encima en el camión. El niño puede cambiarse de carril estando detenido, porque las flechas siguen funcionando, y en cuanto deja de estar en el carril del camión se quita la petición.
2. **Falta `bus` (no grave).** Si `state == STOPPED` y `car_front > bus_rear + pass_margin` y no `same_lane`, se reporta una sola vez por pasada (`_faulted`):
   ```gdscript
   _report_infraction(&"bus", "FALTA_CAMION")
   ```
   Así se detecta "pasar junto al camión detenido": el frente del auto rebasa la parte de atrás del camión por cualquier otro carril. Cuenta **aunque el auto se cambie de carril o vaya despacio**, porque lo que cuenta es avanzar a la par del camión.
3. **No es falta:**
   - cambiarse de carril sin avanzar más allá de `bus_rear + pass_margin`;
   - rebasar al camión mientras está en `ARRIVING` o `DEPARTING`;
   - el frenado de seguridad.
4. **+10 (`bus`).** Al pasar de `STOPPED` a `DEPARTING`, si se cumple todo esto:
   - `not _faulted`;
   - el auto se detuvo en algún momento de `STOPPED` (`_car.speed < stop_speed`), con `car_front ≤ bus_rear + pass_margin`;
   - en ese momento la pieza no lo estaba frenando: el niño frenó por su cuenta (`_auto_stopped == false`).

   Entonces:
   ```gdscript
   _report_good_action(&"bus", "BIEN_CAMION", points)
   ```
   Si el auto se detuvo solo por el frenado de seguridad, no hay falta ni puntos. En Peque eso significa que el niño no pisó el freno; las reglas son las mismas que en Grande.

### 3.6 API para pruebas y para el conductor de `test_levels`

```gdscript
var state: State                  # solo lectura desde fuera
func is_stopped() -> bool         # state == STOPPED
## Verdadero mientras el auto debe quedarse detrás: el camión va llegando o está detenido.
func must_wait() -> bool          # state in [ARRIVING, STOPPED]
## Dónde termina el camión (x global de su parte de atrás).
func bus_rear_global_x() -> float
func passengers_done() -> bool
```

### 3.7 `checkpoint_restored` (`_on_car_restarted`)

Se llama solo si el punto de control quedó antes de la pieza; eso ya lo revisa `RulePiece`. En este nivel no hay faltas graves, pero se implementa igual:

- `state = IDLE`, el camión se oculta en `bus_start_x`, `speed = 0` y `modulate.a = 1`.
- Los pasajeros vuelven a su lugar con `reset_at()`: los que bajan quedan ocultos y los que suben, visibles en la parada.
- `_car.remove_stop_request(self)`.
- `_car = null`, `_faulted = false`, `_auto_stopped = false`, `_waited = false`, `stopped_time = 0` y `close_time = 0`.
- Se ignoran los temporizadores de una pasada anterior (contador de ronda, como en `crosswalk`).

### 3.8 Claves

- `FALTA_CAMION`, `BIEN_CAMION`: mensajes de la pieza.
- `REGLA_BUS`: nombre de la regla en Tutores.
- **Para integración:** agregar `"bus" -> REGLA_BUS` en `ruleName()` de `native/android/.../TutorsScreen.kt` y lo mismo en iOS. Si no se puede tocar lo nativo, la otra opción es usar `rule_id = &"distance"` también para el camión: la tabla de faltas del diseño junta las dos situaciones en "Distancia". Esta ficha usa `bus`, como se decidió.

### 3.9 Dibujo en el editor

Con `Engine.is_editor_hint()` se dibuja:

- una línea dorada en x = −`trigger_distance`;
- el rectángulo del camión detenido en x = 0;
- una línea en `bus_rear + pass_margin`.

---

## 4. Pieza nueva `cyclist_distance`

**Archivos:** `scenes/rules/cyclist_distance.gd` y `scenes/rules/cyclist_distance.tscn`, con `class_name CyclistDistance extends RulePiece` y `@tool`.

**Origen:** la **línea de disparo**. Cuando el auto la cruza, aparece la bici en `cyclist_start_x`. El auto avanza hacia +x.

### 4.1 Nodos de la escena

| Nodo | Tipo | Qué es |
| --- | --- | --- |
| `Trigger` | `Area2D`, rect de 16 × `road_width` centrado en x = 0 | Disparo |
| bici | `cyclist.tscn` (ya existe; anima `ride`; grupo `cyclist`), instanciada como hija de la pieza al disparar | Va en (`cyclist_start_x`, `bike_side_offset`) y avanza con su propio `speed`; se borra sola en `end_x = cyclist_end_x` |

### 4.2 Valores exportados

```gdscript
@export var road_width: float = 256.0
## Centro de la ciclovía desde la línea central de la ruta (+y = derecha), igual que BikeLane.side_offset.
@export var bike_side_offset: float = -96.0
@export var lane_width: float = 64.0
## Dónde sale la bici (x local). Positiva = adelante del auto; negativa = llega por detrás.
@export var cyclist_start_x: float = 448.0
@export var cyclist_speed: float = 80.0
## Opcional: al pasar esta x local la bici baja a cyclist_slow_speed (INF = nunca).
@export var cyclist_slow_x: float = INF
@export var cyclist_slow_speed: float = 70.0
## La bici se borra al llegar aquí (x local). Tiene que quedar fuera de cámara.
@export var cyclist_end_x: float = 2400.0
## Distancia mínima en y entre el centro del auto y el centro de la ciclovía para ir "separado".
## 112 = dos carriles (128) menos 16 px de tolerancia. Carril pegado = 64 → falta; carril de en medio = 128 → bien.
@export var min_center_distance: float = 112.0
## Medio largo de la ventana "a la par": |x auto − x bici| ≤ pass_window.
## Auto (68 px) y bici (60 px) se tocan a lo largo con |dx| < 64; se dan 32 px de margen.
@export var pass_window: float = 96.0
## Segundos seguidos en el carril pegado, dentro de la ventana, antes de la falta (evita parpadeos a media maniobra).
@export var adjacent_grace: float = 0.25
## Si el auto va DENTRO de la ciclovía detrás de la bici, frena solo a esta distancia (no es falta de esta pieza).
@export var safety_gap: float = 24.0
@export var car_half_length: float = 34.0
@export var bike_half_length: float = 30.0
## Solo sale en modo Grande (más tráfico). En Peque la pieza no hace nada.
@export var grande_only: bool = false
@export var points: int = 10
```

### 4.3 Cómo se mide si va pegado

Todo se mide en coordenadas locales de la pieza: `local = to_local(car.global_position)`. La posición global del auto ya incluye `v_offset`, así que el cálculo funciona aunque la pieza esté girada y también a media animación de cambio de carril.

```
dx  = local.x - cyclist.position.x          # + = el auto va adelante
sep = absf(local.y - bike_side_offset)      # distancia lateral al centro de la ciclovía
in_bike_lane = sep < lane_width / 2.0       # 32: va dentro de la ciclovía
adjacent     = not in_bike_lane and sep < min_center_distance
```

En la avenida del nivel 8, `sep` vale 0 en el carril 0 (ciclovía), 64 en el carril 1 (**pegado**), 128 en el carril 2 (**separado**) y 192 en el carril 3 (separado).

No se usa `lane_index`, porque cambia al empezar la animación y no cuando el auto ya está en el otro carril.

### 4.4 Ventana de tiempo y evaluación

La bici solo se evalúa **cuando el auto la rebasa**: el auto viene de atrás, se pone a la par y termina adelante. Una vez por pasada.

| Paso | Condición | Efecto |
| --- | --- | --- |
| Detrás | `dx < -pass_window` | `_was_behind = true`. Si estaba a la par y se quedó atrás, `_alongside = false` y no se evalúa |
| A la par | `abs(dx) ≤ pass_window` y `_was_behind` | `_alongside = true`. Si `adjacent`, suma `delta` a `_adjacent_time`; si no, `_adjacent_time = 0` |
| Falta `distance` | `_alongside` y `_adjacent_time ≥ adjacent_grace` y no `_faulted` | `_faulted = true`; `_report_infraction(&"distance", "FALTA_DISTANCIA_BICI")` (no grave) |
| Adelante | `dx > pass_window` y `_alongside` | Si no `_faulted`: `_report_good_action(&"distance", "BIEN_DISTANCIA_BICI", points)`. En los dos casos, `_done = true` y no se vuelve a evaluar |

- **Si la bici rebasa al auto** (en el clímax el auto está detenido), el auto nunca venía de atrás (`_was_behind` es falso), así que no se evalúa nada. Cuando la bici ya lo rebasó, `dx < -pass_window` marca `_was_behind` y se evalúa el rebase que viene después.
- **Si el auto nunca la rebasa** (va más lento) y la bici llega a `cyclist_end_x`, no hay falta ni puntos.
- **Si el auto va dentro de la ciclovía**, esta pieza **no** da falta, porque ya la da `BikeLane` (`bike_lane`) y no se cuenta dos veces. Tampoco da +10 en esa pasada (`_done = true` sin puntos si termina adelante habiendo estado `in_bike_lane` a la par). Por seguridad, mientras `in_bike_lane` y `0 < -dx < car_half_length + bike_half_length + safety_gap` (la bici va justo adelante), se llama `car.add_stop_request(self)`. Si la bici viene detrás del auto a esa distancia, la bici se queda con `speed = 0`. Nadie se encima nunca. La petición se quita en cuanto deja de cumplirse.
- **Cambiarse a medio rebase:** si el auto entra a la ventana pegado y se cambia antes de `adjacent_grace` (0.25 s), no hay falta. El niño tiene que decidir antes: la direccional dura 1 s y la animación 0.4 s. Por eso hay un hint antes de la primera bici.
- **Bajar la velocidad:** cuando la bici pasa `cyclist_slow_x`, su `speed` pasa a `cyclist_slow_speed`. En el clímax sirve para que la bici pase rápido junto al camión y luego se pueda rebasar en unos 4 s.
- **`grande_only`:** si `GameState.mode == MODE_PEQUE`, la pieza no conecta `Trigger` ni dibuja nada en el juego.

### 4.5 API para pruebas

```gdscript
func is_active() -> bool                 # hay bici en la calle
func cyclist_global_x() -> float         # INF si no hay bici
func is_done() -> bool                   # ya se evaluó en esta pasada
```

### 4.6 `checkpoint_restored` (`_on_car_restarted`)

- `queue_free()` de la bici, si existe.
- `car.remove_stop_request(self)`.
- `_triggered`, `_was_behind`, `_alongside`, `_faulted` y `_done` vuelven a `false`; `_adjacent_time = 0`.
- Al volver a cruzar `Trigger`, la bici sale otra vez.

### 4.7 Claves

- `FALTA_DISTANCIA_BICI`, `BIEN_DISTANCIA_BICI`.
- La regla usa `REGLA_DISTANCE`, que ya existe ("Distancia con ciclista") y ya está en Tutores de Android como `"distance"`.

---

## 5. Lo que necesito del constructor de 4 carriles (`tools/level_builder.gd`)

1. **Una opción de avenida**, por ejemplo `lanes := 4` en `_init`, que pinte las filas de la tabla 2.1:
   - asfalto en y = −2, −1, 0 y 1;
   - banqueta arriba en −3 (`(4,0)`) y abajo en 2 (`(5,0)`);
   - orilla en −4 y 3 (`(3,0)`).
   
   La fila −2 puede ser asfalto liso (sin raya de carril del lado de arriba), porque `BikeLane` pinta el verde y su raya blanca encima. Las rayas punteadas entre carriles van en las fronteras y = −64, 0 y 64. Si hacen falta tiles nuevos para el carril de en medio (rayas arriba y abajo), los hace el equipo de base.
2. **Casas y plantas recorridas** fuera de la avenida: casas en las filas −8 y 5, plantas en −5 y 4. Ninguna casa encima de la banqueta, para que no tape la parada ni el letrero.
3. **Losas de meta** en la última columna, en las 4 filas de asfalto (−2 … 1).
4. **`Route.default_lane_count = 4`** y curva en y = 0, de (64, 0) a (`tiles`·64 − 32, 0). El `start_lane` se pasa como hoy (aquí es 1).
5. **`road_width` por defecto = 256** en lo que agregue `add()` cuando `lanes == 4`, o una forma sencilla de pasarlo. Si no, se pone a mano en cada pieza (tabla 2.3).
6. **Que `FollowCamera.bounds_layer` siga funcionando** con la avenida más ancha. La vista mide 720 de alto y la avenida con sus banquetas mide 512, así que cabe completa.

Con eso el nivel se arma como `LevelBuilder.new("Level08", 172, 1, <semilla>, ...)` más los `add()` de la tabla 2.3, y después se corre `tools/make_inherited.py levels/level_08.tscn`.

---

## 6. Momentos (ritmo y clímax)

| t (Peque) | Momento | Emoción |
| --- | --- | --- |
| 0–3 s | Cinturón. "¡Qué avenida tan grande!…" Se ven la franja verde y la parada a lo lejos. | Curiosidad |
| ≈ 6 s | El copiloto avisa de la bici. | Atención |
| ≈ 9–14 s | Aparece la bici adelante. Flecha derecha y direccional. **Primer +10** al rebasarla separado. Por esos segundos, una moto rebasa por la derecha. | Primer logro |
| ≈ 20 s | +10 de la ciclovía (repaso del nivel 2). | Confianza |
| ≈ 21–28 s | "El camión va a su parada…" El camión frena y se abre la puerta. | Anticipación |
| ≈ 28–34 s | Baja una señora y sube un señor. El niño frena detrás. El camión arranca: **+10**. | Calma |
| ≈ 44–50 s | Semáforo en rojo o amarillo (repaso del nivel 5). Respiro tranquilo antes del final. | Pausa |
| ≈ 55–70 s | **Clímax.** "Otra parada y viene una bici…" Un camión detenido, gente con niñas en la banqueta, una moto esperando detrás del camión y una bici rápida que pasa por la izquierda. La tentación es salirse para rebasar; lo correcto es esperar. | Tensión suave |
| ≈ 70–75 s | El camión arranca (+10). La bici baja la velocidad y el auto la rebasa con un carril de espacio (+10). | Alivio y orgullo |
| ≈ 80–85 s | +10 de la ciclovía, la biblioteca, la meta y la tarjeta con la frase "La calle es de todos." | Cierre |

**Reglas de ritmo que se respetan:**

- Nunca hay dos evaluaciones nuevas al mismo tiempo, salvo en el clímax, que está hecho a propósito (camión y bici seguidos).
- Hay un respiro de 8 s o más entre los bloques B, D, F y H.
- Si el niño no frena en el clímax, las faltas posibles son 2 (camión y bici); ninguna es grave, así que el nivel termina con 2 estrellas.

---

## 7. Peque y Grande

**Las reglas son las mismas.** En Peque el auto avanza solo al 70 % (168 px/s). Para esperar detrás del camión **hay que mantener el freno**; si no, el frenado de seguridad lo detiene, pero sin +10 (3.5). Las flechas funcionan igual en los dos modos.

| | Peque | Grande |
| --- | --- | --- |
| Bicis evaluadas | 2 (`Cyclist1`, `Cyclist2`) | 3 (más `Cyclist1b`, `grande_only = true`) |
| Motos | 1 (`Moto1`) | 3 (`Moto1` a `Moto3`) |
| Camiones y pasajeros | Iguales | Iguales |
| Hints | `L08_CAMION_PEQUE` y `L08_CLIMAX_PEQUE` (dicen "pisa el freno") | `L08_CAMION` y `L08_CLIMAX` (el del clímax pregunta en vez de decir) |
| Semáforo | Igual. El amarillo en Peque usa la propiedad "deja avanzar" de la base técnica (plan, punto 3) | Igual |

**Motos solo en Grande:** `NpcCar` no sabe del modo. La propuesta es agregar a `npc_car.gd` `@export var grande_only := false`, y en `_ready`, `if grande_only and GameState.mode == GameState.MODE_PEQUE: queue_free()` (2 líneas). `npc_car.gd` no está en la lista de archivos de la base técnica, así que **lo tiene que aprobar el lead-programmer**. Si no se aprueba, Moto2 y Moto3 se quitan y queda solo Moto1 en los dos modos.

---

## 8. Textos nuevos (para `i18n/textos.csv`)

Todos tienen 14 palabras o menos, están pensados para leerse en voz alta, están en español de México y explican el porqué.

```csv
L08_INICIO,"¡Qué avenida tan grande! Hoy la compartimos con bicis, motos y camiones."
L08_BICI,"Ahí va una bici. Cámbiate al carril de en medio para darle espacio."
L08_CAMION,"El camión va a su parada. Cuando se detenga, esperamos detrás de él."
L08_CAMION_PEQUE,"El camión va a su parada. Cuando se detenga, pisa el freno y esperamos."
L08_CLIMAX,"Otra parada, y viene una bici. Piensa: ¿quién necesita espacio?"
L08_CLIMAX_PEQUE,"Otra parada y viene una bici. Frena y esperamos detrás del camión."
FALTA_DISTANCIA_BICI,"¡Muy pegadito a la bici! Deja un carril libre para que vaya segura."
BIEN_DISTANCIA_BICI,"¡Bien! Le dejaste un carril de espacio a la bici."
FALTA_CAMION,"¡Espera! Con el camión detenido, alguien puede salir de enfrente sin que lo veas."
BIEN_CAMION,"¡Muy bien! Esperaste detrás del camión mientras la gente subía y bajaba."
REGLA_BUS,Camión detenido
DESTINO_BIBLIOTECA,Biblioteca
```

- Ya existen y se reutilizan: `NIVEL_08_NOMBRE`, `FRASE_08`, `DECALOGO_05`, `REGLA_DISTANCE`, `FALTA_CICLOVIA`, `BIEN_CICLOVIA`, `FALTA_ROJO`, `BIEN_ROJO`, `FALTA_AMARILLO` y `META_LLEGASTE`.
- Cada clave nueva necesita su voz en `assets/audio/voz/<CLAVE>.ogg` (fase de audio).

---

## 9. Pruebas a escribir

### 9.1 `tests/test_cyclist_distance.gd`

Usa `levels/level_08.tscn` con `TestDriver`, como `test_patience.gd`, y `car.seatbelt_on = true`. Para cambiar de carril usa `tap(&"car_right")` o `tap(&"car_left")` y espera 1.6 s. Usa `Cyclist1` (disparo en x = 1450, es decir, progreso 1386).

1. **Separado da +10.** Desde el progreso 1000, en el carril 2, a 150 px/s durante 8 s → `rm.points` sube 10 por `distance`, `infractions` no tiene `distance` y `Cyclist1.is_done()`.
2. **Pegado da falta.** Igual que la 1 pero en el carril 1 → `infractions["distance"] == 1` y no hay +10 de `distance`. Aunque siga a la par 2 s más, la falta no sube a 2.
3. **El carril 3 también cuenta como separado** → +10.
4. **Cambiarse a tiempo:** en el carril 1, se pide la flecha derecha cuando el auto está 400 px detrás de la bici → +10 y sin falta.
5. **Ir detrás no se evalúa:** a 40 px/s (más lento que la bici) hasta que la bici se borra → sin falta, sin puntos y `is_active() == false` al final.
6. **La bici rebasa al auto detenido.** Con `Cyclist2` (bici por detrás), el auto detenido en el carril 1 con `target = 0` mientras pasa la bici → sin falta. Luego, en el carril 2, rebasarla → +10.
7. **Dentro de la ciclovía.** El auto en el carril 0 detrás de la bici a 200 px/s → la distancia en x entre auto y bici nunca es menor que 64. `infractions` tiene `bike_lane` pero no tiene `distance`.
8. **`grande_only` en Peque.** Con `GameState.mode = MODE_PEQUE`, pasar por `Cyclist1b` → `is_active()` siempre es falso.
9. **Reinicio:** `rm.checkpoint_restored.emit(0.0)` con la bici activa → la bici se borra y, al volver a pasar, la evaluación se repite.

### 9.2 `tests/test_bus_stop.gd`

Usa `level_08.tscn` y `BusStop1` (origen en 5200; disparo en el progreso 3736; el frente del auto queda detrás si `progress + 64 + 34 ≤ 5130 + 24`).

1. **Ciclo de estados:** `IDLE → ARRIVING → STOPPED → DEPARTING → GONE`. En `STOPPED`, `Bus.position.x` está en 0 ± 2.
2. **Esperar detrás en el carril 2 da +10.** El auto frena hasta el progreso 4990 → +10 por `bus`, sin falta. El camión no arranca antes de `min_dwell` contado desde que el auto entró a `wait_distance`.
3. **Esperar detrás en el carril 3 frenando por su cuenta (el `TestDriver` frena en 4990)** → +10.
4. **Pasar junto al camión detenido da falta.** En el carril 2, sin frenar, a 150 px/s mientras está `STOPPED` → `infractions["bus"] == 1` y sin +10. Una sola falta aunque pase todo el camión.
5. **Cambiarse de carril no es falta.** Detenido detrás en el carril 3, se cambia al carril 2 y se queda detenido → sin falta y +10 al arrancar el camión.
6. **Rebasar mientras llega no es falta.** Con `bus_cruise_speed = 60` para que el auto lo alcance en `ARRIVING`, el auto en el carril 2 a 240 → sin falta.
7. **Frenado de seguridad.** En el carril 3 sin frenar → el auto se detiene solo con `car_front ≤ bus_rear - safety_gap + 2`, nunca se encima, y no hay falta ni puntos.
8. **Pasajeros:** al entrar a `DEPARTING`, `passengers_done()` es verdadero y todos los pasajeros están ocultos (`visible == false` o `modulate.a == 0`).
9. **El hitbox del camión está en el grupo `traffic`.** Un `NpcCar` en el carril 3 detrás del camión detenido se queda con `is_stopped()`.
10. **Reinicio:** `rm.checkpoint_restored.emit(0.0)` → `state == IDLE`, el camión está oculto y los pasajeros vuelven a su lugar.

### 9.3 `tests/test_levels.gd` (la parte de base técnica que toma la lista de `LevelData`)

El conductor cuidadoso tiene que manejar el nivel 8:

- **Carril:** si el nivel tiene alguna `CyclistDistance`, al arrancar hace `tap(&"car_right")` una vez (del carril 1 al 2) y se queda en el carril 2 todo el recorrido.
- **Camión:** en `play()`, cada `BusStop` se agrega a `stops` con `at = piece.position.x - piece.bus_half_length - 40.0 - 34.0 - 64.0` (5200 → 4992; 9200 → 8992). En `must_wait()`: `if piece is BusStop: return (piece as BusStop).must_wait()`.
- **Resultado esperado:** el nivel 8 termina con 3 estrellas y sin faltas, en Grande y en Peque (en Peque mantiene el freno detrás del camión).
- **Prueba nueva en `run()`:** un conductor que no frena en los camiones (`must_wait` falso para `BusStop`) → el nivel 8 trae `infractions.has("bus")` y `stars < 3`.

### 9.4 Datos

En `test_level_data.gd`, si revisa claves: `level_08.tres` tiene `scene_path`, `destination_key = "DESTINO_BIBLIOTECA"` y `decalogo_key = "DECALOGO_05"`, y todas las claves de la sección 8 existen en `textos.csv`.

---

## 10. Arte usado (todo existe; no hace falta Pixel Engine)

| Uso | Archivo |
| --- | --- |
| Camión | `assets/sprites/vehicles/bus.png` (139 × 80, frente hacia +x). No lleva logo; no es el camión de ADO |
| Parada | `assets/sprites/city/bus_stop.png` (97 × 80) |
| Letrero de parada | `assets/sprites/city/bus_stop_sign.png` (28 × 52) |
| Motos | `assets/sprites/vehicles/motorcycle.png` (60 × 27) en `npc_car.tscn`, con `body_color = WHITE` |
| Bicis | `assets/sprites/vehicles/cyclist_frames.tres` (ya lo usa `cyclist.tscn`) |
| Pasajeros | `assets/sprites/pedestrians/adult_frames.tres`, `elder_frames.tres`, `girl_frames.tres` |
| Ciclovía | La dibuja `bike_lane.gd` (verde de la paleta y bici blanca) |
| Semáforo | `assets/sprites/signals/traffic_light.png` (por `traffic_light.tscn`) |
| Destino: biblioteca | `assets/sprites/city/edificios.png`, `region_rect = Rect2(284, 0, 142, 160)` (edificio naranja) |
| Casas y plantas | Tiles del constructor (`casas`, plantas) |
| Tarjeta de hábito | `assets/ui/habit_cards/card_08.png` (ya está en `level_08.tres`) |

**Nota de tamaño:** el camión mide 80 px de alto y el carril 64. En el carril 3 (y de 56 a 136) invade 8 px del carril 2 y 8 px de la banqueta. El auto en el carril 2 llega hasta y = 52, así que no se tocan. Se deja a 1:1, como piden las reglas de sprites.
