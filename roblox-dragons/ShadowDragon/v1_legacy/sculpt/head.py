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
    A(Chain(list(P + N2 * 0.17 + face_n * 0.02), [0.05] * len(P)), k=0.04, mat='lip', part=H)        # labio superior
    A(Chain(list(P - N2 * 0.17 + face_n * 0.02), [0.05] * len(P)), k=0.04, mat='lip', part=J)        # labio inferior
    for i in range(len(P) - 1):
        for f in ((0.0,) if i % 3 else (0.0, 0.5)):
            q = P[i] + (P[i + 1] - P[i]) * f; n2 = N2[i]
            tw = (P[i + 1] - P[i]) / max(np.linalg.norm(P[i + 1] - P[i]), 1e-6) * rng.uniform(-0.35, 0.35)
            L = 0.2 + 0.3 * rng.random() ** 1.3
            up = q + n2 * 0.15 + face_n * 0.03
            A(horn(up, up - (n2 + tw) * L * 0.5 + face_n * 0.04, up - (n2 + tw) * L, 0.024, n=4), k=0.008, mat='needle', part=H)
            lo = q - n2 * 0.15 + face_n * 0.03 + (P[i + 1] - P[i]) * 0.25
            L = 0.18 + 0.28 * rng.random() ** 1.3
            A(horn(lo, lo + (n2 - tw) * L * 0.5 + face_n * 0.03, lo + (n2 - tw) * L, 0.019, n=4), k=0.008, mat='needle', part=J)

    # --- mandíbula: todo lo que queda por debajo de la sonrisa en la cara ---
    def below(x, y, z):
        return np.maximum(np.maximum(y - mouth_y(x) + 0.02, z + 0.25), np.abs(x) - 1.35)
    A(Field(below, (-1.7, -3.0, -2.8), (1.7, 0.6, 0.0)), op='label', part=J)

    # --- puntos de los ojos: pequeñas fosas; la luz la pone Roblox ---
    eyes = []
    for (x, y) in EYE_LOCAL:
        hit = surface(g, X.apply((x, y, -4.0)), X.apply((x, y, 0.5)))
        loc = Xinv(hit) if hit is not None else np.array([x, y, -1.5])
        A(Ellipsoid(loc, (0.075, 0.075, 0.075)), op='sub', k=0.02, carve_mat='socket')
        eyes.append(X.apply(loc + face_n * 0.03))
    return {'eyes': [list(map(float, e)) for e in eyes], 'chin': list(map(float, X.apply(CHIN))),
            'hinge': list(map(float, X.apply(HINGE))), 'snout': list(map(float, X.apply(SNOUT)))}
