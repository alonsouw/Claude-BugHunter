// Prueba de WolfBrain con luau, sin Roblox: aullido del alfa, cerco, mordiscos por turnos, luz, día, heridas y muerte.
// Uso: node tools/test_brain.js /ruta/a/luau
const fs = require('fs'), path = require('path'), os = require('os'), { execFileSync } = require('child_process');
const ROOT = path.join(__dirname, '..');
const src = fs.readFileSync(path.join(ROOT, 'roblox/WolfBrain.lua'), 'utf8');
const test = `
local Random = {}
Random.__index = Random
function Random.new(seed) return setmetatable({ s = seed or 12345 }, Random) end
function Random:NextNumber() self.s = (self.s * 1103515245 + 12345) % 2147483648; return self.s / 2147483648 end
function Random:NextInteger(a, b) return a + math.floor(self:NextNumber() * (b - a + 1)) end
local Brain = (function() ${src} end)()
local fails = 0
local function check(c, m) if not c then fails += 1; print("FALLO: " .. m) end end

-- manada simulada: 1 alfa + 3 lobos; el jugador se acerca y se queda; como máximo 2 muerden a la vez
local function pack(seconds, scene, seed)
	local wolves = {}
	for i = 1, 4 do wolves[i] = { b = Brain.new({}, Random.new(seed * 10 + i), i == 1), dist = 120, hp = 1, speed = 0, mode = "stop", bites = 0, anims = {} } end
	local alerted, howls, maxAttacking, bitesInLight, despawned, deaths = false, 0, 0, 0, 0, 0
	local t = 0
	while t < seconds do
		t += 0.1
		local env = scene(t)
		local attacking = 0
		for _, w in ipairs(wolves) do if w.b.state == "Attack" then attacking += 1 end end
		maxAttacking = math.max(maxAttacking, attacking)
		for i, w in ipairs(wolves) do
			local hurt = env.hit == i and t % 1 < 0.1
			if hurt then w.hp -= env.dmg or 0.3 end
			local P = { dist = env.dist or w.dist, hasTarget = true, canAttack = attacking < 2, inLight = env.wolfLight or false, targetInLight = env.light or false,
				day = env.day or false, alerted = alerted, health = w.hp, hurt = hurt, dead = w.hp <= 0 }
			for _, c in ipairs(w.b:Update(0.1, P)) do
				if c[1] == "alert" then alerted = true; howls += 1 end
				if c[1] == "bite" then w.bites += 1; if env.light then bitesInLight += 1 end end
				if c[1] == "anim" then w.anims[c[2]] = (w.anims[c[2]] or 0) + 1; if c[2] == "Attack" then attacking += 1 end; if c[2] == "Death" then deaths += 1 end end
				if c[1] == "despawn" then despawned += 1 end
				if c[1] == "move" then w.speed, w.mode = c[2], c[3] end
			end
		end
	end
	return { wolves = wolves, howls = howls, maxAttacking = maxAttacking, bitesInLight = bitesInLight, despawned = despawned, deaths = deaths, alerted = alerted }
end

-- 1) jugador lejos: no cazan
local r1 = pack(30, function() return { dist = 200 } end, 1)
check(not r1.alerted and r1.howls == 0, "cazaron a un jugador a 200 studs")
-- 2) jugador a 50 y luego a 8: el alfa aúlla una vez, rodean y muerden, nunca más de 2 a la vez
local r2 = pack(60, function(t) return { dist = t < 5 and 50 or 5 } end, 2)
check(r2.howls == 1, "el alfa no aulló exactamente una vez (" .. r2.howls .. ")")
local totalBites = 0
for _, w in ipairs(r2.wolves) do totalBites += w.bites; check((w.anims.Growl or 0) > 0, "un lobo no gruñó en el cerco") end
check(totalBites >= 6, "casi no muerden (" .. totalBites .. ")")
check(r2.maxAttacking <= 2, "mordían más de 2 a la vez (" .. r2.maxAttacking .. ")")
-- 3) el jugador está en la luz de la hoguera: lo rodean pero nunca muerden
local r3 = pack(40, function(t) return { dist = t < 5 and 50 or 5, light = t > 5 } end, 3)
check(r3.bitesInLight == 0, "mordieron dentro de la luz")
-- 4) si la luz alcanza al lobo, huye
local r4 = pack(10, function(t) return { dist = 12, wolfLight = t > 3 } end, 4)
check((r4.wolves[2].anims.Run or 0) > 0, "no huyó de la luz")
-- 5) de día se retiran y desaparecen todos
local r5 = pack(15, function(t) return { dist = 10, day = t > 2 } end, 5)
check(r5.despawned == 4, "de día no desaparecieron los 4 (" .. r5.despawned .. ")")
-- 6) heridas: se encoge, con poca vida huye, y al llegar a 0 muere una sola vez
local r6 = pack(20, function(t) return { dist = 8, hit = 2, dmg = 0.3 } end, 6)
local w2 = r6.wolves[2]
check((w2.anims.Hurt or 0) >= 1, "no reaccionó al daño")
check((w2.anims.Run or 0) >= 1, "con poca vida no huyó")
check(r6.deaths == 1 and w2.b.state == "Dead", "no murió exactamente una vez")
-- 7) tipos: el pálido es silencioso (no gruñe ni ruge) y el sarnoso huye antes que el normal
do
	local function sounds(cfg)
		local b = Brain.new(cfg, Random.new(77), false); local n = 0
		for i = 1, 600 do
			for _, c in ipairs(b:Update(0.1, { dist = i < 30 and 50 or 6, hasTarget = true, canAttack = true, inLight = false, targetInLight = false, day = false, alerted = true, health = 1, hurt = false, dead = false })) do
				if c[1] == "sound" and (c[2] == "Growl" or c[2] == "Snarl") then n += 1 end
			end
		end
		return n
	end
	check(sounds({ Silent = true }) == 0 and sounds({}) > 0, "el pálido hizo ruido (o el normal no)")
	local function fleesAt(cfg)
		local b = Brain.new(cfg, Random.new(5), false)
		b:Update(0.1, { dist = 6, hasTarget = true, canAttack = false, inLight = false, targetInLight = false, day = false, alerted = true, health = 1, hurt = false, dead = false })
		local fled = false
		for _, c in ipairs(b:Update(0.1, { dist = 6, hasTarget = true, canAttack = false, inLight = false, targetInLight = false, day = false, alerted = true, health = 0.4, hurt = true, dead = false })) do
			if c[1] == "anim" and c[2] == "Run" then fled = true end
		end
		return fled
	end
	check(fleesAt({ FleeHealth = 0.5 }) and not fleesAt({ FleeHealth = 0.25 }), "con 40 % de vida el sarnoso no huye o el normal sí")
end
print(("cerco: %d mordiscos, máx. %d a la vez; luz: %d mordiscos; día: %d desaparecen; muertes: %d"):format(totalBites, r2.maxAttacking, r3.bitesInLight, r5.despawned, r6.deaths))
print(fails == 0 and "OK: la manada cumple las reglas" or ("FALLOS: " .. fails))
if fails > 0 then error("fallos") end
`;
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'wolf-')); const f = path.join(dir, 't.luau'); fs.writeFileSync(f, test);
try { process.stdout.write(execFileSync(process.argv[2] || 'luau', [f], { encoding: 'utf8' })); } catch (e) { process.stdout.write((e.stdout || '') + (e.stderr || '')); process.exit(1); }
