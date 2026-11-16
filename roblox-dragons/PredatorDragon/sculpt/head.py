"""Cabeza del Dragón Depredador, esculpida según la hoja de referencia.

Espacio local de la cabeza: Y arriba, el hocico apunta a -Z y la nuca está en z = 0.
Lectura de la referencia:
  · cráneo ancho y macizo; hocico largo, ancho y de dorso casi plano, con la punta algo caída
  · ceja pesada en V que baja hacia el hocico; placas óseas sobre el hocico
  · corona de cuchillas óseas hacia atrás, cuernos en media luna a los lados y abanicos de espinas en las mejillas
  · boca muy abierta: mandíbula inferior separada, dientes irregulares arriba y abajo, encías y comisuras de carne viva
  · babas entre ambas mandíbulas y una lengua larga que cuelga y se enrosca
  · SIN ojos: solo una hendidura en sombra bajo la ceja (allí va el punto de luz, que no es geometría)
"""
import numpy as np
from sdf import Ellipsoid, RoundCone, Box, Chain, Xf, horn, rot, bezier

PART = {'Head': 1, 'Jaw': 2, 'Tongue': 3, 'Drool': 4, 'Neck': 5}
JAW_OPEN = -0.4          # radianes: boca abierta en la pose de reposo
HINGE = np.array([0.0, -0.45, -0.35])
EYE_POINTS = [(1.0, 0.53, -2.0), (-1.0, 0.53, -2.0)]   # dónde brilla el punto en la oscuridad


def sym(fn):
    for s in (1, -1): fn(s)


def build(g, X, rng):
    """Esculpe la cabeza en la rejilla g. X: transformación cabeza→mundo."""
    H = PART['Head']
    A = lambda prim, **kw: g.apply(prim, **{'xf': X, **kw})

    # --- cráneo y hocico ---
    A(Ellipsoid((0, 0.25, -0.9), (1.3, 1.05, 1.45)), k=0, part=H)
    A(Ellipsoid((0, 0.1, 0.1), (1.05, 0.95, 0.9)), k=0.4, part=H)
    A(RoundCone((0, 0.15, -1.7), (0, -0.05, -4.55), 1.05, 0.52, squash=(1.22, 0.72)), k=0.5, part=H)
    A(Ellipsoid((0, -0.1, -4.72), (0.6, 0.44, 0.55)), k=0.35, part=H)
    A(RoundCone((0, 0.72, -1.5), (0, 0.33, -4.5), 0.27, 0.14), k=0.3, part=H)   # caballete nasal
    def brow(s):
        A(RoundCone((s * 1.1, 0.86, -0.5), (s * 0.42, 0.62, -2.75), 0.35, 0.14), k=0.35, part=H)
        A(Ellipsoid((s * 0.96, 0.84, -1.6), (0.4, 0.25, 0.62)), k=0.25, part=H)
        A(RoundCone((s * 1.22, -0.05, -0.35), (s * 0.98, -0.18, -2.5), 0.42, 0.24), k=0.4, part=H)   # pómulo
        A(Ellipsoid((s * 1.06, -0.33, -0.2), (0.46, 0.55, 0.62)), k=0.35, part=H)                   # masetero
        A(Ellipsoid((s * 0.38, 0.18, -4.8), (0.2, 0.14, 0.24)), k=0.1, part=H)                      # aleta nasal
    sym(brow)
    # placas óseas sobre el hocico, integradas en la piel
    for i in range(7):
        z = -1.8 - i * 0.4; top = 0.85 + (z + 1.5) * 0.155
        for x in ((0.0,) if i % 2 else (-0.36, 0.36)):
            A(Ellipsoid((x, top + 0.02, z), (0.24 - i * 0.012, 0.075, 0.26)), k=0.09, part=H)
    # fosas nasales y hendiduras oculares (sin globo ocular)
    sym(lambda s: A(Ellipsoid((s * 0.37, 0.14, -4.95), (0.07, 0.05, 0.14)), op='sub', k=0.04, carve_mat='socket'))
    sym(lambda s: A(Ellipsoid((s * 0.97, 0.53, -1.95), (0.15, 0.06, 0.34)), op='sub', k=0.06, carve_mat='socket'))
    # boca: corte del paladar siguiendo la pendiente del hocico
    A(Box((0, -1.0, -3.0), (1.7, 0.45, 2.45), 0.05), op='sub', k=0.12, carve_mat='gum', xf=X @ Xf.about((0, -0.55, -0.6), rot((1, 0, 0), -0.035)))
    # encías superiores y comisuras de carne viva
    gum_u = lambda s: [(s * 1.0, -0.5, -0.7), (s * 1.0, -0.54, -2.0), (s * 0.8, -0.58, -3.4), (s * 0.45, -0.62, -4.45), (0, -0.64, -4.78)]
    sym(lambda s: A(Chain(gum_u(s), [0.07, 0.065, 0.06, 0.055, 0.05]), k=0.05, mat='gum', part=H))
    sym(lambda s: A(Ellipsoid((s * 0.98, -0.58, -0.62), (0.2, 0.22, 0.34)), k=0.12, mat='flesh', part=H))
    # heridas: piel abierta en mejillas y frente (rojo oscuro de la referencia)
    for (c, r) in [((1.28, -0.2, -1.05), (0.12, 0.3, 0.55)), ((-1.25, -0.05, -0.8), (0.1, 0.25, 0.4)), ((0.55, 0.88, -1.1), (0.1, 0.06, 0.35)), ((-0.7, 0.4, -3.2), (0.06, 0.12, 0.45))]:
        A(Ellipsoid(c, r), op='paint', mat='wound')

    # --- corona: cuchillas, cuernos y abanicos de espinas (salen del hueso) ---
    A(horn((0, 1.0, -0.8), (0, 1.95, 0.25), (0, 2.25, 1.85), 0.6, squash=(0.38, 1)), k=0.25, mat='horn', part=H)
    def crown(s):
        A(horn((s * 0.62, 0.95, -0.6), (s * 1.0, 1.8, 0.3), (s * 1.25, 2.05, 1.7), 0.5, squash=(0.42, 1)), k=0.22, mat='horn', part=H)
        A(horn((s * 1.05, 0.72, -0.35), (s * 1.62, 1.25, 0.4), (s * 2.0, 1.4, 1.55), 0.42, squash=(0.45, 1)), k=0.2, mat='horn', part=H)
        A(horn((s * 1.2, 0.55, 0.05), (s * 2.45, 0.85, 0.45), (s * 2.55, 2.25, -0.35), 0.35, n=9), k=0.2, mat='horn', part=H)
        A(horn((s * 1.27, -0.25, -0.1), (s * 1.88, -0.25, 0.62), (s * 2.38, -0.08, 1.45), 0.21, squash=(0.45, 1)), k=0.12, mat='horn', part=H)
        A(horn((s * 1.22, -0.66, 0.05), (s * 1.72, -0.86, 0.72), (s * 2.02, -1.02, 1.42), 0.18, squash=(0.45, 1)), k=0.1, mat='horn', part=H)
        A(horn((s * 1.08, 0.97, -0.95), (s * 1.42, 1.3, -0.6), (s * 1.62, 1.52, -0.1), 0.14), k=0.08, mat='horn', part=H)
    sym(crown)

    # --- dientes superiores: irregulares, con colmillos ---
    def upper_teeth(s):
        path = bezier(gum_u(s)[0], gum_u(s)[2], gum_u(s)[4], 40)
        for i in range(15):
            t = 0.02 + 0.93 * i / 14; p = path[int(t * 39)] + np.array([0, -0.06, 0])
            L = (0.33 + rng.random() * 0.36) * (2.0 if i == 11 else 1.5 if i in (3, 7) else 1)
            tilt = np.array([-s * (0.08 + rng.random() * 0.1), -1, 0.18 + rng.random() * 0.2]); tilt /= np.linalg.norm(tilt)
            tip = p + tilt * L; ctrl = p + tilt * L * 0.5 + np.array([0, 0, 0.08 * L])
            A(horn(p, ctrl, tip, 0.06 + 0.035 * L, n=5), k=0.025, mat='teeth', part=H)
    sym(upper_teeth)

    # --- mandíbula inferior (pieza propia, abierta) ---
    J = PART['Jaw']; XJ = X @ Xf.about(HINGE, rot((1, 0, 0), JAW_OPEN))
    B = lambda prim, **kw: g.apply(prim, xf=XJ, **kw)
    gum_l = lambda s: [(s * 0.92, -0.42, -0.72), (s * 0.86, -0.46, -2.0), (s * 0.7, -0.5, -3.3), (s * 0.36, -0.52, -4.3), (0, -0.53, -4.58)]
    def jaw(s):
        B(RoundCone((s * 0.98, -0.62, -0.45), (s * 0.78, -0.72, -3.3), 0.31, 0.22, squash=(0.8, 1.25)), k=0.3, part=J)
        B(RoundCone((s * 0.78, -0.72, -3.3), (0, -0.76, -4.42), 0.22, 0.3), k=0.3, part=J)
        B(Ellipsoid((s * 0.96, -0.6, -0.5), (0.4, 0.44, 0.52)), k=0.3, part=J)
        B(Chain(gum_l(s), [0.065, 0.06, 0.06, 0.055, 0.05]), k=0.04, mat='gum', part=J)
        B(Ellipsoid((s * 1.02, -0.72, -1.25), (0.16, 0.27, 0.62)), op='paint', mat='wound')
        path = bezier(gum_l(s)[0], gum_l(s)[2], gum_l(s)[4], 40)
        for i in range(13):
            t = 0.04 + 0.9 * i / 12; p = path[int(t * 39)] + np.array([0, 0.05, 0])
            L = (0.28 + rng.random() * 0.3) * (1.9 if i == 10 else 1.4 if i == 4 else 1)
            d = np.array([s * (0.05 + rng.random() * 0.12), 1, 0.12 + rng.random() * 0.15]); d /= np.linalg.norm(d)
            B(horn(p, p + d * L * 0.5 - np.array([0, 0, 0.06 * L]), p + d * L, 0.055 + 0.035 * L, n=5), k=0.025, mat='teeth', part=J)
    sym(jaw)
    B(Ellipsoid((0, -0.75, -4.45), (0.62, 0.3, 0.42)), k=0.35, part=J)
    B(Ellipsoid((0, -0.8, -2.4), (0.72, 0.12, 1.85)), k=0.2, mat='flesh', part=J)

    # --- lengua: sale del suelo de la boca, cuelga y se enrosca ---
    tp = [XJ.apply((0, -0.68, -1.3)), XJ.apply((0, -0.68, -3.2)), XJ.apply((0.05, -0.66, -4.5))]
    tip0 = tp[-1]
    tp += [X.apply(np.linalg.solve(X.R, (tip0 - X.t) / X.s) + d) for d in [(0.1, -0.7, -0.35), (0.18, -1.6, -0.45), (0.32, -2.15, -0.12), (0.2, -2.1, 0.28)]]
    g.apply(Chain(tp, [0.27, 0.26, 0.24, 0.2, 0.16, 0.11, 0.05], squash=(1.3, 0.62)), k=0.08, mat='tongue', part=PART['Tongue'])

    # --- babas: hilos entre las dos mandíbulas y gotas colgando ---
    for s, zu, zl in [(1, -3.7, -3.6), (-1, -3.2, -3.1), (1, -2.4, -2.3), (-1, -4.2, -4.05)]:
        up = X.apply((s * 0.62, -0.62, zu)); lo = XJ.apply((s * 0.55, -0.48, zl)); mid = (up + lo) / 2 + np.array([0, -0.25, 0])
        g.apply(Chain(list(bezier(up, mid, lo, 6)), [0.022, 0.018, 0.026, 0.034, 0.02, 0.018]), k=0.04, mat='drool', part=PART['Drool'])
    for s, z, L in [(1, -1.6, 1.0), (-1, -4.0, 0.7)]:
        up = X.apply((s * 0.95, -0.6, z)); g.apply(Chain([up, up + np.array([0, -L * 0.6, 0.02]), up + np.array([0, -L, 0])], [0.025, 0.02, 0.045]), k=0.04, mat='drool', part=PART['Drool'])
