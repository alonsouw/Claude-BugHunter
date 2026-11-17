// Prueba de DeerBrain con el intérprete luau, sin Roblox: proporción de malditos, huida, transformación y desaparición.
// Uso: node tools/test_brain.js /ruta/a/luau
const fs = require('fs'), path = require('path'), os = require('os'), { execFileSync } = require('child_process');
const ROOT = path.join(__dirname, '..');
const luau = process.argv[2] || 'luau';
const src = fs.readFileSync(path.join(ROOT, 'roblox/DeerBrain.lua'), 'utf8').replace(/: number\??/g, '');
const test = `
local Random = {}
Random.__index = Random
function Random.new(seed) return setmetatable({ s = seed or 12345 }, Random) end
function Random:NextNumber() self.s = (self.s * 1103515245 + 12345) % 2147483648; return self.s / 2147483648 end
function Random:NextInteger(a, b) return a + math.floor(self:NextNumber() * (b - a + 1)) end
local Brain = (function() ${src} end)()
local fails = 0
local function check(c, m) if not c then fails += 1; print("FALLO: " .. m) end end

-- 1) uno de cada 7
for _, case in ipairs({ { 7, 1 }, { 14, 2 }, { 21, 3 }, { 70, 10 }, { 4, 1 }, { 3, 0 } }) do
	local set, n = Brain.PickCursed(case[1], Random.new(case[1]))
	local k = 0
	for _ in pairs(set) do k += 1 end
	check(n == case[2] and k == case[2], ("PickCursed(%d) = %d, esperado %d"):format(case[1], k, case[2]))
end

-- simulación: un jugador se acerca y se aleja; devuelve qué órdenes salieron
local function run(cursed, cfg, script, seconds, seed)
	local b = Brain.new(cfg or {}, Random.new(seed or 5), cursed)
	local seen = { form = {}, flee = 0, anims = {}, vanish = 0, respawn = 0, chaseT = {} }
	local t = 0
	while t < seconds do
		t += 0.1
		local P = script(t, b)
		for _, c in ipairs(b:Update(0.1, P)) do
			if c[1] == "form" then table.insert(seen.form, c[2]) end
			if c[1] == "move" and c[3] == "flee" then seen.flee += 1 end
			if c[1] == "anim" then seen.anims[c[2]] = (seen.anims[c[2]] or 0) + 1; if c[2] == "CreatureRun" then table.insert(seen.chaseT, t) end end
			if c[1] == "vanish" then seen.vanish += 1 end
			if c[1] == "respawn" then seen.respawn += 1 end
		end
	end
	return seen, b
end
local approach = function(t) return { dist = math.max(5, 80 - t * 4), alarm = false, night = false } end

-- 2) normal: huye y nunca se transforma
local s = run(false, nil, approach, 60)
check(#s.form == 0, "un ciervo normal se transformó")
check(s.flee > 0, "un ciervo normal no huyó al acercarse el jugador")
-- 3) maldito: no huye, se transforma cerca y pasa a criatura
local s2, b2 = run(true, nil, approach, 40)
check(s2.flee == 0, "el maldito huyó en vez de dejarse acercar")
check(s2.form[1] == "creature" and (s2.anims.Transform or 0) == 1, "el maldito no se transformó")
check(b2.form == "creature" and (s2.anims.Shriek or 0) >= 1, "tras transformarse no chilla ni queda como criatura")
-- 4) solo de noche: de día huye como uno normal; de noche se transforma
local s3 = run(true, { NightOnly = true }, approach, 40)
check(#s3.form == 0 and s3.flee > 0, "con NightOnly se transformó de día")
local s4 = run(true, { NightOnly = true }, function(t) return { dist = math.max(5, 80 - t * 4), alarm = false, night = true } end, 40)
check(s4.form[1] == "creature", "con NightOnly no se transformó de noche")
-- 5) criatura: te acecha con enfriamiento entre carreras; si te alejas, desaparece y vuelve a ser ciervo
local s5, b5 = run(true, nil, function(t) if t < 120 then return { dist = 15 + 45 * math.abs(math.sin(t / 9)), alarm = false } end return { dist = 400, alarm = false } end, 200)
for i = 2, #s5.chaseT do check(s5.chaseT[i] - s5.chaseT[i - 1] >= 9, "carreras demasiado seguidas") end
check(#s5.chaseT >= 2, "la criatura casi no persigue (" .. #s5.chaseT .. ")")
check(s5.vanish == 1 and s5.respawn == 1 and b5.form == "deer", "al alejarse el jugador no desapareció ni volvió a ser ciervo")
check(s5.form[#s5.form] == "deer", "la última forma publicada no es ciervo")
-- 6) la manada: un aviso de alarma hace huir a los normales
local s6 = run(false, nil, function(t) return { dist = 100, alarm = t > 5 and t < 6 } end, 20)
check(s6.flee > 0, "la alarma de la manada no hizo huir")
-- 7) muchos ciervos, muchas visitas: solo se transforman los malditos y cada uno a la vez
local transformed, cursedN = 0, 0
local set, n = Brain.PickCursed(70, Random.new(9))
for i = 1, 70 do
	local cur = set[i] == true
	if cur then cursedN += 1 end
	local s7 = run(cur, nil, function(t) return { dist = 8 + 70 * math.abs(math.sin(t / 7)), alarm = false } end, 90, i)
	if #s7.form > 0 then
		check(cur, "un ciervo normal se transformó en la manada")
		transformed += 1
	end
end
check(transformed == cursedN and cursedN == 10, ("en 70 ciervos se transformaron %d de %d malditos"):format(transformed, cursedN))
print(("70 ciervos: %d malditos, %d transformados; normal: %d órdenes de huida; criatura: %d carreras"):format(cursedN, transformed, s.flee, #s5.chaseT))
print(fails == 0 and "OK: el comportamiento de la manada cumple las reglas" or ("FALLOS: " .. fails))
if fails > 0 then error("fallos") end
`;
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'deer-')); const f = path.join(dir, 't.luau'); fs.writeFileSync(f, test);
try { process.stdout.write(execFileSync(luau, [f], { encoding: 'utf8' })); } catch (e) { process.stdout.write((e.stdout || '') + (e.stderr || '')); process.exit(1); }
