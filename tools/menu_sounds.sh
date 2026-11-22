#!/usr/bin/env bash
# Creación y desarrollo: Dylan Isaac Mancilla López
# Sonidos de los menús nativos (Android e iOS), en M4A/AAC porque iOS (AVAudioPlayer)
# no reproduce .ogg. Uso: tools/menu_sounds.sh   (necesita ffmpeg)
#   menu_tap     "pop" corto al tocar un botón (sintetizado)
#   menu_locked  dos tonos graves al tocar una parada cerrada (sintetizado)
#   menu_unlock  el "ding" de acierto del juego (assets/audio/sfx/good.wav), al llegar el auto
#   menu_music   la música del juego (assets/audio/musica/nivel.ogg), en bucle en los menús
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
android="$root/native/android/app/src/main/res/raw"
ios="$root/native/ios/RutaKids/Resources/Audio"
mkdir -p "$android" "$ios"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
sfx=(-ac 1 -ar 44100 -c:a aac -b:a 64k -movflags +faststart -map_metadata -1)

ffmpeg -y -loglevel error -f lavfi -i "aevalsrc=0.55*sin(2*PI*(620+2400*t)*t)*exp(-42*t):s=44100:d=0.1" \
  -af "lowpass=f=5000,afade=t=in:d=0.004" "${sfx[@]}" "$tmp/menu_tap.m4a"
ffmpeg -y -loglevel error -f lavfi -i "aevalsrc=0.45*sin(2*PI*if(lt(t\,0.11)\,330\,247)*t)*exp(-16*mod(t\,0.11)):s=44100:d=0.24" \
  -af "lowpass=f=2500,afade=t=in:d=0.004" "${sfx[@]}" "$tmp/menu_locked.m4a"
ffmpeg -y -loglevel error -i "$root/assets/audio/sfx/good.wav" "${sfx[@]}" "$tmp/menu_unlock.m4a"
ffmpeg -y -loglevel error -i "$root/assets/audio/musica/nivel.ogg" -ac 2 -c:a aac -b:a 96k \
  -movflags +faststart -map_metadata -1 "$tmp/menu_music.m4a"

for f in "$tmp"/*.m4a; do
  cp "$f" "$android/"
  cp "$f" "$ios/"
done
ls -la "$android"
