--[[
	WolfBrain (ModuleScript) · ReplicatedStorage.Creatures.HollowWolf.WolfBrain

	Lógica pura de un lobo de la manada (sin Instances: se prueba fuera de Roblox). El servidor (WolfPack)
	le pasa lo que percibe y aplica las órdenes que devuelve.

	Estados:
	  Roam     la manada deambula siguiendo al alfa (camina, olfatea, descansa)
	  Howl     el alfa aúlla al descubrir a un jugador y avisa a toda la manada
	  Hunt     trote hacia el objetivo
	  Circle   lo rodea gruñendo a 9-14 studs, cada lobo en su flanco (slot); espera su turno para morder
	  Attack   salto con mordisco; luego retrocede al círculo
	  Hurt     se encoge al recibir daño
	  Flee     huye: herido de gravedad, de día, o si la luz le alcanza
	  Dead     muerto

	Percepción (P): dist, hasTarget, canAttack (el servidor limita cuántos muerden a la vez),
	  inLight (el lobo está dentro de una luz segura), targetInLight, day, alerted (la manada ya caza),
	  health (0-1), hurt (recibió daño en este tick), dead
	Órdenes: {"anim", nombre, fundido} · {"move", velocidad, modo} con modo
	  "wander" | "follow" | "toward" | "circle" | "away" | "lunge" | "face" | "stop"
	  · {"alert"} (avisar a la manada) · {"bite"} · {"sound", nombre} · {"despawn"}
]]

local Brain = {}
Brain.__index = Brain

Brain.Defaults = {
	DetectDistance = 70,
	LoseDistance = 130,
	CircleMin = 9,
	CircleMax = 14,
	AttackReach = 5.5,
	WalkSpeed = 6,
	TrotSpeed = 13,
	RunSpeed = 28,
	LungeSpeed = 34,
	AttackCooldown = { 3.5, 6.5 },
	FleeHealth = 0.25,
	Silent = false,          -- el pálido no gruñe ni ruge: solo se le oye al morder
}

function Brain.new(config, rng, isAlpha)
	local self = setmetatable({}, Brain)
	self.cfg = setmetatable(config or {}, { __index = Brain.Defaults })
	self.rng = rng or Random.new()
	self.alpha = isAlpha == true
	self.t = 0
	self.nextAttack = 0
	self.out = {}
	self:enter("Roam", 0)
	return self
end

function Brain:range(r)
	return r[1] + (r[2] - r[1]) * self.rng:NextNumber()
end

function Brain:emit(...)
	local c = { ... }
	if self.cfg.Silent and c[1] == "sound" and (c[2] == "Growl" or c[2] == "Snarl") then
		return
	end
	table.insert(self.out, c)
end

function Brain:enter(state, timer)
	self.state = state
	self.timer = timer or 0
	self.stateTime = 0
end

function Brain:roam()
	local r = self.rng:NextNumber()
	if r < 0.55 then
		self:emit("anim", "Walk", 0.4)
		self:emit("move", self.cfg.WalkSpeed, self.alpha and "wander" or "follow")
		self:enter("Roam", self:range({ 4, 9 }))
	elseif r < 0.8 then
		self:emit("anim", "Sniff", 0.4)
		self:emit("move", 0, "stop")
		self:enter("Roam", self:range({ 2, 5 }))
	else
		self:emit("anim", "Idle", 0.4)
		self:emit("move", 0, "stop")
		self:enter("Roam", self:range({ 3, 6 }))
	end
end

function Brain:toCircle()
	self:emit("anim", "Growl", 0.3)
	self:emit("move", self.cfg.TrotSpeed * 0.55, "circle")
	self:enter("Circle", 0)
end

function Brain:flee(t)
	self:emit("anim", "Run", 0.2)
	self:emit("move", self.cfg.RunSpeed, "away")
	self:enter("Flee", t or self:range({ 4, 7 }))
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
		self:emit("move", 0, "stop")
		self:emit("anim", "Death", 0.1)
		self:emit("sound", "Yelp")
		self:enter("Dead", 0)
		return self.out
	end
	if P.day then   -- de día la manada se retira corriendo y desaparece
		if s ~= "Leave" then
			self:emit("anim", "Run", 0.3)
			self:emit("move", c.RunSpeed, "away")
			self:enter("Leave", 6)
		elseif self.timer <= 0 then
			self:emit("despawn")
			self:enter("Dead", 0)
		end
		return self.out
	end
	if P.hurt and s ~= "Flee" then
		if P.health < c.FleeHealth then
			self:emit("sound", "Yelp")
			self:flee()
		else
			self:emit("anim", "Hurt", 0.05)
			self:emit("move", 0, "face")
			self:emit("sound", "Yelp")
			self:enter("Hurt", 0.55)
		end
		return self.out
	end
	if P.inLight and s ~= "Flee" then   -- la luz quema: sale corriendo
		self:flee(2.5)
		return self.out
	end

	if s == "Roam" then
		if P.hasTarget and (P.dist < c.DetectDistance or P.alerted) then
			if self.alpha and not P.alerted then
				self:emit("anim", "Howl", 0.3)
				self:emit("move", 0, "face")
				self:emit("alert")
				self:emit("sound", "Howl")
				self:enter("Howl", 3.4)
			else
				self:emit("anim", "Trot", 0.3)
				self:emit("move", c.TrotSpeed, "toward")
				self:enter("Hunt", 0)
			end
		elseif self.timer <= 0 then
			self:roam()
		end
	elseif s == "Howl" then
		if self.timer <= 0 then
			self:emit("anim", "Trot", 0.3)
			self:emit("move", c.TrotSpeed, "toward")
			self:enter("Hunt", 0)
		end
	elseif s == "Hunt" then
		if not P.hasTarget or P.dist > c.LoseDistance then
			self:roam()
		elseif P.dist < c.CircleMax + 4 or P.targetInLight then
			self:toCircle()
		end
	elseif s == "Circle" then
		if not P.hasTarget or P.dist > c.LoseDistance then
			self:roam()
		elseif P.dist > c.CircleMax + 10 and not P.targetInLight then
			self:emit("anim", "Trot", 0.3)
			self:emit("move", c.TrotSpeed, "toward")
			self:enter("Hunt", 0)
		elseif not P.targetInLight and P.canAttack and self.t >= self.nextAttack and self.stateTime > 1.2 then
			self:emit("anim", "Attack", 0.1)
			self:emit("move", c.LungeSpeed, "lunge")
			self:emit("sound", "Snarl")
			self.bit = false
			self:enter("Attack", 0.85)
		elseif self.rng:NextNumber() < dt * 0.08 then
			self:emit("sound", "Growl")
		end
	elseif s == "Attack" then
		if not self.bit and self.stateTime >= 0.4 then
			self.bit = true
			if P.dist <= c.AttackReach then
				self:emit("bite")
			end
			self:emit("move", 0, "face")
		end
		if self.timer <= 0 then
			self.nextAttack = self.t + self:range(c.AttackCooldown)
			self:toCircle()
		end
	elseif s == "Hurt" then
		if self.timer <= 0 then
			self:toCircle()
		end
	elseif s == "Flee" then
		if self.timer <= 0 then
			if P.health < c.FleeHealth then
				self:flee()   -- sigue huyendo mientras esté muy herido
			else
				self:roam()
			end
		end
	end
	return self.out
end

return Brain
