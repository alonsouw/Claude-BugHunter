"""Cuerpo del Dragón Sombrío, según la referencia del cuerpo alargado (criatura de zancos).

Espacio Roblox (Y arriba, mira a -Z, izquierda = -X), studs.
  · torso pequeño y huesudo, encorvado en joroba, colgando muy alto
  · cuello largo que baja hacia delante; la cabeza queda a media altura mirando al frente
  · brazos delanteros larguísimos: codos por encima del lomo, manos de dedos curvados en el suelo
  · patas traseras en zigzag (como un rayo)
  · jirones de piel colgando del vientre y del cuello
  · alas hechas jirones plegadas sobre el lomo como un manto; cola larga y fina que se arrastra
"""
import numpy as np
from sdf import Ellipsoid, RoundCone, Chain, Xf, horn, rot, bezier

PART = {'Head': 1, 'Jaw': 2, 'Tongue': 3, 'Drool': 4, 'Body': 5, 'LegFL': 6, 'LegFR': 7, 'LegBL': 8, 'LegBR': 9, 'WingL': 10, 'WingR': 11}

SPINE = [((0, 7.2, -10.6), 0.5), ((0, 8.4, -9.4), 0.46), ((0, 10.2, -7.6), 0.52), ((0, 12.0, -5.6), 0.7),     # v2: cuello más fino
         ((0, 13.4, -3.4), 1.2), ((0, 14.3, -0.8), 1.45), ((0, 13.6, 2.0), 1.3), ((0, 12.0, 4.4), 1.2),
         ((0, 10.0, 6.4), 0.85), ((0.3, 7.8, 8.4), 0.66), ((0.5, 5.6, 10.6), 0.5), ((0.2, 3.6, 13.0), 0.36),
         ((-0.4, 2.0, 15.6), 0.25), ((-1.0, 1.0, 18.4), 0.15), ((-1.4, 0.6, 21.0), 0.08)]
# huesos de la columna: (nombre, padre, índice cabeza, índice cola)
SPINE_BONES = [('Hips', 'Root', 7, 6), ('Spine1', 'Hips', 6, 5), ('Chest', 'Spine1', 5, 4),
               ('Neck1', 'Chest', 4, 3), ('Neck2', 'Neck1', 3, 2), ('Neck3', 'Neck2', 2, 0)]
HIPS_INDEX = 7
HEAD_XF = Xf(rot((1, 0, 0), 0.12), (0, 7.05, -10.9), 1.3)

LEGS = []
for s, side in ((-1, 'L'), (1, 'R')):
    reach = 0.9 if side == 'L' else 0.0      # asimetría: el brazo izquierdo llega más lejos
    LEGS.append(('LegF' + side, s, [(s * 1.1, 13.0, -3.6), (s * 3.2, 15.6, -6.0), (s * 3.7, 6.2, -12.0 - reach), (s * 3.9, 0.45, -14.6 - reach)], [0.5, 0.32, 0.24, 0.22]))
    LEGS.append(('LegB' + side, s, [(s * 1.2, 11.6, 4.4), (s * 3.0, 4.6, 9.8), (s * 3.3, 8.6, 3.2), (s * 3.5, 0.45, 6.4)], [0.55, 0.32, 0.26, 0.22]))

WING = dict(shoulder=(-1.0, 14.0, -2.8), elbow=(-2.1, 15.7, 1.2), wrist=(-2.6, 14.3, 5.0),
            tips=[(-3.7, 8.4, 7.2), (-4.0, 7.9, 3.8), (-3.8, 8.3, 0.4), (-3.1, 9.2, -2.4)], rear=(-1.4, 11.6, 4.0))


def mirror(p): return (-p[0], p[1], p[2])


def wing_side(s):
    if s < 0: return WING
    return dict(shoulder=mirror(WING['shoulder']), elbow=mirror(WING['elbow']), wrist=mirror(WING['wrist']), tips=[mirror(t) for t in WING['tips']], rear=mirror(WING['rear']))


def surface(g, p_out, p_in, n=400):
    p_out, p_in = np.asarray(p_out, float), np.asarray(p_in, float)
    for t in np.linspace(0, 1, n):
        p = p_out + (p_in - p_out) * t
        i = np.round((p - g.lo) / g.h).astype(int)
        if np.any(i < 0) or np.any(i >= g.n): continue
        if g.d[i[0], i[1], i[2]] < 0: return p
    return None


def spine_at(z):
    pts = np.array([p for p, _ in SPINE]); rad = np.array([r for _, r in SPINE]); k = np.argsort(pts[:, 2])
    return np.array([np.interp(z, pts[k, 2], pts[k, 0]), np.interp(z, pts[k, 2], pts[k, 1]), z]), np.interp(z, pts[k, 2], rad[k])


def build(g, rng, include_wing_bones=True):
    B = PART['Body']
    pts = [np.array(p) for p, _ in SPINE]; rad = [r for _, r in SPINE]
    g.apply(Chain(pts, rad), k=0.4, part=B, mat='shadow')
    # jaula torácica estrecha y joroba de vértebras
    g.apply(Ellipsoid((0, 12.6, -2.2), (1.15, 1.7, 2.0)), k=0.6, part=B, mat='shadow')
    g.apply(Ellipsoid((0, 12.7, 2.2), (1.0, 1.1, 1.6)), op='sub', k=0.8)          # vientre hundido
    for s in (-1, 1):
        g.apply(Ellipsoid((s * 0.95, 14.6, -2.6), (0.3, 0.75, 0.9)), k=0.3, part=B, mat='shadow')   # omóplatos
        g.apply(Ellipsoid((s * 0.95, 13.5, 4.3), (0.35, 0.3, 0.7)), k=0.25, part=B, mat='shadow')   # caderas
    # vértebras y púas finas por el lomo, cuello y cola
    path = np.array(pts); Ls = np.r_[0, np.cumsum(np.linalg.norm(np.diff(path, axis=0), axis=1))]
    for k in range(44):
        u = 0.03 + 0.92 * k / 43; x = u * Ls[-1]; i = max(0, min(np.searchsorted(Ls, x) - 1, len(Ls) - 2)); f = (x - Ls[i]) / (Ls[i + 1] - Ls[i])
        p = path[i] * (1 - f) + path[i + 1] * f; r = rad[i] * (1 - f) + rad[i + 1] * f; t = path[i + 1] - path[i]; t /= np.linalg.norm(t)
        up = np.array([0, 1.0, 0]) - t * t[1]; up /= np.linalg.norm(up)
        base = p + up * r * 0.85
        g.apply(Ellipsoid(base, (0.16 + r * 0.1, 0.12, 0.18)), k=0.12, part=B, mat='shadow')
        h = 0.35 + 0.5 * np.exp(-((u - 0.4) / 0.2) ** 2)
        g.apply(horn(base, base + up * h * 0.6 + t * 0.1, base + up * h + t * h * 0.5, 0.07, n=4), k=0.04, mat='horn', part=B)

    # extremidades: segmentos finos con articulaciones nudosas
    for name, s, P, R in LEGS:
        part = PART[name]; P = [np.array(p) for p in P]
        for a, b, ra, rb in ((P[0], P[1], R[0], R[1]), (P[1], P[2], R[1], R[2]), (P[2], P[3], R[2], R[3])):
            g.apply(RoundCone(a, b, ra, rb), k=0.15, part=part, mat='shadow')
        g.apply(Ellipsoid(P[0], (R[0] * 1.3, R[0] * 1.3, R[0] * 1.3)), k=0.3, part=part, mat='shadow')
        for j in (1, 2):
            g.apply(Ellipsoid(P[j], (R[j] * 1.6, R[j] * 1.5, R[j] * 1.6)), k=0.1, part=part, mat='shadow')
            g.apply(horn(P[j], P[j] + np.array([s * 0.2, 0.3, 0.35]), P[j] + np.array([s * 0.3, 0.45, 0.75]), R[j] * 0.45, n=4), k=0.05, mat='horn', part=part)
        # tendones y nudos: extremidades fibrosas, no tubos lisos
        for a, b, rr in ((P[0], P[1], R[0]), (P[1], P[2], R[1]), (P[2], P[3], R[2])):
            ax = (b - a) / np.linalg.norm(b - a); side = np.cross(ax, [0, 1, 0]); side /= max(np.linalg.norm(side), 1e-6); up = np.cross(side, ax)
            for ang in (0.6, 2.4, 4.3):
                off = (side * np.cos(ang) + up * np.sin(ang)) * rr * 0.85
                mid = (a + b) / 2 + off * 1.35
                g.apply(Chain([a + off * 0.7, mid, b + off * 0.7], [0.04, rr * 0.3, 0.04]), k=0.08, part=part, mat='shadow')
            for _ in range(3):
                q = a + (b - a) * rng.uniform(0.15, 0.85) + (side * rng.normal() + up * rng.normal()) * rr * 0.6
                g.apply(Ellipsoid(q, (rr * 0.35, rr * 0.35, rr * 0.35)), k=0.08, part=part, mat='shadow')
        foot = P[3]
        if 'F' in name:   # mano: dedos larguísimos que se curvan sobre el suelo
            g.apply(Ellipsoid(foot + np.array([0, 0.05, -0.2]), (0.38, 0.22, 0.45)), k=0.15, part=part, mat='shadow')
            for k2 in range(5):
                a = (-0.55 + k2 * 0.27) * 1.3; d = np.array([np.sin(a) + s * 0.1, 0, -np.cos(a)])
                b0 = foot + d * 0.3 + np.array([0, 0.05, 0])
                pts2 = bezier(b0, b0 + d * 1.3 + np.array([0, 0.7, 0]), b0 + d * 1.95 + np.array([0, -0.35, 0]), 8)   # v2: dedos más largos
                g.apply(Chain(list(pts2), [0.1, 0.085, 0.07, 0.075, 0.06, 0.065, 0.05, 0.045]), k=0.05, part=part, mat='shadow')   # nudillos
                tip = pts2[-1]; g.apply(horn(tip, tip + d * 0.15 + np.array([0, -0.15, 0]), tip + np.array([0, -0.3, 0]) - d * 0.12, 0.055, n=4), k=0.02, mat='claw', part=part)
        else:             # pie: tres dedos y espolón
            g.apply(Ellipsoid(foot + np.array([0, 0.05, -0.15]), (0.32, 0.2, 0.4)), k=0.12, part=part, mat='shadow')
            for k2 in range(3):
                a = (-0.45 + k2 * 0.45); d = np.array([np.sin(a), 0, -np.cos(a)]); b0 = foot + d * 0.25
                g.apply(RoundCone(b0, b0 + d * 0.7, 0.09, 0.06), k=0.05, part=part, mat='shadow')
                g.apply(horn(b0 + d * 0.7, b0 + d * 1.0, b0 + d * 1.15 + np.array([0, -0.35, 0]), 0.06, n=4), k=0.02, mat='claw', part=part)
            g.apply(horn(foot, foot + np.array([0, -0.05, 0.4]), foot + np.array([0, -0.35, 0.6]), 0.06, n=4), k=0.02, mat='claw', part=part)

    # costillas que se marcan bajo la piel
    for z in np.arange(-4.6, 0.6, 0.55):
        c, r = spine_at(z)
        for ang_set in (np.linspace(40, -60, 7), np.linspace(140, 240, 7)):
            arc = []
            for a in np.radians(ang_set):
                d = np.array([np.cos(a), np.sin(a), 0]); hit = surface(g, c + d * (r + 3.0), c)
                if hit is None or np.linalg.norm(hit - c) > r * 1.8: arc = []; continue
                arc.append(hit + d * 0.04)
            if len(arc) >= 3: g.apply(Chain(arc, [0.08] * len(arc)), k=0.12, mat='shadow', part=B)

    # jirones de piel colgando del vientre, los flancos y el cuello
    for _ in range(46):
        z = rng.uniform(-9.5, 6.5); c, r = spine_at(z)
        a = np.radians(rng.uniform(195, 345)); d = np.array([np.cos(a), np.sin(a), 0])
        top = surface(g, c + d * (r + 3.0), c)
        if top is None or np.linalg.norm(top - c) > r * 1.8: continue
        L = rng.uniform(1.2, 3.8) * (0.6 if z < -6 else 1.0)
        sway = rng.uniform(-0.25, 0.25, 3); sway[1] = 0
        strip = [top, top + np.array([0, -L * 0.35, 0]) + sway * 0.4 + d * 0.08, top + np.array([0, -L * 0.7, 0]) + sway, top + np.array([0, -L, 0]) + sway * 1.3]
        w = rng.uniform(0.12, 0.26)
        g.apply(Chain(strip, [w, w * 0.85, w * 0.55, 0.03], squash=(1.0, 0.22)), k=0.06, mat='rag', part=B)

    organic_details(g, rng)

    # ala: brazo que nace del hombro (antebrazo y dedos en su propia rejilla)
    if include_wing_bones:
        for s in (-1, 1):
            w = wing_side(s); part = PART['WingL' if s < 0 else 'WingR']
            S, E = np.array(w['shoulder']), np.array(w['elbow'])
            g.apply(RoundCone(S, E, 0.36, 0.26), k=0.3, part=part, mat='shadow')
            g.apply(Ellipsoid(E, (0.3, 0.3, 0.3)), k=0.1, part=part, mat='shadow')


def build_wing_bones(g, s):
    w = wing_side(s); part = PART['WingL' if s < 0 else 'WingR']
    E, W = np.array(w['elbow']), np.array(w['wrist'])
    g.apply(Ellipsoid(E, (0.3, 0.3, 0.3)), k=0.1, part=part, mat='shadow')
    g.apply(RoundCone(E, W, 0.26, 0.2), k=0.15, part=part, mat='shadow')
    g.apply(Ellipsoid(W, (0.26, 0.24, 0.26)), k=0.1, part=part, mat='shadow')
    hook = W + np.array([0, 0.2, 0.1])
    g.apply(horn(hook, hook + np.array([0, 0.7, 0.3]), hook + np.array([0, 0.7, 1.1]), 0.15, n=6), k=0.08, mat='claw', part=part)
    for T in w['tips']:
        T = np.array(T); mid = W + (T - W) * 0.45 + np.array([s * 0.35, 0.2, 0])
        g.apply(Chain(list(bezier(W, mid, T, 7)), [0.16 - 0.13 * i / 6 for i in range(7)]), k=0.1, part=part, mat='shadow')


def organic_details(g, rng):
    """v2: detalles orgánicos en lomo y cuello, colocados con rayos sobre la piel real.
    Pliegues en anillo en el cuello, tendones laterales, venas, nódulos, púas finas en racimo,
    cicatrices y colgajos de piel mudada. Pequeños y repartidos: no recargan la silueta."""
    B = PART['Body']
    def on_skin(z, ang_deg, out=3.0):
        c, r = spine_at(z); a = np.radians(ang_deg); d = np.array([np.cos(a), np.sin(a), 0])
        hit = surface(g, c + d * (r + out), c)
        if hit is None or np.linalg.norm(hit - c) > r * 1.8: return None, d, r
        return hit, d, r
    # pliegues del cuello: arrugas en anillo que se acumulan en la parte baja
    for z in np.arange(-10.0, -4.4, 0.42):
        arc = []
        for a in np.linspace(-20, 200, 13):
            hit, d, r = on_skin(z + rng.uniform(-0.05, 0.05), a)
            if hit is None: arc = []; continue
            arc.append(hit + d * 0.02)
        if len(arc) >= 4: g.apply(Chain(arc, [0.035 + 0.02 * rng.random() for _ in arc]), k=0.06, mat='fold', part=B)
    # tendones a los lados del cuello, de la nuca al pecho
    for s in (-1, 1):
        pts = []
        for z in np.linspace(-10.2, -3.8, 9):
            hit, d, r = on_skin(z, 90 - s * 62)
            if hit is not None: pts.append(hit + d * 0.03)
        if len(pts) >= 4: g.apply(Chain(pts, [0.05, 0.08, 0.1, 0.1, 0.09, 0.09, 0.08, 0.07, 0.06][:len(pts)]), k=0.18, mat='shadow', part=B)
    # venas: hilos finos que serpentean por cuello, lomo y flancos
    for _ in range(26):
        z0 = rng.uniform(-10.0, 5.0); a0 = rng.uniform(10, 170); pts = []
        for k in range(9):
            hit, d, r = on_skin(z0 + k * 0.32, a0 + 14 * np.sin(k * 0.9 + rng.uniform(0, 3)))
            if hit is None: break
            pts.append(hit + d * 0.008)
        if len(pts) >= 4: g.apply(Chain(pts, [0.028] * len(pts)), k=0.025, mat='vein', part=B)
    # nódulos y racimos de púas finas sobre el lomo y la nuca
    for _ in range(70):
        z = rng.uniform(-10.0, 6.0); hit, d, r = on_skin(z, rng.uniform(35, 145))
        if hit is None: continue
        rr = rng.uniform(0.05, 0.12)
        g.apply(Ellipsoid(hit, (rr, rr * 0.8, rr)), k=0.05, mat='nodule', part=B)
        if rng.random() < 0.35:
            for _k in range(rng.integers(2, 5)):
                t = rng.normal(0, 0.35, 3); tip = hit + d * rng.uniform(0.15, 0.32) + t * 0.12
                g.apply(horn(hit, hit + (tip - hit) * 0.5 + t * 0.03, tip, 0.022, n=3), k=0.015, mat='horn', part=B)
    # cicatrices: surcos claros y estrechos en el lomo
    for _ in range(9):
        z = rng.uniform(-6.0, 5.0); a = rng.uniform(45, 135); pts = []
        for k in range(5):
            hit, d, r = on_skin(z + k * 0.22, a + k * rng.uniform(4, 9))
            if hit is not None: pts.append(hit)
        if len(pts) >= 3: g.apply(Chain(pts, [0.035] * len(pts)), op='sub', k=0.03, carve_mat='scar')
    # colgajos de piel mudada en la nuca y los hombros
    for _ in range(12):
        z = rng.uniform(-9.5, -2.0); hit, d, r = on_skin(z, rng.uniform(30, 150))
        if hit is None: continue
        L = rng.uniform(0.4, 0.9); tang = np.array([0, 0, 1.0]); down = np.array([0, -1.0, 0])
        g.apply(Chain([hit, hit + d * 0.08 + tang * L * 0.4, hit + down * L * 0.4 + tang * L], [0.12, 0.09, 0.02], squash=(1.0, 0.2)), k=0.04, mat='rag', part=B)
