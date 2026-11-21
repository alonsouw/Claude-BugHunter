--[[
	InfectedBrain (ModuleScript) · ReplicatedStorage.Creatures.Infected.InfectedBrain

	Lógica pura de un infectado (sin Instances: se prueba fuera de Roblox). El servidor (InfectedSpawner) le pasa lo
	que percibe y aplica las órdenes que devuelve.

	Estados: Idle · Wander · Chase · Attack · Scream · Hurt · Dead
	  · te detecta si te ve a su distancia de detección, o si un gritón ha gritado cerca (alerted)
	  · el gritón, al verte, grita primero (con recarga) y alerta a todos los infectados del radio
	  · ataca al llegar a su alcance, con su tiempo de recarga; el bruto usa el golpe al suelo (Slam)
	  · si te pierde de vista un rato y estás lejos, vuelve a vagar

	Percepción (P): dist, hasTarget, canSee, alerted, health (0-1), hurt, dead
	Órdenes: {"anim", nombre, fundido} · {"move", modo, velocidad} con modo "wander" | "chase" | "stop"
	         {"attack", tipo, retardo} · {"scream"} · {"sound", nombre}
]]

local Brain = {}
Brain.__index = Brain

Brain.Defaults = {
	Detect = 55,
	Reach = 4,
	Cooldown = 1.4,
	WalkSpeed = 5,
	ChaseSpeed = 9,
	ChaseAnim = "Walk",     -- el corredor y el gritón usan "Run"
	AttackAnim = "Attack",  -- el bruto usa "Slam"
	CanScream = false,
	ScreamCooldown = 25,
	LoseTime = 8,
}

function Brain.new(config, rng)
	local self = setmetatable({}, Brain)
	self.cfg = setmetatable(config or {}, { __index = Brain.Defaults })
	self.rng = rng or Random.new()
	self.t = 0
	self.nextAttack = 0
	self.nextScream = 0
	self.lost = 0
	self.out = {}
	self:enter("Idle", self:range({ 1, 4 }))
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

function Brain:chase()
	local c = self.cfg
	self:emit("anim", c.ChaseAnim, 0.25)
	self:emit("move", "chase", c.ChaseSpeed)
	self:enter("Chase", 0)
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
	if P.hurt and s ~= "Attack" and s ~= "Scream" then
		self:emit("anim", "Hurt", 0.05)
		self:emit("move", "stop", 0)
		self:enter("Hurt", 0.4)
		return self.out
	end
	local sees = P.hasTarget and P.canSee and P.dist <= c.Detect
	if s == "Idle" or s == "Wander" then
		if sees and c.CanScream and self.t >= self.nextScream then
			self.nextScream = self.t + c.ScreamCooldown
			self:emit("anim", "Scream", 0.2)
			self:emit("move", "stop", 0)
			self:emit("scream")
			self:emit("sound", "Scream")
			self:enter("Scream", 2.3)
		elseif sees or (P.alerted and P.hasTarget) then
			self:emit("sound", "Groan")
			self:chase()
		elseif self.timer <= 0 then
			if s == "Idle" then
				self:emit("anim", "Walk", 0.4)
				self:emit("move", "wander", c.WalkSpeed)
				self:enter("Wander", self:range({ 4, 9 }))
			else
				self:emit("anim", "Idle", 0.4)
				self:emit("move", "stop", 0)
				self:enter("Idle", self:range({ 2, 6 }))
				if self.rng:NextNumber() < 0.4 then
					self:emit("sound", "Groan")
				end
			end
		end
	elseif s == "Scream" then
		if self.timer <= 0 then
			self:chase()
		end
	elseif s == "Chase" then
		if not P.hasTarget then
			self:emit("anim", "Idle", 0.4)
			self:emit("move", "stop", 0)
			self:enter("Idle", 2)
			return self.out
		end
		self.lost = (P.canSee or P.alerted) and 0 or (self.lost + dt)
		if self.lost > c.LoseTime and P.dist > c.Detect then
			self.lost = 0
			self:emit("anim", "Walk", 0.4)
			self:emit("move", "wander", c.WalkSpeed)
			self:enter("Wander", self:range({ 4, 9 }))
		elseif P.dist <= c.Reach and self.t >= self.nextAttack then
			self.nextAttack = self.t + c.Cooldown
			local slam = c.AttackAnim == "Slam"
			self:emit("anim", c.AttackAnim, 0.1)
			self:emit("move", "stop", 0)
			self:emit("attack", slam and "slam" or "hit", slam and 0.72 or 0.45)
			if slam then
				self:emit("sound", "Roar")
			end
			self:enter("Attack", slam and 1.35 or 0.75)
		elseif self.rng:NextNumber() < dt * 0.05 then
			self:emit("sound", "Groan")
		end
	elseif s == "Attack" or s == "Hurt" then
		if self.timer <= 0 then
			if P.hasTarget then
				self:chase()
			else
				self:emit("anim", "Idle", 0.3)
				self:enter("Idle", 2)
			end
		end
	end
	return self.out
end

return Brain
