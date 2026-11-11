#!/usr/bin/env python3
"""Sprites del arte v2 que se dibujan por código (no los genera Codex).

- assets/sprites/signals/traffic_light.png (48 × 128): caja del semáforo. Los focos
  los enciende traffic_light.gd en LAMP_CENTERS (24,16), (24,42), (24,65), radio 9:
  aquí solo van los huecos apagados exactamente ahí.
- assets/sprites/signals/look_mark.png (104 × 96): ojos y flecha doble del cruce
  ciego (nivel 3), en oro con contorno morado.

Se dibuja a 4× y se reduce. Uso: python3 tools/art/senales_v3.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
K = 4


def rgb(h: str, a: int = 255) -> tuple:
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


PLUM = rgb("#3F1B4E")
PLUM_LIGHT = rgb("#5A2E6B")
OUTLINE = rgb("#1E0F26")
SOCKET = rgb("#2A2230")
POLE = rgb("#6A6178")
POLE_LIGHT = rgb("#8A8098")
GOLD = rgb("#FFC700")
GOLD_DARK = rgb("#B07A00")
WHITE = rgb("#FFFFFF")


def s(v: float) -> float:
    return v * K


def traffic_light() -> None:
    w, h = 48, 128
    im = Image.new("RGBA", (w * K, h * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # Poste y base.
    d.rounded_rectangle((s(20), s(74), s(28), s(124)), s(3), fill=OUTLINE)
    d.rounded_rectangle((s(21.5), s(74), s(26.5), s(123)), s(2), fill=POLE)
    d.line((s(23), s(76), s(23), s(120)), fill=POLE_LIGHT, width=round(s(1.2)))
    d.rounded_rectangle((s(14), s(120), s(34), s(127)), s(3), fill=OUTLINE)
    d.rounded_rectangle((s(15.5), s(121), s(32.5), s(126)), s(2), fill=POLE)
    # Caja con esquinas muy redondas, degradado simple (franja clara a la izquierda).
    d.rounded_rectangle((s(8), s(2), s(40), s(78)), s(10), fill=OUTLINE)
    d.rounded_rectangle((s(10.5), s(4.5), s(37.5), s(75.5)), s(8), fill=PLUM)
    d.rounded_rectangle((s(12.5), s(7), s(17), s(70)), s(2.5), fill=PLUM_LIGHT)
    for cy in (16, 42, 65):
        # Visera arriba del foco y hueco apagado (el código pinta el foco encima).
        d.chord((s(24 - 13), s(cy - 13), s(24 + 13), s(cy + 9)), 180, 360, fill=OUTLINE)
        d.ellipse((s(24 - 10.5), s(cy - 10.5), s(24 + 10.5), s(cy + 10.5)), fill=OUTLINE)
        d.ellipse((s(24 - 9), s(cy - 9), s(24 + 9), s(cy + 9)), fill=SOCKET)
    im.resize((w, h), Image.LANCZOS).save(ROOT / "assets/sprites/signals/traffic_light.png")


def look_mark() -> None:
    w, h = 104, 96
    im = Image.new("RGBA", (w * K, h * K), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # Dos ojos: blanco con aro oro y pupila morada mirando a los lados.
    for cx, look in ((28, -1), (76, 1)):
        d.ellipse((s(cx - 23), s(4), s(cx + 23), s(50)), fill=PLUM)
        d.ellipse((s(cx - 20), s(7), s(cx + 20), s(47)), fill=GOLD)
        d.ellipse((s(cx - 15), s(12), s(cx + 15), s(42)), fill=WHITE)
        px = cx + 5 * look
        d.ellipse((s(px - 8), s(19), s(px + 8), s(35)), fill=PLUM)
        d.ellipse((s(px - 4.5), s(21.5), s(px - 0.5), s(25.5)), fill=WHITE)
    # Flecha doble ←→ en oro con contorno morado.
    def arrow(grow: float, color):
        pts = [(4, 74), (24, 58), (24, 68), (80, 68), (80, 58), (100, 74), (80, 90), (80, 80), (24, 80), (24, 90)]
        cx, cy = 52, 74
        out = []
        for x, y in pts:
            dx, dy = x - cx, y - cy
            out.append((s(cx + dx * (1 + grow / abs(dx or 1) if dx else 1)), s(cy + dy + (grow if dy > 0 else -grow if dy < 0 else 0))))
        d.polygon(out, fill=color)
    arrow(3.0, PLUM)
    arrow(0.0, GOLD)
    d.rectangle((s(26), s(70), s(78), s(72)), fill=rgb("#FFE27A"))
    im.resize((w, h), Image.LANCZOS).save(ROOT / "assets/sprites/signals/look_mark.png")


if __name__ == "__main__":
    traffic_light()
    look_mark()
    print("semáforo y look_mark v2 listos")
