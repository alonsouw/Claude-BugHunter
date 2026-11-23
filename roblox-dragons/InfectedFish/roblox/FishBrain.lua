--[[
	FishBrain (ModuleScript) · ReplicatedStorage.Creatures.InfectedFish.FishBrain

	Lógica pura de un pez infectado (sin Instances: se prueba fuera de Roblox). El servidor (FishSpawner) le pasa lo
	que percibe y aplica las órdenes que devuelve.

	Estados: Wander · Screech · Circle · Chase · Bite · Leap · Hurt · Dead
	  · si estás dentro de su agua y a su distancia de detección: chilla (con recarga), te rodea un rato y embiste
	    (el gigante no rodea: embiste directo)
	  · muerde al llegar a su alcance, con su recarga
	  · si estás fuera del agua pero cerca del borde (canLeap), salta hacia ti (con su recarga)
	  · si sales del agua y no te alcanza un rato, vuelve a nadar a su aire

	Percepción (P): hasTarget, inWater, canLeap, dist, hurt, dead
	Órdenes: {"anim", nombre, fundido} · {"move", modo, velocidad} con modo "wander" | "circle" | "chase" | "stop"
	         {"attack", retardo} · {"leap"} · {"sound", nombre}
]]

local Brain = {}
Brain.__index = Brain

Brain.Defaults = {
	Detect = 45,
	Reach = 3.5,
	Cooldown = 1.2,
	SwimSpeed = 6,
	CircleSpeed = 11,
	ChaseSpeed = 17,
	Circle = true,
	CircleTime = { 2.5, 4.5 },
	ScreechCooldown = 20,
	LeapCooldown = 7,
	LeapTime = 1.4,
	LoseTime = 6,
}

function Brain.new(config, rng)
	local self = setmetatable({}, Brain)
	self.cfg = setmetatable(config or {}, { __index = Brain.Defaults })
	self.rng = rng or Random.new()
	self.t = 0
	self.nextAttack = 0
	self.nextScreech = 0
	self.nextLeap = 0
	self.lost = 0
	self.out = {}
	self:enter("Wander", 0)
	return self
end

function Brain:range(r)
	return r[1] + (r[2] - r[1]) * self.rng:NextNumber()
end

function Brain:emit(...)
	table.insert(self.out, { ... })
end

function Brain:enter(state, timer)
	self.state = state
	self.timer = timer or 0
	self.stateTime = 0
end

function Brain:wander()
	self:emit("anim", "Swim", 0.4)
	self:emit("move", "wander", self.cfg.SwimSpeed)
	self:enter("Wander", 0)
end

function Brain:chase()
	self:emit("anim", "Charge", 0.25)
	self:emit("move", "chase", self.cfg.ChaseSpeed)
	self:enter("Chase", 0)
end

function Brain:circle()
	self:emit("anim", "Swim", 0.3)
	self:emit("move", "circle", self.cfg.CircleSpeed)
	self:enter("Circle", self:range(self.cfg.CircleTime))
end

function Brain:engage()
	if self.cfg.Circle then
		self:circle()
	else
		self:chase()
	end
end

function Brain:leap()
	local c = self.cfg
	self.nextLeap = self.t + c.LeapCooldown
	self:emit("anim", "Leap", 0.1)
	self:emit("leap")
	self:emit("sound", "Splash")
	self:enter("Leap", c.LeapTime)
end

function Brain:Update(dt, P)
	self.out = {}
	local c = self.cfg
	self.t += dt
	self.timer -= dt
	self.stateTime += dt
	local s = self.state
	if s == "Dead" then
		return self.out
	end
	if P.dead then
		self:emit("move", "stop", 0)
		self:emit("anim", "Death", 0.1)
		self:enter("Dead", 0)
		return self.out
	end
	if s == "Leap" then   -- en el aire no se le puede interrumpir
		if self.timer <= 0 then
			if P.hasTarget and P.inWater then
				self:chase()
			else
				self:wander()
			end
		end
		return self.out
	end
	if P.hurt and s ~= "Bite" and s ~= "Screech" then
		self:emit("anim", "Hurt", 0.05)
		self:enter("Hurt", 0.45)
		return self.out
	end
	local sees = P.hasTarget and P.inWater and P.dist <= c.Detect
	local leapable = P.hasTarget and P.canLeap and not P.inWater and self.t >= self.nextLeap
	if s == "Wander" then
		if sees then
			if self.t >= self.nextScreech then
				self.nextScreech = self.t + c.ScreechCooldown
				self:emit("anim", "Screech", 0.15)
				self:emit("move", "stop", 0)
				self:emit("sound", "Screech")
				self:enter("Screech", 1.2)
			else
				self:engage()
			end
		elseif leapable then
			self:leap()
		elseif self.rng:NextNumber() < dt * 0.08 then
			self:emit("sound", "Gurgle")
		end
	elseif s == "Screech" then
		if self.timer <= 0 then
			self:engage()
		end
	elseif s == "Circle" then
		if not P.hasTarget or not P.inWater then
			self.lost += dt
			if leapable then
				self:leap()
			elseif self.lost > c.LoseTime then
				self.lost = 0
				self:wander()
			end
		else
			self.lost = 0
			if self.timer <= 0 then
				self:chase()
			end
		end
	elseif s == "Chase" then
		if not P.hasTarget or not P.inWater then
			self.lost += dt
			if leapable then
				self:leap()
			elseif self.lost > c.LoseTime then
				self.lost = 0
				self:wander()
			end
		elseif P.dist <= c.Reach and self.t >= self.nextAttack then
			self.lost = 0
			self.nextAttack = self.t + c.Cooldown
			self:emit("anim", "Bite", 0.08)
			self:emit("attack", 0.25)
			self:emit("sound", "Bite")
			self:enter("Bite", 0.6)
		else
			self.lost = 0
		end
	elseif s == "Bite" or s == "Hurt" then
		if self.timer <= 0 then
			if P.hasTarget and P.inWater then
				self:chase()
			elseif leapable then
				self:leap()
			else
				self:wander()
			end
		end
	end
	return self.out
end

return Brain
