"""Escultura del ciervo y de la criatura (alta resolución) + renders de revisión.
Guarda <salida>/sculpt_high.blend con DeerBody, HorrorBody, Antlers y Tentacles, y points.json.
Uso: python stage_deer.py <salida> [vóxel] [muestras] [vistas]
"""
import sys, os, time, json
sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
import bpy
from mathutils import Vector
from sdf import Grid, open_edges
import deer as DEER
import preview as PV

out = sys.argv[1]; vox = float(sys.argv[2]) if len(sys.argv) > 2 else 0.02
samples = int(sys.argv[3]) if len(sys.argv) > 3 else 24
views = (sys.argv[4] if len(sys.argv) > 4 else 'side,34,head,cside,c34,chead,cfront').split(',')
os.makedirs(out, exist_ok=True); t0 = time.time()
points = {}

def mesh_of(g, name, noise=None, mask=()):
    if noise: g.noise(noise[0], noise[1], mask_mats=mask)
    v, f, m, p = g.mesh(); holes = open_edges(f)
    assert holes == 0, f'{name}: {holes} aristas abiertas (alguna forma se sale de la rejilla)'
    print(name, len(f), 'triángulos', round(time.time() - t0, 1), 's'); return v, f, m, p

g = Grid((-1.1, -0.1, -3.5), (1.1, 5.4, 3.1), vox)
points['deer'] = DEER.build_deer(g, np.random.default_rng(3))
deer = mesh_of(g, 'DeerBody', (0.006, 9.0), ('eye', 'muzzle', 'hoof')); del g

g = Grid((-1.1, -0.1, -3.5), (1.1, 5.4, 3.1), vox)
points['creature'] = DEER.build_creature(g, np.random.default_rng(3))
g.noise(0.014, 6.0, mask_mats=('eye', 'needle', 'white', 'gullet', 'hoof'))
g.d -= 0.02            # algo más gruesa que el ciervo: al aparecer lo tapa por completo
horror = mesh_of(g, 'HorrorBody'); del g

g = Grid((-1.3, 4.2, -3.3), (1.3, 6.3, -0.6), vox * 0.7)
points['antlers'] = DEER.build_antlers(g, np.random.default_rng(5))
antl = mesh_of(g, 'Antlers', (0.004, 14.0)); del g

g = Grid((-2.8, 3.6, -5.0), (2.8, 8.6, 1.0), vox * 0.9)
curves = DEER.build_tentacles(g, np.random.default_rng(9))
points['tentacles'] = [{'inner': list(map(float, inner)), 'curve': np.round(c, 4).tolist()} for inner, c in curves]
tent = mesh_of(g, 'Tentacles', (0.008, 7.0)); del g
json.dump(points, open(os.path.join(out, 'points.json'), 'w'))

bpy.ops.wm.read_factory_settings(use_empty=True)
PV.studio(0.06, floor_z=0.0)
fur = PV.fur_material(); crea = PV.creature_material()
objs = {}
from sdf import MAT, MATERIALS
for (v, f, m, p), name, mat in ((deer, 'DeerBody', fur), (horror, 'HorrorBody', crea), (antl, 'Antlers', fur), (tent, 'Tentacles', crea)):
    o = PV.make_mesh(name, v, f, m, p); o.data.materials.append(mat); objs[name] = o
    if name == 'DeerBody':   # pelaje con degradados suaves
        col, keep = DEER.deer_colors(v, m, MAT, MATERIALS)
        ca = o.data.color_attributes['mat']; cur = np.zeros(len(v) * 4, np.float32); ca.data.foreach_get('color', cur); cur = cur.reshape(-1, 4)
        cur[keep, :3] = np.clip(col[keep], 0, 1) ** 2.2; ca.data.foreach_set('color', cur.ravel())
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, 'sculpt_high.blend'))
print('escena guardada', round(time.time() - t0, 1), 's')

c = Vector((0, 0, 2.9))
PV.light('Key', c + Vector((-9, 7, 10)), 2600, (1, 0.96, 0.9), 6, c)
PV.light('Rim', c + Vector((8, -10, 6)), 1300, (0.85, 0.9, 1), 5, c)
PV.light('Fill', c + Vector((-4, 10, 1)), 300, (1, 0.95, 0.9), 6, c)
cam = PV.camera()
headc = Vector((0, 2.5, 4.4))
shots = {
    'side': (c + Vector((-17, 0.3, 0.6)), c + Vector((0, 0.3, 0.1)), (1400, 1000), 50),
    '34': (c + Vector((-11, 11, 2.5)), c + Vector((0, 0.5, 0.3)), (1400, 1000), 50),
    'head': (headc + Vector((-2.2, 3.2, 0.4)), headc, (1000, 1000), 55),
    'front': (headc + Vector((0, 5, 0)), headc + Vector((0, 0, -0.6)), (1000, 1000), 45),
}
for k in list(shots): shots['c' + k] = shots[k]
for k in views:
    creature = k.startswith('c')
    objs['DeerBody'].hide_render = creature; objs['HorrorBody'].hide_render = not creature; objs['Tentacles'].hide_render = not creature
    loc, at, res, lens = shots[k]
    PV.shoot(cam, os.path.join(out, f'prev_{k}.jpg'), loc, at, res, lens=lens, samples=samples)
print('listo', round(time.time() - t0, 1), 's')
