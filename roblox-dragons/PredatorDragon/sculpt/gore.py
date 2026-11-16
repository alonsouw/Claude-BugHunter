"""Detalles gore del Dragón Depredador (heridas de batalla). Se aplican sobre la escultura ya hecha.

  · mejilla izquierda arrancada: maxilar y raíces de los dientes al aire, tiras de músculo
  · babas con sangre, sangre en labios, mentón y puntas de los colmillos
  · herida abierta en el lomo con las vértebras expuestas
  · jirones de carne colgando de las heridas del costillar y regueros de sangre que gotean
  · tres zarpazos profundos en el muslo derecho y una herida abierta en el izquierdo
  · lanza rota clavada en el hombro izquierdo y dos flechas en el cuello
  · garras delanteras manchadas de sangre

Espacio Roblox (Y arriba, mira a -Z, izquierda del dragón = -X). Los objetos se colocan sobre la
superficie real: se busca la piel con un rayo contra el campo de distancia.
"""
import numpy as np
from sdf import Ellipsoid, RoundCone, Chain, Xf, horn, rot, bezier
import head as HEAD
import body as BODY

B_PART = BODY.PART['Body']; H_PART = HEAD.PART['Head']


def surface(g, p_out, p_in, n=400):
    """Primer punto con distancia < 0 en el segmento p_out → p_in (o None)."""
    p_out, p_in = np.asarray(p_out, float), np.asarray(p_in, float)
    for t in np.linspace(0, 1, n):
        p = p_out + (p_in - p_out) * t
        i = np.round((p - g.lo) / g.h).astype(int)
        if np.any(i < 0) or np.any(i >= g.n): continue
        if g.d[i[0], i[1], i[2]] < 0: return p
    return None


def drip(g, top, length, rng, width=0.07):
    """Reguero de sangre que baja por la piel y termina en una gota."""
    top = np.asarray(top, float); wob = rng.uniform(-0.08, 0.08, 3); wob[1] = 0
    pts = [top, top + np.array([0, -length * 0.45, 0]) + wob, top + np.array([0, -length, 0]) + wob * 1.5]
    g.apply(Chain(pts, [width, width * 0.75, width * 0.6]), k=0.05, mat='blood', part=B_PART)
    g.apply(Ellipsoid(pts[-1] + np.array([0, -0.05, 0]), (width * 1.6, width * 2.2, width * 1.6)), k=0.04, mat='blood', part=B_PART)


def apply(g, rng):
    X = BODY.HEAD_XF
    XJ = X @ Xf.about(HEAD.HINGE, rot((1, 0, 0), HEAD.JAW_OPEN))
    A = lambda prim, xf=X, **kw: g.apply(prim, xf=xf, **kw)

    # ---------- cabeza ----------
    # mejilla izquierda arrancada: se ve el maxilar con las raíces de los dientes
    # se busca la piel real de la mejilla (en espacio de la cabeza) con un rayo desde fuera
    Xinv = lambda p: np.linalg.solve(X.R, (np.asarray(p) - X.t) / X.s)
    hit = surface(g, X.apply((-3.0, -0.25, -1.35)), X.apply((0.0, -0.25, -1.35)))
    cx = Xinv(hit)[0] if hit is not None else -1.5
    A(Ellipsoid((cx + 0.12, -0.27, -1.35), (0.36, 0.3, 0.8)), op='sub', k=0.06, carve_mat='muscle')
    bx = cx + 0.24
    A(Chain([(bx + 0.05, -0.46, -0.65), (bx, -0.4, -1.35), (bx + 0.07, -0.43, -2.05)], [0.085, 0.09, 0.07]), k=0.04, mat='bone', part=H_PART)
    for z in (-0.85, -1.15, -1.45, -1.75):
        A(Chain([(bx, -0.42, z), (bx + 0.02, -0.62, z + 0.02)], [0.035, 0.03]), k=0.02, mat='teeth', part=H_PART)
    for z, dz in ((-1.0, 0.2), (-1.6, -0.15)):  # tiras de músculo que cruzan el hueco
        A(Chain([(cx + 0.02, -0.06, z), (cx - 0.04, -0.3, z + dz * 0.5), (cx + 0.02, -0.55, z + dz)], [0.035, 0.028, 0.035]), k=0.03, mat='muscle', part=H_PART)
    A(Ellipsoid((cx, -0.3, -1.35), (0.2, 0.5, 1.05)), op='paint', mat='blood')
    # sangre en labios, comisuras, puntas de los colmillos delanteros y mentón
    for s in (1, -1):
        A(Ellipsoid((s * 0.95, -0.56, -0.95), (0.26, 0.18, 0.42)), op='paint', mat='blood')
    A(Ellipsoid((0, -1.02, -4.35), (0.62, 0.16, 0.45)), op='paint', mat='blood')
    A(Ellipsoid((0, -0.82, -4.35), (0.6, 0.26, 0.38)), xf=XJ, op='paint', mat='blood')
    A(Ellipsoid((0.4, -0.95, -3.4), (0.3, 0.2, 0.5)), xf=XJ, op='paint', mat='blood')
    # babas con sangre y gotas que cuelgan del mentón
    for s, zu, zl in [(1, -2.9, -2.8), (-1, -3.9, -3.75)]:
        up = X.apply((s * 0.6, -0.62, zu)); lo = XJ.apply((s * 0.5, -0.48, zl)); mid = (up + lo) / 2 + np.array([0, -0.22, 0])
        g.apply(Chain(list(bezier(up, mid, lo, 6)), [0.024, 0.02, 0.03, 0.038, 0.022, 0.02]), k=0.04, mat='blood', part=HEAD.PART['Drool'])
    chin = XJ.apply((0, -0.95, -4.3))
    for dx, L in ((-0.25, 0.9), (0.18, 0.55), (0.05, 1.3)):
        top = chin + np.array([dx, 0.05, 0.1]); g.apply(Chain([top, top + np.array([0, -L * 0.6, 0]), top + np.array([0, -L, 0])], [0.03, 0.022, 0.05]), k=0.03, mat='blood', part=HEAD.PART['Jaw'])

    # ---------- lomo: herida abierta con vértebras ----------
    g.apply(Ellipsoid((0.45, 8.5, -5.2), (0.85, 0.5, 1.7)), op='sub', k=0.15, carve_mat='muscle')
    for z in np.linspace(-6.4, -4.0, 4):
        g.apply(Ellipsoid((0.15, 8.2, z), (0.33, 0.22, 0.24)), k=0.06, mat='bone', part=B_PART)
        g.apply(horn((0.15, 8.3, z), (0.15, 8.65, z + 0.12), (0.18, 8.85, z + 0.3), 0.1, n=4), k=0.03, mat='bone', part=B_PART)
    p = surface(g, (2.2, 7.8, -5.4), (0.3, 7.8, -5.4))
    if p is not None: drip(g, p, 1.6, rng)

    # ---------- costillar: jirones colgando y regueros ----------
    for s, zs in ((-1, (-6.9, -6.1, -5.3)), (1, (-6.5, -5.6))):
        for z in zs:
            top = surface(g, (s * 4.0, 4.75, z), (s * 0.5, 4.75, z))
            if top is None: continue
            L = rng.uniform(0.6, 1.0)
            flap = [top, top + np.array([s * 0.12, -L * 0.5, 0.06]), top + np.array([s * 0.05, -L, 0.02])]
            g.apply(Chain(flap, [0.13, 0.1, 0.045], squash=(1.0, 0.35)), k=0.05, mat='muscle', part=B_PART)
        for z in (zs[0] + 0.3, zs[-1] - 0.2):
            top = surface(g, (s * 4.0, 5.2, z), (s * 0.5, 5.2, z))
            if top is not None: drip(g, top, rng.uniform(1.1, 1.8), rng)
    for s_ in (-1, 1):
        g.apply(Ellipsoid((s_ * 2.35, 5.0, -6.0), (0.35, 0.55, 2.0)), op='paint', mat='blood')
    top = surface(g, (0, 3.9, -12.5), (0, 3.9, -9.0))   # pecho
    if top is not None: drip(g, top, 1.2, rng, 0.06)

    # ---------- muslos: zarpazos y herida ----------
    for k in range(3):
        a = np.array([4.5, 5.9, -3.25 + k * 0.38]); b = np.array([4.5, 4.4, -2.35 + k * 0.38])
        sa = surface(g, a, a - np.array([3.5, 0, 0])); sb = surface(g, b, b - np.array([3.5, 0, 0]))
        if sa is None or sb is None: continue
        g.apply(RoundCone(sa + np.array([-0.02, 0, 0]), sb + np.array([-0.02, 0, 0]), 0.075, 0.06), op='sub', k=0.04, carve_mat='muscle')
        drip(g, sb + np.array([0.02, 0, 0]), 0.7, rng, 0.035)
    p = surface(g, (-4.5, 5.2, -2.6), (-1.0, 5.2, -2.6))
    if p is not None:
        g.apply(Ellipsoid(p, (0.3, 0.5, 0.6)), op='sub', k=0.1, carve_mat='muscle')
        drip(g, p + np.array([0.05, -0.4, 0]), 1.0, rng)

    # ---------- lanza rota en el hombro izquierdo ----------
    p = surface(g, (-5.5, 7.5, -9.2), (-0.5, 7.5, -9.2))
    if p is not None:
        out = np.array([-0.75, 0.48, 0.45]); out /= np.linalg.norm(out)
        g.apply(RoundCone(p - out * 0.9, p + out * 3.0, 0.13, 0.11), k=0.02, mat='wood', part=B_PART)
        end = p + out * 3.0
        for d in ([0.3, 0.6, 0.1], [-0.2, 0.7, -0.3], [0.1, 0.5, 0.4]):   # punta astillada
            d = np.array(d) * 0.35 + out * 0.25
            g.apply(horn(end, end + d * 0.5, end + d, 0.04, n=4), k=0.01, mat='wood', part=B_PART)
        g.apply(Ellipsoid(p, (0.2, 0.2, 0.2)), k=0.08, mat='muscle', part=B_PART)
        g.apply(Ellipsoid(p, (0.8, 0.75, 0.8)), op='paint', mat='blood')
        drip(g, p + np.array([0.08, -0.15, 0]), 1.7, rng)

    # ---------- dos flechas en el cuello (lado derecho) ----------
    for (y, z, d) in ((9.0, -14.0, (0.85, 0.35, 0.4)), (9.5, -15.9, (0.8, 0.5, 0.2))):
        p = surface(g, (4.0, y, z), (0.0, y, z))
        if p is None: continue
        d = np.array(d); d /= np.linalg.norm(d)
        g.apply(RoundCone(p - d * 0.5, p + d * 1.7, 0.035, 0.032), k=0.01, mat='wood', part=B_PART)
        tail = p + d * 1.55
        for ang in (0, 2.1, 4.2):   # plumas
            side = np.cross(d, [0, 1, 0]); side /= np.linalg.norm(side); up = np.cross(side, d)
            v = side * np.cos(ang) + up * np.sin(ang)
            g.apply(RoundCone(tail, tail + v * 0.14 - d * 0.25, 0.02, 0.01, squash=(1, 0.3)), k=0.01, mat='bone', part=B_PART)
        g.apply(Ellipsoid(p, (0.5, 0.55, 0.5)), op='paint', mat='blood')
        drip(g, p + np.array([0, -0.1, 0]), 1.2, rng, 0.04)

    # ---------- garras delanteras ensangrentadas ----------
    for s in (-1, 1):
        g.apply(Ellipsoid((s * 2.65, 0.3, -11.2), (0.75, 0.3, 0.65)), op='paint', mat='blood')
