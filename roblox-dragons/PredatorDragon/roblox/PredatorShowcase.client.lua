--[[
	PredatorShowcase (LocalScript) · StarterPlayer.StarterPlayerScripts.PredatorShowcase

	Vitrina local del Dragón Depredador:
	  · noche cerrada con bloom: en la oscuridad solo se ven dos puntos blancos diminutos donde
	    estarían los ojos (no tiene ojos); de día son casi imperceptibles (tecla L alterna día/noche)
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
local LOOK = { Head = "Head", Neck = "Neck2", NeckShare = 0.4, MaxYaw = 80, MaxPitch = 35, RestPitch = -22, Speed = 4 }
local DOT_DAY, DOT_NIGHT = 0.93, 0

-- Noche: guarda la iluminación original para poder volver al día
local saved = {
	ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient, FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd,
	ExposureCompensation = Lighting.ExposureCompensation, EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
}
local bloom = Instance.new("BloomEffect")
bloom.Name = "PredatorGazeBloom"
bloom.Intensity = 0.9
bloom.Size = 12
bloom.Threshold = 0.95
local night = false
local dragon: Model? = nil
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
	for _, p in ipairs(model:GetChildren()) do   -- ojos y punto de goteo siguen a su hueso
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
		-- gore: charco de sangre que se extiende bajo el cuerpo
		local scale = dragon:GetAttribute("RigScale") or 1
		local pool = Instance.new("Part")
		pool.Name = "BloodPool"
		pool.Shape = Enum.PartType.Cylinder
		pool.Anchored = true
		pool.CanCollide = false
		pool.CanQuery = false
		pool.Material = Enum.Material.SmoothPlastic
		pool.Reflectance = 0.18
		pool.Color = Color3.fromRGB(62, 3, 7)
		pool.Size = Vector3.new(0.06, 0.5, 0.5)
		local ground = stage.CFrame * CFrame.new(0, stage.Size.Y / 2 + 0.03, 0)
		pool.CFrame = CFrame.new(dragon:GetPivot().Position.X, ground.Y, dragon:GetPivot().Position.Z) * CFrame.Angles(0, 0, math.rad(90))
		pool.Parent = showcase
		TweenService:Create(pool, TweenInfo.new(2.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.06, 14 * scale, 11 * scale) }):Play()
		task.delay(3.4, function()
			TweenService:Create(pool, TweenInfo.new(0.8), { Transparency = 1 }):Play()
			task.delay(0.9, function()
				pool:Destroy()
			end)
		end)
		for _, d in ipairs(dragon:GetDescendants()) do
			if d:IsA("ParticleEmitter") then
				d.Rate = 18 -- la sangre sigue cayendo mientras muere
			end
		end
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
