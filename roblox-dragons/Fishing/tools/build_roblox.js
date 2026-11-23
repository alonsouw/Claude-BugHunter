// Genera roblox/InstallFishing.lua a partir de src/fishing_blueprints.js, los scripts de roblox/ y la plantilla.
// Uso: node tools/build_roblox.js
const fs = require('fs'), path = require('path'), vm = require('vm');
const ROOT = path.join(__dirname, '..');
const ctx = {}; vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(ROOT, 'src/fishing_blueprints.js'), 'utf8'), ctx);
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
const models = Object.fromEntries(Object.entries(ctx.FISHING_MODELS).map(([k, list]) => [k, list.map(b => ({ name: b.name, size: b.size, offset: b.offset, rot: b.rot, color: b.color, material: b.material }))]));
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
const sources = { __LOGIC__: read('roblox/FishingLogic.lua'), __SERVICE__: read('roblox/FishingService.server.lua'),
  __RODCLIENT__: read('roblox/FishingRodClient.client.lua'), __HUD__: read('roblox/FishingHud.client.lua') };
for (const [k, s] of Object.entries(sources)) if (s.includes(']=======]')) throw new Error('el código de ' + k + ' contiene el cierre de cadena larga');
let out = read('tools/InstallFishing.template.lua').replace('__MODELS__', () => lua(models)).replace('__SPECIES__', () => lua(ctx.FISHING_SPECIES));
for (const [k, s] of Object.entries(sources)) out = out.replace(k, () => '\n' + s);
fs.writeFileSync(path.join(ROOT, 'roblox/InstallFishing.lua'), out);
console.log('InstallFishing.lua generado (' + out.split('\n').length + ' líneas) · piezas: ' + Object.entries(models).map(([k, l]) => k + ' ' + l.length).join(', '));
