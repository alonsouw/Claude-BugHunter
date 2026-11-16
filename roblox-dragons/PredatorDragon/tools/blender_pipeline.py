"""Blender: GLB del Depredador -> FBX + OBJ para Roblox Studio, y renders Cycles de la ficha.

Uso:  python blender_pipeline.py <PredatorDragon.glb> <rig.json> <carpeta_modelo> <carpeta_renders> [muestras]
(Funciona con el módulo bpy de PyPI o con: blender -b -P blender_pipeline.py -- <args>)
"""
import sys, json, math, os
import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
GLB, RIG, MODEL_DIR, RENDER_DIR = argv[:4]
SAMPLES = int(argv[4]) if len(argv) > 4 else 64
os.makedirs(MODEL_DIR, exist_ok=True); os.makedirs(RENDER_DIR, exist_ok=True)
rig = {p['name']: p for p in json.load(open(RIG))['parts']}

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=GLB)
parts = [o for o in bpy.context.scene.objects if o.type == 'MESH']
print('mallas importadas:', len(parts))

# ---------- exportación para Roblox (solo las mallas del dragón) ----------
bpy.ops.object.select_all(action='DESELECT')
for o in parts: o.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.export_scene.fbx(filepath=os.path.join(MODEL_DIR, 'PredatorDragon.fbx'), use_selection=True, object_types={'MESH', 'EMPTY'},
                         axis_forward='-Z', axis_up='Y', apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE',
                         path_mode='COPY', embed_textures=True, mesh_smooth_type='FACE', add_leaf_bones=False)
bpy.ops.wm.obj_export(filepath=os.path.join(MODEL_DIR, 'PredatorDragon.obj'), export_selected_objects=True,
                      forward_axis='NEGATIVE_Z', up_axis='Y', path_mode='COPY', export_materials=True)
print('FBX y OBJ exportados')

# ---------- materiales para render ----------
def r2b(v):  # espacio Roblox (Y arriba, -Z adelante) -> Blender (Z arriba, +Y adelante)
    return Vector((v[0], -v[2], v[1]))

for o in parts:
    for slot in o.material_slots:
        m = slot.material
        if not m or not m.use_nodes: continue
        bsdf = next((n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if bsdf:
            bsdf.inputs['Subsurface Weight'].default_value = 0.05
            bsdf.inputs['Subsurface Radius'].default_value = (0.35, 0.12, 0.08)
            bsdf.inputs['Subsurface Scale'].default_value = 0.05
            bsdf.inputs['Coat Weight'].default_value = 0.0
glow = bpy.data.materials.new('EyeGlow'); glow.use_nodes = True
nt = glow.node_tree; nt.nodes.clear()
em = nt.nodes.new('ShaderNodeEmission'); em.inputs['Color'].default_value = (1.0, 1.0, 1.0, 1); em.inputs['Strength'].default_value = 25
out = nt.nodes.new('ShaderNodeOutputMaterial'); nt.links.new(em.outputs[0], out.inputs[0])
for o in parts:
    if o.name.startswith('Eye'):
        o.data.materials.clear(); o.data.materials.append(glow)
    bpy.context.view_layer.objects.active = o
    for poly in o.data.polygons: poly.use_smooth = True

# ---------- escenario ----------
scene = bpy.context.scene
bpy.ops.mesh.primitive_plane_add(size=400, location=(0, 0, 0))
ground = bpy.context.active_object
gm = bpy.data.materials.new('Ground'); gm.use_nodes = True
gb = gm.node_tree.nodes['Principled BSDF']; gb.inputs['Base Color'].default_value = (0.018, 0.017, 0.02, 1); gb.inputs['Roughness'].default_value = 0.6
noise = gm.node_tree.nodes.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value = 0.6
ramp = gm.node_tree.nodes.new('ShaderNodeValToRGB'); ramp.color_ramp.elements[0].position = 0.45; ramp.color_ramp.elements[0].color = (0.5, 0.5, 0.5, 1); ramp.color_ramp.elements[1].color = (0.75, 0.75, 0.75, 1)
gm.node_tree.links.new(noise.outputs['Fac'], ramp.inputs['Fac']); gm.node_tree.links.new(ramp.outputs['Color'], gb.inputs['Roughness'])
ground.data.materials.append(gm)

world = bpy.data.worlds.new('Fog'); scene.world = world; world.use_nodes = True
wb = world.node_tree.nodes['Background']; wb.inputs['Color'].default_value = (0.012, 0.014, 0.02, 1); wb.inputs['Strength'].default_value = 1.0

def light(name, kind, loc, energy, color, size=6, target=None):
    d = bpy.data.lights.new(name, kind); d.energy = energy; d.color = color
    if kind == 'AREA': d.size = size
    o = bpy.data.objects.new(name, d); scene.collection.objects.link(o); o.location = loc
    if target is not None:
        c = o.constraints.new('TRACK_TO'); c.target = target; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'
    return o

lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
for o in parts:
    for v in o.bound_box:
        w = o.matrix_world @ Vector(v); lo = Vector(map(min, lo, w)); hi = Vector(map(max, hi, w))
center = (lo + hi) / 2
tgt = bpy.data.objects.new('Target', None); scene.collection.objects.link(tgt); tgt.location = center
light('Key', 'AREA', center + Vector((-16, 14, 18)), 5200, (1.0, 0.9, 0.78), 10, tgt)
light('RimCold', 'AREA', center + Vector((14, -22, 10)), 9000, (0.55, 0.7, 1.0), 8, tgt)
light('RimBlood', 'AREA', center + Vector((-20, -14, 4)), 2200, (1.0, 0.3, 0.25), 6, tgt)
light('Under', 'AREA', center + Vector((0, 12, -2)), 600, (0.9, 0.25, 0.2), 10, tgt)
light('SideFill', 'AREA', center + Vector((26, 6, 8)), 3800, (0.95, 0.9, 0.85), 12, tgt)

# avatar de Roblox (5 studs) para la escala
avatar = []
for (x, y, z, sx, sy, sz) in [(0, 0, 4.4, 1.1, 1.1, 1.1), (0, 0, 3.0, 2, 1, 1.6), (-1.45, 0, 3.0, .8, .8, 1.7), (1.45, 0, 3.0, .8, .8, 1.7), (-.5, 0, 1.1, .9, .9, 2.2), (.5, 0, 1.1, .9, .9, 2.2)]:
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, z)); c = bpy.context.active_object; c.scale = (sx, sy, sz); avatar.append(c)
am = bpy.data.materials.new('Avatar'); am.use_nodes = True; am.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (0.42, 0.5, 0.6, 1)
for c in avatar: c.data.materials.append(am); c.hide_render = True

# ---------- render ----------
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'; scene.cycles.samples = SAMPLES; scene.cycles.use_denoising = True
scene.cycles.max_bounces = 6
try: scene.view_settings.view_transform = 'AgX'; scene.view_settings.look = 'AgX - Medium High Contrast'
except Exception: pass
scene.render.image_settings.file_format = 'JPEG'; scene.render.image_settings.quality = 88

cam_data = bpy.data.cameras.new('Cam'); cam = bpy.data.objects.new('Cam', cam_data); scene.collection.objects.link(cam); scene.camera = cam
look = bpy.data.objects.new('Look', None); scene.collection.objects.link(look)
tc = cam.constraints.new('TRACK_TO'); tc.target = look; tc.track_axis = 'TRACK_NEGATIVE_Z'; tc.up_axis = 'UP_Y'

def shot(name, loc, at, res, lens=None, ortho=None, show_avatar=False, avatar_at=None):
    look.location = at; cam.location = loc
    if ortho: cam_data.type = 'ORTHO'; cam_data.ortho_scale = ortho
    else: cam_data.type = 'PERSP'; cam_data.lens = lens or 35
    for c in avatar:
        c.hide_render = not show_avatar
    if show_avatar and avatar_at is not None:
        base = Vector(avatar_at)
        for c, off in zip(avatar, [(0, 0, 4.4), (0, 0, 3.0), (-1.45, 0, 3.0), (1.45, 0, 3.0), (-.5, 0, 1.1), (.5, 0, 1.1)]):
            c.location = Vector((base.x, base.y + off[0], off[2]))
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.filepath = os.path.join(RENDER_DIR, name + '.jpg')
    bpy.ops.render.render(write_still=True)
    print('render', name)

head = r2b(rig['Head']['center']); tail = r2b(rig['Tail6']['center']); wing = r2b(rig['WingL_Hand']['center'])
size = hi - lo
only = os.environ.get('ONLY', '')
jobs = [
    ('hero', dict(loc=center + Vector((-24, 34, -3.8)), at=center + Vector((-1, 7, 0.5)), res=(1600, 1000), lens=30)),
    ('front', dict(loc=Vector((center.x, 80, center.z)), at=center, res=(900, 900), ortho=max(size.x, size.z) * 1.12)),
    ('side', dict(loc=Vector((80, center.y + 3, center.z)), at=center + Vector((0, 3, 0)), res=(1200, 900), ortho=max(size.y + 12, size.z * 1.33) * 1.06, show_avatar=True, avatar_at=(0, hi.y + 4.0, 0))),
    ('back', dict(loc=Vector((center.x, -80, center.z)), at=center, res=(900, 900), ortho=max(size.x, size.z) * 1.12)),
    ('head', dict(loc=head + Vector((-5.5, 8.5, 0.4)), at=head + Vector((0, 0.9, -0.5)), res=(1000, 1000), lens=50)),
    ('wing', dict(loc=wing + Vector((-4, -14, 12)), at=wing + Vector((3, 1.5, -1)), res=(1000, 1000), lens=30)),
    ('tail', dict(loc=tail + Vector((8, -4, 4.5)), at=tail + Vector((0, 2.5, 0)), res=(1000, 1000), lens=35)),
]
for name, kw in jobs:
    if only and name not in only.split(','): continue
    shot(name, **kw)

# ---------- la mirada en la oscuridad: todo negro salvo dos puntos blancos ----------
if not only or 'gaze' in only.split(','):
    import numpy as np
    for o in scene.objects:
        if o.type == 'LIGHT': o.data.energy *= 0.03
    wb.inputs['Strength'].default_value = 0.15
    em.inputs['Strength'].default_value = 60
    out_png = os.path.join(RENDER_DIR, '_gaze_raw.png')
    look.location = head + Vector((0, 0.4, -0.1)); cam.location = head + Vector((-0.8, 12, -0.4)); cam_data.type = 'PERSP'; cam_data.lens = 42
    for c in avatar: c.hide_render = True
    scene.render.resolution_x, scene.render.resolution_y = 1200, 900
    scene.render.image_settings.file_format = 'PNG'; scene.render.filepath = out_png
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(out_png); w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    rgb = px[..., :3]
    bright = np.clip(rgb.max(axis=2, keepdims=True) - 0.75, 0, None) * 4.0 * np.ones((1, 1, 3), np.float32)
    def blur(a, r):
        for _ in range(3):
            c = np.cumsum(np.pad(a, ((r + 1, r), (0, 0), (0, 0)), mode='edge'), axis=0); a = (c[2 * r + 1:] - c[:-2 * r - 1]) / (2 * r + 1)
            c = np.cumsum(np.pad(a, ((0, 0), (r + 1, r), (0, 0)), mode='edge'), axis=1); a = (c[:, 2 * r + 1:] - c[:, :-2 * r - 1]) / (2 * r + 1)
        return a
    glow = blur(bright, 3) * 0.9 + blur(bright, 12) * 0.7 + blur(bright, 40) * 0.5
    px[..., :3] = np.clip(rgb + glow * np.array([0.92, 0.96, 1.0], np.float32), 0, 1)
    img.pixels[:] = px.ravel()
    img.filepath_raw = os.path.join(RENDER_DIR, 'gaze.jpg'); img.file_format = 'JPEG'; img.save()
    os.remove(out_png)
    print('render gaze')
print('listo')
