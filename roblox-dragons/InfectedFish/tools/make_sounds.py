"""Sonidos del pez infectado por síntesis (sin muestras de terceros) → sounds/*.ogg (numpy, scipy, ffmpeg).
  Screech  chillido húmedo y burbujeante al descubrirte · Bite    chasquido de dientes y desgarro
  Splash   salida y caída al agua                        · Gurgle  burbujeo grave mientras nada
"""
import os, subprocess, wave
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve
SR = 44100; rng = np.random.default_rng(77)
OUT = os.path.join(os.path.dirname(__file__), '..', 'sounds')
bp = lambda x, lo, hi: sosfilt(butter(4, [lo, hi], 'bandpass', fs=SR, output='sos'), x)
lp = lambda x, f: sosfilt(butter(4, f, 'lowpass', fs=SR, output='sos'), x)
hp = lambda x, f: sosfilt(butter(4, f, 'highpass', fs=SR, output='sos'), x)
env = lambda n, pts: np.interp(np.linspace(0, 1, n), [p[0] for p in pts], [p[1] for p in pts])
def reverb(x, secs=1.0, wet=0.25, tone=3500):
    n = int(SR * secs); ir = lp(rng.standard_normal(n) * np.exp(-np.linspace(0, 6, n)), tone)
    y = fftconvolve(x, ir) / np.sqrt(n) * 6; out = np.zeros(len(y)); out[:len(x)] += x * (1 - wet); return out + y * wet
def save(name, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.89; os.makedirs(OUT, exist_ok=True); wav = os.path.join(OUT, name + '.wav')
    with wave.open(wav, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis', '-q:a', '5', os.path.join(OUT, name + '.ogg')], check=True)
    os.remove(wav); print(name, round(len(x) / SR, 2), 's')
def bubbles(n, count, fmin, fmax, decay=0.04):   # burbujas: senos cortos que suben de tono
    x = np.zeros(n); t = np.arange(int(SR * 0.12)) / SR
    for _ in range(count):
        s = rng.integers(0, max(1, n - len(t))); f0 = rng.uniform(fmin, fmax)
        b = np.sin(2 * np.pi * f0 * (1 + 3 * t) * t) * np.exp(-t / decay) * rng.uniform(0.3, 1)
        x[s:s + len(t)] += b
    return x

n = int(SR * 1.5); t = np.arange(n) / SR       # chillido: tono agudo que tiembla, rasgado, con burbujas y amortiguado (bajo el agua)
f = np.interp(t, [0, 0.1, 0.9, 1.5], [500, 1400, 1250, 700]) * (1 + 0.06 * np.sin(2 * np.pi * 23 * t))
ph = 2 * np.pi * np.cumsum(f) / SR
v = np.tanh(4 * sum(np.sin(k * ph) / k for k in range(1, 8)))
x = (bp(v, 600, 4000) + 0.3 * bp(rng.standard_normal(n), 1500, 6000)) * env(n, [(0, 0), (0.05, 1), (0.8, 0.8), (1, 0)])
x = lp(x, 3200) + 0.5 * bubbles(n, 40, 300, 900)
save('Screech', reverb(x, 1.2, 0.35, 2500))
n = int(SR * 0.45); tt = np.arange(n) / SR      # mordisco: dos chasquidos secos + desgarro húmedo
x = np.zeros(n)
for s, a in [(0.0, 1.0), (0.035, 0.7)]:
    i = int(s * SR); k = np.arange(n - i) / SR; x[i:] += a * hp(rng.standard_normal(n - i), 1500) * np.exp(-k / 0.008)
x += 0.6 * lp(rng.standard_normal(n), 2200) * env(n, [(0, 0), (0.12, 0), (0.25, 1), (1, 0)]) * (np.sin(2 * np.pi * 31 * tt) > 0)
x += 0.5 * np.sin(2 * np.pi * 120 * tt) * np.exp(-tt / 0.05)
save('Bite', reverb(x, 0.3, 0.12))
n = int(SR * 1.4); tt = np.arange(n) / SR       # chapuzón: golpe grave + ruido de espuma + gotas
x = np.sin(2 * np.pi * 70 * tt) * np.exp(-tt / 0.08) * 1.4
x += lp(rng.standard_normal(n), 5000) * env(n, [(0, 0), (0.02, 1), (0.25, 0.5), (1, 0)])
x += 0.6 * hp(bubbles(n, 60, 800, 2400, 0.02), 600) * env(n, [(0, 0), (0.15, 1), (1, 0)])
save('Splash', reverb(x, 0.8, 0.2))
n = int(SR * 2.0)                               # burbujeo grave
x = lp(bubbles(n, 28, 120, 380, 0.06), 1200) + 0.15 * lp(rng.standard_normal(n), 300) * env(n, [(0, 0), (0.2, 1), (0.8, 1), (1, 0)])
save('Gurgle', reverb(x, 1.0, 0.3, 1500))
