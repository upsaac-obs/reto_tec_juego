# Generadores de los niveles 5 a 8

Cada `build_level_0X.gd` arma la versión completa de `levels/level_0X.tscn` con `tools/level_builder.gd`. Después `tools/make_inherited.py` la convierte en escena heredada de `scenes/level/level.tscn`.

Se corren con `-s`, desde la raíz del proyecto:

```bash
godot --headless --path . -s tools/niveles/build_level_05.gd
python3 tools/make_inherited.py levels/level_05.tscn
```

**Errores esperados en la consola.** Al correr con `-s` salen estos avisos antes de que termine:

```text
SCRIPT ERROR: Compile Error: Identifier not found: GameState
   at: GDScript::reload (res://resources/level_data.gd:48)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
ERROR: Failed to load script ".../build_level_0X.gd" with error "Compilation failed".
SCRIPT ERROR: Invalid call. Nonexistent function 'find_by_scene' in base 'GDScript'.
   at: _adopt_first_scene (res://autoload/bridge_client.gd:232)
```

Se pueden ignorar. En modo `-s` Godot compila los scripts antes de registrar los autoloads, y `level_data.gd` usa `GameState` mientras `game_state.gd` depende de `LevelData` (dependencia circular). Los scripts se vuelven a cargar enseguida y el generador guarda la escena. Si al final imprime `0` (OK), el nivel se generó bien. No afecta al juego ni a las pruebas.

**Cuidado:** algunos niveles se ajustaron a mano después de generarlos y regenerarlos borra esos ajustes.

| Nivel | Ajuste a mano |
| --- | --- |
| 5 | Peatón adulto en `CrosswalkTerminal` |
| 8 | `Traffic.traffic_light` |

El nivel 6 no tiene ajustes a mano: la casa de los primos (`casa_primos.png` en y = 292) ya está en su generador.

`make_inherited.py` lee los nodos de `scenes/level/level.tscn`, así que no copia al nivel los nodos de la base (`SpeedometerLayer`, `CityDresser`, `PerfOverlay`…). Godot pone ids nuevos a los `ext_resource` en cada corrida; si quieres un diff limpio, regresa los ids anteriores a mano.

Antes de regenerar un nivel, compara con `git diff`.
