# Lote 01: HUD (P0)

Son los botones e íconos que el niño ve y toca encima del nivel. Todos usan el
botón "caramelo" de `estilo.md` §5 y salen en **una sola hoja**, para que tengan
exactamente el mismo bisel, contorno y brillo.

---

## Ficha 01-A: hoja de íconos del HUD

| Campo | Valor |
|---|---|
| Entrega | `hud_iconos.png` |
| Lienzo | 1536 × 1024, cuadrícula de **4 columnas × 3 filas** (celdas de 384 × 341) |
| Clase de contorno | **S** |
| Referencias | `auto_jugador.png`, `casas_a.png` |
| Reemplaza | `assets/ui/icons/*.png` (lista abajo) |

**Qué va en cada celda.** El tamaño final es el que se ve en pantalla a 1280 × 720.

| Celda | Elemento | Forma | Tamaño final | Notas |
|---|---|---|---|---|
| 1 | Flecha a la DERECHA | flecha gorda y redonda, oro `#FFC700` | 138 × 120 | la izquierda es su espejo; no la dibujes |
| 2 | Pedal de freno | rectángulo horizontal redondeado, rojo `#DD2835` | 180 × 100 | con 3 ranuras horizontales blancas suaves |
| 3 | Pedal de gas | rectángulo vertical redondeado, verde `#3FA34D` | 100 × 180 | con 3 ranuras verticales blancas suaves |
| 4 | Botón de luces | círculo, morado `#3F1B4E` | 120 × 120 | pictograma de faro oro con 3 rayos a la derecha |
| 5 | Botón de cinturón | círculo, azul cielo `#7FC8E8` | 160 × 160 | hebilla de cinturón gris claro con una lengüeta roja, de lado a lado |
| 6 | Moneda | disco oro con contorno `#B07A00` | 44 × 45 | estrella en relieve al centro y un destello |
| 7 | Estrella llena | estrella oro redondeada | 49 × 47 | brillo arriba a la izquierda |
| 8 | Estrella vacía | la misma estrella en `#3F1B4E` | 49 × 47 | contorno un poco más claro, no gris |
| 9 | Engrane | engrane de 8 dientes, gris lila `#BFB0D2` | 92 × 100 | botón secundario: sin labio de color |
| 10-12 | vacías | — | — | dejar transparentes |

**Prompt (SUBJECT):**

```
SUBJECT: a UI icon sheet for a kids' driving game, arranged in a regular grid of
4 columns and 3 rows, one icon per cell, each icon centered and filling about 80%
of its cell, transparent space between cells. All icons share the same glossy
"candy button" construction: rounded shape, thick dark-plum outline (#1E0F26),
body with a soft vertical gradient (12% lighter at the top), a white pill-shaped
gloss at 35% opacity across the top third, and a darker bottom lip like a
physical button. Cells, left to right, top to bottom:
1. a chunky rounded arrow pointing RIGHT, golden yellow (#FFC700);
2. a horizontal rounded-rectangle brake pedal, red (#DD2835), with three soft
   white horizontal grooves;
3. a vertical rounded-rectangle gas pedal, green (#3FA34D), with three soft white
   vertical grooves;
4. a round dark-purple (#3F1B4E) button with a golden headlight pictogram and
   three short light rays pointing right;
5. a round sky-blue (#7FC8E8) button with a car seatbelt buckle seen from the
   front, light-grey metal with a small red release tab;
6. a golden coin with a darker gold rim (#B07A00), an embossed star in the
   center and one sparkle;
7. a chubby rounded golden star with a white highlight at top-left;
8. the same star shape in dark purple (#3F1B4E), empty/unearned look;
9. a lilac-grey (#BFB0D2) settings gear with 8 rounded teeth, no colored lip;
cells 10, 11 and 12 are empty.
```

**Se acepta si:**
- los 9 íconos se ven del mismo set (bisel, contorno y brillo iguales);
- la flecha apunta a la derecha y es simétrica arriba y abajo (se espeja para la izquierda);
- los pictogramas se entienden a 44 px (moneda y estrellas) y a 120 px (botones);
- no hay texto ni letras ("STOP", "GO" ni números).

---

## Ficha 01-B: celular (distracción del nivel 6)

| Campo | Valor |
|---|---|
| Entrega | `celular.png` |
| Lienzo | 1024 × 1536 (vertical), un solo objeto centrado |
| Clase de contorno | **S** |
| Referencias | `hud_iconos.png` (la de 01-A), `auto_jugador.png` |
| Reemplaza | `assets/ui/phone.png`. Tamaño final 168 × 320 (se ve a la mitad) |

**Prompt (SUBJECT):**

```
SUBJECT: a friendly cartoon smartphone seen straight from the front, vertical,
rounded corners, dark-plum body (#3F1B4E) with a soft gloss. The screen is
sky blue (#7FC8E8) and shows ONE big generic green round "incoming call" button
with a white phone-handset pictogram, and two curved vibration lines on each side
of the phone body. No status bar, no app icons, no text, no numbers, no brand.
```

**Se acepta si:** no tiene marca, texto ni hora; el botón verde se entiende como
"te están llamando"; el estilo es el mismo que el de los botones de 01-A.
