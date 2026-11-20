"""Sonidos de los lobos huecos por síntesis (sin muestras de terceros) → sounds/*.ogg (numpy, scipy, ffmpeg).
  Howl   aullido largo y quebrado (el alfa al descubrir a un jugador; se oye lejos)
  Growl  gruñido grave y ronco
  Snarl  ladrido-rugido corto al lanzarse
  Bite   chasquido de dientes
  Yelp   gañido de dolor
"""
import os, subprocess, wave
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve
SR = 44100; rng = np.random.default_rng(31)
OUT = os.path.join(os.path.dirname(__file__), '..', 'sounds')
bp = lambda x, lo, hi: sosfilt(butter(4, [lo, hi], 'bandpass', fs=SR, output='sos'), x)
lp = lambda x, f: sosfilt(butter(4, f, 'lowpass', fs=SR, output='sos'), x)
env = lambda n, pts: np.interp(np.linspace(0, 1, n), [p[0] for p in pts], [p[1] for p in pts])
def reverb(x, secs=1.5, wet=0.3):
    n = int(SR * secs); ir = lp(rng.standard_normal(n) * np.exp(-np.linspace(0, 6, n)), 3500)
    y = fftconvolve(x, ir) / np.sqrt(n) * 6; out = np.zeros(len(y)); out[:len(x)] += x * (1 - wet); return out + y * wet
def save(name, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.89; os.makedirs(OUT, exist_ok=True); wav = os.path.join(OUT, name + '.wav')
    with wave.open(wav, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis', '-q:a', '5', os.path.join(OUT, name + '.ogg')], check=True)
    os.remove(wav); print(name, round(len(x) / SR, 2), 's')
def voice(f, n, harm=8, rough=0.0):
    ph = 2 * np.pi * np.cumsum(f) / SR
    v = sum(np.sin(k * ph + rng.uniform(0, 6)) / k ** 1.1 for k in range(1, harm))
    if rough: v *= 1 + rough * (np.sin(2 * np.pi * 31 * np.arange(n) / SR) > 0.3)
    return v

n = int(SR * 4.2); t = np.arange(n) / SR      # aullido que sube, sostiene y se quiebra al final
f = np.interp(t, [0, 0.5, 1.2, 2.6, 3.2, 3.5, 4.2], [300, 560, 610, 590, 640, 420, 330]) * (1 + 0.012 * np.sin(2 * np.pi * 5.5 * t))
f[int(3.2 * SR):int(3.35 * SR)] *= 1.25       # quiebro de la voz
x = voice(f, n, 6) * env(n, [(0, 0), (0.12, 0.8), (0.75, 1), (0.95, 0.6), (1, 0)]) + 0.08 * bp(rng.standard_normal(n), 1500, 5000) * env(n, [(0, 0), (0.1, 1), (1, 0)])
save('Howl', reverb(x, 3.0, 0.5))
n = int(SR * 1.8); t = np.arange(n) / SR      # gruñido
f = 75 + 10 * np.sin(2 * np.pi * 0.8 * t) + rng.standard_normal(n).cumsum() * 0.004
x = np.tanh(3 * voice(f, n, 14, rough=0.8)) * env(n, [(0, 0), (0.15, 1), (0.8, 0.9), (1, 0)])
x = lp(x, 900) + 0.25 * bp(rng.standard_normal(n), 200, 1200) * env(n, [(0, 0), (0.2, 1), (1, 0)])
save('Growl', reverb(x, 0.6, 0.15))
n = int(SR * 0.6); t = np.arange(n) / SR      # rugido corto al lanzarse
f = np.interp(t, [0, 0.1, 0.6], [180, 330, 160])
x = np.tanh(4 * voice(f, n, 12, rough=0.6)) * env(n, [(0, 0), (0.05, 1), (0.6, 0.5), (1, 0)]) + 0.5 * bp(rng.standard_normal(n), 800, 4000) * env(n, [(0, 0), (0.05, 1), (0.5, 0.2), (1, 0)])
save('Snarl', reverb(x, 0.5, 0.15))
n = int(SR * 0.35); x = np.zeros(n)           # chasquido de dientes (dos golpes)
for t0 in (0.01, 0.06):
    i = int(t0 * SR); L = int(0.04 * SR); tt = np.arange(L) / SR
    x[i:i + L] += (np.sin(2 * np.pi * 2400 * tt) * 0.5 + rng.standard_normal(L)) * np.exp(-tt / 0.004)
save('Bite', reverb(x, 0.3, 0.1))
n = int(SR * 0.7); t = np.arange(n) / SR      # gañido
f = np.interp(t, [0, 0.08, 0.7], [900, 1300, 700])
x = voice(f, n, 6) * env(n, [(0, 0), (0.05, 1), (0.4, 0.6), (1, 0)])
save('Yelp', reverb(x, 0.6, 0.2))
