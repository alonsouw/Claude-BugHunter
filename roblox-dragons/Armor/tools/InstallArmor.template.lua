--[[
	INSTALADOR DE LAS ARMADURAS (cuero, lobo, dragón) · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	No hace falta importar nada: pega TODO este archivo en View > Command Bar y pulsa Enter.

	Resultado:
	  ReplicatedStorage.Armor.ArmorData       (planos y estadísticas: reducción de daño y velocidad)
	  ReplicatedStorage.Armor.ArmorBuilder    (construye y ajusta las piezas sobre un cuerpo R15 o R6)
	  ServerScriptService.ArmorService        (equipar, defensa, velocidad, conservar al reaparecer)
	  Workspace.ArmorStands                   (tres maniquíes con la armadura puesta y el botón «Equipar» (E))
]]

local STANDS_ORIGIN = CFrame.new(0, 0, -20)   -- dónde colocar los maniquíes (luego se pueden mover)

local SOURCES = {
	Data = [=======[__DATA__]=======],
	Builder = [=======[__BUILDER__]=======],
	Service = [=======[__SERVICE__]=======],
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar las armaduras")
end)

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

local folder = ensure(ReplicatedStorage, "Armor")
putScript(folder, "ArmorData", "ModuleScript", SOURCES.Data)
local builderModule = putScript(folder, "ArmorBuilder", "ModuleScript", SOURCES.Builder)
putScript(game:GetService("ServerScriptService"), "ArmorService", "Script", SOURCES.Service)

-- maniquíes: cuerpo R15 de bloques anclado, con la armadura puesta y un ProximityPrompt
local Builder = require(builderModule)
local Data = require(folder.ArmorData)
local old = workspace:FindFirstChild("ArmorStands")
if old then
	old:Destroy()
end
local stands = Instance.new("Folder")
stands.Name = "ArmorStands"
local order = { "Leather", "Wolf", "Dragon" }
for i, setName in ipairs(order) do
	local st = Data.stats[setName]
	local base = STANDS_ORIGIN * CFrame.new((i - 2) * 7, 0, 0) * CFrame.Angles(0, math.pi, 0)
	local m = Instance.new("Model")
	m.Name = "Stand_" .. setName
	local pedestal = Instance.new("Part")
	pedestal.Name = "Pedestal"
	pedestal.Size = Vector3.new(4, 0.6, 4)
	pedestal.CFrame = base * CFrame.new(0, 0.3, 0)
	pedestal.Anchored = true
	pedestal.Material = Enum.Material.Wood
	pedestal.Color = Color3.fromRGB(70, 52, 36)
	pedestal.Parent = m
	for name, P in pairs(Data.dummyParts) do
		local p = Instance.new("Part")
		p.Name = name
		p.Size = Vector3.new(P.size[1], P.size[2], P.size[3])
		p.CFrame = base * CFrame.new(P.center[1], P.center[2] + 0.6, P.center[3])
		p.Anchored = true
		p.CanCollide = name == "UpperTorso"
		p.Material = Enum.Material.Wood
		p.Color = Color3.fromRGB(150, 120, 88)
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = m
	end
	Builder.Attach(m, setName)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Equipar / quitar"
	prompt.ObjectText = st.DisplayName
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.4
	prompt:SetAttribute("ArmorSet", setName)
	prompt.Parent = m.UpperTorso
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 50)
	bb.StudsOffset = Vector3.new(0, 4.2, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(240, 230, 210)
	label.TextStrokeTransparency = 0.4
	label.Text = ("%s\n−%d %% daño · %+d velocidad"):format(st.DisplayName, math.floor(st.Reduction * 100 + 0.5), st.Speed)
	label.Parent = bb
	bb.Parent = m.Head
	m.PrimaryPart = pedestal
	m.Parent = stands
end
stands.Parent = workspace

Selection:Set({ stands })
pcall(function()
	ChangeHistoryService:SetWaypoint("Armaduras instaladas")
end)
print("[Armor] Listo: 3 armaduras (cuero, lobo, dragón) y sus maniquíes en Workspace.ArmorStands. En Play, acércate y pulsa E.")
