"""Escultura por campos de distancia (SDF) con numpy.

Cada forma (elipsoide, cono redondeado, caja) se funde con las demás mediante uniones
suaves, como en un programa de escultura: el resultado es una sola piel continua, no
piezas pegadas. Además de la distancia se guardan, por vóxel, el material (piel, hueso,
carne, dientes…) y la parte del cuerpo (cabeza, mandíbula, cuello…), que luego sirven
para el color horneado y para el skinning de los huesos.

Espacio: el de Roblox (Y arriba, el dragón mira hacia -Z), en studs.
"""
import numpy as np

MATERIALS = {  # id: (nombre, color sRGB, rugosidad, escamas 0-1)
    0: ('skin', (0.12, 0.112, 0.112), 0.6, 1.0),
    1: ('horn', (0.13, 0.115, 0.105), 0.48, 0.15),
    2: ('flesh', (0.26, 0.045, 0.06), 0.28, 0.0),
    3: ('gum', (0.22, 0.05, 0.06), 0.25, 0.0),
    4: ('teeth', (0.62, 0.56, 0.47), 0.32, 0.0),
    5: ('tongue', (0.42, 0.24, 0.25), 0.25, 0.0),
    6: ('drool', (0.5, 0.42, 0.42), 0.05, 0.0),
    7: ('socket', (0.012, 0.010, 0.010), 0.9, 0.0),
    8: ('claw', (0.05, 0.042, 0.040), 0.35, 0.0),
    9: ('wound', (0.24, 0.04, 0.05), 0.3, 0.0),
    10: ('bone', (0.46, 0.38, 0.32), 0.45, 0.0),
    11: ('belly', (0.11, 0.095, 0.095), 0.6, 0.6),
    12: ('membrane', (0.13, 0.032, 0.038), 0.55, 0.0),
    13: ('blood', (0.34, 0.012, 0.02), 0.08, 0.0),
    14: ('muscle', (0.45, 0.07, 0.08), 0.28, 0.0),
    15: ('wood', (0.2, 0.14, 0.09), 0.75, 0.0),
    16: ('rot', (0.11, 0.105, 0.055), 0.35, 0.3),
    17: ('pus', (0.33, 0.31, 0.19), 0.2, 0.0),
    18: ('shadow', (0.068, 0.062, 0.07), 0.74, 0.85),        # v2: algo más claro para que la visión nocturna saque relieve
    19: ('rag', (0.05, 0.043, 0.042), 0.85, 0.2),
    20: ('lip', (0.42, 0.09, 0.1), 0.3, 0.0),
    21: ('needle', (0.86, 0.84, 0.8), 0.25, 0.0),
    22: ('vein', (0.13, 0.035, 0.06), 0.45, 0.0),            # venas moradas bajo la piel
    23: ('nodule', (0.1, 0.088, 0.094), 0.55, 0.3),          # bultos y excrecencias
    24: ('scar', (0.17, 0.13, 0.14), 0.5, 0.0),              # cicatrices claras
    25: ('fold', (0.05, 0.045, 0.05), 0.8, 0.5),             # pliegues de piel
    # --- ciervo ---
    26: ('fur', (0.42, 0.27, 0.16), 0.85, 0.0),              # pelaje pardo
    27: ('furdark', (0.26, 0.17, 0.11), 0.85, 0.0),          # lomo y frente más oscuros
    28: ('cream', (0.8, 0.72, 0.6), 0.85, 0.0),              # vientre, cara interna de las patas
    29: ('white', (0.9, 0.88, 0.84), 0.8, 0.0),              # garganta, anillo del ojo, cola
    30: ('muzzle', (0.07, 0.055, 0.05), 0.35, 0.0),          # trufa húmeda
    31: ('eye', (0.02, 0.018, 0.018), 0.05, 0.0),            # ojo brillante
    32: ('hoof', (0.08, 0.065, 0.055), 0.45, 0.0),
    33: ('antler', (0.45, 0.37, 0.27), 0.6, 0.0),
    34: ('earin', (0.55, 0.4, 0.36), 0.7, 0.0),              # interior de la oreja
    # --- criatura ---
    35: ('pale', (0.5, 0.5, 0.53), 0.65, 0.0),               # piel gris pálida y arrugada
    36: ('sinew', (0.36, 0.06, 0.07), 0.4, 0.0),             # columna de carne roja del cuello
    37: ('sinewpale', (0.62, 0.44, 0.43), 0.45, 0.0),         # vetas claras de la carne
    38: ('gullet', (0.07, 0.05, 0.13), 0.3, 0.0),            # interior de la boca, morado oscuro
    39: ('tendril', (0.16, 0.025, 0.035), 0.4, 0.0),            # tentáculos rojo oscuro
}
MAT = {v[0]: k for k, v in MATERIALS.items()}


def rot(axis, ang):
    axis = np.asarray(axis, float); axis /= np.linalg.norm(axis)
    x, y, z = axis; c, s = np.cos(ang), np.sin(ang); C = 1 - c
    return np.array([[c + x*x*C, x*y*C - z*s, x*z*C + y*s], [y*x*C + z*s, c + y*y*C, y*z*C - x*s], [z*x*C - y*s, z*y*C + x*s, c + z*z*C]])


class Xf:
    """Transformación de semejanza: p_mundo = s · R @ p_local + t."""
    def __init__(self, R=None, t=(0, 0, 0), s=1.0):
        self.R = np.eye(3) if R is None else np.asarray(R, float); self.t = np.asarray(t, float); self.s = float(s)
    def __matmul__(self, o):
        return Xf(self.R @ o.R, self.s * (self.R @ o.t) + self.t, self.s * o.s)
    def apply(self, p):
        return self.s * (self.R @ np.asarray(p, float)) + self.t
    @staticmethod
    def about(pivot, R):
        pivot = np.asarray(pivot, float); return Xf(R, pivot - R @ pivot)


def smin(a, b, k):
    if k <= 0: return np.minimum(a, b)
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1)
    return b + (a - b) * h - k * h * (1 - h)


class Grid:
    def __init__(self, lo, hi, h):
        self.h = h; self.lo = np.asarray(lo, float)
        self.n = np.ceil((np.asarray(hi, float) - self.lo) / h).astype(int) + 1
        self.d = np.full(self.n, 1e3, np.float32)
        self.mat = np.zeros(self.n, np.uint8)
        self.part = np.zeros(self.n, np.uint8)
        print('rejilla', self.n, 'vóxeles', int(np.prod(self.n)))

    def _sub(self, lo, hi):
        i0 = np.clip(np.floor((lo - self.lo) / self.h).astype(int), 0, self.n - 1)
        i1 = np.clip(np.ceil((hi - self.lo) / self.h).astype(int) + 1, 0, self.n)
        if np.any(i1 <= i0): return None
        ax = [self.lo[k] + self.h * np.arange(i0[k], i1[k]) for k in range(3)]
        X = ax[0][:, None, None]; Y = ax[1][None, :, None]; Z = ax[2][None, None, :]
        return (slice(i0[0], i1[0]), slice(i0[1], i1[1]), slice(i0[2], i1[2])), X, Y, Z

    def apply(self, prim, op='add', k=0.1, mat='skin', part=0, xf=None, carve_mat=None, band=0.0):
        """op: 'add' (unión suave), 'sub' (resta suave), 'paint' (solo material en una zona)."""
        lo, hi = prim.bounds()
        if xf is not None:  # caja envolvente transformada
            c = np.array([[x, y, z] for x in (lo[0], hi[0]) for y in (lo[1], hi[1]) for z in (lo[2], hi[2])])
            w = xf.s * (c @ xf.R.T) + xf.t; lo, hi = w.min(0), w.max(0)
        pad = k + 2 * self.h + band
        s = self._sub(lo - pad, hi + pad)
        if s is None: return
        sl, X, Y, Z = s
        if xf is not None:  # p_local = R^T (p - t)
            dx, dy, dz = X - xf.t[0], Y - xf.t[1], Z - xf.t[2]; R = xf.R
            inv = 1.0 / xf.s
            lx = (R[0, 0] * dx + R[1, 0] * dy + R[2, 0] * dz) * inv
            ly = (R[0, 1] * dx + R[1, 1] * dy + R[2, 1] * dz) * inv
            lz = (R[0, 2] * dx + R[1, 2] * dy + R[2, 2] * dz) * inv
        else:
            lx, ly, lz = np.broadcast_arrays(X, Y, Z)
        pd = (prim.sdf(lx, ly, lz) * (xf.s if xf is not None else 1.0)).astype(np.float32)
        d = self.d[sl]
        if op == 'add':
            m = pd < d + band
            self.mat[sl][m] = MAT[mat]; self.part[sl][m] = part
            self.d[sl] = smin(d, pd, k)
        elif op == 'sub':
            nd = -smin(-d, pd, k)
            if carve_mat is not None:
                m = nd > d + 0.25 * self.h
                self.mat[sl][m] = MAT[carve_mat]
            self.d[sl] = nd
        elif op == 'paint':
            m = pd < 0
            self.mat[sl][m] = MAT[mat]
        elif op == 'label':   # solo cambia la parte (para separar la mandíbula del cráneo)
            m = pd < 0
            self.part[sl][m] = part

    def noise(self, amp, freq, mask_mats=(), seed=1):
        """Relieve orgánico (arrugas, bultos) sumado a la distancia cerca de la superficie."""
        rng = np.random.default_rng(seed)
        near = np.abs(self.d) < amp * 6 + self.h * 2
        idx = np.nonzero(near)
        p = self.lo[None, :] + self.h * np.stack(idx, 1)
        v = value_noise(p * freq, rng) * 0.65 + value_noise(p * freq * 2.3, rng) * 0.35
        w = np.ones(len(v), np.float32)
        for mm in mask_mats: w[self.mat[idx] == MAT[mm]] = 0.15
        self.d[idx] += (amp * v * w).astype(np.float32)

    def mesh(self):
        from skimage.measure import marching_cubes
        v, f, n, _ = marching_cubes(self.d, 0.0, spacing=(self.h,) * 3, allow_degenerate=False)
        v = v + self.lo
        ii = np.clip(np.round((v - self.lo) / self.h).astype(int), 0, self.n - 1)
        # material/parte: el del vóxel vecino más cercano a la superficie por dentro
        mat = self.mat[ii[:, 0], ii[:, 1], ii[:, 2]]; part = self.part[ii[:, 0], ii[:, 1], ii[:, 2]]
        return v.astype(np.float32), f.astype(np.int32), mat, part


def value_noise(p, rng):
    """Ruido de valor 3D suave en [-1, 1], tabla de 64³ repetida."""
    T = value_noise.__dict__.setdefault('T', rng.random((64, 64, 64)).astype(np.float32) * 2 - 1)
    i = np.floor(p).astype(int); f = p - i; f = f * f * (3 - 2 * f)
    out = 0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (f[:, 0] if dx else 1 - f[:, 0]) * (f[:, 1] if dy else 1 - f[:, 1]) * (f[:, 2] if dz else 1 - f[:, 2])
                out = out + w * T[(i[:, 0] + dx) & 63, (i[:, 1] + dy) & 63, (i[:, 2] + dz) & 63]
    return out


# ---------------- primitivas ----------------
class Ellipsoid:
    def __init__(self, c, r):
        self.c = np.asarray(c, float); self.r = np.asarray(r, float)
    def bounds(self): return self.c - self.r, self.c + self.r
    def sdf(self, x, y, z):
        px, py, pz = (x - self.c[0]) / self.r[0], (y - self.c[1]) / self.r[1], (z - self.c[2]) / self.r[2]
        k0 = np.sqrt(px * px + py * py + pz * pz)
        k1 = np.sqrt((px / self.r[0]) ** 2 + (py / self.r[1]) ** 2 + (pz / self.r[2]) ** 2)
        return k0 * (k0 - 1.0) / np.maximum(k1, 1e-6)


class RoundCone:
    """Cono redondeado entre a (radio r1) y b (radio r2); squash aplana la sección (x lateral, y vertical)."""
    def __init__(self, a, b, r1, r2, squash=None):
        self.a = np.asarray(a, float); self.b = np.asarray(b, float); self.r1 = float(r1); self.r2 = float(r2)
        self.sq = None if squash is None else np.asarray(squash, float)
    def bounds(self):
        r = max(self.r1, self.r2) * (1 if self.sq is None else max(1, self.sq.max()))
        return np.minimum(self.a, self.b) - r, np.maximum(self.a, self.b) + r
    def sdf(self, x, y, z):
        a, b = self.a, self.b
        if self.sq is not None:  # aplanar en un marco local alineado con el eje
            ax = (b - a) / np.linalg.norm(b - a); up = np.array([0, 1.0, 0]) if abs(ax[1]) < 0.9 else np.array([1.0, 0, 0])
            side = np.cross(up, ax); side /= np.linalg.norm(side); up = np.cross(ax, side)
            dx, dy, dz = x - a[0], y - a[1], z - a[2]
            u = (dx * side[0] + dy * side[1] + dz * side[2]) / self.sq[0]
            v = (dx * up[0] + dy * up[1] + dz * up[2]) / self.sq[1]
            w = dx * ax[0] + dy * ax[1] + dz * ax[2]
            L = np.linalg.norm(b - a)
            return round_cone(u, v, w, np.zeros(3), np.array([0, 0, L]), self.r1, self.r2) * min(self.sq.min(), 1)
        return round_cone(x, y, z, a, b, self.r1, self.r2)


def round_cone(x, y, z, a, b, r1, r2):
    ba = b - a; l2 = ba @ ba; rr = r1 - r2; a2 = l2 - rr * rr; il2 = 1.0 / l2
    px, py, pz = x - a[0], y - a[1], z - a[2]
    yv = px * ba[0] + py * ba[1] + pz * ba[2]; zv = yv - l2
    qx, qy, qz = px * l2 - ba[0] * yv, py * l2 - ba[1] * yv, pz * l2 - ba[2] * yv
    x2 = qx * qx + qy * qy + qz * qz; y2 = yv * yv * l2; z2 = zv * zv * l2
    kk = np.sign(rr) * rr * rr * x2
    d3 = (np.sqrt(np.maximum(x2 * a2 * il2, 0)) + yv * rr) * il2 - r1
    d1 = np.sqrt(x2 + z2) * il2 - r2
    d2 = np.sqrt(x2 + y2) * il2 - r1
    return np.where(np.sign(zv) * a2 * z2 > kk, d1, np.where(np.sign(yv) * a2 * y2 < kk, d2, d3))


class Box:
    def __init__(self, c, half, round_=0.0):
        self.c = np.asarray(c, float); self.hf = np.asarray(half, float); self.r = round_
    def bounds(self): return self.c - self.hf - self.r, self.c + self.hf + self.r
    def sdf(self, x, y, z):
        qx, qy, qz = np.abs(x - self.c[0]) - self.hf[0], np.abs(y - self.c[1]) - self.hf[1], np.abs(z - self.c[2]) - self.hf[2]
        o = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2 + np.maximum(qz, 0) ** 2)
        return o + np.minimum(np.maximum(qx, np.maximum(qy, qz)), 0) - self.r


class Chain:
    """Tubo curvo: cadena de conos redondeados a través de puntos con radios."""
    def __init__(self, pts, radii, squash=None):
        self.segs = [RoundCone(pts[i], pts[i + 1], radii[i], radii[i + 1], squash) for i in range(len(pts) - 1)]
    def bounds(self):
        lo = np.min([s.bounds()[0] for s in self.segs], 0); hi = np.max([s.bounds()[1] for s in self.segs], 0); return lo, hi
    def sdf(self, x, y, z):
        d = None
        for s in self.segs:
            e = s.sdf(x, y, z); d = e if d is None else np.minimum(d, e)
        return d


def bezier(p0, p1, p2, n):
    p0, p1, p2 = map(lambda v: np.asarray(v, float), (p0, p1, p2))
    t = np.linspace(0, 1, n)[:, None]
    return (1 - t) ** 2 * p0 + 2 * (1 - t) * t * p1 + t * t * p2


def horn(base, ctrl, tip, r0, n=7, squash=None, r_tip=0.012):
    """Cuerno/púa curva que se afina: base → control → punta."""
    pts = bezier(base, ctrl, tip, n)
    radii = [r0 * (1 - i / (n - 1)) ** 1.15 + r_tip for i in range(n)]
    return Chain(pts, radii, squash)


def open_edges(faces):
    """Número de aristas usadas por una sola cara (0 = malla cerrada, sin agujeros)."""
    e = np.sort(np.concatenate([faces[:, [0, 1]], faces[:, [1, 2]], faces[:, [2, 0]]]), axis=1)
    _, counts = np.unique(e, axis=0, return_counts=True)
    return int((counts == 1).sum())


class Field:
    """Campo arbitrario fn(x, y, z) dentro de una caja (útil para etiquetar regiones)."""
    def __init__(self, fn, lo, hi):
        self.fn = fn; self.lo = np.asarray(lo, float); self.hi = np.asarray(hi, float)
    def bounds(self): return self.lo, self.hi
    def sdf(self, x, y, z): return self.fn(x, y, z)
