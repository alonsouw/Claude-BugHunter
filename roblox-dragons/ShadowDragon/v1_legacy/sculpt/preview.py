"""Malla esculpida → Blender, material de vista previa y renders de estudio como la referencia.

Coordenadas: el modelo se esculpe en espacio Roblox (Y arriba, mira a -Z) y se pasa a Blender
como (x, -z, y): Z arriba y el hocico hacia +Y.
"""
import numpy as np
import bpy
from mathutils import Vector
from sdf import MATERIALS


def to_blender(v):
    return np.stack([v[:, 0], -v[:, 2], v[:, 1]], 1)


def make_mesh(name, verts, faces, mat=None, part=None, smooth=True):
    vb = to_blender(verts).astype(np.float32)
    me = bpy.data.meshes.new(name)
    me.vertices.add(len(vb)); me.vertices.foreach_set('co', vb.ravel())
    f = faces[:, ::-1] if True else faces   # el cambio de ejes invierte la orientación
    me.loops.add(f.size); me.loops.foreach_set('vertex_index', f.ravel())
    me.polygons.add(len(f)); me.polygons.foreach_set('loop_start', np.arange(0, f.size, 3, dtype=np.int32))
    me.update(calc_edges=True); me.validate(clean_customdata=False)
    if smooth: me.shade_smooth()
    if mat is not None:
        col = np.zeros((len(vb), 4), np.float32); rough = np.zeros(len(vb), np.float32); scaly = np.zeros(len(vb), np.float32)
        for k, (_, c, r, sc) in MATERIALS.items():
            m = mat == k; col[m, :3] = [x ** 2.2 for x in c]; col[m, 3] = 1; rough[m] = r; scaly[m] = sc
        a = me.color_attributes.new('mat', 'FLOAT_COLOR', 'POINT'); a.data.foreach_set('color', col.ravel())
        me.attributes.new('rough', 'FLOAT', 'POINT').data.foreach_set('value', rough)
        me.attributes.new('scaly', 'FLOAT', 'POINT').data.foreach_set('value', scaly)
    if part is not None:
        me.attributes.new('part', 'INT', 'POINT').data.foreach_set('value', part.astype(np.int32))
    if mat is not None:
        me.attributes.new('matid', 'INT', 'POINT').data.foreach_set('value', mat.astype(np.int32))
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    return ob


def creature_material(name='Creature'):
    """Color por material + escamas procedurales (Voronoi) y vetas, controladas por los atributos."""
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; N = nt.nodes; L = nt.links
    bsdf = N['Principled BSDF']
    col = N.new('ShaderNodeAttribute'); col.attribute_name = 'mat'
    rough = N.new('ShaderNodeAttribute'); rough.attribute_name = 'rough'
    scaly = N.new('ShaderNodeAttribute'); scaly.attribute_name = 'scaly'
    tc = N.new('ShaderNodeTexCoord')
    vor = N.new('ShaderNodeTexVoronoi'); vor.feature = 'DISTANCE_TO_EDGE'; vor.inputs['Scale'].default_value = 9.0
    L.new(tc.outputs['Object'], vor.inputs['Vector'])
    vor2 = N.new('ShaderNodeTexVoronoi'); vor2.feature = 'DISTANCE_TO_EDGE'; vor2.inputs['Scale'].default_value = 24.0
    L.new(tc.outputs['Object'], vor2.inputs['Vector'])
    noise = N.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value = 3.0; noise.inputs['Detail'].default_value = 8
    L.new(tc.outputs['Object'], noise.inputs['Vector'])
    # escamas: bordes oscuros entre placas (mezcla de dos tamaños)
    e1 = N.new('ShaderNodeMapRange'); e1.inputs['From Max'].default_value = 0.12
    L.new(vor.outputs['Distance'], e1.inputs['Value'])
    e2 = N.new('ShaderNodeMapRange'); e2.inputs['From Max'].default_value = 0.1
    L.new(vor2.outputs['Distance'], e2.inputs['Value'])
    mul = N.new('ShaderNodeMath'); mul.operation = 'MULTIPLY'; L.new(e1.outputs[0], mul.inputs[0]); L.new(e2.outputs[0], mul.inputs[1])
    scale_mask = N.new('ShaderNodeMath'); scale_mask.operation = 'MULTIPLY'; L.new(mul.outputs[0], scale_mask.inputs[0]); L.new(scaly.outputs['Fac'], scale_mask.inputs[1])
    inv = N.new('ShaderNodeMath'); inv.operation = 'SUBTRACT'; inv.inputs[0].default_value = 1.0; L.new(scaly.outputs['Fac'], inv.inputs[1])
    height = N.new('ShaderNodeMath'); height.operation = 'ADD'; L.new(scale_mask.outputs[0], height.inputs[0]); L.new(inv.outputs[0], height.inputs[1])
    # color: oscurecer las juntas de escama y variar con ruido rojizo
    dark = N.new('ShaderNodeMix'); dark.data_type = 'RGBA'; dark.blend_type = 'MULTIPLY'
    L.new(col.outputs['Color'], dark.inputs[6])
    ramp = N.new('ShaderNodeValToRGB'); ramp.color_ramp.elements[0].color = (0.35, 0.33, 0.33, 1); ramp.color_ramp.elements[1].color = (1.15, 1.1, 1.1, 1)
    L.new(height.outputs[0], ramp.inputs['Fac']); L.new(ramp.outputs['Color'], dark.inputs[7]); dark.inputs['Factor'].default_value = 1.0
    tint = N.new('ShaderNodeMix'); tint.data_type = 'RGBA'; tint.blend_type = 'MIX'
    L.new(dark.outputs[2], tint.inputs[6]); tint.inputs[7].default_value = (0.09, 0.012, 0.016, 1)
    nr = N.new('ShaderNodeMapRange'); nr.inputs['From Min'].default_value = 0.55; nr.inputs['From Max'].default_value = 0.8; nr.inputs['To Max'].default_value = 0.6
    L.new(noise.outputs['Fac'], nr.inputs['Value'])
    nmask = N.new('ShaderNodeMath'); nmask.operation = 'MULTIPLY'; L.new(nr.outputs[0], nmask.inputs[0]); L.new(scaly.outputs['Fac'], nmask.inputs[1])
    L.new(nmask.outputs[0], tint.inputs['Factor'])
    L.new(tint.outputs[2], bsdf.inputs['Base Color'])
    rr = N.new('ShaderNodeMath'); rr.operation = 'MULTIPLY_ADD'; rr.inputs[1].default_value = 0.25
    L.new(height.outputs[0], rr.inputs[0]); L.new(rough.outputs['Fac'], rr.inputs[2])
    L.new(rr.outputs[0], bsdf.inputs['Roughness'])
    bump = N.new('ShaderNodeBump'); bump.inputs['Strength'].default_value = 0.55; bump.inputs['Distance'].default_value = 0.02
    L.new(height.outputs[0], bump.inputs['Height']); L.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
    bsdf.inputs['Specular IOR Level'].default_value = 0.45
    return m


def studio(bg=0.045, floor_z=0.0):
    sc = bpy.context.scene
    w = bpy.data.worlds.new('Studio'); sc.world = w; w.use_nodes = True
    w.node_tree.nodes['Background'].inputs['Color'].default_value = (bg, bg, bg, 1)
    w.node_tree.nodes['Background'].inputs['Strength'].default_value = 1.0
    sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.use_denoising = True; sc.cycles.max_bounces = 6
    try: sc.view_settings.view_transform = 'AgX'; sc.view_settings.look = 'AgX - Medium High Contrast'
    except Exception: pass
    sc.render.image_settings.file_format = 'JPEG'; sc.render.image_settings.quality = 90
    bpy.ops.mesh.primitive_plane_add(size=500, location=(0, 0, floor_z)); fl = bpy.context.active_object
    fm = bpy.data.materials.new('Floor'); fm.use_nodes = True; b = fm.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (0.05, 0.05, 0.05, 1); b.inputs['Roughness'].default_value = 0.85
    fl.data.materials.append(fm)
    return fl


def light(name, loc, energy, color=(1, 1, 1), size=8, target=(0, 0, 0)):
    d = bpy.data.lights.new(name, 'AREA'); d.energy = energy; d.color = color; d.size = size
    o = bpy.data.objects.new(name, d); bpy.context.scene.collection.objects.link(o); o.location = loc
    o.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    return o


def camera():
    cd = bpy.data.cameras.new('Cam'); cam = bpy.data.objects.new('Cam', cd); bpy.context.scene.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    return cam


def shoot(cam, path, loc, at, res, lens=50, ortho=None, samples=48):
    sc = bpy.context.scene; sc.cycles.samples = samples
    cam.location = loc; cam.rotation_euler = (Vector(at) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    if ortho: cam.data.type = 'ORTHO'; cam.data.ortho_scale = ortho
    else: cam.data.type = 'PERSP'; cam.data.lens = lens
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.filepath = path; bpy.ops.render.render(write_still=True); print('render', path)
