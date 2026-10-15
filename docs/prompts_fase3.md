# RutaKids — prompts de la fase 3 (más assets)

Cada bloque es un prompt completo para UNA imagen: cópialo entero y pégalo en el generador (Gemini). Guarda el resultado en `~/claude/assest2/` y avísale a Claude para importarlo con `tools/import_sprites.py`.

No gastan créditos de Pixel Engine. Si algo se quiere animado (perrito que mueve la cola, palomas que vuelan, sirena), eso sí es Pixel Engine y hay que avisar el costo antes.

| # | Asset | Para qué | Prioridad |
|---|---|---|---|
| 1 | Calle definitiva | Todos los niveles | Alta |
| 2 | Destinos | Niveles 0, 2 y 3 | Alta |
| 3 | Pelota, reloj, lluvia y noche | Niveles 5 y 7 | Alta |
| 4 | Ciclista de noche | Nivel 7 | Alta |
| 5 | Más vehículos | Tráfico y autos estacionados | Media |
| 6 | Vida en la banqueta | Decoración | Media |
| 7 | Lugares de Puebla | Centro (niveles 8 a 10) | Media |
| 8 | Papel picado | Decoración | Baja |

Pendientes de antes (`docs/prompts_assets.md` y `docs/prompts_fase2.md`): botón de luces e iconos de pausa (#16), tiles de cruce y edificios de esquina.

## 1. Calle definitiva — `assets/tiles/street_tiles.png`

Reemplaza `street_provisional.png`. Es lo que más se ve en pantalla, así que es lo que más cambia el juego. Un carril mide 64 px.

```text
Necesito pixel art para un juego de manejo para niñas y niños de 4 a 13 años,
ambientado en una ciudad mexicana (Puebla), estilo tierno y amable.

FORMATO
- PNG. Fondo sólido color #FF00FF (magenta). Sin cuadrícula, sin fondo a
  cuadros, sin bordes ni líneas entre cuadros, sin texto, letras ni números,
  sin marcas de agua.
- Pixel art real: cada píxel del arte es un bloque cuadrado del mismo tamaño
  en toda la imagen. Si la imagen se agranda, que sea un múltiplo exacto
  (×2, ×4, ×8) del tamaño pedido.
- Si hay varios cuadros o piezas: exactamente las columnas y filas pedidas,
  todos los cuadros del mismo tamaño, separados por fondo magenta.

ESTILO
- Contorno oscuro de 1 px color #1E0F26. Luz desde arriba a la izquierda,
  sombreado de 2 tonos, sin degradados, sin antialiasing, sin brillos difusos.
- Colores permitidos (solo estos): #DD2835 #3F1B4E #FFC700 #FFFFFF #4A235A
  #9C4B79 #E86F56 #534A5E #1E0F26 #2A2230 #B8A6CC #F8C99B #3FA34D #2B6B3F
  #7FC8E8 #F2C29B #C68B59 #8A5A3B
- Nada del logo, los camiones ni las terminales de la marca ADO.

OBJETO: hoja de tiles de calle vistos desde ARRIBA (vista cenital, como un
mapa). Exactamente 4 columnas × 2 filas, cada cuadro de 64 × 64 px. Cada tile
llena su cuadro completo (sin fondo magenta dentro del cuadro) para que se
peguen sin huecos, y los bordes izquierdo y derecho de cada tile coinciden
para repetirse en una calle horizontal.
Colores base: asfalto #534A5E con puntitos sueltos #2A2230; banqueta #B8A6CC
con una cuadrícula punteada #9C4B79 cada 32 px; guarnición blanca #FFFFFF de
6 px con una línea #1E0F26 de 2 px del lado del asfalto.
Fila 1:
1. Asfalto liso.
2. Asfalto con línea de carril blanca #FFFFFF discontinua de 4 px pegada al
   borde de arriba (rayas de 24 px y huecos de 8 px).
3. Asfalto con doble línea central amarilla #FFC700 (dos líneas de 3 px)
   pegada al borde de arriba.
4. Paso peatonal (cebra): franjas blancas #FFFFFF verticales de 8 px con
   huecos de 8 px, de borde a borde.
Fila 2:
5. Línea de alto: asfalto con una franja blanca #FFFFFF vertical de 8 px
   pegada al borde derecho.
6. Ciclovía: tile verde #3FA34D con una bicicleta pintada en blanco #FFFFFF
   en el centro y una línea blanca de 4 px en el borde de abajo.
7. Banqueta con guarnición abajo (la guarnición ocupa los últimos 8 px).
8. Banqueta con guarnición arriba (la guarnición ocupa los primeros 8 px).
```

## 2. Destinos de los niveles — `assets/sprites/city/destinos.png`

Cada nivel termina en un lugar. Hoy faltan el parque (nivel 0) y el mercado (nivel 2), y el nivel 3 todavía no tiene destino: la biblioteca y la casa de la abuela son las opciones.

```text
Necesito pixel art para un juego de manejo para niñas y niños de 4 a 13 años,
ambientado en una ciudad mexicana (Puebla), estilo tierno y amable.

FORMATO
- PNG. Fondo sólido color #FF00FF (magenta). Sin cuadrícula, sin fondo a
  cuadros, sin bordes ni líneas entre cuadros, sin texto, letras ni números,
  sin marcas de agua.
- Pixel art real: cada píxel del arte es un bloque cuadrado del mismo tamaño
  en toda la imagen. Si la imagen se agranda, que sea un múltiplo exacto
  (×2, ×4, ×8) del tamaño pedido.
- Si hay varios cuadros o piezas: exactamente las columnas y filas pedidas,
  todos los cuadros del mismo tamaño, separados por fondo magenta.

ESTILO
- Contorno oscuro de 1 px color #1E0F26. Luz desde arriba a la izquierda,
  sombreado de 2 tonos, sin degradados, sin antialiasing, sin brillos difusos.
- Colores permitidos (solo estos): #DD2835 #3F1B4E #FFC700 #FFFFFF #4A235A
  #9C4B79 #E86F56 #534A5E #1E0F26 #2A2230 #B8A6CC #F8C99B #3FA34D #2B6B3F
  #7FC8E8 #F2C29B #C68B59 #8A5A3B
- Nada del logo, los camiones ni las terminales de la marca ADO.

OBJETOS: 4 lugares de una ciudad mexicana colonial (Puebla) vistos en vista
CENITAL (desde arriba, se ve el techo), con una sombra #2A2230 de 6 px hacia
abajo y a la derecha. Exactamente 4 columnas × 1 fila, cada cuadro de
192 × 192 px. La entrada de cada lugar mira hacia ABAJO (ahí está la calle).
1. PARQUE: pasto #3FA34D con caminos #F8C99B en cruz, una fuente redonda
   #B8A6CC con agua #7FC8E8 en el centro, 4 árboles #2B6B3F, bancas #8A5A3B y
   juegos infantiles (resbaladilla #DD2835 y columpio #FFC700).
2. MERCADO: techo de lámina en dos aguas #E86F56 con franjas #C68B59, y al
   frente 4 puestos con toldos a rayas (#DD2835/#FFFFFF, #FFC700/#FFFFFF,
   #3FA34D/#FFFFFF, #9C4B79/#FFFFFF) con cajas de frutas de colores.
3. BIBLIOTECA: edificio colonial con techo plano #F8C99B, pretil de 6 px
   #FFFFFF, un patio central con un árbol y una banca, y escalones #B8A6CC en
   la entrada.
4. CASA DE LA ABUELA: casa de un piso con techo de teja #E86F56, patio con
   macetas #C68B59 llenas de flores #DD2835 y #FFC700, un tendedero con ropa
   de colores y un gato #F8C99B dormido en la azotea.
```

## 3. Objetos del nivel 5 y del clima — `assets/sprites/props/eventos.png`

La pelota que sale a la calle (nivel 5), el reloj del modo Grande (nivel 5) y lo que se necesita para la lluvia y la noche (nivel 7). La pelota se hace rodar girándola en Godot.

```text
Necesito pixel art para un juego de manejo para niñas y niños de 4 a 13 años,
ambientado en una ciudad mexicana (Puebla), estilo tierno y amable.

FORMATO
- PNG. Fondo sólido color #FF00FF (magenta). Sin cuadrícula, sin fondo a
  cuadros, sin bordes ni líneas entre cuadros, sin texto, letras ni números,
  sin marcas de agua.
- Pixel art real: cada píxel del arte es un bloque cuadrado del mismo tamaño
  en toda la imagen. Si la imagen se agranda, que sea un múltiplo exacto
  (×2, ×4, ×8) del tamaño pedido.
- Si hay varios cuadros o piezas: exactamente las columnas y filas pedidas,
  todos los cuadros del mismo tamaño, separados por fondo magenta.

ESTILO
- Contorno oscuro de 1 px color #1E0F26. Luz desde arriba a la izquierda,
  sombreado de 2 tonos, sin degradados, sin antialiasing, sin brillos difusos.
- Colores permitidos (solo estos): #DD2835 #3F1B4E #FFC700 #FFFFFF #4A235A
  #9C4B79 #E86F56 #534A5E #1E0F26 #2A2230 #B8A6CC #F8C99B #3FA34D #2B6B3F
  #7FC8E8 #F2C29B #C68B59 #8A5A3B
- Nada del logo, los camiones ni las terminales de la marca ADO.

OBJETOS: hoja de objetos sueltos. Exactamente 4 columnas × 2 filas, cada
cuadro de 64 × 64 px, cada objeto centrado en su cuadro.
Fila 1 (vista CENITAL, desde arriba):
1. Pelota de juguete de 28 px: gajos #DD2835, #FFFFFF y #FFC700.
2. Charco de lluvia de 56 × 32 px: #7FC8E8 con borde #534A5E y un reflejo
   #FFFFFF.
3. Farola vista desde arriba: base #534A5E de 10 px y un círculo de luz
   #F8C99B de 48 px alrededor (sin degradado: 2 anillos de color plano).
4. Cono de obra naranja #E86F56 con franja #FFFFFF, visto desde arriba.
Fila 2 (vista FRONTAL, iconos de interfaz brillantes):
5. Reloj despertador #DD2835 con campanas #FFC700 y carátula #FFFFFF, sin
   números (solo dos manecillas #1E0F26).
6. Gota de lluvia #7FC8E8 con brillo #FFFFFF.
7. Luna creciente #F8C99B con dos estrellitas #FFC700.
8. Chaleco reflejante #FFC700 con dos franjas #FFFFFF.
```

## 4. Ciclista de noche — `assets/sprites/vehicles/cyclist_night.png`

Para el nivel 7 ("aparecen ciclistas con casco y reflejantes"). Mismo formato que `cyclist1.jpg`, que salió muy bien: pásale esa imagen como referencia.

```text
Necesito pixel art para un juego de manejo para niñas y niños de 4 a 13 años,
ambientado en una ciudad mexicana (Puebla), estilo tierno y amable.

FORMATO
- PNG. Fondo sólido color #FF00FF (magenta). Sin cuadrícula, sin fondo a
  cuadros, sin bordes ni líneas entre cuadros, sin texto, letras ni números,
  sin marcas de agua.
- Pixel art real: cada píxel del arte es un bloque cuadrado del mismo tamaño
  en toda la imagen. Si la imagen se agranda, que sea un múltiplo exacto
  (×2, ×4, ×8) del tamaño pedido.
- Si hay varios cuadros o piezas: exactamente las columnas y filas pedidas,
  todos los cuadros del mismo tamaño, separados por fondo magenta.

ESTILO
- Contorno oscuro de 1 px color #1E0F26. Luz desde arriba a la izquierda,
  sombreado de 2 tonos, sin degradados, sin antialiasing, sin brillos difusos.
- Colores permitidos (solo estos): #DD2835 #3F1B4E #FFC700 #FFFFFF #4A235A
  #9C4B79 #E86F56 #534A5E #1E0F26 #2A2230 #B8A6CC #F8C99B #3FA34D #2B6B3F
  #7FC8E8 #F2C29B #C68B59 #8A5A3B
- Nada del logo, los camiones ni las terminales de la marca ADO.

OBJETO: ciclista visto exactamente desde ARRIBA (vista cenital), con casco
#FFC700 con franja #DD2835 (igual a la imagen de referencia), pero con un
chaleco reflejante #FFC700 con dos franjas #FFFFFF, una luz delantera
#FFFFFF y una luz trasera #DD2835 en la bicicleta #3FA34D.
Exactamente 6 columnas × 2 filas, cada cuadro de 96 × 96 px.
Fila 1: pedaleando hacia ARRIBA, 6 cuadros de un ciclo de pedaleo (las
rodillas suben y bajan, el cuerpo no se mueve de lugar).
Fila 2: lo mismo pedaleando hacia ABAJO.
```

## 5. Más vehículos — `assets/sprites/vehicles/mas_vehiculos.png`

Más variedad para el tráfico y los autos estacionados (hoy todo el tráfico es el mismo auto pintado de distintos colores). Tamaño parecido a `npc_car.png` (70 × 38 px).

```text
Necesito pixel art para un juego de manejo para niñas y niños de 4 a 13 años,
ambientado en una ciudad mexicana (Puebla), estilo tierno y amable.

FORMATO
- PNG. Fondo sólido color #FF00FF (magenta). Sin cuadrícula, sin fondo a
  cuadros, sin bordes ni líneas entre cuadros, sin texto, letras ni números,
  sin marcas de agua.
- Pixel art real: cada píxel del arte es un bloque cuadrado del mismo tamaño
  en toda la imagen. Si la imagen se agranda, que sea un múltiplo exacto
  (×2, ×4, ×8) del tamaño pedido.
- Si hay varios cuadros o piezas: exactamente las columnas y filas pedidas,
  todos los cuadros del mismo tamaño, separados por fondo magenta.

ESTILO
- Contorno oscuro de 1 px color #1E0F26. Luz desde arriba a la izquierda,
  sombreado de 2 tonos, sin degradados, sin antialiasing, sin brillos difusos.
- Colores permitidos (solo estos): #DD2835 #3F1B4E #FFC700 #FFFFFF #4A235A
  #9C4B79 #E86F56 #534A5E #1E0F26 #2A2230 #B8A6CC #F8C99B #3FA34D #2B6B3F
  #7FC8E8 #F2C29B #C68B59 #8A5A3B
- Nada del logo, los camiones ni las terminales de la marca ADO.

OBJETOS: vehículos vistos exactamente desde ARRIBA (vista cenital), con el
frente hacia la DERECHA. Exactamente 4 columnas × 1 fila, cada cuadro de
128 × 64 px, cada vehículo centrado.
1. Taxi pequeño de 72 × 38 px: blanco #FFFFFF con franja #DD2835 a lo largo
   y un letrerito #FFC700 en el techo (sin letras).
2. Vochito (escarabajo clásico) de 64 × 36 px: #7FC8E8 con techo redondo.
3. Camioneta de reparto de 96 × 44 px: caja #FFFFFF y cabina #3FA34D.
4. Camión de basura de 112 × 48 px: cabina #3FA34D y caja #534A5E con
   franjas #FFC700.
```

## 6. Vida en la banqueta — `assets/sprites/props/banqueta.png`

Decoración para que la ciudad se sienta viva y poblana. Solo adornan: no tienen reglas.

```text
Necesito pixel art para un juego de manejo para niñas y niños de 4 a 13 años,
ambientado en una ciudad mexicana (Puebla), estilo tierno y amable.

FORMATO
- PNG. Fondo sólido color #FF00FF (magenta). Sin cuadrícula, sin fondo a
  cuadros, sin bordes ni líneas entre cuadros, sin texto, letras ni números,
  sin marcas de agua.
- Pixel art real: cada píxel del arte es un bloque cuadrado del mismo tamaño
  en toda la imagen. Si la imagen se agranda, que sea un múltiplo exacto
  (×2, ×4, ×8) del tamaño pedido.
- Si hay varios cuadros o piezas: exactamente las columnas y filas pedidas,
  todos los cuadros del mismo tamaño, separados por fondo magenta.

ESTILO
- Contorno oscuro de 1 px color #1E0F26. Luz desde arriba a la izquierda,
  sombreado de 2 tonos, sin degradados, sin antialiasing, sin brillos difusos.
- Colores permitidos (solo estos): #DD2835 #3F1B4E #FFC700 #FFFFFF #4A235A
  #9C4B79 #E86F56 #534A5E #1E0F26 #2A2230 #B8A6CC #F8C99B #3FA34D #2B6B3F
  #7FC8E8 #F2C29B #C68B59 #8A5A3B
- Nada del logo, los camiones ni las terminales de la marca ADO.

OBJETOS: hoja de objetos de banqueta vistos en vista CENITAL (desde arriba),
con sombra #2A2230 de 3 px hacia abajo y a la derecha. Exactamente 4 columnas
× 2 filas, cada cuadro de 64 × 64 px, cada objeto centrado.
Fila 1:
1. Banca de parque #8A5A3B.
2. Bote de basura #3FA34D con tapa.
3. Maceta grande de talavera (#FFFFFF y #4A235A) con una planta #3FA34D.
4. Perrito #C68B59 echado, dormido, enroscado.
Fila 2:
5. Carrito de elotes: carrito #FFFFFF con sombrilla a rayas #DD2835 y
   #FFFFFF (la sombrilla tapa casi todo, vista desde arriba).
6. Puesto de dulces típicos con toldo #9C4B79 y dulces de colores.
7. Vendedor de globos: racimo de 6 globos de colores (#DD2835, #FFC700,
   #7FC8E8, #3FA34D, #E86F56, #9C4B79) vistos desde arriba.
8. Tres palomas #B8A6CC picoteando.
```

## 7. Lugares de Puebla — `assets/sprites/city/puebla.png`

Edificios con identidad poblana para el centro de la ciudad (niveles 8, 9 y 10). Genéricos: que recuerden a Puebla sin copiar un edificio real.

```text
Necesito pixel art para un juego de manejo para niñas y niños de 4 a 13 años,
ambientado en una ciudad mexicana (Puebla), estilo tierno y amable.

FORMATO
- PNG. Fondo sólido color #FF00FF (magenta). Sin cuadrícula, sin fondo a
  cuadros, sin bordes ni líneas entre cuadros, sin texto, letras ni números,
  sin marcas de agua.
- Pixel art real: cada píxel del arte es un bloque cuadrado del mismo tamaño
  en toda la imagen. Si la imagen se agranda, que sea un múltiplo exacto
  (×2, ×4, ×8) del tamaño pedido.
- Si hay varios cuadros o piezas: exactamente las columnas y filas pedidas,
  todos los cuadros del mismo tamaño, separados por fondo magenta.

ESTILO
- Contorno oscuro de 1 px color #1E0F26. Luz desde arriba a la izquierda,
  sombreado de 2 tonos, sin degradados, sin antialiasing, sin brillos difusos.
- Colores permitidos (solo estos): #DD2835 #3F1B4E #FFC700 #FFFFFF #4A235A
  #9C4B79 #E86F56 #534A5E #1E0F26 #2A2230 #B8A6CC #F8C99B #3FA34D #2B6B3F
  #7FC8E8 #F2C29B #C68B59 #8A5A3B
- Nada del logo, los camiones ni las terminales de la marca ADO.

OBJETOS: edificios de una ciudad mexicana colonial (Puebla) vistos en vista
CENITAL (desde arriba, se ve el techo), con una sombra #2A2230 de 6 px hacia
abajo y a la derecha. Exactamente 3 columnas × 1 fila, cada cuadro de
192 × 192 px.
1. Iglesia con una cúpula grande de azulejos de talavera (#FFC700 y #4A235A
   en rombos), dos torres a los lados y un atrio #F8C99B con árboles.
2. Casona colonial con fachada de azulejos (talavera #FFFFFF y #4A235A en el
   pretil), patio interior con fuente y balcones de herrería #1E0F26.
3. Plaza (zócalo) con kiosco octagonal #FFFFFF de techo #DD2835, caminos
   #F8C99B, pasto #3FA34D y árboles #2B6B3F.
```

## 8. Papel picado — `assets/sprites/props/papel_picado.png`

Cuelga sobre algunas calles de un lado al otro. Se dibuja encima del auto, así que debe ser delgado para no tapar la calle.

```text
Necesito pixel art para un juego de manejo para niñas y niños de 4 a 13 años,
ambientado en una ciudad mexicana (Puebla), estilo tierno y amable.

FORMATO
- PNG. Fondo sólido color #FF00FF (magenta). Sin cuadrícula, sin fondo a
  cuadros, sin bordes ni líneas entre cuadros, sin texto, letras ni números,
  sin marcas de agua.
- Pixel art real: cada píxel del arte es un bloque cuadrado del mismo tamaño
  en toda la imagen. Si la imagen se agranda, que sea un múltiplo exacto
  (×2, ×4, ×8) del tamaño pedido.
- Si hay varios cuadros o piezas: exactamente las columnas y filas pedidas,
  todos los cuadros del mismo tamaño, separados por fondo magenta.

ESTILO
- Contorno oscuro de 1 px color #1E0F26. Luz desde arriba a la izquierda,
  sombreado de 2 tonos, sin degradados, sin antialiasing, sin brillos difusos.
- Colores permitidos (solo estos): #DD2835 #3F1B4E #FFC700 #FFFFFF #4A235A
  #9C4B79 #E86F56 #534A5E #1E0F26 #2A2230 #B8A6CC #F8C99B #3FA34D #2B6B3F
  #7FC8E8 #F2C29B #C68B59 #8A5A3B
- Nada del logo, los camiones ni las terminales de la marca ADO.

OBJETO: tira de papel picado colgando de un cordón, vista desde ARRIBA.
Exactamente 1 columna × 2 filas, cada cuadro de 256 × 32 px.
1. Cordón #1E0F26 de 1 px de lado a lado y 8 banderitas rectangulares
   alternando #DD2835, #FFC700, #3FA34D, #9C4B79, #7FC8E8, #E86F56, con
   recortes calados (agujeros con figuras de flores, sin letras).
2. Igual con los colores en otro orden y movidas 1 px (para que ondeen).
```
