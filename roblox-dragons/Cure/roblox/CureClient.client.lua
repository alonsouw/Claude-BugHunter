--[[
	CureClient (LocalScript) · StarterPlayer.StarterPlayerScripts.CureClient

	  · Recetario: botón «Cura 2/7» arriba a la derecha; al pulsarlo (o con la tecla R) se ve qué falta y dónde buscarlo.
	  · Avisos («Ha aparecido: Perla negra», «X ha echado al caldero…»).
	  · Pantalla final al usar el Remedio del Alba.
	  · Anima al dragón de la guarida con DragonAnimator (Roblox no replica Motor6D/Bone.Transform desde el servidor).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild("Cure")
local RECIPE = require(folder:WaitForChild("Recipe"))
local progressCfg = folder:WaitForChild("Progress")
local remote = folder:WaitForChild("Remote")

local GOLD = Color3.fromRGB(255, 214, 120)
local INK = Color3.fromRGB(236, 228, 210)
local DIM = Color3.fromRGB(150, 142, 132)

local gui = Instance.new("ScreenGui")
gui.Name = "CureHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Gotham
	l.TextColor3 = INK
	l.TextXAlignment = Enum.TextXAlignment.Left
	for k, v in pairs(props) do
		l[k] = v
	end
	l.Parent = parent
	return l
end

-- botón y panel del recetario
local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(1, 0)
button.Position = UDim2.new(1, -16, 0, 60)
button.Size = UDim2.fromOffset(150, 40)
button.BackgroundColor3 = Color3.fromRGB(28, 22, 18)
button.BackgroundTransparency = 0.15
button.Font = Enum.Font.GothamBold
button.TextSize = 18
button.TextColor3 = GOLD
button.AutoButtonColor = true
button.Parent = gui
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -16, 0, 108)
panel.Size = UDim2.fromOffset(360, 70 + #RECIPE * 52)
panel.BackgroundColor3 = Color3.fromRGB(20, 16, 14)
panel.BackgroundTransparency = 0.08
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local pad = Instance.new("UIPadding", panel)
pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop = UDim.new(0, 14), UDim.new(0, 14), UDim.new(0, 10)
label(panel, { Text = "Remedio del Alba", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = GOLD, Size = UDim2.new(1, 0, 0, 26) })
local stageLabel = label(panel, { Text = "", TextSize = 14, TextColor3 = DIM, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 28), TextWrapped = true })
local rows = {}
for i, r in ipairs(RECIPE) do
	local y = 56 + (i - 1) * 52
	local sw = Instance.new("Frame")
	sw.Position = UDim2.fromOffset(0, y + 4)
	sw.Size = UDim2.fromOffset(14, 14)
	sw.BackgroundColor3 = Color3.fromRGB(r.color[1], r.color[2], r.color[3])
	sw.BorderSizePixel = 0
	sw.Parent = panel
	local name = label(panel, { Text = r.name, Font = Enum.Font.GothamBold, TextSize = 16, Position = UDim2.fromOffset(22, y), Size = UDim2.new(1, -90, 0, 22) })
	local count = label(panel, { Text = "", Font = Enum.Font.GothamBold, TextSize = 16, Position = UDim2.new(1, -66, 0, y), Size = UDim2.fromOffset(66, 22), TextXAlignment = Enum.TextXAlignment.Right })
	local hint = label(panel, { Text = r.hint, TextSize = 13, TextColor3 = DIM, Position = UDim2.fromOffset(22, y + 22), Size = UDim2.new(1, -22, 0, 20), TextWrapped = true })
	rows[r.id] = { name = name, count = count, hint = hint, need = r.need }
end

local STAGE = {
	Collecting = "Busca los ingredientes y échalos al caldero (E).",
	Ready = "¡Está todo! Ve al caldero y prepara la cura.",
	Done = "¡El Remedio del Alba está listo en el caldero!",
	Used = "La infección se ha curado.",
}
local function refresh()
	local done, total = folder:GetAttribute("Done") or 0, folder:GetAttribute("Total") or #RECIPE
	local stage = folder:GetAttribute("Stage") or "Collecting"
	button.Text = stage == "Used" and "✓ Curado" or ("Cura  %d/%d"):format(done, total)
	if stage == "Brewing" then
		stageLabel.Text = ("Preparando la cura... %d %%"):format(math.floor((folder:GetAttribute("BrewFraction") or 0) * 100))
	else
		stageLabel.Text = STAGE[stage] or ""
	end
	for id, row in pairs(rows) do
		local have = progressCfg:GetAttribute(id) or 0
		local full = have >= row.need
		row.count.Text = full and "✓" or ("%d/%d"):format(have, row.need)
		row.count.TextColor3 = full and Color3.fromRGB(150, 220, 120) or INK
		row.name.TextColor3 = full and DIM or INK
	end
end
for _, a in ipairs({ "Done", "Total", "Stage", "BrewFraction" }) do
	folder:GetAttributeChangedSignal(a):Connect(refresh)
end
progressCfg.AttributeChanged:Connect(refresh)
refresh()
button.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.R then
		panel.Visible = not panel.Visible
	end
end)

-- avisos
local toastLabel = label(gui, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 120), Size = UDim2.fromOffset(640, 30),
	Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = GOLD, TextStrokeTransparency = 1, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center })
local serial = 0
local function showToast(text)
	serial += 1
	local mine = serial
	toastLabel.Text = text
	toastLabel.TextTransparency, toastLabel.TextStrokeTransparency = 0, 0.3
	task.delay(3.5, function()
		if mine == serial then
			TweenService:Create(toastLabel, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- pantalla final
local function showEnding(who)
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.fromRGB(255, 236, 190)
	f.BackgroundTransparency = 1
	f.Parent = gui
	local title = label(f, { Text = "EL REMEDIO DEL ALBA", Font = Enum.Font.GothamBlack, TextSize = 48, TextColor3 = Color3.fromRGB(90, 56, 20),
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.new(1, -40, 0, 60), TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1, TextScaled = true })
	local sub = label(f, { Text = ("La infección se ha curado. Gracias, %s."):format(who), TextSize = 22, TextColor3 = Color3.fromRGB(110, 76, 36),
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.54), Size = UDim2.new(1, -40, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1 })
	local tin = TweenInfo.new(1.5)
	TweenService:Create(f, tin, { BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(title, tin, { TextTransparency = 0 }):Play()
	TweenService:Create(sub, tin, { TextTransparency = 0 }):Play()
	local dawn = folder:FindFirstChild("Dawn")
	if dawn and dawn:IsA("Sound") and dawn.SoundId ~= "" then
		dawn:Play()
	end
	task.delay(9, function()
		local tout = TweenInfo.new(2)
		TweenService:Create(f, tout, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(title, tout, { TextTransparency = 1 }):Play()
		TweenService:Create(sub, tout, { TextTransparency = 1 }):Play()
		task.delay(2.2, function()
			f:Destroy()
		end)
	end)
end

remote.OnClientEvent:Connect(function(kind, value)
	if kind == "toast" then
		showToast(value)
	elseif kind == "ending" then
		showEnding(value)
	end
end)
gui.Parent = player:WaitForChild("PlayerGui")

-- animación del dragón de la guarida
local bossFolder = workspace:WaitForChild("CureBoss")
local function animate(model)
	if not model:IsA("Model") then
		return
	end
	local kind = model:GetAttribute("DragonKind")
	local dragons = ReplicatedStorage:FindFirstChild("Dragons")
	local animatorModule = dragons and dragons:FindFirstChild("DragonAnimator")
	local animsModule = dragons and kind and dragons:FindFirstChild(kind) and dragons[kind]:FindFirstChild("Animations")
	if not animatorModule or not animsModule then
		return
	end
	local ok, err = pcall(function()
		local animator = require(animatorModule).new(model, require(animsModule))
		animator:Play(model:GetAttribute("Anim") or "Idle", 0)
		model:GetAttributeChangedSignal("AnimStamp"):Connect(function()
			animator:Play(model:GetAttribute("Anim"), model:GetAttribute("AnimFade") or 0.3)
		end)
		model.Destroying:Connect(function()
			animator:Destroy()
		end)
	end)
	if not ok then
		warn("[Cure] No pude animar al dragón: " .. tostring(err))
	end
end
for _, m in ipairs(bossFolder:GetChildren()) do
	task.spawn(animate, m)
end
bossFolder.ChildAdded:Connect(function(m)
	task.wait(0.5)
	animate(m)
end)
