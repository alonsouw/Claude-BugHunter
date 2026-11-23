"""Sonidos de la cura por síntesis (sin muestras de terceros) → sounds/*.ogg (numpy, scipy, ffmpeg).
  Pickup  destello al aparecer un ingrediente · Harvest  coger una flor / desenterrar · Add  cae al caldero
  Brew    burbujeo del caldero (en bucle)      · Ready    el remedio está listo        · Dawn  amanecer final
"""
import os, subprocess, wave
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve
SR = 44100; rng = np.random.default_rng(91)
OUT = os.path.join(os.path.dirname(__file__), '..', 'sounds')
bp = lambda x, lo, hi: sosfilt(butter(4, [lo, hi], 'bandpass', fs=SR, output='sos'), x)
lp = lambda x, f: sosfilt(butter(4, f, 'lowpass', fs=SR, output='sos'), x)
env = lambda n, pts: np.interp(np.linspace(0, 1, n), [p[0] for p in pts], [p[1] for p in pts])
def reverb(x, secs=1.0, wet=0.25):
    n = int(SR * secs); ir = lp(rng.standard_normal(n) * np.exp(-np.linspace(0, 6, n)), 5000)
    y = fftconvolve(x, ir) / np.sqrt(n) * 6; out = np.zeros(len(y)); out[:len(x)] += x * (1 - wet); return out + y * wet
def save(name, x, tail=True):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.89; os.makedirs(OUT, exist_ok=True); wav = os.path.join(OUT, name + '.wav')
    with wave.open(wav, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis', '-q:a', '5', os.path.join(OUT, name + '.ogg')], check=True)
    os.remove(wav); print(name, round(len(x) / SR, 2), 's')
def bell(f, n, decay):
    t = np.arange(n) / SR
    return sum(a * np.sin(2 * np.pi * f * r * t) * np.exp(-t / (decay * d)) for r, a, d in [(1, 1, 1), (2.76, 0.4, 0.5), (5.4, 0.2, 0.3)])
def bubbles(n, count, fmin, fmax, decay=0.05):
    x = np.zeros(n); t = np.arange(int(SR * 0.12)) / SR
    for _ in range(count):
        s = rng.integers(0, max(1, n - len(t))); f0 = rng.uniform(fmin, fmax)
        x[s:s + len(t)] += np.sin(2 * np.pi * f0 * (1 + 3 * t) * t) * np.exp(-t / decay) * rng.uniform(0.3, 1)
    return x

n = int(SR * 1.4); x = np.zeros(n)              # destello: arpegio de campanitas
for i, f in enumerate([880, 1109, 1319, 1760]):
    s = int(i * 0.07 * SR); x[s:] += bell(f, n - s, 0.35) * 0.6
save('Pickup', reverb(x, 1.0, 0.3))
n = int(SR * 0.8); t = np.arange(n) / SR        # coger / desenterrar: crujido de hojas y tierra
x = bp(rng.standard_normal(n), 800, 5000) * env(n, [(0, 0), (0.05, 1), (0.3, 0.5), (0.5, 0.9), (1, 0)]) * (0.6 + 0.4 * (np.sin(2 * np.pi * 18 * t) > 0))
x += 0.5 * lp(rng.standard_normal(n), 400) * env(n, [(0, 0), (0.5, 0), (0.6, 1), (1, 0)])
save('Harvest', reverb(x, 0.4, 0.1))
n = int(SR * 1.2); t = np.arange(n) / SR        # cae al caldero: chof espeso + burbujas + campanita
x = lp(rng.standard_normal(n), 1500) * np.exp(-t / 0.12) + 0.8 * bubbles(n, 14, 150, 500) + 0.3 * bell(660, n, 0.4)
save('Add', reverb(x, 0.8, 0.25))
n = int(SR * 4.0); t = np.arange(n) / SR        # burbujeo en bucle (sin principio ni final marcados)
x = lp(bubbles(n, 70, 100, 420, 0.07), 1500) + 0.25 * lp(rng.standard_normal(n), 200)
fade = int(0.2 * SR); x[:fade] *= np.linspace(0, 1, fade); x[-fade:] *= np.linspace(1, 0, fade)
save('Brew', x)
n = int(SR * 2.5); x = np.zeros(n)              # listo: acorde de campanas que sube
for i, f in enumerate([523, 659, 784, 1047]):
    s = int(i * 0.12 * SR); x[s:] += bell(f, n - s, 0.9) * 0.6
save('Ready', reverb(x, 1.6, 0.35))
n = int(SR * 8.0); t = np.arange(n) / SR        # amanecer: coro sintético que crece (acorde mayor con vocales)
chord = [196, 247, 294, 392, 494, 587]
x = np.zeros(n)
for f in chord:
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5 * t + rng.uniform(0, 6))
    ph = 2 * np.pi * np.cumsum(f * vib) / SR
    v = sum(np.sin(k * ph) / k ** 1.2 for k in range(1, 10))
    x += sum(bp(v, c * 0.85, c * 1.15) * g for c, g in [(700, 1), (1150, 0.6), (2600, 0.2)])
x *= env(n, [(0, 0), (0.35, 0.9), (0.75, 1), (1, 0)])
x += 0.3 * sum(bell(f * 2, n, 2.5) for f in chord[:3]) * env(n, [(0, 0), (0.3, 0), (0.32, 1), (1, 1)])
save('Dawn', reverb(x, 2.5, 0.45))
