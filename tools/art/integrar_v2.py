#!/usr/bin/env python3
"""Integra el arte v2 (docs/arte_v2) desde arte_v2/entrada/ a assets/.

Cada imagen generada (fondo transparente o magenta #FF00FF) se recorta a su
contenido y se reduce al tamaño exacto que usa el juego, con el mismo nombre de
archivo que el asset actual. Así el código y las pruebas no cambian.

Uso: python3 tools/art/integrar_v2.py   (luego godot --headless --import)
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "arte_v2/entrada"
SPRITES = ROOT / "assets/sprites"

# Magenta de fondo: cuánto "magenta" (min(R, B) - G) tiene un pixel.
# >= KEY_HI es fondo puro y <= KEY_LO es dibujo. Entre los dos es una orilla
# mezclada: se le baja el alfa y se le quita el magenta (despill).
KEY_HI = 225
KEY_LO = 110


def load_rgba(path: Path) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    px = im.load()
    has_alpha = im.getextrema()[3][0] < 250
    if has_alpha:
        return im
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, _ = px[x, y]
            m = min(r, b) - g
            if m >= KEY_HI:
                px[x, y] = (0, 0, 0, 0)
            elif m > KEY_LO:
                a = (KEY_HI - m) / (KEY_HI - KEY_LO)
                # C = a*F + (1-a)*M  ->  F = (C - (1-a)*M) / a, con M = (255, 0, 255)
                fr = (r - (1 - a) * 255) / a
                fb = (b - (1 - a) * 255) / a
                fg = g / a
                px[x, y] = (
                    max(0, min(255, round(fr))),
                    max(0, min(255, round(fg))),
                    max(0, min(255, round(fb))),
                    round(a * 255),
                )
    return im


def bbox(im: Image.Image, threshold: int = 128) -> tuple:
    return im.getchannel("A").point(lambda a: 255 if a > threshold else 0).getbbox()


def cells(im: Image.Image, cols: int, rows: int) -> list:
    w, h = im.width // cols, im.height // rows
    return [im.crop((c * w, r * h, (c + 1) * w, (r + 1) * h)) for r in range(rows) for c in range(cols)]


def shrink(im: Image.Image, size: tuple) -> Image.Image:
    # Reducir en pasos de la mitad conserva mejor los contornos que un solo salto.
    while im.width >= size[0] * 2 and im.height >= size[1] * 2:
        im = im.resize((im.width // 2, im.height // 2), Image.LANCZOS)
    return im.resize(size, Image.LANCZOS)


def fit(im: Image.Image, size: tuple, anchor: str = "center") -> Image.Image:
    """Recorta al contenido, escala para caber en size sin deformar y lo coloca."""
    im = im.crop(bbox(im))
    scale = min(size[0] / im.width, size[1] / im.height)
    small = shrink(im, (max(1, round(im.width * scale)), max(1, round(im.height * scale))))
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    x = (size[0] - small.width) // 2
    y = (size[1] - small.height) // 2 if anchor == "center" else size[1] - small.height
    out.alpha_composite(small, (x, y))
    return out


def player_car() -> None:
    out = fit(load_rgba(SRC / "auto_jugador.png"), (69, 41))
    out.save(SPRITES / "player_car.png")


def houses() -> None:
    sheet = load_rgba(SRC / "casas_a.png")
    tiles = [fit(c, (128, 128), anchor="bottom") for c in cells(sheet, 3, 2)]
    out = Image.new("RGBA", (128 * len(tiles), 128), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        out.alpha_composite(t, (i * 128, 0))
    out.save(SPRITES / "city/casas.png")


def walk_sheet(name: str, frame: tuple, scale: float, union: tuple) -> Image.Image:
    """Tira de 8 cuadros: misma caja horizontal para todos (sin temblor) y pies abajo."""
    frames = cells(load_rgba(SRC / name), 4, 2)
    out = Image.new("RGBA", (frame[0] * len(frames), frame[1]), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        box = bbox(f)
        crop = f.crop((union[0], box[1], union[2], box[3]))
        small = shrink(crop, (max(1, round(crop.width * scale)), max(1, round(crop.height * scale))))
        x = i * frame[0] + (frame[0] - small.width) // 2
        out.alpha_composite(small, (x, frame[1] - small.height))
    return out


def child() -> None:
    frame = (46, 85)
    boxes = []
    for name in ("nino_camina.png", "nino_sorprendido.png"):
        boxes += [bbox(c) for c in cells(load_rgba(SRC / name), 4, 2)]
    union = (min(b[0] for b in boxes), 0, max(b[2] for b in boxes), 0)
    tallest = max(b[3] - b[1] for b in boxes)
    scale = min(frame[1] / tallest, frame[0] / (union[2] - union[0]))
    walk_sheet("nino_camina.png", frame, scale, union).save(SPRITES / "pedestrians/child_walk.png")
    walk_sheet("nino_sorprendido.png", frame, scale, union).save(SPRITES / "pedestrians/child_scared.png")


if __name__ == "__main__":
    player_car()
    houses()
    child()
    print("arte v2 integrado: player_car, casas, child_walk, child_scared")
