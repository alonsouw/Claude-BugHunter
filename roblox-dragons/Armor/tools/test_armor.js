// Prueba de ArmorBuilder (funciones puras) con luau: reparto R15 → R6 y reducción de daño; y de los planos.
// Uso: node tools/test_armor.js /ruta/a/luau
const fs = require('fs'), path = require('path'), os = require('os'), vm = require('vm'), { execFileSync } = require('child_process');
const ROOT = path.join(__dirname, '..');
const ctx = {}; vm.createContext(ctx); vm.runInContext(fs.readFileSync(path.join(ROOT, 'src/armor_blueprints.js'), 'utf8'), ctx);
let fails = 0; const check = (c, m) => { if (!c) { fails++; console.log('FALLO: ' + m); } };
const parts = Object.keys(ctx.ARMOR_DUMMY.parts);
for (const [name, set] of Object.entries(ctx.ARMOR_SETS)) {
  const covered = new Set(set.pieces.map(p => p.part));
  for (const p of set.pieces) check(parts.includes(p.part), `${name}: parte desconocida ${p.part}`);
  for (const p of parts) if (!(set.bare || []).includes(p)) check(covered.has(p), `${name}: no cubre ${p}`);
  for (const p of parts) if (p.startsWith('Right')) check(covered.has(p) === covered.has(p.replace('Right', 'Left')), `${name}: ${p} sin su pareja izquierda`);
  for (const p of set.pieces) check(p.size.every(v => v > 0), `${name}: pieza con tamaño no positivo`);
}
const src = fs.readFileSync(path.join(ROOT, 'roblox/ArmorBuilder.lua'), 'utf8').replace(/: (string|boolean|number)/g, '').replace(/\): number/g, ')');
const test = `
local script = { Parent = {} }
local AB = (function() ${src} end)()
local fails = 0
local function check(c, m) if not c then fails += 1; print("FALLO: " .. m) end end
-- R15: cada parte va a sí misma
local n, y, s = AB.Region("LeftLowerArm", false); check(n == "LeftLowerArm" and y == 0 and s == 1, "R15 no es identidad")
-- R6: el brazo R15 (1,169 + 1,052 + 0,3) se reparte a lo largo del brazo R6 (2 studs), de arriba abajo, sin huecos
local tot = 0
local prevBottom = 1
for _, p in ipairs({ "RightUpperArm", "RightLowerArm", "RightHand" }) do
	local r6, cy, sy = AB.Region(p, true)
	check(r6 == "Right Arm", p .. " no cae en Right Arm")
	local h = ({ RightUpperArm = 1.169, RightLowerArm = 1.052, RightHand = 0.3 })[p] * sy
	check(math.abs((cy + h / 2) - prevBottom) < 1e-6, p .. " deja un hueco")
	prevBottom = cy - h / 2; tot += h
end
check(math.abs(tot - 2) < 1e-6 and math.abs(prevBottom + 1) < 1e-6, "el brazo R6 no queda cubierto de -1 a 1")
local r6, cy = AB.Region("UpperTorso", true); check(r6 == "Torso" and math.abs(cy - 0.2) < 1e-6, "UpperTorso en R6 mal colocado")
check(AB.Region("Nope", true) == nil, "parte desconocida en R6 debería ser nil")
-- reducción de daño: devuelve el porcentaje de la vida perdida; no cura si no hubo daño; tope del 95 %
check(math.abs(AB.Refund(100, 80, 0.45) - 89) < 1e-9, "dragón: de 20 de daño deberían quedar 11")
check(AB.Refund(80, 100, 0.45) == 100, "curarse no debe cambiar")
check(math.abs(AB.Refund(100, 0, 0.15) - 15) < 1e-9, "cuero: un golpe de 100 deja 15")
check(math.abs(AB.Refund(100, 50, 2) - 97.5) < 1e-9, "la reducción debe tener tope 95 %")
print(fails == 0 and "OK: reparto R6 y reducción de daño" or ("FALLOS: " .. fails))
if fails > 0 then error("fallos") end
`;
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'armor-')); const f = path.join(dir, 't.luau'); fs.writeFileSync(f, test);
try { process.stdout.write(execFileSync(process.argv[2] || 'luau', [f], { encoding: 'utf8' })); } catch (e) { process.stdout.write((e.stdout || '') + (e.stderr || '')); process.exit(1); }
console.log(fails === 0 ? 'OK: los planos cubren todas las partes y son simétricos' : 'FALLOS en planos: ' + fails);
if (fails) process.exit(1);
