#!/usr/bin/env python3
"""Genera los efectos de sonido cortos (.wav) de RutaKids en assets/audio/sfx/.

Solo usa numpy y la librería estándar. Es determinista: la misma versión del
script produce exactamente los mismos archivos (el ruido usa una semilla fija).

Estilo: suave, redondo y amigable para niñas y niños de 4 a 13 años. Nada de
sonidos agudos fuertes ni golpes secos. Mono, 22050 Hz, 16 bits (como good.wav).

Los sonidos en bucle (engine_loop, turn_signal_loop, rain_loop) tienen una
duración con número entero de ciclos de cada frecuencia y llevan un bloque
'smpl' en el WAV con el punto de bucle, así Godot los importa ya en bucle
(edit/loop_mode = "Detect From WAV").

Uso:
    python3 tools/gen_sfx.py            # genera todos
    python3 tools/gen_sfx.py horn coin  # solo los nombrados
"""

from __future__ import annotations

import struct
import sys
from pathlib import Path

import numpy as np

SR = 22050
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "audio" / "sfx"
# Pico máximo después de normalizar (-3 dBFS aprox.), nunca recorta.
PEAK = 0.70
SEED = 20260


# --- Utilidades ---------------------------------------------------------------

def t_axis(seconds: float) -> np.ndarray:
    return np.arange(int(round(seconds * SR))) / SR


def env_ad(n: int, attack: float, decay_rate: float) -> np.ndarray:
    """Envolvente de ataque lineal corto y caída exponencial."""
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0.0, 1.0)
    return a * np.exp(-t * decay_rate)


def fade(x: np.ndarray, fade_in: float = 0.004, fade_out: float = 0.02) -> np.ndarray:
    """Rampas cortas para que no haya clics al inicio ni al final."""
    x = x.copy()
    ni, no = int(fade_in * SR), int(fade_out * SR)
    if ni:
        x[:ni] *= np.linspace(0, 1, ni)
    if no:
        x[-no:] *= np.linspace(1, 0, no)
    return x


def soft_tone(freq, t: np.ndarray, harmonics=(1.0, 0.25, 0.08)) -> np.ndarray:
    """Tono redondo: senoide con pocos armónicos (más cálido que una senoide pura)."""
    phase = 2 * np.pi * np.cumsum(np.broadcast_to(freq, t.shape)) / SR
    out = np.zeros_like(t)
    for k, amp in enumerate(harmonics, start=1):
        out += amp * np.sin(k * phase)
    return out


def lowpass(x: np.ndarray, cutoff: float, periodic: bool = False) -> np.ndarray:
    """Filtro pasa bajas suave por FFT (sin scipy). Con periodic=True respeta el bucle."""
    n = len(x)
    pad = 0 if periodic else n
    spec = np.fft.rfft(x, n + pad)
    f = np.fft.rfftfreq(n + pad, 1 / SR)
    spec *= 1 / np.sqrt(1 + (f / cutoff) ** 4)
    return np.fft.irfft(spec, n + pad)[:n]


def bandpass(x: np.ndarray, lo: float, hi: float, periodic: bool = False) -> np.ndarray:
    n = len(x)
    pad = 0 if periodic else n
    spec = np.fft.rfft(x, n + pad)
    f = np.fft.rfftfreq(n + pad, 1 / SR)
    spec *= 1 / np.sqrt(1 + (f / hi) ** 4)
    spec *= 1 / np.sqrt(1 + (lo / np.maximum(f, 1e-3)) ** 4)
    return np.fft.irfft(spec, n + pad)[:n]


def place(buf: np.ndarray, sound: np.ndarray, at: float, wrap: bool = False) -> None:
    """Suma un sonido en el segundo 'at'. Con wrap la cola regresa al inicio (bucles)."""
    start = int(round(at * SR))
    idx = np.arange(len(sound)) + start
    if wrap:
        np.add.at(buf, idx % len(buf), sound)
    else:
        idx = idx[idx < len(buf)]
        buf[idx] += sound[: len(idx)]


def normalize(x: np.ndarray, peak: float = PEAK) -> np.ndarray:
    x = x - np.mean(x)
    m = np.max(np.abs(x))
    return x if m == 0 else x * (peak / m)


def write_wav(name: str, x: np.ndarray, loop: bool = False, peak: float = PEAK) -> Path:
    x = normalize(x, peak)
    pcm = np.clip(np.round(x * 32767), -32767, 32767).astype("<i2").tobytes()
    fmt = struct.pack("<HHIIHH", 1, 1, SR, SR * 2, 2, 16)
    chunks = b"fmt " + struct.pack("<I", len(fmt)) + fmt
    chunks += b"data" + struct.pack("<I", len(pcm)) + pcm
    if len(pcm) % 2:
        chunks += b"\0"
    if loop:
        # Bloque 'smpl' con un bucle hacia adelante de todo el archivo.
        n = len(pcm) // 2
        smpl = struct.pack("<9I", 0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, n - 1, 0, 0)
        chunks += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    data = b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WAVE" + chunks
    path = OUT_DIR / f"{name}.wav"
    path.write_bytes(data)
    return path


def note_hz(midi: float) -> float:
    return 440.0 * 2 ** ((midi - 69) / 12)


def rng(tag: str) -> np.random.Generator:
    # Semilla fija por sonido: cambiar uno no cambia los demás.
    return np.random.default_rng([SEED, sum(map(ord, tag))])


# --- Sonidos ------------------------------------------------------------------

def engine_loop():
    """Motor tranquilo de juguete: zumbido grave con un pulso suave. Bucle de 1 s."""
    dur = 1.0
    t = t_axis(dur)
    # Todas las frecuencias son enteras: ciclos completos en 1 s, bucle sin costura.
    x = (np.sin(2 * np.pi * 55 * t) * 0.9
         + np.sin(2 * np.pi * 110 * t) * 0.45
         + np.sin(2 * np.pi * 165 * t) * 0.18
         + np.sin(2 * np.pi * 220 * t) * 0.07)
    # "Ronroneo" de 8 pulsos por segundo.
    am = 0.78 + 0.22 * np.sin(2 * np.pi * 8 * t) ** 2
    noise = lowpass(rng("engine").standard_normal(len(t)), 300, periodic=True)
    x = x * am + 0.15 * noise * am
    return x, True, 0.5


def brake():
    """Frenado suave: un 'fiu' que baja con un poco de roce."""
    t = t_axis(0.45)
    f = 900 * np.exp(-t * 2.2)
    tone = soft_tone(f, t, (1.0, 0.15)) * env_ad(len(t), 0.02, 5.0)
    hiss = bandpass(rng("brake").standard_normal(len(t)), 1200, 3500) * env_ad(len(t), 0.03, 7.0)
    return fade(tone * 0.7 + hiss * 0.25, fade_out=0.06), False, 0.55


def horn():
    """Claxon tierno 'bip bip': dos tonos juntos (tercera mayor), cortos y redondos."""
    buf = np.zeros(int(0.42 * SR))
    for start in (0.0, 0.2):
        t = t_axis(0.15)
        x = soft_tone(note_hz(76), t, (1.0, 0.35, 0.12)) + 0.8 * soft_tone(note_hz(80), t, (1.0, 0.35, 0.12))
        x *= 1 + 0.02 * np.sin(2 * np.pi * 30 * t)
        place(buf, fade(x, 0.008, 0.03), start)
    return lowpass(buf, 2500), False, 0.6


def _click(freq: float, length: float = 0.04, decay: float = 120.0) -> np.ndarray:
    t = t_axis(length)
    x = np.sin(2 * np.pi * freq * t) * env_ad(len(t), 0.0008, decay)
    x += 0.3 * bandpass(rng(f"click{freq}").standard_normal(len(t)), 1500, 5000) * env_ad(len(t), 0.0005, decay * 2.5)
    return fade(x, 0.0005, 0.005)


def turn_signal_loop():
    """Direccional 'tic-tac'. Bucle de 0.8 s (tic en 0, tac en 0.4)."""
    buf = np.zeros(int(0.8 * SR))
    place(buf, _click(1800), 0.0)
    place(buf, _click(1300) * 0.85, 0.4)
    return lowpass(buf, 4000, periodic=True), True, 0.5


def celebration():
    """Fin de nivel: arpegio que sube (Do-Mi-Sol-Do) y unos destellos."""
    buf = np.zeros(int(1.8 * SR))
    for i, m in enumerate((72, 76, 79, 84)):
        t = t_axis(0.6 if i < 3 else 1.1)
        x = soft_tone(note_hz(m), t, (1.0, 0.3, 0.1)) * env_ad(len(t), 0.005, 4.0 if i < 3 else 2.5)
        place(buf, fade(x), i * 0.11)
    # Acorde final suave.
    t = t_axis(1.2)
    chord = sum(soft_tone(note_hz(m), t, (1.0, 0.2)) for m in (60, 64, 67)) * env_ad(len(t), 0.02, 2.2)
    place(buf, fade(chord) * 0.35, 0.44)
    # Destellos: notas agudas cortas de la escala mayor.
    r = rng("celebration")
    for k in range(7):
        m = 88 + int(r.choice([0, 2, 4, 7, 9]))
        t = t_axis(0.18)
        place(buf, fade(np.sin(2 * np.pi * note_hz(m) * t) * env_ad(len(t), 0.002, 18)) * 0.18, 0.5 + k * 0.1)
    return fade(buf, fade_out=0.1), False, 0.7


def fault_uy():
    """'¡Uy!': dos notas que bajan, suaves (no asusta). Triángulo con vibrato ligero."""
    buf = np.zeros(int(0.65 * SR))
    for m, at, d in ((69, 0.0, 0.22), (65, 0.2, 0.4)):
        t = t_axis(d)
        f = note_hz(m) * (1 + 0.012 * np.sin(2 * np.pi * 6 * t))
        x = soft_tone(f, t, (1.0, 0.0, 0.11, 0.0, 0.04)) * env_ad(len(t), 0.015, 3.5 if at else 6.0)
        place(buf, fade(x, 0.01, 0.05), at)
    return lowpass(buf, 1800), False, 0.55


def phone_ring():
    """Timbre de celular tipo marimba: tres notas que se repiten dos veces."""
    buf = np.zeros(int(1.5 * SR))
    pattern = (79, 84, 88, 84)
    for rep in range(2):
        for i, m in enumerate(pattern):
            t = t_axis(0.25)
            x = soft_tone(note_hz(m), t, (1.0, 0.0, 0.0, 0.25)) * env_ad(len(t), 0.002, 14)
            place(buf, fade(x), rep * 0.75 + i * 0.12)
    return buf, False, 0.55


def phone_vibrate():
    """Celular vibrando: zumbido grave en dos ráfagas."""
    buf = np.zeros(int(1.0 * SR))
    for at in (0.0, 0.5):
        t = t_axis(0.35)
        x = np.sin(2 * np.pi * 150 * t) + 0.5 * np.sign(np.sin(2 * np.pi * 150 * t)) * 0.3
        x *= 0.75 + 0.25 * np.sin(2 * np.pi * 22 * t)
        place(buf, fade(lowpass(x, 600), 0.02, 0.04), at)
    return buf, False, 0.6


def rain_loop():
    """Lluvia suave: ruido filtrado hecho en frecuencia (periódico) + gotitas. Bucle de 4 s."""
    n = int(4.0 * SR)
    r = rng("rain")
    f = np.fft.rfftfreq(n, 1 / SR)
    # Espectro rosa con pico suave alrededor de 1.5 kHz y sin graves ni agudos fuertes.
    shape = 1 / np.sqrt(np.maximum(f, 20)) * np.exp(-((np.log(np.maximum(f, 1) / 1500)) ** 2) / 2.0)
    spec = shape * (r.standard_normal(len(f)) + 1j * r.standard_normal(len(f)))
    spec[0] = 0
    bed = np.fft.irfft(spec, n)
    bed /= np.max(np.abs(bed))
    buf = bed * 0.6
    # Gotitas sueltas que caen en posiciones fijas (con la cola envuelta al inicio).
    for _ in range(45):
        at = r.uniform(0, 4.0)
        t = t_axis(0.03)
        drop = np.sin(2 * np.pi * r.uniform(2500, 4500) * t) * env_ad(len(t), 0.0005, 180)
        place(buf, drop * r.uniform(0.08, 0.2), at, wrap=True)
    return buf, True, 0.4


def lights_on():
    """Interruptor de luces: clic doble suave."""
    buf = np.zeros(int(0.18 * SR))
    place(buf, _click(1100, 0.05, 90), 0.0)
    place(buf, _click(1600, 0.05, 110) * 0.7, 0.06)
    return lowpass(buf, 3500), False, 0.55


def door_open():
    """Puerta: 'clac' del seguro y un 'fuuu' corto de aire."""
    buf = np.zeros(int(0.6 * SR))
    t = t_axis(0.08)
    clack = (np.sin(2 * np.pi * 420 * t) + 0.5 * np.sin(2 * np.pi * 900 * t)) * env_ad(len(t), 0.001, 60)
    place(buf, fade(clack, 0.0005, 0.01), 0.0)
    t = t_axis(0.45)
    whoosh = bandpass(rng("door").standard_normal(len(t)), 400, 1800)
    whoosh *= np.sin(np.pi * np.linspace(0, 1, len(t))) ** 2
    place(buf, whoosh * 0.35, 0.06)
    return lowpass(buf, 3000), False, 0.55


def bus_stop():
    """Freno de aire del camión: 'pssh' suave que se apaga."""
    t = t_axis(0.9)
    x = bandpass(rng("bus").standard_normal(len(t)), 2000, 6000)
    e = np.clip(t / 0.03, 0, 1) * np.exp(-t * 4.0)
    return fade(lowpass(x * e, 7000), 0.002, 0.15), False, 0.45


def coin():
    """Moneda o puntos: 'ding-ding' (Si → Mi) brillante pero corto."""
    buf = np.zeros(int(0.5 * SR))
    t = t_axis(0.08)
    place(buf, fade(soft_tone(note_hz(83), t, (1.0, 0.2)) * env_ad(len(t), 0.002, 8)), 0.0)
    t = t_axis(0.42)
    place(buf, fade(soft_tone(note_hz(88), t, (1.0, 0.2)) * env_ad(len(t), 0.002, 7), fade_out=0.08), 0.07)
    return buf, False, 0.55


SOUNDS = {
    "engine_loop": engine_loop,
    "brake": brake,
    "horn": horn,
    "turn_signal_loop": turn_signal_loop,
    "celebration": celebration,
    "fault": fault_uy,
    "phone_ring": phone_ring,
    "phone_vibrate": phone_vibrate,
    "rain_loop": rain_loop,
    "lights_on": lights_on,
    "door_open": door_open,
    "bus_stop": bus_stop,
    "coin": coin,
}


def main(argv: list[str]) -> int:
    names = argv or list(SOUNDS)
    unknown = [n for n in names if n not in SOUNDS]
    if unknown:
        print("No existe:", ", ".join(unknown), "| opciones:", ", ".join(SOUNDS))
        return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name in names:
        x, loop, peak = SOUNDS[name]()
        path = write_wav(name, np.asarray(x, dtype=np.float64), loop, peak)
        print(f"{path.name:22s} {len(x) / SR:5.2f} s  {path.stat().st_size / 1024:6.1f} KB{'  (bucle)' if loop else ''}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
