// Prueba de ShadowBrain (lógica del comportamiento) con el intérprete luau, sin Roblox.
// Simula un jugador y su mirada durante horas y comprueba las reglas del diseño.
// Uso: node tools/test_brain.js /ruta/a/luau
const fs = require('fs'), path = require('path'), os = require('os'), { execFileSync } = require('child_process');
const ROOT = path.join(__dirname, '..');
const luau = process.argv[2] || 'luau';
const brainSrc = fs.readFileSync(path.join(ROOT, 'roblox/ShadowBrain.lua'), 'utf8');

const shim = `
-- Random determinista (LCG) con la misma interfaz que Roblox
local Random = {}
Random.__index = Random
function Random.new(seed) return setmetatable({ s = seed or 12345 }, Random) end
function Random:NextNumber() self.s = (self.s * 1103515245 + 12345) % 2147483648; return self.s / 2147483648 end
function Random:NextInteger(a, b) return a + math.floor(self:NextNumber() * (b - a + 1)) end
`;
const tests = `
local Brain = (function() ${brainSrc.replace(/: Vector3/g, '').replace(/\): number/g, ')')} end)()
local fails = 0
local function check(cond, msg) if not cond then fails += 1; print("FALLO: " .. msg) end end

-- mundo simulado: distancia al objetivo, ángulo de su mirada y si alguien lo ve
local function sim(seed, seconds, policy)
	local b = Brain.new({}, Random.new(seed))
	local rng = Random.new(seed * 7 + 1)
	local W = { dist = 1e9, angle = 120, visible = false, speed = 0 }
	local stats = { visibleTime = 0, states = {}, chases = {}, moveWhileSeen = 0, appear = 0, freezeLatency = {}, silences = 0, poses = 0, vanishNear = 0 }
	local dt, t = 0.1, 0
	local seenSince = nil
	while t < seconds do
		t += dt
		policy(W, rng, t, b.state)
		local sees = W.visible and W.angle < 16
		local P = { hasTarget = true, dist = W.dist, targetAngle = W.angle, targetSees = sees, anySees = sees }
		local before = b.state
		local cmds = b:Update(dt, P)
		for _, c in ipairs(cmds) do
			local k = c[1]
			if k == "place" then W.dist = c[2] == "far" and (70 + rng:NextNumber() * 80) or (W.dist * 0.6) end
			if k == "appear" then W.visible = true; stats.appear += 1 end
			if k == "vanish" then if c[2] == 0 then W.visible = false end; W.fadeEnd = t + c[2]; if W.dist < 38 then stats.vanishNear += 1 end end
			if k == "move" then W.speed = c[2]; if c[2] > 0 and sees then stats.moveWhileSeen += 1 end end
			if k == "anim" and c[2] == "Chase" then table.insert(stats.chases, t) end
			if k == "silence" then stats.silences += 1 end
			if k == "pose" then stats.poses += 1; check(not sees, "cambió de postura mientras lo miraban") end
		end
		if W.fadeEnd and t >= W.fadeEnd then W.visible = false; W.fadeEnd = nil end
		if b.state == "Absent" then W.visible = false end
		if W.speed > 0 then W.dist = math.max(1, W.dist - W.speed * dt) end
		if b.state ~= "Stalk" and b.state ~= "Chase" then W.speed = 0 end
		-- reglas: si lo ven mientras observa/acecha, en el mismo tick pasa a Frozen
		if sees and (before == "Observe" or before == "Stalk") then
			check(b.state == "Frozen" or b.state == "Vanish", "visto en " .. before .. " y no se congeló (pasó a " .. b.state .. ")")
		end
		if W.visible then stats.visibleTime += dt end
		stats.states[b.state] = (stats.states[b.state] or 0) + dt
	end
	return stats
end

-- 1) sin jugadores: nunca aparece
do
	local b = Brain.new({}, Random.new(3))
	local appeared = false
	for i = 1, 3000 do
		for _, c in ipairs(b:Update(0.1, { hasTarget = false, dist = 1e9, targetAngle = 180, targetSees = false, anySees = false })) do
			if c[1] == "appear" then appeared = true end
		end
	end
	check(not appeared, "apareció sin jugadores")
end

-- 2) el jugador nunca mira hacia él: acecha y se detiene a distancia, sin perseguir constantemente
local s = sim(11, 3600, function(W) W.angle = 120 end)
check(s.appear > 5, "apenas aparece en una hora (" .. s.appear .. ")")
check((s.states.Stalk or 0) > 30, "no acecha nunca cuando no lo miran")
check(#s.chases == 0, "persiguió sin haber detección")
check(s.moveWhileSeen == 0, "se movió mientras lo miraban")
print(("no mira: apariciones %d, visible %.0f%%, acecho %.0fs, ausente %.0f%%"):format(s.appear, 100 * s.visibleTime / 3600, s.states.Stalk or 0, 100 * (s.states.Absent or 0) / 3600))

-- 3) el jugador lo mira fijamente siempre que está: queda inmóvil y nunca se mueve
local s3 = sim(5, 3600, function(W, rng, t, st) W.angle = W.visible and 3 or 120; W.dist = math.max(W.dist, 60) end)
check(s3.moveWhileSeen == 0, "se movió mientras lo miraban fijamente")
check((s3.states.Frozen or 0) > (s3.states.Stalk or 0), "con mirada fija debería pasar más tiempo inmóvil que acechando")
print(("mirada fija: inmóvil %.0fs, acecho %.0fs"):format(s3.states.Frozen or 0, s3.states.Stalk or 0))

-- 4) el jugador se acerca mucho: se desvanece
local s4 = sim(9, 1800, function(W, rng, t) if W.visible then W.dist = math.max(5, W.dist - 3 * 0.1) end; W.angle = 40 end)
check(s4.vanishNear > 0, "no se desvaneció cuando el jugador se acercó")
print(("acercarse: desapariciones de cerca %d"):format(s4.vanishNear))

-- 5) mirada aleatoria realista durante 4 horas: variedad, enfriamiento de persecución y presencia limitada
local s5 = sim(21, 4 * 3600, function(W, rng)
	W.angle = math.clamp(W.angle + (rng:NextNumber() - 0.5) * 40, 0, 180)
	if rng:NextNumber() < 0.01 then W.angle = rng:NextNumber() * 180 end
end)
for i = 2, #s5.chases do check(s5.chases[i] - s5.chases[i - 1] >= 240, "persecuciones demasiado seguidas") end
check(s5.visibleTime / (4 * 3600) < 0.5, "está visible demasiado tiempo")
local kinds = 0
for k in pairs(s5.states) do kinds += 1 end
check(kinds >= 6, "poca variedad de estados (" .. kinds .. ")")
check(s5.moveWhileSeen == 0, "se movió mientras lo miraban (aleatorio)")
local parts = {}
for k, v in pairs(s5.states) do table.insert(parts, ("%s %.0fs"):format(k, v)) end
table.sort(parts)
print(("aleatorio 4h: persecuciones %d, silencios %d, cambios de postura %d, visible %.0f%%"):format(#s5.chases, s5.silences, s5.poses, 100 * s5.visibleTime / (4 * 3600)))
print("  " .. table.concat(parts, ", "))

-- 6) puntuación de sitios: periferia lejana mejor que delante; nunca dentro de la vista
check(Brain.ScoreSpot("far", 100, 70, false, 0) > Brain.ScoreSpot("far", 100, 5, false, 0), "la periferia no puntúa más que el centro")
check(Brain.ScoreSpot("far", 100, 70, true, 3) < 0, "aceptó un sitio a la vista")
check(Brain.ScoreSpot("far", 100, 70, false, 3) > Brain.ScoreSpot("far", 100, 70, false, 0), "la cobertura (árboles) no suma")
check(Brain.ScoreSpot("closer", 20, 90, false, 0) < 0, "'closer' aceptó un sitio dentro de la distancia de desaparición")

print(fails == 0 and "OK: el comportamiento cumple las reglas" or ("FALLOS: " .. fails))
if fails > 0 then error("fallos") end
`;
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'brain-'));
const file = path.join(dir, 'test.luau');
fs.writeFileSync(file, shim + tests);
try { process.stdout.write(execFileSync(luau, [file], { encoding: 'utf8' })); }
catch (e) { process.stdout.write((e.stdout || '') + (e.stderr || '')); process.exit(1); }
