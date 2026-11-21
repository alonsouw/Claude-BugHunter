// Prueba de InfectedBrain con luau, sin Roblox: detección, persecución, recarga de ataques, grito, golpe del bruto,
// pérdida del objetivo, daño y muerte.  Uso: node tools/test_brain.js /ruta/a/luau
const fs = require('fs'), path = require('path'), os = require('os'), { execFileSync } = require('child_process');
const ROOT = path.join(__dirname, '..');
const src = fs.readFileSync(path.join(ROOT, 'roblox/InfectedBrain.lua'), 'utf8');
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
	local r = { anims = {}, attacks = {}, screams = 0, chaseT = nil, modes = {} }
	local t = 0
	while t < seconds do
		t += 0.2
		local P = scene(t, b)
		for _, c in ipairs(b:Update(0.2, P)) do
			if c[1] == "anim" then r.anims[c[2]] = (r.anims[c[2]] or 0) + 1 end
			if c[1] == "attack" then table.insert(r.attacks, { t = t, kind = c[2], d = P.dist }) end
			if c[1] == "scream" then r.screams += 1 end
			if c[1] == "move" then r.modes[c[2]] = (r.modes[c[2]] or 0) + 1; if c[2] == "chase" and not r.chaseT then r.chaseT = t end end
		end
	end
	return r, b
end
local base = function(dist, see) return { dist = dist, hasTarget = true, canSee = see, alerted = false, health = 1, hurt = false, dead = false } end
-- 1) lejos o sin verte: no persigue
local r1 = run({}, 30, function() return base(120, true) end)
check(r1.chaseT == nil, "persiguió a alguien fuera de su detección")
local r1b = run({}, 30, function() return base(30, false) end)
check(r1b.chaseT == nil, "persiguió sin verte")
-- 2) te ve: persigue; al alcance ataca respetando la recarga
local r2 = run({ Cooldown = 1.4 }, 30, function(t) return base(t < 5 and 30 or 3, true) end)
check(r2.chaseT ~= nil and r2.chaseT < 6, "no empezó a perseguir al verte")
check(#r2.attacks >= 8, "casi no ataca (" .. #r2.attacks .. ")")
for i = 2, #r2.attacks do check(r2.attacks[i].t - r2.attacks[i - 1].t >= 1.39, "ataques más rápido que la recarga") end
for _, a in ipairs(r2.attacks) do check(a.d <= 4, "atacó fuera de su alcance") end
-- 3) gritón: grita una vez al verte (recarga 25 s) y después corre
local r3 = run({ CanScream = true, ScreamCooldown = 25, ChaseAnim = "Run" }, 20, function(t) return base(40, true) end)
check(r3.screams == 1 and (r3.anims.Run or 0) >= 1, "el gritón no gritó una vez y luego corrió")
-- 4) alertado por un grito: persigue aunque no te vea
local r4 = run({}, 10, function() local P = base(70, false); P.alerted = true; return P end)
check(r4.chaseT ~= nil, "no acudió al grito")
-- 5) bruto: golpe al suelo con su animación
local r5 = run({ AttackAnim = "Slam", Reach = 7, Cooldown = 2.6 }, 20, function() return base(5, true) end)
check(#r5.attacks > 0 and r5.attacks[1].kind == "slam" and (r5.anims.Slam or 0) > 0, "el bruto no golpeó el suelo")
-- 6) lo pierde: vuelve a vagar
local r6, b6 = run({ LoseTime = 8, Detect = 55 }, 40, function(t) return base(t < 3 and 20 or 120, t < 3) end)
check(b6.state == "Wander" or b6.state == "Idle", "no dejó de perseguir al perderte (" .. b6.state .. ")")
-- 7) daño y muerte
local r7, b7 = run({}, 6, function(t) local P = base(20, true); P.hurt = t > 2 and t < 2.3; P.dead = t > 4; return P end)
check((r7.anims.Hurt or 0) == 1 and (r7.anims.Death or 0) == 1 and b7.state == "Dead", "no reaccionó al daño o no murió una vez")
print(("ataques: %d (recarga respetada); gritos: %d; golpe del bruto: %s"):format(#r2.attacks, r3.screams, r5.attacks[1] and r5.attacks[1].kind or "-"))
print(fails == 0 and "OK: los infectados cumplen las reglas" or ("FALLOS: " .. fails))
if fails > 0 then error("fallos") end
`;
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'inf-')); const f = path.join(dir, 't.luau'); fs.writeFileSync(f, test);
try { process.stdout.write(execFileSync(process.argv[2] || 'luau', [f], { encoding: 'utf8' })); } catch (e) { process.stdout.write((e.stdout || '') + (e.stderr || '')); process.exit(1); }
