#!/usr/bin/env python3
# Creación y desarrollo: Dylan Isaac Mancilla López
"""Integra el lote 10 de Codex (menús) a las dos apps nativas con los mismos nombres.

Lee arte_v2/entrada/ (acepta el sufijo _REVISAR), recorta cada celda a su dibujo,
la reduce y la guarda en:
  native/android/app/src/main/res/drawable-nodpi/<nombre>.png|jpg
  native/ios/ASSETS de menu de IOS/Assets.xcassets/<nombre>.imageset/
Los fondos y las tarjetas de edad van en JPEG (opacos); lo demás en PNG con alfa.

Uso: python3 tools/art/integrar_menus.py
"""
import json
from pathlib import Path

from PIL import Image

import integrar_v2 as v2

ROOT = v2.ROOT
ANDROID = ROOT / "native/android/app/src/main/res/drawable-nodpi"
IOS = ROOT / "native/ios/ASSETS de menu de IOS/Assets.xcassets"

# (hoja, columnas, filas) -> [(nombre, tamaño máximo en px)] en el orden de las celdas.
SHEETS = {
    ("botones", 3, 2): [("btn_play", 360), ("btn_back", 240), ("btn_exit", 240),
                        ("btn_sound_on", 240), ("btn_sound_off", 240), ("btn_tutors", 240)],
    ("estrellas", 3, 1): [("star_full", 128), ("star_empty", 128), ("icon_lock", 128)],
    ("copiloto_menu", 3, 1): [("copilot_wave", 420), ("copilot_cheer", 420), ("copilot_point", 420)],
}
# Imágenes opacas completas: (archivo, nombre, ancho en px).
OPAQUE = [("fondo_inicio", "bg_home", 1600), ("fondo_menus", "bg_menus", 1600),
          ("edad_peque", "age_peque", 720), ("edad_grande", "age_grande", 720)]


def save(im: Image.Image, name: str, jpeg: bool = False) -> None:
    ext = "jpg" if jpeg else "png"
    for old in ANDROID.glob(f"{name}.*"):
        old.unlink()
    if jpeg:
        im.convert("RGB").save(ANDROID / f"{name}.{ext}", quality=86, optimize=True)
    else:
        im.save(ANDROID / f"{name}.{ext}", optimize=True)
    folder = IOS / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    for old in folder.glob("*.*"):
        if old.name != "Contents.json":
            old.unlink()
    target = folder / f"{name}.{ext}"
    if jpeg:
        im.convert("RGB").save(target, quality=86, optimize=True)
    else:
        im.save(target, optimize=True)
    (folder / "Contents.json").write_text(json.dumps({
        "images": [{"filename": target.name, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")


def tight(im: Image.Image, max_px: int) -> Image.Image:
    box = v2.bbox(im)
    im = im.crop(box)
    scale = min(1.0, max_px / max(im.width, im.height))
    return v2.shrink(im, (max(1, round(im.width * scale)), max(1, round(im.height * scale))))


def main() -> None:
    for (stem, cols, rows), names in SHEETS.items():
        path = v2.find(stem)
        if path is None:
            print(f"  (falta {stem})")
            continue
        for cell, (name, size) in zip(v2.cells(v2.load_rgba(path), cols, rows), names):
            save(tight(cell, size), name)
            print(f"  {name}")
    for stem, name, width in OPAQUE:
        path = v2.find(stem)
        if path is None:
            print(f"  (falta {stem})")
            continue
        im = Image.open(path).convert("RGB")
        im = v2.shrink(im, (width, round(im.height * width / im.width)))
        save(im, name, jpeg=True)
        print(f"  {name}")


if __name__ == "__main__":
    main()
