#!/usr/bin/env python3
"""Convierte un nivel guardado como copia completa de level.tscn en escena heredada.

Godot solo escribe escenas heredadas desde el editor; los niveles armados por
script (tools/level_builder.gd) salen como copia completa. Esto deja solo lo
propio del nivel: el mapa (Ground), Decor, las piezas de Rules, la curva de
Route y el carril inicial del auto. También quita las líneas `script =` de las
piezas instanciadas, que reinician sus ajustes.

Uso: python3 tools/make_inherited.py levels/level_03.tscn
"""
import re
import sys

BASE = "res://scenes/level/level.tscn"
KEEP_OVERRIDES = {"Ground": ["tile_map_data"], "Route": ["curve"], "Route/PlayerCar": ["start_lane"]}
BASE_NODES = {".", "Ground", "Rules", "Route", "Route/PlayerCar", "FollowCamera", "RuleManager", "Hud", "HabitCard"}
INDEX = {"Ground": ' index="0"', "Route": "", "Route/PlayerCar": ' index="0"'}


def node_path(section: str) -> str:
    name = re.search(r'name="([^"]+)"', section).group(1)
    parent = re.search(r'parent="([^"]+)"', section)
    if not parent:
        return "."
    return name if parent.group(1) == "." else f"{parent.group(1)}/{name}"


def convert(path: str) -> None:
    sections = re.split(r"\n(?=\[)", open(path).read().strip())[1:]
    ext = [s for s in sections if s.startswith("[ext_resource")]
    sub = [s for s in sections if s.startswith("[sub_resource")]
    nodes = [re.sub(r" unique_id=\d+", "", s) for s in sections if s.startswith("[node")]
    if 'instance=ExtResource' in nodes[0]:
        print(path, "ya es heredada")
        return

    root = re.search(r'name="([^"]+)"', nodes[0]).group(1)
    out = [f'[node name="{root}" instance=ExtResource("0_base")]']
    for section in nodes[1:]:
        p = node_path(section)
        if p in BASE_NODES:
            keep = KEEP_OVERRIDES.get(p)
            if not keep:
                continue
            name = p.split("/")[-1]
            parent = "." if "/" not in p else p.rsplit("/", 1)[0]
            props = [line for line in section.split("\n")[1:] if line.split(" = ")[0] in keep]
            out.append(f'[node name="{name}" parent="{parent}"{INDEX[p]}]\n' + "\n".join(props))
        else:
            if p == "Decor":
                section = section.replace('parent="."]', 'parent="." index="1"]', 1)
            if "instance=" in section:
                section = re.sub(r'\nscript = ExtResource\("[^"]+"\)', "", section)
            out.append(section)

    body = "\n\n".join(out)
    used_sub = [s for s in sub if re.search(r'id="([^"]+)"', s).group(1) in body]
    text = body + "\n".join(used_sub)
    used_ext = [e for e in ext if f'ExtResource("{re.search(r"id=\"([^\"]+)\"", e).group(1)}")' in text]
    header = "[gd_scene format=4]" if "tile_map_data" in body else "[gd_scene format=3]"
    base = f'[ext_resource type="PackedScene" path="{BASE}" id="0_base"]'
    result = header + "\n\n" + "\n".join([base] + used_ext) + "\n\n"
    if used_sub:
        result += "\n\n".join(used_sub) + "\n\n"
    open(path, "w").write(result + body + "\n")
    print(path, "heredada:", len(out), "nodos")


if __name__ == "__main__":
    for arg in sys.argv[1:]:
        convert(arg)
