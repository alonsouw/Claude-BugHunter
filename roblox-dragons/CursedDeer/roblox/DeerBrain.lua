--[[
	DeerBrain (ModuleScript) · ReplicatedStorage.Creatures.CursedDeer.DeerBrain

	Lógica pura de un ciervo (sin Instances: se prueba fuera de Roblox). El servidor (DeerHerd) le pasa lo que
	percibe y aplica las órdenes que devuelve.

	Ciervo normal:  Graze (pasta) · Idle · Wander (camina) · Alert (te mira) · Flee (huye y avisa a la manada)
	Ciervo maldito: igual que uno normal… pero no huye. Se queda mirándote y, cuando te acercas lo bastante,
	                se transforma (Transform) en la criatura:
	                Shriek → Stare (te mira) / Stalk (te sigue despacio) / Chase (carrera corta) …
	                Si te alejas mucho rato, se desvanece y vuelve a ser un ciervo en otro lugar de la manada.

	Percepción (P):
	  dist        distancia al jugador más cercano (math.huge si no hay)
	  alarm       otro ciervo cercano acaba de huir
	  night       es de noche (solo importa con NightOnly)
	Órdenes: {"anim", nombre, fundido} · {"move", velocidad, modo} con modo "wander" | "flee" | "toward" | "face" | "stop"
	         {"wanderTarget"} · {"alarm"} · {"form", "deer"|"creature"} · {"sound", nombre}
	         {"vanish", s} · {"respawn"} · {"appear", s}
]]

local Brain = {}
Brain.__index = Brain

Brain.Defaults = {
	AlertDistance = 45,     -- empieza a mirarte
	FleeDistance = 24,      -- huye (los normales)
	WalkSpeed = 3.2,
	RunSpeed = 24,
	TriggerMin = 12,        -- el maldito se transforma cuando estás entre TriggerMin y TriggerMax (al azar por ciervo)
	TriggerMax = 26,
	StalkSpeed = 7,
	ChaseSpeed = 27,
	ChaseCooldown = 9,
	LoseDistance = 150,     -- si nadie está más cerca que esto durante LoseTime, desaparece
	LoseTime = 25,
	NightOnly = false,      -- true: el maldito solo se transforma de noche
}

function Brain.new(config, rng, cursed)
	local self = setmetatable({}, Brain)
	self.cfg = setmetatable(config or {}, { __index = Brain.Defaults })
	self.rng = rng or Random.new()
	self.cursed = cursed == true
	self.form = "deer"
	self.t = 0
	self.lastChase = -1e9
	self.trigger = self:range({ self.cfg.TriggerMin, self.cfg.TriggerMax })
	self:enter("Graze", self:range({ 4, 14 }))
	self.out = {}
	return self
end

function Brain:range(r)
	return r[1] + (r[2] - r[1]) * self.rng:NextNumber()
end

function Brain:chance(p)
	return self.rng:NextNumber() < p
end

function Brain:emit(...)
	table.insert(self.out, { ... })
end

function Brain:enter(state, timer)
	self.state = state
	self.timer = timer or 0
	self.stateTime = 0
end

function Brain:calm()
	local r = self.rng:NextNumber()
	if r < 0.5 then
		self:emit("anim", "Graze", 0.6)
		self:emit("move", 0, "stop")
		self:enter("Graze", self:range({ 6, 18 }))
	elseif r < 0.75 then
		self:emit("anim", "Idle", 0.5)
		self:emit("move", 0, "stop")
		self:enter("Idle", self:range({ 3, 8 }))
	else
		self:emit("wanderTarget")
		self:emit("anim", "Walk", 0.4)
		self:emit("move", self.cfg.WalkSpeed, "wander")
		self:enter("Wander", self:range({ 5, 12 }))
	end
end

function Brain:flee()
	self:emit("anim", "Run", 0.2)
	self:emit("move", self.cfg.RunSpeed, "flee")
	self:emit("alarm")
	self:emit("sound", "Snort")
	self:enter("Flee", self:range({ 4, 7 }))
end

function Brain:creatureNext(P)
	local c = self.cfg
	if P.dist > c.LoseDistance then
		self:emit("anim", "CreatureIdle", 0.5)
		self:emit("move", 0, "face")
		self:enter("Stare", 3)
		return
	end
	local canChase = self.t - self.lastChase > c.ChaseCooldown and P.dist > 10
	local r = self.rng:NextNumber()
	if canChase and r < 0.35 then
		self.lastChase = self.t
		self:emit("anim", "CreatureRun", 0.25)
		self:emit("move", c.ChaseSpeed, "toward")
		self:enter("Chase", self:range({ 2.5, 4.5 }))
	elseif r < 0.75 then
		self:emit("anim", "CreatureWalk", 0.4)
		self:emit("move", c.StalkSpeed, "toward")
		self:enter("Stalk", self:range({ 3, 7 }))
	else
		self:emit("anim", "CreatureIdle", 0.5)
		self:emit("move", 0, "face")
		self:enter("Stare", self:range({ 2, 5 }))
	end
end

function Brain:Update(dt, P)
	self.out = {}
	local c = self.cfg
	self.t += dt
	self.timer -= dt
	self.stateTime += dt
	local s = self.state

	if self.form == "deer" then
		local canTransform = self.cursed and (not c.NightOnly or P.night)
		if s == "Transform" then
			if self.timer <= 0 then
				self:emit("sound", "Shriek")
				self:emit("anim", "Shriek", 0.2)
				self:enter("Shriek", 2.6)
				self.form = "creature"
			end
		elseif canTransform and P.dist < self.trigger then
			self:emit("move", 0, "face")
			self:emit("anim", "Transform", 0.3)
			self:emit("form", "creature")
			self:emit("sound", "Crack")
			self:enter("Transform", 4.6)
		elseif s == "Flee" then
			if self.timer <= 0 and P.dist > c.FleeDistance then
				self:emit("anim", "Alert", 0.4)
				self:emit("move", 0, "face")
				self:enter("Alert", self:range({ 2, 4 }))
			end
		elseif not canTransform and (P.dist < c.FleeDistance or P.alarm) then
			self:flee()
		elseif P.dist < c.AlertDistance then
			if s ~= "Alert" then
				self:emit("anim", "Alert", 0.4)
				self:emit("move", 0, "face")
				self:enter("Alert", self:range({ 3, 6 }))
			elseif self.timer <= 0 then
				self.timer = self:range({ 3, 6 })   -- sigue mirándote mientras estés cerca
			end
		elseif s == "Alert" then
			if self.timer <= 0 then
				self:calm()
			end
		elseif self.timer <= 0 then
			self:calm()
		end
		return self.out
	end

	-- forma de criatura
	if s == "Vanish" then
		if self.timer <= 0 then
			self:emit("respawn")
			self:emit("form", "deer")
			self:emit("anim", "Graze", 0)
			self:emit("appear", 2)
			self.form = "deer"
			self.trigger = self:range({ c.TriggerMin, c.TriggerMax })
			self:enter("Graze", self:range({ 8, 20 }))
		end
		return self.out
	end
	if P.dist > c.LoseDistance then
		self.lost = (self.lost or 0) + dt
		if self.lost > c.LoseTime then
			self.lost = 0
			self:emit("move", 0, "stop")
			self:emit("vanish", 2.5)
			self:enter("Vanish", 2.5)
			return self.out
		end
	else
		self.lost = 0
	end
	if s == "Shriek" then
		if self.timer <= 0 then
			self:creatureNext(P)
		end
	elseif s == "Chase" then
		if self.timer <= 0 or P.dist < 4 then
			self:emit("sound", "Shriek")
			self:emit("anim", "Shriek", 0.2)
			self:emit("move", 0, "face")
			self:enter("Shriek", 2.6)
		end
	elseif self.timer <= 0 then
		self:creatureNext(P)
	end
	return self.out
end

-- Elige qué ciervos están malditos: uno de cada 7 (redondeando, al menos 1 si hay 4 o más).
function Brain.PickCursed(count: number, rng, ratio: number?)
	ratio = ratio or 7
	local n = math.floor(count / ratio + 0.5)
	if count >= 4 then
		n = math.max(n, 1)
	end
	local idx = {}
	for i = 1, count do
		idx[i] = i
	end
	for i = count, 2, -1 do
		local j = rng:NextInteger(1, i)
		idx[i], idx[j] = idx[j], idx[i]
	end
	local cursed = {}
	for i = 1, n do
		cursed[idx[i]] = true
	end
	return cursed, n
end

return Brain
