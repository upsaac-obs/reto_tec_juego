# RutaKids — arquitectura híbrida (app nativa + Godot como módulo)

> Versión del repo. Cambios respecto al borrador original: mecanismo del puente (sección 3), la vista no se cierra en `level_finished` sino en `level_exited`, señal `tutor_requested`, `engine_ready` una sola vez, códigos de `bridge_error` y nivel de prueba 99.

Propuesta: la app es nativa en cada plataforma (Swift en iOS, Kotlin en Android). Godot solo corre los niveles. La app nativa abre un nivel en Godot y Godot le regresa el resultado al terminar. Todo el guardado lo hace la app nativa.

> Estado: **por validar con una prueba técnica (spike)**. El lado de Godot del spike ya está hecho (`autoload/bridge_client.gd`, `scenes/bridge/`); faltan las apps de iOS y Android. Si esta arquitectura se adopta, reemplaza lo que dicen `CLAUDE.md` y `PLAN.md` sobre menús, SaveData, modo kiosco y pantalla de tutores dentro de Godot. Si el spike falla, se queda la arquitectura actual (todo en Godot).

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

**Mecanismo (igual en las dos plataformas):**

- **Nativo → Godot:** el objeto `RutaBridge` **emite señales de Godot** con los nombres de la primera tabla (`start_level`, `pause_level`, …). `bridge_client.gd` se conecta a ellas. En Kotlin: `registerPluginSignals` + `emitSignal`. En Swift: propiedades `@Signal` + `emit`.
- **Godot → nativo:** GDScript llama **un solo método**, `notify(event: String, json: String)`, con los nombres de la segunda tabla. En Kotlin: `@UsedByGodot fun notify(...)`. En Swift: `@Callable func notify(...)`. Cada app lo convierte en lo que necesite (un `Flow`, un `@Published`, etc.).

Así cada plataforma implementa 5 señales y 1 método, y las dos quedan iguales (H5).

### Nativo → Godot (métodos)

| Método | Cuándo | Datos |
| --- | --- | --- |
| `start_level(json)` | El niño toca un nivel. Si ya hay un nivel abierto, Godot lo cierra primero con `level_exited` | `{"v":1,"level_id":3,"mode":"peque","kiosk":false,"muted":false}`. `mode` es `peque` o `grande`; `kiosk` y `muted` son booleanos |
| `pause_level()` | La app pasa a segundo plano o entra una llamada | — |
| `resume_level()` | La app regresa | — |
| `abort_level()` | El nativo necesita cerrar el nivel (kiosco, tutor) | — |
| `set_muted(bool)` | Cambia el sonido desde el nativo | — |

### Godot → Nativo (señales)

| Señal | Cuándo | Datos |
| --- | --- | --- |
| `engine_ready` | Godot terminó de arrancar y está esperando en la escena vacía. **Una sola vez por sesión** | — |
| `level_started(json)` | El nivel ya cargó y se ve. También al tocar Repetir en la tarjeta de hábito | `{"v":1,"level_id":3}` |
| `level_finished(json)` | El niño llegó a la meta. **El nativo guarda el resultado pero NO cierra la vista**: Godot muestra la tarjeta de hábito | `{"v":1,"level_id":3,"stars":2,"points":40,"infractions":{"stop":1},"duration_s":95}` |
| `level_exited(json)` | El nivel se cerró: Continuar en la tarjeta (`completed: true`), Salir en la pausa, `abort_level` o un `start_level` encima. **Solo aquí el nativo esconde la vista de Godot** | `{"v":1,"level_id":3,"completed":true}`. `completed` dice si antes se mandó `level_finished` |
| `inactivity_timeout` | 60 s sin tocar la pantalla dentro de un nivel (solo kiosco). Una vez, hasta que vuelvan a tocar. El nativo decide (normalmente llama `abort_level`) | — |
| `tutor_requested(json)` | Mantener presionado el engrane 3 s dentro del nivel. El nativo pausa con `pause_level` y abre la pantalla de tutores | `{"v":1,"level_id":3}` |
| `bridge_error(json)` | Algo falló. Códigos: `invalid_json`, `unsupported_version`, `unknown_level`, `invalid_field`, `no_rule_manager` | `{"v":1,"code":"unknown_level","detail":"..."}` |

Reglas del contrato:

- Godot valida el JSON que recibe. Si algo no cuadra, emite `bridge_error` y no se queda colgado.
- El nativo nunca asume que un nivel terminó si no recibió `level_finished` o `level_exited`.
- Cada `start_level` termina con exactamente un `level_exited`. Si el nivel se cierra mientras todavía carga (`abort_level` o otro `start_level` encima), llega `level_exited` **sin** `level_started` antes. El nativo no debe esperar los dos en pareja.
- `infractions` solo trae las reglas con al menos una falta; la que no aparece vale 0. `duration_s` son segundos jugados, sin contar pausas.
- `level_id` 99 es el nivel de prueba del spike (botones Falta, Terminar y Salir, con la tarjeta de hábito real). El 1 abre por ahora la calle de prueba.
- `infractions` usa los mismos `rule_id` del RuleManager: `stop`, `red_light`, `speed`, `crosswalk`, `bike_lane`, `look`, `patience`, `yellow`, `phone`, `lights`, `distance`, `ambulance`, `crash`.

## 4. Ciclo de vida

1. **Arranque de la app:** el nativo muestra el menú y, en segundo plano, inicia Godot con la vista escondida. Godot carga una escena vacía (`idle.tscn`) y emite `engine_ready`.
2. **Abrir nivel:** el nativo muestra la vista de Godot y llama `start_level`. Godot cambia a la escena del nivel y emite `level_started`. Mientras no llegue `engine_ready`, el botón del nivel muestra un indicador de carga.
3. **Jugar:** todo pasa dentro de Godot (reglas, copiloto, tarjeta de hábito).
4. **Meta:** Godot emite `level_finished` y abre la tarjeta de hábito. El nativo guarda el resultado en ese momento (por si la app se cierra) y deja la vista abierta.
5. **Cerrar:** con Continuar (o Salir, o `abort_level`) Godot emite `level_exited` y vuelve a `idle.tscn` para liberar memoria. El nativo esconde la vista y muestra el menú con las estrellas nuevas. Con Repetir, Godot reinicia el nivel solo y emite `level_started` otra vez.
6. **Segundo plano:** el nativo llama `pause_level` y `resume_level`. Godot también escucha sus notificaciones de pausa de la aplicación, por si acaso.

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

- [ ] Elegir y fijar la versión de Godot compatible con SwiftGodotKit y `godot-lib`. El proyecto usa hoy **Godot 4.7.2**: confirmar que las dos lo soportan o bajar de versión.
- [x] Proyecto Godot mínimo: `scenes/bridge/idle.tscn`, `scenes/bridge/level_test.tscn` (level_id 99), `autoload/bridge_client.gd` y `scenes/bridge/fake_bridge.gd`. Probado con el FakeBridge: errores de JSON, inicio, faltas, meta, tarjeta, Repetir, Continuar, Salir, abort, pausa en segundo plano, kiosco y silencio.
- [ ] iOS: app SwiftUI con un botón "Nivel 1". Muestra `GodotAppView`, manda `start_level` y recibe `level_finished`. Muestra las estrellas en una etiqueta nativa.
- [x] Android: app en Compose con lo mismo, usando `godot-lib` 4.7.2 y un plugin v2 en Kotlin (`native/android/`). Probado en un Samsung Galaxy A15 (SM-A155M, Mali-G57): niveles 1 y 99 completos, tarjeta de hábito, resultado guardado en el nativo.
- [x] Abrir y cerrar el nivel 10 veces seguidas sin cierres ni aumento de memoria. Android (A15): 247 → 253 MB, sube 6 MB en los primeros ciclos y luego se queda estable. Falta en iOS.
- [ ] Medir: tiempo hasta `engine_ready`, tamaño de la app y memoria en un celular de gama baja. Android (A15, build debug): menú nativo visible en 1.9 s, `engine_ready` en 3.7 s, memoria ~250 MB. **Falta**: tamaño en build release (necesita el NDK para quitar símbolos; en debug la librería de Godot pesa ~71 MB por arquitectura) e iOS.

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
- El RuleManager, las piezas de reglas, los niveles y el copiloto no cambian. El RuleManager ahora cuenta las faltas por regla (`infractions`).
- La tarjeta de hábito sí cambia un poco: Repetir y Continuar pasan por `BridgeClient` en vez de cambiar de escena ellos mismos.
- La escena principal de Godot es `idle.tscn`. En el editor, F5 abre el nivel 1 con el FakeBridge (`-- --fake-level=99` para el de prueba) y F6 sobre un nivel lo juega directo.
- El spike va antes de la Fase 1.

## Fuentes

- [LibGodot – Embed Godot Everywhere with Godot 4.6 and Beyond (GodotCon Amsterdam 2026)](https://talks.godotengine.org/godotcon-ams-2026/talk/DQXZZC/)
- [Embedding Godot games in iOS apps is easy now (Christian Selig)](https://christianselig.com/2025/05/godot-ios-interop/)
- Documentación oficial de Godot sobre la librería de Android y los plugins de Android v2: revisar la versión que corresponda a la versión de Godot elegida.
