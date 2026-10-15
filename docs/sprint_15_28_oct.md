# RutaKids — plan del sprint (15 al 28 de octubre de 2026)

Equipo: **Dylan Isaac**, **Diego Sánchez**, **Paulo Vélez** y **Ángel Mael**.

Fechas que manda el calendario (`PLAN.md`):

| Fecha | Qué pasa |
| --- | --- |
| 22 oct | Termina la Fase 2 (contenido): niveles 3 a 8 y menús |
| 20 al 25 oct | Fase 3 (pruebas) |
| **25 oct** | **Hito 4: pruebas listas** |
| 26 oct al 8 nov | Fase 4 (cierre): niveles 9 y 10, arte final, iOS en iPad |
| 15 nov | Entrega final |

## 1. Cómo está el juego hoy (15 oct)

- **Godot (niveles):** los niveles **0, 1 y 2** se juegan completos y dan estrellas, en los modos **Peque** y **Grande**. El nivel **3** tiene sus 3 cruces sin vista, pero todavía no tiene final ni destino. Los niveles 4 a 8 no se han empezado, aunque casi todo su arte ya está importado.
- **Puente `RutaBridge`:** el lado de Godot está terminado y tiene pruebas automáticas (`autoload/bridge_client.gd`, `scenes/bridge/`).
- **Android:** el spike funciona en el Galaxy A15 (`native/android/`). El menú actual es de prueba: solo trae botones para abrir niveles y medir.
- **iOS:** el kit del spike está escrito (`native/ios/`), pero **nunca se ha compilado** en una Mac.
- **Pruebas automáticas:** 148 pasan (`tests/run_tests.sh`).
- **Pendiente con Fundación ADO:** confirmar que Godot incrustado dentro de una app nativa cuenta como "nativo".

## 2. Reparto

| Persona | Se encarga de |
| --- | --- |
| **Diego Sánchez** | Menú nativo de **iOS** (SwiftUI) y probar el juego en iPhone y iPad |
| **Paulo Vélez** | Menú nativo de **Android** (Compose): inicio, edad, niveles y guardado. Pruebas de los niveles 0 y 1 |
| **Ángel Mael** | Menú nativo de **Android** (Compose): tutores, kiosco y build *release*. Pruebas de los niveles 2 y 3, y regresión |
| **Dylan Isaac** | Juego en Godot: final del nivel 3, niveles 4 a 8, sus piezas de reglas, audio e importación de arte. Integra todo y exporta `main.pck` |

**Ramas:** cada quien trabaja en su propia rama `feature/<nombre>`, que sale de `feature/modo-peque`, y sube su trabajo a GitHub (`upsaac-obs/reto_tec_juego`). Dylan junta las ramas cuando el equipo las prueba.

---

## 3. Lo que tienen que hacer los dos menús nativos (iOS y Android)

Las dos apps hacen **lo mismo**. Ninguna es "la principal": si una pantalla cambia en una plataforma, cambia también en la otra. El contrato del puente está en `docs/arquitectura.md` (secciones 3 y 4) y no se cambia sin avisar.

### 3.1 Pantallas

| Pantalla | Qué hace | Criterio de terminado |
| --- | --- | --- |
| **Inicio** | Fondo del menú, botón grande **Jugar**, engrane de tutores y botón de sonido | Se ve en menos de 3 s desde que se toca el ícono (HU-01). Godot arranca **escondido** en segundo plano mientras tanto |
| **Selección de edad** | Solo la primera vez: dos dibujos grandes, **Peque** (4 a 7) y **Grande** (8 a 13), con un solo toque | Se guarda el modo y no vuelve a salir. El modo se cambia después desde Tutores |
| **Selección de niveles** | 11 tarjetas (0 a 10) con ícono (`assets/ui/level_icons.png`), nombre y estrellas | Un nivel se abre con **1 estrella en el anterior**. El 0 siempre está abierto. Los que no están construidos se ven bloqueados (Godot responde `level_not_built`) |
| **Nivel** | Muestra la vista de Godot y manda `start_level` con `level_id`, `mode`, `kiosk` y `muted` | Mientras no llegue `engine_ready`, el botón del nivel muestra "cargando". **Con `level_finished` se guarda el resultado, pero la vista NO se cierra.** Se cierra solo con `level_exited` |
| **Tutores** | Se abre **manteniendo presionado el engrane 3 s** (en el menú, o dentro del nivel cuando llega `tutor_requested`) | Muestra las estrellas por hábito y deja cambiar el modo, borrar el progreso (con confirmación) y activar o desactivar el kiosco |
| **Kiosco** | Todos los niveles abiertos, no se guarda nada y no aparece Salir | Tras **60 s sin tocar** en los menús, la app vuelve a Inicio. Dentro del nivel Godot avisa `inactivity_timeout` y la app manda `abort_level` (H11) |

### 3.2 Guardado (REQ-6: nada personal)

Se guarda solamente esto:

| Dato | Tipo | Ejemplo |
| --- | --- | --- |
| `mode` | texto | `"peque"` o `"grande"` |
| `muted` | sí/no | `false` |
| `kiosk` | sí/no | `false` |
| `level_<id>_stars` | entero 0–3 | Se guarda la **mejor** calificación, nunca una más baja |
| `level_<id>_points` | entero | Los mejores puntos |
| `level_<id>_infractions` | JSON | `{"stop":1}` (para la pantalla de tutores) |

- **iOS:** `UserDefaults`.
- **Android:** `DataStore` (Preferences).
- **En kiosco no se escribe nada.**
- **Sin internet:** sin el permiso `INTERNET`, sin analíticas y sin SDKs de terceros (REQ-5).

### 3.3 Ciclo de vida

| Cuándo | Qué manda la app |
| --- | --- |
| La app pasa a segundo plano | `pause_level` |
| La app regresa | `resume_level` |
| Se toca el botón de sonido | `set_muted` |

Godot se inicia **una sola vez** y nunca se destruye: entre un nivel y otro solo se esconde su vista (H1).

### 3.4 Arte y textos

- **Arte del menú:** los prompts ya están en `docs/prompts_assets.md` (#19 fondo del menú, #20 selección de edad, #21 ícono de la app). **No se usa el logo de ADO.** Los colores son los de la paleta de `CLAUDE.md`.
- **Textos:** salen de `i18n/textos.csv` (H8). Dylan entrega un script que genera `Localizable.strings` (iOS) y `strings.xml` (Android) desde ese archivo. No se escriben textos sueltos en el código.

---

## 4. Diego Sánchez — menú nativo de iOS

Trabaja en la rama `feature/menu-ios`, con Xcode, una Mac y un iPhone o iPad **real**. Godot no corre en el simulador (H3). Las instrucciones para preparar la Mac y para el agente de Claude Code están en `native/ios/README.md` y `native/ios/CLAUDE.md`.

1. **Compilar el spike** (15 al 17 oct): exportar `main.pck`, generar el proyecto con `xcodegen` y hacer que compile.
   - Que llegue `engine_ready` y que el nivel 99 dé `level_started` → `level_finished` → `level_exited`.
   - Anotar en `docs/arquitectura.md`, sección 6: tiempo hasta ver el menú, tiempo hasta `engine_ready`, memoria en 10 ciclos y tamaño de la app.
   - **Si el 17 no compila, avisar ese mismo día con el error.** Es el mayor riesgo del sprint.
2. **Inicio y selección de edad** (18 al 20 oct), en SwiftUI.
3. **Selección de niveles y guardado** (20 al 22 oct): las estrellas y el desbloqueo, con `UserDefaults`.
4. **Tutores y kiosco** (23 al 25 oct): el engrane de 3 s, `tutor_requested`, `inactivity_timeout` y el contador de 60 s en los menús. En iPad, documentar el **Acceso Guiado** para el personal de ADO.
5. **Segundo plano y sonido** (23 al 25 oct): `pause_level`, `resume_level` y `set_muted`.
6. **Pruebas en iOS** (26 al 28 oct):
   - Jugar los niveles 0 a 3 en Peque y Grande en iPhone y en iPad.
   - Comparar con Android que el puente se comporte igual (paridad, H5).
   - Reportar cada problema como *issue* (ver sección 7).

**Pruebas del plan IEEE 829 que le tocan:** usabilidad con niños (UAT-UI-002, del 23 al 25 oct), tráfico de red en iOS (UAT-PRIV-002, con Charles Proxy) y kiosco (UAT-KIOSCO-001 a 003).

## 5. Paulo Vélez — menú nativo de Android (inicio, edad, niveles y guardado)

Trabaja en la rama `feature/menu-android-niveles`, partiendo de `native/android/` (Compose, `GodotFragment`, `RutaBridgePlugin.kt`). Para copiar el juego al proyecto: `native/android/sync_godot.sh`.

1. **Inicio y selección de edad** (15 al 18 oct): convertir el menú de prueba de `MainActivity.kt` en pantallas de Compose con navegación. Godot sigue arrancando escondido.
2. **Guardado con DataStore** (18 al 20 oct): los datos de la sección 3.2, guardados al recibir `level_finished` y conservando siempre la mejor calificación.
3. **Selección de niveles** (19 al 22 oct): tarjetas con estrellas, desbloqueo con 1 estrella y niveles no construidos bloqueados.
4. **Pruebas de los niveles 0 y 1** (20 al 25 oct), en Peque y Grande, en el Galaxy A15:
   - **Funcionales de caja negra:** que las faltas y los puntos salgan donde deben y que las estrellas den 0 / 1–2 / 3+ faltas → 3 / 2 / 1. Probar el límite de velocidad con 1.9 s (sin falta) y 2.1 s (con falta). Casos UAT-FEED-001 y UAT-JUEGO.
   - **Coordinar la evaluación heurística (prueba alfa)** de los 4, del 16 al 18 oct.
   - **Almacenamiento (UAT-PRIV-003):** revisar que solo se guarde lo de la sección 3.2.
   - **Tamaño de la app (UAT-INST-002).**

## 6. Ángel Mael — menú nativo de Android (tutores, kiosco y build) y regresión

Trabaja en la rama `feature/menu-android-tutores`. Coordina con Paulo, porque los dos tocan `native/android/`: Paulo hace la navegación base y Ángel agrega sus pantallas encima.

1. **Pantalla de tutores** (18 al 21 oct): el engrane de 3 s, las estrellas por hábito, cambiar el modo, borrar el progreso con confirmación y activar el kiosco. Abrirla también al recibir `tutor_requested`, pausando el nivel con `pause_level`.
2. **Modo kiosco** (21 al 23 oct): todo abierto, sin guardar y sin Salir. El contador de 60 s en los menús, y `inactivity_timeout` → `abort_level` dentro del nivel. Fijación de pantalla con **lock task** (H12).
3. **Segundo plano y sonido** (21 al 23 oct): `pause_level`, `resume_level` y `set_muted`.
4. **Build *release*** (23 al 24 oct):
   - Firmar con una llave propia del equipo en lugar de la de depuración (sin subir la llave a GitHub).
   - Revisar con `aapt2 dump permissions` que no se pida `INTERNET`.
   - Medir el tamaño de la app.
5. **Pruebas de los niveles 2 y 3** (20 al 25 oct), en Peque y Grande:
   - **Regresión:** correr `tests/run_tests.sh` después de cada cambio que se junte y guardar el log con el commit en `tests/resultados/`.
   - **Estabilidad (UAT-PERF-002):** 50 sesiones sin cierres, con logcat.
   - **Tiempo de arranque (UAT-INICIO-002):** 10 aperturas en frío, menos de 3 s.
   - **Matriz de dispositivos (UAT-PERF-003):** la lista de 10 o más dispositivos acordada con ADO.

## 7. Cómo se reportan los problemas (para los tres)

Cada problema es un *issue* en GitHub con la etiqueta `bug` y este formato:

```text
Nivel y modo:   nivel 2, Grande
Dispositivo:    Galaxy A15, Android 14   (o iPhone 12, iOS 18)
Build:          commit 05bcb28
Pasos:          1. ...  2. ...  3. ...
Esperado:       el semáforo en amarillo da falta si acelero
Obtenido:       no dio falta
Severidad:      0 a 4 (escala de la evaluación heurística)
Evidencia:      video o captura (sin caras ni nombres de niños)
```

Dylan corrige los problemas de Godot. Los del menú nativo los corrige quien hizo esa pantalla.

## 8. Dylan Isaac — juego en Godot e integración

Trabaja con Claude Code en `~/claude/godot_game`, en las ramas `feature/<nivel o pieza>`.

1. **Final del nivel 3** (15 al 16 oct): elegir el destino, estacionarse y abrir la puerta solo cuando no viene un ciclista.
2. **Nivel 4, Con calma** (16 al 17 oct): peatones lentos, silla de ruedas, semáforo peatonal y la regla de paciencia.
3. **Nivel 5, Sin prisa** (17 al 18 oct): reloj (solo en Grande), amarillos y la pelota que sale a la calle.
4. **Nivel 6, Ojos en el camino** (19 oct): **PhoneEvent**.
5. **Nivel 7, Hazte visible** (20 oct): **DarkZone**, botón de luces, túnel, lluvia y ciclistas con reflejantes.
6. **Nivel 8, Comparte el camino** (21 al 22 oct): **BusStop**, ciclovía, motos y distancia con el ciclista.
7. **Audio** (20 al 24 oct): efectos `.wav`, música y voces con IA para las claves de `textos.csv`.
8. **Integración** (todo el sprint):
   - El script de textos para iOS y Android (H8).
   - Exportar `main.pck` para Diego, Paulo y Ángel después de cada nivel nuevo.
   - Importar el arte de `docs/prompts_fase3.md`.
   - Juntar a `main` lo que el equipo pruebe.
9. **Pruebas que le tocan:** permisos (UAT-PRIV-001), fps (UAT-PERF-001), teléfonos (UAT-PLAT-001) y cada prueba automática nueva para las reglas y los niveles.
10. **Preguntarle a ADO** si Godot incrustado cuenta como desarrollo nativo y si se puede usar su logo en el menú.

---

## 9. Reporte del sprint (15 al 28 de octubre de 2026)

El avance es al 15 de octubre.

| # | Tarea | Responsable | Avance | Entrega |
| --- | --- | --- | ---: | --- |
| 1 | Compilar el spike de iOS en iPhone o iPad y medir arranque, memoria y tamaño | Diego Sánchez | 20 % | 17/10/26 |
| 2 | iOS: pantallas de Inicio y Selección de edad | Diego Sánchez | 0 % | 20/10/26 |
| 3 | iOS: Selección de niveles con estrellas, desbloqueo y guardado (`UserDefaults`) | Diego Sánchez | 0 % | 22/10/26 |
| 4 | iOS: Tutores, kiosco (60 s, `inactivity_timeout`), segundo plano y sonido | Diego Sánchez | 0 % | 25/10/26 |
| 5 | Pruebas en iOS de los niveles 0 a 3 y paridad del puente con Android | Diego Sánchez | 0 % | 28/10/26 |
| 6 | Pruebas de usabilidad con niños, tráfico de red en iOS y kiosco | Diego Sánchez | 0 % | 25/10/26 |
| 7 | Android: pantallas de Inicio y Selección de edad en Compose | Paulo Vélez | 15 % | 18/10/26 |
| 8 | Android: guardado con DataStore (mejor calificación, sin datos personales) | Paulo Vélez | 0 % | 20/10/26 |
| 9 | Android: Selección de niveles con estrellas y desbloqueo | Paulo Vélez | 0 % | 22/10/26 |
| 10 | Evaluación heurística (prueba alfa) de los 4 | Paulo Vélez | 0 % | 18/10/26 |
| 11 | Pruebas de los niveles 0 y 1 (caja negra, valores límite, almacenamiento y tamaño) | Paulo Vélez | 0 % | 25/10/26 |
| 12 | Android: Pantalla de tutores (engrane 3 s, `tutor_requested`) | Ángel Mael | 0 % | 21/10/26 |
| 13 | Android: Modo kiosco, lock task, segundo plano y sonido | Ángel Mael | 0 % | 23/10/26 |
| 14 | Android: build *release* firmado, sin permiso `INTERNET`, y tamaño | Ángel Mael | 50 % | 24/10/26 |
| 15 | Pruebas de los niveles 2 y 3, regresión, estabilidad (50 sesiones) y arranque | Ángel Mael | 10 % | 25/10/26 |
| 16 | Matriz de compatibilidad Android (10 o más dispositivos) | Ángel Mael | 0 % | 28/10/26 |
| 17 | Nivel 3, Mira dos veces: final con estacionamiento, puerta y ciclista | Dylan Isaac | 85 % | 16/10/26 |
| 18 | Nivel 4, Con calma: peatones lentos, silla de ruedas, semáforo peatonal | Dylan Isaac | 10 % | 17/10/26 |
| 19 | Nivel 5, Sin prisa: reloj, amarillos y pelota | Dylan Isaac | 10 % | 18/10/26 |
| 20 | Nivel 6, Ojos en el camino: PhoneEvent | Dylan Isaac | 10 % | 19/10/26 |
| 21 | Nivel 7, Hazte visible: DarkZone, luces, túnel y lluvia | Dylan Isaac | 10 % | 20/10/26 |
| 22 | Nivel 8, Comparte el camino: BusStop, ciclovía y motos | Dylan Isaac | 10 % | 22/10/26 |
| 23 | Audio: efectos, música y voces con IA | Dylan Isaac | 5 % | 24/10/26 |
| 24 | Script de textos para iOS y Android, exportar `main.pck` y juntar a `main` | Dylan Isaac | 10 % | 22/10/26 |
| 25 | Pruebas de permisos, fps y teléfonos; reporte del hito 4 | Dylan Isaac | 0 % | 25/10/26 |

**Cómo se calculó el avance:**

| Tareas | Por qué tienen ese avance |
| --- | --- |
| 1 | El código del spike de iOS ya está escrito, pero falta compilarlo |
| 7 | El menú de prueba de Android ya navega y abre niveles |
| 14 | El build *release* ya se armó y se midió (78.1 / 150.5 MB), pero falta la llave propia |
| 15 | Las 148 pruebas automáticas ya cubren los niveles 2 y 3 |
| 17 | Los 3 cruces ya funcionan; falta el final |
| 18–22 | El arte ya está importado |
| 23 | Hay un solo efecto de sonido |
| 24 | El puente y `sync_godot.sh` ya existen |

**Riesgos del sprint:**

1. **El spike de iOS no compila.** Si el 17 de octubre no está listo, se decide con el equipo si se sigue (H13).
2. **Paulo y Ángel tocan el mismo proyecto de Android.** Paulo hace la navegación base primero (18 oct) y Ángel agrega encima.
3. **Los niveles 4 a 8 en una semana es apretado.** Si algo se atrasa, se prioriza que los niveles 0 a 4 estén pulidos para el hito 4 y el resto pasa a la Fase 4.
4. **Fundación ADO no ha confirmado lo de "nativo".** Si responde que no, el menú se hace en Godot y Diego, Paulo y Ángel pasan a pruebas.
