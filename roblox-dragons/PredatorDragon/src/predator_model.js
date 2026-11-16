/*
 * Dragón Depredador (Karnathys sanguifauces): generador del modelo segmentado.
 * Basado en la hoja de diseño del usuario: cuadrúpedo negro con heridas rojas y costillas
 * expuestas, fauces abiertas con babas y lengua colgante, cuernos hacia atrás, cresta de púas,
 * alas rasgadas con membrana granate y cola larga con aleta dentada.
 * Ojos: dos puntos blancos hundidos bajo una ceja pesada (Neon en Roblox).
 * Requiere dragon_core.js. Salida en espacio Roblox (Y arriba, mira a -Z, studs).
 */
(function (root) {
'use strict';
const { samp } = root.DragonCore;

const REG = {
  skin: [0, 0, 0.5, 0.5], bone: [0.5, 0, 1, 0.25], flesh: [0.5, 0.25, 1, 0.5], mem: [0, 0.5, 0.5, 1],
  claw: [0.5, 0.5, 0.75, 0.75], teeth: [0.75, 0.5, 1, 0.75], gum: [0.5, 0.75, 0.75, 1], eye: [0.75, 0.75, 1, 1]
};
const PALETTE = { skin: '#1b191a', scale: '#2c2829', wound: '#6e1c22', flesh: '#4e0f15', tongue: '#b07a78', bone: '#3a332f', mem: '#2a1416', teeth: '#e8e2d8', eye: '#ffffff' };

function paintAtlas(size, seed) {
  const A = root.DragonCore.painter(size, seed), { R, C, H, G, both, clip, blob, veins } = A;
  // Piel: escamas negras superpuestas, polvo gris y grietas rojas.
  both(REG.skin, (x, y, w, h) => {
    C.fillStyle = '#121112'; C.fillRect(x, y, w, h);
    const s = w / 46;
    for (let r = -1; r < h / (s * 0.62) + 1; r++) for (let q = -1; q < w / s + 1; q++) {
      const cx = x + q * s + (r % 2 ? s / 2 : 0) + (R() - 0.5) * s * 0.15, cy = y + r * s * 0.62, rx = s * (0.55 + R() * 0.12), ry = s * 0.5;
      const g = C.createRadialGradient(cx, cy - ry * 0.35, 1, cx, cy, rx); const l = 30 + R() * 22;
      g.addColorStop(0, `rgb(${l + 8},${l + 3},${l + 4})`); g.addColorStop(0.75, `rgb(${l * 0.6},${l * 0.55},${l * 0.57})`); g.addColorStop(1, '#070607');
      C.fillStyle = g; C.beginPath(); C.ellipse(cx, cy, rx, ry, 0, 0, 7); C.fill();
      const gh = H.createRadialGradient(cx, cy - ry * 0.3, 1, cx, cy, rx); gh.addColorStop(0, '#d8d8d8'); gh.addColorStop(0.8, '#808080'); gh.addColorStop(1, '#202020');
      H.fillStyle = gh; H.beginPath(); H.ellipse(cx, cy, rx, ry, 0, 0, 7); H.fill();
    }
    for (let i = 0; i < 70; i++) blob(C, x + R() * w, y + R() * h, 20 + R() * 90, ['rgba(80,16,22,0.14)', 'rgba(70,66,68,0.14)', 'rgba(5,4,5,0.4)'][i % 3]);
    for (let i = 0; i < 14; i++) { // grietas rojas
      let cx = x + R() * w, cy = y + R() * h; C.strokeStyle = 'rgba(140,28,34,0.65)'; H.strokeStyle = 'rgba(40,40,40,0.9)';
      for (const ctx of [C, H]) { ctx.lineWidth = 1 + R() * 2.2; ctx.beginPath(); ctx.moveTo(cx, cy); }
      for (let k = 0; k < 7; k++) { cx += (R() - 0.5) * 26; cy += (R() - 0.5) * 26; C.lineTo(cx, cy); H.lineTo(cx, cy); }
      C.stroke(); H.stroke();
    }
  });
  // Cuernos y púas: hueso oscuro con anillos de crecimiento.
  both(REG.bone, (x, y, w, h) => {
    const g = C.createLinearGradient(0, y, 0, y + h); g.addColorStop(0, '#4a403a'); g.addColorStop(1, '#151211'); C.fillStyle = g; C.fillRect(x, y, w, h);
    for (let i = 0; i < 90; i++) { const yy = y + R() * h; C.strokeStyle = R() < 0.5 ? 'rgba(0,0,0,0.35)' : 'rgba(120,105,95,0.14)'; H.strokeStyle = 'rgba(50,50,50,0.6)'; for (const ctx of [C, H]) { ctx.lineWidth = 0.8 + R() * 1.6; ctx.beginPath(); ctx.moveTo(x, yy); ctx.bezierCurveTo(x + w * 0.3, yy + (R() - 0.5) * 8, x + w * 0.7, yy + (R() - 0.5) * 8, x + w, yy); ctx.stroke(); } }
  });
  // Carne viva de las heridas: fibras musculares húmedas.
  both(REG.flesh, (x, y, w, h) => {
    C.fillStyle = PALETTE.flesh; C.fillRect(x, y, w, h);
    for (let i = 0; i < 1400; i++) { const sx = x + R() * w, sy = y + R() * h, l = 10 + R() * 40; C.strokeStyle = R() < 0.55 ? 'rgba(125,30,38,0.45)' : 'rgba(28,4,8,0.45)'; H.strokeStyle = R() < 0.5 ? 'rgba(200,200,200,0.4)' : 'rgba(60,60,60,0.4)';
      for (const ctx of [C, H]) { ctx.lineWidth = 0.8 + R() * 2; ctx.beginPath(); ctx.moveTo(sx, sy); ctx.quadraticCurveTo(sx + (R() - 0.5) * 8, sy + l / 2, sx + (R() - 0.5) * 6, sy + l); ctx.stroke(); } }
    for (let i = 0; i < 60; i++) blob(C, x + R() * w, y + R() * h, 3 + R() * 12, 'rgba(220,120,120,0.28)');
    for (let i = 0; i < 25; i++) blob(C, x + R() * w, y + R() * h, 10 + R() * 30, 'rgba(15,2,4,0.45)');
  });
  // Membrana: casi negra con interior granate y venas rojas.
  both(REG.mem, (x, y, w, h) => {
    C.fillStyle = '#1a1012'; C.fillRect(x, y, w, h);
    for (let i = 0; i < 80; i++) blob(C, x + R() * w, y + h * (0.15 + R() * 0.85), 25 + R() * 80, 'rgba(105,22,30,0.32)');
    for (let i = 0; i < 40; i++) blob(C, x + R() * w, y + R() * h, 15 + R() * 50, 'rgba(5,3,4,0.4)');
    veins([C, H], ['rgba(140,30,38,0.7)', 'rgba(205,205,205,0.9)'], x, y, w, h, 30, 3.6, true);
  });
  clip(C, REG.claw, (x, y, w, h) => { const g = C.createLinearGradient(0, y, 0, y + h); g.addColorStop(0, '#3a302c'); g.addColorStop(0.5, '#141010'); g.addColorStop(1, '#030202'); C.fillStyle = g; C.fillRect(x, y, w, h); for (let i = 0; i < 200; i++) { const sx = x + R() * w; C.strokeStyle = 'rgba(0,0,0,0.4)'; C.lineWidth = 0.6 + R(); C.beginPath(); C.moveTo(sx, y); C.lineTo(sx + (R() - 0.5) * 6, y + h); C.stroke(); } });
  clip(C, REG.teeth, (x, y, w, h) => { const g = C.createLinearGradient(0, y, 0, y + h); g.addColorStop(0, '#6e2a2a'); g.addColorStop(0.2, '#a08060'); g.addColorStop(0.55, '#d8cfb8'); g.addColorStop(1, '#f0ebe0'); C.fillStyle = g; C.fillRect(x, y, w, h); for (let i = 0; i < 160; i++) { const sx = x + R() * w; C.strokeStyle = 'rgba(110,80,50,0.25)'; C.lineWidth = 0.6 + R(); C.beginPath(); C.moveTo(sx, y); C.lineTo(sx, y + h * (0.3 + R() * 0.6)); C.stroke(); } });
  both(REG.gum, (x, y, w, h) => {
    C.fillStyle = '#a2626a'; C.fillRect(x, y, w, h);
    const g = C.createLinearGradient(x, 0, x + w, 0); g.addColorStop(0, 'rgba(70,20,26,0.55)'); g.addColorStop(0.5, 'rgba(70,20,26,0)'); g.addColorStop(1, 'rgba(70,20,26,0.55)'); C.fillStyle = g; C.fillRect(x, y, w, h);
    C.fillStyle = 'rgba(90,30,36,0.6)'; C.fillRect(x + w * 0.47, y, w * 0.06, h);
    for (let i = 0; i < 1500; i++) { const sx = x + R() * w, sy = y + R() * h; C.fillStyle = 'rgba(70,24,30,0.25)'; H.fillStyle = 'rgba(190,190,190,0.5)'; for (const ctx of [C, H]) { ctx.beginPath(); ctx.arc(sx, sy, 0.6 + R(), 0, 7); ctx.fill(); } }
    for (let i = 0; i < 40; i++) blob(C, x + R() * w, y + R() * h, 4 + R() * 14, 'rgba(240,180,185,0.35)');
  });
  clip(C, REG.eye, (x, y, w, h) => { const g = C.createRadialGradient(x + w / 2, y + h / 2, 1, x + w / 2, y + h / 2, w * 0.6); g.addColorStop(0, '#ffffff'); g.addColorStop(0.7, '#f4f6ff'); g.addColorStop(1, '#c8d2ff'); C.fillStyle = g; C.fillRect(x, y, w, h); });
  A.roughFill(REG, { skin: 170, bone: 140, flesh: 40, mem: 150, claw: 80, teeth: 70, gum: 35, eye: 20 });
  clip(G, REG.skin, (x, y, w, h) => { for (let i = 0; i < 60; i++) blob(G, x + R() * w, y + R() * h, 15 + R() * 50, 'rgba(60,60,60,0.35)'); });
  return A.finish(2.4);
}

function build(THREE, opt) {
  opt = opt || {};
  const K = root.DragonCore.kit(THREE, opt.seed || 222);
  const { V, R, v3, arr, frames, tubeFrom, tube, surf, outward, cone, spike, lump, sphere, fin, limb, talons, wing, mirrorX, part, add } = K;
  const D2R = Math.PI / 180;

  /* --- columna: cuello, pecho, cadera y cola larga --- */
  const SP = [[0, 6.6, 10.4], [0, 6.9, 9.0], [0, 6.4, 7.4], [0, 6.0, 5.8], [0, 6.0, 4.2], [0, 6.1, 1.8], [0, 5.8, -0.8], [0, 5.5, -2.8], [0.3, 5.0, -5.6], [0.8, 4.4, -8.6], [0.9, 3.8, -11.8], [0.4, 3.4, -15.0], [-0.4, 3.2, -18.2], [-0.8, 3.3, -21.4]];
  const SR = [1.0, 1.05, 1.12, 1.3, 1.75, 1.95, 1.8, 1.42, 1.05, 0.8, 0.6, 0.42, 0.27, 0.12];
  const SX = 1.05, SY = 1.0;
  const S = frames(SP, SR, 300), ti = k => k / (SP.length - 1), ix = k => S.idx(ti(k));
  const segs = [['Neck2', 'Neck1', 0, 2, 2], ['Neck1', 'Chest', 2, 4, 4], ['Chest', 'Hips', 4, 6, 6], ['Hips', null, 6, 7, 6.5],
    ['Tail1', 'Hips', 7, 8, 7], ['Tail2', 'Tail1', 8, 9, 8], ['Tail3', 'Tail2', 9, 10, 9], ['Tail4', 'Tail3', 10, 11, 10], ['Tail5', 'Tail4', 11, 12, 11], ['Tail6', 'Tail5', 12, 13, 12]];
  for (const [name, parent, , , pv] of segs) part(name, parent, S.at(ti(pv)).p);
  for (const [name, , a, b] of segs) add(name, tubeFrom(S, ix(a) - (a > 0 ? 5 : 0), ix(b) + (b < 13 ? 5 : 0), { rs: 20, sx: SX, sy: SY, flat: 0.8,
    bulge: name === 'Chest' ? (lf) => 0.06 * Math.sin(Math.PI * lf) : null }), 'skin');
  const segOf = t => { for (const [name, , a, b] of segs) if (t >= ti(a) && t <= ti(b)) return name; return 'Tail6'; };

  // cresta de púas curvas desde la nuca hasta la cola
  const crestH = t => t < 0.12 ? 0.75 + t * 3 : t < 0.42 ? 1.45 - (t - 0.12) * 0.9 : Math.max(0.32, 1.18 - (t - 0.42) * 1.45);
  for (let k = 0; k < 40; k++) {
    const t = 0.015 + 0.95 * k / 39, f = S.at(t), o = outward(f, Math.PI / 2, SX, SY), L = crestH(t) * (0.85 + R() * 0.3);
    add(segOf(t), spike(surf(f, Math.PI / 2, 0.82, SX, SY), o.clone().multiplyScalar(0.8).addScaledVector(f.T, 0.62), f.T, L, 0.12 + L * 0.13, 0.22), 'bone');
  }
  // púas laterales de la cola (bordes dentados vistos desde arriba)
  for (let k = 0; k < 14; k++) for (const th of [0, Math.PI]) {
    const t = 0.5 + 0.44 * k / 13, f = S.at(t), o = outward(f, th, SX, SY), L = 0.62 - k * 0.025;
    add(segOf(t), spike(surf(f, th, 0.85, SX, SY), o.clone().addScaledVector(f.T, 1.1), f.T, L, 0.07, 0.15), 'bone');
  }
  // aleta dentada en la punta de la cola (horizontal + vertical) con púas terminales
  { const f = S.at(1), L = 3.6, Wd = 1.15, poly = [], N = 14;
    for (let i = 0; i <= N; i++) { const x = (i / N) * L, w = Wd * Math.pow(Math.sin(Math.PI * Math.min(x / L * 1.08, 1)), 0.8) * (i % 2 ? 0.55 : 1); poly.push([x + (i % 2 ? 0 : 0.12), w]); }
    for (let i = N; i >= 0; i--) { const x = (i / N) * L, w = Wd * Math.pow(Math.sin(Math.PI * Math.min(x / L * 1.08, 1)), 0.8) * (i % 2 ? 0.55 : 1); poly.push([x + (i % 2 ? 0 : 0.12), -w]); }
    const o = f.p.clone().addScaledVector(f.T, -0.9);
    add('Tail6', fin(poly, o, f.T, f.B, 0.08), 'mem');
    add('Tail6', fin(poly.map(([a, b]) => [a * 0.8, b * 0.55]), o, f.T, f.N, 0.07), 'mem');
    add('Tail6', spike(o.clone().addScaledVector(f.T, L * 0.9), f.T, f.N, 1.1, 0.1, 0.05), 'bone');
  }
  // heridas abiertas: carne viva con costillas al aire (flanco izquierdo grande, otras menores)
  function wound(t0, t1, th, size, ribs) {
    const tm = (t0 + t1) / 2, f = S.at(tm), o = outward(f, th, SX, SY), seg = segOf(tm);
    add(seg, lump(surf(f, th, 0.94, SX, SY), f.T.clone(), o, new V((t1 - t0) * 31 * size, 0.22, f.r * 0.62 * size), 2), 'flesh');
    for (let k = 0; k < (ribs || 0); k++) {
      const fr = S.at(t0 + (t1 - t0) * (0.15 + 0.7 * k / Math.max(ribs - 1, 1))), pts = [];
      for (let i = 0; i <= 8; i++) { const a = th + (-0.65 + 1.3 * i / 8) * size; pts.push(arr(surf(fr, a, 1.03 + 0.04 * Math.sin(Math.PI * i / 8), SX, SY))); }
      add(seg, tube(pts, [0.09, 0.13, 0.12, 0.08], { rs: 7, n: 18 }), 'teeth');
    }
    for (let k = 0; k < 9; k++) { const fr = S.at(t0 + (t1 - t0) * R()), a = th + (R() < 0.5 ? -1 : 1) * 0.62 * size; add(seg, lump(surf(fr, a, 0.98, SX, SY), fr.T.clone(), outward(fr, a, SX, SY), new V(0.25, 0.12, 0.2).multiplyScalar(0.6 + R()), 1), 'flesh'); }
  }
  wound(ti(4.35), ti(5.75), -12 * D2R, 1.0, 5);
  wound(ti(4.8), ti(5.5), 195 * D2R, 0.7, 3);
  wound(ti(1.2), ti(1.9), 200 * D2R, 0.5, 0);
  wound(ti(6.1), ti(6.8), 10 * D2R, 0.55, 0);
  wound(ti(8.3), ti(8.9), 160 * D2R, 0.45, 0);

  /* --- cabeza (local: +Z hocico, origen en la nuca) --- */
  const HL = 4.6, HW = 2.3, HH = 1.9, hsy = HH / HW;
  const d = v3(SP[0]).sub(v3(SP[1])).normalize();
  const headM = new THREE.Matrix4().compose(v3(SP[0]).addScaledVector(d, -0.45), new THREE.Quaternion().setFromUnitVectors(new V(0, 0, 1), d).multiply(new THREE.Quaternion().setFromAxisAngle(new V(1, 0, 0), 0.22)), new V(1, 1, 1));
  const hadd = (name, geo, mat) => { geo.applyMatrix4(headM); return add(name, geo, mat); };
  part('Head', 'Neck2', v3(SP[0]));
  const skF = frames([[0, 0, 0], [0, 0.25, 1.0], [0, 0.15, 2.2], [0, -0.05, 3.4], [0, -0.2, HL]], [1.15, 1.27, 1.1, 0.92, 0.62], 70);
  hadd('Head', tubeFrom(skF, 0, 70, { rs: 22, sy: hsy, flat: 0.5, bulge: (lf) => 0.05 * Math.sin(lf * Math.PI * 3) }), 'skin');
  // ceja pesada que deja los ojos en sombra
  for (const s of [1, -1]) hadd('Head', tube([[s * 0.58, 1.25, 0.6], [s * 0.86, 1.42, 1.45], [s * 0.72, 1.34, 1.95]], [0.22, 0.26, 0.1], { rs: 12, n: 18 }), 'skin');
  // fosas nasales
  for (const s of [1, -1]) hadd('Head', lump(new V(s * 0.36, 0.32, 4.25), new V(0, 0, 1), new V(0, 1, 0), new V(0.26, 0.16, 0.3), 1), 'skin');
  // cuernos: par mayor hacia atrás y arriba, par menor hacia atrás; espinas de mejilla
  for (const s of [1, -1]) {
    hadd('Head', tube([[s * 0.55, 0.85, 0.4], [s * 0.95, 1.55, -0.6], [s * 1.15, 2.0, -2.0], [s * 1.1, 2.25, -3.1]], [0.38, 0.26, 0.12, 0.015], { rs: 12, n: 28 }), 'bone');
    hadd('Head', tube([[s * 1.0, 0.35, 0.35], [s * 1.6, 0.55, -0.6], [s * 2.0, 0.8, -1.7]], [0.26, 0.15, 0.015], { rs: 10, n: 20 }), 'bone');
    for (let k = 0; k < 4; k++) hadd('Head', spike(new V(s * (1.05 - k * 0.05), -0.2 - k * 0.12, 0.7 + k * 0.45), new V(s * 0.7, -0.15, -1), new V(0, 1, 0), 0.95 - k * 0.15, 0.12, 0.2), 'bone');
  }
  for (let k = 0; k < 3; k++) { const f = skF[6 + k * 7]; hadd('Head', spike(surf(f, Math.PI / 2, 0.9, 1, hsy), new V(0, 1, -1.2), new V(0, 0, -1), 0.55 - k * 0.1, 0.1, 0.2), 'bone'); }
  // ojos: cuenca negra profunda y un punto blanco (pieza propia, Neon en Roblox)
  for (const [nm, s] of [['EyeL', 1], ['EyeR', -1]]) {
    const eye = new V(s * 0.82, 1.02, 2.08);
    hadd('Head', sphere(new V(s * 0.7, 0.92, 2.0), 0.17, 14, 10), 'claw');
    part(nm, 'Head', eye.clone().applyMatrix4(headM));
    hadd(nm, sphere(eye, 0.085, 12, 10), 'eye');
  }
  // encías, dientes superiores y babas colgantes
  const edge = s => { const pts = []; for (let i = 0; i <= 10; i++) { const f = skF[Math.round(22 + i * 4.6)]; pts.push(f.p.clone().addScaledVector(f.B, -s * f.r * 0.84).addScaledVector(f.N, -f.r * hsy * 0.32)); } return pts; };
  for (const s of [1, -1]) {
    const e = edge(s); hadd('Head', tube(e.map(arr), 0.075, { rs: 8, n: 30 }), 'gum');
    for (let k = 0; k < 13; k++) {
      const q = e[0].clone().lerp(e[10], k / 12), fang = k === 10 || k === 3, L = (0.32 + R() * 0.24) * (fang ? 1.9 : 1);
      hadd('Head', spike(q, new V(s * 0.12, -1, 0.15 + R() * 0.25), new V(-s * 0.3, 0, -1), L, 0.06 + L * 0.06, 0.15), 'teeth');
    }
    for (let k = 0; k < 3; k++) { const q = e[2 + k * 3].clone(), L = 0.9 + R() * 0.9; hadd('Head', tube([q, q.clone().add(new V(s * 0.05, -L * 0.6, 0.05)), q.clone().add(new V(-s * 0.04, -L, 0))].map(arr), [0.05, 0.025, 0.07], { rs: 6, n: 10 }), 'teeth'); }
  }
  for (let k = 0; k < 4; k++) hadd('Head', spike(new V((k < 2 ? 1 : -1) * (0.25 + (k % 2) * 0.22), -0.35, 4.3), new V(0, -1, 0.1), new V(0, 0, -1), 0.5 + (k % 2 ? 0 : 0.25), 0.07, 0.1), 'teeth');
  hadd('Head', sphere(new V(0, -0.45, 2.4), 1).applyMatrix4(new THREE.Matrix4().makeScale(0.82, 0.28, 1.6)), 'flesh');
  // mandíbula inferior en U, abierta, con colmillos y lengua colgante
  const hinge = new V(0, -0.55, 0.5);
  const jawRot = new THREE.Matrix4().makeTranslation(hinge.x, hinge.y, hinge.z).multiply(new THREE.Matrix4().makeRotationX(0.5)).multiply(new THREE.Matrix4().makeTranslation(-hinge.x, -hinge.y, -hinge.z));
  const jadd = (name, geo, mat) => { geo.applyMatrix4(jawRot); return hadd(name, geo, mat); };
  part('Jaw', 'Head', hinge.clone().applyMatrix4(headM));
  const jawPts = [[1.0, -0.55, 0.4], [1.12, -0.75, 1.6], [0.88, -0.8, 2.9], [0.38, -0.75, 3.9], [0, -0.72, 4.15], [-0.38, -0.75, 3.9], [-0.88, -0.8, 2.9], [-1.12, -0.75, 1.6], [-1.0, -0.55, 0.4]];
  const jF = frames(jawPts, [0.4, 0.38, 0.33, 0.3, 0.3, 0.3, 0.33, 0.38, 0.4], 80);
  jadd('Jaw', tubeFrom(jF, 0, 80, { rs: 14, sy: 0.75 }), 'skin');
  jadd('Jaw', sphere(new V(0, -0.85, 2.3), 1).applyMatrix4(new THREE.Matrix4().makeScale(0.9, 0.2, 1.75)), 'flesh');
  for (let k = 0; k < 24; k++) {
    const t = 0.1 + 0.8 * k / 23; if (Math.abs(t - 0.5) < 0.04) continue;
    const f = jF.at(t), q = f.p.clone().add(new V(0, f.r * 0.62, 0)), fang = Math.abs(t - 0.36) < 0.02 || Math.abs(t - 0.64) < 0.02, L = (0.26 + R() * 0.2) * (fang ? 2.0 : 1);
    jadd('Jaw', spike(q, new V(-q.x * 0.08, 1, 0.12), new V(-Math.sign(q.x) * 0.3, 0, -1), L, 0.05 + L * 0.06, 0.15), 'teeth');
  }
  for (const s of [1, -1]) for (let k = 0; k < 3; k++) jadd('Jaw', spike(new V(s * 1.15, -0.85, 0.7 + k * 0.5), new V(s * 0.6, -0.4, -1), new V(0, -1, 0), 0.7 - k * 0.12, 0.1, 0.2), 'bone');
  const tonguePivot = new V(0, -0.78, 1.3);
  part('Tongue', 'Jaw', tonguePivot.clone().applyMatrix4(jawRot).applyMatrix4(headM));
  jadd('Tongue', tube([[0, -0.78, 1.3], [0, -0.76, 2.6], [0, -0.8, 3.8], [0.1, -1.25, 4.7], [-0.05, -2.1, 5.0], [0.12, -2.8, 4.75], [0.3, -3.05, 4.3]], [0.36, 0.35, 0.31, 0.25, 0.19, 0.13, 0.04], { rs: 12, n: 44, sy: 0.38 }), 'gum');

  /* --- patas: delanteras y traseras, musculosas, con cuatro garras --- */
  const legs = [
    ['LegF', 'Chest', [[1.4, 5.7, 3.4], [2.3, 3.7, 4.3], [2.2, 1.4, 3.8], [2.35, 0.42, 4.6]], [1.05, 0.7, 0.48, 0.38], [0.38, 0.22, 0.08]],
    ['LegB', 'Hips', [[1.45, 5.4, -1.5], [2.5, 3.7, 0.4], [2.6, 1.8, -1.8], [2.7, 0.42, -1.0]], [1.2, 0.75, 0.46, 0.36], [0.42, 0.2, 0.06]]];
  for (const [base, parent, pts, radii, bulge] of legs) for (const [side, mp] of [['L', p => p], ['R', mirrorX]]) {
    const nm = base + side, P3 = pts.map(mp);
    limb([nm + '_Upper', nm + '_Lower', nm + '_Foot'], parent, P3, radii, { bulge, tendons: [0.6, 2.5], sx: 1.0 });
    talons(nm + '_Foot', v3(P3[3]), new V(side === 'L' ? 0.12 : -0.12, -0.15, 1), 4, 0.95, 0.13, 0.27, true);
    const el = v3(P3[1]); add(nm + '_Lower', spike(el, new V(0, 0.4, -1), new V(0, 1, 0), 0.7, 0.13, 0.15), 'bone');
  }

  /* --- alas enormes y rasgadas --- */
  const W = { shoulder: [1.1, 7.1, 2.8], elbow: [5.0, 11.0, 0.6], wrist: [9.6, 12.4, -1.8], tips: [[17.5, 11.6, -4.8], [16.5, 7.8, -8.8], [13.5, 5.6, -11.4], [9.6, 5.0, -12.2], [6.0, 5.4, -10.6]], rear: [1.3, 5.9, -2.6], armR: 0.55, tatter: 0.18, scallop: 0.18, billow: 0.55, thumb: 1.2, spurs: [[0.5, [0.2, 1, -0.3], 0.9], ['wrist', [0.3, 1, 0.2], 1.0, 'hand']] };
  const mirrorW = w => ({ ...w, shoulder: mirrorX(w.shoulder), elbow: mirrorX(w.elbow), wrist: mirrorX(w.wrist), tips: w.tips.map(mirrorX), rear: mirrorX(w.rear), spurs: w.spurs.map(s => [s[0], mirrorX(s[1]), s[2], s[3]]) });
  wing('WingL_Arm', 'WingL_Hand', 'Chest', W);
  wing('WingR_Arm', 'WingR_Hand', 'Chest', mirrorW(W));

  return { parts: K.finalize(REG), REG, PALETTE, atlas: opt.atlas === false ? null : paintAtlas(opt.atlasSize || 1024, 91) };
}

root.PredatorModel = { build, REG, PALETTE, paintAtlas };
})(typeof window !== 'undefined' ? window : globalThis);
