#!/usr/bin/env python3
"""Render the per-tank cue samples (stdlib only).

Writes cue_{agitate,tick,pip,dump}_t{1,2,3}.wav to assets/sounds/ and
mirrors them to android/app/src/main/res/raw/. The iOS .caf copies are
made by afconvert in CI (ios-testflight.yml).
"""
import math
import os
import shutil
import struct
import wave

RATE = 44100
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "assets", "sounds")
RAW = os.path.join(ROOT, "android", "app", "src", "main", "res", "raw")
BASE = {1: 440.0, 2: 587.0, 3: 784.0}


def tone(freq, ms, gain=0.6):
    n = int(RATE * ms / 1000)
    fade = max(1, int(RATE * 0.005))
    out = []
    for i in range(n):
        env = min(1.0, i / fade, (n - i) / fade)
        out.append(gain * env * math.sin(2 * math.pi * freq * i / RATE))
    return out


def click(freq, ms=30):
    n = int(RATE * ms / 1000)
    return [0.7 * math.exp(-6.0 * i / n) * math.sin(2 * math.pi * freq * i / RATE)
            for i in range(n)]


def write(name, samples):
    for d in (OUT, RAW):
        os.makedirs(d, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))
    shutil.copyfile(path, os.path.join(RAW, name + ".wav"))


for slot, f in BASE.items():
    write(f"cue_agitate_t{slot}", tone(f, 125) + tone(f * 1.5, 125))
    write(f"cue_tick_t{slot}", click(f * 2))
    write(f"cue_pip_t{slot}", tone(f * 2, 80))
    write(f"cue_dump_t{slot}", tone(f, 200) + tone(f * 1.25, 200) + tone(f * 1.5, 200))
