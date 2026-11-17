--[[
	INSTALADOR DEL CIERVO MALDITO · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	Pasos:
	  1. Studio > Avatar (o Home) > Import 3D > CursedDeer.fbx.
	     En el importador: Rig General > Rig Type = "Custom". No combines las mallas. Pulsa Import.
	     Aparece un modelo con las mallas DeerBody, HorrorBody, Antlers y Tentacles y sus Bones.
	  2. Selecciona ese modelo en el Explorer.
	  3. View > Command Bar. Pega TODO este archivo y pulsa Enter.
	  4. (Opcional) Pon partes con la etiqueta "DeerSpawn" o dentro de Workspace.DeerSpawns: cada una es una manada.

	Resultado:
	  ReplicatedStorage.Creatures.CursedDeer            (modelo, Settings, Animations, DeerBrain)
	  ReplicatedStorage.Dragons.DragonAnimator          (motor de animación, compartido con los dragones)
	  ServerScriptService.DeerHerd                      (crea los ciervos; 1 de cada 7 está maldito)
	  StarterPlayer.StarterPlayerScripts.DeerClient     (animación, transformación y movimiento suave)
	  ServerStorage.DragonAssets.CursedDeer_Rig         (copia de seguridad)
]]

-- Ajustes principales (también se pueden cambiar luego en ReplicatedStorage.Creatures.CursedDeer.Settings)
local COUNT = 14              -- ciervos en el mapa
local CURSED_RATIO = 7        -- uno de cada 7 está maldito
local DAMAGE = 0              -- daño de la criatura al tocar (0 = terror sin daño)
local NIGHT_ONLY = false      -- true: los malditos solo se transforman de noche
local SPAWN_CENTER = Vector3.new(0, 0, 0)
local SPAWN_RADIUS = 220
-- Opcional: tras subir los PNG (Asset Manager), pega aquí sus ids para crear SurfaceAppearance PBR.
local MAPS = {
	DeerBody = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	HorrorBody = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	Antlers = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	Tentacles = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
}
-- Sonidos: sube los .ogg de sounds/ y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = { Snort = "", Crack = "", Shriek = "" }

local RIG = {
	{ name = "Root", parent = nil, head = { 0, 0, 1.5 }, tail = { 0, 1, 1.5 } },
	{ name = "Hips", parent = "Root", head = { 0, 3.22, 1.5 }, tail = { 0, 3.12, 0.3 } },
	{ name = "Spine", parent = "Hips", head = { 0, 3.12, 0.3 }, tail = { 0, 3.28, -0.8 } },
	{ name = "Chest", parent = "Spine", head = { 0, 3.28, -0.8 }, tail = { 0, 2.95, -1.18 } },
	{ name = "Neck1", parent = "Chest", head = { 0, 2.95, -1.18 }, tail = { 0, 3.5, -1.5 } },
	{ name = "Neck2", parent = "Neck1", head = { 0, 3.5, -1.5 }, tail = { 0, 4.02, -1.78 } },
	{ name = "Neck3", parent = "Neck2", head = { 0, 4.02, -1.78 }, tail = { 0, 4.5, -2 } },
	{ name = "Head", parent = "Neck3", head = { 0, 4.5, -2 }, tail = { 0, 3.7446, -2.886 } },
	{ name = "Jaw", parent = "Head", head = { 0, 4.1838, -2.1675 }, tail = { 0, 3.7074, -2.6628 } },
	{ name = "EarL", parent = "Head", head = { -0.17, 4.6372, -2.2208 }, tail = { -0.6, 4.9186, -2.2742 } },
	{ name = "EarR", parent = "Head", head = { 0.17, 4.6372, -2.2208 }, tail = { 0.6, 4.9186, -2.2742 } },
	{ name = "Tail", parent = "Hips", head = { 0, 3.12, 2.2 }, tail = { 0, 2.8, 2.75 } },
	{ name = "LegFL_Upper", parent = "Chest", head = { -0.3, 2.62, -0.75 }, tail = { -0.29, 1.9, -0.66 } },
	{ name = "LegFL_Lower", parent = "LegFL_Upper", head = { -0.29, 1.9, -0.66 }, tail = { -0.26, 1.08, -0.78 } },
	{ name = "LegFL_Cannon", parent = "LegFL_Lower", head = { -0.26, 1.08, -0.78 }, tail = { -0.25, 0.32, -0.8 } },
	{ name = "LegFL_Hoof", parent = "LegFL_Cannon", head = { -0.25, 0.32, -0.8 }, tail = { -0.25, 0, -0.93 } },
	{ name = "LegBL_Upper", parent = "Hips", head = { -0.32, 2.72, 1.4 }, tail = { -0.34, 1.98, 1 } },
	{ name = "LegBL_Lower", parent = "LegBL_Upper", head = { -0.34, 1.98, 1 }, tail = { -0.28, 1.28, 1.78 } },
	{ name = "LegBL_Cannon", parent = "LegBL_Lower", head = { -0.28, 1.28, 1.78 }, tail = { -0.27, 0.32, 1.64 } },
	{ name = "LegBL_Hoof", parent = "LegBL_Cannon", head = { -0.27, 0.32, 1.64 }, tail = { -0.27, 0, 1.52 } },
	{ name = "LegFR_Upper", parent = "Chest", head = { 0.3, 2.62, -0.75 }, tail = { 0.29, 1.9, -0.66 } },
	{ name = "LegFR_Lower", parent = "LegFR_Upper", head = { 0.29, 1.9, -0.66 }, tail = { 0.26, 1.08, -0.78 } },
	{ name = "LegFR_Cannon", parent = "LegFR_Lower", head = { 0.26, 1.08, -0.78 }, tail = { 0.25, 0.32, -0.8 } },
	{ name = "LegFR_Hoof", parent = "LegFR_Cannon", head = { 0.25, 0.32, -0.8 }, tail = { 0.25, 0, -0.93 } },
	{ name = "LegBR_Upper", parent = "Hips", head = { 0.32, 2.72, 1.4 }, tail = { 0.34, 1.98, 1 } },
	{ name = "LegBR_Lower", parent = "LegBR_Upper", head = { 0.34, 1.98, 1 }, tail = { 0.28, 1.28, 1.78 } },
	{ name = "LegBR_Cannon", parent = "LegBR_Lower", head = { 0.28, 1.28, 1.78 }, tail = { 0.27, 0.32, 1.64 } },
	{ name = "LegBR_Hoof", parent = "LegBR_Cannon", head = { 0.27, 0.32, 1.64 }, tail = { 0.27, 0, 1.52 } },
	{ name = "T1_1", parent = "Head", head = { -0.04, 4.4972, -2.1553 }, tail = { -0.1, 4.4931, -2.3883 } },
	{ name = "T1_2", parent = "T1_1", head = { -0.1, 4.4931, -2.3883 }, tail = { -0.2876, 5.2311, -2.4554 } },
	{ name = "T1_3", parent = "T1_2", head = { -0.2876, 5.2311, -2.4554 }, tail = { -0.4043, 5.9661, -2.5627 } },
	{ name = "T1_4", parent = "T1_3", head = { -0.4043, 5.9661, -2.5627 }, tail = { -0.3793, 6.5244, -2.6386 } },
	{ name = "T2_1", parent = "Head", head = { 0.04, 4.4972, -2.1553 }, tail = { 0.1, 4.4931, -2.3883 } },
	{ name = "T2_2", parent = "T2_1", head = { 0.1, 4.4931, -2.3883 }, tail = { 0.4656, 5.3788, -2.6541 } },
	{ name = "T2_3", parent = "T2_2", head = { 0.4656, 5.3788, -2.6541 }, tail = { 0.9978, 6.1317, -2.2501 } },
	{ name = "T2_4", parent = "T2_3", head = { 0.9978, 6.1317, -2.2501 }, tail = { 0.8956, 6.776, -2.675 } },
	{ name = "T3_1", parent = "Head", head = { 0, 4.5633, -2.1041 }, tail = { 0, 4.6582, -2.2604 } },
	{ name = "T3_2", parent = "T3_1", head = { 0, 4.6582, -2.2604 }, tail = { 0.0746, 5.7451, -2.2495 } },
	{ name = "T3_3", parent = "T3_2", head = { 0.0746, 5.7451, -2.2495 }, tail = { 0.0952, 6.7749, -2.5071 } },
	{ name = "T3_4", parent = "T3_3", head = { 0.0952, 6.7749, -2.5071 }, tail = { -0.0577, 7.4392, -2.4493 } },
	{ name = "T4_1", parent = "Head", head = { -0.08, 4.5335, -2.0632 }, tail = { -0.2, 4.5837, -2.1581 } },
	{ name = "T4_2", parent = "T4_1", head = { -0.2, 4.5837, -2.1581 }, tail = { -0.8936, 5.8928, -2.3 } },
	{ name = "T4_3", parent = "T4_2", head = { -0.8936, 5.8928, -2.3 }, tail = { -1.2402, 6.5165, -2.4772 } },
	{ name = "T4_4", parent = "T4_3", head = { -1.2402, 6.5165, -2.4772 }, tail = { -1.4862, 7.4433, -2.5107 } },
	{ name = "T5_1", parent = "Head", head = { 0.08, 4.5335, -2.0632 }, tail = { 0.2, 4.5837, -2.1581 } },
	{ name = "T5_2", parent = "T5_1", head = { 0.2, 4.5837, -2.1581 }, tail = { 0.3794, 5.5787, -2.4719 } },
	{ name = "T5_3", parent = "T5_2", head = { 0.3794, 5.5787, -2.4719 }, tail = { 0.567, 6.125, -2.6766 } },
	{ name = "T5_4", parent = "T5_3", head = { 0.567, 6.125, -2.6766 }, tail = { 0.5802, 6.9116, -2.8023 } },
	{ name = "T6_1", parent = "Head", head = { -0.024, 4.395, -2.2297 }, tail = { -0.06, 4.2374, -2.5743 } },
	{ name = "T6_2", parent = "T6_1", head = { -0.06, 4.2374, -2.5743 }, tail = { -0.2798, 5.0983, -2.7267 } },
	{ name = "T6_3", parent = "T6_2", head = { -0.2798, 5.0983, -2.7267 }, tail = { -0.5397, 5.6216, -2.738 } },
	{ name = "T6_4", parent = "T6_3", head = { -0.5397, 5.6216, -2.738 }, tail = { -0.4203, 6.2589, -2.9339 } },
	{ name = "T7_1", parent = "Head", head = { 0.028, 4.3996, -2.2232 }, tail = { 0.07, 4.249, -2.5581 } },
	{ name = "T7_2", parent = "T7_1", head = { 0.07, 4.249, -2.5581 }, tail = { 0.155, 5.2226, -2.9646 } },
	{ name = "T7_3", parent = "T7_2", head = { 0.155, 5.2226, -2.9646 }, tail = { 0.3245, 6.2557, -3.3363 } },
	{ name = "T7_4", parent = "T7_3", head = { 0.3245, 6.2557, -3.3363 }, tail = { 0.1857, 6.8075, -3.5429 } },
}
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
	Animaciones del ciervo maldito (ModuleScript) · ReplicatedStorage.Creatures.CursedDeer.Animations
	Generado desde src/deer_anims.js y model/rig.json con tools/build_roblox.js: edita la fuente y regenera.
	Formato: ver DragonAnimator. Ángulos en grados, traslaciones en studs, tiempos en segundos.
]]
return {
	Idle = {
		dur = 7,
		loop = true,
		joints = {
			EarL = {
				o = {
					{ "z", 4, 3, 0 },
					{ "y", 2.4, 3, 0.3 },
				},
				k = {
					{ 0, 0, 0, 0 },
					{ 3, 0, 0, 0 },
					{ 3.1, 0, 25, -10 },
					{ 3.25, 0, 0, 0 },
				},
			},
			EarR = {
				o = {
					{ "z", -4, 3, 0.5 },
					{ "y", -2.4, 3, 0.8 },
				},
			},
			Chest = {
				o = {
					{ "x", 0.8, 2, 0 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.015, 2, 0 },
				},
			},
			Neck1 = {
				o = {
					{ "y", 4, 1, 0.1 },
				},
			},
			Neck3 = {
				o = {
					{ "y", 5, 1, 0.3 },
					{ "x", 3, 1, 0.6 },
				},
			},
			Head = {
				o = {
					{ "z", 3, 1, 0.2 },
				},
			},
			Tail = {
				k = {
					{ 0, 0, 0, 0 },
					{ 5, 0, 0, 0 },
					{ 5.1, 25, 0, 0 },
					{ 5.25, 0, 0, 0 },
					{ 5.35, 20, 0, 0 },
					{ 5.5, 0, 0, 0 },
				},
			},
		},
	},
	Graze = {
		dur = 6,
		loop = true,
		joints = {
			EarL = {
				o = {
					{ "z", 5, 2, 0 },
					{ "y", 3, 2, 0.3 },
				},
			},
			EarR = {
				o = {
					{ "z", -5, 2, 0.5 },
					{ "y", -3, 2, 0.8 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -76, 0, 0 },
				},
				o = {
					{ "y", 6, 1, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, -25, 0, 0 },
				},
			},
			Neck3 = {
				k = {
					{ 0, -12, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 50, 0, 0 },
				},
				o = {
					{ "x", 3, 6, 0 },
				},
			},
			Jaw = {
				o = {
					{ "x", 4, 12, 0 },
				},
			},
			Chest = {
				k = {
					{ 0, -4, 0, 0 },
				},
				p = {
					{ 0, 0, -0.2, 0 },
				},
			},
			LegFL_Upper = {
				k = {
					{ 0, -6, 0, 0 },
				},
			},
			LegFR_Upper = {
				k = {
					{ 0, 8, 0, 0 },
				},
			},
			LegFR_Lower = {
				k = {
					{ 0, -10, 0, 0 },
				},
			},
			Tail = {
				o = {
					{ "x", 10, 4, 0 },
				},
			},
		},
	},
	Walk = {
		dur = 1.7,
		loop = true,
		joints = {
			EarL = {
				o = {
					{ "z", 3, 2, 0 },
					{ "y", 1.8, 2, 0.3 },
				},
			},
			EarR = {
				o = {
					{ "z", -3, 2, 0.5 },
					{ "y", -1.8, 2, 0.8 },
				},
			},
			LegFL_Upper = {
				o = {
					{ "x", 18, 1, 0 },
				},
			},
			LegFL_Lower = {
				o = {
					{ "x", 14, 1, 0.15 },
				},
			},
			LegFL_Cannon = {
				o = {
					{ "x", 18, 1, 0.3 },
				},
			},
			LegFR_Upper = {
				o = {
					{ "x", 18, 1, 0.5 },
				},
			},
			LegFR_Lower = {
				o = {
					{ "x", 14, 1, 0.65 },
				},
			},
			LegFR_Cannon = {
				o = {
					{ "x", 18, 1, 0.8 },
				},
			},
			LegBL_Upper = {
				o = {
					{ "x", 18, 1, 0.55 },
				},
			},
			LegBL_Lower = {
				o = {
					{ "x", 14, 1, 0.7 },
				},
			},
			LegBL_Cannon = {
				o = {
					{ "x", 18, 1, 0.85 },
				},
			},
			LegBR_Upper = {
				o = {
					{ "x", 18, 1, 0.05 },
				},
			},
			LegBR_Lower = {
				o = {
					{ "x", 14, 1, 0.2 },
				},
			},
			LegBR_Cannon = {
				o = {
					{ "x", 18, 1, 0.35 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.05, 2, 0.1 },
					{ "z", 2, 1, 0 },
				},
			},
			Chest = {
				o = {
					{ "z", -2, 1, 0.1 },
				},
			},
			Neck1 = {
				o = {
					{ "x", 3, 2, 0.2 },
				},
			},
			Head = {
				o = {
					{ "x", -3, 2, 0.2 },
				},
			},
			Tail = {
				o = {
					{ "y", 6, 1, 0 },
				},
			},
		},
	},
	Run = {
		dur = 0.62,
		loop = true,
		joints = {
			LegFL_Upper = {
				o = {
					{ "x", 30, 1, 0 },
				},
			},
			LegFL_Lower = {
				o = {
					{ "x", 20, 1, 0.15 },
				},
			},
			LegFL_Cannon = {
				o = {
					{ "x", 24, 1, 0.3 },
				},
			},
			LegFR_Upper = {
				o = {
					{ "x", 30, 1, 0.06 },
				},
			},
			LegFR_Lower = {
				o = {
					{ "x", 20, 1, 0.21 },
				},
			},
			LegFR_Cannon = {
				o = {
					{ "x", 24, 1, 0.36 },
				},
			},
			LegBL_Upper = {
				o = {
					{ "x", 30, 1, 0.5 },
				},
			},
			LegBL_Lower = {
				o = {
					{ "x", 20, 1, 0.65 },
				},
			},
			LegBL_Cannon = {
				o = {
					{ "x", 24, 1, 0.8 },
				},
			},
			LegBR_Upper = {
				o = {
					{ "x", 30, 1, 0.56 },
				},
			},
			LegBR_Lower = {
				o = {
					{ "x", 20, 1, 0.71 },
				},
			},
			LegBR_Cannon = {
				o = {
					{ "x", 24, 1, 0.86 },
				},
			},
			Hips = {
				p = {
					{ 0, 0, 0.1, 0 },
				},
				o = {
					{ "py", 0.35, 1, 0.25 },
					{ "x", 8, 1, 0 },
				},
			},
			Spine = {
				o = {
					{ "x", 6, 1, 0.5 },
				},
			},
			Chest = {
				o = {
					{ "x", 5, 1, 0.5 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -28, 0, 0 },
				},
				o = {
					{ "x", 6, 1, 0.3 },
				},
			},
			Head = {
				k = {
					{ 0, 22, 0, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, 0, 0, -30 },
				},
			},
			EarR = {
				k = {
					{ 0, 0, 0, 30 },
				},
			},
			Tail = {
				k = {
					{ 0, 70, 0, 0 },
				},
			},
		},
	},
	Alert = {
		dur = 4,
		loop = true,
		joints = {
			Neck1 = {
				k = {
					{ 0, 12, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 6, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 8, 0, 0 },
				},
				o = {
					{ "y", 6, 1, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, -15, 0, 15 },
				},
				o = {
					{ "y", 8, 2, 0 },
				},
			},
			EarR = {
				k = {
					{ 0, -15, 0, -15 },
				},
				o = {
					{ "y", -8, 2, 0.4 },
				},
			},
			Tail = {
				k = {
					{ 0, 35, 0, 0 },
				},
				o = {
					{ "x", 15, 4, 0 },
				},
			},
			Chest = {
				o = {
					{ "x", 1.5, 3, 0 },
				},
			},
		},
	},
	Death = {
		dur = 2.2,
		loop = false,
		joints = {
			Hips = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, 0, 0, -15 },
					{ 1.4, 0, 0, -80 },
					{ 2.2, 0, 0, -88 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 1.4, 0, -1.6, 0 },
					{ 2.2, 0, -2, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.6, -30, 0, 0 },
					{ 2.2, -40, 0, -10 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 2.2, -15, 0, -20 },
				},
			},
			LegFL_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.6, 25, 0, 10 },
				},
			},
			LegBL_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.6, 20, 0, 10 },
				},
			},
			LegFR_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.6, -40, 0, 0 },
				},
			},
			LegBR_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.6, 30, 0, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, 0, 0, 0 },
					{ 2.2, 0, 0, -40 },
				},
			},
			EarR = {
				k = {
					{ 0, 0, 0, 0 },
					{ 2.2, 0, 0, 40 },
				},
			},
		},
	},
	Transform = {
		dur = 4.6,
		loop = false,
		next = "CreatureIdle",
		joints = {
			Hips = {
				p = {
					{ 0, 0, 0, 0 },
					{ 1.3, 0, 0, 0 },
					{ 1.5, 0, 0.2624, 0 },
					{ 1.62, 0, 0.2624, 0 },
					{ 1.8, 0, 0.5724, 0 },
					{ 1.95, 0, 0.5724, 0 },
					{ 2.15, 0, 0.8944, 0 },
					{ 2.3, 0, 0.8944, 0 },
					{ 2.7, 0, 1.2402, 0 },
					{ 3, 0, 1.1925, 0 },
				},
			},
			Neck2 = {
				p = {
					{ 0, 0, 0, 0 },
					{ 1.3, 0, 0, 0 },
					{ 1.5, 0, 0.1179, -0.0686 },
					{ 1.62, 0, 0.1179, -0.0686 },
					{ 1.8, 0, 0.2572, -0.1497 },
					{ 1.95, 0, 0.2572, -0.1497 },
					{ 2.15, 0, 0.4019, -0.2338 },
					{ 2.3, 0, 0.4019, -0.2338 },
					{ 2.7, 0, 0.5573, -0.3243 },
					{ 3, 0, 0.5359, -0.3118 },
				},
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, 0, 10, 5 },
					{ 0.75, 0, -12, -8 },
					{ 0.9, 0, 14, 6 },
					{ 1.1, 0, -8, -4 },
					{ 1.3, 0, 0, 0 },
					{ 4.6, 0, 0, 0 },
				},
			},
			Neck3 = {
				p = {
					{ 0, 0, 0, 0 },
					{ 1.3, 0, 0, 0 },
					{ 1.5, 0, 0.1201, -0.0647 },
					{ 1.62, 0, 0.1201, -0.0647 },
					{ 1.8, 0, 0.262, -0.1411 },
					{ 1.95, 0, 0.262, -0.1411 },
					{ 2.15, 0, 0.4094, -0.2205 },
					{ 2.3, 0, 0.4094, -0.2205 },
					{ 2.7, 0, 0.5677, -0.3057 },
					{ 3, 0, 0.5459, -0.2939 },
				},
			},
			Head = {
				p = {
					{ 0, 0, 0, 0 },
					{ 1.3, 0, 0, 0 },
					{ 1.5, 0, 0.124, -0.0568 },
					{ 1.62, 0, 0.124, -0.0568 },
					{ 1.8, 0, 0.2705, -0.124 },
					{ 1.95, 0, 0.2705, -0.124 },
					{ 2.15, 0, 0.4227, -0.1937 },
					{ 2.3, 0, 0.4227, -0.1937 },
					{ 2.7, 0, 0.5862, -0.2687 },
					{ 3, 0, 0.5636, -0.2583 },
				},
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, 0, 0 },
					{ 0.6, 0, 0, 28 },
					{ 0.72, 0, 0, -22 },
					{ 0.85, 0, 0, 34 },
					{ 1, 0, 0, -26 },
					{ 1.15, 0, 0, 18 },
					{ 1.3, 0, 0, 0 },
					{ 2.6, 10, 0, 0 },
					{ 3, 42, 0, 6 },
					{ 3.6, 30, 0, -10 },
					{ 4.6, 6, 0, 0 },
				},
			},
			LegFL_Cannon = {
				p = {
					{ 0, 0, 0, 0 },
					{ 1.3, 0, 0, 0 },
					{ 1.5, 0.0057, -0.1566, -0.0229 },
					{ 1.62, 0.0057, -0.1566, -0.0229 },
					{ 1.8, 0.0125, -0.3417, -0.05 },
					{ 1.95, 0.0125, -0.3417, -0.05 },
					{ 2.15, 0.0195, -0.534, -0.0781 },
					{ 2.3, 0.0195, -0.534, -0.0781 },
					{ 2.7, 0.0271, -0.7404, -0.1084 },
					{ 3, 0.026, -0.7119, -0.1042 },
				},
			},
			LegFL_Hoof = {
				p = {
					{ 0, 0, 0, 0 },
					{ 1.3, 0, 0, 0 },
					{ 1.5, 0.0021, -0.1583, -0.0042 },
					{ 1.62, 0.0021, -0.1583, -0.0042 },
					{ 1.8, 0.0045, -0.3455, -0.0091 },
					{ 1.95, 0.0045, -0.3455, -0.0091 },
					{ 2.15, 0.0071, -0.5398, -0.0142 },
					{ 2.3, 0.0071, -0.5398, -0.0142 },
					{ 2.7, 0.0098, -0.7485, -0.0197 },
					{ 3, 0.0095, -0.7197, -0.0189 },
				},
			},
			LegFR_Cannon = {
				p = {
					{ 0, 0, 0, 0 },
					{ 1.3, 0, 0, 0 },
					{ 1.5, -0.0057, -0.1566, -0.0229 },
					{ 1.62, -0.0057, -0.1566, -0.0229 },
					{ 1.8, -0.0125, -0.3417, -0.05 },
					{ 1.95, -0.0125, -0.3417, -0.05 },
					{ 2.15, -0.0195, -0.534, -0.0781 },
					{ 2.3, -0.0195, -0.534, -0.0781 },
					{ 2.7, -0.0271, -0.7404, -0.1084 },
					{ 3, -0.026, -0.7119, -0.1042 },
				},
			},
			LegFR_Hoof = {
				p = {
					{ 0, 0, 0, 0 },
					{ 1.3, 0, 0, 0 },
					{ 1.5, -0.0021, -0.1583, -0.0042 },
					{ 1.62, -0.0021, -0.1583, -0.0042 },
					{ 1.8, -0.0045, -0.3455, -0.0091 },
					{ 1.95, -0.0045, -0.3455, -0.0091 },
					{ 2.15, -0.0071, -0.5398, -0.0142 },
					{ 2.3, -0.0071, -0.5398, -0.0142 },
					{ 2.7, -0.0098, -0.7485, -0.0197 },
					{ 3, -0.0095, -0.7197, -0.0189 },
				},
			},
			LegBL_Cannon = {
				p = {
					{ 0, 0, 0, 0 },
					{ 1.3, 0, 0, 0 },
					{ 1.5, 0.0091, -0.1056, 0.1177 },
					{ 1.62, 0.0091, -0.1056, 0.1177 },
					{ 1.8, 0.0198, -0.2305, 0.2568 },
					{ 1.95, 0.0198, -0.2305, 0.2568 },
					{ 2.15, 0.0309, -0.3601, 0.4012 },
					{ 2.3, 0.0309, -0.3601, 0.4012 },
					{ 2.7, 0.0428, -0.4993, 0.5564 },
					{ 3, 0.0412, -0.4801, 0.535 },
				},
			},
			LegBL_Hoof = {
				p = {
					{ 0, 0, 0, 0 },
					{ 1.3, 0, 0, 0 },
					{ 1.5, 0.0016, -0.1567, -0.0229 },
					{ 1.62, 0.0016, -0.1567, -0.0229 },
					{ 1.8, 0.0036, -0.342, -0.0499 },
					{ 1.95, 0.0036, -0.342, -0.0499 },
					{ 2.15, 0.0056, -0.5343, -0.0779 },
					{ 2.3, 0.0056, -0.5343, -0.0779 },
					{ 2.7, 0.0077, -0.7409, -0.1081 },
					{ 3, 0.0074, -0.7124, -0.1039 },
				},
			},
			LegBR_Cannon = {
				p = {
					{ 0, 0, 0, 0 },
					{ 1.3, 0, 0, 0 },
					{ 1.5, -0.0091, -0.1056, 0.1177 },
					{ 1.62, -0.0091, -0.1056, 0.1177 },
					{ 1.8, -0.0198, -0.2305, 0.2568 },
					{ 1.95, -0.0198, -0.2305, 0.2568 },
					{ 2.15, -0.0309, -0.3601, 0.4012 },
					{ 2.3, -0.0309, -0.3601, 0.4012 },
					{ 2.7, -0.0428, -0.4993, 0.5564 },
					{ 3, -0.0412, -0.4801, 0.535 },
				},
			},
			LegBR_Hoof = {
				p = {
					{ 0, 0, 0, 0 },
					{ 1.3, 0, 0, 0 },
					{ 1.5, -0.0016, -0.1567, -0.0229 },
					{ 1.62, -0.0016, -0.1567, -0.0229 },
					{ 1.8, -0.0036, -0.342, -0.0499 },
					{ 1.95, -0.0036, -0.342, -0.0499 },
					{ 2.15, -0.0056, -0.5343, -0.0779 },
					{ 2.3, -0.0056, -0.5343, -0.0779 },
					{ 2.7, -0.0077, -0.7409, -0.1081 },
					{ 3, -0.0074, -0.7124, -0.1039 },
				},
			},
			T1_2 = {
				p = {
					{ 0, 0.06, 0.0041, 0.233 },
					{ 1.6, 0.06, 0.0041, 0.233 },
					{ 2.2, 0.039, 0.0027, 0.1515 },
					{ 2.7, 0.012, 0.0008, 0.0466 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 8.4, 3, 0 },
					{ "z", 7, 3, 0.25 },
				},
			},
			T1_3 = {
				p = {
					{ 0, 0.1876, -0.738, 0.0671 },
					{ 1.6, 0.1876, -0.738, 0.0671 },
					{ 2.2, 0.1219, -0.4797, 0.0436 },
					{ 2.7, 0.0375, -0.1476, 0.0134 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 12.6, 3, 0.17 },
					{ "z", 11.2, 3, 0.48 },
				},
			},
			T1_4 = {
				p = {
					{ 0, 0.1167, -0.735, 0.1073 },
					{ 1.6, 0.1167, -0.735, 0.1073 },
					{ 2.2, 0.0759, -0.4778, 0.0697 },
					{ 2.7, 0.0233, -0.147, 0.0215 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 16.8, 3, 0.34 },
					{ "z", 15.4, 3, 0.71 },
				},
			},
			T2_2 = {
				p = {
					{ 0, -0.06, 0.0041, 0.233 },
					{ 1.6, -0.06, 0.0041, 0.233 },
					{ 2.2, -0.039, 0.0027, 0.1515 },
					{ 2.7, -0.012, 0.0008, 0.0466 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 8.4, 3, 0.37 },
					{ "z", 7, 3, 0.86 },
				},
			},
			T2_3 = {
				p = {
					{ 0, -0.3656, -0.8857, 0.2658 },
					{ 1.6, -0.3656, -0.8857, 0.2658 },
					{ 2.2, -0.2376, -0.5757, 0.1728 },
					{ 2.7, -0.0731, -0.1771, 0.0532 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 12.6, 3, 0.54 },
					{ "z", 11.2, 3, 0.09 },
				},
			},
			T2_4 = {
				p = {
					{ 0, -0.5322, -0.7529, -0.404 },
					{ 1.6, -0.5322, -0.7529, -0.404 },
					{ 2.2, -0.3459, -0.4894, -0.2626 },
					{ 2.7, -0.1064, -0.1506, -0.0808 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 16.8, 3, 0.71 },
					{ "z", 15.4, 3, 0.32 },
				},
			},
			T3_2 = {
				p = {
					{ 0, 0, -0.0949, 0.1563 },
					{ 1.6, 0, -0.0949, 0.1563 },
					{ 2.2, 0, -0.0617, 0.1016 },
					{ 2.7, 0, -0.019, 0.0313 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 8.4, 3, 0.74 },
					{ "z", 7, 3, 0.47 },
				},
			},
			T3_3 = {
				p = {
					{ 0, -0.0746, -1.0869, -0.0109 },
					{ 1.6, -0.0746, -1.0869, -0.0109 },
					{ 2.2, -0.0485, -0.7065, -0.0071 },
					{ 2.7, -0.0149, -0.2174, -0.0022 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 12.6, 3, 0.91 },
					{ "z", 11.2, 3, 0.7 },
				},
			},
			T3_4 = {
				p = {
					{ 0, -0.0206, -1.0298, 0.2576 },
					{ 1.6, -0.0206, -1.0298, 0.2576 },
					{ 2.2, -0.0134, -0.6694, 0.1674 },
					{ 2.7, -0.0041, -0.206, 0.0515 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 16.8, 3, 0.08 },
					{ "z", 15.4, 3, 0.93 },
				},
			},
			T4_2 = {
				p = {
					{ 0, 0.12, -0.0502, 0.0949 },
					{ 1.6, 0.12, -0.0502, 0.0949 },
					{ 2.2, 0.078, -0.0326, 0.0617 },
					{ 2.7, 0.024, -0.01, 0.019 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 8.4, 3, 0.11 },
					{ "z", 7, 3, 0.08 },
				},
			},
			T4_3 = {
				p = {
					{ 0, 0.6936, -1.3091, 0.1419 },
					{ 1.6, 0.6936, -1.3091, 0.1419 },
					{ 2.2, 0.4508, -0.8509, 0.0922 },
					{ 2.7, 0.1387, -0.2618, 0.0284 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 12.6, 3, 0.28 },
					{ "z", 11.2, 3, 0.31 },
				},
			},
			T4_4 = {
				p = {
					{ 0, 0.3466, -0.6237, 0.1772 },
					{ 1.6, 0.3466, -0.6237, 0.1772 },
					{ 2.2, 0.2253, -0.4054, 0.1152 },
					{ 2.7, 0.0693, -0.1247, 0.0354 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 16.8, 3, 0.45 },
					{ "z", 15.4, 3, 0.54 },
				},
			},
			T5_2 = {
				p = {
					{ 0, -0.12, -0.0502, 0.0949 },
					{ 1.6, -0.12, -0.0502, 0.0949 },
					{ 2.2, -0.078, -0.0326, 0.0617 },
					{ 2.7, -0.024, -0.01, 0.019 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 8.4, 3, 0.48 },
					{ "z", 7, 3, 0.69 },
				},
			},
			T5_3 = {
				p = {
					{ 0, -0.1794, -0.995, 0.3138 },
					{ 1.6, -0.1794, -0.995, 0.3138 },
					{ 2.2, -0.1166, -0.6468, 0.204 },
					{ 2.7, -0.0359, -0.199, 0.0628 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 12.6, 3, 0.65 },
					{ "z", 11.2, 3, 0.92 },
				},
			},
			T5_4 = {
				p = {
					{ 0, -0.1876, -0.5463, 0.2047 },
					{ 1.6, -0.1876, -0.5463, 0.2047 },
					{ 2.2, -0.1219, -0.3551, 0.1331 },
					{ 2.7, -0.0375, -0.1093, 0.0409 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 16.8, 3, 0.82 },
					{ "z", 15.4, 3, 0.15 },
				},
			},
			T6_2 = {
				p = {
					{ 0, 0.036, 0.1576, 0.3446 },
					{ 1.6, 0.036, 0.1576, 0.3446 },
					{ 2.2, 0.0234, 0.1024, 0.224 },
					{ 2.7, 0.0072, 0.0315, 0.0689 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 8.4, 3, 0.85 },
					{ "z", 7, 3, 0.3 },
				},
			},
			T6_3 = {
				p = {
					{ 0, 0.2198, -0.8609, 0.1524 },
					{ 1.6, 0.2198, -0.8609, 0.1524 },
					{ 2.2, 0.1429, -0.5596, 0.0991 },
					{ 2.7, 0.044, -0.1722, 0.0305 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 12.6, 3, 0.02 },
					{ "z", 11.2, 3, 0.53 },
				},
			},
			T6_4 = {
				p = {
					{ 0, 0.2599, -0.5233, 0.0113 },
					{ 1.6, 0.2599, -0.5233, 0.0113 },
					{ 2.2, 0.1689, -0.3401, 0.0073 },
					{ 2.7, 0.052, -0.1047, 0.0023 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 16.8, 3, 0.19 },
					{ "z", 15.4, 3, 0.76 },
				},
			},
			T7_2 = {
				p = {
					{ 0, -0.042, 0.1506, 0.3349 },
					{ 1.6, -0.042, 0.1506, 0.3349 },
					{ 2.2, -0.0273, 0.0979, 0.2177 },
					{ 2.7, -0.0084, 0.0301, 0.067 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 8.4, 3, 0.22 },
					{ "z", 7, 3, 0.91 },
				},
			},
			T7_3 = {
				p = {
					{ 0, -0.085, -0.9736, 0.4065 },
					{ 1.6, -0.085, -0.9736, 0.4065 },
					{ 2.2, -0.0552, -0.6328, 0.2642 },
					{ 2.7, -0.017, -0.1947, 0.0813 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 12.6, 3, 0.39 },
					{ "z", 11.2, 3, 0.14 },
				},
			},
			T7_4 = {
				p = {
					{ 0, -0.1695, -1.0331, 0.3717 },
					{ 1.6, -0.1695, -1.0331, 0.3717 },
					{ 2.2, -0.1102, -0.6715, 0.2416 },
					{ 2.7, -0.0339, -0.2066, 0.0743 },
					{ 3.2, 0, 0, 0 },
				},
				o = {
					{ "x", 16.8, 3, 0.56 },
					{ "z", 15.4, 3, 0.37 },
				},
			},
			EarL = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, -20, 0, -30 },
					{ 2, -20, 0, -40 },
					{ 4.6, 0, 0, -35 },
				},
			},
			EarR = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, -20, 0, 30 },
					{ 2, -20, 0, 40 },
					{ 4.6, 0, 0, 35 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, 10, 0, 0 },
					{ 0.55, 4, 8, 0 },
					{ 0.7, 12, -10, 0 },
					{ 0.85, 2, 6, 0 },
					{ 1, 14, -4, 0 },
					{ 1.3, 8, 0, 0 },
					{ 2.8, 12, 0, 0 },
					{ 4.6, 0, 0, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, 0, 0, 0 },
					{ 2.6, 0, 0, 0 },
					{ 3, -135, 0, 0 },
					{ 3.5, -120, 0, 0 },
					{ 4.6, -22, 0, 0 },
				},
				o = {
					{ "x", 3, 30, 0 },
				},
			},
			Spine = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.55, -6, 0, 3 },
					{ 0.7, 5, 0, -4 },
					{ 0.85, -7, 0, 2 },
					{ 1.05, 4, 0, -2 },
					{ 1.3, 0, 0, 0 },
				},
			},
			Chest = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, 4, 0, -4 },
					{ 0.8, -5, 0, 5 },
					{ 1, 3, 0, -2 },
					{ 1.3, 0, 0, 0 },
				},
			},
			Tail = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, 60, 0, 0 },
					{ 1.3, 60, 0, 0 },
					{ 4.6, 30, 0, 0 },
				},
			},
			LegBL_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 3, 10, 0, 0 },
				},
			},
			LegBR_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 3, 10, 0, 0 },
				},
			},
		},
	},
	CreatureIdle = {
		dur = 7,
		loop = true,
		joints = {
			Hips = {
				p = {
					{ 0, 0, 1.1925, 0 },
				},
			},
			Neck2 = {
				p = {
					{ 0, 0, 0.5359, -0.3118 },
				},
				o = {
					{ "y", 6, 1, 0.15 },
					{ "z", 4, 1, 0.5 },
				},
			},
			Neck3 = {
				p = {
					{ 0, 0, 0.5459, -0.2939 },
				},
				o = {
					{ "x", 4, 2, 0.2 },
				},
			},
			Head = {
				p = {
					{ 0, 0, 0.5636, -0.2583 },
				},
				k = {
					{ 0, 6, 0, 0 },
				},
				o = {
					{ "z", 14, 1, 0.3 },
					{ "y", 6, 1, 0.7 },
				},
			},
			LegFL_Cannon = {
				p = {
					{ 0, 0.026, -0.7119, -0.1042 },
				},
			},
			LegFL_Hoof = {
				p = {
					{ 0, 0.0095, -0.7197, -0.0189 },
				},
			},
			LegFR_Cannon = {
				p = {
					{ 0, -0.026, -0.7119, -0.1042 },
				},
			},
			LegFR_Hoof = {
				p = {
					{ 0, -0.0095, -0.7197, -0.0189 },
				},
			},
			LegBL_Cannon = {
				p = {
					{ 0, 0.0412, -0.4801, 0.535 },
				},
			},
			LegBL_Hoof = {
				p = {
					{ 0, 0.0074, -0.7124, -0.1039 },
				},
			},
			LegBR_Cannon = {
				p = {
					{ 0, -0.0412, -0.4801, 0.535 },
				},
			},
			LegBR_Hoof = {
				p = {
					{ 0, -0.0074, -0.7124, -0.1039 },
				},
			},
			Jaw = {
				k = {
					{ 0, -22, 0, 0 },
				},
				o = {
					{ "x", 6, 1, 0 },
					{ "x", 1.5, 25, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, 0, 0, -35 },
				},
			},
			EarR = {
				k = {
					{ 0, 0, 0, 35 },
				},
			},
			Tail = {
				k = {
					{ 0, 30, 0, 0 },
				},
			},
			LegBL_Lower = {
				k = {
					{ 0, 10, 0, 0 },
				},
			},
			LegBR_Lower = {
				k = {
					{ 0, 10, 0, 0 },
				},
			},
			T1_2 = {
				o = {
					{ "x", 6, 1, 0 },
					{ "z", 5, 1, 0.25 },
				},
			},
			T1_3 = {
				o = {
					{ "x", 9, 1, 0.17 },
					{ "z", 8, 1, 0.48 },
				},
			},
			T1_4 = {
				o = {
					{ "x", 12, 1, 0.34 },
					{ "z", 11, 1, 0.71 },
				},
			},
			T2_2 = {
				o = {
					{ "x", 6, 1, 0.37 },
					{ "z", 5, 1, 0.86 },
				},
			},
			T2_3 = {
				o = {
					{ "x", 9, 1, 0.54 },
					{ "z", 8, 1, 0.09 },
				},
			},
			T2_4 = {
				o = {
					{ "x", 12, 1, 0.71 },
					{ "z", 11, 1, 0.32 },
				},
			},
			T3_2 = {
				o = {
					{ "x", 6, 1, 0.74 },
					{ "z", 5, 1, 0.47 },
				},
			},
			T3_3 = {
				o = {
					{ "x", 9, 1, 0.91 },
					{ "z", 8, 1, 0.7 },
				},
			},
			T3_4 = {
				o = {
					{ "x", 12, 1, 0.08 },
					{ "z", 11, 1, 0.93 },
				},
			},
			T4_2 = {
				o = {
					{ "x", 6, 1, 0.11 },
					{ "z", 5, 1, 0.08 },
				},
			},
			T4_3 = {
				o = {
					{ "x", 9, 1, 0.28 },
					{ "z", 8, 1, 0.31 },
				},
			},
			T4_4 = {
				o = {
					{ "x", 12, 1, 0.45 },
					{ "z", 11, 1, 0.54 },
				},
			},
			T5_2 = {
				o = {
					{ "x", 6, 1, 0.48 },
					{ "z", 5, 1, 0.69 },
				},
			},
			T5_3 = {
				o = {
					{ "x", 9, 1, 0.65 },
					{ "z", 8, 1, 0.92 },
				},
			},
			T5_4 = {
				o = {
					{ "x", 12, 1, 0.82 },
					{ "z", 11, 1, 0.15 },
				},
			},
			T6_2 = {
				o = {
					{ "x", 6, 1, 0.85 },
					{ "z", 5, 1, 0.3 },
				},
			},
			T6_3 = {
				o = {
					{ "x", 9, 1, 0.02 },
					{ "z", 8, 1, 0.53 },
				},
			},
			T6_4 = {
				o = {
					{ "x", 12, 1, 0.19 },
					{ "z", 11, 1, 0.76 },
				},
			},
			T7_2 = {
				o = {
					{ "x", 6, 1, 0.22 },
					{ "z", 5, 1, 0.91 },
				},
			},
			T7_3 = {
				o = {
					{ "x", 9, 1, 0.39 },
					{ "z", 8, 1, 0.14 },
				},
			},
			T7_4 = {
				o = {
					{ "x", 12, 1, 0.56 },
					{ "z", 11, 1, 0.37 },
				},
			},
			Neck1 = {
				o = {
					{ "y", 8, 1, 0 },
					{ "x", 3, 1, 0.3 },
				},
			},
			Chest = {
				o = {
					{ "x", 2, 2, 0 },
				},
			},
		},
	},
	CreatureWalk = {
		dur = 2.4,
		loop = true,
		joints = {
			Hips = {
				p = {
					{ 0, 0, 1.1925, 0 },
				},
				o = {
					{ "py", 0.12, 2, 0 },
					{ "z", 3, 1, 0.1 },
				},
			},
			Neck2 = {
				p = {
					{ 0, 0, 0.5359, -0.3118 },
				},
				o = {
					{ "z", 5, 1, 0.5 },
				},
			},
			Neck3 = {
				p = {
					{ 0, 0, 0.5459, -0.2939 },
				},
			},
			Head = {
				p = {
					{ 0, 0, 0.5636, -0.2583 },
				},
				k = {
					{ 0, 6, 0, 0 },
				},
				o = {
					{ "z", 10, 1, 0.1 },
					{ "x", 3, 9, 0 },
				},
			},
			LegFL_Cannon = {
				p = {
					{ 0, 0.026, -0.7119, -0.1042 },
				},
				o = {
					{ "x", 16, 1, 0.3 },
				},
			},
			LegFL_Hoof = {
				p = {
					{ 0, 0.0095, -0.7197, -0.0189 },
				},
			},
			LegFR_Cannon = {
				p = {
					{ 0, -0.026, -0.7119, -0.1042 },
				},
				o = {
					{ "x", 16, 1, 0.8 },
				},
			},
			LegFR_Hoof = {
				p = {
					{ 0, -0.0095, -0.7197, -0.0189 },
				},
			},
			LegBL_Cannon = {
				p = {
					{ 0, 0.0412, -0.4801, 0.535 },
				},
				o = {
					{ "x", 16, 1, 0.92 },
				},
			},
			LegBL_Hoof = {
				p = {
					{ 0, 0.0074, -0.7124, -0.1039 },
				},
			},
			LegBR_Cannon = {
				p = {
					{ 0, -0.0412, -0.4801, 0.535 },
				},
				o = {
					{ "x", 16, 1, 0.42 },
				},
			},
			LegBR_Hoof = {
				p = {
					{ 0, -0.0074, -0.7124, -0.1039 },
				},
			},
			Jaw = {
				k = {
					{ 0, -22, 0, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, 0, 0, -35 },
				},
			},
			EarR = {
				k = {
					{ 0, 0, 0, 35 },
				},
			},
			Tail = {
				k = {
					{ 0, 30, 0, 0 },
				},
			},
			LegBL_Lower = {
				k = {
					{ 0, 10, 0, 0 },
				},
				o = {
					{ "x", 18, 1, 0.77 },
				},
			},
			LegBR_Lower = {
				k = {
					{ 0, 10, 0, 0 },
				},
				o = {
					{ "x", 18, 1, 0.27 },
				},
			},
			T1_2 = {
				o = {
					{ "x", 8.4, 2, 0 },
					{ "z", 7, 2, 0.25 },
				},
			},
			T1_3 = {
				o = {
					{ "x", 12.6, 2, 0.17 },
					{ "z", 11.2, 2, 0.48 },
				},
			},
			T1_4 = {
				o = {
					{ "x", 16.8, 2, 0.34 },
					{ "z", 15.4, 2, 0.71 },
				},
			},
			T2_2 = {
				o = {
					{ "x", 8.4, 2, 0.37 },
					{ "z", 7, 2, 0.86 },
				},
			},
			T2_3 = {
				o = {
					{ "x", 12.6, 2, 0.54 },
					{ "z", 11.2, 2, 0.09 },
				},
			},
			T2_4 = {
				o = {
					{ "x", 16.8, 2, 0.71 },
					{ "z", 15.4, 2, 0.32 },
				},
			},
			T3_2 = {
				o = {
					{ "x", 8.4, 2, 0.74 },
					{ "z", 7, 2, 0.47 },
				},
			},
			T3_3 = {
				o = {
					{ "x", 12.6, 2, 0.91 },
					{ "z", 11.2, 2, 0.7 },
				},
			},
			T3_4 = {
				o = {
					{ "x", 16.8, 2, 0.08 },
					{ "z", 15.4, 2, 0.93 },
				},
			},
			T4_2 = {
				o = {
					{ "x", 8.4, 2, 0.11 },
					{ "z", 7, 2, 0.08 },
				},
			},
			T4_3 = {
				o = {
					{ "x", 12.6, 2, 0.28 },
					{ "z", 11.2, 2, 0.31 },
				},
			},
			T4_4 = {
				o = {
					{ "x", 16.8, 2, 0.45 },
					{ "z", 15.4, 2, 0.54 },
				},
			},
			T5_2 = {
				o = {
					{ "x", 8.4, 2, 0.48 },
					{ "z", 7, 2, 0.69 },
				},
			},
			T5_3 = {
				o = {
					{ "x", 12.6, 2, 0.65 },
					{ "z", 11.2, 2, 0.92 },
				},
			},
			T5_4 = {
				o = {
					{ "x", 16.8, 2, 0.82 },
					{ "z", 15.4, 2, 0.15 },
				},
			},
			T6_2 = {
				o = {
					{ "x", 8.4, 2, 0.85 },
					{ "z", 7, 2, 0.3 },
				},
			},
			T6_3 = {
				o = {
					{ "x", 12.6, 2, 0.02 },
					{ "z", 11.2, 2, 0.53 },
				},
			},
			T6_4 = {
				o = {
					{ "x", 16.8, 2, 0.19 },
					{ "z", 15.4, 2, 0.76 },
				},
			},
			T7_2 = {
				o = {
					{ "x", 8.4, 2, 0.22 },
					{ "z", 7, 2, 0.91 },
				},
			},
			T7_3 = {
				o = {
					{ "x", 12.6, 2, 0.39 },
					{ "z", 11.2, 2, 0.14 },
				},
			},
			T7_4 = {
				o = {
					{ "x", 16.8, 2, 0.56 },
					{ "z", 15.4, 2, 0.37 },
				},
			},
			LegFL_Upper = {
				o = {
					{ "x", 16, 1, 0 },
				},
			},
			LegFL_Lower = {
				o = {
					{ "x", 18, 1, 0.15 },
				},
			},
			LegFR_Upper = {
				o = {
					{ "x", 16, 1, 0.5 },
				},
			},
			LegFR_Lower = {
				o = {
					{ "x", 18, 1, 0.65 },
				},
			},
			LegBL_Upper = {
				o = {
					{ "x", 16, 1, 0.62 },
				},
			},
			LegBR_Upper = {
				o = {
					{ "x", 16, 1, 0.12 },
				},
			},
			Chest = {
				o = {
					{ "z", -3, 1, 0.2 },
				},
			},
			Neck1 = {
				o = {
					{ "y", 6, 1, 0.3 },
				},
			},
		},
	},
	CreatureRun = {
		dur = 0.9,
		loop = true,
		joints = {
			Hips = {
				p = {
					{ 0, 0, 1.1925, 0 },
				},
				o = {
					{ "py", 0.35, 2, 0 },
					{ "x", 6, 1, 0 },
				},
			},
			Neck2 = {
				p = {
					{ 0, 0, 0.5359, -0.3118 },
				},
				k = {
					{ 0, -10, 0, 0 },
				},
			},
			Neck3 = {
				p = {
					{ 0, 0, 0.5459, -0.2939 },
				},
			},
			Head = {
				p = {
					{ 0, 0, 0.5636, -0.2583 },
				},
				k = {
					{ 0, 30, 0, 0 },
				},
				o = {
					{ "z", 8, 2, 0 },
				},
			},
			LegFL_Cannon = {
				p = {
					{ 0, 0.026, -0.7119, -0.1042 },
				},
				o = {
					{ "x", 30, 1, 0.3 },
				},
			},
			LegFL_Hoof = {
				p = {
					{ 0, 0.0095, -0.7197, -0.0189 },
				},
			},
			LegFR_Cannon = {
				p = {
					{ 0, -0.026, -0.7119, -0.1042 },
				},
				o = {
					{ "x", 30, 1, 0.4 },
				},
			},
			LegFR_Hoof = {
				p = {
					{ 0, -0.0095, -0.7197, -0.0189 },
				},
			},
			LegBL_Cannon = {
				p = {
					{ 0, 0.0412, -0.4801, 0.535 },
				},
				o = {
					{ "x", 30, 1, 0.8 },
				},
			},
			LegBL_Hoof = {
				p = {
					{ 0, 0.0074, -0.7124, -0.1039 },
				},
			},
			LegBR_Cannon = {
				p = {
					{ 0, -0.0412, -0.4801, 0.535 },
				},
				o = {
					{ "x", 30, 1, 0.9 },
				},
			},
			LegBR_Hoof = {
				p = {
					{ 0, -0.0074, -0.7124, -0.1039 },
				},
			},
			Jaw = {
				k = {
					{ 0, -70, 0, 0 },
				},
				o = {
					{ "x", 10, 2, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, 0, 0, -35 },
				},
			},
			EarR = {
				k = {
					{ 0, 0, 0, 35 },
				},
			},
			Tail = {
				k = {
					{ 0, 30, 0, 0 },
				},
			},
			LegBL_Lower = {
				k = {
					{ 0, 10, 0, 0 },
				},
				o = {
					{ "x", 30, 1, 0.65 },
				},
			},
			LegBR_Lower = {
				k = {
					{ 0, 10, 0, 0 },
				},
				o = {
					{ "x", 30, 1, 0.75 },
				},
			},
			T1_2 = {
				o = {
					{ "x", 13.2, 2, 0 },
					{ "z", 11, 2, 0.25 },
				},
			},
			T1_3 = {
				o = {
					{ "x", 19.8, 2, 0.17 },
					{ "z", 17.6, 2, 0.48 },
				},
			},
			T1_4 = {
				o = {
					{ "x", 26.4, 2, 0.34 },
					{ "z", 24.2, 2, 0.71 },
				},
			},
			T2_2 = {
				o = {
					{ "x", 13.2, 2, 0.37 },
					{ "z", 11, 2, 0.86 },
				},
			},
			T2_3 = {
				o = {
					{ "x", 19.8, 2, 0.54 },
					{ "z", 17.6, 2, 0.09 },
				},
			},
			T2_4 = {
				o = {
					{ "x", 26.4, 2, 0.71 },
					{ "z", 24.2, 2, 0.32 },
				},
			},
			T3_2 = {
				o = {
					{ "x", 13.2, 2, 0.74 },
					{ "z", 11, 2, 0.47 },
				},
			},
			T3_3 = {
				o = {
					{ "x", 19.8, 2, 0.91 },
					{ "z", 17.6, 2, 0.7 },
				},
			},
			T3_4 = {
				o = {
					{ "x", 26.4, 2, 0.08 },
					{ "z", 24.2, 2, 0.93 },
				},
			},
			T4_2 = {
				o = {
					{ "x", 13.2, 2, 0.11 },
					{ "z", 11, 2, 0.08 },
				},
			},
			T4_3 = {
				o = {
					{ "x", 19.8, 2, 0.28 },
					{ "z", 17.6, 2, 0.31 },
				},
			},
			T4_4 = {
				o = {
					{ "x", 26.4, 2, 0.45 },
					{ "z", 24.2, 2, 0.54 },
				},
			},
			T5_2 = {
				o = {
					{ "x", 13.2, 2, 0.48 },
					{ "z", 11, 2, 0.69 },
				},
			},
			T5_3 = {
				o = {
					{ "x", 19.8, 2, 0.65 },
					{ "z", 17.6, 2, 0.92 },
				},
			},
			T5_4 = {
				o = {
					{ "x", 26.4, 2, 0.82 },
					{ "z", 24.2, 2, 0.15 },
				},
			},
			T6_2 = {
				o = {
					{ "x", 13.2, 2, 0.85 },
					{ "z", 11, 2, 0.3 },
				},
			},
			T6_3 = {
				o = {
					{ "x", 19.8, 2, 0.02 },
					{ "z", 17.6, 2, 0.53 },
				},
			},
			T6_4 = {
				o = {
					{ "x", 26.4, 2, 0.19 },
					{ "z", 24.2, 2, 0.76 },
				},
			},
			T7_2 = {
				o = {
					{ "x", 13.2, 2, 0.22 },
					{ "z", 11, 2, 0.91 },
				},
			},
			T7_3 = {
				o = {
					{ "x", 19.8, 2, 0.39 },
					{ "z", 17.6, 2, 0.14 },
				},
			},
			T7_4 = {
				o = {
					{ "x", 26.4, 2, 0.56 },
					{ "z", 24.2, 2, 0.37 },
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
			LegFR_Upper = {
				o = {
					{ "x", 36, 1, 0.1 },
				},
			},
			LegFR_Lower = {
				o = {
					{ "x", 30, 1, 0.25 },
				},
			},
			LegBL_Upper = {
				o = {
					{ "x", 36, 1, 0.5 },
				},
			},
			LegBR_Upper = {
				o = {
					{ "x", 36, 1, 0.6 },
				},
			},
			Spine = {
				o = {
					{ "x", 5, 1, 0.5 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -35, 0, 0 },
				},
			},
		},
	},
	Shriek = {
		dur = 2.6,
		loop = false,
		next = "CreatureIdle",
		joints = {
			Hips = {
				p = {
					{ 0, 0, 1.1925, 0 },
				},
			},
			Neck2 = {
				p = {
					{ 0, 0, 0.5359, -0.3118 },
				},
			},
			Neck3 = {
				p = {
					{ 0, 0, 0.5459, -0.2939 },
				},
			},
			Head = {
				p = {
					{ 0, 0, 0.5636, -0.2583 },
				},
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, 40, 0, 0 },
					{ 2.1, 38, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
				o = {
					{ "z", 3, 40, 0 },
				},
			},
			LegFL_Cannon = {
				p = {
					{ 0, 0.026, -0.7119, -0.1042 },
				},
			},
			LegFL_Hoof = {
				p = {
					{ 0, 0.0095, -0.7197, -0.0189 },
				},
			},
			LegFR_Cannon = {
				p = {
					{ 0, -0.026, -0.7119, -0.1042 },
				},
			},
			LegFR_Hoof = {
				p = {
					{ 0, -0.0095, -0.7197, -0.0189 },
				},
			},
			LegBL_Cannon = {
				p = {
					{ 0, 0.0412, -0.4801, 0.535 },
				},
			},
			LegBL_Hoof = {
				p = {
					{ 0, 0.0074, -0.7124, -0.1039 },
				},
			},
			LegBR_Cannon = {
				p = {
					{ 0, -0.0412, -0.4801, 0.535 },
				},
			},
			LegBR_Hoof = {
				p = {
					{ 0, -0.0074, -0.7124, -0.1039 },
				},
			},
			Jaw = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.35, -140, 0, 0 },
					{ 2.1, -135, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
				o = {
					{ "x", 4, 36, 0 },
				},
			},
			EarL = {
				k = {
					{ 0, 0, 0, -35 },
				},
			},
			EarR = {
				k = {
					{ 0, 0, 0, 35 },
				},
			},
			Tail = {
				k = {
					{ 0, 30, 0, 0 },
				},
			},
			LegBL_Lower = {
				k = {
					{ 0, 10, 0, 0 },
				},
			},
			LegBR_Lower = {
				k = {
					{ 0, 10, 0, 0 },
				},
			},
			T1_2 = {
				o = {
					{ "x", 21, 6, 0 },
					{ "z", 17.5, 6, 0.25 },
				},
			},
			T1_3 = {
				o = {
					{ "x", 31.5, 6, 0.17 },
					{ "z", 28, 6, 0.48 },
				},
			},
			T1_4 = {
				o = {
					{ "x", 42, 6, 0.34 },
					{ "z", 38.5, 6, 0.71 },
				},
			},
			T2_2 = {
				o = {
					{ "x", 21, 6, 0.37 },
					{ "z", 17.5, 6, 0.86 },
				},
			},
			T2_3 = {
				o = {
					{ "x", 31.5, 6, 0.54 },
					{ "z", 28, 6, 0.09 },
				},
			},
			T2_4 = {
				o = {
					{ "x", 42, 6, 0.71 },
					{ "z", 38.5, 6, 0.32 },
				},
			},
			T3_2 = {
				o = {
					{ "x", 21, 6, 0.74 },
					{ "z", 17.5, 6, 0.47 },
				},
			},
			T3_3 = {
				o = {
					{ "x", 31.5, 6, 0.91 },
					{ "z", 28, 6, 0.7 },
				},
			},
			T3_4 = {
				o = {
					{ "x", 42, 6, 0.08 },
					{ "z", 38.5, 6, 0.93 },
				},
			},
			T4_2 = {
				o = {
					{ "x", 21, 6, 0.11 },
					{ "z", 17.5, 6, 0.08 },
				},
			},
			T4_3 = {
				o = {
					{ "x", 31.5, 6, 0.28 },
					{ "z", 28, 6, 0.31 },
				},
			},
			T4_4 = {
				o = {
					{ "x", 42, 6, 0.45 },
					{ "z", 38.5, 6, 0.54 },
				},
			},
			T5_2 = {
				o = {
					{ "x", 21, 6, 0.48 },
					{ "z", 17.5, 6, 0.69 },
				},
			},
			T5_3 = {
				o = {
					{ "x", 31.5, 6, 0.65 },
					{ "z", 28, 6, 0.92 },
				},
			},
			T5_4 = {
				o = {
					{ "x", 42, 6, 0.82 },
					{ "z", 38.5, 6, 0.15 },
				},
			},
			T6_2 = {
				o = {
					{ "x", 21, 6, 0.85 },
					{ "z", 17.5, 6, 0.3 },
				},
			},
			T6_3 = {
				o = {
					{ "x", 31.5, 6, 0.02 },
					{ "z", 28, 6, 0.53 },
				},
			},
			T6_4 = {
				o = {
					{ "x", 42, 6, 0.19 },
					{ "z", 38.5, 6, 0.76 },
				},
			},
			T7_2 = {
				o = {
					{ "x", 21, 6, 0.22 },
					{ "z", 17.5, 6, 0.91 },
				},
			},
			T7_3 = {
				o = {
					{ "x", 31.5, 6, 0.39 },
					{ "z", 28, 6, 0.14 },
				},
			},
			T7_4 = {
				o = {
					{ "x", 42, 6, 0.56 },
					{ "z", 38.5, 6, 0.37 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, 18, 0, 0 },
					{ 2.1, 18, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
				o = {
					{ "y", 2, 30, 0 },
				},
			},
		},
	},
}
]=======],
	Brain = [=======[
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
]=======],
	Herd = [=======[
--[[
	DeerHerd (Script) · ServerScriptService.DeerHerd

	Crea los ciervos del mapa y los mueve. Uno de cada 7 está maldito (nadie lo sabe hasta que se transforma).
	Todos los jugadores ven los mismos ciervos. El servidor decide (DeerBrain) y publica atributos;
	los clientes (DeerClient) animan los huesos, porque Roblox no replica Bone.Transform.

	Dónde aparecen: partes con la etiqueta "DeerSpawn" o dentro de Workspace.DeerSpawns (cada una es el centro
	de una manada). Si no hay, alrededor de Settings.SpawnCenter dentro de Settings.SpawnRadius.

	Atributos de cada Workspace.Deer.Deer_N:
	  Root (CFrame) · Anim, AnimFade, AnimStamp · Form ("deer"/"creature") · FormStamp
	  Visible, FadeTime, FadeStamp · HasAntlers
	(Que esté maldito NO se publica: un cliente no puede saberlo de antemano.)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local folder = ReplicatedStorage:WaitForChild("Creatures"):WaitForChild("CursedDeer")
local Brain = require(folder:WaitForChild("DeerBrain"))
local settings = folder:WaitForChild("Settings")
local template = folder:WaitForChild("CursedDeer") :: Model

local COUNT = settings:GetAttribute("Count") or 14
local RATIO = settings:GetAttribute("CursedRatio") or 7
local HERD_SIZE = settings:GetAttribute("HerdSize") or 4
local HOME_RADIUS = settings:GetAttribute("HomeRadius") or 45
local DAMAGE = settings:GetAttribute("Damage") or 0
local ANTLER_CHANCE = settings:GetAttribute("AntlerChance") or 0.5
local SPAWN_CENTER = settings:GetAttribute("SpawnCenter") or Vector3.new(0, 0, 0)
local SPAWN_RADIUS = settings:GetAttribute("SpawnRadius") or 220
local DEBUG = settings:GetAttribute("Debug") == true
local config = {}
for k, v in pairs(settings:GetAttributes()) do
	if Brain.Defaults[k] ~= nil and type(v) == type(Brain.Defaults[k]) then
		config[k] = v
	end
end

local container = workspace:FindFirstChild("Deer") or Instance.new("Folder")
container.Name = "Deer"
container.Parent = workspace
local scale = template:GetAttribute("RigScale") or 1

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
refreshFilter()

local function groundAt(x, z, fromY)
	local hit = workspace:Raycast(Vector3.new(x, fromY + 80, z), Vector3.new(0, -400, 0), rayParams)
	if hit and hit.Normal.Y > 0.55 and hit.Material ~= Enum.Material.Water then
		return hit.Position
	end
	return nil
end

-- centros de manada
local centers = {}
local tagged = CollectionService:GetTagged("DeerSpawn")
local sf = workspace:FindFirstChild("DeerSpawns")
if sf then
	for _, d in ipairs(sf:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(tagged, d)
		end
	end
end
for _, p in ipairs(tagged) do
	table.insert(centers, p.Position)
end
local rng = Random.new()
local function randomCenter()
	for _ = 1, 30 do
		local a = rng:NextNumber() * math.pi * 2
		local r = math.sqrt(rng:NextNumber()) * SPAWN_RADIUS
		local g = groundAt(SPAWN_CENTER.X + math.cos(a) * r, SPAWN_CENTER.Z + math.sin(a) * r, SPAWN_CENTER.Y)
		if g then
			return g
		end
	end
	return SPAWN_CENTER
end
local herds = math.max(1, math.ceil(COUNT / HERD_SIZE))
while #centers < herds do
	table.insert(centers, randomCenter())
end

local function nearestPlayerTo(pos)
	local best, bestD = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h = c and c:FindFirstChild("HumanoidRootPart")
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if h and hum and hum.Health > 0 then
			local d = (h.Position - pos).Magnitude
			if d < bestD then
				best, bestD = h, d
			end
		end
	end
	return best, bestD
end

local function spotNear(center, radius, avoidPlayers)
	for _ = 1, 20 do
		local a = rng:NextNumber() * math.pi * 2
		local r = math.sqrt(rng:NextNumber()) * radius
		local g = groundAt(center.X + math.cos(a) * r, center.Z + math.sin(a) * r, center.Y)
		if g then
			local _, d = nearestPlayerTo(g)
			if not avoidPlayers or d > 90 then
				return g
			end
		end
	end
	return groundAt(center.X, center.Z, center.Y) or center
end

local cursedSet, cursedCount = Brain.PickCursed(COUNT, rng, RATIO)
if DEBUG then
	print(("[DeerHerd] %d ciervos, %d malditos"):format(COUNT, cursedCount))
end

local deer = {}
local stamp = 0
local function setAttr(d, k, v)
	d.model:SetAttribute(k, v)
end

for i = 1, COUNT do
	local home = centers[(i - 1) % #centers + 1]
	local pos = spotNear(home, 18, false)
	local m = template:Clone()
	m.Name = "Deer_" .. i
	for _, part in ipairs(m:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	local root = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
	local d = {
		model = m, home = home, root = root, brain = Brain.new(table.clone(config), Random.new(rng:NextInteger(1, 1e9)), cursedSet[i]),
		speed = 0, mode = "stop", target = nil, wander = pos, alarmT = -1e9, ground = 0, blocked = false, hitT = 0,
	}
	m:SetAttribute("Root", root)
	m:SetAttribute("Anim", "Graze")
	m:SetAttribute("AnimFade", 0)
	m:SetAttribute("AnimStamp", 0)
	m:SetAttribute("Form", "deer")
	m:SetAttribute("FormStamp", 0)
	m:SetAttribute("Visible", true)
	m:SetAttribute("FadeTime", 0)
	m:SetAttribute("FadeStamp", 0)
	m:SetAttribute("HasAntlers", rng:NextNumber() < ANTLER_CHANCE)
	m:PivotTo(root)
	m.Parent = container
	deer[i] = d
end

local function playSound(d, name)
	local body = d.model:FindFirstChild("DeerBody", true)
	local s = body and body:FindFirstChild(name)
	if s and s.SoundId ~= "" then
		s.PlaybackSpeed = 0.9 + rng:NextNumber() * 0.2
		s:Play()
	end
end

local function apply(d, cmds)
	for _, c in ipairs(cmds) do
		local k = c[1]
		stamp += 1
		if DEBUG then
			print("[DeerHerd]", d.model.Name, d.brain.state, k, tostring(c[2]), tostring(c[3]))
		end
		if k == "anim" then
			setAttr(d, "Anim", c[2])
			setAttr(d, "AnimFade", c[3] or 0.3)
			setAttr(d, "AnimStamp", stamp)
		elseif k == "move" then
			d.speed, d.mode = c[2] * scale, c[3]
		elseif k == "wanderTarget" then
			d.wander = spotNear(d.home, HOME_RADIUS, false)
		elseif k == "alarm" then
			for _, o in ipairs(deer) do
				if o ~= d and (o.root.Position - d.root.Position).Magnitude < 40 then
					o.alarmT = os.clock()
				end
			end
		elseif k == "form" then
			setAttr(d, "Form", c[2])
			setAttr(d, "FormStamp", stamp)
		elseif k == "sound" then
			playSound(d, c[2])
		elseif k == "vanish" or k == "appear" then
			setAttr(d, "FadeTime", c[2])
			setAttr(d, "Visible", k == "appear")
			setAttr(d, "FadeStamp", stamp)
		elseif k == "respawn" then
			local pos = spotNear(d.home, HOME_RADIUS, true)
			d.root = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
			setAttr(d, "Root", d.root)
		end
	end
end

-- movimiento de todos (cada frame, barato: sin física)
RunService.Heartbeat:Connect(function(dt)
	for _, d in ipairs(deer) do
		if d.mode ~= "stop" then
			local pos = d.root.Position
			local cur = d.root.LookVector * Vector3.new(1, 0, 1)
			local want
			if d.mode == "wander" then
				want = (d.wander - pos) * Vector3.new(1, 0, 1)
				if want.Magnitude < 2 then
					d.speed = 0
				end
			elseif d.target then
				local tp = d.target.Position
				want = (tp - pos) * Vector3.new(1, 0, 1)
				if d.mode == "flee" then
					want = -want
				end
			end
			if want and want.Magnitude > 0.1 then
				local maxTurn = math.rad(d.speed > 10 and 200 or 110) * dt
				local ang = math.atan2(cur:Cross(want.Unit).Y, cur:Dot(want.Unit))
				local dir = (CFrame.Angles(0, math.clamp(ang, -maxTurn, maxTurn), 0) * cur).Unit
				d.ground -= dt
				if d.ground <= 0 then
					d.ground = 0.25
					d.blocked = d.speed > 0 and workspace:Raycast(pos + Vector3.new(0, 2 * scale, 0), dir * 5 * scale, rayParams) ~= nil
					if d.blocked and d.mode == "flee" then   -- huyendo, esquiva girando
						dir = (CFrame.Angles(0, math.rad(rng:NextNumber() < 0.5 and 90 or -90), 0) * dir).Unit
						d.blocked = false
					end
				end
				if d.speed > 0 and not d.blocked then
					pos += dir * d.speed * dt
					if d.ground >= 0.24 then
						local g = groundAt(pos.X, pos.Z, pos.Y)
						if g then
							pos = Vector3.new(pos.X, g.Y, pos.Z)
						end
					end
				end
				d.root = CFrame.lookAt(pos, pos + dir)
			end
		end
		-- daño opcional al tocar (desactivado por defecto: Damage = 0)
		if DAMAGE > 0 and d.brain.form == "creature" and d.target and os.clock() - d.hitT > 1.2 then
			if (d.target.Position - d.root.Position).Magnitude < 5 * scale then
				local hum = d.target.Parent and d.target.Parent:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:TakeDamage(DAMAGE)
					d.hitT = os.clock()
				end
			end
		end
	end
end)

-- pensar y publicar 10 veces por segundo
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.1 then
		return
	end
	local step = acc
	acc = 0
	refreshFilter()
	local night = Lighting.ClockTime >= 18.5 or Lighting.ClockTime < 5.5
	for _, d in ipairs(deer) do
		local target, dist = nearestPlayerTo(d.root.Position)
		d.target = target
		local P = { dist = dist, alarm = os.clock() - d.alarmT < 1.5, night = night }
		apply(d, d.brain:Update(step, P))
		if d.model:GetAttribute("Root") ~= d.root then
			d.model:SetAttribute("Root", d.root)
		end
	end
end)
]=======],
	Client = [=======[
--[[
	DeerClient (LocalScript) · StarterPlayer.StarterPlayerScripts.DeerClient

	Parte visual de todos los ciervos en cada jugador:
	  · anima los huesos con DragonAnimator según el atributo Anim que publica el servidor
	  · suaviza el movimiento hacia el Root del servidor
	  · forma: el ciervo (DeerBody + Antlers) o la criatura (HorrorBody + Tentacles + Antlers)
	  · transformación: a los 1,15 s de empezar "Transform" la piel de la criatura aparece por encima del
	    ciervo (0,4 s) y los tentáculos crecen desde el cráneo; después el ciervo se oculta
	  · rendimiento: lejos se anima menos veces por segundo y muy lejos se pausa
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Creatures = ReplicatedStorage:WaitForChild("Creatures")
local DragonAnimator = require(ReplicatedStorage:WaitForChild("Dragons"):WaitForChild("DragonAnimator"))
local folder = Creatures:WaitForChild("CursedDeer")
local animations = require(folder:WaitForChild("Animations"))
local container = workspace:WaitForChild("Deer")

local LOOK = { Head = "Head", Neck = "Neck2", NeckShare = 0.4, MaxYaw = 70, MaxPitch = 30, RestPitch = -30, Speed = 2 }
local CROSSFADE_AT, CROSSFADE_TIME = 1.15, 0.4

local entries = {}

local function setGroup(e, group, alpha) -- alpha: 1 = visible
	for _, p in ipairs(e.parts[group]) do
		p.LocalTransparencyModifier = 1 - alpha
	end
end

local function applyForm(e, form)
	e.form = form
	local creature = form == "creature"
	setGroup(e, "deer", creature and 0 or e.vis)
	setGroup(e, "creature", creature and e.vis or 0)
	setGroup(e, "antlers", e.antlers and e.vis or 0)
end

local function setup(model: Model)
	if entries[model] or not model:IsA("Model") then
		return
	end
	local e = { model = model, parts = { deer = {}, creature = {}, antlers = {} }, vis = 1, visGoal = 1, fade = 1 }
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("MeshPart") then
			local n = d.Name
			if n == "DeerBody" then
				table.insert(e.parts.deer, d)
			elseif n == "HorrorBody" or n == "Tentacles" then
				table.insert(e.parts.creature, d)
			elseif n == "Antlers" then
				table.insert(e.parts.antlers, d)
			end
		end
	end
	e.antlers = model:GetAttribute("HasAntlers") ~= false
	e.animator = DragonAnimator.new(model, animations)
	e.animator:Play(model:GetAttribute("Anim") or "Graze", 0)
	e.current = model:GetAttribute("Root") or model:GetPivot()
	model:PivotTo(e.current)
	applyForm(e, model:GetAttribute("Form") or "deer")
	model:GetAttributeChangedSignal("AnimStamp"):Connect(function()
		local name = model:GetAttribute("Anim")
		e.animator:Play(name, model:GetAttribute("AnimFade") or 0.3)
		if name == "Transform" then
			e.transformT = 0
		end
		-- la criatura mira al jugador mientras acecha; el ciervo, mientras está alerta
		local look = name == "Alert" or name == "Transform" or name == "Shriek" or name:sub(1, 8) == "Creature"
		e.animator:SetLookTarget(look and function()
			local cam = workspace.CurrentCamera
			return cam and cam.CFrame.Position
		end or nil, LOOK)
	end)
	model:GetAttributeChangedSignal("FormStamp"):Connect(function()
		if model:GetAttribute("Form") == "deer" then
			e.transformT = nil
			applyForm(e, "deer")
		end -- la forma de criatura la pone la línea de tiempo de Transform
	end)
	local function onFade()
		e.visGoal = model:GetAttribute("Visible") and 1 or 0
		e.fade = math.max(model:GetAttribute("FadeTime") or 1, 0.01)
	end
	model:GetAttributeChangedSignal("FadeStamp"):Connect(onFade)
	onFade()
	e.vis = e.visGoal
	model:GetAttributeChangedSignal("HasAntlers"):Connect(function()
		e.antlers = model:GetAttribute("HasAntlers") ~= false
		applyForm(e, e.form)
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
		-- fundido de aparición / desaparición
		if e.vis ~= e.visGoal then
			local s = dt / e.fade
			e.vis = e.visGoal > e.vis and math.min(e.visGoal, e.vis + s) or math.max(e.visGoal, e.vis - s)
			applyForm(e, e.form)
		end
		-- transformación: la piel de la criatura cubre al ciervo y luego el ciervo se oculta
		if e.transformT then
			e.transformT += dt
			local a = math.clamp((e.transformT - CROSSFADE_AT) / CROSSFADE_TIME, 0, 1)
			setGroup(e, "creature", a * e.vis)
			if a >= 1 then
				e.transformT = nil
				applyForm(e, "creature")
			end
		end
		-- posición suave
		local goal = model:GetAttribute("Root") or e.current
		local far = (goal.Position - e.current.Position).Magnitude > 20
		e.current = (far or e.vis <= 0.001) and goal or e.current:Lerp(goal, 1 - math.exp(-dt * 10))
		local d = (camPos - e.current.Position).Magnitude
		local visible = e.vis > 0.001 and d < 600
		if visible then
			model:PivotTo(e.current)
		end
		-- rendimiento: menos actualizaciones lejos; pausa si no se ve
		e.animator.Paused = not visible
		e.animator.UpdateInterval = d < 70 and 0 or (d < 180 and 1 / 20 or 1 / 8)
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
local function looksLikeDeer(inst)
	return inst:FindFirstChild("DeerBody", true) and inst:FindFirstChild("Neck3", true)
end
local source
for _, s in ipairs(Selection:Get()) do
	local cand = s:IsA("BasePart") and s.Parent or s
	if looksLikeDeer(cand) then
		source = cand
		break
	end
end
if not source then
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and looksLikeDeer(d) and not d:GetAttribute("RigScale") then
			source = d
			break
		end
	end
end
assert(source, "[Deer] No encontré el modelo importado. Impórtalo con Import 3D (Rig Type: Custom) y selecciónalo.")

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
for _, name in ipairs({ "DeerBody", "HorrorBody", "Antlers", "Tentacles" }) do
	local m = source:FindFirstChild(name, true)
	if m and m:IsA("MeshPart") then
		meshes[name] = m
	else
		table.insert(missing, name)
	end
end
assert(#missing == 0, "[Deer] Faltan piezas o huesos: " .. table.concat(missing, ", ") .. ". ¿Rig Type estaba en Custom?")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar el ciervo maldito")
end)

-- 2. Calibración: escala y orientación con que el importador dejó el esqueleto
local function ratio(a, b)
	return (bones[a].WorldPosition - bones[b].WorldPosition).Magnitude / (v3(byName[a].head) - v3(byName[b].head)).Magnitude
end
local scale = (ratio("Hips", "Head") + ratio("LegFL_Hoof", "LegBR_Hoof") + ratio("Tail", "EarL")) / 3
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
print(("[Deer] escala del import: %.4f · error máximo de huesos: %.3f studs"):format(scale, bestErr))
if bestErr > 0.3 * scale then
	warn("[Deer] Los huesos no coinciden con el rig esperado. Revisa la importación. Continúo igualmente.")
end
local function W(t)
	return origin + R:VectorToWorldSpace(v3(t) * scale)
end

-- 3. Modelo: DeerBody anclado y el resto soldado, para que los huesos deformen todas las mallas a la vez
local model = Instance.new("Model")
model.Name = "CursedDeer"
for _, child in ipairs(source:GetChildren()) do
	child.Parent = model
end
for name, m in pairs(meshes) do
	m.Parent = model
	m.CanCollide = false
	m.CanTouch = false
	m.CastShadow = true
	m.Anchored = name == "DeerBody"
	m.Massless = name ~= "DeerBody"
	-- la forma de criatura empieza oculta (DeerClient la muestra al transformarse)
	m.Transparency = 0
	if name ~= "DeerBody" then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = meshes.DeerBody
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
model.PrimaryPart = meshes.DeerBody
model.WorldPivot = CFrame.new(W({ byName.Hips.head[1], 0, byName.Hips.head[3] })) * R
for name, id in pairs(SOUND_IDS) do
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Volume = name == "Shriek" and 1 or 0.6
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = name == "Shriek" and 220 or 90
	s.Parent = meshes.DeerBody
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
local folder = ensure(creatures, "CursedDeer")
local prev = folder:FindFirstChild("CursedDeer")
if prev then
	prev:Destroy()
end
model.Parent = folder
local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({
	DisplayName = "Ciervo", Count = COUNT, CursedRatio = CURSED_RATIO, Damage = DAMAGE, NightOnly = NIGHT_ONLY,
	SpawnCenter = SPAWN_CENTER, SpawnRadius = SPAWN_RADIUS, HerdSize = 4, HomeRadius = 45, AntlerChance = 0.5, Debug = false,
	-- ajustes del comportamiento (ver DeerBrain.Defaults)
	AlertDistance = 45, FleeDistance = 24, TriggerMin = 12, TriggerMax = 26, StalkSpeed = 7, ChaseSpeed = 27, LoseDistance = 150,
}) do
	settings:SetAttribute(k, v)
end
putScript(ensure(ReplicatedStorage, "Dragons"), "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(folder, "DeerBrain", "ModuleScript", SOURCES.Brain)
putScript(game:GetService("ServerScriptService"), "DeerHerd", "Script", SOURCES.Herd)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "DeerClient", "LocalScript", SOURCES.Client)

local assets = ensure(ServerStorage, "DragonAssets")
local bak = assets:FindFirstChild("CursedDeer_Rig")
if bak then
	bak:Destroy()
end
local backup = model:Clone()
backup.Name = "CursedDeer_Rig"
backup.Parent = assets

if source.Parent and #source:GetChildren() == 0 then
	source:Destroy()
end
Selection:Set({ folder })
pcall(function()
	ChangeHistoryService:SetWaypoint("Ciervo maldito instalado")
end)
print(("[Deer] Listo: %d huesos, 4 mallas. Al pulsar Play aparecen %d ciervos; %d de ellos están malditos."):format(#RIG, COUNT, math.max(COUNT >= 4 and 1 or 0, math.floor(COUNT / CURSED_RATIO + 0.5))))
