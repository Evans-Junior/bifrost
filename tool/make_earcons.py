"""Generates BIFROST's earcons (Section 13) into assets/sounds/.

Each sound is at most 300 ms and has its own pitch shape, so the sounds can
be told apart without words. Run: python3 tool/make_earcons.py
"""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def tone(freq, ms, volume=0.5, shape="sine"):
    n = int(RATE * ms / 1000)
    out = []
    for i in range(n):
        t = i / RATE
        phase = 2 * math.pi * freq * t
        if shape == "square":
            s = 1.0 if math.sin(phase) >= 0 else -1.0
            s = 0.6 * s + 0.4 * math.sin(phase)  # softened square
        else:
            s = math.sin(phase) + 0.15 * math.sin(2 * phase)
        # 8 ms attack and release so notes do not click.
        env = min(1.0, i / (RATE * 0.008), (n - i) / (RATE * 0.008))
        out.append(s * env * volume)
    return out


def silence(ms):
    return [0.0] * int(RATE * ms / 1000)


def click():
    n = int(RATE * 0.012)
    return [math.sin(2 * math.pi * 2400 * i / RATE) * (1 - i / n) * 0.6 for i in range(n)]


SOUNDS = {
    "listen": click(),                                             # short click
    "read": tone(660, 110) + tone(990, 150),                       # bright rising
    "think": tone(587, 200),                                       # single mid tone
    "cant_see": tone(440, 120) + tone(294, 170),                   # low falling
    "clarify": tone(740, 90) + silence(40) + tone(740, 90),        # two equal
    "watch_pulse": tone(523, 70, volume=0.15),                     # very soft
    "error": tone(150, 260, volume=0.45, shape="square"),          # low buzz
}


def write(name, samples):
    assert len(samples) <= RATE * 0.3 + 1, f"{name} longer than 300 ms"
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, samples in SOUNDS.items():
        write(name, samples)
        print(f"{name}.wav  {len(samples) * 1000 // RATE} ms")
