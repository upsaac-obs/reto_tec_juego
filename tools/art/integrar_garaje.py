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
import integrar_v2 as v2
from integrar_menus import save, tight

GAME = v2.ROOT / "assets/sprites/garage"
CAR_SIZE = (69, 41)
# La moto es más angosta que un auto: cabe en este rectángulo sin deformarse.
MOTO_MAX = (66, 34)
MENU_PX = 360
# Celdas de garaje_autos (3 × 2, la última vacía), en orden.
CARS = ["burbuja", "todoterreno", "convertible", "deportivo", "futuro"]


def car(im, car_id: str) -> None:
    v2.fit(im, CAR_SIZE).save(GAME / f"car_{car_id}.png")
    save(tight(im, MENU_PX), f"garage_{car_id}")
    print(f"  {car_id}")


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
        moto, helmet = v2.cells(v2.load_rgba(path), 2, 1)
        v2.fit_tight(moto, MOTO_MAX).save(GAME / "car_moto.png")
        save(tight(moto, MENU_PX), "garage_moto")
        save(tight(helmet, 128), "icon_helmet")
        print("  moto, icon_helmet")
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
