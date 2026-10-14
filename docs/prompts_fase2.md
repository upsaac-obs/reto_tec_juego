# RutaKids — prompts de la fase 2 (cruces del nivel 3)

Cada bloque es un prompt completo para UNA imagen: cópialo entero y pégalo en el generador. Guarda el resultado en `~/claude/assetsss/` y pásaselo a Claude.

Mientras no estén, el nivel 3 usa cruces dibujados con código con los mismos colores; al llegar las imágenes solo se cambia el dibujo.

## 1. Tiles de cruce — `assets/tiles/crossing_tiles.png`

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
mapa), para armar cruces de calles. Exactamente 4 columnas × 2 filas, cada
cuadro de 64 × 64 px. Cada tile llena su cuadro completo (sin fondo magenta
dentro del cuadro) para que se peguen sin huecos.
Colores base: asfalto #534A5E con puntitos sueltos #2A2230; banqueta #B8A6CC
con una cuadrícula punteada #9C4B79 cada 32 px; guarnición (orilla de la
banqueta) blanca #FFFFFF de 6 px con una línea #1E0F26 de 2 px del lado del
asfalto; pasto #3FA34D.
Fila 1:
1. Asfalto liso, sin rayas (centro del cruce).
2. Esquina de banqueta EXTERIOR: banqueta en la esquina de arriba a la
   izquierda con la guarnición curva (cuarto de círculo de 48 px de radio) y
   asfalto en el resto.
3. Esquina de banqueta INTERIOR: asfalto solo en un cuarto de círculo pequeño
   (16 px) en la esquina de abajo a la derecha; el resto banqueta.
4. Rampa para silla de ruedas: banqueta arriba y guarnición abajo, con una
   rampa más clara #F8C99B de 32 px de ancho en el centro, con rayitas.
Fila 2:
5. Marca "MIRA": asfalto con dos ojos grandes pintados en blanco #FFFFFF
   (pupilas #1E0F26) mirando hacia los lados, ocupando el centro del tile.
6. Línea de "mira" punteada: asfalto con una línea blanca punteada vertical
   de 8 px de ancho pegada al borde derecho.
7. Coladera: asfalto con una rejilla rectangular #2A2230 en el centro.
8. Banqueta con poste de luz visto desde arriba: banqueta con un círculo
   #534A5E de 12 px y su lámpara #F8C99B.
```

## 2. Edificios de esquina — `assets/sprites/city/edificios_esquina.png`

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

OBJETOS: edificios de esquina de una ciudad mexicana colonial (Puebla) vistos
en vista CENITAL (desde arriba, se ve el techo), con una sombra #2A2230 de 6 px
hacia abajo y a la derecha. Exactamente 3 columnas × 1 fila, cada cuadro de
192 × 192 px. Cada edificio tiene forma de "L" que abraza la esquina de abajo
a la derecha del cuadro (ahí va el cruce), con techo plano, pretil (borde del
techo) de 6 px más claro y detalles distintos:
1. Techo #E86F56 con tinaco #2A2230 y un tragaluz #7FC8E8.
2. Techo #9C4B79 con macetas #C68B59 con plantas #3FA34D y un toldo a rayas
   #FFC700 y #FFFFFF en el lado de la calle.
3. Techo #F8C99B con azulejos de talavera (#FFFFFF y #4A235A) en el pretil y
   un tendedero con ropa de colores.
```
