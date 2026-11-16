--[[
	INSTALADOR DEL DRAGÓN SOMBRÍO (rig de huesos) · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	Pasos:
	  1. Studio > pestaña Avatar (o Home) > Import 3D > ShadowDragon.fbx.
	     En el importador: Rig General > Rig Type = "Custom" (malla con huesos). No combines las mallas.
	     Pulsa Import. Aparece el modelo en Workspace con las mallas Body, Skull, Teeth, WingL y WingR y sus Bones.
	  2. Selecciona ese modelo en el Explorer.
	  3. View > Command Bar. Pega TODO este archivo y pulsa Enter.

	Versión 2 (remaster): cabeza en malla propia (Skull), dientes irregulares, ojos con luz roja controlada,
	animaciones nuevas y comportamiento de terror psicológico en el servidor: un solo dragón para todos.
	Si ya había un Dragón Sombrío v1 instalado, se guarda como ServerStorage.DragonAssets.ShadowDragon_v1.

	Resultado:
	  ReplicatedStorage.Dragons.ShadowDragon          (modelo con huesos, Settings, Animations)
	  ReplicatedStorage.Dragons.DragonAnimator          (motor de animación por datos, Motor6D o Bones)
	  ServerStorage.DragonAssets.ShadowDragon_Rig     (copia de seguridad)
	  Workspace.DragonShowcase.Stage_Shadow           (escenario + estatua de vista previa)
	  ReplicatedStorage.Dragons.ShadowDragon.ShadowBrain (lógica del comportamiento)
	  ServerScriptService.ShadowStalker                  (el dragón para todos: decide dónde está y qué hace)
	  StarterPlayer.StarterPlayerScripts.ShadowClient    (anima, fundidos, ojos, ambiente y silencios)
	  StarterPlayer.StarterPlayerScripts.ShadowShowcase  (solo si INSTALL_SHOWCASE = true)
]]

-- Opcional: escala final en studs por unidad del modelo (1 = unos 45 studs de largo y 19 de alto).
local DESIRED_SCALE = 1
-- Opcional: tras subir los PNG (Asset Manager), pega aquí sus ids para crear SurfaceAppearance PBR.
-- La vitrina de prueba (noche, botones 1-9) choca con un juego real: actívala solo para revisar animaciones.
local INSTALL_SHOWCASE = false
-- Visión nocturna de prueba con la tecla N (desactívala si tu juego ya tiene la suya).
local PROVIDE_NIGHT_VISION = true
-- Sonidos: sube los .ogg de la carpeta sounds/ (Asset Manager) y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = {
	Breath = "",        -- respiración grave en bucle, sale del cuerpo del dragón
	Creak = "",         -- crujido de articulaciones (cerca)
	Shriek = "",        -- chillido del rugido
	Whisper = "",       -- ambiente: susurro lejano, suena en puntos al azar alrededor del jugador
	DistantBreath = "", -- ambiente: respiración lejana
	Crack = "",         -- ambiente: rama que cruje
}
local MAPS = {
	Body = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	WingL = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	WingR = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	Skull = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
}
-- Teeth no lleva texturas: es marfil liso y ShadowClient la pasa a Neon tenue (la sonrisa brilla en la oscuridad).

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
local EYES = { EyeL = { 0.858, 8.0075, -12.8686 }, EyeR = { -0.858, 8.0075, -12.8686 }, bone = "Head" }
local GROUND_Y = -0.155
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
	Animaciones del Dragón Sombrío (ModuleScript) · ReplicatedStorage.Dragons.ShadowDragon.Animations
	Generado desde src/shadow_anims.js con tools/build_roblox.js: edita la fuente y regenera.
	Formato: ver DragonAnimator. Ángulos en grados, traslaciones en studs, tiempos en segundos.
]]
return {
	Idle = {
		dur = 10,
		loop = true,
		joints = {
			Tail1 = {
				o = {
					{ "y", 1.08, 1, 0.06 },
				},
			},
			Tail2 = {
				o = {
					{ "y", 1.41, 1, 0.12 },
				},
			},
			Tail3 = {
				o = {
					{ "y", 1.74, 1, 0.18 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 2.07, 1, 0.24 },
				},
			},
			Tail5 = {
				o = {
					{ "y", 2.4, 1, 0.3 },
				},
			},
			Tail6 = {
				o = {
					{ "y", 2.73, 1, 0.36 },
				},
			},
			Tail7 = {
				o = {
					{ "y", 3.06, 1, 0.42 },
				},
			},
			Tail8 = {
				o = {
					{ "y", 3.39, 1, 0.48 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.12, 2, 0 },
				},
			},
			Spine1 = {
				o = {
					{ "x", 2.2, 2, 0.05 },
				},
			},
			Chest = {
				o = {
					{ "x", 2.8, 2, 0.1 },
					{ "z", 0.6, 3, 0.3 },
				},
			},
			Neck1 = {
				o = {
					{ "x", 1.2, 2, 0.15 },
				},
			},
			Neck2 = {
				o = {
					{ "y", 1.5, 1, 0.1 },
					{ "x", 0.8, 3, 0.4 },
				},
			},
			Head = {
				o = {
					{ "y", 2.5, 1, 0.35 },
					{ "x", 1.5, 2, 0.6 },
					{ "z", 1.8, 1, 0.8 },
				},
			},
			Jaw = {
				k = {
					{ 0, 0, 0, 0 },
					{ 4.6, 0, 0, 0 },
					{ 5.4, -3, 0, 0 },
					{ 7.8, -3, 0, 0 },
					{ 8.6, 0, 0, 0 },
				},
			},
			LegFL_Foot = {
				o = {
					{ "x", 1.5, 3, 0.2 },
				},
			},
			LegFR_Foot = {
				o = {
					{ "x", 1.5, 4, 0.6 },
				},
			},
			WingL_Arm = {
				o = {
					{ "z", 1.5, 2, 0 },
				},
			},
			WingR_Arm = {
				o = {
					{ "z", -1.5, 2, 0 },
				},
			},
			WingL_Hand = {
				o = {
					{ "y", 2, 2, 0.2 },
				},
			},
			WingR_Hand = {
				o = {
					{ "y", -2, 2, 0.2 },
				},
			},
		},
	},
	Walk = {
		dur = 3.6,
		loop = true,
		joints = {
			Tail1 = {
				o = {
					{ "y", 3.24, 1, 0.16 },
				},
			},
			Tail2 = {
				o = {
					{ "y", 4.23, 1, 0.22 },
				},
			},
			Tail3 = {
				o = {
					{ "y", 5.22, 1, 0.28 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 6.21, 1, 0.34 },
				},
			},
			Tail5 = {
				o = {
					{ "y", 7.2, 1, 0.4 },
				},
			},
			Tail6 = {
				o = {
					{ "y", 8.19, 1, 0.46 },
				},
			},
			Tail7 = {
				o = {
					{ "y", 9.18, 1, 0.52 },
				},
			},
			Tail8 = {
				o = {
					{ "y", 10.17, 1, 0.58 },
				},
			},
			LegFL_Upper = {
				o = {
					{ "x", 19, 1, 0 },
					{ "z", 2, 7, 0.1 },
				},
			},
			LegFL_Lower = {
				o = {
					{ "x", 24, 1, 0.22 },
					{ "x", 3, 6, 0 },
				},
			},
			LegFL_Foot = {
				o = {
					{ "x", 20, 1, 0.4 },
				},
			},
			LegFR_Upper = {
				o = {
					{ "x", 14, 1, 0.46 },
					{ "z", -2, 5, 0.3 },
				},
			},
			LegFR_Lower = {
				o = {
					{ "x", 20, 1, 0.62 },
					{ "x", 3, 7, 0.2 },
				},
			},
			LegFR_Foot = {
				o = {
					{ "x", 16, 1, 0.82 },
				},
			},
			LegBL_Upper = {
				o = {
					{ "x", 17, 1, 0.71 },
				},
			},
			LegBL_Lower = {
				o = {
					{ "x", 22, 1, 0.9 },
					{ "x", 2.5, 5, 0.4 },
				},
			},
			LegBL_Foot = {
				o = {
					{ "x", 15, 1, 0.05 },
				},
			},
			LegBR_Upper = {
				o = {
					{ "x", 13, 1, 0.17 },
				},
			},
			LegBR_Lower = {
				o = {
					{ "x", 18, 1, 0.35 },
					{ "x", 2.5, 6, 0.7 },
				},
			},
			LegBR_Foot = {
				o = {
					{ "x", 14, 1, 0.52 },
				},
			},
			Hips = {
				o = {
					{ "py", 0.25, 2, 0.1 },
					{ "z", 4, 1, 0.1 },
					{ "y", 4, 1, 0.3 },
					{ "x", 1.2, 5, 0 },
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
					{ "y", -2.5, 1, 0.3 },
				},
			},
			Neck2 = {
				o = {
					{ "z", 2.5, 1, 0.6 },
				},
			},
			Head = {
				o = {
					{ "z", -3, 1, 0.2 },
					{ "y", 2, 1, 0.8 },
					{ "x", 1, 9, 0 },
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
		dur = 3.4,
		loop = false,
		next = "Idle",
		joints = {
			Hips = {
				p = {
					{ 0, 0, 0, 0 },
					{ 0.7, 0, -0.6, 0 },
					{ 2.7, 0, -0.6, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			Spine1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, -4, 0, 0 },
					{ 2.7, -4, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			Chest = {
				o = {
					{ "x", 1.4, 34, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, -12, 0, 0 },
					{ 2.7, -12, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, -8, 0, 0 },
					{ 2.7, -8, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			Neck3 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, 16, 0, 0 },
					{ 2.7, 16, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.5, 8, 0, 0 },
					{ 0.75, 8, 0, 30 },
					{ 1.8, 8, 0, 32 },
					{ 1.95, 8, 0, -26 },
					{ 2.7, 8, 0, -26 },
					{ 3.4, 0, 0, 0 },
				},
				o = {
					{ "z", 2.2, 40, 0 },
					{ "y", 2, 23, 0.2 },
				},
			},
			Jaw = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.55, -34, 0, 0 },
					{ 2.7, -32, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
				o = {
					{ "x", 3, 38, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, 0, -18, -45 },
					{ 2.7, 0, -18, -48 },
					{ 3.4, 0, 0, 0 },
				},
				o = {
					{ "z", 3, 24, 0 },
				},
			},
			WingR_Arm = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, 0, 18, 45 },
					{ 2.7, 0, 18, 48 },
					{ 3.4, 0, 0, 0 },
				},
				o = {
					{ "z", -3, 24, 0 },
				},
			},
			WingL_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, 0, -10, -20 },
					{ 2.7, 0, -10, -20 },
					{ 3.4, 0, 0, 0 },
				},
			},
			WingR_Hand = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, 0, 10, 20 },
					{ 2.7, 0, 10, 20 },
					{ 3.4, 0, 0, 0 },
				},
			},
			Tail1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.7, -10, 0, 0 },
					{ 2.7, -10, 0, 0 },
					{ 3.4, 0, 0, 0 },
				},
			},
			Tail6 = {
				o = {
					{ "y", 14, 12, 0 },
				},
			},
		},
	},
	Detect = {
		dur = 3.2,
		loop = false,
		next = "Watch",
		joints = {
			Hips = {
				p = {
					{ 0, 0, 0, 0 },
					{ 3.2, 0, 0.7, 0 },
				},
			},
			Spine1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 3.2, 4, 0, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.6, 0, 0, 0 },
					{ 3.2, 14, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.9, 0, 0, 0 },
					{ 3.2, 11, 0, 0 },
				},
			},
			Neck3 = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.2, 0, 0, 0 },
					{ 3.2, 6, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.5, 0, 0, 0 },
					{ 3.2, -4, 0, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, 0, 0, 0 },
					{ 2.4, 0, 0, 0 },
					{ 3.2, -4, 0, 0 },
				},
			},
		},
	},
	Watch = {
		dur = 8,
		loop = true,
		joints = {
			Hips = {
				k = {
					{ 0, 0, 0, 0 },
				},
				p = {
					{ 0, 0, 0.7, 0 },
				},
				o = {
					{ "py", 0.1, 2, 0 },
				},
			},
			Spine1 = {
				k = {
					{ 0, 4, 0, 0 },
				},
			},
			Chest = {
				o = {
					{ "x", 2.4, 2, 0.1 },
				},
			},
			Neck1 = {
				k = {
					{ 0, 14, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 11, 0, 0 },
				},
			},
			Neck3 = {
				k = {
					{ 0, 6, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, -4, 0, 0 },
				},
				o = {
					{ "y", 1.2, 1, 0.3 },
				},
			},
			Jaw = {
				k = {
					{ 0, -4, 0, 0 },
				},
			},
		},
	},
	Chase = {
		dur = 0.8,
		loop = true,
		joints = {
			Tail1 = {
				o = {
					{ "y", 5.04, 1, 0.16 },
					{ "x", 1.8, 2, 0.06 },
				},
			},
			Tail2 = {
				o = {
					{ "y", 6.58, 1, 0.22 },
					{ "x", 2.35, 2, 0.12 },
				},
			},
			Tail3 = {
				o = {
					{ "y", 8.12, 1, 0.28 },
					{ "x", 2.9, 2, 0.18 },
				},
			},
			Tail4 = {
				o = {
					{ "y", 9.66, 1, 0.34 },
					{ "x", 3.45, 2, 0.24 },
				},
			},
			Tail5 = {
				o = {
					{ "y", 11.2, 1, 0.4 },
					{ "x", 4, 2, 0.3 },
				},
			},
			Tail6 = {
				o = {
					{ "y", 12.74, 1, 0.46 },
					{ "x", 4.55, 2, 0.36 },
				},
			},
			Tail7 = {
				o = {
					{ "y", 14.28, 1, 0.52 },
					{ "x", 5.1, 2, 0.42 },
				},
			},
			Tail8 = {
				o = {
					{ "y", 15.82, 1, 0.58 },
					{ "x", 5.65, 2, 0.48 },
				},
			},
			LegFL_Upper = {
				o = {
					{ "x", 36, 1, 0 },
				},
			},
			LegFL_Lower = {
				o = {
					{ "x", 30, 1, 0.18 },
				},
			},
			LegFL_Foot = {
				o = {
					{ "x", 24, 1, 0.32 },
				},
			},
			LegFR_Upper = {
				o = {
					{ "x", 36, 1, 0.1 },
				},
			},
			LegFR_Lower = {
				o = {
					{ "x", 30, 1, 0.28 },
				},
			},
			LegFR_Foot = {
				o = {
					{ "x", 24, 1, 0.42 },
				},
			},
			LegBL_Upper = {
				o = {
					{ "x", 30, 1, 0.5 },
				},
			},
			LegBL_Lower = {
				o = {
					{ "x", 28, 1, 0.68 },
				},
			},
			LegBL_Foot = {
				o = {
					{ "x", 20, 1, 0.82 },
				},
			},
			LegBR_Upper = {
				o = {
					{ "x", 30, 1, 0.6 },
				},
			},
			LegBR_Lower = {
				o = {
					{ "x", 28, 1, 0.78 },
				},
			},
			LegBR_Foot = {
				o = {
					{ "x", 20, 1, 0.92 },
				},
			},
			Hips = {
				p = {
					{ 0, 0, -1.2, 0 },
				},
				o = {
					{ "py", 0.5, 2, 0 },
					{ "x", 4, 1, 0 },
				},
			},
			Chest = {
				o = {
					{ "x", 5, 1, 0.5 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -14, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, -6, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 12, 0, 0 },
				},
				o = {
					{ "x", 3, 2, 0.3 },
					{ "z", 4, 1, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -16, 0, 0 },
				},
				o = {
					{ "x", 4, 2, 0 },
				},
			},
			WingL_Arm = {
				k = {
					{ 0, 0, 12, -10 },
				},
			},
			WingR_Arm = {
				k = {
					{ 0, 0, -12, 10 },
				},
			},
		},
	},
	Freeze1 = {
		dur = 1,
		loop = true,
		joints = {
			Neck1 = {
				k = {
					{ 0, 4, 12, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 0, 22, 14 },
				},
			},
			Neck3 = {
				k = {
					{ 0, 6, 10, 22 },
				},
			},
			Head = {
				k = {
					{ 0, 4, 0, 48 },
				},
			},
			Jaw = {
				k = {
					{ 0, -6, 0, 0 },
				},
			},
		},
	},
	Freeze2 = {
		dur = 1,
		loop = true,
		joints = {
			Neck1 = {
				k = {
					{ 0, 6, 28, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, 4, 38, 0 },
				},
			},
			Neck3 = {
				k = {
					{ 0, 0, 30, -10 },
				},
			},
			Head = {
				k = {
					{ 0, -6, 20, -34 },
				},
			},
			LegFR_Upper = {
				k = {
					{ 0, 18, 0, 6 },
				},
			},
			LegFR_Lower = {
				k = {
					{ 0, -26, 0, 0 },
				},
			},
			LegFR_Foot = {
				k = {
					{ 0, -30, 0, 0 },
				},
			},
		},
	},
	Freeze3 = {
		dur = 1,
		loop = true,
		joints = {
			Hips = {
				p = {
					{ 0, 0, -1.4, 0 },
				},
			},
			Spine1 = {
				k = {
					{ 0, -6, 0, 0 },
				},
			},
			Neck1 = {
				k = {
					{ 0, -16, 0, 0 },
				},
			},
			Neck2 = {
				k = {
					{ 0, -6, 0, 0 },
				},
			},
			Neck3 = {
				k = {
					{ 0, 18, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 24, 0, -12 },
				},
			},
			Jaw = {
				k = {
					{ 0, -12, 0, 0 },
				},
			},
			LegFL_Upper = {
				k = {
					{ 0, -8, 0, 0 },
				},
			},
			LegFR_Upper = {
				k = {
					{ 0, -8, 0, 0 },
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

local ORDER = { "Idle", "Walk", "Detect", "Chase", "Roar", "Freeze2", "Attack", "Fly", "Death" }
local LABELS = {
	Idle = "Acechar", Walk = "Caminar", Run = "Correr", Fly = "Volar", TakeOff = "Despegar",
	Landing = "Aterrizar", Attack = "Atacar", Roar = "Sonreír", Death = "Morir",
	Detect = "Detectar", Chase = "Perseguir", Freeze2 = "Inmóvil",
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
	elseif airborne and name ~= "Fly" and name ~= "Death" then
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
	Brain = [=======[
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
]=======],
	Stalker = [=======[
--[[
	ShadowStalker (Script) · ServerScriptService.ShadowStalker

	Un solo Dragón Sombrío para todos los jugadores. El servidor decide (ShadowBrain) dónde está y qué hace;
	los clientes animan los huesos y suavizan el movimiento (ShadowClient), porque Roblox no replica
	Bone.Transform desde el servidor.

	Lo que el servidor publica en el modelo Workspace.ShadowDragonLive (atributos):
	  Root (CFrame)                pivote del dragón sobre el suelo, mirando a -Z
	  Visible, FadeTime, FadeStamp aparecer / desaparecer gradualmente
	  Anim, AnimFade, AnimStamp    animación actual
	  Frozen, Pose, PoseStamp      inmovilidad y postura extraña
	  Tilt                         inclinación de cabeza (grados)
	  SilenceUntil                 hora del servidor hasta la que el ambiente queda en silencio
	  State, TargetUserId          estado y objetivo (para depurar)

	Cada cliente envía 5 veces por segundo el CFrame de su cámara (ShadowGaze) para saber si lo está mirando.
	Sitios para aparecer: partes con la etiqueta "ShadowPerch" o dentro de Workspace.ShadowPerches (junto a
	árboles, rocas, zonas oscuras). Si no hay, busca sitios en el terreno alrededor del jugador, mejor si hay
	objetos cerca que lo tapen.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local folder = ReplicatedStorage:WaitForChild("Dragons"):WaitForChild("ShadowDragon")
local Brain = require(folder:WaitForChild("ShadowBrain"))
local settings = folder:WaitForChild("Settings")
local template = folder:WaitForChild("ShadowDragon") :: Model
local gazeRemote = folder:WaitForChild("ShadowGaze")

if settings:GetAttribute("StalkerEnabled") == false then
	return
end
local DEBUG = settings:GetAttribute("Debug") == true
local MAX_SIGHT = settings:GetAttribute("MaxSightDistance") or 320

-- configuración: los atributos de Settings que coinciden con un valor numérico de Brain.Defaults lo sustituyen
local config = {}
for k, v in pairs(settings:GetAttributes()) do
	if type(Brain.Defaults[k]) == "number" and type(v) == "number" then
		config[k] = v
	end
end
local brain = Brain.new(config, Random.new())

-- el dragón vivo: oculto hasta que el cerebro decide aparecer
local live = template:Clone()
live.Name = "ShadowDragonLive"
local scale = live:GetAttribute("RigScale") or 1
local HEAD_OFFSET = live:GetAttribute("HeadOffset") or Vector3.new(0, 7 * scale, -14 * scale)
local BODY_OFFSET = live:GetAttribute("BodyOffset") or Vector3.new(0, 13 * scale, 0)
for _, d in ipairs(live:GetDescendants()) do
	if d:IsA("BasePart") then
		d.CanCollide = false
		d.CanTouch = false
		d.CanQuery = false
	end
end
local root = CFrame.new(0, -500, 0)
live:SetAttribute("Root", root)
live:SetAttribute("Visible", false)
live:SetAttribute("FadeTime", 0)
live:SetAttribute("FadeStamp", 0)
live:SetAttribute("Anim", "Idle")
live:SetAttribute("AnimFade", 0)
live:SetAttribute("AnimStamp", 0)
live:SetAttribute("Frozen", false)
live:SetAttribute("Pose", "")
live:SetAttribute("PoseStamp", 0)
live:SetAttribute("Tilt", 0)
live:SetAttribute("SilenceUntil", 0)
live.Parent = workspace

local sounds = {}
local body = live:FindFirstChild("Body", true)
if body then
	for _, s in ipairs(body:GetChildren()) do
		if s:IsA("Sound") and s.SoundId ~= "" then
			sounds[s.Name] = s
		end
	end
end

-- miradas de los jugadores (CFrame de cámara reciente)
local gaze = {}
gazeRemote.OnServerEvent:Connect(function(player, cf)
	if typeof(cf) == "CFrame" then
		gaze[player] = { cf = cf, t = os.clock() }
	end
end)
Players.PlayerRemoving:Connect(function(p)
	gaze[p] = nil
end)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false
local function refreshFilter()
	local list = { live }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	rayParams.FilterDescendantsInstances = list
end

local function hrpOf(p)
	local c = p.Character
	local h = c and c:FindFirstChild("HumanoidRootPart")
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if h and hum and hum.Health > 0 then
		return h
	end
	return nil
end

local function cameraOf(p)
	local g = gaze[p]
	if g and os.clock() - g.t < 1.5 then
		return g.cf.Position, g.cf.LookVector
	end
	local h = hrpOf(p)
	if h then
		return h.Position + Vector3.new(0, 1.5, 0), h.CFrame.LookVector
	end
	return nil
end

-- ¿ve el jugador p el punto (cabeza o cuerpo) directamente y sin obstáculos?
local function sees(p, points, visible)
	if not visible then
		return false, 180
	end
	local pos, look = cameraOf(p)
	if not pos then
		return false, 180
	end
	local best = 180
	for _, pt in ipairs(points) do
		local dist = (pt - pos).Magnitude
		local ang = Brain.AngleTo(pos, look, pt)
		best = math.min(best, ang)
		-- de cerca el dragón ocupa más pantalla: el cono crece con su tamaño aparente
		local cone = math.max(brain.cfg.LookAngle, math.deg(math.atan2(6 * scale, dist)))
		if dist < MAX_SIGHT and ang < cone then
			local hit = workspace:Raycast(pos, pt - pos, rayParams)
			if not hit or (hit.Position - pt).Magnitude < 2 then
				return true, best
			end
		end
	end
	return false, best
end

local function groundAt(x, z, fromY)
	local hit = workspace:Raycast(Vector3.new(x, fromY + 60, z), Vector3.new(0, -260, 0), rayParams)
	if hit and hit.Normal.Y > 0.6 and hit.Material ~= Enum.Material.Water then
		return hit.Position
	end
	return nil
end

local function coverAt(pos)
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = rayParams.FilterDescendantsInstances
	local n = 0
	for _, part in ipairs(workspace:GetPartBoundsInRadius(pos, 12 * scale, op)) do
		if part ~= workspace.Terrain and part.Size.Y > 4 then
			n += 1
		end
	end
	return n
end

local target: Player? = nil
local lastTargeted = {}
local function pickTarget()
	local best, bestScore = nil, -math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if hrpOf(p) then
			local score = math.random() + (os.clock() - (lastTargeted[p] or -1e6)) / 600
			if score > bestScore then
				best, bestScore = p, score
			end
		end
	end
	target = best
	if best then
		lastTargeted[best] = os.clock()
	end
	live:SetAttribute("TargetUserId", best and best.UserId or 0)
end

local visible = false
local function headPoint(cf)
	return cf:PointToWorldSpace(HEAD_OFFSET), cf:PointToWorldSpace(BODY_OFFSET)
end

local function place(kind: string): boolean
	if not target then
		return false
	end
	local h = hrpOf(target)
	if not h then
		return false
	end
	local tpos = h.Position
	local camPos, camLook = cameraOf(target)
	local candidates = {}
	local perches = CollectionService:GetTagged("ShadowPerch")
	local pf = workspace:FindFirstChild("ShadowPerches")
	if pf then
		for _, d in ipairs(pf:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(perches, d)
			end
		end
	end
	for _, part in ipairs(perches) do
		local g = groundAt(part.Position.X, part.Position.Z, part.Position.Y)
		if g then
			table.insert(candidates, { pos = g, cover = 3 })
		end
	end
	local here = root.Position
	for _ = 1, 28 do
		local a = math.random() * math.pi * 2
		local d = kind == "far" and (60 + math.random() * 110) or (brain.cfg.VanishDistance + 8 + math.random() * 40)
		local c = tpos + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		if kind == "closer" then -- más cerca, pero desde el lado donde ya estaba
			local dir = (here - tpos) * Vector3.new(1, 0, 1)
			if dir.Magnitude > 1 then
				c = tpos + (dir.Unit:Lerp(Vector3.new(math.cos(a), 0, math.sin(a)), 0.35)).Unit * d
			end
		end
		local g = groundAt(c.X, c.Z, tpos.Y)
		if g then
			table.insert(candidates, { pos = g })
		end
	end
	local best, bestScore = nil, 0
	for _, c in ipairs(candidates) do
		local cf = CFrame.lookAt(c.pos, Vector3.new(tpos.X, c.pos.Y, tpos.Z))
		local hp, bp = headPoint(cf)
		local inView = false
		for _, p in ipairs(Players:GetPlayers()) do
			if sees(p, { hp, bp }, true) then
				inView = true
				break
			end
		end
		local dist = (c.pos - tpos).Magnitude
		local ang = camPos and Brain.AngleTo(camPos, camLook, hp) or 90
		local s = Brain.ScoreSpot(kind, dist, ang, inView, c.cover or coverAt(c.pos), brain.cfg)
		if s > bestScore then
			best, bestScore = cf, s
		end
	end
	if not best then
		return false
	end
	root = best
	live:SetAttribute("Root", root)
	return true
end

local stamp = 0
local moveSpeed = 0
local function apply(cmds)
	for _, c in ipairs(cmds) do
		local k = c[1]
		stamp += 1
		if DEBUG then
			print("[ShadowStalker]", brain.state, k, tostring(c[2]), tostring(c[3]))
		end
		if k == "newTarget" then
			pickTarget()
		elseif k == "place" then
			if not place(c[2]) then
				brain:PlaceFailed()
				visible = false
				live:SetAttribute("Visible", false)
				return
			end
		elseif k == "appear" or k == "vanish" then
			visible = k == "appear"
			live:SetAttribute("FadeTime", c[2])
			live:SetAttribute("Visible", visible)
			live:SetAttribute("FadeStamp", stamp)
			if sounds.Breath then
				sounds.Breath.Playing = visible
			end
		elseif k == "anim" then
			live:SetAttribute("Anim", c[2])
			live:SetAttribute("AnimFade", c[3] or 0.3)
			live:SetAttribute("AnimStamp", stamp)
		elseif k == "freeze" then
			live:SetAttribute("Frozen", c[2])
		elseif k == "pose" then
			live:SetAttribute("Pose", c[2])
			live:SetAttribute("PoseStamp", stamp)
		elseif k == "move" then
			moveSpeed = c[2] * scale
		elseif k == "tilt" then
			live:SetAttribute("Tilt", c[2])
		elseif k == "silence" then
			live:SetAttribute("SilenceUntil", workspace:GetServerTimeNow() + c[2])
			if sounds.Breath then
				sounds.Breath.Playing = false
				task.delay(c[2], function()
					sounds.Breath.Playing = visible
				end)
			end
		elseif k == "sound" then
			local s = sounds[c[2]]
			if s then
				s.PlaybackSpeed = 0.9 + math.random() * 0.2
				s:Play()
			end
		end
	end
end

-- movimiento: hacia el objetivo, girando con un límite y pegado al suelo
local groundTimer = 0
local blocked = false
RunService.Heartbeat:Connect(function(dt)
	if moveSpeed <= 0 or not target then
		return
	end
	local h = hrpOf(target)
	if not h then
		return
	end
	local pos = root.Position
	local flat = (h.Position - pos) * Vector3.new(1, 0, 1)
	if flat.Magnitude < 1 then
		return
	end
	local cur = root.LookVector * Vector3.new(1, 0, 1)
	local maxTurn = math.rad(moveSpeed > 15 * scale and 220 or 70) * dt
	local ang = math.atan2(cur:Cross(flat.Unit).Y, cur:Dot(flat.Unit))
	local yaw = math.clamp(ang, -maxTurn, maxTurn)
	local dir = (CFrame.Angles(0, yaw, 0) * cur).Unit
	groundTimer -= dt
	if groundTimer <= 0 then
		groundTimer = 0.2
		-- sin pathfinding: si hay un obstáculo delante (pared, tronco), se queda quieto en vez de atravesarlo
		blocked = workspace:Raycast(pos + Vector3.new(0, 3 * scale, 0), dir * 7 * scale, rayParams) ~= nil
	end
	if blocked then
		root = CFrame.lookAt(pos, pos + dir)
		return
	end
	pos += dir * moveSpeed * dt
	if groundTimer >= 0.19 then
		local g = groundAt(pos.X, pos.Z, pos.Y)
		if g then
			pos = Vector3.new(pos.X, g.Y, pos.Z)
		end
	end
	root = CFrame.lookAt(pos, pos + dir)
end)

-- publicar la posición 10 veces por segundo (solo si cambió) y pensar
local TICK = 0.1
local acc, lastPublished = 0, root
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < TICK then
		return
	end
	local step = acc
	acc = 0
	if root ~= lastPublished then
		lastPublished = root
		live:SetAttribute("Root", root)
	end
	refreshFilter()
	if target and (not target.Parent or not hrpOf(target)) then
		target = nil
	end
	local P = { hasTarget = target ~= nil, dist = math.huge, targetAngle = 180, targetSees = false, anySees = false }
	local hp, bp = headPoint(root)
	if target then
		P.dist = (hrpOf(target).Position - root.Position).Magnitude
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local s, ang = sees(p, { hp, bp }, visible)
		if s then
			P.anySees = true
		end
		if p == target then
			P.targetSees, P.targetAngle = s, ang
		end
	end
	if not target and brain.state == "Absent" then
		P.hasTarget = #Players:GetPlayers() > 0 -- en ausencia basta con que haya alguien; newTarget lo elige
	end
	apply(brain:Update(step, P))
	live:SetAttribute("State", brain.state)
end)
]=======],
	Client = [=======[
--[[
	ShadowClient (LocalScript) · StarterPlayer.StarterPlayerScripts.ShadowClient

	Parte visual y sonora del Dragón Sombrío en cada jugador. El servidor (ShadowStalker) decide;
	aquí se anima el rig, se suaviza el movimiento, se hacen los fundidos y suena el ambiente.

	  · envía el CFrame de la cámara 5 veces por segundo (para saber si lo miras)
	  · reproduce la animación que indica el servidor; si está "Frozen", congela la pose tal como está
	  · la cabeza te sigue despacio (cada jugador siente que lo mira a él) y se ladea según "Tilt"
	  · aparición / desaparición gradual: los ojos se encienden antes que el cuerpo y se apagan después
	  · rendimiento: invisible = animador en pausa; lejos = menos actualizaciones por segundo
	  · sonido: crujidos cerca, ambiente difícil de localizar y silencios repentinos
	  · visión nocturna de prueba con la tecla N (solo si Settings.ProvideNightVision = true)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local Dragons = ReplicatedStorage:WaitForChild("Dragons")
local DragonAnimator = require(Dragons:WaitForChild("DragonAnimator"))
local folder = Dragons:WaitForChild("ShadowDragon")
local animations = require(folder:WaitForChild("Animations"))
local settings = folder:WaitForChild("Settings")
local gazeRemote = folder:WaitForChild("ShadowGaze")
local ambientFolder = folder:FindFirstChild("AmbientSounds")
local player = Players.LocalPlayer

local LOOK = { Head = "Head", Neck = "Neck2", NeckShare = 0.45, MaxYaw = 85, MaxPitch = 35, RestPitch = -5, Speed = 1.1 }

-- mirada de la cámara al servidor (UnreliableRemoteEvent: barato y sin cola)
task.spawn(function()
	while true do
		local cam = workspace.CurrentCamera
		if cam then
			gazeRemote:FireServer(cam.CFrame)
		end
		task.wait(0.2)
	end
end)

local live = workspace:WaitForChild("ShadowDragonLive") :: Model
local scale = live:GetAttribute("RigScale") or 1
local animator = DragonAnimator.new(live, animations)
animator:Play(live:GetAttribute("Anim") or "Idle", 0)
animator:SetLookTarget(function()
	local cam = workspace.CurrentCamera
	return cam and cam.CFrame.Position
end, LOOK)
animator:SetHeadTilt(0, 1.2)

-- piezas: mallas (fundido), puntos de ojos (siguen al hueso Head) y dientes
local meshes, eyes, follow = {}, {}, {}
for _, d in ipairs(live:GetDescendants()) do
	if d:IsA("MeshPart") then
		table.insert(meshes, d)
	end
end
for _, p in ipairs(live:GetChildren()) do
	if p:IsA("BasePart") and p:GetAttribute("Offset") then
		local bone = live:FindFirstChild(p:GetAttribute("Bone"), true)
		if bone then
			table.insert(follow, { p, bone, p:GetAttribute("Offset") })
		end
		if p:GetAttribute("Kind") == "eye" then
			table.insert(eyes, p)
		end
	end
end

-- la sonrisa brilla en la oscuridad (Neon tenue); el color controla la intensidad
local teeth = live:FindFirstChild("Teeth", true)
if teeth and teeth:IsA("BasePart") and settings:GetAttribute("TeethGlow") ~= false then
	teeth.Material = Enum.Material.Neon
	teeth.Color = settings:GetAttribute("TeethGlowColor") or Color3.fromRGB(128, 124, 116)
end

-- visibilidad: 0 = invisible, 1 = visible
local vis, visGoal, fadeTime = 0, 0, 1
local function applyVisibility()
	for _, m in ipairs(meshes) do
		m.LocalTransparencyModifier = 1 - vis
	end
	local eyeVis = math.clamp(vis * 1.6, 0, 1) -- los ojos llegan antes y se van después
	for _, e in ipairs(eyes) do
		e.LocalTransparencyModifier = 1 - eyeVis
		local light = e:FindFirstChildOfClass("PointLight")
		if light then
			light.Enabled = eyeVis > 0.02
			light.Brightness = (e:GetAttribute("LightBrightness") or 1.2) * eyeVis
		end
	end
end
local function onVisible()
	visGoal = live:GetAttribute("Visible") and 1 or 0
	fadeTime = math.max(live:GetAttribute("FadeTime") or 1, 0.01)
	if fadeTime <= 0.011 then
		vis = visGoal
	end
end
live:GetAttributeChangedSignal("FadeStamp"):Connect(onVisible)
live:GetAttributeChangedSignal("Visible"):Connect(onVisible)
onVisible()
vis = visGoal
applyVisibility()

-- animación, inmovilidad y posturas
local posing = false
local function refreshPause()
	animator.Paused = vis <= 0.001 or (live:GetAttribute("Frozen") and not posing)
end
live:GetAttributeChangedSignal("AnimStamp"):Connect(function()
	animator:Play(live:GetAttribute("Anim") or "Idle", live:GetAttribute("AnimFade") or 0.3)
end)
live:GetAttributeChangedSignal("PoseStamp"):Connect(function()
	local pose = live:GetAttribute("Pose")
	if pose and pose ~= "" then
		posing = true
		animator:Play(pose, 0.3)
		task.delay(0.4, function()
			posing = false
		end)
	end
end)
live:GetAttributeChangedSignal("Tilt"):Connect(function()
	animator:SetHeadTilt(live:GetAttribute("Tilt") or 0, 1.2)
end)

-- movimiento suave hacia el Root que publica el servidor
local current = live:GetAttribute("Root") or live:GetPivot()
live:PivotTo(current)

-- sonidos
local closeCreak = live:FindFirstChild("Creak", true)
local ambient = {}
if ambientFolder then
	for _, s in ipairs(ambientFolder:GetChildren()) do
		if s:IsA("Sound") and s.SoundId ~= "" then
			table.insert(ambient, s)
		end
	end
end
local emitter = Instance.new("Part")
emitter.Name = "ShadowAmbientEmitter"
emitter.Anchored = true
emitter.CanCollide = false
emitter.CanQuery = false
emitter.CanTouch = false
emitter.Transparency = 1
emitter.Size = Vector3.one
emitter.Parent = workspace

local silenced = false
local savedVolumes = {}
local function setSilence(on: boolean)
	if on == silenced then
		return
	end
	silenced = on
	local groupName = settings:GetAttribute("AmbientGroupName") or "Ambient"
	local groups = {}
	for _, g in ipairs(SoundService:GetDescendants()) do
		if g:IsA("SoundGroup") and g.Name == groupName then
			table.insert(groups, g)
		end
	end
	for _, g in ipairs(groups) do
		if on then
			savedVolumes[g] = g.Volume
			TweenService:Create(g, TweenInfo.new(0.12), { Volume = 0 }):Play()
		elseif savedVolumes[g] then
			TweenService:Create(g, TweenInfo.new(2.5), { Volume = savedVolumes[g] }):Play()
		end
	end
	for _, s in ipairs(emitter:GetChildren()) do
		if s:IsA("Sound") then
			s:Stop()
		end
	end
end

local nextAmbient = os.clock() + 20 + math.random() * 40
local nextCreak = os.clock() + 5
local function ambientTick(now, myPos, dragonDist)
	if silenced or #ambient == 0 or not myPos then
		return
	end
	if now >= nextAmbient then
		-- más frecuente cuando el dragón está presente; siempre en un punto distinto alrededor
		nextAmbient = now + (vis > 0.5 and (12 + math.random() * 25) or (35 + math.random() * 60))
		local a = math.random() * math.pi * 2
		local d = 25 + math.random() * 40
		emitter.Position = myPos + Vector3.new(math.cos(a) * d, math.random() * 8 - 2, math.sin(a) * d)
		local s = ambient[math.random(#ambient)]:Clone()
		s.PlaybackSpeed = 0.85 + math.random() * 0.25
		s.Parent = emitter
		s:Play()
		s.Ended:Once(function()
			s:Destroy()
		end)
	end
	if closeCreak and vis > 0.5 and dragonDist < 55 * scale and now >= nextCreak then
		nextCreak = now + 4 + math.random() * 9
		closeCreak.PlaybackSpeed = 0.8 + math.random() * 0.3
		closeCreak:Play()
	end
end

-- visión nocturna de prueba (el juego final puede usar la suya)
if settings:GetAttribute("ProvideNightVision") then
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "ShadowNightVision"
	cc.Enabled = false
	cc.TintColor = Color3.fromRGB(150, 255, 160)
	cc.Brightness = 0.18
	cc.Contrast = 0.15
	cc.Saturation = -0.6
	cc.Parent = Lighting
	local savedExposure = Lighting.ExposureCompensation
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.N then
			cc.Enabled = not cc.Enabled
			Lighting.ExposureCompensation = cc.Enabled and savedExposure + 2.2 or savedExposure
		end
	end)
end

RunService.RenderStepped:Connect(function(dt)
	-- fundido
	if vis ~= visGoal then
		local stepV = dt / fadeTime
		vis = visGoal > vis and math.min(visGoal, vis + stepV) or math.max(visGoal, vis - stepV)
		applyVisibility()
	end
	-- posición
	local goal = live:GetAttribute("Root") or current
	if (goal.Position - current.Position).Magnitude > 25 * scale or vis <= 0.001 then
		current = goal -- teletransporte o invisible: salto directo
	else
		current = current:Lerp(goal, 1 - math.exp(-dt * 8))
	end
	if vis > 0.001 then
		live:PivotTo(current)
		for _, e in ipairs(follow) do
			e[1].CFrame = e[2].TransformedWorldCFrame * e[3]
		end
	end
	-- rendimiento: menos actualizaciones lejos de la cámara
	local cam = workspace.CurrentCamera
	local camDist = cam and (cam.CFrame.Position - current.Position).Magnitude or 0
	animator.UpdateInterval = camDist < 90 * scale and 0 or (camDist < 220 * scale and 1 / 20 or 1 / 10)
	refreshPause()
	-- sonido
	local now = os.clock()
	setSilence(workspace:GetServerTimeNow() < (live:GetAttribute("SilenceUntil") or 0))
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	ambientTick(now, hrp and hrp.Position, hrp and (hrp.Position - current.Position).Magnitude or math.huge)
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
for _, name in ipairs({ "Body", "Skull", "Teeth", "WingL", "WingR" }) do
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
	dot.Size = Vector3.one * 0.1 * scale
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
	dot:SetAttribute("LightBrightness", 1.4)
	-- brillo rojo intenso pero controlado: luz diminuta que solo tiñe la cuenca y el ceño
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 30, 20)
	light.Range = 2.4 * scale
	light.Brightness = 1.4
	light.Shadows = false
	light.Parent = dot
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
model:SetAttribute("Version", 2)
-- puntos de referencia para el servidor (en el espacio del pivote): cabeza y joroba
model:SetAttribute("HeadOffset", model.WorldPivot:PointToObjectSpace(bones.Head.WorldPosition))
model:SetAttribute("BodyOffset", model.WorldPivot:PointToObjectSpace(bones.Chest.WorldPosition))
-- sonidos que salen del cuerpo
for _, name in ipairs({ "Breath", "Creak", "Shriek" }) do
	local snd = Instance.new("Sound")
	snd.Name = name
	snd.SoundId = SOUND_IDS[name]
	snd.Looped = name == "Breath"
	snd.Volume = name == "Breath" and 0.5 or (name == "Shriek" and 0.9 or 0.6)
	snd.RollOffMode = Enum.RollOffMode.InverseTapered
	snd.RollOffMinDistance = 6 * DESIRED_SCALE
	snd.RollOffMaxDistance = (name == "Shriek" and 260 or 120) * DESIRED_SCALE
	snd.Parent = meshes.Body
end
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
	local assetsFolder = ensure(ServerStorage, "DragonAssets")
	if (prev:GetAttribute("Version") or 1) < 2 and not assetsFolder:FindFirstChild("ShadowDragon_v1") then
		prev.Name = "ShadowDragon_v1" -- copia de seguridad de la versión original
		prev.Parent = assetsFolder
	else
		prev:Destroy()
	end
end
model.Parent = folder
local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({
	DisplayName = "Dragón Sombrío", Species = "Umbrafex ridens", Epithet = "La Sonrisa en la Oscuridad",
	WalkSpeed = 8, RunSpeed = 34, FlySpeed = 36, FlyHeight = 7, MaxHealth = 2200, AttackDamage = 70,
	AttackRange = 16, EyePointColor = Color3.fromRGB(255, 20, 12), GrinGlows = true,
	StalkerEnabled = true, Debug = false, ProvideNightVision = PROVIDE_NIGHT_VISION, TeethGlow = true,
	AmbientGroupName = "Ambient", MaxSightDistance = 320,
	-- ajustes del comportamiento (ver ShadowBrain.Defaults): distancias en studs, probabilidades por segundo
	VanishDistance = 38, StalkSpeed = 5, ChaseSpeed = 34, ChaseChance = 0.22, ChaseCooldown = 240,
}) do
	settings:SetAttribute(k, v)
end
putScript(dragons, "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(folder, "ShadowBrain", "ModuleScript", SOURCES.Brain)
local sps = ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts")
putScript(sps, "ShadowClient", "LocalScript", SOURCES.Client)
putScript(game:GetService("ServerScriptService"), "ShadowStalker", "Script", SOURCES.Stalker)
if INSTALL_SHOWCASE then
	putScript(sps, "ShadowShowcase", "LocalScript", SOURCES.Showcase)
elseif sps:FindFirstChild("ShadowShowcase") then
	sps.ShadowShowcase:Destroy()
end
if not folder:FindFirstChild("ShadowGaze") then
	local gaze = Instance.new("UnreliableRemoteEvent")
	gaze.Name = "ShadowGaze"
	gaze.Parent = folder
end
local amb = ensure(folder, "AmbientSounds")
for _, name in ipairs({ "Whisper", "DistantBreath", "Crack" }) do
	local snd = amb:FindFirstChild(name) or Instance.new("Sound")
	snd.Name = name
	snd.SoundId = SOUND_IDS[name]
	snd.Volume = 0.35
	snd.RollOffMode = Enum.RollOffMode.InverseTapered
	snd.RollOffMinDistance = 10
	snd.RollOffMaxDistance = 140
	snd.Parent = amb
end

local assets = ensure(ServerStorage, "DragonAssets")
local bak = assets:FindFirstChild("ShadowDragon_Rig")
if bak then
	bak:Destroy()
end
local backup = model:Clone()
backup.Name = "ShadowDragon_Rig"
backup.Parent = assets

local statue
if INSTALL_SHOWCASE then
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
	statue = showcase:FindFirstChild("ShadowDragon_Preview")
	if statue then
		statue:Destroy()
	end
	statue = model:Clone()
	statue.Name = "ShadowDragon_Preview"
	statue:PivotTo(stage.CFrame * CFrame.new(0, stage.Size.Y / 2, 0) * CFrame.Angles(0, math.rad(180), 0))
	statue.Parent = showcase
end

if source.Parent and #source:GetChildren() == 0 then
	source:Destroy()
end
Selection:Set({ statue or folder })
pcall(function()
	ChangeHistoryService:SetWaypoint("Dragón Sombrío instalado")
end)
print("[Shadow] Listo (v2): " .. #RIG .. " huesos, 5 mallas. Al pulsar Play el dragón aparecerá tras un rato, lejos y en la periferia; si lo miras se queda inmóvil." .. (PROVIDE_NIGHT_VISION and " Tecla N: visión nocturna de prueba." or ""))
