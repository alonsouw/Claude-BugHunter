--[[
	INSTALADOR DEL DRAGÓN SOMBRÍO (rig de huesos) · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	Pasos:
	  1. Studio > pestaña Avatar (o Home) > Import 3D > ShadowDragon.fbx.
	     En el importador: Rig General > Rig Type = "Custom" (malla con huesos). No combines las mallas.
	     Pulsa Import. Aparece el modelo en Workspace con las mallas Body, Teeth, WingL y WingR y sus Bones.
	  2. Selecciona ese modelo en el Explorer.
	  3. View > Command Bar. Pega TODO este archivo y pulsa Enter.

	Resultado:
	  ReplicatedStorage.Dragons.ShadowDragon          (modelo con huesos, Settings, Animations)
	  ReplicatedStorage.Dragons.DragonAnimator          (motor de animación por datos, Motor6D o Bones)
	  ServerStorage.DragonAssets.ShadowDragon_Rig     (copia de seguridad)
	  Workspace.DragonShowcase.Stage_Shadow           (escenario + estatua de vista previa)
	  StarterPlayer.StarterPlayerScripts.ShadowShowcase (vitrina nocturna, botones 1-9)
]]

-- Opcional: escala final en studs por unidad del modelo (1 = unos 45 studs de largo y 19 de alto).
local DESIRED_SCALE = 1
-- Opcional: tras subir los PNG (Asset Manager), pega aquí sus ids para crear SurfaceAppearance PBR.
local MAPS = {
	Body = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	WingL = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	WingR = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
}
-- Teeth no lleva texturas: es marfil liso y de noche la vitrina la pasa a Neon (la sonrisa brilla).

local RIG = {
	{ name = "Root", parent = nil, head = { 0, 0, 4.4 }, tail = { 0, 1.5, 4.4 } },
	{ name = "Hips", parent = "Root", head = { 0, 12, 4.4 }, tail = { 0, 13.6, 2 } },
	{ name = "Spine1", parent = "Hips", head = { 0, 13.6, 2 }, tail = { 0, 14.3, -0.8 } },
	{ name = "Chest", parent = "Spine1", head = { 0, 14.3, -0.8 }, tail = { 0, 13.4, -3.4 } },
	{ name = "Neck1", parent = "Chest", head = { 0, 13.4, -3.4 }, tail = { 0, 12, -5.6 } },
	{ name = "Neck2", parent = "Neck1", head = { 0, 12, -5.6 }, tail = { 0, 10.2, -7.6 } },
	{ name = "Neck3", parent = "Neck2", head = { 0, 10.2, -7.6 }, tail = { 0, 7.2, -10.6 } },
	{ name = "Head", parent = "Neck3", head = { 0, 7.2, -10.6 }, tail = { 0, 6.8139, -13.2854 } },
	{ name = "Jaw", parent = "Head", head = { 0, 7.1589, -11.8035 }, tail = { 0, 4.3383, -13.3875 } },
	{ name = "Tail1", parent = "Hips", head = { 0, 12, 4.4 }, tail = { 0, 10, 6.4 } },
	{ name = "Tail2", parent = "Tail1", head = { 0, 10, 6.4 }, tail = { 0.3, 7.8, 8.4 } },
	{ name = "Tail3", parent = "Tail2", head = { 0.3, 7.8, 8.4 }, tail = { 0.5, 5.6, 10.6 } },
	{ name = "Tail4", parent = "Tail3", head = { 0.5, 5.6, 10.6 }, tail = { 0.2, 3.6, 13 } },
	{ name = "Tail5", parent = "Tail4", head = { 0.2, 3.6, 13 }, tail = { -0.4, 2, 15.6 } },
	{ name = "Tail6", parent = "Tail5", head = { -0.4, 2, 15.6 }, tail = { -1, 1, 18.4 } },
	{ name = "Tail7", parent = "Tail6", head = { -1, 1, 18.4 }, tail = { -1.4, 0.6, 21 } },
	{ name = "Tail8", parent = "Tail7", head = { -1.4, 0.6, 21 }, tail = { -1.851, 0.149, 23.9314 } },
	{ name = "LegFL_Upper", parent = "Chest", head = { -1.1, 13, -3.6 }, tail = { -3.2, 15.6, -6 } },
	{ name = "LegFL_Lower", parent = "LegFL_Upper", head = { -3.2, 15.6, -6 }, tail = { -3.7, 6.2, -12.9 } },
	{ name = "LegFL_Foot", parent = "LegFL_Lower", head = { -3.7, 6.2, -12.9 }, tail = { -3.9, 0.45, -16.4 } },
	{ name = "LegBL_Upper", parent = "Hips", head = { -1.2, 11.6, 4.4 }, tail = { -3, 4.6, 9.8 } },
	{ name = "LegBL_Lower", parent = "LegBL_Upper", head = { -3, 4.6, 9.8 }, tail = { -3.3, 8.6, 3.2 } },
	{ name = "LegBL_Foot", parent = "LegBL_Lower", head = { -3.3, 8.6, 3.2 }, tail = { -3.5, 0.45, 5.5 } },
	{ name = "LegFR_Upper", parent = "Chest", head = { 1.1, 13, -3.6 }, tail = { 3.2, 15.6, -6 } },
	{ name = "LegFR_Lower", parent = "LegFR_Upper", head = { 3.2, 15.6, -6 }, tail = { 3.7, 6.2, -12 } },
	{ name = "LegFR_Foot", parent = "LegFR_Lower", head = { 3.7, 6.2, -12 }, tail = { 3.9, 0.45, -15.5 } },
	{ name = "LegBR_Upper", parent = "Hips", head = { 1.2, 11.6, 4.4 }, tail = { 3, 4.6, 9.8 } },
	{ name = "LegBR_Lower", parent = "LegBR_Upper", head = { 3, 4.6, 9.8 }, tail = { 3.3, 8.6, 3.2 } },
	{ name = "LegBR_Foot", parent = "LegBR_Lower", head = { 3.3, 8.6, 3.2 }, tail = { 3.5, 0.45, 5.5 } },
	{ name = "WingL_Arm", parent = "Chest", head = { -1, 14, -2.8 }, tail = { -2.1, 15.7, 1.2 } },
	{ name = "WingL_Fore", parent = "WingL_Arm", head = { -2.1, 15.7, 1.2 }, tail = { -2.6, 14.3, 5 } },
	{ name = "WingL_Hand", parent = "WingL_Fore", head = { -2.6, 14.3, 5 }, tail = { -4, 7.9, 3.8 } },
	{ name = "WingR_Arm", parent = "Chest", head = { 1, 14, -2.8 }, tail = { 2.1, 15.7, 1.2 } },
	{ name = "WingR_Fore", parent = "WingR_Arm", head = { 2.1, 15.7, 1.2 }, tail = { 2.6, 14.3, 5 } },
	{ name = "WingR_Hand", parent = "WingR_Fore", head = { 2.6, 14.3, 5 }, tail = { 4, 7.9, 3.8 } },
}
local EYES = { EyeL = { 0.858, 8.0184, -12.9589 }, EyeR = { -0.858, 8.0184, -12.9589 }, bone = "Head" }
local GROUND_Y = -0.156
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
	self._conn = RunService.Stepped:Connect(function(_, dt)
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
	Animaciones del Dragón Sombrío (ModuleScript) · ReplicatedStorage.Dragons.ShadowDragon.Animations
	Generado desde src/shadow_anims.js con tools/build_roblox.js: edita la fuente y regenera.
	Formato: ver DragonAnimator. Ángulos en grados, traslaciones en studs, tiempos en segundos.
]]
return {
	Idle = {
		dur = 6,
		loop = true,
		joints = {
			Tail1 = {
				o = {
					{ "y", 1.44, 1, 0.06 },
				},
			},
			Tail2 = {
				o = {
					{ "y", 1.88, 1, 0.12 },
				},
			},
			Tail3 = {
				o = {
					{ "y", 2.32, 1, 0.18 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 2.76, 1, 0.24 },
				},
			},
			Tail5 = {
				o = {
					{ "y", 3.2, 1, 0.3 },
				},
			},
			Tail6 = {
				o = {
					{ "y", 3.64, 1, 0.36 },
				},
			},
			Tail7 = {
				o = {
					{ "y", 4.08, 1, 0.42 },
				},
			},
			Tail8 = {
				o = {
					{ "y", 4.52, 1, 0.48 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.08, 2, 0 },
				},
			},
			Spine1 = {
				o = {
					{ "x", 1.2, 2, 0.05 },
				},
			},
			Chest = {
				o = {
					{ "x", 1.5, 2, 0.1 },
				},
			},
			Neck1 = {
				o = {
					{ "x", 1.5, 1, 0 },
				},
			},
			Neck2 = {
				o = {
					{ "y", 2, 1, 0.1 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 2.2, 0, 0, 0 },
					{ 2.35, 0, 4, 22 },
					{ 3.9, 0, 4, 24 },
					{ 4.1, 0, 0, 0 },
				},
				o = {
					{ "z", 0.8, 30, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, 0, 0, 0 },
					{ 2.3, 0, 0, 0 },
					{ 2.5, -5, 0, 0 },
					{ 3.8, -5, 0, 0 },
					{ 4.1, 0, 0, 0 },
				},
			},
			LegFL_Foot = {
				o = {
					{ "x", 3, 3, 0.2 },
				},
			},
			LegFR_Foot = {
				o = {
					{ "x", 3, 3, 0.6 },
				},
			},
			WingL_Arm = {
				o = {
					{ "z", 1.5, 1, 0 },
				},
			},
			WingR_Arm = {
				o = {
					{ "z", -1.5, 1, 0 },
				},
			},
			WingL_Hand = {
				o = {
					{ "y", 2, 1, 0.2 },
				},
			},
			WingR_Hand = {
				o = {
					{ "y", -2, 1, 0.2 },
				},
			},
		},
	},
	Walk = {
		dur = 3.2,
		loop = true,
		joints = {
			Tail1 = {
				o = {
					{ "y", 3.6, 1, 0.16 },
				},
			},
			Tail2 = {
				o = {
					{ "y", 4.7, 1, 0.22 },
				},
			},
			Tail3 = {
				o = {
					{ "y", 5.8, 1, 0.28 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 6.9, 1, 0.34 },
				},
			},
			Tail5 = {
				o = {
					{ "y", 8, 1, 0.4 },
				},
			},
			Tail6 = {
				o = {
					{ "y", 9.1, 1, 0.46 },
				},
			},
			Tail7 = {
				o = {
					{ "y", 10.2, 1, 0.52 },
				},
			},
			Tail8 = {
				o = {
					{ "y", 11.3, 1, 0.58 },
				},
			},
			LegFL_Upper = {
				o = {
					{ "x", 16, 1, 0 },
				},
			},
			LegFL_Lower = {
				o = {
					{ "x", 22, 1, 0.2 },
				},
			},
			LegFL_Foot = {
				o = {
					{ "x", 18, 1, 0.35 },
				},
			},
			LegFR_Upper = {
				o = {
					{ "x", 16, 1, 0.5 },
				},
			},
			LegFR_Lower = {
				o = {
					{ "x", 22, 1, 0.7 },
				},
			},
			LegFR_Foot = {
				o = {
					{ "x", 18, 1, 0.85 },
				},
			},
			LegBL_Upper = {
				o = {
					{ "x", 16, 1, 0.62 },
				},
			},
			LegBL_Lower = {
				o = {
					{ "x", 22, 1, 0.82 },
				},
			},
			LegBL_Foot = {
				o = {
					{ "x", 18, 1, 0.97 },
				},
			},
			LegBR_Upper = {
				o = {
					{ "x", 16, 1, 0.12 },
				},
			},
			LegBR_Lower = {
				o = {
					{ "x", 22, 1, 0.32 },
				},
			},
			LegBR_Foot = {
				o = {
					{ "x", 18, 1, 0.47 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.25, 2, 0.1 },
					{ "z", 4, 1, 0.1 },
					{ "y", 4, 1, 0.3 },
				},
			},
			Spine1 = {
				o = {
					{ "z", -2, 1, 0.15 },
				},
			},
			Chest = {
				o = {
					{ "z", -3, 1, 0.2 },
					{ "y", -3, 1, 0.3 },
				},
			},
			Neck1 = {
				o = {
					{ "y", -2, 1, 0.3 },
				},
			},
			Neck2 = {
				o = {
					{ "z", 2, 1, 0.6 },
				},
			},
			Head = {
				o = {
					{ "z", -3, 1, 0.2 },
					{ "y", 2, 1, 0.8 },
				},
			},
		},
	},
	Run = {
		dur = 1,
		loop = true,
		joints = {
			Tail1 = {
				o = {
					{ "y", 4.32, 1, 0.16 },
					{ "x", 2.16, 2, 0.06 },
				},
			},
			Tail2 = {
				o = {
					{ "y", 5.64, 1, 0.22 },
					{ "x", 2.82, 2, 0.12 },
				},
			},
			Tail3 = {
				o = {
					{ "y", 6.96, 1, 0.28 },
					{ "x", 3.48, 2, 0.18 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 8.28, 1, 0.34 },
					{ "x", 4.14, 2, 0.24 },
				},
			},
			Tail5 = {
				o = {
					{ "y", 9.6, 1, 0.4 },
					{ "x", 4.8, 2, 0.3 },
				},
			},
			Tail6 = {
				o = {
					{ "y", 10.92, 1, 0.46 },
					{ "x", 5.46, 2, 0.36 },
				},
			},
			Tail7 = {
				o = {
					{ "y", 12.24, 1, 0.52 },
					{ "x", 6.12, 2, 0.42 },
				},
			},
			Tail8 = {
				o = {
					{ "y", 13.56, 1, 0.58 },
					{ "x", 6.78, 2, 0.48 },
				},
			},
			LegFL_Upper = {
				o = {
					{ "x", 35, 1, 0 },
				},
			},
			LegFL_Lower = {
				o = {
					{ "x", 30, 1, 0.2 },
				},
			},
			LegFL_Foot = {
				o = {
					{ "x", 22, 1, 0.35 },
				},
			},
			LegFR_Upper = {
				o = {
					{ "x", 35, 1, 0.08 },
				},
			},
			LegFR_Lower = {
				o = {
					{ "x", 30, 1, 0.28 },
				},
			},
			LegFR_Foot = {
				o = {
					{ "x", 22, 1, 0.43 },
				},
			},
			LegBL_Upper = {
				o = {
					{ "x", 35, 1, 0.5 },
				},
			},
			LegBL_Lower = {
				o = {
					{ "x", 30, 1, 0.7 },
				},
			},
			LegBL_Foot = {
				o = {
					{ "x", 22, 1, 0.85 },
				},
			},
			LegBR_Upper = {
				o = {
					{ "x", 35, 1, 0.58 },
				},
			},
			LegBR_Lower = {
				o = {
					{ "x", 30, 1, 0.78 },
				},
			},
			LegBR_Foot = {
				o = {
					{ "x", 22, 1, 0.93 },
				},
			},
			Hips = {
				k = {
					{ 0, -6, 0, 0 },
				},
				p = {
					{ 0, 0, -0.4, 0 },
				},
				o = {
					{ "py", 0.45, 2, 0 },
					{ "x", 5, 1, 0 },
				},
			},
			Chest = {
				o = {
					{ "x", 6, 1, 0.5 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -10, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 8, 0, 0 },
				},
				o = {
					{ "x", 4, 2, 0.3 },
				},
			},
			Jaw = {
				k = {
					{ 0, -8, 0, 0 },
				},
			},
			WingL_Hand = {
				k = {
					{ 0, 0, 10, 0 },
				},
			},
			WingR_Hand = {
				k = {
					{ 0, 0, -10, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 18, -8 },
				},
			},
			WingR_Arm = {
				k = {
					{ 0, 0, -18, 8 },
				},
			},
		},
	},
	Fly = {
		dur = 1.6,
		loop = true,
		joints = {
			Tail1 = {
				o = {
					{ "x", 2.16, 1, 0.36 },
					{ "y", 2.16, 1, 0.06 },
				},
			},
			Tail2 = {
				o = {
					{ "x", 2.82, 1, 0.42 },
					{ "y", 2.82, 1, 0.12 },
				},
			},
			Tail3 = {
				o = {
					{ "x", 3.48, 1, 0.48 },
					{ "y", 3.48, 1, 0.18 },
				},
			},
			Tail4 = {
				o = {
					{ "x", 4.14, 1, 0.54 },
					{ "y", 4.14, 1, 0.24 },
				},
			},
			Tail5 = {
				o = {
					{ "x", 4.8, 1, 0.6 },
					{ "y", 4.8, 1, 0.3 },
				},
			},
			Tail6 = {
				o = {
					{ "x", 5.46, 1, 0.66 },
					{ "y", 5.46, 1, 0.36 },
				},
			},
			Tail7 = {
				o = {
					{ "x", 6.12, 1, 0.72 },
					{ "y", 6.12, 1, 0.42 },
				},
			},
			Tail8 = {
				o = {
					{ "x", 6.78, 1, 0.78 },
					{ "y", 6.78, 1, 0.48 },
				},
			},
			Hips = {
				k = {
					{ 0, 4, 0, 0 },
				},
				p = {
					{ 0, 0, 7, 0 },
				},
				o = {
					{ "py", 0.7, 1, 0.25 },
				},
			},
			LegFL_Upper = {
				k = {
					{ 0, -35, 0, 0 },
				},
			},
			LegFL_Lower = {
				k = {
					{ 0, 60, 0, 0 },
				},
			},
			LegFL_Foot = {
				k = {
					{ 0, -30, 0, 0 },
				},
			},
			LegFR_Upper = {
				k = {
					{ 0, -35, 0, 0 },
				},
			},
			LegFR_Lower = {
				k = {
					{ 0, 60, 0, 0 },
				},
			},
			LegFR_Foot = {
				k = {
					{ 0, -30, 0, 0 },
				},
			},
			LegBL_Upper = {
				k = {
					{ 0, -50, 0, 0 },
				},
			},
			LegBL_Lower = {
				k = {
					{ 0, 35, 0, 0 },
				},
			},
			LegBL_Foot = {
				k = {
					{ 0, -25, 0, 0 },
				},
			},
			LegBR_Upper = {
				k = {
					{ 0, -50, 0, 0 },
				},
			},
			LegBR_Lower = {
				k = {
					{ 0, 35, 0, 0 },
				},
			},
			LegBR_Foot = {
				k = {
					{ 0, -25, 0, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -10, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, -6, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 10, 0, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -6, 0, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 0, -5 },
				},
				o = {
					{ "z", 45, 1, 0 },
				},
			},
			WingR_Arm = {
				k = {
					{ 0, 0, 0, 5 },
				},
				o = {
					{ "z", -45, 1, 0 },
				},
			},
			WingL_Hand = {
				o = {
					{ "z", 28, 1, 0.12 },
					{ "y", 10, 1, 0.3 },
				},
			},
			WingR_Hand = {
				o = {
					{ "z", -28, 1, 0.12 },
					{ "y", -10, 1, 0.3 },
				},
			},
			WingL_Fore = {
				o = {
					{ "z", 16, 1, 0.06 },
				},
			},
			WingR_Fore = {
				o = {
					{ "z", -16, 1, 0.06 },
				},
			},
		},
	},
	TakeOff = {
		dur = 1.8,
		loop = false,
		next = "Fly",
		joints = {
			Hips = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 6, 0, 0 },
					{ 0.8, -12, 0, 0 },
					{ 1.8, 4, 0, 0 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 0.45, 0, -1.2, 0 },
					{ 0.8, 0, 2.8, -0.8 },
					{ 1.8, 0, 7, 0 },
				},
			},
			LegBL_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 25, 0, 0 },
					{ 0.75, -30, 0, 0 },
					{ 1.8, -50, 0, 0 },
				},
			},
			LegBR_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 25, 0, 0 },
					{ 0.75, -30, 0, 0 },
					{ 1.8, -50, 0, 0 },
				},
			},
			LegBL_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, -40, 0, 0 },
					{ 0.75, 15, 0, 0 },
					{ 1.8, 35, 0, 0 },
				},
			},
			LegBR_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, -40, 0, 0 },
					{ 0.75, 15, 0, 0 },
					{ 1.8, 35, 0, 0 },
				},
			},
			LegBL_Foot = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.8, -25, 0, 0 },
				},
			},
			LegBR_Foot = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.8, -25, 0, 0 },
				},
			},
			LegFL_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 20, 0, 0 },
					{ 0.8, -20, 0, 0 },
					{ 1.8, -35, 0, 0 },
				},
			},
			LegFR_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 20, 0, 0 },
					{ 0.8, -20, 0, 0 },
					{ 1.8, -35, 0, 0 },
				},
			},
			LegFL_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, -30, 0, 0 },
					{ 0.8, 40, 0, 0 },
					{ 1.8, 60, 0, 0 },
				},
			},
			LegFR_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, -30, 0, 0 },
					{ 0.8, 40, 0, 0 },
					{ 1.8, 60, 0, 0 },
				},
			},
			LegFL_Foot = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.8, -30, 0, 0 },
				},
			},
			LegFR_Foot = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.8, -30, 0, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 8, 0, 0 },
					{ 1.8, -10, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.8, -6, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, -8, 0, 0 },
					{ 1.8, 10, 0, 0 },
				},
			},
			WingL_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 0, 0, -20 },
					{ 0.85, 0, 0, 30 },
					{ 1.2, 0, 0, -25 },
					{ 1.55, 0, 0, 25 },
					{ 1.8, 0, 0, 0 },
				},
			},
			WingR_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 0, 0, 20 },
					{ 0.85, 0, 0, -30 },
					{ 1.2, 0, 0, 25 },
					{ 1.55, 0, 0, -25 },
					{ 1.8, 0, 0, 0 },
				},
			},
			Tail1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, -10, 0, 0 },
					{ 0.85, 12, 0, 0 },
					{ 1.8, 0, 0, 0 },
				},
			},
			Tail3 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, -10, 0, 0 },
					{ 0.95, 14, 0, 0 },
					{ 1.8, 0, 0, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 6, 4 },
					{ 0.45, 0, -10, -50 },
					{ 0.8, 0, 0, 50 },
					{ 1.15, 0, 0, -40 },
					{ 1.5, 0, 0, 42 },
					{ 1.8, 0, 0, -5 },
				},
			},
			WingR_Arm = {
				k = {
					{ 0, 0, -6, -4 },
					{ 0.45, 0, 10, 50 },
					{ 0.8, 0, 0, -50 },
					{ 1.15, 0, 0, 40 },
					{ 1.5, 0, 0, -42 },
					{ 1.8, 0, 0, 5 },
				},
			},
		},
	},
	Landing = {
		dur = 1.5,
		loop = false,
		next = "Idle",
		joints = {
			Hips = {
				k = {
					{ 0, 4, 0, 0 },
					{ 0.6, 10, 0, 0 },
					{ 1, -5, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
				p = {
					{ 0, 0, 7, 0 },
					{ 0.8, 0, 0.6, 0 },
					{ 1, 0, -0.9, 0.2 },
					{ 1.5, 0, 0, 0 },
				},
			},
			LegFL_Upper = {
				k = {
					{ 0, -35, 0, 0 },
					{ 0.6, 25, 0, 0 },
					{ 1, 15, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			LegFR_Upper = {
				k = {
					{ 0, -35, 0, 0 },
					{ 0.6, 25, 0, 0 },
					{ 1, 15, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			LegFL_Lower = {
				k = {
					{ 0, 60, 0, 0 },
					{ 0.6, -10, 0, 0 },
					{ 1, -25, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			LegFR_Lower = {
				k = {
					{ 0, 60, 0, 0 },
					{ 0.6, -10, 0, 0 },
					{ 1, -25, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			LegFL_Foot = {
				k = {
					{ 0, -30, 0, 0 },
					{ 0.7, 0, 0, 0 },
				},
			},
			LegFR_Foot = {
				k = {
					{ 0, -30, 0, 0 },
					{ 0.7, 0, 0, 0 },
				},
			},
			LegBL_Upper = {
				k = {
					{ 0, -50, 0, 0 },
					{ 0.6, 15, 0, 0 },
					{ 1, 25, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			LegBR_Upper = {
				k = {
					{ 0, -50, 0, 0 },
					{ 0.6, 15, 0, 0 },
					{ 1, 25, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			LegBL_Lower = {
				k = {
					{ 0, 35, 0, 0 },
					{ 0.6, 0, 0, 0 },
					{ 1, -35, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			LegBR_Lower = {
				k = {
					{ 0, 35, 0, 0 },
					{ 0.6, 0, 0, 0 },
					{ 1, -35, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			LegBL_Foot = {
				k = {
					{ 0, -25, 0, 0 },
					{ 0.7, 0, 0, 0 },
				},
			},
			LegBR_Foot = {
				k = {
					{ 0, -25, 0, 0 },
					{ 0.7, 0, 0, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -10, 0, 0 },
					{ 0.7, 8, 0, 0 },
					{ 1.05, -10, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, -6, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 10, 0, 0 },
					{ 1.05, -8, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -6, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 0, -5 },
					{ 0.35, 0, -10, -55 },
					{ 0.7, 0, 0, 25 },
					{ 1, 0, 10, -15 },
					{ 1.5, 0, 6, 4 },
				},
			},
			WingR_Arm = {
				k = {
					{ 0, 0, 0, 5 },
					{ 0.35, 0, 10, 55 },
					{ 0.7, 0, 0, -25 },
					{ 1, 0, -10, 15 },
					{ 1.5, 0, -6, -4 },
				},
			},
		},
	},
	Attack = {
		dur = 1.4,
		loop = false,
		next = "Idle",
		joints = {
			Hips = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 6, 0, 0 },
					{ 0.62, -8, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 0.45, 0, 0.3, 0.8 },
					{ 0.62, 0, -0.4, -2 },
					{ 1, 0, -0.2, -1.2 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 22, 0, 0 },
					{ 0.62, -25, 0, 0 },
					{ 0.95, -20, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 15, 0, 0 },
					{ 0.62, -18, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 15, 0, 0 },
					{ 0.62, -5, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, -30, 0, 0 },
					{ 0.62, -34, 0, 0 },
					{ 0.7, 8, 0, 0 },
					{ 1, 8, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			LegFL_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, 50, 0, -15 },
					{ 0.62, -20, 0, 5 },
					{ 1.4, 0, 0, 0 },
				},
			},
			LegFL_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, -50, 0, 0 },
					{ 0.62, 10, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Tail2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 0, 15, 0 },
					{ 0.7, 0, -20, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Tail4 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, 22, 0 },
					{ 0.75, 0, -28, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 0, -10, -30 },
					{ 0.7, 0, 0, 10 },
					{ 1.4, 0, 0, 0 },
				},
			},
			WingR_Arm = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 0, 10, 30 },
					{ 0.7, 0, 0, -10 },
					{ 1.4, 0, 0, 0 },
				},
			},
		},
	},
	Roar = {
		dur = 3,
		loop = false,
		next = "Idle",
		joints = {
			Hips = {
				p = {
					{ 0, 0, 0, 0 },
					{ 0.6, 0, -0.5, 0 },
					{ 2.4, 0, -0.5, 0 },
					{ 3, 0, 0, 0 },
				},
			},
			Chest = {
				o = {
					{ "x", 1.2, 30, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, -10, 0, 0 },
					{ 2.4, -10, 0, 0 },
					{ 3, 0, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, -8, 0, 0 },
					{ 2.4, -8, 0, 0 },
					{ 3, 0, 0, 0 },
				},
			},
			Neck3 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, 14, 0, 0 },
					{ 2.4, 14, 0, 0 },
					{ 3, 0, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 6, 0, 0 },
					{ 0.7, 6, 0, 28 },
					{ 1.6, 6, 0, 28 },
					{ 1.75, 6, 0, -24 },
					{ 2.4, 6, 0, -24 },
					{ 3, 0, 0, 0 },
				},
				o = {
					{ "y", 2, 21, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.55, -26, 0, 0 },
					{ 2.4, -24, 0, 0 },
					{ 3, 0, 0, 0 },
				},
				o = {
					{ "x", 2.5, 34, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, 0, -18, -45 },
					{ 2.4, 0, -18, -48 },
					{ 3, 0, 0, 0 },
				},
				o = {
					{ "z", 3, 24, 0 },
				},
			},
			WingR_Arm = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, 0, 18, 45 },
					{ 2.4, 0, 18, 48 },
					{ 3, 0, 0, 0 },
				},
				o = {
					{ "z", -3, 24, 0 },
				},
			},
			WingL_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, 0, -10, -20 },
					{ 2.4, 0, -10, -20 },
					{ 3, 0, 0, 0 },
				},
			},
			WingR_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, 0, 10, 20 },
					{ 2.4, 0, 10, 20 },
					{ 3, 0, 0, 0 },
				},
			},
			Tail1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, -10, 0, 0 },
					{ 2.4, -10, 0, 0 },
					{ 3, 0, 0, 0 },
				},
			},
			Tail6 = {
				o = {
					{ "y", 14, 12, 0 },
				},
			},
		},
	},
	Death = {
		dur = 3,
		loop = false,
		joints = {
			Hips = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 8, 0, 0 },
					{ 1.4, -4, 6, -38 },
					{ 3, -6, 8, -48 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, 0.4, 0 },
					{ 1.4, 0, -8, 0 },
					{ 3, 0, -9.4, 0 },
				},
			},
			LegFL_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.4, 30, 0, 20 },
					{ 3, 40, 0, 25 },
				},
			},
			LegFL_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.4, -50, 0, 0 },
					{ 3, -60, 0, 0 },
				},
			},
			LegBL_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.4, 30, 0, 20 },
					{ 3, 40, 0, 25 },
				},
			},
			LegBL_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.4, -50, 0, 0 },
					{ 3, -60, 0, 0 },
				},
			},
			LegFR_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.4, -20, 0, -10 },
					{ 3, -30, 0, -15 },
				},
			},
			LegFR_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.4, 40, 0, 0 },
					{ 3, 50, 0, 0 },
				},
			},
			LegBR_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.4, -20, 0, -10 },
					{ 3, -30, 0, -15 },
				},
			},
			LegBR_Lower = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.4, 40, 0, 0 },
					{ 3, 50, 0, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 20, 0, 0 },
					{ 1.6, -25, 0, -15 },
					{ 3, -30, 0, -20 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.7, -20, 10, 0 },
					{ 3, -25, 12, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 30, 0, 0 },
					{ 1.8, -15, 0, -25 },
					{ 3, -20, 0, -30 },
				},
			},
			Jaw = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, -35, 0, 0 },
					{ 3, -20, 0, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, -15, -40 },
					{ 1.6, 0, 20, 30 },
					{ 3, 0, 30, 45 },
				},
			},
			WingL_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.6, 0, 30, 20 },
					{ 3, 0, 45, 30 },
				},
			},
			WingR_Arm = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, 15, 40 },
					{ 1.6, 0, -20, -10 },
					{ 3, 0, -30, -20 },
				},
			},
			WingR_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.6, 0, -30, -20 },
					{ 3, 0, -45, -30 },
				},
			},
			Tail1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.5, 15, 0, 0 },
					{ 3, 20, 0, 0 },
				},
			},
			Tail3 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 3, 0, 20, 0 },
				},
			},
			Tail5 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 3, 0, 25, 0 },
				},
			},
		},
	},
}
]=======],
	Showcase = [=======[
--[[
	ShadowShowcase (LocalScript) · StarterPlayer.StarterPlayerScripts.ShadowShowcase

	Vitrina local del Dragón Sombrío:
	  · noche cerrada con bloom: en la oscuridad solo se ven dos puntos rojos y la sonrisa de agujas
	    blancas (la malla Teeth pasa a Neon); de día el cuerpo negro se ve entero (tecla L alterna día/noche)
	  · la cabeza sigue tu cámara: te mira fijamente esté donde esté
	  · botones o teclas 1-9 para las nueve animaciones
	Todo ocurre en este cliente: el clon y la iluminación solo existen para quien juega.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Dragons = ReplicatedStorage:WaitForChild("Dragons")
local DragonAnimator = require(Dragons:WaitForChild("DragonAnimator"))
local folder = Dragons:WaitForChild("ShadowDragon")
local animations = require(folder:WaitForChild("Animations"))
local template = folder:WaitForChild("ShadowDragon") :: Model
local showcase = workspace:WaitForChild("DragonShowcase")
local stage = showcase:WaitForChild("Stage_Shadow") :: BasePart
local statue = showcase:FindFirstChild("ShadowDragon_Preview")
if statue then
	statue.Parent = nil -- la estatua solo sirve en modo edición
end

local ORDER = { "Idle", "Walk", "Run", "Fly", "TakeOff", "Landing", "Attack", "Roar", "Death" }
local LABELS = {
	Idle = "Acechar", Walk = "Caminar", Run = "Correr", Fly = "Volar", TakeOff = "Despegar",
	Landing = "Aterrizar", Attack = "Atacar", Roar = "Sonreír", Death = "Morir",
}
local LOOK = { Head = "Head", Neck = "Neck2", NeckShare = 0.4, MaxYaw = 70, MaxPitch = 35, RestPitch = -5, Speed = 4 }
local DOT_DAY, DOT_NIGHT = 0.4, 0

-- Noche: guarda la iluminación original para poder volver al día
local saved = {
	ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient, FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd,
	ExposureCompensation = Lighting.ExposureCompensation, EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
}
local bloom = Instance.new("BloomEffect")
bloom.Name = "ShadowGrinBloom"
bloom.Intensity = 0.9
bloom.Size = 12
bloom.Threshold = 0.95
local night = false
local dragon: Model? = nil
-- la sonrisa: de noche los dientes son Neon (brillan con el bloom); de día, marfil mate
local function setGrin(model)
	local teeth = model and model:FindFirstChild("Teeth", true)
	if teeth and teeth:IsA("BasePart") then
		teeth.Material = night and Enum.Material.Neon or Enum.Material.SmoothPlastic
		teeth.Color = night and Color3.fromRGB(150, 146, 138) or Color3.fromRGB(222, 216, 202)
	end
end
local function eyeParts(model)
	local list = {}
	if model then
		for _, p in ipairs(model:GetChildren()) do
			if p:IsA("BasePart") and p:GetAttribute("Kind") == "eye" then
				table.insert(list, p)
			end
		end
	end
	return list
end
local function setNight(on: boolean)
	night = on
	for _, dot in ipairs(eyeParts(dragon)) do
		dot.Transparency = on and DOT_NIGHT or DOT_DAY
	end
	setGrin(dragon)
	if on then
		Lighting.ClockTime = 0
		Lighting.Brightness = 0
		Lighting.Ambient = Color3.fromRGB(6, 6, 9)
		Lighting.OutdoorAmbient = Color3.fromRGB(10, 10, 14)
		Lighting.FogColor = Color3.fromRGB(2, 2, 4)
		Lighting.FogEnd = 150
		Lighting.ExposureCompensation = -0.6
		Lighting.EnvironmentDiffuseScale = 0
		Lighting.EnvironmentSpecularScale = 0
		bloom.Parent = Lighting
	else
		for k, v in pairs(saved) do
			Lighting[k] = v
		end
		bloom.Parent = nil
	end
end

local animator = nil
local busy = false
local dotConn = nil

-- los puntos de los ojos siguen al hueso de la cabeza (no son geometría del modelo)
local function followEyes(model)
	if dotConn then
		dotConn:Disconnect()
	end
	local pairsList = {}
	for _, p in ipairs(model:GetChildren()) do   -- los ojos siguen a su hueso
		if p:IsA("BasePart") and p:GetAttribute("Offset") then
			local bone = model:FindFirstChild(p:GetAttribute("Bone"), true)
			if bone then
				table.insert(pairsList, { p, bone, p:GetAttribute("Offset") })
			end
		end
	end
	for _, dot in ipairs(eyeParts(model)) do
		dot.Transparency = night and DOT_NIGHT or DOT_DAY
	end
	setGrin(model)
	dotConn = RunService.RenderStepped:Connect(function()
		for _, e in ipairs(pairsList) do
			e[1].CFrame = e[2].TransformedWorldCFrame * e[3]
		end
	end)
end

local function spawnDragon()
	if animator then
		animator:Destroy()
	end
	if dragon then
		dragon:Destroy()
	end
	dragon = template:Clone()
	dragon:PivotTo(stage.CFrame * CFrame.new(0, stage.Size.Y / 2, 0) * CFrame.Angles(0, math.rad(180), 0))
	dragon.Parent = showcase
	animator = DragonAnimator.new(dragon, animations)
	animator:Play("Idle", 0)
	followEyes(dragon)
	animator:SetLookTarget(function()
		return workspace.CurrentCamera.CFrame.Position
	end, LOOK)
	animator.Finished.Event:Connect(function(name)
		if name ~= "Death" then
			return
		end
		busy = true
		animator:SetLookTarget(nil)
		-- el cuerpo se disuelve en la oscuridad; los ojos y la sonrisa aguantan un momento más
		local eyes = eyeParts(dragon)
		local teeth = dragon:FindFirstChild("Teeth", true)
		if teeth then
			table.insert(eyes, teeth)
		end
		for _, p in ipairs(dragon:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "Root" and not table.find(eyes, p) then
				TweenService:Create(p, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
			end
		end
		task.delay(1.9, function()
			for _, e in ipairs(eyes) do
				TweenService:Create(e, TweenInfo.new(0.9), { Transparency = 1 }):Play()
			end
		end)
		task.delay(3.4, function()
			spawnDragon()
			busy = false
		end)
	end)
end

local function play(name: string)
	if busy or not animator then
		return
	end
	local cur = animator.Current
	local airborne = cur == "Fly" or cur == "TakeOff"
	if name == "Fly" and not airborne then
		name = "TakeOff"
	elseif airborne and (name == "Idle" or name == "Walk" or name == "Run" or name == "Attack" or name == "Roar") then
		name = "Landing"
	end
	animator:Play(name, 0.25)
end

-- Interfaz
local gui = Instance.new("ScreenGui")
gui.Name = "ShadowShowcaseGui"
gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -16)
bar.Size = UDim2.new(0, 0, 0, 44)
bar.AutomaticSize = Enum.AutomaticSize.X
bar.BackgroundColor3 = Color3.fromRGB(10, 8, 9)
bar.BackgroundTransparency = 0.2
bar.Parent = gui
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 6)
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Parent = bar
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 8)
pad.PaddingRight = UDim.new(0, 8)
pad.Parent = bar

local function button(text: string, onClick)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 96, 0, 32)
	b.BackgroundColor3 = Color3.fromRGB(16, 14, 18)
	b.TextColor3 = Color3.fromRGB(232, 226, 216)
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 14
	b.Text = text
	b.Parent = bar
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(150, 30, 36)
	stroke.Transparency = 0.4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	b.Activated:Connect(onClick)
	return b
end
for i, name in ipairs(ORDER) do
	button(string.format("%d · %s", i, LABELS[name]), function()
		play(name)
	end)
end
local nightButton
nightButton = button("L · Día", function()
	setNight(not night)
	nightButton.Text = night and "L · Día" or "L · Noche"
end)

local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine }
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.L then
		setNight(not night)
		nightButton.Text = night and "L · Día" or "L · Noche"
		return
	end
	for i, key in ipairs(KEYS) do
		if input.KeyCode == key then
			play(ORDER[i])
		end
	end
end)

setNight(true)
spawnDragon()
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
local function looksLikeDragon(inst)
	return inst:FindFirstChild("Body", true) and inst:FindFirstChild("Neck3", true)
end
local source
for _, s in ipairs(Selection:Get()) do
	local cand = s:IsA("BasePart") and s.Parent or s
	if looksLikeDragon(cand) then
		source = cand
		break
	end
end
if not source then
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and looksLikeDragon(d) and not d:GetAttribute("RigScale") then
			source = d
			break
		end
	end
end
assert(source, "[Shadow] No encontré el modelo importado. Impórtalo con Import 3D (Rig Type: Custom) y selecciónalo.")

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
for _, name in ipairs({ "Body", "Teeth", "WingL", "WingR" }) do
	local m = source:FindFirstChild(name, true)
	if m and m:IsA("MeshPart") then
		meshes[name] = m
	else
		table.insert(missing, name)
	end
end
assert(#missing == 0, "[Shadow] Faltan piezas o huesos: " .. table.concat(missing, ", ") .. ". ¿Rig Type estaba en Custom?")

pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar Dragón Sombrío")
end)

-- 2. Calibración: escala y orientación con que el importador dejó el esqueleto
local function ratio(a, b)
	return (bones[a].WorldPosition - bones[b].WorldPosition).Magnitude / (v3(byName[a].head) - v3(byName[b].head)).Magnitude
end
local scale = (ratio("Hips", "Head") + ratio("Hips", "Tail7") + ratio("WingL_Hand", "WingR_Hand")) / 3
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
print(("[Shadow] escala del import: %.4f · error máximo de huesos: %.3f studs"):format(scale, bestErr))
if bestErr > 0.6 * scale then
	warn("[Shadow] Los huesos no coinciden con el rig esperado. Revisa la importación. Continúo igualmente.")
end
local function W(t)
	return origin + R:VectorToWorldSpace(v3(t) * scale)
end

-- 3. Modelo: una sola asamblea (Body anclado, alas soldadas) para que los huesos deformen todas las mallas
local model = Instance.new("Model")
model.Name = "ShadowDragon"
for _, child in ipairs(source:GetChildren()) do
	child.Parent = model
end
for name, m in pairs(meshes) do
	m.Parent = model
	m.CanCollide = false
	m.CanTouch = false
	m.CastShadow = true
	m.Anchored = name == "Body"
	m.Massless = name ~= "Body"
	if name ~= "Body" then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = meshes.Body
		weld.Part1 = m
		weld.Parent = m
	end
	if name == "Teeth" then
		m.Material = Enum.Material.SmoothPlastic
		m.Color = Color3.fromRGB(222, 216, 202)
		m.CastShadow = false
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
model.WorldPivot = CFrame.new(W({ byName.Hips.head[1], GROUND_Y, byName.Hips.head[3] })) * R

-- Ojos: NO son globos oculares. Dos puntos rojos de Neon, pequeños y separados, que la vitrina mueve
-- con el hueso Head; de noche solo se ven ellos y la sonrisa.
local head = bones[EYES.bone]
for _, name in ipairs({ "EyeL", "EyeR" }) do
	local dot = Instance.new("Part")
	dot.Name = name .. "Point"
	dot.Shape = Enum.PartType.Ball
	dot.Size = Vector3.one * 0.11 * scale
	dot.Material = Enum.Material.Neon
	dot.Color = Color3.fromRGB(255, 20, 12)
	dot.Transparency = 0.4
	dot.Anchored = true
	dot.CanCollide = false
	dot.CanQuery = false
	dot.CanTouch = false
	dot.CastShadow = false
	dot.CFrame = CFrame.new(W(EYES[name]))
	dot:SetAttribute("Bone", EYES.bone)
	dot:SetAttribute("Kind", "eye")
	dot:SetAttribute("Offset", head.WorldCFrame:ToObjectSpace(dot.CFrame))
	dot.Parent = model
end

if math.abs(DESIRED_SCALE / scale - 1) > 1e-3 then
	model:ScaleTo(DESIRED_SCALE / scale)
	for _, p in ipairs(model:GetChildren()) do
		if p:GetAttribute("Offset") then
			local off = p:GetAttribute("Offset")
			p:SetAttribute("Offset", off.Rotation + off.Position * (DESIRED_SCALE / scale))
		end
	end
end
model:SetAttribute("RigScale", DESIRED_SCALE)
model:SetAttribute("Species", "Umbrafex ridens")

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

local dragons = ensure(ReplicatedStorage, "Dragons")
for _, n in ipairs({ "AbyssalDragon", "ShadowDragon", "AberrantDragon", "AerialDragon", "AncientDragon", "ShadowDragon" }) do
	ensure(dragons, n)
end
local folder = dragons.ShadowDragon
local prev = folder:FindFirstChild("ShadowDragon")
if prev then
	prev:Destroy()
end
model.Parent = folder
local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({
	DisplayName = "Dragón Sombrío", Species = "Umbrafex ridens", Epithet = "La Sonrisa en la Oscuridad",
	WalkSpeed = 8, RunSpeed = 34, FlySpeed = 36, FlyHeight = 7, MaxHealth = 2200, AttackDamage = 70,
	AttackRange = 16, EyePointColor = Color3.fromRGB(255, 20, 12), GrinGlows = true,
}) do
	settings:SetAttribute(k, v)
end
putScript(dragons, "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "ShadowShowcase", "LocalScript", SOURCES.Showcase)

local assets = ensure(ServerStorage, "DragonAssets")
local bak = assets:FindFirstChild("ShadowDragon_Rig")
if bak then
	bak:Destroy()
end
local backup = model:Clone()
backup.Name = "ShadowDragon_Rig"
backup.Parent = assets

local showcase = ensure(workspace, "DragonShowcase")
local stage = showcase:FindFirstChild("Stage_Shadow")
if not stage then
	stage = Instance.new("Part")
	stage.Name = "Stage_Shadow"
	stage.Anchored = true
	stage.Size = Vector3.new(100, 1, 100)
	stage.CFrame = CFrame.new(0, 0.5, -300)
	stage.Material = Enum.Material.Slate
	stage.Color = Color3.fromRGB(22, 21, 24)
	stage.Parent = showcase
end
local statue = showcase:FindFirstChild("ShadowDragon_Preview")
if statue then
	statue:Destroy()
end
statue = model:Clone()
statue.Name = "ShadowDragon_Preview"
statue:PivotTo(stage.CFrame * CFrame.new(0, stage.Size.Y / 2, 0) * CFrame.Angles(0, math.rad(180), 0))
statue.Parent = showcase

if source.Parent and #source:GetChildren() == 0 then
	source:Destroy()
end
Selection:Set({ statue })
pcall(function()
	ChangeHistoryService:SetWaypoint("Dragón Sombrío instalado")
end)
print("[Shadow] Listo: " .. #RIG .. " huesos, 4 mallas. Pulsa Play: noche cerrada, solo dos puntos rojos y una sonrisa de agujas te observan. Botones 1-9 y L para la luz.")
