"""Escultura → modelo de juego del ciervo maldito para Roblox.

  1. Retopología por decimado (límite de Roblox: 20k triángulos por MeshPart):
       DeerBody ≈ 18k · HorrorBody ≈ 19,5k · Antlers ≈ 4k · Tentacles ≈ 7k
  2. UV automáticas y horneado de color (con oclusión), normal y rugosidad desde la escultura.
  3. Un solo esqueleto para las dos formas (56 Bones). La criatura usa pesos más suaves en el cuello y las
     patas para que se puedan estirar sin romperse; los tentáculos tienen 4 huesos cada uno.
  4. Exporta FBX (Roblox) y GLB (visor web) más rig.json (huesos, ojos, tentáculos, medidas).
  5. Renders del ciervo (la criatura en movimiento se ve en el visor, con las mismas animaciones que Roblox).

Uso: python produce_deer.py <sculpt_high.blend> <carpeta_modelo> <carpeta_renders> [textura] [muestras]
"""
import sys, os, json, math, time
sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
import bpy, bmesh
from mathutils import Vector
from scipy.spatial import cKDTree
import deer as DEER
import preview as PV

BLEND, OUT, REND = sys.argv[1:4]
TEX = int(sys.argv[4]) if len(sys.argv) > 4 else 1024
SAMPLES = int(sys.argv[5]) if len(sys.argv) > 5 else 48
os.makedirs(OUT, exist_ok=True); os.makedirs(REND, exist_ok=True)
T0 = time.time()
def log(*a): print(f'[{time.time() - T0:6.1f}s]', *a, flush=True)

bpy.ops.wm.open_mainfile(filepath=BLEND)
sc = bpy.context.scene; D = bpy.data
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = 16
B = lambda p: Vector((p[0], -p[2], p[1]))
R = lambda v: (v[0], v[2], -v[1])
PTS = json.load(open(os.path.join(os.path.dirname(BLEND), 'points.json')))


def select_only(objs, active):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = active


def duplicate(o, name):
    c = o.copy(); c.data = o.data.copy(); c.name = name; c.data.name = name; sc.collection.objects.link(c)
    c.data.materials.clear(); return c


def ntris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)


def decimate(o, target, group=None, invert=False):
    tris0 = ntris(o); ratio = min(1.0, target / tris0)
    for _ in range(6):
        c = o.copy(); c.data = o.data.copy(); sc.collection.objects.link(c)
        m = c.modifiers.new('Dec', 'DECIMATE'); m.ratio = ratio; m.use_collapse_triangulate = True
        if group: m.vertex_group = group; m.invert_vertex_group = invert
        select_only([c], c); bpy.ops.object.modifier_apply(modifier=m.name)
        got = ntris(c)
        if abs(got - target) / target < 0.03 or ratio >= 1.0: break
        D.objects.remove(c); ratio = min(1.0, max(1e-4, ratio * target / max(got, 1)))
    o.data = c.data; D.objects.remove(c)
    log(o.name, tris0, '→', ntris(o))


def smart_uv(o, margin=0.004):
    select_only([o], o); bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(62), island_margin=margin, area_weight=0.6)
    bpy.ops.object.mode_set(mode='OBJECT')


def bake_maps(low, highs, prefix, extrusion=0.03, ray=0.08):
    mat = D.materials.new(prefix + '_Mat'); mat.use_nodes = True; low.data.materials.append(mat)
    N = mat.node_tree.nodes; L = mat.node_tree.links; bsdf = N['Principled BSDF']
    imgs = {}
    for kind, cs in (('color', 'sRGB'), ('normal', 'Non-Color'), ('roughness', 'Non-Color')):
        im = D.images.new(f'{prefix}_{kind}', TEX, TEX, alpha=False); im.colorspace_settings.name = cs
        im.generated_color = (0.5, 0.5, 1, 1) if kind == 'normal' else (0.3, 0.3, 0.3, 1); imgs[kind] = im
    nodes = {k: N.new('ShaderNodeTexImage') for k in imgs}
    for k, n in nodes.items(): n.image = imgs[k]
    bk = sc.render.bake; bk.use_selected_to_active = True; bk.cage_extrusion = extrusion; bk.max_ray_distance = ray; bk.margin = 6
    select_only(highs + [low], low)
    for kind, btype in (('color', 'DIFFUSE'), ('normal', 'NORMAL'), ('roughness', 'ROUGHNESS')):
        for n in N: n.select = False
        nodes[kind].select = True; N.active = nodes[kind]
        if btype == 'DIFFUSE': bk.use_pass_direct = False; bk.use_pass_indirect = False; bk.use_pass_color = True
        bpy.ops.object.bake(type=btype)
        if kind == 'color':   # oclusión ambiental suave en el color (pliegues, axilas, interior de orejas)
            ao = D.images.new(f'{prefix}_ao', TEX, TEX, alpha=False); ao.colorspace_settings.name = 'Non-Color'
            aon = N.new('ShaderNodeTexImage'); aon.image = ao
            for n in N: n.select = False
            aon.select = True; N.active = aon
            sc.world.light_settings.distance = 0.25
            vis_ = [(o, o.visible_diffuse, o.visible_shadow) for o in sc.objects if o.type == 'MESH' and o not in highs]
            for o, _, _ in vis_: o.visible_diffuse = False; o.visible_shadow = False
            bpy.ops.object.bake(type='AO')
            for o, vd, vs in vis_: o.visible_diffuse = vd; o.visible_shadow = vs
            px = np.array(imgs['color'].pixels[:], np.float32).reshape(-1, 4); a_ = np.array(ao.pixels[:], np.float32).reshape(-1, 4)[:, :1]
            ref = np.percentile(a_[a_ > 0.02], 85) if np.any(a_ > 0.02) else 1.0
            px[:, :3] *= 0.5 + 0.5 * np.clip(a_ / max(ref, 1e-3), 0, 1)
            imgs['color'].pixels.foreach_set(px.ravel()); imgs['color'].update()
            N.remove(aon)
        imgs[kind].filepath_raw = os.path.join(OUT, f'{prefix}_{kind}.png'); imgs[kind].file_format = 'PNG'; imgs[kind].save()
        log('horneado', prefix, kind)
    L.new(nodes['color'].outputs['Color'], bsdf.inputs['Base Color'])
    L.new(nodes['roughness'].outputs['Color'], bsdf.inputs['Roughness'])
    nm = N.new('ShaderNodeNormalMap'); L.new(nodes['normal'].outputs['Color'], nm.inputs['Color']); L.new(nm.outputs['Normal'], bsdf.inputs['Normal'])
    bsdf.inputs['Specular IOR Level'].default_value = 0.35
    return mat


def zone_group(o, part_ids, name='zone'):
    pa = np.zeros(len(o.data.vertices), np.int32); o.data.attributes['part'].data.foreach_get('value', pa)
    idx = np.nonzero(np.isin(pa, part_ids))[0]
    vg = o.vertex_groups.new(name=name); vg.add(idx.tolist(), 1.0, 'REPLACE')
    return len(idx) / max(1, len(pa))


# ---------------- 1-2. retopología + horneado ----------------
highs = {n: D.objects[n] for n in ('DeerBody', 'HorrorBody', 'Antlers', 'Tentacles')}
for n, o in highs.items(): o.name = n + '_high'
lows = {}
P = DEER.PART
for name, target, zone_ids, zone_share in (('DeerBody', 18500, [P['Head'], P['Jaw'], P['EarL'], P['EarR']], 0.3),
                                           ('HorrorBody', 19500, [P['Head'], P['Jaw'], P['Neck']], 0.42)):
    lo = duplicate(highs[name], name + '_low'); frac = zone_group(lo, zone_ids)
    zone_high = int(ntris(lo) * frac)
    decimate(lo, int(target * (1 - zone_share)) + zone_high, 'zone', invert=True)   # primero el resto
    decimate(lo, target, 'zone', invert=False)                                       # luego la cabeza/cuello
    for v in lo.vertex_groups: lo.vertex_groups.remove(v)
    lows[name] = lo
for name, target in (('Antlers', 4000), ('Tentacles', 14000)):
    lows[name] = duplicate(highs[name], name + '_low'); decimate(lows[name], target)
for name, lo in lows.items():
    assert ntris(lo) <= 20000, name + ' supera 20k triángulos'
    smart_uv(lo)
    bake_maps(lo, [highs[name]], name)

# ---------------- 3. esqueleto ----------------
HX = DEER.HEAD_XF
bones = [('Root', None, (0, 0.0, DEER.HIPS[2]), (0, 1.0, DEER.HIPS[2])),
         ('Hips', 'Root', DEER.HIPS, DEER.SPINE_MID), ('Spine', 'Hips', DEER.SPINE_MID, DEER.CHEST),
         ('Chest', 'Spine', DEER.CHEST, DEER.N1), ('Neck1', 'Chest', DEER.N1, DEER.N2), ('Neck2', 'Neck1', DEER.N2, DEER.N3),
         ('Neck3', 'Neck2', DEER.N3, DEER.ATLAS), ('Head', 'Neck3', DEER.ATLAS, HX.apply(DEER.SNOUT_L)),
         ('Jaw', 'Head', HX.apply(DEER.HINGE_L), HX.apply(DEER.CHIN_L)),
         ('EarL', 'Head', HX.apply(DEER.EAR_BASE_L[0]), HX.apply(DEER.EAR_TIP_L[0])), ('EarR', 'Head', HX.apply(DEER.EAR_BASE_L[1]), HX.apply(DEER.EAR_TIP_L[1])),
         ('Tail', 'Hips', DEER.TAIL_BASE, DEER.TAIL_TIP)]
for name, s, Pp, _ in DEER.LEGS:
    parent = 'Chest' if 'F' in name else 'Hips'
    bones += [(name + '_Upper', parent, Pp[0], Pp[1]), (name + '_Lower', name + '_Upper', Pp[1], Pp[2]),
              (name + '_Cannon', name + '_Lower', Pp[2], Pp[3]), (name + '_Hoof', name + '_Cannon', Pp[3], Pp[4])]
TENT = []
for n, t in enumerate(PTS['tentacles']):
    c = np.array(t['curve']); m = len(c); k1, k2 = m // 3, 2 * m // 3
    pts = [np.array(t['inner']), c[0], c[k1], c[k2], c[-1]]
    names = [f'T{n + 1}_{k}' for k in range(1, 5)]
    for k in range(4):
        bones.append((names[k], 'Head' if k == 0 else names[k - 1], pts[k], pts[k + 1]))
    TENT.append(names)
BONE = {b[0]: b for b in bones}
arm_data = D.armatures.new('DeerRig'); rig = D.objects.new('CursedDeer', arm_data); sc.collection.objects.link(rig)
select_only([rig], rig); bpy.ops.object.mode_set(mode='EDIT')
eb = {}
for nm, parent, h, t in bones:
    b = arm_data.edit_bones.new(nm); b.head = B(h); b.tail = B(t)
    if (b.tail - b.head).length < 1e-3: b.tail = b.head + Vector((0, 0, 0.2))
    if parent: b.parent = eb[parent]
    eb[nm] = b
bpy.ops.object.mode_set(mode='OBJECT')
log('huesos', len(bones))

# ---------------- pesos ----------------
def seg_dist(Q, a, b):
    a, b = np.asarray(a, float), np.asarray(b, float); ab = b - a
    t = np.clip(((Q - a) @ ab) / max(ab @ ab, 1e-9), 0, 1)
    return np.linalg.norm(Q - (a + t[:, None] * ab), axis=1), t

def chain_weights(Q, chain, blend=0.28):
    D2 = []; TT = []
    for _, a, b in chain:
        d, t = seg_dist(Q, a, b); D2.append(d); TT.append(t)
    D2 = np.array(D2); TT = np.array(TT); i = D2.argmin(0); u = TT[i, np.arange(len(Q))]
    W = np.zeros((len(chain), len(Q)), np.float32); W[i, np.arange(len(Q))] = 1.0; n = len(chain)
    lo = (u < blend) & (i > 0); f = 0.5 * (1 - u[lo] / blend); W[i[lo], np.nonzero(lo)[0]] -= f; W[i[lo] - 1, np.nonzero(lo)[0]] += f
    hi = (u > 1 - blend) & (i < n - 1); f = 0.5 * (1 - (1 - u[hi]) / blend); W[i[hi], np.nonzero(hi)[0]] -= f; W[i[hi] + 1, np.nonzero(hi)[0]] += f
    return {chain[k][0]: W[k] for k in range(n)}

def seg(nm): return (nm, np.array(BONE[nm][2], float), np.array(BONE[nm][3], float))

def weights_for(obj, parts, soft):
    """soft = True para la criatura: mezclas largas en cuello y patas (se estiran sin romperse)."""
    me = obj.data; n = len(me.vertices); co = np.zeros(n * 3, np.float32); me.vertices.foreach_get('co', co)
    Pw = np.array([R(v) for v in co.reshape(-1, 3)]); out = {}
    def add(name, idx, w): out.setdefault(name, np.zeros(n, np.float32))[idx] += w
    neck_chain = [seg('Chest'), seg('Neck1'), seg('Neck2'), seg('Neck3'), ('Head', np.array(DEER.ATLAS), HX.apply((0, 0, -0.3)))]
    body_chain = [seg('Tail'), seg('Hips'), seg('Spine'), seg('Chest')]
    for pid in np.unique(parts):
        idx = np.nonzero(parts == pid)[0]; Q = Pw[idx]
        if pid == P['Head'] or pid == P['Antler']:
            if pid == P['Antler']: add('Head', idx, np.ones(len(idx))); continue
            for k, w in chain_weights(Q, neck_chain[-2:], 0.35).items(): add(k, idx, w)
        elif pid == P['Jaw']: add('Jaw', idx, np.ones(len(idx)))
        elif pid in (P['EarL'], P['EarR']):
            e = 'EarL' if pid == P['EarL'] else 'EarR'
            for k, w in chain_weights(Q, [('Head', np.array(BONE['Head'][2]), np.array(BONE[e][2])), seg(e)], 0.3).items(): add(k, idx, w)
        elif pid == P['Neck']:
            # la criatura: cada vértebra va casi rígida con su hueso; al estirarse, la columna se separa y se ven los tendones
            for k, w in chain_weights(Q, neck_chain, 0.18 if soft else 0.3).items(): add(k, idx, w)
        elif pid == P['Tail']:
            for k, w in chain_weights(Q, [seg('Hips'), seg('Tail')], 0.3).items(): add(k, idx, w)
        elif pid in (P['LegFL'], P['LegFR'], P['LegBL'], P['LegBR']):
            name = [k for k, v in P.items() if v == pid][0]; parent = 'Chest' if 'F' in name else 'Hips'
            up = BONE[name + '_Upper']; root = np.array([0, up[2][1] + 0.25, up[2][2]])
            ch = [(parent, root, np.array(up[2])), seg(name + '_Upper'), seg(name + '_Lower'), seg(name + '_Cannon'), seg(name + '_Hoof')]
            for k, w in chain_weights(Q, ch, 0.45 if soft else 0.22).items(): add(k, idx, w)
        elif pid >= DEER.TENT_PART0:
            tn = (pid - DEER.TENT_PART0) // 10
            ch = [seg(b) for b in TENT[tn]]
            for k, w in chain_weights(Q, ch, 0.42).items(): add(k, idx, w)
        else:
            for k, w in chain_weights(Q, body_chain + neck_chain[1:2], 0.3).items(): add(k, idx, w)
    return out

def apply_weights(obj, W):
    tot = sum(W.values()); tot[tot == 0] = 1
    for nm, w in W.items():
        vg = obj.vertex_groups.new(name=nm); w = w / tot
        for val in np.unique(np.round(w[w > 0.01], 2)):
            ids = np.nonzero(np.abs(np.round(w, 2) - val) < 1e-6)[0]
            vg.add(ids.tolist(), float(val), 'REPLACE')
    obj.parent = rig; m = obj.modifiers.new('Armature', 'ARMATURE'); m.object = rig

def parts_from_high(low, high):
    hc = np.zeros(len(high.data.vertices) * 3, np.float32); high.data.vertices.foreach_get('co', hc)
    hp = np.zeros(len(high.data.vertices), np.int32); high.data.attributes['part'].data.foreach_get('value', hp)
    lc = np.zeros(len(low.data.vertices) * 3, np.float32); low.data.vertices.foreach_get('co', lc)
    _, nn = cKDTree(hc.reshape(-1, 3)).query(lc.reshape(-1, 3)); return hp[nn]

for name, lo in lows.items():
    apply_weights(lo, weights_for(lo, parts_from_high(lo, highs[name]), soft=name != 'DeerBody'))
    lo.name = name
log('pesos aplicados')

# ---------------- 4. exportación ----------------
for o in highs.values(): o.hide_render = True; o.hide_set(True)
game = [rig] + [lows[n] for n in ('DeerBody', 'HorrorBody', 'Antlers', 'Tentacles')]
select_only(game, rig)
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, 'CursedDeer.fbx'), use_selection=True, object_types={'ARMATURE', 'MESH'},
                         axis_forward='-Z', axis_up='Y', apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE', add_leaf_bones=False,
                         bake_anim=False, path_mode='COPY', embed_textures=True, mesh_smooth_type='FACE', use_armature_deform_only=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, 'CursedDeer.glb'), export_format='GLB', use_selection=True, export_skins=True,
                          export_animations=False, export_yup=True, export_apply=False)
log('FBX y GLB exportados')
tris = {o.name: ntris(o) for o in game[1:]}
rigjson = {'name': 'CursedDeer', 'units': 'studs', 'forward': '-Z', 'meshes': tris,
           'bones': [{'name': n, 'parent': p, 'head': [round(float(x), 4) for x in h], 'tail': [round(float(x), 4) for x in t]} for n, p, h, t in bones],
           'eyes': PTS['deer']['eyes'], 'chestEyes': PTS['creature'].get('chest_eyes', []), 'tentacles': TENT}
lo_ = np.min([np.array(R(o.matrix_world @ Vector(c))) for o in game[1:3] for c in o.bound_box], 0)
hi_ = np.max([np.array(R(o.matrix_world @ Vector(c))) for o in game[1:3] for c in o.bound_box], 0)
rigjson['bounds'] = {'min': lo_.round(3).tolist(), 'max': hi_.round(3).tolist()}
json.dump(rigjson, open(os.path.join(OUT, 'rig.json'), 'w'), indent=1)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, 'CursedDeer_game.blend'))
log('rig.json', tris)

# ---------------- 5. renders del ciervo ----------------
for o in list(sc.objects):
    if o.type in ('LIGHT', 'CAMERA'): D.objects.remove(o)
c = Vector((0, 0, 2.9))
PV.light('Key', c + Vector((-9, 7, 10)), 2600, (1, 0.96, 0.9), 6, c)
PV.light('Rim', c + Vector((8, -10, 6)), 1300, (0.85, 0.9, 1), 5, c)
PV.light('Fill', c + Vector((-4, 10, 1)), 300, (1, 0.95, 0.9), 6, c)
cam = PV.camera()
headc = Vector((0, 2.5, 4.4))
lows['HorrorBody'].hide_render = True; lows['Tentacles'].hide_render = True
for name, loc, at, res, lens in (('deer_side', c + Vector((-17, 0.3, 0.6)), c + Vector((0, 0.3, 0.1)), (1400, 1000), 50),
                                 ('deer_34', c + Vector((-11, 11, 2.5)), c + Vector((0, 0.5, 0.3)), (1400, 1000), 50),
                                 ('deer_head', headc + Vector((-2.2, 3.2, 0.4)), headc, (1000, 1000), 55)):
    PV.shoot(cam, os.path.join(REND, name + '.jpg'), loc, at, res, lens=lens, samples=SAMPLES)
lows['DeerBody'].hide_render = True; lows['HorrorBody'].hide_render = False; lows['Tentacles'].hide_render = False
for name, loc, at, res, lens in (('creature_rest_34', c + Vector((-11, 11, 3.5)), c + Vector((0, 0.5, 1.2)), (1400, 1000), 45),
                                 ('creature_rest_head', headc + Vector((-2.4, 3.2, 0.2)), headc + Vector((0, 0, 0.3)), (1000, 1000), 50)):
    PV.shoot(cam, os.path.join(REND, name + '.jpg'), loc, at, res, lens=lens, samples=SAMPLES)
log('listo')
