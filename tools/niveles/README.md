# Generadores de los niveles 5 a 8

Cada `build_level_0X.gd` arma la versión completa de `levels/level_0X.tscn` con `tools/level_builder.gd`. Después `tools/make_inherited.py` la convierte en escena heredada de `scenes/level/level.tscn`.

Se corren como escena (no con `-s`), porque usan los autoloads (`GameState`, `Feedback`). Desde la raíz del proyecto:

```bash
godot --headless --path . -s tools/niveles/build_level_05.gd   # si falla por autoloads, córrelo desde una escena temporal
python3 tools/make_inherited.py levels/level_05.tscn
```

**Cuidado:** algunos niveles se ajustaron a mano después de generarlos y regenerarlos borra esos ajustes.

| Nivel | Ajuste a mano |
| --- | --- |
| 5 | Peatón adulto en `CrosswalkTerminal` |
| 8 | `Traffic.traffic_light` |

Antes de regenerar un nivel, compara con `git diff`.
