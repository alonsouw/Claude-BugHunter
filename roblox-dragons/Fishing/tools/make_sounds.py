"""Sonidos de la pesca por síntesis (sin muestras de terceros) → sounds/*.ogg (numpy, scipy, ffmpeg).
  Cast  silbido de la caña · Plop  la boya en el agua · Reel  carraca del carrete · Catch  sale del agua
  Eat   bocados            · Sizzle  chisporroteo en la hoguera
"""
import os, subprocess, wave
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve
SR = 44100; rng = np.random.default_rng(23)
OUT = os.path.join(os.path.dirname(__file__), '..', 'sounds')
bp = lambda x, lo, hi: sosfilt(butter(4, [lo, hi], 'bandpass', fs=SR, output='sos'), x)
lp = lambda x, f: sosfilt(butter(4, f, 'lowpass', fs=SR, output='sos'), x)
hp = lambda x, f: sosfilt(butter(4, f, 'highpass', fs=SR, output='sos'), x)
env = lambda n, pts: np.interp(np.linspace(0, 1, n), [p[0] for p in pts], [p[1] for p in pts])
def reverb(x, secs=0.6, wet=0.15):
    n = int(SR * secs); ir = lp(rng.standard_normal(n) * np.exp(-np.linspace(0, 6, n)), 4000)
    y = fftconvolve(x, ir) / np.sqrt(n) * 6; out = np.zeros(len(y)); out[:len(x)] += x * (1 - wet); return out + y * wet
def save(name, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.89; os.makedirs(OUT, exist_ok=True); wav = os.path.join(OUT, name + '.wav')
    with wave.open(wav, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis', '-q:a', '5', os.path.join(OUT, name + '.ogg')], check=True)
    os.remove(wav); print(name, round(len(x) / SR, 2), 's')
def plop(n, f0=420, decay=0.06):   # gota que entra al agua: tono que sube rápido
    t = np.arange(n) / SR
    return np.sin(2 * np.pi * f0 * (1 + 2.5 * t / (decay * 4)) * t) * np.exp(-t / decay)

n = int(SR * 0.5); t = np.arange(n) / SR       # silbido: ruido filtrado que barre de grave a agudo
f = np.interp(t, [0, 0.5], [600, 3000]); x = np.zeros(n); noise = rng.standard_normal(n)
for k in range(0, n, 512):
    seg = slice(k, min(n, k + 512)); c = f[k]; x[seg] = bp(noise, c * 0.7, c * 1.3)[seg]
save('Cast', reverb(x * env(n, [(0, 0), (0.3, 1), (1, 0)]), 0.3, 0.1))
n = int(SR * 0.5)                               # plop de la boya
x = plop(n) + 0.25 * lp(rng.standard_normal(n), 2500) * np.exp(-np.arange(n) / SR / 0.04)
save('Plop', reverb(x, 0.5, 0.2))
n = int(SR * 0.22); x = np.zeros(n)             # carraca del carrete: clics metálicos seguidos
for i in range(7):
    s = int(i * 0.028 * SR); k = np.arange(n - s) / SR
    x[s:] += hp(rng.standard_normal(n - s), 2500) * np.exp(-k / 0.004) + 0.4 * np.sin(2 * np.pi * 3200 * k) * np.exp(-k / 0.006)
save('Reel', x)
n = int(SR * 1.2); tt = np.arange(n) / SR       # sale del agua: chapoteo + dos notas alegres
x = lp(rng.standard_normal(n), 4500) * env(n, [(0, 0), (0.02, 1), (0.3, 0.3), (1, 0)])
for i in range(6):
    s = rng.integers(0, n // 2); x[s:] += 0.5 * plop(n - s, rng.uniform(500, 900), 0.04)
for f0, s in [(784, 0.15), (1175, 0.32)]:
    i = int(s * SR); k = np.arange(n - i) / SR; x[i:] += 0.35 * (np.sin(2 * np.pi * f0 * k) + 0.3 * np.sin(4 * np.pi * f0 * k)) * np.exp(-k / 0.35)
save('Catch', reverb(x, 0.6, 0.15))
n = int(SR * 0.9); x = np.zeros(n)               # bocados: tres mordiscos húmedos
for s in [0.0, 0.3, 0.58]:
    i = int(s * SR); k = np.arange(n - i) / SR
    x[i:] += bp(rng.standard_normal(n - i), 300, 3000) * np.exp(-k / 0.05) * (1 + 0.8 * (np.sin(2 * np.pi * 40 * k) > 0))
    x[i:] += 0.4 * np.sin(2 * np.pi * 140 * k) * np.exp(-k / 0.04)
save('Eat', reverb(x, 0.3, 0.08))
n = int(SR * 2.4); tt = np.arange(n) / SR       # chisporroteo: crepitar + siseo
x = 0.4 * hp(rng.standard_normal(n), 3500) * env(n, [(0, 0), (0.1, 1), (0.85, 0.8), (1, 0)])
pops = (rng.random(n) < 0.0016) * rng.uniform(0.5, 1.5, n)
x += lp(np.convolve(pops, np.exp(-np.arange(200) / 30), 'same') * rng.standard_normal(n), 6000)
save('Sizzle', reverb(x, 0.4, 0.1))
