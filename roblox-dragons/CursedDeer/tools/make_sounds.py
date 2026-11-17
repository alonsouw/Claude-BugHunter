"""Sonidos del ciervo maldito por síntesis (sin muestras de terceros) → sounds/*.ogg (numpy, scipy, ffmpeg).
  Snort   resoplido de alarma del ciervo (aire por la nariz, dos golpes)
  Crack   la transformación: huesos que crujen y se estiran, carne que se desgarra
  Shriek  chillido de la criatura: un balido de ciervo que se deforma en un grito distorsionado
"""
import os, subprocess, wave
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve
SR = 44100; rng = np.random.default_rng(21)
OUT = os.path.join(os.path.dirname(__file__), '..', 'sounds')
bp = lambda x, lo, hi: sosfilt(butter(4, [lo, hi], 'bandpass', fs=SR, output='sos'), x)
lp = lambda x, f: sosfilt(butter(4, f, 'lowpass', fs=SR, output='sos'), x)
env = lambda n, pts: np.interp(np.linspace(0, 1, n), [p[0] for p in pts], [p[1] for p in pts])
def reverb(x, secs=1.2, wet=0.3):
    n = int(SR * secs); ir = lp(rng.standard_normal(n) * np.exp(-np.linspace(0, 7, n)), 4000)
    y = fftconvolve(x, ir) / np.sqrt(n) * 6; out = np.zeros(len(y)); out[:len(x)] += x * (1 - wet); return out + y * wet
def save(name, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.89; os.makedirs(OUT, exist_ok=True); wav = os.path.join(OUT, name + '.wav')
    with wave.open(wav, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis', '-q:a', '5', os.path.join(OUT, name + '.ogg')], check=True)
    os.remove(wav); print(name, round(len(x) / SR, 2), 's')

# resoplido: dos ráfagas de aire nasal
n = int(SR * 1.1); x = np.zeros(n)
for t0, L, a in ((0.05, 0.28, 1.0), (0.45, 0.4, 0.8)):
    i, m = int(t0 * SR), int(L * SR)
    x[i:i + m] += bp(rng.standard_normal(m), 250, 2600) * env(m, [(0, 0), (0.08, a), (0.4, a * 0.6), (1, 0)])
save('Snort', reverb(x, 0.8, 0.2))

# crujidos: serie de chasquidos de hueso que se aceleran, estiramiento húmedo y desgarro
n = int(SR * 3.2); x = np.zeros(n)
ts = np.cumsum(rng.exponential(0.09, 30)) + 0.05
for k, t0 in enumerate(ts[ts < 2.9]):
    i = int(t0 * SR); L = int(0.05 * SR)
    if i + L >= n: break
    tt = np.arange(L) / SR; f = rng.uniform(300, 1400)
    x[i:i + L] += (np.sin(2 * np.pi * f * tt) * np.exp(-tt / 0.006) + rng.standard_normal(L) * np.exp(-tt / 0.002)) * rng.uniform(0.5, 1)
    if k % 4 == 0:   # crujido grave, más grande
        x[i:i + L] += np.sin(2 * np.pi * rng.uniform(90, 160) * tt) * np.exp(-tt / 0.02) * 0.8
wet = bp(rng.standard_normal(n), 150, 900) * (0.5 + 0.5 * np.sin(2 * np.pi * 13 * np.arange(n) / SR)) * env(n, [(0, 0), (0.3, 0.25), (0.8, 0.35), (1, 0)])
save('Crack', reverb(x + wet, 1.0, 0.25))

# chillido: empieza como un balido y se rompe en un grito con armónicos distorsionados
n = int(SR * 2.6); t = np.arange(n) / SR
f = np.interp(t, [0, 0.25, 0.5, 1.4, 2.2, 2.6], [520, 560, 900, 1150, 700, 500]) * (1 + 0.025 * np.sin(2 * np.pi * 9 * t))
ph = 2 * np.pi * np.cumsum(f) / SR
voice = sum(np.sin(k * ph + rng.uniform(0, 6)) / k ** 0.7 for k in range(1, 10))
drive = np.interp(t, [0, 0.4, 0.7, 2.6], [1, 1.2, 6, 5])
voice = np.tanh(drive * voice) * env(n, [(0, 0), (0.05, 0.8), (0.2, 0.6), (0.3, 1), (0.85, 0.9), (1, 0)])
hiss = bp(rng.standard_normal(n), 2500, 8000) * env(n, [(0, 0), (0.25, 0.1), (0.35, 0.5), (0.9, 0.35), (1, 0)])
save('Shriek', reverb(0.7 * voice + 0.4 * hiss, 1.8, 0.3))
