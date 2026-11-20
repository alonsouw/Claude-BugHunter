"""Escultura del lobo hueco (alta resolución) + renders de revisión.
Guarda <salida>/sculpt_high.blend con WolfBody y points.json.  Uso: python stage_wolf.py <salida> [vóxel] [muestras] [vistas]
"""
import sys, os, time, json
sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
import bpy
from mathutils import Vector
from sdf import Grid, open_edges, MAT, MATERIALS
import wolf as WOLF
import preview as PV

out = sys.argv[1]; vox = float(sys.argv[2]) if len(sys.argv) > 2 else 0.015
samples = int(sys.argv[3]) if len(sys.argv) > 3 else 24
views = (sys.argv[4] if len(sys.argv) > 4 else 'side,34,head,front').split(',')
os.makedirs(out, exist_ok=True); t0 = time.time()
g = Grid((-0.9, -0.1, -3.0), (0.9, 3.8, 3.0), vox)
pts = WOLF.build_wolf(g, np.random.default_rng(4))
g.noise(0.006, 9.0, mask_mats=('wolfeye', 'teeth', 'muzzle', 'claw', 'gum'))
v, f, m, p = g.mesh(); holes = open_edges(f)
assert holes == 0, f'{holes} aristas abiertas'
print('WolfBody', len(f), 'triángulos', round(time.time() - t0, 1), 's'); del g
json.dump(pts, open(os.path.join(out, 'points.json'), 'w'))
bpy.ops.wm.read_factory_settings(use_empty=True)
PV.studio(0.06, floor_z=0.0)
o = PV.make_mesh('WolfBody', v, f, m, p); o.data.materials.append(PV.fur_material())
col, keep = WOLF.wolf_colors(v, m, MAT, MATERIALS)
ca = o.data.color_attributes['mat']; cur = np.zeros(len(v) * 4, np.float32); ca.data.foreach_get('color', cur); cur = cur.reshape(-1, 4)
cur[keep, :3] = col[keep] ** 2.2; ca.data.foreach_set('color', cur.ravel())
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, 'sculpt_high.blend'))
c = Vector((0, 0, 2.0))
PV.light('Key', c + Vector((-8, 6, 8)), 1800, (1, 0.96, 0.9), 5, c)
PV.light('Rim', c + Vector((7, -8, 5)), 1100, (0.85, 0.9, 1), 4, c)
PV.light('Fill', c + Vector((-3, 8, 1)), 250, (1, 0.95, 0.9), 5, c)
cam = PV.camera(); headc = Vector((0, 2.1, 2.85))
shots = {'side': (c + Vector((-12, 0.3, 0.4)), c + Vector((0, 0.2, 0)), (1400, 1000), 50),
         '34': (c + Vector((-8, 8, 1.6)), c + Vector((0, 0.4, 0.1)), (1400, 1000), 50),
         'head': (headc + Vector((-1.6, 2.0, 0.3)), headc, (1000, 1000), 55),
         'front': (headc + Vector((0, 3.2, 0.1)), headc + Vector((0, 0, -0.1)), (1000, 1000), 50)}
for k in views:
    loc, at, res, lens = shots[k]; PV.shoot(cam, os.path.join(out, f'prev_{k}.jpg'), loc, at, res, lens=lens, samples=samples)
print('listo', round(time.time() - t0, 1), 's')
