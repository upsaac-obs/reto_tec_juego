# RutaKids — plan de cierre: niveles 5 a 8 (1 de noviembre de 2026)

Coordina Claude Code con agentes de rol (directores, líderes y especialistas). Este documento es la referencia común de todos los agentes.

## Alcance

El juego tiene **9 niveles: del 0 al 8**. Es lo que muestra el menú de iOS (tutorial 0 + niveles 1 a 8); Android se recorta a lo mismo. Los niveles 9 y 10 quedan fuera de esta entrega.

Hoy faltan los niveles **5, 6, 7 y 8**, el audio y el cierre de Android.

## Decisiones tomadas (1 nov)

| Tema | Decisión |
| --- | --- |
| Nivel 5, reloj | **Tablero de salidas de la terminal que siempre va "A tiempo".** Sin cuenta regresiva que empuje a correr. Al llegar, el copiloto dice "¡Llegamos a tiempo!" |
| Modo Peque | **Mismas reglas que Grande.** El niño frena y toca los botones (celular, luces); si no lo hace, es falta. En Peque, "acelerar" significa dejar que el auto avance solo sin frenar |
| Voces | **Todas las claves de `textos.csv`.** Desde el 12 de noviembre es la voz neuronal **Piper `es_MX-claude-high`** (Apache-2.0), generada sin internet con `tools/gen_voces.py`; la provisional espeak-ng queda como `--engine espeak` |
| Libertad de diseño | **Dentro del diseño.** Cada nivel tiene su regla principal del documento de diseño, un momento clímax y repaso de reglas anteriores. No se inventan reglas nuevas |
| Camión (nivel 8) | Solo es falta pasar junto al camión mientras está detenido en su parada |
| Salir del nivel | Mantener el engrane 3 s abre Tutores (que tiene Salir) |
| Destinos | Se usan los edificios que ya existen en `assets/sprites/city/` |

## Fases

| Fase | Quién (rol) | Qué | Depende de |
| --- | --- | --- | --- |
| 1 Diseño | game-designer + level-designer + writer (uno por nivel), revisa creative-director | Una ficha por nivel en `docs/niveles/nivel_0X.md`: regla, recorrido, momentos, Peque/Grande, textos | — |
| 2 Base técnica | lead-programmer | Cambios en archivos compartidos, una sola vez (ver abajo) | — |
| 2 Audio | sound-designer | Efectos `.wav` y voces de todas las claves | — |
| 2 Android | ui-programmer / release-manager | Lista 0–8, kiosco de 60 s, `inactivity_timeout`, release listo sin la llave | — |
| 3 Niveles | gameplay-programmer (uno por nivel), revisa qa-lead | Pieza nueva + nivel + pruebas | Fases 1 y 2 |
| 4 Integración | Claude Code, revisa technical-director | Juntar en `main` uno por uno con todas las pruebas | Fase 3 |
| 5 Cierre | producer | Revisar contra este plan y reportar | Fase 4 |

### Base técnica (fase 2)

Son los únicos cambios en archivos compartidos (`player_car.gd`, `hud.tscn`/`hud.gd`, `traffic_light.gd`, `feedback.gd`, `parking_spot.gd`, `door_exit.gd`, `tools/level_builder.gd`, `tests/test_levels.gd`). Después de esta fase, los niveles **no tocan esos archivos**.

1. **Engrane:** mantener 3 s llama `BridgeClient.request_tutor()`.
2. **Estacionamiento reutilizable:** `parking_spot` puede soltar el auto después de estacionar (nivel 6) y `door_exit` usa su propio cajón, no el primero del grupo.
3. **Amarillo en Peque:** el auto tiene una propiedad que dice si el niño "deja avanzar" el auto (Grande: acelera; Peque: no frena). `traffic_light` la usa para la regla del amarillo.
4. **Luces:** `player_car.headlights_on` y un botón de luces en el HUD que solo aparece si el nivel lo pide (nivel 7).
5. **Pausa con voz:** la pausa de una falta dura lo que dure su voz (mínimo `pause_time`).
6. **Constructor:** `level_builder` puede pintar avenidas de 4 carriles (nivel 8).
7. **Pruebas:** `test_levels` toma la lista de niveles de los `LevelData` construidos.
8. **Versión:** `engine_ready` manda el commit del build (`{"build": "..."}`), y `tools/export_all.sh` exporta el `main.pck` para las dos apps.

## Reglas para todos los agentes

- Las reglas del proyecto están en `CLAUDE.md` (sin internet, sin datos personales, nada violento, sin logo de ADO, textos con `tr()`, valores como `@export`, tipos estáticos). Textos, comentarios y commits en español.
- Cada agente trabaja en su propia copia (worktree) y rama; no toca archivos fuera de su tarea.
- Antes de entregar código: `tests/run_tests.sh` sin fallas.
- No se hace `git push`.
