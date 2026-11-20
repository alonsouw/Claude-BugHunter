--[[
	INSTALADOR DE LOS LOBOS HUECOS · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	Pasos:
	  1. Studio > Avatar (o Home) > Import 3D > HollowWolf.fbx.
	     En el importador: Rig General > Rig Type = "Custom". No combines las mallas. Pulsa Import.
	     Aparece un modelo con la malla WolfBody y sus Bones.
	  2. Selecciona ese modelo en el Explorer.
	  3. View > Command Bar. Pega TODO este archivo y pulsa Enter.
	  4. (Opcional) Partes con la etiqueta "WolfSpawn" (o en Workspace.WolfSpawns): por dónde salen las manadas.
	     Partes con la etiqueta "SafeLight" (atributo Radius): zonas de luz donde los lobos no entran (la hoguera).

	Resultado:
	  ReplicatedStorage.Creatures.HollowWolf            (modelo, Settings, Animations, WolfBrain, DamageWolf)
	  ReplicatedStorage.Dragons.DragonAnimator          (motor de animación, compartido con los dragones)
	  ServerScriptService.WolfPack                      (manadas: salen de noche, cazan en grupo, se van al amanecer)
	  StarterPlayer.StarterPlayerScripts.WolfClient     (animación, ojos y movimiento suave)
	  ServerStorage.DragonAssets.HollowWolf_Rig         (copia de seguridad)
]]

-- Ajustes principales (también se pueden cambiar luego en ReplicatedStorage.Creatures.HollowWolf.Settings)
local PACKS = 2               -- manadas a la vez
local PACK_SIZE = 4           -- lobos por manada (1 alfa + 3)
local DAMAGE = 8              -- daño de cada mordisco (el alfa hace ALPHA_DAMAGE)
local ALPHA_DAMAGE = 15
local HEALTH = 60             -- vida de cada lobo (el alfa tiene ALPHA_HEALTH)
local ALPHA_HEALTH = 150
local NIGHT_ONLY = true       -- salen al anochecer y se van al amanecer
local SPAWN_CENTER = Vector3.new(0, 0, 0)
local SPAWN_RADIUS = 250
-- Opcional: tras subir los PNG (Asset Manager), pega aquí sus ids para crear SurfaceAppearance PBR.
local MAPS = {
	WolfBody = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
}
-- Sonidos: sube los .ogg de sounds/ y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = { Howl = "", Growl = "", Snarl = "", Bite = "", Yelp = "" }

local RIG = {
	{ name = "Root", parent = nil, head = { 0, 0, 1.2 }, tail = { 0, 1, 1.2 } },
	{ name = "Hips", parent = "Root", head = { 0, 2.45, 1.2 }, tail = { 0, 2.38, 0.25 } },
	{ name = "Spine", parent = "Hips", head = { 0, 2.38, 0.25 }, tail = { 0, 2.56, -0.62 } },
	{ name = "Chest", parent = "Spine", head = { 0, 2.56, -0.62 }, tail = { 0, 2.3, -0.98 } },
	{ name = "Neck1", parent = "Chest", head = { 0, 2.3, -0.98 }, tail = { 0, 2.7, -1.32 } },
	{ name = "Neck2", parent = "Neck1", head = { 0, 2.7, -1.32 }, tail = { 0, 2.98, -1.6 } },
	{ name = "Head", parent = "Neck2", head = { 0, 2.98, -1.6 }, tail = { 0, 2.7042, -2.604 } },
	{ name = "Jaw", parent = "Head", head = { 0, 2.83, -1.8124 }, tail = { 0, 2.6133, -2.4607 } },
	{ name = "EarL", parent = "Head", head = { -0.13, 3.1241, -1.7347 }, tail = { -0.21, 3.4723, -1.6896 } },
	{ name = "EarR", parent = "Head", head = { 0.13, 3.1241, -1.7347 }, tail = { 0.21, 3.4723, -1.6896 } },
	{ name = "Tail1", parent = "Hips", head = { 0, 2.42, 1.62 }, tail = { 0, 2.22, 2.02 } },
	{ name = "Tail2", parent = "Tail1", head = { 0, 2.22, 2.02 }, tail = { 0, 1.8, 2.36 } },
	{ name = "Tail3", parent = "Tail2", head = { 0, 1.8, 2.36 }, tail = { 0, 1.38, 2.55 } },
	{ name = "Tail4", parent = "Tail3", head = { 0, 1.38, 2.55 }, tail = { 0, 1, 2.62 } },
	{ name = "LegFL_Upper", parent = "Chest", head = { -0.26, 2.12, -0.66 }, tail = { -0.25, 1.42, -0.56 } },
	{ name = "LegFL_Lower", parent = "LegFL_Upper", head = { -0.25, 1.42, -0.56 }, tail = { -0.22, 0.55, -0.66 } },
	{ name = "LegFL_Cannon", parent = "LegFL_Lower", head = { -0.22, 0.55, -0.66 }, tail = { -0.22, 0.1, -0.76 } },
	{ name = "LegFL_Paw", parent = "LegFL_Cannon", head = { -0.22, 0.1, -0.76 }, tail = { -0.22, 0.02, -0.98 } },
	{ name = "LegBL_Upper", parent = "Hips", head = { -0.28, 2.25, 1.15 }, tail = { -0.3, 1.5, 0.8 } },
	{ name = "LegBL_Lower", parent = "LegBL_Upper", head = { -0.3, 1.5, 0.8 }, tail = { -0.25, 0.86, 1.36 } },
	{ name = "LegBL_Cannon", parent = "LegBL_Lower", head = { -0.25, 0.86, 1.36 }, tail = { -0.23, 0.1, 1.26 } },
	{ name = "LegBL_Paw", parent = "LegBL_Cannon", head = { -0.23, 0.1, 1.26 }, tail = { -0.23, 0.02, 1.05 } },
	{ name = "LegFR_Upper", parent = "Chest", head = { 0.26, 2.12, -0.66 }, tail = { 0.25, 1.42, -0.56 } },
	{ name = "LegFR_Lower", parent = "LegFR_Upper", head = { 0.25, 1.42, -0.56 }, tail = { 0.22, 0.55, -0.66 } },
	{ name = "LegFR_Cannon", parent = "LegFR_Lower", head = { 0.22, 0.55, -0.66 }, tail = { 0.22, 0.1, -0.76 } },
	{ name = "LegFR_Paw", parent = "LegFR_Cannon", head = { 0.22, 0.1, -0.76 }, tail = { 0.22, 0.02, -0.98 } },
	{ name = "LegBR_Upper", parent = "Hips", head = { 0.28, 2.25, 1.15 }, tail = { 0.3, 1.5, 0.8 } },
	{ name = "LegBR_Lower", parent = "LegBR_Upper", head = { 0.3, 1.5, 0.8 }, tail = { 0.25, 0.86, 1.36 } },
	{ name = "LegBR_Cannon", parent = "LegBR_Lower", head = { 0.25, 0.86, 1.36 }, tail = { 0.23, 0.1, 1.26 } },
	{ name = "LegBR_Paw", parent = "LegBR_Cannon", head = { 0.23, 0.1, 1.26 }, tail = { 0.23, 0.02, 1.05 } },
}
local EYES = { { -0.1695, 2.9495, -2.059 }, { 0.1695, 2.9495, -2.059 } }
local SOURCES = {
	DragonAnimator = [=======[
--[[
	DragonAnimator (ModuleScript) · ReplicatedStorage.Dragons.DragonAnimator

	Reproduce animaciones definidas como datos sobre un rig de Motor6D (piezas rígidas)
	o de Bones (malla con skinning). No necesita subir assets de animación: escribe
	Motor6D.Transform o Bone.Transform cada frame.

	Uso:
		local animator = DragonAnimator.new(model, require(animsModule))
		animator:Play("Idle")
		animator.Finished.Event:Connect(function(name) ... end)
		animator:SetLookTarget(player.Character.Head)   -- opcional: la cabeza sigue al objetivo
		animator:Destroy()

	Opciones (todas opcionales; sin tocarlas el comportamiento es el de siempre):
		animator.Paused = true          -- congela la pose tal como está (no escribe nada: coste cero)
		animator.UpdateInterval = 1/15  -- evalúa menos veces por segundo (lejos de la cámara)
		animator.Speed = 0.5            -- velocidad de reproducción
		animator:SetHeadTilt(35, 1.5)   -- inclina la cabeza 35° (alabeo) y llega a esa inclinación a ritmo 1.5

	Formato de cada articulación (nombre = Part1 del Motor6D o nombre del Bone):
		k = { {t, rx, ry, rz}, ... }   claves de rotación en grados
		p = { {t, x, y, z}, ... }      claves de traslación en studs del modelo original (se multiplican por RigScale)
		o = { {"eje", amplitud, ciclos, fase}, ... }   ejes "x","y","z" (grados) o "px","py","pz" (studs)
	Los ángulos se expresan en los ejes del modelo (Y arriba, el dragón mira a -Z). Para los Bones,
	el animador los convierte al marco local de cada hueso con su orientación de reposo.
]]

local RunService = game:GetService("RunService")

local DragonAnimator = {}
DragonAnimator.__index = DragonAnimator

local function smooth(x: number): number
	return x * x * (3 - 2 * x)
end

local function sampleKeys(keys, t: number, dur: number, loop: boolean)
	if keys == nil or #keys == 0 then
		return nil
	end
	local first = keys[1]
	if #keys == 1 or t <= first[1] then
		return { first[2], first[3], first[4] }
	end
	for i = 1, #keys - 1 do
		local a, b = keys[i], keys[i + 1]
		if t <= b[1] then
			local f = smooth((t - a[1]) / math.max(b[1] - a[1], 1e-6))
			return { a[2] + (b[2] - a[2]) * f, a[3] + (b[3] - a[3]) * f, a[4] + (b[4] - a[4]) * f }
		end
	end
	local last = keys[#keys]
	if loop then
		local f = smooth((t - last[1]) / math.max(dur - last[1], 1e-6))
		return { last[2] + (first[2] - last[2]) * f, last[3] + (first[3] - last[3]) * f, last[4] + (first[4] - last[4]) * f }
	end
	return { last[2], last[3], last[4] }
end

-- Devuelve rx, ry, rz (grados) y px, py, pz (studs) de una articulación en el instante t.
function DragonAnimator.EvalJoint(joint, t: number, dur: number, loop: boolean)
	local r = sampleKeys(joint.k, t, dur, loop) or { 0, 0, 0 }
	local p = sampleKeys(joint.p, t, dur, loop) or { 0, 0, 0 }
	if joint.o then
		for _, osc in ipairs(joint.o) do
			local axis, amp, cycles, phase = osc[1], osc[2], osc[3], osc[4]
			local v = amp * math.sin(2 * math.pi * (cycles * t / dur + phase))
			if axis == "x" then
				r[1] += v
			elseif axis == "y" then
				r[2] += v
			elseif axis == "z" then
				r[3] += v
			elseif axis == "px" then
				p[1] += v
			elseif axis == "py" then
				p[2] += v
			elseif axis == "pz" then
				p[3] += v
			end
		end
	end
	return r, p
end

function DragonAnimator.new(model: Model, animations)
	local self = setmetatable({}, DragonAnimator)
	self.Model = model
	self.Animations = animations
	self.Scale = model:GetAttribute("RigScale") or 1
	self.Joints = {}
	local pivot = model:GetPivot()
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") and d.Part1 then
			self.Joints[d.Part1.Name] = { inst = d, kind = "motor" }
		elseif d:IsA("Bone") then
			d.Transform = CFrame.identity
			-- orientación de reposo del hueso en los ejes del modelo
			local rest = (pivot:Inverse() * d.WorldCFrame).Rotation
			local entry = { inst = d, rest = rest, restInv = rest:Inverse() }
			local j = self.Joints[d.Name]
			if j and j.kind == "bone" then
				table.insert(j.copies, entry) -- el importador puede duplicar el esqueleto por malla
			else
				self.Joints[d.Name] = { inst = d, kind = "bone", rest = rest, restInv = entry.restInv, copies = { entry } }
			end
		end
	end
	self.Values = {} -- último valor aplicado por articulación: {rx, ry, rz, px, py, pz}
	self.From = {}
	self.Current = nil
	self.Time = 0
	self.FadeTime = 0.25
	self.FadeElapsed = 0
	self.Speed = 1
	self.Finished = Instance.new("BindableEvent")
	self.Paused = false
	self.UpdateInterval = 0
	self._acc = 0
	self._conn = RunService.Stepped:Connect(function(_, dt)
		if self.Paused then
			return
		end
		local iv = self.UpdateInterval
		if iv and iv > 0 then
			self._acc += dt
			if self._acc < iv then
				return
			end
			dt, self._acc = self._acc, 0
		end
		self:Step(dt)
	end)
	return self
end

-- Escribe en la articulación una transformación expresada en los ejes del modelo.
local function setJoint(j, m: CFrame)
	if j.kind == "bone" then
		for _, c in ipairs(j.copies) do
			c.inst.Transform = c.restInv * m * c.rest
		end
	else
		j.inst.Transform = m
	end
end

function DragonAnimator:Play(name: string, fadeTime: number?)
	local anim = self.Animations[name]
	assert(anim, "Animación desconocida: " .. tostring(name))
	self.From = {}
	for jointName, v in pairs(self.Values) do
		self.From[jointName] = table.clone(v)
	end
	self.Current = name
	self.Time = 0
	self.FadeTime = fadeTime or 0.25
	self.FadeElapsed = 0
	self._done = false
end

function DragonAnimator:Step(dt: number)
	local name = self.Current
	if not name then
		return
	end
	local anim = self.Animations[name]
	self.Time += dt * self.Speed
	self.FadeElapsed += dt
	if not anim.loop and self.Time >= anim.dur then
		if anim.next then
			self:Play(anim.next, 0.2)
			self.Finished:Fire(name)
			return self:Step(0)
		end
		self.Time = anim.dur
		if not self._done then
			self._done = true
			task.defer(function()
				self.Finished:Fire(name)
			end)
		end
	end
	local t = anim.loop and (self.Time % anim.dur) or self.Time
	local w = self.FadeTime > 0 and smooth(math.clamp(self.FadeElapsed / self.FadeTime, 0, 1)) or 1
	local s = self.Scale
	local frames = {}
	for jointName in pairs(self.Joints) do
		local j = anim.joints[jointName]
		local v
		if j then
			local r, p = DragonAnimator.EvalJoint(j, t, anim.dur, anim.loop)
			v = { r[1], r[2], r[3], p[1], p[2], p[3] }
		else
			v = { 0, 0, 0, 0, 0, 0 }
		end
		local from = self.From[jointName]
		if from and w < 1 then
			for i = 1, 6 do
				v[i] = from[i] + (v[i] - from[i]) * w
			end
		end
		self.Values[jointName] = v
		frames[jointName] = CFrame.new(v[4] * s, v[5] * s, v[6] * s)
			* CFrame.Angles(math.rad(v[1]), math.rad(v[2]), math.rad(v[3]))
	end
	self:_applyLook(dt, frames)
	self:_applyTilt(dt, frames)
	for jointName, m in pairs(frames) do
		setJoint(self.Joints[jointName], m)
	end
end

local function resolveTarget(target): Vector3?
	if typeof(target) == "Vector3" then
		return target
	elseif typeof(target) == "Instance" then
		if target:IsA("BasePart") then
			return target.Position
		elseif target:IsA("Model") then
			return target:GetPivot().Position
		end
	elseif type(target) == "function" then
		return target()
	end
	return nil
end

--[[
	Seguimiento de mirada: la cabeza (y una parte del cuello) gira hacia el objetivo,
	sumado encima de la animación. target: BasePart, Model, Vector3, función que devuelve
	Vector3, o nil para soltarlo.
	options: Head ("Head"), Neck ("Neck2"), NeckShare (0.35), MaxYaw (75), MaxPitch (35),
	         RestPitch (grados que apunta el hocico en reposo; negativo = hacia abajo), Speed (5)
]]
function DragonAnimator:SetLookTarget(target, options)
	self.LookTarget = target
	if options then
		self.LookOptions = options
	end
	self.LookOptions = self.LookOptions or {}
	self.LookYaw = self.LookYaw or 0
	self.LookPitch = self.LookPitch or 0
end

-- Marco (en ejes del modelo) del pivote de una articulación, sin su propia transformación.
local function baseFrame(j): CFrame?
	if j.kind == "bone" then
		local b = j.inst
		local parent = b.Parent
		local pcf = parent:IsA("Bone") and parent.TransformedWorldCFrame or (parent:IsA("BasePart") and parent.CFrame)
		if not pcf then
			return nil
		end
		return pcf * b.CFrame * j.restInv
	end
	local m = j.inst
	if not m.Part0 then
		return nil
	end
	return m.Part0.CFrame * m.C0
end

local function pivotPosition(j): Vector3?
	if j.kind == "bone" then
		return j.inst.TransformedWorldCFrame.Position
	end
	local m = j.inst
	return m.Part0 and (m.Part0.CFrame * m.C0).Position or nil
end

function DragonAnimator:_applyLook(dt: number, frames)
	if self.LookYaw == nil then
		return
	end
	local o = self.LookOptions or {}
	local headName, neckName = o.Head or "Head", o.Neck or "Neck2"
	local head, neck = self.Joints[headName], self.Joints[neckName]
	if not head or not neck then
		return
	end
	local goalYaw, goalPitch = 0, 0
	local pos = resolveTarget(self.LookTarget)
	local base = baseFrame(neck)
	local headPivot = pivotPosition(head)
	if pos and base and headPivot then
		local p = base:VectorToObjectSpace(pos - headPivot)
		local maxYaw, maxPitch = math.rad(o.MaxYaw or 75), math.rad(o.MaxPitch or 35)
		goalYaw = math.clamp(math.atan2(-p.X, -p.Z), -maxYaw, maxYaw)
		goalPitch = math.clamp(math.atan2(p.Y, math.sqrt(p.X * p.X + p.Z * p.Z)) - math.rad(o.RestPitch or 0), -maxPitch, maxPitch)
	end
	local k = math.min(1, dt * (o.Speed or 5))
	self.LookYaw += (goalYaw - self.LookYaw) * k
	self.LookPitch += (goalPitch - self.LookPitch) * k
	local share = o.NeckShare or 0.35
	frames[neckName] = CFrame.Angles(0, self.LookYaw * share, 0) * CFrame.Angles(self.LookPitch * share, 0, 0) * (frames[neckName] or CFrame.identity)
	frames[headName] = CFrame.Angles(0, self.LookYaw * (1 - share), 0) * CFrame.Angles(self.LookPitch * (1 - share), 0, 0) * (frames[headName] or CFrame.identity)
end

--[[
	Inclinación de cabeza (alabeo alrededor del eje del hocico), sumada encima de la animación y
	de la mirada. degrees = 0 la endereza; speed controla lo rápido que llega (por defecto 2).
]]
function DragonAnimator:SetHeadTilt(degrees: number, speed: number?, headName: string?)
	self.TiltGoal = degrees
	self.TiltSpeed = speed or 2
	self.TiltHead = headName or self.TiltHead or "Head"
	self.Tilt = self.Tilt or 0
end

function DragonAnimator:_applyTilt(dt: number, frames)
	if self.TiltGoal == nil then
		return
	end
	self.Tilt += (self.TiltGoal - self.Tilt) * math.min(1, dt * self.TiltSpeed)
	local h = self.TiltHead
	if self.Joints[h] then
		frames[h] = CFrame.Angles(0, 0, math.rad(self.Tilt)) * (frames[h] or CFrame.identity)
	end
end

function DragonAnimator:Destroy()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
	for _, j in pairs(self.Joints) do
		for _, c in ipairs(j.copies or { j }) do
			c.inst.Transform = CFrame.identity
		end
	end
	self.Finished:Destroy()
end

return DragonAnimator
]=======],
	Animations = [=======[
--[[
	Animaciones del lobo hueco (ModuleScript) · ReplicatedStorage.Creatures.HollowWolf.Animations
	Generado desde src/wolf_anims.js y model/rig.json con tools/build_roblox.js: edita la fuente y regenera.
	Formato: ver DragonAnimator. Ángulos en grados, traslaciones en studs, tiempos en segundos.
]]
return {
	Idle = {
		dur = 5,
		loop = true,
		joints = {
			Tail1 = {
				k = {
					{ 0, 1.5, 0, 0 },
				},
				o = {
					{ "y", 2.4, 1, 0.08 },
				},
			},
			Tail2 = {
				k = {
					{ 0, 1.5, 0, 0 },
				},
				o = {
					{ "y", 3.2, 1, 0.16 },
				},
			},
			Tail3 = {
				k = {
					{ 0, 1.5, 0, 0 },
				},
				o = {
					{ "y", 4, 1, 0.24 },
				},
			},
			Tail4 = {
				k = {
					{ 0, 1.5, 0, 0 },
				},
				o = {
					{ "y", 4.8, 1, 0.32 },
				},
			},
			EarL = {
				o = {
					{ "x", 4, 3, 0 },
					{ "z", 2, 3, 0.3 },
				},
				k = {
					{ 0, 0, 0, 0 },
					{ 2.2, 0, 0, 0 },
					{ 2.3, 25, 0, -10 },
					{ 2.45, 0, 0, 0 },
				},
			},
			EarR = {
				o = {
					{ "x", 4, 3, 0.5 },
					{ "z", -2, 3, 0.8 },
				},
			},
			Chest = {
				o = {
					{ "x", 1.5, 2, 0 },
				},
			},
			Spine = {
				o = {
					{ "x", 1, 2, 0.1 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.02, 2, 0 },
				},
			},
			Neck1 = {
				o = {
					{ "y", 6, 1, 0 },
				},
			},
			Head = {
				o = {
					{ "y", 5, 1, 0.3 },
					{ "x", 3, 1, 0.6 },
				},
			},
			Jaw = {
				o = {
					{ "x", -2, 2, 0 },
				},
			},
		},
	},
	Sniff = {
		dur = 3,
		loop = true,
		joints = {
			Tail1 = {
				k = {
					{ 0, 0, 0, 0 },
				},
				o = {
					{ "y", 4.8, 2, 0.08 },
				},
			},
			Tail2 = {
				k = {
					{ 0, 0, 0, 0 },
				},
				o = {
					{ "y", 6.4, 2, 0.16 },
				},
			},
			Tail3 = {
				k = {
					{ 0, 0, 0, 0 },
				},
				o = {
					{ "y", 8, 2, 0.24 },
				},
			},
			Tail4 = {
				k = {
					{ 0, 0, 0, 0 },
				},
				o = {
					{ "y", 9.6, 2, 0.32 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -38, 0, 0 },
				},
				o = {
					{ "y", 10, 1, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, -15, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, -20, 0, 0 },
				},
				o = {
					{ "x", 4, 9, 0 },
				},
			},
			Chest = {
				k = {
					{ 0, -4, 0, 0 },
				},
				p = {
					{ 0, 0, -0.12, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, -10, 0, 0 },
				},
			},
			EarR = {
				k = {
					{ 0, -10, 0, 0 },
				},
			},
		},
	},
	Walk = {
		dur = 1.3,
		loop = true,
		joints = {
			Tail1 = {
				k = {
					{ 0, 2.5, 0, 0 },
				},
				o = {
					{ "y", 4.8, 1, 0.18 },
				},
			},
			Tail2 = {
				k = {
					{ 0, 2.5, 0, 0 },
				},
				o = {
					{ "y", 6.4, 1, 0.26 },
				},
			},
			Tail3 = {
				k = {
					{ 0, 2.5, 0, 0 },
				},
				o = {
					{ "y", 8, 1, 0.34 },
				},
			},
			Tail4 = {
				k = {
					{ 0, 2.5, 0, 0 },
				},
				o = {
					{ "y", 9.6, 1, 0.42 },
				},
			},
			EarL = {
				o = {
					{ "x", 3, 2, 0 },
					{ "z", 1.5, 2, 0.3 },
				},
			},
			EarR = {
				o = {
					{ "x", 3, 2, 0.5 },
					{ "z", -1.5, 2, 0.8 },
				},
			},
			LegFL_Upper = {
				o = {
					{ "x", 20, 1, 0 },
				},
			},
			LegFL_Lower = {
				o = {
					{ "x", 18, 1, 0.15 },
				},
			},
			LegFL_Cannon = {
				o = {
					{ "x", 14, 1, 0.3 },
				},
			},
			LegFL_Paw = {
				o = {
					{ "x", 16, 1, 0.4 },
				},
			},
			LegFR_Upper = {
				o = {
					{ "x", 20, 1, 0.5 },
				},
			},
			LegFR_Lower = {
				o = {
					{ "x", 18, 1, 0.65 },
				},
			},
			LegFR_Cannon = {
				o = {
					{ "x", 14, 1, 0.8 },
				},
			},
			LegFR_Paw = {
				o = {
					{ "x", 16, 1, 0.9 },
				},
			},
			LegBL_Upper = {
				o = {
					{ "x", 20, 1, 0.55 },
				},
			},
			LegBL_Lower = {
				o = {
					{ "x", -18, 1, 0.7 },
				},
			},
			LegBL_Cannon = {
				o = {
					{ "x", 14, 1, 0.85 },
				},
			},
			LegBL_Paw = {
				o = {
					{ "x", 16, 1, 0.95 },
				},
			},
			LegBR_Upper = {
				o = {
					{ "x", 20, 1, 0.05 },
				},
			},
			LegBR_Lower = {
				o = {
					{ "x", -18, 1, 0.2 },
				},
			},
			LegBR_Cannon = {
				o = {
					{ "x", 14, 1, 0.35 },
				},
			},
			LegBR_Paw = {
				o = {
					{ "x", 16, 1, 0.45 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.04, 2, 0.1 },
					{ "z", 2, 1, 0 },
				},
			},
			Chest = {
				o = {
					{ "z", -2, 1, 0.1 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -8, 0, 0 },
				},
				o = {
					{ "x", 3, 2, 0.2 },
				},
			},
			Head = {
				k = {
					{ 0, 4, 0, 0 },
				},
			},
		},
	},
	Trot = {
		dur = 0.75,
		loop = true,
		joints = {
			Tail1 = {
				k = {
					{ 0, 1, 0, 0 },
				},
				o = {
					{ "y", 3.6, 1, 0.18 },
				},
			},
			Tail2 = {
				k = {
					{ 0, 1, 0, 0 },
				},
				o = {
					{ "y", 4.8, 1, 0.26 },
				},
			},
			Tail3 = {
				k = {
					{ 0, 1, 0, 0 },
				},
				o = {
					{ "y", 6, 1, 0.34 },
				},
			},
			Tail4 = {
				k = {
					{ 0, 1, 0, 0 },
				},
				o = {
					{ "y", 7.2, 1, 0.42 },
				},
			},
			LegFL_Upper = {
				o = {
					{ "x", 26, 1, 0 },
				},
			},
			LegFL_Lower = {
				o = {
					{ "x", 22, 1, 0.15 },
				},
			},
			LegFL_Cannon = {
				o = {
					{ "x", 18, 1, 0.3 },
				},
			},
			LegFL_Paw = {
				o = {
					{ "x", 20, 1, 0.4 },
				},
			},
			LegFR_Upper = {
				o = {
					{ "x", 26, 1, 0.5 },
				},
			},
			LegFR_Lower = {
				o = {
					{ "x", 22, 1, 0.65 },
				},
			},
			LegFR_Cannon = {
				o = {
					{ "x", 18, 1, 0.8 },
				},
			},
			LegFR_Paw = {
				o = {
					{ "x", 20, 1, 0.9 },
				},
			},
			LegBL_Upper = {
				o = {
					{ "x", 26, 1, 0.52 },
				},
			},
			LegBL_Lower = {
				o = {
					{ "x", -22, 1, 0.67 },
				},
			},
			LegBL_Cannon = {
				o = {
					{ "x", 18, 1, 0.82 },
				},
			},
			LegBL_Paw = {
				o = {
					{ "x", 20, 1, 0.92 },
				},
			},
			LegBR_Upper = {
				o = {
					{ "x", 26, 1, 0.02 },
				},
			},
			LegBR_Lower = {
				o = {
					{ "x", -22, 1, 0.17 },
				},
			},
			LegBR_Cannon = {
				o = {
					{ "x", 18, 1, 0.32 },
				},
			},
			LegBR_Paw = {
				o = {
					{ "x", 20, 1, 0.42 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.08, 2, 0.1 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -18, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 12, 0, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, -8, 0, 0 },
				},
			},
			EarR = {
				k = {
					{ 0, -8, 0, 0 },
				},
			},
		},
	},
	Run = {
		dur = 0.48,
		loop = true,
		joints = {
			Tail1 = {
				k = {
					{ 0, 7.5, 0, 0 },
				},
				o = {
					{ "x", 3.6, 1, 0.38 },
				},
			},
			Tail2 = {
				k = {
					{ 0, 7.5, 0, 0 },
				},
				o = {
					{ "x", 4.8, 1, 0.46 },
				},
			},
			Tail3 = {
				k = {
					{ 0, 7.5, 0, 0 },
				},
				o = {
					{ "x", 6, 1, 0.54 },
				},
			},
			Tail4 = {
				k = {
					{ 0, 7.5, 0, 0 },
				},
				o = {
					{ "x", 7.2, 1, 0.62 },
				},
			},
			LegFL_Upper = {
				o = {
					{ "x", 36, 1, 0 },
				},
			},
			LegFL_Lower = {
				o = {
					{ "x", 30, 1, 0.15 },
				},
			},
			LegFL_Cannon = {
				o = {
					{ "x", 24, 1, 0.3 },
				},
			},
			LegFL_Paw = {
				o = {
					{ "x", 28, 1, 0.4 },
				},
			},
			LegFR_Upper = {
				o = {
					{ "x", 36, 1, 0.08 },
				},
			},
			LegFR_Lower = {
				o = {
					{ "x", 30, 1, 0.23 },
				},
			},
			LegFR_Cannon = {
				o = {
					{ "x", 24, 1, 0.38 },
				},
			},
			LegFR_Paw = {
				o = {
					{ "x", 28, 1, 0.48 },
				},
			},
			LegBL_Upper = {
				o = {
					{ "x", 36, 1, 0.5 },
				},
			},
			LegBL_Lower = {
				o = {
					{ "x", -30, 1, 0.65 },
				},
			},
			LegBL_Cannon = {
				o = {
					{ "x", 24, 1, 0.8 },
				},
			},
			LegBL_Paw = {
				o = {
					{ "x", 28, 1, 0.9 },
				},
			},
			LegBR_Upper = {
				o = {
					{ "x", 36, 1, 0.58 },
				},
			},
			LegBR_Lower = {
				o = {
					{ "x", -30, 1, 0.73 },
				},
			},
			LegBR_Cannon = {
				o = {
					{ "x", 24, 1, 0.88 },
				},
			},
			LegBR_Paw = {
				o = {
					{ "x", 28, 1, 0.98 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.18, 1, 0.25 },
					{ "x", 7, 1, 0 },
				},
			},
			Spine = {
				o = {
					{ "x", 7, 1, 0.5 },
				},
			},
			Chest = {
				o = {
					{ "x", 5, 1, 0.5 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -22, 0, 0 },
				},
				o = {
					{ "x", 5, 1, 0.3 },
				},
			},
			Head = {
				k = {
					{ 0, 18, 0, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -8, 0, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, 35, 0, 0 },
				},
			},
			EarR = {
				k = {
					{ 0, 35, 0, 0 },
				},
			},
		},
	},
	Howl = {
		dur = 3.4,
		loop = false,
		next = "Idle",
		joints = {
			Hips = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, -10, 0, 0 },
					{ 2.8, -10, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 0.6, 0, -0.35, 0.1 },
					{ 2.8, 0, -0.35, 0.1 },
					{ 3.4, 0, 0, 0 },
				},
			},
			LegBL_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, 30, 0, 0 },
					{ 2.8, 30, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			LegBR_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, 30, 0, 0 },
					{ 2.8, 30, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			LegBL_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, -30, 0, 0 },
					{ 2.8, -30, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			LegBR_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, -30, 0, 0 },
					{ 2.8, -30, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, 32, 0, 0 },
					{ 2.8, 34, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, 18, 0, 0 },
					{ 2.8, 18, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, 30, 0, 0 },
					{ 2.8, 34, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
				o = {
					{ "z", 1.5, 30, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.8, -24, 0, 0 },
					{ 2.6, -20, 0, 0 },
					{ 3, 0, 0, 0 },
				},
				o = {
					{ "x", 1.5, 26, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, 25, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			EarR = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, 25, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			Tail1 = {
				k = {
					{ 0, 0, 0, 0 },
				},
				o = {
					{ "y", 1.8, 3, 0.08 },
				},
			},
			Tail2 = {
				k = {
					{ 0, 0, 0, 0 },
				},
				o = {
					{ "y", 2.4, 3, 0.16 },
				},
			},
			Tail3 = {
				k = {
					{ 0, 0, 0, 0 },
				},
				o = {
					{ "y", 3, 3, 0.24 },
				},
			},
			Tail4 = {
				k = {
					{ 0, 0, 0, 0 },
				},
				o = {
					{ "y", 3.6, 3, 0.32 },
				},
			},
		},
	},
	Growl = {
		dur = 2.4,
		loop = true,
		joints = {
			Tail1 = {
				k = {
					{ 0, 4.5, 0, 0 },
				},
				o = {
					{ "y", 1.2, 6, 0.08 },
				},
			},
			Tail2 = {
				k = {
					{ 0, 4.5, 0, 0 },
				},
				o = {
					{ "y", 1.6, 6, 0.16 },
				},
			},
			Tail3 = {
				k = {
					{ 0, 4.5, 0, 0 },
				},
				o = {
					{ "y", 2, 6, 0.24 },
				},
			},
			Tail4 = {
				k = {
					{ 0, 4.5, 0, 0 },
				},
				o = {
					{ "y", 2.4, 6, 0.32 },
				},
			},
			Hips = {
				p = {
					{ 0, 0, -0.18, 0 },
				},
			},
			Chest = {
				k = {
					{ 0, -6, 0, 0 },
				},
				p = {
					{ 0, 0, -0.22, 0 },
				},
				o = {
					{ "x", 1, 22, 0 },
				},
			},
			Spine = {
				o = {
					{ "z", 0.8, 18, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -22, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, -6, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 16, 0, 0 },
				},
				o = {
					{ "x", 1.5, 14, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -14, 0, 0 },
				},
				o = {
					{ "x", 3, 6, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, 45, 0, -10 },
				},
			},
			EarR = {
				k = {
					{ 0, 45, 0, 10 },
				},
			},
			LegFL_Upper = {
				k = {
					{ 0, -12, 0, 0 },
				},
			},
			LegFR_Upper = {
				k = {
					{ 0, -12, 0, 0 },
				},
			},
			LegFL_Lower = {
				k = {
					{ 0, -15, 0, 0 },
				},
			},
			LegFR_Lower = {
				k = {
					{ 0, -15, 0, 0 },
				},
			},
			LegBL_Upper = {
				k = {
					{ 0, 10, 0, 0 },
				},
			},
			LegBR_Upper = {
				k = {
					{ 0, 10, 0, 0 },
				},
			},
		},
	},
	Attack = {
		dur = 0.85,
		loop = false,
		next = "Growl",
		joints = {
			Hips = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.25, 6, 0, 0 },
					{ 0.45, -10, 0, 0 },
					{ 0.85, 0, 0, 0 },
				},
				p = {
					{ 0, 0, -0.18, 0 },
					{ 0.25, 0, -0.3, 0.2 },
					{ 0.45, 0, 0.35, -1 },
					{ 0.6, 0, 0.1, -1.1 },
					{ 0.85, 0, 0, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -22, 0, 0 },
					{ 0.25, -30, 0, 0 },
					{ 0.45, -5, 0, 0 },
					{ 0.85, -20, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 16, 0, 0 },
					{ 0.45, 5, 0, 0 },
					{ 0.85, 16, 0, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -14, 0, 0 },
					{ 0.3, -38, 0, 0 },
					{ 0.48, -40, 0, 0 },
					{ 0.55, 0, 0, 0 },
					{ 0.85, -12, 0, 0 },
				},
			},
			LegFL_Upper = {
				k = {
					{ 0, -12, 0, 0 },
					{ 0.25, -25, 0, 0 },
					{ 0.45, 45, 0, 0 },
					{ 0.85, -10, 0, 0 },
				},
			},
			LegFR_Upper = {
				k = {
					{ 0, -12, 0, 0 },
					{ 0.25, -25, 0, 0 },
					{ 0.45, 45, 0, 0 },
					{ 0.85, -10, 0, 0 },
				},
			},
			LegBL_Upper = {
				k = {
					{ 0, 10, 0, 0 },
					{ 0.25, 30, 0, 0 },
					{ 0.45, -35, 0, 0 },
					{ 0.85, 10, 0, 0 },
				},
			},
			LegBR_Upper = {
				k = {
					{ 0, 10, 0, 0 },
					{ 0.25, 30, 0, 0 },
					{ 0.45, -35, 0, 0 },
					{ 0.85, 10, 0, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, 45, 0, 0 },
				},
			},
			EarR = {
				k = {
					{ 0, 45, 0, 0 },
				},
			},
			Tail1 = {
				k = {
					{ 0, -10, 0, 0 },
					{ 0.45, -30, 0, 0 },
					{ 0.85, -10, 0, 0 },
				},
			},
		},
	},
	Hurt = {
		dur = 0.55,
		loop = false,
		next = "Growl",
		joints = {
			Hips = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.12, 0, 0, 10 },
					{ 0.55, 0, 0, 0 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 0.12, 0.15, -0.1, 0.25 },
					{ 0.55, 0, 0, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.12, 15, 18, 0 },
					{ 0.55, 0, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.12, 10, 0, 15 },
					{ 0.55, 0, 0, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.1, -25, 0, 0 },
					{ 0.4, 0, 0, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.1, 50, 0, 0 },
					{ 0.55, 0, 0, 0 },
				},
			},
			EarR = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.1, 50, 0, 0 },
					{ 0.55, 0, 0, 0 },
				},
			},
			Tail1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.12, 35, 0, 0 },
					{ 0.55, 0, 0, 0 },
				},
			},
		},
	},
	Death = {
		dur = 1.8,
		loop = false,
		joints = {
			Hips = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, 0, -20 },
					{ 1.2, 0, 0, -84 },
					{ 1.8, 0, 0, -88 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 1.2, 0, -1.55, 0 },
					{ 1.8, 0, -1.7, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.3, -30, 0, -10 },
					{ 1.8, -35, 0, -15 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.8, -20, 0, -15 },
				},
			},
			Jaw = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, -30, 0, 0 },
					{ 1.8, -12, 0, 0 },
				},
			},
			LegFL_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.3, 25, 0, 10 },
				},
			},
			LegBL_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.3, 20, 0, 10 },
				},
			},
			LegFR_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.3, 30, 0, 0 },
				},
			},
			LegBR_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.3, -30, 0, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.8, 40, 0, 0 },
				},
			},
			EarR = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.8, 40, 0, 0 },
				},
			},
			Tail2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.8, 20, 25, 0 },
				},
			},
		},
	},
}
]=======],
	Brain = [=======[
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
	table.insert(self.out, { ... })
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
]=======],
	Pack = [=======[
--[[
	WolfPack (Script) · ServerScriptService.WolfPack

	Manadas de lobos huecos, las mismas para todos los jugadores. Salen al anochecer y se van al amanecer
	(NightOnly; por defecto true). Cada manada tiene un alfa (más grande, más vida, aúlla) y varios lobos.
	El servidor decide (WolfBrain), mueve los modelos 10 veces por segundo (para que las armas acierten en el
	servidor) y publica atributos; los clientes (WolfClient) animan los huesos y suavizan el movimiento.

	Dónde aparecen: partes con la etiqueta "WolfSpawn" o dentro de Workspace.WolfSpawns; si no hay, alrededor
	de Settings.SpawnCenter, lejos de los jugadores.
	Luz segura: partes con la etiqueta "SafeLight" (atributo Radius, por defecto 25). Ningún lobo entra en esa
	zona y no muerden a quien está dentro. Es el gancho para la hoguera.

	Daño a los lobos (para las armas de tu juego):
	  ReplicatedStorage.Creatures.HollowWolf.DamageWolf:Invoke(lobo, cantidad)   -- desde el servidor
	  o simplemente lobo:SetAttribute("Health", lobo:GetAttribute("Health") - cantidad)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local folder = ReplicatedStorage:WaitForChild("Creatures"):WaitForChild("HollowWolf")
local Brain = require(folder:WaitForChild("WolfBrain"))
local settings = folder:WaitForChild("Settings")
local template = folder:WaitForChild("HollowWolf") :: Model

local function S(k, d)
	local v = settings:GetAttribute(k)
	if v == nil then
		return d
	end
	return v
end
local PACKS, PACK_SIZE = S("Packs", 2), S("PackSize", 4)
local DAMAGE, ALPHA_DAMAGE = S("Damage", 8), S("AlphaDamage", 15)
local HEALTH, ALPHA_HEALTH = S("Health", 60), S("AlphaHealth", 150)
local ALPHA_SCALE = S("AlphaScale", 1.35)
local NIGHT_ONLY = S("NightOnly", true)
local SPAWN_CENTER, SPAWN_RADIUS = S("SpawnCenter", Vector3.zero), S("SpawnRadius", 250)
local MAX_BITERS = S("MaxBiters", 2)
local DEBUG = S("Debug", false)
local config = {}
for k, v in pairs(settings:GetAttributes()) do
	if type(Brain.Defaults[k]) == "number" and type(v) == "number" then
		config[k] = v
	end
end

local container = workspace:FindFirstChild("Wolves") or Instance.new("Folder")
container.Name = "Wolves"
container.Parent = workspace
local rng = Random.new()

local damageFn = folder:FindFirstChild("DamageWolf") or Instance.new("BindableFunction")
damageFn.Name = "DamageWolf"
damageFn.Parent = folder
damageFn.OnInvoke = function(model, amount)
	if typeof(model) == "Instance" and model:IsDescendantOf(container) and type(amount) == "number" then
		model:SetAttribute("Health", math.max(0, (model:GetAttribute("Health") or 0) - amount))
		return true
	end
	return false
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function refreshFilter()
	local list = { container }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	rayParams.FilterDescendantsInstances = list
end
local function groundAt(x, z, fromY)
	local hit = workspace:Raycast(Vector3.new(x, fromY + 60, z), Vector3.new(0, -300, 0), rayParams)
	if hit and hit.Normal.Y > 0.55 and hit.Material ~= Enum.Material.Water then
		return hit.Position
	end
	return nil
end
local function lights()
	local out = {}
	for _, p in ipairs(CollectionService:GetTagged("SafeLight")) do
		if p:IsA("BasePart") and (p:GetAttribute("Enabled") ~= false) then
			table.insert(out, { pos = p.Position, r = p:GetAttribute("Radius") or 25 })
		end
	end
	return out
end
local function inLight(pos, L)
	for _, l in ipairs(L) do
		if ((pos - l.pos) * Vector3.new(1, 0, 1)).Magnitude < l.r then
			return l
		end
	end
	return nil
end
local function alive(p)
	local c = p.Character
	local h = c and c:FindFirstChild("HumanoidRootPart")
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if h and hum and hum.Health > 0 then
		return h, hum
	end
	return nil
end
local function isNight()
	return Lighting.ClockTime >= 18.5 or Lighting.ClockTime < 5.5
end

local packs, stamp = {}, 0
local function spawnPoint()
	local pts = CollectionService:GetTagged("WolfSpawn")
	local sf = workspace:FindFirstChild("WolfSpawns")
	if sf then
		for _, d in ipairs(sf:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(pts, d)
			end
		end
	end
	for _ = 1, 30 do
		local c
		if #pts > 0 then
			c = pts[rng:NextInteger(1, #pts)].Position
		else
			local a, r = rng:NextNumber() * math.pi * 2, math.sqrt(rng:NextNumber()) * SPAWN_RADIUS
			c = SPAWN_CENTER + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		end
		local g = groundAt(c.X, c.Z, c.Y)
		local far = true
		for _, p in ipairs(Players:GetPlayers()) do
			local h = alive(p)
			if h and (h.Position - (g or c)).Magnitude < 80 then
				far = false
			end
		end
		if g and far and not inLight(g, lights()) then
			return g
		end
	end
	return nil
end

local function makeWolf(pack, isAlpha, pos)
	local m = template:Clone()
	m.Name = isAlpha and "WolfAlpha" or "Wolf"
	if isAlpha then
		m:ScaleTo(ALPHA_SCALE)
		m:SetAttribute("RigScale", ALPHA_SCALE)
	end
	local s = m:GetAttribute("RigScale") or 1
	local root = CFrame.new(pos + Vector3.new(rng:NextNumber() * 6 - 3, 0, rng:NextNumber() * 6 - 3)) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
	local hp = isAlpha and ALPHA_HEALTH or HEALTH
	for k, v in pairs({ Root = root, Anim = "Idle", AnimFade = 0, AnimStamp = 0, Alpha = isAlpha, Health = hp, MaxHealth = hp, Visible = true }) do
		m:SetAttribute(k, v)
	end
	m:PivotTo(root)
	m.Parent = container
	local w = {
		model = m, pack = pack, alpha = isAlpha, scale = s, root = root, speed = 0, mode = "stop", slot = 0, lastHp = hp,
		brain = Brain.new(table.clone(config), Random.new(rng:NextInteger(1, 1e9)), isAlpha), ground = 0, wander = pos,
	}
	table.insert(pack.wolves, w)
	return w
end

local function spawnPack()
	local pos = spawnPoint()
	if not pos then
		return
	end
	local pack = { wolves = {}, alerted = false, target = nil, home = pos }
	makeWolf(pack, true, pos)
	for _ = 2, PACK_SIZE do
		makeWolf(pack, false, pos)
	end
	for i, w in ipairs(pack.wolves) do
		w.slot = (i - 1) / #pack.wolves * math.pi * 2   -- cada lobo rodea por un flanco distinto
	end
	table.insert(packs, pack)
	if DEBUG then
		print("[WolfPack] manada en", pos)
	end
end

local function playSound(w, name)
	local body = w.model:FindFirstChild("WolfBody", true)
	local s = body and body:FindFirstChild(name)
	if s and s.SoundId ~= "" then
		s.PlaybackSpeed = (w.alpha and 0.85 or 1) * (0.92 + rng:NextNumber() * 0.16)
		s:Play()
	end
end

local function apply(w, cmds)
	for _, c in ipairs(cmds) do
		local k = c[1]
		stamp += 1
		if k == "anim" then
			w.model:SetAttribute("Anim", c[2])
			w.model:SetAttribute("AnimFade", c[3] or 0.3)
			w.model:SetAttribute("AnimStamp", stamp)
		elseif k == "move" then
			w.speed, w.mode = c[2] * w.scale, c[3]
		elseif k == "alert" then
			w.pack.alerted = true
		elseif k == "sound" then
			playSound(w, c[2])
		elseif k == "bite" then
			local h, hum = nil, nil
			if w.pack.target then
				h, hum = alive(w.pack.target)
			end
			if h and hum and (h.Position - w.root.Position).Magnitude <= (w.brain.cfg.AttackReach + 1.5) * w.scale then
				hum:TakeDamage(w.alpha and ALPHA_DAMAGE or DAMAGE)
				playSound(w, "Bite")
			end
		elseif k == "despawn" then
			w.gone = true
			w.model:SetAttribute("Visible", false)
			task.delay(1.5, function()
				w.model:Destroy()
			end)
		end
	end
end

-- movimiento (cada frame, sin física) con la luz como barrera
RunService.Heartbeat:Connect(function(dt)
	local L = lights()
	for _, pack in ipairs(packs) do
		local th = pack.target and alive(pack.target)
		local leader = pack.wolves[1]
		for _, w in ipairs(pack.wolves) do
			if w.gone or w.brain.state == "Dead" or w.mode == "stop" then
				continue
			end
			local pos = w.root.Position
			local goal
			if w.mode == "wander" then
				if (w.wander - pos).Magnitude < 4 then
					local a, r = rng:NextNumber() * math.pi * 2, 20 + rng:NextNumber() * 40
					w.wander = pack.home + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
				end
				goal = w.wander
			elseif w.mode == "follow" and leader and not leader.gone then
				goal = leader.root.Position + Vector3.new(math.cos(w.slot) * 4, 0, math.sin(w.slot) * 4)
			elseif th then
				local tp = th.Position
				if w.mode == "toward" or w.mode == "lunge" or w.mode == "face" then
					goal = tp
				elseif w.mode == "away" then
					goal = pos + (pos - tp) * Vector3.new(1, 0, 1)
				elseif w.mode == "circle" then
					w.slot += dt * 0.35 * (w.alpha and -1 or 1)
					local r = (w.brain.cfg.CircleMin + w.brain.cfg.CircleMax) * 0.5 * w.scale
					local l = inLight(tp, L)
					if l then
						r = math.max(r, l.r + 4 - ((tp - l.pos) * Vector3.new(1, 0, 1)).Magnitude)   -- rodea por fuera de la luz
					end
					goal = tp + Vector3.new(math.cos(w.slot) * r, 0, math.sin(w.slot) * r)
				end
			end
			if not goal then
				continue
			end
			local want = (goal - pos) * Vector3.new(1, 0, 1)
			local cur = w.root.LookVector * Vector3.new(1, 0, 1)
			local dir = cur
			if want.Magnitude > 0.2 then
				local maxTurn = math.rad(w.speed > 15 and 260 or 160) * dt
				local ang = math.atan2(cur:Cross(want.Unit).Y, cur:Dot(want.Unit))
				dir = (CFrame.Angles(0, math.clamp(ang, -maxTurn, maxTurn), 0) * cur).Unit
			end
			local npos = pos
			if w.mode ~= "face" and want.Magnitude > 1.5 then
				npos = pos + dir * w.speed * dt
				if inLight(npos, L) and w.mode ~= "away" then
					npos = pos   -- nunca entra en la luz
				end
				w.ground -= dt
				if w.ground <= 0 then
					w.ground = 0.2
					local g = groundAt(npos.X, npos.Z, npos.Y)
					if g then
						npos = Vector3.new(npos.X, g.Y, npos.Z)
					end
				end
			end
			if w.mode == "circle" and th then   -- en el cerco mira a la presa
				local f = (th.Position - npos) * Vector3.new(1, 0, 1)
				if f.Magnitude > 0.1 then
					dir = f.Unit
				end
			end
			w.root = CFrame.lookAt(npos, npos + dir)
		end
	end
end)

-- pensar, publicar y aparecer/desaparecer 10 veces por segundo
local acc = 0
local spawnTimer = 3
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.1 then
		return
	end
	local step = acc
	acc = 0
	refreshFilter()
	local night = not NIGHT_ONLY or isNight()
	local L = lights()
	-- manadas nuevas de noche
	for i = #packs, 1, -1 do
		local alive_ = false
		for _, w in ipairs(packs[i].wolves) do
			if not w.gone and w.model.Parent then
				alive_ = true
			end
		end
		if not alive_ then
			table.remove(packs, i)
		end
	end
	spawnTimer -= step
	if night and #packs < PACKS and spawnTimer <= 0 and #Players:GetPlayers() > 0 then
		spawnTimer = 20 + rng:NextNumber() * 40
		spawnPack()
	end
	for _, pack in ipairs(packs) do
		-- objetivo: el jugador vivo más cercano al alfa (o al primer lobo vivo)
		local ref = pack.wolves[1].root.Position
		local best, bestD = nil, math.huge
		for _, p in ipairs(Players:GetPlayers()) do
			local h = alive(p)
			if h and (h.Position - ref).Magnitude < bestD then
				best, bestD = p, (h.Position - ref).Magnitude
			end
		end
		pack.target = best
		local th = best and alive(best)
		local targetLight = th and inLight(th.Position, L) ~= nil
		local biters = 0
		for _, w in ipairs(pack.wolves) do
			if w.brain.state == "Attack" then
				biters += 1
			end
		end
		for _, w in ipairs(pack.wolves) do
			if w.gone or not w.model.Parent then
				continue
			end
			local hp = w.model:GetAttribute("Health") or 0
			local maxHp = w.model:GetAttribute("MaxHealth") or 1
			local P = {
				dist = th and (th.Position - w.root.Position).Magnitude / w.scale or math.huge, hasTarget = th ~= nil,
				canAttack = biters < MAX_BITERS, inLight = inLight(w.root.Position, L) ~= nil, targetInLight = targetLight,
				day = not night, alerted = pack.alerted, health = hp / maxHp, hurt = hp < w.lastHp, dead = hp <= 0,
			}
			w.lastHp = hp
			local wasDead = w.brain.state == "Dead"
			apply(w, w.brain:Update(step, P))
			if w.brain.state == "Attack" and P.canAttack and biters < MAX_BITERS then
				biters += 1   -- cuenta al que acaba de lanzarse, para no pasar del máximo en este mismo tick
			end
			if not wasDead and w.brain.state == "Dead" and not w.gone then
				w.gone = true
				task.delay(6, function()   -- el cuerpo se queda un rato y luego desaparece
					w.model:SetAttribute("Visible", false)
					task.delay(1.5, function()
						w.model:Destroy()
					end)
				end)
			end
			if w.model.Parent and w.model:GetAttribute("Root") ~= w.root then
				w.model:SetAttribute("Root", w.root)
				w.model:PivotTo(w.root)   -- también en el servidor, para que las armas acierten
			end
		end
	end
end)
]=======],
	Client = [=======[
--[[
	WolfClient (LocalScript) · StarterPlayer.StarterPlayerScripts.WolfClient

	Parte visual de los lobos en cada jugador: anima los huesos (DragonAnimator) según el atributo Anim,
	suaviza el movimiento hacia el Root del servidor, mantiene los ojos (puntos Neon con una luz amarilla
	diminuta) pegados al hueso Head, la cabeza sigue al jugador mientras caza y los cuerpos se desvanecen.
	Rendimiento: lejos se anima menos veces por segundo y muy lejos se pausa.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DragonAnimator = require(ReplicatedStorage:WaitForChild("Dragons"):WaitForChild("DragonAnimator"))
local folder = ReplicatedStorage:WaitForChild("Creatures"):WaitForChild("HollowWolf")
local animations = require(folder:WaitForChild("Animations"))
local container = workspace:WaitForChild("Wolves")

local LOOK = { Head = "Head", Neck = "Neck2", NeckShare = 0.45, MaxYaw = 75, MaxPitch = 30, RestPitch = -10, Speed = 5 }
local HUNTING = { Trot = true, Growl = true, Attack = true, Howl = true, Hurt = true }
local entries = {}

local function setup(model: Model)
	if entries[model] or not model:IsA("Model") then
		return
	end
	local e = { model = model, vis = 1, goal = 1, meshes = {}, eyes = {} }
	e.animator = DragonAnimator.new(model, animations)
	e.animator:Play(model:GetAttribute("Anim") or "Idle", 0)
	e.current = model:GetAttribute("Root") or model:GetPivot()
	local head = model:FindFirstChild("Head", true)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("MeshPart") then
			table.insert(e.meshes, d)
		elseif d:IsA("BasePart") and d:GetAttribute("Kind") == "eye" and head and head:IsA("Bone") then
			table.insert(e.eyes, { d, head, head.TransformedWorldCFrame:ToObjectSpace(d.CFrame) })
		end
	end
	if model:GetAttribute("Alpha") then   -- el alfa: ojos más brillantes
		for _, ey in ipairs(e.eyes) do
			local l = ey[1]:FindFirstChildOfClass("PointLight")
			if l then
				l.Brightness *= 1.6
			end
		end
	end
	model:GetAttributeChangedSignal("AnimStamp"):Connect(function()
		local name = model:GetAttribute("Anim")
		e.animator:Play(name, model:GetAttribute("AnimFade") or 0.3)
		e.animator:SetLookTarget(HUNTING[name] and function()
			local cam = workspace.CurrentCamera
			return cam and cam.CFrame.Position
		end or nil, LOOK)
	end)
	model:GetAttributeChangedSignal("Visible"):Connect(function()
		e.goal = model:GetAttribute("Visible") and 1 or 0
	end)
	entries[model] = e
	model.Destroying:Connect(function()
		e.animator:Destroy()
		entries[model] = nil
	end)
end

for _, m in ipairs(container:GetChildren()) do
	setup(m)
end
container.ChildAdded:Connect(setup)

RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	for model, e in pairs(entries) do
		if e.vis ~= e.goal then
			e.vis = e.goal > e.vis and math.min(1, e.vis + dt / 1.2) or math.max(0, e.vis - dt / 1.2)
			for _, m in ipairs(e.meshes) do
				m.LocalTransparencyModifier = 1 - e.vis
			end
			for _, ey in ipairs(e.eyes) do
				ey[1].LocalTransparencyModifier = 1 - e.vis
			end
		end
		local goal = model:GetAttribute("Root") or e.current
		e.current = (goal.Position - e.current.Position).Magnitude > 15 and goal or e.current:Lerp(goal, 1 - math.exp(-dt * 12))
		local d = (camPos - e.current.Position).Magnitude
		local visible = d < 500 and e.vis > 0.001
		if visible then
			model:PivotTo(e.current)
			for _, ey in ipairs(e.eyes) do
				ey[1].CFrame = ey[2].TransformedWorldCFrame * ey[3]
			end
		end
		e.animator.Paused = not visible
		e.animator.UpdateInterval = d < 60 and 0 or (d < 160 and 1 / 20 or 1 / 8)
	end
end)
]=======],
}

local Selection = game:GetService("Selection")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local function v3(t)
	return Vector3.new(t[1], t[2], t[3])
end
local byName = {}
for _, b in ipairs(RIG) do
	byName[b.name] = b
end

-- 1. Localizar el modelo importado
local function looksLikeWolf(inst)
	return inst:FindFirstChild("WolfBody", true) and inst:FindFirstChild("Neck2", true) and inst:FindFirstChild("Tail4", true)
end
local source
for _, s in ipairs(Selection:Get()) do
	local cand = s:IsA("BasePart") and s.Parent or s
	if looksLikeWolf(cand) then
		source = cand
		break
	end
end
if not source then
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and looksLikeWolf(d) and not d:GetAttribute("RigScale") then
			source = d
			break
		end
	end
end
assert(source, "[Wolf] No encontré el modelo importado. Impórtalo con Import 3D (Rig Type: Custom) y selecciónalo.")

local bones, meshes, missing = {}, {}, {}
for _, d in ipairs(source:GetDescendants()) do
	if d:IsA("Bone") and not bones[d.Name] then
		bones[d.Name] = d
	end
end
for _, b in ipairs(RIG) do
	if not bones[b.name] then
		table.insert(missing, b.name)
	end
end
for _, name in ipairs({ "WolfBody" }) do
	local m = source:FindFirstChild(name, true)
	if m and m:IsA("MeshPart") then
		meshes[name] = m
	else
		table.insert(missing, name)
	end
end
assert(#missing == 0, "[Wolf] Faltan piezas o huesos: " .. table.concat(missing, ", ") .. ". ¿Rig Type estaba en Custom?")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar los lobos")
end)

-- 2. Calibración: escala y orientación con que el importador dejó el esqueleto
local function ratio(a, b)
	return (bones[a].WorldPosition - bones[b].WorldPosition).Magnitude / (v3(byName[a].head) - v3(byName[b].head)).Magnitude
end
local scale = (ratio("Hips", "Head") + ratio("LegFL_Paw", "LegBR_Paw") + ratio("Tail4", "EarL")) / 3
local ROTATIONS = {
	CFrame.identity,
	CFrame.Angles(0, math.pi, 0),
	CFrame.Angles(math.pi / 2, 0, 0),
	CFrame.Angles(-math.pi / 2, 0, 0),
	CFrame.Angles(0, math.pi, 0) * CFrame.Angles(math.pi / 2, 0, 0),
	CFrame.Angles(0, math.pi, 0) * CFrame.Angles(-math.pi / 2, 0, 0),
}
local R, origin, bestErr
for _, rot in ipairs(ROTATIONS) do
	local o = bones.Hips.WorldPosition - rot:VectorToWorldSpace(v3(byName.Hips.head) * scale)
	local err = 0
	for _, b in ipairs(RIG) do
		err = math.max(err, (o + rot:VectorToWorldSpace(v3(b.head) * scale) - bones[b.name].WorldPosition).Magnitude)
	end
	if not bestErr or err < bestErr then
		R, origin, bestErr = rot, o, err
	end
end
print(("[Wolf] escala del import: %.4f · error máximo de huesos: %.3f studs"):format(scale, bestErr))
if bestErr > 0.3 * scale then
	warn("[Wolf] Los huesos no coinciden con el rig esperado. Revisa la importación. Continúo igualmente.")
end
local function W(t)
	return origin + R:VectorToWorldSpace(v3(t) * scale)
end

-- 3. Modelo: WolfBody anclado (lo mueven los scripts, sin física)
local model = Instance.new("Model")
model.Name = "HollowWolf"
for _, child in ipairs(source:GetChildren()) do
	child.Parent = model
end
for name, m in pairs(meshes) do
	m.Parent = model
	m.CanCollide = false
	m.CanTouch = false
	m.CastShadow = true
	m.Anchored = name == "WolfBody"
	m.Massless = name ~= "WolfBody"
	m.CanQuery = true   -- para que las armas puedan acertarle
	if name ~= "WolfBody" then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = meshes.WolfBody
		weld.Part1 = m
		weld.Parent = m
	end
	local maps = MAPS[name]
	if maps and maps.ColorMap ~= "" then
		local sa = m:FindFirstChildOfClass("SurfaceAppearance") or Instance.new("SurfaceAppearance")
		sa.ColorMap = maps.ColorMap
		sa.NormalMap = maps.NormalMap
		sa.RoughnessMap = maps.RoughnessMap
		sa.Parent = m
	end
end
model.PrimaryPart = meshes.WolfBody
model.WorldPivot = CFrame.new(W({ byName.Hips.head[1], 0, byName.Hips.head[3] })) * R
for name, id in pairs(SOUND_IDS) do
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Volume = name == "Howl" and 1 or 0.7
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = name == "Howl" and 400 or 90
	s.Parent = meshes.WolfBody
end
-- ojos: puntos Neon amarillos con una luz diminuta; WolfClient los pega al hueso Head
for i, p in ipairs(EYES) do
	local dot = Instance.new("Part")
	dot.Name = i == 1 and "EyeL" or "EyeR"
	dot.Shape = Enum.PartType.Ball
	dot.Size = Vector3.one * 0.075 * scale
	dot.Material = Enum.Material.Neon
	dot.Color = Color3.fromRGB(255, 205, 80)
	dot.Anchored = true
	dot.CanCollide = false
	dot.CanQuery = false
	dot.CanTouch = false
	dot.CastShadow = false
	dot.CFrame = CFrame.new(W(p))
	dot:SetAttribute("Kind", "eye")
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 90)
	light.Range = 1.6 * scale
	light.Brightness = 0.8
	light.Parent = dot
	dot.Parent = model
end
model:SetAttribute("RigScale", 1)
if math.abs(scale - 1) > 1e-3 then
	model:ScaleTo(1 / scale)
end

-- 4. Organización del proyecto
local function ensure(parent, name, class)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new(class or "Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end
local function putScript(parent, name, class, src)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local s = Instance.new(class)
	s.Name = name
	s.Source = src
	s.Parent = parent
	return s
end

local creatures = ensure(ReplicatedStorage, "Creatures")
local folder = ensure(creatures, "HollowWolf")
local prev = folder:FindFirstChild("HollowWolf")
if prev then
	prev:Destroy()
end
model.Parent = folder
local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({
	DisplayName = "Lobo hueco", Packs = PACKS, PackSize = PACK_SIZE, Damage = DAMAGE, AlphaDamage = ALPHA_DAMAGE,
	Health = HEALTH, AlphaHealth = ALPHA_HEALTH, AlphaScale = 1.35, NightOnly = NIGHT_ONLY, MaxBiters = 2,
	SpawnCenter = SPAWN_CENTER, SpawnRadius = SPAWN_RADIUS, Debug = false,
	-- ajustes del comportamiento (ver WolfBrain.Defaults)
	DetectDistance = 70, LoseDistance = 130, CircleMin = 9, CircleMax = 14, TrotSpeed = 13, RunSpeed = 28,
}) do
	settings:SetAttribute(k, v)
end
putScript(ensure(ReplicatedStorage, "Dragons"), "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(folder, "WolfBrain", "ModuleScript", SOURCES.Brain)
putScript(game:GetService("ServerScriptService"), "WolfPack", "Script", SOURCES.Pack)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "WolfClient", "LocalScript", SOURCES.Client)

local assets = ensure(ServerStorage, "DragonAssets")
local bak = assets:FindFirstChild("HollowWolf_Rig")
if bak then
	bak:Destroy()
end
local backup = model:Clone()
backup.Name = "HollowWolf_Rig"
backup.Parent = assets

if source.Parent and #source:GetChildren() == 0 then
	source:Destroy()
end
Selection:Set({ folder })
pcall(function()
	ChangeHistoryService:SetWaypoint("Lobos instalados")
end)
print(("[Wolf] Listo: %d huesos. Al anochecer salen %d manadas de %d lobos (un alfa cada una). Partes con la etiqueta SafeLight: zonas donde no entran."):format(#RIG, PACKS, PACK_SIZE))
