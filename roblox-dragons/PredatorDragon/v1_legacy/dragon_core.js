/*
 * Núcleo compartido del Bestiario Umbral: herramientas de geometría y de atlas
 * para construir dragones segmentados (una MeshPart por hueso) listos para Roblox.
 *
 * DragonCore.kit(THREE, seed) devuelve un "taller" con:
 *   frames/tube/tubeFrom/surf/outward/cone/spike/lump/sphere/fin/membrane/limb/talons/wing
 *   part(name, parent, pivot) y add(name, geo, mat) para declarar piezas
 *   finalize(REG) → piezas en espacio Roblox (Y arriba, mirando a -Z) con UV del atlas.
 * El modelo se escribe mirando hacia +Z con su lado izquierdo en +X; finalize lo gira 180°.
 */
(function (root) {
'use strict';

function rng(seed) { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
function samp(arr, u) { if (typeof arr === 'number') return arr; const f = Math.min(Math.max(u, 0), 1) * (arr.length - 1); const i = Math.min(Math.floor(f), arr.length - 2); const k = f - i; return arr[i] * (1 - k) + arr[i + 1] * k; }

/* ---------- pintura de atlas ---------- */
function painter(size, seed) {
  const R = rng(seed);
  const mk = () => { const c = document.createElement('canvas'); c.width = c.height = size; return c; };
  const col = mk(), hgt = mk(), rough = mk();
  const C = col.getContext('2d'), H = hgt.getContext('2d'), G = rough.getContext('2d');
  H.fillStyle = '#808080'; H.fillRect(0, 0, size, size);
  const px = r => [r[0] * size, r[1] * size, (r[2] - r[0]) * size, (r[3] - r[1]) * size];
  const clip = (ctx, r, fn) => { const [x, y, w, h] = px(r); ctx.save(); ctx.beginPath(); ctx.rect(x, y, w, h); ctx.clip(); fn(x, y, w, h); ctx.restore(); };
  const both = (r, fn) => clip(C, r, (x, y, w, h) => clip(H, r, () => fn(x, y, w, h)));
  const blob = (ctx, x, y, rad, color) => { const g = ctx.createRadialGradient(x, y, 0, x, y, rad); g.addColorStop(0, color); g.addColorStop(1, 'rgba(0,0,0,0)'); ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, rad, 0, Math.PI * 2); ctx.fill(); };
  function veins(ctxs, styles, x, y, w, h, n, w0, down) {
    function br(px0, py0, a, len, wd, depth) {
      if (len < 3 || wd < 0.35 || depth > 9) return;
      const x2 = px0 + Math.cos(a) * len, y2 = py0 + Math.sin(a) * len;
      const cx = (px0 + x2) / 2 + (R() - 0.5) * len * 0.5, cy = (py0 + y2) / 2 + (R() - 0.5) * len * 0.5;
      ctxs.forEach((ctx, k) => { ctx.strokeStyle = styles[k]; ctx.lineWidth = wd; ctx.lineCap = 'round'; ctx.beginPath(); ctx.moveTo(px0, py0); ctx.quadraticCurveTo(cx, cy, x2, y2); ctx.stroke(); });
      br(x2, y2, a + (R() - 0.5) * 0.7, len * 0.86, wd * 0.82, depth + 1);
      if (R() < 0.5) br(x2, y2, a + (R() < 0.5 ? -1 : 1) * (0.5 + R() * 0.6), len * 0.62, wd * 0.6, depth + 1);
    }
    for (let i = 0; i < n; i++) { const sx = x + R() * w, sy = down ? y : y + R() * h; br(sx, sy, down ? Math.PI / 2 + (R() - 0.5) * 0.5 : R() * Math.PI * 2, (down ? h / 9 : w / 14) * (0.7 + R() * 0.6), w0 * (0.7 + R() * 0.6), 0); }
  }
  function roughFill(REG, values) { for (const k in values) { const [x, y, w, h] = px(REG[k]); const v = values[k]; G.fillStyle = `rgb(${v},${v},${v})`; G.fillRect(x, y, w, h); } }
  function finish(strength) {
    const nrm = mk(), N = nrm.getContext('2d');
    const hd = H.getImageData(0, 0, size, size).data, out = N.createImageData(size, size), o = out.data, s = (strength || 2.2) / 255;
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
  return { R, C, H, G, size, px, clip, both, blob, veins, roughFill, finish };
}

/* ---------- taller de geometría ---------- */
function kit(THREE, seed) {
  const V = THREE.Vector3, R = rng(seed || 1);
  const v3 = p => (p instanceof V ? p.clone() : new V(p[0], p[1], p[2]));
  const arr = p => [p.x, p.y, p.z];

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
      const f = F[i], lf = (i - i0) / Math.max(cnt, 1), r = f.r * (o.bulge ? 1 + o.bulge(lf, f.t) : 1);
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
    return tube([base, p1, p2].map(arr), [r, r * 0.6, r * 0.05], { rs: 8, n: 10 });
  }
  function lump(pos, x, y, scale, detail) {
    const g = new THREE.DodecahedronGeometry(1, detail === undefined ? 1 : detail); const z = new V().crossVectors(x, y).normalize(), yy = new V().crossVectors(z, x).normalize();
    g.applyMatrix4(new THREE.Matrix4().makeBasis(x.clone().normalize(), yy, z).scale(scale).setPosition(pos)); return g;
  }
  function sphere(c, r, w, h) { const g = new THREE.SphereGeometry(r, w || 14, h || 10); g.translate(c.x, c.y, c.z); return g; }
  /* aleta extruida a partir de un polígono 2D (u a lo largo de x, v a lo largo de y) */
  function fin(poly, origin, xAxis, yAxis, thick) {
    const shape = new THREE.Shape(poly.map(p => new THREE.Vector2(p[0], p[1])));
    const g = new THREE.ExtrudeGeometry(shape, { depth: thick, bevelEnabled: true, bevelThickness: thick * 0.3, bevelSize: thick * 0.4, bevelSegments: 1, curveSegments: 3 });
    g.translate(0, 0, -thick / 2);
    g.computeBoundingBox(); const bb = g.boundingBox, uv = g.attributes.uv; const pa = g.attributes.position;
    for (let i = 0; i < uv.count; i++) uv.setXY(i, (pa.getX(i) - bb.min.x) / (bb.max.x - bb.min.x || 1), (pa.getY(i) - bb.min.y) / (bb.max.y - bb.min.y || 1));
    const x = xAxis.clone().normalize(), z = new V().crossVectors(x, yAxis).normalize(), y = new V().crossVectors(z, x).normalize();
    g.applyMatrix4(new THREE.Matrix4().makeBasis(x, y, z).setPosition(origin));
    return g.index ? g : indexify(g);
  }

  /* piezas */
  const P = {}, order = [];
  const part = (name, parent, pivot) => { P[name] = { name, parent, pivot: v3(pivot), geos: [] }; order.push(name); };
  const add = (name, geo, mat) => { if (!P[name]) throw new Error('pieza desconocida ' + name); P[name].geos.push({ geo, mat }); return geo; };

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
  /* extremidad segmentada: una pieza por tramo entre puntos de control */
  function limb(names, parent, pts, radii, o) {
    o = o || {};
    const F = frames(pts, radii, 30 * (pts.length - 1)); const n = pts.length - 1;
    names.forEach((nm, i) => {
      part(nm, i === 0 ? parent : names[i - 1], v3(pts[i]));
      const i0 = Math.round(F.n * i / n), i1 = Math.round(F.n * (i + 1) / n);
      add(nm, tubeFrom(F, i0 - (i ? 3 : 0), i1 + 3, { rs: o.rs || 14, sx: o.sx || 1, bulge: o.bulge ? (lf) => o.bulge[i] * Math.sin(Math.PI * lf) : null }), o.mat || 'skin');
      if (i > 0) { const jr = samp(radii, i / n), f = F[i0]; add(nm, lump(v3(pts[i]), f.T.clone(), f.N.clone(), new V(jr * 1.12, jr * 1.08, jr * 1.05), 1), o.mat || 'skin'); }
      for (const th of o.tendons || []) {
        const tp = []; for (let q = 0; q <= 8; q++) { const fq = F[Math.round(i0 + (i1 - i0) * (0.08 + 0.84 * q / 8))]; const pp = surf(fq, th, 0.88 + 0.2 * Math.sin(Math.PI * q / 8), o.sx || 1); tp.push(arr(pp)); }
        add(nm, tube(tp, [0.03, samp(radii, i / n) * 0.18, 0.03], { rs: 6, n: 16 }), o.mat || 'skin');
      }
    });
    return F;
  }
  function talons(nm, at, fwd, n, len, r, spread, back, mat) {
    const f = fwd.clone().normalize(), side = new V().crossVectors(f, new V(0, 1, 0)).normalize();
    for (let k = 0; k < n; k++) {
      const off = k - (n - 1) / 2, dd = f.clone().addScaledVector(side, off * 0.42).normalize(), base = at.clone().addScaledVector(side, off * spread);
      add(nm, tube([base, base.clone().addScaledVector(dd, len * 0.45).add(new V(0, 0.08, 0))].map(arr), [r * 1.5, r * 1.15], { rs: 9, n: 5 }), mat || 'skin');
      add(nm, spike(base.clone().addScaledVector(dd, len * 0.4), dd, new V(0, -1, 0), len, r, 0.6), 'claw');
    }
    if (back) add(nm, spike(at.clone().add(new V(0, 0.15, 0)), f.clone().negate().add(new V(0, -0.4, 0)), new V(0, -1, 0), len * 0.6, r * 0.9, 0.4), 'claw');
  }
  function wing(armName, handName, parent, w) {
    const Sh = v3(w.shoulder), E = v3(w.elbow), Wr = v3(w.wrist), tips = w.tips.map(v3), rear = v3(w.rear), ar = w.armR;
    part(armName, parent, Sh); if (handName) part(handName, armName, Wr);
    const hand = handName || armName;
    add(armName, tube([Sh, E, Wr].map(arr), [ar, ar * 0.72, ar * 0.55], { rs: 12, n: 30 }), 'skin');
    add(armName, lump(E, Wr.clone().sub(Sh), new V(0, 1, 0), new V(ar * 1.2, ar, ar * 0.9), 1), 'skin');
    tips.forEach(t => {
      const mid = Wr.clone().lerp(t, 0.45).add(new V(0, 0.35, 0));
      add(hand, tube([Wr, mid, t].map(arr), [ar * 0.42, ar * 0.3, 0.025], { rs: 8, n: 26 }), 'skin');
      add(hand, lump(mid, t.clone().sub(Wr), new V(0, 1, 0), new V(ar * 0.45, ar * 0.32, ar * 0.32), 1), 'skin');
    });
    add(hand, spike(Wr, new V(Math.sign(Wr.x) * 0.2, 0.7, 0.7), new V(0, -1, 0), w.thumb || 0.8, ar * 0.32, 0.45), 'claw');
    const chain = [...tips, rear], n = chain.length, sc = w.scallop || 0.16;
    for (let i = 0; i < n - 1; i++) add(i === n - 2 ? armName : hand, membrane(Wr, chain[i], chain[i + 1], i / n, (i + 1) / n, i === n - 2 ? sc * 1.4 : sc, w.billow || 0.5, w.tatter || 0), 'mem');
    add(armName, membrane(Wr, rear, Sh, 0.9, 1, 0.05, 0.3, 0), 'mem');
    add(armName, membrane(E, Sh, Wr, 0, 0.1, 0.12, 0.3, 0), 'mem');
    for (const sp of w.spurs || []) add(sp[3] === 'hand' ? hand : armName, spike(sp[0] === 'wrist' ? Wr.clone() : Sh.clone().lerp(E, sp[0]), v3(sp[1]), new V(0, 0, -1), sp[2], ar * 0.3, 0.3), 'bone');
  }
  const mirrorX = p => [-p[0], p[1], p[2]];

  /* ---------- salida en espacio Roblox ---------- */
  function finalize(REG) {
    const toRbx = new THREE.Matrix4().makeRotationY(Math.PI), out = [];
    for (const name of order) {
      const p = P[name], geos = [];
      for (const { geo, mat } of p.geos) {
        const g = geo.index ? geo : indexify(geo);
        if (!g.attributes.normal) g.computeVertexNormals();
        g.applyMatrix4(toRbx); remapUV(g, REG[mat]); geos.push(g);
      }
      const merged = merge(geos); merged.computeBoundingBox();
      out.push({ name, parent: p.parent, pivot: p.pivot.clone().applyMatrix4(toRbx), geometry: merged, center: merged.boundingBox.getCenter(new V()), tris: merged.index.count / 3, mats: [...new Set(p.geos.map(g => g.mat))] });
    }
    return out;
  }
  function indexify(g) { const n = g.attributes.position.count, idx = []; for (let i = 0; i < n; i++) idx.push(i); g.setIndex(idx); return g; }
  function remapUV(g, r) {
    const uv = g.attributes.uv, ins = 0.004;
    for (let i = 0; i < uv.count; i++) { const u = Math.min(Math.max(uv.getX(i), 0), 1), v = Math.min(Math.max(uv.getY(i), 0), 1); uv.setXY(i, r[0] + ins + u * (r[2] - r[0] - 2 * ins), r[1] + ins + v * (r[3] - r[1] - 2 * ins)); }
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

  return { THREE, V, R, v3, arr, frames, tubeFrom, tube, surf, outward, cone, spike, lump, sphere, fin, membrane, limb, talons, wing, mirrorX, part, add, P, order, finalize };
}

root.DragonCore = { rng, samp, kit, painter };
})(typeof window !== 'undefined' ? window : globalThis);
