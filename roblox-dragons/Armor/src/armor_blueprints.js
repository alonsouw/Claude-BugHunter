/*
 * Planos de las armaduras de bloques (Parts) para personajes R15 de Roblox: Cuero, Lobo y Dragón.
 * Los usan igual el instalador de Studio (tools/build_roblox.js los convierte en Luau) y el visor web.
 *
 * Cada pieza va soldada a una parte del cuerpo R15 y se define para el tamaño por defecto de esa parte
 * (DUMMY.parts). Al equiparla, ArmorService la escala por eje al tamaño real de la parte del jugador, así
 * encaja en cuerpos más anchos o más altos. Para R6 hay una tabla de equivalencias (R6_MAP en ArmorBuilder).
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

const D2R = Math.PI / 180;
// ------------------------------------------------------------------ CUERO (jubón de cuero curtido con cordones, hombreras en láminas y cota de malla)
function leather() {
  const S = set('Leather'), { add, both } = S;
  S.bare = ['Head'];   // sin casco: la cara queda al aire
  const LB = [86, 46, 30], LH = [116, 66, 40], LD = [50, 27, 18], BR = [182, 142, 68], CH = [78, 80, 84], SL = [56, 56, 58], GL = [26, 24, 24], PT = [40, 38, 38];
  const LE = { material: 'Leather' };
  // jubón con cuello alto
  add('UpperTorso', [2.12, 1.66, 1.14], [0, 0.02, 0], LB, LE);
  for (const s of [-1, 1]) {
    add('UpperTorso', [0.5, 0.34, 0.12], [s * 0.3, 0.94, -0.42], LB, { material: 'Leather', rot: [0, s * 18, 0] });
    add('UpperTorso', [0.12, 0.34, 0.8], [s * 0.52, 0.94, 0], LB, LE);
    add('UpperTorso', [0.5, 0.04, 0.13], [s * 0.3, 1.1, -0.42], LH, { rot: [0, s * 18, 0] });                 // ribete del cuello
  }
  add('UpperTorso', [1.0, 0.34, 0.12], [0, 0.94, 0.42], LB, LE);
  add('UpperTorso', [1.9, 0.035, 0.03], [0, 0.52, -0.585], LH);                                                 // costura del canesú
  for (const s of [-1, 1]) add('UpperTorso', [0.035, 1.25, 0.03], [s * 0.62, -0.12, -0.585], LH, { rot: [0, 0, s * 5] });   // costuras laterales
  // cordones en X con ojales de latón
  add('UpperTorso', [0.1, 1.5, 0.04], [0, -0.04, -0.585], LD);
  for (let i = 0; i < 7; i++) {
    const y = 0.66 - i * 0.22;
    for (const s of [-1, 1]) add('UpperTorso', [0.06, 0.06, 0.04], [s * 0.14, y, -0.6], BR);
    if (i < 6) for (const s of [-1, 1]) add('UpperTorso', [0.34, 0.035, 0.03], [0, y - 0.11, -0.615], LD, { rot: [0, 0, s * 33] });
  }
  for (const s of [-1, 1]) for (let i = 0; i < 3; i++) add('UpperTorso', [0.03, 0.035, 0.3], [s * 1.065, 0.1 - i * 0.2, 0], LD, { rot: [s * 30, 0, 0] });   // cordones de los costados
  // faldón partido por delante, con ribete
  for (const s of [-1, 1]) {
    add('LowerTorso', [0.96, 0.95, 0.1], [s * 0.53, -0.6, -0.56], LB, { material: 'Leather', rot: [-5, 0, 0] });
    add('LowerTorso', [0.96, 0.05, 0.11], [s * 0.53, -1.04, -0.6], LH, { rot: [-5, 0, 0] });
    add('LowerTorso', [0.1, 0.95, 1.12], [s * 1.06, -0.6, 0], LB, LE);
  }
  add('LowerTorso', [2.1, 0.95, 0.1], [0, -0.6, 0.56], LB, { material: 'Leather', rot: [5, 0, 0] });
  add('LowerTorso', [2.1, 0.05, 0.11], [0, -1.04, 0.6], LH, { rot: [5, 0, 0] });
  // cinturón ancho con hebilla de marco y dos bolsas con solapa y hebilla
  add('LowerTorso', [2.22, 0.3, 1.22], [0, 0.02, 0], LD, LE);
  for (const y of [0.13, -0.09]) add('LowerTorso', [0.36, 0.05, 0.05], [0, y, -0.63], BR, { material: 'Metal' });
  for (const s of [-1, 1]) add('LowerTorso', [0.05, 0.27, 0.05], [s * 0.16, 0.02, -0.63], BR, { material: 'Metal' });
  add('LowerTorso', [0.035, 0.2, 0.04], [0, 0.02, -0.65], BR, { material: 'Metal' });
  add('LowerTorso', [0.34, 0.18, 0.04], [0.38, 0.02, -0.625], LB, LE);
  for (const s of [-1, 1]) {
    const x = s * 0.66;
    add('LowerTorso', [0.62, 0.62, 0.32], [x, -0.42, -0.76], LB, LE);
    add('LowerTorso', [0.66, 0.3, 0.36], [x, -0.2, -0.77], LH, { material: 'Leather', rot: [-6, 0, 0] });
    add('LowerTorso', [0.66, 0.035, 0.37], [x, -0.33, -0.775], LD, { rot: [-6, 0, 0] });                       // costura de la solapa
    add('LowerTorso', [0.12, 0.5, 0.04], [x, -0.36, -0.95], LD, LE);
    add('LowerTorso', [0.2, 0.16, 0.04], [x, -0.36, -0.975], BR, { material: 'Metal' });
    add('LowerTorso', [0.1, 0.08, 0.04], [x, -0.36, -0.99], LD);
  }
  // hombreras de tres láminas remachadas
  for (let k = 0; k < 3; k++) {
    const w = 1.24 - k * 0.05, y = 0.5 - k * 0.22, x = 0.1 + k * 0.03, rz = -(16 - k * 4), r = rz * D2R;
    both('UpperArm', [w, 0.3, w], [x, y, 0], k % 2 ? LH : LB, { material: 'Leather', rot: [0, 0, rz] });
    both('UpperArm', [w + 0.02, 0.045, w + 0.02], [x, y - 0.15, 0], LD, { rot: [0, 0, rz] });
    for (const dx of [0.15, 0.42]) both('UpperArm', [0.07, 0.07, 0.05], [x + dx * Math.cos(r), y + dx * Math.sin(r), -w / 2 - 0.02], BR, { material: 'Metal', rot: [0, 0, rz] });
  }
  // cota de malla bajo la hombrera y manga oscura
  both('UpperArm', [1.08, 0.78, 1.08], [0, -0.2, 0], CH, { material: 'DiamondPlate' });
  both('LowerArm', [1.04, 0.3, 1.04], [0, 0.38, 0], SL, { material: 'Fabric' });
  // brazales largos con correas y hebillas
  both('LowerArm', [1.14, 0.78, 1.14], [0, -0.08, 0], LB, LE);
  for (const y of [0.31, -0.47]) both('LowerArm', [1.18, 0.06, 1.18], [0, y, 0], LH);
  for (const y of [0.12, -0.24]) {
    both('LowerArm', [1.17, 0.08, 1.17], [0, y, 0], LD, LE);
    both('LowerArm', [0.05, 0.14, 0.16], [0.6, y, -0.18], BR, { material: 'Metal' });
  }
  both('LowerArm', [0.08, 0.32, 0.62], [0.58, 0.33, 0.1], LB, { material: 'Leather', rot: [0, 0, -8] });         // codera
  // cuchillo en el brazal derecho
  add('RightLowerArm', [0.08, 0.55, 0.16], [0.64, -0.12, 0.1], LD, LE);
  add('RightLowerArm', [0.09, 0.05, 0.26], [0.645, 0.17, 0.1], BR, { material: 'Metal' });
  add('RightLowerArm', [0.08, 0.26, 0.08], [0.645, 0.33, 0.1], GL, LE);
  add('RightLowerArm', [0.09, 0.07, 0.09], [0.645, 0.48, 0.1], BR, { material: 'Metal' });
  // guantes negros
  both('Hand', [1.1, 0.3, 1.1], [0, 0, 0], GL, LE);
  both('Hand', [1.16, 0.12, 1.16], [0, 0.16, 0], GL, LE);
  for (let i = 0; i < 4; i++) both('Hand', [0.2, 0.3, 0.24], [-0.36 + i * 0.24, -0.27, -0.12], GL, LE);
  both('Hand', [0.2, 0.25, 0.3], [-0.5, -0.15, -0.35], GL, { material: 'Leather', rot: [0, -30, 0] });
  // calzas oscuras y botas con vuelta
  both('UpperLeg', [1.04, 1.22, 1.04], [0, 0, 0], PT, { material: 'Fabric' });
  both('LowerLeg', [1.12, 1.0, 1.12], [0, -0.08, 0], LD, LE);
  both('LowerLeg', [1.2, 0.24, 1.2], [0, 0.44, 0], LB, LE);
  both('LowerLeg', [1.15, 0.08, 1.15], [0, -0.1, 0], LB);
  both('LowerLeg', [0.05, 0.13, 0.16], [0.59, -0.1, -0.15], BR, { material: 'Metal' });
  both('Foot', [1.12, 0.36, 1.32], [0, 0.02, -0.12], LD, LE);
  both('Foot', [1.14, 0.08, 1.34], [0, -0.15, -0.12], [32, 22, 16]);
  return S;
}

// ------------------------------------------------------------------ LOBO (piel de lobo como capucha, rostro en sombra, capa raída, vendas)
function wolf() {
  const S = set('Wolf'), { add, both } = S;
  const FL = [158, 154, 146], FM = [112, 108, 102], FD = [62, 58, 56], VOID = [12, 11, 12], EYE = [245, 245, 238], BO = [232, 224, 200];
  const VE = [64, 52, 44], STUD = [150, 146, 140], CL = [132, 126, 116], CLD = [92, 86, 78], BD = [190, 180, 158], BD2 = [160, 150, 130], BEL = [40, 33, 28], RP = [64, 50, 40], BLOOD = [110, 46, 40];
  const FUR = { material: 'Carpet' }, CLOTH = { material: 'Fabric' };
  // rostro: sombra negra bajo la piel con dos ojos blancos rasgados
  add('Head', [1.24, 1.24, 0.06], [0, 0, -0.62], VOID);
  for (const s of [-1, 1]) add('Head', [0.24, 0.06, 0.03], [s * 0.25, 0.1, -0.66], EYE, { neon: true, rot: [0, 0, s * 10] });
  // la cabeza del lobo encima: cráneo, frente, hocico, orejas, colmillos
  add('Head', [1.44, 0.6, 1.5], [0, 0.55, 0.05], FL, FUR);
  add('Head', [1.44, 0.2, 0.3], [0, 0.32, -0.72], FM, FUR);
  add('Head', [0.64, 0.4, 0.72], [0, 0.56, -1.0], FL, FUR);
  add('Head', [0.22, 0.06, 0.74], [0, 0.77, -0.98], FD);
  add('Head', [0.28, 0.18, 0.14], [0, 0.62, -1.4], VOID);
  for (const s of [-1, 1]) {
    add('Head', [0.06, 0.16, 0.06], [s * 0.22, 0.3, -1.26], BO);
    add('Head', [0.06, 0.1, 0.06], [s * 0.12, 0.32, -1.3], BO);
    add('Head', [0.36, 0.62, 0.16], [s * 0.48, 1.1, 0.05], FL, { material: 'Carpet', rot: [0, 0, s * -12] });
    add('Head', [0.2, 0.42, 0.04], [s * 0.47, 1.06, -0.04], FD, { rot: [0, 0, s * -12] });
    add('Head', [0.16, 0.1, 0.06], [s * 0.36, 0.62, -0.88], VOID);                                             // ojos vacíos de la piel
    add('Head', [0.2, 1.12, 1.32], [s * 0.72, -0.02, 0.1], FM, FUR);
  }
  add('Head', [1.44, 1.2, 0.26], [0, -0.06, 0.74], FM, FUR);
  for (let i = 0; i < 3; i++) add('Head', [0.12, 0.04, 0.9], [-0.3 + i * 0.3, 0.86, 0.15], FD);                // rayas oscuras
  add('Head', [0.04, 0.04, 0.62], [0.42, 0.86, -0.12], VOID);                                                  // cicatriz cosida
  for (let i = 0; i < 4; i++) add('Head', [0.16, 0.03, 0.03], [0.42, 0.87, -0.36 + i * 0.16], VOID);
  // chaleco acolchado y tachonado
  add('UpperTorso', [2.1, 1.62, 1.12], [0, 0, 0], VE, { material: 'Leather' });
  for (let r = 0; r < 4; r++) {
    add('UpperTorso', [1.8, 0.03, 0.03], [0, 0.42 - r * 0.32 - 0.16, -0.575], [44, 36, 30]);
    for (let c = 0; c < 4; c++) add('UpperTorso', [0.08, 0.08, 0.05], [-0.6 + c * 0.4, 0.42 - r * 0.32, -0.58], STUD, { material: 'Metal' });
  }
  add('UpperTorso', [2.16, 0.32, 1.18], [0, -0.66, 0], BD, CLOTH);                                             // faja de tela
  for (let i = 0; i < 3; i++) add('UpperTorso', [0.5, 0.03, 0.03], [-0.6 + i * 0.6, -0.66, -0.6], BD2, { rot: [0, 0, 20] });
  // manto de pelo alrededor del cuello
  for (let i = 0; i < 14; i++) {
    const a = i / 14 * Math.PI * 2;
    add('UpperTorso', [0.5, 0.42 + (i * 7 % 3) * 0.1, 0.4], [Math.sin(a) * 1.0, 0.84 + (i % 2) * 0.06, Math.cos(a) * 0.62], i % 2 ? FL : FM, { material: 'Carpet', rot: [0, a / D2R, (i % 3 - 1) * 8] });
  }
  for (let i = 0; i < 6; i++) add('UpperTorso', [0.3, 0.32 + (i % 2) * 0.12, 0.12], [-0.75 + i * 0.3, 0.52, -0.72], i % 2 ? FM : FL, { material: 'Carpet', rot: [0, 0, (i - 2.5) * 9] });
  // capa raída: cae por la espalda y cruza el pecho del hombro izquierdo a la cadera derecha
  add('UpperTorso', [2.3, 1.9, 0.12], [0, -0.2, 0.74], CL, CLOTH);
  for (let i = 0; i < 7; i++) add('UpperTorso', [0.3, 0.3 + (i * 5 % 4) * 0.14, 0.11], [-0.98 + i * 0.33, -1.25 - (i * 5 % 4) * 0.07, 0.75], i % 2 ? CL : CLD, { material: 'Fabric', rot: [0, 0, (i % 3 - 1) * 6] });
  add('UpperTorso', [0.62, 2.0, 0.1], [0, -0.02, -0.68], CL, { material: 'Fabric', rot: [0, 0, 40] });
  add('UpperTorso', [0.64, 0.04, 0.11], [0.62, -0.78, -0.69], CLD, { rot: [0, 0, 40] });
  for (const [x, y, z] of [[-0.6, 0.2, 0.81], [0.5, -0.5, 0.81], [-0.25, 0.1, -0.74]]) {                    // remiendos cosidos
    add('UpperTorso', [0.32, 0.3, 0.03], [x, y, z], CLD, CLOTH);
    for (let i = 0; i < 3; i++) add('UpperTorso', [0.03, 0.1, 0.03], [x - 0.12 + i * 0.12, y + 0.16, z + Math.sign(z) * 0.02], VOID);
  }
  // collar de colmillos y un amuleto
  for (let i = 0; i < 7; i++) { const a = (i - 3) * 0.3; add('UpperTorso', [0.18, 0.035, 0.035], [Math.sin(a) * 0.55, 0.5 - (1 - Math.cos(a)) * -0.5 - 0.1, -0.76], RP, { rot: [0, 0, a / D2R] }); }
  for (let i = 0; i < 5; i++) { const a = (i - 2) * 0.28; add('UpperTorso', [0.1, 0.3 - Math.abs(i - 2) * 0.05, 0.07], [Math.sin(a) * 0.5, 0.25 - Math.abs(i - 2) * 0.02, -0.78], BO, { rot: [0, 0, -a / D2R * 0.6] }); }
  add('UpperTorso', [0.14, 0.14, 0.06], [0, 0.42, -0.79], [140, 30, 30], { rot: [0, 0, 45] });
  add('UpperTorso', [0.1, 0.2, 0.04], [0.3, 0.72, -0.76], STUD, { material: 'Metal' });
  // cinturón tachonado y cola del lobo
  add('LowerTorso', [2.2, 0.32, 1.2], [0, 0, 0], BEL, { material: 'Leather' });
  for (let i = 0; i < 6; i++) add('LowerTorso', [0.08, 0.08, 0.05], [-0.9 + i * 0.36, 0, -0.62], STUD, { material: 'Metal' });
  add('LowerTorso', [0.36, 0.26, 0.06], [0, 0, -0.63], STUD, { material: 'Metal' });
  add('LowerTorso', [0.24, 0.14, 0.04], [0, 0, -0.66], BEL);
  for (let i = 0; i < 6; i++) add('LowerTorso', [0.42 - i * 0.05, 0.42 - i * 0.05, 0.4], [0, -0.25 - i * 0.32, 0.68 + i * 0.12], i % 2 ? FL : FM, { material: 'Carpet', rot: [20 + i * 8, 0, 0] });
  add('LowerTorso', [0.22, 0.22, 0.22], [0, -2.15, 1.4], FD, FUR);
  // hombros de piel; mangas oscuras; antebrazos vendados con manchas; garras
  both('UpperArm', [1.3, 0.45, 1.3], [0.08, 0.4, 0], FL, { material: 'Carpet', rot: [0, 0, -12] });
  for (let i = 0; i < 3; i++) both('UpperArm', [0.32, 0.3, 0.3], [0.5, 0.18, -0.35 + i * 0.35], FM, { material: 'Carpet', rot: [0, 0, -25] });
  both('UpperArm', [1.04, 0.7, 1.04], [0, -0.18, 0], FD, CLOTH);
  both('LowerArm', [1.06, 0.98, 1.06], [0, 0, 0], BD, CLOTH);
  for (let i = 0; i < 6; i++) both('LowerArm', [1.1, 0.09, 1.1], [0, 0.42 - i * 0.17, 0], i % 2 ? BD2 : BD, { material: 'Fabric', rot: [0, 0, i % 2 ? 7 : -7] });
  both('LowerArm', [0.04, 0.34, 0.12], [0.58, -0.2, 0.2], BD2, { material: 'Fabric', rot: [0, 0, 8] });       // venda suelta
  add('RightLowerArm', [0.14, 0.1, 0.03], [0.1, 0.1, -0.57], BLOOD); add('LeftLowerArm', [0.1, 0.16, 0.03], [0.2, -0.25, -0.57], BLOOD);
  both('Hand', [1.08, 0.3, 1.08], [0, 0, 0], BD, CLOTH);
  for (let i = 0; i < 3; i++) both('Hand', [0.1, 0.34, 0.1], [-0.3 + i * 0.3, -0.26, -0.44], BO, { rot: [-35, 0, 0] });
  // calzas oscuras, piel en la rodilla, espinilleras vendadas con cuerda cruzada, botas de piel
  both('UpperLeg', [1.06, 1.16, 1.06], [0, 0, 0], FD, CLOTH);
  both('LowerLeg', [1.22, 0.28, 1.22], [0, 0.46, 0], FM, FUR);
  both('LowerLeg', [1.08, 0.9, 1.08], [0, -0.12, 0], BD, CLOTH);
  for (const s of [-1, 1]) both('LowerLeg', [0.05, 1.0, 0.04], [0, -0.12, -0.56], RP, { rot: [0, 0, s * 25] });
  both('Foot', [1.16, 0.38, 1.34], [0, 0.02, -0.14], FM, FUR);
  both('Foot', [1.18, 0.08, 1.36], [0, -0.15, -0.14], [40, 34, 30]);
  return S;
}

// ------------------------------------------------------------------ DRAGÓN (cuero negro de escamas, ribetes de bronce, paneles rojos, máscara cerrada)
function dragon() {
  const S = set('Dragon'), { add, both } = S;
  const BK = [28, 26, 28], BK2 = [44, 40, 40], PI = [84, 58, 42], RED = [158, 28, 28], STR = [46, 40, 38], MET = [92, 86, 82], DARK = [8, 8, 8], GLOW = [255, 70, 40];
  const P = { material: 'Pebble' }, L = { material: 'Leather' }, ME = { material: 'Metal' };
  const frame = (part, w, h, x, y, z, c = PI) => {   // ribete: cuatro listones alrededor de un panel frontal
    add(part, [w, 0.045, 0.04], [x, y + h / 2, z], c); add(part, [w, 0.045, 0.04], [x, y - h / 2, z], c);
    add(part, [0.045, h, 0.04], [x - w / 2, y, z], c); add(part, [0.045, h, 0.04], [x + w / 2, y, z], c);
  };
  // yelmo-máscara: ranura de los ojos con brillo, cejas rojas en V, cresta de aleta
  add('Head', [1.38, 1.38, 1.38], [0, 0.02, 0], BK, P);
  add('Head', [1.32, 0.6, 0.08], [0, -0.33, -0.71], BK2, P);
  add('Head', [0.06, 0.58, 0.05], [0, -0.33, -0.76], PI);
  for (let i = 0; i < 3; i++) for (const s of [-1, 1]) add('Head', [0.04, 0.04, 0.03], [s * 0.2, -0.2 - i * 0.14, -0.76], DARK);   // respiraderos
  add('Head', [1.06, 0.24, 0.04], [0, 0.1, -0.705], DARK);
  for (const s of [-1, 1]) {
    add('Head', [0.2, 0.07, 0.03], [s * 0.26, 0.1, -0.72], GLOW, { neon: true });
    add('Head', [0.52, 0.3, 0.05], [s * 0.33, 0.38, -0.72], RED, { rot: [0, 0, s * 24] });
    add('Head', [0.56, 0.04, 0.06], [s * 0.36, 0.52, -0.73], PI, { rot: [0, 0, s * 24] });
    add('Head', [0.3, 0.7, 0.06], [s * 0.6, -0.1, -0.52], BK2, { material: 'Pebble', rot: [0, s * 40, 0] });  // carrilleras
  }
  add('Head', [1.1, 0.045, 0.05], [0, 0.23, -0.73], PI); add('Head', [1.1, 0.045, 0.05], [0, -0.03, -0.73], PI);
  add('Head', [0.06, 0.32, 0.05], [0, 0.4, -0.73], PI);
  add('Head', [1.42, 0.06, 1.42], [0, -0.02, 0], PI);
  add('Head', [0.1, 0.06, 1.44], [0, 0.73, 0], PI);
  add('Head', [0.06, 0.55, 0.3], [0, 0.98, -0.42], BK2, { rot: [-18, 0, 0] });
  add('Head', [0.05, 0.42, 0.2], [0, 1.18, -0.62], BK2, { rot: [-28, 0, 0] });
  add('Head', [0.06, 0.38, 0.4], [0, 0.88, -0.05], BK2, { rot: [-8, 0, 0] });
  add('Head', [0.06, 0.26, 0.4], [0, 0.82, 0.32], BK2, { rot: [8, 0, 0] });
  // gola y coraza con paneles ribeteados
  add('UpperTorso', [1.24, 0.3, 1.04], [0, 0.92, 0], BK2, P);
  add('UpperTorso', [2.16, 1.68, 1.16], [0, 0.02, 0], BK, P);
  for (const s of [-1, 1]) { add('UpperTorso', [0.86, 0.72, 0.06], [s * 0.48, 0.38, -0.6], BK2, P); frame('UpperTorso', 0.86, 0.72, s * 0.48, 0.38, -0.635); }
  for (let i = 0; i < 3; i++) { add('UpperTorso', [1.2, 0.24, 0.06], [0, -0.18 - i * 0.26, -0.6], BK2, P); add('UpperTorso', [1.24, 0.04, 0.04], [0, -0.06 - i * 0.26, -0.635], PI); }
  for (const s of [-1, 1]) {
    add('UpperTorso', [0.06, 1.4, 0.7], [s * 1.1, -0.08, 0], RED, { material: 'Fabric' });                        // paneles rojos de los costados
    for (let i = 0; i < 5; i++) add('UpperTorso', [0.07, 0.03, 0.7], [s * 1.11, 0.5 - i * 0.28, 0], [100, 16, 18], { rot: [s * 20, 0, 0] });
    add('UpperTorso', [0.18, 1.2, 0.05], [s * 0.93, -0.18, -0.6], RED, { material: 'Fabric' });
    // correas en V de los hombros a la hebilla, por delante y por detrás
    for (const z of [-0.67, 0.64]) add('UpperTorso', [0.16, 1.72, 0.05], [s * 0.375, 0.03, z], STR, { material: 'Leather', rot: [0, 0, -s * 25.8] });
    add('UpperTorso', [0.12, 0.12, 0.06], [s * 0.72, 0.72, -0.68], MET, ME);
  }
  add('UpperTorso', [1.6, 1.3, 0.06], [0, 0, 0.6], BK2, P); frame('UpperTorso', 1.6, 1.3, 0, 0, 0.635);
  for (let i = 0; i < 4; i++) add('UpperTorso', [0.08, 0.2, 0.2], [0, 0.55 - i * 0.32, 0.72], BK2, { rot: [45, 0, 0] });   // pequeñas púas dorsales
  // hombreras grandes en capas, con ribete y remaches
  for (let k = 0; k < 3; k++) {
    const w = 1.5 - k * 0.08, y = 0.55 - k * 0.24, x = 0.12 + k * 0.03, rz = -(14 - k * 3);
    both('UpperArm', [w, 0.34, w - 0.05], [x, y, 0], k % 2 ? BK2 : BK, { material: 'Pebble', rot: [0, 0, rz] });
    both('UpperArm', [w + 0.02, 0.045, w - 0.03], [x, y - 0.17, 0], PI, { rot: [0, 0, rz] });
    both('UpperArm', [0.08, 0.08, 0.05], [x + 0.35, y - 0.08 - k * 0.0, -(w - 0.05) / 2 - 0.02], MET, { material: 'Metal', rot: [0, 0, rz] });
  }
  // insignia propia en la hombrera izquierda: octógono rojo con tres zarpazos negros
  // (la placa se gira primero en su plano y luego se inclina como la hombrera: ángulos XYZ de Rz·Rx)
  const tilt = (ax, az) => { const a = ax * D2R, c = az * D2R; return [Math.atan2(Math.cos(c) * Math.sin(a), Math.cos(a)) / D2R, Math.asin(Math.sin(c) * Math.sin(a)) / D2R, Math.atan2(Math.sin(c) * Math.cos(a), Math.cos(c)) / D2R]; };
  const face = (d, y) => [-0.12 - d * Math.cos(14 * D2R), 0.42 + y - d * Math.sin(14 * D2R)];
  for (const ax of [0, 45]) { const [x, y] = face(0.78, 0); add('LeftUpperArm', [0.05, 0.56, 0.56], [x, y, 0], RED, { rot: tilt(ax, 14) }); }
  for (let i = 0; i < 3; i++) { const [x, y] = face(0.81, 0); add('LeftUpperArm', [0.04, 0.46 - Math.abs(i - 1) * 0.1, 0.07], [x, y, -0.14 + i * 0.14], BK, { rot: tilt(28, 14) }); }
  both('UpperArm', [1.06, 0.6, 1.06], [0, -0.26, 0], BK, P);
  // brazales con correas, cresta lateral y codera
  both('LowerArm', [1.14, 0.95, 1.14], [0, -0.03, 0], BK2, P);
  for (const y of [0.44, -0.5]) both('LowerArm', [1.18, 0.05, 1.18], [0, y, 0], PI);
  for (const y of [0.22, -0.02, -0.26]) { both('LowerArm', [1.17, 0.08, 1.17], [0, y, 0], STR, L); both('LowerArm', [0.05, 0.12, 0.14], [0.6, y, -0.2], MET, ME); }
  both('LowerArm', [0.08, 0.8, 0.36], [0.6, 0, 0.18], BK, P);
  both('LowerArm', [0.6, 0.36, 0.2], [0, 0.42, 0.6], BK, { material: 'Pebble', rot: [-15, 0, 0] });
  // guanteletes
  both('Hand', [1.12, 0.32, 1.12], [0, 0, 0], BK, P);
  both('Hand', [1.2, 0.14, 1.2], [0, 0.17, 0], BK2, P);
  both('Hand', [1.0, 0.14, 0.22], [0, -0.04, -0.56], BK2, P);
  for (let i = 0; i < 4; i++) both('Hand', [0.2, 0.3, 0.24], [-0.36 + i * 0.24, -0.27, -0.12], BK, P);
  // cinturón con hebilla de placa y braguetón ribeteado
  add('LowerTorso', [2.22, 0.34, 1.22], [0, 0, 0], STR, L);
  add('LowerTorso', [0.52, 0.32, 0.08], [0, 0, -0.64], MET, ME);
  add('LowerTorso', [0.32, 0.16, 0.04], [0, 0, -0.68], BK);
  for (const s of [-1, 1]) add('LowerTorso', [0.08, 0.08, 0.04], [s * 0.7, 0, -0.62], MET, ME);
  add('LowerTorso', [0.7, 0.36, 0.08], [0, -0.36, -0.58], BK2, P); frame('LowerTorso', 0.7, 0.36, 0, -0.36, -0.625);
  // muslos con costuras ribeteadas y dos correas; rodilleras; botas altas y pesadas
  both('UpperLeg', [1.1, 1.22, 1.1], [0, 0, 0], BK, P);
  both('UpperLeg', [0.045, 1.12, 0.04], [0.565, 0, 0], PI);
  both('UpperLeg', [0.7, 0.5, 0.06], [0, -0.12, -0.57], BK2, P); frame('RightUpperLeg', 0.7, 0.5, 0, -0.12, -0.605); frame('LeftUpperLeg', 0.7, 0.5, 0, -0.12, -0.605);
  for (const y of [0.3, -0.48]) { both('UpperLeg', [1.14, 0.1, 1.14], [0, y, 0], STR, L); both('UpperLeg', [0.16, 0.14, 0.05], [0, y, -0.6], MET, ME); }
  both('LowerLeg', [1.12, 1.2, 1.12], [0, 0, 0], BK, P);
  both('LowerLeg', [0.84, 0.48, 0.22], [0, 0.46, -0.6], BK2, P);
  both('LowerLeg', [0.88, 0.05, 0.24], [0, 0.22, -0.6], PI);
  both('LowerLeg', [1.3, 0.5, 1.3], [0, -0.35, 0], BK2, P);
  both('LowerLeg', [1.32, 0.05, 1.32], [0, -0.1, 0], PI);
  for (const y of [-0.24, -0.46]) { both('LowerLeg', [1.34, 0.08, 1.34], [0, y, 0], STR, L); both('LowerLeg', [0.05, 0.12, 0.14], [0.68, y, -0.2], MET, ME); }
  both('Foot', [1.3, 0.4, 1.46], [0, 0.04, -0.16], BK, P);
  both('Foot', [1.32, 0.1, 1.48], [0, -0.15, -0.16], [16, 14, 14]);
  both('Foot', [1.2, 0.26, 0.3], [0, 0.02, -0.82], BK2, P);
  return S;
}

const SETS = { Leather: leather(), Wolf: wolf(), Dragon: dragon() };
for (const k in SETS) { delete SETS[k].add; delete SETS[k].both; if (!SETS[k].bare) SETS[k].bare = []; }
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
