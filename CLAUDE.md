# RutaKids — instrucciones para Claude Code

Juego móvil 2D (Android e iOS) hecho en Godot 4 para Fundación ADO. Niñas y niños de 4 a 13 años manejan un auto visto desde arriba por una ciudad basada en Puebla. Cada nivel enseña un punto del decálogo de movilidad. El diseño completo está en `docs/diseno.md` y las tareas están en `PLAN.md`.

## Reglas que nunca se rompen

- Nada de internet: sin peticiones HTTP, sin SDKs de anuncios ni de analíticas, sin servicios en línea (REQ-5).
- Nada de datos personales: no se piden nombres, correos, ubicación ni identificadores. Solo se guardan estrellas, puntos y ajustes en `user://save.cfg` (REQ-6).
- Nada violento: el auto nunca atropella a nadie. Si va a tocar a un peatón, frena solo antes (falta grave).
- No se usa el logo, el camión ni la terminal de ADO. Sí se usa su paleta de colores.
- Todo texto visible sale de `i18n/textos.csv` con `tr("CLAVE")`. Nunca se escribe texto directo en scripts ni en escenas.

## Cómo trabajar

- Haz una tarea de `PLAN.md` por sesión, en una rama `feature/<nombre-corto>`.
- Antes de empezar, lee la tarea y su criterio de terminado. Si algo no está claro, pregunta en vez de inventar reglas del juego.
- Al terminar, explica cómo probarla en el editor de Godot (qué escena abrir y qué hacer), porque el equipo la prueba a mano antes de aceptarla.
- Marca la tarea en `PLAN.md` solo cuando el equipo confirme que funciona.
- No cambies las decisiones técnicas de abajo sin preguntar.

## Decisiones técnicas

- Godot 4, la misma versión estable para todo el equipo. GDScript con tipos estáticos.
- Render: Compatibility (OpenGL). Es el que mejor corre en gama baja.
- Pantalla horizontal. Viewport base 1280 × 720, stretch mode `viewport`, aspect `expand`. Se duplicó de 640 × 360 para usar los sprites de Pixel Engine a su tamaño original (salen de ~100 px y al reducirlos se pierde el detalle).
- Filtro de texturas por defecto: Nearest (pixel art).
- Tiles de 64 × 64 px en `TileMapLayer`. Un carril mide 64 px. Los sprites de Pixel Engine se usan a 1:1, sin reducir ni escalar.
- Audio: `.ogg` para música y voces, `.wav` para efectos cortos.
- Exportar Android con arm64 y armv7 para cubrir celulares viejos. iOS se exporta desde las Mac de Diego o Dylan.

## Convenciones de código

- Archivos y carpetas en `snake_case`. `class_name` en `PascalCase`. Nodos en `PascalCase`.
- Señales en pasado: `infraction_reported`, `level_finished`.
- Nombres de código en inglés; textos, comentarios y commits en español.
- Valores ajustables como `@export`, no como números sueltos dentro del código.
- Nada de `get_node` con rutas largas entre escenas: usa señales, grupos o los autoloads.

## Estructura

```text
res://
  autoload/        game_state.gd, save_data.gd, audio_manager.gd, feedback.gd
  scenes/ui/       main_menu, level_select, age_select, hud, pause_menu, habit_card, tutor_screen
  scenes/level/    level.tscn, player_car.tscn, rule_manager.gd
  scenes/rules/    stop_zone, crosswalk, traffic_light, speed_zone, bike_lane,
                   look_mark, dark_zone, phone_event, bus_stop, ambulance_event
  scenes/actors/   pedestrian, npc_car, cyclist
  levels/          level_00.tscn … level_10.tscn
  data/            level_00.tres … level_10.tres
  resources/       level_data.gd
  i18n/            textos.csv
  assets/          sprites/, tiles/, ui/, audio/sfx/, audio/voz/, audio/musica/
  docs/            diseno.md
```

## Cómo funciona un nivel

1. `level.tscn` es la escena base. Cada nivel la hereda y agrega su `TileMapLayer`, su ruta y sus piezas de reglas.
2. El auto (`PlayerCar`) sigue la ruta (`DrivingRoute`, un `Path2D`) con un `PathFollow2D`. `progress` avanza con la velocidad. Cambiar de carril es animar `v_offset` con un tween; cada calle define sus carriles con `StreetSection`. Los giros están en la ruta y se marcan con `TurnPoint`: el niño elige girar tocando la flecha que marca el piso; si no la toca, el auto se detiene antes del cruce y espera (las otras flechas no hacen nada ahí). El auto pone la direccional 1 segundo antes de cada giro y cada cambio de carril. Para mover el auto a un punto de control usa `restart_at()`, no cambies `progress` directo.
3. Cada pieza de regla es un `Area2D` que detecta al auto (grupo `player`), revisa su estado (velocidad, luces, cinturón) y llama al `RuleManager`. Cada pieza reporta como máximo una falta por pasada.
4. `RuleManager` cuenta faltas y puntos, guarda el último punto de control y calcula las estrellas al llegar a la meta.
5. `Feedback` (autoload con `process_mode = ALWAYS`) muestra al copiloto con el texto y reproduce `assets/audio/voz/<CLAVE>.ogg` si existe. `show_infraction()` pausa el juego 2 segundos; `show_good_action()` suena alegre y muestra "+10" sin pausar; `show_info()` solo habla. El `RuleManager` lo llama solo; las piezas de reglas no lo usan directo.

API del RuleManager:

```gdscript
signal infraction_reported(rule_id: StringName, grave: bool)
signal good_action_reported(action_id: StringName, points: int)
signal level_finished(stars: int)

func report_infraction(rule_id: StringName, message_key: String, grave := false) -> void
func report_good_action(action_id: StringName, message_key: String, points := 10) -> void
func set_checkpoint(progress: float) -> void
func finish_level() -> void
```

Estrellas: 0 faltas = 3, 1 o 2 faltas = 2, 3 o más = 1. La falta grave cuenta como falta y regresa al último punto de control.

## Modos

- `GameState.mode`: `"peque"` (4 a 7 años: el auto acelera solo al 70% del límite, solo freno y flechas, menos tráfico) o `"grande"` (8 a 13: dos pedales, más tráfico, reloj, celular y luces).
- `GameState.kiosk`: todos los niveles abiertos, no se guarda nada, se oculta Salir y tras 60 segundos sin tocar la pantalla se vuelve al inicio.
- La pantalla de tutores se abre manteniendo presionado el engrane 3 segundos.

## Paleta de colores

Oficiales: rojo ADO `#DD2835` (bordes y barra), morado oscuro `#3F1B4E` (fondo de botones), amarillo dorado `#FFC700` (detalles y Jugar), blanco `#FFFFFF` (texto), cielo `#4A235A` → `#9C4B79` → `#E86F56` (gradiente de arriba a abajo), asfalto `#534A5E`.

Extra (propuesta): contorno `#1E0F26`, llantas y sombras `#2A2230`, banqueta `#B8A6CC`, nubes y luces `#F8C99B`, verde `#3FA34D`, verde oscuro `#2B6B3F`, vidrios `#7FC8E8`, piel `#F2C29B` `#C68B59` `#8A5A3B`.

Define estos colores una sola vez en un tema de Godot (`assets/ui/theme.tres`) y en constantes de `game_state.gd`. No escribas colores sueltos en las escenas.

## Rendimiento (gama baja)

- La app debe abrir en menos de 3 segundos (HU-01).
- Sprites en atlas de máximo 2048 × 2048. Nada de fondos gigantes de una sola imagen.
- Sin shaders pesados ni partículas en exceso. Objetivo de 60 fps y nunca abajo de 30.

## Pixel Engine

Solo hay 100 créditos. Antes de generar algo, revisa el orden y las reglas de la sección de assets en `PLAN.md` y avisa cuántos créditos va a costar. Fondo liso, vista desde arriba, paleta de ADO en `palette`, y el primer sprite aprobado como `source_job_id` para los demás. Descarga cada resultado a `assets/sprites/` en el momento, porque los enlaces caducan.
