"""Lobo hueco: un lobo famélico del bosque nocturno.

Espacio Roblox: Y arriba, mira a -Z, izquierda = -X, studs. Suelo en y = 0. Cruz a ~2,6 studs.
  · pelaje gris pardo con montura oscura en el lomo y vientre, patas y mejillas más claros
  · flaco hasta el hueso: costillas, vértebras y caderas marcadas, cintura muy recogida
  · calvas de sarna con la piel rosácea al aire, cicatrices y una oreja mordida
  · gorguera de mechones en el cuello, crin erizada en el lomo y cola tupida pero rala
  · hocico largo gruñendo: labios recogidos, encías y colmillos al aire; ojos amarillos hundidos
El alfa es el mismo modelo más grande (escala en el juego) con más calvas y los ojos más brillantes.
"""
import numpy as np
from sdf import Ellipsoid, RoundCone, Chain, Box, Xf, Field, horn, rot, bezier

PART = {'Body': 1, 'Head': 2, 'Jaw': 3, 'EarL': 4, 'EarR': 5, 'Tail': 6, 'Neck': 7,
        'LegFL': 10, 'LegFR': 11, 'LegBL': 12, 'LegBR': 13}

TAIL_BASE = (0, 2.42, 1.62)
HIPS = (0, 2.45, 1.2)
SPINE_MID = (0, 2.38, 0.25)
CHEST = (0, 2.56, -0.62)
N1 = (0, 2.3, -0.98)
N2 = (0, 2.7, -1.32)
ATLAS = (0, 2.98, -1.6)
TAIL_PTS = [TAIL_BASE, (0, 2.22, 2.02), (0, 1.8, 2.36), (0, 1.38, 2.55), (0, 1.0, 2.62)]
HEAD_XF = Xf(rot((1, 0, 0), -0.22), ATLAS, 1.0)

LEGS = []
for s, side in ((-1, 'L'), (1, 'R')):
    LEGS.append(('LegF' + side, s, [(s * 0.26, 2.12, -0.66), (s * 0.25, 1.42, -0.56), (s * 0.22, 0.55, -0.66), (s * 0.22, 0.1, -0.76), (s * 0.22, 0.02, -0.98)],
                 [0.19, 0.11, 0.07, 0.07, 0.075]))
    LEGS.append(('LegB' + side, s, [(s * 0.28, 2.25, 1.15), (s * 0.3, 1.5, 0.8), (s * 0.25, 0.86, 1.36), (s * 0.23, 0.1, 1.26), (s * 0.23, 0.02, 1.05)],
                 [0.27, 0.14, 0.07, 0.065, 0.075]))

# cabeza local (origen en el atlas, hocico hacia -Z)
SNOUT_L = (0, -0.05, -1.04)
HINGE_L = (0, -0.1, -0.24)
CHIN_L = (0, -0.17, -0.92)
EYE_L = [(-0.135, 0.07, -0.42), (0.135, 0.07, -0.42)]
EAR_BASE_L = [(-0.13, 0.17, -0.1), (0.13, 0.17, -0.1)]
EAR_TIP_L = [(-0.21, 0.5, 0.02), (0.21, 0.5, 0.02)]


def H(p): return HEAD_XF.apply(p)


def surface(g, p_out, p_in, n=300):
    p_out, p_in = np.asarray(p_out, float), np.asarray(p_in, float)
    for t in np.linspace(0, 1, n):
        p = p_out + (p_in - p_out) * t
        i = np.round((p - g.lo) / g.h).astype(int)
        if np.any(i < 0) or np.any(i >= g.n): continue
        if g.d[i[0], i[1], i[2]] < 0: return p
    return None


def spine_at(z):
    pts = np.array([TAIL_BASE, HIPS, SPINE_MID, CHEST]); k = np.argsort(pts[:, 2])
    return np.array([0, np.interp(z, pts[k, 2], pts[k, 1]), z])


def build_wolf(g, rng):
    B, F = PART['Body'], 'wolffur'
    A = lambda prim, **kw: g.apply(prim, **{'mat': F, **kw})
    # tronco: pecho hondo, cintura de galgo, grupa estrecha
    A(Chain([TAIL_BASE, HIPS, SPINE_MID, CHEST], [0.2, 0.24, 0.24, 0.24]), k=0.25, part=B)
    A(Ellipsoid((0, 2.08, -0.42), (0.33, 0.56, 0.52)), k=0.35, part=B)
    A(Ellipsoid((0, 2.15, 0.3), (0.28, 0.36, 0.85)), k=0.35, part=B)
    A(Ellipsoid((0, 2.24, 1.15), (0.3, 0.36, 0.45)), k=0.3, part=B)
    g.apply(Ellipsoid((0, 1.48, 0.75), (0.6, 0.32, 0.7)), op='sub', k=0.35)
    for s in (-1, 1):
        A(Ellipsoid((s * 0.21, 2.28, -0.6), (0.15, 0.4, 0.26)), k=0.22, part=B)     # escápula
        A(Ellipsoid((s * 0.24, 2.25, 1.12), (0.17, 0.42, 0.36)), k=0.22, part=B)    # muslo alto
        g.apply(Ellipsoid((s * 0.4, 2.05, 0.55), (0.12, 0.3, 0.4)), op='sub', k=0.25)   # ijar hundido
    # cuello y cabeza
    A(Chain([N1, N2, ATLAS], [0.34, 0.27, 0.22], squash=(0.85, 1.0)), k=0.3, part=PART['Neck'])
    pts = build_head(g, rng)
    # cola
    A(Chain(TAIL_PTS, [0.11, 0.1, 0.085, 0.065, 0.04]), k=0.12, part=PART['Tail'])
    # patas: digitígradas, finas, con codo y corvejón marcados y pies de cuatro dedos con uñas
    for name, s, P, R in LEGS:
        part = PART[name]; P = [np.array(p) for p in P]
        for a, b, ra, rb in zip(P[:-1], P[1:], R[:-1], R[1:]):
            A(RoundCone(a, b, ra, rb), k=0.1, part=part)
        A(Ellipsoid(P[2], (0.075, 0.08, 0.08)), k=0.05, part=part)
        if 'B' in name: A(Ellipsoid(P[2] + np.array([0, 0.04, 0.06]), (0.05, 0.08, 0.05)), k=0.04, part=part)
        else: A(Ellipsoid(P[1] + np.array([0, 0, 0.06]), (0.07, 0.07, 0.06)), k=0.04, part=part)   # codo
        paw = P[3] + np.array([0, -0.03, -0.12])
        A(Ellipsoid(paw, (0.1, 0.06, 0.13)), k=0.05, part=part)
        for k_, dx in enumerate((-0.06, -0.02, 0.02, 0.06)):
            toe = paw + np.array([dx * 1.2, -0.01, -0.1 - (0.025 if k_ in (1, 2) else 0)])
            A(Ellipsoid(toe, (0.03, 0.035, 0.045)), k=0.02, part=part)
            g.apply(horn(toe + np.array([0, 0.0, -0.03]), toe + np.array([0, -0.02, -0.07]), toe + np.array([0, -0.045, -0.09]), 0.014, n=3, r_tip=0.003), k=0.006, mat='claw', part=part)
    gaunt(g, rng)
    fur(g, rng)
    mange(g, rng)
    return pts


def build_head(g, rng):
    Hh, J = PART['Head'], PART['Jaw']
    A = lambda prim, **kw: g.apply(prim, **{'xf': HEAD_XF, 'mat': 'wolffur', **kw})
    A(Ellipsoid((0, 0.05, -0.18), (0.22, 0.2, 0.24)), k=0, part=Hh)
    A(RoundCone((0, 0.0, -0.34), (0, -0.05, -0.98), 0.145, 0.072, squash=(0.82, 1.0)), k=0.18, part=Hh)
    A(Ellipsoid((0, 0.1, -0.42), (0.12, 0.08, 0.14)), k=0.1, part=Hh)                         # frente (stop)
    for s in (-1, 1):
        A(Ellipsoid((s * 0.16, -0.03, -0.28), (0.1, 0.1, 0.15)), k=0.1, part=Hh)               # arco cigomático
        A(Ellipsoid((s * 0.12, 0.13, -0.38), (0.07, 0.04, 0.09)), k=0.06, part=Hh)              # ceja ósea, ceño
    A(Ellipsoid((0, -0.02, -1.0), (0.068, 0.058, 0.06)), k=0.03, mat='muzzle', part=Hh)       # trufa
    for s in (-1, 1):
        A(Ellipsoid((s * 0.03, -0.03, -1.05), (0.016, 0.02, 0.02)), op='sub', k=0.006, carve_mat='muzzle')
    A(RoundCone((0, -0.13, -0.3), (0, -0.15, -0.9), 0.085, 0.05, squash=(0.9, 0.85)), k=0.1, part=J)
    # gruñido: labios recogidos, encía granate al aire y dientes
    for s in (-1, 1):
        lip = [(s * 0.03, -0.1, -0.97), (s * 0.07, -0.09, -0.8), (s * 0.1, -0.085, -0.6), (s * 0.12, -0.09, -0.42)]
        A(Chain(lip, [0.028, 0.034, 0.032, 0.026]), op='sub', k=0.015, carve_mat='gum')
        A(Chain([(x, y + 0.035, z) for x, y, z in lip], [0.012] * 4), k=0.012, mat='wolfdark', part=Hh)
        A(Chain([(x, y - 0.04, z) for x, y, z in lip], [0.011] * 4), k=0.012, mat='wolfdark', part=J)
        # colmillos
        A(horn((s * 0.04, -0.075, -0.9), (s * 0.042, -0.12, -0.91), (s * 0.04, -0.17, -0.9), 0.016, n=4, r_tip=0.003), k=0.004, mat='teeth', part=Hh)
        A(horn((s * 0.035, -0.125, -0.86), (s * 0.037, -0.085, -0.87), (s * 0.035, -0.05, -0.86), 0.013, n=4, r_tip=0.003), k=0.004, mat='teeth', part=J)
        for z in np.linspace(-0.82, -0.48, 6):          # premolares y carniceras
            L = 0.03 + 0.03 * rng.random()
            A(horn((s * (0.075 + 0.05 * (z + 0.82)), -0.08, z), (s * 0.08, -0.08 - L * 0.5, z), (s * 0.08, -0.08 - L, z + 0.01), 0.012, n=3, r_tip=0.003), k=0.004, mat='teeth', part=Hh)
            A(horn((s * (0.07 + 0.05 * (z + 0.82)), -0.12, z + 0.02), (s * 0.075, -0.12 + L * 0.5, z + 0.02), (s * 0.075, -0.12 + L, z + 0.03), 0.011, n=3, r_tip=0.003), k=0.004, mat='teeth', part=J)
    for x in (-0.02, 0.0, 0.02):                         # incisivos
        A(Ellipsoid((x, -0.1, -0.98), (0.008, 0.02, 0.008)), k=0.003, mat='teeth', part=Hh)
    # orejas triangulares y erguidas (la izquierda, mordida)
    for i, s in enumerate((-1, 1)):
        part = PART['EarL' if s < 0 else 'EarR']; b0, t0 = np.array(EAR_BASE_L[i]), np.array(EAR_TIP_L[i])
        A(Chain([b0, b0 + (t0 - b0) * 0.5, t0], [0.1, 0.07, 0.012], squash=(0.35, 1.0)), k=0.05, part=part)
        A(Chain([b0 + np.array([0, 0.03, -0.035]), b0 + (t0 - b0) * 0.5 + np.array([0, 0, -0.035]), t0 + np.array([0, -0.04, -0.02])], [0.06, 0.045, 0.006], squash=(0.25, 1.0)),
          op='sub', k=0.02, carve_mat='wolfdark')
        if s < 0:
            A(Ellipsoid(b0 + (t0 - b0) * 0.7 + np.array([-0.04, 0, 0]), (0.04, 0.03, 0.06)), op='sub', k=0.01, carve_mat='mange')
    # ojos amarillos hundidos bajo el ceño
    eyes = []
    for (x, y, z) in EYE_L:
        o = H((x * 4, y, z - 0.1)); c = H((0, y, z)); hit = surface(g, o, c)
        loc = np.linalg.solve(HEAD_XF.R, (hit - HEAD_XF.t)) if hit is not None else np.array([x, y, z])
        n_out = np.array([np.sign(x), 0.05, -0.55]); n_out /= np.linalg.norm(n_out)
        A(Ellipsoid(loc - n_out * 0.01, (0.045, 0.03, 0.045)), op='sub', k=0.01, carve_mat='wolfdark')
        A(Ellipsoid(loc - n_out * 0.025, (0.034, 0.024, 0.036)), k=0.006, mat='wolfeye', part=Hh)
        eyes.append(list(map(float, H(loc + n_out * 0.01))))
    return {'eyes': eyes}


def gaunt(g, rng):
    """Hambre: costillas, vértebras y caderas que se marcan bajo el pelo."""
    B = PART['Body']
    for z in np.arange(-0.75, 0.5, 0.16) + rng.uniform(-0.03, 0.03, 8):
        c = spine_at(z) - np.array([0, 0.35, 0])
        for s in (-1, 1):
            arc = []
            for a in np.radians(np.linspace(70, -60, 7)):
                d = np.array([s * np.cos(a), np.sin(a), 0]); hit = surface(g, c + d * 1.5, c)
                if hit is None or np.linalg.norm(hit - c) > 0.8: arc = []; continue
                arc.append(hit + d * 0.008)
            if len(arc) >= 3: g.apply(Chain(arc, [0.016] * len(arc)), k=0.035, mat='wolffur', part=B)
    for z in np.linspace(-0.6, 1.5, 15):
        p = spine_at(z); hit = surface(g, p + np.array([0, 0.8, 0]), p)
        if hit is not None: g.apply(Ellipsoid(hit, (0.045, 0.035, 0.05)), k=0.03, mat='wolffur', part=B)
    for s in (-1, 1):
        g.apply(Ellipsoid((s * 0.22, 2.48, 1.32), (0.07, 0.06, 0.08)), k=0.05, mat='wolffur', part=B)   # punta de la cadera


def fur(g, rng):
    """Mechones: gorguera del cuello, crin del lomo, mejillas y cola (ralos, desordenados)."""
    def tufts(n, sampler, length, radius, part):
        for _ in range(n):
            res = sampler()
            if res is None: continue
            base, d = res
            L = length * rng.uniform(0.6, 1.2); d = d + rng.normal(0, 0.18, 3); d /= np.linalg.norm(d)
            g.apply(horn(base - d * 0.02, base + d * L * 0.5 + np.array([0, -L * 0.15, 0]), base + d * L + np.array([0, -L * 0.3, 0]), radius, n=3, r_tip=0.004),
                    k=0.02, mat='wolffur', part=part)
    neck = [np.array(p) for p in (N1, N2, ATLAS)]
    def ruff():
        t = rng.random(); seg = min(int(t * 2), 1); f = t * 2 - seg; c = neck[seg] * (1 - f) + neck[seg + 1] * f
        a = rng.uniform(0, 2 * np.pi); d = np.array([np.cos(a) * 0.85, np.sin(a), 0.2])
        hit = surface(g, c + d * 1.2, c)
        return None if hit is None else (hit, np.array([d[0] * 0.6, -0.3 + d[1] * 0.3, 0.8]))
    tufts(70, ruff, 0.2, 0.03, PART['Neck'])
    def hackles():
        z = rng.uniform(-0.7, 1.2); p = spine_at(z); hit = surface(g, p + np.array([rng.uniform(-0.15, 0.15), 0.8, 0]), p)
        return None if hit is None else (hit, np.array([0, 0.6, 0.8]))
    tufts(45, hackles, 0.14, 0.022, PART['Body'])
    def cheeks():
        s = rng.choice([-1, 1]); l = np.array([s * 0.18, rng.uniform(-0.12, 0.02), rng.uniform(-0.35, -0.15)])
        hit = surface(g, H(l * np.array([3, 1, 1])), H(l * np.array([0, 1, 1])))
        return None if hit is None else (hit, HEAD_XF.R @ np.array([s * 0.7, -0.2, 0.7]))
    tufts(24, cheeks, 0.12, 0.022, PART['Head'])
    tail = [np.array(p) for p in TAIL_PTS]
    def tailtuft():
        t = rng.uniform(0.1, 1.0) * (len(tail) - 1); i = min(int(t), len(tail) - 2); f = t - i; c = tail[i] * (1 - f) + tail[i + 1] * f
        ax = tail[i + 1] - tail[i]; ax /= np.linalg.norm(ax); a = rng.uniform(0, 2 * np.pi)
        side = np.cross([1, 0, 0], ax); side /= np.linalg.norm(side); d = np.array([1, 0, 0]) * np.cos(a) + side * np.sin(a)
        return c + d * 0.06, d * 0.6 + ax
    tufts(60, tailtuft, 0.18, 0.03, PART['Tail'])


def mange(g, rng):
    """Calvas de sarna (piel rosácea, un poco hundida) y cicatrices."""
    for _ in range(9):
        z = rng.uniform(-0.6, 1.3); a = rng.uniform(-30, 210); c = spine_at(z) - np.array([0, 0.3, 0])
        d = np.array([np.cos(np.radians(a)), np.sin(np.radians(a)), 0]); hit = surface(g, c + d * 1.5, c)
        if hit is None: continue
        r = rng.uniform(0.07, 0.15)
        g.apply(Ellipsoid(hit + d * r * 0.75, (r, r * 0.8, r * 1.2)), op='sub', k=0.02, carve_mat='mange')   # calva poco honda
        g.apply(Ellipsoid(hit, (r * 0.85, r * 0.7, r * 1.05)), op='paint', mat='mange')
    for _ in range(4):
        z = rng.uniform(-0.5, 1.0); c = spine_at(z) - np.array([0, 0.3, 0]); s = rng.choice([-1, 1])
        p0 = surface(g, c + np.array([s * 1.5, 0.2, 0]), c); p1 = surface(g, c + np.array([s * 1.5, -0.3, 0.25]), c + np.array([0, 0, 0.25]))
        if p0 is not None and p1 is not None:
            g.apply(Chain([p0, p1], [0.015, 0.015]), op='sub', k=0.01, carve_mat='mange')


def _ss(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t)


def wolf_colors(v, mat, MAT, MATERIALS):
    """Pelaje con degradados: montura oscura en el lomo y la cola, vientre, patas, mejillas y garganta claros."""
    base = np.array(MATERIALS[MAT['wolffur']][1]); dark = np.array(MATERIALS[MAT['wolfdark']][1]); light = np.array([0.5, 0.47, 0.42])
    x, y, z = v[:, 0], v[:, 1], v[:, 2]
    col = np.tile(base, (len(v), 1))
    col += (dark * 1.6 - col) * (_ss(2.35, 2.7, y) * _ss(-1.0, -0.6, z))[:, None] * 0.75            # montura
    col += (light - col) * (_ss(1.9, 1.6, y) * _ss(0.35, 0.15, np.abs(x)) ** 0.5)[:, None] * 0.8     # vientre
    col += (light * 0.85 - col) * _ss(1.3, 0.5, y)[:, None] * 0.6                                   # patas
    L = (v - HEAD_XF.t) @ HEAD_XF.R
    head = np.linalg.norm(L, axis=1) < 1.3
    col += (light - col) * (head * _ss(-0.02, -0.12, L[:, 1]) * _ss(-0.2, -0.45, L[:, 2]))[:, None] * 0.7   # mejillas y belfos claros
    col += (dark * 1.4 - col) * (head * _ss(0.05, 0.16, L[:, 1]) * _ss(-0.3, -0.75, L[:, 2]))[:, None] * 0.5  # caña de la nariz oscura
    tail_tip = _ss(1.6, 1.1, y) * _ss(2.3, 2.5, z); col += (dark - col) * tail_tip[:, None] * 0.9
    noise = (np.sin(x * 17 + z * 5) * np.sin(y * 13 - z * 11)) * 0.06
    col *= (1 + noise)[:, None]
    keep = mat == MAT['wolffur']
    return np.clip(col, 0, 1), keep
