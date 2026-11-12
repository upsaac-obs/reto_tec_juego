#!/usr/bin/env python3
"""Portal del túnel del nivel 7 visto desde arriba (lo dibuja el código, no Codex).

assets/sprites/city/tunel_portal.png (232 × 544): el cerro atraviesa la calle y el
auto pasa por debajo. La cara de cantera mira a la izquierda (entrada, el auto llega
por -x); la salida es el mismo sprite con flip_h. El centro vertical de la imagen es
el centro de la calle; la abertura cubre la calle (±64) y los muros del túnel (±84).
TunnelDecor (scenes/level/tunnel_decor.gd) lo coloca con la cara en start_x / end_x.

Se dibuja a 4× y se reduce. Uso: python3 tools/art/tunel_v3.py
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
K = 4
W, H = 232, 544
CY = H / 2
# Distancia del borde izquierdo de la imagen a la cara de cantera (TunnelDecor.FACE_X).
FACE_X = 30
OPEN_HALF = 84
# Fin del techo sobre la calle: el auto queda oculto solo entre FACE_X y ROOF_END.
ROOF_END = 92


def rgb(h: str, a: int = 255) -> tuple:
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


OUTLINE = rgb("#1E0F26")
HILL_EDGE = rgb("#3E6B3F")
HILL = rgb("#6E9E62")
HILL_HI = rgb("#86B472")
HILL_CLUMP = rgb("#5E8E54")
CANTERA = rgb("#E3BE98")
CANTERA_HI = rgb("#F2D7B8")
CANTERA_JOINT = rgb("#B98E6C")
PINE = rgb("#3F6E45")
PINE_HI = rgb("#5C8F57")
TRUNK_SHADOW = rgb("#2F4F35", 90)


def s(v: float) -> float:
    return v * K


def box(x0, y0, x1, y1):
    return (s(x0), s(y0), s(x1), s(y1))


def mound_shapes(grow: float) -> list:
    """Cerro: dos lomas (arriba y abajo de la calle) unidas por el techo del túnel."""
    g = grow
    return [
        ("ellipse", box(34 - g, 4 - g, W - 4 + g, CY - 58 + g)),
        ("ellipse", box(34 - g, CY + 58 - g, W - 4 + g, H - 4 + g)),
        ("rect", box(40 - g, CY - 130 - g, ROOF_END + g, CY + 130 + g)),
    ]


def draw_shapes(d: ImageDraw.ImageDraw, shapes: list, fill) -> None:
    for kind, b in shapes:
        if kind == "ellipse":
            d.ellipse(b, fill=fill)
        else:
            d.rounded_rectangle(b, radius=s(14), fill=fill)


def pine(d: ImageDraw.ImageDraw, x: float, y: float, r: float) -> None:
    d.ellipse(box(x - r + 3, y - r + 4, x + r + 3, y + r + 4), fill=TRUNK_SHADOW)
    d.ellipse(box(x - r - 1.5, y - r - 1.5, x + r + 1.5, y + r + 1.5), fill=OUTLINE)
    d.ellipse(box(x - r, y - r, x + r, y + r), fill=PINE)
    d.ellipse(box(x - r * 0.65, y - r * 0.7, x + r * 0.15, y + r * 0.1), fill=PINE_HI)


def portal() -> Image.Image:
    im = Image.new("RGBA", (W * K, H * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # Sombra de la boca sobre la calle, antes de la cara (se lee como "aquí se entra").
    shade = Image.new("RGBA", im.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    for i in range(FACE_X):
        a = int(110 * (i / FACE_X) ** 1.6)
        sd.rectangle(box(i, CY - OPEN_HALF + 6, i + 1, CY + OPEN_HALF - 6), fill=(20, 12, 30, a))
    # Sombra del techo hacia adentro del túnel.
    for i in range(18):
        a = int(120 * (1 - i / 18) ** 1.4)
        sd.rectangle(box(ROOF_END + i, CY - OPEN_HALF + 6, ROOF_END + i + 1, CY + OPEN_HALF - 6), fill=(20, 12, 30, a))
    im.alpha_composite(shade)
    # Cerro: contorno, borde y relleno.
    draw_shapes(d, mound_shapes(3.0), OUTLINE)
    draw_shapes(d, mound_shapes(0.0), HILL_EDGE)
    inner = Image.new("RGBA", im.size, (0, 0, 0, 0))
    draw_shapes(ImageDraw.Draw(inner), mound_shapes(-4.0), HILL)
    im.alpha_composite(inner)
    # Brillo arriba a la izquierda de cada loma y matas de pasto.
    d.ellipse(box(56, 26, 170, 96), fill=HILL_HI)
    d.ellipse(box(56, CY + 84, 170, CY + 140), fill=HILL_HI)
    rnd = random.Random(7)
    mask = Image.new("L", im.size, 0)
    draw_shapes(ImageDraw.Draw(mask), mound_shapes(-8.0), 255)
    for _ in range(40):
        x, y = rnd.uniform(46, W - 6), rnd.uniform(6, H - 6)
        if mask.getpixel((int(s(x)), int(s(y)))) and abs(y - CY) > 30:
            d.ellipse(box(x - 4, y - 2.5, x + 4, y + 2.5), fill=HILL_CLUMP)
    # Pinos en las lomas, lejos de la calle.
    for x, y, r in ((116, 56, 17), (170, 92, 14), (196, 150, 12), (88, 128, 11), (144, 160, 10), (118, H - 60, 17), (172, H - 98, 14), (198, H - 156, 12), (88, H - 132, 11), (146, H - 166, 10)):
        pine(d, x, y, r)
    # Cara de cantera: franja de sillares de orilla a orilla de la abertura.
    top, bottom = CY - OPEN_HALF - 22, CY + OPEN_HALF + 22
    d.rounded_rectangle(box(FACE_X - 3, top - 3, FACE_X + 25, bottom + 3), radius=s(6), fill=OUTLINE)
    d.rounded_rectangle(box(FACE_X, top, FACE_X + 22, bottom), radius=s(4), fill=CANTERA)
    d.rectangle(box(FACE_X + 2, top + 3, FACE_X + 7, bottom - 3), fill=CANTERA_HI)
    y = top + 14
    while y < bottom - 6:
        d.line((s(FACE_X + 1), s(y), s(FACE_X + 21), s(y)), fill=CANTERA_JOINT, width=round(s(1.2)))
        y += 15
    # Clave al centro y estribos en las puntas.
    d.rounded_rectangle(box(FACE_X - 7, CY - 11, FACE_X + 27, CY + 11), radius=s(4), fill=OUTLINE)
    d.rounded_rectangle(box(FACE_X - 4.5, CY - 8.5, FACE_X + 24.5, CY + 8.5), radius=s(3), fill=CANTERA_HI)
    for yc in (top + 6, bottom - 6):
        d.rounded_rectangle(box(FACE_X - 9, yc - 14, FACE_X + 29, yc + 14), radius=s(5), fill=OUTLINE)
        d.rounded_rectangle(box(FACE_X - 6, yc - 11, FACE_X + 26, yc + 11), radius=s(4), fill=CANTERA)
        d.rectangle(box(FACE_X - 4, yc - 9, FACE_X + 2, yc + 9), fill=CANTERA_HI)
    return im.resize((W, H), Image.LANCZOS)


if __name__ == "__main__":
    portal().save(ROOT / "assets/sprites/city/tunel_portal.png")
    print("portal del túnel listo")
