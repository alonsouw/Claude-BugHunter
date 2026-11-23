// Genera roblox/Recipe.lua y roblox/InstallCure.lua a partir de src/cure_blueprints.js, los scripts y la plantilla.
// Uso: node tools/build_roblox.js
const fs = require('fs'), path = require('path'), vm = require('vm');
const ROOT = path.join(__dirname, '..');
const ctx = {}; vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(ROOT, 'src/cure_blueprints.js'), 'utf8'), ctx);
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
const recipeLua = `--[[
	Receta del Remedio del Alba (ModuleScript) · ReplicatedStorage.Cure.Recipe
	Generado desde src/cure_blueprints.js. Se puede editar aquí: need = cuántos hacen falta, hint = la pista del recetario.
]]
return ${lua(ctx.CURE_RECIPE)}
`;
fs.writeFileSync(path.join(ROOT, 'roblox/Recipe.lua'), recipeLua);
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
const sources = { __RECIPE__: recipeLua, __LOGIC__: read('roblox/CureLogic.lua'), __SERVICE__: read('roblox/CureService.server.lua'), __CLIENT__: read('roblox/CureClient.client.lua') };
for (const [k, s] of Object.entries(sources)) if (s.includes(']=======]')) throw new Error('el código de ' + k + ' contiene el cierre de cadena larga');
let out = read('tools/InstallCure.template.lua').replace('__ITEMS__', () => lua(ctx.CURE_ITEMS)).replace('__WORLD__', () => lua(ctx.CURE_WORLD));
for (const [k, s] of Object.entries(sources)) out = out.replace(k, () => '\n' + s);
fs.writeFileSync(path.join(ROOT, 'roblox/InstallCure.lua'), out);
console.log('Recipe.lua e InstallCure.lua generados (' + out.split('\n').length + ' líneas)');
