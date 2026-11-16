// Genera roblox/AberrantAnimations.lua y roblox/InstallAberrant.lua a partir de
// src/aberrant_anims.js, model/rig.json y la plantilla del instalador.
// Uso: node tools/build_roblox.js
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const ctx = {}; vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(ROOT, 'src/aberrant_anims.js'), 'utf8'), ctx);
const ANIMS = ctx.ABERRANT_ANIMS;
const rig = JSON.parse(fs.readFileSync(path.join(ROOT, 'model/rig.json'), 'utf8'));

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
	Animaciones del Dragón Aberrante (ModuleScript) · ReplicatedStorage.Dragons.AberrantDragon.Animations
	Generado desde src/aberrant_anims.js con tools/build_roblox.js: edita la fuente y regenera.
	Formato: ver DragonAnimator. Ángulos en grados, traslaciones en studs, tiempos en segundos.
]]
return ${lua(ANIMS)}
`;
fs.writeFileSync(path.join(ROOT, 'roblox/AberrantAnimations.lua'), animsLua);

const rigLua = '{\n' + rig.parts.map(p => `\t{ name = ${JSON.stringify(p.name)}, parent = ${p.parent ? JSON.stringify(p.parent) : 'nil'}, pivot = ${lua(p.pivot)}, center = ${lua(p.center)} },`).join('\n') + '\n}';
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
const sources = { __ANIMATOR__: read('roblox/DragonAnimator.lua'), __ANIMS__: animsLua, __SHOWCASE__: read('roblox/DragonShowcase.client.lua') };
for (const [k, s] of Object.entries(sources)) if (s.includes(']=======]')) throw new Error('el código de ' + k + ' contiene el cierre de cadena larga');
let out = read('tools/InstallAberrant.template.lua')
  .replace('__RIG__', () => rigLua)
  .replace('__GROUND_Y__', () => num(rig.bounds.min[1]));
for (const [k, s] of Object.entries(sources)) out = out.replace(k, () => '\n' + s);
fs.writeFileSync(path.join(ROOT, 'roblox/InstallAberrant.lua'), out);
console.log('AberrantAnimations.lua y InstallAberrant.lua generados (' + out.split('\n').length + ' líneas)');
