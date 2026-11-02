# Plan visual de RutaKids

2 nov 2026. Lo armó el creative-director a partir de los reportes del art-director, el world-builder y el technical-artist, con las capturas de los 9 niveles.

Este plan **no cambia ninguna regla del juego**. Todo lo que propone es decoración, iluminación o reacciones visuales.

## 1. Visión visual

1. **Una Puebla de juguete, vista desde arriba.** Calles con casas pegadas, azoteas con tinaco y tendedero, banqueta de cantera, toques de talavera y jacarandas. Hoy el juego parece un suburbio con pasto; tiene que parecer *nuestra colonia*.
2. **La calle manda y el decorado se queda callado.** El suelo va con poca saturación, la ciudad con saturación media y los actores y señales de regla con mucha. Ningún adorno puede parecerse a una pieza de regla: nada de cebras, semáforos, señales ni peatones de adorno junto a la orilla. Si un niño frena por un adorno, el adorno está mal.
3. **Cada nivel lleva a un lugar que se ve.** El destino aparece al final del recorrido, con su puerta dorada `#FFC700`. Llegar tiene que sentirse como llegar.
4. **Amable siempre.** Nada da miedo, nadie corre y una falta nunca castiga con la imagen. Los aciertos sí brillan.
5. **Barato para el A15.** Sprites a 1:1, filtro Nearest y un solo atlas de ciudad, sin Light2D ni shaders. Lo que se repite va en el TileMapLayer.

## 2. Decisiones

| Tema | Decisión | Por qué |
|---|---|---|
| Cómo decorar | **`CityDresser` en runtime.** Es un nodo en `level.tscn`, `@tool` para verlo en el editor, con semilla fija por nivel y `@export enabled`. Los ajustes de cada nivel van en `data/themes/theme_0X.tres` (`LevelTheme`). Capas: Backfill, Lots, Sidewalk, Destination y Canopy. | Los niveles 0–4 están hechos a mano y no tienen script. Reescribir sus `.tscn` pone en riesgo las reglas y las pruebas. En runtime se puede apagar y cambia los 9 niveles de una vez. |
| Banqueta | **Cantera `#C9BDB4`**, con juntas `#968A85` y guarnición de 8 px. El lila `#B8A6CC` queda solo como acento (jacarandas y el parque del N0). | El lila compite en saturación con los actores. |
| Detrás de las casas | **Azoteas** en N1–N6 y N8: fachadas contiguas pegadas a la banqueta y una segunda fila con `casas.png` y `edificios.png`. **Pasto** solo en el N0 (parque), el N7 (cerro, con magueyes) y el camellón del N8, desaturado a `#5E9A5A`. | Es lo que más identidad aporta por hora de trabajo y sale de sprites que ya existen. |
| Tiles de calle | Se hacen con **código** (script PIL que recolorea y saca variantes de `street_provisional.png`). | Quedan alineados a 64 px y en la paleta exacta. |
| Paleta extra | Asfalto `#6B6178`/`#3A3344`, cantera `#C9BDB4`, juntas `#968A85`, ladrillo `#B5523B`, talavera `#2E4DA0`, ocre `#E3A548`, rosa mexicano `#E0457B` y verde hoja `#7CC56B`. `#7FC8E8` sigue siendo el color de los vidrios. | Paleta acotada y sin la marca de ADO. |
| Destinos | Sprite de 192×192 en los últimos 10–15 tiles, con puerta dorada y un ícono de 48 px encima (sin texto). La escuela, el hospital y la terminal usan su sprite actual. El parque, el mercado, la biblioteca y las 3 casas son arte nuevo. | Es el problema número 1 que encontraron los tres reportes. |
| Hora del día | `time_of_day.gd`, generalizado de `level_07_dusk.gd`. N0–N1 mañana, N2 media mañana, N3 tarde, N4 y N8 mediodía, N5 y N6 tarde dorada, N7 anochecer (como ahora). | Variedad casi gratis. |
| Reacciones visuales | **Sí:** sombra bajo los vehículos, direccionales y frenos que brillan, destellos dorados en cada acierto, fundido de entrada y confeti en la meta (sin retrasar `exit_level`). **No:** viñeta roja, sacudida ni parpadeo en las faltas. | Las faltas ya tienen copiloto y pausa. Las direccionales y frenos visibles sí enseñan. |
| Menú nativo | Se queda la ilustración. Solo **el edificio ADO se cambia por una tiendita poblana genérica** (sin letras y sin la combinación morado y rojo), en Android y en iOS. | El choque de estilos se puede tolerar; la marca no. |
| Bocacalles y cebras decorativas | **No.** | Una cebra sin regla enseña mal. |

**Para el equipo:**
- Que ADO o la Fundación aprueben el menú nuevo y una captura por nivel antes del 11 nov.
- Que Paulo confirme si puede editar el archivo fuente del menú.
- Revisar que los autobuses morados de `terminal.png` no parezcan la librea de ADO.

## 3. Fases

D1 = lun 2 nov … D13 = sáb 14 nov. Entrega: 15 nov.

### Fase 0 (D1–D2): solo código y sprites que ya existen, lo hace Claude

| Entregable | Quién | h | Terminado cuando |
|---|---|---|---|
| `scenes/debug/perf_overlay.tscn`: fps, fps mínimo en 10 s, draw calls y memoria, también a logcat | Claude | 2 | Se activa con un flag y no aparece en release |
| Línea base en el A15: niveles 7 y 8, 3 min cada uno | Paulo | 1 | Números anotados aquí |
| `tools/art/recolor_tiles.py` (detalle abajo) | Claude | 4 | Atlas ≤512², alineado a 64, en paleta exacta |
| `CityDresser` v1 y `LevelTheme` ×9 (detalle abajo) | Claude | 8 | Ningún nivel muestra casas sueltas sobre pasto y las pruebas pasan |
| `tests/test_decor.gd` (detalle abajo) | Claude | 2 | `tests/run_tests.sh` en verde |
| Destino visible en los 9 niveles (provisional donde falta arte) | Claude | 2 | Se ve el destino en todos |
| `drop_shadow.gd` y `car_lights_fx.gd` (brillo aditivo de 16 px, como nodos hijos) | Claude | 4 | Direccionales y frenos se ven a 1 m del teléfono |
| `time_of_day.gd` | Claude | 2 | El N7 se ve igual que hoy y los demás tienen su tinte |

Detalle de las tareas de esta fase:

- **`recolor_tiles.py` genera:**
  - banqueta de cantera;
  - pasto desaturado, en 4 variantes;
  - asfalto con parche, coladera y grieta;
  - ciclovía `#2B6B3F` con borde blanco;
  - 4 azoteas.
- **`CityDresser` v1:**
  - Quita las casas de tiles. Con eso se arregla el sprite encimado del N1.
  - Arma fachadas contiguas con `casas.png` y `edificios.png`, usando `flip_h` y sin repetir la misma dos veces seguidas.
  - Pone una segunda fila, azoteas y árboles.
  - Deja libre un radio de calma de 192 px alrededor de cada pieza de Rules.
- **`test_decor.gd` comprueba que:**
  - el decorado no tenga colisiones ni grupos;
  - nada quede sobre los carriles;
  - nada quede dentro del radio de calma;
  - el destino quede a 4 tiles o menos de la meta.

### Fase 1 (D2–D5): arte de destinos y menú

| Entregable | Quién | h | Terminado cuando |
|---|---|---|---|
| **Pieza piloto: el parque.** Gemini, luego `pixelate_image`, luego cuantizado a la paleta con contorno | Ángel genera, Claude procesa | 3 | El equipo la aprueba como referencia de estilo. Nadie sigue sin ese visto bueno |
| Mercado, biblioteca y hoja de 3 casas destino | Ángel + Claude | 5 | Pasan la lista de estilo |
| Hoja de 6 íconos de destino de 48 px | Ángel + Claude | 2 | Se entienden sin texto |
| Menú sin ADO, Android e iOS | Paulo. Respaldo el D4: Claude recolorea y borra el letrero con PIL | 3 | Sin letras ni librea de ADO, mismos tamaños |
| Integración en `city_atlas.png` (≤2048²) | Claude | 3 | Un solo atlas; ≤100 draw calls |
| Build Android (Paulo) y build iOS (Diego) | Paulo, Diego | 3 | fps mínimo ≥55 en los niveles 7 y 8 |

### Fase 2 (D5–D8): identidad por nivel

| Entregable | Quién | h | Terminado cuando |
|---|---|---|---|
| Hoja de 8 props de banqueta, uno cada 2–4 tiles | Ángel + Claude | 5 | Ningún prop a menos de 192 px de una regla |
| 6 fachadas poblanas | Ángel + Claude | 4 | No hay dos iguales seguidas |
| Firmas por nivel (tabla abajo) | Claude + arte | 6 | Cada nivel se reconoce en la captura sin leer el HUD |
| N7: ventanas y faroles con halo aditivo (≤20), en un CanvasLayer aparte del CanvasModulate | Claude | 3 | Validado en el A15 |
| Destellos al acertar, fundido de entrada y confeti en la meta | Claude | 4 | `exit_level` no se retrasa y las pruebas pasan |

| Nivel | Firma |
|---|---|
| N0 | Jacarandas y jardines |
| N1 | Reja de la escuela |
| N2 | Papel picado solo sobre las banquetas |
| N3 | Cúpula y bardas con bugambilia antes de cada BlindCrossing |
| N4 | Ambulancia estacionada, sin sirena |
| N5 | Sitio de taxis y cancha |
| N6 | Cajones pintados |
| N7 | Cerro con magueyes |
| N8 | Camellón con jacarandas y `bus_stop.png` |

### Fase 3 (D9–D13): congelar, aprobar y probar

| Entregable | Quién | Terminado cuando |
|---|---|---|
| Mosaico final de capturas de los 9 niveles | Claude | Listo para enviar |
| **El arte se congela el 11 nov** y se manda a ADO | Equipo | Aprobación por escrito |
| Sesión de 10 min en el A15 (calor) y en iPhone; si se puede, prueba con 2–3 niños | Paulo, Diego, Ángel | fps mínimo ≥55 y ningún niño frena por un adorno |
| Solo corrección de errores. Si algo falla, `CityDresser.enabled = false` en ese nivel | Claude | Builds finales |

Horas aproximadas: Claude ~55 h, Ángel ~15 h, Paulo ~8 h y Diego ~4 h.

## 4. Arte nuevo

Pixel Engine tiene 4 créditos y un sprite cuesta 6, así que todo sale de Gemini y pasa por este proceso:

1. Se pegan `casas.png` y `edificios.png` como referencia de estilo.
2. Se genera con fondo liso `#FF00FF`.
3. Se pasa por `pixelate_image` al tamaño final.
4. Un script lo cuantiza a la paleta y le pone contorno de 1 px `#1E0F26`.

Sufijo de todos los prompts:

> pixel art, toy-like top-down 3/4 view (roof plus thin front facade), 1px dark purple outline, 2-tone flat shading, light from top-left, no text, no letters, no logos, flat magenta background

| # | Pieza | Tamaño | Prompt | Prioridad |
|---|---|---|---|---|
| 1 | Parque (piloto) | 192×192 | Mexican neighborhood park seen from above: small kiosk, round fountain, two benches, jacaranda trees with lilac flowers, paths of warm beige stone | P0 |
| 2 | Mercado | 192×192 | Mexican municipal market hall, sawtooth roof, pink/yellow/orange awnings, fruit crates at entrance | P0 |
| 3 | Biblioteca | 192×192 | Small public library, cantera stone facade, open book mosaic on plaza, benches, trees | P0 |
| 4 | 3 casas destino | 192×192 c/u | Grandma's colonial house with patio and lemon tree / two-story cousins' house with rooftop terrace / orange family house with lit porch | P0 |
| 5 | Íconos de destino (6) | 48×48 c/u | Simple round badges: tree, fruit, book, heart-house, school bell, green cross | P0 |
| 6 | Props de banqueta (8) | 64×64 c/u | Street lamp, trash bin, bench, planter, tamales tricycle, ice-cream cart, bike rack, tree pit | P1 |
| 7 | Fachadas poblanas (6) | 128×128 c/u | Row houses: brick+talavera tiles, ochre+balcony, pink+zaguán door, indigo, white+ironwork, green+corner shop | P1 |
| 8 | Jacaranda | 96×96 | Jacaranda tree canopy from above, lilac flowers, soft shadow | P1 |
| 9 | Cúpula de azulejo (N3) | 128×128 | Tiled church dome seen from above, yellow and blue talavera, small lantern | P2 |
| 10 | Cerro, maguey y nopal (N7) | 64×64 ×3 | Agave, prickly pear cactus, rocky hill edge tile, dusk-friendly colors | P2 |
| 11 | Bugambilia sobre barda | 128×64 | Adobe wall top with magenta bougainvillea spilling over | P2 |
| 12 | Tiendita del menú | en la ilustración | **Paulo**, en el estilo del menú: generic corner shop, ochre walls, striped awning, no sign text | P0 |

**Con código, no con Gemini:**
- todos los tiles (calle, banqueta, azoteas, ciclovía y camellón);
- papel picado y cajones pintados;
- halos y ventanas encendidas;
- sombras del decorado, horneadas en el atlas;
- destellos.

## 5. Lo que no se hará

- **Pixel Engine,** incluidas las palomas animadas: no hay créditos.
- **Reescribir los `.tscn` de los niveles 0–4:** pone en riesgo las reglas y las pruebas.
- **Bocacalles, esquinas y cebras decorativas:** enseñan una regla que no existe.
- **Peatones de adorno caminando en la banqueta:** se confunden con los peatones de regla. Solo se permiten figuras quietas dentro de las plazas de destino.
- **Repintar o pixelar todo el menú:** son 8–12 h y no resuelven nada esencial. Solo se cambia el edificio ADO.
- **Castigos visuales en las faltas** (viñeta roja, sacudida o parpadeo).
- **Tocar `player_car.gd`, `hud.*` o `feedback.gd`:** todo va como nodos hijos que leen el estado público.
- **Light2D, shaders, parallax, partículas densas o fondos de una sola imagen.**
- **Regenerar personajes y autos.**

## 6. Riesgos

| Riesgo | Mitigación |
|---|---|
| Rendimiento en el A15 | Medir el D1 antes de tocar nada. Límites: ≤200 Sprite2D por nivel, ≤100 draw calls, ≤20 aditivos, ≤150 partículas y 1 atlas de ciudad. Sombras del decorado horneadas en el atlas. `VisibleOnScreenEnabler2D` en lo animado. `fx_quality` 0/1. Si el fps mínimo baja de 55, se reduce la densidad del `LevelTheme`. |
| Que el decorado confunda o tape una regla | Radio de calma de 192 px y `test_decor.gd`. Prueba con niños: si alguno frena por un adorno, se quita. |
| Que `CityDresser` rompa un nivel | `enabled` por nivel, semilla fija, mosaico de capturas antes y después, ramas `feature/` por fase. |
| Que Gemini dé estilos inconsistentes | Pieza piloto aprobada antes de seguir, mismas referencias y sufijo, cuantizado obligatorio con el script. Si una pieza no sale en 2 intentos, se usa el respaldo con sprites existentes. |
| Que ADO no apruebe a tiempo | Enviar el 11 nov. El respaldo del menú queda listo el D4. |
| Poco tiempo del equipo | La fase 0 la hace Claude. Si la fase 2 se atrasa, se recorta en este orden: firmas, fachadas y props. Los destinos y la ciudad contigua no se recortan. |
