# Nivel 6 · Ojos en el camino

Ficha de diseño para programar el nivel sin preguntas. Decálogo 6, «Evita distracciones». Frase: **«El celular espera, la calle no.»** (`FRASE_06`).

Fuentes que manda esta ficha: el documento de diseño, `docs/plan_cierre.md` (Peque tiene **las mismas reglas** que Grande) y `CLAUDE.md`.

---

## 1. Resumen y objetivo

**Historia:** vamos a la **casa de los primos**. En el camino, el celular del auto suena tres veces. Son los primos, que quieren saber si ya vamos. Las dos primeras veces lo dejamos sonar. La tercera vez el copiloto propone estacionarnos en un cajón para contestar. Contestamos estacionados y seguimos hasta su casa.

**Qué aprende el niño:** el celular no se toca mientras el auto avanza. Si es importante, primero nos estacionamos y luego contestamos.

**Regla principal (diseño):**

| Situación | Resultado |
| --- | --- |
| Tocar el celular con el auto **en movimiento** | **Falta** `phone`. El celular crece y tapa parte de la calle **2 s sin pausar el juego**. Después viene la pausa normal de falta con la explicación. |
| Dejarlo sonar hasta que se calla | **+10** («ignorar el celular», del diseño) |
| Contestar **estacionado** en el cajón | **+10**. El auto sigue después de la llamada. |

**Reglas que se repasan:**

- Paso peatonal (`crosswalk`, nivel 1).
- Semáforo con amarillo (`traffic_light` con `check_yellow`, niveles 2 y 5).
- Límite de velocidad (`speed_zone`, nivel 2).
- Cinturón (nivel 0, ya viene en el HUD).

**Destino:** casa de los primos, con la clave nueva **`DESTINO_CASA_PRIMOS`**. El arte es la casa morada del tendedero, de `assets/sprites/city/casas.png`. El nivel 3 ya usa la casa amarilla para la casa de la abuela, así que no se repite.

**Duración objetivo:** de 70 a 80 s en Grande y en Peque. El primer +10 llega a los 12 s más o menos.

**Puntos posibles:** celular 1 (+10), paso peatonal (+10), celular 2 (+10), semáforo (+10, si toca rojo o amarillo), contestar estacionado (+10) y zona de velocidad (+10).

---

## 2. Recorrido

Es una calle recta de 2 carriles hacia +x, como los niveles 1 a 4. Se arma con `tools/level_builder.gd`:

```gdscript
LevelBuilder.new("Level06", 125, 1, 6)
```

| Dato | Valor |
| --- | --- |
| Largo | 125 tiles = **8000 px** |
| Ruta | De (64, 0) a (7968, 0) |
| Carril inicial | `start_lane = 1` (derecho, el del cajón) |
| `progress` del auto | `x − 64` |
| Meta | Las losas de meta del final de la calle, que pone el builder. **No se quitan**: aquí el cajón está a media ruta y no es la meta. El nivel termina con `route_finished`, como en los niveles 1, 2 y 4. |

Al terminar, se corre `python3 tools/make_inherited.py levels/level_06.tscn`.

### Segmentos (en orden)

| # | x (px) | Nodo en `Rules` | Pieza | Valores exportados |
| --- | --- | --- | --- | --- |
| A | 64–1000 | — | Arranque, cinturón | — |
| 1 | 400 | `HintIntro` | `tutorial_hint` | `message_key = "CELULAR_INTRO"`, `peque_message_key = ""`, `depth = 64`, `road_width = 128` |
| 2 | 1000 | `Phone1` | **`phone_event`** (modo ignorar) | `spot = null`, `ring_time = 5.0`, `ring_distance = 900.0`; el resto con los valores por defecto (§3) |
| 3 | 2000 | `CheckpointAfterPhone1` | `checkpoint` | por defecto |
| 4 | 2900 | `Crosswalk1` | `crosswalk` | por defecto (`approach_length = 448`, `start_delay = 0.3`, peatón por defecto) |
| 5 | 3300 | `CheckpointAfterCrosswalk` | `checkpoint` | por defecto |
| 6 | 3500 | `Phone2` | **`phone_event`** (modo ignorar) | `spot = null`, `ring_time = 6.0`, `ring_distance = 700.0` |
| 7 | 4900 | `TrafficLight1` | `traffic_light` | `check_yellow = true`, `green_time = 6.0`, `yellow_time = 3.0`, `red_time = 5.0`, `start_light = GREEN`, `reaction_time = 0.6` |
| 8 | 5300 | `CheckpointAfterLight` | `checkpoint` | por defecto |
| 9 | 5300–8900 | `TrafficLeft` (fuera de `Rules`, hijo de la raíz) | tráfico del nivel (§5) | `activate_x = 5600`, `stop_x = 7400` |
| 10 | 5700 | `Phone3` | **`phone_event`** (modo contestar) | `spot = NodePath("../ParkingSpot")`, `vibrate_angle = 12.0` (vibra más fuerte: es el clímax) |
| 11 | 5800 | `HintPark` | `tutorial_hint` | `message_key = "CELULAR_ESTACIONAR"`, `depth = 64` |
| 12 | 6400 | `ParkingSpot` | `parking_spot` (reutilizable) | `bay_offset = 32`, `approach_length = 320`, `show_finish_line = false`, valores de la base para soltar el auto (ver §3.6) |
| 13 | 6800 | `CheckpointAfterPark` | `checkpoint` | por defecto |
| 14 | 6900 | `SpeedZone1` | `speed_zone` | `kind = STREET`, `limit_kmh = 30`, `zone_length = 768`, `grace_time = 2.0` |
| B | 7968 | — | Fin de la ruta, `META_LLEGASTE` | — |

### Decorado (nodo `Decor`, como en los niveles 3 y 4)

| Nodo | Textura | Posición | Otros valores |
| --- | --- | --- | --- |
| `PrimosHouse` | `casas.png` | (7900, 300) | `region_enabled = true`, `region_rect = Rect2(128, 0, 128, 128)` (casa morada), `flip_v = true` (la puerta mira a la calle, igual que la casa de la abuela del nivel 3) |
| `Buildings` (opcional) | `edificios.png` | (6400, −330) | `region_rect = Rect2(142, 0, 142, 160)`; hace ver el cajón como una calle del centro |

### Reglas de espacio (por qué están ahí las piezas)

Mientras el celular tapa la calle, el auto sigue avanzando. Por eso ninguna pieza que pida frenar empieza dentro del tramo donde puede sonar o tapar el celular. Ese tramo se cuenta a velocidad máxima: 240 px/s × 2 s de tapa = 480 px.

| Celular | Dónde puede terminar de tapar | Siguiente pieza | Holgura |
| --- | --- | --- | --- |
| Phone1 | 1000 + 900 + 480 = **2380** | Crosswalk1: su zona empieza en 2900 − 32 − 448 = **2420** | ✔ |
| Phone2 | 3500 + 700 + 480 = **4680** | TrafficLight1: su zona empieza en 4900 − 192 = **4708** | ✔ |
| Phone3 | Suena dentro del frenado automático del cajón, que ya baja la velocidad | — | ✔ |

Si se mueve una pieza, hay que respetar esta cuenta: `trigger + ring_distance + 480 ≤ inicio de la zona de la siguiente pieza`.

Los checkpoints van **después** de cada celular. Así una falta grave en el paso peatonal (regreso a 2000) no vuelve a hacer sonar el Phone1.

---

## 3. Pieza nueva `phone_event`

Archivos: `scenes/rules/phone_event.gd` y `phone_event.tscn`.

- `class_name PhoneEvent`
- `extends RulePiece`
- **No** lleva `@tool` en lógica de juego. Si se quiere ver el trigger en el editor, se agrega `@tool` con `_draw` solo en el editor, como `tutorial_hint`.

### 3.1 Escena

```text
PhoneEvent (Node2D, phone_event.gd)
├── Trigger (Area2D)
│   └── CollisionShape2D (RectangleShape2D, resource_local_to_scene = true)
├── Ring (AudioStreamPlayer)                 stream = ring_sound
└── Layer (CanvasLayer, layer = 2, visible = false)   ← igual que DoorExit
    └── Holder (Node2D)                      su posición es el CENTRO del celular
        └── Phone (TouchScreenButton)        texture_normal = res://assets/ui/phone.png
                                             position = (-84, -160)  (centra la textura de 168 × 320)
```

- **`TouchScreenButton`**, no `Button` ni `TextureButton`: en Grande el niño puede tener el pedal verde presionado con un dedo y tocar el celular con otro. Los `Control` solo reciben el primer toque emulado y lo perderían. Como `pointing/emulate_touch_from_mouse=true` ya está activo, en la PC también funciona con clic.
- No lleva `action`. Su señal `pressed` se conecta a `touch_phone()`.
- `Holder` sirve para escalar y rotar el celular alrededor de su centro (vibración y crecimiento).
- No se toca `hud.tscn` ni `player_car.gd`. La pieza solo lee `car.speed` y `car.progress`.

### 3.2 Variables exportadas (con sus valores por defecto)

| Variable | Tipo | Defecto | Para qué sirve |
| --- | --- | --- | --- |
| `spot` | `ParkingSpot` | `null` | `null` = modo **ignorar**. Con un cajón = modo **contestar**. |
| `ring_time` | `float` | `5.0` | Modo ignorar: segundos que suena como máximo |
| `ring_distance` | `float` | `900.0` | Modo ignorar: px de ruta desde el trigger. Deja de sonar con lo primero que se cumpla de `ring_time` y `ring_distance`. |
| `moving_speed` | `float` | `10.0` | px/s. Por encima de este valor el auto está **en movimiento**. Es el mismo valor que `stop_speed` de las otras piezas. |
| `cover_time` | `float` | `2.0` | Segundos que el celular tapa la calle (diseño) |
| `grow_time` | `float` | `0.25` | Segundos que tarda en crecer y en encogerse |
| `small_center` | `Vector2` | `(66, 176)` | Centro del celular chico, en la esquina superior izquierda, debajo de la barra (de 24 a 108 en x, de 96 a 256 en y). No choca con el cinturón (y ≥ 316), el engrane (a la derecha) ni la burbuja del copiloto (x ≥ 200). |
| `small_scale` | `float` | `0.5` | 84 × 160 px |
| `cover_center` | `Vector2` | `(720, 330)` | Centro del celular grande. Tapa de 552 a 888 en x y de 10 a 650 en y: justo **la calle delante del auto** (el auto queda en x ≈ 400 por el `look_ahead = 240` de la cámara), sin tapar los pedales (x ≥ 908). |
| `cover_scale` | `float` | `2.0` | 336 × 640 px. Es un múltiplo entero, así no se deforma el pixel art. |
| `vibrate_angle` | `float` | `8.0` | Grados de la sacudida |
| `vibrate_step` | `float` | `0.06` | Segundos de cada medio ciclo de la sacudida |
| `burst_time` | `float` | `0.6` | Segundos que vibra en cada «ring» |
| `burst_pause` | `float` | `0.6` | Segundos quieto entre rings |
| `ring_sound` | `AudioStream` | `null` | `res://assets/audio/sfx/phone_ring.wav` cuando lo entregue Audio. Con `null` no suena y no da error. |
| `points` | `int` | `10` | Puntos por ignorarlo o por contestarlo |
| `answer_timeout` | `float` | `8.0` | Modo contestar: segundos estacionado sin contestar antes de seguir sin puntos |
| `call_time` | `float` | `2.5` | Modo contestar: duración de la «llamada» después de tocar |
| `release_delay` | `float` | `2.0` | Modo contestar: segundos entre el mensaje de los primos y soltar el auto |
| `depth` | `float` | `64.0` | Largo del trigger sobre la ruta. Con setter `_refresh()`, como `tutorial_hint`. |
| `road_width` | `float` | `128.0` | Ancho del trigger |

### 3.3 Estados

```gdscript
enum State { IDLE, RINGING, COVERING, WAITING_PARK, ANSWERABLE, IN_CALL, DONE }
```

| Estado | Qué se ve | Cómo entra | Cómo sale |
| --- | --- | --- | --- |
| `IDLE` | Nada (`Layer` oculto) | Al empezar o al reiniciar | El auto entra a `Trigger` → `RINGING` (solo una vez por pasada) |
| `RINGING` | Celular chico en la esquina, vibrando a ráfagas y sonando | Trigger | Ver §3.4 |
| `COVERING` | Celular grande en `cover_center`, sin vibrar y sin sonido. El juego **no** está en pausa. | Toque en movimiento | Al acabar `cover_time`: falta → `DONE` en modo ignorar, `WAITING_PARK` en modo contestar (o `ANSWERABLE` si ya está estacionado) |
| `WAITING_PARK` | Nada. El celular «espera». | Modo contestar, después de la falta | `spot.parked` → `ANSWERABLE` |
| `ANSWERABLE` | Celular chico vibrando y sonando, con un pulso de `modulate` para que se note que ahora sí se puede | `spot.parked` en modo contestar | Toque → `IN_CALL`. Al pasar `answer_timeout` → `DONE` (sin puntos) |
| `IN_CALL` | Celular chico quieto, sin sonido | Toque estacionado | Al acabar `call_time + release_delay` → `DONE` |
| `DONE` | Nada | — | Solo `_on_car_restarted()` la regresa a `IDLE` |

**Vibración:** un `Tween` en bucle sobre `Holder.rotation_degrees`:

```text
+vibrate_angle → −vibrate_angle   (alternando cada vibrate_step durante burst_time)
→ 0
→ espera burst_pause
```

`Ring.play()` se llama al empezar cada ráfaga. El tween se mata al salir de `RINGING` o `ANSWERABLE`.

**Tiempo:** el tiempo de ring se cuenta en `_physics_process` (pausable). Una pausa por falta de otra pieza no se come el tiempo del celular.

### 3.4 Condiciones exactas

Para que no haya ambigüedad:

```gdscript
func is_car_moving() -> bool:
	return _car.speed > moving_speed
```

`touch_phone()` (público) lo llama el botón y también lo pueden llamar las pruebas:

| Estado al tocar | Condición | Resultado |
| --- | --- | --- |
| `RINGING` | `is_car_moving()` | Ver «Toque en movimiento» abajo |
| `RINGING` | auto detenido y (modo ignorar, o modo contestar con `not spot.is_parked()`) | `Feedback.show_info("CELULAR_ESPERA_CAJON")` una sola vez por ring. Sin falta y sin puntos. Sigue sonando y **no** pierde el +10 de ignorar. Detenerse no es manejar distraído, pero tampoco es contestar. |
| `RINGING` en modo contestar con `spot.is_parked()` | — | Igual que `ANSWERABLE` (no debería pasar, pero se cubre) |
| `ANSWERABLE` | — | Ver «Contestar» abajo |
| `COVERING`, `WAITING_PARK`, `IN_CALL`, `DONE`, `IDLE` | — | No hace nada. Así hay como máximo **una falta por pasada**. |

**Toque en movimiento:**

1. `_touched_moving = true` y el estado pasa a `COVERING`.
2. Se mata la vibración y se para `Ring`.
3. `Feedback.show_info("CELULAR_TAPA")`. Es un aviso sin pausa: «¡no vemos la calle!».
4. Un tween de `grow_time` mueve `Holder.position` de `small_center` a `cover_center` y `Holder.scale` de `small_scale` a `cover_scale`.
5. Espera `cover_time`. **El auto sigue moviéndose y el niño sigue manejando**: es la experiencia que pide el diseño.
6. Un tween de regreso de `grow_time` encoge el celular. `Layer` se oculta.
7. Se llama `_report_infraction(&"phone", "FALTA_CELULAR")`. **La falta se reporta al terminar la tapa, no al tocar**, porque `Feedback.show_infraction()` pausa el juego y congelaría la calle tapada.
8. Siguiente estado: `DONE` en modo ignorar. En modo contestar, `ANSWERABLE` si `spot.is_parked()`, si no `WAITING_PARK`.

Cada `await` revisa `_round` (como `crosswalk`). Si el nivel se reinició o terminó a la mitad, no reporta nada.

**Fin del ring (solo en modo ignorar, en `RINGING`):**

Se cumple cuando `_elapsed >= ring_time` o `_car.progress >= _trigger_progress + ring_distance`, donde `_trigger_progress = _progress_on_route(car)` al entrar al trigger. Entonces:

1. Se para la vibración y el sonido, y se oculta `Layer`.
2. Si `not _touched_moving`: `_report_good_action(&"phone", "BIEN_CELULAR", points)`. En `RINGING` siempre es así, porque tocar en movimiento ya sacó a la pieza de ese estado.
3. El estado pasa a `DONE`.

En modo contestar, `RINGING` no termina por tiempo ni por distancia: sigue hasta que el auto se estaciona.

**Contestar (`ANSWERABLE` + toque):**

1. El estado pasa a `IN_CALL`. Se para la vibración y el sonido, y se quita el pulso.
2. `_report_good_action(&"phone", "BIEN_CONTESTAR", points)`.
3. Espera `call_time` y llama `Feedback.show_info("CELULAR_PRIMOS")`.
4. Espera `release_delay`, oculta `Layer`, llama `spot.release()` (§3.6) y el estado pasa a `DONE`.

Contestar da +10 **aunque antes haya tenido la falta**: el juego premia más lo que se hace bien.

**Sin contestar (`ANSWERABLE` durante `answer_timeout`):**

1. `Feedback.show_info("CELULAR_LUEGO")`.
2. Se oculta `Layer`, se llama `spot.release()` y el estado pasa a `DONE`.
3. Sin falta y sin puntos.

Así el nivel nunca se traba. Además, el conductor cuidadoso de `tests/test_levels.gd` lo termina sin saber del celular.

### 3.5 `rule_id`, ids y claves de mensaje

| Uso | id | Clave |
| --- | --- | --- |
| Falta al tocar en movimiento | `&"phone"` (ya existe `REGLA_PHONE` para la pantalla de tutores) | `FALTA_CELULAR` |
| Ignorarlo hasta que se calla | `&"phone"` | `BIEN_CELULAR` |
| Contestar estacionado | `&"phone"` | `BIEN_CONTESTAR` |
| Aviso al tocar, durante la tapa (`show_info`) | — | `CELULAR_TAPA` |
| Tocar detenido sin estar estacionado (`show_info`) | — | `CELULAR_ESPERA_CAJON` |
| Al estacionarse en modo contestar (`show_info`) | — | `CELULAR_CONTESTA` |
| Durante la llamada (`show_info`) | — | `CELULAR_PRIMOS` |
| Se acabó el tiempo sin contestar (`show_info`) | — | `CELULAR_LUEGO` |

### 3.6 Relación con `parking_spot` (y qué se le pide al equipo base)

`phone_event` en modo contestar:

- En `_ready()` (fuera del editor), si `spot != null`, se conecta a `spot.parked`.
- Al recibir `parked`:
  - Si está en `RINGING` o `WAITING_PARK`, pasa a `ANSWERABLE`, arranca la vibración y llama `Feedback.show_info("CELULAR_CONTESTA")` con `call_deferred`. Así reemplaza a `ESTACIONADO_AVISO` («toca Abrir puerta»), que aquí no aplica.
  - Si está en `COVERING`, no hace nada: el paso 8 de §3.4 lo manda a `ANSWERABLE`.
- `phone_event` decide cuándo se va el auto: llama `spot.release()` y nada más.

Se le pide al equipo base (punto 2 de la fase 2 en `plan_cierre.md`):

1. **Un método público para soltar el auto**: `ParkingSpot.release() -> void`.
   - Quita su `stop_request` y su límite de velocidad.
   - Ya no vuelve a detener al auto en esa pasada, aunque siga dentro de `Approach`.
   - En Grande el auto arranca con el pedal verde; en Peque arranca solo.
   - Si la base le pone otro nombre (por ejemplo, `release_after_park` como export más un método), solo cambia esa llamada en `phone_event.gd`.
   - Para el nivel 6, `release_after_park` (o lo que lo reemplace) tiene que estar **apagado**: quien suelta es `phone_event`.
2. **(Deseable)** un export `parked_message_key: String = "ESTACIONADO_AVISO"` para no tener que pisar el mensaje. Si no existe, basta con el `call_deferred` de arriba.
3. Que `_on_car_restarted()` del cajón también limpie el estado de «ya soltado».

`phone_event` **no** se busca el cajón por grupo, como hace `door_exit`. Se usa solo el `spot` exportado, porque en el nivel 6 el celular 1 y el 2 no tienen cajón.

### 3.7 Puntos de control (`_on_car_restarted`)

`RulePiece` llama a `_on_car_restarted()` solo si el punto restaurado está antes de la pieza. Cuando eso pasa:

1. `_round += 1`, para invalidar los `await` pendientes de tapa, llamada o timeout.
2. Se matan todos los tweens (vibración, crecer, pulso) y se llama `Ring.stop()`.
3. `Layer.visible = false`. `Holder` vuelve a `small_center`, `small_scale` y rotación 0.
4. `_state = IDLE`, `_touched_moving = false`, `_elapsed = 0`, `_said_wait = false`, `_car = null`.
5. **Si se cancela una tapa en curso, no se reporta la falta.** Por la regla de espacio de §2 no debería pasar.

Si el punto restaurado está **después** de la pieza, la pieza sigue como estaba.

Además, `phone_event` se conecta a `RuleManager.level_finished`. Al terminar el nivel, oculta todo, para el sonido y pasa a `DONE`.

### 3.8 API pública (para pruebas y para el nivel)

```gdscript
signal ring_started
signal ring_finished          # al pasar a DONE por cualquier camino

func touch_phone() -> void
func is_ringing() -> bool     # RINGING o ANSWERABLE
func is_covering() -> bool    # COVERING
func is_answerable() -> bool  # ANSWERABLE
func get_state() -> State
```

---

## 4. Momentos (ritmo y clímax)

Tiempos aproximados en Grande, manejando a unos 170 px/s. En Peque el auto va solo a 168 px/s, así que el ritmo es casi igual.

| t (s) | x | Momento | Qué siente el niño |
| --- | --- | --- | --- |
| 0–2 | 64 | Cinturón (pulso del HUD) | Rutina conocida |
| ~4 | 400 | `CELULAR_INTRO`: el copiloto avisa que el celular va a sonar y qué hacemos | Expectativa: le dicen la regla antes del reto |
| ~7 | 1000 | **Ring 1**: vibra y suena en la esquina | Primera tentación, fácil y en calle vacía |
| ~12 | ~1900 | Se calla → **+10** `BIEN_CELULAR` | **Primer +10 a los ~12 s** |
| ~18–22 | 2900 | Paso peatonal: un peatón cruza, se espera → +10 | Repaso del nivel 1 |
| ~27 | 3500 | **Ring 2**, más largo (6 s) y justo cuando vuelve a acelerar | Tentación con las manos ocupadas (pedal y flechas) |
| ~31 | ~4200 | Se calla → +10 | Ya entendió el patrón |
| ~33–42 | 4900 | Semáforo con amarillo largo (3 s): frenar, esperar el verde → +10 | Repaso de los niveles 2 y 5 |
| ~44 | 5300–5600 | Empiezan a pasar autos por el carril izquierdo | La calle «se llena» antes del clímax |
| ~47 | 5700 | **Ring 3 (clímax)**: vibra más fuerte y no se calla | La tentación más fuerte: «¿y si es importante?» |
| ~47.5 | 5800 | `CELULAR_ESTACIONAR`: el copiloto señala el cajón | La regla tiene salida: sí se puede, pero estacionados |
| ~48–52 | 6080–6400 | El auto frena solo hacia el cajón **y el celular sigue sonando** | Clímax: aguantarse hasta quedar quieto. Tocar mientras rueda todavía es falta. |
| ~52 | 6400 | Estacionado: `CELULAR_CONTESTA`; el celular pulsa | Permiso |
| ~53 | 6400 | Toca → **+10** `BIEN_CONTESTAR`; `CELULAR_PRIMOS`. Mientras tanto pasan autos por el carril izquierdo. | Recompensa y alivio. Se ve que estacionado es seguro: la calle sigue y nosotros no estorbamos. |
| ~57 | 6400 | El auto queda libre | Cierre del clímax |
| ~61–69 | 6900–7668 | Zona de 30 km/h → +10 | Repaso del nivel 2 y bajada de ritmo |
| ~72 | 7968 | Casa de los primos, `META_LLEGASTE` y tarjeta con «El celular espera, la calle no.» | Llegada cálida |

- **Total:** de 70 a 80 s. Puede llegar a ~85 s si toca rojo completo en el semáforo. Queda dentro de 1 a 2 min.
- **Escalada:** ring 1 en calle vacía, ring 2 con 1 s más y mientras acelera, ring 3 que no se calla y vibra más.
- **Lo que pasa si se equivoca:** el niño ve con sus ojos que, con el celular enfrente, la calle desaparece mientras el auto sigue. Luego el copiloto explica por qué, sin regaño.

---

## 5. Peque vs Grande

**Las reglas son idénticas** (`plan_cierre.md`):

- Mismos tres celulares, mismos tiempos, misma falta y mismos puntos.
- En Peque el auto avanza solo. «En movimiento» se mide igual (`car.speed > 10`), así que tocar el celular sin frenar es falta.
- No hay `peque_message_key` distintos: los textos sirven para las dos edades.

Lo único que cambia es el **tráfico** del carril izquierdo, en el nodo `TrafficLeft`. Es un script del nivel (`levels/level_06_traffic.gd`), no una pieza compartida:

- `extends Path2D`.
- Curva de (5100, −32) a (8900, −32), en el carril izquierdo y hacia +x.
- Empieza **después** del semáforo, para que ningún auto del tráfico se pase el rojo en pantalla: `NpcCar` no respeta semáforos.

| Export | Defecto | Grande | Peque |
| --- | --- | --- | --- |
| `activate_x` | `5600.0` | Empieza a generar cuando el auto pasa este x | igual |
| `stop_x` | `7400.0` | Deja de generar después de este x | igual |
| `npc_speed` | `100.0` | px/s, por debajo de los 120 px/s de la zona de 30 km/h | igual |
| `interval_min` / `interval_max` | `4.0` / `6.0` | Cada 4 a 6 s | × `peque_traffic_factor` |
| `peque_traffic_factor` | `1.8` | — | Cada 7 a 11 s (igual que en `blind_crossing`) |
| `spawn_behind` | `520.0` | Aparece en `max(car_x − 520, 5100)`, justo fuera de la pantalla por la izquierda | igual |
| `despawn_behind` | `1500.0` | Se borra si queda más de 1500 px detrás del auto | igual |

El primer auto sale en cuanto se activa. El tráfico se usa con la escena `scenes/actors/npc_car.tscn` y colores de `NPC_COLORS`, como `blind_crossing`, o de la paleta.

- **Para qué sirve:** mientras el niño contesta estacionado, los autos pasan a su lado. Es la imagen de que el cajón es el lugar seguro para usar el celular.
- **No genera faltas.** El jugador va en el carril derecho y `NpcCar` frena solo si tiene al jugador enfrente: nunca choca.
- Al reiniciar el nivel, no hay que limpiar nada: los autos se borran solos.

---

## 6. Textos nuevos

Se agregan al final de `i18n/textos.csv`.

```csv
DESTINO_CASA_PRIMOS,"Casa de los primos"
CELULAR_INTRO,"Si suena el celular, lo dejamos sonar. Manejando, los ojos van en la calle."
BIEN_CELULAR,"¡Muy bien! Dejaste sonar el celular y tus ojos siguieron en la calle."
CELULAR_TAPA,"¡Uy! Con el celular enfrente ya no vemos la calle."
FALTA_CELULAR,"Mientras el auto avanza, el celular espera. Si lo miras, no ves la calle."
CELULAR_ESPERA_CAJON,"Todavía vamos manejando. Lo contestamos cuando nos estacionemos."
CELULAR_ESTACIONAR,"¡Otra vez el celular! Adelante hay un cajón: ahí nos estacionamos para contestar."
CELULAR_CONTESTA,"¡Ya estamos estacionados! Ahora sí puedes contestar el celular."
BIEN_CONTESTAR,"¡Muy bien! Primero te estacionaste y luego contestaste."
CELULAR_PRIMOS,"Son tus primos: ya nos esperan. ¡Vamos con calma!"
CELULAR_LUEGO,"Les llamamos al llegar. ¡Seguimos con calma!"
```

Revisión:

- Todos tienen 14 palabras o menos.
- Usan «tú» y «nos», el registro del copiloto.
- Las faltas explican el porqué («si lo miras, no ves la calle») y no regañan.
- Se pueden decir con voz sin signos raros.

Se generan sus `.ogg` con el script de voces (fase 2 de audio) y se corre `tools/gen_strings.py` si aplica.

---

## 7. Pruebas a escribir

Archivo: `tests/test_phone.gd` (`extends TestCase`, mismo estilo que `test_parking.gd`).

- Abre `res://levels/level_06.tscn` con `open_scene`, `TestDriver` y `wait_until`.
- En `open_level()` se pone `car.seatbelt_on = true` y se toman `Phone1`, `Phone2`, `Phone3`, `ParkingSpot` y `rm`.
- Para no esperar el sonido, `ring_sound` queda `null`.

| # | Nombre del bloque | Pasos | Asserts (`check`) |
| --- | --- | --- | --- |
| 0 | Estructura | Abrir en Grande | Hay 3 `PhoneEvent`; `Phone1.spot == null` y `Phone2.spot == null`; `Phone3.spot == ParkingSpot`; `ParkingSpot.show_finish_line == false`; `LevelData` 6 tiene `destination_key == "DESTINO_CASA_PRIMOS"` y `scene_path == "res://levels/level_06.tscn"`; las losas de meta siguen al final de la calle |
| 1 | Ignorar da +10 | `restart_at(700)`, `driver.target = 170` | `Phone1.is_ringing()` en ≤ 5 s y `Phone1.get_node("Layer").visible`; al callarse (≤ `ring_time + 1`): `rm.points` subió 10, `rm.faults == 0`, `get_state() == DONE`, `Layer` oculto |
| 2 | Para por distancia | Igual que el 1 con `driver.target = 240` | Deja de sonar antes de `ring_time` y con `car.progress >= trigger + ring_distance − 10` |
| 3 | Tocar en movimiento: tapa sin pausa | `restart_at(700)`, target 170; cuando suena, `touch_phone()` | Enseguida: `is_covering()`, `rm.faults == 0`, `not get_tree().paused`. A 1 s: `car.speed > 10` (el auto sigue) y la escala de `Holder` ≈ `cover_scale`. A `cover_time + grow_time + 0.2`: `rm.faults == 1`, `rm.infractions[&"phone"] == 1`, puntos sin cambio. Después de `wait_unpaused()`: `Layer` oculto, `DONE`, y al pasar `ring_time` **no** se sumó +10 |
| 4 | Una falta por pasada | Después del 3, `touch_phone()` dos veces | `rm.faults == 1` |
| 5 | Tocar detenido no es falta | Suena Phone2; `driver.target = 0` hasta `car.speed == 0`; `touch_phone()` | `rm.faults == 0`, `is_ringing()`, `not is_covering()`; al soltar el freno y callarse, +10 |
| 6 | Contestar estacionado | `restart_at(5500)`, target 170 sin tocar; `wait_until(spot.is_parked, 25)` | `Phone3.is_answerable()`; `touch_phone()` → +10 y `faults == 0`. Antes de `call_time + release_delay`, el auto sigue detenido aunque `driver.target = 170`. Después, `car.progress > 6336 + 100` en ≤ 5 s y `Phone3.get_state() == DONE` |
| 7 | Tocar mientras entra al cajón | `restart_at(5500)`; cuando `Phone3.is_ringing()` y `car.speed > 10`, `touch_phone()` | Tras la tapa: `infractions[&"phone"] == 1`; `Layer` oculto (`WAITING_PARK`); al estacionarse, `is_answerable()`; `touch_phone()` → +10 y el auto sale |
| 8 | Sin contestar sigue solo | `restart_at(5500)`, se estaciona y no toca | A `answer_timeout + 0.5`: `DONE`, puntos sin cambio, `faults == 0`, el auto avanza al dar gas |
| 9 | Peque: mismas reglas | `GameState.mode = peque`; `restart_at(700)` sin driver (avanza solo); al sonar, `touch_phone()` | Después de la tapa: `infractions[&"phone"] == 1`. En otra pasada sin tocar: +10 |
| 10 | Peque contesta | Peque, `restart_at(5500)` | Se estaciona solo; `touch_phone()` → +10; tras `call_time + release_delay`, `car.progress` aumenta sin tocar pedales |
| 11 | Punto de control | Con Phone2 sonando, `car.restart_at(3300 − 64)` y `rm.checkpoint_restored.emit(3236.0)` | `Phone2.get_state() == IDLE`, `Layer` oculto; al manejar otra vez vuelve a sonar (`ring_started` se emite de nuevo); `Phone1.get_state() == DONE` (no se reinicia) |
| 12 | Tráfico por modo | Grande, `restart_at(5500)`, contar `NpcCar` hijos de `TrafficLeft` durante 12 s | Grande ≥ 2; Peque ≤ Grande; ningún `NpcCar` con `position.x < 5100` |

**Recorridos completos:** los cubre `tests/test_levels.gd` en cuanto `data/level_06.tres` tenga `scene_path`. Es el punto 7 de la base técnica: la lista de niveles sale de `LevelData`.

- El conductor cuidadoso no toca el celular. En el cajón, lo suelta el `answer_timeout`.
- Por eso tiene que terminar con **3 estrellas y sin faltas en Grande y en Peque**.
- No hay que editar `test_levels.gd`.

---

## 8. Arte usado

Solo arte que ya existe:

| Uso | Archivo |
| --- | --- |
| Celular (chico, grande y en llamada; es el mismo sprite) | `assets/ui/phone.png` (168 × 320) |
| Casa de los primos | `assets/sprites/city/casas.png`, región `Rect2(128, 0, 128, 128)` |
| Edificios junto al cajón (opcional) | `assets/sprites/city/edificios.png`, región `Rect2(142, 0, 142, 160)` |
| Calle, banquetas, casas de fondo, meta | `assets/tiles/street_tiles.tres` (lo pinta `level_builder`) |
| Semáforo | `assets/sprites/signals/traffic_light.png` (lo trae `traffic_light`) |
| Letrero de 30 km/h | `assets/sprites/signals/signs.png` (lo trae `speed_zone`) |
| Peatón del paso | El que trae `crosswalk.tscn` por defecto |
| Tráfico | `scenes/actors/npc_car.tscn` (`assets/sprites/vehicles/npc_car.png` con `body_color`) |
| Cajón | Lo dibuja `parking_spot` (`_draw`) |
| Ilustración de la tarjeta | `assets/ui/habit_cards/card_06.png` (ya está en `data/level_06.tres`) |

**Provisionales** (no se genera nada con Pixel Engine):

- **Sonido del celular:** `ring_sound = null` hasta que Audio entregue `assets/audio/sfx/phone_ring.wav` (en el sprint aparece como «vibración del celular»). El nivel funciona en silencio.
- **Voces** de las 11 claves nuevas: voz provisional de espeak-ng, como dice `plan_cierre.md`.
- **Pantalla de «en llamada»:** se usa el mismo `phone.png` quieto y sin pulso. No hace falta arte nuevo.

### Cambios en `data/level_06.tres`

- `destination_key = "DESTINO_CASA_PRIMOS"`
- `scene_path = "res://levels/level_06.tscn"`
