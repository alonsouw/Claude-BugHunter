"""Ciervo de cola blanca (macho) y su forma maldita, en el mismo esqueleto.

Espacio Roblox: Y arriba, mira a -Z, izquierda = -X, studs. Suelo en y = 0. Cruz a ~3,3 studs.

  build_deer(g)      ciervo normal (pelaje pardo, vientre crema, garganta blanca, trufa negra)
  build_creature(g)  la misma anatomía convertida en la criatura de las referencias:
                       · piel gris pálida, costillas y vértebras marcadas, ojos abiertos en el pecho
                       · cuello hecho de cordones de carne roja con vetas claras
                       · collar de dientes donde el cuello entra en el cuerpo
                       · la cabeza se parte por debajo: mandíbula con hileras de agujas e interior morado
  build_antlers(g)   cuernas (malla aparte, comunes a las dos formas)
  build_tentacles(g) tentáculos rojo oscuro que brotan del cráneo (malla aparte, crecen al transformarse)
"""
import numpy as np
from sdf import Ellipsoid, RoundCone, Chain, Box, Xf, Field, horn, rot, bezier

PART = {'Body': 1, 'Head': 2, 'Jaw': 3, 'EarL': 4, 'EarR': 5, 'Tail': 6, 'Neck': 7,
        'LegFL': 10, 'LegFR': 11, 'LegBL': 12, 'LegBR': 13, 'Antler': 20}
TENT_PART0 = 100   # parte del tentáculo n, segmento k: 100 + 10 * n + k

# columna: de la cola a la cabeza
TAIL_BASE = (0, 3.12, 2.2)
HIPS = (0, 3.22, 1.5)
SPINE_MID = (0, 3.12, 0.3)
CHEST = (0, 3.28, -0.8)
N1 = (0, 2.95, -1.18)
N2 = (0, 3.5, -1.5)
N3 = (0, 4.02, -1.78)
ATLAS = (0, 4.5, -2.0)
TAIL_TIP = (0, 2.8, 2.75)
HEAD_XF = Xf(rot((1, 0, 0), -0.62), ATLAS, 1.0)      # cabeza inclinada ~35° hacia abajo

# patas: hombro/cadera, codo/rodilla, carpo/corvejón, menudillo, pezuña
LEGS = []
for s, side in ((-1, 'L'), (1, 'R')):
    LEGS.append(('LegF' + side, s, [(s * 0.3, 2.62, -0.75), (s * 0.29, 1.9, -0.66), (s * 0.26, 1.08, -0.78), (s * 0.25, 0.32, -0.8), (s * 0.25, 0.0, -0.93)],
                 [0.21, 0.12, 0.07, 0.058, 0.06]))
    LEGS.append(('LegB' + side, s, [(s * 0.32, 2.72, 1.4), (s * 0.34, 1.98, 1.0), (s * 0.28, 1.28, 1.78), (s * 0.27, 0.32, 1.64), (s * 0.27, 0.0, 1.52)],
                 [0.3, 0.16, 0.07, 0.058, 0.06]))

# cabeza en espacio local (origen en el atlas, hocico hacia -Z)
SNOUT_L = (0, -0.1, -1.16)
HINGE_L = (0, -0.16, -0.32)
CHIN_L = (0, -0.26, -1.0)
EYE_L = [(-0.19, 0.06, -0.42), (0.19, 0.06, -0.42)]
EAR_BASE_L = [(-0.17, 0.24, -0.1), (0.17, 0.24, -0.1)]
EAR_TIP_L = [(-0.6, 0.5, 0.02), (0.6, 0.5, 0.02)]
ANTLER_BASE_L = [(-0.13, 0.29, -0.2), (0.13, 0.29, -0.2)]


def surface(g, p_out, p_in, n=300):
    p_out, p_in = np.asarray(p_out, float), np.asarray(p_in, float)
    for t in np.linspace(0, 1, n):
        p = p_out + (p_in - p_out) * t
        i = np.round((p - g.lo) / g.h).astype(int)
        if np.any(i < 0) or np.any(i >= g.n): continue
        if g.d[i[0], i[1], i[2]] < 0: return p
    return None


def H(p):
    return HEAD_XF.apply(p)


def head_frame_dir(v):
    return HEAD_XF.R @ np.asarray(v, float)


# ---------------------------------------------------------------- base común
def build_base(g, skin, rng, creature=False):
    B = PART['Body']
    A = lambda prim, **kw: g.apply(prim, **{'mat': skin, **kw})
    # tronco: barril, pecho profundo, cruz, grupa, vientre recogido
    A(Chain([TAIL_BASE, HIPS, SPINE_MID, CHEST], [0.24, 0.3, 0.3, 0.28]), k=0.3, part=B)
    A(Ellipsoid((0, 2.66, 0.3), (0.47 if not creature else 0.43, 0.62, 1.3)), k=0.4, part=B)
    A(Ellipsoid((0, 2.55, -0.62), (0.45 if not creature else 0.41, 0.72, 0.62)), k=0.35, part=B)
    A(Ellipsoid((0, 3.06, -0.66), (0.2, 0.3, 0.55)), k=0.3, part=B)
    A(Ellipsoid((0, 2.86, 1.42), (0.46, 0.5, 0.62)), k=0.32, part=B)
    g.apply(Ellipsoid((0, 1.68, 0.75), (0.8, 0.32, 0.85)), op='sub', k=0.4)
    if creature:   # flancos hundidos detrás de las costillas
        for s in (-1, 1):
            g.apply(Ellipsoid((s * 0.56, 2.45, 0.85), (0.16, 0.38, 0.5)), op='sub', k=0.3)
    for s in (-1, 1):
        A(Ellipsoid((s * 0.3, 2.75, -0.72), (0.2, 0.5, 0.32)), k=0.28, part=B)    # escápula
        A(Ellipsoid((s * 0.31, 2.62, 1.38), (0.24, 0.58, 0.5)), k=0.28, part=B)   # anca
    # cuello (más estrecho de lado) y papada
    A(Chain([N1, N2, N3, ATLAS], [0.4, 0.31, 0.25, 0.21], squash=(0.72, 1.0)), k=0.32, part=PART['Neck'])
    A(Ellipsoid((0, 3.45, -1.6), (0.12, 0.3, 0.12)), k=0.25, part=PART['Neck'])
    # cola corta y plana
    A(Chain([TAIL_BASE, (0, 3.02, 2.5), TAIL_TIP], [0.13, 0.13, 0.07], squash=(1.4, 0.55)), k=0.12, part=PART['Tail'])
    # patas finas con articulaciones marcadas y pezuña hendida
    for name, s, P, R in LEGS:
        part = PART[name]; P = [np.array(p) for p in P]
        for a, b, ra, rb in zip(P[:-1], P[1:], R[:-1], R[1:]):
            A(RoundCone(a, b, ra, rb), k=0.12, part=part)
        A(Ellipsoid(P[2], (0.08, 0.09, 0.085)), k=0.05, part=part)                  # carpo / corvejón
        A(Ellipsoid(P[3] + np.array([0, 0.02, 0.02]), (0.07, 0.075, 0.075)), k=0.04, part=part)
        if 'B' in name:
            A(Ellipsoid(P[2] + np.array([0, 0.05, 0.08]), (0.07, 0.1, 0.07)), k=0.05, part=part)   # punta del corvejón
        hoof = P[4]
        g.apply(RoundCone(P[3] + np.array([0, -0.14, -0.02]), hoof + np.array([0, 0.05, -0.03]), 0.062, 0.072), k=0.04, mat='hoof', part=part)
        g.apply(Box(hoof + np.array([0, 0.06, -0.08]), (0.006, 0.08, 0.06)), op='sub', k=0.01)
        for dx in (-0.04, 0.04):                                                      # espolones
            g.apply(Ellipsoid(P[3] + np.array([dx, -0.03, 0.08]), (0.025, 0.03, 0.03)), k=0.02, mat='hoof', part=part)
    return build_head(g, skin, rng, creature)


def build_head(g, skin, rng, creature):
    Hh, J = PART['Head'], PART['Jaw']
    A = lambda prim, **kw: g.apply(prim, **{'xf': HEAD_XF, 'mat': skin, **kw})
    A(Ellipsoid((0, 0.05, -0.27), (0.23, 0.24, 0.29)), k=0, part=Hh)
    A(RoundCone((0, 0.02, -0.38), (0, -0.1, -1.05), 0.2, 0.095, squash=(0.78, 1.2)), k=0.28, part=Hh)
    A(Ellipsoid((0, -0.12, -1.03), (0.1, 0.115, 0.11)), k=0.1, part=Hh)
    A(RoundCone((0, -0.17, -0.4), (0, -0.22, -0.98), 0.12, 0.07, squash=(0.85, 0.8)), k=0.14, part=J)
    for s in (-1, 1):
        A(Ellipsoid((s * 0.13, -0.08, -0.48), (0.09, 0.13, 0.17)), k=0.14, part=Hh)          # maseteros
        A(Ellipsoid((s * 0.165, 0.12, -0.42), (0.08, 0.06, 0.11)), k=0.1, part=Hh)           # arco de la órbita
    A(Ellipsoid((0, -0.06, -1.12), (0.1, 0.085, 0.06)), op='paint', mat='muzzle')
    for s in (-1, 1):
        A(Ellipsoid((s * 0.045, -0.08, -1.14), (0.02, 0.028, 0.03)), op='sub', k=0.01, carve_mat='muzzle')
    # orejas grandes, planas y cóncavas
    for i, s in enumerate((-1, 1)):
        part = PART['EarL' if s < 0 else 'EarR']
        b0, t0 = np.array(EAR_BASE_L[i]), np.array(EAR_TIP_L[i])
        mid = b0 + (t0 - b0) * 0.45 + np.array([0, 0.07, -0.02])
        A(Chain([b0, mid, t0], [0.08, 0.16, 0.025], squash=(0.32, 1.0)), k=0.06, part=part)
        A(Chain([b0 + np.array([0, 0, -0.05]), mid + np.array([0, 0, -0.06]), t0 + np.array([0, 0, -0.04])], [0.045, 0.12, 0.01], squash=(0.2, 1.0)),
          op='sub', k=0.03, carve_mat='earin')
    pts = {}
    if not creature:
        # boca cerrada: comisura fina
        for s in (-1, 1):
            A(Chain([(0, -0.215, -1.12), (s * 0.08, -0.205, -1.02), (s * 0.13, -0.19, -0.84)], [0.012] * 3), op='sub', k=0.008, carve_mat='muzzle')
    else:
        pts.update(build_maw(g, rng))
    # ojos sobre la piel real
    eyes = []
    for (x, y, z) in EYE_L:
        o = H((x * 4, y, z)); c = H((0, y, z)); hit = surface(g, o, c)
        loc = np.linalg.solve(HEAD_XF.R, (hit - HEAD_XF.t)) if hit is not None else np.array([x, y, z])
        n_out = np.array([np.sign(x), 0.15, -0.25]); n_out /= np.linalg.norm(n_out)
        A(Ellipsoid(loc - n_out * 0.02, (0.07, 0.062, 0.082)), k=0.01, mat='eye', part=Hh)   # ojo grande y saltón
        eyes.append(H(loc + n_out * 0.04))
    pts['eyes'] = [list(map(float, e)) for e in eyes]
    return pts


def deer_paint(g):
    """Zonas de color discretas (la trufa y los ojos); el pelaje usa degradados (deer_colors)."""
    HX = lambda prim, **kw: g.apply(prim, **{'xf': HEAD_XF, **kw})
    HX(Ellipsoid((0, -0.06, -1.12), (0.1, 0.085, 0.06)), op='paint', mat='muzzle')


def _ss(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t)


def deer_colors(v, mat, MAT, MATERIALS):
    """Color sRGB por vértice del pelaje con transiciones suaves, como un ciervo de cola blanca:
    lomo y frente más oscuros, flancos pardos, vientre y cara interna crema, garganta, anillo del ojo,
    banda del hocico, barbilla y bajo la cola blancos, patas algo más grises abajo."""
    fur = np.array(MATERIALS[MAT['fur']][1]); dark = np.array(MATERIALS[MAT['furdark']][1])
    cream = np.array(MATERIALS[MAT['cream']][1]); white = np.array(MATERIALS[MAT['white']][1])
    x, y, z = v[:, 0], v[:, 1], v[:, 2]
    col = np.tile(fur, (len(v), 1))
    torso = _ss(-1.6, -1.2, z) * _ss(2.4, 2.0, z)
    col += (dark - fur) * (_ss(2.85, 3.3, y) * torso)[:, None] * 0.85
    col += (cream - col) * (_ss(2.2, 1.85, y) * torso * _ss(0.5, 0.2, np.abs(x)) ** 0.3)[:, None]
    col += (cream - col) * (_ss(0.31, 0.22, np.abs(x)) * _ss(2.0, 1.7, y) * _ss(0.3, 0.5, y))[:, None] * 0.9
    legs = _ss(1.2, 0.5, y); col += (np.array([0.33, 0.25, 0.19]) - col) * legs[:, None] * 0.6
    # espacio de la cabeza
    L = (v - HEAD_XF.t) @ HEAD_XF.R
    hx, hy, hz = L[:, 0], L[:, 1], L[:, 2]
    head = (np.linalg.norm(L, axis=1) < 1.4)
    def blob(c, r):
        d = np.sqrt(((L - np.array(c)) ** 2 / np.array(r) ** 2).sum(1)); return _ss(1.0, 0.7, d) * head
    col += (dark - col) * (blob((0, 0.18, -0.6), (0.11, 0.1, 0.42)) * 0.8)[:, None]           # frente
    col += (white - col) * (blob((0, -0.06, -0.99), (0.13, 0.12, 0.07)) * 0.65)[:, None]      # banda clara tras la trufa
    col += (white - col) * blob((0, -0.24, -0.93), (0.1, 0.06, 0.14))[:, None]                # barbilla
    for ex, ey, ez in EYE_L:
        d = np.sqrt(((L - np.array([ex * 1.05, ey, ez])) ** 2 / np.array([1.0, 1.0, 1.0])).sum(1))
        col += (white - col) * (_ss(0.115, 0.095, d) * _ss(0.07, 0.085, d) * head * 0.7)[:, None]   # anillo fino alrededor del ojo
    W = HEAD_XF.apply((0, -0.32, -0.15))                                                   # mancha de la garganta
    d = np.sqrt(((v - W) ** 2 / np.array([0.13, 0.15, 0.17]) ** 2).sum(1)); col += (white - col) * (_ss(1.0, 0.7, d) * 0.9)[:, None]
    under_tail = _ss(2.15, 2.3, z) * _ss(3.0, 2.85, y + (z - 2.2) * 0.3) * _ss(0.3, 0.15, np.abs(x)); col += (white - col) * under_tail[:, None]
    keep = np.isin(mat, [MAT['fur'], MAT['furdark'], MAT['cream'], MAT['white']])
    return col, keep


def build_deer(g, rng):
    pts = build_base(g, 'fur', rng)
    deer_paint(g)
    return pts


# ---------------------------------------------------------------- criatura
def build_maw(g, rng):
    """La cabeza se parte por debajo, del hocico a la garganta: interior morado y agujas a los dos lados."""
    Hh, J = PART['Head'], PART['Jaw']
    A = lambda prim, **kw: g.apply(prim, **{'xf': HEAD_XF, **kw})
    gape = lambda x: -0.2 + 0.0 * x
    line = []
    for s in (-1, 1):
        line.append([(s * 0.03, -0.205, -1.12), (s * 0.095, -0.2, -0.95), (s * 0.14, -0.19, -0.7), (s * 0.15, -0.2, -0.45), (s * 0.11, -0.23, -0.2), (s * 0.04, -0.27, 0.02)])
        A(Chain(line[-1], [0.035] * 6), op='sub', k=0.02, carve_mat='gullet')
    A(Ellipsoid((0, -0.19, -0.62), (0.1, 0.055, 0.5)), op='sub', k=0.04, carve_mat='gullet')   # interior hueco
    # agujas: arriba hacia abajo (Head) y abajo hacia arriba (Jaw), largas y desordenadas
    for L_ in line:
        P = np.array([np.array(p) for p in L_])
        Ls = np.r_[0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]
        for u in np.linspace(0.03, Ls[-1] - 0.03, 34):
            i = max(0, min(np.searchsorted(Ls, u) - 1, len(P) - 2)); f = (u - Ls[i]) / (Ls[i + 1] - Ls[i])
            q = P[i] * (1 - f) + P[i + 1] * f
            side = np.array([np.sign(q[0]) * 0.02, 0, 0])
            L = 0.07 + 0.11 * rng.random() ** 1.4; tw = rng.uniform(-0.03, 0.03, 3)
            top = q + np.array([0, 0.03, 0]) + side
            A(horn(top, top + np.array([0, -L * 0.5, 0]) + tw, top + np.array([0, -L, 0]) + tw * 2, 0.012, n=4, r_tip=0.003), k=0.004, mat='needle', part=Hh)
            L = 0.06 + 0.1 * rng.random() ** 1.4; tw = rng.uniform(-0.03, 0.03, 3)
            bot = q + np.array([0, -0.03, 0]) + side
            A(horn(bot, bot + np.array([0, L * 0.5, 0]) + tw, bot + np.array([0, L, 0]) + tw * 2, 0.011, n=4, r_tip=0.003), k=0.004, mat='needle', part=J)

    def below(x, y, z):   # mandíbula: todo lo que queda por debajo de la línea de apertura
        return np.maximum(np.maximum(y + 0.21, z - 0.08), -z - 1.3)
    g.apply(Field(below, (-0.5, -0.6, -1.3), (0.5, 0.0, 0.1)), op='label', part=J, xf=HEAD_XF)
    return {}


def build_creature(g, rng):
    pts = build_base(g, 'pale', rng, creature=True)
    B = PART['Body']
    # costillas bajo la piel y vértebras que asoman
    for z in np.arange(-0.9, 0.75, 0.27):
        for s in (-1, 1):
            arc = []
            for a in np.radians(np.linspace(70, -55, 7)):
                d = np.array([s * np.cos(a), np.sin(a), 0]); c = np.array([0, 2.55, z])
                hit = surface(g, c + d * 2.0, c)
                if hit is None or np.linalg.norm(hit - c) > 1.2: arc = []; continue
                arc.append(hit + d * 0.01)
            if len(arc) >= 3: g.apply(Chain(arc, [0.026] * len(arc)), k=0.05, mat='pale', part=B)
    path = np.array([TAIL_BASE, HIPS, SPINE_MID, CHEST])
    for t in np.linspace(0.05, 0.95, 16):
        seg = t * 3; i = min(int(seg), 2); f = seg - i; p = path[i] * (1 - f) + path[i + 1] * f
        hit = surface(g, p + np.array([0, 1.0, 0]), p)
        if hit is not None: g.apply(Ellipsoid(hit, (0.08, 0.06, 0.08)), k=0.04, mat='pale', part=B)
    # ojos abiertos en el pecho y los hombros
    eye_pts = []
    for (dirv, c) in (((-0.35, 0.1, -1), (0, 2.6, -0.6)), ((0.35, 0.1, -1), (0, 2.6, -0.6)), ((-1, 0.25, -0.35), (0, 2.75, -0.75)), ((1, 0.3, -0.2), (0, 2.6, -0.45)), ((-0.15, -0.3, -1), (0, 2.2, -0.6))):
        d = np.array(dirv, float); d /= np.linalg.norm(d); c = np.array(c, float)
        hit = surface(g, c + d * 2.5, c)
        if hit is None: continue
        g.apply(Ellipsoid(hit, (0.17, 0.17, 0.17)), k=0.06, mat='pale', part=B)                    # párpados hinchados
        g.apply(Ellipsoid(hit + d * 0.15, (0.12, 0.12, 0.12)), op='sub', k=0.02, carve_mat='white')
        g.apply(Ellipsoid(hit + d * 0.02, (0.105, 0.105, 0.105)), k=0.008, mat='white', part=B)   # globo
        g.apply(Ellipsoid(hit + d * 0.075, (0.065, 0.065, 0.065)), k=0.006, mat='eye', part=B)    # iris negro
        eye_pts.append(list(map(float, hit + d * 0.13)))
    # cuello de cordones de carne retorcidos
    neck = [np.array(p, float) for p in (N1, N2, N3, ATLAS)]
    g.apply(Chain(neck, [0.44, 0.34, 0.28, 0.24], squash=(0.76, 1.02)), op='paint', mat='sinew')
    for j in range(16):
        ph = j / 16 * 2 * np.pi + rng.uniform(-0.2, 0.2); strand = []; rr = []; twist = rng.uniform(1.6, 3.2)
        for t in np.linspace(0, 1, 9):
            seg = t * 3; i = min(int(seg), 2); f = seg - i
            c = neck[i] * (1 - f) + neck[i + 1] * f
            r = [0.4, 0.31, 0.25, 0.21][i] * (1 - f) + [0.31, 0.25, 0.21, 0.18][i] * f
            ax = neck[min(i + 1, 3)] - neck[i]; ax /= np.linalg.norm(ax)
            side = np.cross([0, 1, 0], ax); side /= np.linalg.norm(side); up = np.cross(ax, side)
            a = ph + t * twist + 0.25 * np.sin(t * 9 + j)
            strand.append(c + (side * np.cos(a) * 0.74 + up * np.sin(a)) * r * 1.1); rr.append((0.08 + 0.06 * rng.random()) * (1.0 - 0.3 * t))
        g.apply(Chain(strand, rr), k=0.025, mat='sinewpale' if j % 5 == 0 else ('tendril' if j % 2 else 'sinew'), part=PART['Neck'])
    # collar de dientes donde el cuello entra en el cuerpo
    c0 = np.array(N1) + np.array([0, 0.14, -0.1]); ax = np.array(N2) - np.array(N1); ax /= np.linalg.norm(ax)
    side = np.cross([0, 1, 0], ax); side /= np.linalg.norm(side); up = np.cross(ax, side)
    g.apply(Chain([c0 + (side * np.cos(a) * 0.82 + up * np.sin(a)) * 0.46 for a in np.linspace(0, 2 * np.pi, 25)], [0.05] * 25), k=0.05, mat='gullet', part=B)
    for a in np.linspace(0, 2 * np.pi, 30, endpoint=False):
        rdir = side * np.cos(a) * 0.82 + up * np.sin(a); base = c0 + rdir * 0.46
        L = 0.12 + 0.08 * rng.random()
        g.apply(horn(base, base + ax * L * 0.6 + rdir * 0.03, base + ax * L + rdir * 0.05, 0.022, n=4, r_tip=0.004), k=0.008, mat='needle', part=B)
    # cráneo más huesudo
    g.apply(Ellipsoid((0, 0.1, -0.3), (0.24, 0.23, 0.26)), xf=HEAD_XF, k=0.08, mat='pale', part=PART['Head'])
    pts['chest_eyes'] = eye_pts
    return pts


# ---------------------------------------------------------------- cuernas y tentáculos
def build_antlers(g, rng):
    pts = []
    for i, s in enumerate((-1, 1)):
        b = H(ANTLER_BASE_L[i])
        g.apply(Ellipsoid(b, (0.06, 0.05, 0.06)), k=0.02, mat='antler', part=PART['Antler'])   # roseta
        # rama principal: sale hacia fuera y atrás y se curva hacia delante
        beam = bezier(b, b + np.array([s * 0.55, 0.65, 0.45]), b + np.array([s * 0.55, 1.05, -0.45]), 12)
        g.apply(Chain(list(beam), list(np.linspace(0.055, 0.022, 12))), k=0.02, mat='antler', part=PART['Antler'])
        # candil de la frente y puntas hacia arriba
        g.apply(horn(b + np.array([s * 0.03, 0.06, 0]), b + np.array([s * 0.08, 0.25, -0.12]), b + np.array([s * 0.05, 0.42, -0.2]), 0.03, n=5, r_tip=0.008), k=0.015, mat='antler', part=PART['Antler'])
        for t, h in ((0.45, 0.42), (0.68, 0.36), (0.86, 0.25)):
            k_ = int(t * 11); p = beam[k_]
            g.apply(horn(p, p + np.array([s * 0.03, h * 0.6, -0.05]), p + np.array([s * 0.06, h, 0.02]), 0.032, n=5, r_tip=0.008), k=0.015, mat='antler', part=PART['Antler'])
        pts.append(list(map(float, b)))
    return pts


TENTACLES = []   # (raíz dentro del cráneo, puntos de la curva) en espacio mundo, para huesos y pesos
def tentacle_curves(rng):
    out = []
    roots = [(-0.1, 0.22, -0.32), (0.1, 0.22, -0.32), (0.0, 0.28, -0.12), (-0.2, 0.16, -0.08), (0.2, 0.16, -0.08), (-0.06, 0.12, -0.62), (0.07, 0.12, -0.6)]
    for n, r in enumerate(roots):
        r = np.array(r, float); out_dir = head_frame_dir((r[0] * 3.5, 1.0, r[2] * 0.6 + 0.1)); out_dir /= np.linalg.norm(out_dir)
        out_dir = out_dir + np.array([0, 0.7, 0.35]); out_dir /= np.linalg.norm(out_dir)   # más hacia arriba que hacia delante
        inner = H(r * 0.4)                       # raíz bien dentro del cráneo
        base = H(r)
        L = 2.0 + 0.6 * rng.random()
        wob = rng.normal(0, 0.5, 3); wob2 = rng.normal(0, 0.6, 3)
        p1 = base + out_dir * L * 0.35 + wob * 0.4
        p2 = base + out_dir * L * 0.7 + wob2 * 0.5 + np.array([np.sign(r[0] + 1e-3) * 0.3, 0, 0])
        p3 = base + out_dir * L + (wob + wob2) * 0.35
        curve = np.concatenate([bezier(base, p1, (p1 + p2) / 2, 8), bezier((p1 + p2) / 2, p2, p3, 8)[1:]])
        out.append((inner, curve))
    return out


def build_tentacles(g, rng):
    curves = tentacle_curves(rng)
    for n, (inner, curve) in enumerate(curves):
        m = len(curve); radii = 0.016 + 0.08 * np.linspace(1, 0, m) ** 1.3
        # parte por segmentos (1 = dentro del cráneo, 2-4 = tercios de la curva)
        g.apply(RoundCone(inner, curve[0], 0.06, 0.075), k=0.02, mat='tendril', part=TENT_PART0 + 10 * n + 1)
        for k in range(m - 1):
            seg = 2 + min(2, int(3 * k / (m - 1)))
            g.apply(RoundCone(curve[k], curve[k + 1], radii[k], radii[k + 1]), k=0.02, mat='tendril', part=TENT_PART0 + 10 * n + seg)
        # ramitas laterales (como astas de carne)
        for k in (m // 3, 2 * m // 3):
            p = curve[k]; d = rng.normal(0, 1, 3); d /= np.linalg.norm(d)
            seg = 2 + min(2, int(3 * k / (m - 1)))
            g.apply(horn(p, p + d * 0.2, p + d * 0.35 + np.array([0, 0.15, 0]), 0.03, n=4, r_tip=0.006), k=0.015, mat='tendril', part=TENT_PART0 + 10 * n + seg)
    return curves
