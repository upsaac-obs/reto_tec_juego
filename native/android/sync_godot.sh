#!/usr/bin/env bash
# Exporta el proyecto de Godot y copia sus archivos a los assets de la app (H10).
# Lo hace tools/export_all.sh --android (preset "Android", mismas plantillas 4.7.2
# que godot-lib; del APK se toma solo la carpeta assets/) con la marca del build.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
exec "$here/../../tools/export_all.sh" --android
