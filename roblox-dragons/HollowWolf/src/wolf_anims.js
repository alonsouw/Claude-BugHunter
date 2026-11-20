/*
 * Animaciones del lobo hueco, como datos (mismo formato que los dragones y el ciervo).
 *   k: [t, rx, ry, rz] grados · p: [t, x, y, z] studs · o: [eje, amplitud, ciclos, fase]
 * Ejes del modelo (Y arriba, mira a -Z): +rx adelanta lo que cuelga (patas), levanta lo que mira al frente
 * (cuello, cabeza) y echa hacia atrás lo que apunta arriba (orejas); -rx levanta la cola y abre la mandíbula.
 * Huesos: Hips, Spine, Chest, Neck1, Neck2, Head, Jaw, EarL, EarR, Tail1-4, Leg{F,B}{L,R}_{Upper,Lower,Cannon,Paw}
 */
(function (root) {
const merge = (...objs) => { const out = {}; for (const o of objs) for (const k in o) { out[k] = out[k] || {}; for (const c in o[k]) out[k][c] = c === 'o' ? (out[k][c] || []).concat(o[k][c]) : o[k][c]; } return out; };
const LEGS = ['LegFL', 'LegFR', 'LegBL', 'LegBR'];
const legs = (u, l, c, p, ph) => { const j = {}; for (const L of LEGS) { const f = ph[L]; j[L + '_Upper'] = { o: [['x', u, 1, f]] }; j[L + '_Lower'] = { o: [['x', -l * (L[3] === 'F' ? -1 : 1), 1, f + 0.15]] }; j[L + '_Cannon'] = { o: [['x', c, 1, f + 0.3]] }; j[L + '_Paw'] = { o: [['x', p, 1, f + 0.4]] }; } return j; };
const tail = (axis, amp, cyc, ph0, base) => { const o = {}; for (let i = 1; i <= 4; i++) o['Tail' + i] = { k: [[0, (base || 0) / 4, 0, 0]], o: [[axis, amp * (0.4 + 0.2 * i), cyc, ph0 + 0.08 * i]] }; return o; };
const ears = (amp, cyc) => ({ EarL: { o: [['x', amp, cyc, 0], ['z', amp * 0.5, cyc, 0.3]] }, EarR: { o: [['x', amp, cyc, 0.5], ['z', -amp * 0.5, cyc, 0.8]] } });

const WOLF_ANIMS = {
  Idle: { dur: 5, loop: true, joints: merge(tail('y', 4, 1, 0, 6), ears(4, 3), {
    Chest: { o: [['x', 1.5, 2, 0]] }, Spine: { o: [['x', 1, 2, 0.1]] }, Hips: { o: [['py', 0.02, 2, 0]] },
    Neck1: { o: [['y', 6, 1, 0]] }, Head: { o: [['y', 5, 1, 0.3], ['x', 3, 1, 0.6]] }, Jaw: { o: [['x', -2, 2, 0]] },
    EarL: { k: [[0, 0, 0, 0], [2.2, 0, 0, 0], [2.3, 25, 0, -10], [2.45, 0, 0, 0]] }
  }) },
  Sniff: { dur: 3, loop: true, joints: merge(tail('y', 8, 2, 0, 0), {
    Neck1: { k: [[0, -38, 0, 0]], o: [['y', 10, 1, 0]] }, Neck2: { k: [[0, -15, 0, 0]] }, Head: { k: [[0, -20, 0, 0]], o: [['x', 4, 9, 0]] },
    Chest: { k: [[0, -4, 0, 0]], p: [[0, 0, -0.12, 0]] }, EarL: { k: [[0, -10, 0, 0]] }, EarR: { k: [[0, -10, 0, 0]] }
  }) },
  Walk: { dur: 1.3, loop: true, joints: merge(tail('y', 8, 1, 0.1, 10), ears(3, 2), legs(20, 18, 14, 16, { LegFL: 0, LegBR: 0.05, LegFR: 0.5, LegBL: 0.55 }), {
    Hips: { o: [['py', 0.04, 2, 0.1], ['z', 2, 1, 0]] }, Chest: { o: [['z', -2, 1, 0.1]] }, Neck1: { k: [[0, -8, 0, 0]], o: [['x', 3, 2, 0.2]] }, Head: { k: [[0, 4, 0, 0]] }
  }) },
  // trote de caza: diagonal, la cabeza baja y fija en la presa
  Trot: { dur: 0.75, loop: true, joints: merge(tail('y', 6, 1, 0.1, 4), legs(26, 22, 18, 20, { LegFL: 0, LegBR: 0.02, LegFR: 0.5, LegBL: 0.52 }), {
    Hips: { o: [['py', 0.08, 2, 0.1]] }, Neck1: { k: [[0, -18, 0, 0]] }, Head: { k: [[0, 12, 0, 0]] },
    EarL: { k: [[0, -8, 0, 0]] }, EarR: { k: [[0, -8, 0, 0]] }
  }) },
  // galope: pares de patas juntos, el lomo se flexiona, orejas y cola hacia atrás
  Run: { dur: 0.48, loop: true, joints: merge(tail('x', 6, 1, 0.3, 30), legs(36, 30, 24, 28, { LegFL: 0, LegFR: 0.08, LegBL: 0.5, LegBR: 0.58 }), {
    Hips: { o: [['py', 0.18, 1, 0.25], ['x', 7, 1, 0]] }, Spine: { o: [['x', 7, 1, 0.5]] }, Chest: { o: [['x', 5, 1, 0.5]] },
    Neck1: { k: [[0, -22, 0, 0]], o: [['x', 5, 1, 0.3]] }, Head: { k: [[0, 18, 0, 0]] }, Jaw: { k: [[0, -8, 0, 0]] },
    EarL: { k: [[0, 35, 0, 0]] }, EarR: { k: [[0, 35, 0, 0]] }
  }) },
  Howl: { dur: 3.4, loop: false, next: 'Idle', joints: merge({
    Hips: { k: [[0, 0, 0, 0], [0.6, -10, 0, 0], [2.8, -10, 0, 0], [3.4, 0, 0, 0]], p: [[0, 0, 0, 0], [0.6, 0, -0.35, 0.1], [2.8, 0, -0.35, 0.1], [3.4, 0, 0, 0]] },
    LegBL_Upper: { k: [[0, 0, 0, 0], [0.6, 30, 0, 0], [2.8, 30, 0, 0], [3.4, 0, 0, 0]] }, LegBR_Upper: { k: [[0, 0, 0, 0], [0.6, 30, 0, 0], [2.8, 30, 0, 0], [3.4, 0, 0, 0]] },
    LegBL_Lower: { k: [[0, 0, 0, 0], [0.6, -30, 0, 0], [2.8, -30, 0, 0], [3.4, 0, 0, 0]] }, LegBR_Lower: { k: [[0, 0, 0, 0], [0.6, -30, 0, 0], [2.8, -30, 0, 0], [3.4, 0, 0, 0]] },
    Neck1: { k: [[0, 0, 0, 0], [0.7, 32, 0, 0], [2.8, 34, 0, 0], [3.4, 0, 0, 0]] }, Neck2: { k: [[0, 0, 0, 0], [0.7, 18, 0, 0], [2.8, 18, 0, 0], [3.4, 0, 0, 0]] },
    Head: { k: [[0, 0, 0, 0], [0.7, 30, 0, 0], [2.8, 34, 0, 0], [3.4, 0, 0, 0]], o: [['z', 1.5, 30, 0]] },
    Jaw: { k: [[0, 0, 0, 0], [0.8, -24, 0, 0], [2.6, -20, 0, 0], [3.0, 0, 0, 0]], o: [['x', 1.5, 26, 0]] },
    EarL: { k: [[0, 0, 0, 0], [0.7, 25, 0, 0], [3.4, 0, 0, 0]] }, EarR: { k: [[0, 0, 0, 0], [0.7, 25, 0, 0], [3.4, 0, 0, 0]] }
  }, tail('y', 3, 3, 0, 0)) },
  // gruñido: agazapado, cabeza baja y adelantada, belfos abiertos, orejas atrás, temblor en el lomo
  Growl: { dur: 2.4, loop: true, joints: merge(tail('y', 2, 6, 0, 18), {
    Hips: { p: [[0, 0, -0.18, 0]] }, Chest: { k: [[0, -6, 0, 0]], p: [[0, 0, -0.22, 0]], o: [['x', 1, 22, 0]] }, Spine: { o: [['z', 0.8, 18, 0]] },
    Neck1: { k: [[0, -22, 0, 0]] }, Neck2: { k: [[0, -6, 0, 0]] }, Head: { k: [[0, 16, 0, 0]], o: [['x', 1.5, 14, 0]] },
    Jaw: { k: [[0, -14, 0, 0]], o: [['x', 3, 6, 0]] }, EarL: { k: [[0, 45, 0, -10]] }, EarR: { k: [[0, 45, 0, 10]] },
    LegFL_Upper: { k: [[0, -12, 0, 0]] }, LegFR_Upper: { k: [[0, -12, 0, 0]] }, LegFL_Lower: { k: [[0, -15, 0, 0]] }, LegFR_Lower: { k: [[0, -15, 0, 0]] },
    LegBL_Upper: { k: [[0, 10, 0, 0]] }, LegBR_Upper: { k: [[0, 10, 0, 0]] }
  }) },
  // ataque: se agacha, salta hacia delante y cierra la mandíbula
  Attack: { dur: 0.85, loop: false, next: 'Growl', joints: {
    Hips: { k: [[0, 0, 0, 0], [0.25, 6, 0, 0], [0.45, -10, 0, 0], [0.85, 0, 0, 0]], p: [[0, 0, -0.18, 0], [0.25, 0, -0.3, 0.2], [0.45, 0, 0.35, -1.0], [0.6, 0, 0.1, -1.1], [0.85, 0, 0, 0]] },
    Neck1: { k: [[0, -22, 0, 0], [0.25, -30, 0, 0], [0.45, -5, 0, 0], [0.85, -20, 0, 0]] }, Head: { k: [[0, 16, 0, 0], [0.45, 5, 0, 0], [0.85, 16, 0, 0]] },
    Jaw: { k: [[0, -14, 0, 0], [0.3, -38, 0, 0], [0.48, -40, 0, 0], [0.55, 0, 0, 0], [0.85, -12, 0, 0]] },
    LegFL_Upper: { k: [[0, -12, 0, 0], [0.25, -25, 0, 0], [0.45, 45, 0, 0], [0.85, -10, 0, 0]] }, LegFR_Upper: { k: [[0, -12, 0, 0], [0.25, -25, 0, 0], [0.45, 45, 0, 0], [0.85, -10, 0, 0]] },
    LegBL_Upper: { k: [[0, 10, 0, 0], [0.25, 30, 0, 0], [0.45, -35, 0, 0], [0.85, 10, 0, 0]] }, LegBR_Upper: { k: [[0, 10, 0, 0], [0.25, 30, 0, 0], [0.45, -35, 0, 0], [0.85, 10, 0, 0]] },
    EarL: { k: [[0, 45, 0, 0]] }, EarR: { k: [[0, 45, 0, 0]] }, Tail1: { k: [[0, -10, 0, 0], [0.45, -30, 0, 0], [0.85, -10, 0, 0]] }
  } },
  Hurt: { dur: 0.55, loop: false, next: 'Growl', joints: {
    Hips: { k: [[0, 0, 0, 0], [0.12, 0, 0, 10], [0.55, 0, 0, 0]], p: [[0, 0, 0, 0], [0.12, 0.15, -0.1, 0.25], [0.55, 0, 0, 0]] },
    Neck1: { k: [[0, 0, 0, 0], [0.12, 15, 18, 0], [0.55, 0, 0, 0]] }, Head: { k: [[0, 0, 0, 0], [0.12, 10, 0, 15], [0.55, 0, 0, 0]] },
    Jaw: { k: [[0, 0, 0, 0], [0.1, -25, 0, 0], [0.4, 0, 0, 0]] }, EarL: { k: [[0, 0, 0, 0], [0.1, 50, 0, 0], [0.55, 0, 0, 0]] }, EarR: { k: [[0, 0, 0, 0], [0.1, 50, 0, 0], [0.55, 0, 0, 0]] },
    Tail1: { k: [[0, 0, 0, 0], [0.12, 35, 0, 0], [0.55, 0, 0, 0]] }
  } },
  Death: { dur: 1.8, loop: false, joints: {
    Hips: { k: [[0, 0, 0, 0], [0.5, 0, 0, -20], [1.2, 0, 0, -84], [1.8, 0, 0, -88]], p: [[0, 0, 0, 0], [1.2, 0, -1.55, 0], [1.8, 0, -1.7, 0]] },
    Neck1: { k: [[0, 0, 0, 0], [1.3, -30, 0, -10], [1.8, -35, 0, -15]] }, Head: { k: [[0, 0, 0, 0], [1.8, -20, 0, -15]] }, Jaw: { k: [[0, 0, 0, 0], [0.4, -30, 0, 0], [1.8, -12, 0, 0]] },
    LegFL_Upper: { k: [[0, 0, 0, 0], [1.3, 25, 0, 10]] }, LegBL_Upper: { k: [[0, 0, 0, 0], [1.3, 20, 0, 10]] },
    LegFR_Lower: { k: [[0, 0, 0, 0], [1.3, 30, 0, 0]] }, LegBR_Lower: { k: [[0, 0, 0, 0], [1.3, -30, 0, 0]] },
    EarL: { k: [[0, 0, 0, 0], [1.8, 40, 0, 0]] }, EarR: { k: [[0, 0, 0, 0], [1.8, 40, 0, 0]] }, Tail2: { k: [[0, 0, 0, 0], [1.8, 20, 25, 0]] }
  } }
};

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
root.WOLF_ANIMS = WOLF_ANIMS;
root.AnimEval = { evalJoint, sampleKeys };
})(typeof window !== 'undefined' ? window : globalThis);
