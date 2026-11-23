// Genera roblox/FishAnimations.lua y roblox/InstallFish.lua a partir de src/fish_anims.js, src/fish_blueprints.js
// y la plantilla del instalador.  Uso: node tools/build_roblox.js
const fs = require('fs'), path = require('path'), vm = require('vm');
const ROOT = path.join(__dirname, '..');
const ctx = {}; vm.createContext(ctx);
for (const f of ['src/fish_blueprints.js', 'src/fish_anims.js']) vm.runInContext(fs.readFileSync(path.join(ROOT, f), 'utf8'), ctx);
const ANIMS = ctx.FISH_ANIMS, BP = ctx.FISH_BLUEPRINTS, ST = ctx.FISH_STATS;
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
	Animaciones del pez infectado (ModuleScript) · ReplicatedStorage.Creatures.InfectedFish.Animations
	Generado desde src/fish_anims.js con tools/build_roblox.js: edita la fuente y regenera.
]]
return ${lua(ANIMS)}
`;
fs.writeFileSync(path.join(ROOT, 'roblox/FishAnimations.lua'), animsLua);
fs.copyFileSync(path.join(ROOT, '..', 'shared', 'DragonAnimator.lua'), path.join(ROOT, 'roblox', 'DragonAnimator.lua'));
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
const sources = { __ANIMATOR__: read('roblox/DragonAnimator.lua'), __ANIMS__: animsLua, __BRAIN__: read('roblox/FishBrain.lua'),
  __SPAWNER__: read('roblox/FishSpawner.server.lua'), __CLIENT__: read('roblox/FishClient.client.lua') };
for (const [k, s] of Object.entries(sources)) if (s.includes(']=======]')) throw new Error('el código de ' + k + ' contiene el cierre de cadena larga');
let out = read('tools/InstallFish.template.lua').replace('__BLUEPRINTS__', () => lua(BP)).replace('__STATS__', () => lua(ST));
for (const [k, s] of Object.entries(sources)) out = out.replace(k, () => '\n' + s);
fs.writeFileSync(path.join(ROOT, 'roblox/InstallFish.lua'), out);
const parts = Object.entries(BP).map(([k, b]) => k + ' ' + (Object.keys(b.limbs).length + b.details.length));
console.log('FishAnimations.lua e InstallFish.lua generados (' + out.split('\n').length + ' líneas) · piezas: ' + parts.join(', '));
