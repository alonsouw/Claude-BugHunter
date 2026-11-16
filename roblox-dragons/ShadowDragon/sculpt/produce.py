"""Etapa 3: escultura → modelo de juego para Roblox.

  1. Retopología por decimado: Body ≈ 19k triángulos, cada ala (huesos + membrana) ≈ 12k (límite Roblox: 20k por MeshPart).
  2. UV automáticas y horneado desde la escultura de alta: color, normal (detalle de escamas y relieve) y rugosidad.
  3. Esqueleto (Bones) con nombres de juego y pesos calculados por zona anatómica.
  4. Exporta FBX (Roblox) y GLB (visor web) con texturas, más rig.json con huesos y los puntos de los ojos.
  5. Renders del modelo de juego (no de la escultura) y la toma «mirada en la oscuridad».

Uso: python produce.py <sculpt_high.blend> <carpeta_modelo> <carpeta_renders> [tamaño_textura] [muestras]
"""
import sys, os, json, math, time
sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
import bpy, bmesh
from mathutils import Vector, Matrix
from scipy.spatial import cKDTree
import body as BODY
import head as HEAD
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
B = lambda p: Vector((p[0], -p[2], p[1]))              # Roblox → Blender
R = lambda v: (v[0], v[2], -v[1])                       # Blender → Roblox


def select_only(objs, active):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = active


def duplicate(o, name):
    c = o.copy(); c.data = o.data.copy(); c.name = name; c.data.name = name; sc.collection.objects.link(c)
    c.data.materials.clear(); return c


def ntris(o): return sum(len(p.vertices) - 2 for p in o.data.polygons)


def decimate(o, target, group=None, invert=False):
    """Decimado por colapso hasta ~target triángulos. Con group, solo se reduce la zona con peso 1
    (o la de peso 0 si invert): el resto se conserva intacto."""
    tris0 = ntris(o); ratio = min(1.0, target / tris0)
    for _ in range(5):
        c = o.copy(); c.data = o.data.copy(); sc.collection.objects.link(c)
        m = c.modifiers.new('Dec', 'DECIMATE'); m.ratio = ratio; m.use_collapse_triangulate = True
        if group: m.vertex_group = group; m.invert_vertex_group = invert
        select_only([c], c); bpy.ops.object.modifier_apply(modifier=m.name)
        got = ntris(c)
        if abs(got - target) / target < 0.04 or ratio >= 1.0:
            break
        D.objects.remove(c)
        ratio = min(1.0, max(1e-4, ratio * target / max(got, 1)))
    o.data = c.data; D.objects.remove(c)
    log(o.name, tris0, '→', ntris(o), 'triángulos', f'(grupo {group}, invertido)' if invert else (f'(grupo {group})' if group else ''))


def smart_uv(o, margin=0.004):
    select_only([o], o); bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(62), island_margin=margin, area_weight=0.6)
    bpy.ops.object.mode_set(mode='OBJECT')


def bake_maps(low, highs, prefix, extrusion=0.08, ray=0.3):
    """Hornea color, normal y rugosidad de las piezas de alta a la de baja."""
    mat = D.materials.new(prefix + '_Mat'); mat.use_nodes = True; low.data.materials.append(mat)
    N = mat.node_tree.nodes; L = mat.node_tree.links; bsdf = N['Principled BSDF']
    imgs = {}
    for kind, cs in (('color', 'sRGB'), ('normal', 'Non-Color'), ('roughness', 'Non-Color')):
        im = D.images.new(f'{prefix}_{kind}', TEX, TEX, alpha=False); im.colorspace_settings.name = cs
        im.generated_color = (0.5, 0.5, 1, 1) if kind == 'normal' else (0.1, 0.1, 0.1, 1); imgs[kind] = im
    nodes = {k: N.new('ShaderNodeTexImage') for k in imgs}
    for k, n in nodes.items(): n.image = imgs[k]
    bk = sc.render.bake; bk.use_selected_to_active = True; bk.cage_extrusion = extrusion; bk.max_ray_distance = ray; bk.margin = 6
    select_only(highs + [low], low)
    for kind, btype in (('color', 'DIFFUSE'), ('normal', 'NORMAL'), ('roughness', 'ROUGHNESS')):
        for n in nodes.values(): n.select = False
        nodes[kind].select = True; N.active = nodes[kind]
        if btype == 'DIFFUSE': bk.use_pass_direct = False; bk.use_pass_indirect = False; bk.use_pass_color = True
        bpy.ops.object.bake(type=btype)
        if kind == 'color':   # v2: sombras de cavidad (oclusión ambiental) horneadas dentro del color
            ao = D.images.new(f'{prefix}_ao', TEX, TEX, alpha=False); ao.colorspace_settings.name = 'Non-Color'
            aon = N.new('ShaderNodeTexImage'); aon.image = ao
            for n in N: n.select = False
            aon.select = True; N.active = aon
            sc.world.light_settings.distance = 0.45
            vis_ = [(o, o.visible_diffuse, o.visible_shadow) for o in sc.objects if o.type == 'MESH' and o not in highs]
            for o, _, _ in vis_: o.visible_diffuse = False; o.visible_shadow = False   # solo ocluye la escultura
            bpy.ops.object.bake(type='AO')
            for o, vd, vs in vis_: o.visible_diffuse = vd; o.visible_shadow = vs
            px = np.array(imgs['color'].pixels[:], np.float32).reshape(-1, 4); a_ = np.array(ao.pixels[:], np.float32).reshape(-1, 4)[:, :1]
            ref = np.percentile(a_[a_ > 0.02], 85) if np.any(a_ > 0.02) else 1.0
            a_ = np.clip(a_ / max(ref, 1e-3), 0, 1)          # normalizado: la piel abierta queda a 1, solo las cavidades oscurecen
            px[:, :3] *= 0.4 + 0.6 * a_
            # v2: la piel oscura sube ~1,9x para que la visión nocturna saque relieve; labios, encías y hueso no cambian
            lum = px[:, :3].mean(1, keepdims=True); k = np.clip((lum - 0.03) / 0.12, 0, 1); k = k * k * (3 - 2 * k)
            px[:, :3] *= 1.0 + 0.9 * (1 - k)
            imgs['color'].pixels.foreach_set(px.ravel()); imgs['color'].update()
            log('oclusión', prefix, 'referencia', round(float(ref), 3))
            N.remove(aon); nodes['color'].select = True; N.active = nodes['color']
        imgs[kind].filepath_raw = os.path.join(OUT, f'{prefix}_{kind}.png'); imgs[kind].file_format = 'PNG'; imgs[kind].save()
        log('horneado', prefix, kind)
    L.new(nodes['color'].outputs['Color'], bsdf.inputs['Base Color'])
    L.new(nodes['roughness'].outputs['Color'], bsdf.inputs['Roughness'])
    nm = N.new('ShaderNodeNormalMap'); L.new(nodes['normal'].outputs['Color'], nm.inputs['Color']); L.new(nm.outputs['Normal'], bsdf.inputs['Normal'])
    bsdf.inputs['Specular IOR Level'].default_value = 0.4
    return mat


def double_side(o, face_filter):
    """Duplica las caras de la membrana con la normal invertida (Roblox no dibuja la cara trasera)."""
    bm = bmesh.new(); bm.from_mesh(o.data)
    faces = [f for f in bm.faces if face_filter(f)]
    ret = bmesh.ops.duplicate(bm, geom=faces)
    newf = [g for g in ret['geom'] if isinstance(g, bmesh.types.BMFace)]
    bmesh.ops.reverse_faces(bm, faces=newf)
    bm.to_mesh(o.data); bm.free(); o.data.update()


# ---------------- 1-2. retopología + horneado ----------------
body_h = D.objects['Body']; body_h.name = 'Body_high'
HPTS = json.load(open(os.path.join(os.path.dirname(BLEND), 'head_points.json')))
from sdf import MAT
def keep_faces(o, keep_teeth):
    """Separa los dientes (material 'needle') del resto: borra las caras del otro grupo."""
    mi = np.zeros(len(o.data.vertices), np.int32); o.data.attributes['matid'].data.foreach_get('value', mi)
    teeth_v = mi == MAT['needle']
    bm = bmesh.new(); bm.from_mesh(o.data)
    kill = [f for f in bm.faces if all(teeth_v[v.index] for v in f.verts) != keep_teeth]
    bmesh.ops.delete(bm, geom=kill, context='FACES'); bm.to_mesh(o.data); bm.free(); o.data.update()
teeth = duplicate(body_h, 'Teeth'); keep_faces(teeth, True); decimate(teeth, 7000)
tm = D.materials.new('TeethMat'); tm.use_nodes = True; tb = tm.node_tree.nodes['Principled BSDF']
tb.inputs['Base Color'].default_value = (0.78, 0.76, 0.72, 1); tb.inputs['Roughness'].default_value = 0.3; teeth.data.materials.append(tm)
body = duplicate(body_h, 'Body_low'); keep_faces(body, False)
# v2: la cabeza va en su propia malla (Skull, ~16k triángulos y textura propia); el cuerpo ~14.5k
pa = np.zeros(len(body.data.vertices), np.int32); body.data.attributes['part'].data.foreach_get('value', pa)
headv = np.nonzero(np.isin(pa, [HEAD.PART['Head'], HEAD.PART['Jaw'], HEAD.PART['Tongue'], HEAD.PART['Drool']]))[0]
vg = body.vertex_groups.new(name='headzone'); vg.add(headv.tolist(), 1.0, 'REPLACE')
head_tris_high = int(round(ntris(body) * len(headv) / len(body.data.vertices)))
decimate(body, head_tris_high + 14500, 'headzone', invert=True)     # reduce el cuerpo, conserva la cabeza
decimate(body, 30500, 'headzone', invert=False)                     # ahora reduce la cabeza
# separar la cabeza: cada cara va con la parte mayoritaria de sus vértices (vecino más cercano en la escultura)
_hc = np.zeros(len(body_h.data.vertices) * 3, np.float32); body_h.data.vertices.foreach_get('co', _hc)
_hp = np.zeros(len(body_h.data.vertices), np.int32); body_h.data.attributes['part'].data.foreach_get('value', _hp)
_lc = np.zeros(len(body.data.vertices) * 3, np.float32); body.data.vertices.foreach_get('co', _lc)
_, _nn = cKDTree(_hc.reshape(-1, 3)).query(_lc.reshape(-1, 3))
is_head_v = np.isin(_hp[_nn], [HEAD.PART['Head'], HEAD.PART['Jaw']])
def keep_head(o, want_head):
    bm = bmesh.new(); bm.from_mesh(o.data)
    kill = [f for f in bm.faces if (np.mean([is_head_v[v.index] for v in f.verts]) >= 0.5) != want_head]
    bmesh.ops.delete(bm, geom=kill, context='FACES'); bm.to_mesh(o.data); bm.free(); o.data.update()
skull = duplicate(body, 'Skull_low'); keep_head(skull, True); keep_head(body, False)
for o in (body, skull):
    for v in o.vertex_groups: o.vertex_groups.remove(v)
log('cuerpo', ntris(body), 'cabeza', ntris(skull))
assert ntris(body) <= 20000 and ntris(skull) <= 20000, 'una malla supera los 20k triángulos de Roblox'
smart_uv(body); smart_uv(skull)
bake_maps(body, [body_h], 'Body', extrusion=0.1, ray=0.35)
bake_maps(skull, [body_h], 'Skull', extrusion=0.08, ray=0.3)
wings = {}
for side in ('L', 'R'):
    bones_h, mem_h = D.objects['WingBones' + side], D.objects['Membrane' + side]
    bl = duplicate(bones_h, 'Wing' + side + '_low'); decimate(bl, 2600)
    ml = duplicate(mem_h, 'Mem' + side + '_tmp')
    for p in ml.data.polygons: p.material_index = 0
    ml.data.attributes.new('is_mem', 'INT', 'FACE').data.foreach_set('value', np.ones(len(ml.data.polygons), np.int32))
    select_only([bl, ml], bl); bpy.ops.object.join(); w = bl
    smart_uv(w, 0.006)
    bake_maps(w, [bones_h, mem_h], 'Wing' + side, extrusion=0.06, ray=0.25)
    ism = np.zeros(len(w.data.polygons), np.int32); w.data.attributes['is_mem'].data.foreach_get('value', ism)
    mem_set = set(np.nonzero(ism)[0].tolist())
    double_side(w, lambda f: f.index in mem_set)
    wings[side] = w
    log('ala', side, sum(len(p.vertices) - 2 for p in w.data.polygons), 'triángulos')

# ---------------- 3. esqueleto ----------------
SP = [np.array(p) for p, _ in BODY.SPINE]
HX = BODY.HEAD_XF
hp = lambda p: HX.apply(p)
HI = BODY.HIPS_INDEX
snout = np.array(HPTS['snout']); jaw_tip = np.array(HPTS['chin'])
bones = [('Root', None, (SP[HI][0], 0.0, SP[HI][2]), (SP[HI][0], 1.5, SP[HI][2]))]
bones += [(n, p, SP[a], SP[b]) for n, p, a, b in BODY.SPINE_BONES]
bones += [('Head', 'Neck3', SP[0], snout), ('Jaw', 'Head', np.array(HPTS['hinge']), jaw_tip)]
tail_pts = SP[HI:] + [SP[-1] + (SP[-1] - SP[-2]) / np.linalg.norm(SP[-1] - SP[-2]) * 3.0]
prev = 'Hips'
for i in range(len(tail_pts) - 1):
    nm = f'Tail{i + 1}'; bones.append((nm, prev, tail_pts[i], tail_pts[i + 1])); prev = nm
for name, s, P, _ in BODY.LEGS:
    parent = 'Chest' if 'F' in name else 'Hips'
    bones += [(name + '_Upper', parent, P[0], P[1]), (name + '_Lower', name + '_Upper', P[1], P[2]), (name + '_Foot', name + '_Lower', P[2], np.array(P[3]) + np.array([0, 0, -0.9]))]
for s, side in ((-1, 'L'), (1, 'R')):
    w = BODY.wing_side(s); tips = np.array(w['tips'])
    bones += [('Wing' + side + '_Arm', 'Chest', w['shoulder'], w['elbow']), ('Wing' + side + '_Fore', 'Wing' + side + '_Arm', w['elbow'], w['wrist']),
              ('Wing' + side + '_Hand', 'Wing' + side + '_Fore', w['wrist'], tips[1])]
BONE = {b[0]: b for b in bones}

arm_data = D.armatures.new('DragonRig'); rig = D.objects.new('ShadowDragon', arm_data); sc.collection.objects.link(rig)
select_only([rig], rig); bpy.ops.object.mode_set(mode='EDIT')
eb = {}
for nm, parent, h, t in bones:
    b = arm_data.edit_bones.new(nm); b.head = B(h); b.tail = B(t)
    if (b.tail - b.head).length < 1e-3: b.tail = b.head + Vector((0, 0, 0.5))
    if parent: b.parent = eb[parent]
    eb[nm] = b
bpy.ops.object.mode_set(mode='OBJECT')
log('huesos', len(bones))

# ---------------- pesos por zona anatómica ----------------
def seg_dist(P, a, b):
    a, b = np.asarray(a, float), np.asarray(b, float); ab = b - a
    t = np.clip(((P - a) @ ab) / max(ab @ ab, 1e-9), 0, 1)
    return np.linalg.norm(P - (a + t[:, None] * ab), axis=1), t

def chain_weights(P, chain, blend=0.28):
    """chain: [(hueso, a, b)]. Hueso del segmento más cercano, mezclado con el vecino cerca de cada articulación."""
    D2 = []; TT = []
    for _, a, b in chain:
        d, t = seg_dist(P, a, b); D2.append(d); TT.append(t)
    D2 = np.array(D2); TT = np.array(TT); i = D2.argmin(0); u = TT[i, np.arange(len(P))]
    W = np.zeros((len(chain), len(P)), np.float32); W[i, np.arange(len(P))] = 1.0
    n = len(chain)
    lo = (u < blend) & (i > 0); f = 0.5 * (1 - u[lo] / blend); W[i[lo], np.nonzero(lo)[0]] -= f; W[i[lo] - 1, np.nonzero(lo)[0]] += f
    hi = (u > 1 - blend) & (i < n - 1); f = 0.5 * (1 - (1 - u[hi]) / blend); W[i[hi], np.nonzero(hi)[0]] -= f; W[i[hi] + 1, np.nonzero(hi)[0]] += f
    return {chain[k][0]: W[k] for k in range(n)}

def seg(nm): return (nm, BONE[nm][2], BONE[nm][3])
SPINE_CHAIN = [('Head', BONE['Neck3'][3], BONE['Neck3'][3] + (BONE['Neck3'][3] - BONE['Neck3'][2]) * 0.3), seg('Neck3'), seg('Neck2'), seg('Neck1'), seg('Chest'), seg('Spine1'), seg('Hips')] + [seg(f'Tail{i}') for i in range(1, len(tail_pts))]

def weights_for(obj, parts):
    me = obj.data; n = len(me.vertices); co = np.zeros(n * 3, np.float32); me.vertices.foreach_get('co', co)
    P = np.array([R(v) for v in co.reshape(-1, 3)])
    out = {}
    def add(name, idx, w):
        out.setdefault(name, np.zeros(n, np.float32))[idx] += w
    for pid in np.unique(parts):
        idx = np.nonzero(parts == pid)[0]; Q = P[idx]
        if pid in (HEAD.PART['Head'],):
            d_head, _ = seg_dist(Q, BONE['Head'][2], BONE['Head'][3]); d_neck, _ = seg_dist(Q, BONE['Neck3'][2], BONE['Neck3'][3])
            w = np.clip((d_neck - d_head + 0.8) / 1.6, 0, 1); add('Head', idx, w); add('Neck3', idx, 1 - w)
        elif pid == HEAD.PART['Jaw']: add('Jaw', idx, np.ones(len(idx)))
        elif pid == HEAD.PART['Tongue']:
            d, t = seg_dist(Q, BONE['Tongue'][2], BONE['Tongue'][3]); add('Tongue', idx, np.ones(len(idx)))
        elif pid == HEAD.PART['Drool']:
            dh, _ = seg_dist(Q, BONE['Head'][2], BONE['Head'][3]); dj, _ = seg_dist(Q, BONE['Jaw'][2], BONE['Jaw'][3])
            w = dj ** 2 / (dh ** 2 + dj ** 2); add('Head', idx, w); add('Jaw', idx, 1 - w)
        elif pid in (BODY.PART['LegFL'], BODY.PART['LegFR'], BODY.PART['LegBL'], BODY.PART['LegBR']):
            name = [k for k, v in BODY.PART.items() if v == pid][0]; parent = 'Chest' if 'F' in name else 'Hips'
            up = BONE[name + '_Upper']; root = np.array([0, up[2][1] + 0.3, up[2][2]])
            ch = [(parent, root, up[2]), seg(name + '_Upper'), seg(name + '_Lower'), seg(name + '_Foot')]
            for k, w in chain_weights(Q, ch, 0.22).items(): add(k, idx, w)
        elif pid in (BODY.PART['WingL'], BODY.PART['WingR'], 0) and obj.name.startswith('Wing'):
            side = 'L' if obj.name.startswith('WingL') else 'R'; w = BODY.wing_side(-1 if side == 'L' else 1)
            arm = BONE['Wing' + side + '_Arm']
            ch = [('Chest', np.array([0, arm[2][1], arm[2][2]]), arm[2]), seg('Wing' + side + '_Arm'), seg('Wing' + side + '_Fore')]
            D = [seg_dist(Q, *c[1:])[0] for c in ch]
            for t in w['tips']: D.append(seg_dist(Q, w['wrist'], t)[0]); ch.append(('Wing' + side + '_Hand', None, None))
            D.append(seg_dist(Q, w['shoulder'], w['rear'])[0]); ch.append(('Chest', None, None))
            D = np.array(D); inv = 1.0 / np.maximum(D, 0.05) ** 4; inv /= inv.sum(0)
            for k, c in enumerate(ch): add(c[0], idx, inv[k])
        elif pid in (BODY.PART['WingL'], BODY.PART['WingR']):   # raíz del ala dentro del cuerpo
            side = 'L' if pid == BODY.PART['WingL'] else 'R'; arm = BONE['Wing' + side + '_Arm']
            ch = [('Chest', np.array([0, arm[2][1], arm[2][2]]), arm[2]), seg('Wing' + side + '_Arm')]
            for k, w in chain_weights(Q, ch, 0.3).items(): add(k, idx, w)
        else:
            for k, w in chain_weights(Q, SPINE_CHAIN, 0.3).items(): add(k, idx, w)
    return out

def apply_weights(obj, W):
    tot = sum(W.values()); tot[tot == 0] = 1
    for nm, w in W.items():
        vg = obj.vertex_groups.new(name=nm); w = w / tot
        for val in np.unique(np.round(w[w > 0.01], 2)):
            ids = np.nonzero(np.abs(np.round(w, 2) - val) < 1e-6)[0]
            vg.add(ids.tolist(), float(val), 'REPLACE')
    obj.parent = rig; m = obj.modifiers.new('Armature', 'ARMATURE'); m.object = rig

# partes de la malla baja: vecino más cercano en la escultura
def high_parts(o):
    me = o.data; n = len(me.vertices); co = np.zeros(n * 3, np.float32); me.vertices.foreach_get('co', co)
    pa = np.zeros(n, np.int32); me.attributes['part'].data.foreach_get('value', pa); return co.reshape(-1, 3), pa
hc, hpart = high_parts(body_h); tree = cKDTree(hc)
lc = np.zeros(len(body.data.vertices) * 3, np.float32); body.data.vertices.foreach_get('co', lc)
_, nn = tree.query(lc.reshape(-1, 3)); apply_weights(body, weights_for(body, hpart[nn]))
sk = np.zeros(len(skull.data.vertices) * 3, np.float32); skull.data.vertices.foreach_get('co', sk)
_, nn = tree.query(sk.reshape(-1, 3)); apply_weights(skull, weights_for(skull, hpart[nn]))
tc = np.zeros(len(teeth.data.vertices) * 3, np.float32); teeth.data.vertices.foreach_get('co', tc)
_, nn = tree.query(tc.reshape(-1, 3)); apply_weights(teeth, weights_for(teeth, hpart[nn]))
for side, w in wings.items():
    n = len(w.data.vertices); apply_weights(w, weights_for(w, np.zeros(n, np.int32) + BODY.PART['Wing' + side]))
body.name = 'Body'; skull.name = 'Skull'; wings['L'].name = 'WingL'; wings['R'].name = 'WingR'
log('pesos aplicados')

# ---------------- 4. exportación ----------------
for o in list(sc.objects):
    if o.name in ('Body_high',): pass
for o in (body_h, D.objects['WingBonesL'], D.objects['WingBonesR'], D.objects['MembraneL'], D.objects['MembraneR']):
    o.hide_render = True; o.hide_set(True)
game = [rig, body, skull, wings['L'], wings['R'], teeth]
select_only(game, rig)
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, 'ShadowDragon.fbx'), use_selection=True, object_types={'ARMATURE', 'MESH'},
                         axis_forward='-Z', axis_up='Y', apply_unit_scale=True, apply_scale_options='FBX_SCALE_NONE', add_leaf_bones=False,
                         bake_anim=False, path_mode='COPY', embed_textures=True, mesh_smooth_type='FACE', use_armature_deform_only=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, 'ShadowDragon.glb'), export_format='GLB', use_selection=True, export_skins=True,
                          export_animations=False, export_yup=True, export_apply=False)
log('FBX y GLB exportados')
tris = {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in game[1:]}
eyes = HPTS['eyes']
rigjson = {'name': 'ShadowDragon', 'units': 'studs', 'forward': '-Z', 'meshes': tris,
           'bones': [{'name': n, 'parent': p, 'head': [round(float(x), 4) for x in h], 'tail': [round(float(x), 4) for x in t]} for n, p, h, t in bones],
           'eyes': {'EyeL': eyes[0], 'EyeR': eyes[1], 'bone': 'Head'}}
lo = np.min([np.array(R(o.matrix_world @ Vector(c))) for o in game[1:] for c in o.bound_box], 0)
hi = np.max([np.array(R(o.matrix_world @ Vector(c))) for o in game[1:] for c in o.bound_box], 0)
rigjson['bounds'] = {'min': lo.round(3).tolist(), 'max': hi.round(3).tolist()}
json.dump(rigjson, open(os.path.join(OUT, 'rig.json'), 'w'), indent=1)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, 'ShadowDragon_game.blend'))
log('rig.json', tris)

# ---------------- 5. renders del modelo de juego ----------------
for o in list(sc.objects):
    if o.type == 'LIGHT' or o.type == 'CAMERA': D.objects.remove(o)
c = Vector((0, -1.0, 8.0))
key = PV.light('Key', c + Vector((-22, 16, 26)), 16000, (1, 0.96, 0.92), 14, c)
rim = PV.light('Rim', c + Vector((20, -30, 16)), 7000, (0.85, 0.9, 1), 12, c)
fill = PV.light('Fill', c + Vector((-10, 30, 2)), 1500, (1, 0.9, 0.9), 14, c)
top = PV.light('Top', c + Vector((0, 0, 30)), 6000, (1, 1, 1), 30, c)
cam = PV.camera()
headc = B(hp((0, -0.5, -1.4)))
shots = [('hero', c + Vector((-48, 46, 4)), c + Vector((0, 3, 0.0)), (1600, 1000), 40), ('side', c + Vector((-90, 1.0, 1.0)), c + Vector((0, 1.0, 0.5)), (1600, 900), 40), ('right', c + Vector((48, 36, 8)), c + Vector((0, 2.5, 0.0)), (1600, 1000), 42),
         ('front', c + Vector((0, 80, -1.0)), c + Vector((0, 0, 1.0)), (1100, 1000), 45), ('top', c + Vector((0, 0.01, 95)), c, (1600, 900), 40),
         ('head', headc + Vector((-7, 10, 1.0)), headc + Vector((0, 0.5, 0.0)), (1000, 1000), 45), ('headfront', headc + Vector((0, 15, 0.0)), headc + Vector((0, 0, 0.0)), (1000, 1000), 50),
         ('wing', c + Vector((-28, -16, 26)), B(np.array(BODY.WING['wrist'])) + Vector((0, -6, -3)), (1000, 1000), 35), ('tail', B(tail_pts[-2]) + Vector((-9, 5, 4)), B(tail_pts[-2]) + Vector((0, -1, 0)), (1000, 1000), 40)]
only = os.environ.get('ONLY', '')
for name, loc, at, res, lens in shots:
    if only and name not in only.split(','): continue
    PV.shoot(cam, os.path.join(REND, name + '.jpg'), loc, at, res, lens=lens, samples=SAMPLES)

# mirada: oscuridad total y solo dos puntos diminutos donde estarían los ojos
if not only or 'gaze' in only.split(','):
    for L_ in (key, rim, fill, top): L_.data.energy *= 0.004
    sc.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.05
    em = D.materials.new('EyePoint'); em.use_nodes = True; nt = em.node_tree; nt.nodes.clear()
    e = nt.nodes.new('ShaderNodeEmission'); e.inputs['Strength'].default_value = 60; e.inputs['Color'].default_value = (1, 0.04, 0.02, 1); o_ = nt.nodes.new('ShaderNodeOutputMaterial'); nt.links.new(e.outputs[0], o_.inputs[0])
    for p in eyes:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.06, location=B(p)); s_ = bpy.context.active_object; s_.data.materials.append(em)
    # la sonrisa: los dientes brillan un poco (en Roblox pasan a Neon de noche)
    tb.inputs['Emission Color'].default_value = (0.9, 0.88, 0.82, 1); tb.inputs['Emission Strength'].default_value = 1.6
    PV.shoot(cam, os.path.join(REND, 'gaze.jpg'), headc + Vector((-0.6, 16, 0.2)), headc + Vector((0, 0, -0.2)), (1200, 900), lens=50, samples=SAMPLES)
log('listo')
