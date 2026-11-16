"""Deformidad y podredumbre del Dragón Depredador (se aplica después de gore.py).

  · tumores que deforman la mandíbula derecha y un cuerno torcido que le brota de la mejilla
  · cráneo pelado con el hueso a la vista; media cresta rota
  · joroba: vértebras que rompen la piel del lomo; costillas astilladas que salen del flanco
  · segunda boca: una herida vertical en el flanco derecho con labios y dientes
  · decenas de tajos abiertos repartidos por todo el cuerpo (músculo, sangre, goteos)
  · manchas de podredumbre verdosa con pústulas de pus
  · tramo de la cola descarnado hasta las vértebras; antebrazo izquierdo con el hueso expuesto

Todo se coloca sobre la piel real (rayo contra el campo de distancia) y se orienta con la normal de la superficie.
"""
import numpy as np
from sdf import Ellipsoid, RoundCone, Chain, Xf, horn, rot
import head as HEAD
import body as BODY
from gore import surface, drip

BP = BODY.PART['Body']; HP = HEAD.PART['Head']; JP = HEAD.PART['Jaw']


def sample(g, p):
    i = np.clip(np.round((np.asarray(p) - g.lo) / g.h).astype(int), 1, g.n - 2)
    return i


def normal(g, p):
    """Normal de la piel en p (gradiente del campo de distancia)."""
    i = sample(g, p); d = g.d
    n = np.array([d[i[0] + 1, i[1], i[2]] - d[i[0] - 1, i[1], i[2]], d[i[0], i[1] + 1, i[2]] - d[i[0], i[1] - 1, i[2]], d[i[0], i[1], i[2] + 1] - d[i[0], i[1], i[2] - 1]], float)
    l = np.linalg.norm(n); return n / l if l > 1e-6 else np.array([0, 1.0, 0])


def spine_at(z):
    pts = np.array([p for p, _ in BODY.SPINE]); rad = np.array([r for _, r in BODY.SPINE])
    k = np.argsort(pts[:, 2]); return np.array([np.interp(z, pts[k, 2], pts[k, 0]), np.interp(z, pts[k, 2], pts[k, 1]), z]), np.interp(z, pts[k, 2], rad[k])


def body_point(g, z, ang):
    """Punto de la piel del cuerpo a la altura z, en el ángulo ang alrededor de la columna (0 = derecha, 90 = lomo)."""
    c, r = spine_at(z); d = np.array([np.cos(ang), np.sin(ang), 0.0])
    return surface(g, c + d * (r + 3.0), c)


def gash(g, p, rng, length=None, width=None, bleed=True):
    """Tajo abierto: corte alargado tangente a la piel, con músculo expuesto, halo de sangre y goteo."""
    n = normal(g, p); t = np.cross(n, rng.normal(size=3)); t /= np.linalg.norm(t)
    L = (length or rng.uniform(0.9, 1.9)) * 1.25; w = width or rng.uniform(0.07, 0.12)
    a, b = p - t * L / 2 - n * 0.06, p + t * L / 2 - n * 0.06
    g.apply(RoundCone(a, b, w, w * 0.6), op='sub', k=0.03, carve_mat='muscle')
    for q in (a + (b - a) * 0.3, a + (b - a) * 0.7):   # labios de piel desgarrada a los lados
        for sgn in (1, -1):
            side = np.cross(n, t); g.apply(Ellipsoid(q + side * sgn * w * 1.3 + n * 0.02, (w * 0.7, w * 0.7, w * 0.7)), k=0.04, mat='wound', part=BP)
    g.apply(RoundCone(a + n * 0.05, b + n * 0.05, w * 2.0, w * 1.4), op='paint', mat='blood')
    if bleed and n[1] < 0.6 and rng.random() < 0.7:
        drip(g, p + np.array([0, -w, 0]), rng.uniform(0.5, 1.4), rng, 0.05)


def growth(g, p, size, rng, pus=True, part=BP):
    """Racimo de tumores/pústulas sobre la piel."""
    n = normal(g, p)
    g.apply(Ellipsoid(p + n * size * 0.2, (size, size, size)), k=size * 0.5, mat='rot', part=part)
    for _ in range(int(4 + size * 10)):
        r3 = rng.normal(size=3); r3 -= n * (r3 @ n)
        q = p + r3 * size * 0.75 + n * size * 0.15
        s = size * rng.uniform(0.25, 0.55)
        g.apply(Ellipsoid(q, (s, s, s)), k=s * 0.5, mat='pus' if pus and rng.random() < 0.35 else 'rot', part=part)


def apply(g, rng):
    X = BODY.HEAD_XF
    XJ = X @ Xf.about(HEAD.HINGE, rot((1, 0, 0), HEAD.JAW_OPEN))
    A = lambda prim, xf=X, **kw: g.apply(prim, xf=xf, **kw)

    # ---------- cabeza deforme ----------
    A(Ellipsoid((0.98, -0.85, -1.7), (0.5, 0.45, 0.7)), xf=XJ, k=0.25, mat='rot', part=JP)          # mandíbula hinchada
    for c, r in [((1.2, -0.7, -1.2), 0.22), ((1.05, -1.15, -2.0), 0.18), ((1.3, -0.95, -2.3), 0.14), ((0.85, -1.2, -1.3), 0.16)]:
        A(Ellipsoid(c, (r, r, r)), xf=XJ, k=0.08, mat='pus' if r < 0.17 else 'rot', part=JP)
    A(horn((1.25, -0.05, -2.0), (2.05, 0.15, -2.55), (2.3, 1.0, -2.15), 0.2, n=7), k=0.1, mat='horn', part=HP)   # cuerno que brota de la mejilla
    A(horn((1.05, 0.3, -3.0), (1.5, 0.2, -3.4), (1.7, -0.25, -3.3), 0.11, n=5), k=0.06, mat='horn', part=HP)
    A(Ellipsoid((0.3, 1.12, -1.25), (0.5, 0.14, 0.75)), op='sub', k=0.06, carve_mat='bone')           # cráneo pelado
    A(Ellipsoid((-0.55, 0.95, -2.6), (0.28, 0.1, 0.4)), op='sub', k=0.05, carve_mat='bone')
    # pústulas hundidas en la piel de la cabeza (colocadas con un rayo, nunca flotando)
    for c in [(0.55, 3.0, -3.4), (-0.5, 3.0, -3.9), (0.95, 3.0, -0.6), (-0.95, 3.0, -0.4)]:
        top = surface(g, X.apply(c), X.apply((c[0], -0.5, c[2])))
        if top is not None:
            g.apply(Ellipsoid(top - np.array([0, 0.04, 0]), (0.13, 0.08, 0.13)), k=0.06, mat='pus', part=HP)
            g.apply(Ellipsoid(top, (0.3, 0.3, 0.3)), op='paint', mat='rot')

    # ---------- media cresta rota: muñones de púas sobre el cuello ----------
    for z in (-15.5, -14.6, -13.2):
        c, r = spine_at(z); p = c + np.array([0, r * 0.95, 0])
        g.apply(RoundCone(p, p + np.array([0.05, 0.45, 0.2]), 0.22, 0.18), k=0.08, mat='bone', part=BP)

    # ---------- joroba: vértebras que rompen la piel del lomo ----------
    for z in np.linspace(-9.5, -1.0, 8):
        c, r = spine_at(z); p = c + np.array([0.0, r * 0.9, 0])
        g.apply(Ellipsoid(p + np.array([0, 0.35, 0]), (0.6, 0.45, 0.4)), k=0.25, mat='bone', part=BP)
        g.apply(horn(p + np.array([0, 0.5, 0]), p + np.array([0.05, 1.1, 0.15]), p + np.array([0.12, 1.6, 0.5]), 0.2, n=5), k=0.06, mat='bone', part=BP)
        g.apply(Ellipsoid(p + np.array([0, 0.2, 0]), (0.85, 0.3, 0.6)), op='paint', mat='muscle')

    # ---------- costillas astilladas saliendo del flanco derecho ----------
    for i, z in enumerate((-7.2, -6.4, -5.5)):
        p = body_point(g, z, np.radians(-10 + i * 12))
        if p is None: continue
        n = normal(g, p); d = n + np.array([0, -0.2, 0.3]); d /= np.linalg.norm(d)
        g.apply(horn(p - n * 0.4, p + d * 0.5, p + d * (1.1 + 0.3 * i), 0.11, n=5), k=0.04, mat='bone', part=BP)
        g.apply(Ellipsoid(p, (0.35, 0.35, 0.35)), op='sub', k=0.05, carve_mat='muscle')

    # ---------- segunda boca en el flanco derecho ----------
    p = body_point(g, -1.6, np.radians(5))
    if p is not None:
        n = normal(g, p); up = np.array([0, 1.0, 0]); up -= n * (up @ n); up /= np.linalg.norm(up)
        side = np.cross(up, n)
        g.apply(Ellipsoid(p - n * 0.2, (0.62, 1.55, 0.55)), op='sub', k=0.1, carve_mat='flesh')
        for s in (1, -1):   # labios
            lip = [p + up * 1.4, p + side * s * 0.5 + n * 0.1, p - up * 1.4]
            g.apply(Chain(lip, [0.08, 0.17, 0.08]), k=0.08, mat='gum', part=BP)
            for k in range(9):
                q = p + up * (1.15 - k * 0.29) + side * s * (0.44 - abs(k - 4) * 0.04) + n * 0.03
                g.apply(horn(q, q - side * s * 0.16 + n * 0.06, q - side * s * 0.38, 0.06, n=4), k=0.015, mat='teeth', part=BP)
        drip(g, p - up * 1.45, 1.3, rng, 0.07)
        g.apply(Ellipsoid(p, (0.9, 1.9, 0.9)), op='paint', mat='blood')

    # ---------- decenas de tajos abiertos ----------
    n_ok = 0
    for _ in range(60):
        z = rng.uniform(-17.5, 16.0); ang = rng.uniform(-60, 240)
        if -10.5 < z < -8.0 and (ang < 40 or ang > 140): continue   # deja libre la raíz de las patas delanteras
        p = body_point(g, z, np.radians(ang))
        if p is None: continue
        gash(g, p, rng, length=rng.uniform(0.6, 1.5) * (0.6 if z > 8 else 1.0)); n_ok += 1
        if n_ok >= 34: break
    # patas: tajos en muslos y antebrazos
    for name, s, P, R in BODY.LEGS:
        mid = (np.array(P[0]) + np.array(P[1])) / 2
        p = surface(g, mid + np.array([s * 4.0, 0, 0]), mid)
        if p is not None: gash(g, p, rng, length=0.9)

    # ---------- podredumbre y pústulas ----------
    for z, ang, size in [(-13.0, 200, 0.42), (-11.5, 120, 0.35), (-3.5, 210, 0.5), (2.5, 60, 0.38), (6.5, 160, 0.3), (10.5, 20, 0.26), (-6.5, 95, 0.32)]:
        p = body_point(g, z, np.radians(ang))
        if p is None: continue
        g.apply(Ellipsoid(p, (size * 2.6, size * 2.6, size * 2.6)), op='paint', mat='rot')
        growth(g, p, size, rng)

    # ---------- cola descarnada hasta las vértebras ----------
    for z0 in (9.0,):
        c, r = spine_at(z0 + 0.8)
        g.apply(Ellipsoid(c, (r * 1.15, r * 1.15, 1.0)), op='sub', k=0.12, carve_mat='muscle')
        for k in range(4):
            cz, rz = spine_at(z0 + k * 0.5)
            g.apply(Ellipsoid(cz, (rz * 0.45, rz * 0.45, 0.2)), k=0.08, mat='bone', part=BP)
        g.apply(Chain([spine_at(z0 - 0.3)[0], spine_at(z0 + 1.9)[0]], [0.12, 0.12]), k=0.06, mat='bone', part=BP)
        drip(g, c + np.array([0, -r * 0.7, 0]), 1.0, rng)

    # ---------- antebrazo izquierdo con el hueso al aire ----------
    for name, s, P, R in BODY.LEGS:
        if name != 'LegFL': continue
        a, b = np.array(P[1]), np.array(P[2]); mid = (a + b) / 2
        p = surface(g, mid + np.array([s * 4.0, 0, 0]), mid)
        if p is None: continue
        g.apply(Ellipsoid(p - np.array([s * 0.15, 0, 0]), (0.45, 1.0, 0.45)), op='sub', k=0.08, carve_mat='muscle')
        g.apply(RoundCone(a + (b - a) * 0.25, a + (b - a) * 0.8, 0.16, 0.14), k=0.04, mat='bone', part=BODY.PART[name])
        flap = [p + np.array([s * 0.05, -0.9, 0.2]), p + np.array([s * 0.25, -1.5, 0.3]), p + np.array([s * 0.2, -2.0, 0.2])]
        g.apply(Chain(flap, [0.14, 0.1, 0.05], squash=(0.35, 1.0)), k=0.05, mat='muscle', part=BODY.PART[name])
        drip(g, p + np.array([0, -1.0, 0]), 1.2, rng)
