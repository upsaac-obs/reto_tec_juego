# RutaKids — plan de desarrollo

Una tarea por sesión. Una fase termina cuando se cumple su criterio de terminado. Reglas del proyecto en `CLAUDE.md`; diseño del juego en `docs/diseno.md`.

Hitos: prototipo 6 oct (hito 3) · pruebas listas 25 oct (hito 4) · entrega final 15 nov (hito 5).

## Fase 0 · Prototipo (5 y 6 oct)

**Terminado cuando:** el APK corre en un celular Android y se puede manejar, frenar en un alto y recibir una falta con mensaje.

- [ ] **Proyecto base.** Crear el proyecto con las decisiones técnicas de `CLAUDE.md` (Compatibility, 1280 × 720, Nearest, horizontal), la estructura de carpetas, `.gitignore` de Godot y los autoloads vacíos.
- [ ] **PlayerCar.** `PathFollow2D` sobre un `Path2D`. Botón de cinturón (sin cinturón no avanza), pedal verde (acelera), pedal rojo (frena), sin pedales baja de velocidad poco a poco. Flechas cambian de carril animando `v_offset`. Valores iniciales como `@export`: velocidad máxima 240 px/s, aceleración 120 px/s², frenado 300 px/s², desaceleración sin pedales 60 px/s² (el doble de los valores originales por el cambio a 1280 × 720).
- [ ] **Calle de prueba.** Una calle recta con tiles provisionales de colores planos y una `Camera2D` que sigue al auto.
- [ ] **StopZone y Crosswalk.** Alto: es falta si el auto cruza la línea sin bajar a menos de 5 px/s dentro de la zona. Paso peatonal: un peatón cruza; si el auto entra mientras está ocupado, frena solo y es falta grave.
- [ ] **HUD provisional.** Como el mockup: nombre del nivel, estrellas, puntos, engrane, flechas, cinturón y pedales. Mensaje simple de falta (sin copiloto todavía).
- [ ] **APK de prueba.** Exportar e instalar en un celular real. Anotar el tiempo de arranque.

## Fase 1 · Núcleo (7 al 12 oct)

**Terminado cuando:** los niveles 0, 1 y 2 se juegan de principio a fin, dan estrellas y el progreso se guarda.

- [ ] **RuleManager** con la API de `CLAUDE.md`: faltas, falta grave con regreso al punto de control, puntos y cálculo de estrellas.
- [ ] **Feedback**: copiloto provisional, texto con `tr()`, voz si existe el archivo, pausa de 2 segundos. Sonido alegre y "+10" para las acciones correctas.
- [ ] **Tarjeta de hábito** al final del nivel: ilustración, frase del decálogo y estrellas.
- [ ] **LevelData** (`resources/level_data.gd`): número, nombre, punto del decálogo, clave de la frase final, destino y escena.
- [ ] **SaveData**: `user://save.cfg` con estrellas por nivel, puntos, modo y silencio. No guarda nada en modo kiosco.
- [ ] **TrafficLight** (rojo, amarillo, verde con tiempos `@export`; la luz se distingue por posición, no solo por color), **SpeedZone** (falta si pasa el límite más de 2 s) y **BikeLane** (falta si el auto la invade).
- [ ] **Selección de niveles** con estrellas. Un nivel se desbloquea con 1 estrella en el anterior.
- [ ] **Nivel 0** (tutorial), **Nivel 1** (Primero el peatón) y **Nivel 2** (Respeta las señales). Ver tabla de niveles en `docs/diseno.md`.

## Fase 2 · Contenido (13 al 22 oct)

**Terminado cuando:** los niveles 3 a 8 se juegan completos en los modos Peque y Grande, y el modo kiosco funciona.

- [ ] **Pedestrian** con velocidad ajustable (normal, lenta para persona mayor y silla de ruedas) y animación de susto. **NPCCar** que sigue su ruta, guarda distancia y respeta semáforos.
- [ ] **LookMark** (falta si pasa la marca sin detenerse), **DarkZone** + botón de luces, **PhoneEvent** (falta si se toca el celular en movimiento; puntos si se contesta estacionado) y **BusStop** (falta si rebasa el camión detenido).
- [ ] **Niveles 3 a 8.**
- [ ] **Selección de edad** al abrir por primera vez (dos dibujos grandes, un toque) y diferencias entre Peque y Grande.
- [ ] **Pantalla de tutores**: estrellas por hábito, cambiar modo, borrar progreso, activar kiosco.
- [ ] **Modo kiosco**: todo abierto, sin guardar, sin Salir, reinicio tras 60 s sin tocar.
- [ ] **Audio**: efectos, música y voces hechas con IA para todas las claves de `textos.csv`.

## Fase 3 · Pruebas (20 al 25 oct)

**Terminado cuando:** se cumplen los números del SRS en un celular de gama baja.

- [ ] Abre en menos de 3 segundos (HU-01).
- [ ] Corre estable durante todo un nivel, sin bajar de 30 fps.
- [ ] Funciona completo en modo avión (REQ-5).
- [ ] Menos de 2% de sesiones con cierres inesperados y sin errores críticos en al menos 95% de las pruebas (sección 4.1 del SRS).
- [ ] Lista de pruebas por nivel y reporte para el hito 4.

## Fase 4 · Cierre (26 oct al 8 nov)

**Terminado cuando:** los 10 niveles tienen arte final y la app corre en iPhone y iPad.

- [ ] **AmbulanceEvent** (falta si no se orilla) y **niveles 9 y 10**.
- [ ] Cambiar el arte provisional por el de Pixel Engine y el hecho a mano.
- [ ] Exportar a iOS desde la Mac de Diego o Dylan y probar en iPad.
- [ ] Bloqueo de pantalla en Android para kiosco (lock task). En iPad lo hace el personal con Acceso Guiado.

## Fase 5 · Entrega (9 al 15 nov)

- [ ] Fichas de las tiendas y builds firmados.
- [ ] Manual de instalación y de uso para tutores y personal de ADO.
- [ ] Visto bueno de Fundación ADO.

## Assets con Pixel Engine (100 créditos)

Costos: generate_sprite 6 (modelo `oai_gpt25_low`) a 36 · animate_sprite 20 (`pixel-engine-v1.1`) a 26 · remove_background 2 · pixelate_image gratis.

Orden para gastar:

1. Copiloto (12, modelo `nb_flash`). ADO lo aprueba antes de seguir.
2. Auto del jugador (6). El tráfico usa el mismo sprite con `modulate`.
3. Peatón niño y persona mayor (12), luego la caminata de uno (20 + 2 para quitar fondo).
4. Camión de pasajeros, ciclista y ambulancia (18).
5. El resto se guarda para repetir los que salgan mal.

Reglas:

- Fondo liso de un color y vista desde arriba. Si sale de frente, repetir con imagen de referencia.
- Pasar siempre la paleta del juego en `palette`:

  ```text
  Oficiales: #DD2835 #3F1B4E #FFC700 #FFFFFF #4A235A #9C4B79 #E86F56 #534A5E
  Extra (propuesta): #1E0F26 #2A2230 #B8A6CC #F8C99B #3FA34D #2B6B3F #7FC8E8 #F2C29B #C68B59 #8A5A3B
  ```
- El primer sprite aprobado va como `source_job_id` en los siguientes.
- Tiles, señales y botones: dibujarlos a mano y pasarlos por `pixelate_image` con la misma paleta.
- Direccionales, luces y semáforos se animan en Godot cambiando colores.
- Descargar cada resultado a `assets/sprites/` el mismo día.
