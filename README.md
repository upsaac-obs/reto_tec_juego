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

## Estado del spike

- **Android** (Samsung Galaxy A15): funciona. Menú nativo en 1.9 s, `engine_ready` en 3.7 s, memoria estable (247 → 253 MB en 10 ciclos de abrir y cerrar un nivel). APK *release*: 78.1 MB solo arm64, 150.5 MB con arm64 + armv7.
- **iOS**: el kit está listo en `native/ios/`, falta compilarlo y medirlo en una Mac con un iPhone o iPad real.
- **Por confirmar con Fundación ADO**: si Godot incrustado dentro de una app nativa cuenta como desarrollo nativo.

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
- **Pruebas automáticas**: `tests/run_tests.sh` (sin abrir el editor).
- **Android**: `native/android/sync_godot.sh` y luego abrir `native/android/` en Android Studio.
- **iOS**: seguir `native/ios/README.md`.
