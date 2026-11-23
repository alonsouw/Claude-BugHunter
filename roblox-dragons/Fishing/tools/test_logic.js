// Prueba de FishingLogic con luau, sin Roblox: lanzar, esperar, picar, clavar a tiempo, recoger, escaparse,
// límite de clics y probabilidad de cada especie.  Uso: node tools/test_logic.js /ruta/a/luau
const fs = require('fs'), path = require('path'), os = require('os'), { execFileSync } = require('child_process');
const ROOT = path.join(__dirname, '..');
const src = fs.readFileSync(path.join(ROOT, 'roblox/FishingLogic.lua'), 'utf8');
const test = `
local Random = {}
Random.__index = Random
function Random.new(seed) return setmetatable({ s = seed or 12345 }, Random) end
function Random:NextNumber() self.s = (self.s * 1103515245 + 12345) % 2147483648; return self.s / 2147483648 end
local Logic = (function() ${src} end)()
local fails = 0
local function check(c, m) if not c then fails += 1; print("FALLO: " .. m) end end
local function has(evs, kind, val) for _, e in ipairs(evs) do if e[1] == kind and (val == nil or e[2] == val) then return e end end end
-- avanza el tiempo hasta un evento (o hasta un límite)
local function runUntil(L, t, kind, limit)
	while t < limit do t += 0.05; local e = has(L:Update(t), kind); if e then return t, e end end
	return t, nil
end
-- 1) lanzar → esperar → pica dentro del tiempo de espera
local L = Logic.new({}, Random.new(7))
check(has(L:Cast(0), "state", "Casting"), "no empezó a lanzar")
check(#L:Cast(0.1) == 0, "se pudo lanzar dos veces")
local t, e = runUntil(L, 0, "bite", 30)
check(e ~= nil and t >= 0.6 + 4 - 0.06 and t <= 0.6 + 12 + 0.06, "picó fuera del tiempo de espera (" .. tostring(t) .. ")")
-- 2) clavar a tiempo y recoger rápido (8 clics por segundo): lo saca
local hooked = L:Hook(t + 0.3)
check(has(hooked, "state", "Reeling"), "no se clavó el anzuelo a tiempo")
local caught, tt = nil, t + 0.3
for _ = 1, 200 do tt += 0.125; local ev = L:Reel(tt); local c = has(ev, "caught"); if c then caught = c; break end end
check(caught ~= nil and L.state == "Idle", "no lo sacó recogiendo rápido")
-- 3) clic antes de que pique: lo espanta
local L3 = Logic.new({}, Random.new(9)); L3:Cast(0); L3:Update(1)
check(has(L3:Hook(1.5), "escaped", "early") and L3.state == "Idle", "clic antes de tiempo no lo espantó")
-- 4) no hacer clic durante la picada: se escapa
local L4 = Logic.new({}, Random.new(11)); L4:Cast(0)
local t4 = runUntil(L4, 0, "bite", 30)
local _, e4 = runUntil(L4, t4, "escaped", t4 + 3)
check(e4 and e4[2] == "late", "no se escapó al no clavar")
-- 5) recoger despacio (1 clic por segundo): el pez vacía la barra y se escapa
local L5 = Logic.new({ Species = { { "Perch", 1, 18 } } }, Random.new(3)); L5:Cast(0)
local t5 = runUntil(L5, 0, "bite", 30); L5:Hook(t5 + 0.2)
local lost = nil; local tt5 = t5 + 0.2
for _ = 1, 40 do tt5 += 1; local ev = L5:Reel(tt5); local c = has(ev, "escaped"); if c then lost = c; break end; c = has(L5:Update(tt5 + 0.5), "escaped"); if c then lost = c; break end end
check(lost and lost[2] == "lost", "recogiendo despacio no se escapó")
-- 6) los clics demasiado seguidos no cuentan (autoclicker a 100 por segundo ≈ 14 por segundo)
local L6 = Logic.new({ Species = { { "Trout", 1, 0 } } }, Random.new(5)); L6:Cast(0)
local t6 = runUntil(L6, 0, "bite", 30); L6:Hook(t6)
local p0 = L6.progress; local tt6 = t6
for _ = 1, 50 do tt6 += 0.01; L6:Reel(tt6) end
check(L6.progress - p0 <= 9 * 8 + 1e-6, "contó clics a 100 por segundo (" .. (L6.progress - p0) .. ")")
-- 7) recogiendo demasiado tiempo: el pez se cansa y se suelta
local L7 = Logic.new({ Species = { { "Trout", 1, 9 } }, MaxReel = 5 }, Random.new(5)); L7:Cast(0)
local t7 = runUntil(L7, 0, "bite", 30); L7:Hook(t7)
local tired = nil; local tt7 = t7
for _ = 1, 100 do tt7 += 1; local ev = L7:Reel(tt7); local c = has(ev, "escaped"); if c then tired = c; break end end
check(tired and tired[2] == "tired", "no se soltó al pasar el tiempo máximo")
-- 8) probabilidad de cada especie (60/30/10)
local L8 = Logic.new({}, Random.new(1234)); local n = { Trout = 0, Perch = 0, GoldenSalmon = 0 }
for _ = 1, 20000 do local s = L8:roll(); n[s] += 1 end
check(math.abs(n.Trout / 20000 - 0.6) < 0.02 and math.abs(n.Perch / 20000 - 0.3) < 0.02 and math.abs(n.GoldenSalmon / 20000 - 0.1) < 0.015, ("reparto de especies raro: %d %d %d"):format(n.Trout, n.Perch, n.GoldenSalmon))
-- 9) cancelar (guardar la caña) vuelve a Idle desde cualquier estado
local L9 = Logic.new({}, Random.new(2)); L9:Cast(0); L9:Update(1)
check(has(L9:Cancel(), "state", "Idle") and L9.state == "Idle" and #L9:Cancel() == 0, "cancelar no reinicia")
print(fails == 0 and "OK: lógica de la pesca (9 escenarios)" or ("FALLOS: " .. fails))
if fails > 0 then error("fallos") end
`;
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'fishing-')); const f = path.join(dir, 't.luau'); fs.writeFileSync(f, test);
try { process.stdout.write(execFileSync(process.argv[2] || 'luau', [f], { encoding: 'utf8' })); } catch (e) { process.stdout.write((e.stdout || '') + (e.stderr || '')); process.exit(1); }
