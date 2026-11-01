# RutaKids — prompts listos de la fase 1

Cada bloque es un prompt completo para UNA imagen: cópialo entero y pégalo en el generador. Guarda el resultado en `~/claude/assetsss/` y pásaselo a Claude.

## 1. Semáforo de autos — `assets/sprites/signals/traffic_light.png`

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

OBJETO: semáforo vehicular, vista FRONTAL. Imagen de 48 × 128 píxeles.
- Caja vertical #2A2230 con contorno #1E0F26, esquinas redondeadas, visera
  pequeña arriba de cada luz.
- Tres círculos IGUALES de 24 px de diámetro, uno arriba de otro, centrados,
  con 8 px de separación, todos APAGADOS: color #534A5E con un brillo #B8A6CC
  de 2 px arriba a la izquierda.
- Poste #534A5E de 8 px de ancho desde abajo de la caja hasta el borde inferior.
- Sin luces encendidas, sin texto.
```

## 2. Señales — `assets/sprites/signals/signs.png`

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

OBJETO: hoja con 4 señales de tránsito mexicanas, vista FRONTAL, SIN letras
ni números (el texto se agrega aparte). Exactamente 4 columnas × 1 fila, cada
cuadro de 72 × 112 píxeles. Cada señal tiene un poste #534A5E de 6 px que
llega al borde inferior.
1. ALTO: octágono rojo #DD2835 con borde blanco #FFFFFF de 3 px, centro liso.
2. LÍMITE DE VELOCIDAD: círculo blanco #FFFFFF con borde rojo #DD2835 de 5 px,
   centro blanco liso.
3. ZONA ESCOLAR: pentágono (forma de casita) amarillo dorado #FFC700 con borde
   #1E0F26 y la silueta de dos niños caminando de la mano en #1E0F26.
4. CEDA EL PASO: triángulo con la punta hacia abajo, blanco con borde rojo
   #DD2835 de 5 px.
```

## 3. Casas, escuela y árboles — `assets/sprites/city/`

### casas.png

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

OBJETOS: edificios de una colonia vistos en vista CENITAL (desde arriba, se
ve el techo), con una sombra #2A2230 de 6 px hacia abajo y a la derecha.


HOJA A (casas.png): 4 columnas × 1 fila, cada cuadro de 128 × 128 px.
Casas mexicanas de una planta con techo plano o de dos aguas, cada una con
detalles distintos en el techo: tinaco #2A2230 redondo, tendedero con ropa de
colores, macetas #C68B59 con plantas #3FA34D, tragaluz #7FC8E8.
Colores de techo: 1) #E86F56, 2) #9C4B79, 3) #F8C99B, 4) #B8A6CC.

```

### escuela.png

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

OBJETOS: edificios de una colonia vistos en vista CENITAL (desde arriba, se
ve el techo), con una sombra #2A2230 de 6 px hacia abajo y a la derecha.


HOJA B (escuela.png): un solo cuadro de 320 × 224 px.
Escuela primaria vista desde arriba: edificio en forma de "L" con techo
#E86F56, patio #B8A6CC con una cancha pintada #FFFFFF, asta con bandera de
México (verde #3FA34D, blanco #FFFFFF, rojo #DD2835), dos árboles #2B6B3F,
bancas #8A5A3B y un portón #3F1B4E en el borde inferior. Sin letras.

```

### arboles.png

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

OBJETOS: edificios de una colonia vistos en vista CENITAL (desde arriba, se
ve el techo), con una sombra #2A2230 de 6 px hacia abajo y a la derecha.


HOJA C (arboles.png): 4 columnas × 1 fila, cada cuadro de 64 × 64 px.
Copas de árbol vistas desde arriba: 1) redondo grande #3FA34D con sombra
#2B6B3F, 2) jacaranda morada #9C4B79 con flores #B8A6CC, 3) arbusto doble
#2B6B3F, 4) maceta grande #C68B59 con flores #FFC700. Con sombra abajo-derecha.
```

## 4. Iconos de niveles — `assets/ui/level_icons.png`

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

OBJETO: hoja de iconos de interfaz, vista FRONTAL, estilo brillante de
caricatura. Exactamente 6 columnas × 2 filas, cada cuadro de 96 × 96 px.
Fila 1:
1. Cinturón de seguridad abrochado (correa #2A2230, hebilla #B8A6CC).
2. Niño cruzando sobre una cebra blanca (piel #C68B59, mochila #FFC700).
3. Señal de alto: octágono #DD2835 con una mano abierta blanca #FFFFFF (sin letras).
4. Dos ojos grandes mirando a los lados (#FFFFFF con pupilas #1E0F26).
5. Señora mayor con bastón (cabello #FFFFFF, rebozo #4A235A).
6. Reloj despertador amarillo #FFC700 con manecillas #1E0F26.
Fila 2:
7. Celular #2A2230 con una tacha roja #DD2835 encima.
8. Faro de auto encendido con rayos de luz #F8C99B.
9. Bicicleta #3FA34D con casco #FFC700 encima.
10. Ambulancia blanca de frente con torreta #DD2835 y #7FC8E8.
11. Trofeo dorado #FFC700 con una estrella.
12. Candado cerrado #534A5E con brillo #B8A6CC (nivel bloqueado).
```

## 5. Tarjetas de hábito — una imagen por nivel

### card_00.png — Abróchate y arranca

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

OBJETO: ilustración para una tarjeta de premio al terminar un nivel,
vista 3/4 alta, 480 × 288 px, escena completa con fondo de ciudad (aquí NO
va fondo magenta: el fondo es la escena). Sin texto. El copiloto es un
ajolote durazno #F2C29B con branquias coral #E86F56, gorra amarilla #FFC700
con visera roja #DD2835 y cinturón cruzado #2A2230; aparece en una esquina
celebrando con el pulgar arriba.

ESCENA: Un niño sentado en el auto se abrocha el cinturón con una gran sonrisa.
```

### card_01.png — Primero el peatón

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

OBJETO: ilustración para una tarjeta de premio al terminar un nivel,
vista 3/4 alta, 480 × 288 px, escena completa con fondo de ciudad (aquí NO
va fondo magenta: el fondo es la escena). Sin texto. El copiloto es un
ajolote durazno #F2C29B con branquias coral #E86F56, gorra amarilla #FFC700
con visera roja #DD2835 y cinturón cruzado #2A2230; aparece en una esquina
celebrando con el pulgar arriba.

ESCENA: Un auto rojo detenido antes de la cebra mientras un grupo de niños con mochila cruza.
```

### card_02.png — Respeta las señales

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

OBJETO: ilustración para una tarjeta de premio al terminar un nivel,
vista 3/4 alta, 480 × 288 px, escena completa con fondo de ciudad (aquí NO
va fondo magenta: el fondo es la escena). Sin texto. El copiloto es un
ajolote durazno #F2C29B con branquias coral #E86F56, gorra amarilla #FFC700
con visera roja #DD2835 y cinturón cruzado #2A2230; aparece en una esquina
celebrando con el pulgar arriba.

ESCENA: Un auto detenido en un semáforo en rojo junto a una señal de ALTO.
```

### card_03.png — Mira dos veces

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

OBJETO: ilustración para una tarjeta de premio al terminar un nivel,
vista 3/4 alta, 480 × 288 px, escena completa con fondo de ciudad (aquí NO
va fondo magenta: el fondo es la escena). Sin texto. El copiloto es un
ajolote durazno #F2C29B con branquias coral #E86F56, gorra amarilla #FFC700
con visera roja #DD2835 y cinturón cruzado #2A2230; aparece en una esquina
celebrando con el pulgar arriba.

ESCENA: Un auto asomándose en una esquina con edificios; dos ojos grandes dibujados en el piso.
```

### card_04.png — Con calma

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

OBJETO: ilustración para una tarjeta de premio al terminar un nivel,
vista 3/4 alta, 480 × 288 px, escena completa con fondo de ciudad (aquí NO
va fondo magenta: el fondo es la escena). Sin texto. El copiloto es un
ajolote durazno #F2C29B con branquias coral #E86F56, gorra amarilla #FFC700
con visera roja #DD2835 y cinturón cruzado #2A2230; aparece en una esquina
celebrando con el pulgar arriba.

ESCENA: Una señora con bastón y una persona en silla de ruedas cruzan tranquilas; el auto espera.
```

### card_05.png — Sin prisa

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

OBJETO: ilustración para una tarjeta de premio al terminar un nivel,
vista 3/4 alta, 480 × 288 px, escena completa con fondo de ciudad (aquí NO
va fondo magenta: el fondo es la escena). Sin texto. El copiloto es un
ajolote durazno #F2C29B con branquias coral #E86F56, gorra amarilla #FFC700
con visera roja #DD2835 y cinturón cruzado #2A2230; aparece en una esquina
celebrando con el pulgar arriba.

ESCENA: Un auto avanzando despacio; una pelota rueda a la calle y un niño la sigue desde la banqueta.
```

### card_06.png — Ojos en el camino

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

OBJETO: ilustración para una tarjeta de premio al terminar un nivel,
vista 3/4 alta, 480 × 288 px, escena completa con fondo de ciudad (aquí NO
va fondo magenta: el fondo es la escena). Sin texto. El copiloto es un
ajolote durazno #F2C29B con branquias coral #E86F56, gorra amarilla #FFC700
con visera roja #DD2835 y cinturón cruzado #2A2230; aparece en una esquina
celebrando con el pulgar arriba.

ESCENA: Un celular guardado en la guantera con la pantalla apagada; el conductor mira la calle.
```

### card_07.png — Hazte visible

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

OBJETO: ilustración para una tarjeta de premio al terminar un nivel,
vista 3/4 alta, 480 × 288 px, escena completa con fondo de ciudad (aquí NO
va fondo magenta: el fondo es la escena). Sin texto. El copiloto es un
ajolote durazno #F2C29B con branquias coral #E86F56, gorra amarilla #FFC700
con visera roja #DD2835 y cinturón cruzado #2A2230; aparece en una esquina
celebrando con el pulgar arriba.

ESCENA: Atardecer con lluvia, un auto con los faros encendidos y un ciclista con chaleco reflejante.
```

### card_08.png — Comparte el camino

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

OBJETO: ilustración para una tarjeta de premio al terminar un nivel,
vista 3/4 alta, 480 × 288 px, escena completa con fondo de ciudad (aquí NO
va fondo magenta: el fondo es la escena). Sin texto. El copiloto es un
ajolote durazno #F2C29B con branquias coral #E86F56, gorra amarilla #FFC700
con visera roja #DD2835 y cinturón cruzado #2A2230; aparece en una esquina
celebrando con el pulgar arriba.

ESCENA: Un auto dejando espacio a una bicicleta en la ciclovía y esperando detrás de un camión en su parada.
```

### card_09.png — Piensa en todos

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

OBJETO: ilustración para una tarjeta de premio al terminar un nivel,
vista 3/4 alta, 480 × 288 px, escena completa con fondo de ciudad (aquí NO
va fondo magenta: el fondo es la escena). Sin texto. El copiloto es un
ajolote durazno #F2C29B con branquias coral #E86F56, gorra amarilla #FFC700
con visera roja #DD2835 y cinturón cruzado #2A2230; aparece en una esquina
celebrando con el pulgar arriba.

ESCENA: Autos orillados a la derecha dejando pasar a una ambulancia.
```

### card_10.png — Hábito de campeón

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

OBJETO: ilustración para una tarjeta de premio al terminar un nivel,
vista 3/4 alta, 480 × 288 px, escena completa con fondo de ciudad (aquí NO
va fondo magenta: el fondo es la escena). Sin texto. El copiloto es un
ajolote durazno #F2C29B con branquias coral #E86F56, gorra amarilla #FFC700
con visera roja #DD2835 y cinturón cruzado #2A2230; aparece en una esquina
celebrando con el pulgar arriba.

ESCENA: El ajolote copiloto con un trofeo dorado y muchas estrellas, el auto rojo detrás.
```
