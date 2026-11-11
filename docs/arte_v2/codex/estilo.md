# Estilo v2: biblia de arte de RutaKids

> **Para Codex.** El bloque **STYLE BASE** (§1) va al inicio de cada prompt, palabra por
> palabra. Las demás secciones explican las reglas que el prompt resume; consúltalas
> cuando revises si una imagen se acepta.

## 1. STYLE BASE (copiar sin cambios al inicio de cada prompt)

```
STYLE: vector cartoon illustration for a kids' mobile game (ages 4-13), clean
Flash-era vector look, matching the attached reference images exactly. Rounded,
chunky, slightly inflated shapes with no sharp corners. Big simple shapes: no detail
smaller than 1/20 of the object's width. Max 3 tones per surface (base color, soft
linear gradient lighter at top-left, one flat cel-shadow tone at bottom-right).
Small white glossy highlights on glass, metal and plastic. Light always from the
top-left, neutral midday light.
OUTLINE: bold, uniform outline using a darker shade of each object's own color,
never pure black.
COLOR: decor and buildings use soft, slightly muted colors; only characters,
vehicles, traffic signals and UI buttons are bright and saturated.
NEVER: text, letters, numbers, logos, brand names, watermark, pixel art, noise
texture, photorealism, 3D render, drop shadow on the ground.
BACKGROUND: fully transparent (PNG with alpha).
SETTING: a colorful, friendly neighborhood in Puebla, Mexico.
```

Justo después va la línea del grosor de contorno, según la clase de tamaño que diga la
ficha:

| Clase | Tamaño final en el juego | Línea que se agrega |
|---|---|---|
| **XS** | menos de 70 px (auto, moto, peatones, íconos) | `OUTLINE THICKNESS: about 3% of the object's longest side.` |
| **S** | 70-130 px (casas, árboles, señales, copiloto, botones) | `OUTLINE THICKNESS: about 2% of the object's longest side.` |
| **L** | más de 130 px (edificios, destinos, bus, túnel, tarjetas) | `OUTLINE THICKNESS: about 1.2% of the object's longest side.` |

El objetivo es que, ya reducidos, todos los objetos del juego tengan un contorno parecido.
Sin esta regla, lo chico queda con línea finísima y lo grande con línea gruesa.

## 2. Cámaras: solo existen estas 3, no inventes una cuarta

| Tipo | Vista | Ejemplos |
|---|---|---|
| **Lo que rueda** | Cenital pura (desde arriba), **frente hacia la DERECHA** | autos, bus, ambulancia, moto, ciclista |
| **Lo que está de pie** | De frente con un poco de arriba (3/4); **base abajo al centro**; las personas caminan hacia la derecha | personas, copiloto, postes, semáforos, señales, árboles, puestos, bancas |
| **Lo grande y fijo** | Cenital con **la fachada visible abajo**: azotea arriba y fachada abajo, la línea de la fachada a la **mitad de la altura (50 % ±3 %)** | casas, edificios, destinos, túnel |

**Única excepción:** las tarjetas de hábito (lote 08) son "postales": una ilustración de
calle en 3/4 a la altura de la banqueta.

## 3. Lenguaje de color (qué significa cada color)

| Color | Significa | Va en | **No** va en |
|---|---|---|---|
| Rojo `#DD2835` | "Tú" y "alto" | auto del jugador, señal de alto, foco rojo, freno | autos de tráfico, fachadas (el ladrillo va apagado: `#B9695A`) |
| Oro `#FFC700` | "Se toca" o "premio" | flechas, monedas, estrellas, gorra del copiloto, zona escolar | decorado grande |
| Verde `#3FA34D` | "Adelante" o "bien" | foco verde, peatón en verde, pedal de gas | vegetación (va apagada: `#5E9A5A`, `#6FAE5E`, `#2B6B3F`) |
| Azul cielo `#7FC8E8` | Vidrio e información | ventanas, botón del cinturón, fondo del retrato | — |
| Morado `#3F1B4E` y `#1E0F26` | Estructura | fondos de botones, contornos más oscuros | — |
| Blanco `#FFFFFF` | Texto y globos (los pone el juego) | — | fachadas: el "blanco" de una casa es `#F6F1EA` |

**Fachadas y decorado (apagados):**

| Color | Hex |
|---|---|
| Rosa | `#D46A8C` |
| Ocre | `#E2B46A` |
| Lila | `#BFB0D2` |
| Durazno | `#F3CFAA` |
| Ladrillo | `#B9695A` |
| Terracota | `#DA8068` |
| Blanco cal | `#F6F1EA` |
| Menta | `#9CC9A7` |
| Azul pastel | `#9DBFDC` |
| Talavera (solo cenefas y detalles) | `#3554A5` |

**Piel (alternar siempre):** `#F2C29B`, `#C68B59`, `#8A5A3B`.

**Jerarquía.** Lo que importa para jugar (auto, peatones, semáforos y señales) es lo más
brillante de la pantalla. El fondo nunca le gana.

## 4. Materiales

| Material | Cómo se dibuja |
|---|---|
| **Aplanado o estuco** (muros) | Color plano, un degradado suave y una sombra cel. Sin textura |
| **Vidrio** | Azul cielo con 1 o 2 destellos blancos en diagonal |
| **Metal** (tinacos, postes, rejas) | `#4A4256` con un solo brillo |
| **Plástico y botones** | Estilo "caramelo": cuerpo con degradado, brillo blanco en forma de píldora en el tercio superior y un labio inferior más oscuro (ver §5) |
| **Vegetación** | 2 o 3 tonos en grumos redondos, con orilla festoneada |
| **Cantera** | Gris cálido `#C9BDB4` con losas redondeadas |
| **Talavera** | Cobalto `#3554A5` sobre blanco cal, solo en cenefas, macetas, bancas y nichos |
| **Tela** (toldos, papel picado) | Rayas y orilla festoneada |

## 5. Interfaz: el botón "caramelo"

Todos los botones e íconos del HUD comparten esta construcción:
- forma redonda: círculo o rectángulo con esquinas muy redondeadas;
- contorno grueso `#1E0F26`;
- cuerpo con degradado: arriba un 12 % más claro, abajo el color base;
- brillo blanco en forma de píldora al 35 % en el tercio superior;
- labio inferior (como un botón físico) del color base un 25 % más oscuro;
- pictograma blanco o dorado, grande y simple, centrado.

## 6. Personajes

- **Proporciones chibi:** cabeza grande (≈1/3 de la altura), ojos grandes y amables,
  manos simples.
- **Expresiones:** siempre amables. "Sorprendido" significa ojos muy abiertos y boca en
  "o", nunca miedo ni llanto.
- **Ropa:** la de diario en México, sin marcas, uniformes reales ni letras.
- **Variedad obligatoria:** tono de piel, edad, complexión y peinado.

## 7. Toque poblano (dónde sí y dónde no)

**Sí:**
- fachadas de colores;
- cenefas de talavera;
- cantera y herrería en balcones y rejas;
- tinacos y tendederos en las azoteas;
- buganvilias;
- tienditas con cortina metálica;
- puestos (elotes, camotes, fruta);
- papel picado;
- kiosco en el parque.

**No:** iglesias como destino, el volcán dentro del nivel (solo en las tarjetas),
banderas, ni nada religioso o político.
