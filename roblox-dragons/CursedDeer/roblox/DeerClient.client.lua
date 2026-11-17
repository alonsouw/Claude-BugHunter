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
