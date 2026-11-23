/*
 * Animaciones del pez infectado, como datos (mismo formato que los infectados, los dragones y los lobos).
 *   k: [t, rx, ry, rz] grados · p: [t, x, y, z] studs · o: [eje, amplitud, ciclos, fase]
 * Motor6D con C0/C1 sin rotación: los giros son en los ejes de la pieza padre (en reposo, los del modelo; el pez mira a -Z).
 *   ry gira a los lados (la onda del nado) · +rx levanta el morro (Head) · la mandíbula se abre con -rx
 *   aletas pectorales: +rz baja la izquierda y sube la derecha
 * Piezas: Body (sobre Root), Head, Jaw, Mid, Tail, TailFin, LeftFin, RightFin
 * El servidor mueve el pez entero; el giro panza arriba al morir también lo hace el servidor.
 */
(function (root) {
// onda lateral que recorre el cuerpo de la cabeza a la cola (cada pieza un poco más tarde y con más amplitud)
const wave = (a, cyc = 1) => ({
  Body: { o: [['y', a * 0.25, cyc, 0]] }, Head: { o: [['y', a * 0.35, cyc, 0.5]] },
  Mid: { o: [['y', a * 0.6, cyc, 0.15]] }, Tail: { o: [['y', a * 1.1, cyc, 0.3]] }, TailFin: { o: [['y', a * 1.5, cyc, 0.45]] },
});
const fins = (a, cyc, base = 0) => ({ LeftFin: { k: [[0, 0, 0, base]], o: [['z', a, cyc, 0]] }, RightFin: { k: [[0, 0, 0, -base]], o: [['z', -a, cyc, 0]] } });
const merge = (...objs) => { const out = {}; for (const o of objs) for (const k in o) { out[k] = out[k] || {}; for (const c in o[k]) out[k][c] = c === 'o' ? (out[k][c] || []).concat(o[k][c]) : o[k][c]; } return out; };

const FISH_ANIMS = {
  // flota casi quieto: onda lenta, boquea
  Idle: { dur: 3.2, loop: true, joints: merge(wave(10), fins(14, 2), { Jaw: { k: [[0, -8, 0, 0]], o: [['x', 6, 2, 0]] }, Head: { o: [['x', 2, 1, 0.2]] } }) },
  // nado de crucero
  Swim: { dur: 1.2, loop: true, joints: merge(wave(16), fins(18, 1), { Jaw: { k: [[0, -6, 0, 0]], o: [['x', 4, 2, 0]] } }) },
  // embestida: onda rápida y amplia, aletas pegadas, la boca abierta
  Charge: { dur: 0.5, loop: true, joints: merge(wave(24), fins(6, 2, -55), { Jaw: { k: [[0, -30, 0, 0]], o: [['x', 8, 2, 0]] }, Head: { k: [[0, 6, 0, 0]] } }) },
  // mordisco: levanta el morro, abre del todo y cierra de golpe
  Bite: { dur: 0.6, loop: false, next: 'Charge', joints: merge(fins(8, 3, -40), {
    Head: { k: [[0, 0, 0, 0], [0.18, 16, 0, 0], [0.3, -10, 0, 0], [0.6, 0, 0, 0]] },
    Jaw: { k: [[0, -20, 0, 0], [0.18, -62, 0, 0], [0.28, 0, 0, 0], [0.6, -20, 0, 0]] },
    Body: { k: [[0, 0, 0, 0], [0.28, -6, 0, 10], [0.6, 0, 0, 0]] },
    Mid: { k: [[0, 0, 0, 0], [0.28, 0, -18, 0], [0.6, 0, 0, 0]] }, Tail: { k: [[0, 0, 0, 0], [0.3, 0, 30, 0], [0.6, 0, 0, 0]] },
    TailFin: { k: [[0, 0, 0, 0], [0.32, 0, 40, 0], [0.6, 0, 0, 0]] },
  }) },
  // salto fuera del agua: se arquea, abre la boca en lo alto y muerde, vuelve a caer coleteando
  Leap: { dur: 1.4, loop: false, next: 'Swim', joints: {
    Head: { k: [[0, 0, 0, 0], [0.2, 22, 0, 0], [0.55, 10, 0, 0], [0.75, -18, 0, 0], [1.4, 0, 0, 0]] },
    Jaw: { k: [[0, -10, 0, 0], [0.45, -70, 0, 0], [0.62, 0, 0, 0], [0.9, -25, 0, 0], [1.4, -8, 0, 0]] },
    Mid: { k: [[0, 0, 0, 0], [0.2, -14, 0, 0], [0.7, 12, 0, 0], [1.4, 0, 0, 0]], o: [['y', 10, 5, 0]] },
    Tail: { k: [[0, 0, 0, 0], [0.2, -24, 0, 0], [0.7, 26, 0, 0], [1.4, 0, 0, 0]], o: [['y', 18, 5, 0.2]] },
    TailFin: { k: [[0, 0, 0, 0], [0.2, -30, 0, 0], [0.7, 30, 0, 0], [1.4, 0, 0, 0]], o: [['y', 26, 5, 0.4]] },
    LeftFin: { k: [[0, 0, 0, 0], [0.3, 0, 0, -35], [1.0, 0, 0, 20], [1.4, 0, 0, 0]], o: [['z', 15, 6, 0]] },
    RightFin: { k: [[0, 0, 0, 0], [0.3, 0, 0, 35], [1.0, 0, 0, -20], [1.4, 0, 0, 0]], o: [['z', -15, 6, 0]] },
  } },
  // chillido al descubrirte: morro arriba, boca abierta del todo, todo tiembla
  Screech: { dur: 1.2, loop: false, next: 'Charge', joints: merge(fins(10, 14, 30), {
    Head: { k: [[0, 0, 0, 0], [0.2, 24, 0, 0], [0.95, 22, 0, 0], [1.2, 0, 0, 0]], o: [['y', 3, 16, 0], ['x', 2, 21, 0.3]] },
    Jaw: { k: [[0, -10, 0, 0], [0.2, -78, 0, 0], [0.95, -74, 0, 0], [1.2, -25, 0, 0]], o: [['x', 4, 18, 0]] },
    Mid: { k: [[0, 0, 0, 0], [0.2, 8, 0, 0], [1.2, 0, 0, 0]], o: [['y', 4, 12, 0]] },
    Tail: { k: [[0, 0, 0, 0], [0.2, 14, 0, 0], [1.2, 0, 0, 0]], o: [['y', 8, 12, 0.3]] },
    TailFin: { o: [['y', 14, 12, 0.5]] },
  }) },
  Hurt: { dur: 0.45, loop: false, next: 'Swim', joints: {
    Body: { k: [[0, 0, 0, 0], [0.1, 0, 0, 22], [0.45, 0, 0, 0]] }, Head: { k: [[0, 0, 0, 0], [0.1, 10, 20, 0], [0.45, 0, 0, 0]] },
    Jaw: { k: [[0, -6, 0, 0], [0.1, -45, 0, 0], [0.45, -6, 0, 0]] },
    Mid: { k: [[0, 0, 0, 0], [0.12, 0, -25, 0], [0.45, 0, 0, 0]] }, Tail: { k: [[0, 0, 0, 0], [0.14, 0, -35, 0], [0.45, 0, 0, 0]] },
    TailFin: { k: [[0, 0, 0, 0], [0.16, 0, -40, 0], [0.45, 0, 0, 0]] },
  } },
  // espasmos y queda flácido, con la boca abierta y las aletas caídas
  Death: { dur: 1.6, loop: false, joints: {
    Head: { k: [[0, 0, 0, 0], [0.2, 15, -20, 0], [0.5, -10, 15, 0], [1.6, -8, 12, 0]] },
    Jaw: { k: [[0, -6, 0, 0], [0.3, -60, 0, 0], [1.6, -42, 0, 0]] },
    Mid: { k: [[0, 0, 0, 0], [0.25, 0, 30, 0], [0.55, 0, -25, 0], [1.6, 0, -10, 0]] },
    Tail: { k: [[0, 0, 0, 0], [0.3, 0, 40, 0], [0.6, 0, -35, 0], [1.6, 0, -16, 0]] },
    TailFin: { k: [[0, 0, 0, 0], [0.35, 0, 45, 0], [0.65, 0, -40, 0], [1.6, 0, -20, 0]] },
    LeftFin: { k: [[0, 0, 0, 0], [1.6, 0, 0, 40]] }, RightFin: { k: [[0, 0, 0, 0], [1.6, 0, 0, -40]] },
  } },
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
root.FISH_ANIMS = FISH_ANIMS;
root.AnimEval = { evalJoint, sampleKeys };
})(typeof window !== 'undefined' ? window : globalThis);
