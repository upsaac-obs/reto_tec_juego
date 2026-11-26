# Lote 11: garaje (vehículos que se compran con estrellas)

El niño gasta sus estrellas en el mapa para cambiar el vehículo con el que juega. Hay
6: dos de 3 estrellas, dos de 6 y dos de 9. El juego cambia el sprite del auto del
jugador por el elegido y el menú nativo los muestra en grande en el garaje.

**Para todo el lote:**
- Va el STYLE BASE de `estilo.md` y la clase de contorno de cada ficha.
- **Vista cenital pura** (se ve el techo) y **el frente apunta a la DERECHA**, igual
  que `auto_jugador.png`.
- **Referencias en todas las llamadas:** `auto_jugador.png` y `autos_trafico.png`.
- **Todos llevan la raya dorada `#FFC700`** a lo largo del techo o del cofre: es la
  marca del jugador. Así nunca se confunden con el tráfico. Ninguno usa el color
  exacto de un auto de tráfico (ver lote 04).
- **Misma huella que el auto actual:** cada auto termina en **69 × 41 px**
  (≈ 1.7 veces más largo que ancho). Llantas asomándose a los lados como el auto rojo.
- **Luces en el mismo lugar:** dos faros claros en las esquinas del frente (derecha) y
  dos calaveras rojas o naranjas en las esquinas de atrás (izquierda). El juego dibuja
  el brillo de faros y frenos encima de esos puntos.
- **Sin género:** no hay "de niña" ni "de niño". Cada par tiene un estilo distinto
  (uno aventurero, uno tierno) y cualquiera elige.
- **Nada de ADO, patrullas, militares, sirenas ni torretas.** Sin logos, placas con
  letras ni texto.

---

## Ficha 11-A: autos del garaje (5 en una hoja)

| Campo | Valor |
|---|---|
| Entrega | `garaje_autos.png` |
| Lienzo y cuadrícula | 1536 × 1024, **3 × 2** (la última celda va vacía) |
| Clase de contorno | **XS** |
| Referencias | `auto_jugador.png`, `autos_trafico.png` |
| Va a | `assets/sprites/garage/car_<id>.png` (69 × 41) y a los menús nativos en grande |

| Celda | id | Precio | Vehículo | Color |
|---|---|---|---|---|
| 1 | `burbuja` | 3 ★ | Compacto redondito tipo burbuja, muy tierno, faros grandes | rosa mexicano `#E0457B` |
| 2 | `todoterreno` | 3 ★ | Auto todoterreno chico, llantas gruesas, rejilla en el techo | verde hoja `#7CC56B` |
| 3 | `convertible` | 6 ★ | Convertible sin techo, se ven dos asientos vacíos con cinturón | azul talavera `#2E4DA0` |
| 4 | `deportivo` | 9 ★ | Superdeportivo bajo y alargado, alerón atrás, el más llamativo | amarillo dorado `#FFC700` con raya morada `#3F1B4E` |
| 5 | `futuro` | 9 ★ | Auto del futuro eléctrico tipo cápsula, cabina de vidrio grande, luces turquesa | blanco perla `#F6F1EA` con detalles turquesa `#3FB8AF` |

> El deportivo es el único sin raya dorada (ya es dorado): lleva la raya en morado.

**Prompt (SUBJECT):**

```
SUBJECT: a sprite sheet of 5 special toy-like cars for the player to unlock, seen
exactly from above (top-down), every car with its front pointing to the RIGHT,
arranged in a grid of 3 columns and 2 rows, one car per cell, the last cell (bottom
right) left empty, transparent space between cells. Every car has the same length
and width as the attached red car (about 1.7 times longer than wide), the exact
same rounded toy style, glossy light-blue windows, peeking dark wheels, two pale
headlights at the front corners and two red tail lights at the back corners. Every
car has a golden (#FFC700) racing stripe along its length, except car 4 whose stripe
is dark purple (#3F1B4E). They must look more special and exciting than the attached
red car and clearly different from the attached traffic cars. Cells, left to right,
top to bottom:
1. a tiny round bubble car with big cute headlights, Mexican pink (#E0457B);
2. a small off-road car with chunky wheels and a roof rack, leaf green (#7CC56B);
3. an open-top convertible showing two empty seats with seat belts, talavera blue
   (#2E4DA0);
4. a low, long supercar with a rear spoiler, the flashiest of all, golden yellow
   (#FFC700);
5. a futuristic electric capsule car with a big glass cockpit and turquoise
   (#3FB8AF) light strips, pearl white (#F6F1EA).
No police, no sirens, no military, no logos, no license plates, no text.
```

**Se acepta si:**
- los 5 tienen el mismo largo y ancho que el auto rojo y todos miran a la derecha;
- a 69 px se distingue cada uno por su forma y su color;
- todos tienen la raya (dorada o morada en el 4) y los faros y calaveras en las esquinas;
- ninguno parece patrulla, ambulancia ni auto de tráfico.

---

## Ficha 11-B: moto con casco

| Campo | Valor |
|---|---|
| Entrega | `garaje_moto.png` |
| Lienzo y cuadrícula | 1536 × 1024, **2 × 1**: izquierda la moto con su conductor, derecha solo el casco de frente |
| Clase de contorno | **XS** (moto) y **S** (casco) |
| Referencias | `auto_jugador.png`, `ciclista.png` |
| Va a | `assets/sprites/garage/car_moto.png` (≈ 60 × 26) y el ícono del casco del HUD |

Precio: **6 ★**. En la moto el casco ocupa el lugar del cinturón, así que el casco
tiene que leerse muy claro desde arriba.

**Prompt (SUBJECT):**

```
SUBJECT: left cell: a friendly toy-like scooter-style motorcycle seen exactly from
above (top-down), front pointing to the RIGHT, about 2.3 times longer than wide,
same rounded toy style and glossy highlights as the attached red car, body color
orange-coral (#E86F56) with a golden (#FFC700) stripe. A rider sits on it, seen from
above: the most visible part is a big, round, shiny full-face helmet in golden
yellow (#FFC700) with a light-blue visor, shoulders and hands on the handlebar. One
pale headlight at the front tip and one red tail light at the back tip, small
turn-signal lights on both sides of the front and the back.
Right cell: the same helmet alone, seen from the front, big and centered, as a game
icon.
No logos, no text.
```

**Se acepta si:**
- el casco es lo primero que se ve en la moto, aun a 60 px;
- las direccionales se ven en las cuatro esquinas (adelante y atrás, a los lados);
- el estilo es el mismo juguete que los autos.

---

## Ficha 11-C: botón e ícono del garaje

| Campo | Valor |
|---|---|
| Entrega | `garaje_iconos.png` |
| Lienzo y cuadrícula | 1536 × 1024, **2 × 1** |
| Clase de contorno | **M** |
| Referencias | `botones.png`, `estrellas.png`, `auto_jugador.png` |
| Va a | `btn_garage` y `icon_coin_star` en las dos apps (`res/drawable-nodpi/` y `Assets.xcassets`) |

```
SUBJECT: two game UI icons seen from the front, same glossy candy button family as
the attached buttons. Left cell: a round dark purple (#3F1B4E) button with a golden
(#FFC700) ring, showing a small cute car (the attached red car seen from the front)
with a tiny wrench beside it, meaning "garage". Right cell: a single golden star
(#FFC700) like the attached stars, slightly tilted, with a sparkle, used as a coin
for prices. No text, no numbers.
```

**Se acepta si:** el botón se ve de la misma familia que Jugar, Atrás y Sonido, y la
estrella moneda combina con `estrellas.png`.
