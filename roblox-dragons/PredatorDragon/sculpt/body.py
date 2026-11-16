"""Cuerpo del Dragón Depredador: cuello, torso, patas, cola con aleta, heridas con costillas
y la parte ósea de las alas. Espacio Roblox (Y arriba, mira a -Z, izquierda del dragón = -X), studs.

Proporciones tomadas de la vista lateral de la referencia (largo total ≈ 44):
cabeza ≈ 1/8 · cuello grueso en S suave · torso largo con pecho profundo · cola ≈ 1/2 del largo,
casi horizontal y acabada en aleta con lóbulos de espinas · patas flexionadas, traseras con corvejón alto.
"""
import numpy as np
from sdf import Ellipsoid, RoundCone, Chain, Xf, horn, rot, bezier

PART = {'Head': 1, 'Jaw': 2, 'Tongue': 3, 'Drool': 4, 'Body': 5, 'LegFL': 6, 'LegFR': 7, 'LegBL': 8, 'LegBR': 9, 'WingL': 10, 'WingR': 11}

# columna (cuello → cola) que también usa el rig: puntos y radios
SPINE = [((0, 9.05, -18.4), 1.3), ((0, 9.55, -16.6), 1.5), ((0, 9.2, -14.5), 1.8), ((0, 8.2, -12.2), 2.15), ((0, 7.4, -10.4), 2.3),
         ((0, 6.9, -8.6), 2.25), ((0, 6.7, -5.6), 1.95), ((0, 6.6, -2.4), 1.85), ((0, 6.3, 0.6), 1.65),
         ((0.1, 5.9, 4.0), 1.3), ((0.25, 5.4, 7.6), 1.0), ((0.35, 4.95, 11.2), 0.74), ((0.2, 4.65, 14.6), 0.52),
         ((-0.15, 4.5, 17.8), 0.34), ((-0.3, 4.45, 20.6), 0.2)]
HEAD_XF = Xf(rot((1, 0, 0), -0.3), (0, 9.3, -18.2), 1.22)

# patas: (nombre, lado, puntos hombro/cadera → codo/rodilla → muñeca/corvejón → pie, radios)
LEGS = []
for s, side in ((-1, 'L'), (1, 'R')):
    LEGS.append(('LegF' + side, s, [(s * 2.0, 6.5, -9.6), (s * 2.75, 3.7, -7.6), (s * 2.55, 1.3, -9.2), (s * 2.65, 0.45, -10.4)], [1.4, 0.95, 0.62, 0.5]))
    LEGS.append(('LegB' + side, s, [(s * 1.9, 6.3, -2.0), (s * 2.7, 3.7, -4.0), (s * 2.7, 2.0, -0.8), (s * 2.8, 0.45, -2.0)], [1.65, 0.98, 0.6, 0.5]))

# alas (lado izquierdo; el derecho es su espejo). Pose de reposo: medio alzadas como en la referencia
WING = dict(shoulder=(-1.7, 8.6, -8.6), elbow=(-5.6, 12.6, -7.6), wrist=(-11.2, 15.0, -9.4),
            tips=[(-21.5, 13.0, -2.6), (-20.2, 10.8, 2.6), (-16.8, 9.1, 6.4), (-12.0, 8.2, 7.4), (-6.6, 7.9, 4.8)], rear=(-1.95, 7.1, -1.0))


def mirror(p): return (-p[0], p[1], p[2])


def wing_side(s):
    if s < 0: return WING
    return dict(shoulder=mirror(WING['shoulder']), elbow=mirror(WING['elbow']), wrist=mirror(WING['wrist']), tips=[mirror(t) for t in WING['tips']], rear=mirror(WING['rear']))


def build(g, rng, include_wing_bones=True):
    B = PART['Body']
    pts = [np.array(p) for p, _ in SPINE]; rad = [r for _, r in SPINE]
    # --- columna continua: cuello, torso y cola ---
    g.apply(Chain(pts, rad, squash=(1.0, 1.0)), k=0.6, part=B)
    # masas musculares y óseas que dan anatomía al torso
    g.apply(Ellipsoid((0, 6.0, -8.6), (2.0, 2.4, 2.7)), k=0.8, part=B)            # pecho profundo
    g.apply(Ellipsoid((0, 6.1, -5.0), (1.8, 1.8, 2.7)), k=0.8, part=B)            # costillar
    g.apply(Ellipsoid((0, 6.3, -1.6), (1.75, 1.7, 2.2)), k=0.8, part=B)             # cadera
    g.apply(Ellipsoid((0, 4.55, -8.0), (1.45, 1.0, 2.0)), k=0.7, part=B, mat='belly')  # quilla del pecho
    g.apply(Ellipsoid((0, 5.0, -4.0), (1.25, 0.6, 2.2)), k=0.7, part=B, mat='belly')  # vientre recogido
    for s in (-1, 1):
        g.apply(Ellipsoid((s * 1.55, 7.6, -9.4), (0.95, 1.4, 1.7)), k=0.6, part=B)      # escápula
        g.apply(Ellipsoid((s * 1.4, 7.9, -12.4), (0.75, 1.0, 1.8)), k=0.7, part=B)      # músculo del cuello
        g.apply(Ellipsoid((s * 1.45, 6.7, -1.3), (0.9, 1.3, 1.6)), k=0.6, part=B)       # ilíaco
    # piel del cuello con pliegues ventrales (garganta)
    for i in range(7):
        z = -17.6 + i * 0.85; y = 9.2 + (z + 18.4) * 0.05 - (1.3 + (z + 18.4) * 0.12) * 0.93
        g.apply(Ellipsoid((0, y, z), (0.95, 0.2, 0.3)), k=0.3, part=B, mat='belly')

    # --- patas ---
    for name, s, P, R in LEGS:
        part = PART[name]; P = [np.array(p) for p in P]
        g.apply(RoundCone(P[0], P[1], R[0], R[1]), k=0.55, part=part)
        g.apply(RoundCone(P[1], P[2], R[1] * 0.92, R[2]), k=0.3, part=part)
        g.apply(RoundCone(P[2], P[3], R[2], R[3]), k=0.25, part=part)
        up = P[0] + (P[1] - P[0]) * 0.42
        front = 'F' in name
        g.apply(Ellipsoid(up + np.array([s * 0.15, 0.1, -0.25 if front else 0.35]), (R[0] * 0.95, R[0] * 1.35, R[0] * 1.15)), k=0.45, part=part)   # bíceps / muslo
        mid = P[1] + (P[2] - P[1]) * 0.35
        g.apply(Ellipsoid(mid + np.array([0, 0, -0.18 if front else 0.2]), (R[1] * 0.8, R[1] * 1.25, R[1] * 0.95)), k=0.3, part=part)
        g.apply(Ellipsoid(P[1], (R[1] * 0.85, R[1] * 0.85, R[1] * 0.85)), k=0.2, part=part)
        # codo/corvejón con espolón
        spur_dir = np.array([0, 0.3, 1.0]) if front else np.array([0, 0.5, 1.0])
        j = P[1] if front else P[2]
        g.apply(horn(j, j + spur_dir * 0.45, j + spur_dir * 0.85 + np.array([0, 0.1, 0]), 0.2), k=0.12, mat='horn', part=part)
        # pie: almohadilla ancha + 4 dedos con garras curvas + dedo trasero
        foot = P[3]
        g.apply(Ellipsoid(foot + np.array([0, -0.05, -0.15]), (0.62, 0.32, 0.72)), k=0.25, part=part)
        for t in range(4):
            a = (-0.5 + t / 3) * 0.9; d = np.array([np.sin(a) * 0.9 + s * 0.08, 0, -np.cos(a)])
            base = foot + np.array([0, -0.1, -0.35]) + d * 0.35
            knuck = base + d * 0.45 + np.array([0, 0.05, 0])
            g.apply(RoundCone(base, knuck, 0.2, 0.15), k=0.12, part=part)
            g.apply(horn(knuck, knuck + d * 0.45 + np.array([0, 0.05, 0]), knuck + d * 0.75 + np.array([0, -0.4, 0]), 0.14, n=6), k=0.05, mat='claw', part=part)
        bk = foot + np.array([0, 0.0, 0.45])
        g.apply(horn(bk, bk + np.array([0, -0.1, 0.35]), bk + np.array([0, -0.35, 0.55]), 0.11, n=5), k=0.05, mat='claw', part=part)

    # --- cresta dorsal: cuchillas curvas de la nuca a la punta de la cola ---
    path = np.array(pts); L = np.r_[0, np.cumsum(np.linalg.norm(np.diff(path, axis=0), axis=1))]
    def spine_at(u):
        x = u * L[-1]; i = min(np.searchsorted(L, x) - 1, len(L) - 2); i = max(i, 0); f = (x - L[i]) / (L[i + 1] - L[i])
        p = path[i] * (1 - f) + path[i + 1] * f; r = rad[i] * (1 - f) + rad[i + 1] * f; t = path[i + 1] - path[i]
        return p, r, t / np.linalg.norm(t)
    n = 42
    for k in range(n):
        u = 0.02 + 0.93 * k / (n - 1); p, r, t = spine_at(u)
        h = 1.4 * (1.05 + 0.9 * np.exp(-((u - 0.22) / 0.12) ** 2)) * (1 - 0.6 * max(0, u - 0.3) / 0.7) * (0.8 + 0.4 * rng.random())
        base = p + np.array([0, r * 0.82, 0]); back = t * 0.75 + np.array([0, 0.66, 0]); back /= np.linalg.norm(back)
        g.apply(horn(base, base + back * h * 0.55 + t * 0.15 * h, base + back * h + t * 0.42 * h, 0.17 + h * 0.2, n=6, squash=(0.42, 1)), k=0.14, mat='horn', part=B)
        if u > 0.5:  # púas laterales de la cola (vista superior)
            for s in (-1, 1):
                b2 = p + np.array([s * r * 0.8, 0.0, 0]); d2 = np.array([s * 0.8, 0.1, 0.6]); d2 /= np.linalg.norm(d2); h2 = h * 0.55
                g.apply(horn(b2, b2 + d2 * h2 * 0.5, b2 + d2 * h2 + t * 0.2 * h2, 0.07 + h2 * 0.15, n=5, squash=(1, 0.45)), k=0.08, mat='horn', part=B)

    # --- aleta de la cola: lóbulos membranosos con espinas, arriba, abajo y a los lados ---
    tip, _, t = spine_at(1.0)
    for ang, length, w in [(60, 3.4, 0.7), (40, 4.3, 0.8), (18, 3.6, 0.65), (-18, 3.3, 0.6), (-38, 4.0, 0.72), (-58, 3.0, 0.55)]:
        a = np.radians(ang); d = np.array([0, np.sin(a), np.cos(a)]); start = tip - t * 1.6 + np.array([0, np.sign(ang) * 0.1, 0])
        g.apply(horn(start, start + d * length * 0.55 + t * 0.4, start + d * length, w, n=7, squash=(0.12, 1)), k=0.15, mat='membrane', part=B)
        g.apply(horn(start, start + d * length * 0.5, start + d * length * 1.08, 0.08, n=5), k=0.04, mat='horn', part=B)
    for s in (-1, 1):
        for ang, length in [(25, 2.8), (55, 2.2)]:
            a = np.radians(ang); d = np.array([s * np.sin(a), 0, np.cos(a)]); start = tip - t * 1.2
            g.apply(horn(start, start + d * length * 0.5, start + d * length, 0.5, n=6, squash=(1, 0.12)), k=0.12, mat='membrane', part=B)
    g.apply(horn(tip - t * 0.5, tip + t * 0.9, tip + t * 1.9, 0.18, n=5), k=0.08, mat='horn', part=B)

    # --- heridas con costillas al aire (flancos y pecho, como en la referencia) ---
    for s in (-1, 1):
        c = np.array([s * 2.2, 5.75, -6.0])
        g.apply(Ellipsoid(c, (0.7, 1.25, 2.2)), op='sub', k=0.35, carve_mat='wound')
        for i in range(6):
            z = c[2] - 1.7 + i * 0.66 + rng.uniform(-0.12, 0.12); th = rng.uniform(0.75, 1.25); sink = rng.uniform(0.0, 0.18)
            ribs = [np.array([s * (1.75 - sink), 7.05, z]), np.array([s * (2.25 - sink), 6.2, z + 0.12]), np.array([s * (2.22 - sink), 5.2, z + 0.24]), np.array([s * (1.8 - sink), 4.5, z + 0.3])]
            g.apply(Chain(ribs, [0.08 * th, 0.12 * th, 0.11 * th, 0.07 * th]), k=0.08, mat='bone', part=B)
        for i in range(4):  # jirones de carne
            q = c + np.array([s * -0.05, rng.uniform(-0.8, 0.8), rng.uniform(-1.5, 1.5)])
            g.apply(Ellipsoid(q, (0.12, 0.28, 0.14)), k=0.08, mat='flesh', part=B)
    cf = np.array([0, 4.45, -10.25])
    g.apply(Ellipsoid(cf, (0.95, 0.85, 0.55)), op='sub', k=0.2, carve_mat='wound')
    for i in range(4):
        x = -0.6 + i * 0.4
        g.apply(Chain([np.array([x, 5.1, -10.0]), np.array([x * 1.1, 4.45, -10.55]), np.array([x, 3.8, -10.1])], [0.08, 0.1, 0.08]), k=0.05, mat='bone', part=B)
    for (c2, r2) in [((-2.05, 7.6, -11.6), (0.12, 0.6, 0.9)), ((2.3, 5.6, -1.2), (0.12, 0.7, 0.8)), ((-1.4, 6.3, 3.2), (0.1, 0.5, 0.9)), ((1.3, 7.2, -13.8), (0.1, 0.4, 0.7))]:
        g.apply(Ellipsoid(c2, r2), op='paint', mat='wound')

    # --- huesos de las alas que nacen del hombro (brazo); antebrazo y dedos van en su propia rejilla ---
    if include_wing_bones:
        for s in (-1, 1):
            w = wing_side(s); part = PART['WingL' if s < 0 else 'WingR']
            S, E = np.array(w['shoulder']), np.array(w['elbow'])
            g.apply(RoundCone(S, E, 0.62, 0.45), k=0.55, part=part)
            g.apply(Ellipsoid(S + (E - S) * 0.35, (0.75, 0.75, 0.75)), k=0.4, part=part)
            g.apply(Ellipsoid(E, (0.5, 0.5, 0.5)), k=0.2, part=part)


def build_wing_bones(g, s):
    """Antebrazo, muñeca con garra en gancho y dedos largos de un ala (rejilla propia)."""
    w = wing_side(s); part = PART['WingL' if s < 0 else 'WingR']
    E, W = np.array(w['elbow']), np.array(w['wrist'])
    g.apply(Ellipsoid(E, (0.5, 0.5, 0.5)), k=0.2, part=part)
    g.apply(RoundCone(E, W, 0.45, 0.33), k=0.3, part=part)
    g.apply(Ellipsoid(W, (0.42, 0.38, 0.42)), k=0.2, part=part)
    hook = W + np.array([0, 0.25, -0.2])
    g.apply(horn(hook, hook + np.array([0, 0.9, -0.5]), hook + np.array([0, 0.85, -1.5]), 0.24, n=7), k=0.12, mat='claw', part=part)
    for T in w['tips']:
        T = np.array(T); mid = W + (T - W) * 0.45 + np.array([0, 0.6, 0])
        pts = bezier(W, mid, T, 8); radii = [0.26 - 0.22 * i / 7 for i in range(8)]
        g.apply(Chain(list(pts), radii), k=0.15, part=part)
        k1 = W + (T - W) * 0.32 + np.array([0, 0.45, 0])
        g.apply(Ellipsoid(k1, (0.24, 0.2, 0.24)), k=0.1, part=part)
