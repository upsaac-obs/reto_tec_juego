# Nivel 7 · Hazte visible — ficha de diseño

Decálogo 7. Diseño: *"Atardecer, un túnel y lluvia. Aparecen ciclistas con casco y reflejantes. Se evalúa: encender las luces en tramos oscuros."* Frase final: **"Si te ven, te cuidan."** (`FRASE_07`).

Esta ficha sigue `docs/plan_cierre.md` (Peque con las mismas reglas que Grande; no hay reglas nuevas; destinos con arte existente) y `CLAUDE.md`.

---

## 1. Resumen y objetivo

- **Historia:** regresamos **a casa** al atardecer. El sol se va escondiendo, hay que cruzar un túnel y al final empieza a llover.
- **Regla principal:** `lights`. Al entrar a un tramo oscuro hay que **prender las luces**:
  - Si pasan más de 2 s dentro del tramo con las luces apagadas, es **falta**.
  - Si el auto va con las luces prendidas, gana **+10**.
- **El porqué, sin palabras:**
  - En lo oscuro, los ciclistas casi no se ven.
  - Cuando el auto lleva las luces prendidas, el ciclista se ilumina y su chaleco reflejante brilla.
  - El niño ve que con luz **se ven unos a otros**.
- **Repaso:**
  - `bike_lane` (nivel 2): la ciclovía corre por los tres tramos oscuros, junto a los ciclistas.
  - `speed` (nivel 2): el túnel tiene límite de 30 km/h.
- **Clímax:** el túnel. Es lo más oscuro del nivel, hay que ir despacio y aparecen dos ciclistas con reflejantes.
- **Duración:** unos 60–65 s manejando bien, en Peque y en Grande. El primer +10 llega entre los 10 y los 12 s.
- **Destino:** Casa (`assets/sprites/city/casas.png`), con la clave nueva `DESTINO_CASA`.
- **Ambiente de todo el nivel:** un `CanvasModulate` cálido de atardecer (ver §2). Es una sola multiplicación de color, sin shaders.

## 2. Recorrido

**Medidas:**
- 140 tiles de largo (`LevelBuilder.new("Level07", 140, 0, 707)`).
- La ruta va de x = 64 a x = 140·64 − 32 = **8928** px, sobre y = 0.
- Calle de 2 carriles: el carril 0 (y = −32) es el del auto y el carril 1 (y = +32) es la ciclovía.
- `PlayerCar.start_lane = 0`.
- Progreso sobre la ruta = x − 64.

**Ambiente (nodos del nivel, fuera de `Rules`):**
- `Dusk` (`CanvasModulate`), hijo directo de la raíz, con `color = GameState.COLOR_WARM_LIGHT` (#F8C99B). Es un tinte de atardecer sobre el mundo; el HUD y el copiloto no se tiñen porque son `CanvasLayer`.
  - Si el equipo prefiere no poner colores en la escena, se asigna por código en un `_ready` del nivel. Se recomienda poner `level_07.gd` mínimo en la raíz solo para esto.
- `Decor` (`Node2D`, index 1, como en los niveles 3 y 4):
  - `TunelEntrada` (`Sprite2D`, `tunel_entrada.png`) en (3640, −190).
  - `TunelSalida` (`Sprite2D`, `tunel_salida.png`) en (5260, −190).
  - `Casa` (`Sprite2D`, `casas.png`, `region_enabled`, primera casa `Rect2(0, 0, 128, 128)`) en (8760, −200).
  - Los túneles son arte en 3/4 y se usan como decoración arriba de la calle: el cerro con la boca queda junto a la entrada y la salida. El interior lo hacen la sombra y las paredes del `dark_zone`.

**Orden de los hijos de `Rules` (importa):** los tres `DarkZone` van **al final**. Así su sombra se dibuja encima de la pintura de la ciclovía y de los letreros, y debajo del auto (`Route` está después de `Rules` en el árbol, ver §3).

| # | Tramo | x (px) | Piezas y valores |
| --- | --- | --- | --- |
| A | Arranque, atardecer claro | 64 → 900 | `TutorialHint` **HintLuces** en x = 500: `message_key = "TUTO_LUCES"`, `peque_message_key = ""` (el mismo texto: las reglas son iguales), `depth = 64`, `road_width = 128` |
| B | **Atardecer** (primer tramo oscuro) | 1000 → 2000 | `BikeLane` **BikeLane1** en (900, 0): `side_offset = 32`, `length = 1200`, `points = 10`<br>`DarkZone` **DarkDusk** en (1000, 0): `kind = DUSK`, `length = 1000`, `darkness = 0.5`, `cyclist_starts = [350.0, 750.0]`, `peque_cyclist_count = 1`, `cyclist_speed = 80`, `rain = false`, `walls = false`<br>`TutorialHint` **HintReflejante** en x = 1650: `message_key = "TUTO_REFLEJANTE"` |
| — | Punto de control | 2300 | `Checkpoint` **CheckpointAfterDusk** |
| C | Respiro, calle con luz | 2300 → 3500 | `TutorialHint` **HintTunel** en x = 3250: `message_key = "TUTO_TUNEL"` |
| D | **Túnel** (clímax) | 3500 → 5400 | `SpeedZone` **SpeedTunnel** en (3500, 0): `kind = STREET`, `limit_kmh = 30`, `zone_length = 1900`, `grace_time = 2.0`. El letrero queda antes de que empiece a oscurecer (3672).<br>`BikeLane` **BikeLane2** en (3700, 0): `side_offset = 32`, `length = 1600`<br>`DarkZone` **DarkTunnel** en (3800, 0): `kind = TUNNEL`, `length = 1400`, `darkness = 0.78`, `walls = true`, `cyclist_starts = [250.0, 700.0]`, `peque_cyclist_count = 1`, `cyclist_speed = 50`, `rain = false` |
| — | Punto de control | 5600 | `Checkpoint` **CheckpointAfterTunnel** |
| E | Salida del túnel | 5600 → 6500 | `TutorialHint` **HintLluvia** en x = 6300: `message_key = "TUTO_LLUVIA"` |
| F | **Lluvia** (cierre tranquilo) | 6600 → 8000 | `BikeLane` **BikeLane3** en (6500, 0): `side_offset = 32`, `length = 1600`<br>`DarkZone` **DarkRain** en (6600, 0): `kind = RAIN`, `length = 1400`, `darkness = 0.55`, `rain = true`, `cyclist_starts = [400.0, 900.0]`, `peque_cyclist_count = 1`, `cyclist_speed = 80`, `walls = false` |
| G | Llegada a casa | 8100 → 8928 | Meta del `LevelBuilder` (tile `FINISH`) y la casa en `Decor` |

**Orden final de `Rules`:**
1. HintLuces
2. BikeLane1
3. HintReflejante
4. CheckpointAfterDusk
5. HintTunel
6. SpeedTunnel
7. BikeLane2
8. CheckpointAfterTunnel
9. HintLluvia
10. BikeLane3
11. DarkDusk
12. DarkTunnel
13. DarkRain

**`data/level_07.tres`:**
- `destination_key = "DESTINO_CASA"`
- `scene_path = "res://levels/level_07.tscn"`

**`levels/level_07.tscn`:** sobrescribir en el nodo `Hud` `show_lights_button = true` (ver §4).

**Puntos posibles (sin faltas):** 3 tramos oscuros × 10 + 3 ciclovías × 10 + túnel 30 km/h × 10 = **70**.

**No hay faltas graves en este nivel:** no hay peatones. Los puntos de control solo sirven si el equipo agrega una pieza grave más adelante, y se dejan por consistencia con los niveles 3 y 4.

## 3. Pieza nueva `dark_zone`

**Archivos:**
- `scenes/rules/dark_zone.gd` (`class_name DarkZone`, `extends RulePiece`, `@tool`).
- `scenes/rules/dark_zone.tscn`.

**Origen y orientación:** el origen es el inicio del tramo, sobre el centro de la calle. El auto avanza hacia +x, igual que `bike_lane` y `speed_zone`.

### 3.1 Nodos de la escena (en este orden)

| Nodo | Tipo | Para qué |
| --- | --- | --- |
| `Zone` | `Area2D` + `CollisionShape2D` (`RectangleShape2D`) | Detecta al auto. Rect = `Rect2(0, -road_width/2, length, road_width)` |
| `Riders` | `Node2D` | Contiene a los ciclistas. **Antes de `Shade`**: sin luces quedan debajo de la sombra |
| `Shade` | `Node2D` con tres `Polygon2D` hijos: `FadeIn`, `Body`, `FadeOut` | La oscuridad |
| `Beam` | `Polygon2D` | Haz de luz delante del auto, solo dentro del tramo y con luces |
| `Rain` | `CPUParticles2D` | Lluvia, solo si `rain = true` |

### 3.2 `@export` (con valores por omisión)

```text
enum Kind { DUSK, TUNNEL, RAIN }
kind: Kind = DUSK                 # cambia los mensajes (tabla 3.5)
length: float = 1000.0            # setter → _refresh()
road_width: float = 128.0         # setter → _refresh()
darkness: float = 0.55            # alfa de la sombra (0 = nada, 1 = negro)
shade_color: Color = Palette.COLOR_OUTLINE   # #1E0F26, se le aplica `darkness` como alfa
fade_length: float = 160.0        # degradado antes y después del tramo
cover_height: float = 1600.0      # alto de la sombra (cubre la pantalla aunque la cámara suba o baje)
grace_time: float = 2.0           # segundos SEGUIDOS sin luces dentro antes de la falta
confirm_time: float = 0.5         # segundos seguidos con luces dentro para dar +10
points: int = 10
walls: bool = false               # paredes de túnel
wall_width: float = 24.0
@export_group("Ciclistas")
cyclist_starts: PackedFloat32Array = []   # x relativas al origen donde aparecen al entrar el auto
peque_cyclist_count: int = 1      # en Peque solo salen los primeros N
cyclist_speed: float = 80.0
cyclist_offset: float = 32.0      # y del carril de bici (igual al side_offset de la BikeLane)
cyclist_end_margin: float = 600.0 # el ciclista se borra en end_x = length + margin
safety_gap: float = 110.0         # ver 3.6
lit_z_index: int = 1              # z de Riders con luces (encima de Shade)
@export_group("Haz de luz")
beam_length: float = 260.0
beam_width: float = 150.0         # ancho al final del haz; al inicio mide 28
beam_alpha: float = 0.35          # color COLOR_WARM_LIGHT con este alfa
@export_group("Lluvia")
rain: bool = false
rain_amount: int = 120
```

### 3.3 Cómo se dibuja la oscuridad (barato y sin shaders)

- **Sombra en el mundo.** No va en pantalla: la oscuridad está exactamente donde está el tramo y el niño la ve venir.
  - `Body` es un rectángulo `(0, -cover_height/2) → (length, cover_height/2)` con `color = shade_color` y alfa `darkness`.
  - `FadeIn` y `FadeOut` son cuadriláteros de `fade_length` de ancho con `vertex_colors`: alfa 0 en la orilla de afuera y `darkness` en la de adentro.
  - Se arman en `_refresh()`, sin `_process`. Son 3 polígonos por tramo.
- **El auto nunca se oscurece.**
  - Las piezas de `Rules` se dibujan antes que `Route/PlayerCar` (mismo `z_index` 0, orden del árbol). Así la sombra queda encima de la calle, el pasto y la decoración, y debajo del auto.
  - Para el niño, su auto siempre se ve claro, y los faros que dibuje la base también.
- **Ciclistas:**
  - `Riders` va antes de `Shade`, así que sin luces los ciclistas quedan debajo de la sombra y casi no se ven. En el túnel solo se ve una silueta.
  - Con `car.headlights_on`, `Riders.z_index = lit_z_index` y los ciclistas pasan encima de la sombra.
- **Reflejantes:** al crear cada ciclista, la pieza le agrega hijos `ColorRect`, sin tocar `cyclist.gd`, con `mouse_filter = IGNORE`:
  - Chaleco `COLOR_GOLD` de 10 × 18 en (−6, −9), con dos franjas `COLOR_WHITE` de 10 × 2 en y = −5 y y = +3.
  - Luz trasera `COLOR_ADO_RED` de 3 × 6 en (−29, −3).
  - Debajo de la sombra se ven apagados; con luces brillan. Es lo que hace un reflejante de verdad.
- **Haz de luz (`Beam`):**
  - Trapecio `(30, -14), (30 + beam_length, -beam_width/2), (30 + beam_length, beam_width/2), (30, 14)` con `COLOR_WARM_LIGHT` y alfa `beam_alpha`.
  - Visible solo con el auto dentro de `Zone` y `headlights_on`.
  - Cada `_physics_process` copia `global_position` y `global_rotation` del auto.
  - Queda encima de la sombra y debajo del auto (orden del árbol).
- **Paredes (`walls = true`):** `_draw()` del propio `DarkZone` pinta dos franjas `COLOR_SIDEWALK` de `wall_width` en y = ±(road_width/2 + wall_width/2), de 0 a `length`, con un borde `COLOR_OUTLINE` de 2 px. Quedan debajo de la sombra, como piedra en penumbra.
- **Lluvia (`rain = true`, opcional según el recorte de alcance):**
  - `CPUParticles2D` en el mundo, sin textura (gotitas cuadradas).
  - Valores: `amount = rain_amount`, `lifetime = 0.5`, `emission_shape = RECTANGLE` centrado en (length/2, 0) con `emission_rect_extents = (length/2 + fade_length, cover_height/2)`, `direction = (0.25, 1)`, `spread = 5`, `gravity = (0, 0)`, `initial_velocity 600–700`, `scale_amount 2–3`, `color = COLOR_GLASS`, `z_index = lit_z_index + 1`.
  - `emitting` solo mientras el auto esté dentro de `Zone`; al salir o al reiniciar se apaga.
  - Si en el A15 baja de 60 fps, se pone `rain = false` y queda solo la sombra.
- En el editor (`@tool`) se ve la sombra completa y un rectángulo `COLOR_GOLD` con la zona, como en las demás piezas.

### 3.4 Lógica exacta (una falta y un +10 por pasada como máximo)

**Estado:**
- `_car: PlayerCar`
- `_off_time: float` (segundos seguidos sin luces)
- `_on_time: float` (segundos seguidos con luces)
- `_faulted: bool`
- `_rewarded: bool`
- `_riders: Array[Cyclist]`

**`Zone.area_entered` (auto):**
- `_car = car`, `_off_time = 0`, `_on_time = 0`, `_faulted = false`, `_rewarded = false`.
- Conecta `car.headlights_changed` → `_on_headlights_changed`.
- Crea los ciclistas (3.6).
- Llama `_update_visuals()`.

**`_physics_process(delta)`**, si `_car != null`:
- **Luces prendidas** (`_car.headlights_on`): `_on_time += delta` y `_off_time = 0`.
  - Si `_on_time >= confirm_time`, no hubo falta y no hubo +10, se marca `_rewarded = true` y se llama `_report_good_action(&"lights", MESSAGES[kind][1], points)`.
- **Luces apagadas:** `_off_time += delta` y `_on_time = 0`.
  - Si `_off_time > grace_time` y no hubo falta, se marca `_faulted = true` y se llama `_report_infraction(&"lights", MESSAGES[kind][0])`.
- Mueve `Beam` y aplica `safety_gap` (3.6).

**Consecuencias:**
- Si el auto entra con las luces ya prendidas (por ejemplo, desde el tramo anterior), gana +10 a los 0.5 s. Llevar las luces prendidas es justo el hábito.
- Si prende las luces después de la falta, no hay +10 en esa pasada.
- Si gana +10 y luego las apaga más de 2 s, también hay falta. Son como máximo una de cada una.
- El tiempo sin luces se cuenta **seguido** (igual que `speed_zone`): prender y apagar reinicia la cuenta.

**`Zone.area_exited` (auto), por delante o por detrás:**
- Desconecta la señal y `_car = null`.
- Oculta `Beam`, `Rain.emitting = false` y `Riders.z_index = 0`.
- **Salir del tramo devuelve la luz sola:** la sombra está en el mundo, no hay nada que restaurar.
- Al salir no se dan puntos, porque ya se dieron dentro.

**`_on_headlights_changed(on)`:** llama `_update_visuals()`. Esto cambia `Riders.z_index` y la visibilidad de `Beam` en el mismo cuadro: el niño ve aparecer a las bicis justo al tocar el botón.

**`_on_car_restarted()`** (lo llama `RulePiece` con `checkpoint_restored` si el punto de control está antes del tramo):
- `_car = null` y todos los contadores y banderas en cero.
- Libera a los ciclistas (`queue_free`) y vacía `_riders`.
- `Beam.visible = false`, `Rain.emitting = false`, `Riders.z_index = 0`.
- Si la señal sigue conectada, la desconecta.

**Métodos públicos para las pruebas:**
- `is_car_inside() -> bool`
- `are_riders_lit() -> bool` (es `Riders.z_index > 0`)
- `get_riders() -> Array[Cyclist]`

### 3.5 Claves y `rule_id`

**`rule_id`:** `&"lights"`, el mismo para la falta y el +10. Ya existe `REGLA_LIGHTS` ("Luces") para la pantalla de tutores.

```gdscript
const MESSAGES := {
	Kind.DUSK:   ["FALTA_LUCES",        "BIEN_LUCES"],
	Kind.TUNNEL: ["FALTA_LUCES_TUNEL",  "BIEN_LUCES_TUNEL"],
	Kind.RAIN:   ["FALTA_LUCES_LLUVIA", "BIEN_LUCES_LLUVIA"],
}
```

### 3.6 Ciclistas del tramo

- **Cuándo y dónde aparecen:** al entrar el auto se instancian `cyclist.tscn` como hijos de `Riders`.
  - Grande: uno por cada valor de `cyclist_starts`. Peque: solo los primeros `peque_cyclist_count`.
  - Posición: `Vector2(start, cyclist_offset)`, con `speed = cyclist_speed` y `end_x = length + cyclist_end_margin`.
  - Como aparecen al entrar el auto, siempre están delante de él y en el tramo oscuro.
- **Nunca se toca a nadie** (regla de `CLAUDE.md`):
  - En cada `_physics_process`, si el auto está en el carril de la ciclovía (`_car.lane_index == 1`) y un ciclista está entre 0 y `safety_gap` px delante del auto (en x local), la pieza llama `_car.add_stop_request(self)`.
  - Cuando ya no se cumple, llama `remove_stop_request(self)`, y también al salir y al reiniciar.
  - No da una falta extra: meterse a la ciclovía ya es falta de `bike_lane`.
  - Es el mismo patrón que usa `crosswalk` con los peatones.

## 4. Lo que el nivel necesita de la base técnica (fase 2, punto 4)

Es lo mínimo que esta ficha supone. Si la base usa otros nombres, solo se cambian aquí.

1. **`player_car.gd`:**
   - `var headlights_on: bool = false`
   - `signal headlights_changed(on: bool)`
   - `func set_headlights(on: bool) -> void`: cambia la propiedad y emite la señal solo si cambió.
   - Lee la acción de input **`car_lights`** (`is_action_just_pressed`) y alterna las luces: `set_headlights(not headlights_on)`.
   - Las luces **no** se apagan en `restart_at()`.
   - Funciona igual en Peque y en Grande.
   - Si la base dibuja faros (cono o sprite), bien. `dark_zone` dibuja su propio haz dentro de los tramos, así que el nivel no depende de eso.
2. **`hud.gd` / `hud.tscn`:**
   - `@export var show_lights_button: bool = false`
   - Un `TouchScreenButton` `%Lights` con `action = "car_lights"` (como `Seatbelt`) e ícono #16 de `docs/prompts_assets.md`, apagado o encendido según `car.headlights_changed`.
   - Solo se ve si `show_lights_button` es `true`, y en los dos modos. El nivel 7 lo pone en `true` sobrescribiendo la propiedad del nodo `Hud` en `level_07.tscn`.
3. **`project.godot`:** la acción `car_lights` (tecla `L` para probar en el editor).
4. **`tests/test_levels.gd`** (también es de la base): el conductor cuidadoso tiene que **prender las luces al empezar** cuando el nivel tenga algún `DarkZone` en `Rules`, con `car.set_headlights(true)` o `tap(&"car_lights")`. Sin esto, el nivel 7 no se puede terminar con 3 estrellas en la prueba general.

## 5. Momentos (ritmo y clímax)

Los tiempos son aproximados para Grande a ~150–160 px/s. Peque va a 168 px/s en calle libre y a 84 px/s en el túnel; el total da casi lo mismo.

| t (s) | Momento | Qué siente el niño |
| --- | --- | --- |
| 0–2 | Cinturón. La calle está tibia, color de atardecer. Aparece el botón de luces | "Hay un botón nuevo" |
| ~4 | `TUTO_LUCES`: el copiloto pide prender las luces y la calle de adelante ya se ve más oscura | Curiosidad: lo toca |
| ~6–8 | Entra al **atardecer**: con luces, las bicis aparecen con el chaleco brillando | El porqué, visto con sus ojos |
| **~8–10** | **Primer +10** (`BIEN_LUCES`). Si no las prendió, falta a los 2 s y el copiloto explica | Recompensa rápida |
| ~13 | `TUTO_REFLEJANTE`: "las bicis traen chaleco que brilla con tus luces" | Se refuerza el porqué |
| ~15 | Sale del tramo: +10 por la ciclovía | Ritmo de premios |
| 15–22 | Respiro con luz. `TUTO_TUNEL` avisa del túnel | Anticipación |
| 22–38 | **Clímax, el túnel:** letrero de 30 km/h, el cerro con la boca, paredes de piedra y la sombra más fuerte (0.78). Sin luces no se ve casi nada; con luces, el haz alumbra dos ciclistas lentos | Tensión suave: ir despacio y mirar |
| ~38 | Sale del túnel: +10 por la velocidad y +10 por la ciclovía; la luz regresa sola | Alivio y celebración |
| 40–48 | `TUTO_LLUVIA`: empieza a llover | Último reto, más fácil |
| 48–57 | **Lluvia:** gotitas, sombra media y ciclistas con reflejantes; +10 de luces y +10 de ciclovía | Lo hace solo, ya lo aprendió |
| ~60–65 | Llega a **casa**. Tarjeta de hábito: "Si te ven, te cuidan." | Cierre cálido |

**La curva de dificultad:**
1. Atardecer: se enseña con aviso y sombra ligera.
2. Túnel: el reto más fuerte, suma oscuridad, velocidad y bicis lentas delante.
3. Lluvia: se practica sin presión.

## 6. Peque vs Grande (solo cambia el tráfico)

Las reglas son **las mismas**: en Peque también hay que tocar el botón de luces, con el mismo `grace_time` de 2 s. Lo que cambia:

| | Peque | Grande |
| --- | --- | --- |
| Ciclistas por tramo | 1 (`peque_cyclist_count = 1`): 3 en total | 2 por tramo: 6 en total |
| Velocidad | El auto avanza solo al 70 % del límite: 84 px/s en el túnel | Los dos pedales; el límite de 30 km/h es la tentación |
| Textos | Los mismos (`peque_message_key` vacío) | — |

No hay `npc_car` en este nivel: el tramo oscuro y las bicis ya son bastante para leer la pantalla.

## 7. Textos nuevos (`i18n/textos.csv`)

Formato del archivo: `CLAVE,texto`, con comillas cuando hay comas.

```csv
DESTINO_CASA,Casa
TUTO_LUCES,"Se está haciendo de noche. Toca el botón para prender las luces."
TUTO_REFLEJANTE,"Las bicis traen chaleco que brilla cuando tus luces lo alumbran."
TUTO_TUNEL,"Ahí viene el túnel y adentro está oscuro. ¿Ya prendiste tus luces?"
TUTO_LLUVIA,"Empezó a llover y se ve poquito. Con luces, todos te ven."
FALTA_LUCES,"¡Está oscuro! Prende las luces para que las bicis te vean."
BIEN_LUCES,"¡Muy bien! Con tus luces prendidas, todos te ven."
FALTA_LUCES_TUNEL,"En el túnel no se ve nada. Prende las luces para que te vean."
BIEN_LUCES_TUNEL,"¡Bien! En el túnel, tus luces avisan que ahí vas."
FALTA_LUCES_LLUVIA,"Con lluvia cuesta ver. Prende las luces para que te cuiden."
BIEN_LUCES_LLUVIA,"¡Bien! Con lluvia, tus luces te hacen visible."
BOTON_LUCES,Luces
```

- Todos tienen 14 palabras o menos y explican el porqué ("para que te vean").
- Usan "prender", que es más natural en México que "encender".
- `BOTON_LUCES` es para la base, por si el botón lleva etiqueta o texto de accesibilidad. Si el botón es solo ícono, la clave igual sirve para la voz.
- Cada clave lleva su voz en `assets/audio/voz/<CLAVE>.ogg` (provisional con espeak-ng).

## 8. Pruebas a escribir

**Archivo nuevo:** `tests/test_dark_zone.gd` (`extends TestCase`), con el mismo patrón que `test_patience.gd`.
- Abre `res://levels/level_07.tscn`, pone `car.seatbelt_on = true` y usa `TestDriver`.
- `DarkDusk` está en x = 1000, es decir, en progreso 936.

1. **Sin luces, falta:**
   - `restart_at(700)`, luces apagadas, avanzar a 150 px/s.
   - Debe llegar `infraction_reported(&"lights")` una sola vez.
   - Solo después de > 2 s dentro: el auto ya pasó progreso ~936 + 300.
2. **Una falta por pasada:** sigue sin luces hasta salir de `DarkDusk`. Sigue habiendo una sola falta `lights` y ningún `good_action` `lights`.
3. **Con luces a tiempo, +10:**
   - `restart_at(700)` y prender las luces al entrar (progreso ≥ 940), con `set_headlights(true)`.
   - Debe llegar `good_action_reported(&"lights", 10)` y ninguna falta `lights`.
4. **Entrar ya con luces, +10:** prender en progreso 700 y luego entrar. Da +10 a los ≥ 0.5 s.
5. **Prender tarde no premia:** entrar sin luces, esperar la falta y prenderlas. No hay +10 en esa pasada.
6. **Ciclistas visibles solo con luces:**
   - Dentro de `DarkDusk` sin luces: `get_riders().size() == 2` en Grande y `are_riders_lit() == false`.
   - `set_headlights(true)` → `are_riders_lit() == true` en el mismo cuadro.
   - Al salir del tramo, `false` otra vez.
7. **Peque, un ciclista:** con `GameState.mode = MODE_PEQUE`, `get_riders().size() == 1`. La falta sin luces sigue igual: mismas reglas.
8. **Salir devuelve la luz:** después de salir, `is_car_inside() == false`, `Beam` oculto y `Rain.emitting == false` (en `DarkRain`).
9. **Punto de control:**
   - Entrar sin luces a `DarkTunnel` y provocar la falta.
   - Llamar `rm.checkpoint_restored.emit(CheckpointAfterDusk.progress)`, o `car.restart_at(2236)` más la señal.
   - La pieza vuelve al estado inicial: sin ciclistas y sin estado. Al volver a entrar puede dar falta otra vez.
10. **Nunca toca a un ciclista:**
    - En `DarkDusk`, poner el auto en carril 1 (`lane_index = 1`) detrás de un ciclista y acelerar.
    - Verificar que el auto nunca queda a menos de 40 px del ciclista en x.
    - Debe aparecer la falta `bike_lane` y ninguna otra.
11. **Recorrido completo:** lo cubre `test_levels.gd` cuando la base agregue el punto 4 de §4. Debe dar 3 estrellas y 0 faltas en Peque y en Grande.

## 9. Arte usado (solo lo que ya existe)

| Uso | Archivo |
| --- | --- |
| Boca del túnel, entrada y salida (decoración arriba de la calle) | `assets/sprites/city/tunel_entrada.png`, `assets/sprites/city/tunel_salida.png` |
| Destino: casa | `assets/sprites/city/casas.png` (región de la primera casa) |
| Ciclistas | `assets/sprites/vehicles/cyclist_frames.tres` (por medio de `scenes/actors/cyclist.tscn`) |
| Letrero de 30 km/h | `assets/sprites/signals/signs.png` (de `speed_zone`) |
| Calle, pasto y meta | `assets/tiles/street_tiles.tres` (de `LevelBuilder`) |
| Tarjeta de hábito | `assets/ui/habit_cards/card_07.png` (ya está en `level_07.tres`) |

**Dibujado por código, con colores de la paleta y sin imagen:**
- Sombra, degradados y haz de luz.
- Paredes del túnel.
- Chaleco reflejante y luz trasera del ciclista.
- Gotas de lluvia.
- Tinte de atardecer (`CanvasModulate`).

**Provisionales (cuando llegue el arte final, se cambian sin tocar la lógica):**
- **Botón de luces:** ícono #16 de `docs/prompts_assets.md`, pendiente. Mientras tanto, la base usa uno provisional.
- **Ciclista con casco y reflejantes:** prompt #4 de `docs/prompts_fase3.md`. Mientras tanto, `cyclist_frames.tres` con los `ColorRect` reflejantes.
- **Charcos y gota:** prompt #3 de `docs/prompts_fase3.md`. Fuera de alcance por el recorte; la lluvia son partículas sin textura.
- **Túnel visto desde arriba:** los sprites actuales están en 3/4. Si se pide arte nuevo, sería un techo o una boca de túnel en vista cenital de 256 px de alto.
