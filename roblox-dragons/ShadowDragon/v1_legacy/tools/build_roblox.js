// Genera roblox/ShadowAnimations.lua y roblox/InstallShadow.lua a partir de
// src/shadow_anims.js, model/rig.json y la plantilla del instalador.
// Uso: node tools/build_roblox.js
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const ctx = {}; vm.createContext(ctx);
vm.runInContext(fs.readFileSync(path.join(ROOT, 'src/shadow_anims.js'), 'utf8'), ctx);
const ANIMS = ctx.SHADOW_ANIMS;
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
	Animaciones del Dragón Sombrío (ModuleScript) · ReplicatedStorage.Dragons.ShadowDragon.Animations
	Generado desde src/shadow_anims.js con tools/build_roblox.js: edita la fuente y regenera.
	Formato: ver DragonAnimator. Ángulos en grados, traslaciones en studs, tiempos en segundos.
]]
return ${lua(ANIMS)}
`;
fs.writeFileSync(path.join(ROOT, 'roblox/ShadowAnimations.lua'), animsLua);

const rigLua = '{\n' + rig.bones.map(b => `\t{ name = ${JSON.stringify(b.name)}, parent = ${b.parent ? JSON.stringify(b.parent) : 'nil'}, head = ${lua(b.head)}, tail = ${lua(b.tail)} },`).join('\n') + '\n}';
const eyesLua = `{ EyeL = ${lua(rig.eyes.EyeL)}, EyeR = ${lua(rig.eyes.EyeR)}, bone = ${JSON.stringify(rig.eyes.bone)} }`;
const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
// el animador es común a todas las especies: se copia desde shared/
fs.copyFileSync(path.join(ROOT, '..', 'shared', 'DragonAnimator.lua'), path.join(ROOT, 'roblox', 'DragonAnimator.lua'));
const sources = { __ANIMATOR__: read('roblox/DragonAnimator.lua'), __ANIMS__: animsLua, __SHOWCASE__: read('roblox/ShadowShowcase.client.lua') };
for (const [k, s] of Object.entries(sources)) if (s.includes(']=======]')) throw new Error('el código de ' + k + ' contiene el cierre de cadena larga');
let out = read('tools/InstallShadow.template.lua')
  .replace('__RIG__', () => rigLua)
  .replace('__EYES__', () => eyesLua)
  .replace('__GROUND_Y__', () => num(rig.bounds.min[1]));
for (const [k, s] of Object.entries(sources)) out = out.replace(k, () => '\n' + s);
fs.writeFileSync(path.join(ROOT, 'roblox/InstallShadow.lua'), out);
console.log('ShadowAnimations.lua y InstallShadow.lua generados (' + out.split('\n').length + ' líneas)');
