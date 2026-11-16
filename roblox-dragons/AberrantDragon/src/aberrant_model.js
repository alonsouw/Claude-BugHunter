/*
 * Dragón Aberrante (Xethra contorta): generador del modelo segmentado.
 *
 * Una sola fuente para tres usos:
 *   - la ficha interactiva (vista previa con animaciones),
 *   - la exportación GLB/FBX para Roblox Studio (una MeshPart por segmento),
 *   - los datos del rig (pivotes Motor6D) que usa el instalador Luau.
 *
 * Todo el resultado está en espacio Roblox: Y arriba, el dragón mira hacia -Z,
 * su derecha es +X. Unidades: studs.
 */
(function (root) {
'use strict';

function rng(seed) { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
function samp(arr, u) { if (typeof arr === 'number') return arr; const f = Math.min(Math.max(u, 0), 1) * (arr.length - 1); const i = Math.min(Math.floor(f), arr.length - 2); const k = f - i; return arr[i] * (1 - k) + arr[i + 1] * k; }

/* Regiones del atlas de textura (u, v con v = 0 arriba, como glTF). */
const REG = {
  skin: [0, 0, 0.5, 0.5], bone: [0.5, 0, 1, 0.5], mem: [0, 0.5, 0.5, 1],
  claw: [0.5, 0.5, 0.75, 0.75], teeth: [0.75, 0.5, 1, 0.75], gum: [0.5, 0.75, 0.75, 1], eye: [0.75, 0.75, 1, 1]
};

const PALETTE = {
  skin: '#bdb7aa', bruise: '#5a2f3c', vein: '#4a3f63', bone: '#ddd0b9', mem: '#6b3b3c',
  claw: '#1a1210', teeth: '#e2d6bd', gum: '#4a1418', eye: '#e4ff6e'
};

/* ---------- atlas procedural: color, altura → normal, rugosidad ---------- */
function paintAtlas(size, seed) {
  const R = rng(seed);
  const mk = () => { const c = document.createElement('canvas'); c.width = c.height = size; return c; };
  const col = mk(), hgt = mk(), rough = mk();
  const C = col.getContext('2d'), H = hgt.getContext('2d'), G = rough.getContext('2d');
  H.fillStyle = '#808080'; H.fillRect(0, 0, size, size);
  const px = r => [r[0] * size, r[1] * size, (r[2] - r[0]) * size, (r[3] - r[1]) * size];
  const clip = (ctx, r, fn) => { const [x, y, w, h] = px(r); ctx.save(); ctx.beginPath(); ctx.rect(x, y, w, h); ctx.clip(); fn(x, y, w, h); ctx.restore(); };
  const blob = (ctx, x, y, rad, color) => { const g = ctx.createRadialGradient(x, y, 0, x, y, rad); g.addColorStop(0, color); g.addColorStop(1, 'rgba(0,0,0,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, rad, 0, Math.PI * 2); ctx.fill(); };
  function veins(ctxs, x, y, w, h, n, styleC, styleH, w0, down) {
    function br(px0, py0, a, len, wd, depth) {
      if (len < 3 || wd < 0.35 || depth > 9) return;
      const x2 = px0 + Math.cos(a) * len, y2 = py0 + Math.sin(a) * len;
      const cx = (px0 + x2) / 2 + (R() - 0.5) * len * 0.5, cy = (py0 + y2) / 2 + (R() - 0.5) * len * 0.5;
      ctxs.forEach((ctx, k) => { ctx.strokeStyle = k ? styleH : styleC; ctx.lineWidth = wd; ctx.lineCap = 'round'; ctx.beginPath(); ctx.moveTo(px0, py0); ctx.quadraticCurveTo(cx, cy, x2, y2); ctx.stroke(); });
      br(x2, y2, a + (R() - 0.5) * 0.7, len * 0.86, wd * 0.82, depth + 1);
      if (R() < 0.5) br(x2, y2, a + (R() < 0.5 ? -1 : 1) * (0.5 + R() * 0.6), len * 0.62, wd * 0.6, depth + 1);
    }
    for (let i = 0; i < n; i++) {
      const sx = x + R() * w, sy = down ? y : y + R() * h;
      br(sx, sy, down ? Math.PI / 2 + (R() - 0.5) * 0.5 : R() * Math.PI * 2, (down ? h / 9 : w / 14) * (0.7 + R() * 0.6), w0 * (0.7 + R() * 0.6), 0);
    }
  }

  // Piel: pálida, húmeda, con moretones, venas, arrugas y poros.
  clip(C, REG.skin, (x, y, w, h) => {
    C.fillStyle = PALETTE.skin; C.fillRect(x, y, w, h);
    for (let i = 0; i < 110; i++) blob(C, x + R() * w, y + R() * h, 20 + R() * 110, ['rgba(105,112,92,0.2)', 'rgba(80,88,104,0.18)', 'rgba(236,230,220,0.18)', 'rgba(120,96,80,0.16)'][i % 4]);
    for (let i = 0; i < 22; i++) blob(C, x + R() * w, y + R() * h, 25 + R() * 70, 'rgba(70,30,52,0.34)');
    for (let i = 0; i < 30; i++) blob(C, x + R() * w, y + R() * h, 30 + R() * 90, 'rgba(30,28,30,0.22)');
    for (let i = 0; i < 6; i++) blob(C, x + R() * w, y + R() * h, 10 + R() * 30, 'rgba(120,30,30,0.25)');
  });
  clip(H, REG.skin, (x, y, w, h) => { for (let i = 0; i < 120; i++) blob(H, x + R() * w, y + R() * h, 10 + R() * 50, R() < 0.5 ? 'rgba(160,160,160,0.25)' : 'rgba(90,90,90,0.25)'); });
  clip(C, REG.skin, (x, y, w, h) => clip(H, REG.skin, () => {
    veins([C, H], x, y, w, h, 30, 'rgba(58,62,110,0.4)', 'rgba(150,150,150,0.35)', 2.2, false);
    for (let i = 0; i < 2600; i++) { // arrugas: surcos cortos alrededor del cuerpo
      const sx = x + R() * w, sy = y + R() * h, l = 4 + R() * 16, a = (R() - 0.5) * 0.5;
      C.strokeStyle = 'rgba(60,46,48,0.2)'; H.strokeStyle = 'rgba(70,70,70,0.4)';
      for (const ctx of [C, H]) { ctx.lineWidth = 0.8; ctx.beginPath(); ctx.moveTo(sx, sy); ctx.quadraticCurveTo(sx + l / 2, sy + (R() - 0.5) * 4, sx + Math.cos(a) * l, sy + Math.sin(a) * l); ctx.stroke(); }
    }
    for (let i = 0; i < 6000; i++) { const sx = x + R() * w, sy = y + R() * h, r = 0.5 + R() * 1.1; C.fillStyle = 'rgba(80,55,58,0.22)'; H.fillStyle = 'rgba(50,50,50,0.5)'; for (const ctx of [C, H]) { ctx.beginPath(); ctx.arc(sx, sy, r, 0, 7); ctx.fill(); } }
    for (let i = 0; i < 9; i++) { // cicatrices
      const sx = x + R() * w, sy = y + R() * h, l = 30 + R() * 70, a = R() * Math.PI;
      C.strokeStyle = 'rgba(205,160,160,0.5)'; H.strokeStyle = 'rgba(215,215,215,0.9)';
      for (const ctx of [C, H]) { ctx.lineWidth = 2 + R() * 2; ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(sx + Math.cos(a) * l, sy + Math.sin(a) * l); ctx.stroke(); }
    }
  }));
  // Hueso: marfil sucio con manchas, poros y grietas.
  clip(C, REG.bone, (x, y, w, h) => clip(H, REG.bone, () => {
    C.fillStyle = PALETTE.bone; C.fillRect(x, y, w, h);
    for (let i = 0; i < 70; i++) blob(C, x + R() * w, y + R() * h, 15 + R() * 80, ['rgba(150,118,70,0.2)', 'rgba(90,70,50,0.15)', 'rgba(245,238,225,0.2)'][i % 3]);
    for (let i = 0; i < 40; i++) {
      let cx = x + R() * w, cy = y + R() * h; C.strokeStyle = 'rgba(55,40,28,0.55)'; H.strokeStyle = 'rgba(30,30,30,0.9)';
      for (const ctx of [C, H]) { ctx.lineWidth = 0.6 + R(); ctx.beginPath(); ctx.moveTo(cx, cy); }
      for (let k = 0; k < 9; k++) { cx += (R() - 0.5) * 22; cy += (R() - 0.2) * 16; C.lineTo(cx, cy); H.lineTo(cx, cy); }
      C.stroke(); H.stroke();
    }
    for (let i = 0; i < 3000; i++) { const sx = x + R() * w, sy = y + R() * h; C.fillStyle = 'rgba(110,90,60,0.25)'; H.fillStyle = 'rgba(60,60,60,0.5)'; for (const ctx of [C, H]) { ctx.beginPath(); ctx.arc(sx, sy, 0.5 + R(), 0, 7); ctx.fill(); } }
  }));
  // Membrana: carne fina rojiza con zonas translúcidas y venas que salen del brazo.
  clip(C, REG.mem, (x, y, w, h) => clip(H, REG.mem, () => {
    C.fillStyle = PALETTE.mem; C.fillRect(x, y, w, h);
    for (let i = 0; i < 70; i++) blob(C, x + R() * w, y + h * (0.3 + R() * 0.7), 20 + R() * 70, 'rgba(170,100,92,0.22)');
    for (let i = 0; i < 30; i++) blob(C, x + R() * w, y + R() * h, 10 + R() * 40, 'rgba(40,14,18,0.3)');
    veins([C, H], x, y, w, h, 34, 'rgba(38,10,14,0.75)', 'rgba(200,200,200,0.9)', 3.4, true);
    for (let i = 0; i < 1800; i++) { const sx = x + R() * w, sy = y + R() * h; C.strokeStyle = 'rgba(50,20,22,0.12)'; C.lineWidth = 0.7; C.beginPath(); C.moveTo(sx, sy); C.lineTo(sx + (R() - 0.5) * 3, sy + 6 + R() * 8); C.stroke(); }
  }));
  // Garras: queratina oscura, base más clara, estrías longitudinales.
  clip(C, REG.claw, (x, y, w, h) => clip(H, REG.claw, () => {
    const g = C.createLinearGradient(0, y, 0, y + h); g.addColorStop(0, '#5a463c'); g.addColorStop(0.5, '#2a1e1a'); g.addColorStop(1, '#0d0908'); C.fillStyle = g; C.fillRect(x, y, w, h);
    for (let i = 0; i < 260; i++) { const sx = x + R() * w; C.strokeStyle = R() < 0.5 ? 'rgba(0,0,0,0.35)' : 'rgba(140,120,100,0.15)'; H.strokeStyle = 'rgba(60,60,60,0.6)'; for (const ctx of [C, H]) { ctx.lineWidth = 0.6 + R() * 1.4; ctx.beginPath(); ctx.moveTo(sx, y); ctx.lineTo(sx + (R() - 0.5) * 8, y + h); ctx.stroke(); } }
  }));
  // Dientes: amarillentos en la base, sucios.
  clip(C, REG.teeth, (x, y, w, h) => {
    const g = C.createLinearGradient(0, y, 0, y + h); g.addColorStop(0, '#6a3a2a'); g.addColorStop(0.18, '#9a7a52'); g.addColorStop(0.55, '#d9cdb2'); g.addColorStop(1, '#efe6d2'); C.fillStyle = g; C.fillRect(x, y, w, h);
    for (let i = 0; i < 180; i++) { const sx = x + R() * w; C.strokeStyle = 'rgba(110,85,50,0.22)'; C.lineWidth = 0.6 + R(); C.beginPath(); C.moveTo(sx, y); C.lineTo(sx, y + h * (0.3 + R() * 0.7)); C.stroke(); }
  });
  // Encías y boca: carne húmeda.
  clip(C, REG.gum, (x, y, w, h) => {
    C.fillStyle = PALETTE.gum; C.fillRect(x, y, w, h);
    for (let i = 0; i < 60; i++) blob(C, x + R() * w, y + R() * h, 8 + R() * 40, R() < 0.5 ? 'rgba(150,50,55,0.3)' : 'rgba(20,4,6,0.35)');
    veins([C], x, y, w, h, 12, 'rgba(25,5,8,0.5)', '', 1.6, false);
  });
  // Ojo: iris amarillo enfermizo con pupila vertical.
  clip(C, REG.eye, (x, y, w, h) => {
    const cx = x + w / 2, cy = y + h / 2; const g = C.createRadialGradient(cx, cy, 2, cx, cy, w * 0.55);
    g.addColorStop(0, '#f6ffb0'); g.addColorStop(0.45, '#d4f04e'); g.addColorStop(1, '#5a6a10'); C.fillStyle = g; C.fillRect(x, y, w, h);
    C.fillStyle = '#0a0a04'; C.beginPath(); C.ellipse(cx, cy, w * 0.05, h * 0.42, 0, 0, 7); C.fill();
  });
  // Rugosidad (gris: 0 = brillante, 255 = mate).
  const rr = { skin: 140, bone: 165, mem: 175, claw: 95, teeth: 80, gum: 45, eye: 30 };
  for (const k in REG) { const [x, y, w, h] = px(REG[k]); G.fillStyle = `rgb(${rr[k]},${rr[k]},${rr[k]})`; G.fillRect(x, y, w, h); }
  clip(G, REG.skin, (x, y, w, h) => { for (let i = 0; i < 80; i++) blob(G, x + R() * w, y + R() * h, 20 + R() * 60, 'rgba(70,70,70,0.35)'); });
  // Altura → mapa normal (Sobel), formato OpenGL (+Y), como espera Roblox.
  const nrm = mk(); const N = nrm.getContext('2d');
  const hd = H.getImageData(0, 0, size, size).data, out = N.createImageData(size, size), o = out.data, s = 2.2 / 255;
  const at = (x, y) => hd[((Math.min(Math.max(y, 0), size - 1)) * size + Math.min(Math.max(x, 0), size - 1)) * 4];
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    const dx = (at(x + 1, y - 1) + 2 * at(x + 1, y) + at(x + 1, y + 1) - at(x - 1, y - 1) - 2 * at(x - 1, y) - at(x - 1, y + 1)) * s;
    const dy = (at(x - 1, y + 1) + 2 * at(x, y + 1) + at(x + 1, y + 1) - at(x - 1, y - 1) - 2 * at(x, y - 1) - at(x + 1, y - 1)) * s;
    let nx = -dx, ny = dy, nz = 1; const l = Math.hypot(nx, ny, nz); nx /= l; ny /= l; nz /= l;
    const i = (y * size + x) * 4; o[i] = (nx * 0.5 + 0.5) * 255; o[i + 1] = (ny * 0.5 + 0.5) * 255; o[i + 2] = (nz * 0.5 + 0.5) * 255; o[i + 3] = 255;
  }
  N.putImageData(out, 0, 0);
  return { color: col, normal: nrm, roughness: rough, height: hgt };
}

/* ---------- construcción ---------- */
function build(THREE, opt) {
  opt = opt || {};
  const V = THREE.Vector3, D2R = Math.PI / 180;
  const R = rng(opt.seed || 333);
  const v3 = p => new V(p[0], p[1], p[2]);

  /* marcos de transporte paralelo a lo largo de una curva Catmull-Rom */
  function frames(pts, radii, n) {
    const curve = new THREE.CatmullRomCurve3(pts.map(v3), false, 'centripetal');
    const F = []; let N = null;
    for (let i = 0; i <= n; i++) {
      const t = i / n, p = curve.getPoint(t), T = curve.getTangent(t).normalize();
      if (!N) { N = new V(0, 1, 0).addScaledVector(T, -T.y); if (N.lengthSq() < 1e-4) N = new V(1, 0, 0).addScaledVector(T, -T.x); N.normalize(); }
      else N = N.clone().addScaledVector(T, -N.dot(T)).normalize();
      F.push({ p, T, N: N.clone(), B: new V().crossVectors(T, N).normalize(), r: samp(radii, t), t });
    }
    F.n = n; F.at = t => F[Math.round(Math.min(Math.max(t, 0), 1) * n)]; F.idx = t => Math.round(Math.min(Math.max(t, 0), 1) * n);
    return F;
  }
  function tubeFrom(F, i0, i1, o) {
    o = o || {}; const rs = o.rs || 14, sx = o.sx || 1, sy = o.sy || 1, flat = o.flat || 1;
    i0 = Math.max(0, i0); i1 = Math.min(F.n, i1);
    const pos = [], uv = [], idx = [], cnt = i1 - i0;
    for (let i = i0; i <= i1; i++) {
      const f = F[i], lf = (i - i0) / Math.max(cnt, 1);
      const r = f.r * (o.bulge ? 1 + o.bulge(lf, f.t) : 1);
      for (let j = 0; j <= rs; j++) {
        const a = j / rs * Math.PI * 2; let s = Math.sin(a); if (s < 0) s *= flat;
        const q = f.p.clone().addScaledVector(f.B, Math.cos(a) * r * sx).addScaledVector(f.N, s * r * sy);
        pos.push(q.x, q.y, q.z); uv.push(j / rs, lf);
      }
    }
    const row = rs + 1;
    for (let i = 0; i < cnt; i++) for (let j = 0; j < rs; j++) { const a = i * row + j, b = a + row; idx.push(a, b, a + 1, b, b + 1, a + 1); }
    if (o.caps !== false) {
      const c0 = pos.length / 3, p0 = F[i0].p, p1 = F[i1].p; pos.push(p0.x, p0.y, p0.z, p1.x, p1.y, p1.z); uv.push(0.5, 0, 0.5, 1);
      for (let j = 0; j < rs; j++) { idx.push(c0, j + 1, j); const e = cnt * row; idx.push(c0 + 1, e + j, e + j + 1); }
    }
    const m = Math.floor(cnt / 2) * row, A = new V().fromArray(pos, m * 3), B = new V().fromArray(pos, (m + row) * 3), C = new V().fromArray(pos, (m + 1) * 3);
    if (new V().crossVectors(B.clone().sub(A), C.clone().sub(A)).dot(A.clone().sub(F[i0 + Math.floor(cnt / 2)].p)) < 0)
      for (let k = 0; k < idx.length; k += 3) { const t = idx[k]; idx[k] = idx[k + 1]; idx[k + 1] = t; }
    const g = new THREE.BufferGeometry(); g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3)); g.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2)); g.setIndex(idx); g.computeVertexNormals();
    return g;
  }
  const tube = (pts, radii, o) => { const F = frames(pts, radii, (o && o.n) || 24); return tubeFrom(F, 0, F.n, o); };
  const surf = (f, th, lift, sx, sy) => f.p.clone().addScaledVector(f.B, Math.cos(th) * f.r * (sx || 1) * lift).addScaledVector(f.N, Math.sin(th) * f.r * (sy || 1) * lift);
  const outward = (f, th, sx, sy) => f.B.clone().multiplyScalar(Math.cos(th) * (sx || 1)).addScaledVector(f.N, Math.sin(th) * (sy || 1)).normalize();
  function cone(base, dir, len, rad, seg) { const g = new THREE.ConeGeometry(rad, len, seg || 7); g.translate(0, len / 2, 0); g.applyQuaternion(new THREE.Quaternion().setFromUnitVectors(new V(0, 1, 0), dir.clone().normalize())); g.translate(base.x, base.y, base.z); return g; }
  function spike(base, dir, up, len, r, curl) {
    const d = dir.clone().normalize(), u = up.clone().normalize();
    const p1 = base.clone().addScaledVector(d, len * 0.5).addScaledVector(u, len * curl * 0.3), p2 = base.clone().addScaledVector(d, len).addScaledVector(u, len * curl);
    return tube([base, p1, p2].map(p => [p.x, p.y, p.z]), [r, r * 0.6, r * 0.05], { rs: 8, n: 10 });
  }
  function lump(pos, x, y, scale, detail) {
    const g = new THREE.DodecahedronGeometry(1, detail === undefined ? 1 : detail); const z = new V().crossVectors(x, y).normalize(), yy = new V().crossVectors(z, x).normalize();
    g.applyMatrix4(new THREE.Matrix4().makeBasis(x.clone().normalize(), yy, z).scale(scale).setPosition(pos)); return g;
  }
  function sphere(c, r, w, h) { const g = new THREE.SphereGeometry(r, w || 14, h || 10); g.translate(c.x, c.y, c.z); return g; }

  /* ---------- partes ---------- */
  const P = {}, order = [];
  const part = (name, parent, pivot) => { P[name] = { name, parent, pivot: pivot.clone(), geos: [] }; order.push(name); };
  const add = (name, geo, mat) => { P[name].geos.push({ geo, mat }); return geo; };

  /* --- columna: cuello, pecho, cadera, cola --- */
  const SP = [[0.6, 17.4, 6.8], [0.8, 17.9, 5.2], [0.5, 16.6, 3.2], [0.1, 14.6, 2.0], [-0.3, 12.4, 1.1], [-0.2, 10.6, 0.6], [0, 9.6, 0.2], [0.2, 8.4, -0.8], [0.1, 7.7, -2.1], [-0.2, 7.1, -3.6], [-1.2, 5.9, -6.0], [-2.2, 4.4, -8.4], [-1.6, 3.0, -11.0], [0.6, 2.4, -13.6]];
  const SR = [0.5, 0.46, 0.44, 0.48, 0.55, 0.72, 1.05, 1.5, 1.45, 1.2, 0.72, 0.48, 0.3, 0.13];
  const S = frames(SP, SR, 260); const ti = k => k / (SP.length - 1); const ix = k => S.idx(ti(k));
  const SX = 0.88, SY = 1.08;
  const segs = [
    ['Neck3', 'Neck2', 0, 2, 2], ['Neck2', 'Neck1', 2, 4, 4], ['Neck1', 'Chest', 4, 6, 6], ['Chest', 'Hips', 6, 8, 8],
    ['Hips', null, 8, 9, 8.5], ['Tail1', 'Hips', 9, 10, 9], ['Tail2', 'Tail1', 10, 11, 10], ['Tail3', 'Tail2', 11, 12, 11], ['Tail4', 'Tail3', 12, 13, 12]];
  const pivAt = k => { const f = S.at(ti(k)); return f.p.clone(); };
  for (const [name, parent, a, b, pv] of segs) part(name, parent, pivAt(pv));
  for (const [name, , a, b] of segs) {
    const ov = 4; // solapamiento para ocultar la junta al rotar
    add(name, tubeFrom(S, ix(a) - (a > 0 ? ov : 0), ix(b) + (b < 13 ? ov : 0), { rs: 18, sx: SX, sy: SY, flat: name === 'Chest' || name === 'Hips' ? 0.72 : 0.9,
      bulge: name.startsWith('Neck') ? (lf, t) => 0.08 * Math.sin(lf * Math.PI * 3) : null }), 'skin');
  }
  const segOf = t => { for (const [name, , a, b] of segs) if (t >= ti(a) && t <= ti(b)) return name; return 'Tail4'; };
  // vértebras marcadas a lo largo del lomo
  for (let k = 0; k < 46; k++) {
    const t = 0.04 + 0.9 * k / 45, f = S.at(t), o = outward(f, Math.PI / 2, SX, SY);
    const s = 0.12 + 0.16 * Math.sin(Math.PI * Math.min(1, t * 1.4));
    add(segOf(t), lump(surf(f, Math.PI / 2, 0.9, SX, SY).addScaledVector(o, s * 0.3), f.T.clone(), o.clone().addScaledVector(f.T, -0.3), new V(s * 1.2, s * 0.9, s * 0.75), 1), 'bone');
  }
  // púas óseas sobre la cola
  for (let k = 0; k < 9; k++) { const t = 0.68 + 0.27 * k / 8, f = S.at(t), o = outward(f, Math.PI / 2, SX, SY); add(segOf(t), spike(surf(f, Math.PI / 2, 0.85, SX, SY), o.clone().addScaledVector(f.T, 0.9), f.T, 0.55 - k * 0.03, 0.07, 0.15), 'bone'); }
  // costillas expuestas sobre el pecho hundido
  for (let k = 0; k < 7; k++) {
    const t = ti(6.15 + 1.7 * k / 6), f = S.at(t);
    for (const [a0, a1] of [[-75, 55], [125, 255]]) {
      const pts = []; for (let i = 0; i <= 10; i++) { const q = surf(f, (a0 + (a1 - a0) * i / 10) * D2R, 1.04 - 0.05 * Math.sin(Math.PI * i / 10), SX, SY); pts.push([q.x, q.y, q.z]); }
      add('Chest', tube(pts, [0.07, 0.11, 0.1, 0.07], { rs: 7, n: 18, caps: true }), 'bone');
    }
  }
  // tumores óseos sobre el hombro derecho (asimetría)
  for (let k = 0; k < 22; k++) { const t = ti(5.6 + R() * 1.6), f = S.at(t), a = (150 + R() * 70) * D2R; add(segOf(t), lump(surf(f, a, 0.97, SX, SY), f.T.clone(), outward(f, a, SX, SY), new V(1, 1, 1).multiplyScalar(0.12 + R() * 0.28)), R() < 0.7 ? 'bone' : 'skin'); }
  // cola bifurcada con pinzas
  { const f = S.at(1);
    for (const [s, k] of [[1, 1], [-1, 0.62]]) {
      const p0 = f.p, p1 = p0.clone().addScaledVector(f.T, 0.9 * k).addScaledVector(f.B, s * 0.55 * k), p2 = p1.clone().addScaledVector(f.T, 1.0 * k).addScaledVector(f.B, s * 0.15).addScaledVector(f.N, 0.5 * k);
      add('Tail4', tube([p0, p1, p2].map(p => [p.x, p.y, p.z]), [0.13, 0.1, 0.04], { rs: 9, n: 14 }), 'skin');
      for (const q of [1, -1]) add('Tail4', spike(p2, f.T.clone().addScaledVector(f.N, q * 0.7), f.B.clone().multiplyScalar(-s), 0.55 * k, 0.06, 0.55), 'claw');
    } }

  /* --- cabeza (espacio local: +Z hacia el hocico, origen en la nuca) --- */
  const HL = 3.6, HW = 1.15, HH = 1.35;
  const d = v3(SP[0]).sub(v3(SP[1])).normalize();
  const headM = new THREE.Matrix4().compose(v3(SP[0]).addScaledVector(d, -HW * 0.3), new THREE.Quaternion().setFromUnitVectors(new V(0, 0, 1), d).multiply(new THREE.Quaternion().setFromAxisAngle(new V(1, 0, 0), 1.12)), new V(1, 1, 1));
  const HP = (x, y, z) => new V(x, y, z).applyMatrix4(headM);
  part('Head', 'Neck3', v3(SP[0]));
  const hadd = (name, geo, mat) => { geo.applyMatrix4(headM); return add(name, geo, mat); };
  const skF = frames([[0, 0, 0], [0, 0.2, 0.9], [0, 0.1, 1.9], [0, -0.1, 2.8], [0, -0.28, HL]], [0.58, 0.64, 0.5, 0.36, 0.14], 60);
  const skSY = HH / HW;
  hadd('Head', tubeFrom(skF, 0, 60, { rs: 20, sy: skSY, flat: 0.55, bulge: (lf) => 0.06 * Math.sin(lf * Math.PI * 4) }), 'skin');
  // crestas de la ceja (la izquierda más gruesa) y nódulos del cráneo
  for (const [s, k] of [[1, 1.35], [-1, 0.8]]) hadd('Head', tube([[s * 0.42, 0.42, 0.4], [s * 0.56, 0.36, 1.5], [s * 0.4, 0.12, 2.6]], [0.13 * k, 0.11 * k, 0.04], { rs: 9, n: 16 }), 'bone');
  for (let k = 0; k < 9; k++) { const f = skF[Math.floor(6 + R() * 26)], a = (55 + R() * 70) * D2R; hadd('Head', lump(surf(f, a, 0.95, 1, skSY), f.T.clone(), outward(f, a, 1, skSY), new V(1, 1, 1).multiplyScalar(0.08 + R() * 0.12)), 'bone'); }
  // cuerno curvo solo a la derecha y muñón roto a la izquierda
  hadd('Head', tube([[-0.35, 0.5, 0.6], [-0.65, 1.35, 0.2], [-0.45, 2.0, -0.6], [-0.1, 2.1, -1.3]], [0.2, 0.14, 0.07, 0.015], { rs: 10, n: 24 }), 'bone');
  hadd('Head', tube([[0.35, 0.5, 0.5], [0.52, 0.9, 0.3], [0.58, 1.05, 0.25]], [0.16, 0.13, 0.12], { rs: 9, n: 8 }), 'bone');
  // encías y dientes superiores irregulares
  const mouthEdge = s => { const pts = []; for (let i = 0; i <= 8; i++) { const f = skF[Math.round(18 + i * 5)]; const q = f.p.clone().addScaledVector(f.B, -s * f.r * 0.78).addScaledVector(f.N, -f.r * skSY * 0.45); pts.push(q); } return pts; };
  for (const s of [1, -1]) {
    const edge = mouthEdge(s);
    hadd('Head', tube(edge.map(p => [p.x, p.y, p.z]), 0.08, { rs: 7, n: 24 }), 'gum');
    for (let k = 0; k < 11; k++) { const q = edge[0].clone().lerp(edge[8], k / 10); const L = (0.22 + R() * 0.32) * (k === 2 ? 1.9 : 1); hadd('Head', spike(q, new V(s * 0.15, -1, 0.25 + R() * 0.3), new V(-s * 0.4, 0, -1), L, 0.045 + L * 0.06, 0.18), 'teeth'); }
  }
  hadd('Head', sphere(new V(0, -0.3, 1.6), 1).applyMatrix4(new THREE.Matrix4().makeScale(0.38, 0.22, 0.95).setPosition(0, -0.3 * 0, 0)), 'gum');
  // ojos: uno grande a la derecha, dos pequeños a la izquierda
  const eyes = [['Eye1', 0.44, 175, 0.15], ['Eye2', 0.4, 22, 0.1], ['Eye3', 0.6, 8, 0.075]];
  for (const [nm, u, th, r] of eyes) {
    const f = skF.at(u), p = surf(f, th * D2R, 0.9, 1, skSY), o = outward(f, th * D2R, 1, skSY);
    part(nm, 'Head', p.clone().applyMatrix4(headM));
    hadd(nm, sphere(p.clone().addScaledVector(o, r * 0.25), r, 16, 12), 'eye');
    hadd('Head', tube([p.clone().addScaledVector(f.T, -r * 1.4).addScaledVector(o, r * 0.3), p.clone().addScaledVector(o, r * 0.75).addScaledVector(f.N, r * 0.4), p.clone().addScaledVector(f.T, r * 1.4).addScaledVector(o, r * 0.2)].map(q => [q.x, q.y, q.z]), [0.04, r * 0.45, 0.04], { rs: 7, n: 10 }), 'gum');
  }
  // mandíbula partida en dos mitades que se abren hacia los lados
  for (const [nm, s] of [['JawL', 1], ['JawR', -1]]) {
    const hinge = new V(s * 0.42, -0.36, 0.35);
    part(nm, 'Head', hinge.clone().applyMatrix4(headM));
    const rot = new THREE.Matrix4().makeTranslation(hinge.x, hinge.y, hinge.z).multiply(new THREE.Matrix4().makeRotationFromEuler(new THREE.Euler(0.22, s * 0.16, 0, 'XYZ'))).multiply(new THREE.Matrix4().makeTranslation(-hinge.x, -hinge.y, -hinge.z));
    const jaw = [[s * 0.42, -0.36, 0.35], [s * 0.52, -0.55, 1.4], [s * 0.4, -0.55, 2.5], [s * 0.16, -0.42, 3.25]];
    const jF = frames(jaw, [0.22, 0.19, 0.14, 0.06], 40);
    const jg = [tubeFrom(jF, 0, 40, { rs: 12, sy: 0.7 })];
    for (let k = 0; k < 9; k++) { const f = jF[8 + k * 3], q = f.p.clone().addScaledVector(f.B, s * f.r * 0.5 * (f.B.x * s > 0 ? -1 : 1)).add(new V(-s * 0.06, 0.1, 0)); const L = 0.2 + R() * 0.25; jg.push(spike(q, new V(-s * 0.25, 1, 0.2), new V(-s * 0.3, 0, -1), L, 0.045, 0.2)); }
    jg.push(spike(new V(s * 0.16, -0.38, 3.2), new V(-s * 0.4, 0.6, 0.5), new V(0, 1, 0), 0.75, 0.08, 0.45)); // colmillo en gancho
    jg.push(tube([[s * 0.36, -0.28, 0.9], [s * 0.38, -0.3, 2.0], [s * 0.2, -0.3, 2.9]], 0.07, { rs: 6, n: 16 }));
    jg.forEach((g, i) => { g.applyMatrix4(rot); hadd(nm, g, i === 0 ? 'skin' : i === jg.length - 1 ? 'gum' : 'teeth'); });
  }
  // lengua colgante
  part('Tongue', 'Head', new V(0, -0.42, 0.8).applyMatrix4(headM));
  hadd('Tongue', tube([[0, -0.42, 0.8], [0, -0.62, 2.0], [0.1, -1.15, 3.1], [-0.08, -2.0, 3.45], [0.05, -2.5, 3.3]], [0.17, 0.14, 0.11, 0.07, 0.02], { rs: 10, n: 36, sy: 0.45 }), 'gum');

  /* --- extremidades segmentadas --- */
  function limb(names, parent, pts, radii, o) {
    const F = frames(pts, radii, 30 * (pts.length - 1)); const n = pts.length - 1;
    names.forEach((nm, i) => {
      part(nm, i === 0 ? parent : names[i - 1], v3(pts[i]));
      const i0 = Math.round(F.n * i / n), i1 = Math.round(F.n * (i + 1) / n);
      add(nm, tubeFrom(F, i0 - (i ? 2 : 0), i1 + 2, { rs: 12, bulge: o.bulge ? (lf) => o.bulge[i] * Math.sin(Math.PI * lf) : null }), 'skin');
      if (i > 0 && o.knobs) {
        const jr = samp(radii, i / n), f = F[Math.round(F.n * i / n)];
        add(nm, lump(v3(pts[i]), f.T.clone(), f.N.clone(), new V(jr * 1.35, jr * 1.25, jr * 1.2), 1), 'skin');
        const back = f.T.clone().negate().addScaledVector(f.N, 0.6).normalize();
        add(nm, spike(v3(pts[i]).addScaledVector(back, jr * 0.9), back, f.N, jr * 1.4, jr * 0.32, 0.25), 'bone');
      }
      // tendones visibles a lo largo del segmento
      for (const th of [0.5, 2.4, 4.2]) {
        const tp = []; for (let q = 0; q <= 8; q++) { const fq = F[Math.round(i0 + (i1 - i0) * (0.08 + 0.84 * q / 8))]; const lift = 0.9 + 0.22 * Math.sin(Math.PI * q / 8); const pp = surf(fq, th, lift); tp.push([pp.x, pp.y, pp.z]); }
        add(nm, tube(tp, [0.03, samp(radii, i / n) * 0.16, 0.03], { rs: 6, n: 16 }), 'skin');
      }
    });
    return F;
  }
  function talons(nm, at, fwd, n, len, r, spread, back) {
    const f = fwd.clone().normalize(), side = new V().crossVectors(f, new V(0, 1, 0)).normalize();
    for (let k = 0; k < n; k++) { const off = k - (n - 1) / 2; const dd = f.clone().addScaledVector(side, off * 0.45).normalize(); const base = at.clone().addScaledVector(side, off * spread);
      add(nm, tube([base, base.clone().addScaledVector(dd, len * 0.35).add(new V(0, 0.05, 0))].map(p => [p.x, p.y, p.z]), [r * 1.2, r], { rs: 8, n: 4 }), 'skin');
      add(nm, spike(base.clone().addScaledVector(dd, len * 0.3), dd, new V(0, -1, 0), len, r, 0.55), 'claw'); }
    if (back) add(nm, spike(at, f.clone().negate().add(new V(0, -0.3, 0)), new V(0, -1, 0), len * 0.6, r * 0.9, 0.4), 'claw');
  }
  // piernas (la izquierda algo más larga): muslo, espinilla, pie
  limb(['LegL_Thigh', 'LegL_Shin', 'LegL_Foot'], 'Hips', [[0.9, 7.2, -3.1], [2.6, 5.6, -0.2], [2.8, 3.0, -4.6], [3.2, 0.35, -3.6]], [0.72, 0.38, 0.24, 0.17], { bulge: [0.35, 0.18, 0.05], knobs: true });
  talons('LegL_Foot', new V(3.2, 0.3, -3.6), new V(0.15, -0.1, 1), 3, 0.9, 0.09, 0.22, true);
  limb(['LegR_Thigh', 'LegR_Shin', 'LegR_Foot'], 'Hips', [[-0.9, 7.3, -3.0], [-2.2, 5.2, 0.5], [-2.4, 2.6, -3.5], [-2.6, 0.35, -2.3]], [0.7, 0.36, 0.23, 0.16], { bulge: [0.3, 0.15, 0.05], knobs: true });
  talons('LegR_Foot', new V(-2.6, 0.3, -2.3), new V(-0.15, -0.1, 1), 3, 0.9, 0.09, 0.22, true);
  // brazo derecho largo, apoyado en el suelo, con dos garras en hoz
  limb(['ArmR_Upper', 'ArmR_Fore', 'ArmR_Hand'], 'Chest', [[-1.1, 9.6, 0.6], [-2.8, 7.0, 3.0], [-2.5, 3.5, 4.5], [-2.7, 0.45, 5.5]], [0.48, 0.3, 0.22, 0.15], { bulge: [0.3, 0.2, 0.05], knobs: true });
  { const at = new V(-2.7, 0.45, 5.5); for (const [s, L] of [[1, 1.7], [-1, 1.3]]) add('ArmR_Hand', spike(at.clone().add(new V(s * 0.12, 0, 0)), new V(s * 0.25, 0.15, 1), new V(0, -1, 0), L, 0.11, 0.65), 'claw'); }
  // brazo izquierdo atrofiado, plegado contra el pecho
  limb(['ArmL_Upper', 'ArmL_Fore'], 'Chest', [[1.0, 9.2, 0.8], [1.6, 8.0, 2.2], [1.1, 7.6, 3.0]], [0.32, 0.2, 0.13], { bulge: [0.15, 0.1], knobs: true });
  talons('ArmL_Fore', new V(1.1, 7.6, 3.0), new V(-0.2, -0.6, 1), 3, 0.38, 0.045, 0.08, false);

  /* --- alas: huesos + membrana doble cara, rasgada --- */
  function membrane(apex, A, B, u0, u1, scal, bil, tat) {
    const rows = 6, cols = 12, pos = [], uv = [], idx = [];
    const nrm = new V().crossVectors(A.clone().sub(apex), B.clone().sub(apex)).normalize(); if (nrm.y > 0) nrm.negate();
    const span = A.distanceTo(B), edge = [];
    for (let c = 0; c <= cols; c++) { const u = c / cols; const q = A.clone().lerp(B, u); let s = scal * Math.sin(Math.PI * u); if (tat) s *= 1 + tat * (R() - 0.3) * 2.6; q.lerp(apex, Math.max(0, Math.min(0.85, s))); edge.push(q); }
    for (let r = 0; r <= rows; r++) for (let c = 0; c <= cols; c++) {
      const rr = r / rows, u = c / cols; const q = apex.clone().lerp(edge[c], rr).addScaledVector(nrm, bil * span * 0.08 * Math.sin(Math.PI * rr) * Math.sin(Math.PI * u));
      pos.push(q.x, q.y, q.z); uv.push(u0 + (u1 - u0) * u, rr);
    }
    for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) { if (tat && r >= rows - 3 && R() < tat * 0.3) continue; const a = r * (cols + 1) + c, b = a + cols + 1; idx.push(a, b, a + 1, b, b + 1, a + 1); }
    const g = new THREE.BufferGeometry(); g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3)); g.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2)); g.setIndex(idx); g.computeVertexNormals();
    return doubleSide(g);
  }
  function wing(armName, handName, w) {
    const Sh = v3(w.shoulder), E = v3(w.elbow), Wr = v3(w.wrist), tips = w.tips.map(v3), rear = v3(w.rear), ar = w.armR;
    part(armName, 'Chest', Sh); if (handName) part(handName, armName, Wr);
    const hand = handName || armName;
    add(armName, tube([Sh, E, Wr].map(p => [p.x, p.y, p.z]), [ar, ar * 0.72, ar * 0.55], { rs: 11, n: 30, bulge: null }), 'skin');
    add(armName, lump(E, Wr.clone().sub(Sh), new V(0, 1, 0), new V(ar * 1.2, ar * 1.0, ar * 0.9), 1), 'skin');
    tips.forEach((t, i) => { const mid = Wr.clone().lerp(t, 0.45).add(new V(0, 0.35, 0)); add(hand, tube([Wr, mid, t].map(p => [p.x, p.y, p.z]), [ar * 0.42, ar * 0.3, 0.025], { rs: 8, n: 26 }), 'skin');
      add(hand, lump(mid, t.clone().sub(Wr), new V(0, 1, 0), new V(ar * 0.45, ar * 0.32, ar * 0.32), 1), 'skin'); });
    add(hand, spike(Wr, new V(Math.sign(Wr.x) * 0.2, 0.7, 0.7), new V(0, -1, 0), w.thumb || 0.8, ar * 0.32, 0.45), 'claw');
    const chain = [...tips, rear], n = chain.length;
    for (let i = 0; i < n - 1; i++) add(i === n - 2 ? armName : hand, membrane(Wr, chain[i], chain[i + 1], i / n, (i + 1) / n, i === n - 2 ? (w.scallop || 0.16) * 1.4 : (w.scallop || 0.16), w.billow || 0.5, w.tatter || 0), 'mem');
    add(armName, membrane(Wr, rear, Sh, 0.9, 1, 0.05, 0.3, 0), 'mem');
    add(armName, membrane(E, Sh, Wr, 0, 0.1, 0.12, 0.3, 0), 'mem');
    for (const sp of w.spurs || []) add(armName, spike(Sh.clone().lerp(E, sp[0]), new V(...sp[1]), new V(0, 0, -1), sp[2], ar * 0.25, 0.3), 'bone');
  }
  wing('WingL_Arm', 'WingL_Hand', { shoulder: [0.6, 10, -0.3], elbow: [4, 13.5, -1.5], wrist: [8, 13, -3.5], tips: [[13.5, 12, -4.5], [13, 8.5, -7], [11, 5.5, -9], [7.5, 4.6, -9.8]], rear: [0.8, 7.2, -4], armR: 0.34, tatter: 0.35, scallop: 0.17, billow: 0.7, thumb: 1.0 });
  wing('WingR', null, { shoulder: [-0.6, 10, -0.3], elbow: [-2.2, 11.6, -1.4], wrist: [-3.6, 11.2, -2.2], tips: [[-5.6, 10.4, -3], [-4.6, 8.6, -3.6]], rear: [-0.8, 8.4, -1.6], armR: 0.24, scallop: 0.28, billow: 1.6, thumb: 0.6, spurs: [[0.5, [-0.4, 1, -0.3], 0.6], [0.8, [-0.6, 0.8, 0.2], 0.45]] });

  /* ---------- a espacio Roblox (girar 180° en Y: mira hacia -Z) ---------- */
  const toRbx = new THREE.Matrix4().makeRotationY(Math.PI);
  const out = [];
  for (const name of order) {
    const p = P[name]; const geos = [];
    for (const { geo, mat } of p.geos) {
      const g = geo.index ? geo : indexify(geo);
      if (!g.attributes.normal) g.computeVertexNormals();
      g.applyMatrix4(toRbx);
      remapUV(g, REG[mat]); g.userData.mat = mat; geos.push(g);
    }
    const merged = merge(geos);
    merged.computeBoundingBox();
    out.push({ name, parent: p.parent, pivot: p.pivot.clone().applyMatrix4(toRbx), geometry: merged, center: merged.boundingBox.getCenter(new V()), tris: merged.index.count / 3, mats: [...new Set(p.geos.map(g => g.mat))] });
  }
  return { parts: out, REG, PALETTE, atlas: opt.atlas === false ? null : paintAtlas(opt.atlasSize || 1024, 77) };

  /* ---------- utilidades de geometría ---------- */
  function indexify(g) { const n = g.attributes.position.count; const idx = []; for (let i = 0; i < n; i++) idx.push(i); g.setIndex(idx); return g; }
  function remapUV(g, r) {
    const uv = g.attributes.uv; const ins = 0.004;
    for (let i = 0; i < uv.count; i++) {
      const u = Math.min(Math.max(uv.getX(i), 0), 1), v = Math.min(Math.max(uv.getY(i), 0), 1);
      uv.setXY(i, r[0] + ins + u * (r[2] - r[0] - 2 * ins), r[1] + ins + v * (r[3] - r[1] - 2 * ins));
    }
  }
  function doubleSide(g) {
    const pos = g.attributes.position.array, nor = g.attributes.normal.array, uv = g.attributes.uv.array, idx = g.index.array, n = pos.length / 3;
    const P2 = new Float32Array(pos.length * 2), N2 = new Float32Array(pos.length * 2), U2 = new Float32Array(uv.length * 2), I2 = [];
    P2.set(pos); P2.set(pos, pos.length); N2.set(nor); for (let i = 0; i < nor.length; i++) N2[nor.length + i] = -nor[i]; U2.set(uv); U2.set(uv, uv.length);
    for (let i = 0; i < idx.length; i += 3) { I2.push(idx[i], idx[i + 1], idx[i + 2]); I2.push(idx[i] + n, idx[i + 2] + n, idx[i + 1] + n); }
    const o = new THREE.BufferGeometry(); o.setAttribute('position', new THREE.BufferAttribute(P2, 3)); o.setAttribute('normal', new THREE.BufferAttribute(N2, 3)); o.setAttribute('uv', new THREE.BufferAttribute(U2, 2)); o.setIndex(I2); return o;
  }
  function merge(gs) {
    let nv = 0, ni = 0; for (const g of gs) { nv += g.attributes.position.count; ni += g.index.count; }
    const pos = new Float32Array(nv * 3), nor = new Float32Array(nv * 3), uv = new Float32Array(nv * 2), idx = new Uint32Array(ni);
    let ov = 0, oi = 0;
    for (const g of gs) {
      pos.set(g.attributes.position.array, ov * 3); nor.set(g.attributes.normal.array, ov * 3); uv.set(g.attributes.uv.array, ov * 2);
      const gi = g.index.array; for (let i = 0; i < gi.length; i++) idx[oi + i] = gi[i] + ov;
      ov += g.attributes.position.count; oi += gi.length;
    }
    const o = new THREE.BufferGeometry(); o.setAttribute('position', new THREE.BufferAttribute(pos, 3)); o.setAttribute('normal', new THREE.BufferAttribute(nor, 3)); o.setAttribute('uv', new THREE.BufferAttribute(uv, 2)); o.setIndex(new THREE.BufferAttribute(idx, 1)); return o;
  }
}

root.AberrantModel = { build, REG, PALETTE, paintAtlas };
})(typeof window !== 'undefined' ? window : globalThis);
