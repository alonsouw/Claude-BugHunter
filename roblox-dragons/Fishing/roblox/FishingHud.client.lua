--[[
	FishingHud (LocalScript) · StarterPlayer.StarterPlayerScripts.FishingHud
	Muestra los avisos de la pesca («¡Has pescado: Trucha!», «¡Qué rico!: +25 de vida»…) aunque no lleves la caña.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Fishing"):WaitForChild("Remote")

local gui = Instance.new("ScreenGui")
gui.Name = "FishingHud"
gui.ResetOnSpawn = false
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 90)
label.Size = UDim2.fromOffset(520, 32)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextSize = 20
label.TextColor3 = Color3.fromRGB(255, 214, 120)
label.TextStrokeTransparency = 0.3
label.TextTransparency = 1
label.TextStrokeTransparency = 1
label.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

local serial = 0
remote.OnClientEvent:Connect(function(kind, text)
	if kind ~= "toast" then
		return
	end
	serial += 1
	local mine = serial
	label.Text = text
	label.TextTransparency, label.TextStrokeTransparency = 0, 0.3
	task.delay(2.5, function()
		if mine == serial then
			TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end)
