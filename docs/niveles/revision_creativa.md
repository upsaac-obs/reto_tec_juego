# Revisión creativa de las fichas 5 a 8 (1 nov)

Revisó el director creativo. Las cuatro fichas quedan **aprobadas con cambios**. Los cambios de abajo son **obligatorios** y **mandan sobre la ficha** cuando no coinciden.

## Todos los niveles

- **Semáforos:** `yellow_time = 3.0` y `reaction_time = 1.0` en todos.
- **Conductor cuidadoso de `test_levels.gd`:** cada pieza usa la interfaz genérica de la base. Expone `careful_stop_x()` y `must_wait()`, y opcionalmente `careful_lane()` y `careful_range()`. Las piezas que piden luces se unen al grupo `needs_headlights`. No se agrega ninguna rama `is <Clase>` en `test_levels.gd`.
- **Textos:** variar cómo empiezan los aciertos. No todos con "¡Muy bien!".

## Nivel 5

1. `SpeedZone40.zone_length = 704`, de modo que la zona termina en 1344.
2. `SpeedZone30` en x = 3968 con `zone_length = 1376`, y `HintBallStreet` en x = 4000.
3. `YellowCrossing2.trigger_distance = 420`.
4. `PRISA_AMARILLO_AVISO_PEQUE,"Si ves la luz amarilla, toca el freno. ¡Ya viene el rojo!"`
5. `FALTA_AMARILLO,"La luz amarilla avisa que viene el rojo. Ahí frenamos con calma."` Reemplaza la línea actual y vale para los dos modos.

## Nivel 6

1. `TrafficLight1.reaction_time = 1.0`.
2. `Phone3` en x = 5900 y `HintPark` en x = 5930.
3. `FALTA_CELULAR,"Mientras el auto avanza, el celular espera. Lo contestamos estacionados."`
4. `level_06_traffic.gd` y la decoración de edificios se hacen al final. Si no da tiempo, se quitan.

## Nivel 7

1. El botón de luces parpadea; lo hace la base. El nivel solo usa el grupo `needs_headlights` e `is_car_inside()`.
2. `DarkTunnel.darkness = 0.65`.
3. `FALTA_LUCES_TUNEL,"En el túnel está oscuro. Prende las luces para que te vean."`
4. Las claves `TUTO_LUCES`, `TUTO_REFLEJANTE`, `TUTO_TUNEL` y `TUTO_LLUVIA` se llaman `LUCES_INTRO`, `LUCES_REFLEJANTE`, `LUCES_TUNEL` y `LUCES_LLUVIA`.
5. La lluvia se hace al final. Si baja de 60 fps en el A15, el nivel sale con `rain = false`.
6. Opcional: `DESTINO_CASA,"Nuestra casa"`.

## Nivel 8

1. **La falta del camión y su +10 usan `rule_id &"distance"`.**
   - Se quitan la clave `REGLA_BUS` y la nota de integración de §3.8.
   - Las pruebas 9.2 y 9.3 revisan `"distance"` y distinguen el camión por la clave del mensaje.
2. **Motos solo en Grande:** las crea el script del nivel. No se toca `npc_car.gd`.
3. `BusStop2.min_dwell = 5.0`.
4. `Cyclist2` en (8600, 0), con `cyclist_start_x = -560` y `cyclist_speed = 180`.
5. Prueba nueva: la bici pasa el frente del camión antes de que el camión arranque.
6. Textos:
   - `L08_BICI,"Ahí va una bici. Toca la flecha para alejarnos y darle espacio."`
   - `L08_CAMION_PEQUE,"Cuando el camión se detenga, mantén el freno hasta que arranque."`
   - `FALTA_CAMION,"Con el camión detenido, alguien puede cruzar por enfrente. Esperamos detrás."`
7. Opcional: `HintBus` en x = 3750. Si falta tiempo, se quitan `Cyclist1b` y las motos (máximo 30 min para las motos).

## Datos (los hace el coordinador al integrar)

Las claves del decálogo de `data/*.tres` se corrigen así:

| Nivel | Clave |
| --- | --- |
| 2 | `DECALOGO_04` |
| 4 | `DECALOGO_08` |
| 5 | `DECALOGO_02` |
| 8 | `DECALOGO_05` |
