#!/usr/bin/env bash
# Exporta el juego para las dos apps con la misma marca de versión (H10).
#
#   tools/export_all.sh            # iOS y Android
#   tools/export_all.sh --ios      # solo main.pck para las apps de iOS
#   tools/export_all.sh --android  # solo los assets de la app de Android
#
# 1. Escribe res://build_info.gd con el commit corto (más "-mod" si hay cambios sin
#    commit). BridgeClient lo manda en engine_ready: {"v":1,"build":"<commit>"}.
# 2. iOS: exporta main.pck UNA vez con --export-pack y el preset "iOS" y lo copia a
#    native/ios/RutaKids/main.pck y native/ios/RutaKidsSpike/main.pck
#    (GodotApp(packFile: "main.pck")).
# 3. Android: godot-lib no lee un main.pck sino el proyecto exportado suelto en
#    app/src/main/assets/. Por eso se exporta el preset "Android" a un APK temporal
#    y se copia su carpeta assets/ (lo que hacía native/android/sync_godot.sh).
# 4. Deja build_info.gd otra vez en "dev" aunque algo falle.
#
# No corre Gradle ni Xcode. Necesita Godot 4.7.x como "godot" (o GODOT=/ruta) y,
# para Android, las plantillas de exportación 4.7.2 instaladas.
set -euo pipefail
project="$(cd "$(dirname "$0")/.." && pwd)"
godot="${GODOT:-godot}"
do_ios=1
do_android=1
case "${1:-}" in
  --ios) do_android=0 ;;
  --android) do_ios=0 ;;
  "") ;;
  *) echo "Uso: $0 [--ios|--android]" >&2; exit 2 ;;
esac

info="$project/build_info.gd"
tmp="$(mktemp -d)"
cp "$info" "$tmp/build_info.gd.orig"
restore() {
  cp "$tmp/build_info.gd.orig" "$info"
  rm -rf "$tmp"
}
trap restore EXIT

build="$(git -C "$project" rev-parse --short HEAD 2>/dev/null || echo dev)"
if [ "$build" != dev ] && [ -n "$(git -C "$project" status --porcelain 2>/dev/null)" ]; then
  build="$build-mod"
fi
sed -i.bak -E "s/^const BUILD := \".*\"$/const BUILD := \"$build\"/" "$info"
rm -f "$info.bak"
grep -q "const BUILD := \"$build\"" "$info" || { echo "No se pudo escribir la marca en $info" >&2; exit 1; }
echo "Build: $build"

if [ "$do_ios" = 1 ]; then
  ios="$project/native/ios"
  "$godot" --headless --path "$project" --export-pack "iOS" "$tmp/main.pck"
  for app in RutaKids RutaKidsSpike; do
    cp "$tmp/main.pck" "$ios/$app/main.pck"
  done
  echo "iOS: main.pck ($(du -h "$tmp/main.pck" | cut -f1)) en RutaKids/ y RutaKidsSpike/"
fi

if [ "$do_android" = 1 ]; then
  android="$project/native/android"
  "$godot" --headless --path "$project" --export-debug "Android" "$tmp/godot.apk"
  dest="$android/app/src/main/assets"
  rm -rf "$dest"
  mkdir -p "$dest"
  unzip -q "$tmp/godot.apk" -d "$tmp/apk"
  cp -r "$tmp/apk/assets/." "$dest/"
  echo "Android: assets de Godot en $dest ($(du -sh "$dest" | cut -f1))"
fi
