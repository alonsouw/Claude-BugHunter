"""Sonidos de los infectados por síntesis (sin muestras de terceros) → sounds/*.ogg (numpy, scipy, ffmpeg).
  Groan   gemido ronco al deambular   · Scream  grito del gritón (se oye lejos) · Hit  golpe que acierta
  Pop     el hinchado revienta        · Roar    el bruto al golpear el suelo
"""
import os, subprocess, wave
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve
SR = 44100; rng = np.random.default_rng(41)
OUT = os.path.join(os.path.dirname(__file__), '..', 'sounds')
bp = lambda x, lo, hi: sosfilt(butter(4, [lo, hi], 'bandpass', fs=SR, output='sos'), x)
lp = lambda x, f: sosfilt(butter(4, f, 'lowpass', fs=SR, output='sos'), x)
env = lambda n, pts: np.interp(np.linspace(0, 1, n), [p[0] for p in pts], [p[1] for p in pts])
def reverb(x, secs=1.0, wet=0.25):
    n = int(SR * secs); ir = lp(rng.standard_normal(n) * np.exp(-np.linspace(0, 6, n)), 3500)
    y = fftconvolve(x, ir) / np.sqrt(n) * 6; out = np.zeros(len(y)); out[:len(x)] += x * (1 - wet); return out + y * wet
def save(name, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.89; os.makedirs(OUT, exist_ok=True); wav = os.path.join(OUT, name + '.wav')
    with wave.open(wav, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis', '-q:a', '5', os.path.join(OUT, name + '.ogg')], check=True)
    os.remove(wav); print(name, round(len(x) / SR, 2), 's')
def voice(f, n, harm=10):
    ph = 2 * np.pi * np.cumsum(f) / SR
    return sum(np.sin(k * ph + rng.uniform(0, 6)) / k ** 0.9 for k in range(1, harm))
def formant(x, centers):
    return sum(bp(x, c * 0.8, c * 1.2) * g for c, g in centers)

n = int(SR * 2.2); t = np.arange(n) / SR      # gemido: "uuuaaargh" ronco con temblor
f = np.interp(t, [0, 0.6, 1.6, 2.2], [110, 140, 120, 90]) * (1 + 0.04 * np.sin(2 * np.pi * 6 * t)) + rng.standard_normal(n).cumsum() * 0.002
v = np.tanh(2.5 * voice(f, n, 14)) * (1 + 0.6 * (np.sin(2 * np.pi * 27 * t) > 0.2))
x = formant(v, [(500, 1.0), (900, 0.7), (2400, 0.25)]) * env(n, [(0, 0), (0.15, 1), (0.8, 0.8), (1, 0)])
save('Groan', reverb(x, 0.8, 0.2))
n = int(SR * 2.4); t = np.arange(n) / SR      # grito agudo, rasgado
f = np.interp(t, [0, 0.15, 1.2, 2.0, 2.4], [400, 950, 1050, 880, 600]) * (1 + 0.03 * np.sin(2 * np.pi * 9 * t))
v = np.tanh(5 * voice(f, n, 9))
x = formant(v, [(800, 0.8), (1500, 1.0), (3000, 0.7)]) + 0.35 * bp(rng.standard_normal(n), 2500, 8000)
save('Scream', reverb(x * env(n, [(0, 0), (0.04, 1), (0.85, 0.9), (1, 0)]), 1.8, 0.35))
n = int(SR * 0.4); tt = np.arange(n) / SR     # golpe: impacto sordo + crujido
x = np.sin(2 * np.pi * 90 * tt) * np.exp(-tt / 0.05) + 0.6 * lp(rng.standard_normal(n), 2500) * np.exp(-tt / 0.03)
save('Hit', reverb(x, 0.3, 0.1))
n = int(SR * 1.3); tt = np.arange(n) / SR     # reventón húmedo
x = lp(rng.standard_normal(n), 1800) * np.exp(-tt / 0.18) + np.sin(2 * np.pi * 60 * tt) * np.exp(-tt / 0.12) * 1.5
x += 0.4 * bp(rng.standard_normal(n), 200, 900) * (np.sin(2 * np.pi * 14 * tt) > 0.4) * np.exp(-tt / 0.5)
save('Pop', reverb(x, 0.8, 0.25))
n = int(SR * 1.6); t = np.arange(n) / SR      # rugido del bruto
f = np.interp(t, [0, 0.3, 1.2, 1.6], [70, 95, 85, 60])
x = lp(np.tanh(5 * voice(f, n, 18)), 1200) * env(n, [(0, 0), (0.1, 1), (0.8, 0.8), (1, 0)]) + 0.3 * bp(rng.standard_normal(n), 150, 1500) * env(n, [(0, 0), (0.1, 1), (1, 0)])
save('Roar', reverb(x, 1.0, 0.25))
