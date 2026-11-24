#!/usr/bin/env bash
# Creación y desarrollo: Dylan Isaac Mancilla López
# Corre las pruebas automáticas sin abrir el editor y guarda la salida en
# tests/resultados/ con la fecha y el commit (evidencia para el plan de pruebas).
#
# Sin argumentos corre todo en paralelo: cada tests/test_*.gd es un trabajo y
# test_levels.gd se parte en un trabajo por nivel y modo (más "nivel 1 corriendo").
# Corren hasta N procesos de Godot a la vez (N = núcleos − 2, mínimo 1) y al
# terminar cada uno se imprime su bloque completo; al final, un solo log y un
# solo "== RESULTADO" con la suma.
#   tests/run_tests.sh                       todo, en paralelo
#   tests/run_tests.sh --only=yellow,phone   solo archivos cuyo nombre los contiene
#                                            (un texto que termina en .gd pide ese
#                                            archivo exacto: --only=test_levels.gd)
#   tests/run_tests.sh --fast                salta los archivos marcados SLOW
#   tests/run_tests.sh -j 4                  hasta 4 procesos a la vez (opcional;
#                                            también RUTAKIDS_JOBS=4)
#   tests/run_tests.sh -j 1                  en serie, un solo proceso (como antes)
# Corren en serie (un proceso, salida en vivo): -j 1, --level=N / --mode=... (los
# lee test_levels.gd), --list, un filtro que deja un solo archivo, una máquina de
# 3 núcleos o menos, o un bash anterior a 5.1 (el bash de macOS es 3.2).
# Los demás argumentos van tal cual al runner (tests/test_runner.gd).
set -uo pipefail
project="$(cd "$(dirname "$0")/.." && pwd)"
out="$project/tests/resultados"
GODOT="${GODOT:-godot}"
started="${EPOCHREALTIME:-}"
# Líneas del motor que no aportan nada al log (las mismas en serie y en paralelo).
NOISE='^Godot Engine|^\s*$|FakeBridge|resources still in use|RID allocations'

# --- Argumentos: -j N / -jN / --jobs=N son del script; lo demás, del runner.
jobs_wanted="${RUTAKIDS_JOBS:-}"
args=()
while (($#)); do
  case "$1" in
    -j)
      jobs_wanted="${2:-(nada)}"
      (($# > 1)) && shift
      ;;
    -j*) jobs_wanted="${1#-j}" ;;
    --jobs=*) jobs_wanted="${1#--jobs=}" ;;
    *) args+=("$1") ;;
  esac
  shift
done
if [ -n "$jobs_wanted" ] && ! [[ "$jobs_wanted" =~ ^[1-9][0-9]*$ ]]; then
  echo "run_tests.sh: -j necesita un número de procesos mayor que 0, no '$jobs_wanted'" >&2
  exit 2
fi

# --- Log: fecha con segundos; si ya existe (dos corridas en el mismo segundo) se
# agrega -2, -3… El archivo se crea con noclobber, así dos corridas a la vez
# nunca escriben el mismo.
mkdir -p "$out"
commit="$(git -C "$project" rev-parse --short HEAD 2>/dev/null || echo sin-git)"
dirty=""
[ -n "$(git -C "$project" status --porcelain 2>/dev/null)" ] && dirty="-con-cambios"
stamp="$(date +%Y-%m-%d_%H%M%S)"
log="$out/${stamp}_${commit}${dirty}.log"
k=2
until (set -C; : > "$log") 2>/dev/null; do
  log="$out/${stamp}_${commit}${dirty}-$k.log"
  k=$((k + 1))
done
{
  echo "RutaKids — pruebas automáticas"
  echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')  Commit: ${commit}${dirty}  Godot: $("$GODOT" --version)"
} >> "$log"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/rutakids_pruebas.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

# Imprime en pantalla y en el log.
say() { printf '%s\n' "$*" | tee -a "$log"; }

print_total_time() {
  [ -n "$started" ] || return 0
  local us=$((${EPOCHREALTIME//[.,]/} - ${started//[.,]/}))  # "," en algunos idiomas
  say "Tiempo total: $((us / 1000000)).$((us / 100000 % 10)) s$1"
}

# --- Importación: solo si hace falta (sin .godot/, un asset sin .import, un
# recurso importado que falta en .godot/imported o una lista de class_name
# distinta a la de la caché). Así ningún proceso de prueba arranca con la caché
# vieja; si está al día no se llama a Godot (--import tarda ~5 s aunque no haya
# nada que hacer). Todo en un solo awk: en Git Bash cada proceso cuesta ~40 ms.
IMPORT_AWK='
FILENAME == ARGV[1] { have[$0] = 1; next }
{ files[++n] = $0; if ($0 ~ /\/\.gdignore$/) ign[substr($0, 1, length($0) - 9)] = 1 }
function ignored(f, d) { for (d in ign) if (index(f, d) == 1) return 1; return 0 }
function reason(r) { print r; exit }
END {
  for (i = 1; i <= n; i++) {
    f = files[i]
    if (ignored(f)) continue
    if (tolower(f) ~ /\.(png|jpe?g|webp|svg|ogg|wav|mp3|ttf|otf|csv)$/) asset[f] = 1
    else if (f ~ /\.import$/) {
      imp[substr(f, 1, length(f) - 7)] = 1
      while ((getline line < f) > 0)
        while (match(line, /res:\/\/\.godot\/imported\/[^"]*/)) {
          if (!(substr(line, RSTART + 22, RLENGTH - 22) in have)) reason("faltan recursos importados en .godot/")
          line = substr(line, RSTART + RLENGTH)
        }
      close(f)
    } else if (f ~ /\.gd$/) {
      while ((getline line < f) > 0)
        if (line ~ /^class_name[ \t]/) { split(line, w, "[ \t]+"); classes[w[2]] = 1 }
      close(f)
    }
  }
  for (a in asset) if (!(a in imp)) reason("hay archivos nuevos sin importar")
  while ((getline line < cache) > 0)
    if (line ~ /^"class": &"/) { split(line, w, "\""); cached[w[4]] = 1 }
  for (c in classes) if (!(c in cached)) reason("cambió la lista de class_name")
  for (c in cached) if (!(c in classes)) reason("cambió la lista de class_name")
}'
import_reason() (
  cd "$project" || exit 0
  if ! [ -d .godot/imported ] || ! [ -f .godot/global_script_class_cache.cfg ]; then
    echo "no hay caché .godot/"
    exit 0
  fi
  ls -1 .godot/imported > "$tmp/have"
  find . \( -path ./.git -o -path ./.godot \) -prune -o -type f -print \
    | LC_ALL=C awk -v cache=.godot/global_script_class_cache.cfg "$IMPORT_AWK" "$tmp/have" -
)

import_if_needed() {
  local reason
  reason="$(import_reason)"
  [ -n "$reason" ] || return 0
  say "Importando el proyecto ($reason)…"
  if ! "$GODOT" --headless --import --path "$project" > "$tmp/import.log" 2>&1; then
    # No se detiene: si de verdad falta algo, las pruebas lo dirán.
    say "AVISO: godot --import terminó con error (se sigue); últimas líneas:"
    tail -n 5 "$tmp/import.log" | tee -a "$log"
  fi
}

# --- Serie: un solo proceso con todos los argumentos, salida en vivo.
# (${args[@]+…}: el bash 3.2 de macOS no expande un arreglo vacío con set -u.)
run_serial() {
  say "Modo: serie (un proceso)${1:+ — $1}"
  import_if_needed
  # --fixed-fps 60: reloj simulado. Cada cuadro recibe delta = 1/60 s exacto y Godot
  # no espera al reloj real, así que la suite corre mucho más rápido con los mismos
  # pasos de tiempo que un celular a 60 fps.
  "$GODOT" --headless --fixed-fps 60 --path "$project" res://tests/run_tests.tscn -- ${args[@]+"${args[@]}"} 2>&1 \
    | grep --line-buffered -vE "$NOISE" | tee -a "$log"
  local status=${PIPESTATUS[0]}
  print_total_time ""
  echo "Log: $log"
  exit "$status"
}

# --- ¿Serie o paralelo?
for a in ${args[@]+"${args[@]}"}; do
  case "$a" in
    --level=* | --mode=*) run_serial "con $a solo corre test_levels" ;;
    --list) run_serial ;;
  esac
done
if [ "$jobs_wanted" = 1 ]; then
  run_serial "-j 1"
fi
if ((BASH_VERSINFO[0] < 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] < 1))); then
  run_serial "bash $BASH_VERSION no tiene wait -n -p; instala bash 5.1+ para el modo paralelo"
fi
cores="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
[[ "$cores" =~ ^[0-9]+$ ]] || cores="${NUMBER_OF_PROCESSORS:-}"
[[ "$cores" =~ ^[0-9]+$ ]] || cores=4
if [ -n "$jobs_wanted" ]; then
  max_jobs="$jobs_wanted"
  why_jobs="-j $jobs_wanted"
else
  max_jobs=$((cores - 2))
  ((max_jobs < 1)) && max_jobs=1
  why_jobs="núcleos: $cores − 2"
fi
((max_jobs == 1)) && run_serial "$why_jobs"

# Filtros del usuario, con la misma regla que el runner (--only por subcadena, o
# exacto si termina en .gd). Lo que hace --fast no se sabe sin Godot (hay que
# cargar cada script para ver su SLOW y si compila), así que con --fast se le
# pregunta al runner (--list) antes de armar la cola.
fast=0
only_given=0
only_parts=()
for a in "${args[@]}"; do
  case "$a" in
    --fast) fast=1 ;;
    --only=*)
      only_given=1
      IFS=, read -ra parts <<< "${a#--only=}"
      for p in "${parts[@]}"; do
        p="${p#"${p%%[![:space:]]*}"}"
        p="${p%"${p##*[![:space:]]}"}"
        [ -n "$p" ] && only_parts+=("$p")
      done
      ;;
    *) say "AVISO: argumento desconocido '$a' (se ignora)" ;;
  esac
done
files=()
for path in "$project"/tests/test_*.gd; do
  f="${path##*/}"
  [[ "$f" == test_case.gd || "$f" == test_runner.gd ]] && continue
  if ((only_given)); then
    m=0
    for p in "${only_parts[@]}"; do
      if [[ "$p" == *.gd ]]; then [[ "$f" == "$p" ]] && m=1; else [[ "$f" == *"$p"* ]] && m=1; fi
    done
    ((m)) || continue
  fi
  files+=("$f")
done
# Sin coincidencias, el runner da el error de siempre (código 1).
((${#files[@]} == 0)) && run_serial
((${#files[@]} == 1)) && [ "${files[0]}" != test_levels.gd ] && run_serial "un solo archivo"

say "Modo: paralelo, hasta $max_jobs procesos a la vez ($why_jobs)"
import_if_needed

list_godot() {
  "$GODOT" --headless --path "$project" res://tests/run_tests.tscn -- --list "$@" > "$tmp/list" 2>&1
}
skipped_line=""
if ((fast)); then
  if ! list_godot "${args[@]}" || ! grep -q '^LISTA archivo ' "$tmp/list"; then
    run_serial "nada que repartir"  # el runner explica por qué (código 1)
  fi
  files=()
  while IFS= read -r f; do files+=("$f"); done < <(sed -n 's/^LISTA archivo //p' "$tmp/list")
  skipped_line="$(sed -n 's/^LISTA saltadas //p' "$tmp/list")"
fi

# --- Trabajos: J_ARGS (argumentos para el runner), J_LABEL (nombre en pantalla) y
# J_EST (segundos que tardó en los logs más recientes; 1 si no aparece), para
# arrancar primero los más largos.
J_ARGS=()
J_LABEL=()
J_EST=()
declare -A EST
while IFS=$'\t' read -r secs label; do
  EST["$label"]="$secs"
done < <(
  shopt -s nullglob
  logs=("$out"/*.log)
  ((${#logs[@]})) || exit 0
  # Encabezados "[k/M] >> trabajo (N s)" (paralelo) o "== test_x.gd (N s)" (serie).
  ls -t "${logs[@]}" | head -n 6 | tr '\n' '\0' | xargs -0 cat | LC_ALL=C awk '
    { line = $0 }
    sub(/^\[[0-9]+\/[0-9]+\] >> /, "", line) || (line ~ /^== test_[a-z0-9_]+\.gd \([0-9.]+ s\)/ && sub(/^== /, "", line)) {
      i = index(line, " (")
      if (i == 0) next
      label = substr(line, 1, i - 1)
      if (!(label in seen)) { seen[label] = 1; printf "%s\t%s\n", substr(line, i + 2) + 0, label }
    }'
)
pending=()
add_job() {  # etiqueta, argumentos…
  local i=${#J_ARGS[@]}
  J_LABEL[i]="$1"
  shift
  J_ARGS[i]="$*"
  J_EST[i]="${EST["${J_LABEL[i]}"]:-1}"
  pending+=("$i")
}
# Un trabajo por nivel y modo, más el de fast-run (que lleva el check de la lista
# de niveles: la suma da los mismos checks que test_levels.gd entero). Si no se
# supo la lista (test_levels.gd no compila o falló el runner), un solo trabajo con
# test_levels.gd completo, que reporta la falla.
add_level_jobs() {
  local ids id mode
  ids="$(sed -n 's/^LISTA niveles //p' "$tmp/list" 2>/dev/null)"
  if [ -z "$ids" ]; then
    add_job test_levels.gd --only=test_levels.gd
    return
  fi
  for mode in grande peque; do
    for id in ${ids//,/ }; do
      add_job "test_levels.gd --level=$id --mode=$mode" --only=test_levels.gd --level="$id" --mode="$mode"
    done
  done
  add_job "test_levels.gd --mode=fast-run" --only=test_levels.gd --mode=fast-run
}
sort_pending() {
  local -a sorted=()
  local i
  while IFS=$'\t' read -r _ i; do sorted+=("$i"); done < <(
    for i in "${pending[@]}"; do printf '%s\t%s\n' "${J_EST[i]}" "$i"; done | LC_ALL=C sort -t$'\t' -k1,1gr -k2,2n
  )
  pending=("${sorted[@]}")
}

levels_async=0
for f in "${files[@]}"; do
  if [ "$f" = test_levels.gd ]; then
    if ((fast)); then add_level_jobs; else levels_async=1; fi
  else
    add_job "$f" --only="$f"
  fi
done
sort_pending

# Resume la salida de un trabajo (POSIX awk): quita el ruido, convierte su
# "== RESULTADO" en "-- trabajo:" (el único "== RESULTADO" es el total) y deja en
# archivos aparte su suma, sus FALLA de resumen y sus AVISO. Un godot que muere o
# sale con un código inesperado sin decir RESULTADO cuenta como una falla.
JOB_AWK='
BEGIN { p = 0; f = 0; got = 0; after = 0; n = 0 }
$0 ~ noise || /^Filtro: / { next }
/^== RESULTADO: [0-9]+ pasan, [0-9]+ fallan/ {
  split($0, w, " "); p = w[3] + 0; f = w[5] + 0; got = 1; after = 1
  body[++n] = "-- trabajo: " p " pasan, " f " fallan"; next
}
after && /^   FALLA / { print > fal }
/^AVISO/ { print > avi }
{ body[++n] = $0 }
END {
  extra = ""
  if (!got) { f = 1; extra = "   FALLA " label ": godot terminó con código " code " sin imprimir RESULTADO" }
  else if (code != 0 && f == 0) { f = 1; extra = "   FALLA " label ": godot terminó con código " code " sin reportar fallas" }
  if (extra != "") { body[++n] = extra; print extra > fal }
  printf ">> %s (%s s)%s\n", label, secs, (f > 0 ? " FALLA" : "")
  for (k = 1; k <= n; k++) print body[k]
  print p, f > sum
}'
AWK_NOISE="${NOISE//\\s/[[:space:]]}"  # awk POSIX no conoce \s

run_job() {  # índice; corre en segundo plano y deja <i>.block, <i>.sum, <i>.fal, <i>.avi
  local i=$1 t0 code secs
  t0=${EPOCHREALTIME//[.,]/}
  # J_ARGS sin comillas a propósito: son palabras sin espacios ni comodines.
  "$GODOT" --headless --fixed-fps 60 --path "$project" res://tests/run_tests.tscn -- ${J_ARGS[i]} \
    > "$tmp/$i.raw" 2>&1 &
  echo $! > "$tmp/$i.pid"
  wait $!
  code=$?
  t0=$((${EPOCHREALTIME//[.,]/} - t0))
  printf -v secs '%d.%d' $((t0 / 1000000)) $((t0 / 100000 % 10))
  [ -f "$tmp/$i.raw" ] || return 0  # interrumpido antes de arrancar
  : > "$tmp/$i.fal"
  : > "$tmp/$i.avi"
  LC_ALL=C awk -v noise="$AWK_NOISE" -v label="${J_LABEL[i]}" -v code="$code" -v secs="$secs" \
    -v sum="$tmp/$i.sum" -v fal="$tmp/$i.fal" -v avi="$tmp/$i.avi" "$JOB_AWK" "$tmp/$i.raw" > "$tmp/$i.block"
  rm -f "$tmp/$i.pid"
}

# Ctrl+C: cierra los godot que sigan vivos y sale.
on_interrupt() {
  local p
  trap '' INT TERM
  for p in "$tmp"/*.pid; do [ -f "$p" ] && kill "$(< "$p")" 2>/dev/null; done
  [ -n "${list_pid:-}" ] && kill "$list_pid" 2>/dev/null
  wait  # los subshells de los trabajos terminan solos al morir su godot
  echo "Interrumpido." >&2
  exit 130
}
declare -A JOB_OF_PID
trap on_interrupt INT TERM

# --- Cola: hasta max_jobs a la vez. Al terminar uno, arranca el siguiente y se
# imprime el bloque entero del que terminó (sin procesos externos en este ciclo:
# en Git Bash cada uno cuesta decenas de ms y retrasaría la cola). La lista de
# niveles se le pide a Godot en segundo plano mientras ya corren los demás.
running=0
list_pid=""
fill_slots() {
  local i
  while ((running < max_jobs && ${#pending[@]} > 0)); do
    i=${pending[0]}
    pending=("${pending[@]:1}")
    run_job "$i" &
    JOB_OF_PID[$!]=$i
    running=$((running + 1))
  done
}
if ((levels_async)); then
  # Sin función de por medio: así $! es el propio godot (Ctrl+C lo puede cerrar).
  "$GODOT" --headless --path "$project" res://tests/run_tests.tscn -- --list --only=test_levels.gd \
    > "$tmp/list" 2>&1 &
  list_pid=$!
  running=1
fi
done_count=0
total_passed=0
total_failed=0
summaries=()
fill_slots
while ((running > 0)); do
  wait -n -p finished
  running=$((running - 1))
  if [ "$finished" = "$list_pid" ]; then
    list_pid=""
    add_level_jobs
    sort_pending
    fill_slots
    continue
  fi
  fill_slots
  i=${JOB_OF_PID[$finished]}
  done_count=$((done_count + 1))
  if [ -f "$tmp/$i.sum" ]; then
    read -r jp jf < "$tmp/$i.sum"
    mapfile -t block < "$tmp/$i.block"
  else
    jp=0
    jf=1
    block=(">> ${J_LABEL[i]} FALLA" "   FALLA ${J_LABEL[i]}: el trabajo terminó sin resultado")
    printf '%s\n' "${block[1]}" > "$tmp/$i.fal"
    : > "$tmp/$i.avi"
  fi
  summaries+=("$tmp/$i.avi" "$tmp/$i.fal")
  total_passed=$((total_passed + jp))
  total_failed=$((total_failed + jf))
  block[0]="[$done_count/${#J_ARGS[@]}] ${block[0]}"
  printf '%s\n' "${block[@]}"
  printf '%s\n' "${block[@]}" >> "$log"
done

# --- Resumen, como en serie: saltadas, AVISO, RESULTADO y FALLA (en el orden en
# que terminaron los trabajos).
if ((done_count == 0)); then
  total_failed=$((total_failed + 1))
  printf '   FALLA ninguna prueba corrió: la cola quedó vacía\n' > "$tmp/vacia.fal"
  summaries+=("$tmp/vacia.fal")
fi
{
  [ -z "$skipped_line" ] || echo "Saltadas por --fast (SLOW): $skipped_line"
  cat "${summaries[@]}" | grep '^AVISO'
  echo "== RESULTADO: $total_passed pasan, $total_failed fallan"
  cat "${summaries[@]}" | grep '^   FALLA'
} | tee -a "$log"
print_total_time " (${#J_ARGS[@]} trabajos, hasta $((max_jobs < ${#J_ARGS[@]} ? max_jobs : ${#J_ARGS[@]})) a la vez)"
echo "Log: $log"
((total_failed == 0))
