"""Cabeza del Dragón Sombrío, según la referencia de la cara (sonrisa en la oscuridad).

Espacio local: Y arriba, la cara mira a -Z, nuca en z = 0.
  · cráneo negro y redondeado con un gran domo estriado (mechones/humo) sobre la frente
  · cara que se estrecha hacia una barbilla en punta (forma de V)
  · sonrisa enorme de oreja a oreja: labios rojos y agujas blancas apretadas arriba y abajo
  · dos puntos rojos pequeños y separados (no son globos oculares: luz en Roblox)
  · puntas laterales como orejas
La mandíbula (todo lo que queda por debajo de la sonrisa) es una parte propia para animarla.
"""
import numpy as np
from sdf import Ellipsoid, RoundCone, Chain, Xf, Field, horn, rot, bezier

PART = {'Head': 1, 'Jaw': 2, 'Tongue': 3, 'Drool': 4, 'Neck': 5}
JAW_OPEN = 0.0
HINGE = np.array([0.0, 0.0, -0.7])
CHIN = np.array([0.0, -2.3, -1.65])
TONGUE = ((0.0, -0.9, -0.9), (0.0, -1.0, -1.2))
SNOUT = (0.0, -0.4, -1.8)
EYE_LOCAL = [(0.66, 0.55), (-0.66, 0.55)]           # (x, y) en la cara; z se busca sobre la piel


def mouth_y(x):
    return -1.85 + 2.0 * (np.abs(x) / 1.25) ** 1.45


def surface(g, p_out, p_in, n=400):
    p_out, p_in = np.asarray(p_out, float), np.asarray(p_in, float)
    for t in np.linspace(0, 1, n):
        p = p_out + (p_in - p_out) * t
        i = np.round((p - g.lo) / g.h).astype(int)
        if np.any(i < 0) or np.any(i >= g.n): continue
        if g.d[i[0], i[1], i[2]] < 0: return p
    return None


def build(g, X, rng):
    """Esculpe la cabeza. Devuelve puntos útiles en espacio mundo (ojos, barbilla)."""
    H, J = PART['Head'], PART['Jaw']
    A = lambda prim, **kw: g.apply(prim, **{'xf': X, **kw})
    Xinv = lambda p: np.linalg.solve(X.R, (np.asarray(p) - X.t) / X.s)

    # --- cráneo, domo y cara en V ---
    A(Ellipsoid((0, 0.55, -0.35), (1.45, 1.35, 1.3)), k=0, part=H, mat='shadow')
    A(RoundCone((0, 0.3, -0.85), (0, -2.25, -1.6), 1.18, 0.22, squash=(0.7, 1.22)), k=0.45, part=H, mat='shadow')
    for s in (1, -1):
        A(Ellipsoid((s * 0.92, -0.45, -0.9), (0.42, 0.75, 0.48)), k=0.35, part=H, mat='shadow')
        A(horn((s * 1.35, 0.45, -0.3), (s * 2.0, 0.75, 0.05), (s * 2.3, 1.4, 0.25), 0.21), k=0.12, mat='horn', part=H)
        A(horn((s * 1.25, -0.4, -0.5), (s * 1.8, -0.5, -0.2), (s * 2.1, -0.32, 0.25), 0.12), k=0.08, mat='horn', part=H)
    # estrías del domo, como mechones de humo, y púas que caen hacia atrás
    for x in np.linspace(-1.05, 1.05, 9):
        A(Chain(list(bezier((x * 0.8, 1.15, -1.0), (x, 2.05, -0.2), (x * 1.15, 0.95, 1.0), 7)), [0.1, 0.14, 0.15, 0.14, 0.12, 0.1, 0.08]), k=0.14, part=H, mat='shadow')
    for x in (-0.7, -0.25, 0.25, 0.7):
        A(horn((x, 1.45, 0.5), (x * 1.3, 1.35, 1.7), (x * 1.5, 0.55, 2.7), 0.15), k=0.1, mat='horn', part=H)
    # melena: mechones gruesos que nacen sobre la frente, se hinchan en un domo y caen hacia atrás
    for x in np.linspace(-1.3, 1.3, 14):
        j = rng.uniform(-0.15, 0.15, 3)
        pts = bezier((x * 0.65, 1.35, -1.15), (x * 1.25 + j[0], 3.3 + j[1], -0.2), (x * 1.7 + j[2], 0.5 - abs(x) * 0.6, 3.0), 9)
        A(Chain(list(pts), [0.12, 0.2, 0.27, 0.29, 0.27, 0.22, 0.16, 0.1, 0.04]), k=0.05, part=H, mat='shadow')

    # ceño: crestas óseas inclinadas hacia el centro y mejillas hundidas
    for s in (1, -1):
        A(Chain([(s * 0.22, 0.72, -1.55), (s * 0.62, 0.86, -1.45), (s * 1.05, 1.08, -1.15)], [0.09, 0.13, 0.08]), k=0.12, part=H, mat='shadow')
        A(Ellipsoid((s * 0.82, -0.1, -1.45), (0.3, 0.45, 0.25)), op='sub', k=0.25)
    # --- la sonrisa: puntos sobre la piel real de la cara ---
    xs = np.linspace(-1.25, 1.25, 45)
    P = []
    for x in xs:
        y = mouth_y(x); hit = surface(g, X.apply((x, y, -4.0)), X.apply((x, y, 0.5)))
        P.append(Xinv(hit) if hit is not None else np.array([x, y, -1.4]))
    P = np.array(P)
    T = np.gradient(P, axis=0); T /= np.linalg.norm(T, axis=1, keepdims=True)
    face_n = np.array([0, 0, -1.0])
    N2 = np.cross(face_n, T); N2[N2[:, 1] < 0] *= -1             # perpendicular a la sonrisa, hacia arriba
    N2 /= np.linalg.norm(N2, axis=1, keepdims=True)
    A(Chain(list(P - face_n * 0.05), [0.14] * len(P)), op='sub', k=0.03, carve_mat='gum')        # boca entreabierta: interior granate
    # labios: grosor irregular, como carne retraída y cuarteada
    lw = 0.045 + 0.02 * np.abs(np.sin(np.arange(len(P)) * 1.7)) * rng.uniform(0.6, 1.2, len(P))
    A(Chain(list(P + N2 * 0.17 + face_n * 0.02), list(lw)), k=0.04, mat='lip', part=H)        # labio superior
    A(Chain(list(P - N2 * 0.17 + face_n * 0.035), list(lw * 1.1)), k=0.04, mat='lip', part=J)   # labio inferior, algo adelantado
    # dientes irregulares: largos y grosores distintos, torcidos, rotos, algunos que faltan y colmillos sueltos
    fang_up = set(rng.choice(np.arange(3, len(P) - 4), 5, replace=False).tolist())
    fang_lo = set(rng.choice(np.arange(3, len(P) - 4), 4, replace=False).tolist())
    def tooth(root, d, L, r, part, broken):
        d = d / np.linalg.norm(d)
        if broken:   # roto: tocón romo y astillado
            A(RoundCone(root, root + d * L * 0.45, r * 1.15, r * 0.8), k=0.008, mat='needle', part=part)
        else:
            bend = np.cross(d, face_n) * rng.uniform(-0.12, 0.12)
            A(horn(root, root + d * L * 0.5 + face_n * 0.04 + bend * L, root + d * L, r, n=4), k=0.008, mat='needle', part=part)
        A(Ellipsoid(root - d * 0.02, (r * 2.2, r * 2.2, r * 2.0)), k=0.03, mat='gum', part=part)   # encía hinchada en la raíz
    for i in range(len(P) - 1):
        for f in ((0.0,) if i % 3 else (0.0, 0.5)):
            q = P[i] + (P[i + 1] - P[i]) * f; n2 = N2[i]
            T_ = (P[i + 1] - P[i]) / max(np.linalg.norm(P[i + 1] - P[i]), 1e-6)
            if rng.random() > 0.1:                     # ~10 % de huecos arriba
                tw = T_ * rng.uniform(-0.6, 0.6)
                fang = i in fang_up and f == 0.0
                L = (0.5 + 0.2 * rng.random()) if fang else 0.16 + 0.34 * rng.random() ** 1.3
                r = (0.04 if fang else 0.017 + 0.016 * rng.random())
                up = q + n2 * 0.15 + face_n * 0.03
                tooth(up, -(n2 + tw), L, r, H, broken=(not fang and rng.random() < 0.12))
            if rng.random() > 0.12:
                tw = T_ * rng.uniform(-0.6, 0.6)
                fang = i in fang_lo and f == 0.0
                lo = q - n2 * 0.15 + face_n * 0.04 + (P[i + 1] - P[i]) * 0.25
                L = (0.45 + 0.2 * rng.random()) if fang else 0.15 + 0.3 * rng.random() ** 1.3
                r = (0.036 if fang else 0.014 + 0.014 * rng.random())
                tooth(lo, n2 - tw, L, r, J, broken=(not fang and rng.random() < 0.12))
    # segunda fila, más corta y desordenada, detrás de los dientes del frente
    for i in range(int(len(P) * 0.3), int(len(P) * 0.7), 2):
        q = P[i] - face_n * 0.12; n2 = N2[i]; tw = rng.uniform(-0.5, 0.5, 3) * 0.3
        tooth(q + n2 * 0.11, -(n2 + tw), 0.12 + 0.12 * rng.random(), 0.014, H, broken=False)
        tooth(q - n2 * 0.11, n2 - tw, 0.1 + 0.1 * rng.random(), 0.012, J, broken=False)

    # --- mandíbula más intimidante: barbilla larga y adelantada, crestas óseas a los lados ---
    A(RoundCone((0, -2.25, -1.35), (0, -2.75, -1.75), 0.3, 0.16, squash=(0.85, 1.0)), k=0.3, part=J, mat='shadow')
    for s in (1, -1):
        ridge = [(s * 1.12, -0.95, -0.75), (s * 0.95, -1.45, -1.25), (s * 0.6, -2.0, -1.62), (s * 0.22, -2.45, -1.85)]
        A(Chain(ridge, [0.07, 0.1, 0.09, 0.06]), k=0.1, part=J, mat='shadow')
        for t in (0.25, 0.55, 0.8):                      # pequeños nudos de hueso en la cresta
            p_ = np.array(ridge[0]) + (np.array(ridge[-1]) - np.array(ridge[0])) * t + np.array([s * 0.05, -0.04, -0.02])
            A(horn(p_, p_ + np.array([s * 0.1, -0.06, 0.02]), p_ + np.array([s * 0.2, -0.16, 0.05]), 0.035, n=3), k=0.02, mat='horn', part=J)
    A(horn((0, -2.7, -1.75), (0, -3.0, -1.8), (0, -3.3, -1.6), 0.06, n=4), k=0.04, mat='horn', part=J)   # púa del mentón

    # --- mandíbula: todo lo que queda por debajo de la sonrisa en la cara ---
    def below(x, y, z):
        return np.maximum(np.maximum(y - mouth_y(x) + 0.02, z + 0.25), np.abs(x) - 1.35)
    A(Field(below, (-1.7, -3.4, -2.8), (1.7, 0.6, 0.0)), op='label', part=J)

    # --- puntos de los ojos: pequeñas fosas; la luz la pone Roblox ---
    eyes = []
    for (x, y) in EYE_LOCAL:
        hit = surface(g, X.apply((x, y, -4.0)), X.apply((x, y, 0.5)))
        loc = Xinv(hit) if hit is not None else np.array([x, y, -1.5])
        n_out = face_n                                   # face_n apunta hacia fuera de la cara (-Z)
        A(Ellipsoid(loc - face_n * 0.03, (0.12, 0.1, 0.11)), op='sub', k=0.05, carve_mat='socket')   # cuenca honda
        A(Chain([loc + n_out * 0.02 + np.array([-0.17, 0.11, 0]), loc + n_out * 0.04 + np.array([0, 0.15, 0]), loc + n_out * 0.02 + np.array([0.17, 0.11, 0])], [0.035, 0.05, 0.035]), k=0.05, mat='horn', part=H)
        eyes.append(X.apply(loc - face_n * 0.04))   # el punto de luz queda dentro de la cuenca
    return {'eyes': [list(map(float, e)) for e in eyes], 'chin': list(map(float, X.apply(CHIN))),
            'hinge': list(map(float, X.apply(HINGE))), 'snout': list(map(float, X.apply(SNOUT)))}
