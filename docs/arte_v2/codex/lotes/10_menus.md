# Lote 10: menús de Android e iOS

Las dos apps (Android con Compose, iOS con SwiftUI) usan **las mismas imágenes**. Este
lote reemplaza el arte de los menús: fondos, botones, íconos de nivel, estrellas,
copiloto de menú y tarjetas de edad. Claude las recorta, las reduce y las copia a
las dos apps (`res/drawable-nodpi/` y `Assets.xcassets`).

**Para todo el lote:**
- Va el STYLE BASE de `estilo.md` y la clase de contorno de cada ficha.
- **Sin texto, letras ni números en ninguna imagen.** Los números de nivel, "Jugar",
  "Salir", las edades, etc. los escribe la app con su fuente (Fredoka), porque cambian
  con el idioma y la accesibilidad los lee.
- **Nada de ADO:** ni logo, ni autobús, ni terminal, ni letreros con marca. Sí su paleta:

  | Uso | Color |
  |---|---|
  | Fondo de botones | morado oscuro `#3F1B4E` |
  | Aros, brillos, botón principal | amarillo dorado `#FFC700` |
  | Detalles y bordes de alerta | rojo `#DD2835` |
  | Íconos sobre morado | blanco `#FFFFFF` |
  | Cielo, de arriba a abajo | `#4A235A` → `#9C4B79` → `#E86F56` |

- **Referencias en todas las llamadas:** `copiloto_maestra.png`, `auto_jugador.png`,
  `casas_a.png` y `hud_iconos.png`. Los botones deben verse de la misma familia que los
  pedales y flechas del HUD (lote 01, botón "caramelo").
- **Cámara:** los botones, íconos y estrellas van **de frente**, como el HUD. Los fondos
  y las tarjetas de edad son **postales** en 3/4, como las tarjetas de hábito (lote 08).

## Ficha 10-A: fondo de Inicio

| Campo | Valor |
|---|---|
| Entrega | `fondo_inicio.png` |
| Lienzo | 1536 × 1024, opaco (sin transparencia) |
| Clase de contorno | **L** |

Los celulares lo recortan entre 16:9 y 20:9: **todo lo importante va en la franja
central, entre y = 180 y y = 840**. El centro queda libre para el botón Jugar y la
franja de arriba (y < 150) libre para la barra de estrellas.

```
SUBJECT: a cheerful postcard view at sidewalk height of a colorful street in Puebla,
Mexico, at golden hour. The sky is a smooth vertical gradient from deep purple
(#4A235A) at the top through magenta-plum (#9C4B79) to warm coral (#E86F56) at the
horizon, with a few soft rounded clouds. In the distance, a snowy volcano silhouette
and a low skyline of colorful colonial houses with talavera tiles and iron balconies.
In the lower-left third, the attached red car parked by the sidewalk, and the attached
axolotl co-pilot standing next to it waving hello. The center of the image is calm
and empty (open street and sky) for a big round button that the app places on top.
Soft, slightly muted colors in the buildings so the button stands out. No text, no
signs with letters, no buses, no logos.
```

## Ficha 10-B: fondo de los demás menús

| Campo | Valor |
|---|---|
| Entrega | `fondo_menus.png` |
| Lienzo | 1536 × 1024, opaco |
| Clase de contorno | **L** |

Es el fondo de Selección de edad, Selección de niveles y Tutores. Encima van tarjetas
y una cuadrícula de 9 niveles, así que debe ser **muy tranquilo**.

```
SUBJECT: the same street and sky as the attached Inicio background, but simpler and
calmer: mostly sky with the same purple-to-coral gradient and a few soft clouds, and
only a low, slightly blurred band of colorful houses and the volcano along the bottom
fifth. No car, no characters, nothing in the center. No text, no logos.
```

Adjunta también `fondo_inicio.png` como referencia para que sea el mismo lugar.

## Ficha 10-C: botones

| Campo | Valor |
|---|---|
| Entrega | `botones.png` |
| Lienzo y cuadrícula | 1536 × 1024, **3 × 2** (un botón por celda, centrado, con margen) |
| Clase de contorno | **S** |
| Fondo | transparente (o magenta `#FF00FF` plano si falla la transparencia) |

| Celda | Botón | Descripción |
|---|---|---|
| 1 | Jugar | botón **grande y redondo** dorado `#FFC700` con un triángulo de "play" morado `#3F1B4E` al centro, aro rojo `#DD2835` delgado |
| 2 | Regresar | botón redondo morado con una flecha gruesa hacia la izquierda en blanco |
| 3 | Salir | botón redondo morado con una puerta entreabierta y una flechita saliendo, en blanco |
| 4 | Sonido encendido | botón redondo morado con una bocina y dos ondas, en blanco |
| 5 | Sonido apagado | el mismo botón de la celda 4, con la bocina sin ondas y una pequeña "x" redondeada |
| 6 | Tutores | botón redondo morado con un engrane blanco |

```
SUBJECT: a sheet of 6 glossy "candy" game buttons seen straight from the front, one
per cell in a 3x2 grid, exactly like the attached HUD buttons: chunky, inflated,
with a soft top-left highlight, a thin golden (#FFC700) rim and a darker purple
bottom edge that makes them look pressable. {LISTA DE LA TABLA}. Simple bold white
pictograms, no text, no letters, no numbers.
```

## Ficha 10-D: pictogramas de las paradas del mapa

| Campo | Valor |
|---|---|
| Entrega | `pictogramas.png` |
| Lienzo y cuadrícula | 1536 × 1536, **3 × 3** (nivel 0 arriba a la izquierda, nivel 8 abajo a la derecha) |
| Clase de contorno | **XS** (se ven a unos 40 px) |
| Fondo | transparente (o magenta plano) |

La selección de niveles es un mapa: cada nivel es una parada con un **letrero redondo
de talavera** (aro azul con puntos blancos y centro blanco). El letrero lo dibuja el
juego; Codex solo hace **el dibujo que va en el centro blanco**. Por eso:

- cada dibujo cabe en un **círculo** (que no se salga de él) y **no lleva fondo, placa ni aro**;
- es **muy simple y grande**: una sola idea, máximo 2 o 3 formas, que se entienda a 40 px;
- colores vivos que contrasten con el blanco; contorno morado oscuro `#1E0F26`;
- **nada que dé miedo**: caras siempre sonrientes, ojos amables, nada de miradas fijas;
- sin texto, letras ni números.

| Celda | Nivel (hábito) | Dibujo |
|---|---|---|
| 0 | Abróchate y arranca | la hebilla del cinturón cerrándose, con un destello |
| 1 | Primero el peatón | un niño sonriente con mochila caminando sobre tres rayas de paso de cebra |
| 2 | Respeta las señales | una señal octagonal roja **sin letras**, con un pequeño semáforo en rojo al lado |
| 3 | Mira dos veces | **el copiloto ajolote** (adjunta `copiloto_maestra.png`) sonriendo, con la mano en la frente como visera, mirando a un lado, y dos flechitas curvas a izquierda y derecha |
| 4 | Con calma | una abuelita sonriente con bastón, caminando tranquila |
| 5 | Sin prisa | un caracol sonriente con un casquito |
| 6 | Ojos en el camino | un teléfono boca abajo con una lunita de "silencio" |
| 7 | Hazte visible | el frente del auto rojo con los faros encendidos y dos haces de luz cálida |
| 8 | Comparte el camino | un niño sonriente en bicicleta, con casco |

```
SUBJECT: a 3x3 sheet of 9 simple, friendly pictograms for a kids' road-safety game,
one per cell, each fitting inside a circle, seen from the front, no background,
no frame, no badge: {LISTA DE LA TABLA, en orden}. Very simple bold shapes readable
at 40 pixels, bright colors that contrast on white, dark purple outline, every face
smiling and kind. No text, no letters, no numbers.
```

## Ficha 10-E: estrellas y candado

| Campo | Valor |
|---|---|
| Entrega | `estrellas.png` |
| Lienzo y cuadrícula | 1536 × 512, **3 × 1** |
| Clase de contorno | **S** |

Celdas: **1** estrella llena dorada `#FFC700` brillante, **2** la misma estrella vacía
(morado claro translúcido con contorno morado), **3** un candado dorado redondeado
(para los niveles bloqueados). Mismo estilo que la estrella y la moneda de `hud_iconos.png`.

```
SUBJECT: 3 game icons seen from the front, one per cell: a chunky glossy golden star,
the same star empty (pale translucent purple fill with a purple outline), and a
rounded golden padlock. Exactly the style of the star in the attached HUD icons.
No text.
```

## Ficha 10-F: copiloto de menú

| Campo | Valor |
|---|---|
| Entrega | `copiloto_menu.png` |
| Lienzo y cuadrícula | 1536 × 1024, **3 × 1** |
| Clase de contorno | **S** |
| Referencia | **`copiloto_maestra.png` (obligatoria)**: mismo personaje, misma gorra y mismos colores |

Celdas: **1** saludando con la mano en alto, **2** celebrando con los brazos arriba y
estrellitas alrededor, **3** señalando hacia la derecha con una sonrisa (para indicar
botones). Cuerpo entero, de frente.

## Ficha 10-G: tarjetas de edad

| Campo | Valor |
|---|---|
| Entregas | `edad_peque.png` y `edad_grande.png` |
| Lienzo | 1024 × 1024 cada una, opaco |
| Clase de contorno | **L** |

Van dentro de las dos tarjetas grandes de Selección de edad; la app escribe "Peque 4-7"
y "Grande 8-13" abajo, así que el **tercio de abajo** debe ser tranquilo.

```
Peque: SUBJECT: a happy little child (about 5 years old) sitting in the attached red
car with the attached axolotl co-pilot hugging them, big smiles, simple soft
background of the same purple-to-coral sky. No text.

Grande: SUBJECT: a confident child (about 11 years old) at the wheel of the attached
red car, hands at the wheel and seatbelt on, the axolotl co-pilot giving a thumbs up
from the passenger seat, same sky background. No text.
```

## Ficha 10-H (opcional): ícono de la app

| Campo | Valor |
|---|---|
| Entrega | `icono_app.png` |
| Lienzo | 1024 × 1024, opaco |
| Clase de contorno | **L** |

El auto rojo de frente en 3/4 con el copiloto asomado por la ventana, sobre un fondo
morado `#3F1B4E` con un círculo dorado detrás. Todo lo importante dentro del círculo
central del 66 % (Android recorta el ícono en círculo o en gota). Sin texto.

## Orden y entrega

Prioridad: **10-C, 10-E, 10-A, 10-F, 10-G, 10-B** (ya entregadas) y después **10-D**
(pictogramas del mapa, `docs/plan_menus_mapa.md`). La 10-H es opcional. Las reglas de entrega son las mismas de los lotes anteriores: guarda en
`arte_v2/entrada/`, con versiones en `variantes/`, `_REVISAR` si algo no cumple, y
anótalo en `REPORTE.md`.

**Se acepta si:**
- no hay ninguna letra, número ni logo;
- los botones se ven de la misma familia que los del HUD;
- los 9 pictogramas caben en un círculo, se distinguen entre sí a 40 px y ninguno da miedo;
- el centro de los fondos queda libre.
