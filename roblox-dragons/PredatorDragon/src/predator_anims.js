/*
 * Animaciones del Dragón Depredador, como datos (mismo formato que el Aberrante).
 *   k: [t, rx, ry, rz] grados · p: [t, x, y, z] studs (solo Hips) · o: [eje, amplitud, ciclos, fase]
 * Ejes en espacio Roblox, pose de reposo: +rx adelanta lo que cuelga (patas) y levanta lo que mira al frente;
 * la mandíbula se abre con -rx. Ala izquierda: +rz baja la punta, +ry la pliega atrás; ala derecha, al revés.
 * La cabeza además sigue al jugador en tiempo real (LookAt de DragonAnimator), sumado encima de esto.
 * Rig de Bones: Hips, Chest, Neck1-3, Head, Jaw, Tongue, Tail1-7, Leg{F,B}{L,R}_{Upper,Lower,Foot}, Wing{L,R}_{Arm,Fore,Hand}.
 */
(function (root) {
const tail = (axis, amp, cyc, ph0) => { const o = {}; for (let i = 1; i <= 7; i++) o['Tail' + i] = { o: [[axis, amp * (0.25 + 0.11 * i), cyc, ph0 + 0.06 * i]] }; return o; };
const merge = (...objs) => { const out = {}; for (const o of objs) for (const k in o) { out[k] = out[k] || {}; for (const c in o[k]) out[k][c] = (out[k][c] || []).concat(o[k][c]); } return out; };
const legs = (ampU, ampL, ampF, ph) => ({
  LegFL_Upper: { o: [['x', ampU, 1, ph.FL]] }, LegFL_Lower: { o: [['x', ampL, 1, ph.FL + 0.2]] }, LegFL_Foot: { o: [['x', ampF, 1, ph.FL + 0.35]] },
  LegFR_Upper: { o: [['x', ampU, 1, ph.FR]] }, LegFR_Lower: { o: [['x', ampL, 1, ph.FR + 0.2]] }, LegFR_Foot: { o: [['x', ampF, 1, ph.FR + 0.35]] },
  LegBL_Upper: { o: [['x', ampU, 1, ph.BL]] }, LegBL_Lower: { o: [['x', ampL, 1, ph.BL + 0.2]] }, LegBL_Foot: { o: [['x', ampF, 1, ph.BL + 0.35]] },
  LegBR_Upper: { o: [['x', ampU, 1, ph.BR]] }, LegBR_Lower: { o: [['x', ampL, 1, ph.BR + 0.2]] }, LegBR_Foot: { o: [['x', ampF, 1, ph.BR + 0.35]] } });
const wingsK = (keysL, keysR) => ({ WingL_Arm: { k: keysL }, WingR_Arm: { k: keysR } });
const mirror = keys => keys.map(([t, x, y, z]) => [t, x, -y, -z]);
const tuck = { FL: [-35, 60, -30], BL: [-50, 35, -25] };

const ANIMS = {
  Idle: { dur: 4, loop: true, joints: merge(tail('y', 5, 1, 0), {
    Hips: { o: [['py', 0.06, 2, 0]] }, Chest: { o: [['x', 1.5, 2, 0.1]] },
    Neck1: { o: [['x', 2, 1, 0]] }, Neck2: { o: [['x', 2, 1, 0.1]] }, Head: { o: [['x', 2.5, 1, 0.2]] },
    Jaw: { o: [['x', 3, 1, 0.3]] }, Tongue: { o: [['x', 6, 1, 0.1], ['z', 4, 2, 0.3]] },
    WingL_Arm: { k: [[0, 0, 6, 4]], o: [['z', 2.5, 1, 0]] }, WingR_Arm: { k: [[0, 0, -6, -4]], o: [['z', -2.5, 1, 0]] },
    WingL_Hand: { o: [['y', 3, 1, 0.2]] }, WingR_Hand: { o: [['y', -3, 1, 0.2]] }
  }) },

  Walk: { dur: 2.0, loop: true, joints: merge(tail('y', 9, 1, 0.1), legs(20, 16, 14, { FL: 0, BR: 0, FR: 0.5, BL: 0.5 }), {
    Hips: { o: [['py', 0.15, 2, 0], ['z', 3, 1, 0.1], ['y', 3, 1, 0.3]] }, Chest: { o: [['z', -3, 1, 0.2]] },
    Neck1: { o: [['x', 3, 2, 0.1]] }, Head: { o: [['z', 4, 1, 0.5]] }, Tongue: { o: [['x', 12, 2, 0.2]] },
    WingL_Hand: { k: [[0, 0, 15, 0]] }, WingR_Hand: { k: [[0, 0, -15, 0]] }
  }, wingsK([[0, 0, 25, 12]], [[0, 0, -25, -12]])) },

  Run: { dur: 1.0, loop: true, joints: merge(tail('y', 12, 1, 0.1), tail('x', 6, 2, 0), legs(35, 30, 22, { FL: 0, FR: 0.08, BL: 0.5, BR: 0.58 }), {
    Hips: { k: [[0, -6, 0, 0]], p: [[0, 0, -0.4, 0]], o: [['py', 0.45, 2, 0], ['x', 5, 1, 0]] },
    Chest: { o: [['x', 6, 1, 0.5]] }, Neck1: { k: [[0, -10, 0, 0]] }, Head: { k: [[0, 8, 0, 0]], o: [['x', 4, 2, 0.3]] },
    Jaw: { k: [[0, -8, 0, 0]] }, Tongue: { o: [['x', 18, 2, 0.2]] },
    WingL_Hand: { k: [[0, 0, 10, 0]] }, WingR_Hand: { k: [[0, 0, -10, 0]] }
  }, wingsK([[0, 0, 18, -8]], [[0, 0, -18, 8]])) },

  Fly: { dur: 1.6, loop: true, joints: merge(tail('x', 6, 1, 0.3), tail('y', 6, 1, 0), {
    Hips: { k: [[0, 4, 0, 0]], p: [[0, 0, 7, 0]], o: [['py', 0.7, 1, 0.25]] },
    LegFL_Upper: { k: [[0, tuck.FL[0], 0, 0]] }, LegFL_Lower: { k: [[0, tuck.FL[1], 0, 0]] }, LegFL_Foot: { k: [[0, tuck.FL[2], 0, 0]] },
    LegFR_Upper: { k: [[0, tuck.FL[0], 0, 0]] }, LegFR_Lower: { k: [[0, tuck.FL[1], 0, 0]] }, LegFR_Foot: { k: [[0, tuck.FL[2], 0, 0]] },
    LegBL_Upper: { k: [[0, tuck.BL[0], 0, 0]] }, LegBL_Lower: { k: [[0, tuck.BL[1], 0, 0]] }, LegBL_Foot: { k: [[0, tuck.BL[2], 0, 0]] },
    LegBR_Upper: { k: [[0, tuck.BL[0], 0, 0]] }, LegBR_Lower: { k: [[0, tuck.BL[1], 0, 0]] }, LegBR_Foot: { k: [[0, tuck.BL[2], 0, 0]] },
    Neck1: { k: [[0, -10, 0, 0]] }, Neck2: { k: [[0, -6, 0, 0]] }, Head: { k: [[0, 10, 0, 0]] }, Jaw: { k: [[0, -6, 0, 0]] },
    Tongue: { k: [[0, -20, 0, 0]], o: [['x', 10, 2, 0]] },
    WingL_Arm: { k: [[0, 0, 0, -5]], o: [['z', 45, 1, 0]] }, WingR_Arm: { k: [[0, 0, 0, 5]], o: [['z', -45, 1, 0]] },
    WingL_Hand: { o: [['z', 28, 1, 0.12], ['y', 10, 1, 0.3]] }, WingR_Hand: { o: [['z', -28, 1, 0.12], ['y', -10, 1, 0.3]] },
    WingL_Fore: { o: [['z', 16, 1, 0.06]] }, WingR_Fore: { o: [['z', -16, 1, 0.06]] }
  }) },

  TakeOff: { dur: 1.8, loop: false, next: 'Fly', joints: merge({
    Hips: { k: [[0, 0, 0, 0], [0.45, 6, 0, 0], [0.8, -12, 0, 0], [1.8, 4, 0, 0]], p: [[0, 0, 0, 0], [0.45, 0, -1.2, 0], [0.8, 0, 2.8, -0.8], [1.8, 0, 7, 0]] },
    LegBL_Upper: { k: [[0, 0, 0, 0], [0.45, 25, 0, 0], [0.75, -30, 0, 0], [1.8, tuck.BL[0], 0, 0]] }, LegBR_Upper: { k: [[0, 0, 0, 0], [0.45, 25, 0, 0], [0.75, -30, 0, 0], [1.8, tuck.BL[0], 0, 0]] },
    LegBL_Lower: { k: [[0, 0, 0, 0], [0.45, -40, 0, 0], [0.75, 15, 0, 0], [1.8, tuck.BL[1], 0, 0]] }, LegBR_Lower: { k: [[0, 0, 0, 0], [0.45, -40, 0, 0], [0.75, 15, 0, 0], [1.8, tuck.BL[1], 0, 0]] },
    LegBL_Foot: { k: [[0, 0, 0, 0], [1.8, tuck.BL[2], 0, 0]] }, LegBR_Foot: { k: [[0, 0, 0, 0], [1.8, tuck.BL[2], 0, 0]] },
    LegFL_Upper: { k: [[0, 0, 0, 0], [0.45, 20, 0, 0], [0.8, -20, 0, 0], [1.8, tuck.FL[0], 0, 0]] }, LegFR_Upper: { k: [[0, 0, 0, 0], [0.45, 20, 0, 0], [0.8, -20, 0, 0], [1.8, tuck.FL[0], 0, 0]] },
    LegFL_Lower: { k: [[0, 0, 0, 0], [0.45, -30, 0, 0], [0.8, 40, 0, 0], [1.8, tuck.FL[1], 0, 0]] }, LegFR_Lower: { k: [[0, 0, 0, 0], [0.45, -30, 0, 0], [0.8, 40, 0, 0], [1.8, tuck.FL[1], 0, 0]] },
    LegFL_Foot: { k: [[0, 0, 0, 0], [1.8, tuck.FL[2], 0, 0]] }, LegFR_Foot: { k: [[0, 0, 0, 0], [1.8, tuck.FL[2], 0, 0]] },
    Neck1: { k: [[0, 0, 0, 0], [0.45, 8, 0, 0], [1.8, -10, 0, 0]] }, Neck2: { k: [[0, 0, 0, 0], [1.8, -6, 0, 0]] }, Head: { k: [[0, 0, 0, 0], [0.45, -8, 0, 0], [1.8, 10, 0, 0]] },
    WingL_Hand: { k: [[0, 0, 0, 0], [0.45, 0, 0, -20], [0.85, 0, 0, 30], [1.2, 0, 0, -25], [1.55, 0, 0, 25], [1.8, 0, 0, 0]] },
    WingR_Hand: { k: mirror([[0, 0, 0, 0], [0.45, 0, 0, -20], [0.85, 0, 0, 30], [1.2, 0, 0, -25], [1.55, 0, 0, 25], [1.8, 0, 0, 0]]) },
    Tail1: { k: [[0, 0, 0, 0], [0.45, -10, 0, 0], [0.85, 12, 0, 0], [1.8, 0, 0, 0]] }, Tail3: { k: [[0, 0, 0, 0], [0.5, -10, 0, 0], [0.95, 14, 0, 0], [1.8, 0, 0, 0]] }
  }, wingsK([[0, 0, 6, 4], [0.45, 0, -10, -50], [0.8, 0, 0, 50], [1.15, 0, 0, -40], [1.5, 0, 0, 42], [1.8, 0, 0, -5]], mirror([[0, 0, 6, 4], [0.45, 0, -10, -50], [0.8, 0, 0, 50], [1.15, 0, 0, -40], [1.5, 0, 0, 42], [1.8, 0, 0, -5]]))) },

  Landing: { dur: 1.5, loop: false, next: 'Idle', joints: merge({
    Hips: { k: [[0, 4, 0, 0], [0.6, 10, 0, 0], [1.0, -5, 0, 0], [1.5, 0, 0, 0]], p: [[0, 0, 7, 0], [0.8, 0, 0.6, 0], [1.0, 0, -0.9, 0.2], [1.5, 0, 0, 0]] },
    LegFL_Upper: { k: [[0, tuck.FL[0], 0, 0], [0.6, 25, 0, 0], [1.0, 15, 0, 0], [1.5, 0, 0, 0]] }, LegFR_Upper: { k: [[0, tuck.FL[0], 0, 0], [0.6, 25, 0, 0], [1.0, 15, 0, 0], [1.5, 0, 0, 0]] },
    LegFL_Lower: { k: [[0, tuck.FL[1], 0, 0], [0.6, -10, 0, 0], [1.0, -25, 0, 0], [1.5, 0, 0, 0]] }, LegFR_Lower: { k: [[0, tuck.FL[1], 0, 0], [0.6, -10, 0, 0], [1.0, -25, 0, 0], [1.5, 0, 0, 0]] },
    LegFL_Foot: { k: [[0, tuck.FL[2], 0, 0], [0.7, 0, 0, 0]] }, LegFR_Foot: { k: [[0, tuck.FL[2], 0, 0], [0.7, 0, 0, 0]] },
    LegBL_Upper: { k: [[0, tuck.BL[0], 0, 0], [0.6, 15, 0, 0], [1.0, 25, 0, 0], [1.5, 0, 0, 0]] }, LegBR_Upper: { k: [[0, tuck.BL[0], 0, 0], [0.6, 15, 0, 0], [1.0, 25, 0, 0], [1.5, 0, 0, 0]] },
    LegBL_Lower: { k: [[0, tuck.BL[1], 0, 0], [0.6, 0, 0, 0], [1.0, -35, 0, 0], [1.5, 0, 0, 0]] }, LegBR_Lower: { k: [[0, tuck.BL[1], 0, 0], [0.6, 0, 0, 0], [1.0, -35, 0, 0], [1.5, 0, 0, 0]] },
    LegBL_Foot: { k: [[0, tuck.BL[2], 0, 0], [0.7, 0, 0, 0]] }, LegBR_Foot: { k: [[0, tuck.BL[2], 0, 0], [0.7, 0, 0, 0]] },
    Neck1: { k: [[0, -10, 0, 0], [0.7, 8, 0, 0], [1.05, -10, 0, 0], [1.5, 0, 0, 0]] }, Neck2: { k: [[0, -6, 0, 0], [1.5, 0, 0, 0]] }, Head: { k: [[0, 10, 0, 0], [1.05, -8, 0, 0], [1.5, 0, 0, 0]] },
    Jaw: { k: [[0, -6, 0, 0], [1.5, 0, 0, 0]] }
  }, wingsK([[0, 0, 0, -5], [0.35, 0, -10, -55], [0.7, 0, 0, 25], [1.0, 0, 10, -15], [1.5, 0, 6, 4]], mirror([[0, 0, 0, -5], [0.35, 0, -10, -55], [0.7, 0, 0, 25], [1.0, 0, 10, -15], [1.5, 0, 6, 4]]))) },

  Attack: { dur: 1.4, loop: false, next: 'Idle', joints: merge({
    Hips: { k: [[0, 0, 0, 0], [0.45, 6, 0, 0], [0.62, -8, 0, 0], [1.4, 0, 0, 0]], p: [[0, 0, 0, 0], [0.45, 0, 0.3, 0.8], [0.62, 0, -0.4, -2.0], [1.0, 0, -0.2, -1.2], [1.4, 0, 0, 0]] },
    Neck1: { k: [[0, 0, 0, 0], [0.45, 22, 0, 0], [0.62, -25, 0, 0], [0.95, -20, 0, 0], [1.4, 0, 0, 0]] },
    Neck2: { k: [[0, 0, 0, 0], [0.45, 15, 0, 0], [0.62, -18, 0, 0], [1.4, 0, 0, 0]] },
    Head: { k: [[0, 0, 0, 0], [0.45, 15, 0, 0], [0.62, -5, 0, 0], [1.4, 0, 0, 0]] },
    Jaw: { k: [[0, 0, 0, 0], [0.45, -30, 0, 0], [0.62, -34, 0, 0], [0.7, 8, 0, 0], [1.0, 8, 0, 0], [1.4, 0, 0, 0]] },
    Tongue: { k: [[0, 0, 0, 0], [0.6, 25, 0, 0], [1.4, 0, 0, 0]] },
    LegFL_Upper: { k: [[0, 0, 0, 0], [0.4, 50, 0, -15], [0.62, -20, 0, 5], [1.4, 0, 0, 0]] },
    LegFL_Lower: { k: [[0, 0, 0, 0], [0.4, -50, 0, 0], [0.62, 10, 0, 0], [1.4, 0, 0, 0]] },
    Tail2: { k: [[0, 0, 0, 0], [0.45, 0, 15, 0], [0.7, 0, -20, 0], [1.4, 0, 0, 0]] }, Tail4: { k: [[0, 0, 0, 0], [0.5, 0, 22, 0], [0.75, 0, -28, 0], [1.4, 0, 0, 0]] }
  }, wingsK([[0, 0, 0, 0], [0.45, 0, -10, -30], [0.7, 0, 0, 10], [1.4, 0, 0, 0]], mirror([[0, 0, 0, 0], [0.45, 0, -10, -30], [0.7, 0, 0, 10], [1.4, 0, 0, 0]]))) },

  Roar: { dur: 2.6, loop: false, next: 'Idle', joints: merge({
    Hips: { k: [[0, 0, 0, 0], [0.5, 8, 0, 0], [2.1, 8, 0, 0], [2.6, 0, 0, 0]], p: [[0, 0, 0, 0], [0.5, 0, 0.3, 0.3], [2.1, 0, 0.3, 0.3], [2.6, 0, 0, 0]] },
    Chest: { o: [['x', 1.5, 26, 0]] },
    Neck1: { k: [[0, 0, 0, 0], [0.5, 25, 0, 0], [2.1, 25, 0, 0], [2.6, 0, 0, 0]] }, Neck2: { k: [[0, 0, 0, 0], [0.5, 15, 0, 0], [2.1, 15, 0, 0], [2.6, 0, 0, 0]] },
    Head: { k: [[0, 0, 0, 0], [0.55, 30, 0, 0], [2.1, 28, 0, 0], [2.6, 0, 0, 0]], o: [['z', 3, 26, 0], ['y', 3, 19, 0.2]] },
    Jaw: { k: [[0, 0, 0, 0], [0.55, -38, 0, 0], [2.1, -36, 0, 0], [2.6, 0, 0, 0]], o: [['x', 3, 30, 0]] },
    Tongue: { k: [[0, 0, 0, 0], [0.55, -20, 0, 0], [2.1, -20, 0, 0], [2.6, 0, 0, 0]], o: [['z', 8, 20, 0]] },
    WingL_Arm: { k: [[0, 0, 0, 0], [0.5, 0, -15, -40], [2.1, 0, -15, -42], [2.6, 0, 0, 0]], o: [['z', 3, 24, 0]] },
    WingR_Arm: { k: mirror([[0, 0, 0, 0], [0.5, 0, -15, -40], [2.1, 0, -15, -42], [2.6, 0, 0, 0]]), o: [['z', -3, 24, 0]] },
    WingL_Hand: { k: [[0, 0, 0, 0], [0.5, 0, -10, -15], [2.1, 0, -10, -15], [2.6, 0, 0, 0]] }, WingR_Hand: { k: mirror([[0, 0, 0, 0], [0.5, 0, -10, -15], [2.1, 0, -10, -15], [2.6, 0, 0, 0]]) },
    LegFL_Upper: { k: [[0, 0, 0, 0], [0.5, -10, 0, 0], [2.1, -10, 0, 0], [2.6, 0, 0, 0]] }, LegFR_Upper: { k: [[0, 0, 0, 0], [0.5, -10, 0, 0], [2.1, -10, 0, 0], [2.6, 0, 0, 0]] },
    Tail1: { k: [[0, 0, 0, 0], [0.5, -12, 0, 0], [2.1, -12, 0, 0], [2.6, 0, 0, 0]] }, Tail6: { o: [['y', 12, 12, 0]] }
  }) },

  Death: { dur: 3.0, loop: false, joints: {
    Hips: { k: [[0, 0, 0, 0], [0.5, 8, 0, 0], [1.4, -4, 6, -38], [3.0, -6, 8, -48]], p: [[0, 0, 0, 0], [0.5, 0, 0.4, 0], [1.4, 0, -3.6, 0], [3.0, 0, -3.9, 0]] },
    LegFL_Upper: { k: [[0, 0, 0, 0], [1.4, 30, 0, 20], [3.0, 40, 0, 25]] }, LegFL_Lower: { k: [[0, 0, 0, 0], [1.4, -50, 0, 0], [3.0, -60, 0, 0]] },
    LegBL_Upper: { k: [[0, 0, 0, 0], [1.4, 30, 0, 20], [3.0, 40, 0, 25]] }, LegBL_Lower: { k: [[0, 0, 0, 0], [1.4, -50, 0, 0], [3.0, -60, 0, 0]] },
    LegFR_Upper: { k: [[0, 0, 0, 0], [1.4, -20, 0, -10], [3.0, -30, 0, -15]] }, LegFR_Lower: { k: [[0, 0, 0, 0], [1.4, 40, 0, 0], [3.0, 50, 0, 0]] },
    LegBR_Upper: { k: [[0, 0, 0, 0], [1.4, -20, 0, -10], [3.0, -30, 0, -15]] }, LegBR_Lower: { k: [[0, 0, 0, 0], [1.4, 40, 0, 0], [3.0, 50, 0, 0]] },
    Neck1: { k: [[0, 0, 0, 0], [0.5, 20, 0, 0], [1.6, -25, 0, -15], [3.0, -30, 0, -20]] }, Neck2: { k: [[0, 0, 0, 0], [1.7, -20, 10, 0], [3.0, -25, 12, 0]] },
    Head: { k: [[0, 0, 0, 0], [0.5, 30, 0, 0], [1.8, -15, 0, -25], [3.0, -20, 0, -30]] },
    Jaw: { k: [[0, 0, 0, 0], [0.5, -35, 0, 0], [3.0, -20, 0, 0]] }, Tongue: { k: [[0, 0, 0, 0], [3.0, 20, 0, 30]] },
    WingL_Arm: { k: [[0, 0, 0, 0], [0.5, 0, -15, -40], [1.6, 0, 20, 30], [3.0, 0, 30, 45]] }, WingL_Hand: { k: [[0, 0, 0, 0], [1.6, 0, 30, 20], [3.0, 0, 45, 30]] },
    WingR_Arm: { k: [[0, 0, 0, 0], [0.5, 0, 15, 40], [1.6, 0, -20, -10], [3.0, 0, -30, -20]] }, WingR_Hand: { k: [[0, 0, 0, 0], [1.6, 0, -30, -20], [3.0, 0, -45, -30]] },
    Tail1: { k: [[0, 0, 0, 0], [1.5, 15, 0, 0], [3.0, 20, 0, 0]] }, Tail3: { k: [[0, 0, 0, 0], [3.0, 0, 20, 0]] }, Tail5: { k: [[0, 0, 0, 0], [3.0, 0, 25, 0]] }
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
root.PREDATOR_ANIMS = ANIMS;
root.AnimEval = { evalJoint, sampleKeys };
})(typeof window !== 'undefined' ? window : globalThis);
