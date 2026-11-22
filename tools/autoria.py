#!/usr/bin/env python3
# Creación y desarrollo: Dylan Isaac Mancilla López
"""Pone (o actualiza) la línea de autoría al inicio de cada archivo de código del repo:

    # Creación y desarrollo: Nombre Apellido, Otro Nombre

Los autores salen del historial de git de cada archivo (git log --follow), ordenados por
cuántos commits hizo cada quien en ese archivo. AUTHORS traduce la cuenta de git al nombre.
Es idempotente: si el archivo ya tiene la línea, la reemplaza. Se corre de nuevo cuando
haya archivos nuevos o cambie quién trabajó en ellos.

Uso: python3 tools/autoria.py [--dry-run]
"""
from __future__ import annotations

import argparse
import subprocess
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "Creación y desarrollo: "
# Asunto de los commits que solo actualizan estas líneas (no cuentan como autoría).
HEADER_COMMIT = "Autoría al inicio"

# Cuenta de git -> nombre completo.
AUTHORS = {
    "upsaac-obs": "Dylan Isaac Mancilla López",
    "PauloVel": "José Paulo Vélez Ortiz",
    "Paulo Vélez": "José Paulo Vélez Ortiz",
    "ITESM-VCAM": "Angel Mael Vera Carpio",
    # Los commits con autor "Claude" son los de los PR #1 y #2 de Diego (whoisdiego),
    # hechos con Claude Code desde su cuenta.
    "Claude": "Diego Sánchez López",
}
# Quien aparece si el archivo todavía no tiene commits (archivo nuevo).
DEFAULT_AUTHOR = "Dylan Isaac Mancilla López"

COMMENT = {".gd": "#", ".py": "#", ".sh": "#", ".kt": "//", ".kts": "//", ".swift": "//"}
SKIP_DIRS = ("tests/resultados/", "native/android/app/build/", ".godot/")


def authors_of(path: str) -> list[str]:
    # Una línea por commit: autor y asunto (%an puede tener espacios: "Paulo Vélez").
    # Los commits que solo ponen estas líneas de autoría no cuentan como trabajo en el archivo.
    lines = subprocess.run(["git", "log", "--follow", "--format=%an\t%s", "--", path],
                           cwd=ROOT, capture_output=True, text=True, check=True).stdout.splitlines()
    names = [line.split("\t", 1)[0].strip() for line in lines
             if line.strip() and not line.split("\t", 1)[-1].startswith(HEADER_COMMIT)]
    counts = Counter(AUTHORS.get(name, name) for name in names if name)
    if not counts:
        return [DEFAULT_AUTHOR]
    # Más commits primero; empate: el orden de AUTHORS (Dylan primero).
    order = list(dict.fromkeys(AUTHORS.values()))
    return sorted(counts, key=lambda n: (-counts[n], order.index(n) if n in order else len(order)))


def files() -> list[str]:
    tracked = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True).stdout.splitlines()
    others = subprocess.run(["git", "ls-files", "--others", "--exclude-standard"], cwd=ROOT,
                            capture_output=True, text=True, check=True).stdout.splitlines()
    return sorted(f for f in set(tracked + others)
                  if Path(f).suffix in COMMENT and not f.startswith(SKIP_DIRS) and (ROOT / f).is_file())


def apply(path: str, dry_run: bool) -> bool:
    file = ROOT / path
    mark = COMMENT[file.suffix]
    header = f"{mark} {PREFIX}{', '.join(authors_of(path))}"
    lines = file.read_text(encoding="utf-8").split("\n")
    # Después del shebang (#!) si lo hay.
    at = 1 if lines and lines[0].startswith("#!") else 0
    if at < len(lines) and lines[at].startswith(f"{mark} {PREFIX}"):
        if lines[at] == header:
            return False
        lines[at] = header
    else:
        lines.insert(at, header)
    if not dry_run:
        file.write_text("\n".join(lines), encoding="utf-8")
    return True


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="solo muestra qué cambiaría")
    args = ap.parse_args()
    changed = Counter()
    for path in files():
        if apply(path, args.dry_run):
            changed[", ".join(authors_of(path))] += 1
    for who, n in changed.most_common():
        print(f"{n:4d}  {who}")
    print(f"{sum(changed.values())} archivos {'cambiarían' if args.dry_run else 'actualizados'}")


if __name__ == "__main__":
    main()
