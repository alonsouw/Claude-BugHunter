/*
 * Animaciones del ciervo y de su forma maldita, como datos (mismo formato que los dragones).
 *   k: [t, rx, ry, rz] grados · p: [t, x, y, z] studs · o: [eje, amplitud, ciclos, fase]
 * Ejes del modelo (Y arriba, mira a -Z): +rx adelanta lo que cuelga (patas) y levanta lo que mira al frente
 * (cuello, cabeza); la mandíbula se abre con -rx.
 *
 * Las animaciones de la criatura dependen del esqueleto (dirección y largo de cada hueso), por eso se generan
 * con makeDeerAnims(rig) a partir de model/rig.json: así el cuello, las patas y los tentáculos se estiran
 * exactamente a lo largo de sus huesos, igual en Roblox (tools/build_roblox.js) y en el visor web.
 *
 * Ciervo:   Idle, Graze, Walk, Run, Alert, Death
 * Criatura: Transform (4,6 s → CreatureIdle), CreatureIdle, CreatureWalk, CreatureRun, Shriek
 */
(function (root) {
// combina articulaciones: las claves k y p de la última fuente reemplazan a las anteriores; las oscilaciones o se suman
const merge = (...objs) => { const out = {}; for (const o of objs) for (const k in o) { out[k] = out[k] || {}; for (const c in o[k]) out[k][c] = c === 'o' ? (out[k][c] || []).concat(o[k][c]) : o[k][c]; } return out; };
const LEGS = ['LegFL', 'LegFR', 'LegBL', 'LegBR'];

function makeDeerAnims(rig) {
  const B = {}; for (const b of rig.bones) B[b.name] = b;
  const vec = n => B[n].tail.map((x, i) => x - B[n].head[i]);
  const len = v => Math.hypot(v[0], v[1], v[2]);
  const dir = n => { const v = vec(n), l = len(v) || 1; return v.map(x => x / l); };
  const sc = (v, s) => v.map(x => +(x * s).toFixed(4));
  const ramp = (v, prof) => prof.map(([t, f]) => [t, ...sc(v, f)]);
  const TENT = rig.tentacles || [];

  // --- pose base de la criatura: cuello y patas estirados a lo largo de sus huesos ---
  const NECK = 0.62, LEG = 0.72;
  const neckP = { Neck2: dir('Neck1'), Neck3: dir('Neck2'), Head: dir('Neck3') };
  const legP = {}; let rise = 0;
  for (const L of LEGS) { legP[L + '_Cannon'] = dir(L + '_Lower'); legP[L + '_Hoof'] = dir(L + '_Cannon'); }
  rise = -LEG * (dir('LegBL_Lower')[1] + dir('LegBL_Cannon')[1]);       // lo que suben las caderas para que las pezuñas toquen el suelo
  const stretch = (f, t) => {   // articulaciones con la fracción f del estiramiento, en el instante t
    const j = { Hips: { p: [[t, 0, +(rise * f).toFixed(4), 0]] } };
    for (const n in neckP) j[n] = { p: [[t, ...sc(neckP[n], NECK * f)]] };
    for (const n in legP) j[n] = { p: [[t, ...sc(legP[n], LEG * f)]] };
    return j;
  };
  const stretchKeys = prof => {   // prof: [[t, f]] → claves p de todas las articulaciones estiradas
    const j = { Hips: { p: prof.map(([t, f]) => [t, 0, +(rise * f).toFixed(4), 0]) } };
    for (const n in neckP) j[n] = { p: ramp(neckP[n], prof.map(([t, f]) => [t, NECK * f])) };
    for (const n in legP) j[n] = { p: ramp(legP[n], prof.map(([t, f]) => [t, LEG * f])) };
    return j;
  };
  // tentáculos: recogidos dentro del cráneo (cada hueso vuelve sobre el anterior) → extendidos
  const tentKeys = prof => {
    const j = {};
    for (const names of TENT) for (let k = 1; k < names.length; k++) j[names[k]] = { p: ramp(vec(names[k - 1]), prof.map(([t, f]) => [t, -(1 - f)])) };
    return j;
  };
  const writhe = (amp, cyc) => {
    const j = {};
    TENT.forEach((names, n) => names.slice(1).forEach((b, k) => {
      j[b] = { o: [['x', amp * (0.6 + 0.3 * k), cyc, (n * 0.37 + k * 0.17) % 1], ['z', amp * (0.5 + 0.3 * k), cyc, (n * 0.61 + k * 0.23 + 0.25) % 1]] };
    }));
    return j;
  };
  const BASE = merge(stretch(1, 0), {
    Jaw: { k: [[0, -22, 0, 0]] }, Head: { k: [[0, 6, 0, 0]] },
    EarL: { k: [[0, 0, 0, -35]] }, EarR: { k: [[0, 0, 0, 35]] }, Tail: { k: [[0, 30, 0, 0]] },
    LegBL_Lower: { k: [[0, 10, 0, 0]] }, LegBR_Lower: { k: [[0, 10, 0, 0]] }
  });
  const legsOsc = (ampU, ampL, ampC, ph) => {
    const j = {};
    for (const L of LEGS) { const f = ph[L]; j[L + '_Upper'] = { o: [['x', ampU, 1, f]] }; j[L + '_Lower'] = { o: [['x', ampL, 1, f + 0.15]] }; j[L + '_Cannon'] = { o: [['x', ampC, 1, f + 0.3]] }; }
    return j;
  };
  const ears = (amp, cyc) => ({ EarL: { o: [['z', amp, cyc, 0], ['y', amp * 0.6, cyc, 0.3]] }, EarR: { o: [['z', -amp, cyc, 0.5], ['y', -amp * 0.6, cyc, 0.8]] } });

  const A = {
    // ---------------- ciervo ----------------
    Idle: { dur: 7, loop: true, joints: merge(ears(4, 3), {
      Chest: { o: [['x', 0.8, 2, 0]] }, Hips: { o: [['py', 0.015, 2, 0]] },
      Neck1: { o: [['y', 4, 1, 0.1]] }, Neck3: { o: [['y', 5, 1, 0.3], ['x', 3, 1, 0.6]] }, Head: { o: [['z', 3, 1, 0.2]] },
      EarL: { k: [[0, 0, 0, 0], [3.0, 0, 0, 0], [3.1, 0, 25, -10], [3.25, 0, 0, 0]] },
      Tail: { k: [[0, 0, 0, 0], [5.0, 0, 0, 0], [5.1, 25, 0, 0], [5.25, 0, 0, 0], [5.35, 20, 0, 0], [5.5, 0, 0, 0]] }
    }) },
    Graze: { dur: 6, loop: true, joints: merge(ears(5, 2), {
      Neck1: { k: [[0, -76, 0, 0]], o: [['y', 6, 1, 0]] }, Neck2: { k: [[0, -25, 0, 0]] }, Neck3: { k: [[0, -12, 0, 0]] }, Head: { k: [[0, 50, 0, 0]], o: [['x', 3, 6, 0]] },
      Jaw: { o: [['x', 4, 12, 0]] }, Chest: { k: [[0, -4, 0, 0]], p: [[0, 0, -0.2, 0]] },
      LegFL_Upper: { k: [[0, -6, 0, 0]] }, LegFR_Upper: { k: [[0, 8, 0, 0]] }, LegFR_Lower: { k: [[0, -10, 0, 0]] },
      Tail: { o: [['x', 10, 4, 0]] }
    }) },
    Walk: { dur: 1.7, loop: true, joints: merge(ears(3, 2), legsOsc(18, 14, 18, { LegFL: 0, LegBR: 0.05, LegFR: 0.5, LegBL: 0.55 }), {
      Hips: { o: [['py', 0.05, 2, 0.1], ['z', 2, 1, 0]] }, Chest: { o: [['z', -2, 1, 0.1]] },
      Neck1: { o: [['x', 3, 2, 0.2]] }, Head: { o: [['x', -3, 2, 0.2]] }, Tail: { o: [['y', 6, 1, 0]] }
    }) },
    // galope a saltos: las patas de cada par juntas, el lomo se flexiona
    Run: { dur: 0.62, loop: true, joints: merge(legsOsc(30, 20, 24, { LegFL: 0, LegFR: 0.06, LegBL: 0.5, LegBR: 0.56 }), {
      Hips: { p: [[0, 0, 0.1, 0]], o: [['py', 0.35, 1, 0.25], ['x', 8, 1, 0]] }, Spine: { o: [['x', 6, 1, 0.5]] }, Chest: { o: [['x', 5, 1, 0.5]] },
      Neck1: { k: [[0, -28, 0, 0]], o: [['x', 6, 1, 0.3]] }, Head: { k: [[0, 22, 0, 0]] },
      EarL: { k: [[0, 0, 0, -30]] }, EarR: { k: [[0, 0, 0, 30]] }, Tail: { k: [[0, 70, 0, 0]] }   // cola blanca levantada (bandera)
    }) },
    Alert: { dur: 4, loop: true, joints: {
      Neck1: { k: [[0, 12, 0, 0]] }, Neck2: { k: [[0, 6, 0, 0]] }, Head: { k: [[0, 8, 0, 0]], o: [['y', 6, 1, 0]] },
      EarL: { k: [[0, -15, 0, 15]], o: [['y', 8, 2, 0]] }, EarR: { k: [[0, -15, 0, -15]], o: [['y', -8, 2, 0.4]] },
      Tail: { k: [[0, 35, 0, 0]], o: [['x', 15, 4, 0]] }, Chest: { o: [['x', 1.5, 3, 0]] }
    } },
    Death: { dur: 2.2, loop: false, joints: {
      Hips: { k: [[0, 0, 0, 0], [0.6, 0, 0, -15], [1.4, 0, 0, -80], [2.2, 0, 0, -88]], p: [[0, 0, 0, 0], [1.4, 0, -1.6, 0], [2.2, 0, -2.0, 0]] },
      Neck1: { k: [[0, 0, 0, 0], [1.6, -30, 0, 0], [2.2, -40, 0, -10]] }, Head: { k: [[0, 0, 0, 0], [2.2, -15, 0, -20]] },
      LegFL_Upper: { k: [[0, 0, 0, 0], [1.6, 25, 0, 10]] }, LegBL_Upper: { k: [[0, 0, 0, 0], [1.6, 20, 0, 10]] },
      LegFR_Lower: { k: [[0, 0, 0, 0], [1.6, -40, 0, 0]] }, LegBR_Lower: { k: [[0, 0, 0, 0], [1.6, 30, 0, 0]] },
      EarL: { k: [[0, 0, 0, 0], [2.2, 0, 0, -40]] }, EarR: { k: [[0, 0, 0, 0], [2.2, 0, 0, 40]] }
    } },

    // ---------------- transformación ----------------
    // 0-0,5 se queda rígido · 0,5-1,3 convulsiones · 1,2 aparece la piel de la criatura (cliente)
    // 1,3-2,7 el cuello y las patas se estiran a tirones (crujidos) · 1,6-3,2 brotan los tentáculos
    // 2,6-3,1 la cabeza se parte: la mandíbula cae y la cabeza mira al cielo · 4,6 pose de criatura
    Transform: { dur: 4.6, loop: false, next: 'CreatureIdle', joints: merge(
      stretchKeys([[0, 0], [1.3, 0], [1.5, 0.22], [1.62, 0.22], [1.8, 0.48], [1.95, 0.48], [2.15, 0.75], [2.3, 0.75], [2.7, 1.04], [3.0, 1.0]]),
      tentKeys([[0, 0], [1.6, 0], [2.2, 0.35], [2.7, 0.8], [3.2, 1.0]]),
      writhe(14, 3),
      {
        EarL: { k: [[0, 0, 0, 0], [0.4, -20, 0, -30], [2.0, -20, 0, -40], [4.6, 0, 0, -35]] }, EarR: { k: [[0, 0, 0, 0], [0.4, -20, 0, 30], [2.0, -20, 0, 40], [4.6, 0, 0, 35]] },
        Neck1: { k: [[0, 0, 0, 0], [0.4, 10, 0, 0], [0.55, 4, 8, 0], [0.7, 12, -10, 0], [0.85, 2, 6, 0], [1.0, 14, -4, 0], [1.3, 8, 0, 0], [2.8, 12, 0, 0], [4.6, 0, 0, 0]] },
        Neck2: { k: [[0, 0, 0, 0], [0.6, 0, 10, 5], [0.75, 0, -12, -8], [0.9, 0, 14, 6], [1.1, 0, -8, -4], [1.3, 0, 0, 0], [4.6, 0, 0, 0]] },
        Head: { k: [[0, 0, 0, 0], [0.5, 0, 0, 0], [0.6, 0, 0, 28], [0.72, 0, 0, -22], [0.85, 0, 0, 34], [1.0, 0, 0, -26], [1.15, 0, 0, 18], [1.3, 0, 0, 0],
                    [2.6, 10, 0, 0], [3.0, 42, 0, 6], [3.6, 30, 0, -10], [4.6, 6, 0, 0]] },
        Jaw: { k: [[0, 0, 0, 0], [2.6, 0, 0, 0], [3.0, -135, 0, 0], [3.5, -120, 0, 0], [4.6, -22, 0, 0]], o: [['x', 3, 30, 0]] },
        Spine: { k: [[0, 0, 0, 0], [0.55, -6, 0, 3], [0.7, 5, 0, -4], [0.85, -7, 0, 2], [1.05, 4, 0, -2], [1.3, 0, 0, 0]] },
        Chest: { k: [[0, 0, 0, 0], [0.6, 4, 0, -4], [0.8, -5, 0, 5], [1.0, 3, 0, -2], [1.3, 0, 0, 0]] },
        Tail: { k: [[0, 0, 0, 0], [0.4, 60, 0, 0], [1.3, 60, 0, 0], [4.6, 30, 0, 0]] },
        LegBL_Lower: { k: [[0, 0, 0, 0], [3.0, 10, 0, 0]] }, LegBR_Lower: { k: [[0, 0, 0, 0], [3.0, 10, 0, 0]] }
      }) },

    // ---------------- criatura ----------------
    CreatureIdle: { dur: 7, loop: true, joints: merge(BASE, writhe(10, 1), {
      Neck1: { o: [['y', 8, 1, 0], ['x', 3, 1, 0.3]] }, Neck2: { o: [['y', 6, 1, 0.15], ['z', 4, 1, 0.5]] }, Neck3: { o: [['x', 4, 2, 0.2]] },
      Head: { o: [['z', 14, 1, 0.3], ['y', 6, 1, 0.7]] }, Jaw: { o: [['x', 6, 1, 0], ['x', 1.5, 25, 0]] },
      Chest: { o: [['x', 2, 2, 0]] }
    }) },
    CreatureWalk: { dur: 2.4, loop: true, joints: merge(BASE, writhe(14, 2), legsOsc(16, 18, 16, { LegFL: 0, LegBR: 0.12, LegFR: 0.5, LegBL: 0.62 }), {
      Hips: { o: [['py', 0.12, 2, 0], ['z', 3, 1, 0.1]] }, Chest: { o: [['z', -3, 1, 0.2]] },
      Neck1: { o: [['y', 6, 1, 0.3]] }, Neck2: { o: [['z', 5, 1, 0.5]] }, Head: { o: [['z', 10, 1, 0.1], ['x', 3, 9, 0]] }
    }) },
    CreatureRun: { dur: 0.9, loop: true, joints: merge(BASE, writhe(22, 2), legsOsc(36, 30, 30, { LegFL: 0, LegFR: 0.1, LegBL: 0.5, LegBR: 0.6 }), {
      Hips: { o: [['py', 0.35, 2, 0], ['x', 6, 1, 0]] }, Spine: { o: [['x', 5, 1, 0.5]] },
      Neck1: { k: [[0, -35, 0, 0]] }, Neck2: { k: [[0, -10, 0, 0]] }, Head: { k: [[0, 30, 0, 0]], o: [['z', 8, 2, 0]] },
      Jaw: { k: [[0, -70, 0, 0]], o: [['x', 10, 2, 0]] }
    }) },
    Shriek: { dur: 2.6, loop: false, next: 'CreatureIdle', joints: merge(BASE, writhe(35, 6), {
      Neck1: { k: [[0, 0, 0, 0], [0.4, 18, 0, 0], [2.1, 18, 0, 0], [2.6, 0, 0, 0]], o: [['y', 2, 30, 0]] },
      Head: { k: [[0, 0, 0, 0], [0.4, 40, 0, 0], [2.1, 38, 0, 0], [2.6, 0, 0, 0]], o: [['z', 3, 40, 0]] },
      Jaw: { k: [[0, 0, 0, 0], [0.35, -140, 0, 0], [2.1, -135, 0, 0], [2.6, 0, 0, 0]], o: [['x', 4, 36, 0]] }
    }) }
  };
  return A;
}

function smooth(x) { return x * x * (3 - 2 * x); }
function sampleKeys(keys, t, dur, loop) {
  if (!keys || !keys.length) return null;
  if (keys.length === 1) return keys[0].slice(1);
  if (t <= keys[0][0]) return keys[0].slice(1);
  for (let i = 0; i < keys.length - 1; i++) { const a = keys[i], b = keys[i + 1]; if (t <= b[0]) { const f = smooth((t - a[0]) / Math.max(b[0] - a[0], 1e-6)); return a.slice(1).map((v, j) => v + (b[j + 1] - v) * f); } }
  const last = keys[keys.length - 1];
  if (loop) { const f = smooth((t - last[0]) / Math.max(dur - last[0], 1e-6)); return last.slice(1).map((v, j) => v + (keys[0][j + 1] - v) * f); }
  return last.slice(1);
}
function evalJoint(j, t, dur, loop) {
  const r = sampleKeys(j.k, t, dur, loop) || [0, 0, 0], p = sampleKeys(j.p, t, dur, loop) || [0, 0, 0];
  for (const [ax, amp, cyc, ph] of j.o || []) {
    const v = amp * Math.sin(2 * Math.PI * (cyc * t / dur + ph));
    if (ax === 'x') r[0] += v; else if (ax === 'y') r[1] += v; else if (ax === 'z') r[2] += v; else if (ax === 'px') p[0] += v; else if (ax === 'py') p[1] += v; else if (ax === 'pz') p[2] += v;
  }
  return { r, p };
}
root.makeDeerAnims = makeDeerAnims;
root.AnimEval = { evalJoint, sampleKeys };
})(typeof window !== 'undefined' ? window : globalThis);
