#!/usr/bin/env bash
# Exporta el proyecto de Godot como main.pck con el preset "iOS" y lo copia a las dos
# apps: RutaKids/main.pck (la app real) y RutaKidsSpike/main.pck (la prueba técnica).
# Lo hace tools/export_all.sh --ios, que además pone el commit en engine_ready.
# Necesita Godot 4.7.x en el PATH como "godot" (o GODOT=/ruta/al/binario).
# En la Mac: GODOT=/Applications/Godot.app/Contents/MacOS/Godot ./export_pck.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
exec "$here/../../tools/export_all.sh" --ios
