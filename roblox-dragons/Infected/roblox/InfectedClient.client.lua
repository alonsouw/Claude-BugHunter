--[[
	InfectedClient (LocalScript) · StarterPlayer.StarterPlayerScripts.InfectedClient

	Anima a los infectados en cada jugador: lee el atributo Anim que publica el servidor y mueve sus Motor6D con
	DragonAnimator (Roblox no replica Motor6D.Transform desde el servidor). Los cuerpos los mueve la física del
	servidor; aquí solo se anima. Rendimiento: lejos se anima menos veces por segundo y muy lejos se pausa.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DragonAnimator = require(ReplicatedStorage:WaitForChild("Dragons"):WaitForChild("DragonAnimator"))
local animations = require(ReplicatedStorage:WaitForChild("Creatures"):WaitForChild("Infected"):WaitForChild("Animations"))
local container = workspace:WaitForChild("Infected")
local entries = {}

local function setup(model)
	if entries[model] or not model:IsA("Model") then
		return
	end
	local e = { model = model }
	e.animator = DragonAnimator.new(model, animations)
	e.animator:Play(model:GetAttribute("Anim") or "Idle", 0)
	model:GetAttributeChangedSignal("AnimStamp"):Connect(function()
		e.animator:Play(model:GetAttribute("Anim"), model:GetAttribute("AnimFade") or 0.3)
	end)
	entries[model] = e
	model.Destroying:Connect(function()
		e.animator:Destroy()
		entries[model] = nil
	end)
end

for _, m in ipairs(container:GetChildren()) do
	task.spawn(setup, m)
end
container.ChildAdded:Connect(function(m)
	m:WaitForChild("HumanoidRootPart", 5)
	setup(m)
end)

RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	for model, e in pairs(entries) do
		local root = model.PrimaryPart
		if root then
			local d = (root.Position - camPos).Magnitude
			e.animator.Paused = d > 400
			e.animator.UpdateInterval = d < 60 and 0 or (d < 160 and 1 / 20 or 1 / 8)
		end
	end
end)
