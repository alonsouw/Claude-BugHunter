// Prueba de CureLogic con luau, sin Roblox: receta, botín de cada criatura, noche, preparación y el jefe dragón.
// Uso: node tools/test_logic.js /ruta/a/luau
const fs = require('fs'), path = require('path'), os = require('os'), vm = require('vm'), { execFileSync } = require('child_process');
const ROOT = path.join(__dirname, '..');
const ctx = {}; vm.createContext(ctx); vm.runInContext(fs.readFileSync(path.join(ROOT, 'src/cure_blueprints.js'), 'utf8'), ctx);
const recipe = ctx.CURE_RECIPE.map(r => `{ id = "${r.id}", need = ${r.need} }`).join(', ');
const items = Object.keys(ctx.CURE_ITEMS);
let jsFails = 0;
for (const r of ctx.CURE_RECIPE) if (!items.includes(r.id)) { jsFails++; console.log('FALLO: falta el modelo de ' + r.id); }
if (!items.includes('Remedy')) { jsFails++; console.log('FALLO: falta el modelo del remedio'); }
const src = fs.readFileSync(path.join(ROOT, 'roblox/CureLogic.lua'), 'utf8').replace(/: (string|boolean|number)/g, '');
const test = `
local L = (function() ${src} end)()
local fails = 0
local function check(c, m) if not c then fails += 1; print("FALLO: " .. m) end end
local recipe = { ${recipe} }
-- 1) receta: no se puede echar de más; se completa con todo
local p = {}
check(L.Remaining(p, recipe, "Moonflower") == 3, "faltan 3 flores al empezar")
check(L.Add(p, recipe, "Moonflower") and L.Add(p, recipe, "Moonflower") and L.Add(p, recipe, "Moonflower"), "no se pudieron echar 3 flores")
check(not L.Add(p, recipe, "Moonflower"), "se pudo echar una cuarta flor")
check(not L.Add(p, recipe, "Nada"), "se echó algo que no está en la receta")
check(not L.Complete(p, recipe), "completa sin todo")
for _, r in ipairs(recipe) do while L.Remaining(p, recipe, r.id) > 0 do L.Add(p, recipe, r.id) end end
local done, total = L.Count(p, recipe)
check(L.Complete(p, recipe) and done == total and total == 7, "no se completó con todo")
-- 2) botín: cada criatura suelta lo suyo y solo eso
check(L.DropFor("boss", {}) == "DragonSaliva", "el dragón no suelta saliva")
check(L.DropFor("wolf", { alpha = true }) == "AlphaFang" and L.DropFor("wolf", { variant = "Alpha" }) == "AlphaFang", "el alfa no suelta colmillo")
check(L.DropFor("wolf", { variant = "Normal" }) == nil, "un lobo normal suelta colmillo")
check(L.DropFor("deerForm", { form = "creature" }) == "CursedAntler" and L.DropFor("deerForm", { form = "deer" }) == nil, "asta maldita mal")
check(L.DropFor("infected", { name = "Brute" }) == "BruteHeart" and L.DropFor("infected", { name = "Walker" }) == nil, "corazón del bruto mal")
check(L.DropFor("fish", { name = "Giant" }) == "BlackPearl" and L.DropFor("fish", { name = "Normal" }) == nil, "perla negra mal")
check(L.DropFor("custom", { cureDrop = "BloodRoot" }) == "BloodRoot", "el atributo CureDrop no manda")
-- 3) noche
check(L.IsNight(22) and L.IsNight(3) and not L.IsNight(12) and not L.IsNight(18), "la noche está mal")
-- 4) preparación: solo con todo; tarda lo que tiene que tardar; se usa una vez
local b = L.Brew.new(90)
check(not b:Start(0), "se empezó sin ingredientes")
b:SetReady(true)
check(b:Start(10) and b.state == "Brewing", "no empezó a prepararse")
check(not b:Update(50) and math.abs(b:Fraction(55) - 0.5) < 1e-9, "fracción mal a mitad")
check(b:Update(100) and b.state == "Done" and not b:Update(101), "no terminó a los 90 s (o terminó dos veces)")
check(b:Use() and not b:Use(), "la cura se pudo usar dos veces")
-- 5) jefe: ruge al verte, persigue, ataca a su alcance con recarga, vuelve a casa si te alejas, muere una vez
local boss = L.Boss.new({ Cooldown = 2.8 })
local t, roars, attacks, homes, lastA, okGap = 0, 0, 0, 0, -10, true
local function step(P) t += 0.1; for _, o in ipairs(boss:Update(0.1, P)) do
	if o[1] == "sound" and o[2] == "Roar" then roars += 1 end
	if o[1] == "attack" then attacks += 1; if t - lastA < 2.8 - 1e-6 then okGap = false end; lastA = t end
	if o[1] == "move" and o[2] == "home" then homes += 1 end end end
for _ = 1, 50 do step({ hasTarget = true, dist = 200, fromHome = 0, targetFromHome = 200, dead = false }) end
check(roars == 0 and boss.state == "Idle", "reaccionó a alguien lejos")
for _ = 1, 30 do step({ hasTarget = true, dist = 40, fromHome = 0, targetFromHome = 30, dead = false }) end
check(roars == 1 and boss.state == "Chase", "no rugió y persiguió al verte")
for _ = 1, 200 do step({ hasTarget = true, dist = 8, fromHome = 10, targetFromHome = 20, dead = false }) end
check(attacks >= 6 and okGap, "ataques mal (" .. attacks .. ")")
for _ = 1, 20 do step({ hasTarget = true, dist = 60, fromHome = 30, targetFromHome = 120, dead = false }) end
check(homes >= 1 and boss.state == "Return", "no volvió a su guarida")
local d1 = boss:Update(0.1, { dead = true }); local d2 = boss:Update(0.1, { dead = true, hasTarget = true, dist = 1 })
check(boss.state == "Dead" and #d1 >= 2 and #d2 == 0, "la muerte del jefe no es definitiva")
print(fails == 0 and "OK: receta, botín, noche, preparación y jefe dragón" or ("FALLOS: " .. fails))
if fails > 0 then error("fallos") end
`;
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'cure-')); const f = path.join(dir, 't.luau'); fs.writeFileSync(f, test);
try { process.stdout.write(execFileSync(process.argv[2] || 'luau', [f], { encoding: 'utf8' })); } catch (e) { process.stdout.write((e.stdout || '') + (e.stderr || '')); process.exit(1); }
if (jsFails) process.exit(1);
console.log('OK: cada ingrediente de la receta tiene su modelo');
