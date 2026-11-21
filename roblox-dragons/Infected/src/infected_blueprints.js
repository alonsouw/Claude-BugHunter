/*
 * Planos de los infectados: personajes de bloques al estilo Roblox (Parts), cinco tipos.
 * Los usan igual el instalador de Studio (tools/build_roblox.js los convierte en Luau) y el visor web.
 *
 * Espacio del modelo: Y arriba, mira a -Z, izquierda = -X, studs, suelo en y = 0.
 * Rig: HumanoidRootPart → Torso → Head → Jaw; Torso → {Left,Right}UpperArm → LowerArm; Torso → {Left,Right}UpperLeg → LowerLeg.
 * Cada articulación es un Motor6D con C0/C1 sin rotación, situado en su pivote: las animaciones giran en los ejes del modelo.
 *
 * limbs:   { nombre: { size, center, color, material } }
 * joints:  [ [padre, hijo, pivote] ]
 * details: [ { limb, size, offset (desde el centro de la pieza), rot (grados), color, material, neon } ]
 */
(function (root) {
const C = {   // paleta (RGB 0-255)
  skin: [118, 134, 104], skinDark: [86, 98, 78], skinPale: [168, 172, 150], rot: [92, 104, 60],
  blood: [96, 14, 18], bloodDark: [60, 8, 10], wound: [140, 36, 40], bone: [214, 204, 180], gut: [150, 60, 66],
  pus: [196, 206, 70], eye: [210, 255, 90], eyeRed: [255, 60, 40], mouth: [30, 8, 10], teeth: [220, 210, 170],
  hair: [40, 32, 28],
};
// ropa sucia: camisa y pantalón (se eligen por tipo)
const SHIRTS = [[92, 104, 128], [128, 64, 58], [88, 96, 72], [150, 140, 120], [60, 70, 92]];
const PANTS = [[52, 62, 88], [70, 58, 46], [44, 44, 48]];

function rng(seed) { let s = seed >>> 0; return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 4294967296); }

// rig base (proporciones de un personaje de bloques)
function baseRig(o = {}) {
  const aw = o.armW || 1, lw = o.legW || 1, tw = o.torsoW || 2, td = o.torsoD || 1, th = o.torsoH || 2;
  const armLen = o.armLen || 1, hs = o.head || 1.15;
  const hipY = 2.15, top = hipY + th, sx = tw / 2 + aw / 2;
  const ua = 1.1 * armLen, la = 1.1 * armLen;
  const limbs = {
    HumanoidRootPart: { size: [2, 2, 1], center: [0, hipY + 1, 0], transparent: true },
    Torso: { size: [tw, th, td], center: [0, hipY + th / 2, 0], color: o.shirt, material: 'Fabric' },
    Head: { size: [hs, hs, hs], center: [0, top + hs / 2 + 0.02, 0], color: o.skin, material: 'SmoothPlastic' },
    Jaw: { size: [hs * 0.7, 0.26, hs * 0.42], center: [0, top + 0.17, -hs * 0.36], color: o.skin, material: 'SmoothPlastic' },
    LeftUpperArm: { size: [aw, ua, aw], center: [-sx, top - 0.05 - ua / 2, 0], color: o.sleeve || o.shirt, material: 'Fabric' },
    RightUpperArm: { size: [aw, ua, aw], center: [sx, top - 0.05 - ua / 2, 0], color: o.sleeve || o.shirt, material: 'Fabric' },
    LeftLowerArm: { size: [aw * 0.9, la, aw * 0.9], center: [-sx, top - 0.05 - ua - la / 2, 0], color: o.skin, material: 'SmoothPlastic' },
    RightLowerArm: { size: [aw * 0.9, la, aw * 0.9], center: [sx, top - 0.05 - ua - la / 2, 0], color: o.skin, material: 'SmoothPlastic' },
    LeftUpperLeg: { size: [lw * 0.95, 1.1, lw * 0.95], center: [-0.5 * lw, hipY - 0.55, 0], color: o.pants, material: 'Fabric' },
    RightUpperLeg: { size: [lw * 0.95, 1.1, lw * 0.95], center: [0.5 * lw, hipY - 0.55, 0], color: o.pants, material: 'Fabric' },
    LeftLowerLeg: { size: [lw * 0.9, 1.05, lw * 0.9], center: [-0.5 * lw, 0.525, 0], color: o.pants, material: 'Fabric' },
    RightLowerLeg: { size: [lw * 0.9, 1.05, lw * 0.9], center: [0.5 * lw, 0.525, 0], color: o.pants, material: 'Fabric' },
  };
  const joints = [
    ['HumanoidRootPart', 'Torso', [0, hipY + th / 2, 0]],
    ['Torso', 'Head', [0, top, 0]],
    ['Head', 'Jaw', [0, top + 0.3, -hs * 0.12]],
    ['Torso', 'LeftUpperArm', [-sx, top - 0.35, 0]], ['LeftUpperArm', 'LeftLowerArm', [-sx, top - 0.05 - ua, 0]],
    ['Torso', 'RightUpperArm', [sx, top - 0.35, 0]], ['RightUpperArm', 'RightLowerArm', [sx, top - 0.05 - ua, 0]],
    ['Torso', 'LeftUpperLeg', [-0.5 * lw, hipY, 0]], ['LeftUpperLeg', 'LeftLowerLeg', [-0.5 * lw, 1.05, 0]],
    ['Torso', 'RightUpperLeg', [0.5 * lw, hipY, 0]], ['RightUpperLeg', 'RightLowerLeg', [0.5 * lw, 1.05, 0]],
  ];
  return { limbs, joints, hipHeight: hipY, height: top + hs };
}

// detalles comunes de un infectado (todos son bloques soldados a su pieza)
function common(bp, r, o) {
  const D = bp.details, L = bp.limbs, hs = L.Head.size[0], h2 = hs / 2;
  const add = (limb, size, offset, color, extra = {}) => D.push({ limb, size, offset, color, material: extra.material || 'SmoothPlastic', rot: extra.rot || [0, 0, 0], neon: !!extra.neon });
  // ojos que brillan, hundidos, y cuencas oscuras
  for (const s of [-1, 1]) {
    add('Head', [0.3, 0.2, 0.06], [s * 0.25 * hs / 1.15, 0.1, -h2 - 0.005], C.mouth);
    add('Head', [0.15, 0.1, 0.06], [s * 0.25 * hs / 1.15, 0.1, -h2 - 0.02], o.eye || C.eye, { neon: true });
  }
  // boca: hueco oscuro, dientes y mandíbula colgando
  add('Head', [0.62, 0.22, 0.06], [0, -0.33, -h2 - 0.005], C.mouth);
  for (let i = 0; i < 5; i++) add('Head', [0.07, 0.09, 0.05], [-0.22 + i * 0.11, -0.25, -h2 - 0.02], C.teeth);
  for (let i = 0; i < 4; i++) add('Jaw', [0.07, 0.08, 0.05], [-0.17 + i * 0.11, 0.1, -L.Jaw.size[2] / 2 - 0.01], C.teeth);
  add('Jaw', [L.Jaw.size[0] * 0.8, 0.06, 0.05], [0, -0.1, -L.Jaw.size[2] / 2 - 0.01], C.blood);
  // pelo ralo y calvas
  add('Head', [hs * 1.02, 0.12, hs * 0.7], [0, h2 + 0.03, 0.12], C.hair);
  add('Head', [0.3, 0.13, 0.3], [0.2, h2 + 0.06, -0.15], C.rot);
  // sangre que baja de la boca al pecho
  add('Head', [0.2, 0.35, 0.04], [0.12, -0.5, -h2 - 0.01], C.blood);
  add('Torso', [0.35, 0.9, 0.04], [0.15, L.Torso.size[1] / 2 - 0.5, -L.Torso.size[2] / 2 - 0.01], C.blood);
  add('Torso', [0.22, 0.4, 0.04], [0.4, L.Torso.size[1] / 2 - 1.1, -L.Torso.size[2] / 2 - 0.01], C.bloodDark);
  // ropa rota: jirones y agujeros con la piel o la herida debajo
  const tw = L.Torso.size[0], th = L.Torso.size[1], td = L.Torso.size[2];
  for (let i = 0; i < 6; i++) {
    const x = (r() - 0.5) * tw * 0.8, y = (r() - 0.5) * th * 0.7, w = 0.25 + r() * 0.35, h = 0.2 + r() * 0.35;
    const front = r() < 0.6;
    add('Torso', [w, h, 0.05], [x, y, front ? -td / 2 - 0.012 : td / 2 + 0.012], r() < 0.5 ? o.skin : C.wound);
    if (r() < 0.5) add('Torso', [w * 0.5, h * 0.5, 0.05], [x, y, front ? -td / 2 - 0.03 : td / 2 + 0.03], C.blood);
  }
  for (let i = 0; i < 5; i++) {   // flecos colgando del borde de la camisa
    const x = -tw / 2 + 0.2 + r() * (tw - 0.4);
    add('Torso', [0.18 + r() * 0.15, 0.2 + r() * 0.25, 0.08], [x, -th / 2 - 0.12, -td / 2 + 0.04], o.shirt, { material: 'Fabric', rot: [0, 0, (r() - 0.5) * 30] });
  }
  // costillas al aire en un costado
  const sx = r() < 0.5 ? -1 : 1;
  add('Torso', [0.06, 0.8, 0.6], [sx * (tw / 2 + 0.01), 0.1, -0.05], C.wound);
  for (let i = 0; i < 4; i++) add('Torso', [0.07, 0.08, 0.5], [sx * (tw / 2 + 0.03), 0.4 - i * 0.2, -0.05], C.bone);
  // brazos: manga rota, piel con heridas, manos con dedos de bloque
  for (const s of ['Left', 'Right']) {
    const la = L[s + 'LowerArm'], ua = L[s + 'UpperArm'];
    add(s + 'UpperArm', [ua.size[0] * 1.04, 0.18, ua.size[2] * 1.04], [0, -ua.size[1] / 2 + 0.05, 0], o.shirt, { material: 'Fabric', rot: [0, 0, s === 'Left' ? 8 : -8] });
    add(s + 'LowerArm', [la.size[0] * 0.7, 0.3, 0.05], [0, 0.1, -la.size[2] / 2 - 0.01], r() < 0.5 ? C.wound : C.rot);
    for (let f = 0; f < 3; f++) add(s + 'LowerArm', [0.16, 0.35, 0.16], [-0.25 + f * 0.25, -la.size[1] / 2 - 0.12, -0.15], o.skin);
    add(s + 'LowerArm', [0.04, 0.05, 0.04], [-0.25, -la.size[1] / 2 - 0.31, -0.15], C.blood);
  }
  // pantalón roto, zapatos
  for (const s of ['Left', 'Right']) {
    const ll = L[s + 'LowerLeg'];
    add(s + 'LowerLeg', [ll.size[0] * 1.05, 0.32, ll.size[2] * 1.35], [0, -ll.size[1] / 2 + 0.16, -0.15], [36, 30, 28]);
    if (r() < 0.6) add(s + 'LowerLeg', [0.4, 0.35, 0.05], [0.1, 0.15, -ll.size[2] / 2 - 0.01], o.skin);
  }
  if (r() < 0.7) add('RightUpperLeg', [0.5, 0.3, 0.05], [0, 0.1, -0.49], C.blood);
}

function make(name, seed, rigOpts, colors, extra) {
  const r = rng(seed);
  const o = Object.assign({ skin: C.skin, shirt: SHIRTS[seed % SHIRTS.length], pants: PANTS[seed % PANTS.length] }, colors);
  const bp = Object.assign(baseRig(Object.assign({}, rigOpts, o)), { name, details: [] });
  common(bp, r, o);
  if (extra) extra(bp, r, o, (limb, size, offset, color, x = {}) => bp.details.push({ limb, size, offset, color, material: x.material || 'SmoothPlastic', rot: x.rot || [0, 0, 0], neon: !!x.neon }));
  return bp;
}

const BLUEPRINTS = {
  // el común: arrastra los pies con los brazos por delante
  Walker: make('Walker', 3, {}, {}, (bp, r, o, add) => {
    add('Head', [0.4, 0.25, 0.05], [-0.25, 0.32, -0.585], [150, 40, 44]);                 // tajo en la frente
  }),
  // el corredor: flaco, encorvado, la camisa casi arrancada; muy rápido
  Runner: make('Runner', 7, { armW: 0.8, legW: 0.85, torsoW: 1.7, torsoD: 0.8, armLen: 1.12, head: 1.05 },
    { skin: C.skinPale, shirt: [150, 140, 120], eye: C.eyeRed }, (bp, r, o, add) => {
      const T = bp.limbs.Torso.size;
      add('Torso', [T[0] * 0.95, 0.9, 0.05], [0, -0.3, -T[2] / 2 - 0.02], C.skinPale);      // pecho al aire
      for (let i = 0; i < 4; i++) add('Torso', [0.9, 0.06, 0.05], [0, -0.05 - i * 0.18, -T[2] / 2 - 0.04], C.skinDark);   // costillas marcadas
      add('Torso', [0.35, 0.35, 0.05], [0.4, -0.7, -T[2] / 2 - 0.05], C.wound);
    }),
  // el hinchado: enorme torso lleno de pústulas; explota al morir
  Bloater: make('Bloater', 11, { torsoW: 2.9, torsoD: 2.1, torsoH: 2.3, armW: 1.15, legW: 1.2, head: 1.1 },
    { skin: C.rot, shirt: [120, 126, 96], eye: C.eye }, (bp, r, o, add) => {
      const T = bp.limbs.Torso.size;
      for (let i = 0; i < 22; i++) {   // pústulas: cubos amarillo verdosos que brillan un poco
        const face = Math.floor(r() * 4), s = 0.22 + r() * 0.35;
        const off = face === 0 ? [(r() - 0.5) * T[0] * 0.85, (r() - 0.5) * T[1] * 0.8, -T[2] / 2 - s * 0.3] :
                    face === 1 ? [(r() - 0.5) * T[0] * 0.85, (r() - 0.5) * T[1] * 0.8, T[2] / 2 + s * 0.3] :
                    [(face === 2 ? -1 : 1) * (T[0] / 2 + s * 0.3), (r() - 0.5) * T[1] * 0.8, (r() - 0.5) * T[2] * 0.8];
        add('Torso', [s, s, s], off, i % 3 ? C.pus : [150, 170, 60], { neon: i % 4 === 0, rot: [r() * 40, r() * 40, r() * 40] });
      }
      add('Torso', [T[0] * 0.6, 0.12, 0.05], [0, -0.5, -T[2] / 2 - 0.02], C.gut);           // costura reventada
      add('Head', [0.3, 0.3, 0.3], [0.4, 0.3, -0.4], C.pus, { neon: true });
    }),
  // el gritón: brazos larguísimos, cabeza partida con la boca enorme; grita y atrae a los demás
  Screamer: make('Screamer', 5, { armW: 0.75, armLen: 1.45, torsoW: 1.8, torsoD: 0.85, head: 1.2 },
    { skin: C.skinPale, shirt: [40, 40, 46], eye: [255, 255, 255] }, (bp, r, o, add) => {
      const hs = bp.limbs.Head.size[0];
      add('Head', [0.9, 0.55, 0.06], [0, -0.2, -hs / 2 - 0.02], C.mouth);                    // boca enorme
      for (let i = 0; i < 7; i++) add('Head', [0.07, 0.12, 0.05], [-0.36 + i * 0.12, 0.03, -hs / 2 - 0.04], C.teeth);
      add('Head', [0.08, hs * 1.02, hs * 1.02], [0.15, 0.05, 0], C.wound);                  // cráneo partido
      add('Head', [0.05, hs * 0.9, 0.05], [0.15, 0.05, -hs / 2 - 0.03], C.bone);
    }),
  // el bruto: enorme, con el brazo derecho deforme lleno de hueso; golpea el suelo
  Brute: make('Brute', 9, { torsoW: 2.6, torsoD: 1.4, torsoH: 2.3, armW: 1.2, legW: 1.25, head: 1.15 },
    { skin: C.skinDark, shirt: [70, 58, 48], eye: C.eyeRed }, (bp, r, o, add) => {
      const RA = bp.limbs.RightUpperArm, RL = bp.limbs.RightLowerArm;
      add('RightUpperArm', [RA.size[0] * 1.35, RA.size[1], RA.size[2] * 1.35], [0.12, 0, 0], C.rot);    // brazo hinchado
      add('RightLowerArm', [RL.size[0] * 1.8, RL.size[1] * 1.2, RL.size[2] * 1.8], [0.15, -0.15, 0], C.skinDark);
      for (let i = 0; i < 5; i++) add('RightLowerArm', [0.16, 0.5, 0.16], [0.35 + (i % 2) * 0.2, 0.3 - i * 0.25, -0.5 + i * 0.25], C.bone, { rot: [30, 0, -40] });   // púas de hueso
      add('RightLowerArm', [1.2, 0.5, 1.2], [0.15, -0.9, 0], C.skinDark);                    // puño enorme
      for (let i = 0; i < 4; i++) add('Torso', [0.25, 0.4, 0.25], [-0.9 + i * 0.6, 1.2, 0.5], C.bone, { rot: [-30, 0, 0] });   // espinazo que asoma
      add('Torso', [1.0, 0.8, 0.05], [-0.4, 0.2, -0.72], C.wound);
    }),
};
const STATS = {   // también en Luau (InfectedSpawner usa estos valores; se pueden cambiar en Settings)
  Walker: { Health: 100, Damage: 15, WalkSpeed: 5, ChaseSpeed: 9, Detect: 55, Reach: 4, Cooldown: 1.4, Scale: 1 },
  Runner: { Health: 60, Damage: 10, WalkSpeed: 7, ChaseSpeed: 22, Detect: 75, Reach: 4, Cooldown: 0.9, Scale: 1 },
  Bloater: { Health: 140, Damage: 10, WalkSpeed: 4, ChaseSpeed: 6, Detect: 45, Reach: 4.5, Cooldown: 1.8, Scale: 1, ExplodeDamage: 35, ExplodeRadius: 12 },
  Screamer: { Health: 70, Damage: 8, WalkSpeed: 6, ChaseSpeed: 13, Detect: 80, Reach: 5, Cooldown: 1.2, Scale: 1, ScreamRadius: 120, ScreamCooldown: 25 },
  Brute: { Health: 400, Damage: 35, WalkSpeed: 5, ChaseSpeed: 8, Detect: 60, Reach: 7, Cooldown: 2.6, Scale: 1.4, SlamRadius: 8 },
};
root.INFECTED_BLUEPRINTS = BLUEPRINTS;
root.INFECTED_STATS = STATS;
})(typeof window !== 'undefined' ? window : globalThis);
