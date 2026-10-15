# RutaKids — arquitectura híbrida (app nativa + Godot como módulo)

Propuesta: la app es nativa en cada plataforma (Swift en iOS, Kotlin en Android). Godot solo corre los niveles. La app nativa abre un nivel en Godot y Godot le regresa el resultado al terminar. Todo el guardado lo hace la app nativa.

> Estado: **por validar con una prueba técnica (spike)**. Si esta arquitectura se adopta, reemplaza lo que dicen `CLAUDE.md` y `PLAN.md` sobre menús, SaveData, modo kiosco y pantalla de tutores dentro de Godot. Si el spike falla, se queda la arquitectura actual (todo en Godot).

## 1. Quién hace qué

| Parte | Responsable | Detalle |
| --- | --- | --- |
| Pantalla de inicio, selección de edad, selección de niveles | App nativa | SwiftUI en iOS, Jetpack Compose en Android |
| Pantalla de tutores y modo kiosco | App nativa | Incluye el bloqueo de pantalla del kiosco |
| Guardado de progreso y ajustes | App nativa | iOS: UserDefaults o SwiftData. Android: DataStore o Room. Solo estrellas, puntos, faltas por regla y ajustes. Nada personal |
| Niveles (manejo, reglas, copiloto, tarjeta de hábito) | Godot | Exportado como `main.pck` dentro de cada app |
| Comunicación entre los dos | Puente `RutaBridge` | Un objeto que los dos lados ven, con señales y mensajes en JSON |

Godot **no guarda nada en disco**. Todo lo que necesita lo recibe al abrir el nivel, y todo lo que produce lo entrega al cerrarlo.

## 2. Tecnología para incrustar Godot

- **Base: LibGodot.** Desde Godot 4.6, Godot puede compilarse como librería para incrustarse en otra app. Se usa en producción con Swift y Kotlin. La función para detener Godot y volver a arrancarlo todavía se está integrando (ver hallazgo H1).
- **iOS: SwiftGodotKit.** Pone el juego dentro de una vista de SwiftUI (`GodotApp(packFile: "main.pck")` + `GodotAppView()`). El puente es una clase Swift marcada con `@Godot`, con propiedades `@Signal`, registrada con `Engine.registerSingleton` en el hook de inicio (`initHookCb`, nivel `.scene`). En GDScript se obtiene con `Engine.get_singleton("RutaBridge")`. Los nombres camelCase de Swift llegan en snake_case a Godot.
- **Android: Godot como librería** (`godot-lib`, la librería oficial de Godot para Android) dentro de una `Activity` o `Fragment` de la app. El puente es un **plugin de Android v2** escrito en Kotlin (clase que extiende `GodotPlugin`, métodos con `@UsedByGodot` y señales registradas y emitidas desde Kotlin). En GDScript se obtiene igual, con `Engine.get_singleton("RutaBridge")`.
- **Versión:** fijar una sola versión de Godot (4.6 o superior) que sea compatible con SwiftGodotKit y con `godot-lib`. Verificar la compatibilidad antes de empezar: es el primer punto del spike.

## 3. Contrato del puente

Un solo singleton llamado `RutaBridge` en las dos plataformas, con los mismos nombres. Los datos viajan como **texto JSON** para no depender de cómo cada plataforma convierte diccionarios. Todo mensaje lleva `"v": 1` para poder cambiar el formato después.

### Nativo → Godot (métodos)

| Método | Cuándo | Datos |
| --- | --- | --- |
| `start_level(json)` | El niño toca un nivel | `{"v":1,"level_id":3,"mode":"peque","kiosk":false,"muted":false}` |
| `pause_level()` | La app pasa a segundo plano o entra una llamada | — |
| `resume_level()` | La app regresa | — |
| `abort_level()` | El nativo necesita cerrar el nivel (kiosco, tutor) | — |
| `set_muted(bool)` | Cambia el sonido desde el nativo | — |

### Godot → Nativo (señales)

| Señal | Cuándo | Datos |
| --- | --- | --- |
| `engine_ready` | Godot terminó de arrancar y está esperando en la escena vacía | — |
| `level_started(json)` | El nivel ya cargó y se ve | `{"v":1,"level_id":3}` |
| `level_finished(json)` | El niño llegó a la meta | `{"v":1,"level_id":3,"stars":2,"points":40,"infractions":{"stop":1,"speed":0},"duration_s":95}` |
| `level_exited(json)` | El niño tocó Salir en la pausa | `{"v":1,"level_id":3,"completed":false}` |
| `inactivity_timeout` | 60 s sin tocar la pantalla dentro de un nivel (solo kiosco) | — |
| `bridge_error(json)` | Algo falló (nivel inexistente, JSON inválido) | `{"v":1,"code":"unknown_level","detail":"..."}` |

Reglas del contrato:

- Godot valida el JSON que recibe. Si algo no cuadra, emite `bridge_error` y no se queda colgado.
- El nativo nunca asume que un nivel terminó si no recibió `level_finished` o `level_exited`.
- `infractions` usa los mismos `rule_id` del RuleManager: `stop`, `red_light`, `speed`, `crosswalk`, `bike_lane`, `look`, `patience`, `yellow`, `phone`, `lights`, `distance`, `ambulance`, `crash`.

## 4. Ciclo de vida

1. **Arranque de la app:** el nativo muestra el menú y, en segundo plano, inicia Godot con la vista escondida. Godot carga una escena vacía (`idle.tscn`) y emite `engine_ready`.
2. **Abrir nivel:** el nativo muestra la vista de Godot y llama `start_level`. Godot cambia a la escena del nivel y emite `level_started`. Mientras no llegue `engine_ready`, el botón del nivel muestra un indicador de carga.
3. **Jugar:** todo pasa dentro de Godot (reglas, copiloto, tarjeta de hábito).
4. **Terminar:** Godot emite `level_finished` o `level_exited` y vuelve a `idle.tscn` para liberar memoria. El nativo guarda el resultado, esconde la vista de Godot y muestra el menú con las estrellas nuevas.
5. **Segundo plano:** el nativo llama `pause_level` y `resume_level`. Godot también escucha sus notificaciones de pausa de la aplicación, por si acaso.

Godot se inicia **una sola vez** por sesión de la app y nunca se destruye entre niveles.

## 5. Problemas, hallazgos y soluciones

| # | Problema o hallazgo | Impacto | Solución |
| --- | --- | --- | --- |
| H1 | Detener Godot y volver a arrancarlo todavía no está terminado en LibGodot (los parches de reinicio se están integrando) | Si se crea y destruye Godot en cada nivel, puede fallar o fugar memoria | Iniciar Godot una vez, mantenerlo vivo y solo esconder o mostrar su vista. Entre niveles regresar a `idle.tscn` |
| H2 | Godot tarda en arrancar la primera vez | Puede romper el objetivo de abrir en menos de 3 s (HU-01) | El menú nativo abre al instante. Godot arranca en segundo plano mientras el niño ve el menú. Medir el tiempo en un celular de gama baja |
| H3 | Godot no corre en el simulador de iOS | No se puede probar el juego en el simulador | Probar siempre en iPhone o iPad reales. El menú nativo sí se puede probar en el simulador con un puente falso |
| H4 | Godot agrega unos 30 MB al tamaño de la app | Más espacio y descarga (HU-03 pide ocupar poco) | Comprimir texturas, usar `.ogg`, no incluir lo que no se usa en la exportación. Medir el tamaño final en las dos plataformas |
| H5 | El puente se escribe dos veces (Swift y Kotlin) y pueden quedar diferentes | Errores que solo pasan en una plataforma | Un solo contrato (sección 3) con los mismos nombres. Pruebas del puente iguales en las dos plataformas. Mensajes en JSON con versión |
| H6 | Hay que probar los niveles sin abrir la app nativa | Desarrollar niveles sería muy lento | En Godot, si `Engine.has_singleton("RutaBridge")` es falso, usar un `FakeBridge` en GDScript que arranca un nivel de prueba y escribe el resultado en consola. Así se juega directo desde el editor |
| H7 | Godot y el menú nativo usan memoria al mismo tiempo | En gama baja puede haber cierres | Menú nativo ligero. Godot vuelve a `idle.tscn` al terminar cada nivel. Probar con el celular más barato que tengan |
| H8 | Los textos quedan repartidos en tres lugares (Godot, iOS, Android) | ADO tendría que revisar textos en varios archivos | Un solo `textos.csv` como fuente. Un script genera `Localizable.strings` (iOS) y `strings.xml` (Android) a partir de él. Godot lo usa directo |
| H9 | La versión de Godot tiene que coincidir con SwiftGodotKit y con `godot-lib` | Si no coinciden, no compila o falla al arrancar | Fijar la versión en el spike y anotarla en el README. Nadie la cambia sin probar las dos plataformas |
| H10 | Cada cambio en Godot requiere volver a exportar `main.pck` y copiarlo a dos proyectos | Se olvida y se prueba una versión vieja | Script que exporta con `godot --headless --export-pack` y copia el `.pck` al bundle de Xcode y a `assets/` de Android |
| H11 | Kiosco: el contador de inactividad vive en dos lugares | El reinicio puede fallar dentro de un nivel | El nativo cuenta la inactividad en los menús. Dentro del nivel cuenta Godot y emite `inactivity_timeout`. El nativo reinicia todo |
| H12 | El bloqueo de pantalla del kiosco | El juego no debe dejar salir al niño | Ahora es más sencillo porque la app es nativa: Android usa lock task desde Kotlin. En iPad el personal activa Acceso Guiado |
| H13 | Más proyectos y más integración con 4 personas y entrega el 15 de noviembre | Riesgo alto de no llegar | Hacer primero el spike (sección 6) con fecha límite. Si falla, volver a todo en Godot sin perder lo hecho en niveles |

## 6. Spike (primera tarea, 1 o 2 días)

Objetivo: probar que el puente funciona de ida y vuelta en las dos plataformas antes de construir encima.

- [ ] Elegir y fijar la versión de Godot compatible con SwiftGodotKit y `godot-lib`.
- [ ] Proyecto Godot mínimo: `idle.tscn` y un `level_test.tscn` con un botón "Terminar". Script `bridge_client.gd` que usa `RutaBridge` o el `FakeBridge`.
- [ ] iOS: app SwiftUI con un botón "Nivel 1". Muestra `GodotAppView`, manda `start_level` y recibe `level_finished`. Muestra las estrellas en una etiqueta nativa.
- [ ] Android: app en Compose con lo mismo, usando `godot-lib` y un plugin v2 en Kotlin.
- [ ] Abrir y cerrar el nivel 10 veces seguidas sin cierres ni aumento de memoria.
- [ ] Medir: tiempo hasta `engine_ready`, tamaño de la app y memoria en un celular de gama baja.

Criterio de terminado: todo lo anterior funciona en un iPhone o iPad real y en un Android real. Si no está listo en 2 días de trabajo, se descarta esta arquitectura y se sigue con todo en Godot.

## 7. Estructura de repositorio sugerida

```text
rutakids/
  godot/            proyecto Godot (solo niveles, idle.tscn, bridge_client.gd, fake_bridge.gd)
  ios/              proyecto Xcode (SwiftUI, SwiftGodotKit, RutaBridge.swift)
  android/          proyecto Android Studio (Compose, godot-lib, RutaBridgePlugin.kt)
  shared/
    textos.csv      fuente única de textos
    bridge.md       este contrato
  scripts/
    export_pck.sh   exporta main.pck y lo copia a ios/ y android/
    gen_strings.py  genera los textos de iOS y Android desde textos.csv
```

## 8. Qué cambia en el plan actual

- Selección de niveles, selección de edad, pantalla de tutores, modo kiosco y SaveData pasan de Godot a la app nativa (dos veces: iOS y Android).
- En Godot desaparecen `main_menu`, `level_select`, `age_select`, `tutor_screen` y `save_data.gd`. Se agregan `idle.tscn`, `bridge_client.gd` y `fake_bridge.gd`.
- El RuleManager, las piezas de reglas, los niveles, el copiloto y la tarjeta de hábito no cambian.
- El spike va antes de la Fase 1.

## Fuentes

- [LibGodot – Embed Godot Everywhere with Godot 4.6 and Beyond (GodotCon Amsterdam 2026)](https://talks.godotengine.org/godotcon-ams-2026/talk/DQXZZC/)
- [Embedding Godot games in iOS apps is easy now (Christian Selig)](https://christianselig.com/2025/05/godot-ios-interop/)
- Documentación oficial de Godot sobre la librería de Android y los plugins de Android v2: revisar la versión que corresponda a la versión de Godot elegida.
