# LEEME, Codex: producción del arte v2 de RutaKids

> **Para Codex.** Lee este archivo completo antes de generar cualquier imagen. Después
> lee `estilo.md` y luego **un lote a la vez** de `lotes/`, en el orden de la tabla §4.
> Si algo no está claro, no lo inventes: anótalo en el reporte (§6) y sigue con lo demás.

---

## 1. Contexto

**RutaKids** es un juego móvil 2D de educación vial para niñas y niños de 4 a 13 años,
hecho para la Fundación ADO (Puebla, México):

- El niño maneja un auto rojo visto desde arriba por una calle horizontal de una
  colonia de Puebla.
- Cada nivel enseña un hábito: cinturón, peatones, señales, mirar dos veces, calma,
  sin prisa, sin celular, luces y compartir el camino.

**Estamos reemplazando todo el pixel art de dentro de los niveles** por un estilo de
caricatura vectorial. El piloto (auto, 6 casas y niño) ya fue aprobado. Es la
referencia de calidad y de estilo:

| Referencia | Archivo (en el repo) |
|---|---|
| Auto del jugador | `arte_v2/entrada/auto_jugador.png` |
| Casas | `arte_v2/entrada/casas_a.png` |
| Personaje (estilo y escala) | `arte_v2/entrada/nino_camina.png` y `nino_sorprendido.png` |

**Qué hace Codex:** solo genera imágenes, según las fichas.

**Qué hace Claude** (no lo hagas tú):
- recortar, reducir y quitar el fondo;
- meter los assets al juego y ajustar el código;
- las calles, banquetas, pasto, azoteas del fondo, flechas del piso, velocímetro e
  insignia de destino: esos se dibujan por código.

> ⛔ **No edites nada fuera de `arte_v2/entrada/`.** Nada de `assets/`, escenas, scripts,
> `docs/` ni configuración.

## 2. Archivos de este paquete

| Archivo | Qué es |
|---|---|
| `LEEME_CODEX.md` | Este archivo: proceso y reglas |
| `estilo.md` | La biblia de arte. Su bloque **STYLE BASE** va al inicio de **cada** prompt, sin cambios |
| `lotes/NN_nombre.md` | Las fichas de cada lote: qué generar, cuadrícula, prompt y criterios de aceptación |
| `manifiesto.json` | La versión para máquina: nombre de cada entrega, lienzo, cuadrícula y destino en el juego. Debe coincidir con las fichas; si ves una diferencia, gana la ficha y lo anotas en el reporte |

## 3. Cómo producir cada ficha (el ciclo)

1. **Lee la ficha completa**: tabla de datos, prompt y "Se acepta si".
2. **Arma el prompt** en este orden:
   1. el bloque **STYLE BASE** de `estilo.md`;
   2. la línea `OUTLINE` con el valor de la clase de tamaño que diga la ficha (XS, S o L);
   3. el texto de `SUBJECT` de la ficha.
3. **Adjunta las referencias** que pida la ficha (columna "Referencias"). Siempre van
   el auto y las casas del piloto; si hay personas, también el niño.
4. **Genera 2 o 3 versiones.**
5. **Revisa cada versión** contra "Se acepta si" y contra la **lista de rechazo
   automático** (§5).
6. **Guarda la mejor** en `arte_v2/entrada/` con el nombre exacto de "Entrega".
   - Las otras versiones van en `arte_v2/entrada/variantes/` con sufijo `_v1`, `_v2`.
   - Si ninguna pasa, guarda la menos mala con sufijo `_REVISAR` y explica por qué en
     el reporte.
7. **Agrega su renglón al reporte** (§6) y pasa a la siguiente ficha.

## 4. Orden de producción

| # | Lote | Prioridad | Entregas |
|---|---|---|---|
| 1 | `lotes/01_hud.md`: botones e íconos del HUD y celular | P0 | 2 |
| 2 | `lotes/02_copiloto.md`: ajolote copiloto (ficha maestra y 8 poses) | P0 | 2 |
| 3 | `lotes/03_peatones.md`: niña, adulto, persona mayor y silla de ruedas | P0 | 7 |
| 4 | `lotes/04_vehiculos.md`: autos de tráfico, bus, ambulancia, moto y ciclista | P0 | 4 |
| 5 | `lotes/05_senales.md`: señales y semáforo peatonal | P0 | 1 |
| 6 | `lotes/06_ciudad.md`: árboles, edificios, mobiliario y parada | P0 | 3 |
| 7 | `lotes/07_destinos.md`: escuela, hospital, terminal y túnel | P0 | 4 |
| 8 | `lotes/08_tarjetas.md`: tarjetas de hábito de los niveles 0-8 | P1 | 9 |
| 9 | `lotes/09_variedad.md`: más casas, destinos poblanos, más peatones y papel picado | P1 | 6 |

Haz todo el P0 antes de empezar el P1. Si el tiempo se acaba, **se recorta variedad, no
se deja pixel art**: es mejor menos versiones que lotes sin hacer.

## 5. Reglas técnicas y rechazo automático

**Reglas para todas las imágenes:**
- **Lienzo:** el que diga la ficha (`1024×1024`, `1536×1024` o `1024×1536`). No hace
  falta el tamaño final del juego: Claude reduce.
- **Fondo:** transparente (PNG con alfa). Solo si no es posible, color plano `#FF00FF`
  sin degradado ni sombra.
- **Cuadrículas:** celdas iguales, **un elemento por celda**, centrado, sin tocar las
  orillas de su celda y con al menos 5 % de margen transparente. El orden es de
  izquierda a derecha y de arriba abajo, como dice la ficha.
- **Animaciones:** todos los cuadros en **una sola imagen**. Es el mismo personaje con la
  misma ropa, el mismo tamaño y los **pies en la misma línea base** en todos los cuadros.
- **Sombras:** no se dibuja sombra en el piso (la pone el juego).
- **Formato:** PNG RGBA y nombres en minúsculas, como dice la ficha.

**Rechazo automático.** No guardes como buena una imagen que tenga:
1. **Cualquier texto, letra o número.** Incluye letreros de tiendas, placas, "ALTO",
   "STOP", "BUS", nombres de escuela y números en las señales.
2. **Logotipos o marcas reales:** autos con logo, la ADO, tiendas reales.
3. **El estilo equivocado:** pixel art, aspecto 3D realista, fotografía o texturas con
   ruido.
4. **Contornos negros puros** o una cámara distinta a la que pide la ficha.
5. **Algo violento, triste o que asuste:** choques, heridas, llanto o caras de enojo.
6. **Cruz roja** (es emblema protegido; los hospitales y ambulancias llevan un "+"
   azul) o un bus o terminal con colores que recuerden a ADO (rojo, morado o blanco
   dominante).
7. **Personajes que se parezcan a personajes conocidos** de juegos, caricaturas o marcas.

## 6. Reporte

Al terminar cada lote, agrega una sección a `arte_v2/entrada/REPORTE.md`:

```markdown
## Lote 03_peatones — 2026-11-12
| Entrega | Estado | Versiones | Notas |
|---|---|---|---|
| nina_camina.png | OK | 3 (elegida v2) | — |
| nina_reacciones.png | REVISAR | 2 | cuadro 3 cambió el peinado |
Dudas para Claude: …
```

Estados: `OK` cumple todo; `REVISAR` tiene un problema conocido; `FALTA` no se pudo generar.
