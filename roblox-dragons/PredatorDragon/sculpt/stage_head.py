"""Etapa 1: solo la cabeza. Esculpe, genera la malla y renderiza tres vistas para compararlas con la referencia.
Uso: python stage_head.py <carpeta_salida> [vóxel] [muestras]
"""
import sys, os, time
sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
import bpy
from mathutils import Vector
from sdf import Grid, RoundCone, Xf
import head as HEAD
import preview as PV

out = sys.argv[1]; vox = float(sys.argv[2]) if len(sys.argv) > 2 else 0.03; samples = int(sys.argv[3]) if len(sys.argv) > 3 else 32
os.makedirs(out, exist_ok=True)
t0 = time.time()
g = Grid((-3.2, -4.2, -6.0), (3.2, 3.4, 4.6), vox)
X = Xf()
rng = np.random.default_rng(7)
g.apply(RoundCone((0, -0.2, 0.5), (0, -1.6, 3.8), 1.2, 1.6), k=0.5, part=HEAD.PART['Neck'])
HEAD.build(g, X, rng)
g.noise(0.022, 2.2, mask_mats=('teeth', 'horn', 'drool', 'tongue'))
v, f, mat, part = g.mesh()
print('malla', len(v), 'vértices', len(f), 'triángulos', round(time.time() - t0, 1), 's')

bpy.ops.wm.read_factory_settings(use_empty=True)
PV.studio(0.05, floor_z=-4.6)
ob = PV.make_mesh('Head', v, f, mat, part); ob.data.materials.append(PV.creature_material())
c = Vector((0, 1.4, -0.3))
PV.light('Key', c + Vector((-6, 8, 9)), 1600, (1, 0.96, 0.92), 6, c)
PV.light('Rim', c + Vector((7, -6, 5)), 1400, (0.85, 0.9, 1), 5, c)
PV.light('Fill', c + Vector((8, 7, -1)), 300, (1, 0.85, 0.85), 8, c)
cam = PV.camera()
PV.shoot(cam, os.path.join(out, 'head_side.jpg'), c + Vector((-17, 0, 0.4)), c + Vector((0, 0, -0.2)), (1000, 760), lens=50, samples=samples)
PV.shoot(cam, os.path.join(out, 'head_front.jpg'), c + Vector((0, 17, 0.8)), c + Vector((0, 0, -0.2)), (900, 900), lens=55, samples=samples)
PV.shoot(cam, os.path.join(out, 'head_34.jpg'), c + Vector((-11, 12, 2.0)), c + Vector((0, 0.2, -0.3)), (1000, 900), lens=55, samples=samples)
PV.shoot(cam, os.path.join(out, 'head_snout.jpg'), c + Vector((-2.5, 9.5, 1.0)), c + Vector((0, 3.4, -0.5)), (900, 900), lens=50, samples=samples)
print('listo', round(time.time() - t0, 1), 's')
