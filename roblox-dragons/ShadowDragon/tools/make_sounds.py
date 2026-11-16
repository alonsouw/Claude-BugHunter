"""Genera los sonidos del Dragón Sombrío por síntesis (sin muestras de terceros) en sounds/*.ogg.
Requiere numpy, scipy y ffmpeg. Uso: python tools/make_sounds.py
Después se suben a Roblox (Asset Manager › Import) y sus ids se pegan en SOUND_IDS del instalador.
"""
import os, subprocess, wave
import numpy as np
from scipy.signal import butter, sosfilt, fftconvolve

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'sounds')
rng = np.random.default_rng(13)


def bp(x, lo, hi, order=4):
    return sosfilt(butter(order, [lo, hi], 'bandpass', fs=SR, output='sos'), x)


def lp(x, f, order=4):
    return sosfilt(butter(order, f, 'lowpass', fs=SR, output='sos'), x)


def env(n, pts):
    """Envolvente por puntos [(t_rel, valor)] interpolada."""
    t = np.linspace(0, 1, n); a = np.array(pts)
    return np.interp(t, a[:, 0], a[:, 1])


def reverb(x, secs=1.8, wet=0.35):
    n = int(SR * secs); ir = rng.standard_normal(n) * np.exp(-np.linspace(0, 7, n)); ir = lp(ir, 3500)
    y = fftconvolve(x, ir)[:len(x) + n] / np.sqrt(n) * 6
    out = np.zeros(len(y)); out[:len(x)] += x * (1 - wet); out += y * wet
    return out


def save(name, x, loop=False):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.89
    if loop:  # fundido cruzado para que el bucle no haga clic
        k = int(0.05 * SR); x[:k] *= np.linspace(0, 1, k); x[-k:] *= np.linspace(1, 0, k)
    os.makedirs(OUT, exist_ok=True)
    wav = os.path.join(OUT, name + '.wav')
    with wave.open(wav, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((x * 32767).astype('<i2').tobytes())
    ogg = os.path.join(OUT, name + '.ogg')
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis', '-q:a', '5', ogg], check=True)
    os.remove(wav)
    print(name, round(len(x) / SR, 2), 's')


def breath_cycle(dur, growl=True):
    n = int(SR * dur); t = np.arange(n) / SR
    noise = rng.standard_normal(n)
    inhale = bp(noise, 300, 1800) * env(n, [(0, 0), (0.08, 0.35), (0.38, 0.55), (0.45, 0), (1, 0)])
    exhale = bp(noise, 120, 900) * env(n, [(0, 0), (0.5, 0), (0.56, 0.9), (0.8, 0.6), (0.97, 0), (1, 0)])
    rattle = (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 23 * t + 3 * np.sin(2 * np.pi * 0.7 * t)))) * bp(noise, 80, 400)
    x = inhale + exhale * (1 + 0.8 * rattle)
    if growl:
        f0 = 52 + 6 * np.sin(2 * np.pi * 0.31 * t) + rng.standard_normal(n).cumsum() * 0.002
        ph = 2 * np.pi * np.cumsum(f0) / SR
        g = np.tanh(3 * (np.sin(ph) + 0.5 * np.sin(2 * ph + 0.3) + 0.3 * np.sin(3 * ph)))
        x += 0.45 * lp(g, 300) * env(n, [(0, 0), (0.52, 0), (0.6, 1), (0.9, 0.7), (0.98, 0), (1, 0)])
    return x


def clicks(dur, times, freq=(900, 2600), decay=0.012):
    n = int(SR * dur); x = np.zeros(n)
    for tt in times:
        i = int(tt * SR); L = int(SR * decay * 6)
        if i + L >= n: continue
        f = rng.uniform(*freq); tt_ = np.arange(L) / SR
        x[i:i + L] += np.sin(2 * np.pi * f * tt_) * np.exp(-tt_ / decay) * rng.uniform(0.5, 1)
        x[i:i + 40] += rng.standard_normal(40) * 0.8
    return x


# respiración grave en bucle (dos ciclos de 3,4 s)
save('Breath', np.concatenate([breath_cycle(3.4), breath_cycle(3.6)]), loop=True)

# crujido de articulaciones: deslizamiento a tirones que acelera + chasquido final
ts = np.cumsum(np.geomspace(0.07, 0.012, 34)) + 0.05
x = clicks(1.2, list(ts) + [ts[-1] + 0.12], freq=(500, 1800), decay=0.008)
x += 0.4 * clicks(1.2, [ts[-1] + 0.12], freq=(120, 300), decay=0.03)
save('Creak', reverb(x, 0.6, 0.2))

# chillido del rugido: armónicos que suben y bajan, distorsión, temblor y un rugido grave debajo
n = int(SR * 3.0); t = np.arange(n) / SR
f = np.interp(t, [0, 0.35, 1.4, 2.4, 3.0], [260, 820, 760, 300, 220]) * (1 + 0.03 * np.sin(2 * np.pi * 7.5 * t))
ph = 2 * np.pi * np.cumsum(f) / SR
voice = sum(np.sin(k * ph + rng.uniform(0, 6)) / k ** 0.8 for k in range(1, 9))
voice = np.tanh(2.5 * voice) * env(n, [(0, 0), (0.06, 1), (0.75, 0.85), (1, 0)])
hiss = bp(rng.standard_normal(n), 2000, 7000) * env(n, [(0, 0), (0.08, 0.5), (0.8, 0.3), (1, 0)])
low = lp(np.tanh(4 * np.sin(2 * np.pi * np.cumsum(70 + 8 * np.sin(2 * np.pi * 0.9 * t)) / SR)), 260) * env(n, [(0, 0), (0.1, 0.9), (0.85, 0.6), (1, 0)])
save('Shriek', reverb(0.6 * voice + 0.35 * hiss + 0.6 * low, 2.2, 0.3))

# susurro lejano: ruido con formantes de voz y sílabas irregulares, sin palabras
n = int(SR * 2.8); t = np.arange(n) / SR; noise = rng.standard_normal(n)
syl = np.clip(np.sin(2 * np.pi * np.cumsum(5.5 + 2.5 * rng.standard_normal(n).cumsum() / n) / SR) , 0, 1) ** 2
form = bp(noise, 700, 1100) * 0.7 + bp(noise, 1800, 2600) + bp(noise, 3200, 5200) * 0.6
save('Whisper', reverb(form * syl * env(n, [(0, 0), (0.1, 1), (0.85, 0.8), (1, 0)]), 2.5, 0.55))

# respiración lejana: la misma respiración, apagada y con mucha reverberación
save('DistantBreath', reverb(lp(breath_cycle(3.5, growl=True), 700), 3.0, 0.65))

# rama que cruje: golpe seco + crepitar
x = clicks(1.6, [0.05] + list(0.05 + np.cumsum(rng.exponential(0.03, 22))), freq=(1500, 5000), decay=0.004)
x[int(0.05 * SR):int(0.05 * SR) + 300] += rng.standard_normal(300) * 3
save('Crack', reverb(x, 1.5, 0.4))
