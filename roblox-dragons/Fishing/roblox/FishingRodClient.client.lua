--[[
	FishingRodClient (LocalScript) · dentro del Tool FishingRod

	Lo que ve y hace el jugador con la caña en la mano:
	  · clic en el agua: lanza (manda el punto al servidor; FishingService comprueba que es agua y que está cerca)
	  · clic mientras pica: clava el anzuelo · clic mientras recoges: recoge (clic rápido)
	  · interfaz: un mensaje con lo que pasa y la barra para recoger (los avisos los muestra FishingHud)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local tool = script.Parent
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Fishing"):WaitForChild("Remote")
local mouse = player:GetMouse()

local state = "Idle"
local gui, msg, bar, fill

local MESSAGES = {
	Idle = "Haz clic en el agua para lanzar",
	Casting = "",
	Waiting = "Espera a que pique...",
	Bite = "¡PICA! ¡HAZ CLIC!",
	Reeling = "¡RECOGE! · CLIC RÁPIDO",
}

local function makeGui()
	gui = Instance.new("ScreenGui")
	gui.Name = "FishingGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -110)
	frame.Size = UDim2.fromOffset(360, 74)
	frame.BackgroundTransparency = 1
	frame.Parent = gui
	msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, 0, 0, 30)
	msg.BackgroundTransparency = 1
	msg.Font = Enum.Font.GothamBold
	msg.TextSize = 22
	msg.TextColor3 = Color3.fromRGB(245, 235, 210)
	msg.TextStrokeTransparency = 0.3
	msg.Parent = frame
	bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(20, 38)
	bar.Size = UDim2.new(1, -40, 0, 18)
	bar.BackgroundColor3 = Color3.fromRGB(18, 26, 30)
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 84, 90)
	stroke.Parent = bar
	fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0.3, 1)
	fill.BackgroundColor3 = Color3.fromRGB(130, 200, 100)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	gui.Parent = player:WaitForChild("PlayerGui")
end

local function refresh()
	if not gui then
		return
	end
	msg.Text = MESSAGES[state] or ""
	msg.TextColor3 = state == "Bite" and Color3.fromRGB(255, 90, 70) or Color3.fromRGB(245, 235, 210)
	msg.TextSize = state == "Bite" and 28 or 22
	bar.Visible = state == "Reeling"
end

local function aimPoint()
	local cam = workspace.CurrentCamera
	if not cam then
		return nil
	end
	local ray = cam:ViewportPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	params.IgnoreWater = false   -- el agua de Terrain cuenta como blanco
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 400, params)
	return hit and hit.Position or nil
end

tool.Equipped:Connect(function()
	if not gui then
		makeGui()
	end
	state = "Idle"
	refresh()
end)
tool.Unequipped:Connect(function()
	remote:FireServer("cancel")
	if gui then
		gui:Destroy()
		gui = nil
	end
end)
tool.Activated:Connect(function()
	if state == "Idle" then
		remote:FireServer("cast", aimPoint())
	elseif state == "Waiting" or state == "Bite" then
		remote:FireServer("hook")
	elseif state == "Reeling" then
		remote:FireServer("reel")
	end
end)

remote.OnClientEvent:Connect(function(kind, value)
	if kind == "state" then
		state = value
		refresh()
	elseif kind == "progress" and fill then
		TweenService:Create(fill, TweenInfo.new(0.1), { Size = UDim2.fromScale(math.clamp(value / 100, 0, 1), 1) }):Play()
		fill.BackgroundColor3 = value < 25 and Color3.fromRGB(220, 90, 60) or Color3.fromRGB(130, 200, 100)
	end
end)
