// Genera roblox/WolfAnimations.lua y roblox/InstallWolves.lua a partir de src/wolf_anims.js,
// model/rig.json (las animaciones de la criatura dependen del esqueleto) y la plantilla del instalador.
// Uso: node tools/build_roblox.js
const fs = require('fs'), path = require('path'), vm = require('vm');
const ROOT = path.join(__dirname, '..');
const ctx = {}; vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(ROOT, 'src/wolf_anims.js'), 'utf8'), ctx);
const rig = JSON.parse(fs.readFileSync(path.join(ROOT, 'model/rig.json'), 'utf8'));
const ANIMS = ctx.WOLF_ANIMS;

const num = n => { const s = (+n.toFixed(4)).toString(); return s === '-0' ? '0' : s; };
function lua(v, ind = '') {
  if (v === null || v === undefined) return 'nil';
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'string') return JSON.stringify(v);
  if (Array.isArray(v)) return v.every(x => typeof x !== 'object') ? `{ ${v.map(x => lua(x)).join(', ')} }` : `{\n${v.map(x => ind + '\t' + lua(x, ind + '\t')).join(',\n')},\n${ind}}`;
  const keys = Object.keys(v).filter(k => v[k] !== undefined);
  return `{\n${keys.map(k => `${ind}\t${/^[A-Za-z_]\w*$/.test(k) ? k : `[${JSON.stringify(k)}]`} = ${lua(v[k], ind + '\t')}`).join(',\n')},\n${ind}}`;
}
const animsLua = `--[[
	Animaciones del lobo hueco (ModuleScript) · ReplicatedStorage.Creatures.HollowWolf.Animations
	Generado desde src/wolf_anims.js y model/rig.json con tools/build_roblox.js: edita la fuente y regenera.
	Formato: ver DragonAnimator. Ángulos en grados, traslaciones en studs, tiempos en segundos.
]]
return ${lua(ANIMS)}
`;
fs.writeFileSync(path.join(ROOT, 'roblox/WolfAnimations.lua'), animsLua);
const rigLua = '{\n' + rig.bones.map(b => `\t{ name = ${JSON.stringify(b.name)}, parent = ${b.parent ? JSON.stringify(b.parent) : 'nil'}, head = ${lua(b.head)}, tail = ${lua(b.tail)} },`).join('\n') + '\n}';
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
fs.copyFileSync(path.join(ROOT, '..', 'shared', 'DragonAnimator.lua'), path.join(ROOT, 'roblox', 'DragonAnimator.lua'));
const sources = { __ANIMATOR__: read('roblox/DragonAnimator.lua'), __ANIMS__: animsLua, __BRAIN__: read('roblox/WolfBrain.lua'),
  __PACK__: read('roblox/WolfPack.server.lua'), __CLIENT__: read('roblox/WolfClient.client.lua') };
for (const [k, s] of Object.entries(sources)) if (s.includes(']=======]')) throw new Error('el código de ' + k + ' contiene el cierre de cadena larga');
let out = read('tools/InstallWolves.template.lua').replace('__RIG__', () => rigLua).replace('__EYES__', () => '{ ' + rig.eyes.map(e => lua(e)).join(', ') + ' }');
for (const [k, s] of Object.entries(sources)) out = out.replace(k, () => '\n' + s);
fs.writeFileSync(path.join(ROOT, 'roblox/InstallWolves.lua'), out);
console.log('WolfAnimations.lua y InstallWolves.lua generados (' + out.split('\n').length + ' líneas)');
