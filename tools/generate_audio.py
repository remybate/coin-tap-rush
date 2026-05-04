"""Generate simple arcade-style WAV assets for Coin Tap Rush (run once; Godot imports them)."""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

SR = 44100


def pack_frame(samples: list[float]) -> bytes:
    out = bytearray()
    for s in samples:
        s = max(-1.0, min(1.0, s))
        out += struct.pack("<h", int(s * 32767))
    return bytes(out)


def env_linear(n: int, attack: int, release: int) -> list[float]:
    e = []
    for i in range(n):
        a = min(1.0, i / max(1, attack))
        r = min(1.0, (n - 1 - i) / max(1, release))
        e.append(a * r)
    return e


def sine_tone(freq: float, secs: float, vol: float = 0.22) -> list[float]:
    n = int(SR * secs)
    e = env_linear(n, int(SR * 0.005), int(SR * 0.04))
    return [vol * e[i] * math.sin(2 * math.pi * freq * i / SR) for i in range(n)]


def save_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = pack_frame(samples)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(raw)


def main() -> None:
    root = Path(__file__).resolve().parent.parent / "audio"

    # Coin tap — bright short ping
    s = sine_tone(988.0, 0.06, 0.28)
    s2 = sine_tone(1318.0, 0.04, 0.12)
    coin = s + [0.0] * int(SR * 0.01) + s2
    save_wav(root / "coin_tap.wav", coin)

    # Miss — low dull thud
    n = int(SR * 0.28)
    e = env_linear(n, int(SR * 0.002), int(SR * 0.12))
    miss = [0.18 * e[i] * math.sin(2 * math.pi * 140 * i / SR) for i in range(n)]
    miss = [m + 0.08 * e[i] * math.sin(2 * math.pi * 85 * i / SR) for i, m in enumerate(miss)]
    save_wav(root / "miss.wav", miss)

    # Game over — two descending notes
    go = sine_tone(440.0, 0.18, 0.2) + sine_tone(330.0, 0.22, 0.22) + sine_tone(247.0, 0.35, 0.18)
    save_wav(root / "game_over.wav", go)

    # UI click — tiny tick
    click = sine_tone(1400.0, 0.035, 0.15)
    save_wav(root / "button_click.wav", click)

    # Level up — quick rising triad
    lu = sine_tone(523.25, 0.1, 0.2) + sine_tone(659.25, 0.1, 0.2) + sine_tone(783.99, 0.16, 0.22)
    save_wav(root / "level_up.wav", lu)

    # Light arcade loop (~8s): soft bass + pentatonic arpeggio, quiet
    bpm = 112
    spb = 60.0 / bpm
    beats_total = 32
    n_total = int(SR * spb * beats_total)
    freqs = [261.63, 293.66, 329.63, 392.0, 440.0, 523.25]
    bass = [130.81, 146.83, 164.81, 196.0]

    music = [0.0] * n_total
    for i in range(n_total):
        t = i / SR
        beat = int(t / spb) % 8
        # bass on 1 and 5
        bf = bass[beat % 4]
        bass_s = 0.06 * math.sin(2 * math.pi * bf * t)
        # arpeggio step
        step = (i // int(SR * spb * 0.5)) % len(freqs)
        af = freqs[step]
        arp = 0.045 * math.sin(2 * math.pi * af * t)
        # soft pulse
        pulse = 0.5 + 0.5 * math.sin(2 * math.pi * (1.0 / (spb * 4)) * t)
        music[i] = (bass_s + arp) * (0.55 + 0.45 * pulse)

    # master envelope for loop seam (fade ends)
    fade = int(SR * 0.4)
    for i in range(fade):
        k = i / fade
        music[i] *= k
        music[-1 - i] *= k

    save_wav(root / "music_loop.wav", music)
    print("Wrote:", root)


if __name__ == "__main__":
    main()
