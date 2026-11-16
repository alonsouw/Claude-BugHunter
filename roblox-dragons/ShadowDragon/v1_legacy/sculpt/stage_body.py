"""Etapa 2: dragón completo en alta resolución (escultura) + renders de comparación con la referencia.
Guarda la escena en <salida>/sculpt_high.blend para la etapa de retopología, horneado y rig.
Uso: python stage_body.py <carpeta_salida> [vóxel_cuerpo] [muestras] [vistas separadas por comas]
"""
import sys, os, time
sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
import bpy
from mathutils import Vector
from sdf import Grid, MAT
import head as HEAD
import body as BODY
import membrane as MEM
import preview as PV

out = sys.argv[1]; vox = float(sys.argv[2]) if len(sys.argv) > 2 else 0.07
samples = int(sys.argv[3]) if len(sys.argv) > 3 else 32
views = (sys.argv[4] if len(sys.argv) > 4 else 'side,front,top,34,head').split(',')
os.makedirs(out, exist_ok=True)
t0 = time.time(); rng = np.random.default_rng(11)

# --- cuerpo + cabeza (una sola piel) ---
g = Grid((-6.2, -0.6, -19.5), (6.2, 18.8, 22.5), vox)
BODY.build(g, rng)
gh = None
import json
head_pts = HEAD.build(g, BODY.HEAD_XF, np.random.default_rng(7))
json.dump(head_pts, open(os.path.join(out, 'head_points.json'), 'w'))
print('gore aplicado', round(time.time() - t0, 1), 's')
g.noise(0.025, 1.8, mask_mats=('needle', 'lip', 'horn', 'claw', 'socket', 'rag'))
bv, bf, bmat, bpart = g.mesh()
print('cuerpo', len(bf), 'triángulos', round(time.time() - t0, 1), 's'); del g
from sdf import open_edges
holes = open_edges(bf)
assert holes == 0, f'La escultura tiene {holes} aristas abiertas: alguna forma se sale de la rejilla'
print('malla cerrada: 0 aristas abiertas')

# --- huesos de las alas (rejilla propia por lado) ---
wings = []
for s in (-1, 1):
    w = BODY.wing_side(s)
    pts = np.array([w['elbow'], w['wrist']] + w['tips']); lo = pts.min(0) - 1.2; hi = pts.max(0) + 1.2
    hi[1] = max(hi[1], 18.0)
    gw = Grid(lo, hi, vox * 0.9)
    BODY.build_wing_bones(gw, s)
    gw.noise(0.02, 2.0, mask_mats=('claw',))
    wings.append(gw.mesh()); del gw
    print('ala', s, len(wings[-1][1]), 'triángulos')

# --- escena ---
bpy.ops.wm.read_factory_settings(use_empty=True)
PV.studio(0.05, floor_z=0.0)
mat = PV.creature_material()
body = PV.make_mesh('Body', bv, bf, bmat, bpart); body.data.materials.append(mat)
for (v, f, m, p), name in zip(wings, ('WingBonesL', 'WingBonesR')):
    o = PV.make_mesh(name, v, f, m, p); o.data.materials.append(mat)
memmat = bpy.data.materials.new('Membrane'); memmat.use_nodes = True
nt = memmat.node_tree; N = nt.nodes; Lk = nt.links; b = N['Principled BSDF']
tc = N.new('ShaderNodeTexCoord'); vor = N.new('ShaderNodeTexVoronoi'); vor.feature = 'DISTANCE_TO_EDGE'; vor.inputs['Scale'].default_value = 1.4
Lk.new(tc.outputs['Object'], vor.inputs['Vector'])
noi = N.new('ShaderNodeTexNoise'); noi.inputs['Scale'].default_value = 0.35; noi.inputs['Detail'].default_value = 10; Lk.new(tc.outputs['Object'], noi.inputs['Vector'])
ramp = N.new('ShaderNodeValToRGB'); ramp.color_ramp.elements[0].color = (0.012, 0.006, 0.007, 1); ramp.color_ramp.elements[1].position = 0.75; ramp.color_ramp.elements[1].color = (0.04, 0.034, 0.036, 1)
Lk.new(noi.outputs['Fac'], ramp.inputs['Fac'])
veins = N.new('ShaderNodeMapRange'); veins.inputs['From Max'].default_value = 0.035; Lk.new(vor.outputs['Distance'], veins.inputs['Value'])
mix = N.new('ShaderNodeMix'); mix.data_type = 'RGBA'; mix.blend_type = 'MULTIPLY'; mix.inputs['Factor'].default_value = 0.85
Lk.new(ramp.outputs['Color'], mix.inputs[6]); Lk.new(veins.outputs[0], mix.inputs[7]); Lk.new(mix.outputs[2], b.inputs['Base Color'])
b.inputs['Roughness'].default_value = 0.78; b.inputs['Specular IOR Level'].default_value = 0.2
b.inputs['Subsurface Weight'].default_value = 0.0
b.inputs['Transmission Weight'].default_value = 0.0
bump = N.new('ShaderNodeBump'); bump.inputs['Strength'].default_value = 0.35; Lk.new(veins.outputs[0], bump.inputs['Height']); Lk.new(bump.outputs['Normal'], b.inputs['Normal'])
for s, name in ((-1, 'MembraneL'), (1, 'MembraneR')):
    V, F, UV = MEM.wing_membrane(BODY.wing_side(s), np.random.default_rng(5 if s < 0 else 6))
    o = PV.make_mesh(name, V.astype(np.float32), F.astype(np.int32)); o.data.materials.append(memmat)
    uvl = o.data.uv_layers.new(name='UVMap'); loops = np.zeros(len(o.data.loops) * 2, np.float32)
    vi = np.zeros(len(o.data.loops), np.int32); o.data.loops.foreach_get('vertex_index', vi); uvl.data.foreach_set('uv', UV[vi].astype(np.float32).ravel())
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out, 'sculpt_high.blend'))
print('escena guardada', round(time.time() - t0, 1), 's')

# --- luces y vistas como la referencia (fondo gris, luz suave) ---
c = Vector((0, -2.0, 8.0))
PV.light('Key', c + Vector((-22, 16, 26)), 16000, (1, 0.96, 0.92), 14, c)
PV.light('Rim', c + Vector((20, -30, 16)), 7000, (0.85, 0.9, 1), 12, c)
PV.light('Fill', c + Vector((-10, 30, 2)), 1500, (1, 0.9, 0.9), 14, c)
PV.light('Top', c + Vector((0, 0, 30)), 6000, (1, 1, 1), 30, c)
cam = PV.camera()
shots = {
    'side': (c + Vector((-75, 1.5, 2.0)), c + Vector((0, 1.5, 0.3)), (1600, 900), 42),
    'right': (c + Vector((40, 30, 8)), c + Vector((0, 2.5, 0.0)), (1600, 1000), 45),
    'front': (c + Vector((0, 70, 0.5)), c + Vector((0, 0, 1.0)), (1100, 900), 50),
    'top': (c + Vector((0, 0.01, 80)), c + Vector((0, 0, 0)), (1600, 900), 42),
    '34': (c + Vector((-45, 42, 12)), c + Vector((0, 2, 0)), (1600, 1000), 45),
    'head': (c + Vector((-3.5, 23.5, 1.0)), c + Vector((0, 12.0, 1.0)), (1000, 1000), 45),
    'face': (Vector((0.0, 22.5, 6.6)), Vector((0.0, 12.8, 6.3)), (1000, 1000), 50),
    'face34': (Vector((-6.5, 20.5, 8.0)), Vector((0.0, 12.0, 6.6)), (1000, 1000), 45),
}
for k in views:
    loc, at, res, lens = shots[k]
    PV.shoot(cam, os.path.join(out, f'full_{k}.jpg'), loc, at, res, lens=lens, samples=samples)
print('listo', round(time.time() - t0, 1), 's')
