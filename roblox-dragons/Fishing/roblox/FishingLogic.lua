--[[
	FishingLogic (ModuleScript) · ReplicatedStorage.Fishing.FishingLogic

	La pesca de un jugador como máquina de estados pura (sin Instances: se prueba fuera de Roblox).
	FishingService la usa para cada jugador que pesca y aplica los eventos que devuelve.

	Idle → (Cast) → Casting → Waiting → (pica) → Bite → (Hook a tiempo) → Reeling → (barra llena) → Caught
	  · clic antes de que pique (Hook en Waiting): espanta al pez → "escaped", "early"
	  · no hacer clic durante la picada: → "escaped", "late"
	  · recogiendo, el pez vacía la barra (Drain por segundo, según la especie); cada clic (Reel) la llena ReelPower;
	    si se vacía → "escaped", "lost"; si pasa MaxReel segundos → "escaped", "tired"

	Eventos: {"state", nombre} · {"bite", especie} · {"progress", 0-100} · {"caught", especie} · {"escaped", motivo}
]]

local Logic = {}
Logic.__index = Logic

Logic.Defaults = {
	CastTime = 0.6,
	WaitTime = { 4, 12 },
	BiteWindow = 1.3,
	ReelStart = 30,
	ReelPower = 9,
	MinClick = 0.07,   -- clics más seguidos que esto no cuentan (autoclickers)
	MaxReel = 15,
	-- especies: { nombre, peso, Drain }
	Species = { { "Trout", 60, 14 }, { "Perch", 30, 18 }, { "GoldenSalmon", 10, 26 } },
}

function Logic.new(config, rng)
	local self = setmetatable({}, Logic)
	self.cfg = setmetatable(config or {}, { __index = Logic.Defaults })
	self.rng = rng or Random.new()
	self.state = "Idle"
	self.last = 0
	return self
end

function Logic:roll()
	local total = 0
	for _, s in ipairs(self.cfg.Species) do
		total += s[2]
	end
	local x = self.rng:NextNumber() * total
	for _, s in ipairs(self.cfg.Species) do
		x -= s[2]
		if x <= 0 then
			return s[1], s[3]
		end
	end
	local s = self.cfg.Species[#self.cfg.Species]
	return s[1], s[3]
end

function Logic:set(state, out)
	self.state = state
	table.insert(out, { "state", state })
end

function Logic:Cast(now: number)
	local out = {}
	if self.state ~= "Idle" then
		return out
	end
	self.tEnd = now + self.cfg.CastTime
	self.last = now
	self:set("Casting", out)
	return out
end

function Logic:Hook(now: number)
	local out = {}
	if self.state == "Bite" then
		self.progress = self.cfg.ReelStart
		self.reelStart = now
		self.lastClick = -math.huge
		self.last = now
		self:set("Reeling", out)
		table.insert(out, { "progress", self.progress })
	elseif self.state == "Waiting" or self.state == "Casting" then
		table.insert(out, { "escaped", "early" })
		self:set("Idle", out)
	end
	return out
end

function Logic:Reel(now: number)
	local out = {}
	if self.state ~= "Reeling" then
		return out
	end
	for _, e in ipairs(self:Update(now)) do   -- primero lo que ha tirado el pez hasta ahora
		table.insert(out, e)
	end
	if self.state ~= "Reeling" or now - self.lastClick < self.cfg.MinClick then
		return out
	end
	self.lastClick = now
	self.progress = math.min(100, self.progress + self.cfg.ReelPower)
	table.insert(out, { "progress", self.progress })
	if self.progress >= 100 then
		table.insert(out, { "caught", self.species })
		self:set("Idle", out)
	end
	return out
end

function Logic:Cancel()
	local out = {}
	if self.state ~= "Idle" then
		self:set("Idle", out)
	end
	return out
end

function Logic:Update(now: number)
	local out = {}
	local dt = math.max(0, now - self.last)
	self.last = now
	local s = self.state
	if s == "Casting" and now >= self.tEnd then
		local w = self.cfg.WaitTime
		self.biteAt = now + w[1] + (w[2] - w[1]) * self.rng:NextNumber()
		self:set("Waiting", out)
	elseif s == "Waiting" and now >= self.biteAt then
		self.species, self.drain = self:roll()
		self.tEnd = now + self.cfg.BiteWindow
		table.insert(out, { "bite", self.species })
		self:set("Bite", out)
	elseif s == "Bite" and now >= self.tEnd then
		table.insert(out, { "escaped", "late" })
		self:set("Idle", out)
	elseif s == "Reeling" then
		self.progress -= self.drain * dt
		if self.progress <= 0 then
			self.progress = 0
			table.insert(out, { "escaped", "lost" })
			self:set("Idle", out)
		elseif now - self.reelStart > self.cfg.MaxReel then
			table.insert(out, { "escaped", "tired" })
			self:set("Idle", out)
		end
	end
	return out
end

return Logic
