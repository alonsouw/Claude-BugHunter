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
	-- color de ojos según el tipo; el alfa brilla más; el pálido solo enciende los ojos de cerca (EyesNear)
	local eyeColor = model:GetAttribute("EyeColor")
	e.eyesNear = model:GetAttribute("EyesNear") or 0
	for _, ey in ipairs(e.eyes) do
		local l = ey[1]:FindFirstChildOfClass("PointLight")
		if eyeColor then
			ey[1].Color = eyeColor
			if l then
				l.Color = eyeColor
			end
		end
		if l and model:GetAttribute("Alpha") then
			l.Brightness *= 1.6
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
			local eyeOn = e.eyesNear <= 0 or d < e.eyesNear
			for _, ey in ipairs(e.eyes) do
				ey[1].CFrame = ey[2].TransformedWorldCFrame * ey[3]
				if e.eyesNear > 0 then
					ey[1].LocalTransparencyModifier = eyeOn and (1 - e.vis) or 1
					local l = ey[1]:FindFirstChildOfClass("PointLight")
					if l then
						l.Enabled = eyeOn
					end
				end
			end
		end
		e.animator.Paused = not visible
		e.animator.UpdateInterval = d < 60 and 0 or (d < 160 and 1 / 20 or 1 / 8)
	end
end)
