#!/usr/bin/env bash
# Exporta el proyecto de Godot y copia sus archivos a los assets de la app (H10).
# Usa el preset "Android" (mismas plantillas 4.7.2 que godot-lib) y saca de ese
# APK solo la carpeta assets/: ahí está el proyecto exportado que lee godot-lib.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
godot_project="$(cd "$here/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

godot --headless --path "$godot_project" --export-debug "Android" "$tmp/godot.apk"
dest="$here/app/src/main/assets"
rm -rf "$dest"
mkdir -p "$dest"
unzip -q "$tmp/godot.apk" 'assets/*' -d "$tmp/x"
cp -r "$tmp/x/assets/." "$dest/"
echo "Assets de Godot copiados a $dest ($(du -sh "$dest" | cut -f1))"
