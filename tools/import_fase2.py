#!/usr/bin/env python3
"""Importa los assets de ~/claude/assest2 (fase 2) al proyecto.
Uso: python3 tools/import_fase2.py  (desde la raíz del proyecto de Godot)"""
import os
import shutil
import sys
sys.path.insert(0, os.path.dirname(__file__))
from import_sprites import (load, crop_frac, crop_px, grid_cells, trim, scale_all, rotate_cw, strip,
                            save_png, write_sprite_frames)

SRC = os.path.expanduser("~/claude/assest2")
PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def out(rel):
    return os.path.join(PROJECT, rel)


def raw(name, rel_dir):
    """Guarda la imagen original junto al sprite como *_raw.jpg (no se exporta)."""
    base = os.path.splitext(name)[0]
    shutil.copyfile(os.path.join(SRC, name), out(f"{rel_dir}/{base}_raw.jpg"))


def person(name, rel_dir, cols, rows, height, anims, crop=(0, 0, 1, 1)):
    sheet = crop_frac(load(os.path.join(SRC, name)), crop)
    cells = scale_all(grid_cells(sheet, cols, rows), height=height)
    canvas, size = strip(cells, "bottom")
    base = os.path.splitext(name)[0]
    save_png(canvas, out(f"{rel_dir}/{base}.png"))
    write_sprite_frames(out(f"{rel_dir}/{base}_frames.tres"), f"res://{rel_dir}/{base}.png", size, len(cells), anims)
    raw(name, rel_dir)
    print(f"{base}: {len(cells)} cuadros de {size}")


def single(name, rel_path, fit, crop=(0, 0, 1, 1), rotate=False):
    cells = [trim(crop_frac(load(os.path.join(SRC, name)), crop))]
    if rotate:
        cells = rotate_cw(cells)
    cells = scale_all(cells, fit=fit)
    canvas, size = strip(cells, "center")
    save_png(canvas, out(rel_path))
    print(f"{os.path.basename(rel_path)}: {size}")


def main():
    # Personas (alineadas por los pies, como child_frames y elder_frames)
    person("adult.jpg", "assets/sprites/pedestrians", 8, 2, 88,
           {"walk": (list(range(8)), 8, True), "scared": ([9, 10, 11, 12, 13], 8, False), "idle": ([14], 1, True)})
    person("girl.jpg", "assets/sprites/pedestrians", 8, 2, 80,
           {"walk": (list(range(8)), 8, True), "scared": ([9, 10, 11, 12], 8, False), "idle": ([14], 1, True)},
           crop=(0, 0.13, 1, 1))
    person("wheelchair.jpg", "assets/sprites/pedestrians", 6, 2, 78,
           {"walk": ([1, 2, 10, 11], 4, True), "scared": ([3, 7, 8, 9], 6, False), "idle": ([10], 1, True),
            "happy": ([0, 4, 5, 6], 4, True)})

    # Ciclista visto desde arriba: mira hacia arriba en la imagen, se gira hacia +x
    sheet = load(os.path.join(SRC, "cyclist1.jpg"))
    cells = scale_all(rotate_cw(grid_cells(sheet, 6, 2)), width=60)
    canvas, size = strip(cells, "center")
    save_png(canvas, out("assets/sprites/vehicles/cyclist.png"))
    write_sprite_frames(out("assets/sprites/vehicles/cyclist_frames.tres"), "res://assets/sprites/vehicles/cyclist.png",
                        size, len(cells), {"ride": (list(range(6)), 8, True), "idle": ([0], 1, True)})
    raw("cyclist1.jpg", "assets/sprites/vehicles")
    print(f"cyclist: {len(cells)} cuadros de {size}")

    # Vehículos vistos desde arriba, con el frente hacia +x (como player_car.png, 69 × 41)
    os.makedirs(out("assets/sprites/vehicles"), exist_ok=True)
    single("npc_car.jpg", "assets/sprites/vehicles/npc_car.png", (70, 40))
    single("motorcycle.jpg", "assets/sprites/vehicles/motorcycle.png", (60, 30))
    single("ambulance.jpg", "assets/sprites/vehicles/ambulance.png", (104, 50))
    single("bus.jpg", "assets/sprites/vehicles/bus.png", (140, 80), crop=(0, 0, 0.485, 1))
    for f, d in [("npc_car.jpg", "vehicles"), ("motorcycle.jpg", "vehicles"), ("ambulance.jpg", "vehicles"), ("bus.jpg", "vehicles")]:
        raw(f, f"assets/sprites/{d}")
    os.makedirs(out("assets/sprites/city"), exist_ok=True)
    single("bus.jpg", "assets/sprites/city/bus_stop.png", (128, 80), crop=(0.505, 0, 0.84, 1))
    single("bus.jpg", "assets/sprites/city/bus_stop_sign.png", (28, 64), crop=(0.84, 0, 1, 1))

    # Señales y marcas
    single("look_mark.jpg", "assets/sprites/signals/look_mark.png", (104, 104))
    raw("look_mark.jpg", "assets/sprites/signals")
    sheet = load(os.path.join(SRC, "pedestrian_light.jpg"))
    cells = scale_all(grid_cells(sheet, 3, 1), height=104)
    canvas, size = strip(cells, "bottom")
    save_png(canvas, out("assets/sprites/signals/pedestrian_light.png"))
    raw("pedestrian_light.jpg", "assets/sprites/signals")
    print(f"pedestrian_light: 3 cuadros de {size} (apagado, rojo, verde)")

    # Ciudad (city2.jpg): paneles separados por blanco, con títulos; se cortan por
    # píxel un poco adentro de cada panel (el blanco del hospital no es fondo)
    city = load(os.path.join(SRC, "city2.jpg"))
    buildings = scale_all([trim(crop_px(city, b)) for b in [(40, 56, 319, 358), (334, 56, 606, 358), (621, 56, 899, 358)]], fit=(160, 160))
    canvas, size = strip(buildings, "bottom")
    save_png(canvas, out("assets/sprites/city/edificios.png"))
    print(f"edificios: 3 cuadros de {size}")
    for name, box, fit in [("hospital", (942, 56, 1368, 358), (300, 220)), ("terminal", (40, 428, 699, 734), (380, 190)),
                           ("tunel_entrada", (779, 428, 1063, 734), (256, 256)), ("tunel_salida", (1079, 428, 1368, 734), (256, 256))]:
        cells = scale_all([trim(crop_px(city, box))], fit=fit)
        canvas, size = strip(cells, "center")
        save_png(canvas, out(f"assets/sprites/city/{name}.png"))
        print(f"{name}: {size}")
    raw("city2.jpg", "assets/sprites/city")

    # Interfaz
    single("phone.jpg", "assets/ui/phone.png", (180, 320))
    raw("phone.jpg", "assets/ui")


if __name__ == "__main__":
    main()
