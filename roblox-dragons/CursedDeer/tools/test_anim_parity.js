// Prueba: el intérprete Luau (DragonAnimator.EvalJoint) y el de JS (AnimEval.evalJoint)
// deben dar los mismos ángulos y traslaciones para todas las animaciones.
// Uso: node tools/test_anim_parity.js <ruta al ejecutable luau>
const fs = require('fs'), os = require('os'), path = require('path'), vm = require('vm'), { execFileSync } = require('child_process');
const ROOT = path.join(__dirname, '..');
const luau = process.argv[2];

const ctx = {}; vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(ROOT, 'src/deer_anims.js'), 'utf8'), ctx);
const ANIMS = ctx.makeDeerAnims(JSON.parse(fs.readFileSync(path.join(ROOT, 'model/rig.json'), 'utf8'))), E = ctx.AnimEval;
const TIMES = [0, 0.37, 0.9, 1.33, 1.71, 2.05, 2.7, 3.05, 4.4];

const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'parity-'));
// copia temporal del módulo con un stub de `game` (fuera de Roblox no existe); el código evaluado es el mismo
fs.writeFileSync(path.join(dir, 'DragonAnimator.luau'), 'local game = { GetService = function() return {} end }\n' + fs.readFileSync(path.join(ROOT, 'roblox/DragonAnimator.lua'), 'utf8'));
fs.copyFileSync(path.join(ROOT, 'roblox/DeerAnimations.lua'), path.join(dir, 'Anims.luau'));
fs.writeFileSync(path.join(dir, 'run.luau'), `

local A = require("./DragonAnimator")
local anims = require("./Anims")
local times = { ${TIMES.join(', ')} }
for name, a in pairs(anims) do
	for jname, j in pairs(a.joints) do
		for _, t in ipairs(times) do
			local r, p = A.EvalJoint(j, t, a.dur, a.loop)
			print(string.format("%s|%s|%s|%.9f|%.9f|%.9f|%.9f|%.9f|%.9f", name, jname, tostring(t), r[1], r[2], r[3], p[1], p[2], p[3]))
		end
	end
end`);
const lines = execFileSync(luau, ['run.luau'], { cwd: dir, encoding: 'utf8' }).trim().split('\n');

let checked = 0, worst = 0, fails = [];
for (const line of lines) {
  const [name, joint, t, ...vals] = line.split('|');
  const a = ANIMS[name], { r, p } = E.evalJoint(a.joints[joint], +t, a.dur, a.loop);
  const js = [...r, ...p];
  vals.map(Number).forEach((v, i) => { const d = Math.abs(v - js[i]); worst = Math.max(worst, d); if (d > 1e-6) fails.push(`${name}.${joint} t=${t} canal ${i}: luau ${v} js ${js[i]}`); });
  checked++;
}
const expected = Object.values(ANIMS).reduce((n, a) => n + Object.keys(a.joints).length * TIMES.length, 0);
console.log(`muestras comparadas: ${checked} de ${expected} · diferencia máxima: ${worst.toExponential(2)}`);
if (checked !== expected || fails.length) { console.log(fails.slice(0, 10).join('\n')); process.exit(1); }
console.log('OK: Luau y JS coinciden');
