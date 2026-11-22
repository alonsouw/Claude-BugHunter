/*
 * Planos de las armaduras de bloques (Parts) para personajes R15 de Roblox: Cuero, Lobo y Dragón.
 * Los usan igual el instalador de Studio (tools/build_roblox.js los convierte en Luau) y el visor web.
 *
 * Cada pieza va soldada a una parte del cuerpo R15 y se define para el tamaño por defecto de esa parte
 * (DUMMY.parts). Al equiparla, ArmorService la escala por eje al tamaño real de la parte del jugador, así
 * encaja en cuerpos más anchos o más altos. Para R6 hay una tabla de equivalencias (R6_MAP en ArmorService).
 *
 * pieza: { part, size, offset (desde el centro de la parte), rot (grados XYZ), color, material, neon }
 * Las piezas del lado derecho se reflejan solas al izquierdo (mirror).
 */
(function (root) {
// maniquí R15 por defecto (tamaños estándar de bloque), suelo en y = 0, mira a -Z
const DUMMY = {
  parts: {
    Head: { size: [1.2, 1.2, 1.2], center: [0, 5.31, 0] },
    UpperTorso: { size: [2, 1.6, 1], center: [0, 3.91, 0] },
    LowerTorso: { size: [2, 0.4, 1], center: [0, 2.91, 0] },
    RightUpperArm: { size: [1, 1.169, 1], center: [1.5, 4.1255, 0] }, LeftUpperArm: { size: [1, 1.169, 1], center: [-1.5, 4.1255, 0] },
    RightLowerArm: { size: [1, 1.052, 1], center: [1.5, 3.015, 0] }, LeftLowerArm: { size: [1, 1.052, 1], center: [-1.5, 3.015, 0] },
    RightHand: { size: [1, 0.3, 1], center: [1.5, 2.339, 0] }, LeftHand: { size: [1, 0.3, 1], center: [-1.5, 2.339, 0] },
    RightUpperLeg: { size: [1, 1.217, 1], center: [0.5, 2.1015, 0] }, LeftUpperLeg: { size: [1, 1.217, 1], center: [-0.5, 2.1015, 0] },
    RightLowerLeg: { size: [1, 1.193, 1], center: [0.5, 0.8965, 0] }, LeftLowerLeg: { size: [1, 1.193, 1], center: [-0.5, 0.8965, 0] },
    RightFoot: { size: [1, 0.3, 1], center: [0.5, 0.15, 0] }, LeftFoot: { size: [1, 0.3, 1], center: [-0.5, 0.15, 0] },
  },
  skin: [234, 184, 146], shirt: [70, 80, 96], pants: [44, 48, 58],
};

function set(name) {
  const pieces = [];
  const add = (part, size, offset, color, x = {}) => pieces.push({ part, size, offset, color, material: x.material || 'SmoothPlastic', rot: x.rot || [0, 0, 0], neon: !!x.neon });
  // add para los dos lados: se define en el derecho y se refleja al izquierdo
  const both = (part, size, offset, color, x = {}) => {
    add('Right' + part, size, offset, color, x);
    const r = x.rot || [0, 0, 0];
    add('Left' + part, size, [-offset[0], offset[1], offset[2]], color, Object.assign({}, x, { rot: [r[0], -r[1], -r[2]] }));
  };
  return { name, pieces, add, both };
}

// ------------------------------------------------------------------ CUERO
function leather() {
  const S = set('Leather'), { add, both } = S;
  const L = [112, 74, 44], D = [74, 48, 30], ST = [190, 160, 108], BR = [200, 164, 74], F = 'Fabric';
  // capucha de cuero con banda en la frente
  add('Head', [1.32, 0.42, 1.32], [0, 0.44, 0.04], L, { material: F });
  add('Head', [1.34, 0.14, 1.34], [0, 0.22, 0], D, { material: F });
  add('Head', [0.16, 0.7, 1.1], [0.66, -0.05, 0.1], L, { material: F }); add('Head', [0.16, 0.7, 1.1], [-0.66, -0.05, 0.1], L, { material: F });
  add('Head', [1.32, 0.9, 0.16], [0, 0.0, 0.66], L, { material: F });
  // jubón
  add('UpperTorso', [2.12, 1.66, 1.14], [0, 0.02, 0], L, { material: F });
  add('UpperTorso', [0.14, 1.5, 0.06], [0, 0, -0.6], D);                                        // cordón central
  for (let i = 0; i < 5; i++) add('UpperTorso', [0.36, 0.05, 0.05], [0, 0.6 - i * 0.3, -0.62], ST, { rot: [0, 0, i % 2 ? 20 : -20] });
  add('UpperTorso', [0.24, 2.3, 0.08], [0.15, 0.05, -0.62], D, { rot: [0, 0, 40] });             // correa cruzada
  add('UpperTorso', [0.24, 2.3, 0.08], [-0.15, 0.05, 0.62], D, { rot: [0, 0, -40] });
  add('UpperTorso', [0.28, 0.22, 0.1], [0.42, 0.42, -0.66], BR);                                  // hebilla
  add('UpperTorso', [2.18, 0.2, 1.2], [0, 0.82, 0], D, { material: F });                         // cuello
  // cinturón con bolsas
  add('LowerTorso', [2.18, 0.32, 1.18], [0, 0, 0], D);
  add('LowerTorso', [0.34, 0.26, 0.1], [0, 0, -0.62], BR);
  both('UpperLeg', [0.5, 0.45, 0.35], [0.55, 0.42, -0.25], L, { material: F });                 // bolsa en la cadera
  both('UpperLeg', [0.5, 0.08, 0.37], [0.55, 0.66, -0.25], D);
  // hombreras, brazales, guantes sin dedos
  both('UpperArm', [1.22, 0.36, 1.22], [0.05, 0.42, 0], L, { material: F, rot: [0, 0, -8] });
  both('UpperArm', [1.24, 0.08, 1.24], [0.05, 0.26, 0], D);
  both('LowerArm', [1.12, 0.72, 1.12], [0, -0.1, 0], L, { material: F });
  for (const y of [0.15, -0.3]) both('LowerArm', [1.14, 0.08, 1.14], [0, y, 0], D);
  both('Hand', [1.06, 0.26, 1.06], [0, 0, 0], D);
  // musleras y botas altas
  both('UpperLeg', [1.08, 0.7, 0.2], [0, -0.1, -0.52], L, { material: F });
  both('LowerLeg', [1.12, 0.95, 1.12], [0, -0.1, 0], D);
  both('LowerLeg', [1.16, 0.14, 1.16], [0, 0.32, 0], L);
  both('LowerLeg', [0.2, 0.12, 0.08], [0, 0.0, -0.58], BR);
  both('Foot', [1.12, 0.36, 1.3], [0, 0.02, -0.12], D);
  both('Foot', [1.14, 0.08, 1.32], [0, -0.15, -0.12], [40, 28, 20]);
  return S;
}

// ------------------------------------------------------------------ LOBO
function wolf() {
  const S = set('Wolf'), { add, both } = S;
  const FUR = [124, 120, 112], FD = [84, 80, 74], FL = [176, 172, 162], LE = [92, 64, 42], BO = [228, 218, 192], DK = [30, 26, 26];
  // casco: la cabeza de un lobo encima de la del jugador, hocico sobre la frente, orejas, colmillos
  add('Head', [1.36, 0.5, 1.36], [0, 0.5, 0.05], FUR, { material: 'Fabric' });
  add('Head', [0.66, 0.38, 0.75], [0, 0.5, -0.95], FUR, { material: 'Fabric' });                // hocico
  add('Head', [0.5, 0.18, 0.7], [0, 0.32, -0.95], FL, { material: 'Fabric' });                 // mandíbula clara
  add('Head', [0.22, 0.16, 0.12], [0, 0.6, -1.33], DK);                                          // trufa
  for (const s of [-1, 1]) {
    add('Head', [0.28, 0.42, 0.14], [s * 0.42, 0.88, 0.1], FUR, { material: 'Fabric', rot: [0, 0, s * -10] });   // orejas
    add('Head', [0.14, 0.26, 0.06], [s * 0.42, 0.86, 0.02], FD, { rot: [0, 0, s * -10] });
    add('Head', [0.16, 0.08, 0.06], [s * 0.38, 0.62, -0.62], [250, 210, 90], { neon: true });   // ojos del lobo
    for (let i = 0; i < 3; i++) add('Head', [0.06, 0.12, 0.06], [s * 0.26, 0.24, -0.72 - i * 0.18], BO);   // colmillos
  }
  add('Head', [1.4, 1.1, 0.4], [0, 0.0, 0.62], FUR, { material: 'Fabric' });                     // capucha de piel por detrás
  for (const s of [-1, 1]) add('Head', [0.2, 0.95, 1.2], [s * 0.7, 0.02, 0.15], FD, { material: 'Fabric' });
  // manto de piel sobre los hombros y chaleco de cuero
  add('UpperTorso', [2.1, 1.62, 1.12], [0, 0, 0], LE, { material: 'Fabric' });
  for (let i = 0; i < 9; i++) {
    const x = -1.25 + i * 0.31;
    add('UpperTorso', [0.42, 0.42 + (i % 3) * 0.08, 1.4], [x, 0.82, 0.05], i % 2 ? FUR : FD, { material: 'Fabric', rot: [0, 0, (i - 4) * -6] });
  }
  add('UpperTorso', [2.3, 1.1, 0.25], [0, 0.25, 0.65], FUR, { material: 'Fabric' });            // la piel cae por la espalda
  for (let i = 0; i < 7; i++) add('UpperTorso', [0.32, 0.25 + (i % 2) * 0.12, 0.2], [-0.95 + i * 0.32, -0.38 - (i % 2) * 0.06, 0.66], FD, { material: 'Fabric' });
  // collar de colmillos
  for (let i = 0; i < 7; i++) { const a = (i - 3) * 0.32; add('UpperTorso', [0.08, 0.2, 0.08], [Math.sin(a) * 0.65, 0.48 - Math.cos(a) * 0.18, -0.6], BO, { rot: [0, 0, -a * 30] }); }
  add('UpperTorso', [0.2, 0.2, 0.08], [0, 0.22, -0.62], [160, 30, 30]);
  // hombreras de piel con zarpa
  both('UpperArm', [1.3, 0.45, 1.3], [0.08, 0.4, 0], FUR, { material: 'Fabric', rot: [0, 0, -12] });
  both('UpperArm', [1.0, 0.3, 1.0], [0.12, 0.62, 0], FD, { material: 'Fabric', rot: [0, 0, -12] });
  for (let i = 0; i < 3; i++) both('UpperArm', [0.08, 0.25, 0.08], [0.66, 0.25, -0.3 + i * 0.3], BO, { rot: [0, 0, 30] });
  // brazales vendados con puño de piel; guanteletes con garras
  both('LowerArm', [1.1, 0.8, 1.1], [0, -0.05, 0], LE, { material: 'Fabric' });
  for (const y of [0.25, 0.0, -0.25]) both('LowerArm', [1.13, 0.07, 1.13], [0, y, 0], [60, 42, 28]);
  both('LowerArm', [1.22, 0.24, 1.22], [0, 0.45, 0], FUR, { material: 'Fabric' });
  both('Hand', [1.08, 0.3, 1.08], [0, 0, 0], LE);
  for (let i = 0; i < 3; i++) both('Hand', [0.1, 0.32, 0.1], [-0.3 + i * 0.3, -0.25, -0.42], BO, { rot: [-35, 0, 0] });
  // cinturón con la cola del lobo
  add('LowerTorso', [2.16, 0.34, 1.16], [0, 0, 0], LE);
  for (let i = 0; i < 6; i++) add('LowerTorso', [0.42 - i * 0.05, 0.42 - i * 0.05, 0.4], [0, -0.25 - i * 0.32, 0.65 + i * 0.12], i % 2 ? FUR : FD, { material: 'Fabric', rot: [20 + i * 8, 0, 0] });
  add('LowerTorso', [0.22, 0.22, 0.22], [0, -2.15, 1.37], FL, { material: 'Fabric' });
  // perneras vendadas y botas con borde de piel
  both('UpperLeg', [1.08, 1.1, 1.08], [0, 0, 0], LE, { material: 'Fabric' });
  for (const y of [0.35, 0.05, -0.25]) both('UpperLeg', [1.11, 0.08, 1.11], [0, y, 0], [60, 42, 28], { rot: [0, 0, 6] });
  both('LowerLeg', [1.1, 1.0, 1.1], [0, -0.08, 0], FD, { material: 'Fabric' });
  both('LowerLeg', [1.26, 0.3, 1.26], [0, 0.45, 0], FUR, { material: 'Fabric' });
  both('Foot', [1.12, 0.36, 1.32], [0, 0.02, -0.14], LE);
  return S;
}

// ------------------------------------------------------------------ DRAGÓN
function dragon() {
  const S = set('Dragon'), { add, both } = S;
  const SC = [128, 22, 22], SD = [72, 12, 14], MT = [34, 30, 32], GD = [206, 154, 52], GL = [255, 140, 30], HN = [222, 206, 170], M = 'Metal';
  const scales = (part, w, h, z, rows, cols, y0, x0) => {   // escamas: placas pequeñas superpuestas en filas alternas
    for (let r = 0; r < rows; r++) for (let c = 0; c < cols + (r % 2 ? -1 : 0); c++) {
      const x = x0 + c * w + (r % 2 ? w / 2 : 0);
      add(part, [w * 0.95, h, 0.07], [x, y0 - r * h * 0.75, z], r % 2 ? SD : SC, { rot: [-12, 0, 0] });
    }
  };
  // yelmo cerrado con visera que brilla, cresta de púas y dos cuernos curvados hacia atrás
  add('Head', [1.38, 1.38, 1.38], [0, 0.02, 0], SC, { material: M });
  add('Head', [1.1, 0.16, 0.08], [0, 0.1, -0.7], GL, { neon: true });                           // visera
  add('Head', [1.4, 0.12, 1.4], [0, -0.3, 0], GD, { material: M });                             // filo dorado
  add('Head', [0.4, 0.45, 0.2], [0, -0.38, -0.65], MT, { material: M });                        // barbote
  for (let i = 0; i < 5; i++) add('Head', [0.12, 0.3 - i * 0.03, 0.2], [0, 0.82 - i * 0.03, -0.45 + i * 0.25], SD, { rot: [-25, 0, 0] });   // cresta
  for (const s of [-1, 1]) {
    for (let i = 0; i < 5; i++) {
      const t = i / 4;
      add('Head', [0.24 - i * 0.035, 0.24 - i * 0.035, 0.32], [s * (0.6 + t * 0.35), 0.55 + Math.sin(t * 2.2) * 0.35, 0.05 + t * 0.75], HN, { rot: [-30 - i * 12, 0, s * -15] });
    }
    add('Head', [0.18, 0.5, 0.5], [s * 0.72, -0.1, -0.15], SD, { material: M, rot: [0, s * 15, 0] });   // carrilleras
  }
  // coraza de escamas, gema-ojo de dragón y espinazo de púas
  add('UpperTorso', [2.18, 1.7, 1.2], [0, 0.02, 0], MT, { material: M });
  scales('UpperTorso', 0.36, 0.3, -0.63, 6, 6, 0.65, -0.9);
  add('UpperTorso', [2.22, 0.12, 1.24], [0, 0.84, 0], GD, { material: M });
  add('UpperTorso', [2.22, 0.1, 1.24], [0, -0.8, 0], GD, { material: M });
  add('UpperTorso', [0.32, 0.32, 0.1], [0, 0.15, -0.72], GD, { material: M, rot: [0, 0, 45] });
  add('UpperTorso', [0.2, 0.2, 0.1], [0, 0.15, -0.78], GL, { neon: true, rot: [0, 0, 45] });
  for (let i = 0; i < 5; i++) add('UpperTorso', [0.14, 0.32, 0.32], [0, 0.65 - i * 0.33, 0.68], HN, { rot: [45, 0, 0] });
  // alas plegadas a la espalda: dos placas de membrana
  for (const s of [-1, 1]) {
    add('UpperTorso', [0.9, 1.3, 0.06], [s * 0.6, 0.35, 0.78], SD, { rot: [0, s * 25, s * 12] });
    add('UpperTorso', [0.1, 1.4, 0.1], [s * 1.0, 0.45, 0.85], MT, { material: M, rot: [0, s * 25, s * 12] });
  }
  // hombreras en capas con púas
  for (let k = 0; k < 3; k++) both('UpperArm', [1.45 - k * 0.12, 0.3, 1.45 - k * 0.12], [0.1 + k * 0.04, 0.52 - k * 0.2, 0], k % 2 ? SD : SC, { material: M, rot: [0, 0, -15] });
  both('UpperArm', [1.48, 0.07, 1.48], [0.1, 0.38, 0], GD, { material: M, rot: [0, 0, -15] });
  for (let i = 0; i < 3; i++) both('UpperArm', [0.16, 0.45, 0.16], [0.35 + i * 0.12, 0.85 - i * 0.05, -0.25 + i * 0.25], HN, { rot: [0, 0, -30 - i * 8] });
  // brazales con cresta y guanteletes con garras
  both('LowerArm', [1.14, 0.95, 1.14], [0, -0.02, 0], MT, { material: M });
  scales('RightLowerArm', 0.32, 0.25, -0.58, 3, 3, 0.25, -0.32); scales('LeftLowerArm', 0.32, 0.25, -0.58, 3, 3, 0.25, -0.32);
  for (let i = 0; i < 3; i++) both('LowerArm', [0.12, 0.28, 0.28], [0.6, 0.3 - i * 0.3, 0], HN, { rot: [45, 0, 0] });
  both('Hand', [1.12, 0.34, 1.12], [0, 0, 0], SC, { material: M });
  for (let i = 0; i < 4; i++) both('Hand', [0.09, 0.4, 0.09], [-0.36 + i * 0.24, -0.3, -0.45], HN, { rot: [-40, 0, 0] });
  // faldar de escamas y cola
  add('LowerTorso', [2.2, 0.36, 1.2], [0, 0, 0], MT, { material: M });
  add('LowerTorso', [0.36, 0.3, 0.1], [0, 0, -0.64], GD, { material: M });
  for (let i = 0; i < 6; i++) add('LowerTorso', [0.36, 0.55, 0.08], [-0.9 + i * 0.36, -0.42, -0.6], i % 2 ? SD : SC, { material: M, rot: [-8, 0, 0] });
  for (let i = 0; i < 7; i++) add('LowerTorso', [0.5 - i * 0.055, 0.42 - i * 0.045, 0.45], [0, -0.3 - i * 0.28, 0.7 + i * 0.32], i % 2 ? SD : SC, { material: M, rot: [25 + i * 6, 0, 0] });
  for (let i = 0; i < 6; i++) add('LowerTorso', [0.08, 0.2 - i * 0.02, 0.15], [0, -0.05 - i * 0.28, 0.75 + i * 0.32], HN, { rot: [30, 0, 0] });
  // grebas con rodillera de púa y botas de garra
  both('UpperLeg', [1.12, 1.15, 1.12], [0, 0, 0], MT, { material: M });
  scales('RightUpperLeg', 0.32, 0.28, -0.58, 4, 3, 0.4, -0.32); scales('LeftUpperLeg', 0.32, 0.28, -0.58, 4, 3, 0.4, -0.32);
  both('LowerLeg', [1.14, 1.15, 1.14], [0, 0, 0], SC, { material: M });
  both('LowerLeg', [0.5, 0.4, 0.3], [0, 0.45, -0.62], GD, { material: M });
  both('LowerLeg', [0.14, 0.4, 0.14], [0, 0.6, -0.8], HN, { rot: [-50, 0, 0] });
  both('Foot', [1.16, 0.38, 1.35], [0, 0.03, -0.15], MT, { material: M });
  for (let i = 0; i < 3; i++) both('Foot', [0.14, 0.14, 0.4], [-0.3 + i * 0.3, -0.05, -0.95], HN, { rot: [15, 0, 0] });
  return S;
}

const SETS = { Leather: leather(), Wolf: wolf(), Dragon: dragon() };
for (const k in SETS) { delete SETS[k].add; delete SETS[k].both; }
// estadísticas: reducción de daño (todas las fuentes) y cambio de velocidad al caminar
const STATS = {
  Leather: { DisplayName: 'Armadura de cuero', Reduction: 0.15, Speed: 1, Color: [112, 74, 44] },
  Wolf: { DisplayName: 'Armadura de lobo', Reduction: 0.25, Speed: 2, Color: [124, 120, 112] },
  Dragon: { DisplayName: 'Armadura de dragón', Reduction: 0.45, Speed: -1, Color: [128, 22, 22] },
};
root.ARMOR_DUMMY = DUMMY;
root.ARMOR_SETS = SETS;
root.ARMOR_STATS = STATS;
})(typeof window !== 'undefined' ? window : globalThis);
