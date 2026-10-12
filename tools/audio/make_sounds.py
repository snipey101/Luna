"""Synthesise Luna's sound effects and music loop as 16-bit mono WAVs.

Pure standard library. Run: python3 tools/audio/make_sounds.py
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "audio"))
random.seed(7)


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = 0.9 / peak if peak > 0.9 else 1.0
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767))
                               for s in samples))
    print("wrote", path)


def env(i, n, attack=0.01, release=0.1):
    t = i / RATE
    dur = n / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (dur - t) / release) if release > 0 else 1.0
    return max(0.0, min(a, r))


def lowpass(samples, k):
    out, y = [], 0.0
    for s in samples:
        y += k * (s - y)
        out.append(y)
    return out


def bark():
    n = int(0.22 * RATE)
    out, ph = [], 0.0
    for i in range(n):
        t = i / n
        f = 620 - 330 * t + 120 * math.sin(t * math.pi)
        ph += 2 * math.pi * f / RATE
        tone = 0.6 * math.sin(ph) + 0.3 * math.sin(2 * ph) + 0.2 * (1 if math.sin(ph) > 0 else -1)
        noise = random.uniform(-1, 1) * 0.35 * (1 - t)
        out.append((tone + noise) * env(i, n, 0.008, 0.08) * (1 - 0.5 * t))
    return lowpass(out, 0.35)


def chime():
    notes = [1046.5, 1318.5, 1568.0, 2093.0]
    n = int(0.9 * RATE)
    out = [0.0] * n
    for k, f in enumerate(notes):
        start = int(k * 0.07 * RATE)
        for i in range(start, n):
            t = (i - start) / RATE
            out[i] += 0.35 * math.sin(2 * math.pi * f * t) * math.exp(-t * 5) \
                + 0.1 * math.sin(4 * math.pi * f * t) * math.exp(-t * 9)
    return out


def whimper():
    n = int(0.55 * RATE)
    out, ph = [], 0.0
    for i in range(n):
        t = i / n
        f = 950 - 420 * t + 25 * math.sin(i / RATE * 2 * math.pi * 11)
        ph += 2 * math.pi * f / RATE
        out.append(0.5 * math.sin(ph) * env(i, n, 0.04, 0.2))
    return lowpass(out, 0.5)


def step():
    n = int(0.06 * RATE)
    out = [random.uniform(-1, 1) * (1 - i / n) ** 3 for i in range(n)]
    return lowpass(out, 0.12)


def munch():
    """Three crunchy bites."""
    n = int(0.75 * RATE)
    out = [0.0] * n
    for k in range(3):
        start = int(k * 0.24 * RATE)
        m = int(0.09 * RATE)
        for i in range(m):
            out[start + i] += random.uniform(-1, 1) * (1 - i / m) ** 2 * 0.8
    return lowpass(out, 0.25)


def tinkle():
    """A light, cartoon trickle: quick random high blips."""
    n = int(1.0 * RATE)
    out = [0.0] * n
    t = 0
    while t < n - int(0.05 * RATE):
        f = random.uniform(1400, 2400)
        m = int(0.04 * RATE)
        for i in range(m):
            out[t + i] += 0.25 * math.sin(2 * math.pi * f * i / RATE) * (1 - i / m)
        t += int(random.uniform(0.02, 0.05) * RATE)
    return [s * env(i, n, 0.05, 0.3) for i, s in enumerate(out)]


def plop():
    n = int(0.3 * RATE)
    out, ph = [], 0.0
    for i in range(n):
        t = i / n
        f = 320 - 220 * t
        ph += 2 * math.pi * f / RATE
        out.append(0.7 * math.sin(ph) * (1 - t) ** 2)
    return out


def tone(freq, dur, kind="tri", vol=0.3, decay=3.0):
    n = int(dur * RATE)
    out = []
    for i in range(n):
        t = i / RATE
        p = (freq * t) % 1.0
        if kind == "tri":
            v = 4 * abs(p - 0.5) - 1
        else:
            v = math.sin(2 * math.pi * freq * t)
        out.append(v * vol * math.exp(-t * decay) * env(i, n, 0.005, 0.03))
    return out


def midi(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def mix_into(buf, src, start):
    for i, s in enumerate(src):
        if start + i < len(buf):
            buf[start + i] += s


def win():
    seq = [(72, 0.12), (76, 0.12), (79, 0.12), (84, 0.45), (79, 0.12), (84, 0.6)]
    out, pos = [0.0] * int(1.8 * RATE), 0
    for m, d in seq:
        mix_into(out, tone(midi(m), d + 0.25, "tri", 0.35, 2.5), pos)
        mix_into(out, tone(midi(m - 12), d + 0.25, "sine", 0.2, 2.5), pos)
        pos += int(d * RATE)
    return out


def music():
    """Gentle 16-bar loop in C major, ~100 bpm, I-vi-IV-V."""
    bpm = 100
    beat = 60 / bpm
    bars = 16
    total = int(bars * 4 * beat * RATE)
    out = [0.0] * total
    chords = [(60, 64, 67), (57, 60, 64), (53, 57, 60), (55, 59, 62)]
    pent = [72, 74, 76, 79, 81, 84]
    rnd = random.Random(3)
    melody_bars = []
    for b in range(4):  # 4-bar phrase repeated with variation
        notes = []
        for q in range(8):
            if rnd.random() < 0.75:
                notes.append(rnd.choice(pent))
            else:
                notes.append(None)
        melody_bars.append(notes)
    for bar in range(bars):
        chord = chords[bar % 4]
        start = int(bar * 4 * beat * RATE)
        # Bass on beats 1 and 3
        for b in (0, 2):
            mix_into(out, tone(midi(chord[0] - 12), beat * 1.6, "sine", 0.32, 1.6),
                     start + int(b * beat * RATE))
        # Soft chord plucks on the off-beats
        for b in (1, 3):
            for m in chord:
                mix_into(out, tone(midi(m), beat * 0.9, "sine", 0.07, 4.0),
                         start + int((b + 0.0) * beat * RATE))
        # Melody in eighths (rest for the last bar of each 8 to breathe)
        if bar % 8 != 7:
            phrase = melody_bars[bar % 4]
            for q, m in enumerate(phrase):
                if m is not None and (bar < 8 or q % 2 == 0 or m != phrase[0]):
                    mix_into(out, tone(midi(m), beat * 0.6, "tri", 0.12, 4.5),
                             start + int(q * beat / 2 * RATE))
    return out


write("bark.wav", bark())
write("chime.wav", chime())
write("whimper.wav", whimper())
write("step.wav", step())
write("win.wav", win())
write("music.wav", music())
write("munch.wav", munch())
write("tinkle.wav", tinkle())
write("plop.wav", plop())
