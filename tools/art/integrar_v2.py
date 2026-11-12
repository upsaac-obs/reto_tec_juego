#!/usr/bin/env python3
"""Integra el arte v2 (docs/arte_v2/codex) desde arte_v2/entrada/ a assets/.

Cada entrega de Codex (fondo transparente o magenta #FF00FF) se parte en su
cuadrícula, cada celda se recorta a su contenido y se reduce al tamaño exacto que
usa el juego, con el mismo nombre de archivo que el asset actual. Solo procesa
las entregas que existan; lo que falta se queda como está.

Decisiones del 11-11 (LEEME_CODEX.md §7): HUD al tamaño en que se ve (hud.tscn a
escala 1), peatones al 80 % dentro de su cuadro y decorado desaturado.

Uso: python3 tools/art/integrar_v2.py   (luego godot --headless --import)
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "arte_v2/entrada"
SPRITES = ROOT / "assets/sprites"
ICONS = ROOT / "assets/ui/icons"

# Magenta de fondo: "magenta" de un pixel = min(R, B) - G. >= KEY_HI es fondo puro,
# <= KEY_LO es dibujo; en medio es orilla mezclada: se baja el alfa y se quita el
# magenta (despill), suponiendo C = a*F + (1-a)*M con M = (255, 0, 255).
KEY_HI = 225.0
KEY_LO = 110.0
# Peatones al 80 % de su cuadro (para que quepan en un carril).
PEDESTRIAN_SCALE = 0.8
# Decorado: saturación y valor (para no competir con el auto ni los peatones).
DECOR_SAT = 0.85
DECOR_VAL = 0.95


# ------------------------------------------------------------------ utilidades

def load_rgba(path: Path) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    a = np.asarray(im).astype(np.float32)
    if a[..., 3].min() < 250:  # ya trae alfa
        return im
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    m = np.minimum(r, b) - g
    alpha = np.clip((KEY_HI - m) / (KEY_HI - KEY_LO), 0.0, 1.0)
    safe = np.maximum(alpha, 1e-3)
    out = np.empty_like(a)
    out[..., 0] = (r - (1 - alpha) * 255) / safe
    out[..., 1] = g / safe
    out[..., 2] = (b - (1 - alpha) * 255) / safe
    out[..., 3] = alpha * 255
    out = np.clip(out, 0, 255).astype(np.uint8)
    im = Image.fromarray(out, "RGBA")
    # Erosiona 1 px el alfa: quita el último halo rosa de la orilla.
    a_ch = im.getchannel("A").filter(ImageFilter.MinFilter(3))
    im.putalpha(a_ch)
    return im


def bbox(im: Image.Image, threshold: int = 128):
    return im.getchannel("A").point(lambda v: 255 if v > threshold else 0).getbbox()


def cells(im: Image.Image, cols: int, rows: int) -> list:
    """Celdas proporcionales (1024 / 3 no es entero)."""
    xs = [round(i * im.width / cols) for i in range(cols + 1)]
    ys = [round(j * im.height / rows) for j in range(rows + 1)]
    return [im.crop((xs[c], ys[r], xs[c + 1], ys[r + 1])) for r in range(rows) for c in range(cols)]


def shrink(im: Image.Image, size: tuple) -> Image.Image:
    while im.width >= size[0] * 2 and im.height >= size[1] * 2:
        im = im.resize((im.width // 2, im.height // 2), Image.LANCZOS)
    return im.resize(size, Image.LANCZOS)


def fit(im: Image.Image, size: tuple, anchor: str = "center", fill: float = 1.0) -> Image.Image:
    """Recorta al contenido, escala para caber en size*fill sin deformar y coloca."""
    box = bbox(im)
    if box is None:
        return Image.new("RGBA", size, (0, 0, 0, 0))
    im = im.crop(box)
    scale = min(size[0] * fill / im.width, size[1] * fill / im.height)
    small = shrink(im, (max(1, round(im.width * scale)), max(1, round(im.height * scale))))
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    x = (size[0] - small.width) // 2
    y = (size[1] - small.height) // 2 if anchor == "center" else size[1] - small.height
    out.alpha_composite(small, (x, y))
    return out


def desaturate(im: Image.Image, sat: float = DECOR_SAT, val: float = DECOR_VAL) -> Image.Image:
    alpha = im.getchannel("A")
    h, s, v = im.convert("RGB").convert("HSV").split()
    s = s.point(lambda p: round(p * sat))
    v = v.point(lambda p: round(p * val))
    out = Image.merge("HSV", (h, s, v)).convert("RGB").convert("RGBA")
    out.putalpha(alpha)
    return out


def strip(frames: list, size: tuple) -> Image.Image:
    out = Image.new("RGBA", (size[0] * len(frames), size[1]), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.alpha_composite(f, (i * size[0], 0))
    return out


def anim_frames(sheets: list, frame: tuple, scale_extra: float = 1.0, anchor: str = "bottom") -> list:
    """Cuadros de animación con la MISMA escala y la misma caja horizontal para todos
    (sin temblor). sheets = [(imagen, columnas, filas, cuántos cuadros)]. Devuelve
    una lista por hoja. Con anchor 'bottom' cada cuadro se apoya en su línea base."""
    all_cells = []
    for im, cols, rows, count in sheets:
        all_cells.append(cells(im, cols, rows)[:count])
    # Caja horizontal por hoja (cada hoja tiene su propio tamaño de celda).
    spans = []
    for group in all_cells:
        bs = [bbox(c) for c in group if bbox(c)]
        spans.append((min(b[0] for b in bs), max(b[2] for b in bs)))
    boxes = [bbox(c) for group in all_cells for c in group if bbox(c)]
    top = min(b[1] for b in boxes)
    bottom = max(b[3] for b in boxes)
    tallest = max(b[3] - b[1] for b in boxes) if anchor == "bottom" else bottom - top
    widest = max(r - l for l, r in spans)
    scale = min(frame[1] / tallest, frame[0] / widest) * scale_extra
    result = []
    for group, (left, right) in zip(all_cells, spans):
        frames = []
        for c in group:
            box = bbox(c)
            out = Image.new("RGBA", frame, (0, 0, 0, 0))
            if box is None:
                frames.append(out)
                continue
            y0, y1 = (box[1], box[3]) if anchor == "bottom" else (top, bottom)
            crop = c.crop((left, y0, right, y1))
            small = shrink(crop, (max(1, round(crop.width * scale)), max(1, round(crop.height * scale))))
            x = (frame[0] - small.width) // 2
            y = frame[1] - small.height if anchor == "bottom" else (frame[1] - small.height) // 2
            out.alpha_composite(small, (x, y))
            frames.append(out)
        result.append(frames)
    return result


def have(*names: str) -> bool:
    missing = [n for n in names if not (SRC / n).exists()]
    if missing:
        print(f"  (falta {', '.join(missing)}: se deja como está)")
    return not missing


# ------------------------------------------------------------------ piloto

def player_car() -> None:
    if have("auto_jugador.png"):
        fit(load_rgba(SRC / "auto_jugador.png"), (69, 41)).save(SPRITES / "player_car.png")


def houses() -> None:
    if not have("casas_a.png"):
        return
    tiles = [desaturate(fit(c, (128, 128), anchor="bottom")) for c in cells(load_rgba(SRC / "casas_a.png"), 3, 2)]
    # Lote 09: segunda hoja, casas 7-12 (LOTS 12-17 del CityDresser).
    path = find("casas_b")
    if path:
        tiles += [desaturate(fit(c, (128, 128), anchor="bottom")) for c in cells(load_rgba(path), 3, 2)]
    strip(tiles, (128, 128)).save(SPRITES / "city/casas.png")


def child() -> None:
    if not have("nino_camina.png", "nino_sorprendido.png"):
        return
    walk, scared = anim_frames(
        [(load_rgba(SRC / "nino_camina.png"), 4, 2, 8), (load_rgba(SRC / "nino_sorprendido.png"), 4, 2, 8)],
        (46, 85), PEDESTRIAN_SCALE)
    strip(walk, (46, 85)).save(SPRITES / "pedestrians/child_walk.png")
    strip(scared, (46, 85)).save(SPRITES / "pedestrians/child_scared.png")


# ------------------------------------------------------------------ lote 01: HUD

# Celda de hud_iconos.png -> (archivo, tamaño en pantalla). hud.tscn los usa a escala 1.
HUD_ICONS = {
    0: ("arrow_right.png", (138, 120)),
    1: ("brake_pedal.png", (180, 100)),
    2: ("gas_pedal.png", (100, 180)),
    3: ("lights.png", (120, 120)),
    4: ("seatbelt.png", (160, 160)),
    5: ("coin.png", (44, 45)),
    6: ("star.png", (49, 47)),
    7: ("star_empty.png", (49, 47)),
    8: ("gear.png", (92, 100)),
}


def hud() -> None:
    name = next((n for n in ("hud_iconos.png", "hud_iconos_REVISAR.png") if (SRC / n).exists()), None)
    if name is None:
        print("  (falta hud_iconos.png: se deja como está)")
        return
    cs = cells(load_rgba(SRC / name), 4, 3)
    for index, (file, size) in HUD_ICONS.items():
        icon = fit(cs[index], size, fill=0.96)
        icon.save(ICONS / file)
        if file == "arrow_right.png":
            icon.transpose(Image.FLIP_LEFT_RIGHT).save(ICONS / "arrow_left.png")


def phone() -> None:
    if have("celular.png"):
        fit(load_rgba(SRC / "celular.png"), (168, 320)).save(ROOT / "assets/ui/phone.png")


# ------------------------------------------------------------------ lote 02: copiloto

# copilot.png conserva su acomodo (copilot_frames.tres no cambia): 4 filas de 6
# cuadros de 105 × 106 -> talk, happy, surprised, thinking. Cada cuadro es una de
# las 8 poses (1 habla cerrada, 2 habla abierta, 3 feliz, 4 pulgar, 5 sorprendido,
# 6 pensando, 7 parpadeo, 8 saluda).
COPILOT_ROWS = [
    [1, 2, 1, 2, 2, 1],  # talk (8 fps, en ciclo)
    [3, 3, 4, 4, 4, 3],  # happy
    [5, 5, 5, 5, 5, 5],  # surprised (una vez)
    [6, 6, 6, 6, 7, 6],  # thinking (5 fps): parpadea una vez
]


def copilot() -> None:
    if not have("copiloto_poses.png"):
        return
    (poses,) = anim_frames([(load_rgba(SRC / "copiloto_poses.png"), 4, 2, 8)], (105, 106), 0.96, anchor="fixed")
    out = Image.new("RGBA", (105 * 6, 106 * 4), (0, 0, 0, 0))
    for row, seq in enumerate(COPILOT_ROWS):
        for col, pose in enumerate(seq):
            out.alpha_composite(poses[pose - 1], (col * 105, row * 106))
    out.save(SPRITES / "copilot/copilot.png")


# ------------------------------------------------------------------ lote 03: peatones

def write_sprite_frames(tres: Path, png_res: str, frame: tuple, anims: list) -> None:
    """Reescribe un SpriteFrames: anims = [(nombre, [índices en la tira], loop, fps)]."""
    used = sorted({i for _, idx, _, _ in anims for i in idx})
    lines = ['[gd_resource type="SpriteFrames" format=3]', "",
             f'[ext_resource type="Texture2D" path="{png_res}" id="1_sheet"]', ""]
    for i in used:
        lines += [f'[sub_resource type="AtlasTexture" id="AtlasTexture_{i}"]', 'atlas = ExtResource("1_sheet")',
                  f"region = Rect2({i * frame[0]}, 0, {frame[0]}, {frame[1]})", ""]
    blocks = []
    for name, idx, loop, fps in anims:
        frames = ", ".join('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % i for i in idx)
        blocks.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}'
                      % (frames, "true" if loop else "false", name, float(fps)))
    lines += ["[resource]", "animations = [" + ", ".join(blocks) + "]", ""]
    tres.write_text("\n".join(lines))


# Por personaje: hojas de Codex (archivo, columnas, filas, cuadros) y animaciones
# sobre la tira resultante (walk, después reacciones; la última celda de reacciones
# es idle salvo en la silla). Velocidades y loops como en los .tres de antes.
PEDESTRIANS = {
    "girl": {
        "frame": (64, 80),
        "sheets": [("nina_camina", 4, 2, 8), ("nina_reacciones", 3, 2, 5)],
        "anims": [("walk", list(range(0, 8)), True, 8), ("scared", [8, 9, 10, 11], False, 8), ("idle", [12], True, 1)],
    },
    "adult": {
        "frame": (64, 88),
        "sheets": [("adulto_camina", 4, 2, 8), ("adulto_reacciones", 3, 2, 6)],
        "anims": [("walk", list(range(0, 8)), True, 8), ("scared", [8, 9, 10, 11, 12], False, 8), ("idle", [13], True, 1)],
    },
    "elder": {
        "frame": (64, 78),
        "sheets": [("abuelita_camina", 3, 2, 6), ("abuelita_reacciones", 3, 2, 6)],
        # La reacción de 10 cuadros se arma de ida y vuelta con los 5 de Codex.
        "anims": [("idle", [11], True, 1), ("scared", [6, 7, 8, 9, 8, 9, 8, 9, 10, 10], False, 10),
                  ("walk", list(range(0, 6)), True, 6)],
    },
    # Lote 09: solo caminata. Quietos usan el cuadro 0; "scared" es una pausa corta
    # en el mismo cuadro (Pedestrian solo espera a que termine para seguir).
    "dad_stroller": {
        "frame": (88, 88),
        "sheets": [("papa_carriola_camina", 4, 2, 8)],
        "anims": [("walk", list(range(0, 8)), True, 8), ("scared", [0, 0, 0, 0], False, 8), ("idle", [0], True, 1)],
    },
    "teen": {
        "frame": (64, 88),
        "sheets": [("joven_camina", 4, 2, 8)],
        "anims": [("walk", list(range(0, 8)), True, 8), ("scared", [0, 0, 0, 0], False, 8), ("idle", [0], True, 1)],
    },
    "shopper": {
        "frame": (64, 86),
        "sheets": [("senora_mandado_camina", 4, 2, 8)],
        "anims": [("walk", list(range(0, 8)), True, 8), ("scared", [0, 0, 0, 0], False, 8), ("idle", [0], True, 1)],
    },
    "wheelchair": {
        "frame": (72, 78),
        "sheets": [("silla_ruedas", 4, 4, 13)],
        "anims": [("walk", [0, 1, 2, 3], True, 4), ("scared", [4, 5, 6, 7], False, 6), ("idle", [12], True, 1),
                  ("happy", [8, 9, 10, 11], True, 4)],
    },
}


def find(stem: str):
    for name in (f"{stem}.png", f"{stem}_REVISAR.png"):
        if (SRC / name).exists():
            return SRC / name
    return None


def pedestrians() -> None:
    folder = SPRITES / "pedestrians"
    for key, spec in PEDESTRIANS.items():
        paths = [find(stem) for stem, *_ in spec["sheets"]]
        if None in paths:
            print(f"  (faltan hojas de {key}: se deja como está)")
            continue
        sheets = [(load_rgba(p), cols, rows, count) for p, (_, cols, rows, count) in zip(paths, spec["sheets"])]
        groups = anim_frames(sheets, spec["frame"], PEDESTRIAN_SCALE)
        frames = [f for group in groups for f in group]
        strip(frames, spec["frame"]).save(folder / f"{key}.png")
        write_sprite_frames(folder / f"{key}_frames.tres", f"res://assets/sprites/pedestrians/{key}.png",
                            spec["frame"], spec["anims"])


# ------------------------------------------------------------------ lote 04: vehículos

def same_box(cs: list, size: tuple, fill: float = 0.98, anchor: str = "center") -> list:
    """Varias celdas con la misma caja y la misma escala (sin saltos entre cuadros)."""
    boxes = [bbox(c) for c in cs if bbox(c)]
    box = (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))
    w, h = box[2] - box[0], box[3] - box[1]
    scale = min(size[0] * fill / w, size[1] * fill / h)
    out = []
    for c in cs:
        small = shrink(c.crop(box), (max(1, round(w * scale)), max(1, round(h * scale))))
        frame = Image.new("RGBA", size, (0, 0, 0, 0))
        y = (size[1] - small.height) // 2 if anchor == "center" else size[1] - small.height
        frame.alpha_composite(small, ((size[0] - small.width) // 2, y))
        out.append(frame)
    return out


def vehicles() -> None:
    folder = SPRITES / "vehicles"
    path = find("autos_trafico")
    if path:
        # npc_car.gd: tira de 8 autos de 70 × 38 en el orden de CAR_COLORS.
        cars = [fit(c, (70, 38), fill=0.98) for c in cells(load_rgba(path), 4, 2)]
        strip(cars, (70, 38)).save(folder / "npc_cars.png")
    path = find("vehiculos_grandes")
    if path:
        bus, ambulance = cells(load_rgba(path), 1, 2)
        fit(bus, (139, 80)).save(folder / "bus.png")
        fit(ambulance, (94, 50)).save(folder / "ambulance.png")
    path = find("moto")
    if path:
        fit(load_rgba(path), (60, 27)).save(folder / "motorcycle.png")
    path = find("ciclista")
    if path:
        frames = same_box(cells(load_rgba(path), 3, 2), (60, 29))
        strip(frames, (60, 29)).save(folder / "cyclist.png")
        write_sprite_frames(folder / "cyclist_frames.tres", "res://assets/sprites/vehicles/cyclist.png", (60, 29),
                            [("ride", list(range(6)), True, 8), ("idle", [0], True, 1)])


# ------------------------------------------------------------------ lote 05: señales

# speed_zone.gd escribe el número del límite en LIMIT_CENTER (35.5, 52) del cuadro 1.
LIMIT_CENTER = (35.5, 52.0)


def white_center(im: Image.Image) -> tuple:
    a = np.asarray(im).astype(np.int32)
    mask = (a[..., 0] > 235) & (a[..., 1] > 235) & (a[..., 2] > 235) & (a[..., 3] > 200)
    ys, xs = np.nonzero(mask)
    return float(xs.mean()), float(ys.mean())


def signals() -> None:
    path = find("senales")
    if not path:
        print("  (falta senales.png: se deja como está)")
        return
    cs = cells(load_rgba(path), 4, 2)
    signs = same_box(cs[0:4], (72, 112), fill=0.92, anchor="bottom")
    # Mueve los 4 letreros igual para que el círculo vacío caiga donde el juego escribe.
    cx, cy = white_center(signs[1])
    dx, dy = round(LIMIT_CENTER[0] - cx), round(LIMIT_CENTER[1] - cy)
    print(f"  letreros movidos ({dx}, {dy}) para el número del límite")
    signs = [_shift(s, dx, dy) for s in signs]
    strip(signs, (72, 112)).save(SPRITES / "signals/signs.png")
    lights = same_box(cs[4:7], (43, 104), anchor="bottom")
    strip(lights, (43, 104)).save(SPRITES / "signals/pedestrian_light.png")
    fit(cs[7], (28, 52), anchor="bottom").save(SPRITES / "city/bus_stop_sign.png")


def _shift(im: Image.Image, dx: int, dy: int) -> Image.Image:
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (dx, dy), im)
    return out


# ------------------------------------------------------------------ lote 06: ciudad

def city() -> None:
    folder = SPRITES / "city"
    path = find("arboles")
    if path:
        # 10 plantas de 64 × 64 en el orden de la ficha (LevelTheme.tree_kinds usa estos índices).
        plants = [desaturate(fit(c, (64, 64), anchor="bottom", fill=0.96)) for c in cells(load_rgba(path), 4, 3)[:10]]
        strip(plants, (64, 64)).save(folder / "arboles.png")
    path = find("edificios")
    if path:
        # Los 3 primeros reemplazan a los de antes (LOTS 4-6 del CityDresser).
        blocks = [desaturate(fit(c, (142, 160), anchor="bottom")) for c in cells(load_rgba(path), 3, 2)]
        strip(blocks, (142, 160)).save(folder / "edificios.png")
    path = find("mobiliario")
    if path:
        props = cells(load_rgba(path), 3, 2)
        desaturate(fit(props[0], (97, 80), anchor="bottom")).save(folder / "bus_stop.png")
        # Objetos de banqueta (farol, banca, bote, elotes, fruta) para decorar después.
        extras = [desaturate(fit(c, (64, 64), anchor="bottom", fill=0.96)) for c in props[1:]]
        strip(extras, (64, 64)).save(folder / "mobiliario.png")


# ------------------------------------------------------------------ lote 07: destinos

def fit_tight(im: Image.Image, max_size: tuple) -> Image.Image:
    """Como fit, pero el PNG mide justo lo que el dibujo (sin relleno transparente),
    para que el rect del Sprite2D sea el del edificio."""
    im = im.crop(bbox(im))
    scale = min(max_size[0] / im.width, max_size[1] / im.height)
    return shrink(im, (max(1, round(im.width * scale)), max(1, round(im.height * scale))))


def fill_holes(im: Image.Image) -> Image.Image:
    """Rellena huecos transparentes encerrados (p. ej. recortes del papel picado del
    mercado que Codex dejó en magenta) con el color medio de su orilla."""
    a = np.array(im.getchannel("A")) > 128
    outside = Image.fromarray(np.where(a, 0, 255).astype(np.uint8))
    from PIL import ImageDraw
    padded = Image.new("L", (outside.width + 2, outside.height + 2), 255)
    padded.paste(outside, (1, 1))
    ImageDraw.floodfill(padded, (0, 0), 128)
    holes = np.array(padded)[1:-1, 1:-1] == 255
    if not holes.any():
        return im
    rgba = np.array(im).astype(np.float32)
    ring = np.array(Image.fromarray(holes.astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(5))) > 0
    ring &= a
    color = np.median(rgba[ring][:, :3], axis=0)
    rgba[holes, :3] = color
    rgba[holes, 3] = 255
    return Image.fromarray(rgba.astype(np.uint8), "RGBA")


# Lote 09: destinos sin relleno, tamaño máximo (el PNG queda al tamaño del dibujo).
DESTINATIONS_TIGHT = {
    "destino_biblioteca": ("biblioteca.png", (300, 210)),
    "destino_mercado": ("mercado.png", (290, 190)),
    "destino_parque": ("parque.png", (300, 230)),
    "destino_abuela": ("casa_abuela.png", (190, 140)),
    "destino_primos": ("casa_primos.png", (200, 140)),
}

DESTINATIONS = {
    "destino_escuela": ("escuela.png", (320, 224)),
    "destino_hospital": ("hospital.png", (300, 217)),
    "destino_terminal": ("terminal.png", (322, 190)),
}


def destinations() -> None:
    folder = SPRITES / "city"
    for stem, (file, size) in DESTINATIONS.items():
        path = find(stem)
        if path:
            desaturate(fit(load_rgba(path), size, anchor="bottom"), 0.92, 0.98).save(folder / file)
    # El túnel del nivel 7 ya no usa el arte de Codex: tools/art/tunel_v3.py lo dibuja desde arriba.
    for stem, (file, size) in DESTINATIONS_TIGHT.items():
        path = find(stem)
        if path:
            im = desaturate(fit_tight(fill_holes(load_rgba(path)), size), 0.92, 0.98)
            im.save(folder / file)
            print(f"  {file}: {im.size}")
    path = find("papel_picado")
    if path:
        # 3 tiras de 256 × 48 en fila (region por tira); los recortes quedan transparentes.
        flags = [fit(c, (256, 48), fill=0.98) for c in cells(load_rgba(path), 1, 3)]
        strip(flags, (256, 48)).save(folder / "papel_picado.png")


# ------------------------------------------------------------------ lote 08: tarjetas

# Recorte 5:3 de 1536 × 1024 (922 de alto): por defecto se quita todo lo de arriba
# para no cortar al copiloto de la esquina inferior; la 00 y la 06 bajan menos para
# no cortar el pelo del niño ni el espejo.
CARD_TOP = {0: 20, 6: 90}


def cards() -> None:
    folder = ROOT / "assets/ui/habit_cards"
    for i in range(11):
        path = find(f"tarjeta_{i:02d}")
        if path is None:
            continue
        im = Image.open(path).convert("RGB")
        h = round(im.width * 3 / 5)
        top = CARD_TOP.get(i, im.height - h)
        im.crop((0, top, im.width, top + h)).resize((720, 432), Image.LANCZOS).convert("RGBA").save(
            folder / f"card_{i:02d}.png")


if __name__ == "__main__":
    for step in (player_car, houses, child, hud, phone, copilot, pedestrians, vehicles, signals, city, destinations, cards):
        print(step.__name__)
        step()
    print("arte v2 integrado")
