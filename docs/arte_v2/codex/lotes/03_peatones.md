# Lote 03: peatones (P0)

Son 4 personajes que cruzan la calle. Hay que rediseñarlos en el estilo del niño
del piloto, conservando su identidad para que el equipo los reconozca.

**Reglas comunes de este lote:**
- **Referencias obligatorias:** `nino_camina.png` y `nino_sorprendido.png`. Dan el
  estilo, la escala de la cabeza y el tamaño. Todos los peatones miden más o menos lo
  mismo que el niño, salvo la persona mayor, que va un poco encorvada.
- **Vista:** de pie, frente-perfil 3/4, **caminando hacia la DERECHA**, cuerpo
  completo y pies en la misma línea base en todos los cuadros.
- **Dos hojas por personaje:** la caminata y las reacciones. Para pedir las
  reacciones, **adjunta la caminata del mismo personaje**.
- "Asustado" se dibuja como **sorprendido** (ojos muy abiertos, se detiene y levanta
  las manos). Nunca miedo, llanto ni caída.
- **Clase de contorno:** **XS**.

---

## Ficha 03-A y 03-B: niña de primaria

**Personaje:**
- niña de unos 7 años, piel morena oscura `#8A5A3B`;
- cabello negro con dos coletas y moños rojos;
- suéter escolar morado oscuro `#3F1B4E` sobre una blusa blanca;
- falda lila `#9C4B79`, calcetas blancas y zapatos negros;
- mochila azul cielo `#7FC8E8`.

| Ficha | Entrega | Lienzo y cuadrícula | Cuadros |
|---|---|---|---|
| 03-A | `nina_camina.png` | 1536 × 1024, 4 × 2 | 8 cuadros de caminata |
| 03-B | `nina_reacciones.png` | 1536 × 1024, 3 × 2 | 1-4: se detiene, voltea y levanta las manos sorprendida; 5: parada tranquila de frente (idle); 6: vacía |

Reemplaza `assets/sprites/pedestrians/girl.png` (cuadros finales de 43 × 80).

**Prompt 03-A (SUBJECT):**

```
SUBJECT: animation sprite sheet, 8 frames of a walk cycle in a grid of 4 columns
and 2 rows (left to right, top to bottom), transparent space between frames.
The SAME character in every frame: a cheerful 7-year-old Mexican schoolgirl with
dark brown skin (#8A5A3B), black hair in two pigtails with red bows, a dark-purple
(#3F1B4E) school sweater over a white collar, lilac skirt (#9C4B79), white socks,
black shoes and a sky-blue (#7FC8E8) backpack. Standing figure, 3/4 front-side
view (NOT from above), walking to the RIGHT. Full body, feet on the same baseline,
same size in every frame, same art style and proportions as the attached boy.
Smooth walk cycle: legs and arms alternate, every frame different.
```

**Prompt 03-B (SUBJECT):**

```
SUBJECT: animation sprite sheet, grid of 3 columns and 2 rows, the SAME girl as
the attached walk cycle (identical design, size, view facing right, feet on the
same baseline). Frames 1-4: she stops, turns her head toward the viewer and raises
both open hands at chest height in a friendly surprised "whoa!" (eyes wide, small
round mouth), never scared or crying. Frame 5: standing still, relaxed, facing
the viewer (idle). Frame 6: empty.
```

---

## Ficha 03-C y 03-D: señora adulta con bolsas del mandado

**Personaje:**
- mujer de unos 35 años, piel clara `#F2C29B`;
- cabello castaño en cola de caballo;
- suéter verde `#3FA34D` y pantalón morado oscuro `#3F1B4E`;
- tenis blancos;
- una **bolsa del mandado amarilla `#FFC700`** en cada mano.

| Ficha | Entrega | Lienzo y cuadrícula | Cuadros |
|---|---|---|---|
| 03-C | `adulto_camina.png` | 1536 × 1024, 4 × 2 | 8 cuadros de caminata |
| 03-D | `adulto_reacciones.png` | 1536 × 1024, 3 × 2 | 1-5: se detiene, voltea y levanta las bolsas sorprendida; 6: parada tranquila (idle) |

Reemplaza `assets/sprites/pedestrians/adult.png` (cuadros finales de 46 × 88).

**Prompts:** usa los mismos de 03-A y 03-B y cambia la descripción del personaje por:

```
a friendly Mexican woman about 35 years old with light skin (#F2C29B), brown
hair in a ponytail, green (#3FA34D) sweater, dark-purple (#3F1B4E) trousers,
white sneakers, carrying a yellow (#FFC700) shopping bag in each hand
```

En 03-D, los cuadros son: `Frames 1-5: she stops, turns toward the viewer and lifts
her bags in a friendly surprised gesture. Frame 6: standing still, relaxed (idle).`

---

## Ficha 03-E y 03-F: abuelita con bastón

**Personaje:**
- señora de unos 75 años, piel morena `#C68B59`;
- cabello blanco recogido y lentes redondos;
- blusa blanca, rebozo morado `#3F1B4E` sobre los hombros y falda larga lila `#9C4B79`;
- zapatos cafés;
- **bastón** en la mano del frente.

Camina despacio y un poco encorvada.

| Ficha | Entrega | Lienzo y cuadrícula | Cuadros |
|---|---|---|---|
| 03-E | `abuelita_camina.png` | 1536 × 1024, 3 × 2 | 6 cuadros de caminata lenta con bastón |
| 03-F | `abuelita_reacciones.png` | 1536 × 1024, 3 × 2 | 1-5: se detiene, voltea y levanta la mano libre sorprendida (sin soltar el bastón); 6: parada tranquila (idle) |

Reemplaza `assets/sprites/pedestrians/elder.png` (cuadros finales de 48 × 78). El
juego reproduce la reacción de ida y vuelta.

**Descripción para los prompts:**

```
a sweet Mexican grandmother about 75 years old with brown skin (#C68B59), white
hair in a bun, round glasses, white blouse, a dark-purple (#3F1B4E) rebozo shawl
over her shoulders, long lilac (#9C4B79) skirt, brown shoes, walking slowly and
slightly hunched with a wooden cane in her front hand
```

---

## Ficha 03-G: niño en silla de ruedas (una sola hoja)

**Personaje:**
- niño de unos 9 años, piel morena oscura `#8A5A3B`;
- cabello negro corto;
- playera azul cielo `#7FC8E8` y pantalón morado oscuro `#3F1B4E`;
- tenis blancos;
- **silla de ruedas roja `#DD2835`** con ruedas grandes grises.

Va de perfil 3/4 hacia la derecha y avanza empujando las ruedas.

| Campo | Valor |
|---|---|
| Entrega | `silla_ruedas.png` |
| Lienzo y cuadrícula | 1024 × 1024, **4 × 4** |
| Fila 1 (cuadros 1-4) | avanza empujando las ruedas |
| Fila 2 (cuadros 5-8) | se detiene y levanta las manos sorprendido |
| Fila 3 (cuadros 9-12) | feliz, saluda con los brazos arriba |
| Fila 4 | cuadro 13: quieto y tranquilo (idle); cuadros 14-16 vacíos |
| Reemplaza | `assets/sprites/pedestrians/wheelchair.png` (cuadros finales de 55 × 78) |

**Prompt (SUBJECT):**

```
SUBJECT: animation sprite sheet in a grid of 4 columns and 4 rows, transparent
space between frames. The SAME character in every frame: a cheerful Mexican boy
about 9 years old with dark brown skin (#8A5A3B), short black hair, sky-blue
(#7FC8E8) t-shirt, dark-purple (#3F1B4E) trousers and white sneakers, sitting in
a red (#DD2835) wheelchair with big grey wheels, 3/4 side view facing RIGHT, same
size and baseline in every frame, same art style as the attached boy.
Row 1 (frames 1-4): rolling forward, pushing the wheels with his hands.
Row 2 (frames 5-8): stops and raises his open hands in a friendly surprised gesture.
Row 3 (frames 9-12): happy, waving with both arms up, big smile.
Row 4: frame 13 sitting still, relaxed (idle); frames 14-16 empty.
```

---

**Se acepta si (todo el lote):**
- cada personaje es **idéntico** en sus dos hojas (ropa, peinado, colores y tamaño);
- los pies o las ruedas quedan en la misma línea en todos los cuadros;
- la caminata alterna piernas y no tiene dos cuadros iguales seguidos;
- se distinguen entre sí de lejos: los colores y las siluetas son distintos;
- nadie se ve asustado, triste ni lastimado.
