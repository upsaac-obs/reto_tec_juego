#!/usr/bin/env python3
"""Tileset de calle del arte v2 (caricatura vectorial), por código.

Reescribe assets/tiles/street_v2.png con las MISMAS coordenadas de atlas que ya
usan los niveles y el CityDresser, así que no hay que repintar nada:

  fila 0: (0) pasto (1) pasto con matas (2) pasto con flores (3) banqueta
          (4) banqueta con guarnición abajo (calle debajo) (5) guarnición arriba
          (6) asfalto liso (7) asfalto con parche
  fila 1: (0) carril con media raya abajo (1) media raya arriba (2) paso de cebra
          (3) línea de alto a la derecha (4) meta (5) árbol (6) arbusto (7) pasto con flores blancas
  filas 2-3: casas provisionales de 2×2 (las tapa el CityDresser; quedan como azotea)
  fila 4: (0-3) pasto variado (4) banqueta con registro (5) banqueta con coladera
          (6-7) pasto del cerro
  fila 5: azoteas del fondo: (0) tinaco (1) tendedero (2) impermeabilizante
          (3) macetas (4) tragaluz (5) tinacos y antena (6-7) losa lisa en dos tonos

Colores y formas: docs/arte_v2/codex/estilo.md y la revisión de arte (§2.6).
Se dibuja a 4× y se reduce, para tener orillas suaves. Determinista.
Uso: python3 tools/art/tiles_v3.py
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/tiles/street_v2.png"
T = 64
K = 4  # sobremuestreo
TK = T * K


def rgb(h: str, a: int = 255) -> tuple:
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


ASPHALT = rgb("#534A5E")
ASPHALT_PATCH = rgb("#5A5166")
ASPHALT_DARK = rgb("#4A4255")
LINE = rgb("#F4EEE6")
CANTERA = rgb("#C9BDB4")
JOINT = rgb("#B3A69E")
SLAB_LIGHT = rgb("#D6CBC3")
CURB_TOP = rgb("#F4EEE6")
CURB = rgb("#E2D9D1")
CURB_SHADOW = rgb("#7E7280")
GRASS = rgb("#6FAE5E")
GRASS_CLUMP = rgb("#5E9A5A")
GRASS_LIGHT = rgb("#8CC46F")
HILL = rgb("#5E8E54")
HILL_CLUMP = rgb("#4F7A4A")
HILL_LIGHT = rgb("#6E9E62")
PEACH = rgb("#F3CFAA")
LILAC = rgb("#BFB0D2")
PINK = rgb("#D46A8C")
WHITE_FLOWER = rgb("#F6F1EA")
PLUM = rgb("#3F1B4E")
OUTLINE = rgb("#1E0F26")
METAL = rgb("#4A4256")
METAL_LIGHT = rgb("#6A6178")
LEAF = rgb("#5E9A5A")
LEAF_DARK = rgb("#2B6B3F")
LEAF_LIGHT = rgb("#7CC56B")
ROOF = rgb("#BDB4BC")
ROOF_B = rgb("#B4AFBE")
PARAPET = rgb("#D3CBD0")
ROOF_EDGE = rgb("#9A8E99")
WATERPROOF = rgb("#C9806E")
GLASS = rgb("#9DBFDC")
CLAY = rgb("#B9695A")


def new(color=(0, 0, 0, 0)):
    im = Image.new("RGBA", (TK, TK), color)
    return im, ImageDraw.Draw(im)


def done(im: Image.Image) -> Image.Image:
    return im.resize((T, T), Image.LANCZOS)


def s(v: float) -> int:
    """De px finales a px sobremuestreados."""
    return round(v * K)


def circle_wrap(d, cx, cy, r, fill):
    # Dibuja el círculo y sus copias al otro lado de cada orilla: el tile empata.
    for ox in (-TK, 0, TK):
        for oy in (-TK, 0, TK):
            d.ellipse((cx + ox - r, cy + oy - r, cx + ox + r, cy + oy + r), fill=fill)


# ---------------------------------------------------------------- suelos

def grass(rnd, base=GRASS, clump=GRASS_CLUMP, light=GRASS_LIGHT, flowers=None, n_clumps=3):
    im, d = new(base)
    for _ in range(n_clumps):
        cx, cy = rnd.randrange(TK), rnd.randrange(TK)
        for _ in range(3):
            r = s(rnd.uniform(5, 9))
            circle_wrap(d, cx + s(rnd.uniform(-8, 8)), cy + s(rnd.uniform(-5, 5)), r, clump)
    for _ in range(2):
        circle_wrap(d, rnd.randrange(TK), rnd.randrange(TK), s(rnd.uniform(2.5, 4)), light)
    if flowers:
        for _ in range(4):
            cx, cy = rnd.randrange(s(6), TK - s(6)), rnd.randrange(s(6), TK - s(6))
            for a in range(5):
                import math
                ang = a * 2 * math.pi / 5
                px, py = cx + s(2.4) * math.cos(ang), cy + s(2.4) * math.sin(ang)
                d.ellipse((px - s(1.8), py - s(1.8), px + s(1.8), py + s(1.8)), fill=flowers)
            d.ellipse((cx - s(1.4), cy - s(1.4), cx + s(1.4), cy + s(1.4)), fill=rgb("#FFC700"))
    return done(im)


def sidewalk(extra=None):
    """Losas de cantera de 64×32 desfasadas, junta suave y luz arriba de cada losa."""
    im, d = new(CANTERA)
    j = s(1)
    # Juntas horizontales a la mitad y en la orilla de arriba (la de abajo la pone el vecino).
    for y in (0, TK // 2):
        d.rectangle((0, y, TK, y + j * 2 - 1), fill=JOINT)
        d.rectangle((0, y + j * 2, TK, y + j * 3 - 1), fill=SLAB_LIGHT)
    # Juntas verticales: fila de arriba en x = 0, fila de abajo en la mitad (desfase).
    d.rectangle((0, 0, j * 2 - 1, TK // 2), fill=JOINT)
    d.rectangle((TK // 2, TK // 2, TK // 2 + j * 2 - 1, TK), fill=JOINT)
    if extra:
        extra(d)
    return im


def registro(d):
    x0, y0 = s(22), s(36)
    d.rounded_rectangle((x0, y0, x0 + s(20), y0 + s(14)), s(3), fill=METAL, outline=rgb("#3E3747"), width=s(1.5))
    for i in range(3):
        y = y0 + s(4 + i * 3.5)
        d.line((x0 + s(4), y, x0 + s(16), y), fill=METAL_LIGHT, width=s(1))


def coladera(d):
    cx, cy = s(46), s(14)
    d.ellipse((cx - s(7), cy - s(7), cx + s(7), cy + s(7)), fill=METAL, outline=rgb("#3E3747"), width=s(1.5))
    for i in (-3, 0, 3):
        d.line((cx - s(4), cy + s(i), cx + s(4), cy + s(i)), fill=METAL_LIGHT, width=s(1))


def curb(im, top: bool):
    """Guarnición de 8 px en la orilla de la banqueta que da a la calle."""
    d = ImageDraw.Draw(im)
    h = s(8)
    if top:  # la calle está arriba: guarnición en la orilla de arriba
        d.rectangle((0, 0, TK, h), fill=CURB)
        d.rectangle((0, s(2), TK, s(4)), fill=CURB_TOP)
        d.rectangle((0, 0, TK, s(2)), fill=CURB_SHADOW)
        d.rectangle((0, h, TK, h + s(1)), fill=JOINT)
    else:  # la calle está abajo
        d.rectangle((0, TK - h, TK, TK), fill=CURB)
        d.rectangle((0, TK - h - s(1), TK, TK - h), fill=JOINT)
        d.rectangle((0, TK - h, TK, TK - h + s(2)), fill=CURB_TOP)
        d.rectangle((0, TK - s(2), TK, TK), fill=CURB_SHADOW)
    return im


def asphalt(patch=False):
    im, d = new(ASPHALT)
    if patch:
        d.rounded_rectangle((s(10), s(22), s(40), s(40)), s(6), fill=ASPHALT_PATCH)
    return im


def lane(half_at_bottom: bool):
    """Media raya de carril (3 px de grueso) en la orilla: dos tiles juntos forman la raya de 6 px."""
    im, d = new(ASPHALT)
    w, ln = s(6), s(32)
    x0 = (TK - ln) // 2
    y = TK - w // 2 if half_at_bottom else -w // 2
    d.rounded_rectangle((x0, y, x0 + ln, y + w), w // 2, fill=LINE)
    return im


def crosswalk():
    im, d = new(ASPHALT)
    for x in (s(6), s(38)):
        d.rounded_rectangle((x, s(-4), x + s(20), TK + s(4)), s(3), fill=LINE)
    return im


def stop_line():
    im, d = new(ASPHALT)
    d.rounded_rectangle((TK - s(10), s(-4), TK - s(2), TK + s(4)), s(2), fill=LINE)
    return im


def finish():
    im, d = new(LINE)
    q = s(16)
    for i in range(4):
        for j in range(4):
            if (i + j) % 2:
                d.rectangle((i * q, j * q, (i + 1) * q - 1, (j + 1) * q - 1), fill=PLUM)
    return im


# ---------------------------------------------------------------- plantas (fila 1)

def blob(d, circles, fill, outline, width):
    for (x, y, r) in circles:
        d.ellipse((s(x) - s(r) - width, s(y) - s(r) - width, s(x) + s(r) + width, s(y) + s(r) + width), fill=outline)
    for (x, y, r) in circles:
        d.ellipse((s(x) - s(r), s(y) - s(r), s(x) + s(r), s(y) + s(r)), fill=fill)


def tree_tile(rnd):
    im = grass(rnd)
    big = Image.new("RGBA", (TK, TK), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    canopy = [(32, 30, 17), (22, 26, 11), (42, 26, 11), (26, 38, 11), (40, 38, 11)]
    blob(d, [(x + 3, y + 4, r) for x, y, r in canopy], rgb("#2A2230", 70), (0, 0, 0, 0), 0)
    blob(d, canopy, LEAF, LEAF_DARK, s(1.6))
    d.ellipse((s(20), s(18), s(34), s(30)), fill=LEAF_LIGHT)
    d.ellipse((s(23), s(20), s(28), s(24)), fill=rgb("#A6DA8F"))
    return Image.alpha_composite(im.resize((TK, TK), Image.NEAREST), big).resize((T, T), Image.LANCZOS)


def bush_tile(rnd):
    im = grass(rnd)
    big = Image.new("RGBA", (TK, TK), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    clumps = [(20, 36, 11), (34, 32, 13), (46, 38, 10), (28, 42, 10)]
    blob(d, [(x + 2, y + 3, r) for x, y, r in clumps], rgb("#2A2230", 70), (0, 0, 0, 0), 0)
    blob(d, clumps, rgb("#4F8E4F"), LEAF_DARK, s(1.6))
    d.ellipse((s(26), s(24), s(36), s(32)), fill=LEAF_LIGHT)
    return Image.alpha_composite(im.resize((TK, TK), Image.NEAREST), big).resize((T, T), Image.LANCZOS)


# ---------------------------------------------------------------- azoteas (fila 5 y casas viejas)

def roof(kind: int, rnd) -> Image.Image:
    if kind >= 6:
        # Losa lisa sin borde: el CityDresser junta varias en una azotea grande.
        im, d = new(ROOF if kind == 6 else ROOF_B)
        return done(im)
    # Sin pretil: los objetos van sobre la misma losa lisa (6,5), así la azotea se lee
    # continua y no como una cuadrícula de cajitas (el CityDresser solo los pone ahí).
    im, d = new(ROOF)
    if kind == 0:  # tinaco
        d.ellipse((s(34), s(12), s(54), s(32)), fill=METAL)
        d.ellipse((s(38), s(15), s(46), s(21)), fill=METAL_LIGHT)
    elif kind == 1:  # tendedero
        for y in (22, 36):
            d.line((s(10), s(y), s(54), s(y)), fill=ROOF_EDGE, width=s(1))
        cols = [rgb("#E8A0B4"), rgb("#9DBFDC"), rgb("#F3D88A"), WHITE_FLOWER, rgb("#A9D3B3")]
        for i, x in enumerate(range(13, 50, 9)):
            d.rounded_rectangle((s(x), s(22), s(x + 6), s(29)), s(1.5), fill=cols[i % 5])
            d.rounded_rectangle((s(x + 2), s(36), s(x + 7), s(41)), s(1.5), fill=cols[(i + 2) % 5])
    elif kind == 2:  # impermeabilizante
        d.rounded_rectangle((s(8), s(8), TK - s(8), TK - s(8)), s(4), fill=WATERPROOF)
    elif kind == 3:  # macetas
        for x, y in ((12, 12), (24, 12), (12, 44), (44, 44)):
            d.ellipse((s(x), s(y), s(x + 9), s(y + 9)), fill=CLAY)
            d.ellipse((s(x + 1.5), s(y + 0.5), s(x + 7.5), s(y + 6)), fill=LEAF)
    elif kind == 4:  # tragaluz
        d.rounded_rectangle((s(20), s(20), s(44), s(44)), s(4), fill=ROOF_EDGE)
        d.rounded_rectangle((s(22), s(22), s(42), s(42)), s(3), fill=GLASS)
        d.line((s(25), s(25), s(32), s(25)), fill=WHITE_FLOWER, width=s(1.5))
    elif kind == 5:  # tinacos chicos y antena
        for x in (10, 26):
            d.ellipse((s(x), s(38), s(x + 13), s(51)), fill=METAL)
            d.ellipse((s(x + 3), s(40), s(x + 7), s(44)), fill=METAL_LIGHT)
        d.line((s(48), s(10), s(48), s(30)), fill=METAL, width=s(1.5))
        d.line((s(42), s(14), s(54), s(14)), fill=METAL, width=s(1.5))
        d.line((s(44), s(20), s(52), s(20)), fill=METAL, width=s(1.5))
    return done(im)


def old_house_quadrant(color, qx: int, qy: int) -> Image.Image:
    """Casas provisionales de 2×2 tiles (filas 2-3): azotea con pretil, sin pixel art."""
    big = Image.new("RGBA", (TK * 2, TK * 2), GRASS)
    d = ImageDraw.Draw(big)
    d.rounded_rectangle((s(8), s(8), 2 * TK - s(8), 2 * TK - s(8)), s(10), fill=ROOF_EDGE)
    d.rounded_rectangle((s(10), s(10), 2 * TK - s(10), 2 * TK - s(10)), s(9), fill=PARAPET)
    d.rounded_rectangle((s(15), s(15), 2 * TK - s(15), s(70)), s(6), fill=ROOF)
    d.rounded_rectangle((s(15), s(74), 2 * TK - s(15), 2 * TK - s(15)), s(6), fill=color)
    tile = big.crop((qx * TK, qy * TK, (qx + 1) * TK, (qy + 1) * TK))
    return done(tile)


def main() -> None:
    rnd = random.Random(2026_11_11)
    out = Image.new("RGBA", (8 * T, 8 * T), (0, 0, 0, 0))

    def put(col, row, tile):
        if tile.size != (T, T):
            tile = done(tile)
        out.paste(tile, (col * T, row * T))

    put(0, 0, grass(rnd))
    put(1, 0, grass(rnd, n_clumps=5))
    put(2, 0, grass(rnd, flowers=PINK))
    put(3, 0, sidewalk())
    put(4, 0, curb(sidewalk(), top=False))
    put(5, 0, curb(sidewalk(), top=True))
    put(6, 0, asphalt())
    put(7, 0, asphalt(patch=True))
    put(0, 1, lane(half_at_bottom=True))
    put(1, 1, lane(half_at_bottom=False))
    put(2, 1, crosswalk())
    put(3, 1, stop_line())
    put(4, 1, finish())
    put(5, 1, tree_tile(rnd))
    put(6, 1, bush_tile(rnd))
    put(7, 1, grass(rnd, flowers=WHITE_FLOWER))
    for i, color in enumerate((rgb("#DA8068"), rgb("#BFB0D2"))):
        for qx in (0, 1):
            for qy in (0, 1):
                put(i * 2 + qx, 2 + qy, old_house_quadrant(color, qx, qy))
    put(0, 4, grass(rnd))
    put(1, 4, grass(rnd, flowers=LILAC))
    put(2, 4, grass(rnd, flowers=PEACH))
    put(3, 4, grass(rnd, n_clumps=5))
    put(4, 4, sidewalk(registro))
    put(5, 4, sidewalk(coladera))
    put(6, 4, grass(rnd, HILL, HILL_CLUMP, HILL_LIGHT))
    put(7, 4, grass(rnd, HILL, HILL_CLUMP, HILL_LIGHT, n_clumps=5))
    for kind in range(8):
        put(kind, 5, roof(kind, rnd))
    out.save(OUT)
    print(f"{OUT.relative_to(ROOT)}: {out.width}x{out.height}")


if __name__ == "__main__":
    main()
