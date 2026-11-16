--[[
	ShadowBrain (ModuleScript) · ReplicatedStorage.Dragons.ShadowDragon.ShadowBrain

	Lógica pura del comportamiento del Dragón Sombrío (sin Instances: se puede probar fuera de Roblox).
	El servidor le pasa cada tick lo que "percibe" y aplica las órdenes que devuelve.

	Estados:
	  Absent   no está. Espera un tiempo aleatorio largo antes de volver a aparecer.
	  Observe  quieto y lejos, mirando al objetivo. Ladea la cabeza de vez en cuando.
	  Frozen   alguien lo mira directamente: se queda inmóvil. Si dejan de mirarlo puede cambiar de
	           postura, acercarse de golpe, desaparecer o seguir observando.
	  Stalk    se acerca despacio solo mientras el objetivo no mira en su dirección.
	  Detect   levanta la cabeza muy despacio (te ha visto). Puede seguir un rugido o, rara vez, una persecución.
	  Roar     abre la sonrisa al máximo.
	  Chase    ráfaga corta y rápida hacia el objetivo; termina desvaneciéndose. Con enfriamiento largo.
	  Vanish   se desvanece poco a poco (por ejemplo, si te acercas demasiado).

	Percepción (tabla P) que entrega el servidor en cada Update:
	  hasTarget     hay un jugador objetivo válido
	  dist          distancia del dragón al objetivo (studs)
	  targetAngle   ángulo (grados) entre la mirada de la cámara del objetivo y el dragón
	  targetSees    el objetivo lo mira directamente y sin obstáculos
	  anySees       algún jugador lo mira directamente y sin obstáculos

	Órdenes devueltas (lista de tablas {cmd, ...}):
	  {"place", "far" | "closer"}   el servidor busca un sitio (lejos y en la periferia, o más cerca y fuera de la vista)
	  {"appear", segundos}          aparecer gradualmente
	  {"vanish", segundos}          desaparecer gradualmente
	  {"anim", nombre, fundido}     animación (la reproducen los clientes)
	  {"freeze", true|false}        congelar la pose tal como está / soltarla
	  {"pose", nombre}              cambiar a una postura extraña (mientras nadie mira)
	  {"move", velocidad}           avanzar hacia el objetivo (0 = parar)
	  {"tilt", grados}              inclinación de cabeza
	  {"silence", segundos}         silencio repentino del ambiente
	  {"sound", nombre}             sonido puntual en el dragón ("Creak", "Shriek")
	  {"newTarget"}                 elegir otro jugador objetivo
]]

local Brain = {}
Brain.__index = Brain

Brain.Defaults = {
	FirstAbsent = { 20, 45 },      -- primera aparición tras entrar
	Absent = { 45, 120 },          -- ausencia normal entre apariciones
	AbsentAfterVanish = { 35, 100 },
	Observe = { 18, 50 },          -- cuánto observa antes de irse o cambiar de sitio
	Presence = { 30, 70 },         -- tiempo total visible por aparición; luego se va (aunque lo mires)
	StareVanish = { 7, 16 },       -- si lo miras fijamente tanto tiempo, se disuelve delante de ti
	LookAngle = 16,                -- ángulo de "mirar directamente" (lo calcula el servidor)
	PeripheralAngle = 55,          -- más allá de esto, el objetivo no está mirando hacia él
	VanishDistance = 38,           -- si el objetivo se acerca tanto, se desvanece
	VanishFade = 2.6,
	AppearFade = 3.5,
	StalkSpeed = 5,
	StalkStop = { 32, 48 },
	StalkMaxTime = 14,
	StalkChance = 0.45,
	DetectChancePerSec = 0.1,
	ChaseChance = 0.22,
	ChaseCooldown = 240,
	ChaseSpeed = 34,
	ChaseTime = { 2.5, 4.0 },
	ChaseEnd = 12,
	RoarChance = 0.3,
	SilenceCooldown = 90,
	SilenceChancePerSec = 0.006,
}

function Brain.new(config, rng)
	local self = setmetatable({}, Brain)
	self.cfg = setmetatable(config or {}, { __index = Brain.Defaults })
	self.rng = rng or Random.new()
	self.state = "Absent"
	self.timer = self:range(self.cfg.FirstAbsent)
	self.t = 0
	self.lastChase = -1e9
	self.lastSilence = -1e9
	self.history = {}
	self.out = {}
	return self
end

function Brain:range(r)
	return r[1] + (r[2] - r[1]) * self.rng:NextNumber()
end

function Brain:chance(p)
	return self.rng:NextNumber() < p
end

-- Elige una opción con pesos, penalizando la que se usó la última vez (para no repetir patrones).
function Brain:pick(options)
	local total = 0
	for _, o in ipairs(options) do
		local w = o[2]
		if self.history[#self.history] == o[1] then
			w *= 0.35
		end
		o.w = w
		total += w
	end
	local x = self.rng:NextNumber() * total
	for _, o in ipairs(options) do
		x -= o.w
		if x <= 0 then
			table.insert(self.history, o[1])
			if #self.history > 6 then
				table.remove(self.history, 1)
			end
			return o[1]
		end
	end
	return options[#options][1]
end

function Brain:emit(...)
	table.insert(self.out, { ... })
end

function Brain:enter(state, timer)
	self.state = state
	self.timer = timer or 0
	self.stateTime = 0
end

-- Llamado por el servidor si no encontró un sitio para "place": vuelve a la ausencia un rato corto.
function Brain:PlaceFailed()
	self:emit("vanish", 0)
	self:enter("Absent", self:range({ 6, 14 }))
end

function Brain:toObserve()
	self:emit("move", 0)
	self:emit("freeze", false)
	self:emit("anim", self:chance(0.5) and "Watch" or "Idle", 1.2)
	self.unseen = 0
	self.nextTilt = self:range({ 3, 8 })
	self:enter("Observe", self:range(self.cfg.Observe))
end

function Brain:toVanish(fade)
	fade = fade or self.cfg.VanishFade
	self:emit("move", 0)
	self:emit("vanish", fade)
	self:emit("tilt", 0)
	if self:chance(0.3) and self.t - self.lastSilence > self.cfg.SilenceCooldown then
		self.lastSilence = self.t
		self:emit("silence", self:range({ 3, 7 }))
	end
	self:enter("Vanish", fade)
end

function Brain:toFrozen()
	self:emit("move", 0)
	self:emit("freeze", true)
	self.unseen = 0
	self.posed = false
	self.thaw = self:range({ 0.8, 3.0 })
	self.stare = 0
	self.stareLimit = self:range(self.cfg.StareVanish)
	self:enter("Frozen", 0)
end

function Brain:Update(dt, P)
	self.out = {}
	local c = self.cfg
	self.t += dt
	self.timer -= dt
	self.stateTime = (self.stateTime or 0) + dt
	local s = self.state

	if s == "Absent" then
		if self.t - self.lastSilence > c.SilenceCooldown and self:chance(c.SilenceChancePerSec * dt) then
			self.lastSilence = self.t
			self:emit("silence", self:range({ 3, 6 }))
		end
		if self.timer <= 0 then
			if not P.hasTarget then
				self.timer = 5
			else
				self:emit("newTarget")
				self:emit("place", "far")
				self:emit("tilt", 0)
				self:emit("appear", c.AppearFade)
				self.presence = self:range(c.Presence)
				self:toObserve()
			end
		end
		return self.out
	end

	-- límite de presencia: no se queda demasiado; se va despacio si lo miran, de golpe si no
	if s ~= "Vanish" and s ~= "Chase" and s ~= "Roar" then
		self.presence = (self.presence or 60) - dt
		if self.presence <= 0 then
			self:toVanish(P.anySees and 4.5 or 1.2)
			return self.out
		end
	end

	if not P.hasTarget then
		if s ~= "Vanish" then
			self:toVanish(1.5)
		end
	elseif s == "Observe" then
		if P.anySees then
			self:toFrozen()
		elseif P.dist < c.VanishDistance then
			self:toVanish()
		else
			self.unseen = (P.targetAngle > c.PeripheralAngle) and (self.unseen + dt) or 0
			self.nextTilt -= dt
			if self.nextTilt <= 0 then
				self.nextTilt = self:range({ 4, 11 })
				self:emit("tilt", self:chance(0.35) and 0 or (self:chance(0.5) and 1 or -1) * self:range({ 18, 48 }))
			end
			if P.targetAngle > c.LookAngle and P.targetAngle < 45 and self:chance(c.DetectChancePerSec * dt) then
				self:emit("tilt", 0)
				self:emit("anim", "Detect", 0.6)
				self:enter("Detect", 3.2 + self:range({ 0.8, 2.5 }))
			elseif self.unseen > 3 and P.dist > c.StalkStop[2] and self:chance(c.StalkChance * dt / 3) then
				self:emit("tilt", 0)
				self:emit("anim", "Walk", 0.5)
				self:emit("move", c.StalkSpeed)
				self.stalkStop = self:range(c.StalkStop)
				self:enter("Stalk", c.StalkMaxTime)
			elseif self.timer <= 0 then
				if P.targetAngle > c.PeripheralAngle and self:chance(0.4) then
					self:emit("vanish", 0)        -- se va mientras no lo miras...
					self:emit("place", "far")     -- ...y reaparece en otro sitio
					self:emit("appear", c.AppearFade)
					self:toObserve()
				else
					self:toVanish()
				end
			end
		end
	elseif s == "Frozen" then
		if P.dist < c.VanishDistance then
			self:toVanish()                       -- se disuelve delante de ti
		elseif P.anySees then
			self.unseen = 0
			self.stare = (self.stare or 0) + dt
			if self.stare > self.stareLimit then
				self:toVanish(4.5)                -- se disuelve mientras lo miras
			end
		else
			self.unseen += dt
			if not self.posed and self.unseen > 0.6 and self:chance(0.35) then
				self.posed = true                 -- al volver a mirar, está en otra postura
				local poses = { "Freeze1", "Freeze2", "Freeze3" }
				self:emit("pose", poses[self.rng:NextInteger(1, 3)])
			end
			if self.unseen > self.thaw then
				local choice = self:pick({ { "observe", 40 }, { "closer", 25 }, { "stalk", 20 }, { "gone", 15 } })
				if choice == "closer" and P.dist > c.VanishDistance + 25 then
					self:emit("place", "closer")
					self.unseen = 0
					self.thaw = self:range({ 1.0, 3.0 })
				elseif choice == "stalk" and P.dist > c.StalkStop[2] then
					self:emit("freeze", false)
					self:emit("anim", "Walk", 0.4)
					self:emit("move", c.StalkSpeed)
					self.stalkStop = self:range(c.StalkStop)
					self:enter("Stalk", c.StalkMaxTime)
				elseif choice == "gone" then
					self:toVanish(0.4)
				else
					self:toObserve()
				end
			end
		end
	elseif s == "Stalk" then
		if P.anySees then
			self:toFrozen()
		elseif P.dist < self.stalkStop or self.timer <= 0 then
			self:toObserve()
		elseif self.stateTime > 1 and self:chance(0.08 * dt) then
			self:emit("sound", "Creak")
		end
	elseif s == "Detect" then
		if P.dist < c.VanishDistance then
			self:toVanish()
		elseif P.anySees and self.stateTime > 0.3 then
			self:toFrozen()
		elseif self.timer <= 0 then
			local canChase = self.t - self.lastChase > c.ChaseCooldown and P.dist > c.ChaseEnd * 2
			if canChase and self:chance(c.ChaseChance) then
				self:emit("anim", "Roar", 0.3)
				self:emit("sound", "Shriek")
				self.thenChase = true
				self:enter("Roar", 3.0)
			elseif self:chance(c.RoarChance) then
				self:emit("anim", "Roar", 0.3)
				self:emit("sound", "Shriek")
				self.thenChase = false
				self:enter("Roar", 3.4)
			else
				self:toObserve()
			end
		end
	elseif s == "Roar" then
		if self.timer <= 0 then
			if self.thenChase then
				self.lastChase = self.t
				self:emit("anim", "Chase", 0.25)
				self:emit("move", c.ChaseSpeed)
				self:enter("Chase", self:range(c.ChaseTime))
			else
				self:toObserve()
			end
		end
	elseif s == "Chase" then
		if P.dist < c.ChaseEnd or self.timer <= 0 then
			self:toVanish(0.5)
			self.lastSilence = self.t
			self:emit("silence", self:range({ 4, 8 }))
		end
	elseif s == "Vanish" then
		if self.timer <= 0 then
			self:emit("freeze", false)
			self:emit("anim", "Idle", 0)
			self:enter("Absent", self:range(c.AbsentAfterVanish) * (self:chance(0.3) and 3 or 1))
		end
	end
	return self.out
end

--[[ Geometría auxiliar (también pura) ]]

-- Ángulo en grados entre la dirección de una cámara y un punto.
function Brain.AngleTo(camPos: Vector3, camLook: Vector3, point: Vector3): number
	local d = point - camPos
	if d.Magnitude < 1e-3 then
		return 0
	end
	local cos = math.clamp(camLook.Unit:Dot(d.Unit), -1, 1)
	return math.deg(math.acos(cos))
end

-- Puntuación de un sitio candidato para aparecer: lejos, en la visión periférica del objetivo
-- (ni delante ni detrás), fuera de la vista directa de todos, y mejor si hay algo cerca (árboles).
function Brain.ScoreSpot(kind: string, dist: number, angle: number, inAnyView: boolean, cover: number, cfg)
	cfg = cfg or Brain.Defaults
	if inAnyView then
		return -1
	end
	local score = 0
	if kind == "far" then
		if dist < 60 or dist > 170 then
			return -1
		end
		score += 1 - math.abs(dist - 100) / 70
		score += 1.5 * (1 - math.abs(angle - 70) / 70)    -- periferia: unos 70°
	else -- "closer"
		if dist < cfg.VanishDistance + 8 or dist > 90 then
			return -1
		end
		if angle < cfg.PeripheralAngle then
			return -1
		end
		score += 1 - math.abs(dist - (cfg.VanishDistance + 20)) / 40
	end
	return score + 0.6 * math.min(cover, 3) / 3
end

return Brain
