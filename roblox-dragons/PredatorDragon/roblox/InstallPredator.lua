--[[
	INSTALADOR DEL DRAGÓN DEPREDADOR · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	Pasos:
	  1. Studio > pestaña Avatar (o Home) > Import 3D > PredatorDragon.fbx (o .glb).
	     En el importador: deja "Rig General > Rig Type" en "No Rig" y NO combines mallas.
	     Pulsa Import. Aparece el modelo en Workspace.
	  2. Selecciona ese modelo en el Explorer.
	  3. View > Command Bar. Pega TODO este archivo y pulsa Enter.

	Resultado:
	  ReplicatedStorage.Dragons.PredatorDragon          (rig con Motor6D, Settings, Animations)
	  ReplicatedStorage.Dragons.DragonAnimator          (motor de animación por datos)
	  ServerStorage.DragonAssets.PredatorDragon_Rig     (copia de seguridad del rig)
	  Workspace.DragonShowcase                          (escenario + estatua de vista previa)
	  StarterPlayer.StarterPlayerScripts.PredatorShowcase (vitrina nocturna, botones 1-9)
	Pulsa Play para ver al dragón y probar sus animaciones.
]]

-- Opcional: escala final en studs por unidad del modelo (1 = 40 studs de largo).
local DESIRED_SCALE = 1
-- Opcional: tras subir los PNG del atlas (Asset Manager), pega aquí sus ids "rbxassetid://..."
-- para crear SurfaceAppearance PBR en cada pieza.
local MAPS = { ColorMap = "", NormalMap = "", RoughnessMap = "" }

local RIG = {
	{ name = "Neck2", parent = "Neck1", pivot = { 0, 6.403, -7.4107 }, center = { 0.0321, 7.0427, -8.1573 } },
	{ name = "Neck1", parent = "Chest", pivot = { 0, 5.9995, -4.2234 }, center = { 0, 6.5758, -5.5955 } },
	{ name = "Chest", parent = "Hips", pivot = { 0, 5.8065, 0.7513 }, center = { -0.0079, 6.5252, -1.5736 } },
	{ name = "Hips", parent = nil, pivot = { 0.0144, 5.659, 1.7965 }, center = { 0, 6.1231, 1.84 } },
	{ name = "Tail1", parent = "Hips", pivot = { -0.0028, 5.4915, 2.8516 }, center = { -0.0347, 5.6035, 4.3773 } },
	{ name = "Tail2", parent = "Tail1", pivot = { -0.3068, 4.9907, 5.6493 }, center = { -0.4513, 4.9621, 7.1465 } },
	{ name = "Tail3", parent = "Tail2", pivot = { -0.8041, 4.3919, 8.6418 }, center = { -0.8587, 4.3464, 10.2126 } },
	{ name = "Tail4", parent = "Tail3", pivot = { -0.898, 3.795, 11.832 }, center = { -0.726, 3.8895, 13.4341 } },
	{ name = "Tail5", parent = "Tail4", pivot = { -0.3956, 3.398, 15.0214 }, center = { -0.1077, 3.5036, 16.5834 } },
	{ name = "Tail6", parent = "Tail5", pivot = { 0.402, 3.1998, 18.2106 }, center = { 0.8996, 3.3136, 21.1256 } },
	{ name = "Head", parent = "Neck2", pivot = { 0, 6.6, -10.4 }, center = { 0, 6.6551, -11.4439 } },
	{ name = "EyeL", parent = "Head", pivot = { -0.82, 6.7518, -12.2759 }, center = { -0.82, 6.7518, -12.2759 } },
	{ name = "EyeR", parent = "Head", pivot = { 0.82, 6.7518, -12.2759 }, center = { 0.82, 6.7518, -12.2759 } },
	{ name = "Jaw", parent = "Head", pivot = { 0, 5.9857, -10.1844 }, center = { 0, 4.1114, -11.5196 } },
	{ name = "Tongue", parent = "Jaw", pivot = { 0, 5.2066, -10.4775 }, center = { 0, 3.2353, -11.3079 } },
	{ name = "LegFL_Upper", parent = "Chest", pivot = { -1.4, 5.7, -3.4 }, center = { -1.7786, 4.822, -3.795 } },
	{ name = "LegFL_Lower", parent = "LegFL_Upper", pivot = { -2.3, 3.7, -4.3 }, center = { -2.3208, 2.7811, -4.1319 } },
	{ name = "LegFL_Foot", parent = "LegFL_Lower", pivot = { -2.2, 1.4, -3.8 }, center = { -2.4825, 0.7881, -4.61 } },
	{ name = "LegFR_Upper", parent = "Chest", pivot = { 1.4, 5.7, -3.4 }, center = { 1.7786, 4.822, -3.795 } },
	{ name = "LegFR_Lower", parent = "LegFR_Upper", pivot = { 2.3, 3.7, -4.3 }, center = { 2.3208, 2.7809, -4.1319 } },
	{ name = "LegFR_Foot", parent = "LegFR_Lower", pivot = { 2.2, 1.4, -3.8 }, center = { 2.4825, 0.7904, -4.61 } },
	{ name = "LegBL_Upper", parent = "Hips", pivot = { -1.45, 5.4, 1.5 }, center = { -1.8633, 4.7158, 0.5351 } },
	{ name = "LegBL_Lower", parent = "LegBL_Upper", pivot = { -2.5, 3.7, -0.4 }, center = { -2.5384, 3.0636, 0.5374 } },
	{ name = "LegBL_Foot", parent = "LegBL_Lower", pivot = { -2.6, 1.8, 1.8 }, center = { -2.8325, 0.9803, 0.9745 } },
	{ name = "LegBR_Upper", parent = "Hips", pivot = { 1.45, 5.4, 1.5 }, center = { 1.8633, 4.7158, 0.5351 } },
	{ name = "LegBR_Lower", parent = "LegBR_Upper", pivot = { 2.5, 3.7, -0.4 }, center = { 2.5384, 3.0636, 0.5374 } },
	{ name = "LegBR_Foot", parent = "LegBR_Lower", pivot = { 2.6, 1.8, 1.8 }, center = { 2.8325, 0.9803, 0.9745 } },
	{ name = "WingL_Arm", parent = "Chest", pivot = { -1.1, 7.1, -2.8 }, center = { -5.2242, 9.046, 3.6482 } },
	{ name = "WingL_Hand", parent = "WingL_Arm", pivot = { -9.6, 12.4, 1.8 }, center = { -11.743, 9.162, 6.5906 } },
	{ name = "WingR_Arm", parent = "Chest", pivot = { 1.1, 7.1, -2.8 }, center = { 5.2242, 9.046, 3.6482 } },
	{ name = "WingR_Hand", parent = "WingR_Arm", pivot = { 9.6, 12.4, 1.8 }, center = { 11.743, 9.162, 6.5906 } },
}
local GROUND_Y = -0.3463
local SOURCES = {
	DragonAnimator = [=======[
--[[
	DragonAnimator (ModuleScript) · ReplicatedStorage.Dragons.DragonAnimator

	Reproduce animaciones definidas como datos (ver AberrantAnimations) sobre un rig
	de Motor6D. No necesita subir assets de animación: escribe Motor6D.Transform cada frame.

	Uso:
		local animator = DragonAnimator.new(model, require(animsModule))
		animator:Play("Idle")
		animator.Finished.Event:Connect(function(name) ... end)
		animator:SetLookTarget(player.Character.Head)   -- opcional: la cabeza sigue al objetivo
		animator:Destroy()

	Formato de cada articulación (nombre = Part1 del Motor6D):
		k = { {t, rx, ry, rz}, ... }   claves de rotación en grados
		p = { {t, x, y, z}, ... }      claves de traslación en studs del modelo original (se multiplican por RigScale)
		o = { {"eje", amplitud, ciclos, fase}, ... }   ejes "x","y","z" (grados) o "px","py","pz" (studs)
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
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") and d.Part1 then
			self.Joints[d.Part1.Name] = d
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
	for jointName, motor in pairs(self.Joints) do
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
		motor.Transform = CFrame.new(v[4] * s, v[5] * s, v[6] * s)
			* CFrame.Angles(math.rad(v[1]), math.rad(v[2]), math.rad(v[3]))
	end
	self:_applyLook(dt)
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

function DragonAnimator:_applyLook(dt: number)
	if self.LookYaw == nil then
		return
	end
	local o = self.LookOptions or {}
	local head = self.Joints[o.Head or "Head"]
	local neck = self.Joints[o.Neck or "Neck2"]
	if not head or not neck or not neck.Part0 then
		return
	end
	local goalYaw, goalPitch = 0, 0
	local pos = resolveTarget(self.LookTarget)
	if pos then
		-- marco del cuello sin la mirada aplicada, con origen en el pivote de la cabeza
		local base = neck.Part0.CFrame * neck.C0
		local headPivot = (head.Part0.CFrame * head.C0).Position
		local p = base:VectorToObjectSpace(pos - headPivot)
		local maxYaw, maxPitch = math.rad(o.MaxYaw or 75), math.rad(o.MaxPitch or 35)
		goalYaw = math.clamp(math.atan2(-p.X, -p.Z), -maxYaw, maxYaw)
		goalPitch = math.clamp(math.atan2(p.Y, math.sqrt(p.X * p.X + p.Z * p.Z)) - math.rad(o.RestPitch or 0), -maxPitch, maxPitch)
	end
	local k = math.min(1, dt * (o.Speed or 5))
	self.LookYaw += (goalYaw - self.LookYaw) * k
	self.LookPitch += (goalPitch - self.LookPitch) * k
	local share = o.NeckShare or 0.35
	neck.Transform = CFrame.Angles(0, self.LookYaw * share, 0) * CFrame.Angles(self.LookPitch * share, 0, 0) * neck.Transform
	head.Transform = CFrame.Angles(0, self.LookYaw * (1 - share), 0) * CFrame.Angles(self.LookPitch * (1 - share), 0, 0) * head.Transform
end

function DragonAnimator:Destroy()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
	for _, motor in pairs(self.Joints) do
		motor.Transform = CFrame.identity
	end
	self.Finished:Destroy()
end

return DragonAnimator
]=======],
	Animations = [=======[
--[[
	Animaciones del Dragón Depredador (ModuleScript) · ReplicatedStorage.Dragons.PredatorDragon.Animations
	Generado desde src/predator_anims.js con tools/build_roblox.js: edita la fuente y regenera.
	Formato: ver DragonAnimator. Ángulos en grados, traslaciones en studs, tiempos en segundos.
]]
return {
	Idle = {
		dur = 4,
		loop = true,
		joints = {
			Tail1 = {
				o = {
					{ "y", 2.2, 1, 0.07 },
				},
			},
			Tail2 = {
				o = {
					{ "y", 2.9, 1, 0.14 },
				},
			},
			Tail3 = {
				o = {
					{ "y", 3.6, 1, 0.21 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 4.3, 1, 0.28 },
				},
			},
			Tail5 = {
				o = {
					{ "y", 5, 1, 0.35 },
				},
			},
			Tail6 = {
				o = {
					{ "y", 5.7, 1, 0.42 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.06, 2, 0 },
				},
			},
			Chest = {
				o = {
					{ "x", 1.5, 2, 0.1 },
				},
			},
			Neck1 = {
				o = {
					{ "x", 2, 1, 0 },
				},
			},
			Neck2 = {
				o = {
					{ "x", 2, 1, 0.1 },
				},
			},
			Head = {
				o = {
					{ "x", 2.5, 1, 0.2 },
				},
			},
			Jaw = {
				o = {
					{ "x", 3, 1, 0.3 },
				},
			},
			Tongue = {
				o = {
					{ "x", 6, 1, 0.1 },
					{ "z", 4, 2, 0.3 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 6, 4 },
				},
				o = {
					{ "z", 2.5, 1, 0 },
				},
			},
			WingR_Arm = {
				k = {
					{ 0, 0, -6, -4 },
				},
				o = {
					{ "z", -2.5, 1, 0 },
				},
			},
			WingL_Hand = {
				o = {
					{ "y", 3, 1, 0.2 },
				},
			},
			WingR_Hand = {
				o = {
					{ "y", -3, 1, 0.2 },
				},
			},
		},
	},
	Walk = {
		dur = 2,
		loop = true,
		joints = {
			Tail1 = {
				o = {
					{ "y", 3.96, 1, 0.17 },
				},
			},
			Tail2 = {
				o = {
					{ "y", 5.22, 1, 0.24 },
				},
			},
			Tail3 = {
				o = {
					{ "y", 6.48, 1, 0.31 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 7.74, 1, 0.38 },
				},
			},
			Tail5 = {
				o = {
					{ "y", 9, 1, 0.45 },
				},
			},
			Tail6 = {
				o = {
					{ "y", 10.26, 1, 0.52 },
				},
			},
			LegFL_Upper = {
				o = {
					{ "x", 20, 1, 0 },
				},
			},
			LegFL_Lower = {
				o = {
					{ "x", 16, 1, 0.2 },
				},
			},
			LegFL_Foot = {
				o = {
					{ "x", 14, 1, 0.35 },
				},
			},
			LegFR_Upper = {
				o = {
					{ "x", 20, 1, 0.5 },
				},
			},
			LegFR_Lower = {
				o = {
					{ "x", 16, 1, 0.7 },
				},
			},
			LegFR_Foot = {
				o = {
					{ "x", 14, 1, 0.85 },
				},
			},
			LegBL_Upper = {
				o = {
					{ "x", 20, 1, 0.5 },
				},
			},
			LegBL_Lower = {
				o = {
					{ "x", 16, 1, 0.7 },
				},
			},
			LegBL_Foot = {
				o = {
					{ "x", 14, 1, 0.85 },
				},
			},
			LegBR_Upper = {
				o = {
					{ "x", 20, 1, 0 },
				},
			},
			LegBR_Lower = {
				o = {
					{ "x", 16, 1, 0.2 },
				},
			},
			LegBR_Foot = {
				o = {
					{ "x", 14, 1, 0.35 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.15, 2, 0 },
					{ "z", 3, 1, 0.1 },
					{ "y", 3, 1, 0.3 },
				},
			},
			Chest = {
				o = {
					{ "z", -3, 1, 0.2 },
				},
			},
			Neck1 = {
				o = {
					{ "x", 3, 2, 0.1 },
				},
			},
			Head = {
				o = {
					{ "z", 4, 1, 0.5 },
				},
			},
			Tongue = {
				o = {
					{ "x", 12, 2, 0.2 },
				},
			},
			WingL_Hand = {
				k = {
					{ 0, 0, 15, 0 },
				},
			},
			WingR_Hand = {
				k = {
					{ 0, 0, -15, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 25, 12 },
				},
			},
			WingR_Arm = {
				k = {
					{ 0, 0, -25, -12 },
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
					{ "y", 5.28, 1, 0.17 },
					{ "x", 2.64, 2, 0.07 },
				},
			},
			Tail2 = {
				o = {
					{ "y", 6.96, 1, 0.24 },
					{ "x", 3.48, 2, 0.14 },
				},
			},
			Tail3 = {
				o = {
					{ "y", 8.64, 1, 0.31 },
					{ "x", 4.32, 2, 0.21 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 10.32, 1, 0.38 },
					{ "x", 5.16, 2, 0.28 },
				},
			},
			Tail5 = {
				o = {
					{ "y", 12, 1, 0.45 },
					{ "x", 6, 2, 0.35 },
				},
			},
			Tail6 = {
				o = {
					{ "y", 13.68, 1, 0.52 },
					{ "x", 6.84, 2, 0.42 },
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
			Tongue = {
				o = {
					{ "x", 18, 2, 0.2 },
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
					{ "x", 2.64, 1, 0.37 },
					{ "y", 2.64, 1, 0.07 },
				},
			},
			Tail2 = {
				o = {
					{ "x", 3.48, 1, 0.44 },
					{ "y", 3.48, 1, 0.14 },
				},
			},
			Tail3 = {
				o = {
					{ "x", 4.32, 1, 0.51 },
					{ "y", 4.32, 1, 0.21 },
				},
			},
			Tail4 = {
				o = {
					{ "x", 5.16, 1, 0.58 },
					{ "y", 5.16, 1, 0.28 },
				},
			},
			Tail5 = {
				o = {
					{ "x", 6, 1, 0.65 },
					{ "y", 6, 1, 0.35 },
				},
			},
			Tail6 = {
				o = {
					{ "x", 6.84, 1, 0.72 },
					{ "y", 6.84, 1, 0.42 },
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
			Tongue = {
				k = {
					{ 0, -20, 0, 0 },
				},
				o = {
					{ "x", 10, 2, 0 },
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
			Tongue = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, 25, 0, 0 },
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
		dur = 2.6,
		loop = false,
		next = "Idle",
		joints = {
			Hips = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 8, 0, 0 },
					{ 2.1, 8, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, 0.3, 0.3 },
					{ 2.1, 0, 0.3, 0.3 },
					{ 2.6, 0, 0, 0 },
				},
			},
			Chest = {
				o = {
					{ "x", 1.5, 26, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 25, 0, 0 },
					{ 2.1, 25, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 15, 0, 0 },
					{ 2.1, 15, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.55, 30, 0, 0 },
					{ 2.1, 28, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
				o = {
					{ "z", 3, 26, 0 },
					{ "y", 3, 19, 0.2 },
				},
			},
			Jaw = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.55, -38, 0, 0 },
					{ 2.1, -36, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
				o = {
					{ "x", 3, 30, 0 },
				},
			},
			Tongue = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.55, -20, 0, 0 },
					{ 2.1, -20, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
				o = {
					{ "z", 8, 20, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, -15, -40 },
					{ 2.1, 0, -15, -42 },
					{ 2.6, 0, 0, 0 },
				},
				o = {
					{ "z", 3, 24, 0 },
				},
			},
			WingR_Arm = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, 15, 40 },
					{ 2.1, 0, 15, 42 },
					{ 2.6, 0, 0, 0 },
				},
				o = {
					{ "z", -3, 24, 0 },
				},
			},
			WingL_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, -10, -15 },
					{ 2.1, 0, -10, -15 },
					{ 2.6, 0, 0, 0 },
				},
			},
			WingR_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, 10, 15 },
					{ 2.1, 0, 10, 15 },
					{ 2.6, 0, 0, 0 },
				},
			},
			LegFL_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, -10, 0, 0 },
					{ 2.1, -10, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
			},
			LegFR_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, -10, 0, 0 },
					{ 2.1, -10, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
			},
			Tail1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, -12, 0, 0 },
					{ 2.1, -12, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
			},
			Tail6 = {
				o = {
					{ "y", 12, 12, 0 },
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
					{ 1.4, 0, -3.6, 0 },
					{ 3, 0, -3.9, 0 },
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
			Tongue = {
				k = {
					{ 0, 0, 0, 0 },
					{ 3, 20, 0, 30 },
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
	PredatorShowcase (LocalScript) · StarterPlayer.StarterPlayerScripts.PredatorShowcase

	Vitrina local del Dragón Depredador:
	  · noche cerrada con bloom: en la oscuridad solo se ven sus dos ojos blancos (tecla L alterna día/noche)
	  · la cabeza sigue tu cámara: te mira fijamente esté donde esté
	  · botones o teclas 1-9 para las nueve animaciones
	Todo ocurre en este cliente: el clon y la iluminación solo existen para quien juega.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local Dragons = ReplicatedStorage:WaitForChild("Dragons")
local DragonAnimator = require(Dragons:WaitForChild("DragonAnimator"))
local folder = Dragons:WaitForChild("PredatorDragon")
local animations = require(folder:WaitForChild("Animations"))
local template = folder:WaitForChild("PredatorDragon") :: Model
local showcase = workspace:WaitForChild("DragonShowcase")
local stage = showcase:WaitForChild("Stage_Predator") :: BasePart
local statue = showcase:FindFirstChild("PredatorDragon_Preview")
if statue then
	statue.Parent = nil -- la estatua solo sirve en modo edición
end

local ORDER = { "Idle", "Walk", "Run", "Fly", "TakeOff", "Landing", "Attack", "Roar", "Death" }
local LABELS = {
	Idle = "Acechar", Walk = "Caminar", Run = "Correr", Fly = "Volar", TakeOff = "Despegar",
	Landing = "Aterrizar", Attack = "Atacar", Roar = "Rugir", Death = "Morir",
}
local LOOK = { Head = "Head", Neck = "Neck2", NeckShare = 0.35, MaxYaw = 80, MaxPitch = 35, RestPitch = -18, Speed = 4 }

-- Noche: guarda la iluminación original para poder volver al día
local saved = {
	ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient, FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd,
	ExposureCompensation = Lighting.ExposureCompensation, EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
}
local bloom = Instance.new("BloomEffect")
bloom.Name = "PredatorGazeBloom"
bloom.Intensity = 1.2
bloom.Size = 28
bloom.Threshold = 0.85
local night = false
local function setNight(on: boolean)
	night = on
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

local dragon: Model? = nil
local animator = nil
local busy = false

local function eyeParts(model)
	local list = {}
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and string.sub(p.Name, 1, 3) == "Eye" then
			table.insert(list, p)
		end
	end
	return list
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
	animator:SetLookTarget(function()
		return workspace.CurrentCamera.CFrame.Position
	end, LOOK)
	animator.Finished.Event:Connect(function(name)
		if name ~= "Death" then
			return
		end
		busy = true
		animator:SetLookTarget(nil)
		-- el cuerpo se disuelve en la oscuridad; los ojos aguantan un momento más
		local eyes = eyeParts(dragon)
		for _, p in ipairs(dragon:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "Root" and not table.find(eyes, p) then
				TweenService:Create(p, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
			end
		end
		task.delay(1.9, function()
			for _, e in ipairs(eyes) do
				TweenService:Create(e, TweenInfo.new(0.9), { Transparency = 1 }):Play()
				local light = e:FindFirstChildOfClass("PointLight")
				if light then
					TweenService:Create(light, TweenInfo.new(0.9), { Brightness = 0 }):Play()
				end
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
gui.Name = "PredatorShowcaseGui"
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
	b.BackgroundColor3 = Color3.fromRGB(32, 18, 20)
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
for _, e in ipairs(RIG) do
	byName[e.name] = e
end

-- 1. Localizar el modelo importado
local function findParts(container)
	local found, missing = {}, {}
	for _, e in ipairs(RIG) do
		local p = container.Name == e.name and container:IsA("BasePart") and container or container:FindFirstChild(e.name, true)
		if p and p:IsA("BasePart") then
			found[e.name] = p
		else
			table.insert(missing, e.name)
		end
	end
	return found, missing
end

local source
for _, s in ipairs(Selection:Get()) do
	local cand = s:IsA("BasePart") and s.Parent or s
	if cand:FindFirstChild("WingL_Hand", true) then
		source = cand
		break
	end
end
if not source then
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and d:FindFirstChild("WingL_Hand", true) and d:FindFirstChild("Hips", true) and not d:FindFirstChildWhichIsA("Motor6D", true) then
			source = d
			break
		end
	end
end
assert(source, "[Predator] No encontré el modelo importado. Impórtalo con Import 3D y selecciónalo antes de ejecutar.")
local parts, missing = findParts(source)
assert(#missing == 0, "[Predator] Faltan piezas en el modelo importado: " .. table.concat(missing, ", ") .. ". ¿Se combinaron las mallas al importar?")

pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar Dragón Depredador")
end)

-- 2. Calibración: escala y orientación con que el importador dejó el modelo
local function ratio(a, b)
	return (parts[a].Position - parts[b].Position).Magnitude / (v3(byName[a].center) - v3(byName[b].center)).Magnitude
end
local scale = (ratio("Head", "Tail6") + ratio("LegFL_Foot", "WingR_Hand") + ratio("LegBR_Foot", "WingL_Hand")) / 3
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
	local o = parts.Hips.Position - rot:VectorToWorldSpace(v3(byName.Hips.center) * scale)
	local err = 0
	for _, e in ipairs(RIG) do
		err = math.max(err, (o + rot:VectorToWorldSpace(v3(e.center) * scale) - parts[e.name].Position).Magnitude)
	end
	if not bestErr or err < bestErr then
		R, origin, bestErr = rot, o, err
	end
end
print(("[Predator] escala del import: %.4f · error máximo de posición: %.3f studs"):format(scale, bestErr))
if bestErr > 0.6 * scale then
	warn("[Predator] Las piezas no coinciden con el rig esperado. ¿Se movió o se rotó alguna pieza después de importar? Continúo igualmente.")
end
local function W(t)
	return origin + R:VectorToWorldSpace(v3(t) * scale)
end

-- 3. Construir el rig: Root anclado + Motor6D en cada articulación
local model = Instance.new("Model")
model.Name = "PredatorDragon"
local hips = byName.Hips
local root = Instance.new("Part")
root.Name = "Root"
root.Size = Vector3.new(2, 1, 2) * scale
root.Transparency = 1
root.Anchored = true
root.CanCollide = false
root.CanQuery = false
root.CanTouch = false
root.CFrame = CFrame.new(W({ hips.pivot[1], GROUND_Y, hips.pivot[3] })) * R
root.Parent = model
model.PrimaryPart = root

for _, e in ipairs(RIG) do
	local p = parts[e.name]
	p.Parent = model
end
for _, e in ipairs(RIG) do
	local p = parts[e.name]
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = true
	local p0 = e.parent and parts[e.parent] or root
	local pivot = CFrame.new(W(e.pivot)) * R
	local m = Instance.new("Motor6D")
	m.Name = e.name
	m.Part0 = p0
	m.Part1 = p
	m.C0 = p0.CFrame:ToObjectSpace(pivot)
	m.C1 = p.CFrame:ToObjectSpace(pivot)
	m.Parent = p
	if string.sub(e.name, 1, 3) == "Eye" then
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(245, 248, 255)
		pcall(function()
			p.TextureID = ""
		end)
		p.CastShadow = false
	elseif MAPS.ColorMap ~= "" then
		local sa = p:FindFirstChildOfClass("SurfaceAppearance") or Instance.new("SurfaceAppearance")
		sa.ColorMap = MAPS.ColorMap
		sa.NormalMap = MAPS.NormalMap
		sa.RoughnessMap = MAPS.RoughnessMap
		sa.Parent = p
	end
end
for _, eyeName in ipairs({ "EyeL", "EyeR" }) do
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(235, 240, 255)
	glow.Range = 3 * scale
	glow.Brightness = 0.8
	glow.Shadows = false
	glow.Parent = parts[eyeName]
end

-- Escala final deseada (Model:ScaleTo también escala los Motor6D)
if math.abs(DESIRED_SCALE / scale - 1) > 1e-3 then
	model:ScaleTo(DESIRED_SCALE / scale)
end
model:SetAttribute("RigScale", DESIRED_SCALE)
model:SetAttribute("Species", "Karnathys sanguifauces")

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
for _, n in ipairs({ "AbyssalDragon", "PredatorDragon", "PredatorDragon", "AerialDragon", "AncientDragon", "ShadowDragon" }) do
	ensure(dragons, n)
end
local folder = dragons.PredatorDragon
local prev = folder:FindFirstChild("PredatorDragon")
if prev then
	prev:Destroy()
end
model.Parent = folder

local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({
	DisplayName = "Dragón Depredador", Species = "Karnathys sanguifauces", Epithet = "Fauce Roja",
	WalkSpeed = 12, RunSpeed = 30, FlySpeed = 40, FlyHeight = 7, MaxHealth = 2600, AttackDamage = 60,
	AttackRange = 12, EyeColor = Color3.fromRGB(245, 248, 255),
}) do
	settings:SetAttribute(k, v)
end

putScript(dragons, "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "PredatorShowcase", "LocalScript", SOURCES.Showcase)

local assets = ensure(ServerStorage, "DragonAssets")
local bak = assets:FindFirstChild("PredatorDragon_Rig")
if bak then
	bak:Destroy()
end
local backup = model:Clone()
backup.Name = "PredatorDragon_Rig"
backup.Parent = assets

local showcase = ensure(workspace, "DragonShowcase")
local stage = showcase:FindFirstChild("Stage_Predator")
if not stage then
	stage = Instance.new("Part")
	stage.Name = "Stage_Predator"
	stage.Anchored = true
	stage.Size = Vector3.new(90, 1, 90)
	stage.CFrame = CFrame.new(0, 0.5, -150)
	stage.Material = Enum.Material.Slate
	stage.Color = Color3.fromRGB(28, 26, 30)
	stage.Parent = showcase
end
local statue = showcase:FindFirstChild("PredatorDragon_Preview")
if statue then
	statue:Destroy()
end
statue = model:Clone()
statue.Name = "PredatorDragon_Preview"
statue:PivotTo(stage.CFrame * CFrame.new(0, stage.Size.Y / 2, 0) * CFrame.Angles(0, math.rad(180), 0))
statue.Parent = showcase

if source.Parent and #source:GetDescendants() == 0 then
	source:Destroy()
end
Selection:Set({ statue })
pcall(function()
	ChangeHistoryService:SetWaypoint("Dragón Depredador instalado")
end)
print("[Predator] Listo: rig con " .. #RIG .. " Motor6D en ReplicatedStorage.Dragons.PredatorDragon. Pulsa Play: noche cerrada, te mira fijamente; botones 1-9 y L para la luz.")
