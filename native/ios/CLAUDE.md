# Instrucciones para Claude Code en la Mac — spike de iOS

Estás en la Mac del equipo de RutaKids. Tu trabajo es terminar la **mitad de iOS del spike** de la arquitectura híbrida: una app de SwiftUI que incrusta Godot con SwiftGodotKit y habla con él por el puente `RutaBridge`. Responde en español, con tono directo. El equipo es Dylan Isaac, Diego Sánchez, Paulo Vélez y Ángel Mael.

## Contexto que tienes que leer

- `docs/arquitectura.md`: la propuesta, el **contrato del puente** (sección 3), el ciclo de vida (sección 4), los hallazgos H1–H13 y el spike (sección 6).
- `native/ios/README.md`: pasos para personas (preparar la Mac, compilar, qué medir).
- `native/android/`: la mitad de Android, que **ya funciona** en un Galaxy A15. Úsala como referencia de comportamiento (`MainActivity.kt`, `RutaBridgePlugin.kt`).
- `CLAUDE.md` de la raíz: reglas del juego (sin internet, sin datos personales, textos con `tr()`).

## Cómo funciona el puente en iOS

En Android, Godot ve un singleton `RutaBridge` (plugin v2). SwiftGodotKit no hace eso: la app **busca un nodo** en el árbol de Godot y le habla directo, como su ejemplo `Samples/AxolotlDemo`. Por eso del lado de Godot existe `scenes/bridge/host_bridge.gd`:

- `BridgeClient` (autoload) crea el nodo `/root/BridgeClient/HostBridge` cuando `OS.has_feature("ios")` es verdadero (o con el argumento `--host-bridge`).
- **Nativo → Godot:** la app llama `HostBridge.receive_packet("comando|json")`. Comandos: `connect`, `start_level`, `pause_level`, `resume_level`, `abort_level`, `set_muted` (json `"true"`/`"false"`).
- **Godot → nativo:** la app escucha la señal `HostBridge.message(packet)`, con `packet = "evento|json"`.
- Godot manda `engine_ready` antes de que la app se conecte; HostBridge lo guarda y lo entrega cuando la app manda `connect|`.
- Todo viaja en **un solo String** a propósito: así no dependemos de cómo SwiftGodot pasa varios argumentos.

El código Swift está en `native/ios/RutaKidsSpike/` (`RutaKidsSpikeApp.swift`, `RutaBridge.swift`, `MenuView.swift`) y el proyecto se genera con `xcodegen generate` desde `project.yml`. **Ese código se escribió en Linux sin poder compilarlo.** Es tu primer trabajo hacerlo compilar.

## Riesgos conocidos (revisa estos primero si no compila o no conecta)

1. **API de SwiftGodot:** se usaron `Callable { (packet: String) in ... }`, `node.connect(signal:callable:)`, `node.call(method: "receive_packet", Variant(packet))`, `handle.getRoot()?.findChild(pattern:recursive:owned:)` y `app.runOnGodotThread`. Están tomados del ejemplo AxolotlDemo de la rama `swiftgodotkit-4.7`, salvo `Variant(packet)` (crear un Variant desde un String) y el closure con parámetro `String`. Si el compilador se queja, revisa `Samples/AxolotlDemo/App/AxolotlDemoApp.swift` y el código fuente de SwiftGodot en el paquete descargado, y ajusta **solo el lado Swift**.
2. **Versión de Godot:** el proyecto y Android usan **4.7.2**; SwiftGodotKit trae **4.7.3-rc** (`v4.7.3-rc-swiftgodotkit.1`). Un `main.pck` exportado con 4.7.2 debería cargar en 4.7.3 (misma versión menor), pero confírmalo y anota cualquier aviso de versión en la consola. Si no carga, prueba exportar el pck con el editor de Godot que use SwiftGodotKit y anótalo como hallazgo (H9).
3. **Driver de pantalla:** el README de SwiftGodotKit dice que algunas compilaciones de `libgodot` solo traen los drivers `macos` y `headless` y que el render incrustado necesita uno que registre el driver embebido. Si la vista sale negra en iPhone, revisa ese punto en la documentación del paquete.
4. **`OS.has_feature("ios")`:** si `BridgeClient` no crea `HostBridge` (la app dice "No se encontró HostBridge"), revisa qué etiquetas de plataforma reporta Godot dentro de SwiftGodotKit. Como arreglo temporal se puede pasar el argumento de usuario `--host-bridge`, si `GodotApp` permite argumentos; si tienes que tocar `autoload/bridge_client.gd`, hazlo mínimo y explícalo.
5. **Simulador vs. dispositivo:** compilar y probar el flujo en el simulador está bien, pero las mediciones solo cuentan en un iPhone o iPad real (H3).

## Qué tienes que entregar

1. La app compila y corre en un iPhone o iPad **real**.
2. Llega `engine_ready` y el menú muestra "Godot listo en … ms".
3. Nivel 99 completo: `level_started` → `level_finished` (con `stars`, `points`, `infractions`, `duration_s`) → tarjeta de hábito → Continuar → `level_exited` con `completed: true`; el menú muestra las estrellas guardadas.
4. Niveles 0, 1 y 2 se ven y se juegan.
5. Segundo plano: con un nivel abierto, salir y regresar pausa y reanuda.
6. Botón "Abrir y cerrar 10 veces": anota la lista de memoria y que no haya cierres.
7. Mediciones: tiempo hasta ver el menú, tiempo hasta `engine_ready`, memoria, tamaño de la app (Ajustes → Almacenamiento) y modelo/versión de iOS del dispositivo.
8. Anota los resultados en `docs/arquitectura.md`, sección 6 (marca las casillas de iOS y escribe los números junto a los de Android), y cualquier hallazgo nuevo en la tabla de la sección 5.

## Reglas

- Trabaja en la rama `feature/spike-ios`. Haz commits pequeños con mensajes en español y termina cada mensaje con la línea de coautoría que te indique tu configuración.
- **No cambies el contrato del puente** sin actualizar `docs/arquitectura.md` y avisar: Android ya lo implementa igual.
- No agregues dependencias con internet, analíticas ni SDKs de terceros (REQ-5, REQ-6).
- No hagas `git push` ni instales programas sin preguntar primero a la persona.
- No inventes números: solo anota lo que mediste en el dispositivo.
- El límite del spike son 2 días de trabajo (H13). Si algo te bloquea más de medio día, detente y explica el bloqueo con evidencia (mensajes de error, versión de Xcode, de iOS y del paquete).

## Pruebas del lado de Godot

Si tocas algo en Godot, corre `tests/run_tests.sh` (necesita `godot` 4.7.2 en el PATH o `GODOT=/Applications/Godot.app/Contents/MacOS/Godot`). Todas deben pasar. `tests/test_host_bridge.gd` prueba el lado de Godot de este puente.
