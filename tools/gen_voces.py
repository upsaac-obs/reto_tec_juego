#!/usr/bin/env python3
"""Genera las voces del copiloto: assets/audio/voz/<CLAVE>.ogg para cada clave
de i18n/textos.csv (columna "es").

Voz PROVISIONAL con espeak-ng (sin internet). El motor es reemplazable: cada
motor es una función `motor(texto, wav_salida)` registrada en ENGINES; para usar
un TTS mejor (por ejemplo Piper con una voz mexicana descargada a mano) se agrega
su función ahí y se corre con `--engine <nombre>`.

Solo regenera las claves cuyo texto (o motor/voz) cambió desde la última vez:
guarda un hash por clave en tools/voz_manifest.json (fuera de res:// a propósito
para que no se exporte con el juego).

Uso:
    python3 tools/gen_voces.py                      # las que cambiaron
    python3 tools/gen_voces.py --key FALTA_ALTO     # solo esa clave (forzada)
    python3 tools/gen_voces.py --force              # todas
    python3 tools/gen_voces.py --prune              # borra .ogg de claves que ya no existen
    python3 tools/gen_voces.py --engine espeak --voice es-419+f3
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "i18n" / "textos.csv"
OUT_DIR = ROOT / "assets" / "audio" / "voz"
MANIFEST = Path(__file__).resolve().parent / "voz_manifest.json"
LANG_COLUMN = "es"

# Salida: mono, 24 kHz, Vorbis de baja calidad (voz sintética, basta y pesa poco).
OUT_RATE = 24000
OGG_QUALITY = "1"

# Ajustes de la voz provisional. es-419 = español de Latinoamérica (alias es-mx).
ESPEAK_VOICE = "es-419+f3"   # variante femenina, más suave
ESPEAK_SPEED = 140           # palabras por minuto (lento y claro para peques)
ESPEAK_PITCH = 62            # 0-99, un poco más agudo y amigable
ESPEAK_GAP = 2               # pausa extra entre palabras (en 10 ms)

# Palabras que el TTS lee mal: se reemplazan solo para hablar, no en pantalla.
PRONUNCIATION = {
    r"\bRutaKids\b": "Ruta Kids",
    r"\bbicis\b": "bicicletas",
    r"\bbici\b": "bicicleta",
}


def speakable(text: str) -> str:
    """Limpia el texto de pantalla para el TTS: puntuación rara, símbolos, alias."""
    s = text.strip()
    s = s.replace("·", ",").replace("…", ".").replace("...", ".")
    s = s.replace("—", ",").replace("–", ",").replace("+", " más ")
    # ¡ y ¿ no se pronuncian; espeak los acepta, pero quitarlos evita pausas raras.
    s = s.replace("¡", "").replace("¿", "")
    for pat, rep in PRONUNCIATION.items():
        s = re.sub(pat, rep, s)
    s = re.sub(r"\s+", " ", s).strip()
    # Una etiqueta suelta ("Jugar") suena mejor con punto final (entonación cerrada).
    if s and s[-1] not in ".!?:,":
        s += "."
    return s


# --- Motores ------------------------------------------------------------------

def engine_espeak(text: str, wav_out: Path, voice: str) -> None:
    subprocess.run(
        ["espeak-ng", "-v", voice, "-s", str(ESPEAK_SPEED), "-p", str(ESPEAK_PITCH),
         "-g", str(ESPEAK_GAP), "-w", str(wav_out), text],
        check=True,
    )


ENGINES = {
    # nombre: (función, voz por defecto)
    "espeak": (engine_espeak, ESPEAK_VOICE),
}


# --- Proceso ------------------------------------------------------------------

def read_texts() -> dict[str, str]:
    with CSV_PATH.open(encoding="utf-8", newline="") as f:
        rows = csv.DictReader(f)
        return {r["keys"].strip(): r[LANG_COLUMN] for r in rows if r.get("keys", "").strip()}


def fingerprint(text: str, engine: str, voice: str) -> str:
    settings = f"{engine}|{voice}|{ESPEAK_SPEED}|{ESPEAK_PITCH}|{ESPEAK_GAP}|{OUT_RATE}|{OGG_QUALITY}"
    return hashlib.sha1(f"{settings}\n{speakable(text)}".encode()).hexdigest()[:16]


def wav_to_ogg(wav: Path, ogg: Path) -> None:
    # Quita silencio al inicio, sube el volumen a un pico parejo y codifica en mono.
    filters = ("silenceremove=start_periods=1:start_threshold=-50dB,"
               "areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse,"
               "highpass=f=90,loudnorm=I=-18:TP=-2:LRA=11,"
               f"aresample={OUT_RATE},apad=pad_dur=0.12")
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-af", filters, "-ac", "1",
         "-ar", str(OUT_RATE), "-c:a", "libvorbis", "-q:a", OGG_QUALITY,
         "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact", str(ogg)],
        check=True,
    )


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--engine", default="espeak", choices=sorted(ENGINES))
    ap.add_argument("--voice", default=None, help="voz del motor (por defecto la del motor)")
    ap.add_argument("--key", action="append", default=[], help="genera solo esta clave (se puede repetir)")
    ap.add_argument("--force", action="store_true", help="regenera aunque el texto no haya cambiado")
    ap.add_argument("--prune", action="store_true", help="borra .ogg de claves que ya no están en el CSV")
    args = ap.parse_args()

    func, default_voice = ENGINES[args.engine]
    voice = args.voice or default_voice
    texts = read_texts()
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {}

    keys = args.key or list(texts)
    missing = [k for k in keys if k not in texts]
    if missing:
        print("Claves que no están en textos.csv:", ", ".join(missing))
        return 1
    force = args.force or bool(args.key)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    made = skipped = 0
    with tempfile.TemporaryDirectory() as tmp:
        for key in keys:
            fp = fingerprint(texts[key], args.engine, voice)
            ogg = OUT_DIR / f"{key}.ogg"
            if not force and manifest.get(key) == fp and ogg.exists():
                skipped += 1
                continue
            wav = Path(tmp) / f"{key}.wav"
            func(speakable(texts[key]), wav, voice)
            wav_to_ogg(wav, ogg)
            manifest[key] = fp
            made += 1
            print(f"  {key}: {speakable(texts[key])}")

    if args.prune:
        for ogg in OUT_DIR.glob("*.ogg"):
            if ogg.stem not in texts:
                ogg.unlink()
                Path(str(ogg) + ".import").unlink(missing_ok=True)
                manifest.pop(ogg.stem, None)
                print(f"  borrada {ogg.name}")

    MANIFEST.write_text(json.dumps(dict(sorted(manifest.items())), indent=1, ensure_ascii=False) + "\n",
                        encoding="utf-8")
    total = sum(p.stat().st_size for p in OUT_DIR.glob("*.ogg"))
    print(f"Generadas {made}, sin cambios {skipped}. Carpeta voz: "
          f"{len(list(OUT_DIR.glob('*.ogg')))} archivos, {total / 1024 / 1024:.2f} MB ({voice}, {args.engine}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
