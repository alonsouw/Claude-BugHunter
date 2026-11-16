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
