# RutaKids

Juego móvil 2D para Fundación ADO. Niñas y niños de 4 a 13 años manejan un auto visto desde arriba por una ciudad basada en Puebla, y cada nivel enseña un punto del decálogo de movilidad.

## Arquitectura: app nativa + Godot incrustado

La app es **nativa en cada plataforma** y **Godot solo corre los niveles**:

| Parte | Quién la hace |
| --- | --- |
| Inicio, selección de edad y de niveles, pantalla de tutores, modo kiosco, guardado del progreso | **App nativa**: Swift/SwiftUI en iOS, Kotlin/Jetpack Compose en Android |
| Niveles: manejo, reglas, copiloto, tarjeta de hábito | **Godot 4.7.2 incrustado**: SwiftGodotKit en iOS, `godot-lib` + plugin v2 en Android |

La app nativa y Godot hablan por un puente llamado **`RutaBridge`** con mensajes JSON (`"v": 1`):

```text
 App nativa (menús, guardado)                       Godot (solo niveles)
 ────────────────────────────                       ────────────────────
 start_level / pause_level / resume_level  ───────▶  BridgeClient (autoload)
 abort_level / set_muted                             abre data/level_XX.tres
                                                      │
 guarda estrellas, puntos, faltas          ◀───────  engine_ready, level_started,
 esconde la vista de Godot al salir                   level_finished, level_exited,
                                                      inactivity_timeout,
                                                      tutor_requested, bridge_error
```

Godot arranca una sola vez en una escena vacía (`scenes/bridge/idle.tscn`) y avisa `engine_ready`. Cuando el niño elige un nivel, el nativo manda `start_level`. Al llegar a la meta, Godot manda `level_finished` y muestra la tarjeta de hábito. Al tocar Continuar, Godot manda `level_exited` y el nativo vuelve a su menú.

## Documentos

| Documento | Contenido |
| --- | --- |
| [`docs/arquitectura.md`](docs/arquitectura.md) | **Documento vivo de la arquitectura**: quién hace qué, tecnología para incrustar Godot, contrato completo del puente, ciclo de vida, hallazgos H1–H13 y resultados del spike |
| [`docs/arquitectura_propuesta_original.md`](docs/arquitectura_propuesta_original.md) | Propuesta original de la arquitectura híbrida, antes del spike |
| [`docs/plan_de_pruebas_avance.pdf`](docs/plan_de_pruebas_avance.pdf) | Plan de pruebas (IEEE 829) de la arquitectura híbrida: tipos de prueba, responsables y calendario |
| [`native/ios/README.md`](native/ios/README.md) | Cómo compilar y medir la app de iOS en una Mac |
| [`native/ios/CLAUDE.md`](native/ios/CLAUDE.md) | Instrucciones para el agente de Claude Code en la Mac |
| [`CLAUDE.md`](CLAUDE.md) | Reglas del proyecto y decisiones técnicas del lado de Godot |
| [`PLAN.md`](PLAN.md) | Tareas por fase y su criterio de terminado |
| `RutaKids — Diseño del juego.pdf` | Diseño del juego: niveles, reglas y decálogo |


## Estructura

```text
autoload/         GameState, Feedback, AudioManager, BridgeClient (puente del lado de Godot)
scenes/bridge/    idle.tscn, fake_bridge.gd (editor), host_bridge.gd (iOS), level_test.tscn (nivel 99)
scenes/level/     level.tscn (escena base), auto, RuleManager
scenes/rules/     piezas de reglas: alto, cruce peatonal, semáforo, velocidad, ciclovía, cruce ciego…
levels/           level_00.tscn … (escenas heredadas de level.tscn)
data/             level_00.tres … level_10.tres, level_99.tres
native/android/   app de Android Studio (Compose + GodotFragment + RutaBridgePlugin.kt)
native/ios/       app de Xcode (SwiftUI + SwiftGodotKit + RutaBridge.swift)
tests/            pruebas automáticas (tests/run_tests.sh)
tools/            constructor de niveles e importador de sprites
docs/             arquitectura, plan de pruebas y prompts de arte
```

## Ramas

El trabajo más reciente está en `feature/modo-peque`; cada rama `feature/*` sale de la anterior. `main` se actualiza cuando el equipo prueba y acepta las tareas.

## Cómo probar

- **Godot**: abrir el proyecto con Godot 4.7.2. F5 abre el nivel 1 con el puente falso (`-- --fake-level=N` para otro nivel); F6 sobre un nivel lo juega directo.
- **Pruebas automáticas**: `tests/run_tests.sh` (sin abrir el editor). Flujo de trabajo abajo.
- **Android**: `native/android/sync_godot.sh` y luego abrir `native/android/` en Android Studio.
- **iOS**: seguir `native/ios/README.md`.

### Flujo de pruebas

- **Mientras programas**: corre solo lo que tocaste, con `--only=<tema>` (texto que aparece en el nombre del archivo `tests/test_*.gd`), o `--fast` para todo menos las pruebas lentas.
- **Antes de entregar**: corre la suite completa, `tests/run_tests.sh`. Corre en paralelo y tarda unos 12 s. Debe terminar con `0 fallan`.

```bash
tests/run_tests.sh --only=yellow                          # solo test_yellow_crossing.gd
tests/run_tests.sh --only=yellow,phone                    # dos temas a la vez
tests/run_tests.sh --only=test_levels.gd                  # un archivo exacto
tests/run_tests.sh --fast                                 # todo menos las pruebas SLOW
tests/run_tests.sh --only=levels --level=3 --mode=peque   # un nivel en un modo
tests/run_tests.sh -j 1 --only=yellow,phone               # en serie, un proceso
```

- `-j N` (o `RUTAKIDS_JOBS=N`) fija cuántos procesos corren a la vez; por defecto son núcleos − 2.
- **Regla SLOW**: si tu prueba juega un nivel completo o tarda más de ~10 s, ponle `const SLOW := true` justo debajo del `extends`. Una prueba sin SLOW que tarde más de 10 s sale con un `AVISO` en el resumen. Por defecto una prueba nueva no es SLOW.
- Cada corrida guarda su log en `tests/resultados/` con la fecha, la hora y el commit.
