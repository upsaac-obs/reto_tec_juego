# Lote 02: copiloto ajolote (P0)

El copiloto es la mascota que habla con el niño durante el nivel. Aparece dentro de
un medallón redondo junto al globo de texto (el medallón lo dibuja el juego).

Se produce **en 2 pasos**. Primero la ficha maestra (02-A). Cuando esté aprobada,
**adjúntala siempre** para pedir las poses (02-B), así es el mismo personaje en
todas.

**Personaje (debe reconocerse el de hoy):** un ajolote (axolotl) bebé con estos rasgos:
- cuerpo rosa durazno `#F4A6B8`;
- 3 branquias de cada lado de la cabeza, rosa coral `#E0457B`, como plumitas;
- ojos grandes negros con brillo y cachetes rosados;
- gorra de chofer amarilla `#FFC700` con banda roja `#DD2835` y una placa redonda
  lila **sin letras ni dibujo**;
- **el cinturón de seguridad puesto**, una banda morada `#3F1B4E` en diagonal del
  hombro a la cadera.

Se ve **de busto**: cabeza, hombros y pecho. Es amable y curioso, nunca regañón.

---

## Ficha 02-A: ficha maestra del copiloto

| Campo | Valor |
|---|---|
| Entrega | `copiloto_maestra.png` |
| Lienzo | 1024 × 1024, un solo personaje centrado |
| Clase de contorno | **S** |
| Referencias | `nino_camina.png`, `auto_jugador.png` |
| Uso | Referencia para 02-B. No entra directo al juego |

**Prompt (SUBJECT):**

```
SUBJECT: character reference of the game's mascot co-pilot: a cute baby axolotl,
bust portrait (head, shoulders and chest), facing the viewer, slightly turned
3/4. Peachy-pink skin (#F4A6B8), three feathery coral-pink gills (#E0457B) on
each side of the head, big glossy black eyes, rosy cheeks, small friendly smile.
Wears a yellow (#FFC700) chauffeur cap with a red (#DD2835) band and a plain
round lilac badge with no letters or symbols. A dark-purple (#3F1B4E) seatbelt
strap crosses the chest diagonally from the left shoulder. Neutral, warm,
curious expression. Same chibi proportions and art style as the attached boy.
```

**Se acepta si:**
- se reconoce como ajolote (branquias) y como el copiloto de antes (gorra amarilla y cinturón);
- no tiene letras en la gorra;
- lo cuadrado del busto no corta las branquias;
- se ve tierno, no raro.

---

## Ficha 02-B: hoja de 8 poses

| Campo | Valor |
|---|---|
| Entrega | `copiloto_poses.png` |
| Lienzo | 1536 × 1024, cuadrícula de **4 columnas × 2 filas** |
| Clase de contorno | **S** |
| Referencias | **`copiloto_maestra.png` (obligatoria)**, `nino_camina.png` |
| Reemplaza | `assets/sprites/copilot/copilot.png`. Cuadros finales de 105 × 106; el juego arma las animaciones (hablar, feliz, sorprendido, pensando) con estas poses |

**Las 8 poses**, de izquierda a derecha y de arriba abajo:

| Celda | Pose |
|---|---|
| 1 | Hablando, boca cerrada (sonrisa suave) |
| 2 | Hablando, boca abierta (vocal "a") |
| 3 | Feliz: ojos cerrados en arco y sonrisa grande |
| 4 | Feliz con el pulgar arriba (una mano a la altura del pecho) |
| 5 | Sorprendido: ojos muy abiertos y boca en "o" pequeña (amable, sin miedo) |
| 6 | Pensando: mira hacia arriba con una mano en la barbilla |
| 7 | Parpadeo: ojos cerrados, boca neutra |
| 8 | Saluda con la mano abierta |

**Prompt (SUBJECT):**

```
SUBJECT: expression sheet of the SAME axolotl co-pilot shown in the attached
reference (identical design, colors, cap, seatbelt, size and framing in every
cell), bust portrait, arranged in a grid of 4 columns and 2 rows with transparent
space between cells. The head is in the same position and size in every cell,
only the face and hands change. Cells, left to right, top to bottom:
1. talking, mouth closed with a soft smile;
2. talking, mouth open saying "ah";
3. happy, eyes closed in happy arcs, big smile;
4. happy, giving a thumbs up with one hand at chest height;
5. surprised, eyes wide open, small round "o" mouth, friendly not scared;
6. thinking, looking up with one hand on the chin;
7. blinking, eyes closed, neutral mouth;
8. waving hello with one open hand.
```

**Se acepta si:**
- es **idéntico** en las 8 celdas (gorra, colores, cinturón, tamaño de cabeza);
- la cabeza está en el mismo lugar en todas, para que al animar no "salte";
- las 8 expresiones se distinguen en un cuadro de 105 px.
