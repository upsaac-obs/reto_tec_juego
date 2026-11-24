#!/usr/bin/env bash
# Creación y desarrollo: Dylan Isaac Mancilla López
# Corre todas las pruebas automáticas sin abrir el editor y guarda la salida en
# tests/resultados/ con la fecha y el commit (evidencia para el plan de pruebas).
set -uo pipefail
project="$(cd "$(dirname "$0")/.." && pwd)"
out="$project/tests/resultados"
mkdir -p "$out"
commit="$(git -C "$project" rev-parse --short HEAD 2>/dev/null || echo sin-git)"
dirty=""
[ -n "$(git -C "$project" status --porcelain 2>/dev/null)" ] && dirty="-con-cambios"
log="$out/$(date +%Y-%m-%d_%H%M)_${commit}${dirty}.log"
{
  echo "RutaKids — pruebas automáticas"
  echo "Fecha: $(date '+%Y-%m-%d %H:%M')  Commit: ${commit}${dirty}  Godot: $(${GODOT:-godot} --version)"
} > "$log"
# --fixed-fps 60: reloj simulado. Cada cuadro recibe delta = 1/60 s exacto y Godot
# no espera al reloj real, así que la suite corre mucho más rápido con los mismos
# pasos de tiempo que un celular a 60 fps.
${GODOT:-godot} --headless --fixed-fps 60 --path "$project" res://tests/run_tests.tscn 2>&1 \
  | grep --line-buffered -vE "^Godot Engine|^\s*$|FakeBridge|resources still in use|RID allocations" | tee -a "$log"
status=${PIPESTATUS[0]}
echo "Log: $log"
exit "$status"
