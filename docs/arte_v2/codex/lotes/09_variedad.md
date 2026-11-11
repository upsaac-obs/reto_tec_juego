# Lote 09: variedad (P1)

Agrega variedad para que las cuadras no se repitan. **Empiézalo solo con el P0
terminado.**

**Para todo el lote:**
- se usan las mismas reglas y la misma cámara que los lotes base;
- **adjunta como referencia la hoja original de cada categoría**, como indica cada ficha.

---

## Ficha 09-A: casas, segunda hoja

| Campo | Valor |
|---|---|
| Entrega | `casas_b.png` |
| Lienzo y cuadrícula | 1536 × 1024, **3 × 2** |
| Clase de contorno | **S** |
| Referencias | **`casas_a.png` (obligatoria)** |

**Prompt.** Es el mismo de la ficha de casas del piloto (`docs/arte_v2/fichas_piloto.md`,
ficha 2), pero con estas 6 casas y la regla de fachada al 50 %:

```
1. mint (#9CC9A7) facade, green iron window grilles (cancel), small balcony;
2. pastel blue (#9DBFDC) facade, bougainvillea climbing the wall;
3. terracotta (#DA8068) facade, a small talavera niche next to the door;
4. off-white (#F6F1EA) facade, a little corner store with a rolled-up shutter, no sign;
5. ochre (#E2B46A) facade, wooden door with a round iron knocker, potted plants on the roof;
6. lilac (#BFB0D2) facade, garage gate and a water tank with a white parapet.
Every facade starts at exactly half the height of the image, like the attached houses.
```

## Ficha 09-B: destinos poblanos

| Campo | Valor |
|---|---|
| Entregas | `destino_biblioteca.png`, `destino_mercado.png`, `destino_parque.png`, `destino_abuela.png`, `destino_primos.png` |
| Lienzo | 1536 × 1024, uno por imagen |
| Clase de contorno | **L** |
| Referencias | `casas_a.png`, `edificios.png`, `destino_escuela.png` |

| Destino | `SUBJECT` |
|---|---|
| Biblioteca | `a public library with a cantera stone portal of three arches, tall windows and a big round window above the door, a few benches in front. No text.` |
| Mercado | `a neighborhood market with colorful striped awnings, fruit and flower stalls at the front and colorful papel picado (perforated paper flags with simple flower and star cut-outs, no letters) hanging above.` |
| Parque | `a small park with a Puebla-style kiosk (round gazebo with a dome), a talavera fountain, paths, benches and round trees. No text.` |
| Casa de la abuela | `a cozy house fully covered with blue-and-white talavera tiles on the facade, flower pots and a bench by the door.` |
| Casa de los primos | `a mint-green house with a small front garden and a swing hanging from a tree.` |

## Ficha 09-C: más peatones

| Campo | Valor |
|---|---|
| Entregas | `papa_carriola_camina.png`, `joven_camina.png`, `senora_mandado_camina.png` |
| Lienzo y cuadrícula | 1536 × 1024, **4 × 2** (8 cuadros de caminata cada una) |
| Clase de contorno | **XS** |
| Referencias | `nino_camina.png`, `nina_camina.png` |

| Personaje | Descripción |
|---|---|
| Papá con carriola | papá de piel morena con camisa a cuadros; empuja una carriola con capota (no se ve al bebé) |
| Joven | adolescente de piel clara con sudadera menta y audífonos colgados del cuello (no puestos) |
| Señora del mandado | señora de piel morena oscura con delantal de flores y una canasta de mandado |

Se usa el prompt de 03-A con su descripción.

## Ficha 09-D: papel picado

| Campo | Valor |
|---|---|
| Entrega | `papel_picado.png` |
| Lienzo y cuadrícula | 1536 × 1024, **1 × 3** (3 tiras) |
| Clase de contorno | **S** |
| Referencias | `casas_a.png` |

**Prompt (SUBJECT):**

```
SUBJECT: three horizontal strings of Mexican papel picado (perforated paper
flags) seen from the front, one string per row, each with 6 flags in alternating
pink (#E0457B), golden (#FFC700), turquoise (#3FB8AF), lilac and orange, with
simple cut-out shapes (flowers, stars, birds), NO letters or words.
```
