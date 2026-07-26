import math
import random
import struct
import wave
from pathlib import Path

RATE = 32000
TAU = math.tau
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def midi(note):
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def add(buf, start, duration, voice, gain=1.0, wrap=True):
    count = int(duration * RATE)
    base = int(start * RATE)
    size = len(buf)
    for i in range(count):
        target = base + i
        if wrap:
            target %= size
        elif target >= size:
            break
        buf[target] += voice(i / RATE, duration) * gain


def pluck(freq):
    def voice(t, _):
        env = math.exp(-5.2 * t)
        shimmer = 0.12 * math.sin(TAU * 5.2 * t)
        return env * (
            math.sin(TAU * freq * t + shimmer)
            + 0.34 * math.sin(TAU * freq * 2.01 * t)
            + 0.13 * math.sin(TAU * freq * 3.98 * t)
        )

    return voice


def keys(freq):
    def voice(t, duration):
        attack = min(1.0, t / 0.018)
        release = min(1.0, (duration - t) / 0.12)
        env = attack * max(0.0, release) * math.exp(-1.45 * t)
        return env * (
            math.sin(TAU * freq * t)
            + 0.23 * math.sin(TAU * freq * 2 * t)
            + 0.08 * math.sin(TAU * freq * 4 * t)
        )

    return voice


def bass(freq):
    def voice(t, duration):
        env = min(1.0, t / 0.012) * min(1.0, max(0.0, duration - t) / 0.06)
        return env * (
            math.sin(TAU * freq * t)
            + 0.32 * math.sin(TAU * freq * 2 * t)
            + 0.12 * math.sin(TAU * freq * 3 * t)
        )

    return voice


def brass(freq):
    def voice(t, duration):
        attack = min(1.0, t / 0.025)
        release = min(1.0, max(0.0, duration - t) / 0.09)
        env = attack * release * math.exp(-0.8 * t)
        vibrato = 0.003 * math.sin(TAU * 6.2 * t)
        phase = TAU * freq * t * (1 + vibrato)
        return env * (
            math.sin(phase)
            + 0.38 * math.sin(phase * 2)
            + 0.19 * math.sin(phase * 3)
            + 0.08 * math.sin(phase * 4)
        )

    return voice


def pad(freq):
    def voice(t, duration):
        env = min(1.0, t / 0.12) * min(1.0, max(0.0, duration - t) / 0.2)
        wobble = 0.9 + 0.1 * math.sin(TAU * 0.7 * t)
        return env * wobble * (
            math.sin(TAU * freq * t)
            + 0.18 * math.sin(TAU * freq * 2 * t)
            + 0.08 * math.sin(TAU * freq * 3 * t)
        )

    return voice


def compose_opening(path):
    bpm = 150
    beat = 60.0 / bpm
    bar = beat * 4
    bars = 4
    buf = [0.0] * int(bars * bar * RATE)
    progression = [
        (60, (60, 64, 67)),
        (65, (65, 69, 72)),
        (67, (67, 71, 74)),
        (60, (60, 64, 67)),
    ]
    fanfare = [
        (72, 76, 79, 84, 79, 76, 81, 84),
        (77, 81, 84, 89, 84, 81, 79, 77),
        (79, 83, 86, 91, 86, 83, 81, 79),
        (84, 83, 81, 79, 76, 79, 84, 88),
    ]

    for bar_index, (root, chord) in enumerate(progression):
        start = bar_index * bar
        for note in chord:
            add(buf, start, bar * 1.02, pad(midi(note)), 0.09)
        for beat_index in range(4):
            step = start + beat_index * beat
            add(buf, step, beat * 0.72, bass(midi(root - 12)), 0.28)
            add(buf, step, 0.22, kick, 0.62)
            if beat_index in (1, 3):
                add(
                    buf,
                    step,
                    0.19,
                    noise_voice(21000 + bar_index * 9 + beat_index, 20, 0.4),
                    0.21,
                )
        for eighth, note in enumerate(fanfare[bar_index]):
            step = start + eighth * beat / 2
            add(buf, step, beat * 0.48, brass(midi(note)), 0.23)
            add(buf, step, beat * 0.36, pluck(midi(note + 12)), 0.12)
            add(
                buf,
                step,
                0.06,
                noise_voice(24000 + bar_index * 13 + eighth, 55),
                0.065,
            )
        if bar_index == bars - 1:
            for sixteenth in range(8):
                step = start + (2.0 + sixteenth * 0.25) * beat
                add(buf, step, 0.16, kick, 0.24 + sixteenth * 0.025)
                add(
                    buf,
                    step,
                    0.12,
                    noise_voice(26000 + sixteenth, 26, 0.18),
                    0.08 + sixteenth * 0.008,
                )

    write_wav(path, buf)


def kick(t, duration):
    env = math.exp(-18 * t)
    phase = TAU * (48 * t + 62 * (1 - math.exp(-24 * t)) / 24)
    click = math.exp(-80 * t) * math.sin(TAU * 1400 * t)
    return env * math.sin(phase) + 0.16 * click


def noise_voice(seed, decay, body=0.0):
    rng = random.Random(seed)
    previous = 0.0

    def voice(t, _):
        nonlocal previous
        sample = rng.uniform(-1.0, 1.0)
        bright = sample - previous * 0.72
        previous = sample
        return math.exp(-decay * t) * (
            bright + body * math.sin(TAU * 185 * t)
        )

    return voice


def compose(path, bpm, bars, progression, melody, extra_sparkle=False):
    beat = 60.0 / bpm
    bar = beat * 4
    duration = bars * bar
    buf = [0.0] * int(duration * RATE)

    for bar_index in range(bars):
        root, chord = progression[bar_index % len(progression)]
        start = bar_index * bar

        for note in chord:
            add(buf, start, bar * 1.02, pad(midi(note)), 0.075)

        for beat_index in range(4):
            step = start + beat_index * beat
            add(buf, step, beat * 0.82, bass(midi(root - 12)), 0.25)
            add(buf, step, 0.24, kick, 0.55)
            if beat_index in (1, 3):
                add(
                    buf,
                    step,
                    0.22,
                    noise_voice(4000 + bar_index * 11 + beat_index, 18, 0.35),
                    0.17,
                )

        for eighth in range(8):
            step = start + eighth * beat / 2
            hat_gain = 0.07 if eighth % 2 == 0 else 0.045
            add(
                buf,
                step,
                0.075,
                noise_voice(9000 + bar_index * 17 + eighth, 48),
                hat_gain,
            )
            arp_note = chord[(eighth + bar_index) % len(chord)] + 12
            add(buf, step, beat * 0.42, keys(midi(arp_note)), 0.12)

        notes = melody[bar_index % len(melody)]
        for eighth, note in enumerate(notes):
            if note is None:
                continue
            step = start + eighth * beat / 2
            length = beat * (0.72 if eighth % 4 else 1.05)
            add(buf, step, length, pluck(midi(note)), 0.24)

        if extra_sparkle and bar_index % 2 == 1:
            add(buf, start + 3.5 * beat, beat, pluck(midi(chord[-1] + 24)), 0.1)

    write_wav(path, buf)


def compose_victory(path):
    duration = 3.4
    buf = [0.0] * int(duration * RATE)
    beat = 0.28
    fanfare = [67, 72, 76, 79, 84]
    for i, note in enumerate(fanfare):
        start = i * beat
        add(buf, start, 0.75, pluck(midi(note)), 0.35, wrap=False)
        add(buf, start, 0.7, keys(midi(note - 12)), 0.18, wrap=False)
        add(buf, start, 0.2, kick, 0.38, wrap=False)
    for note in (72, 76, 79, 84):
        add(buf, 1.45, 1.75, pad(midi(note)), 0.14, wrap=False)
    for i in range(12):
        add(
            buf,
            1.35 + i * 0.11,
            0.1,
            noise_voice(12000 + i, 38),
            0.075,
            wrap=False,
        )
    write_wav(path, buf, fade_out=0.35)


def write_wav(path, buf, fade_out=0.0):
    if fade_out:
        fade_samples = int(fade_out * RATE)
        for i in range(fade_samples):
            buf[-fade_samples + i] *= 1 - i / fade_samples
    peak = max(abs(value) for value in buf) or 1.0
    scale = 0.91 / peak
    pcm = bytearray()
    for value in buf:
        softened = math.tanh(value * scale * 1.18) / math.tanh(1.18)
        pcm.extend(struct.pack("<h", int(max(-1, min(1, softened)) * 32767)))
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm)


compose_opening(OUT / "opening_theme.wav")

compose(
    OUT / "gameplay_theme.wav",
    bpm=126,
    bars=12,
    progression=[
        (62, (62, 66, 69)),
        (57, (61, 64, 69)),
        (59, (59, 62, 66)),
        (55, (59, 62, 67)),
    ],
    melody=[
        (74, None, 78, 81, 78, 76, 74, 69),
        (73, 76, 81, None, 78, 76, 73, 69),
        (71, 74, 78, 83, 81, 78, 74, 71),
        (71, 74, 79, 78, 74, 71, 69, None),
    ],
    extra_sparkle=True,
)

compose_victory(OUT / "victory_jingle.wav")
