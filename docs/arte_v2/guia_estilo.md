# Guía de estilo: arte v2 de los niveles

Reemplaza el pixel art **solo dentro de los niveles** de Godot. Los menús nativos
(iOS y Android) no cambian.

Esta guía va **pegada al inicio de cada pedido a Codex** (el bloque "Estilo base",
§2) para que todas las imágenes salgan del mismo mundo. Primero se hace el piloto
(`fichas_piloto.md`). Si el estilo gusta, se escriben las fichas del resto.

---

## 1. La idea en una frase

**Una ciudad de Puebla de juguete, vista desde arriba, dibujada como caricatura
vectorial para niños**: formas redondas y "gorditas", colores vivos, degradados
suaves y cero agresividad. El niño debe reconocer en un segundo **su auto, el
semáforo y al peatón**. Todo lo demás es fondo y se ve más tranquilo.

Referencia de sensación: los juegos infantiles en Flash de los 2000 (caricatura
vectorial con degradados). **No** se nombra ningún juego en los prompts: la IA copia
personajes o estilos con dueño, y este juego se presenta en público con la
Fundación ADO.

## 2. Estilo base (se pega en cada prompt, sin cambios)

```
STYLE: vector cartoon illustration for a kids' mobile game (ages 4-13), clean
Flash-era vector look. Rounded, chunky, slightly inflated shapes with no sharp
corners. Bright, saturated but friendly colors. Soft linear gradients on large
surfaces (light at top-left, darker at bottom-right). One flat cel-shadow tone per
surface. Outlines 3-4 px at 512 px scale, using a darker shade of the object's own
color (never pure black). Small white glossy highlights on glass, metal and
plastic. No texture noise, no pixel art, no photorealism, no 3D render, no text,
no letters, no logos, no watermark.
CAMERA: orthographic top-down view of a toy town, light from the top-left.
BACKGROUND: fully transparent (PNG with alpha). No ground, no drop shadow baked in.
SETTING: a colorful neighborhood in Puebla, Mexico.
```

## 3. Cámara y orientación (no cambian; el código depende de esto)

| Tipo | Vista | Hacia dónde mira |
|---|---|---|
| Vehículos | Cenital pura: se ve el techo | **Frente hacia la derecha** (→) |
| Casas y edificios | Cenital con **el frente visible abajo**: azotea arriba y fachada con puerta abajo, como hoy | La fachada mira hacia abajo |
| Personas | **De pie, vistas de frente-perfil (3/4)**, no desde arriba; así se les ve la cara | Caminan **hacia la derecha** |
| Árboles y objetos | Cenital con un poco de frente (copa redonda y algo de tronco) | — |

## 4. Paleta

Son los colores oficiales del juego (`autoload/game_state.gd`). Hay que usarlos como
base y se permiten tonos intermedios entre ellos. No se inventan colores
fluorescentes.

| Uso | Color |
|---|---|
| Auto del jugador, acentos | Rojo `#DD2835` |
| Contornos más oscuros | Morado `#3F1B4E`, `#1E0F26` |
| Estrellas, monedas, rayas | Oro `#FFC700` |
| Vidrios | Azul cielo `#7FC8E8` |
| Fachadas (variedad) | Rosa mexicano `#E0457B`, ocre `#E3A548`, talavera `#2E4DA0`, lila `#B8A6CC`, durazno `#F8C99B`, ladrillo `#B5523B`, blanco `#FFFFFF`, terracota `#E86F56` |
| Vegetación | `#3FA34D`, `#2B6B3F`, `#7CC56B` |
| Banqueta (cantera) | `#C9BDB4`, juntas `#968A85` |
| Piel (variedad obligatoria) | `#F2C29B`, `#C68B59`, `#8A5A3B` |

**Jerarquía de saturación.** Los personajes, vehículos y señales van **más
saturados** que las casas y la vegetación. El fondo nunca le gana al auto ni al
semáforo.

## 5. Variedad (regla del proyecto)

La ciudad no debe verse copiada y pegada. Cada categoría tiene un **mínimo de
variantes**, y conviene **generar de más** y quedarse con las mejores:

| Categoría | Hoy | Mínimo v2 | Pedir a Codex |
|---|---|---|---|
| Casas | 4 | 8 | 12 |
| Edificios | 3 | 5 | 8 |
| Árboles y plantas | 4 | 8 | 10 |
| Autos de tráfico | 1 | 5 colores y 3 formas | 8 |
| Peatones (personajes distintos) | 5 | 8 | 10 |
| Objetos de banqueta (puesto, poste, banca, bote) | 0 | 6 | 8 |

**Cómo variar sin romper el estilo.** Hay que cambiar **forma, color y detalles**,
y mantener fijos el trazo, la luz, la escala y la cámara. En las casas eso
significa:

- otra silueta (uno o dos pisos, azotea plana o con tejado de lámina);
- otro color de fachada;
- otra cosa en la azotea (tinaco, tendedero, macetas, tragaluz, antena,
  impermeabilizante rojo);
- otra puerta: zaguán, cortina de tienda o portón.

**Personas.** Tienen que variar el tono de piel, la complexión, la edad, la ropa y
el peinado. Hay que incluir siempre una niña y un niño, una persona mayor y una
persona en silla de ruedas. La ropa es la de diario en México; nada de uniformes
de marca.

## 6. Reglas técnicas para quien genera

1. **Tamaño de generación.** Se genera en grande (1024 o 1536 px) y **yo lo reduzco**
   al tamaño exacto con `tools/art/`. No hace falta generar al tamaño final.
2. **Fondo transparente siempre.** Si Codex no puede, que el fondo sea un color
   plano `#FF00FF` (magenta) y yo lo quito.
3. **Hojas con varios elementos.** Van en una **cuadrícula regular** con espacio
   transparente entre cada uno. Nada se toca ni se corta en la orilla.
4. **Animaciones.** Se generan **todos los cuadros en una sola imagen** (una tira o
   una cuadrícula), para que sea el mismo personaje. Los pies de todos los cuadros
   van **a la misma altura**.
5. **Sin sombra dibujada en el piso.** La sombra la pone el juego con código, igual
   para todos.
6. **Sin texto ni letras.** Nada que diga "ADO", ni logotipos, marcas o placas.
7. **Nombre del archivo.** El que dice la ficha, para que el script lo encuentre.
   Va en `arte_v2/entrada/`.

## 7. Cómo entra al juego (lo hace Claude)

- Cada PNG se recorta a su contenido, se escala al tamaño de la ficha y se guarda
  **con el mismo nombre y tamaño** que el asset actual. Así el código no cambia.
- `project.godot` pasa el filtro de texturas de *Nearest* (pixel) a *Linear*.
- Se prueba `window/stretch/mode = canvas_items`, para que en el teléfono se
  dibuje a resolución real y no se vea borroso. Si se ve bien, el arte puede
  subir a 2× después.
- Las luces del auto (direccionales, frenos, faros) se dibujan con código encima
  del sprite. Después de integrar se ajusta su posición para que caigan sobre las
  calaveras y los faros del dibujo nuevo.
- Todo vive en la rama `feature/arte-v2` y entra a `main` solo cuando esté completo
  y con las 511 pruebas pasando.

## 8. Qué se rechaza

- Pixel art o bordes dentados.
- Texturas realistas (asfalto con grano, ladrillos fotográficos).
- Contornos negros gruesos tipo cómic.
- Perspectiva distinta a la de la tabla §3.
- Algo violento, triste o que asuste: choques, heridos, sangre, caras de enojo.
- Logotipos, texto, marcas o el autobús o la terminal de ADO.
- Personajes que se parezcan a personajes conocidos.
