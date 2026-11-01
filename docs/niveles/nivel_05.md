# Nivel 5 · Sin prisa

Ficha de diseño (fase 1 del `docs/plan_cierre.md`). Roles: game-designer + level-designer + writer. Revisa: creative-director.

## 1. Resumen y objetivo

| Campo | Valor |
| --- | --- |
| Decálogo | 2 · No normalices la prisa |
| Diseño | "Hay un reloj para llegar a la terminal, pero siempre se llega a tiempo manejando bien. También hay semáforos en amarillo y una pelota que sale a la calle." |
| Se evalúa | Velocidad segura y frenar en amarillo |
| Frase | "Llegar bien es mejor que llegar rápido." (`FRASE_05`) |
| Destino | Terminal de autobuses (`DESTINO_TERMINAL`, `assets/sprites/city/terminal.png`) |
| Duración | 1:05 en Grande y 1:20 en Peque, con un conductor cuidadoso |
| Puntos máximos | 60 (6 acciones de +10) |

**Historia en una línea:** vamos en familia a la terminal a tomar el autobús. Desde el inicio, un tablero de salidas en la esquina dice "A tiempo" y nunca cambia. En el camino hay dos semáforos que se ponen en amarillo justo cuando llegamos y una calle con autos estacionados de donde sale una pelota y, detrás de ella, una niña. Al llegar, el copiloto dice "¡Llegamos a tiempo!".

**Lo que el niño aprende:** no hay que correr para llegar a tiempo. La pelota (el clímax) muestra el porqué: si vas despacio, alcanzas a frenar.

**Reglas:** las del diseño, sin agregar ninguna:
- Amarillo (`yellow`), nueva en este nivel.
- Límite de velocidad (`speed`, repaso del nivel 2).
- Semáforo en rojo (`red_light`, repaso del nivel 2).
- Peatón, falta grave (`crosswalk`, repaso del nivel 1). La pelota usa esta misma regla.

**Piezas nuevas:**
- `ball_event`: la pieza que pidió el sprint.
- `yellow_crossing`: un cruce con semáforo que se pone en amarillo cuando llega el auto. Hace falta porque un `traffic_light` normal cambia con su propio reloj y no garantiza que el niño vea el amarillo.
- `departure_board`: el tablero de salidas. No es una regla, solo se muestra.

Ninguna toca `hud.tscn`, `player_car.gd` ni `traffic_light.gd`.

**Datos (`data/level_05.tres`):**
- `scene_path = "res://levels/level_05.tscn"`.
- **Corrección:** hoy dice `decalogo_key = "DECALOGO_05"` ("Comparte el camino"), pero el diseño pone el decálogo 2 en este nivel. Tiene que ser `"DECALOGO_02"` ("No normalices la prisa").
- Lo mismo pasa en los niveles 2 (debe ser `DECALOGO_04`), 4 (`DECALOGO_08`) y 8 (`DECALOGO_05`). Se avisa al creative-director; esta ficha no los cambia.

## 2. Recorrido

Es una calle recta como en los niveles 1 a 4: el auto avanza hacia +x, con 2 carriles de 64 px (y de −64 a 64) y empieza en el carril derecho (`start_lane = 1`).

- **Cómo se arma:** `LevelBuilder.new("Level05", 103, 1, 5, 95)`, es decir, 103 tiles, semilla 5 y casas solo hasta el tile 95, para dejar libre el lugar de la terminal. Después se corre `python3 tools/make_inherited.py levels/level_05.tscn`.
- **Ruta:** de (64, 0) a (6560, 0). **Largo total: 6496 px** de progreso (103 tiles). El progreso de una pieza es su x − 64.
- **Velocidades de referencia:** `max_speed` = 240 px/s (60 km/h) y `PX_PER_KMH` = 4. En Peque el auto avanza solo al 70 %: 168 px/s en la calle, 112 en la zona de 40 y 84 en la de 30. El freno es de 300 px/s².

### Tramos

| # | Tramo | x (px) | Qué pasa |
| --- | --- | --- | --- |
| A | Salida | 64 – 640 | Cinturón, arranque y el copiloto presenta el tablero |
| B | Calle de 40 | 640 – 1536 | Repaso del límite. Primer +10 |
| C | Primer amarillo (enseña) | 1700 – 2752 | Aviso del copiloto y semáforo que se pone en amarillo al llegar |
| D | Segundo amarillo (tentación) | 2944 – 3904 | El copiloto recuerda que vamos a tiempo; el amarillo sale un poco más cerca |
| E | Calle de los autos estacionados (clímax) | 4096 – 5440 | Un carril, límite 30, la pelota y la niña |
| F | Llegada a la terminal | 5440 – 6560 | Paso peatonal frente a la terminal, tablero en la banqueta y meta |

### Piezas, en orden

Todas van en `Rules` con `y = 0`, salvo las que se indican. Los valores que no aparecen se quedan con su valor por defecto.

| # | Nodo | Escena | x | Valores exportados |
| --- | --- | --- | --- | --- |
| 1 | `HintIntro` | `tutorial_hint.tscn` | 256 | `message_key = "PRISA_INTRO"` |
| 2 | `SpeedZone40` | `speed_zone.tscn` | 640 | `kind = STREET (0)`, `limit_kmh = 40`, `zone_length = 896.0` (termina en 1536) |
| 3 | `HintYellow` | `tutorial_hint.tscn` | 1728 | `message_key = "PRISA_AMARILLO_AVISO"`, `peque_message_key = "PRISA_AMARILLO_AVISO_PEQUE"` |
| 4 | `YellowCrossing1` | `yellow_crossing.tscn` (nueva) | 2432 | `trigger_distance = 420.0` (dispara en x = 2012), `yellow_time = 3.0`, `red_time = 4.0`. El resto por defecto (ver §3b) |
| 5 | `CheckpointAfterLight1` | `checkpoint.tscn` | 2752 | — |
| 6 | `HintBoard` | `tutorial_hint.tscn` | 2944 | `message_key = "PRISA_TABLERO_AVISO"` |
| 7 | `YellowCrossing2` | `yellow_crossing.tscn` | 3584 | `trigger_distance = 360.0` (dispara en x = 3224), `yellow_time = 3.0`, `red_time = 4.0` |
| 8 | `CheckpointAfterLight2` | `checkpoint.tscn` | 3904 | — |
| 9 | `OneLane` | `StreetSection` (**hijo de `Route`**, no de `Rules`) | 4096 | `lane_count = 1`. El auto se acomoda solo al centro (y = 0) |
| 10 | `CheckpointBallStreet` | `checkpoint.tscn` | 4128 | — (después de la falta grave se vuelve aquí: queda 350 px antes del disparo de la pelota) |
| 11 | `HintBallStreet` | `tutorial_hint.tscn` | 4176 | `message_key = "PELOTA_CALLE_AVISO"` |
| 12 | `SpeedZone30` | `speed_zone.tscn` | 4256 | `kind = STREET (0)`, `limit_kmh = 30`, `zone_length = 1088.0` (termina en 5344) |
| 13 | `BallEvent` | `ball_event.tscn` (nueva) | 4800 | `trigger_distance = 280.0` (dispara en x = 4520). El resto por defecto (ver §3) |
| 14 | `CheckpointAfterBall` | `checkpoint.tscn` | 5408 | — |
| 15 | `TwoLanes` | `StreetSection` (hijo de `Route`) | 5440 | `lane_count = 2` |
| 16 | `CrosswalkTerminal` | `crosswalk.tscn` | 5952 | `approach_length = 448.0`, `start_delay = 0.3`. Con hijos editables: `Pedestrian.sprite_frames = adult_frames.tres` (gente que va a su autobús) |
| 17 | `CheckpointAfterCrosswalk` | `checkpoint.tscn` | 6208 | — |
| 18 | `DepartureBoard` | `departure_board.tscn` (nueva) | 6304, **y = −160** | Valores por defecto (ver §4). Va sobre la banqueta de arriba, frente a la terminal |

**Decor** (`Decor`, `Sprite2D`):
- `Terminal`: `assets/sprites/city/terminal.png` en (6400, −300). Mide 322 × 190, así que ocupa x 6239–6561 y y −395 a −205.
- 2 árboles de `arboles.png` (región de 64 × 64) en (6176, −224) y (6624, −224).

**Meta:** el cuadro de meta del constructor queda en el último tile (x 6528–6592), en la entrada de la terminal.

## 3. Pieza nueva `ball_event`

Archivos: `scenes/rules/ball_event.gd` y `.tscn`, con `class_name BallEvent extends RulePiece` y `@tool`.

**Para qué sirve:** es el clímax del nivel. Entre autos estacionados sale una pelota rodando y, detrás de ella, una niña que la persigue. Si el auto va despacio, alcanza a frenar; si va rápido, no.

Funciona igual que `crosswalk`:
- La calle está "ocupada" desde que sale la pelota hasta que la niña llega a la otra banqueta.
- Si el auto entra a la zona ocupada, frena solo antes de tocar a nadie: falta grave.
- Si se detiene antes, da +10.

**Origen y sentido:** el origen es el punto por donde la pelota cruza el centro de la calle. El auto llega desde −x y +y es la derecha del auto, donde están los autos estacionados.

### Nodos de la escena

| Nodo | Tipo | Para qué |
| --- | --- | --- |
| `Zone` | `Area2D` + `RectangleShape2D` (`resource_local_to_scene`) | Zona de falta: `Rect2(-crossing_width/2 - fault_margin, -road_width/2, crossing_width + fault_margin, road_width)` |
| `Approach` | `Area2D` + rectángulo (local) | Disparo y espera: `Rect2(-trigger_distance, -road_width/2, trigger_distance - crossing_width/2 - fault_margin, road_width)` |
| `Child` | instancia de `scenes/actors/pedestrian.tscn` | La niña. `sprite_frames = child_frames` y `walk_speed = child_speed` en `_ready()`. Empieza oculta |
| `ChildStart` | `Marker2D` | (0, 100): banqueta, entre los dos autos del hueco |
| `ChildEnd` | `Marker2D` | (0, −120): banqueta de enfrente, junto a donde se detiene la pelota |
| `ChildExit` | `Marker2D` | (200, −120): se va por la banqueta con su pelota |

La pelota y los autos estacionados se dibujan en `_draw()`, igual que la cebra de `crosswalk`. Así se ven en el editor y no hace falta arte nuevo.

### @export

| Variable | Tipo | Valor por defecto | Para qué |
| --- | --- | --- | --- |
| `road_width` | float | 128.0 | Ancho de la calle (setter → `_refresh()`) |
| `crossing_width` | float | 64.0 | Ancho de la franja por donde cruzan la pelota y la niña (setter → `_refresh()`) |
| `fault_margin` | float | 16.0 | Igual que en `crosswalk`: desde aquí el auto "ya entró" y frena solo (setter → `_refresh()`) |
| `trigger_distance` | float | 280.0 | Distancia antes del origen donde el auto hace que salga la pelota (setter → `_refresh()`) |
| `ball_start` | Vector2 | (0, 90) | Dónde aparece la pelota, en el hueco entre autos |
| `ball_end` | Vector2 | (0, −150) | Dónde se detiene, en la banqueta de enfrente |
| `ball_speed` | float | 200.0 | px/s rodando |
| `ball_radius` | float | 9.0 | Tamaño del dibujo |
| `child_frames` | SpriteFrames | `girl_frames.tres` | Quién persigue la pelota. Los textos dicen "la niña" |
| `child_delay` | float | 0.6 | Segundos entre que sale la pelota y aparece la niña |
| `child_speed` | float | 60.0 | px/s. Despacio a propósito, para que la calle siga ocupada cuando llega el auto, sobre todo en Peque |
| `parked_car_x` | Array[float] | [−427, −337, −247, −157, −67, 67, 157, 247, 337] | Centros de los autos estacionados. Dejan un hueco de 64 px en el origen |
| `parked_car_y` | float | 46.0 | Lado derecho, pegados a la banqueta |
| `parked_colors` | Array[Color] | `Palette.COLOR_GLASS`, `COLOR_GOLD`, `COLOR_GREEN`, `COLOR_SKY_MID`, `COLOR_WHITE` | Los mismos de `blind_crossing`, en ciclo. No se escriben colores sueltos |
| `stop_speed` | float | 10.0 | Por debajo de esto el auto cuenta como detenido |
| `points` | int | 10 | Puntos al frenar a tiempo |

Constante: `PARKED_CAR := preload("res://assets/sprites/vehicles/npc_car.png")`, dibujado con `draw_texture(..., modulate)` centrado en cada punto.

### Estados

```
IDLE → BALL → CHILD → CLEAR → GONE
```

| Estado | Qué se ve | ¿Ocupada? |
| --- | --- | --- |
| `IDLE` | Solo los autos estacionados. La pelota y la niña están ocultas | No |
| `BALL` | La pelota rueda de `ball_start` a `ball_end` (`move_toward` a `ball_speed`, con una raya que gira para que se note que rueda). A los `child_delay` s pasa a `CHILD` | **Sí** |
| `CHILD` | La niña aparece en `ChildStart` y camina a `ChildEnd` | **Sí** |
| `CLEAR` | La niña llegó (`arrived`): la pelota se oculta (ya la recogió) y camina a `ChildExit` | No |
| `GONE` | Llegó a `ChildExit` y llama a `fade_out()` | No |

`func is_occupied() -> bool: return _state == State.BALL or _state == State.CHILD`.

Si la pelota llega a `ball_end` antes de que termine el estado `BALL`, se queda quieta ahí y sigue visible.

### Condiciones exactas

- **Disparo:** con `Approach.area_entered` del auto y el estado en `IDLE`, se guarda `_car`, se pone `_car_in_approach = true` y se pasa a `BALL`. El temporizador de la niña es `get_tree().create_timer(child_delay, false)` atado a `_round`, como en `crosswalk`. `Approach.area_exited` pone `_car_in_approach = false`.
- **Acierto (+10):**
  - En `_physics_process`: si `_car_in_approach and is_occupied() and not _faulted and _car.speed <= stop_speed`, entonces `_yielded = true`.
  - Cuando la niña llega a `ChildEnd` (pasa de `CHILD` a `CLEAR`): si `_yielded and not _faulted`, se llama `_report_good_action(&"crosswalk", "BIEN_PELOTA", points)`.
- **Falta grave:**
  - Con `Zone.area_entered` del auto, si `is_occupied() and not _faulted`:
    - `_faulted = true`
    - `car.emergency_stop()`
    - `car.add_stop_request(self)`
    - si la niña ya es visible, `Child.scare()`; si todavía está en `BALL`, se pasa a `CHILD` en ese momento y se asusta al aparecer
    - `_report_infraction(&"crosswalk", "FALTA_PELOTA", true)`
  - Es una sola falta por pasada.
  - Al llegar la niña a `ChildEnd`, si `_faulted`, se llama `_car.remove_stop_request(self)`. Normalmente el `RuleManager` ya regresó el auto al punto de control.
- **Entrar a la zona sin que esté ocupada** (antes del disparo o después de `CLEAR`) no tiene ningún efecto.
- **Por qué es justo:** el disparo queda 232 px antes de la zona.

  | Auto | Velocidad | Tiempo hasta la zona | Distancia para frenar |
  | --- | --- | --- | --- |
  | Grande al límite (30 km/h) | 120 px/s | 1.9 s | 24 px |
  | Peque | 84 px/s | 2.8 s | 12 px |
  | Grande a 60 km/h | 240 px/s | 0.97 s | 96 px (casi no da tiempo) |

  La calle queda ocupada 0.6 + 220/60 ≈ **4.3 s**, así que en Peque tampoco se puede pasar sin frenar.

  Esa es la lección: **despacio sí alcanzas a frenar.**
- **`rule_id`:**
  - Se usa `&"crosswalk"`, que es la regla del diseño "Peatón… Falta grave". Así no hace falta una regla nueva ni cambiar `TutorsScreen.kt` ni la app de iOS.
  - Si el equipo quiere ver la pelota aparte en Tutores, se usaría `&"ball"` con la clave `REGLA_BALL,Pelota en la calle` y su línea en las dos apps nativas. **No se recomienda.**
- **Mensajes:** `FALTA_PELOTA` y `BIEN_PELOTA` (ver §7).

### Punto de control (`_on_car_restarted`)

`RulePiece` lo llama cuando el auto vuelve a un punto anterior a la pieza. Ahí:
- `_round += 1`, para que el temporizador de una pasada anterior no haga nada.
- Si hay `_car`, `remove_stop_request(self)`.
- `_state = IDLE`, `_faulted = false`, `_yielded = false`, `_car_in_approach = false`.
- La pelota regresa a `ball_start` y se oculta.
- `Child.reset_at(ChildStart.position)` y luego `Child.hide()`.

Así, después de la falta grave, la situación se repite completa desde `CheckpointBallStreet`.

### Peque y Grande

Es idéntico en los dos modos: sale la pelota y sale la niña.
- En Peque, "frenar a tiempo" es tocar el freno. Si el niño lo suelta mientras la niña sigue cruzando, el auto avanza solo y puede entrar a la zona: es falta grave, igual que en `crosswalk`.
- No depende de la propiedad nueva de "dejar avanzar"; solo usa `speed`.

### Lo que usa de lo que ya existe

- Igual que `crosswalk`: `emergency_stop()`, `add_stop_request`/`remove_stop_request`, `Pedestrian.walk_to`/`scare`/`reset_at`/`fade_out`, `_set_rect` y `_car_from`.
- La lógica de `_yielded`/`_faulted` se copia de `crosswalk.gd`.

### Para las pruebas de recorrido

Expone `func careful_stop_x() -> float: return position.x - crossing_width / 2.0 - fault_margin - 40.0` (ver §8, pedido a la base técnica).

## 3b. Pieza nueva `yellow_crossing`

Archivos: `scenes/rules/yellow_crossing.gd` y `.tscn`, con `class_name YellowCrossing extends RulePiece` y `@tool`.

**Para qué sirve:** que el amarillo **siempre** aparezca cuando el auto se acerca. Un `traffic_light` normal cambia con su reloj desde que empieza el nivel, y el niño podría no ver nunca el amarillo.

Copia el patrón de `patience_zone`:
- Tiene un `TrafficLight` hijo que no cambia solo (todos sus tiempos en 99999) y esta pieza lo cambia con `set_light()`.
- La regla del amarillo sigue en `traffic_light.gd` (`check_yellow`), incluida la versión de Peque que agrega la base técnica. **Esta pieza no evalúa el amarillo; solo lo pone a tiempo.**

**Origen:** es la línea de alto, igual que en `traffic_light`. El auto llega desde −x. La calle que cruza va de x = `line_gap` a `line_gap + cross_width`.

### Nodos

| Nodo | Tipo | Valores |
| --- | --- | --- |
| `Light` | instancia de `traffic_light.tscn` en (0, 0) | `start_light = GREEN`, `check_yellow = true`, `give_points = false`, `reaction_time = 1.0`, `zone_length = 320.0`, `green_time = yellow_time = red_time = 99999.0` |
| `Trigger` | `Area2D` (rectángulo local) | `Rect2(-trigger_distance, -road_width/2, trigger_distance, road_width)`: desde el disparo hasta la línea |
| `Line` | `Area2D` | `Rect2(-8, -road_width/2, 8, road_width)` |
| `Box` | `Area2D` | El cruce: `Rect2(line_gap, -road_width/2, cross_width, road_width)` |

### @export

| Variable | Valor por defecto | Para qué |
| --- | --- | --- |
| `road_width` | 128.0 | |
| `trigger_distance` | 420.0 | Distancia antes de la línea donde la luz pasa a amarillo |
| `yellow_time` | 3.0 | Amarillo largo, como pide el sprint |
| `red_time` | 4.0 | Mínimo en rojo. El verde llega cuando además el cruce está libre |
| `line_gap` | 24.0 | De la línea a la orilla de la calle que cruza |
| `cross_width` | 128.0 | |
| `cross_length` | 700.0 | Cuánto se dibuja la calle que cruza hacia cada lado |
| `cross_car_speed` | 160.0 | |
| `spawn_distance` | 420.0 | A qué distancia del centro de la calle aparecen los autos que cruzan (fuera de la pantalla) |
| `first_spawn_delay` | 0.5 | Segundos después de que se pone el rojo |
| `spawn_spacing` | 1.2 | Segundos entre autos del mismo rojo |
| `cars_per_red_grande` | 2 | Tráfico en Grande |
| `cars_per_red_peque` | 1 | Tráfico en Peque (la única diferencia entre modos) |
| `stop_speed` | 10.0 | |
| `points` | 10 | |

### Estados

```
ARMED → YELLOW → RED → GREEN_DONE
```

- **`ARMED`:** la luz está en verde. Con `Trigger.area_entered` del auto, se guarda `_car`, se llama `Light.set_light(YELLOW)` y se pasa a `YELLOW`.
- **`YELLOW`:** a los `yellow_time` s, `Light.set_light(RED)` y se pasa a `RED`.
- **`RED`:**
  - Salen `cars_per_red` autos que cruzan.
    - Usan `npc_car.tscn` sobre 2 `Path2D` propios, uno por sentido, a ±32 px del centro de la calle que cruza. Se copia `_build_traffic_paths()` y `spawn_car()` de `blind_crossing.gd`.
    - Los sentidos se alternan.
    - No sale ningún auto mientras el auto del jugador está dentro de `Box`.
  - Cuando pasan `red_time` s, ya salieron todos los autos y `is_busy()` es falso, se llama `Light.set_light(GREEN)` y se pasa a `GREEN_DONE`.
- **`GREEN_DONE`:** se queda en verde. No vuelve a cambiar en esta pasada.

`func is_busy() -> bool`: hay un auto que cruza dentro de `Box` agrandado 48 px hacia cada lado de la calle que cruza.

### Seguridad, para que nunca haya choques

- **Si el jugador entra a `Box` mientras `is_busy()`:** `add_stop_request(self)` y se quita cuando el cruce queda libre. Es lo mismo que hace `blind_crossing`, y no hay otra falta además de la de rojo que ya marcó la luz.
- **Si el jugador ya está dentro de `Box`:** los autos que cruzan frenan solos con su `Sensor`.

### Acierto (+10)

1. Desde que se pone en amarillo, si el auto está dentro de `Trigger` (antes de la línea) y `speed <= stop_speed`, se pone `_waited = true`.
2. Mientras la pieza no está en `ARMED`, escucha `RuleManager.infraction_reported`. Si llega `&"yellow"` o `&"red_light"` mientras el auto está en `Trigger` o en `Line`, se pone `_faulted = true`.
3. Con `Line.area_entered` del auto: si la luz está en `GREEN` y `_waited and not _faulted`, se llama `_report_good_action(&"yellow", "BIEN_AMARILLO", points)`. Una sola vez por pasada.

### Faltas

Las pone el `TrafficLight` hijo, sin cambios:
- `yellow` / `FALTA_AMARILLO` si el auto sigue "dejando avanzar" (Grande: pisa el verde; Peque: no frena) más de 1.0 s dentro de los 320 px antes de la línea, con la luz en amarillo.
- `red_light` / `FALTA_ROJO` si cruza la línea en rojo.

Cruzar en amarillo sin acelerar (en Grande, soltando los pedales) no es falta. El diseño dice "acelera en vez de frenar".

### Punto de control (`_on_car_restarted`)

- Se borran los autos que cruzan (`queue_free`).
- `remove_stop_request(self)`.
- `Light.set_light(GREEN)`.
- `_state = ARMED`, `_waited = false`, `_faulted = false` y se reinician los temporizadores.

Para las pruebas de recorrido expone:
- `func careful_stop_x() -> float: return position.x - 45.0`
- `func must_wait() -> bool: return Light.light != TrafficLight.Light.GREEN or is_busy()`

## 4. Tablero de salidas (`departure_board`)

Archivos: `scenes/rules/departure_board.gd` y `.tscn`, con `class_name DepartureBoard extends RulePiece` y `@tool`. **No toca `hud.tscn` ni `player_car.gd`.**

El tablero **nunca** cuenta hacia atrás, no muestra números ni horas y no cambia de "A tiempo". Es la tentación del diseño, pero sin presión: no se puede perder por tiempo.

### 1. Widget en pantalla

Es un `CanvasLayer` propio, hijo de la pieza, con `layer = 2`: arriba del HUD y abajo de la burbuja del copiloto (que está en 10).
- Un `PanelContainer` con `theme = assets/ui/theme.tres` y la variación `TopBarPill`, en `widget_position` = (16, 88), con un ancho mínimo de 200 px. Queda debajo de la barra superior, a la izquierda, sin tapar la burbuja (x 200–1080) ni el engrane (a la derecha).
- Adentro, un `VBoxContainer` con:
  1. `Label` `tr("TABLERO_TITULO")` → "Salidas" (chico, dorado `COLOR_GOLD`, desde el tema).
  2. Una fila (`HBoxContainer`) con:
     - `Label` `tr("TABLERO_AUTOBUS")` → "Nuestro autobús"
     - un punto verde (`ColorRect` de 12 × 12 con `COLOR_GREEN`) que late suave: un `Tween` en bucle con `modulate:a` entre 1.0 y 0.5 cada `blink_interval`
     - `Label` `tr("TABLERO_A_TIEMPO")` → "A tiempo"
- `mouse_filter = IGNORE` en todo, para no robar toques.
- `process_mode` normal, para que se congele con la pausa de las faltas.

### 2. Letrero en el mundo

En `_draw()`, sobre la banqueta frente a la terminal, se dibuja un tablero de 144 × 64:
- fondo `COLOR_DARK_PURPLE`, borde `COLOR_ADO_RED` de 3 px y patas `COLOR_SHADOW`
- encima, los mismos 3 textos con `draw_string` y `ThemeDB.fallback_font`, como los números de `speed_zone`, siempre con `tr()`
- el texto "A tiempo" en `COLOR_GREEN`

Cuando el auto llega, el niño ve en grande el mismo tablero que traía en la esquina.

### @export

| Variable | Valor por defecto |
| --- | --- |
| `show_widget` | true |
| `show_in_peque` | true (ver §6) |
| `widget_position` | Vector2(16, 88) |
| `blink_interval` | 0.8 |
| `board_size` | Vector2(144, 64) |
| `arrival_message_key` | `"LLEGADA_A_TIEMPO"` |

### Comportamiento

- **En `_ready()`:**
  - crea el widget si `show_widget`, y en Peque solo si además `show_in_peque`;
  - se conecta a `RuleManager.level_finished`, después del `RuleManager` (con `call_deferred`, como `RulePiece`).
- **Con `level_finished`:**
  - llama `Feedback.show_good_action(arrival_message_key, 0)`. Pasa en el mismo cuadro en que el `RuleManager` muestra `META_LLEGASTE`, así que lo reemplaza: el copiloto dice "¡Llegamos a tiempo!" con cara feliz;
  - el widget hace un pequeño "pop" (escala 1.15 → 1.0 en 0.2 s).
  - La tarjeta de hábito abre 1.2 s después (`open_delay`) y luego dice `FRASE_05`.
  - Hay un precedente de una pieza que llama a `Feedback` directo: `tutorial_hint.gd`.
- **Punto de control:** no hace nada.

## 5. Momentos (ritmo)

Tiempos aproximados en Grande con un conductor cuidadoso (Peque, en paréntesis).

| Tiempo | x | Momento | Para el niño |
| --- | --- | --- | --- |
| 0:00 | 64 | Cinturón y arranque. Aparece el tablero "A tiempo" | Calma |
| 0:02 | 256 | **Copiloto:** "¡Vamos a la terminal! Nuestro autobús va a tiempo, así que sin prisa." | Se presenta el tablero por voz (muchos no leen) |
| 0:04 | 640 | Letrero de 40 km/h | Repaso del nivel 2 |
| **0:10 (0:12)** | 1536 | **Primer +10** (`BIEN_VELOCIDAD`) | Gana algo pronto |
| 0:12 | 1728 | **Copiloto:** aviso del amarillo | Lo prepara antes de que pase |
| 0:14 | 2012 | **Amarillo 1.** Frena, rojo de 4 s, pasa 1 auto (2 en Grande) | Ve por qué se frena: sí venían autos |
| 0:21 (0:24) | 2432 | Verde: **+10** `BIEN_AMARILLO` | |
| 0:25 | 2944 | **Copiloto:** "Mira el tablero: seguimos a tiempo…" | El tablero sigue igual aunque esperamos |
| 0:28 | 3224 | **Amarillo 2**, un poco más cerca (360 px) | Prueba sin aviso |
| 0:35 (0:40) | 3584 | Verde: **+10** | |
| 0:39 | 4096 | La calle se angosta a un carril y hay autos estacionados a la derecha | Cambio de ambiente: atención |
| 0:40 | 4176 | **Copiloto:** "Calle con autos estacionados. Despacio…" | |
| 0:41 | 4256 | Letrero de 30 km/h | Pocos segundos para bajar la velocidad antes de la pelota |
| **0:44 (0:52)** | 4520 | **CLÍMAX:** sale la pelota rodando entre dos autos; 0.6 s después, la niña corre tras ella | Sorpresa. Frena |
| 0:48 (0:56) | — | La niña llega a la banqueta, recoge su pelota y se va saludando. **+10** `BIEN_PELOTA` | Alivio y premio |
| 0:55 (1:06) | 5344 | Termina la zona de 30: **+10** | Despacio también es seguro |
| 0:57 | 5440 | La calle vuelve a tener 2 carriles. Se ve la terminal | Vamos llegando |
| 1:00 (1:12) | 5952 | Paso peatonal: una persona va a su autobús. **+10** | Repaso del nivel 1 |
| **1:05 (1:20)** | 6560 | Meta. Copiloto: **"¡Llegamos a tiempo! Y llegamos bien, que es lo más importante."** Tarjeta con `FRASE_05` | Remate del mensaje |

**Curva:**
1. Calma.
2. Aprender el amarillo.
3. Probarlo.
4. Clímax (la pelota, a los 2/3 del nivel).
5. Bajada tranquila.
6. Remate.

**El mensaje del tablero:** el niño esperó en dos rojos y en la pelota, y aun así el tablero dice "A tiempo". Lo aprende por experiencia, no por sermón.

## 6. Peque vs Grande

Las reglas son **idénticas** (decisión del plan de cierre). Solo cambia lo de siempre de cada modo y la cantidad de tráfico.

| Tema | Peque | Grande |
| --- | --- | --- |
| Manejo | El auto avanza solo al 70 % del límite. Frenar = tocar el freno | Dos pedales |
| Amarillo | Falta si **no frena** más de 1.0 s dentro de la zona (propiedad de la base técnica, punto 3) | Falta si **acelera** más de 1.0 s dentro de la zona |
| Autos que cruzan en cada rojo | **1** (`cars_per_red_peque`) | **2** (`cars_per_red_grande`) |
| Pelota y niña | Sí, iguales | Sí, iguales |
| Autos estacionados | 9, iguales (no son tráfico: forman el lugar de donde sale la pelota) | 9 |
| Avisos del copiloto | `HintYellow` usa `PRISA_AMARILLO_AVISO_PEQUE` ("toca el freno") | `PRISA_AMARILLO_AVISO` ("deja de acelerar y frena") |
| Tablero | Se ve (`show_in_peque = true`) | Se ve |

**Para el creative-director:** el diseño dice que "el reloj" aparece en Grande. Con la decisión del 1 de noviembre ya no es un reloj sino un tablero que siempre dice "A tiempo", no presiona y el copiloto lo explica por voz. Por eso se propone mostrarlo también en Peque. Si se prefiere seguir el diseño al pie de la letra, basta con `show_in_peque = false`; el copiloto sigue diciendo "¡Llegamos a tiempo!" al final.

## 7. Textos nuevos

Van en `i18n/textos.csv`. Todos se dicen con voz, tienen 14 palabras o menos, explican el porqué y no regañan.

```csv
PRISA_INTRO,"¡Vamos a la terminal! Nuestro autobús va a tiempo, así que sin prisa."
PRISA_AMARILLO_AVISO,"Si ves la luz amarilla, deja de acelerar y frena: viene el rojo."
PRISA_AMARILLO_AVISO_PEQUE,"Si ves la luz amarilla, toca el freno: avisa que viene el rojo."
BIEN_AMARILLO,"¡Bien! Frenaste con la amarilla. Esperar un ratito nos cuida a todos."
PRISA_TABLERO_AVISO,"Mira el tablero: seguimos a tiempo. Manejando bien, siempre llegamos."
PELOTA_CALLE_AVISO,"Calle con autos estacionados. Despacio: alguien podría salir de entre ellos."
FALTA_PELOTA,"¡Uy! Detrás de una pelota casi siempre viene alguien. Despacio sí alcanzamos a frenar."
BIEN_PELOTA,"¡Muy bien! Frenaste a tiempo y la niña recuperó su pelota."
LLEGADA_A_TIEMPO,"¡Llegamos a tiempo! Y llegamos bien, que es lo más importante."
TABLERO_TITULO,Salidas
TABLERO_AUTOBUS,Nuestro autobús
TABLERO_A_TIEMPO,A tiempo
```

**Claves que ya existen y se usan:**
- `FALTA_AMARILLO`, `FALTA_ROJO`, `BIEN_ROJO` (este no aparece aquí porque `give_points = false`)
- `FALTA_VELOCIDAD`, `BIEN_VELOCIDAD`
- `FALTA_PEATON`, `BIEN_PEATON`
- `META_LLEGASTE`, `DESTINO_TERMINAL`, `NIVEL_05_NOMBRE`, `FRASE_05`, `DECALOGO_02`

**Cambio propuesto (opcional, lo decide el creative-director):** el `FALTA_AMARILLO` de hoy dice "…hay que frenar, no acelerar". En Peque el niño no acelera. Propuesta que sirve para los dos modos: `FALTA_AMARILLO,"La luz amarilla avisa que viene el rojo. Ahí frenamos con calma."`

Después de agregar las claves: correr `tools/gen_strings.py` y el script de voces provisionales para las 12 claves nuevas.

## 8. Pruebas a escribir

Siguen el estilo de `tests/test_patience.gd`:
- `extends TestCase` y `run()` por bloques numerados;
- `open_scene("res://levels/level_05.tscn")`, `car.seatbelt_on = true` y `TestDriver` para manejar;
- `car.restart_at()` para empezar cerca de la pieza;
- en Peque, `GameState.mode` y volverlo a `GRANDE` al terminar.

### `tests/test_ball_event.gd`

Pieza `Rules/BallEvent` en x = 4800. Constantes:
- `TRIGGER := 4456.0` (progreso del disparo)
- `ZONE := 4688.0` (inicio de la zona)
- `CHECKPOINT := 4064.0`

| # | Nombre del bloque | Qué revisa |
| --- | --- | --- |
| 1 | `frenar a tiempo da +10` | `restart_at(4200)`, `target = 110`; cuando `is_occupied()` se vuelve verdadero, `brake_after = car.progress`. Revisa: `car.progress` máximo < `ZONE`; la niña llega a `ChildEnd`; `rm.points == 10` y `rm.faults == 0`; después el auto sigue y pasa x = 4900 sin más faltas |
| 2 | `la pelota sale primero y la calle queda ocupada` | Al cruzar `TRIGGER`: `is_occupied()` es verdadero y la niña está oculta; a los `child_delay` + 0.1 s ya es visible; antes del disparo `is_occupied()` es falso |
| 3 | `ir rápido: frena solo y es falta grave` | `target = 240` desde 4200. Revisa: `rm.infractions[&"crosswalk"] == 1`; al marcar la falta, `car.progress < ZONE + 4` (nunca llega a la niña); la niña pasó por `scared` |
| 4 | `después de la falta grave se repite desde el punto de control` | Sigue del bloque 3: `wait_unpaused()` y espera al regreso. Revisa: `car.progress ≈ CHECKPOINT` (±2); el estado es `IDLE`, la pelota y la niña están ocultas y `is_occupied()` es falso. Luego maneja como en el bloque 1: +10 y el total de faltas sigue en 1 |
| 5 | `una sola falta por pasada` | En el bloque 3, aunque el auto siga en la zona, `rm.faults` no pasa de 1 hasta el regreso |
| 6 | `peque: frenar a tiempo da +10` | `MODE_PEQUE`, `restart_at(4200)`, sin pedales; al ocuparse la calle, `Input.action_press(&"car_brake")` hasta que la niña llega. Revisa `+10` y 0 faltas |
| 7 | `peque: sin frenar, frena solo y es falta grave` | `MODE_PEQUE` sin tocar nada. Revisa `infractions[&"crosswalk"] == 1` y `car.progress < ZONE + 4`. Al terminar, `GameState.mode = MODE_GRANDE` |

### `tests/test_yellow_crossing.gd`

`Rules/YellowCrossing1`, con la línea en el progreso 2368 y el disparo en 1948.

| # | Nombre del bloque | Qué revisa |
| --- | --- | --- |
| 1 | `la luz espera al auto` | Antes del disparo la luz está en `GREEN` aunque pasen 20 s; al cruzar 1948, `YELLOW`; a los 3.0 s, `RED`; el verde llega cuando pasaron ≥ 4.0 s y `is_busy()` es falso |
| 2 | `frenar en amarillo y esperar da +10` | `restart_at(1600)`, `target = 168`, `brake_after = 2300`. Revisa: el auto se detiene antes de 2368; `rm.good_action_reported` con `&"yellow"`; `points == 10` y `faults == 0` |
| 3 | `seguir acelerando en amarillo es falta yellow` | `target = 240` sin frenar. Revisa `infractions[&"yellow"] == 1` y que no haya +10 de `&"yellow"` |
| 4 | `soltar los pedales en amarillo no es falta` | `restart_at(1900)`, llega a 168, al ponerse amarillo `stop_driving()`. Revisa que no hay falta `yellow` (puede cruzar en amarillo) |
| 5 | `pasarse el rojo con tráfico: falta red_light y nunca hay choque` | Se pasa el rojo. Revisa `infractions[&"red_light"] == 1`. En cada cuadro, el `Hitbox` del jugador nunca se encima con el `Hitbox` de un `NpcCar` (`overlaps_area`) |
| 6 | `tráfico por modo` | Grande: en un rojo salen 2 `NpcCar`. Peque: 1 |
| 7 | `peque: no frenar en amarillo es falta, frenar da +10` | `MODE_PEQUE`. Depende de la propiedad de la base técnica (punto 3) |
| 8 | `punto de control rearma el cruce` | Después de una falta grave forzada más adelante (o de `rm.checkpoint_restored.emit(1500)` con `car.restart_at(1500)`): luz en `GREEN`, estado `ARMED` y ningún `NpcCar` hijo |

### `tests/test_departure_board.gd`

| # | Nombre del bloque | Qué revisa |
| --- | --- | --- |
| 1 | `el tablero siempre dice A tiempo` | Se maneja el nivel completo a 150 px/s. En cada segundo, el texto del widget es `tr("TABLERO_A_TIEMPO")`, y ningún `Label` del widget tiene dígitos (`RegEx "\\d"`) |
| 2 | `no se puede perder por tiempo` | Se maneja todo el nivel a 40 px/s (tarda varios minutos de juego; usar `Engine.time_scale = 4`). Revisa: el nivel termina con `level_finished`, 3 estrellas y ninguna falta |
| 3 | `al llegar el copiloto dice Llegamos a tiempo` | Después de `level_finished`, `Feedback._bubble` `%MessageLabel.text == tr("LLEGADA_A_TIEMPO")`, como en `test_feedback.gd` |
| 4 | `widget en peque` | Con `show_in_peque = true` el widget existe en Peque; con `false`, no |

### `tests/test_levels.gd`

Lo cambia **la base técnica**, no este nivel. Hay que avisarle al lead-programmer.
- El nivel 5 entra solo con el punto 7 del plan (la lista sale de los `LevelData`).
- El conductor cuidadoso no conoce las piezas nuevas. **Pedido:** en `play()` y en `must_wait()`, aceptar cualquier pieza con `has_method("careful_stop_x")`:
  - el punto de parada es `careful_stop_x() - 64`;
  - hay que esperar si `piece.must_wait()` (si existe) o `piece.is_occupied()`.
- Con eso, el nivel 5 en Grande y en Peque tiene que terminar con **3 estrellas y sin faltas**.
- `BallEvent` y `YellowCrossing` ya exponen esos métodos (§3 y §3b). A `BallEvent` le falta agregar `func must_wait() -> bool: return is_occupied()`.

### Estructura (dentro de `test_level_data.gd` o un bloque nuevo en `test_ball_event.gd`)

- `data/level_05.tres` tiene `scene_path == "res://levels/level_05.tscn"` y `decalogo_key == "DECALOGO_02"`.
- Las 2 `YellowCrossing` tienen `Light.check_yellow == true`.
- `SpeedZone30` cubre x = 4800 (la pelota está dentro de la zona de 30).
- Las 12 claves nuevas existen en `textos.csv` (`tr(clave) != clave`).

## 9. Arte usado

**Ya existe:**

| Uso | Archivo |
| --- | --- |
| Terminal (destino) | `assets/sprites/city/terminal.png` (322 × 190, a 1:1) |
| Autos estacionados y autos que cruzan | `assets/sprites/vehicles/npc_car.png` con `modulate` de la paleta |
| Niña que persigue la pelota | `assets/sprites/pedestrians/girl_frames.tres` (`idle`, `walk`, `scared`) |
| Persona en el paso peatonal de la terminal | `assets/sprites/pedestrians/adult_frames.tres` |
| Semáforos | `assets/sprites/signals/traffic_light.png` (lo dibuja `traffic_light`) |
| Letreros de 40 y 30 | `assets/sprites/signals/signs.png` (lo dibuja `speed_zone`) |
| Calle, casas y meta | `assets/tiles/street_tiles.tres` (`level_builder`) |
| Árboles junto a la terminal | `assets/sprites/city/arboles.png` |
| Tarjeta de hábito | `assets/ui/habit_cards/card_05.png`. Ya muestra un auto, una pelota y un niño, y combina con el clímax |
| Estilo del widget | `assets/ui/theme.tres` (`TopBarPill`) |

**No hay arte; se usa un provisional dibujado con código:**

| Falta | Provisional | Arte final (si se pide) |
| --- | --- | --- |
| Pelota | `draw_circle` dorado `COLOR_GOLD` con una raya `COLOR_ADO_RED` que gira, contorno `COLOR_OUTLINE` y sombra `COLOR_SHADOW`, de radio 9 | Sprite de 24 × 24 con 4 cuadros de giro (ver `docs/prompts_listos_fase1.md`, escena de la pelota) |
| Tablero de salidas (mundo y widget) | Rectángulos de la paleta y `Label`/`draw_string` con `tr()` | Sprite del tablero de 144 × 64 sin texto (el texto siempre por código) |
| Calle que cruza en `yellow_crossing` | Rectángulo `COLOR_ASPHALT` con rayas, como en `blind_crossing` | — |
| Sonido de la pelota rebotando | Ninguno (opcional) | `assets/audio/sfx/ball.wav`, para el sound-designer |

**Personaje:** la niña se ve con su animación `scared` solo cuando el auto frena solo. Nunca hay contacto ni heridos.
