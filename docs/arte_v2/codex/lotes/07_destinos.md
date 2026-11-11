# Lote 07: destinos y túnel (P0)

Los destinos son **la meta de cada nivel**: el edificio al que llega el niño. Son
más grandes que una casa y deben reconocerse de un vistazo, **sin letreros**. Lo que
los identifica es la forma y un objeto clave. Encima, el juego pone un ícono flotante.

**Para todo el lote:**
- **Vista:** igual que las casas, con la azotea o el terreno arriba y la fachada abajo.
- **Clase de contorno:** **L**.
- **Referencias:** `casas_a.png` (obligatoria) y `edificios.png`.
- **Lienzo:** 1536 × 1024, **una imagen por destino**.

---

## Ficha 07-A: escuela primaria

| Entrega | `destino_escuela.png` |
|---|---|
| Reemplaza | `assets/sprites/city/escuela.png` (320 × 224) |

**Prompt (SUBJECT):**

```
SUBJECT: a friendly Mexican primary school seen from above with the front facade
at the bottom: an L-shaped two-storey building in warm peach (#F3CFAA) and
terracotta trim, a schoolyard with a basketball court painted on the ground, two
round trees, a small flagpole with an empty pole (no flag), a big iron gate at the
front center. No text, no school name, no flag.
```

## Ficha 07-B: hospital

| Entrega | `destino_hospital.png` |
|---|---|
| Reemplaza | `assets/sprites/city/hospital.png` (300 × 217) |

**Prompt (SUBJECT):**

```
SUBJECT: a friendly small hospital seen from above with the front facade at the
bottom: clean off-white (#F6F1EA) building with sky-blue (#7FC8E8) windows, a big
blue (#2E4DA0) rounded "plus" sign on a round white plaque on the roof (NOT a red
cross), a curved entrance canopy at the front center, and a few parking spaces
with white lines on each side. No text, no letters.
```

## Ficha 07-C: terminal de autobuses (genérica)

| Entrega | `destino_terminal.png` |
|---|---|
| Reemplaza | `assets/sprites/city/terminal.png` (322 × 190) |

**Prompt (SUBJECT):**

```
SUBJECT: a generic small bus terminal seen from above with the front facade at
the bottom: a cream (#F6F1EA) and cantera (#C9BDB4) building with a long curved
turquoise (#3FB8AF) canopy over 4 empty bus bays, small trees in planters at the
corners. NO buses, no red, purple or white-dominant color scheme, no logos, no text.
```

**Restricción ADO:** la terminal no puede recordar a ADO. No lleva autobuses ni
colores rojo, morado o blanco dominante, y no lleva letras.

## Ficha 07-D: túnel en el cerro (nivel 7)

| Entrega | `tunel.png` |
|---|---|
| Lienzo | 1024 × 1024 |
| Reemplaza | `assets/sprites/city/tunel_entrada.png` (253 × 256). La salida `tunel_salida.png` es su espejo horizontal |

**Prompt (SUBJECT):**

```
SUBJECT: a small rounded green hill seen from above at a 3/4 angle, with a road
tunnel entrance: a stone (cantera, #C9BDB4) arch portal on the lower-right side
of the hill, dark inside, the road surface leaving the tunnel toward the
bottom-right. A few small round pine trees on the hill, soft muted greens
(#6FAE5E, #4F7A4A). No text, no signs.
```

**Se acepta si (todo el lote):**
- cada destino se reconoce **sin leer**: escuela por el patio y la reja, hospital por
  el "+" azul, terminal por los andenes techados;
- no hay letras, banderas ni cruces rojas;
- el estilo es el de las casas, un poco más grande y con el mismo contorno.
