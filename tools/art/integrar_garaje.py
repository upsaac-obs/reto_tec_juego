#!/usr/bin/env python3
# Creación y desarrollo: Dylan Isaac Mancilla López
"""Integra el lote 11 de Codex (garaje, docs/arte_v2/codex/lotes/11_garaje.md).

Lee arte_v2/entrada/ (acepta el sufijo _REVISAR) y guarda:
  assets/sprites/garage/car_<id>.png   sprite del juego (huella del auto: 69 × 41)
  garage_<id>                          versión grande para los menús nativos
  btn_garage, icon_coin_star, icon_helmet   íconos de los menús nativos
Los de los menús van a las dos apps con los mismos nombres (integrar_menus.save).
El auto rojo de siempre (auto_jugador.png) es el id `clasico`, gratis.

Uso: python3 tools/art/integrar_garaje.py
"""
import numpy as np
from PIL import Image, ImageDraw

import integrar_v2 as v2
from integrar_menus import save, tight

GAME = v2.ROOT / "assets/sprites/garage"
CAR_SIZE = (69, 41)
# La moto es más angosta que un auto: cabe en este rectángulo sin deformarse.
MOTO_MAX = (66, 34)
MENU_PX = 360
# x del hueco entre la moto y el casco en garaje_moto.png (1536 de ancho).
MOTO_SPLIT_X = 890
# Celdas de garaje_autos (3 × 2, la última vacía), en orden.
CARS = ["burbuja", "todoterreno", "convertible", "deportivo", "futuro"]


def car(im, car_id: str) -> None:
    v2.fit(im, CAR_SIZE).save(GAME / f"car_{car_id}.png")
    save(tight(im, MENU_PX), f"garage_{car_id}")
    print(f"  {car_id}")


def hud_helmet(helmet):
    """Botón del casco para el HUD (en lugar del cinturón cuando se maneja la moto):
    el mismo botón caramelo azul de seatbelt.png (160 × 160) con el casco encima."""
    k, size = 4, 160
    big = size * k
    yy, xx = np.mgrid[0:big, 0:big] / big
    # Degradado de arriba a la izquierda (claro) a abajo a la derecha, como seatbelt.png.
    t = np.clip((xx + yy) / 2.0, 0.0, 1.0)[..., None]
    light, dark = np.array([150, 226, 253]), np.array([70, 178, 233])
    disc = Image.fromarray(np.dstack([(light * (1 - t) + dark * t), np.full((big, big, 1), 255)]).astype(np.uint8), "RGBA")
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).ellipse((10 * k, 10 * k, 150 * k, 150 * k), fill=255)
    out = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(out)
    d.ellipse((4 * k, 4 * k, 156 * k, 156 * k), fill=(8, 39, 74, 255))
    out.paste(disc, (0, 0), mask)
    d.arc((22 * k, 20 * k, 138 * k, 136 * k), 200, 250, fill=(236, 251, 253, 255), width=7 * k)
    out = out.resize((size, size), Image.LANCZOS)
    out.alpha_composite(v2.fit(helmet, (112, 112)), (24, 24))
    return out


def main() -> None:
    GAME.mkdir(parents=True, exist_ok=True)
    if v2.have("auto_jugador.png"):
        car(v2.load_rgba(v2.SRC / "auto_jugador.png"), "clasico")
    path = v2.find("garaje_autos")
    if path:
        for cell, car_id in zip(v2.cells(v2.load_rgba(path), 3, 2), CARS):
            car(cell, car_id)
    else:
        print("  (falta garaje_autos)")
    path = v2.find("garaje_moto")
    if path:
        sheet = v2.load_rgba(path)
        # La moto se pasa de la mitad de la hoja: se corta en el hueco entre los dos.
        moto, helmet = sheet.crop((0, 0, MOTO_SPLIT_X, sheet.height)), sheet.crop((MOTO_SPLIT_X, 0, sheet.width, sheet.height))
        v2.fit_tight(moto, MOTO_MAX).save(GAME / "car_moto.png")
        save(tight(moto, MENU_PX), "garage_moto")
        save(tight(helmet, 128), "icon_helmet")
        hud_helmet(helmet).save(v2.ROOT / "assets/ui/icons/helmet.png")
        print("  moto, icon_helmet, botón del casco del HUD")
    else:
        print("  (falta garaje_moto)")
    path = v2.find("garaje_iconos")
    if path:
        button, star = v2.cells(v2.load_rgba(path), 2, 1)
        save(tight(button, 240), "btn_garage")
        save(tight(star, 128), "icon_coin_star")
        print("  btn_garage, icon_coin_star")
    else:
        print("  (falta garaje_iconos)")


if __name__ == "__main__":
    main()
