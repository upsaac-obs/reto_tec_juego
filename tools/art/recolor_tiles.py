#!/usr/bin/env python3
"""Genera assets/tiles/street_v2.png desde street_provisional.png (docs/plan_visual.md, fase 0).

- Filas 0-3: las mismas posiciones del tileset provisional, recoloreadas
  (banqueta de cantera, pasto menos saturado). Así los niveles no cambian de coordenadas.
- Fila 4: variantes de pasto (0-3), de banqueta (4-5) y pasto del cerro (6-7).
- Fila 5: azoteas vistas desde arriba para el relleno detrás de las casas: 0-5 con
  tinaco, tendedero, impermeabilizante, macetas, tragaluz y antena; 6-7 lisas.

Uso: python3 tools/art/recolor_tiles.py   (luego abrir Godot o --import para reimportar)
Determinista: la misma semilla da el mismo PNG.
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "assets/tiles/street_provisional.png"
OUT = ROOT / "assets/tiles/street_v2.png"
T = 64


def rgb(h: str) -> tuple:
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


# Colores (CLAUDE.md, paleta oficial + extra del plan visual).
GRASS = rgb("#5E9A5A")
GRASS_DARK = rgb("#2B6B3F")
GRASS_LIGHT = rgb("#7CC56B")
CANTERA = rgb("#C9BDB4")
JUNTA = rgb("#968A85")
OUTLINE = rgb("#1E0F26")
SHADOW = rgb("#2A2230")
ASPHALT_DARK = rgb("#3A3344")
LILAC = rgb("#B8A6CC")
WARM = rgb("#F8C99B")
SKY_HORIZON = rgb("#E86F56")
CERRO = rgb("#4F7A4A")
CERRO_DARK = rgb("#3A5C3A")
LADRILLO = rgb("#B5523B")
WHITE = rgb("#FFFFFF")

# Recoloreo directo del tileset provisional (solo filas 0-1: suelo y calle).
RECOLOR = {
    rgb("#3fa34d"): GRASS,
    rgb("#b8a6cc"): CANTERA,
    rgb("#9c4b79"): JUNTA,
}

# Azoteas: (losa, pretil). Poco saturadas: son fondo (plan visual §1, pilar 2).
ROOF_COLORS = [
    (rgb("#B8ADA4"), rgb("#A0958C")),
    (rgb("#B39A8C"), rgb("#9A8275")),
    (rgb("#A9A2B0"), rgb("#918A99")),
    (rgb("#BDB298"), rgb("#A39880")),
]


def speckle(d: ImageDraw.ImageDraw, rnd: random.Random, box, colors, count):
    x0, y0, x1, y1 = box
    for _ in range(count):
        x, y = rnd.randrange(x0, x1), rnd.randrange(y0, y1)
        d.point((x, y), fill=rnd.choice(colors))


def grass_tile(rnd: random.Random, base, dark, light, extra=None) -> Image.Image:
    im = Image.new("RGBA", (T, T), base)
    d = ImageDraw.Draw(im)
    for _ in range(7):
        x, y = rnd.randrange(2, T - 4), rnd.randrange(2, T - 4)
        d.point([(x, y + 1), (x + 1, y), (x + 2, y + 1)], fill=dark)
    speckle(d, rnd, (0, 0, T, T), [light], 6)
    if extra:
        extra(d, rnd)
    return im


def flowers(color):
    def draw(d, rnd):
        for _ in range(4):
            x, y = rnd.randrange(4, T - 6), rnd.randrange(4, T - 6)
            d.point([(x, y - 1), (x - 1, y), (x + 1, y), (x, y + 1)], fill=color)
            d.point((x, y), fill=WARM)
    return draw


def pebbles(d, rnd):
    for _ in range(5):
        x, y = rnd.randrange(4, T - 6), rnd.randrange(4, T - 6)
        d.rectangle((x, y, x + 2, y + 1), fill=JUNTA)
        d.point((x, y), fill=CANTERA)


def sidewalk_base(src: Image.Image) -> Image.Image:
    # La banqueta lisa del provisional (3,0), ya recoloreada.
    return src.crop((3 * T, 0, 4 * T, T)).copy()


def sidewalk_registro(src) -> Image.Image:
    im = sidewalk_base(src)
    d = ImageDraw.Draw(im)
    d.rectangle((22, 22, 41, 41), fill=JUNTA, outline=OUTLINE)
    d.rectangle((25, 25, 38, 38), outline=ASPHALT_DARK)
    for y in (29, 33):
        d.line((26, y, 37, y), fill=ASPHALT_DARK)
    return im


def sidewalk_cracked(src) -> Image.Image:
    im = sidewalk_base(src)
    d = ImageDraw.Draw(im)
    d.line([(10, 8), (16, 18), (14, 26), (22, 34)], fill=JUNTA)
    d.line([(16, 18), (24, 16)], fill=JUNTA)
    return im


def roof_tile(rnd: random.Random, kind: int) -> Image.Image:
    slab, parapet = ROOF_COLORS[kind % len(ROOF_COLORS)]
    if kind >= 6:
        # Losa lisa sin borde: varias juntas forman una azotea grande (CityDresser elige
        # el tono por manzanas), así el fondo no se ve como cuadrícula.
        slab = ROOF_COLORS[0][0] if kind == 6 else ROOF_COLORS[2][0]
        im = Image.new("RGBA", (T, T), slab)
        speckle(ImageDraw.Draw(im), rnd, (0, 0, T, T), [ROOF_COLORS[0][1] if kind == 6 else ROOF_COLORS[2][1]], 12)
        return im
    im = Image.new("RGBA", (T, T), parapet)
    d = ImageDraw.Draw(im)
    # Losa con pretil de 3 px y sombra interior arriba-izquierda (luz arriba-izquierda).
    d.rectangle((3, 3, T - 4, T - 4), fill=slab)
    d.line((3, 3, T - 4, 3), fill=parapet)
    d.line((3, 3, 3, T - 4), fill=parapet)
    d.line((0, T - 1, T - 1, T - 1), fill=SHADOW)
    d.line((T - 1, 0, T - 1, T - 1), fill=SHADOW)
    speckle(d, rnd, (5, 5, T - 5, T - 5), [parapet], 10)
    if kind == 0:  # tinaco
        d.ellipse((34, 10, 52, 28), fill=SHADOW)
        d.ellipse((32, 8, 50, 26), fill=OUTLINE)
        d.ellipse((35, 11, 47, 23), fill=ASPHALT_DARK)
        d.point((40, 14), fill=JUNTA)
    elif kind == 1:  # tendedero
        for y in (20, 34):
            d.line((8, y, 56, y), fill=OUTLINE)
        cols = [SKY_HORIZON, rgb("#7FC8E8"), rgb("#FFC700"), WHITE, rgb("#E0457B")]
        for i, x in enumerate(range(11, 52, 9)):
            c = cols[(i + kind) % len(cols)]
            d.rectangle((x, 21, x + 5, 27), fill=c)
            d.rectangle((x + 2, 35, x + 6, 39), fill=cols[(i + 2) % len(cols)])
    elif kind == 2:  # impermeabilizante rojo
        d.rectangle((6, 6, T - 7, T - 7), fill=rgb("#A35B4A"))
        speckle(d, rnd, (7, 7, T - 8, T - 8), [rgb("#8E4F41")], 30)
    elif kind == 3:  # macetas
        for x, y in ((10, 10), (22, 10), (10, 44), (46, 44)):
            d.rectangle((x, y, x + 7, y + 7), fill=LADRILLO, outline=OUTLINE)
            d.rectangle((x + 2, y + 1, x + 5, y + 4), fill=GRASS_DARK)
    elif kind == 4:  # tragaluz
        d.rectangle((20, 20, 43, 43), fill=OUTLINE)
        d.rectangle((22, 22, 41, 41), fill=rgb("#7FC8E8"))
        d.line((23, 23, 30, 23), fill=WHITE)
    elif kind == 5:  # dos tinacos chicos y antena
        for x in (10, 26):
            d.ellipse((x, 38, x + 12, 50), fill=OUTLINE)
            d.ellipse((x + 2, 40, x + 10, 48), fill=ASPHALT_DARK)
        d.line((48, 10, 48, 30), fill=OUTLINE)
        d.line((42, 14, 54, 14), fill=OUTLINE)
        d.line((44, 20, 52, 20), fill=OUTLINE)
    return im


def main() -> None:
    rnd = random.Random(2026_11_02)
    src = Image.open(SRC).convert("RGBA")
    px = src.load()
    for y in range(2 * T):
        for x in range(src.width):
            c = px[x, y]
            if c in RECOLOR:
                px[x, y] = RECOLOR[c]
    out = Image.new("RGBA", (8 * T, 8 * T), (0, 0, 0, 0))
    out.paste(src, (0, 0))

    def put(col, row, tile):
        out.paste(tile, (col * T, row * T))

    put(0, 4, grass_tile(rnd, GRASS, GRASS_DARK, GRASS_LIGHT))
    put(1, 4, grass_tile(rnd, GRASS, GRASS_DARK, GRASS_LIGHT, flowers(LILAC)))
    put(2, 4, grass_tile(rnd, GRASS, GRASS_DARK, GRASS_LIGHT, flowers(SKY_HORIZON)))
    put(3, 4, grass_tile(rnd, GRASS, GRASS_DARK, GRASS_LIGHT, pebbles))
    put(4, 4, sidewalk_registro(src))
    put(5, 4, sidewalk_cracked(src))
    put(6, 4, grass_tile(rnd, CERRO, CERRO_DARK, GRASS))
    put(7, 4, grass_tile(rnd, CERRO, CERRO_DARK, GRASS, pebbles))
    for kind in range(8):
        put(kind, 5, roof_tile(rnd, kind))
    out.save(OUT)
    print(f"{OUT.relative_to(ROOT)}: {out.width}x{out.height}")


if __name__ == "__main__":
    main()
