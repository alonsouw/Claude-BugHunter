/*
 * La cura («Remedio del Alba»): ingredientes, plantas, caldero y el frasco final, en bloques al estilo Roblox.
 * Los usan igual el instalador de Studio (tools/build_roblox.js los convierte en Luau) y el visor web.
 *
 * Cada modelo es una lista de bloques relativa al centro del primer bloque (el Handle de los Tools).
 * bloque: { name?, size, offset, rot (grados XYZ), color, material }
 */
(function (root) {
const D2R = Math.PI / 180;
const B = (size, offset, color, x = {}) => ({ size, offset, color, rot: x.rot || [0, 0, 0], material: x.material || 'SmoothPlastic', name: x.name });
// cadena de segmentos que empiezan donde acaba el anterior (colmillos, astas): cada uno con su largo, grosor y giro (rx, rz)
function chain(L, start, segs, color, x = {}) {
  let p = start.slice();
  for (const s of segs) {
    const rx = s[2] * D2R, rz = s[3] * D2R;
    const d = [-Math.sin(rz), Math.cos(rz) * Math.cos(rx), Math.cos(rz) * Math.sin(rx)];
    L.push(B([s[1], s[0], s[1] * (x.depth || 1)], [p[0] + d[0] * s[0] / 2, p[1] + d[1] * s[0] / 2, p[2] + d[2] * s[0] / 2], s[4] || color, Object.assign({}, x, { rot: [s[2], 0, s[3]] })));
    p = [p[0] + d[0] * s[0] * 0.92, p[1] + d[1] * s[0] * 0.92, p[2] + d[2] * s[0] * 0.92];
  }
  return p;
}

// saliva de dragón: frasco de cristal con un líquido ámbar verdoso que brilla y burbujas
function saliva() {
  return [
    B([0.5, 0.7, 0.5], [0, 0, 0], [200, 230, 220], { name: 'Handle', material: 'Glass' }),
    B([0.42, 0.5, 0.42], [0, -0.08, 0], [190, 230, 60], { material: 'Neon' }),
    B([0.3, 0.14, 0.3], [0, 0.42, 0], [200, 230, 220], { material: 'Glass' }),
    B([0.26, 0.16, 0.26], [0, 0.55, 0], [120, 84, 50], { material: 'Wood' }),
    B([0.08, 0.08, 0.08], [0.1, 0.05, -0.18], [240, 255, 170], { material: 'Neon' }),
    B([0.06, 0.06, 0.06], [-0.12, -0.12, -0.19], [240, 255, 170], { material: 'Neon' }),
    B([0.54, 0.06, 0.54], [0, -0.33, 0], [90, 70, 50], { material: 'Wood' }),
    B([0.06, 0.3, 0.04], [0.15, 0.25, -0.24], [190, 230, 60], { material: 'Neon', rot: [0, 0, 10] }),   // gota que resbala
  ];
}
// colmillo del lobo alfa: curvo, amarillento, con un cordón de cuero
function fang() {
  const L = [B([0.32, 0.36, 0.28], [0, 0, 0], [92, 62, 40], { name: 'Handle', material: 'Leather' })];
  L.push(B([0.34, 0.12, 0.3], [0, -0.22, 0], [70, 40, 30], { material: 'Leather' }));
  const tip = chain(L, [0, 0.12, 0], [[0.34, 0.28, 8, 0, [236, 226, 196]], [0.32, 0.23, 22, 0, [232, 220, 186]], [0.28, 0.18, 38, 0, [226, 212, 176]], [0.24, 0.12, 55, 0, [218, 202, 164]], [0.18, 0.07, 70, 0, [210, 194, 156]]], null);
  L.push(B([0.05, 0.36, 0.05], [0, 0.42, -0.1], [150, 40, 36], { rot: [12, 0, 0] }));   // sangre seca
  return L;
}
// asta maldita: cuerna oscura con venas rojas que brillan
function antler() {
  const L = [B([0.24, 0.3, 0.24], [0, 0, 0], [110, 30, 30], { name: 'Handle' })], BR = [68, 54, 44], RV = [210, 30, 30];
  const top = chain(L, [0, 0.12, 0], [[0.6, 0.2, 0, -6], [0.55, 0.17, 0, -14], [0.5, 0.14, 0, -24], [0.35, 0.1, 0, -36]], BR);
  chain(L, [0.06, 0.55, 0], [[0.5, 0.12, 0, 42], [0.32, 0.08, 0, 25]], BR);       // candiles hacia fuera
  chain(L, [0.2, 1.05, 0], [[0.45, 0.11, 18, -60], [0.25, 0.07, 30, -40]], BR);
  chain(L, [0.32, 1.35, 0], [[0.4, 0.09, -20, 10]], BR);
  chain(L, [0.02, 0.15, -0.11], [[0.55, 0.035, 0, -6], [0.5, 0.035, 0, -14], [0.3, 0.035, 0, -24]], RV, { material: 'Neon' });   // venas que brillan
  chain(L, [0.08, 0.58, -0.07], [[0.4, 0.03, 0, 42]], RV, { material: 'Neon' });
  return L;
}
// perla negra del pez gigante: oscura, con destellos morados
function pearl() {
  return [
    B([0.56, 0.56, 0.56], [0, 0, 0], [24, 20, 30], { name: 'Handle', material: 'Glass' }),
    B([0.5, 0.5, 0.5], [0, 0, 0], [30, 24, 40], { rot: [45, 45, 0], material: 'Glass' }),
    B([0.42, 0.42, 0.42], [0, 0, 0], [40, 30, 56], { rot: [0, 45, 45], material: 'Glass' }),
    B([0.1, 0.1, 0.04], [0.12, 0.14, -0.3], [200, 140, 255], { material: 'Neon' }),
    B([0.06, 0.06, 0.04], [-0.1, -0.06, -0.3], [170, 110, 240], { material: 'Neon' }),
  ];
}
// corazón podrido del bruto: rojo oscuro, venas negras y pústulas verdes
function heart() {
  return [
    B([0.6, 0.6, 0.5], [0, 0, 0], [110, 20, 26], { name: 'Handle' }),
    B([0.4, 0.4, 0.44], [-0.18, 0.28, 0], [120, 24, 30]),
    B([0.36, 0.36, 0.42], [0.2, 0.3, 0], [104, 18, 24]),
    B([0.36, 0.36, 0.4], [0, -0.32, 0], [96, 16, 22], { rot: [0, 0, 45] }),
    B([0.12, 0.3, 0.12], [-0.12, 0.58, 0.05], [80, 14, 20]),
    B([0.1, 0.24, 0.1], [0.14, 0.58, -0.05], [140, 140, 120]),
    B([0.04, 0.5, 0.04], [0.05, 0.05, -0.26], [40, 8, 12], { rot: [0, 0, 20] }),
    B([0.04, 0.4, 0.04], [-0.15, -0.05, -0.26], [40, 8, 12], { rot: [0, 0, -25] }),
    B([0.12, 0.12, 0.12], [0.2, -0.05, -0.25], [190, 232, 70], { material: 'Neon' }),
    B([0.09, 0.09, 0.09], [-0.22, 0.15, -0.24], [190, 232, 70], { material: 'Neon' }),
  ];
}
// flor de luna (cogida): tallo y cinco pétalos azul pálido que brillan
function moonflower() {
  const L = [B([0.08, 0.8, 0.08], [0, 0, 0], [60, 110, 70], { name: 'Handle' })];
  for (let i = 0; i < 5; i++) { const a = i / 5 * Math.PI * 2; L.push(B([0.14, 0.04, 0.32], [Math.sin(a) * 0.16, 0.44, Math.cos(a) * 0.16], [190, 225, 255], { material: 'Neon', rot: [-25, a / D2R, 0] })); }
  L.push(B([0.1, 0.1, 0.1], [0, 0.46, 0], [255, 250, 200], { material: 'Neon' }));
  L.push(B([0.24, 0.03, 0.12], [0.1, -0.1, 0], [70, 130, 80], { rot: [0, 0, -20] }));
  L.push(B([0.22, 0.03, 0.1], [-0.1, 0.05, 0], [70, 130, 80], { rot: [0, 30, 20] }));
  return L;
}
// raíz de sangre: raíces retorcidas rojas con tierra pegada
function bloodroot() {
  return [
    B([0.3, 0.5, 0.3], [0, 0, 0], [140, 26, 34], { name: 'Handle', rot: [0, 0, 10] }),
    B([0.2, 0.45, 0.2], [0.14, -0.35, 0.05], [130, 22, 30], { rot: [0, 0, -25] }),
    B([0.14, 0.4, 0.14], [-0.16, -0.32, -0.05], [124, 20, 28], { rot: [10, 0, 30] }),
    B([0.1, 0.35, 0.1], [0.28, -0.6, 0.06], [118, 18, 26], { rot: [0, 0, -45] }),
    B([0.08, 0.3, 0.08], [-0.3, -0.58, 0], [118, 18, 26], { rot: [0, 0, 50] }),
    B([0.34, 0.16, 0.34], [0, 0.22, 0], [70, 52, 36], { material: 'Ground' }),
    B([0.06, 0.3, 0.06], [0.05, 0.4, 0], [60, 110, 50], { rot: [0, 0, 15] }),
    B([0.06, 0.26, 0.06], [-0.06, 0.38, 0.03], [60, 110, 50], { rot: [0, 0, -20] }),
  ];
}
// el Remedio del Alba: frasco con líquido dorado que brilla, tapón dorado y un sol
function remedy() {
  return [
    B([0.62, 0.8, 0.62], [0, 0, 0], [230, 236, 240], { name: 'Handle', material: 'Glass' }),
    B([0.54, 0.62, 0.54], [0, -0.06, 0], [255, 214, 110], { material: 'Neon' }),
    B([0.32, 0.22, 0.32], [0, 0.5, 0], [230, 236, 240], { material: 'Glass' }),
    B([0.38, 0.14, 0.38], [0, 0.66, 0], [214, 170, 60], { material: 'Metal' }),
    B([0.1, 0.1, 0.1], [0, 0.78, 0], [214, 170, 60], { material: 'Metal' }),
    B([0.66, 0.06, 0.66], [0, -0.38, 0], [214, 170, 60], { material: 'Metal' }),
    B([0.2, 0.2, 0.03], [0, 0.0, -0.33], [255, 250, 220], { material: 'Neon', rot: [0, 0, 45] }),
    B([0.36, 0.05, 0.03], [0, 0.0, -0.335], [255, 236, 160], { material: 'Neon' }),
    B([0.05, 0.36, 0.03], [0, 0.0, -0.335], [255, 236, 160], { material: 'Neon' }),
  ];
}
// ---------------------------------------------------------------- en el mundo
// planta de flor de luna: de noche abierta (Petal), de día un capullo cerrado (Bud)
function moonPlant() {
  const L = [B([1.4, 0.2, 1.4], [0, 0.1, 0], [52, 74, 44], { name: 'Handle', material: 'Grass' })];
  for (const [x, z, h] of [[0, 0, 1.6], [0.35, 0.2, 1.1], [-0.3, -0.2, 1.25]]) {
    L.push(B([0.1, h, 0.1], [x, 0.2 + h / 2, z], [60, 110, 70]));
    for (let i = 0; i < 5; i++) { const a = i / 5 * Math.PI * 2; L.push(B([0.18, 0.05, 0.4], [x + Math.sin(a) * 0.2, 0.25 + h, z + Math.cos(a) * 0.2], [190, 225, 255], { material: 'Neon', rot: [-25, a / D2R, 0], name: 'Petal' })); }
    L.push(B([0.12, 0.12, 0.12], [x, 0.27 + h, z], [255, 250, 200], { material: 'Neon', name: 'Petal' }));
    L.push(B([0.18, 0.3, 0.18], [x, 0.3 + h, z], [70, 110, 90], { name: 'Bud' }));
  }
  for (const [x, z, r] of [[0.3, -0.3, 30], [-0.35, 0.3, -20], [0.1, 0.4, 70]]) L.push(B([0.5, 0.04, 0.18], [x, 0.45, z], [70, 130, 80], { rot: [0, r, 15] }));
  return L;
}
// montículo de raíz de sangre: tierra removida con raíces rojas asomando
function rootMound() {
  const L = [B([1.6, 0.4, 1.4], [0, 0.2, 0], [74, 56, 40], { name: 'Handle', material: 'Ground' })];
  L.push(B([1.0, 0.3, 0.9], [0.1, 0.5, 0], [84, 64, 46], { material: 'Ground' }));
  for (const [x, z, r] of [[0.3, 0.1, -30], [-0.25, -0.15, 40], [0, 0.35, 10], [0.45, -0.3, -60]]) L.push(B([0.14, 0.6, 0.14], [x, 0.6, z], [140, 26, 34], { rot: [r / 3, 0, r] }));
  for (const [x, z] of [[0.2, -0.1], [-0.2, 0.2]]) L.push(B([0.06, 0.4, 0.06], [x, 0.85, z], [60, 110, 50], { rot: [0, 0, x * 60] }));
  return L;
}
// caldero de la cura: olla de hierro octogonal sobre patas y fuego, con el líquido (Liquid) y siete peanas alrededor
function cauldron() {
  const L = [B([6.5, 0.3, 6.5], [0, 0.15, 0], [70, 66, 62], { name: 'Handle', material: 'Slate' })], IRON = [40, 38, 40];
  for (let i = 0; i < 8; i++) { const a = i / 8 * Math.PI * 2; L.push(B([1.35, 1.8, 0.25], [Math.sin(a) * 1.55, 2.1, Math.cos(a) * 1.55], IRON, { material: 'Metal', rot: [0, a / D2R, 0] })); }
  for (let i = 0; i < 8; i++) { const a = (i + 0.5) / 8 * Math.PI * 2; L.push(B([1.0, 0.2, 0.3], [Math.sin(a) * 1.68, 3.0, Math.cos(a) * 1.68], [60, 56, 58], { material: 'Metal', rot: [0, a / D2R, 0] })); }
  L.push(B([3.0, 0.3, 3.0], [0, 1.25, 0], IRON, { material: 'Metal' }));
  L.push(B([2.9, 0.2, 2.9], [0, 2.7, 0], [70, 120, 60], { material: 'Neon', name: 'Liquid' }));
  for (const s of [[1, 1], [1, -1], [-1, 1], [-1, -1]]) L.push(B([0.3, 1.1, 0.3], [s[0] * 1.2, 0.75, s[1] * 1.2], IRON, { material: 'Metal' }));
  L.push(B([1.0, 0.6, 1.0], [0, 0.6, 0], [255, 120, 30], { material: 'Neon', name: 'Fire' }));
  L.push(B([0.6, 0.8, 0.6], [0.1, 0.7, 0.05], [255, 190, 60], { material: 'Neon', rot: [0, 40, 0] }));
  for (const s of [-1, 1]) L.push(B([0.25, 0.25, 0.8], [s * 1.75, 2.85, 0], IRON, { material: 'Metal' }));   // asas
  // peanas de los siete ingredientes (Slot1..Slot7): se encienden al echar cada uno
  for (let i = 0; i < 7; i++) {
    const a = i / 7 * Math.PI * 2 + Math.PI;
    L.push(B([0.7, 1.2, 0.7], [Math.sin(a) * 4.3, 0.9, Math.cos(a) * 4.3], [90, 86, 80], { material: 'Slate' }));
    L.push(B([0.5, 0.2, 0.5], [Math.sin(a) * 4.3, 1.6, Math.cos(a) * 4.3], [60, 56, 54], { name: 'Slot' + (i + 1), material: 'Neon' }));
  }
  return L;
}

const ITEMS = { DragonSaliva: saliva(), AlphaFang: fang(), CursedAntler: antler(), BlackPearl: pearl(), BruteHeart: heart(), Moonflower: moonflower(), BloodRoot: bloodroot(), Remedy: remedy() };
const WORLD = { MoonflowerPlant: moonPlant(), BloodRootMound: rootMound(), Cauldron: cauldron() };
// la receta: qué hace falta, cuánto, y la pista que se ve en el recetario
const RECIPE = [
  { id: 'DragonSaliva', name: 'Saliva de dragón', need: 1, hint: 'Mata al dragón que guarda la guarida.', color: [190, 230, 60] },
  { id: 'AlphaFang', name: 'Colmillo de alfa', need: 1, hint: 'Lo suelta el lobo alfa al morir.', color: [236, 226, 196] },
  { id: 'CursedAntler', name: 'Asta maldita', need: 1, hint: 'Un ciervo maldito la deja caer al transformarse.', color: [200, 30, 30] },
  { id: 'BlackPearl', name: 'Perla negra', need: 1, hint: 'La lleva dentro el pez infectado gigante.', color: [170, 110, 240] },
  { id: 'BruteHeart', name: 'Corazón del bruto', need: 1, hint: 'Arráncaselo a un infectado bruto.', color: [160, 30, 36] },
  { id: 'Moonflower', name: 'Flor de luna', need: 3, hint: 'Solo se abre de noche, en el bosque.', color: [190, 225, 255] },
  { id: 'BloodRoot', name: 'Raíz de sangre', need: 2, hint: 'Desentiérrala; crece en la tierra enferma.', color: [140, 26, 34] },
];
root.CURE_ITEMS = ITEMS;
root.CURE_WORLD = WORLD;
root.CURE_RECIPE = RECIPE;
})(typeof window !== 'undefined' ? window : globalThis);
