"""Membranas de las alas: malla fina de doble cara entre los dedos, con caída, borde rasgado en tiras y agujeros."""
import numpy as np


def patch(apex, A, B, rows, cols, scallop, billow, tatter, rng, u0, u1):
    apex, A, B = map(np.asarray, (apex, A, B))
    nrm = np.cross(A - apex, B - apex); nrm /= np.linalg.norm(nrm)
    if nrm[1] > 0: nrm = -nrm
    span = np.linalg.norm(A - B)
    edge = []
    ctrl = rng.random(6)                       # borde irregular de baja frecuencia
    notch = rng.integers(2, cols - 2) if tatter and rng.random() < 0.8 else -10   # un desgarro grande
    for c in range(cols + 1):
        u = c / cols; q = A + (B - A) * u
        s = scallop * np.sin(np.pi * u)
        if tatter:
            s += tatter * 0.12 * np.interp(u * 5, np.arange(6), ctrl) * np.sin(np.pi * u) ** 0.4
            if abs(c - notch) <= 1: s += tatter * (0.55 if c == notch else 0.3)
        edge.append(q + (apex - q) * min(0.85, s))
    V, UV = [], []
    for r in range(rows + 1):
        rr = r / rows
        for c in range(cols + 1):
            u = c / cols
            q = apex + (edge[c] - apex) * rr + nrm * billow * span * 0.07 * np.sin(np.pi * rr) * np.sin(np.pi * u)
            V.append(q); UV.append((u0 + (u1 - u0) * u, rr))
    F = []
    for r in range(rows):
        for c in range(cols):
            if tatter and rr_hole(r, c, rows, cols, tatter, rng): continue
            a = r * (cols + 1) + c; b = a + cols + 1
            F += [(a, b, a + 1), (b, b + 1, a + 1)]
    return np.array(V), np.array(F), np.array(UV)


def rr_hole(r, c, rows, cols, tatter, rng):
    # desgarros: agujeros alargados cerca del borde y alguno suelto en el interior
    if r >= rows - 1 and rng.random() < tatter * 0.05: return True
    if 0.55 < r / rows < 0.9 and rng.random() < tatter * 0.025: return True
    return False


def wing_membrane(w, rng, rows=14, cols=22, tatter=0.45):
    W = np.array(w['wrist']); chain = [np.array(t) for t in w['tips']] + [np.array(w['rear'])]
    Vs, Fs, UVs, off = [], [], [], 0
    n = len(chain)
    for i in range(n - 1):
        last = i == n - 2
        v, f, uv = patch(W, chain[i], chain[i + 1], rows, cols, 0.15 if last else 0.08, 0.55, tatter * (0.6 if last else 1), rng, i / n, (i + 1) / n)
        Vs.append(v); Fs.append(f + off); UVs.append(uv); off += len(v)
    # unión al cuerpo (muñeca → borde trasero → hombro) y propatagio (hombro → codo → muñeca)
    for apex, A, B, u0 in [(W, np.array(w['rear']), np.array(w['shoulder']), 0.9), (np.array(w['elbow']), np.array(w['shoulder']), W, 0.0)]:
        v, f, uv = patch(apex, A, B, 8, 10, 0.06, 0.3, 0, rng, u0, u0 + 0.1)
        Vs.append(v); Fs.append(f + off); UVs.append(uv); off += len(v)
    V = np.concatenate(Vs); F = np.concatenate(Fs); UV = np.concatenate(UVs)
    return V, F, UV
