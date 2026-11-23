/*
 * Planos de la pesca (bloques, estilo Roblox): tres peces comestibles (crudo y cocinado), la caña, la boya y la hoguera.
 * Los usan igual el instalador de Studio (tools/build_roblox.js los convierte en Luau) y el visor web.
 *
 * Cada modelo es una lista de bloques relativa al centro del Handle (el primer bloque): el pez es un Tool que se
 * lleva en la mano y se come con clic. Ejes: el pez mira a -Z, Y arriba, X a su derecha.
 * bloque: { name?, size, offset, rot (grados XYZ), color, material, kind }   kind decide cómo cambia al cocinarlo
 */
(function (root) {
const box = (size, offset, color, kind, x = {}) => ({ size, offset, color, kind, rot: x.rot || [0, 0, 0], material: x.material || 'SmoothPlastic', name: x.name });
const both = (list, size, offset, color, kind, x = {}) => {   // a los dos lados (X reflejada)
  const r = x.rot || [0, 0, 0];
  list.push(box(size, offset, color, kind, x));
  list.push(box(size, [-offset[0], offset[1], offset[2]], color, kind, Object.assign({}, x, { rot: [r[0], -r[1], -r[2]] })));
};

// ---------------------------------------------------------------- trucha: plateada y oliva, banda rosa y pintas oscuras
function trout() {
  const L = [], SK = [122, 132, 104], BK = [78, 96, 70], BE = [226, 218, 196], FN = [112, 118, 92], PK = [214, 128, 138], SP = [40, 44, 36];
  L.push(box([0.5, 0.62, 1.2], [0, 0, 0], SK, 'skin', { name: 'Handle' }));
  L.push(box([0.52, 0.16, 1.22], [0, 0.24, 0], BK, 'skin'));
  L.push(box([0.52, 0.18, 1.22], [0, -0.23, 0], BE, 'belly'));
  L.push(box([0.46, 0.54, 0.5], [0, 0.0, -0.82], SK, 'skin'));
  L.push(box([0.47, 0.14, 0.5], [0, 0.22, -0.82], BK, 'skin'));
  L.push(box([0.36, 0.34, 0.24], [0, -0.04, -1.18], SK, 'skin'));
  L.push(box([0.3, 0.04, 0.02], [0, -0.13, -1.31], [60, 40, 40], 'mouth'));
  L.push(box([0.32, 0.42, 0.46], [0, 0, 0.82], SK, 'skin'));
  L.push(box([0.33, 0.12, 0.47], [0, 0.17, 0.82], BK, 'skin'));
  for (const s of [-1, 1]) L.push(box([0.05, 0.36, 0.36], [0, s * 0.2, 1.2], FN, 'fin', { rot: [s * -22, 0, 0] }));
  L.push(box([0.05, 0.24, 0.42], [0, 0.42, -0.05], FN, 'fin', { rot: [12, 0, 0] }));
  L.push(box([0.05, 0.1, 0.14], [0, 0.26, 0.62], FN, 'fin'));
  L.push(box([0.05, 0.16, 0.26], [0, -0.38, 0.45], FN, 'fin', { rot: [-15, 0, 0] }));
  both(L, [0.26, 0.03, 0.18], [0.32, -0.16, -0.5], FN, 'fin', { rot: [0, 0, -25] });
  both(L, [0.18, 0.03, 0.14], [0.2, -0.32, 0.15], FN, 'fin', { rot: [0, 0, -15] });
  both(L, [0.02, 0.12, 1.1], [0.261, 0.03, 0.05], PK, 'band');
  both(L, [0.02, 0.1, 0.42], [0.231, 0.02, -0.82], PK, 'band');
  for (const [y, z] of [[0.16, -0.4], [0.12, -0.1], [0.18, 0.2], [0.1, 0.45], [-0.02, -0.25], [0.2, -0.65], [0.0, 0.3], [0.14, 0.75]]) both(L, [0.02, 0.06, 0.06], [z > 0.6 ? 0.17 : 0.262, y, z], SP, 'spot');
  both(L, [0.02, 0.15, 0.15], [0.236, 0.06, -0.88], [232, 222, 120], 'eye');
  both(L, [0.02, 0.07, 0.07], [0.246, 0.06, -0.89], [14, 12, 12], 'pupil');
  return L;
}
// ---------------------------------------------------------------- perca: verde amarillenta, barras oscuras y aletas naranjas
function perch() {
  const L = [], SK = [156, 162, 74], BK = [92, 104, 46], BE = [230, 222, 170], BAR = [52, 62, 30], OR = [222, 96, 40], FN = [130, 128, 70];
  L.push(box([0.46, 0.72, 1.1], [0, 0, 0], SK, 'skin', { name: 'Handle' }));
  L.push(box([0.48, 0.18, 1.12], [0, 0.29, 0], BK, 'skin'));
  L.push(box([0.48, 0.2, 1.12], [0, -0.28, 0], BE, 'belly'));
  L.push(box([0.42, 0.58, 0.44], [0, -0.02, -0.76], SK, 'skin'));
  L.push(box([0.43, 0.15, 0.45], [0, 0.22, -0.76], BK, 'skin'));
  L.push(box([0.32, 0.32, 0.2], [0, -0.08, -1.06], SK, 'skin'));
  L.push(box([0.28, 0.04, 0.02], [0, -0.16, -1.17], [60, 40, 40], 'mouth'));
  L.push(box([0.28, 0.4, 0.4], [0, -0.02, 0.74], SK, 'skin'));
  for (const s of [-1, 1]) L.push(box([0.05, 0.34, 0.32], [0, s * 0.19, 1.06], FN, 'fin', { rot: [s * -20, 0, 0] }));
  for (let i = 0; i < 5; i++) L.push(box([0.04, 0.3 - Math.abs(i - 1.5) * 0.04, 0.04], [0, 0.5, -0.42 + i * 0.12], [60, 60, 40], 'fin', { rot: [15, 0, 0] }));
  L.push(box([0.03, 0.2, 0.5], [0, 0.46, -0.18], [176, 150, 80], 'fin', { rot: [8, 0, 0] }));
  L.push(box([0.04, 0.2, 0.32], [0, 0.46, 0.35], FN, 'fin', { rot: [10, 0, 0] }));
  L.push(box([0.05, 0.2, 0.26], [0, -0.44, 0.36], OR, 'fin', { rot: [-15, 0, 0] }));
  both(L, [0.2, 0.03, 0.2], [0.18, -0.4, -0.3], OR, 'fin', { rot: [0, 0, -30] });
  both(L, [0.24, 0.03, 0.16], [0.3, -0.12, -0.45], FN, 'fin', { rot: [0, 0, -25] });
  for (let i = 0; i < 5; i++) both(L, [0.02, 0.48 - Math.abs(i - 2) * 0.06, 0.1], [0.241, 0.08, -0.4 + i * 0.22], BAR, 'spot');
  both(L, [0.02, 0.17, 0.17], [0.216, 0.06, -0.82], [240, 170, 50], 'eye');
  both(L, [0.02, 0.08, 0.08], [0.226, 0.06, -0.83], [14, 12, 12], 'pupil');
  return L;
}
// ---------------------------------------------------------------- salmón dorado (raro): dorado brillante, aletas rojizas, mandíbula ganchuda
function golden() {
  const L = [], SK = [226, 172, 62], BK = [176, 116, 36], BE = [250, 232, 186], PK = [240, 140, 108], FN = [206, 92, 66], F = { material: 'Foil' };
  L.push(box([0.56, 0.66, 1.5], [0, 0, 0], SK, 'skin', Object.assign({ name: 'Handle' }, F)));
  L.push(box([0.58, 0.16, 1.52], [0, 0.26, 0], BK, 'skin', F));
  L.push(box([0.58, 0.18, 1.52], [0, -0.25, 0], BE, 'belly'));
  L.push(box([0.5, 0.56, 0.56], [0, 0.0, -1.02], SK, 'skin', F));
  L.push(box([0.51, 0.14, 0.57], [0, 0.22, -1.02], BK, 'skin', F));
  L.push(box([0.4, 0.3, 0.3], [0, -0.04, -1.42], SK, 'skin', F));
  L.push(box([0.34, 0.12, 0.12], [0, -0.2, -1.55], SK, 'skin', { material: 'Foil', rot: [-25, 0, 0] }));   // gancho de la mandíbula
  L.push(box([0.32, 0.04, 0.02], [0, -0.13, -1.58], [70, 36, 30], 'mouth'));
  L.push(box([0.34, 0.44, 0.5], [0, 0, 1.0], SK, 'skin', F));
  for (const s of [-1, 1]) L.push(box([0.05, 0.44, 0.42], [0, s * 0.24, 1.42], FN, 'fin', { rot: [s * -26, 0, 0] }));
  L.push(box([0.05, 0.3, 0.5], [0, 0.46, -0.1], FN, 'fin', { rot: [14, 0, 0] }));
  L.push(box([0.05, 0.12, 0.16], [0, 0.28, 0.78], FN, 'fin'));
  L.push(box([0.05, 0.18, 0.3], [0, -0.4, 0.58], FN, 'fin', { rot: [-15, 0, 0] }));
  both(L, [0.3, 0.03, 0.2], [0.36, -0.16, -0.62], FN, 'fin', { rot: [0, 0, -25] });
  both(L, [0.2, 0.03, 0.16], [0.24, -0.33, 0.2], FN, 'fin', { rot: [0, 0, -15] });
  both(L, [0.02, 0.14, 1.36], [0.291, 0.0, 0.05], PK, 'band');
  for (const [y, z] of [[0.18, -0.5], [0.2, 0.0], [0.15, 0.4], [0.2, 0.75]]) both(L, [0.02, 0.05, 0.05], [0.292, y, z], [255, 236, 150], 'spot', { material: 'Neon' });
  both(L, [0.02, 0.16, 0.16], [0.256, 0.06, -1.08], [250, 230, 150], 'eye');
  both(L, [0.02, 0.08, 0.08], [0.266, 0.06, -1.09], [14, 12, 12], 'pupil');
  return L;
}

// cocinado: piel tostada, vientre dorado, aletas chamuscadas, ojos blancos y marcas de parrilla
const mix = (a, b, t) => a.map((v, i) => Math.round(v + (b[i] - v) * t));
function cooked(list) {
  const out = list.map(p => {
    const q = Object.assign({}, p, { material: p.material === 'Foil' || p.material === 'Neon' ? 'SmoothPlastic' : p.material });
    if (p.kind === 'skin') q.color = mix(p.color, [150, 88, 42], 0.65);
    else if (p.kind === 'belly') q.color = [204, 156, 98];
    else if (p.kind === 'band') q.color = mix(p.color, [160, 90, 50], 0.6);
    else if (p.kind === 'fin') q.color = [66, 42, 26];
    else if (p.kind === 'spot') q.color = [70, 44, 26];
    else if (p.kind === 'eye') q.color = [236, 232, 222];
    else if (p.kind === 'pupil') q.color = [120, 114, 104];
    return q;
  });
  const body = list[0], w = body.size[0] / 2 + 0.012;
  for (let i = 0; i < 4; i++) for (const s of [-1, 1]) out.push(box([0.02, body.size[1] * 0.9, 0.07], [s * w, 0, -body.size[2] * 0.36 + i * body.size[2] * 0.24], [40, 24, 14], 'grill', { rot: [-30, 0, 0] }));
  return out;
}

// ---------------------------------------------------------------- caña: mango de corcho, carrete, puntera fina y anillas
function rod() {
  const L = [], CORK = [196, 156, 104], BLK = [26, 26, 30], GOLD = [210, 170, 70], MET = [150, 150, 156];
  L.push(box([0.28, 0.28, 1.3], [0, 0, 0], CORK, 'rod', { name: 'Handle', material: 'Wood' }));
  L.push(box([0.32, 0.32, 0.14], [0, 0, 0.7], BLK, 'rod'));
  L.push(box([0.32, 0.32, 0.12], [0, 0, -0.68], BLK, 'rod'));
  // carrete bajo el mango, con su manivela
  L.push(box([0.08, 0.18, 0.08], [0, -0.22, -0.2], MET, 'rod', { material: 'Metal' }));
  L.push(box([0.36, 0.36, 0.22], [0, -0.42, -0.2], MET, 'rod', { material: 'Metal' }));
  L.push(box([0.38, 0.12, 0.12], [0, -0.42, -0.2], GOLD, 'rod', { material: 'Metal' }));
  L.push(box([0.04, 0.24, 0.04], [0.24, -0.5, -0.2], BLK, 'rod'));
  L.push(box([0.08, 0.08, 0.12], [0.26, -0.62, -0.2], BLK, 'rod'));
  // la caña: segmentos que se afinan hacia la punta, un poco levantada
  const tilt = 8 * Math.PI / 180;
  let z = -0.74, segs = 6;
  for (let i = 0; i < segs; i++) {
    const len = 1.0, th = 0.13 - i * 0.016, zc = z - len / 2;
    L.push(box([th, th, len], [0, -zc * Math.sin(tilt), zc * Math.cos(tilt)], BLK, 'rod', { rot: [tilt * 180 / Math.PI, 0, 0], name: i === segs - 1 ? 'Tip' : undefined }));
    if (i % 2 === 1) L.push(box([th + 0.04, th + 0.04, 0.06], [0, -(z - len) * Math.sin(tilt), (z - len) * Math.cos(tilt)], GOLD, 'rod', { rot: [tilt * 180 / Math.PI, 0, 0] }));
    L.push(box([0.03, 0.12, 0.03], [0, -(zc) * Math.sin(tilt) - th / 2 - 0.05, zc * Math.cos(tilt)], MET, 'rod', { material: 'Metal' }));
    z -= len;
  }
  return L;
}
// punta de la caña (donde se ata el sedal), en el espacio del Handle
const ROD_TIP = (() => { const tilt = 8 * Math.PI / 180, z = -0.74 - 6; return [0, -z * Math.sin(tilt), z * Math.cos(tilt)]; })();

// boya roja y blanca
function bobber() {
  return [
    box([0.3, 0.16, 0.3], [0, 0.07, 0], [220, 40, 36], 'rod', { name: 'Handle' }),
    box([0.3, 0.14, 0.3], [0, -0.08, 0], [240, 240, 236], 'rod'),
    box([0.06, 0.18, 0.06], [0, 0.24, 0], [220, 40, 36], 'rod'),
    box([0.04, 0.1, 0.04], [0, -0.2, 0], [30, 30, 30], 'rod'),
  ];
}
// hoguera para cocinar: troncos cruzados, piedras y llamas
function campfire() {
  const L = [], LOG = [92, 62, 40], ST = [110, 108, 104];
  L.push(box([2.6, 0.2, 2.6], [0, 0.1, 0], [40, 34, 30], 'rod', { name: 'Handle', material: 'Slate' }));
  for (let i = 0; i < 4; i++) L.push(box([0.35, 0.35, 2.2], [0, 0.42, 0], LOG, 'rod', { material: 'Wood', rot: [i % 2 ? 18 : -18, i * 45, 0] }));
  for (let i = 0; i < 9; i++) { const a = i / 9 * Math.PI * 2; L.push(box([0.6, 0.4, 0.45], [Math.cos(a) * 1.35, 0.25, Math.sin(a) * 1.35], ST, 'rod', { material: 'Slate', rot: [0, -a * 180 / Math.PI, 0] })); }
  L.push(box([0.7, 0.9, 0.7], [0, 0.85, 0], [255, 120, 30], 'fire', { material: 'Neon', rot: [0, 20, 0] }));
  L.push(box([0.4, 1.3, 0.4], [0.1, 1.0, 0.05], [255, 190, 60], 'fire', { material: 'Neon', rot: [0, 50, 8] }));
  L.push(box([0.3, 0.8, 0.3], [-0.25, 0.8, -0.1], [255, 90, 20], 'fire', { material: 'Neon', rot: [0, 10, -10] }));
  return L;
}

const FISH = { Trout: trout(), Perch: perch(), GoldenSalmon: golden() };
const MODELS = {};
for (const [k, v] of Object.entries(FISH)) { MODELS[k] = v; MODELS[k + '_Cooked'] = cooked(v); }
MODELS.FishingRod = rod(); MODELS.Bobber = bobber(); MODELS.Campfire = campfire();
// especies: probabilidad (Weight), dificultad al recoger (Drain: cuánto se escapa por segundo) y lo que da al comer
const SPECIES = {
  Trout: { DisplayName: 'Trucha', Weight: 60, Drain: 14, Raw: { Heal: 8, Food: 15 }, Cooked: { Heal: 25, Food: 35 } },
  Perch: { DisplayName: 'Perca', Weight: 30, Drain: 18, Raw: { Heal: 6, Food: 12 }, Cooked: { Heal: 20, Food: 30 } },
  GoldenSalmon: { DisplayName: 'Salmón dorado', Weight: 10, Drain: 26, Raw: { Heal: 15, Food: 25 }, Cooked: { Heal: 50, Food: 60 } },
};
root.FISHING_MODELS = MODELS;
root.FISHING_SPECIES = SPECIES;
root.FISHING_ROD_TIP = ROD_TIP;
})(typeof window !== 'undefined' ? window : globalThis);
