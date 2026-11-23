--[[
	CureLogic (ModuleScript) · ReplicatedStorage.Cure.CureLogic

	Lógica pura de la cura (sin Instances: se prueba fuera de Roblox). La usa CureService.
	  · Receta: cuánto falta de cada ingrediente, echar uno al caldero, si ya está todo.
	  · Botín: qué suelta cada criatura (DropFor).
	  · Noche: la flor de luna solo se abre de noche (IsNight).
	  · Preparación: Collecting → Ready → Brewing → Done → Used.
	  · Jefe dragón de la guarida (Boss): Idle · Roar · Chase · Attack · Return · Hurt · Dead.
]]

local Logic = {}

-- ---------------------------------------------------------------- receta
function Logic.Remaining(progress, recipe, id)
	for _, r in ipairs(recipe) do
		if r.id == id then
			return math.max(0, r.need - (progress[id] or 0))
		end
	end
	return 0
end

function Logic.Add(progress, recipe, id)   -- true si hacía falta y se ha echado
	if Logic.Remaining(progress, recipe, id) > 0 then
		progress[id] = (progress[id] or 0) + 1
		return true
	end
	return false
end

function Logic.Complete(progress, recipe)
	for _, r in ipairs(recipe) do
		if (progress[r.id] or 0) < r.need then
			return false
		end
	end
	return true
end

function Logic.Count(progress, recipe)   -- ingredientes completos, total
	local done = 0
	for _, r in ipairs(recipe) do
		if (progress[r.id] or 0) >= r.need then
			done += 1
		end
	end
	return done, #recipe
end

-- ---------------------------------------------------------------- botín
-- kind: "boss" | "wolf" | "deerForm" | "infected" | "fish" | "custom"; info: lo que se sabe de la criatura
function Logic.DropFor(kind, info)
	info = info or {}
	if info.cureDrop and info.cureDrop ~= "" then
		return info.cureDrop
	end
	if kind == "boss" then
		return "DragonSaliva"
	elseif kind == "wolf" and (info.alpha == true or info.variant == "Alpha") then
		return "AlphaFang"
	elseif kind == "deerForm" and info.form == "creature" then
		return "CursedAntler"
	elseif kind == "infected" and info.name == "Brute" then
		return "BruteHeart"
	elseif kind == "fish" and info.name == "Giant" then
		return "BlackPearl"
	end
	return nil
end

function Logic.IsNight(clockTime: number)
	return clockTime >= 18.5 or clockTime < 5.5
end

-- ---------------------------------------------------------------- preparación en el caldero
local Brew = {}
Brew.__index = Brew
Logic.Brew = Brew

function Brew.new(duration: number)
	return setmetatable({ state = "Collecting", duration = duration, t0 = 0 }, Brew)
end
function Brew:SetReady(ready: boolean)
	if self.state == "Collecting" and ready then
		self.state = "Ready"
	end
end
function Brew:Start(now: number)
	if self.state ~= "Ready" then
		return false
	end
	self.state = "Brewing"
	self.t0 = now
	return true
end
function Brew:Fraction(now: number)
	if self.state == "Brewing" then
		return math.clamp((now - self.t0) / self.duration, 0, 1)
	end
	return (self.state == "Done" or self.state == "Used") and 1 or 0
end
function Brew:Update(now: number)   -- true justo cuando termina
	if self.state == "Brewing" and now - self.t0 >= self.duration then
		self.state = "Done"
		return true
	end
	return false
end
function Brew:Use()
	if self.state == "Done" then
		self.state = "Used"
		return true
	end
	return false
end

-- ---------------------------------------------------------------- jefe dragón
-- P: hasTarget, dist (al jugador), fromHome (distancia del dragón a su guarida), targetFromHome, dead, hurt
-- Órdenes: {"anim", nombre, fundido} · {"move", "chase"|"home"|"stop", velocidad} · {"attack", retardo} · {"sound", nombre}
local Boss = {}
Boss.__index = Boss
Logic.Boss = Boss
Boss.Defaults = { Detect = 70, Reach = 14, Cooldown = 2.8, Speed = 12, Leash = 70, RoarCooldown = 25 }

function Boss.new(cfg)
	local self = setmetatable({}, Boss)
	self.cfg = setmetatable(cfg or {}, { __index = Boss.Defaults })
	self.t = 0
	self.nextAttack = 0
	self.nextRoar = 0
	self.state = "Idle"
	self.timer = 0
	return self
end
function Boss:emit(out, ...)
	table.insert(out, { ... })
end
function Boss:Update(dt, P)
	local out, c = {}, self.cfg
	self.t += dt
	self.timer -= dt
	local s = self.state
	if s == "Dead" then
		return out
	end
	if P.dead then
		self:emit(out, "move", "stop", 0)
		self:emit(out, "anim", "Death", 0.2)
		self:emit(out, "sound", "Death")
		self.state = "Dead"
		return out
	end
	local valid = P.hasTarget and P.dist <= c.Detect and P.targetFromHome <= c.Leash
	if s == "Idle" or s == "Return" then
		if valid then
			if self.t >= self.nextRoar then
				self.nextRoar = self.t + c.RoarCooldown
				self:emit(out, "move", "stop", 0)
				self:emit(out, "anim", "Roar", 0.2)
				self:emit(out, "sound", "Roar")
				self.state, self.timer = "Roar", 2.2
			else
				self:emit(out, "anim", "Walk", 0.3)
				self:emit(out, "move", "chase", c.Speed)
				self.state = "Chase"
			end
		elseif s == "Return" and P.fromHome < 3 then
			self:emit(out, "anim", "Idle", 0.4)
			self:emit(out, "move", "stop", 0)
			self.state = "Idle"
		end
	elseif s == "Roar" then
		if self.timer <= 0 then
			self:emit(out, "anim", "Walk", 0.3)
			self:emit(out, "move", "chase", c.Speed)
			self.state = "Chase"
		end
	elseif s == "Chase" then
		if not valid then
			self:emit(out, "anim", "Walk", 0.3)
			self:emit(out, "move", "home", c.Speed * 0.7)
			self.state = "Return"
		elseif P.dist <= c.Reach and self.t >= self.nextAttack then
			self.nextAttack = self.t + c.Cooldown
			self:emit(out, "move", "stop", 0)
			self:emit(out, "anim", "Attack", 0.15)
			self:emit(out, "attack", 0.5)
			self.state, self.timer = "Attack", 1.3
		elseif P.dist <= c.Reach then
			self:emit(out, "move", "stop", 0)
		else
			self:emit(out, "move", "chase", c.Speed)
		end
	elseif s == "Attack" then
		if self.timer <= 0 then
			self:emit(out, "anim", "Walk", 0.3)
			if valid then
				self:emit(out, "move", "chase", c.Speed)
				self.state = "Chase"
			else
				self:emit(out, "move", "home", c.Speed * 0.7)
				self.state = "Return"
			end
		end
	end
	return out
end

return Logic
