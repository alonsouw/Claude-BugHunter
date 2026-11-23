/*
 * Planos del pez infectado: criatura de bloques al estilo Roblox (Parts), dos variantes: Normal y Gigante.
 * Los usan igual el instalador de Studio (tools/build_roblox.js los convierte en Luau) y el visor web.
 *
 * Espacio del modelo: Y arriba, mira a -Z, izquierda = -X, studs, centro del pez en el origen.
 * Rig: Root (invisible, lo mueve el servidor) → Body → Head → Jaw; Body → Mid → Tail → TailFin; Body → {Left,Right}Fin.
 * Cada articulación es un Motor6D con C0/C1 sin rotación, situado en su pivote.
 *
 * limbs:   { nombre: { size, center, color, material } }
 * joints:  [ [padre, hijo, pivote] ]
 * details: [ { limb, size, offset (desde el centro de la pieza), rot (grados XYZ), color, material, neon } ]
 */
(function (root) {
const D2R = Math.PI / 180;
const C = {
  back: [58, 70, 62], side: [104, 116, 96], scale: [90, 102, 84], belly: [184, 182, 150], rot: [88, 100, 56],
  flesh: [168, 92, 88], fleshDark: [120, 58, 56], wound: [140, 36, 40], blood: [70, 10, 14], bone: [214, 204, 180], boneDark: [176, 166, 138],
  pus: [190, 232, 70], eye: [214, 255, 96], mouth: [28, 8, 10], gum: [120, 32, 42], teeth: [228, 220, 190], fin: [80, 92, 80], worm: [206, 196, 164],
};

function fish(giant) {
  const P = Object.assign({}, C);
  if (giant) Object.assign(P, { back: [38, 46, 44], side: [74, 86, 74], scale: [62, 72, 62], fin: [56, 66, 60], belly: [160, 158, 128] });
  const limbs = {
    Root: { size: [1, 1, 1], center: [0, 0, 0], transparent: true },
    Body: { size: [1.3, 1.9, 1.6], center: [0, 0, 0], color: P.side },
    Head: { size: [1.15, 1.35, 1.1], center: [0, 0.1, -1.35], color: P.side },
    Jaw: { size: [1.0, 0.34, 1.15], center: [0, -0.7, -1.42], color: P.side },
    Mid: { size: [1.1, 1.5, 1.25], center: [0, -0.02, 1.4], color: P.side },
    Tail: { size: [0.34, 0.34, 1.1], center: [0, 0, 2.55], color: P.bone },
    TailFin: { size: [0.14, 0.3, 0.25], center: [0, 0, 3.2], color: P.bone },
    LeftFin: { size: [0.75, 0.07, 0.45], center: [-1.0, -0.4, -0.4], color: P.fin },
    RightFin: { size: [0.75, 0.07, 0.45], center: [1.0, -0.4, -0.4], color: P.fin },
  };
  const joints = [
    ['Root', 'Body', [0, 0, 0]],
    ['Body', 'Head', [0, 0, -0.8]], ['Head', 'Jaw', [0, -0.6, -0.85]],
    ['Body', 'Mid', [0, 0, 0.8]], ['Mid', 'Tail', [0, 0, 2.0]], ['Tail', 'TailFin', [0, 0, 3.1]],
    ['Body', 'LeftFin', [-0.64, -0.4, -0.4]], ['Body', 'RightFin', [0.64, -0.4, -0.4]],
  ];
  const details = [];
  const add = (limb, size, offset, color, x = {}) => details.push({ limb, size, offset, color, material: x.material || 'SmoothPlastic', rot: x.rot || [0, 0, 0], neon: !!x.neon });
  const tiles = (limb, s, x, rows, cols, y0, z0, skip = () => false) => {   // escamas: placas finas en filas alternas
    for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) if (!skip(r, c)) add(limb, [0.04, 0.2, 0.3], [s * x, y0 - r * 0.28, z0 + c * 0.37 + (r % 2) * 0.18], (r + c) % 2 ? P.scale : P.side);
  };
  // ---------- cuerpo: lomo oscuro, vientre claro, escamas; herida abierta con costillas (derecha) y pústulas (izquierda)
  add('Body', [1.32, 0.4, 1.62], [0, 0.78, 0], P.back);
  add('Body', [1.32, 0.36, 1.62], [0, -0.8, 0], P.belly);
  tiles('Body', 1, 0.66, 3, 4, 0.3, -0.62, (r, c) => c === 1 || c === 2);
  tiles('Body', -1, 0.66, 3, 4, 0.3, -0.62, (r, c) => c >= 2 && r >= 1);
  add('Body', [0.04, 0.95, 0.85], [0.665, -0.05, 0.05], P.blood);
  add('Body', [0.03, 0.75, 0.65], [0.672, -0.05, 0.05], P.wound);
  for (let i = 0; i < 4; i++) add('Body', [0.06, 0.85, 0.07], [0.7, -0.05, -0.24 + i * 0.16], P.bone, { rot: [i % 2 ? 6 : -6, 0, 0] });
  for (const [y, z] of [[0.42, -0.2], [0.42, 0.25], [-0.5, -0.1], [-0.5, 0.3]]) add('Body', [0.06, 0.12, 0.2], [0.69, y, z], P.flesh, { rot: [y > 0 ? 20 : -20, 0, 0] });
  add('Body', [0.04, 0.72, 0.72], [-0.665, -0.12, 0.28], P.rot);
  for (const [y, z, s] of [[0.05, 0.1, 0.2], [-0.2, 0.35, 0.16], [0.15, 0.45, 0.12], [-0.35, 0.05, 0.14], [-0.05, 0.55, 0.1], [0.2, 0.25, 0.1]]) add('Body', [s * 0.8, s, s], [-0.69 - s * 0.2, y, z], P.pus, { neon: true });
  // aleta dorsal rota: radios de hueso con jirones de membrana
  for (let i = 0; i < 5; i++) {
    const h = 0.7 - Math.abs(i - 1.5) * 0.1;
    add('Body', [0.06, h, 0.06], [0, 0.95 + h / 2 - 0.05, -0.5 + i * 0.26], P.bone, { rot: [25, 0, 0] });
    if (i !== 2 && i < 4) add('Body', [0.04, h * (i === 3 ? 0.4 : 0.7), 0.22], [0, 0.92 + h * 0.3, -0.38 + i * 0.26], P.fin, { rot: [25, 0, 0] });
  }
  // agallas y gusanos parásitos saliendo de la agalla derecha
  for (const s of [-1, 1]) for (let i = 0; i < 3; i++) add('Body', [0.04, 0.6 - i * 0.08, 0.06], [s * 0.665, 0, -0.72 + i * 0.12], P.gum);
  for (const [z, a] of [[-0.68, 0], [-0.55, 1]]) {
    let x = 0.7, y = -0.05 - a * 0.25, zz = z;
    for (let k = 0; k < 3; k++) { add('Body', [0.07, 0.07, 0.22], [x, y, zz], P.worm, { rot: [k * 25 - 20, 30 + k * 25, 0] }); x += 0.09; y -= 0.06 - k * 0.07; zz += 0.12; }
  }
  // ---------- cabeza: lomo, dientes como agujas, ojo que brilla (izq.) y ojo colgando de la cuenca (der.)
  add('Head', [1.17, 0.34, 1.12], [0, 0.52, 0], P.back);
  add('Head', [1.13, 0.45, 0.95], [0, 0.66, 0.16], P.back, { rot: [-22, 0, 0] });                // frente inclinada hacia el lomo
  add('Head', [1.0, 0.12, 0.9], [0, -0.63, -0.05], P.mouth);
  add('Head', [1.05, 0.06, 0.06], [0, -0.575, -0.56], P.gum);
  for (let i = 0; i < 7; i++) { const h = [0.3, 0.22, 0.34, 0.2, 0.32, 0.24, 0.28][i]; add('Head', [0.06, h, 0.06], [-0.42 + i * 0.14, -0.575 - h / 2, -0.5], P.teeth); }
  for (const s of [-1, 1]) for (let j = 0; j < 3; j++) add('Head', [0.06, 0.2, 0.06], [s * 0.5, -0.68, -0.3 + j * 0.2], P.teeth);
  add('Head', [0.04, 0.38, 0.38], [-0.585, 0.12, -0.12], P.mouth);
  add('Head', [0.06, 0.26, 0.26], [-0.6, 0.12, -0.12], P.eye, { neon: true });
  add('Head', [0.03, 0.18, 0.06], [-0.635, 0.12, -0.12], P.mouth);
  add('Head', [0.04, 0.38, 0.38], [0.585, 0.12, -0.12], P.blood);
  add('Head', [0.05, 0.2, 0.05], [0.63, 0.0, -0.12], P.wound, { rot: [0, 0, -10] });
  add('Head', [0.05, 0.2, 0.05], [0.66, -0.2, -0.1], P.wound, { rot: [0, 0, 10] });
  add('Head', [0.22, 0.22, 0.22], [0.7, -0.4, -0.1], [232, 228, 204]);
  add('Head', [0.03, 0.12, 0.12], [0.815, -0.4, -0.1], P.eye, { neon: true });
  add('Head', [0.5, 0.05, 0.4], [0.12, 0.7, -0.22], P.bone);                                   // cráneo al aire
  add('Head', [0.56, 0.04, 0.46], [0.12, 0.685, -0.22], P.wound);
  add('Head', [0.2, 0.06, 0.04], [0.1, -0.15, -0.565], P.wound, { rot: [0, 0, 20] });            // tajos
  add('Head', [0.28, 0.05, 0.04], [-0.2, 0.25, -0.565], P.fleshDark, { rot: [0, 0, -15] });
  // ---------- mandíbula prognata: colmillos hacia arriba, sangre que gotea
  for (let i = 0; i < 6; i++) { const h = [0.24, 0.3, 0.2, 0.32, 0.22, 0.28][i]; add('Jaw', [0.06, h, 0.06], [-0.36 + i * 0.144, 0.17 + h / 2 - 0.04, -0.52], P.teeth); }
  add('Jaw', [1.02, 0.08, 1.17], [0, -0.14, 0], P.belly);
  add('Jaw', [0.07, 0.38, 0.04], [0.2, -0.33, -0.56], P.blood);
  add('Jaw', [0.05, 0.22, 0.04], [-0.25, -0.26, -0.56], P.blood);
  // ---------- tronco trasero: escamas arrancadas, gusano, aleta anal
  add('Mid', [1.12, 0.36, 1.27], [0, 0.6, 0], P.back);
  add('Mid', [1.06, 0.5, 0.6], [0, 0.62, 0.5], P.back, { rot: [32, 0, 0] });                       // el lomo baja hacia la cola
  add('Mid', [1.06, 0.5, 0.6], [0, -0.64, 0.5], P.belly, { rot: [-32, 0, 0] });
  add('Mid', [1.12, 0.3, 1.27], [0, -0.62, 0], P.belly);
  tiles('Mid', 1, 0.56, 3, 3, 0.25, -0.45);
  tiles('Mid', -1, 0.56, 3, 3, 0.25, -0.45, (r, c) => c >= 1 && r <= 1);
  add('Mid', [0.04, 0.55, 0.55], [-0.565, 0.05, 0.12], P.flesh);
  add('Mid', [0.03, 0.3, 0.3], [-0.575, 0.05, 0.12], P.wound);
  for (let i = 0; i < 3; i++) add('Mid', [0.06, 0.55 - i * 0.1, 0.06], [0, 1.0 - i * 0.08, -0.3 + i * 0.25], P.bone, { rot: [30, 0, 0] });
  add('Mid', [0.04, 0.3, 0.2], [0, 0.93, -0.18], P.fin, { rot: [30, 0, 0] });
  for (let i = 0; i < 3; i++) add('Mid', [0.05, 0.38, 0.05], [0, -0.9, 0.1 + i * 0.18], P.bone, { rot: [-25, 0, 0] });
  for (let k = 0; k < 3; k++) add('Mid', [0.07, 0.07, 0.2], [0.6 + k * 0.08, -0.2 - k * 0.08, 0.2 + k * 0.1], P.worm, { rot: [30, 20 + k * 30, 0] });
  // ---------- cola en hueso: vértebras, espinas y jirones de carne
  for (let i = 0; i < 6; i++) {
    const z = -0.45 + i * 0.18;
    add('Tail', [0.44, 0.44, 0.08], [0, 0, z], P.boneDark);
    add('Tail', [0.05, 0.36, 0.05], [0, 0.34, z], P.bone, { rot: [25, 0, 0] });
    add('Tail', [0.05, 0.3, 0.05], [0, -0.32, z], P.bone, { rot: [-25, 0, 0] });
  }
  add('Tail', [0.6, 0.62, 0.3], [0, 0, -0.42], P.side);
  add('Tail', [0.62, 0.2, 0.31], [0, 0.22, -0.42], P.back);
  add('Tail', [0.3, 0.26, 0.22], [-0.12, -0.08, -0.1], P.flesh);
  add('Tail', [0.05, 0.32, 0.05], [0.1, -0.3, -0.2], P.fleshDark, { rot: [10, 0, 0] });
  add('Tail', [0.04, 0.24, 0.04], [-0.14, -0.28, 0.1], P.blood);
  // ---------- aleta caudal: abanico de radios con la membrana rota a trozos
  const RAYS = giant ? [-52, -36, -20, 20, 36, 52] : [-50, -34, -18, 0, 18, 34, 50];
  RAYS.forEach((a, i) => {
    const L = 1.05 - Math.abs(a) * 0.002 - (i === 2 ? 0.25 : 0);
    add('TailFin', [0.05, 0.05, L], [0, Math.sin(a * D2R) * L / 2, Math.cos(a * D2R) * L / 2], P.bone, { rot: [-a, 0, 0] });
  });
  for (const [a, f, len] of [[-42, 0.45, 0.5], [-26, 0.3, 0.35], [26, 0.5, 0.45], [42, 0.35, 0.55], [8, 0.6, 0.3]]) {
    const d = f + len / 2;
    add('TailFin', [0.04, 0.2, len], [0, Math.sin(a * D2R) * d, Math.cos(a * D2R) * d], P.fin, { rot: [-a, 0, 0] });
  }
  // ---------- aletas pectorales
  for (const f of ['LeftFin', 'RightFin']) {
    const s = f === 'LeftFin' ? -1 : 1;
    for (let i = 0; i < 3; i++) add(f, [0.72, 0.04, 0.04], [s * 0.02, 0.04, -0.15 + i * 0.15], P.bone);
    add(f, [0.2, 0.08, 0.14], [s * 0.2, 0, 0.12], f === 'RightFin' ? P.wound : P.mouth);
  }
  // ---------- gigante: señuelo luminoso en la frente, barbas, púas de hueso que rompen el lomo, percebes y más pústulas
  if (giant) {
    add('Head', [0.06, 0.32, 0.06], [0, 0.8, -0.32], P.fleshDark, { rot: [-20, 0, 0] });
    add('Head', [0.06, 0.3, 0.06], [0, 0.98, -0.4], P.fleshDark, { rot: [-50, 0, 0] });
    add('Head', [0.06, 0.06, 0.28], [0, 1.08, -0.62], P.fleshDark);
    add('Head', [0.05, 0.2, 0.05], [0, 0.98, -0.76], P.fleshDark);
    add('Head', [0.2, 0.2, 0.2], [0, 0.84, -0.78], P.pus, { neon: true });
    for (const s of [-1, 1]) for (let k = 0; k < 3; k++) add('Jaw', [0.05, 0.05, 0.28], [s * (0.42 + k * 0.03), -0.18 - k * 0.12, -0.62 - k * 0.12], P.fleshDark, { rot: [40 + k * 15, 0, 0] });
    for (const [z, h] of [[-0.45, 0.7], [0.05, 0.9], [0.5, 0.6]]) add('Body', [0.14, h, 0.14], [0.25, 0.95 + h / 2, z], P.bone, { rot: [20, 0, -15] });
    for (const [l, x, y, z] of [['Head', -0.3, 0.7, -0.1], ['Head', 0.35, 0.68, -0.3], ['Body', -0.4, 0.98, 0.5], ['Mid', 0.3, 0.78, 0.1], ['Mid', -0.2, 0.78, -0.3]])
      add(l, [0.18, 0.1, 0.18], [x, y, z], P.boneDark);
    for (const [y, z, s] of [[0.2, -0.3, 0.14], [-0.1, -0.1, 0.18], [0.1, 0.35, 0.12]]) add('Mid', [s * 0.8, s, s], [0.57 + s * 0.2, y, z], P.pus, { neon: true });
    add('Head', [0.06, 0.12, 0.12], [-0.6, 0.12, -0.12], [255, 120, 40], { neon: true });
  }
  return { limbs, joints, details };
}

const FISH_BLUEPRINTS = { Normal: fish(false), Giant: fish(true) };
// estadísticas (el instalador las copia a Settings: "NormalHealth", "GiantDamage"...)
const FISH_STATS = {
  Normal: { DisplayName: 'Pez infectado', Health: 60, Damage: 12, Reach: 3.5, Detect: 45, SwimSpeed: 6, CircleSpeed: 11, ChaseSpeed: 17, Cooldown: 1.2,
            LeapRange: 16, LeapCooldown: 7, LeapHeight: 4, Scale: 1, Circle: true, Chance: 0.875 },
  Giant: { DisplayName: 'Pez infectado gigante', Health: 320, Damage: 30, Reach: 7, Detect: 70, SwimSpeed: 5, CircleSpeed: 9, ChaseSpeed: 14, Cooldown: 2.0,
           LeapRange: 24, LeapCooldown: 12, LeapHeight: 7, Scale: 2.2, Circle: false, Chance: 0.125 },
};
root.FISH_BLUEPRINTS = FISH_BLUEPRINTS;
root.FISH_STATS = FISH_STATS;
})(typeof window !== 'undefined' ? window : globalThis);
