# Fichas del piloto: arte v2

Tres assets para decidir si el estilo de `guia_estilo.md` gusta, antes de pedir
los otros ~60. Claude los integra en el nivel 1 y saca capturas para comparar
antes y después.

## Cómo pedirlos en Codex

1. **El orden importa.** Primero el auto. Cuando te guste, **adjúntalo como imagen
   de referencia** en los pedidos de las casas y del niño, con la frase
   `Match exactly the art style, outline and shading of the attached reference image.`
   Así los tres salen del mismo mundo.
2. **Cada prompt se arma así:** bloque *Estilo base* de la guía (§2) + el prompt de
   la ficha. Los prompts van en inglés porque la IA de imágenes los sigue mejor.
3. **Pide 2 o 3 versiones de cada uno** y quédate con la mejor. Si ninguna convence,
   anota qué falla: eso corrige la guía.
4. **Dónde guardarlos:** en `~/claude/godot_game/arte_v2/entrada/`, con el nombre que
   dice cada ficha. Esa carpeta no se sube a git.

---

## Ficha 1: auto del jugador

| | |
|---|---|
| Reemplaza | `assets/sprites/player_car.png` |
| Tamaño final en el juego | **69 × 41 px** (ancho × alto). Claude lo reduce |
| Generar en | 1536 × 1024, auto centrado ocupando ~80 % del ancho |
| Vista | Cenital pura. **El frente mira a la derecha** |
| Nombre de entrega | `auto_jugador.png` |
| Se ve | Todo el tiempo, en todos los niveles. Es el protagonista |

**Prompt:**

```
SUBJECT: the player's car, seen exactly from above (top-down), front of the car
pointing to the RIGHT. A small, friendly, rounded compact hatchback, like a toy car.
Body color bright red (#DD2835) with a darker red outline. Light-blue glossy
windshield (#7FC8E8) toward the right/front and a smaller rear window toward the
left/back, with a red roof between them and a small white highlight on the glass.
Two little side mirrors. The four dark wheels (#2A2230) peek out slightly on the
top and bottom edges. Front (right end): two small warm-white headlights. Back
(left end): two small red-orange taillights. A thin golden (#FFC700) stripe along
the roof center. Proportions about 1.7 times wider than tall. Centered, nothing
else in the image.
```

**Se acepta si:**
- se reconoce como auto a 69 px de ancho (Claude lo prueba reducido);
- el frente mira a la derecha;
- los faros quedan en la orilla derecha y las calaveras en la izquierda, porque
  el juego dibuja encima los destellos de frenos y direccionales;
- no trae sombra, piso ni texto.

---

## Ficha 2: casas de la cuadra (hoja de 6)

| | |
|---|---|
| Reemplaza | `assets/sprites/city/casas.png`, que hoy tiene 4 casas de 128 × 128 |
| Tamaño final | **128 × 128 px cada casa**. El juego v2 usará 8 o más casas (Claude ajusta el código) |
| Generar en | 1536 × 1024, cuadrícula de **3 columnas × 2 filas**, una casa por celda, con espacio transparente entre ellas |
| Vista | Cenital: **azotea arriba (~70 % de la altura) y fachada con puerta abajo (~30 %)** |
| Nombre de entrega | `casas_a.png` (y `casas_b.png` si haces una segunda hoja) |
| Se ve | Pegadas una tras otra a lo largo de la calle, formando la cuadra |

**Reglas de forma:**
- Cada casa es **cuadrada y llena su celda de orilla a orilla a lo ancho**. En el
  juego van pegadas como en una calle real de Puebla, sin huecos.
- Las 6 casas tienen **el mismo tamaño y la misma altura de fachada**. Solo cambia
  todo lo demás.

**Prompt:**

```
SUBJECT: a sprite sheet of 6 different small Mexican neighborhood houses from
Puebla, arranged in a regular grid of 3 columns and 2 rows, one house per cell,
with transparent space between cells. Each house is a SQUARE footprint seen from
above: the flat rooftop fills the top 70% and the front facade with the door is
visible at the bottom 30%, facing down toward the viewer. All 6 houses have the
same size and the same facade height, and each one fills its cell edge to edge
horizontally so they can be placed side by side in a continuous street.
Make every house clearly different:
1. Mexican-pink (#E0457B) facade, black round water tank (tinaco) on the roof,
   wooden door.
2. Ochre (#E3A548) facade, colorful clothesline with drying clothes on the roof,
   two windows with iron bars.
3. White facade with talavera-blue (#2E4DA0) tile trim, potted plants on the roof,
   blue door.
4. Lilac (#B8A6CC) facade, red waterproofed roof (#A35B4A), a small skylight,
   a garage gate.
5. Peach (#F8C99B) facade, two-story look with a small upper terrace and a TV
   antenna, a little corner shop with a rolled-up metal shutter (no text).
6. Brick-red (#B5523B) facade, rooftop with two small water tanks and a potted
   tree, an arched doorway.
Doors, windows and roof details are simple, rounded and readable at small size.
```

**Se acepta si:**
- las 6 se notan distintas a 128 px;
- las fachadas quedan a la misma altura, para que se alineen en la cuadra;
- no traen sombra en el piso, texto ni letreros con letras;
- se ven más tranquilas (menos saturadas) que el auto.

---

## Ficha 3: niño caminando y sorprendido (peatón)

| | |
|---|---|
| Reemplaza | `assets/sprites/pedestrians/child_walk.png` y `child_scared.png` (8 cuadros cada una, de 46 × 85 px) |
| Tamaño final | **46 × 85 px por cuadro**, con los pies abajo al centro |
| Generar en | 1536 × 1024, cuadrícula de **4 columnas × 2 filas** = 8 cuadros, de izquierda a derecha y de arriba a abajo |
| Vista | De pie, **frente-perfil (3/4)**, caminando **hacia la derecha**. No cenital |
| Nombres de entrega | `nino_camina.png` y `nino_sorprendido.png` |
| Se ve | Cruzando la calle en el paso peatonal (niveles 1, 2, 4 y 8). El niño tiene que frenar por él |

**Personaje.** Es el mismo de hoy, para que se reconozca: un niño de unos 8 años,
piel morena (`#C68B59`), cabello oscuro despeinado, playera blanca, short morado,
mochila amarilla y tenis rojos.

**Prompt A, caminando (`nino_camina.png`):**

```
SUBJECT: animation sprite sheet, 8 frames of a walk cycle, arranged in a grid of
4 columns and 2 rows (read left to right, top to bottom), with transparent space
between frames. The SAME character in every frame: a cheerful 8-year-old Mexican
boy with brown skin (#C68B59), messy dark hair, big friendly eyes, white t-shirt,
purple shorts, a yellow school backpack and red sneakers. Standing figure seen
from a 3/4 front-side view (NOT from above), walking to the RIGHT. Full body, feet
at the same baseline in every frame, same size and proportions in every frame.
Smooth walk cycle: legs and arms alternate naturally, slight head bob.
Chibi-like proportions: big head (about 1/3 of the height).
```

**Prompt B, sorprendido (`nino_sorprendido.png`).** Es para cuando el auto se
detiene cerca: el niño se para, ve el auto y levanta las manos. Debe verse
**sorprendido, no asustado ni lastimado**.

```
SUBJECT: animation sprite sheet, 8 frames, grid of 4 columns and 2 rows, same
character as the attached walk cycle (same boy, same clothes, same size, same
3/4 view facing right, feet on the same baseline). Frames 1-2: still walking.
Frames 3-4: stops and turns his head toward the viewer, eyes wide open.
Frames 5-7: raises both open hands at chest height in a surprised "whoa!" gesture,
small round open mouth. Frame 8: relaxes, small relieved smile. Friendly and
light-hearted, never scared, crying or hurt.
```

**Se acepta si:**
- es claramente el mismo niño en los 16 cuadros;
- los pies están a la misma altura (si no, el niño "brinca" al animarse);
- se le ve la cara y la mochila a 85 px de alto;
- no se ve asustado ni lastimado (regla de nada violento).

---

## Qué hace Claude cuando lleguen

1. Quita el fondo si hace falta, recorta cada elemento y lo reduce al tamaño exacto
   (`tools/art/integrar_v2.py`).
2. Cambia el filtro a *Linear* en la rama `feature/arte-v2` y ajusta las luces del
   auto al dibujo nuevo.
3. Saca capturas del nivel 1 **antes y después** en el mismo momento del recorrido
   y te las enseña juntas.
4. Contigo decide qué corregir en la guía: color, trazo, contorno o proporciones.
   Con la guía corregida se escriben las fichas de los ~60 assets restantes.
