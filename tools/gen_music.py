#!/usr/bin/env python3
"""Genera la música de RutaKids (chiptune suave) y la convierte a .ogg con ffmpeg.

- assets/audio/musica/nivel.ogg: bucle alegre y tranquilo en Do mayor, 100 BPM,
  32 compases (76.8 s). Las colas de las notas y el eco se "envuelven" al inicio,
  así el final empata con el principio sin costura.
- assets/audio/musica/menu_jingle.ogg: jingle corto (unos 4 s, sin bucle).

Solo usa numpy y ffmpeg (sin internet). Determinista: misma partitura, mismo audio.

Uso:
    python3 tools/gen_music.py
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np

SR = 32000
BPM = 100
BEAT = 60 / BPM
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "audio" / "musica"
# Calidad Vorbis (0 a 10). 2 ≈ 64 kb/s en mono: suficiente para chiptune.
OGG_QUALITY = "2"

NOTE_NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi(name: str) -> int:
    """'C5', 'F#4', 'Bb3' → número MIDI."""
    base = NOTE_NAMES[name[0]]
    rest = name[1:]
    if rest.startswith("#"):
        base, rest = base + 1, rest[1:]
    elif rest.startswith("b"):
        base, rest = base - 1, rest[1:]
    return 12 * (int(rest) + 1) + base


def hz(m: float) -> float:
    return 440.0 * 2 ** ((m - 69) / 12)


# --- Instrumentos (síntesis aditiva, sin aliasing) ---------------------------

def pulse(f: float, t: np.ndarray, duty: float = 0.25, max_h: int = 12) -> np.ndarray:
    """Onda de pulso con armónicos limitados y atenuados: suena a 8 bits pero suave."""
    out = np.zeros_like(t)
    for k in range(1, max_h + 1):
        if k * f > SR * 0.45:
            break
        amp = np.sin(np.pi * k * duty) / k * (1 / (1 + (k * f / 3500) ** 2))
        out += amp * np.sin(2 * np.pi * k * f * t)
    return out


def triangle(f: float, t: np.ndarray) -> np.ndarray:
    out = np.zeros_like(t)
    for i, k in enumerate((1, 3, 5, 7, 9)):
        out += ((-1) ** i) / k**2 * np.sin(2 * np.pi * k * f * t)
    return out * 8 / np.pi**2


def adsr(n: int, a=0.01, d=0.08, s=0.6, r=0.08, hold: float | None = None) -> np.ndarray:
    t = np.arange(n) / SR
    hold = hold if hold is not None else n / SR - r
    e = np.where(t < a, t / a, np.where(t < a + d, 1 - (1 - s) * (t - a) / d, s))
    rel = np.clip(1 - (t - hold) / r, 0, 1)
    return e * np.where(t > hold, rel, 1)


def lead_note(m: int, beats: float) -> np.ndarray:
    dur = beats * BEAT
    n = int((dur + 0.15) * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.25) / 0.2, 0, 1)
    f = hz(m)
    phase_t = np.cumsum(vib) / SR
    return pulse(f, phase_t, 0.25) * adsr(n, 0.008, 0.1, 0.55, 0.12, hold=dur * 0.9)


def arp_note(m: int, dur: float) -> np.ndarray:
    n = int((dur + 0.1) * SR)
    t = np.arange(n) / SR
    return pulse(hz(m), t, 0.5, 6) * np.exp(-t * 9) * np.clip(t / 0.003, 0, 1)


def bass_note(m: int, dur: float) -> np.ndarray:
    n = int((dur + 0.08) * SR)
    t = np.arange(n) / SR
    return triangle(hz(m), t) * adsr(n, 0.005, 0.15, 0.7, 0.08, hold=dur * 0.85)


def hat(seed: int) -> np.ndarray:
    n = int(0.05 * SR)
    r = np.random.default_rng([7, seed])
    x = r.standard_normal(n)
    x = np.diff(x, prepend=0)  # quita graves: suena a "tss" chiquito
    return x * np.exp(-np.arange(n) / SR * 90)


def kick() -> np.ndarray:
    n = int(0.18 * SR)
    t = np.arange(n) / SR
    f = 110 * np.exp(-t * 25) + 45
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 18)


# --- Partitura ----------------------------------------------------------------

CHORDS = {
    "C": ("C3", ("C4", "E4", "G4")),
    "Am": ("A2", ("A3", "C4", "E4")),
    "F": ("F2", ("F3", "A3", "C4")),
    "G": ("G2", ("G3", "B3", "D4")),
    "Em": ("E2", ("E3", "G3", "B3")),
    "Dm": ("D3", ("D4", "F4", "A4")),
}

# Cada compás: acordes (uno o dos por compás) y melodía [(nota|None, tiempos)].
A_CHORDS = [["C"], ["Am"], ["F"], ["G"], ["C"], ["Am"], ["F", "G"], ["C"]]
B_CHORDS = [["F"], ["G"], ["Em"], ["Am"], ["F"], ["G"], ["Dm"], ["G"]]

A_MELODY = [
    [("E5", 1), ("G5", 1), ("E5", 1), ("C5", 1)],
    [("A4", 1), ("C5", 1), ("E5", 2)],
    [("F5", 1), ("E5", 1), ("D5", 1), ("C5", 1)],
    [("D5", 3), (None, 1)],
    [("E5", 1), ("G5", 1), ("C6", 1), ("G5", 1)],
    [("A5", 1), ("G5", 1), ("E5", 2)],
    [("F5", 1), ("A5", 1), ("G5", 1), ("B4", 1)],
    [("C5", 3), (None, 1)],
]
# Segunda vuelta de A: cambia dos compases para que no sea idéntica.
A2_MELODY = A_MELODY[:3] + [[("D5", 1), ("E5", 0.5), ("D5", 0.5), ("B4", 2)]] + A_MELODY[4:7] + [[("C5", 2), ("E5", 1), ("G5", 1)]]
B_MELODY = [
    [("A5", 1.5), ("G5", 0.5), ("F5", 2)],
    [("G5", 1.5), ("F5", 0.5), ("D5", 2)],
    [("E5", 1), ("G5", 1), ("B5", 1), ("G5", 1)],
    [("A5", 3), (None, 1)],
    [("F5", 1), ("A5", 1), ("C6", 1), ("A5", 1)],
    [("B5", 1), ("G5", 1), ("D5", 2)],
    [("F5", 1), ("E5", 1), ("D5", 1), ("F5", 1)],
    [("G5", 2), ("B4", 1), ("D5", 1)],
]
# Última A: termina con un "respiro" para volver al inicio del bucle.
A3_MELODY = A_MELODY[:7] + [[("C5", 2), (None, 2)]]

SECTIONS = [
    (A_CHORDS, A_MELODY, False),
    (A_CHORDS, A2_MELODY, False),
    (B_CHORDS, B_MELODY, True),
    (A_CHORDS, A3_MELODY, True),
]


def add(buf: np.ndarray, x: np.ndarray, at: float, gain: float) -> None:
    """Suma envolviendo al inicio lo que se pase del final (bucle sin costura)."""
    start = int(round(at * SR))
    idx = (np.arange(len(x)) + start) % len(buf)
    np.add.at(buf, idx, x * gain)


def render_level_loop() -> np.ndarray:
    bars = sum(len(s[0]) for s in SECTIONS)
    total = bars * 4 * BEAT
    lead = np.zeros(int(round(total * SR)))
    back = np.zeros_like(lead)
    bar = 0
    for chords, melody, drums in SECTIONS:
        for b in range(8):
            t0 = (bar + b) * 4 * BEAT
            # Melodía
            pos = 0.0
            for name, beats in melody[b]:
                if name:
                    add(lead, lead_note(midi(name), beats), t0 + pos * BEAT, 0.30)
                pos += beats
            # Acordes: bajo en tiempos 1 y 3, arpegio en octavos.
            per = 4 // len(chords[b])
            for ci, ch in enumerate(chords[b]):
                root, tones = CHORDS[ch]
                for k in range(0, per, 2):
                    add(back, bass_note(midi(root), BEAT * 1.6), t0 + (ci * per + k) * BEAT, 0.35)
                pattern = [0, 1, 2, 1] * 2
                for k in range(per * 2):
                    add(back, arp_note(midi(tones[pattern[k]]), BEAT / 2), t0 + (ci * per + k / 2) * BEAT, 0.09)
            # Percusión muy suave: "tss" a contratiempo; bombo solo en B y A final.
            for k in range(4):
                add(back, hat(bar * 4 + k), t0 + (k + 0.5) * BEAT, 0.05)
                if drums and k % 2 == 0:
                    add(back, kick(), t0 + k * BEAT, 0.22)
        bar += 8
    # Eco circular en la melodía (octavo con puntillo), también sin costura.
    d = int(round(0.75 * BEAT * SR))
    lead = lead + 0.28 * np.roll(lead, d) + 0.08 * np.roll(lead, 2 * d)
    mix = lead + back
    # Pasa bajas suave por FFT (periódico, respeta el bucle): quita lo chillón.
    spec = np.fft.rfft(mix)
    f = np.fft.rfftfreq(len(mix), 1 / SR)
    mix = np.fft.irfft(spec / np.sqrt(1 + (f / 6000) ** 4), len(mix))
    return mix


def render_menu_jingle() -> np.ndarray:
    notes = [("C5", 0, 0.5), ("E5", 0.5, 0.5), ("G5", 1, 0.5), ("C6", 1.5, 1),
             ("A5", 2.5, 0.5), ("B5", 3, 0.5), ("C6", 3.5, 3)]
    total = 8 * BEAT * 0.8
    buf = np.zeros(int((total + 1.0) * SR))

    def put(x, at, g):
        s = int(at * SR)
        e = min(len(buf), s + len(x))
        buf[s:e] += x[: e - s] * g

    for name, at, beats in notes:
        put(lead_note(midi(name), beats * 0.8), at * BEAT * 0.8, 0.35)
    for at, (root, tones) in ((0, CHORDS["C"]), (2.5, CHORDS["F"]), (3.5, CHORDS["C"])):
        put(bass_note(midi(root), BEAT * 1.2), at * BEAT * 0.8, 0.35)
        for i, tn in enumerate(tones):
            put(arp_note(midi(tn) + 12, BEAT), (at + i * 0.25) * BEAT * 0.8, 0.12)
    n = len(buf)
    buf *= np.minimum(1, np.linspace(6, 0, n) ** 1)  # se apaga al final
    return buf


def to_ogg(x: np.ndarray, out: Path, peak: float = 0.8) -> None:
    x = x - x.mean()
    x = x * (peak / np.max(np.abs(x)))
    pcm = np.clip(np.round(x * 32767), -32767, 32767).astype("<i2")
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "m.wav"
        with wave.open(str(wav), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis",
             "-q:a", OGG_QUALITY, "-map_metadata", "-1", "-fflags", "+bitexact",
             "-flags:a", "+bitexact", str(out)],
            check=True,
        )
    print(f"{out.name:18s} {len(x) / SR:5.1f} s  {out.stat().st_size / 1024:6.1f} KB")


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    to_ogg(render_level_loop(), OUT_DIR / "nivel.ogg")
    to_ogg(render_menu_jingle(), OUT_DIR / "menu_jingle.ogg")
    return 0


if __name__ == "__main__":
    sys.exit(main())
