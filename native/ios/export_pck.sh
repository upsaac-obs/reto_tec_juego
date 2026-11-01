#!/usr/bin/env bash
# Exporta el proyecto de Godot como main.pck con el preset "iOS" y lo copia a las dos
# apps: RutaKids/main.pck (la app real) y RutaKidsSpike/main.pck (la prueba técnica).
# Necesita Godot 4.7.x en el PATH como "godot" (o GODOT=/ruta/al/binario).
# En la Mac: GODOT=/Applications/Godot.app/Contents/MacOS/Godot ./export_pck.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
project="$(cd "$here/../.." && pwd)"
"${GODOT:-godot}" --headless --path "$project" --export-pack "iOS" "$here/RutaKids/main.pck"
cp "$here/RutaKids/main.pck" "$here/RutaKidsSpike/main.pck"
echo "main.pck: $(du -h "$here/RutaKids/main.pck" | cut -f1)"
