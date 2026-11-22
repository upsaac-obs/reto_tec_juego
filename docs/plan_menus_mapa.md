# Menús nuevos: "Postal de Puebla" + mapa de ruta (21 al 26 de noviembre de 2026)

Objetivo: que los menús de Android e iOS se vean del mismo juego que los niveles.

- **Inicio, Selección de edad y Tutores:** estilo "postal de Puebla". Fondo con el cielo de la paleta de ADO, botones "caramelo" como los del HUD, el copiloto y la fuente Fredoka.
- **Selección de niveles:** un **mapa de ruta**. Un camino recorre la ciudad vista desde arriba (la misma cámara del juego) y cada nivel es una parada frente a su destino. El auto rojo se para en el nivel que toca y, al ganar uno, maneja hasta la siguiente parada.

## 1. Cómo se ve el mapa

- **Desplazamiento:** el mapa es horizontal y ocupa unas 3 pantallas de ancho. Se arrastra con el dedo y al abrir se centra en el auto.
- **Camino:** sinuoso, de izquierda a derecha. Asfalto con línea punteada y banquetas de cantera, como en el juego.
- **Inicio del camino:** el **Parque** del tutorial (nivel 0). Es solo la salida, no una parada: el nivel 0 se sigue abriendo solo la primera vez que se toca Jugar.
- **Paradas 1 a 8:** cada una con su destino, ya dibujado para el juego:

  | Parada | Nivel | Destino (sprite del juego) |
  |---|---|---|
  | 1 | Primero el peatón | Escuela |
  | 2 | Respeta las señales | Mercado |
  | 3 | Mira dos veces | Casa de la abuela |
  | 4 | Con calma | Hospital |
  | 5 | Sin prisa | Terminal |
  | 6 | Ojos en el camino | Casa de los primos |
  | 7 | Hazte visible | Nuestra casa |
  | 8 | Comparte el camino | Biblioteca |

- **Cada parada** es un medallón redondo sobre el camino, con el número (Fredoka), sus estrellas debajo y un candado si está cerrada. El destino va a un lado del camino. Tocar el medallón **o** el edificio abre el nivel.
- **Relleno:** árboles, casas y objetos de banqueta del juego (`arboles.png`, `casas.png`, `mobiliario.png`). Con eso el mapa casi no necesita arte nuevo.
- **Auto:** `player_car.png`, el mismo del juego.
  - Al regresar de un nivel ganado por primera vez, maneja por el camino hasta la parada siguiente (~1.5 s) y la parada nueva hace un pequeño rebote.
- **Reglas que no cambian:** el 1 siempre está abierto, cada nivel se abre con 1 estrella en el anterior, en kiosco todo está abierto y "Muy pronto" sale si Godot responde `level_not_built`.
- **Accesibilidad:** cada parada es un botón con la etiqueta "Nivel N, nombre, X estrellas" (o "bloqueado").

## 2. Una sola fuente de verdad para las dos apps

Para que Android e iOS dibujen exactamente el mismo mapa sin ajustar coordenadas dos veces:

- **`tools/menu_map.py`** (lo hace Claude) genera:
  - **`map_layout.json`:**
    - el tamaño del mapa en unidades;
    - los puntos del camino (curva suave);
    - la posición de cada parada y de su destino;
    - los adornos (sprite, región, posición, escala).
  - **`map_*.png`:** los sprites que usa el mapa, sacados de `assets/sprites/` del juego, en un solo atlas.

  Los copia a `android/app/src/main/assets/menu_map/` y a `ios/RutaKids/Resources/menu_map/`.
- **Cada app** solo lee el JSON y dibuja:
  - **Android:** Compose, con `Canvas` para el camino e `Image` para los sprites, dentro de un `horizontalScroll`.
  - **iOS:** SwiftUI, con `Path` para el camino e `Image` dentro de un `ScrollView(.horizontal)` con `ScrollViewReader`.
- **Si cambia el mapa** (mover una parada, más árboles), se edita el script y se regenera. No se toca el código de las apps.

## 3. Arte nuevo (lote 10 de Codex)

El mapa reutiliza el arte del juego. A Codex solo se le pide lo de los menús (`docs/arte_v2/codex/lotes/10_menus.md`), en este orden:

| Prioridad | Ficha | Para qué |
|---|---|---|
| 1 | 10-C botones | Jugar, Regresar, Salir, sonido sí/no, Tutores |
| 2 | 10-E estrellas y candado | Paradas del mapa y barra de estrellas |
| 3 | 10-A fondo de Inicio | Pantalla de Inicio |
| 4 | 10-F copiloto de menú | Saluda en Inicio y celebra en el mapa |
| 5 | 10-G tarjetas de edad | Selección de edad |
| 6 | 10-B fondo de menús | Tutores |
| — | 10-D íconos de nivel | **Ya no hace falta:** las paradas usan los destinos. Queda opcional |
| — | 10-H ícono de la app | Opcional |

**Si Codex se atrasa**, el mapa funciona igual: no usa nada de Codex. Los botones pueden salir provisionalmente de `hud_iconos.png`.

## 4. Fases

| # | Tarea | Hace | Revisa / prueba | Entrega |
|---|---|---|---|---|
| 1 | Generar el lote 10 en Codex (fichas 10-C, 10-E, 10-A, 10-F, 10-G, 10-B) | Dylan Mancilla | Claude (integra) | 22/11/26 |
| 2 | `tools/menu_map.py`: diseño del camino, paradas, adornos, atlas y JSON para las dos apps | Claude Code | Dylan Mancilla (aprueba el mapa en una captura) | 22/11/26 |
| 3 | Android: pantalla del mapa (dibujo, scroll, centrar en el auto, paradas, candados, accesibilidad) | Claude Code | Paulo Vélez (A15) | 23/11/26 |
| 4 | Android: animación del auto al ganar un nivel y rebote de la parada nueva | Claude Code | Paulo Vélez | 24/11/26 |
| 5 | Android: Inicio, Edad y Tutores con el lote 10 y Fredoka; integrar los assets en `drawable-nodpi` | Paulo Vélez (con Claude) | Dylan Mancilla | 24/11/26 |
| 6 | iOS: la misma pantalla del mapa en SwiftUI, leyendo el mismo JSON | Claude Code (escribe) | **Diego Sánchez (compila y prueba en Mac/iPhone)** | 24/11/26 |
| 7 | iOS: Inicio, Edad y Tutores con el lote 10 y Fredoka; integrar los assets en `Assets.xcassets` | Diego Sánchez (con Claude) | Dylan Mancilla | 25/11/26 |
| 8 | Sonidos de menú: toque de botón, parada abierta, auto avanzando (de los efectos que ya hay) | Ángel Mael | Dylan Mancilla | 24/11/26 |
| 9 | Pruebas en los dos celulares: progreso, desbloqueo, kiosco, regreso del nivel, accesibilidad (TalkBack/VoiceOver) y fluidez del scroll | Ángel Mael y Paulo Vélez | Dylan Mancilla | 26/11/26 |

## 5. Riesgos

- **iOS se compila solo en una Mac:** Claude escribe el código, pero no lo puede compilar ni probar. Diego tiene que compilarlo el mismo día para corregir rápido. Por eso iOS va un día después que Android, copiando la versión de Android ya probada.
- **Tiempo:** son 5 días. Si no alcanza, el orden de recorte es:
  1. la animación del auto (fase 4; el auto aparece ya en su parada);
  2. el rebote;
  3. la pantalla de Tutores (se queda como está, solo con la fuente nueva).

  El mapa y la pantalla de Inicio no se recortan.
- **Rendimiento en el A15:** el mapa son ~100 sprites chicos de un solo atlas y un camino. Se dibuja una vez y el scroll solo lo mueve. Si se traba, se baja la cantidad de adornos en el script.
- **Fuente:** Fredoka (OFL) va en `res/font/` (Android) y en el `Info.plist` de iOS (`UIAppFonts`), con su licencia.
