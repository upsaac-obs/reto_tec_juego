# Lote 05: señales (P0)

Las señales viven junto a la calle. Son **objetos de pie**: se ven de frente, con la
base abajo al centro. Los colores son los oficiales de tránsito, brillantes, porque
el niño tiene que verlas antes que el decorado.

> **El semáforo de autos NO se pide.** Claude lo dibuja por código, porque el juego
> enciende sus focos en posiciones exactas.

**Restricción clave: ninguna señal lleva letras ni números.**
- El "ALTO" lo escribe el juego.
- El número del límite de velocidad también lo escribe el juego, dentro del círculo
  blanco vacío.

---

## Ficha 05-A: hoja de señales

| Campo | Valor |
|---|---|
| Entrega | `senales.png` |
| Lienzo y cuadrícula | 1536 × 1024, **4 columnas × 2 filas** |
| Clase de contorno | **S** |
| Referencias | `auto_jugador.png`, `casas_a.png`, `hud_iconos.png` |
| Reemplaza | `assets/sprites/signals/signs.png` (cuadros de 72 × 112), `pedestrian_light.png` (3 cuadros de 43 × 104) y `city/bus_stop_sign.png` (28 × 52) |

**Qué va en cada celda.** Todas las celdas tienen la misma altura de poste, salvo la 8.

| Celda | Elemento | Detalle |
|---|---|---|
| 1 | Señal de alto **sin texto** | octágono rojo `#DD2835` con borde blanco, en poste gris |
| 2 | Límite de velocidad **vacío** | círculo blanco grande con aro rojo grueso y el centro **totalmente blanco y vacío** (ahí escribe el juego), en poste gris |
| 3 | Zona escolar | pentágono oro `#FFC700` con borde oscuro y dos siluetas de niños caminando con mochila, en poste gris |
| 4 | Ceda el paso | triángulo invertido blanco con borde rojo grueso, en poste gris |
| 5 | Semáforo peatonal, **apagado** | caja oscura `#3F1B4E` vertical con 2 ventanas: arriba la figura de pie y abajo la figura caminando, las dos apagadas (gris oscuro) |
| 6 | Semáforo peatonal, **rojo** | la misma caja, con la figura de pie de arriba encendida en rojo brillante y la de abajo apagada |
| 7 | Semáforo peatonal, **verde** | la misma caja, con la figura de arriba apagada y la figura caminando de abajo encendida en verde brillante `#3FA34D` |
| 8 | Letrero de parada de bus | poste delgado con un disco azul cielo `#7FC8E8` con un pictograma blanco de bus de frente, **sin letras**, más bajo que las demás señales |

**Prompt (SUBJECT):**

```
SUBJECT: a sheet of standing street signs for a kids' game, front view with a
slight top-down angle, each sign on a short grey rounded pole with its base at
the bottom center of its cell, arranged in a grid of 4 columns and 2 rows, one
item per cell, transparent space between cells, all poles the same height
except item 8. ABSOLUTELY NO letters or numbers on any sign. Cells, left to right,
top to bottom:
1. stop sign: red (#DD2835) octagon with a white border, completely blank face;
2. speed-limit sign: big white circle with a thick red ring, the inside left
   completely blank and white;
3. school-zone sign: golden (#FFC700) pentagon with a dark border and two simple
   child silhouettes walking with backpacks;
4. yield sign: white inverted triangle with a thick red border, blank inside;
5. pedestrian traffic light, OFF: dark-purple (#3F1B4E) rounded box on a pole
   with two windows, top window a standing person pictogram, bottom window a
   walking person pictogram, both unlit dark grey;
6. the same pedestrian light with only the TOP standing figure lit in bright red;
7. the same pedestrian light with only the BOTTOM walking figure lit in bright
   green (#3FA34D);
8. a shorter thin pole with a sky-blue (#7FC8E8) disc showing a simple white
   front-view bus pictogram, no letters.
```

**Se acepta si:**
- **no hay ninguna letra ni número** (rechazo automático si aparece "ALTO", "STOP" o "40");
- el círculo del límite está vacío y blanco por dentro;
- las celdas 5, 6 y 7 son la **misma caja** y solo cambia qué figura se enciende;
- todas tienen la base abajo al centro.
