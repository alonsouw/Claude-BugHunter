// Genera roblox/ArmorData.lua (planos y estadísticas) y roblox/InstallArmor.lua.  Uso: node tools/build_roblox.js
const fs = require('fs'), path = require('path'), vm = require('vm');
const ROOT = path.join(__dirname, '..');
const ctx = {}; vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(ROOT, 'src/armor_blueprints.js'), 'utf8'), ctx);
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
const D = ctx.ARMOR_DUMMY;
const data = {
  dummy: Object.fromEntries(Object.entries(D.parts).map(([k, p]) => [k, p.size])),
  dummyParts: D.parts,
  sets: ctx.ARMOR_SETS,
  stats: ctx.ARMOR_STATS,
};
const dataLua = `--[[
	ArmorData (ModuleScript) · ReplicatedStorage.Armor.ArmorData
	Planos de las armaduras (piezas por parte del cuerpo R15) y estadísticas. Generado desde src/armor_blueprints.js.
	stats: Reduction = parte del daño que se devuelve (0,45 = −45 %), Speed = suma a WalkSpeed. Se pueden editar aquí.
]]
return ${lua(data)}
`;
fs.writeFileSync(path.join(ROOT, 'roblox/ArmorData.lua'), dataLua);
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
const sources = { __DATA__: dataLua, __BUILDER__: read('roblox/ArmorBuilder.lua'), __SERVICE__: read('roblox/ArmorService.server.lua') };
for (const [k, s] of Object.entries(sources)) if (s.includes(']=======]')) throw new Error(k);
let out = read('tools/InstallArmor.template.lua');
for (const [k, s] of Object.entries(sources)) out = out.replace(k, () => '\n' + s);
fs.writeFileSync(path.join(ROOT, 'roblox/InstallArmor.lua'), out);
console.log('ArmorData.lua e InstallArmor.lua generados (' + out.split('\n').length + ' líneas) · piezas: ' + Object.entries(ctx.ARMOR_SETS).map(([k, s]) => k + ' ' + s.pieces.length).join(', '));
