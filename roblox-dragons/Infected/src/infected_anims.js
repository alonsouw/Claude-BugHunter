/*
 * Animaciones de los infectados (personajes de bloques), como datos: mismo formato que los dragones y los lobos.
 *   k: [t, rx, ry, rz] grados · p: [t, x, y, z] studs · o: [eje, amplitud, ciclos, fase]
 * Motor6D con C0/C1 sin rotación: los giros son en los ejes de la pieza padre (en reposo, los del modelo).
 *   brazos y piernas cuelgan: +rx los lleva hacia delante; la rodilla se dobla con -rx en LowerLeg
 *   torso y cabeza apuntan arriba: -rx los inclina hacia delante; rz los ladea
 *   la mandíbula se abre con -rx; un brazo se abre hacia fuera con rz (izquierdo -, derecho +)
 * Piezas: Torso (sobre HumanoidRootPart), Head, Jaw, {Left,Right}{Upper,Lower}Arm, {Left,Right}{Upper,Lower}Leg
 */
(function (root) {
const merge = (...objs) => { const out = {}; for (const o of objs) for (const k in o) { out[k] = out[k] || {}; for (const c in o[k]) out[k][c] = c === 'o' ? (out[k][c] || []).concat(o[k][c]) : o[k][c]; } return out; };
const ARMS_FORWARD = (rx, amp, cyc) => ({
  LeftUpperArm: { k: [[0, rx, 0, -4]], o: [['x', amp, cyc, 0]] }, RightUpperArm: { k: [[0, rx - 10, 0, 6]], o: [['x', amp, cyc, 0.5]] },
  LeftLowerArm: { k: [[0, 12, 0, 0]], o: [['x', amp * 0.6, cyc, 0.2]] }, RightLowerArm: { k: [[0, 18, 0, 0]], o: [['x', amp * 0.6, cyc, 0.7]] },
});

const INFECTED_ANIMS = {
  Idle: { dur: 4.5, loop: true, joints: merge({
    Torso: { k: [[0, -8, 0, 0]], o: [['z', 3, 1, 0], ['x', 1.5, 2, 0.2]] },
    Head: { k: [[0, -6, 0, 14], [1.8, -6, 0, 14], [1.9, -10, 10, -12], [3.2, -10, 10, -12], [3.35, -6, 0, 14]], o: [['z', 2, 7, 0]] },
    Jaw: { k: [[0, -14, 0, 0]], o: [['x', 4, 3, 0]] },
    LeftUpperArm: { k: [[0, 6, 0, -3]], o: [['x', 4, 1, 0.1]] }, RightUpperArm: { k: [[0, 4, 0, 5]], o: [['x', 5, 1, 0.6]] },
    LeftLowerArm: { k: [[0, 10, 0, 0]] }, RightLowerArm: { k: [[0, 6, 0, 0]] },
    RightUpperLeg: { k: [[0, -3, 0, 4]] }, RightLowerLeg: { k: [[0, -6, 0, 0]] }
  }) },
  // arrastra los pies: la pierna derecha cojea y se arrastra, brazos por delante, cabeza caída
  Walk: { dur: 1.9, loop: true, joints: merge(ARMS_FORWARD(78, 8, 1), {
    Torso: { k: [[0, -14, 0, 0]], p: [[0, 0, 0, 0]], o: [['z', 6, 1, 0], ['y', 6, 1, 0.25], ['py', 0.07, 2, 0]] },
    Head: { k: [[0, -8, 0, 16]], o: [['z', 5, 1, 0.5], ['x', 3, 2, 0.3]] }, Jaw: { k: [[0, -18, 0, 0]], o: [['x', 5, 2, 0]] },
    LeftUpperLeg: { o: [['x', 24, 1, 0]] }, LeftLowerLeg: { k: [[0, -14, 0, 0]], o: [['x', 14, 1, 0.75]] },
    RightUpperLeg: { k: [[0, -4, 0, 4]], o: [['x', 13, 1, 0.5]] }, RightLowerLeg: { k: [[0, -6, 0, 0]], o: [['x', 5, 1, 0.25]] }
  }) },
  // carrera desbocada: muy inclinado, brazos sacudiéndose, la boca abierta
  Run: { dur: 0.56, loop: true, joints: {
    Torso: { k: [[0, -30, 0, 0]], o: [['py', 0.18, 2, 0], ['y', 8, 1, 0], ['z', 4, 1, 0.3]] },
    Head: { k: [[0, 18, 0, 10]], o: [['z', 8, 2, 0.4]] }, Jaw: { k: [[0, -32, 0, 0]], o: [['x', 8, 2, 0]] },
    LeftUpperArm: { k: [[0, 10, 0, -20]], o: [['x', 60, 1, 0.5]] }, RightUpperArm: { k: [[0, 10, 0, 20]], o: [['x', 60, 1, 0]] },
    LeftLowerArm: { k: [[0, 35, 0, 0]], o: [['x', 20, 1, 0.7]] }, RightLowerArm: { k: [[0, 35, 0, 0]], o: [['x', 20, 1, 0.2]] },
    LeftUpperLeg: { k: [[0, 10, 0, 0]], o: [['x', 48, 1, 0]] }, RightUpperLeg: { k: [[0, 10, 0, 0]], o: [['x', 48, 1, 0.5]] },
    LeftLowerLeg: { k: [[0, -40, 0, 0]], o: [['x', 35, 1, 0.75]] }, RightLowerLeg: { k: [[0, -40, 0, 0]], o: [['x', 35, 1, 0.25]] }
  } },
  // zarpazo con las dos manos y mordisco
  Attack: { dur: 0.75, loop: false, next: 'Walk', joints: {
    Torso: { k: [[0, -14, 0, 0], [0.25, 4, 0, 0], [0.45, -32, 0, 0], [0.75, -14, 0, 0]], p: [[0, 0, 0, 0], [0.45, 0, -0.15, -0.4], [0.75, 0, 0, 0]] },
    LeftUpperArm: { k: [[0, 78, 0, -4], [0.25, 155, 0, -12], [0.45, 40, 0, 8], [0.75, 78, 0, -4]] },
    RightUpperArm: { k: [[0, 68, 0, 6], [0.25, 150, 0, 14], [0.45, 35, 0, -8], [0.75, 68, 0, 6]] },
    LeftLowerArm: { k: [[0, 12, 0, 0], [0.25, 30, 0, 0], [0.45, 5, 0, 0], [0.75, 12, 0, 0]] }, RightLowerArm: { k: [[0, 18, 0, 0], [0.25, 30, 0, 0], [0.45, 5, 0, 0], [0.75, 18, 0, 0]] },
    Head: { k: [[0, -8, 0, 16], [0.3, 10, 0, 0], [0.5, -15, 0, 5], [0.75, -8, 0, 16]] },
    Jaw: { k: [[0, -18, 0, 0], [0.3, -50, 0, 0], [0.48, 0, 0, 0], [0.75, -18, 0, 0]] },
    LeftUpperLeg: { k: [[0, 0, 0, 0], [0.45, 25, 0, 0], [0.75, 0, 0, 0]] }, LeftLowerLeg: { k: [[0, 0, 0, 0], [0.45, -20, 0, 0], [0.75, 0, 0, 0]] }
  } },
  // grito: echa la cabeza atrás, abre la boca al máximo y los brazos, todo tiembla
  Scream: { dur: 2.3, loop: false, next: 'Run', joints: {
    Torso: { k: [[0, -8, 0, 0], [0.35, 12, 0, 0], [1.9, 12, 0, 0], [2.3, -14, 0, 0]], o: [['z', 1.5, 40, 0]] },
    Head: { k: [[0, -6, 0, 0], [0.35, 38, 0, 0], [1.9, 36, 0, 0], [2.3, -6, 0, 10]], o: [['z', 3, 34, 0], ['y', 2, 27, 0.2]] },
    Jaw: { k: [[0, -14, 0, 0], [0.3, -75, 0, 0], [1.9, -72, 0, 0], [2.3, -20, 0, 0]], o: [['x', 4, 38, 0]] },
    LeftUpperArm: { k: [[0, 6, 0, -3], [0.4, 20, 0, -75], [1.9, 20, 0, -78], [2.3, 70, 0, -4]], o: [['z', 3, 30, 0]] },
    RightUpperArm: { k: [[0, 4, 0, 5], [0.4, 20, 0, 75], [1.9, 20, 0, 78], [2.3, 70, 0, 6]], o: [['z', -3, 30, 0.5]] },
    LeftLowerArm: { k: [[0, 10, 0, 0], [0.4, 25, 0, -20], [2.3, 12, 0, 0]] }, RightLowerArm: { k: [[0, 6, 0, 0], [0.4, 25, 0, 20], [2.3, 18, 0, 0]] }
  } },
  // golpe al suelo del bruto con el brazo deforme
  Slam: { dur: 1.35, loop: false, next: 'Walk', joints: {
    Torso: { k: [[0, -14, 0, 0], [0.5, 12, 0, -8], [0.72, -38, 0, 6], [1.0, -38, 0, 6], [1.35, -14, 0, 0]], p: [[0, 0, 0, 0], [0.72, 0, -0.5, -0.3], [1.0, 0, -0.5, -0.3], [1.35, 0, 0, 0]] },
    RightUpperArm: { k: [[0, 68, 0, 6], [0.5, 175, 0, 10], [0.72, 25, 0, 0], [1.0, 25, 0, 0], [1.35, 68, 0, 6]] },
    RightLowerArm: { k: [[0, 18, 0, 0], [0.5, 40, 0, 0], [0.72, 0, 0, 0], [1.35, 18, 0, 0]] },
    LeftUpperArm: { k: [[0, 78, 0, -4], [0.5, 30, 0, -30], [0.72, 60, 0, -10], [1.35, 78, 0, -4]] },
    Head: { k: [[0, -8, 0, 16], [0.5, 20, 0, 0], [0.72, -10, 0, 0], [1.35, -8, 0, 16]] }, Jaw: { k: [[0, -18, 0, 0], [0.55, -60, 0, 0], [1.0, -40, 0, 0], [1.35, -18, 0, 0]] },
    LeftUpperLeg: { k: [[0, 0, 0, 0], [0.72, 30, 0, 0], [1.0, 30, 0, 0], [1.35, 0, 0, 0]] }, LeftLowerLeg: { k: [[0, 0, 0, 0], [0.72, -45, 0, 0], [1.0, -45, 0, 0], [1.35, 0, 0, 0]] },
    RightUpperLeg: { k: [[0, 0, 0, 0], [0.72, -20, 0, 0], [1.35, 0, 0, 0]] }
  } },
  Hurt: { dur: 0.4, loop: false, next: 'Walk', joints: {
    Torso: { k: [[0, -14, 0, 0], [0.1, 10, 0, 8], [0.4, -14, 0, 0]] }, Head: { k: [[0, -8, 0, 16], [0.1, 20, 15, -20], [0.4, -8, 0, 16]] },
    Jaw: { k: [[0, -18, 0, 0], [0.1, -40, 0, 0], [0.4, -18, 0, 0]] },
    LeftUpperArm: { k: [[0, 78, 0, -4], [0.1, 40, 0, -30], [0.4, 78, 0, -4]] }, RightUpperArm: { k: [[0, 68, 0, 6], [0.1, 40, 0, 30], [0.4, 68, 0, 6]] }
  } },
  // se desploma de bruces
  Death: { dur: 1.6, loop: false, joints: {
    Torso: { k: [[0, -14, 0, 0], [0.3, 8, 0, 10], [1.1, -84, 0, 6], [1.6, -88, 0, 4]], p: [[0, 0, 0, 0], [0.3, 0, 0.1, 0.1], [1.1, 0, -2.45, -0.9], [1.6, 0, -2.55, -1.0]] },
    Head: { k: [[0, -8, 0, 16], [1.1, 20, 30, 0], [1.6, 25, 40, 0]] }, Jaw: { k: [[0, -18, 0, 0], [1.6, -40, 0, 0]] },
    LeftUpperArm: { k: [[0, 78, 0, -4], [1.1, 160, 0, -40], [1.6, 170, 0, -45]] }, RightUpperArm: { k: [[0, 68, 0, 6], [1.1, 120, 0, 50], [1.6, 125, 0, 55]] },
    LeftUpperLeg: { k: [[0, 0, 0, 0], [1.1, 75, 0, -5], [1.6, 82, 0, -5]] }, RightUpperLeg: { k: [[0, 0, 0, 0], [1.1, 70, 0, 8], [1.6, 80, 0, 8]] },
    LeftLowerLeg: { k: [[0, 0, 0, 0], [1.6, -20, 0, 0]] }, RightLowerLeg: { k: [[0, 0, 0, 0], [1.6, -35, 0, 0]] }
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
root.INFECTED_ANIMS = INFECTED_ANIMS;
root.AnimEval = { evalJoint, sampleKeys };
})(typeof window !== 'undefined' ? window : globalThis);
