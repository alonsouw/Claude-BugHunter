// Prueba de FishBrain con luau, sin Roblox: detección en el agua, chillido, vueltas, embestida, mordiscos con recarga,
// el gigante embiste sin rodear, salto a la orilla con recarga, pérdida del objetivo, daño y muerte.
// Uso: node tools/test_brain.js /ruta/a/luau
const fs = require('fs'), path = require('path'), os = require('os'), { execFileSync } = require('child_process');
const ROOT = path.join(__dirname, '..');
const src = fs.readFileSync(path.join(ROOT, 'roblox/FishBrain.lua'), 'utf8');
const test = `
local Random = {}
Random.__index = Random
function Random.new(seed) return setmetatable({ s = seed or 12345 }, Random) end
function Random:NextNumber() self.s = (self.s * 1103515245 + 12345) % 2147483648; return self.s / 2147483648 end
function Random:NextInteger(a, b) return a + math.floor(self:NextNumber() * (b - a + 1)) end
local Brain = (function() ${src} end)()
local fails = 0
local function check(c, m) if not c then fails += 1; print("FALLO: " .. m) end end
local function run(cfg, seconds, scene, seed)
	local b = Brain.new(cfg or {}, Random.new(seed or 3))
	local r = { anims = {}, attacks = {}, leaps = {}, sounds = {}, modes = {}, first = {} }
	local t = 0
	while t < seconds do
		t += 0.1
		local P = scene(t, b)
		for _, c in ipairs(b:Update(0.1, P)) do
			if c[1] == "anim" then r.anims[c[2]] = (r.anims[c[2]] or 0) + 1; r.first[c[2]] = r.first[c[2]] or t end
			if c[1] == "attack" then table.insert(r.attacks, { t = t, d = P.dist }) end
			if c[1] == "leap" then table.insert(r.leaps, t) end
			if c[1] == "sound" then r.sounds[c[2]] = (r.sounds[c[2]] or 0) + 1 end
			if c[1] == "move" then r.modes[c[2]] = (r.modes[c[2]] or 0) + 1; r.first["m_" .. c[2]] = r.first["m_" .. c[2]] or t end
		end
	end
	return r, b
end
local none = function() return { hasTarget = false, inWater = false, canLeap = false, dist = math.huge, hurt = false, dead = false } end
local water = function(d) return { hasTarget = true, inWater = true, canLeap = false, dist = d, hurt = false, dead = false } end
local shore = function(d) return { hasTarget = true, inWater = false, canLeap = true, dist = d, hurt = false, dead = false } end
-- 1) sin nadie: nada a su aire, sin atacar ni saltar
local r1 = run({}, 30, none)
check(#r1.attacks == 0 and #r1.leaps == 0 and r1.first.m_chase == nil, "atacó o persiguió sin nadie")
-- 2) en el agua pero fuera de su detección: no te hace caso
local r2 = run({ Detect = 45 }, 30, function() return water(80) end)
check(r2.first.m_chase == nil and r2.first.Screech == nil, "reaccionó fuera de su detección")
-- 3) te ve en el agua: chilla una vez, rodea y luego embiste; muerde al alcance respetando la recarga
local r3 = run({ Cooldown = 1.2 }, 30, function(t) return water(t < 6 and 20 or 2.5) end)
check(r3.first.Screech and r3.first.Screech < 0.5, "no chilló al verte")
check((r3.sounds.Screech or 0) == 1, "chilló más de una vez en 30 s (recarga 20 s)")
check(r3.first.m_circle and r3.first.m_circle > r3.first.Screech, "no rodeó después de chillar")
check(r3.first.m_chase and r3.first.m_chase >= r3.first.m_circle + 2.4, "embistió antes de dar vueltas")
check(#r3.attacks >= 10, "casi no muerde (" .. #r3.attacks .. ")")
local okGap = true
for i = 2, #r3.attacks do if r3.attacks[i].t - r3.attacks[i - 1].t < 1.2 - 1e-6 then okGap = false end end
check(okGap, "mordió sin respetar la recarga")
for _, a in ipairs(r3.attacks) do check(a.d <= 3.5, "mordió fuera de su alcance") end
-- 4) el gigante no rodea: embiste directo tras el chillido
local r4 = run({ Circle = false }, 10, function() return water(20) end)
check(r4.first.m_circle == nil and r4.first.m_chase and r4.first.m_chase < 1.6, "el gigante dio vueltas o tardó en embestir")
-- 5) en la orilla: salta, y no vuelve a saltar antes de su recarga
local r5 = run({ LeapCooldown = 7 }, 30, function() return shore(10) end)
check(#r5.leaps >= 3, "casi no salta a la orilla (" .. #r5.leaps .. ")")
local okLeap = true
for i = 2, #r5.leaps do if r5.leaps[i] - r5.leaps[i - 1] < 7 - 1e-6 then okLeap = false end end
check(okLeap, "saltó sin respetar la recarga")
check((r5.sounds.Splash or 0) == #r5.leaps, "no salpicó en cada salto")
-- 6) durante el salto no se interrumpe aunque le hagan daño
local r6, b6 = run({}, 0.4, function() return shore(10) end)
local P = shore(10); P.hurt = true
local o = b6:Update(0.1, P)
check(b6.state == "Leap", "el daño interrumpió el salto")
-- 7) sales del agua y no estás a su alcance de salto: tras perderte vuelve a nadar
local r7, b7 = run({ LoseTime = 6 }, 25, function(t) if t < 6 then return water(10) end return none() end)
check(b7.state == "Wander", "no volvió a nadar tras perderte (estado " .. b7.state .. ")")
-- 8) daño: reacciona; muerte: una sola vez y luego nada más
local _, b8 = run({}, 1, none)
local h = b8:Update(0.1, { hasTarget = false, inWater = false, canLeap = false, dist = math.huge, hurt = true, dead = false })
check(b8.state == "Hurt", "no reaccionó al daño")
local d1 = b8:Update(0.1, { hasTarget = false, dead = true, hurt = false })
local d2 = b8:Update(0.1, { hasTarget = true, inWater = true, dist = 1, dead = true, hurt = false })
check(b8.state == "Dead" and #d1 >= 2 and #d2 == 0, "la muerte no es definitiva")
print(fails == 0 and "OK: comportamiento del pez (8 escenarios)" or ("FALLOS: " .. fails))
if fails > 0 then error("fallos") end
`;
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'fishbrain-')); const f = path.join(dir, 't.luau'); fs.writeFileSync(f, test);
try { process.stdout.write(execFileSync(process.argv[2] || 'luau', [f], { encoding: 'utf8' })); } catch (e) { process.stdout.write((e.stdout || '') + (e.stderr || '')); process.exit(1); }
