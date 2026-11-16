--[[
	INSTALADOR DEL DRAGÓN ABERRANTE · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	Pasos:
	  1. Studio > pestaña Avatar (o Home) > Import 3D > AberrantDragon.fbx (o .glb).
	     En el importador: deja "Rig General > Rig Type" en "No Rig" y NO combines mallas.
	     Pulsa Import. Aparece el modelo en Workspace.
	  2. Selecciona ese modelo en el Explorer.
	  3. View > Command Bar. Pega TODO este archivo y pulsa Enter.

	Resultado:
	  ReplicatedStorage.Dragons.AberrantDragon          (rig con Motor6D, Settings, Animations)
	  ReplicatedStorage.Dragons.DragonAnimator          (motor de animación por datos)
	  ServerStorage.DragonAssets.AberrantDragon_Rig     (copia de seguridad del rig)
	  Workspace.DragonShowcase                          (escenario + estatua de vista previa)
	  StarterPlayer.StarterPlayerScripts.DragonShowcase (vitrina con botones 1-9)
	Pulsa Play para ver al dragón y probar sus animaciones.
]]

-- Opcional: escala final en studs por unidad del modelo (1 = 23 studs de largo).
local DESIRED_SCALE = 1
-- Opcional: tras subir los PNG del atlas (Asset Manager), pega aquí sus ids "rbxassetid://..."
-- para crear SurfaceAppearance PBR en cada pieza.
local MAPS = { ColorMap = "", NormalMap = "", RoughnessMap = "" }

local RIG = {
	{ name = "Neck3", parent = "Neck2", pivot = { -0.5, 16.6, -3.2 }, center = { -0.6139, 17.2599, -4.7409 } },
	{ name = "Neck2", parent = "Neck1", pivot = { 0.3, 12.4, -1.1 }, center = { -0.0698, 14.5816, -2.0992 } },
	{ name = "Neck1", parent = "Chest", pivot = { 0, 9.6, -0.2 }, center = { 0.0963, 10.8845, -0.3708 } },
	{ name = "Chest", parent = "Hips", pivot = { -0.1, 7.7, 2.1 }, center = { -0.1723, 8.262, 0.8857 } },
	{ name = "Hips", parent = nil, pivot = { 0.0129, 7.4078, 2.8245 }, center = { -0.0528, 7.681, 2.9659 } },
	{ name = "Tail1", parent = "Hips", pivot = { 0.2, 7.1, 3.6 }, center = { 0.509, 6.7678, 4.8391 } },
	{ name = "Tail2", parent = "Tail1", pivot = { 1.2, 5.9, 6 }, center = { 1.4742, 5.3429, 7.1211 } },
	{ name = "Tail3", parent = "Tail2", pivot = { 2.2, 4.4, 8.4 }, center = { 1.8503, 3.8795, 9.6616 } },
	{ name = "Tail4", parent = "Tail3", pivot = { 1.6, 3, 11 }, center = { -0.0997, 2.783, 12.9355 } },
	{ name = "Head", parent = "Neck3", pivot = { -0.6, 17.4, -6.8 }, center = { -0.4746, 16.4891, -7.1207 } },
	{ name = "Eye1", parent = "Head", pivot = { -1.039, 15.897, -6.959 }, center = { -1.0756, 15.8963, -6.9672 } },
	{ name = "Eye2", parent = "Head", pivot = { -0.0824, 16.0526, -7.0165 }, center = { -0.0587, 16.0531, -7.0245 } },
	{ name = "Eye3", parent = "Head", pivot = { -0.1569, 15.2676, -6.8489 }, center = { -0.1382, 15.2677, -6.8497 } },
	{ name = "JawL", parent = "Head", pivot = { -1.0867, 17.0948, -6.2204 }, center = { -1.2272, 15.4349, -6.3071 } },
	{ name = "JawR", parent = "Head", pivot = { -0.2527, 17.1099, -6.1209 }, center = { -0.1219, 15.452, -6.1772 } },
	{ name = "Tongue", parent = "Head", pivot = { -0.6606, 16.6485, -6.1776 }, center = { -0.6833, 15.2041, -5.3794 } },
	{ name = "LegL_Thigh", parent = "Hips", pivot = { -0.9, 7.2, 3.1 }, center = { -1.6498, 6.5321, 1.6666 } },
	{ name = "LegL_Shin", parent = "LegL_Thigh", pivot = { -2.6, 5.6, 0.2 }, center = { -2.6517, 4.6156, 2.3037 } },
	{ name = "LegL_Foot", parent = "LegL_Shin", pivot = { -2.8, 3, 4.6 }, center = { -3.2774, 1.5629, 3.6672 } },
	{ name = "LegR_Thigh", parent = "Hips", pivot = { 0.9, 7.3, 3 }, center = { 1.4137, 6.3788, 1.2545 } },
	{ name = "LegR_Shin", parent = "LegR_Thigh", pivot = { 2.2, 5.2, -0.5 }, center = { 2.2495, 4.1986, 1.3757 } },
	{ name = "LegR_Foot", parent = "LegR_Shin", pivot = { 2.4, 2.6, 3.5 }, center = { 2.7572, 1.3432, 2.4594 } },
	{ name = "ArmR_Upper", parent = "Chest", pivot = { 1.1, 9.6, -0.6 }, center = { 1.8988, 8.3026, -1.8054 } },
	{ name = "ArmR_Fore", parent = "ArmR_Upper", pivot = { 2.8, 7, -3 }, center = { 2.7232, 5.4809, -3.6939 } },
	{ name = "ArmR_Hand", parent = "ArmR_Fore", pivot = { 2.5, 3.5, -4.5 }, center = { 2.652, 1.7986, -5.6692 } },
	{ name = "ArmL_Upper", parent = "Chest", pivot = { -1, 9.2, -0.8 }, center = { -1.2629, 8.6243, -1.4735 } },
	{ name = "ArmL_Fore", parent = "ArmL_Upper", pivot = { -1.6, 8, -2.2 }, center = { -1.2913, 7.8009, -2.69 } },
	{ name = "WingL_Arm", parent = "Chest", pivot = { -0.6, 10, 0.3 }, center = { -4.2208, 9.233, 4.8897 } },
	{ name = "WingL_Hand", parent = "WingL_Arm", pivot = { -8, 13, 3.5 }, center = { -10.4916, 8.9332, 6.3129 } },
	{ name = "WingR", parent = "Chest", pivot = { 0.6, 10, 0.3 }, center = { 3.0166, 10.1227, 1.8544 } },
}
local GROUND_Y = -0.4145
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
	Animaciones del Dragón Aberrante (ModuleScript) · ReplicatedStorage.Dragons.AberrantDragon.Animations
	Generado desde src/aberrant_anims.js con tools/build_roblox.js: edita la fuente y regenera.
	Formato: ver DragonAnimator. Ángulos en grados, traslaciones en studs, tiempos en segundos.
]]
return {
	Idle = {
		dur = 4,
		loop = true,
		joints = {
			Tail1 = {
				o = {
					{ "y", 2, 1, 0 },
				},
			},
			Tail2 = {
				o = {
					{ "y", 3, 1, 0.08 },
				},
			},
			Tail3 = {
				o = {
					{ "y", 4, 1, 0.16 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 5, 1, 0.24 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.08, 2, 0 },
				},
			},
			Chest = {
				o = {
					{ "x", 2, 2, 0.1 },
				},
			},
			Neck1 = {
				o = {
					{ "x", 2.5, 1, 0 },
				},
			},
			Neck2 = {
				o = {
					{ "x", 3, 1, 0.1 },
					{ "z", 3, 1, 0.3 },
				},
			},
			Neck3 = {
				o = {
					{ "z", 5, 1, 0.2 },
				},
			},
			Head = {
				o = {
					{ "z", 9, 1, 0.3 },
					{ "y", 6, 1, 0.55 },
					{ "x", 2, 4, 0 },
				},
			},
			JawL = {
				k = {
					{ 0, -4, 4, 0 },
				},
				o = {
					{ "y", 5, 2, 0 },
					{ "x", 3, 3, 0.2 },
				},
			},
			JawR = {
				k = {
					{ 0, -4, -4, 0 },
				},
				o = {
					{ "y", -5, 2, 0.05 },
					{ "x", 3, 3, 0.4 },
				},
			},
			Tongue = {
				o = {
					{ "x", 9, 1, 0.1 },
					{ "z", 6, 2, 0.3 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 8, 6 },
				},
				o = {
					{ "z", 3, 1, 0 },
				},
			},
			WingL_Hand = {
				o = {
					{ "y", 4, 1, 0.2 },
				},
			},
			WingR = {
				o = {
					{ "z", -6, 3, 0 },
					{ "y", 4, 2, 0.3 },
				},
			},
			ArmL_Upper = {
				o = {
					{ "x", 6, 2, 0 },
				},
			},
			ArmL_Fore = {
				o = {
					{ "x", 12, 3, 0.2 },
				},
			},
			ArmR_Fore = {
				o = {
					{ "x", 2, 1, 0.5 },
				},
			},
		},
	},
	Walk = {
		dur = 2.4,
		loop = true,
		joints = {
			Tail1 = {
				o = {
					{ "y", 4, 1, 0.1 },
				},
			},
			Tail2 = {
				o = {
					{ "y", 6, 1, 0.18 },
				},
			},
			Tail3 = {
				o = {
					{ "y", 8, 1, 0.26 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 10, 1, 0.34 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.22, 2, 0 },
					{ "z", 5, 1, 0.1 },
					{ "y", 5, 1, 0.3 },
				},
			},
			Chest = {
				o = {
					{ "z", -4, 1, 0.2 },
					{ "x", 3, 2, 0.3 },
				},
			},
			Neck1 = {
				o = {
					{ "x", 4, 2, 0.1 },
				},
			},
			Neck2 = {
				o = {
					{ "z", 5, 1, 0.3 },
				},
			},
			Neck3 = {
				o = {
					{ "z", 6, 1, 0.4 },
				},
			},
			Head = {
				o = {
					{ "z", 12, 1, 0.5 },
					{ "x", 4, 2, 0.2 },
				},
			},
			Tongue = {
				o = {
					{ "x", 14, 2, 0.2 },
				},
			},
			LegL_Thigh = {
				o = {
					{ "x", 24, 1, 0 },
				},
			},
			LegL_Shin = {
				o = {
					{ "x", 20, 1, 0.22 },
				},
			},
			LegL_Foot = {
				o = {
					{ "x", 16, 1, 0.4 },
				},
			},
			LegR_Thigh = {
				o = {
					{ "x", 16, 1, 0.5 },
				},
			},
			LegR_Shin = {
				o = {
					{ "x", 28, 1, 0.78 },
				},
			},
			LegR_Foot = {
				o = {
					{ "x", 12, 1, 0.9 },
				},
			},
			ArmR_Upper = {
				o = {
					{ "x", 20, 1, 0.3 },
				},
			},
			ArmR_Fore = {
				o = {
					{ "x", 16, 1, 0.5 },
				},
			},
			ArmR_Hand = {
				o = {
					{ "x", 10, 1, 0.6 },
				},
			},
			ArmL_Upper = {
				o = {
					{ "x", 8, 2, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 22, 10 },
				},
				o = {
					{ "z", 4, 1, 0.3 },
				},
			},
			WingL_Hand = {
				k = {
					{ 0, 0, 15, 0 },
				},
			},
			WingR = {
				o = {
					{ "z", -8, 2, 0 },
				},
			},
			JawL = {
				k = {
					{ 0, -6, 6, 0 },
				},
			},
			JawR = {
				k = {
					{ 0, -6, -6, 0 },
				},
			},
		},
	},
	Run = {
		dur = 1.2,
		loop = true,
		joints = {
			Tail1 = {
				o = {
					{ "y", 5.6, 1, 0.1 },
				},
			},
			Tail2 = {
				o = {
					{ "y", 8.4, 1, 0.18 },
				},
			},
			Tail3 = {
				o = {
					{ "y", 11.2, 1, 0.26 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 14, 1, 0.34 },
				},
			},
			Hips = {
				k = {
					{ 0, -10, 0, 0 },
				},
				p = {
					{ 0, 0, -0.6, 0 },
				},
				o = {
					{ "py", 0.4, 2, 0 },
					{ "z", 6, 1, 0.1 },
				},
			},
			Chest = {
				k = {
					{ 0, -6, 0, 0 },
				},
				o = {
					{ "x", 4, 2, 0.2 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -14, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, -12, 0, 0 },
				},
				o = {
					{ "z", 6, 1, 0.3 },
				},
			},
			Neck3 = {
				k = {
					{ 0, -6, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 14, 0, 0 },
				},
				o = {
					{ "z", 10, 1, 0.5 },
				},
			},
			Tongue = {
				o = {
					{ "x", 20, 2, 0.2 },
				},
			},
			LegL_Thigh = {
				o = {
					{ "x", 38, 1, 0 },
				},
			},
			LegL_Shin = {
				o = {
					{ "x", 32, 1, 0.22 },
				},
			},
			LegL_Foot = {
				o = {
					{ "x", 24, 1, 0.4 },
				},
			},
			LegR_Thigh = {
				o = {
					{ "x", 30, 1, 0.5 },
				},
			},
			LegR_Shin = {
				o = {
					{ "x", 40, 1, 0.75 },
				},
			},
			LegR_Foot = {
				o = {
					{ "x", 20, 1, 0.9 },
				},
			},
			ArmR_Upper = {
				o = {
					{ "x", 34, 1, 0.3 },
				},
			},
			ArmR_Fore = {
				o = {
					{ "x", 26, 1, 0.5 },
				},
			},
			ArmR_Hand = {
				o = {
					{ "x", 16, 1, 0.6 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 10, -18 },
				},
				o = {
					{ "z", 10, 1, 0.2 },
				},
			},
			WingL_Hand = {
				o = {
					{ "z", 8, 1, 0.35 },
				},
			},
			WingR = {
				o = {
					{ "z", -14, 2, 0 },
				},
			},
			JawL = {
				k = {
					{ 0, -14, 12, 0 },
				},
			},
			JawR = {
				k = {
					{ 0, -14, -12, 0 },
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
					{ "y", 4.8, 1, 0.3 },
				},
			},
			Tail2 = {
				o = {
					{ "y", 7.2, 1, 0.38 },
				},
			},
			Tail3 = {
				o = {
					{ "y", 9.6, 1, 0.46 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 12, 1, 0.54 },
				},
			},
			Hips = {
				k = {
					{ 0, 6, 0, 0 },
				},
				p = {
					{ 0, 0, 6, 0 },
				},
				o = {
					{ "py", 0.7, 1, 0.25 },
					{ "z", 4, 1, 0 },
					{ "x", 3, 1, 0.5 },
				},
			},
			Chest = {
				k = {
					{ 0, -8, 0, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -18, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, -12, 0, 0 },
				},
				o = {
					{ "x", 4, 1, 0.3 },
				},
			},
			Neck3 = {
				k = {
					{ 0, -4, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 48, 0, 0 },
				},
				o = {
					{ "z", 6, 1, 0.4 },
				},
			},
			Tongue = {
				k = {
					{ 0, -30, 0, 0 },
				},
				o = {
					{ "x", 10, 2, 0 },
				},
			},
			LegL_Thigh = {
				k = {
					{ 0, -55, 0, 0 },
				},
				o = {
					{ "x", 6, 1, 0.5 },
				},
			},
			LegL_Shin = {
				k = {
					{ 0, 45, 0, 0 },
				},
			},
			LegL_Foot = {
				k = {
					{ 0, -30, 0, 0 },
				},
			},
			LegR_Thigh = {
				k = {
					{ 0, -48, 0, 0 },
				},
				o = {
					{ "x", 8, 1, 0.6 },
				},
			},
			LegR_Shin = {
				k = {
					{ 0, 55, 0, 0 },
				},
			},
			LegR_Foot = {
				k = {
					{ 0, -20, 0, 0 },
				},
			},
			ArmR_Upper = {
				k = {
					{ 0, -45, 0, 0 },
				},
			},
			ArmR_Fore = {
				k = {
					{ 0, 70, 0, 0 },
				},
			},
			ArmR_Hand = {
				k = {
					{ 0, -30, 0, 0 },
				},
			},
			ArmL_Upper = {
				k = {
					{ 0, -20, 0, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 0, -8 },
				},
				o = {
					{ "z", 42, 1, 0 },
				},
			},
			WingL_Hand = {
				o = {
					{ "z", 26, 1, 0.12 },
					{ "y", 10, 1, 0.3 },
				},
			},
			WingR = {
				o = {
					{ "z", -35, 2, 0 },
					{ "y", -10, 2, 0.2 },
				},
			},
			JawL = {
				k = {
					{ 0, -8, 8, 0 },
				},
			},
			JawR = {
				k = {
					{ 0, -8, -8, 0 },
				},
			},
		},
	},
	TakeOff = {
		dur = 1.7,
		loop = false,
		next = "Fly",
		joints = {
			Hips = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, 10, 0, 0 },
					{ 0.75, -10, 0, 0 },
					{ 1.7, 6, 0, 0 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 0.4, 0, -1.1, 0.3 },
					{ 0.75, 0, 2.6, -0.6 },
					{ 1.7, 0, 6, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, 12, 0, 0 },
					{ 0.8, -22, 0, 0 },
					{ 1.7, -18, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.8, -14, 0, 0 },
					{ 1.7, -12, 0, 0 },
				},
			},
			Neck3 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.7, -4, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, -15, 0, 0 },
					{ 0.9, 40, 0, 0 },
					{ 1.7, 48, 0, 0 },
				},
			},
			LegL_Thigh = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, 30, 0, 0 },
					{ 0.7, -20, 0, 0 },
					{ 1.7, -55, 0, 0 },
				},
			},
			LegL_Shin = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, -45, 0, 0 },
					{ 0.7, 10, 0, 0 },
					{ 1.7, 45, 0, 0 },
				},
			},
			LegR_Thigh = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, 28, 0, 0 },
					{ 0.7, -18, 0, 0 },
					{ 1.7, -48, 0, 0 },
				},
			},
			LegR_Shin = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, -42, 0, 0 },
					{ 0.7, 12, 0, 0 },
					{ 1.7, 55, 0, 0 },
				},
			},
			ArmR_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.35, 15, 0, 0 },
					{ 0.75, -45, 0, 0 },
					{ 1.7, -45, 0, 0 },
				},
			},
			ArmR_Fore = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.75, 70, 0, 0 },
					{ 1.7, 70, 0, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 8, 6 },
					{ 0.4, 0, -10, -50 },
					{ 0.75, 0, 0, 48 },
					{ 1.05, 0, 0, -38 },
					{ 1.4, 0, 0, 40 },
					{ 1.7, 0, 0, -8 },
				},
			},
			WingL_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, 0, 0, -20 },
					{ 0.8, 0, 0, 30 },
					{ 1.1, 0, 0, -25 },
					{ 1.45, 0, 0, 28 },
					{ 1.7, 0, 0, 0 },
				},
			},
			WingR = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, 0, 0, 40 },
					{ 0.75, 0, 0, -35 },
					{ 1.05, 0, 0, 30 },
					{ 1.4, 0, 0, -30 },
					{ 1.7, 0, 0, 0 },
				},
			},
			Tail1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.4, -12, 0, 0 },
					{ 0.8, 14, 0, 0 },
					{ 1.7, 0, 0, 0 },
				},
			},
			Tail2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, -10, 0, 0 },
					{ 0.9, 16, 0, 0 },
					{ 1.7, 0, 0, 0 },
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
					{ 0, 6, 0, 0 },
					{ 0.6, 12, 0, 0 },
					{ 1, 6, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
				p = {
					{ 0, 0, 6, 0 },
					{ 0.8, 0, 0.6, 0 },
					{ 1, 0, -1, 0.2 },
					{ 1.5, 0, 0, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -18, 0, 0 },
					{ 0.7, 10, 0, 0 },
					{ 1.05, -12, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, -12, 0, 0 },
					{ 0.7, 6, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			Neck3 = {
				k = {
					{ 0, -4, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 48, 0, 0 },
					{ 0.7, 0, 0, 0 },
					{ 1.05, -12, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			LegL_Thigh = {
				k = {
					{ 0, -55, 0, 0 },
					{ 0.6, 25, 0, 0 },
					{ 1, 30, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			LegL_Shin = {
				k = {
					{ 0, 45, 0, 0 },
					{ 0.6, -10, 0, 0 },
					{ 1, -40, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			LegR_Thigh = {
				k = {
					{ 0, -48, 0, 0 },
					{ 0.6, 22, 0, 0 },
					{ 1, 28, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			LegR_Shin = {
				k = {
					{ 0, 55, 0, 0 },
					{ 0.6, -8, 0, 0 },
					{ 1, -38, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			ArmR_Upper = {
				k = {
					{ 0, -45, 0, 0 },
					{ 0.7, 20, 0, 0 },
					{ 1, 8, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			ArmR_Fore = {
				k = {
					{ 0, 70, 0, 0 },
					{ 0.7, -10, 0, 0 },
					{ 1.5, 0, 0, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 0, -8 },
					{ 0.35, 0, -10, -55 },
					{ 0.7, 0, 0, 25 },
					{ 1, 0, 10, -20 },
					{ 1.5, 0, 8, 6 },
				},
			},
			WingL_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.35, 0, 0, -25 },
					{ 0.7, 0, 0, 20 },
					{ 1.5, 0, 0, 0 },
				},
			},
			WingR = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.35, 0, 0, 40 },
					{ 0.7, 0, 0, -25 },
					{ 1.5, 0, 0, 0 },
				},
			},
			JawL = {
				k = {
					{ 0, -8, 8, 0 },
					{ 1, -2, 2, 0 },
					{ 1.5, -4, 4, 0 },
				},
			},
			JawR = {
				k = {
					{ 0, -8, -8, 0 },
					{ 1, -2, -2, 0 },
					{ 1.5, -4, -4, 0 },
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
					{ 0.45, 6, 8, 0 },
					{ 0.62, -10, -6, 0 },
					{ 1.4, 0, 0, 0 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 0.45, 0, 0.3, 0.6 },
					{ 0.62, 0, -0.5, -1.6 },
					{ 1, 0, -0.2, -1 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Chest = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 8, 0, 0 },
					{ 0.62, -10, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 26, 0, 0 },
					{ 0.62, -30, 0, 0 },
					{ 0.95, -26, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 22, 0, 0 },
					{ 0.62, -32, 0, 0 },
					{ 0.95, -28, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Neck3 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 10, 0, 0 },
					{ 0.62, -18, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, -10, 0, 0 },
					{ 0.62, 32, 0, 0 },
					{ 0.95, 25, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			JawL = {
				k = {
					{ 0, -4, 4, 0 },
					{ 0.45, -32, 34, 0 },
					{ 0.62, -40, 40, 0 },
					{ 0.72, -2, 0, 0 },
					{ 1.4, -4, 4, 0 },
				},
			},
			JawR = {
				k = {
					{ 0, -4, -4, 0 },
					{ 0.45, -32, -34, 0 },
					{ 0.62, -40, -40, 0 },
					{ 0.72, -2, 0, 0 },
					{ 1.4, -4, -4, 0 },
				},
			},
			Tongue = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.62, -35, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			ArmR_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 35, 0, -25 },
					{ 0.62, -45, 0, 10 },
					{ 1, -30, 0, 5 },
					{ 1.4, 0, 0, 0 },
				},
			},
			ArmR_Fore = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, -55, 0, 0 },
					{ 0.62, 30, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			ArmR_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, -40, 0, 0 },
					{ 0.62, 45, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 8, 6 },
					{ 0.45, 0, -10, -35 },
					{ 0.62, 0, 0, 10 },
					{ 1.4, 0, 8, 6 },
				},
			},
			WingR = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 0, 0, 35 },
					{ 0.75, 0, 0, -10 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Tail1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, -10, 15, 0 },
					{ 0.62, 6, -18, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Tail3 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, 25, 0 },
					{ 0.7, 0, -30, 0 },
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
					{ 0.5, 10, 0, 0 },
					{ 2.1, 10, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, 0.3, 0.4 },
					{ 2.1, 0, 0.3, 0.4 },
					{ 2.6, 0, 0, 0 },
				},
			},
			Chest = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 8, 0, 0 },
					{ 2.1, 8, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
				o = {
					{ "x", 1.5, 26, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 22, 0, 0 },
					{ 2.1, 22, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 12, 0, 0 },
					{ 2.1, 12, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
			},
			Neck3 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, -10, 0, 0 },
					{ 2.1, -10, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.55, 48, 0, 0 },
					{ 2.1, 44, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
				o = {
					{ "z", 4, 26, 0 },
					{ "y", 3, 19, 0.2 },
				},
			},
			JawL = {
				k = {
					{ 0, -4, 4, 0 },
					{ 0.55, -42, 42, 0 },
					{ 2.1, -40, 40, 0 },
					{ 2.6, -4, 4, 0 },
				},
				o = {
					{ "y", 5, 30, 0 },
				},
			},
			JawR = {
				k = {
					{ 0, -4, -4, 0 },
					{ 0.55, -42, -42, 0 },
					{ 2.1, -40, -40, 0 },
					{ 2.6, -4, -4, 0 },
				},
				o = {
					{ "y", -5, 30, 0.5 },
				},
			},
			Tongue = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.55, -45, 0, 0 },
					{ 2.1, -40, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
				o = {
					{ "z", 10, 20, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 8, 6 },
					{ 0.5, 0, -20, -40 },
					{ 2.1, 0, -18, -42 },
					{ 2.6, 0, 8, 6 },
				},
				o = {
					{ "z", 3, 24, 0 },
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
			WingR = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, 0, 40 },
					{ 2.1, 0, 0, 40 },
					{ 2.6, 0, 0, 0 },
				},
				o = {
					{ "z", 8, 30, 0 },
				},
			},
			ArmL_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 30, 0, 0 },
					{ 2.1, 30, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
				o = {
					{ "x", 8, 22, 0 },
				},
			},
			ArmR_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 15, 0, -20 },
					{ 2.1, 15, 0, -20 },
					{ 2.6, 0, 0, 0 },
				},
			},
			Tail1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, -10, 0, 0 },
					{ 2.1, -10, 0, 0 },
					{ 2.6, 0, 0, 0 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 10, 12, 0 },
				},
			},
		},
	},
	Death = {
		dur = 2.8,
		loop = false,
		joints = {
			Hips = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 8, 0, 0 },
					{ 1.4, -6, 10, 22 },
					{ 2.8, -8, 12, 28 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, 0.4, 0 },
					{ 1.4, 0, -4.6, 0.5 },
					{ 2.8, 0, -5.2, 0.6 },
				},
			},
			Chest = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 10, 0, 0 },
					{ 1.5, -12, 0, 8 },
					{ 2.8, -14, 0, 10 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 25, 0, 0 },
					{ 1.5, -30, 0, 0 },
					{ 2.8, -45, 0, 10 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 15, 0, 0 },
					{ 1.6, -35, 10, 0 },
					{ 2.8, -50, 15, 0 },
				},
			},
			Neck3 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.7, -30, 0, 20 },
					{ 2.8, -35, 0, 30 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 45, 0, 0 },
					{ 1.8, -10, 0, 30 },
					{ 2.8, -20, 0, 40 },
				},
			},
			JawL = {
				k = {
					{ 0, -4, 4, 0 },
					{ 0.5, -40, 40, 0 },
					{ 2.8, -20, 28, 0 },
				},
			},
			JawR = {
				k = {
					{ 0, -4, -4, 0 },
					{ 0.5, -40, -40, 0 },
					{ 2.8, -15, -22, 0 },
				},
			},
			Tongue = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, -40, 0, 0 },
					{ 2.8, 20, 0, 30 },
				},
			},
			LegL_Thigh = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, -10, 0, 0 },
					{ 1.4, 45, 0, -10 },
					{ 2.8, 60, 0, -15 },
				},
			},
			LegL_Shin = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.4, -70, 0, 0 },
					{ 2.8, -85, 0, 0 },
				},
			},
			LegL_Foot = {
				k = {
					{ 0, 0, 0, 0 },
					{ 2.8, 40, 0, 0 },
				},
			},
			LegR_Thigh = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, -8, 0, 0 },
					{ 1.3, 40, 0, 15 },
					{ 2.8, 55, 0, 20 },
				},
			},
			LegR_Shin = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.3, -65, 0, 0 },
					{ 2.8, -80, 0, 0 },
				},
			},
			LegR_Foot = {
				k = {
					{ 0, 0, 0, 0 },
					{ 2.8, 35, 0, 0 },
				},
			},
			ArmR_Upper = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 25, 0, -20 },
					{ 1.4, -20, 0, 30 },
					{ 2.8, -25, 0, 40 },
				},
			},
			ArmR_Fore = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.4, 40, 0, 0 },
					{ 2.8, 50, 0, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 8, 6 },
					{ 0.5, 0, -15, -45 },
					{ 1.5, 0, 20, 40 },
					{ 2.8, 0, 30, 55 },
				},
			},
			WingL_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.5, 0, 25, 20 },
					{ 2.8, 0, 40, 30 },
				},
			},
			WingR = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 0, 0, 40 },
					{ 2.8, 0, -30, -50 },
				},
			},
			Tail1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.5, 20, 0, 0 },
					{ 2.8, 25, 0, 0 },
				},
			},
			Tail2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 2.8, -10, 20, 0 },
				},
			},
			Tail3 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 2.8, -12, 25, 0 },
				},
			},
		},
	},
}
]=======],
	Showcase = [=======[
--[[
	DragonShowcase (LocalScript) · StarterPlayer.StarterPlayerScripts.DragonShowcase

	Vitrina local: clona el Dragón Aberrante en Workspace.DragonShowcase y muestra
	botones (o teclas 1-9) para probar sus nueve animaciones.
	Corre en el cliente: el clon solo existe para quien juega, ideal para revisar el diseño.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Dragons = ReplicatedStorage:WaitForChild("Dragons")
local DragonAnimator = require(Dragons:WaitForChild("DragonAnimator"))
local folder = Dragons:WaitForChild("AberrantDragon")
local animations = require(folder:WaitForChild("Animations"))
local template = folder:WaitForChild("AberrantDragon") :: Model
local showcase = workspace:WaitForChild("DragonShowcase")
local stage = showcase:WaitForChild("Stage") :: BasePart
-- la estatua de vista previa solo sirve en modo edición: se oculta en este cliente
local statue = showcase:FindFirstChild("AberrantDragon_Preview")
if statue then
	statue.Parent = nil
end

local ORDER = { "Idle", "Walk", "Run", "Fly", "TakeOff", "Landing", "Attack", "Roar", "Death" }
local LABELS = {
	Idle = "Reposo", Walk = "Caminar", Run = "Correr", Fly = "Volar", TakeOff = "Despegar",
	Landing = "Aterrizar", Attack = "Atacar", Roar = "Rugir", Death = "Morir",
}

local dragon: Model? = nil
local animator = nil
local busy = false

local function spawnDragon()
	if animator then
		animator:Destroy()
	end
	if dragon then
		dragon:Destroy()
	end
	dragon = template:Clone()
	local top = stage.CFrame * CFrame.new(0, stage.Size.Y / 2, 0)
	dragon:PivotTo(top * CFrame.Angles(0, math.rad(200), 0))
	dragon.Parent = showcase
	animator = DragonAnimator.new(dragon, animations)
	animator:Play("Idle", 0)
	animator.Finished.Event:Connect(function(name)
		if name == "Death" then
			busy = true
			-- desaparición: los ojos se apagan y el cuerpo se disuelve
			for _, p in ipairs(dragon:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "Root" then
					TweenService:Create(p, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
				elseif p:IsA("PointLight") then
					TweenService:Create(p, TweenInfo.new(0.6), { Brightness = 0 }):Play()
				end
			end
			task.delay(2.6, function()
				spawnDragon()
				busy = false
			end)
		elseif animations[name] and not animations[name].loop and not animations[name].next then
			animator:Play("Idle", 0.35)
		end
	end)
end

local function play(name: string)
	if busy or not animator then
		return
	end
	-- Fly sin estar en el aire: primero despega; Idle/Walk/Run en el aire: primero aterriza.
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
gui.Name = "DragonShowcaseGui"
gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -16)
bar.Size = UDim2.new(0, 0, 0, 44)
bar.AutomaticSize = Enum.AutomaticSize.X
bar.BackgroundColor3 = Color3.fromRGB(14, 12, 15)
bar.BackgroundTransparency = 0.15
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

for i, name in ipairs(ORDER) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 92, 0, 32)
	b.BackgroundColor3 = Color3.fromRGB(38, 32, 36)
	b.TextColor3 = Color3.fromRGB(230, 224, 214)
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 14
	b.Text = string.format("%d · %s", i, LABELS[name])
	b.Parent = bar
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(214, 255, 90)
	stroke.Transparency = 0.7
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	b.Activated:Connect(function()
		play(name)
	end)
end

local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine }
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	for i, key in ipairs(KEYS) do
		if input.KeyCode == key then
			play(ORDER[i])
		end
	end
end)

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
assert(source, "[Aberrant] No encontré el modelo importado. Impórtalo con Import 3D y selecciónalo antes de ejecutar.")
local parts, missing = findParts(source)
assert(#missing == 0, "[Aberrant] Faltan piezas en el modelo importado: " .. table.concat(missing, ", ") .. ". ¿Se combinaron las mallas al importar?")

pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar Dragón Aberrante")
end)

-- 2. Calibración: escala y orientación con que el importador dejó el modelo
local function ratio(a, b)
	return (parts[a].Position - parts[b].Position).Magnitude / (v3(byName[a].center) - v3(byName[b].center)).Magnitude
end
local scale = (ratio("Head", "Tail4") + ratio("LegL_Foot", "WingL_Hand") + ratio("ArmR_Hand", "WingR")) / 3
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
print(("[Aberrant] escala del import: %.4f · error máximo de posición: %.3f studs"):format(scale, bestErr))
if bestErr > 0.6 * scale then
	warn("[Aberrant] Las piezas no coinciden con el rig esperado. ¿Se movió o se rotó alguna pieza después de importar? Continúo igualmente.")
end
local function W(t)
	return origin + R:VectorToWorldSpace(v3(t) * scale)
end

-- 3. Construir el rig: Root anclado + Motor6D en cada articulación
local model = Instance.new("Model")
model.Name = "AberrantDragon"
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
		p.Color = Color3.fromRGB(214, 255, 90)
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
local glow = Instance.new("PointLight")
glow.Color = Color3.fromRGB(214, 255, 90)
glow.Range = 7 * scale
glow.Brightness = 1.6
glow.Shadows = false
glow.Parent = parts.Eye1

-- Escala final deseada (Model:ScaleTo también escala los Motor6D)
if math.abs(DESIRED_SCALE / scale - 1) > 1e-3 then
	model:ScaleTo(DESIRED_SCALE / scale)
end
model:SetAttribute("RigScale", DESIRED_SCALE)
model:SetAttribute("Species", "Xethra contorta")

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
for _, n in ipairs({ "AbyssalDragon", "PredatorDragon", "AberrantDragon", "AerialDragon", "AncientDragon", "ShadowDragon" }) do
	ensure(dragons, n)
end
local folder = dragons.AberrantDragon
local prev = folder:FindFirstChild("AberrantDragon")
if prev then
	prev:Destroy()
end
model.Parent = folder

local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({
	DisplayName = "Dragón Aberrante", Species = "Xethra contorta", Epithet = "El Torcido",
	WalkSpeed = 9, RunSpeed = 22, FlySpeed = 34, FlyHeight = 6, MaxHealth = 1800, AttackDamage = 45,
	AttackRange = 9, EyeColor = Color3.fromRGB(214, 255, 90),
}) do
	settings:SetAttribute(k, v)
end

putScript(dragons, "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "DragonShowcase", "LocalScript", SOURCES.Showcase)

local assets = ensure(ServerStorage, "DragonAssets")
local bak = assets:FindFirstChild("AberrantDragon_Rig")
if bak then
	bak:Destroy()
end
local backup = model:Clone()
backup.Name = "AberrantDragon_Rig"
backup.Parent = assets

local showcase = ensure(workspace, "DragonShowcase")
local stage = showcase:FindFirstChild("Stage")
if not stage then
	stage = Instance.new("Part")
	stage.Name = "Stage"
	stage.Anchored = true
	stage.Size = Vector3.new(70, 1, 70)
	stage.CFrame = CFrame.new(0, 0.5, -60)
	stage.Material = Enum.Material.Slate
	stage.Color = Color3.fromRGB(28, 26, 30)
	stage.Parent = showcase
end
local statue = showcase:FindFirstChild("AberrantDragon_Preview")
if statue then
	statue:Destroy()
end
statue = model:Clone()
statue.Name = "AberrantDragon_Preview"
statue:PivotTo(stage.CFrame * CFrame.new(0, stage.Size.Y / 2, 0) * CFrame.Angles(0, math.rad(200), 0))
statue.Parent = showcase

if source.Parent and #source:GetDescendants() == 0 then
	source:Destroy()
end
Selection:Set({ statue })
pcall(function()
	ChangeHistoryService:SetWaypoint("Dragón Aberrante instalado")
end)
print("[Aberrant] Listo: rig con " .. #RIG .. " Motor6D en ReplicatedStorage.Dragons.AberrantDragon. Pulsa Play y usa los botones 1-9.")
