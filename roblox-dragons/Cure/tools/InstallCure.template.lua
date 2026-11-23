--[[
	INSTALADOR DE LA CURA («Remedio del Alba») · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	No hace falta importar nada: pega TODO este archivo en View > Command Bar y pulsa Enter.

	Resultado:
	  ReplicatedStorage.Cure                     (Recipe, CureLogic, Items, World, Settings, Progress, eventos)
	  ServerScriptService.CureService            (botín, jefe dragón, plantas, caldero y final)
	  StarterPlayer.StarterPlayerScripts.CureClient (recetario, avisos, pantalla final, animación del jefe)
	  Workspace.CureCauldron                     (el caldero, en CAULDRON_POS)
	  Workspace.DragonLair                       (la guarida del dragón, en LAIR_POS)

	Ingredientes: saliva de dragón (jefe de la guarida), colmillo de alfa (lobos), asta maldita (ciervo maldito),
	perla negra (pez infectado gigante), corazón del bruto (infectados), flor de luna ×3 y raíz de sangre ×2 (plantas).
	Para el jefe hace falta tener instalado el Dragón Depredador o el Dragón Aberrante.
]]

local CAULDRON_POS = Vector3.new(0, 0, 30)    -- el caldero (pon aquí tu campamento)
local LAIR_POS = Vector3.new(0, 0, -160)      -- la guarida del dragón (lejos del campamento)
local CREATE_LAIR = true
local BOSS_DRAGON = "PredatorDragon"          -- "PredatorDragon" o "AberrantDragon" (el que tengas instalado)
local BOSS_HEALTH, BOSS_DAMAGE = 2500, 35
local BREW_TIME = 90                          -- segundos que tarda en prepararse
local PLANT_CENTER, PLANT_RADIUS = Vector3.new(0, 0, 0), 150   -- dónde crecen las plantas (o etiquetas MoonflowerSpot / BloodRootSpot)
local MOONFLOWERS, BLOODROOTS = 6, 4
-- Sonidos: sube los .ogg de sounds/ y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = { Pickup = "", Harvest = "", Add = "", Brew = "", Ready = "", Dawn = "" }

local ITEMS = __ITEMS__
local WORLD = __WORLD__
local RECIPE_SRC = [=======[__RECIPE__]=======]
local SOURCES = {
	Logic = [=======[__LOGIC__]=======],
	Service = [=======[__SERVICE__]=======],
	Client = [=======[__CLIENT__]=======],
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar la cura")
end)

local function v3(t)
	return Vector3.new(t[1], t[2], t[3])
end
local function material(name)
	local ok, m = pcall(function()
		return Enum.Material[name]
	end)
	return ok and m or Enum.Material.SmoothPlastic
end
local function sound(parent, name, volume, looped)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = SOUND_IDS[name] or ""
	s.Volume = volume or 0.7
	s.Looped = looped or false
	s.RollOffMaxDistance = 90
	s.Parent = parent
	return s
end
-- piezas de un modelo: la primera es el Handle; el resto, soldadas (o ancladas si anchored)
local function buildParts(list, parent, anchored)
	local handle
	for i, b in ipairs(list) do
		local p = Instance.new("Part")
		p.Name = b.name or (i == 1 and "Handle" or "Part")
		p.Size = v3(b.size)
		local cf = CFrame.new(v3(b.offset)) * CFrame.Angles(math.rad(b.rot[1]), math.rad(b.rot[2]), math.rad(b.rot[3]))
		p.CFrame = handle and handle.CFrame * cf or cf
		p.Color = Color3.fromRGB(b.color[1], b.color[2], b.color[3])
		p.Material = material(b.material)
		if b.material == "Glass" then
			p.Transparency = 0.45
		end
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CanCollide = anchored and i == 1 or false
		p.CastShadow = b.material ~= "Neon"
		p.Anchored = anchored or false
		if i == 1 then
			handle = p
		else
			p.Massless = true
			p.CanTouch, p.CanQuery = false, anchored and true or false
			if not anchored then
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = handle, p
				w.Parent = p
			end
		end
		p.Parent = parent
	end
	return handle
end
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

local folder = ensure(ReplicatedStorage, "Cure")
for _, n in ipairs({ "Items", "World" }) do
	local o = folder:FindFirstChild(n)
	if o then
		o:Destroy()
	end
end
local recipeModule = putScript(folder, "Recipe", "ModuleScript", RECIPE_SRC)
putScript(folder, "CureLogic", "ModuleScript", SOURCES.Logic)
local RECIPE = require(recipeModule)
local NAMES = { Remedy = "Remedio del Alba" }
local COLORS = { Remedy = { 255, 214, 110 } }
for _, r in ipairs(RECIPE) do
	NAMES[r.id], COLORS[r.id] = r.name, r.color
end

-- ingredientes y el remedio: Tools (se cogen al tocarlos y van a la mochila)
local items = ensure(folder, "Items")
for id, list in pairs(ITEMS) do
	local t = Instance.new("Tool")
	t.Name = NAMES[id] or id
	t.CanBeDropped = true
	t.ToolTip = id == "Remedy" and "Clic para usar la cura" or "Ingrediente de la cura · échalo al caldero"
	local h = buildParts(list, t, false)
	local c = COLORS[id] or { 255, 255, 255 }
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(c[1], c[2], c[3])
	light.Range, light.Brightness = 8, 1.2
	light.Parent = h
	sound(h, "Pickup", 0.7)
	t:SetAttribute("CureItem", id)
	CollectionService:AddTag(t, id == "Remedy" and "CureRemedy" or "CureItem")
	t.Parent = items
end
-- plantas (ancladas)
local world = ensure(folder, "World")
for name, list in pairs(WORLD) do
	if name ~= "Cauldron" then
		local m = Instance.new("Model")
		m.Name = name
		m.PrimaryPart = buildParts(list, m, true)
		sound(m.PrimaryPart, "Harvest", 0.7)
		if name == "MoonflowerPlant" then
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = Color3.fromRGB(170, 210, 255), 10, 1
			l.Parent = m.PrimaryPart
		end
		m.Parent = world
	end
end
local dawn = folder:FindFirstChild("Dawn")
if dawn then
	dawn:Destroy()
end
sound(folder, "Dawn", 0.9)

local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({ BrewTime = BREW_TIME, BossDragon = BOSS_DRAGON, BossHealth = BOSS_HEALTH, BossDamage = BOSS_DAMAGE, BossRespawn = 600,
	Moonflowers = MOONFLOWERS, BloodRoots = BLOODROOTS, PlantCenter = PLANT_CENTER, PlantRadius = PLANT_RADIUS, PlantRespawn = 120 }) do
	settings:SetAttribute(k, v)
end
for _, a in ipairs({ "Done", "Total", "Stage", "Brewing", "BrewFraction", "Cured", "RemedyTaken" }) do
	folder:SetAttribute(a, nil)
end
putScript(game:GetService("ServerScriptService"), "CureService", "Script", SOURCES.Service)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "CureClient", "LocalScript", SOURCES.Client)

-- el caldero
local old = workspace:FindFirstChild("CureCauldron")
if old then
	old:Destroy()
end
local cauldron = Instance.new("Model")
cauldron.Name = "CureCauldron"
cauldron.PrimaryPart = buildParts(WORLD.Cauldron, cauldron, true)
for _, p in ipairs(cauldron:GetChildren()) do
	if p:IsA("BasePart") and p.Material == Enum.Material.Metal then
		p.CanCollide = true
	end
end
local fire = cauldron:FindFirstChild("Fire")
if fire then
	local f = Instance.new("Fire")
	f.Size, f.Heat = 3, 4
	f.Parent = fire
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 160, 80), 16, 2
	l.Parent = fire
end
local liquid = cauldron:FindFirstChild("Liquid")
sound(liquid, "Add", 0.8)
sound(liquid, "Brew", 0.6, true)
sound(liquid, "Ready", 1)
-- carteles de las peanas con el nombre de cada ingrediente
for i, r in ipairs(RECIPE) do
	local slot = cauldron:FindFirstChild("Slot" .. i)
	if slot then
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(150, 24)
		bb.StudsOffset = Vector3.new(0, 1.2, 0)
		bb.MaxDistance = 30
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.GothamBold
		l.TextScaled = true
		l.TextColor3 = Color3.fromRGB(236, 228, 210)
		l.TextStrokeTransparency = 0.3
		l.Text = r.need > 1 and ("%s ×%d"):format(r.name, r.need) or r.name
		l.Parent = bb
		bb.Parent = slot
	end
end
cauldron:PivotTo(CFrame.new(CAULDRON_POS))
CollectionService:AddTag(cauldron, "CureCauldron")
cauldron.Parent = workspace

-- la guarida: un anillo de rocas y huesos; el marcador DragonLair es donde aparece el jefe
if CREATE_LAIR then
	local oldLair = workspace:FindFirstChild("DragonLair")
	if oldLair then
		oldLair:Destroy()
	end
	local lair = Instance.new("Model")
	lair.Name = "DragonLair"
	local marker = Instance.new("Part")
	marker.Name = "Center"
	marker.Size = Vector3.new(40, 0.4, 40)
	marker.CFrame = CFrame.new(LAIR_POS + Vector3.new(0, 0.2, 0))
	marker.Anchored = true
	marker.Material = Enum.Material.Ground
	marker.Color = Color3.fromRGB(50, 42, 36)
	marker.Parent = lair
	lair.PrimaryPart = marker
	local r = Random.new(9)
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		local rock = Instance.new("Part")
		rock.Size = Vector3.new(r:NextNumber(4, 8), r:NextNumber(4, 10), r:NextNumber(4, 7))
		rock.CFrame = CFrame.new(LAIR_POS + Vector3.new(math.cos(a) * 34, rock.Size.Y / 2 - 0.5, math.sin(a) * 34)) * CFrame.Angles(0, r:NextNumber(0, 6), r:NextNumber(-0.2, 0.2))
		rock.Anchored = true
		rock.Material = Enum.Material.Slate
		rock.Color = Color3.fromRGB(70, 66, 64)
		rock.Parent = lair
	end
	for i = 1, 10 do   -- huesos de presas
		local bone = Instance.new("Part")
		bone.Size = Vector3.new(0.5, 0.5, r:NextNumber(2, 4))
		bone.CFrame = CFrame.new(LAIR_POS + Vector3.new(r:NextNumber(-16, 16), 0.45, r:NextNumber(-16, 16))) * CFrame.Angles(0, r:NextNumber(0, 6), 0)
		bone.Anchored = true
		bone.CanCollide = false
		bone.Color = Color3.fromRGB(220, 210, 186)
		bone.Parent = lair
	end
	CollectionService:AddTag(marker, "DragonLair")
	lair.Parent = workspace
end

local dragons = ReplicatedStorage:FindFirstChild("Dragons")
local hasDragon = dragons and ((dragons:FindFirstChild(BOSS_DRAGON) and dragons[BOSS_DRAGON]:FindFirstChild(BOSS_DRAGON))
	or (dragons:FindFirstChild("PredatorDragon") and dragons.PredatorDragon:FindFirstChild("PredatorDragon"))
	or (dragons:FindFirstChild("AberrantDragon") and dragons.AberrantDragon:FindFirstChild("AberrantDragon")))
if not hasDragon then
	warn("[Cure] Aviso: no hay ningún dragón instalado (Depredador o Aberrante). Sin él no aparece el jefe y no hay saliva de dragón.")
end
Selection:Set({ cauldron })
pcall(function()
	ChangeHistoryService:SetWaypoint("Cura instalada")
end)
print("[Cure] Listo: caldero en Workspace.CureCauldron" .. (CREATE_LAIR and ", guarida en Workspace.DragonLair" or "") .. ". En Play, pulsa R o el botón «Cura» para ver la receta.")
