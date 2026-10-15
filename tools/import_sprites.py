#!/usr/bin/env python3
"""Limpia imágenes generadas (Gemini) y las convierte en sprites del juego.

- Quita el fondo magenta (también las líneas de cuadrícula magenta oscuro).
- Lleva cada color al más cercano de la paleta de ADO (distancia CIELAB).
- Corta cuadros por cuadrícula (cols × rows) o por objetos separados.
- Reduce cada cuadro al tamaño pedido con voto por bloque (mantiene bordes).
- Arma una tira de cuadros del mismo tamaño (personas alineadas por los pies,
  vehículos centrados) y, si hay animaciones, su SpriteFrames (.tres).

Uso desde Python (ver tools/import_fase2.py):
    sheet = load("~/claude/assest2/girl.jpg")
    frames = grid_cells(sheet, cols=8, rows=2, crop=(0, 0.08, 1, 1))
    ...
Necesita numpy y Pillow.
"""
import os
import numpy as np
from PIL import Image

PALETTE_HEX = ("DD2835 3F1B4E FFC700 FFFFFF 4A235A 9C4B79 E86F56 534A5E 1E0F26 "
               "2A2230 B8A6CC F8C99B 3FA34D 2B6B3F 7FC8E8 F2C29B C68B59 8A5A3B").split()
PALETTE = np.array([[int(h[i:i + 2], 16) for i in (0, 2, 4)] for h in PALETTE_HEX], float)
BG = len(PALETTE)       # índice del fondo transparente
OUTLINE = 8             # índice de #1E0F26


def _lab(rgb):
    c = rgb / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.9505, 1.0, 1.089])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


PALETTE_LAB = _lab(PALETTE)


def load(path, extra_background=()):
    """Imagen → matriz de índices de paleta (BG = transparente).

    extra_background: colores RGB extra que cuentan como fondo (p. ej. blanco
    alrededor de paneles)."""
    a = np.asarray(Image.open(os.path.expanduser(path)).convert("RGB")).astype(float)
    lab = _lab(a)
    idx = np.empty(a.shape[:2], int)
    for y in range(0, a.shape[0], 64):
        d = ((lab[y:y + 64, :, None, :] - PALETTE_LAB) ** 2).sum(-1)
        idx[y:y + 64] = d.argmin(axis=2)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    background = (r - g > 90) & (b - g > 90) & (np.abs(r - b) < 100) & (g < 140)
    for color in extra_background:
        background |= (np.abs(a - np.array(color, float)).sum(-1) < 40)
    idx[background] = BG
    return idx


def crop_frac(idx, box):
    """Recorta con fracciones (x0, y0, x1, y1) de la imagen."""
    h, w = idx.shape
    x0, y0, x1, y1 = box
    return idx[round(y0 * h):round(y1 * h), round(x0 * w):round(x1 * w)]


def crop_px(idx, box):
    x0, y0, x1, y1 = box
    return idx[y0:y1, x0:x1]


def trim(cell, min_run=4):
    """Recorta al borde del objeto ignorando motas sueltas de ruido JPEG."""
    m = cell != BG
    rows = np.convolve(m.sum(1), np.ones(5), "same") > min_run * 4
    cols = np.convolve(m.sum(0), np.ones(5), "same") > min_run * 4
    if not rows.any() or not cols.any():
        return cell[:1, :1]
    ys, xs = np.nonzero(rows)[0], np.nonzero(cols)[0]
    return cell[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def grid_cells(idx, cols, rows):
    """Divide en cols × rows celdas iguales y recorta cada una a su objeto."""
    h, w = idx.shape
    cells = []
    for r in range(rows):
        for c in range(cols):
            cell = idx[round(r * h / rows):round((r + 1) * h / rows), round(c * w / cols):round((c + 1) * w / cols)]
            cells.append(trim(cell))
    return cells


def mode_resize(idx, w, h):
    """Reduce con voto por bloque; el contorno gana si ocupa 30 % del bloque."""
    src_h, src_w = idx.shape
    out = np.empty((h, w), int)
    xe = np.linspace(0, src_w, w + 1).round().astype(int)
    ye = np.linspace(0, src_h, h + 1).round().astype(int)
    for j in range(h):
        for i in range(w):
            block = idx[ye[j]:max(ye[j + 1], ye[j] + 1), xe[i]:max(xe[i + 1], xe[i] + 1)].ravel()
            counts = np.bincount(block, minlength=BG + 1)
            out[j, i] = OUTLINE if counts[OUTLINE] >= 0.3 * block.size else counts.argmax()
    return out


def scale_all(cells, height=None, width=None, fit=None):
    """Escala todos los cuadros con la MISMA escala (el más alto/ancho manda)."""
    if fit:
        s = min(min(fit[0] / c.shape[1], fit[1] / c.shape[0]) for c in cells)
    elif height:
        s = height / max(c.shape[0] for c in cells)
    else:
        s = width / max(c.shape[1] for c in cells)
    return [mode_resize(c, max(1, round(c.shape[1] * s)), max(1, round(c.shape[0] * s))) for c in cells]


def rotate_cw(cells):
    """Gira 90° a la derecha (sprites vistos desde arriba que miran hacia arriba → +x)."""
    return [np.rot90(c, -1) for c in cells]


def strip(cells, align="bottom"):
    """Une cuadros en una tira; todos del tamaño del más grande."""
    fw = max(c.shape[1] for c in cells)
    fh = max(c.shape[0] for c in cells)
    canvas = np.full((fh, fw * len(cells)), BG, int)
    for k, c in enumerate(cells):
        h, w = c.shape
        x = k * fw + (fw - w) // 2
        y = fh - h if align == "bottom" else (fh - h) // 2
        canvas[y:y + h, x:x + w] = c
    return canvas, (fw, fh)


def to_rgba(idx):
    rgba = np.zeros(idx.shape + (4,), np.uint8)
    fg = idx != BG
    rgba[fg, :3] = PALETTE[idx[fg]].astype(np.uint8)
    rgba[fg, 3] = 255
    return Image.fromarray(rgba)


def save_png(idx, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    to_rgba(idx).save(path)
    return path


def write_sprite_frames(tres_path, png_res_path, frame_size, count, animations):
    """animations: {nombre: (lista de índices de cuadro, fps, repetir)}"""
    fw, fh = frame_size
    lines = ['[gd_resource type="SpriteFrames" format=3]', "",
             f'[ext_resource type="Texture2D" path="{png_res_path}" id="1_sheet"]', ""]
    for k in range(count):
        lines += [f'[sub_resource type="AtlasTexture" id="AtlasTexture_{k}"]',
                  'atlas = ExtResource("1_sheet")',
                  f"region = Rect2({k * fw}, 0, {fw}, {fh})", ""]
    anims = []
    for name, (frames, fps, loop) in animations.items():
        frame_list = ", ".join(
            '{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % k for k in frames)
        anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}'
                     % (frame_list, "true" if loop else "false", name, float(fps)))
    lines += ["[resource]", "animations = [" + ", ".join(anims) + "]", ""]
    with open(tres_path, "w") as fh_out:
        fh_out.write("\n".join(lines))
