# Lote 04: vehículos (P0)

**Reglas comunes de este lote:**
- **Vista cenital pura**: se ve el techo. **El frente apunta a la DERECHA.**
- **Referencia obligatoria:** `auto_jugador.png`. Todos los vehículos deben verse del
  mismo juguete que el auto del jugador: silueta redonda, vidrios con brillo y llantas
  que se asoman.
- **Nada es rojo ni lleva raya dorada.** Eso identifica al auto del jugador.
- **Sin logotipos, placas con letras ni texto.**

---

## Ficha 04-A: autos de tráfico (8 en una hoja)

| Campo | Valor |
|---|---|
| Entrega | `autos_trafico.png` |
| Lienzo y cuadrícula | 1536 × 1024, **4 × 2** |
| Clase de contorno | **XS** |
| Referencias | `auto_jugador.png` |
| Reemplaza | `assets/sprites/vehicles/npc_car.png`. Cada auto termina en 70 × 38; el juego elige uno al azar y ya no los tiñe por código |

**Los 8 autos**, de izquierda a derecha y de arriba abajo:

| Celda | Forma | Color |
|---|---|---|
| 1 | Sedán | azul cielo `#7FC8E8` |
| 2 | Hatchback | menta `#9CC9A7` |
| 3 | Auto redondo clásico tipo "vochito", genérico y **sin logo** | turquesa `#3FB8AF` |
| 4 | Sedán | lila `#BFB0D2` |
| 5 | Hatchback | naranja `#E86F56` |
| 6 | Pickup con la caja vacía | gris azulado `#7C8DA6` |
| 7 | Combi o minivan | durazno `#F3CFAA` |
| 8 | Sedán | blanco cal `#F6F1EA` |

**Prompt (SUBJECT):**

```
SUBJECT: a sprite sheet of 8 different friendly toy-like city cars seen exactly
from above (top-down), every car with its front pointing to the RIGHT, arranged
in a grid of 4 columns and 2 rows, one car per cell, transparent space between
cells. All cars have the same length and width (about 1.85 times longer than
wide) and the exact same rounded toy style, glossy light-blue windows and
peeking dark wheels as the attached red car. None of them is red and none has a
golden stripe. Cells, left to right, top to bottom:
1. sedan, sky blue (#7FC8E8);
2. hatchback, mint green (#9CC9A7);
3. classic round beetle-like compact car, generic with no logo, turquoise (#3FB8AF);
4. sedan, lilac (#BFB0D2);
5. hatchback, orange (#E86F56);
6. small pickup truck with an empty cargo bed, blue-grey (#7C8DA6);
7. small rounded minivan, peach (#F3CFAA);
8. sedan, off-white (#F6F1EA).
No logos, no license plates, no text.
```

**Se acepta si:**
- los 8 tienen el mismo tamaño y todos miran a la derecha;
- cada uno se distingue a 70 px por su forma o su color;
- ninguno parece el auto del jugador.

---

## Ficha 04-B: bus urbano y ambulancia

| Campo | Valor |
|---|---|
| Entrega | `vehiculos_grandes.png` |
| Lienzo y cuadrícula | 1536 × 1024, **1 columna × 2 filas**: arriba el bus, abajo la ambulancia |
| Clase de contorno | **L** |
| Referencias | `auto_jugador.png`, `autos_trafico.png` |
| Reemplaza | `assets/sprites/vehicles/bus.png` (139 × 80) y `ambulance.png` (94 × 50) |

**Prompt (SUBJECT):**

```
SUBJECT: two vehicles seen exactly from above (top-down), fronts pointing to the
RIGHT, one per row with transparent space between them, same toy style as the
attached cars.
Top row: a generic friendly city bus, long and rounded, turquoise (#3FB8AF) and
cream (#F6F1EA) two-tone roof, a row of roof hatches, glossy front windshield on
the right end. It must NOT be red, white-dominant or purple, no logos, no route
numbers, no text.
Bottom row: an ambulance van, white (#F6F1EA) body with a light-blue (#7FC8E8)
stripe, a big blue (#2E4DA0) rounded "plus" sign on the roof (NOT a red cross),
and a small light bar with one blue and one red lamp near the front.
The bus is about 1.75 times longer than the ambulance.
```

**Se acepta si:**
- el bus no recuerda a ADO: no es rojo, blanco ni morado dominante y no lleva letras;
- la ambulancia lleva el "+" azul y **no** una cruz roja;
- los dos miran a la derecha.

---

## Ficha 04-C: motocicleta

| Campo | Valor |
|---|---|
| Entrega | `moto.png` |
| Lienzo | 1536 × 1024, una sola moto centrada |
| Clase de contorno | **XS** |
| Referencias | `auto_jugador.png`, `autos_trafico.png` |
| Reemplaza | `assets/sprites/vehicles/motorcycle.png` (60 × 27) |

**Prompt (SUBJECT):**

```
SUBJECT: a small friendly motorcycle with its rider, seen exactly from above
(top-down), front pointing to the RIGHT. The rider wears a round yellow (#FFC700)
helmet and a teal jacket; the motorcycle body is dark purple (#3F1B4E) with
round mirrors. About 2.2 times longer than wide. No logos, no text.
```

---

## Ficha 04-D: ciclista (6 cuadros)

| Campo | Valor |
|---|---|
| Entrega | `ciclista.png` |
| Lienzo y cuadrícula | 1536 × 1024, **3 × 2** = 6 cuadros de pedaleo |
| Clase de contorno | **XS** |
| Referencias | `auto_jugador.png`, `moto.png` |
| Reemplaza | `assets/sprites/vehicles/cyclist.png` (cuadros finales de 60 × 29) |

**Prompt (SUBJECT):**

```
SUBJECT: animation sprite sheet, 6 frames of a pedaling cycle in a grid of 3
columns and 2 rows, transparent space between frames. A cyclist seen exactly
from above (top-down), riding to the RIGHT: green (#3FA34D) bicycle, rider with a
round yellow (#FFC700) helmet, sky-blue shirt, arms on the handlebar. Only the
legs and pedals change between frames (a smooth pedaling loop); the bike, rider
and position are identical in every frame. About 2 times longer than wide.
```

**Se acepta si:** los 6 cuadros forman un ciclo de pedaleo sin brincos, es el mismo
ciclista en todos y se ve desde arriba, no de lado.
