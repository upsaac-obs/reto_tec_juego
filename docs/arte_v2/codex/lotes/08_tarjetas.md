# Lote 08: tarjetas de hábito (P1)

Al terminar cada nivel aparece una **tarjeta**: una ilustración que resume el hábito
aprendido, con un texto corto abajo. El texto y el marco los pone el juego.

**Esta es la única excepción de cámara** (ver `estilo.md` §2): son "postales", una
escena de calle poblana en 3/4 a la altura de la banqueta, no la vista desde arriba
del juego.

**Reglas del lote:**

| Regla | Valor |
|---|---|
| Lienzo | 1536 × 1024. El juego recorta a 5:3 (720 × 432), así que deja **un margen sin nada importante de ~60 px arriba y abajo** |
| Clase de contorno | **L** |
| Referencias obligatorias | `copiloto_maestra.png`, `auto_jugador.png`, `casas_a.png` y, si salen personas, `nino_camina.png` |
| Auto del jugador | Siempre el **auto rojo del piloto**, visto en 3/4 |
| Copiloto | Siempre en una esquina inferior, pequeño (~20 % de la altura), con el pulgar arriba o sonriendo |
| Ambiente | Calles de Puebla de colores, cantera, balcones de herrería y talavera. El volcán se permite al fondo |
| Prohibido | **Sin texto, letreros, marcos ni bordes dentro de la imagen.** Tampoco iglesias en primer plano |

**Entregas:** `tarjeta_00.png` … `tarjeta_08.png`. Reemplazan
`assets/ui/habit_cards/card_00.png` … `card_08.png`. Prioridad: haz primero la 0, la 1,
la 2 y la 3.

## Escenas

Cada prompt es: STYLE BASE + OUTLINE L + este texto, cambiando `{ESCENA}`:

```
SUBJECT: a cheerful postcard illustration for a kids' road-safety game, 3/4 view
of a colorful street in Puebla, Mexico, at sidewalk height. {ESCENA}
The attached axolotl co-pilot appears small in a bottom corner giving a thumbs up.
Keep the top and bottom 60 px free of important elements. No text, no signs with
letters, no frame, no border.
```

| Tarjeta | Nivel (hábito) | `{ESCENA}` |
|---|---|---|
| 00 | Abróchate y arranca | `Close-up inside the red car: a smiling child in the driver seat clicks the seatbelt buckle, a little sparkle at the buckle.` |
| 01 | Primero el peatón | `The red car waits patiently before a white zebra crossing while a group of happy schoolchildren with backpacks crosses the street.` |
| 02 | Respeta las señales | `The red car is stopped at a white stop line next to a red octagonal stop sign with a blank face (no letters) and a traffic light showing red.` |
| 03 | Mira dos veces | `The red car peeks carefully out of a narrow street corner between colorful houses; two big friendly cartoon eyes float above it looking left and right.` |
| 04 | Con calma | `The red car waits at a crosswalk while a grandmother with a cane and a boy in a red wheelchair cross calmly and wave.` |
| 05 | Sin prisa | `The red car has stopped calmly while a bouncing ball rolls across the street and a child waits on the sidewalk for an adult to pick it up.` |
| 06 | Ojos en el camino | `View from the back seat inside the red car: the driver's hands on the wheel, eyes on the road ahead, and a phone resting face-down in the cup holder with a small "silent" moon icon.` |
| 07 | Hazte visible | `Dusk with light rain on a colorful street: the red car drives with its headlights on (warm light beams) and a cyclist ahead wears a bright reflective vest.` |
| 08 | Comparte el camino | `A wide avenue with a green bike lane: the red car keeps a big safe distance behind a cyclist, and a turquoise city bus waits at its stop.` |

**Se acepta si:**
- se entiende el hábito sin leer;
- el auto del jugador es el rojo del piloto;
- el copiloto es el de la ficha maestra;
- no hay letras en ningún letrero;
- nadie se ve en peligro.
