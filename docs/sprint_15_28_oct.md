# RutaKids — plan del sprint (15 al 28 de octubre de 2026)

Objetivo del sprint: **terminar el juego (niveles 3 a 8) y los menús nativos de iOS y Android**.

Responsables: **Diego Sánchez**, **Paulo Vélez** y **Ángel Mael**.

| Fecha | Meta |
| --- | --- |
| 22 oct | Niveles 3 a 8 jugables en Peque y Grande (fin de la Fase 2) |
| 25 oct | Menús nativos completos en iOS y Android |
| 26 al 28 oct | Integración: los menús abren los niveles 0 a 8 en los dos celulares |

## 1. Punto de partida (15 oct)

- **Juego (Godot 4.7.2):** los niveles **0, 1 y 2** se juegan completos en Peque y Grande. El nivel **3** tiene sus 3 cruces sin vista, pero no tiene final ni destino. Los niveles **4 a 8** no existen todavía: su información básica está en `data/level_04.tres` … `level_08.tres` (sin escena), y casi todo su arte ya está en `assets/`.
- **Piezas que ya existen y se reutilizan:**

  | Grupo | Archivos |
  | --- | --- |
  | Reglas (`scenes/rules/`) | `stop_zone`, `crosswalk`, `traffic_light` (con regla de amarillo `check_yellow`), `speed_zone`, `bike_lane`, `blind_crossing`, `checkpoint` y `tutorial_hint` |
  | Personajes (`scenes/actors/`) | `pedestrian` (con `walk_speed`) y `npc_car` |

- **Puente `RutaBridge`:** el lado de Godot está terminado (`autoload/bridge_client.gd`); el contrato está en `docs/arquitectura.md`, secciones 3 y 4.
- **Android:** el spike funciona en el Galaxy A15 (`native/android/`), pero su menú es de prueba.
- **iOS:** el kit está escrito (`native/ios/`), pero nunca se ha compilado.

## 2. Reparto

| Persona | Menú nativo | Juego (Godot) |
| --- | --- | --- |
| **Diego Sánchez** | **iOS completo** (SwiftUI): compilar el spike y hacer las 6 pantallas | Final del **nivel 3** |
| **Paulo Vélez** | **Android, parte 1** (Compose): navegación, Inicio, Selección de edad, Selección de niveles y guardado | **Niveles 4, 5 y 8** y el script de textos |
| **Ángel Mael** | **Android, parte 2** (Compose): Tutores, kiosco, segundo plano y sonido, build *release* | **Niveles 6 y 7** y el audio |

Diego tiene menos niveles porque hace él solo la plataforma completa. En Android, Paulo hace primero la navegación base (para el 18 de octubre) y Ángel construye sus pantallas encima.

## 3. Cómo se trabaja

- **Repositorio:** `https://github.com/upsaac-obs/reto_tec_juego`. Cada tarea va en su propia rama `feature/<nombre>`, que sale de `feature/modo-peque`, y se sube a GitHub al terminarla.
- **Godot:** las reglas del proyecto están en `CLAUDE.md` (sin internet, sin datos personales, textos con `tr()`, valores como `@export`). Si se usa Claude Code, ya lee ese archivo solo.
- **Niveles:** cada nivel nuevo es una **escena heredada** de `scenes/level/level.tscn` (ver "Cómo funciona un nivel" en `CLAUDE.md`).
  - Se guarda en `levels/level_XX.tscn`.
  - Se apunta `scene_path` y `destination_key` en `data/level_XX.tres`.
  - Su tarjeta de hábito (`assets/ui/habit_cards/card_XX.png`) ya existe.
  - Para generar el mapa y las piezas se puede usar `tools/level_builder.gd`.
- **Reglas del juego:** donde este plan dice **"a confirmar"**, el detalle no está en el diseño. Se decide en equipo antes de programarlo y se anota en `docs/diseno.md`; no se inventa.
- **Para probar un nivel:** en el editor, F6 sobre la escena del nivel. Para cambiar de modo, cambiar `GameState.mode`.

---

## 4. Juego: niveles 3 a 8

Para todos los niveles, el criterio de terminado es:

- Se juega de principio a fin en **Peque y Grande**.
- Cada regla da falta o puntos con el mensaje del copiloto.
- Termina en la tarjeta de hábito.
- Los textos nuevos están en `i18n/textos.csv`.

### Nivel 3 · Mira dos veces — Diego Sánchez (entrega 17 oct)

Ya están hechos los 3 cruces sin vista (`blind_crossing`). Falta el final, según el diseño: *"al final hay que estacionarse y abrir la puerta cuando ya no viene una bici"*.

1. **Elegir el destino con el equipo:** biblioteca o casa de la abuela. El arte se pide con el prompt #2 de `docs/prompts_fase3.md`; mientras llega, se usa un edificio de `assets/sprites/city/`.
2. **Pieza nueva `parking_spot`** (`scenes/rules/parking_spot.tscn`): un cajón de estacionamiento junto a la ciclovía, al final de la ruta. El auto tiene que detenerse dentro del cajón.
3. **Pieza nueva `door_exit`:** al estacionarse aparece el botón **Abrir puerta**. Por la ciclovía pasan 1 o 2 ciclistas (`assets/sprites/vehicles/cyclist_frames.tres`, siguiendo un `Path2D`).
   - Abrir mientras viene un ciclista cerca: **falta**. La puerta no se abre y el copiloto explica.
   - Abrir cuando ya pasó: **+10** y el nivel termina.
   - **A confirmar:** a qué distancia cuenta como "cerca" y si en Peque pasa un solo ciclista.
4. Agregar los textos: el nombre del destino, el botón y los mensajes de falta y de acierto.

### Nivel 4 · Con calma — Paulo Vélez (entrega 18 oct)

Diseño: *"personas mayores, una persona en silla de ruedas y un grupo escolar cruzan despacio. El semáforo cambia a verde antes de que terminen. Se evalúa: esperar aunque ya esté en verde."*

1. **Peatones lentos:** usar `pedestrian` con `walk_speed` bajo y los sprites `elder`, `wheelchair_frames.tres` y `adult_frames.tres`. El grupo escolar son 3 o 4 `girl_frames.tres` caminando juntos.
2. **Semáforo peatonal:** `assets/sprites/signals/pedestrian_light.png` (cuadros apagado, rojo y verde), sincronizado con `traffic_light` mediante su señal `light_changed`.
3. **Pieza nueva `patience_zone`:** cuando el semáforo de autos se pone en verde pero todavía hay peatones en el cruce:
   - Si el auto avanza hacia el cruce: **falta** "Hay quien necesita más tiempo".
   - Si espera a que terminen de cruzar: **+10**.
   - `crosswalk` sigue frenando solo el auto si va a tocar a alguien (falta grave).
   - **A confirmar:** qué cuenta como "avanzar" en Peque, donde el auto acelera solo (propuesta: soltar el freno antes de que terminen de cruzar).
4. **Mapa:** 3 cruces con semáforo; en cada uno cruza un tipo de persona distinto. Destino según `data/level_04.tres` (**a confirmar** si no tiene).

### Nivel 5 · Sin prisa — Paulo Vélez (entrega 21 oct)

Diseño: *"Hay un reloj para llegar a la terminal, pero siempre se llega a tiempo manejando bien. También hay semáforos en amarillo y una pelota que sale a la calle."* El reloj **solo es una tentación: no se puede perder por tiempo** (accesibilidad).

1. **Reloj en el HUD (solo en Grande):**
   - Cuenta hacia abajo con un tiempo que alcanza de sobra a velocidad legal.
   - Ícono: prompt #3 de `docs/prompts_fase3.md`; mientras llega, uno provisional.
   - Al llegar a cero no pasa nada malo: el copiloto dice algo como "¡Llegamos bien, eso es lo importante!".
2. **Amarillos:** 2 o 3 `traffic_light` con `check_yellow = true` y tiempos de amarillo largos.
3. **Pieza nueva `ball_event`:**
   - Una pelota sale rodando entre autos estacionados (`npc_car` quietos); un poco después sale una niña (`girl_frames.tres`) detrás de ella.
   - Si el auto no frena a tiempo, frena solo antes de tocarla: **falta grave**, igual que `crosswalk`.
   - Frenar a tiempo: **+10**.
   - **A confirmar:** si en Peque sale la niña o solo la pelota.
4. **Destino:** la terminal de autobuses (`assets/sprites/city/terminal.png`).

### Nivel 8 · Comparte el camino — Paulo Vélez (entrega 24 oct)

Diseño: *"Avenida con ciclovía, motos y un camión que se detiene en su parada. Se evalúa: dejar distancia con el ciclista y no rebasar el camión detenido."*

1. **Avenida** de 2 carriles por sentido con `bike_lane` a la orilla.
2. **Motos:** `npc_car` con el sprite `motorcycle.png`.
3. **Ciclistas** en la ciclovía (`cyclist_frames.tres`). **Pieza nueva `cyclist_distance`:** al pasar junto a un ciclista, el auto tiene que ir en el carril que no está pegado a la ciclovía. Si va en el carril pegado: **falta**. Si se cambia de carril: **+10**.
   - **A confirmar:** la regla de distancia exacta (propuesta: un carril de separación).
4. **Pieza nueva `bus_stop`:**
   - El camión (`bus.png`) se detiene en la parada (`bus_stop.png`, `bus_stop_sign.png`) y suben y bajan peatones.
   - Rebasarlo mientras está detenido: **falta**. Esperar detrás: **+10**.
   - **A confirmar:** si cambiarse de carril para rebasarlo también cuenta como falta, o solo pasarlo.

### Nivel 6 · Ojos en el camino — Ángel Mael (entrega 20 oct)

Diseño: *"El celular del auto suena y vibra durante el recorrido. Si el niño lo toca, la pantalla del celular tapa parte de la calle por 2 segundos. Se evalúa: no tocar el celular en movimiento. Al estacionarse sí se puede contestar y da puntos."*

1. **Pieza nueva `phone_event`:**
   - En puntos de la ruta, el celular (`assets/ui/phone.png`) aparece en una esquina, vibra (animación con un `Tween`) y suena.
   - Tocarlo **en movimiento**: **falta**, y el celular se agranda y tapa parte de la calle por 2 s (como dice el diseño, sin pausar el juego).
   - Ignorarlo hasta que deja de sonar: **+10** ("ignorar el celular", del diseño).
2. **Estacionarse para contestar:** reutilizar `parking_spot` del nivel 3 (coordinar con Diego). Si el auto está detenido en el cajón y el niño contesta: **+10**.
3. **Modo Peque:** el diseño dice que el celular aparece en Grande. **A confirmar** qué pasa en Peque (propuesta: suena, pero el copiloto dice "lo vemos al llegar" y no hay falta).
4. Elegir el destino con el equipo.

### Nivel 7 · Hazte visible — Ángel Mael (entrega 23 oct)

Diseño: *"Atardecer, un túnel y lluvia. Aparecen ciclistas con casco y reflejantes. Se evalúa: encender las luces en tramos oscuros."*

1. **Botón de luces** en el HUD:
   - Ícono #16 de `docs/prompts_assets.md` (apagado y encendido).
   - Agrega a `player_car` la propiedad `headlights_on` y dibuja los faros (cono de luz) con un `PointLight2D` o un sprite.
2. **Pieza nueva `dark_zone`:**
   - Oscurece la pantalla con un `CanvasModulate`, sin shaders pesados.
   - Entrar o seguir dentro sin luces más de 2 s: **falta**. Encenderlas a tiempo: **+10**.
   - Tramos: el atardecer, el túnel (`tunel_entrada.png` y `tunel_salida.png`) y la lluvia.
3. **Lluvia:** gotas con `GPUParticles2D` ligeras (o `CPUParticles2D`), más los charcos del prompt #3.
4. **Ciclistas con reflejantes:** el prompt #4 de `docs/prompts_fase3.md`; mientras llega, `cyclist_frames.tres`.
5. **Modo Peque:** el diseño dice que las luces son de Grande. **A confirmar** (propuesta: en Peque el copiloto las enciende solo y lo explica).
6. Elegir el destino con el equipo.

### Audio — Ángel Mael (entrega 24 oct)

- **Efectos `.wav`** en `assets/audio/sfx/`: motor, freno, claxon, direccional (tic-tac), celebración, "uy", vibración del celular, lluvia y sirena. `good.wav` ya existe.
- **Música `.ogg`** en `assets/audio/musica/`: un tema para los niveles, alegre y sin letra.
- **Voces `.ogg`:** una por cada clave de `i18n/textos.csv`, en `assets/audio/voz/<CLAVE>.ogg`.
  - `Feedback` las reproduce solo en cuanto existen.
  - Se generan con IA fuera del juego; el juego nunca se conecta a internet.
- Conectar el motor y el freno en `player_car` y la vibración en `phone_event`, usando `autoload/audio_manager.gd`.

### Script de textos — Paulo Vélez (entrega 19 oct)

`tools/gen_strings.py` lee `i18n/textos.csv` y genera los textos de cada app (hallazgo H8 de `docs/arquitectura.md`):

| App     | Archivo que genera                                      |
| ------- | ------------------------------------------------------- |
| iOS     | `native/ios/RutaKidsSpike/es.lproj/Localizable.strings` |
| Android | `native/android/app/src/main/res/values/strings.xml`    |

Así los menús nativos no tienen textos sueltos y ADO revisa un solo archivo. Hay que agregar al CSV las claves de los menús: Jugar, Peque, Grande, Tutores, Borrar progreso, Kiosco, etc.

---

## 5. Menús nativos (iOS y Android hacen lo mismo)

### 5.1 Pantallas

| Pantalla                 | Qué hace                                                                                                                            | Terminado cuando                                                                                                                                                                                                  |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Inicio**               | Fondo del menú, botón grande **Jugar**, engrane de tutores y botón de sonido                                                        | Se ve en menos de 3 s desde el ícono. Godot arranca **escondido** en segundo plano                                                                                                                                |
| **Selección de edad**    | Solo la primera vez: dos dibujos grandes, **Peque** (4 a 7) y **Grande** (8 a 13), con un toque                                     | Guarda el modo y no vuelve a salir. El modo se cambia desde Tutores                                                                                                                                               |
| **Selección de niveles** | 11 tarjetas (0 a 10) con ícono (`assets/ui/level_icons.png`), nombre y estrellas                                                    | El 0 siempre está abierto y cada nivel se abre con **1 estrella en el anterior**. Si Godot responde `level_not_built`, la tarjeta sale bloqueada                                                                  |
| **Nivel**                | Muestra la vista de Godot y manda `start_level` con `level_id`, `mode`, `kiosk` y `muted`                                           | Mientras no llegue `engine_ready`, la tarjeta muestra "cargando". **Con `level_finished` se guarda el resultado y la vista NO se cierra** (Godot muestra la tarjeta de hábito); se cierra solo con `level_exited` |
| **Tutores**              | Se abre manteniendo el engrane **3 s**, en el menú o dentro del nivel cuando llega `tutor_requested` (antes se manda `pause_level`) | Muestra las estrellas por hábito y deja cambiar el modo, borrar el progreso (con confirmación) y activar o desactivar el kiosco                                                                                   |
| **Kiosco**               | Todo abierto, no se guarda nada, sin Salir                                                                                          | Tras **60 s sin tocar** en los menús, vuelve a Inicio. Dentro del nivel, al llegar `inactivity_timeout`, se manda `abort_level` y se vuelve a Inicio                                                              |

**Ciclo de vida:**

| Cuándo                      | Qué manda la app |
| --------------------------- | ---------------- |
| La app pasa a segundo plano | `pause_level`    |
| La app regresa              | `resume_level`   |
| Se toca el botón de sonido  | `set_muted`      |

Godot se inicia **una sola vez** y nunca se destruye: entre un nivel y otro solo se esconde su vista.

### 5.2 Qué se guarda (nada personal)

| Dato                     | Ejemplo                                   |
| ------------------------ | ----------------------------------------- |
| `mode`                   | `"peque"` o `"grande"`                    |
| `muted`, `kiosk`         | `false`                                   |
| `level_<id>_stars`       | 0 a 3, siempre la **mejor**               |
| `level_<id>_points`      | los mejores puntos                        |
| `level_<id>_infractions` | `{"stop":1}`, para la pantalla de tutores |

- **iOS:** `UserDefaults`.
- **Android:** DataStore (Preferences).
- **En kiosco no se escribe nada.**
- **Sin internet:** sin el permiso `INTERNET` y sin SDKs de terceros.

### 5.3 Arte y textos

- **Arte del menú:** prompts #19 (fondo del menú), #20 (selección de edad) y #21 (ícono de la app) en `docs/prompts_assets.md`.
- **Íconos que ya existen:** `assets/ui/level_icons.png`, `assets/ui/icons/` (estrellas, engrane) y `assets/ui/app_icon.png`.
- **Sin el logo de ADO.** Los colores son los de la paleta de `CLAUDE.md`.
- **Textos:** salen de los archivos que genera el script de Paulo.

---

## 6. Diego Sánchez — iOS (SwiftUI)

Rama `feature/menu-ios`. Necesita la Mac con Xcode y un iPhone o iPad **real**, porque Godot no corre en el simulador. Los pasos para preparar la Mac y las instrucciones para Claude Code están en `native/ios/README.md` y `native/ios/CLAUDE.md`.

1. **Compilar el spike** (15 al 17 oct):
   - `export_pck.sh` → `xcodegen generate` → compilar.
   - Que llegue `engine_ready` y que el nivel 99 dé `level_started` → `level_finished` → `level_exited`.
   - Anotar en `docs/arquitectura.md`, sección 6, el tiempo de arranque, la memoria y el tamaño.
   - **Si el 17 no compila, avisar al equipo ese día con el error.**
2. **Final del nivel 3** (16 al 17 oct), sección 4.
3. **Navegación, Inicio y Selección de edad** (18 al 20 oct). Separar el puente (`RutaBridge.swift`) de las pantallas, para que las vistas solo llamen funciones como `startLevel(id)`.
4. **Selección de niveles y guardado** (20 al 22 oct), con `UserDefaults`.
5. **Tutores** (22 al 23 oct).
6. **Kiosco, segundo plano y sonido** (23 al 25 oct). Escribir en `native/ios/README.md` cómo activa el personal de ADO el **Acceso Guiado** en el iPad.
7. **Integración** (26 al 28 oct): `main.pck` final con los niveles 0 a 8, y abrirlos todos desde el menú en iPhone y iPad.

## 7. Paulo Vélez — Android parte 1 (Compose)

Rama `feature/menu-android-niveles`, partiendo de `native/android/` (`MainActivity.kt`, `RutaBridgePlugin.kt`). Para copiar el juego al proyecto: `native/android/sync_godot.sh`.

1. **Navegación base** (15 al 18 oct): pasar el menú de prueba de `MainActivity.kt` a pantallas de Compose con Navigation, más un `BridgeViewModel` que envuelva el puente y el estado de Godot (cargando, listo o nivel abierto). Godot sigue arrancando escondido. **Ángel arranca sus pantallas sobre esto el 18.**
2. **Inicio y Selección de edad** (17 al 18 oct).
3. **Nivel 4** (16 al 18 oct), sección 4.
4. **Script de textos** (19 oct), sección 4.
5. **Guardado con DataStore** (19 al 20 oct): la tabla de la sección 5.2, escrita al recibir `level_finished`.
6. **Selección de niveles** (20 al 22 oct): tarjetas con estrellas y desbloqueo.
7. **Nivel 5** (19 al 21 oct) y **nivel 8** (22 al 24 oct), sección 4.
8. **Integración** (26 al 28 oct): niveles 0 a 8 desde el menú en el Galaxy A15.

## 8. Ángel Mael — Android parte 2 (Compose)

Rama `feature/menu-android-tutores`, sobre la navegación base de Paulo.

1. **Nivel 6** (15 al 20 oct), sección 4. Puede empezar desde el primer día, porque no depende del menú.
2. **Pantalla de Tutores** (18 al 21 oct): engrane de 3 s y `tutor_requested` (con `pause_level`). Muestra estrellas por hábito y permite cambiar el modo, borrar el progreso con confirmación y activar el kiosco.
3. **Nivel 7** (20 al 23 oct), sección 4.
4. **Kiosco, segundo plano y sonido** (21 al 23 oct):
   - El contador de 60 s en los menús, y `inactivity_timeout` → `abort_level` dentro del nivel.
   - **Lock task** (fijación de pantalla) al activar el kiosco.
   - `pause_level`, `resume_level` y `set_muted`.
5. **Audio** (20 al 24 oct), sección 4.
6. **Build *release*** (24 al 25 oct):
   - Firmar con una llave propia del equipo (sin subirla a GitHub).
   - Confirmar que no se pide el permiso `INTERNET`.
   - Ícono de la app.
7. **Integración** (26 al 28 oct), junto con Paulo.

---

## 9. Reporte del sprint (15 al 28 de octubre de 2026)

El avance es al 15 de octubre.

| # | Tarea | Responsable | Avance | Entrega |
| --- | --- | --- | ---: | --- |
| 1 | iOS: compilar el spike en iPhone/iPad y medir arranque, memoria y tamaño | Diego Sánchez | 20 % | 17/10/26 |
| 2 | Nivel 3: destino, estacionarse y abrir la puerta sin ciclista (`parking_spot`, `door_exit`) | Diego Sánchez | 80 % | 17/10/26 |
| 3 | iOS: navegación, Inicio y Selección de edad | Diego Sánchez | 5 % | 20/10/26 |
| 4 | iOS: Selección de niveles con estrellas, desbloqueo y guardado (`UserDefaults`) | Diego Sánchez | 0 % | 22/10/26 |
| 5 | iOS: pantalla de Tutores | Diego Sánchez | 0 % | 23/10/26 |
| 6 | iOS: kiosco (60 s, `inactivity_timeout`, Acceso Guiado), segundo plano y sonido | Diego Sánchez | 0 % | 25/10/26 |
| 7 | iOS: integración con los niveles 0 a 8 | Diego Sánchez | 0 % | 28/10/26 |
| 8 | Android: navegación base en Compose y `BridgeViewModel` | Paulo Vélez | 15 % | 18/10/26 |
| 9 | Android: Inicio y Selección de edad | Paulo Vélez | 0 % | 18/10/26 |
| 10 | Nivel 4, Con calma: peatones lentos, semáforo peatonal, `patience_zone` | Paulo Vélez | 10 % | 18/10/26 |
| 11 | Script de textos `textos.csv` → iOS y Android | Paulo Vélez | 0 % | 19/10/26 |
| 12 | Android: guardado con DataStore | Paulo Vélez | 0 % | 20/10/26 |
| 13 | Nivel 5, Sin prisa: reloj, amarillos, `ball_event`, terminal | Paulo Vélez | 10 % | 21/10/26 |
| 14 | Android: Selección de niveles con estrellas y desbloqueo | Paulo Vélez | 0 % | 22/10/26 |
| 15 | Nivel 8, Comparte el camino: motos, `cyclist_distance`, `bus_stop` | Paulo Vélez | 10 % | 24/10/26 |
| 16 | Android: integración con los niveles 0 a 8 | Paulo Vélez | 0 % | 28/10/26 |
| 17 | Nivel 6, Ojos en el camino: `phone_event` y contestar estacionado | Ángel Mael | 10 % | 20/10/26 |
| 18 | Android: pantalla de Tutores | Ángel Mael | 0 % | 21/10/26 |
| 19 | Nivel 7, Hazte visible: botón de luces, `dark_zone`, túnel y lluvia | Ángel Mael | 10 % | 23/10/26 |
| 20 | Android: kiosco con lock task, segundo plano y sonido | Ángel Mael | 0 % | 23/10/26 |
| 21 | Audio: efectos, música y voces con IA | Ángel Mael | 5 % | 24/10/26 |
| 22 | Android: build *release* firmado con llave propia, sin `INTERNET` | Ángel Mael | 50 % | 25/10/26 |
| 23 | Android: integración con los niveles 0 a 8 | Ángel Mael | 0 % | 28/10/26 |

**Cómo se calculó el avance:**

| Tareas | Por qué tienen ese avance |
| --- | --- |
| 1 | El código del spike de iOS ya está escrito, pero falta compilarlo |
| 2 | Los 3 cruces del nivel 3 ya funcionan; falta el final |
| 3 | El spike trae un menú mínimo en `MenuView.swift` |
| 8 | El menú de prueba de Android ya abre niveles por el puente |
| 10, 13, 15, 17, 19 | El arte y el `LevelData` del nivel ya existen |
| 21 | Hay un solo efecto de sonido |
| 22 | El *release* ya se compiló y se midió (78.1 / 150.5 MB); falta la llave propia |

## 10. Decisiones que el equipo tiene que tomar esta semana

1. Los destinos de los niveles 3, 4, 6, 7 y 8.
2. Los detalles marcados **"a confirmar"** en la sección 4 (distancias, qué pasa en Peque con el celular y las luces, rebasar el camión).
3. **Fundación ADO:** si Godot incrustado dentro de la app cuenta como "nativo", y si se puede usar su logo en el menú.
4. **Si el spike de iOS no compila el 17:** se decide si iOS sigue con esta arquitectura o se exporta el juego completo desde Godot.
