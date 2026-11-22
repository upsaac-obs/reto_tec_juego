#!/usr/bin/env python3
"""Mapa de la selección de niveles en una sola pantalla (docs/plan_menus_mapa.md).

El camino hace una "S": paradas 1 a 4 arriba (de izquierda a derecha), vuelta en U a
la derecha y paradas 5 a 8 abajo (de regreso). Cada parada es su destino del juego y un
letrero de talavera con el pictograma del hábito y el número.

Pinta la parte fija con los sprites del juego y escribe lo que cada app dibuja encima.
Android (Compose) e iOS (SwiftUI) solo leen esto, así que el mapa es idéntico en las dos.

Coordenadas: el "contenido" mide CONTENT_W × CONTENT_H unidades; la app lo escala para
que quepa entero en la pantalla y lo centra. El fondo es más grande (BG_W × BG_H) para
cubrir pantallas más anchas (20:9) o más altas (iPad) sin bandas vacías.

Salida (en las dos apps):
  map_bg.jpg             fondo (pasto, camino, casas, árboles y destinos)
  sign_N.png, sign_N_lock.png   letrero de la parada N abierto y cerrado
  map_car.png            el auto del jugador, mirando a la derecha
  map_layout.json        posiciones (en unidades del contenido)
Uso: python3 tools/menu_map.py [--preview ruta.png]
"""
from __future__ import annotations

import argparse
import json
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools/art"))
import integrar_v2 as v2  # noqa: E402  (pictogramas de Codex: find + load_rgba)

SPRITES = ROOT / "assets/sprites"
FONT = ROOT / "assets/fonts/fredoka/Fredoka.ttf"
OUTS = [ROOT / "native/android/app/src/menu/assets/menu_map",
        ROOT / "native/ios/RutaKids/Resources/menu_map"]

CONTENT_W, CONTENT_H = 712, 400      # 16:9; todo lo importante cabe aquí
# El contenido se pega a la derecha de la pantalla (ANCHOR_X = 1): la vuelta en U llega al
# borde y lo que sobra en pantallas anchas queda a la izquierda, donde las calles siguen.
ANCHOR_X = 1.0
LEFT_EXT, RIGHT_EXT, V_EXT = 300, 24, 70   # fondo extra: cubre hasta ~23:9 y la altura del iPad
BG_W, BG_H = LEFT_EXT + CONTENT_W + RIGHT_EXT, CONTENT_H + 2 * V_EXT
OX, OY = LEFT_EXT, V_EXT
PX = 2                               # px por unidad en el fondo
SIGN_PX = 3                          # px por unidad en los letreros (se ven más de cerca)

ROW_A, ROW_B = 200.0, 352.0          # centro de cada calle (contenido)
TURN_X = 600.0                       # centro de la vuelta en U (su orilla llega a ~711)
STOPS_X = [90.0, 240.0, 390.0, 540.0]
ROAD_HALF, SIDEWALK, LANE = 24, 11, 12
DEST_MAX = (112, 76)
SIGN_W, SIGN_H = 46, 69              # letrero en unidades (aro de ~38)
SIGN_DX = -52                        # el letrero va a la izquierda de su destino
CAR_W = 34

ASPHALT = (83, 74, 94)
LINE = (240, 232, 222)
SIDEWALK_COLOR = (201, 189, 180)
CURB = (120, 108, 112)
OUTLINE = (30, 15, 38)
TALAVERA = (46, 77, 160)
WHITE = (255, 255, 255)
GOLD = (255, 199, 0)
PURPLE = (63, 27, 78)
GRAY, GRAY_D, POLE = (150, 140, 160), (110, 100, 122), (106, 97, 120)

DESTINATIONS = {  # nivel -> (sprite, región, ancho máximo)
    1: ("city/escuela.png", None, 112), 2: ("city/mercado.png", None, 112),
    3: ("city/casa_abuela.png", None, 104), 4: ("city/hospital.png", None, 112),
    5: ("city/terminal.png", None, 112), 6: ("city/casa_primos.png", None, 108),
    7: ("city/casas.png", (0, 0, 128, 128), 72), 8: ("city/biblioteca.png", None, 112),
}


def u(v: float) -> int:
    return round(v * PX)


def bg(x: float, y: float) -> tuple[float, float]:
    """Contenido -> fondo."""
    return x + OX, y + OY


# ------------------------------------------------------------------ sprites del juego

def sprite(path: str, region=None) -> Image.Image:
    im = Image.open(SPRITES / path).convert("RGBA")
    if region:
        im = im.crop(region)
    box = im.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox()
    return im.crop(box) if box else im


def fit(im: Image.Image, w: float, h: float, px: int = PX) -> Image.Image:
    s = min(w * px / im.width, h * px / im.height)
    return im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)


def place(canvas: Image.Image, im: Image.Image, cx: float, bottom: float) -> tuple:
    """Pega im centrado en cx (fondo) con su base en bottom. Devuelve su rect en contenido."""
    x, y = u(cx) - im.width // 2, u(bottom) - im.height
    canvas.alpha_composite(im, (x, y))
    return (x / PX - OX, y / PX - OY, im.width / PX, im.height / PX)


def darker(im: Image.Image, amount: float) -> Image.Image:
    shade = Image.new("RGBA", im.size, (40, 20, 50, 0))
    shade.putalpha(im.getchannel("A").point(lambda a: int(a * amount)))
    out = im.copy()
    out.alpha_composite(shade)
    return out


# ------------------------------------------------------------------ camino

def road_points() -> list[tuple[float, float]]:
    """Centro de la calle en contenido, en el sentido del recorrido."""
    pts = [(x, ROW_A) for x in range(-OX - 10, int(TURN_X), 6)]
    r = (ROW_B - ROW_A) / 2
    for i in range(41):
        a = -math.pi / 2 + math.pi * i / 40
        pts.append((TURN_X + r * math.cos(a), (ROW_A + ROW_B) / 2 + r * math.sin(a)))
    pts += [(x, ROW_B) for x in range(int(TURN_X), -OX - 11, -6)]
    return pts


def lane_path(pts: list) -> list[tuple[float, float]]:
    """Carril de la derecha según el sentido (se maneja por la derecha)."""
    out = []
    for i, (x, y) in enumerate(pts):
        a, b = pts[max(i - 1, 0)], pts[min(i + 1, len(pts) - 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        n = math.hypot(dx, dy) or 1.0
        out.append((x - dy / n * LANE, y + dx / n * LANE))
    return out


def draw_road(canvas: Image.Image, pts: list) -> None:
    d = ImageDraw.Draw(canvas)
    flat = [(u(bg(x, y)[0]), u(bg(x, y)[1])) for x, y in pts]
    for width, color in ((ROAD_HALF + SIDEWALK) * 2, SIDEWALK_COLOR), (ROAD_HALF * 2 + 3, CURB), (ROAD_HALF * 2, ASPHALT):
        d.line(flat, fill=color, width=u(width), joint="curve")
    dist = 0.0
    for a, b in zip(pts, pts[1:]):
        if dist % 26 < 14:
            ax, ay = bg(*a)
            bx, by = bg(*b)
            d.line((u(ax), u(ay), u(bx), u(by)), fill=LINE, width=u(2.2))
        dist += math.dist(a, b)


# ------------------------------------------------------------------ letreros

def font(size: int) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(FONT), size)
    try:
        f.set_variation_by_axes([650, 100])
    except OSError:
        pass
    return f


def pictogram(level: int) -> Image.Image:
    """Dibujo del hábito: la hoja de Codex (10-D) si ya está; si no, un sprite del juego."""
    path = v2.find("pictogramas")
    if path is not None:
        cells = v2.cells(v2.load_rgba(path), 3, 3)
        cell = cells[level]
        return cell.crop(v2.bbox(cell))
    signs = Image.open(SPRITES / "signals/signs.png").convert("RGBA")
    if level == 1:
        im = signs.crop((144, 0, 216, 74))
    elif level == 2:
        im = signs.crop((0, 0, 72, 74))
    elif level == 3:
        im = Image.open(SPRITES / "copilot/copilot.png").convert("RGBA").crop((0, 0, 105, 106))
    elif level == 4:
        im = Image.open(SPRITES / "pedestrians/elder.png").convert("RGBA").crop((11 * 64, 0, 12 * 64, 78))
    elif level == 5:
        im = signs.crop((72, 0, 144, 74))
        ImageDraw.Draw(im).text((35.5, 45), "30", font=font(26), fill=OUTLINE, anchor="mm")
    elif level == 6:
        im = Image.open(ROOT / "assets/ui/phone.png").convert("RGBA")
    elif level == 7:
        im = Image.open(ROOT / "assets/ui/icons/lights.png").convert("RGBA")
    else:
        im = Image.open(SPRITES / "vehicles/cyclist.png").convert("RGBA").crop((0, 0, 60, 29))
    box = im.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox()
    return im.crop(box)


def sign(level: int, locked: bool) -> Image.Image:
    """Letrero de talavera en poste: pictograma al centro y número (o candado) en una plaquita."""
    k = SIGN_PX * 4 / 64 * SIGN_W  # px por unidad de dibujo (64 de ancho) a 4×
    W, H = round(64 * k), round(96 * k)
    im = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(im)
    cx, cy, r = W / 2, 32 * k, 27 * k
    d.rounded_rectangle((cx - 4 * k, cy, cx + 4 * k, H - 4 * k), radius=2 * k, fill=OUTLINE)
    d.rectangle((cx - 2 * k, cy, cx + 1.5 * k, H - 6 * k), fill=POLE)
    d.ellipse((cx - 10 * k, H - 9 * k, cx + 10 * k, H - 1 * k), fill=OUTLINE)
    d.ellipse((cx - 8 * k, H - 8 * k, cx + 8 * k, H - 3 * k), fill=POLE)
    d.ellipse((cx - r - 3 * k, cy - r - 3 * k, cx + r + 3 * k, cy + r + 3 * k), fill=OUTLINE)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=GRAY_D if locked else TALAVERA)
    for i in range(14):
        a = i * 2 * math.pi / 14
        x, y = cx + (r - 4 * k) * math.cos(a), cy + (r - 4 * k) * math.sin(a)
        d.ellipse((x - 1.5 * k, y - 1.5 * k, x + 1.5 * k, y + 1.5 * k), fill=(190, 182, 200) if locked else WHITE)
    ri = r - 8 * k
    d.ellipse((cx - ri - k, cy - ri - k, cx + ri + k, cy + ri + k), fill=OUTLINE)
    d.ellipse((cx - ri, cy - ri, cx + ri, cy + ri), fill=(222, 216, 228) if locked else WHITE)
    pic = pictogram(level)
    s = min(2 * ri * 0.8 / pic.width, 2 * ri * 0.8 / pic.height)
    pic = pic.resize((max(1, round(pic.width * s)), max(1, round(pic.height * s))), Image.LANCZOS)
    if locked:
        gray = ImageOps.grayscale(pic.convert("RGB")).convert("RGBA")
        gray.putalpha(pic.getchannel("A").point(lambda a: int(a * 0.55)))
        pic = gray
    im.alpha_composite(pic, (round(cx - pic.width / 2), round(cy - pic.height / 2)))
    bx, by, br = cx + r * 0.72, cy + r * 0.72, 10 * k
    d.ellipse((bx - br - 2 * k, by - br - 2 * k, bx + br + 2 * k, by + br + 2 * k), fill=OUTLINE)
    d.ellipse((bx - br, by - br, bx + br, by + br), fill=GRAY if locked else GOLD)
    if locked:
        s_ = 6 * k
        d.arc((bx - s_ * 0.6, by - s_, bx + s_ * 0.6, by + s_ * 0.2), 180, 360, fill=OUTLINE, width=round(2.2 * k))
        d.rounded_rectangle((bx - s_ * 0.8, by - s_ * 0.35, bx + s_ * 0.8, by + s_ * 0.85), radius=1.5 * k, fill=OUTLINE)
    else:
        d.text((bx, by + 0.5 * k), str(level), font=font(round(14 * k)), fill=PURPLE, anchor="mm")
    return im.resize((round(SIGN_W * SIGN_PX), round(SIGN_H * SIGN_PX)), Image.LANCZOS)


# ------------------------------------------------------------------ mapa

def build(preview: Path | None) -> None:
    rnd = random.Random(5)
    canvas = Image.new("RGBA", (u(BG_W), u(BG_H)), (94, 154, 90, 255))
    tiles = Image.open(ROOT / "assets/tiles/street_v2.png").convert("RGBA")
    grass = [tiles.crop((c * 64, 256, c * 64 + 64, 320)).resize((u(32), u(32)), Image.LANCZOS) for c in (0, 0, 0, 1, 2)]
    for y in range(0, canvas.height, u(32)):
        for x in range(0, canvas.width, u(32)):
            canvas.alpha_composite(grass[rnd.randrange(len(grass))], (x, y))
    houses = [sprite("city/casas.png", (i * 128, 0, i * 128 + 128, 128)) for i in range(12)]
    trees = [sprite("city/arboles.png", (i * 64, 0, i * 64 + 64, 64)) for i in (0, 1, 4, 6, 7)]
    props = [sprite("city/mobiliario.png", (i * 64, 0, i * 64 + 64, 64)) for i in (0, 1, 3, 4)]
    top_a, top_b = ROW_A - ROAD_HALF - SIDEWALK - 2, ROW_B - ROAD_HALF - SIDEWALK - 2
    right_edge = TURN_X - 20

    # Árboles sueltos arriba, abajo y en el pasto del lado derecho.
    for _ in range(110):
        x, y = rnd.uniform(0, BG_W), rnd.choice([rnd.uniform(10, OY + 60), rnd.uniform(OY + CONTENT_H - 4, BG_H + 8)])
        place(canvas, fit(rnd.choice(trees), 24, 24), x, y)
    # Hilera de casas de atrás (más oscuras) a lo largo de cada calle.
    for top in (top_a, top_b):
        x = -OX
        while x < right_edge:
            w = rnd.uniform(40, 46)
            place(canvas, darker(fit(rnd.choice(houses), w, w), 0.22), *bg(x + w / 2, top - 40))
            x += w + rnd.uniform(0, 3)
    # Enfrente, entre destinos: solo árboles y objetos de banqueta.
    for top in (top_a, top_b):
        x = -OX + 6
        while x < right_edge:
            if all(not (sx - 64 < x < sx + 74) for sx in STOPS_X):
                if rnd.random() < 0.75:
                    place(canvas, fit(rnd.choice(trees), 26, 26), *bg(x, top + 2))
                else:
                    place(canvas, fit(rnd.choice(props), 13, 13), *bg(x, top + 6))
            x += rnd.uniform(20, 30)

    pts = road_points()
    draw_road(canvas, pts)
    path = lane_path(pts)

    stops = []
    for level in range(1, 9):
        row_top, sx = (top_a, STOPS_X[level - 1]) if level <= 4 else (top_b, STOPS_X[8 - level])
        file, region, width = DESTINATIONS[level]
        dest = place(canvas, fit(sprite(file, region), width, DEST_MAX[1]), *bg(sx + 10, row_top + 4))
        sign_x, sign_bottom = sx + SIGN_DX, row_top + 10
        sign_rect = (sign_x - SIGN_W / 2, sign_bottom - SIGN_H, SIGN_W, SIGN_H)
        hit_x0 = min(sign_rect[0], dest[0]) - 4
        hit_y0 = min(sign_rect[1], dest[1]) - 14
        hit_x1 = max(sign_rect[0] + SIGN_W, dest[0] + dest[2]) + 4
        hit_y1 = row_top + 12
        row_y = ROW_A if level <= 4 else ROW_B
        index = min(range(len(path)), key=lambda i: abs(path[i][0] - sx) + abs(pts[i][1] - row_y) * 10)
        stops.append({
            "level": level,
            "sign": {"x": round(sign_rect[0], 1), "y": round(sign_rect[1], 1), "width": SIGN_W, "height": SIGN_H},
            "stars": {"x": round(sign_x, 1), "y": round(sign_rect[1] - 7, 1), "size": 13},
            "hit": {"x": round(hit_x0, 1), "y": round(hit_y0, 1), "width": round(hit_x1 - hit_x0, 1),
                    "height": round(hit_y1 - hit_y0, 1)},
            "path_index": index,
        })
    start_index = min(range(len(path)), key=lambda i: abs(path[i][0] - 18) + abs(pts[i][1] - ROW_A) * 10)

    # Salida.
    for out in OUTS:
        out.mkdir(parents=True, exist_ok=True)
        for old in list(out.glob("map_*")) + list(out.glob("sign_*")):
            old.unlink()
        canvas.convert("RGB").save(out / "map_bg.jpg", quality=86, optimize=True)
        for level in range(1, 9):
            sign(level, False).save(out / f"sign_{level}.png", optimize=True)
            sign(level, True).save(out / f"sign_{level}_lock.png", optimize=True)
    car = sprite("player_car.png")
    car = car.resize((CAR_W * SIGN_PX, round(car.height * CAR_W * SIGN_PX / car.width)), Image.LANCZOS)
    layout = {
        "_doc": "Generado por tools/menu_map.py; no editar a mano. Unidades del contenido.",
        "content": [CONTENT_W, CONTENT_H],
        "anchor_x": ANCHOR_X,
        "background": {"file": "map_bg.jpg", "x": -OX, "y": -OY, "width": BG_W, "height": BG_H},
        "car": {"file": "map_car.png", "width": CAR_W, "height": round(car.height / SIGN_PX, 1)},
        "path": [[round(x, 1), round(y, 1)] for x, y in path],
        "start_index": start_index,
        "stops": stops,
    }
    for out in OUTS:
        car.save(out / "map_car.png", optimize=True)
        (out / "map_layout.json").write_text(json.dumps(layout, indent=1, ensure_ascii=False) + "\n")
    print(f"mapa: {len(stops)} paradas, camino de {len(path)} puntos")

    if preview:
        prev = canvas.copy()
        states = {1: 3, 2: 2}
        for s in stops:
            lvl = s["level"]
            sg = Image.open(OUTS[0] / f"sign_{lvl}{'' if lvl <= 3 else '_lock'}.png")
            sg = sg.resize((u(SIGN_W), u(SIGN_H)), Image.LANCZOS)
            prev.alpha_composite(sg, (u(s["sign"]["x"] + OX), u(s["sign"]["y"] + OY)))
            for i in range(3 if lvl in states else 0):
                star = Image.open(ROOT / "native/android/app/src/main/res/drawable-nodpi" /
                                  ("star_full.png" if i < states[lvl] else "star_empty.png")).convert("RGBA")
                star = fit(star, 13, 13)
                prev.alpha_composite(star, (u(s["stars"]["x"] + OX + (i - 1) * 14) - star.width // 2,
                                            u(s["stars"]["y"] + OY) - star.height // 2))
        p = path[stops[2]["path_index"]]
        c = car.resize((u(CAR_W), round(car.height * u(CAR_W) / car.width)), Image.LANCZOS)
        prev.alpha_composite(c, (u(p[0] + OX) - c.width // 2, u(p[1] + OY) - c.height // 2))
        d = ImageDraw.Draw(prev)
        d.rectangle((u(OX), u(OY), u(OX + CONTENT_W), u(OY + CONTENT_H)), outline=(255, 255, 255), width=2)
        prev.convert("RGB").save(preview)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--preview", type=Path, default=None, help="vista con estrellas y auto de muestra")
    build(ap.parse_args().preview)
