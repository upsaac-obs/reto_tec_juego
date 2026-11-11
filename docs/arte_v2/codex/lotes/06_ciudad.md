# Lote 06: ciudad (P0)

Son la vegetación, los edificios y el mobiliario urbano. Es **decorado**: colores
apagados (paleta de fachadas de `estilo.md` §3) y nunca más llamativo que los autos
o los peatones.

**Referencias en todo el lote:** `casas_a.png` (obligatoria) y `auto_jugador.png`.

---

## Ficha 06-A: árboles y plantas (10)

| Campo | Valor |
|---|---|
| Entrega | `arboles.png` |
| Lienzo y cuadrícula | 1536 × 1024, **4 × 3** (celdas 11 y 12 vacías) |
| Clase de contorno | **S** |
| Vista | De pie, de frente con un poco de arriba: copa redonda, algo de tronco y base abajo al centro |
| Reemplaza | `assets/sprites/city/arboles.png`. Cada planta termina en 64 × 64; **el orden de las celdas 1-4 importa** |

| Celda | Planta |
|---|---|
| 1 | Árbol de copa redonda (fresno), verde `#6FAE5E` |
| 2 | Jacaranda con flores lila `#BFB0D2` |
| 3 | Grupo de 2 o 3 arbustos redondos |
| 4 | Maceta grande de barro con flores amarillas |
| 5 | Laurel de la India: copa muy redonda y oscura `#2B6B3F` |
| 6 | Palma pequeña |
| 7 | Buganvilia: arbusto con flores rosa mexicano |
| 8 | Jardinera rectangular de talavera (azul y blanca) con flores |
| 9 | Maceta de barro con un nopal |
| 10 | Seto recortado y alargado |

**Prompt (SUBJECT):**

```
SUBJECT: a sheet of 10 trees and plants for a Mexican neighborhood street, each
seen from the front with a slight top-down angle (round canopy, a bit of trunk),
base at the bottom center of its cell, arranged in a grid of 4 columns and 3
rows, cells 11 and 12 empty, transparent space between cells. Soft, slightly
muted greens (#6FAE5E, #5E9A5A, #2B6B3F) in round scalloped clumps. Cells, left
to right, top to bottom:
1. round ash tree; 2. jacaranda tree with lilac (#BFB0D2) blossoms;
3. a cluster of 2-3 round bushes; 4. big clay pot with yellow flowers;
5. very round dark Indian laurel tree; 6. small palm tree;
7. bougainvillea bush with pink flowers; 8. rectangular blue-and-white talavera
planter with flowers; 9. clay pot with a prickly-pear cactus (nopal);
10. a long trimmed hedge.
```

**Se acepta si:** las 10 se ven del mismo set que las casas, la base queda abajo al
centro, los verdes están apagados (no verde "semáforo") y las celdas 1-4 están en ese
orden.

---

## Ficha 06-B: edificios (6)

| Campo | Valor |
|---|---|
| Entrega | `edificios.png` |
| Lienzo y cuadrícula | 1536 × 1024, **3 × 2** |
| Clase de contorno | **L** |
| Vista | Igual que las casas: azotea arriba y fachada abajo, con la línea de la fachada a la **mitad de la altura** |
| Reemplaza | `assets/sprites/city/edificios.png`. Cada edificio termina en 142 × 160 (un poco más ancho y más alto que una casa) |

| Celda | Edificio |
|---|---|
| 1 | Departamentos de 3 pisos, menta `#9CC9A7`, con balcones de herrería y 2 tinacos en la azotea |
| 2 | Edificio de cantera `#C9BDB4` con 3 arcos de portal abajo (estilo zócalo) |
| 3 | Edificio terracota `#DA8068` de 2 pisos con local abajo: toldo de rayas y cortina metálica (sin letrero) |
| 4 | Edificio azul pastel `#9DBFDC` con cenefa de talavera y macetas en los balcones |
| 5 | Edificio ocre `#E2B46A` con azotea jardín (pasto y macetas) |
| 6 | Edificio rosa `#D46A8C` de 2 pisos con tendedero y antena en la azotea |

**Prompt (SUBJECT):**

```
SUBJECT: a sprite sheet of 6 different small 2-3 storey buildings from Puebla,
Mexico, grid of 3 columns and 2 rows, one building per cell, transparent space
between cells. Same camera and style as the attached houses: flat rooftop seen
from above in the top half, front facade visible in the bottom half facing the
viewer, rounded white parapet. All buildings have the same footprint size and
the facade starts at the same height (half of the image). Soft muted colors.
Cells, left to right, top to bottom:
1. mint (#9CC9A7) 3-storey apartments with wrought-iron balconies, two water
   tanks on the roof;
2. warm-grey cantera stone (#C9BDB4) building with three arches at street level;
3. terracotta (#DA8068) 2-storey building with a ground-floor shop: striped
   awning and rolled-up metal shutter, no sign;
4. pastel blue (#9DBFDC) building with a talavera tile band and flower pots on
   the balconies;
5. ochre (#E2B46A) building with a rooftop garden;
6. pink (#D46A8C) 2-storey building with a clothesline and a TV antenna on the roof.
No text, no signs with letters.
```

---

## Ficha 06-C: mobiliario urbano y parada de bus

| Campo | Valor |
|---|---|
| Entrega | `mobiliario.png` |
| Lienzo y cuadrícula | 1536 × 1024, **3 × 2** |
| Clase de contorno | **S** |
| Vista | De pie, de frente con un poco de arriba, base abajo al centro |
| Reemplaza | `assets/sprites/city/bus_stop.png` (celda 1, 97 × 80). Las celdas 2-6 son nuevas para decorar la banqueta |

| Celda | Objeto |
|---|---|
| 1 | Parada de bus: techo curvo azul cielo `#7FC8E8`, banca y respaldo, **sin letras** |
| 2 | Farol colonial de herrería negra-morada con lámpara crema |
| 3 | Banca de cantera con un respaldo de azulejos de talavera |
| 4 | Bote de basura verde `#5E9A5A` redondo con tapa |
| 5 | Carrito de elotes con sombrilla de colores (sin letrero) |
| 6 | Puesto de fruta con toldo rosa `#D46A8C` y fruta de colores |

**Prompt (SUBJECT):**

```
SUBJECT: a sheet of 6 friendly street-furniture props for a Mexican neighborhood
sidewalk, each standing, front view with a slight top-down angle, base at the
bottom center of its cell, grid of 3 columns and 2 rows, transparent space
between cells, same style as the attached houses. Cells, left to right, top to
bottom:
1. a bus stop shelter with a curved sky-blue (#7FC8E8) roof, a bench and a back
   panel, no letters;
2. a colonial wrought-iron street lamp with a cream lantern;
3. a stone bench with a blue-and-white talavera tile backrest;
4. a round green (#5E9A5A) trash bin with a lid;
5. a corn-on-the-cob (elotes) street cart with a colorful umbrella, no sign;
6. a fruit stand with a pink (#D46A8C) awning and colorful fruit.
No text anywhere.
```

**Se acepta si:** no hay letreros con letras, todos tienen la base abajo al centro, se
ven del mismo mundo que las casas y la parada se reconoce como parada de bus.
