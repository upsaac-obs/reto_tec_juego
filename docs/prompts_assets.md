# RutaKids — prompts para los assets

Cada asset se genera con el **BLOQUE COMÚN** + su bloque propio. Al terminar, guarda el PNG (o el JPG si no hay opción) en `~/claude/assetsss/` y pásaselo a Claude: él quita el fondo, ajusta la cuadrícula, lleva los colores a la paleta, alinea los cuadros y lo mete al juego.

**Escala del juego (todo se usa 1:1, sin escalar):** viewport 1280 × 720 · tile y carril de 64 px · auto 69 × 41 · niño 46 × 85 · señora mayor 48 × 78 · copiloto 105 × 106.

**Lo que NO se pide como imagen** (Claude lo hace por código para que embone perfecto): asfalto, banqueta, pasto, rayas de carril, ciclovía, cebra, línea de alto, direccionales, luces de freno, encendido de semáforos y sirenas, degradado del cielo.

**Estado:** ✅ hecho · ⏳ pendiente. Orden = cuándo se necesita.

| # | Asset | Tipo | Se usa en | Estado |
|---|---|---|---|---|
| — | Auto del jugador | fijo | todos | ✅ |
| — | Niño (caminar + susto) | animado | nivel 1+ | ✅ |
| — | Señora mayor (caminar + susto) | animado | nivel 4 | ✅ (mejorable, ver 5) |
| — | Copiloto ajolote | animado | todos | ✅ falta visto bueno de ADO |
| 1 | Semáforo de autos | fijo | nivel 2 | ⏳ |
| 2 | Señales: límite, zona escolar, ceda el paso, alto | fijo | niveles 1-2 | ⏳ |
| 3 | Casas, escuela y árboles | fijo | niveles 0-2 | ⏳ |
| 4 | Iconos de niveles + candado | fijo | selección de niveles | ⏳ |
| 5 | Tarjetas de hábito (11) | fijo | fin de nivel | ⏳ |
| 6 | Auto blanco para el tráfico | fijo | nivel 2+ | ⏳ |
| 7 | Niña escolar (caminar + susto) | animado | niveles 1, 4 | ⏳ |
| 8 | Adulto (caminar + susto) | animado | nivel 3+ | ⏳ |
| 9 | Persona en silla de ruedas | animado | nivel 4 | ⏳ |
| 10 | Semáforo peatonal | animado (3 cuadros) | nivel 4 | ⏳ |
| 11 | Ciclista con casco | animado | niveles 3, 7, 8 | ⏳ |
| 12 | Camión de pasajeros + parada | fijo | nivel 8 | ⏳ |
| 13 | Moto | fijo | nivel 8 | ⏳ |
| 14 | Marca "mira" en el piso | fijo | nivel 3 | ⏳ |
| 15 | Celular del nivel 6 | fijo | nivel 6 | ⏳ |
| 16 | Botón de luces + iconos de pausa | fijo | HUD | ⏳ |
| 17 | Edificios de avenida, hospital, terminal, túnel | fijo | zonas 2 y 3 | ⏳ |
| 18 | Ambulancia | fijo | nivel 9 | ⏳ |
| 19 | Fondo del menú (ciudad + nubes) | fijo | menú | ⏳ |
| 20 | Selección de edad (Peque / Grande) | fijo | primera vez | ⏳ |
| 21 | Icono de la app | fijo | Android / iOS | ⏳ |

---

## BLOQUE COMÚN (pégalo siempre al inicio)

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
```

**Vistas que se usan:**
- **Cenital:** exactamente desde arriba, como un mapa (vehículos, edificios, objetos en el piso). Vehículos con el frente hacia la DERECHA.
- **3/4 alta:** como un RPG clásico tipo Pokémon / Stardew Valley (personas). Mirando hacia ABAJO, proporciones chibi.
- **Frontal:** de frente, como un letrero visto de pie (señales, semáforos, iconos de interfaz).

**Reglas para animaciones de personas** (agrégalas cuando sea animado):

```text
- El personaje ocupa el mismo tamaño en todos los cuadros, centrado, con los
  pies siempre en la misma línea (2 px arriba del borde de abajo).
- En CAMINAR los pies nunca se despegan del piso (sin brincos).
- Los objetos (bastón, mochila, bolsa) están en la misma mano en TODOS los
  cuadros, también en el susto.
- Sin sombra en el piso.
```

**CAMINAR estándar (8 cuadros, ciclo que se repite)** — se reutiliza en varias personas:

```text
1. Contacto: pie izquierdo adelante tocando el piso, brazo derecho adelante.
2. Bajada: el cuerpo baja 1 px, peso sobre el pie izquierdo.
3. Paso: pie derecho pasa junto al izquierdo, brazos junto al cuerpo.
4. Subida: cuerpo sube 1 px, pie derecho adelante en el aire (sin despegar el izquierdo).
5. Contacto: pie derecho adelante tocando el piso, brazo izquierdo adelante.
6. Bajada: cuerpo baja 1 px, peso sobre el pie derecho.
7. Paso: pie izquierdo pasa junto al derecho, brazos junto al cuerpo.
8. Subida: cuerpo sube 1 px (vuelve al cuadro 1 sin saltos).
```

**SUSTO estándar (8 cuadros, se reproduce una vez):**

```text
1. Caminando normal (igual al cuadro 1 de caminar).
2. Se detiene, ojos más grandes, cejas arriba.
3. Brinquito hacia atrás: cuerpo 3 px arriba, manos a la altura del pecho, boca en "o".
4. Punto más alto del brinco, el cabello y la ropa se levantan 1-2 px.
5. Aterriza: cuerpo a su altura, rodillas un poco dobladas.
6. Manos todavía en el pecho, ojos abiertos.
7. Se tranquiliza: baja las manos, ojos normales.
8. De pie, quieto, pies juntos, sonrisa pequeña (sirve como "quieto").
```

---

## 1. Semáforo de autos — `assets/sprites/signals/traffic_light.png`

Las luces se encienden por código; el dibujo lleva las tres **apagadas**.

```text
[BLOQUE COMÚN]

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

La palabra ALTO y el número del límite los pone el juego con `tr()` (regla de `CLAUDE.md`: ningún texto dentro de imágenes).

```text
[BLOQUE COMÚN]

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

```text
[BLOQUE COMÚN]

OBJETOS: edificios de una colonia vistos en vista CENITAL (desde arriba, se
ve el techo), con una sombra #2A2230 de 6 px hacia abajo y a la derecha.

HOJA A (casas.png): 4 columnas × 1 fila, cada cuadro de 128 × 128 px.
Casas mexicanas de una planta con techo plano o de dos aguas, cada una con
detalles distintos en el techo: tinaco #2A2230 redondo, tendedero con ropa de
colores, macetas #C68B59 con plantas #3FA34D, tragaluz #7FC8E8.
Colores de techo: 1) #E86F56, 2) #9C4B79, 3) #F8C99B, 4) #B8A6CC.

HOJA B (escuela.png): un solo cuadro de 320 × 224 px.
Escuela primaria vista desde arriba: edificio en forma de "L" con techo
#E86F56, patio #B8A6CC con una cancha pintada #FFFFFF, asta con bandera de
México (verde #3FA34D, blanco #FFFFFF, rojo #DD2835), dos árboles #2B6B3F,
bancas #8A5A3B y un portón #3F1B4E en el borde inferior. Sin letras.

HOJA C (arboles.png): 4 columnas × 1 fila, cada cuadro de 64 × 64 px.
Copas de árbol vistas desde arriba: 1) redondo grande #3FA34D con sombra
#2B6B3F, 2) jacaranda morada #9C4B79 con flores #B8A6CC, 3) arbusto doble
#2B6B3F, 4) maceta grande #C68B59 con flores #FFC700. Con sombra abajo-derecha.
```

## 4. Iconos de niveles — `assets/ui/level_icons.png`

Van dentro del botón morado de la selección de niveles (como en el mockup).

```text
[BLOQUE COMÚN]

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

## 5. Tarjetas de hábito — `assets/ui/habit_cards/card_XX.png`

Una imagen por nivel (11). Usa el mismo prompt cambiando la ESCENA.

```text
[BLOQUE COMÚN]

OBJETO: ilustración para una tarjeta de premio al terminar un nivel,
vista 3/4 alta, 480 × 288 px, escena completa con fondo de ciudad (aquí NO
va fondo magenta: el fondo es la escena). Sin texto. El copiloto es un
ajolote durazno #F2C29B con branquias coral #E86F56, gorra amarilla #FFC700
con visera roja #DD2835 y cinturón cruzado #2A2230; aparece en una esquina
celebrando con el pulgar arriba.

ESCENA: <pega aquí la escena del nivel>
```

| Archivo | Nivel | ESCENA |
|---|---|---|
| card_00 | Abróchate y arranca | Un niño sentado en el auto se abrocha el cinturón con una gran sonrisa. |
| card_01 | Primero el peatón | Un auto rojo detenido antes de la cebra mientras un grupo de niños con mochila cruza. |
| card_02 | Respeta las señales | Un auto detenido en un semáforo en rojo junto a una señal de ALTO. |
| card_03 | Mira dos veces | Un auto asomándose en una esquina con edificios; dos ojos grandes dibujados en el piso. |
| card_04 | Con calma | Una señora con bastón y una persona en silla de ruedas cruzan tranquilas; el auto espera. |
| card_05 | Sin prisa | Un auto avanzando despacio; una pelota rueda a la calle y un niño la sigue desde la banqueta. |
| card_06 | Ojos en el camino | Un celular guardado en la guantera con la pantalla apagada; el conductor mira la calle. |
| card_07 | Hazte visible | Atardecer con lluvia, un auto con los faros encendidos y un ciclista con chaleco reflejante. |
| card_08 | Comparte el camino | Un auto dejando espacio a una bicicleta en la ciclovía y esperando detrás de un camión en su parada. |
| card_09 | Piensa en todos | Autos orillados a la derecha dejando pasar a una ambulancia. |
| card_10 | Hábito de campeón | El ajolote copiloto con un trofeo dorado y muchas estrellas, el auto rojo detrás. |

## 6. Auto blanco para el tráfico — `assets/sprites/vehicles/npc_car.png`

Blanco para poder pintarlo de cualquier color por código (`modulate`).

```text
[BLOQUE COMÚN]

OBJETO: auto compacto en vista CENITAL, frente hacia la DERECHA, 70 × 42 px.
Carrocería BLANCA #FFFFFF con sombreado #B8A6CC, techo un poco más oscuro
#B8A6CC, parabrisas y vidrio trasero #7FC8E8, faros #F8C99B en el borde
derecho, calaveras #534A5E en el borde izquierdo, espejos laterales, llantas
#2A2230 asomando a los lados. Sin franjas ni detalles de color.
```

## 7. Niña escolar — `assets/sprites/pedestrians/girl.png`

```text
[BLOQUE COMÚN]
[Reglas para animaciones de personas]

PERSONAJE: niña de unos 8 años, vista 3/4 alta mirando hacia ABAJO, chibi.
Cuadros de 46 × 85 px. Exactamente 8 columnas × 2 filas.
Fila 1 = CAMINAR estándar. Fila 2 = SUSTO estándar.
- Cabello negro #2A2230 en dos coletas con moños #DD2835.
- Piel #C68B59, sombra #8A5A3B, mejillas #E86F56.
- Uniforme escolar: suéter #4A235A, falda #9C4B79, calcetas #FFFFFF,
  zapatos #2A2230. Mochila #7FC8E8 en la espalda (siempre visible igual).

[CAMINAR estándar]
[SUSTO estándar]
```

## 8. Adulto — `assets/sprites/pedestrians/adult.png`

```text
[BLOQUE COMÚN]
[Reglas para animaciones de personas]

PERSONAJE: mamá joven, vista 3/4 alta mirando hacia ABAJO, chibi.
Cuadros de 48 × 92 px. Exactamente 8 columnas × 2 filas.
Fila 1 = CAMINAR estándar. Fila 2 = SUSTO estándar.
- Cabello café #8A5A3B en cola de caballo. Piel #F2C29B, sombra #C68B59.
- Blusa #3FA34D, pantalón #3F1B4E, tenis #FFFFFF.
- Bolsa de mandado #FFC700 en la mano derecha en TODOS los cuadros.

[CAMINAR estándar]
[SUSTO estándar]
```

## 9. Persona en silla de ruedas — `assets/sprites/pedestrians/wheelchair.png`

```text
[BLOQUE COMÚN]
[Reglas para animaciones de personas]

PERSONAJE: joven en silla de ruedas, vista 3/4 alta mirando hacia ABAJO,
chibi, avanzando hacia la cámara. Cuadros de 64 × 84 px.
Exactamente 6 columnas × 2 filas. Fila 1 = RODAR. Fila 2 = SUSTO.
- Cabello negro #2A2230 corto, piel #8A5A3B, sonrisa.
- Playera #7FC8E8, pantalón #3F1B4E, tenis #FFFFFF.
- Silla: ruedas grandes #2A2230 con rines #B8A6CC, asiento #DD2835,
  descansapiés #534A5E.

FILA 1: RODAR (6 cuadros, ciclo)
1. Manos arriba en los aros de las ruedas, cuerpo derecho.
2. Manos empujan hacia adelante 2 px, rayos de las ruedas giran.
3. Manos al frente, cuerpo inclinado 1 px adelante.
4. Manos se sueltan y regresan arriba, rayos siguen girando.
5. Manos arriba otra vez, cuerpo derecho.
6. Igual al 1 con los rayos en otra posición (vuelve al 1 sin saltos).

FILA 2: SUSTO (6 cuadros, una vez)
1. Igual al cuadro 1 de rodar.
2. Ojos grandes, cejas arriba, manos sueltan los aros.
3. Manos al pecho, boca en "o", el cuerpo se hace 1 px hacia atrás.
4. Igual al 3 con el cabello levantado 1 px.
5. Baja las manos a los aros, ojos normales.
6. Quieto, sonrisa pequeña (sirve como "quieto").
```

## 10. Semáforo peatonal — `assets/sprites/signals/pedestrian_light.png`

```text
[BLOQUE COMÚN]

OBJETO: semáforo peatonal, vista FRONTAL. Exactamente 3 columnas × 1 fila,
cada cuadro de 40 × 96 px. Caja #2A2230 con dos ventanas cuadradas una
arriba de otra y poste #534A5E hasta abajo.
1. APAGADO: las dos figuras en #534A5E.
2. ALTO: figura de persona parada arriba encendida en #DD2835 con brillo
   #E86F56; la de abajo apagada.
3. CAMINAR: figura de persona caminando abajo encendida en #3FA34D con brillo
   #FFFFFF; la de arriba apagada.
```

## 11. Ciclista — `assets/sprites/vehicles/cyclist.png`

```text
[BLOQUE COMÚN]

PERSONAJE: ciclista en bicicleta, vista CENITAL (desde arriba), frente hacia
la DERECHA. Cuadros de 72 × 40 px. Exactamente 6 columnas × 1 fila.
- Bicicleta #3FA34D con llantas #2A2230. Casco #FFC700 con franja #DD2835.
- Chaleco reflejante #FFC700 con franjas #FFFFFF. Brazos #C68B59 al manubrio.
FILA: PEDALEAR (6 cuadros, ciclo)
1. Pierna izquierda arriba (rodilla hacia adelante), derecha abajo.
2. Pedales giran 60°: pierna izquierda bajando.
3. Piernas a la misma altura.
4. Pierna derecha arriba, izquierda abajo.
5. Pierna derecha bajando.
6. Piernas a la misma altura (vuelve al 1 sin saltos).
Cuerpo, casco y bicicleta no se mueven; solo piernas y pedales.
```

## 12. Camión de pasajeros y parada — `assets/sprites/vehicles/bus.png`

```text
[BLOQUE COMÚN]

HOJA: 2 columnas × 1 fila, cada cuadro de 192 × 72 px, vista CENITAL.
1. Camión urbano genérico (NO de la marca ADO), frente hacia la DERECHA,
   176 × 60 px: techo blanco #FFFFFF con aire acondicionado #B8A6CC y escotilla,
   franja verde #3FA34D en los bordes, parabrisas #7FC8E8 al frente, puerta
   marcada #2B6B3F del lado de abajo (derecho), calaveras #DD2835 atrás.
2. Parada de camión: techo de parabús #3F1B4E con borde #FFC700, banca
   #8A5A3B debajo, señal redonda #7FC8E8 con la silueta de un camión blanco.
```

## 13. Moto — `assets/sprites/vehicles/motorcycle.png`

```text
[BLOQUE COMÚN]

OBJETO: moto con conductor, vista CENITAL, frente hacia la DERECHA, 52 × 28 px.
Moto #DD2835, llantas #2A2230, conductor con casco #3F1B4E con visera
#7FC8E8, chamarra #534A5E, brazos al manubrio.
```

## 14. Marca "mira" — `assets/sprites/signals/look_mark.png`

```text
[BLOQUE COMÚN]

OBJETO: marca pintada en el asfalto, vista CENITAL, 64 × 64 px. Dos ojos
grandes pintados en amarillo #FFC700 (blanco del ojo) con pupilas #1E0F26
mirando a la izquierda y una flecha doble ↔ #FFC700 debajo. Aspecto de
pintura sobre el piso: bordes un poco gastados, sin contorno negro.
```

## 15. Celular del nivel 6 — `assets/ui/phone.png`

La vibración se hace por código.

```text
[BLOQUE COMÚN]

OBJETO: celular visto de FRENTE, 240 × 420 px. Carcasa #2A2230 con borde
#534A5E, pantalla encendida #7FC8E8 con un icono grande de llamada entrante
(auricular #FFFFFF dentro de un círculo #3FA34D) y ondas #FFFFFF alrededor.
Sin texto ni números.
```

## 16. Botón de luces e iconos de pausa — `assets/ui/icons/`

```text
[BLOQUE COMÚN]

HOJA: iconos de interfaz, vista FRONTAL, estilo brillante de caricatura.
Exactamente 5 columnas × 1 fila, cada cuadro de 80 × 80 px.
1. Botón redondo #4A235A con borde #1E0F26 y un FARO de auto APAGADO
   (#534A5E) en el centro.
2. Igual al 1 con el faro ENCENDIDO (#F8C99B) y rayos de luz #FFC700.
3. SALIR: puerta #8A5A3B entreabierta con una flecha #DD2835 saliendo.
4. SONIDO: bocina #B8A6CC con tres ondas #FFFFFF.
5. SILENCIO: bocina #B8A6CC con una tacha #DD2835.
```

## 17. Avenida, hospital, terminal y túnel — `assets/sprites/city/`

```text
[BLOQUE COMÚN]

Vista CENITAL (se ve el techo), sombra #2A2230 de 8 px hacia abajo-derecha.
HOJA A (edificios.png): 3 columnas × 1 fila, cuadros de 192 × 192 px.
Edificios de varios pisos de una avenida poblana: 1) techo #9C4B79 con tinacos
y antena, 2) techo #534A5E con jardín #3FA34D y paneles solares #7FC8E8,
3) techo #E86F56 con tragaluces y aire acondicionado #B8A6CC.
HOJA B (hospital.png): un cuadro de 320 × 224 px. Techo #FFFFFF con un
helipuerto (círculo #7FC8E8 con una cruz blanca #FFFFFF, sin letras), entrada techada #7FC8E8
abajo, estacionamiento con rayas #FFFFFF.
HOJA C (terminal.png): un cuadro de 384 × 224 px. Terminal de autobuses
genérica (NO de la marca ADO): techo largo curvo #B8A6CC, 4 andenes con
techos #3F1B4E, plaza #F8C99B con bancas y árboles #3FA34D.
HOJA D (tunel.png): 2 columnas × 1 fila, cuadros de 192 × 192 px.
1) Entrada de túnel vista desde arriba: cerro con pasto #3FA34D y árboles,
   boca del túnel en arco de piedra #B8A6CC que se abre hacia la izquierda.
2) Salida igual, abriéndose hacia la derecha.
```

## 18. Ambulancia — `assets/sprites/vehicles/ambulance.png`

La sirena se enciende por código.

```text
[BLOQUE COMÚN]

OBJETO: ambulancia en vista CENITAL, frente hacia la DERECHA, 92 × 46 px.
Carrocería blanca #FFFFFF con sombreado #B8A6CC, franja roja #DD2835 a lo
largo, torreta en el techo con una luz #DD2835 y una #7FC8E8 APAGADAS
(un poco más oscuras: #9C4B79 y #534A5E), parabrisas #7FC8E8,
cruz azul #7FC8E8 de 6 px en el techo (no cruz roja).
```

## 19. Fondo del menú — `assets/ui/menu/`

El cielo con degradado se hace por código; aquí solo la ciudad y las nubes.

```text
[BLOQUE COMÚN]

HOJA A (ciudad.png): tira de 1280 × 256 px, vista FRONTAL, silueta de Puebla
al atardecer que se pueda repetir de lado a lado sin cortes: cúpulas de
iglesias con azulejo #E86F56 y #FFC700, edificios bajos #4A235A y #3F1B4E,
ventanas encendidas #F8C99B, volcán Popocatépetl a lo lejos #9C4B79 con nieve
#FFFFFF. Arriba de los edificios el fondo es magenta (transparente).
HOJA B (nubes.png): 3 columnas × 1 fila, cuadros de 192 × 96 px, nubes
esponjosas #F8C99B con sombra #E86F56, de tres tamaños.
```

## 20. Selección de edad — `assets/ui/age_select.png`

```text
[BLOQUE COMÚN]

HOJA: 2 columnas × 1 fila, cuadros de 320 × 320 px, vista FRONTAL, dentro de
un marco redondeado #3F1B4E con borde #FFC700 de 6 px.
1. PEQUE: niña de 5 años sonriendo, abrazando un autito de juguete #DD2835.
2. GRANDE: niño de 11 años con casco de bici #FFC700, pulgar arriba, mochila.
Sin texto.
```

## 21. Icono de la app — `assets/ui/app_icon_final.png`

```text
[BLOQUE COMÚN]

OBJETO: icono de app, 512 × 512 px, AQUÍ el fondo NO es magenta: cuadrado con
esquinas redondeadas #3F1B4E y borde #DD2835 de 16 px. Dentro, el ajolote
copiloto (durazno #F2C29B, branquias #E86F56, gorra #FFC700 con visera
#DD2835, cinturón #2A2230) asomado por la ventana de un auto rojo #DD2835
visto de lado, sonriendo con el pulgar arriba. Sin texto.
```

---

## Además de imágenes: audio (fase 2)

Voces con IA para cada clave de `i18n/textos.csv` (`assets/audio/voz/<CLAVE>.ogg`), y efectos `.wav` en `assets/audio/sfx/`: motor, freno, claxon, direccional (tic-tac), celebración, "uy", vibración de celular y sirena. Música de fondo `.ogg` en `assets/audio/musica/`.
