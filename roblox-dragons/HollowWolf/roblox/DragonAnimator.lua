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
