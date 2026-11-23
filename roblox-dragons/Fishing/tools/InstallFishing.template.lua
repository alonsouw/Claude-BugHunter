--[[
	INSTALADOR DE LA PESCA (caña, 3 peces comestibles, hoguera) · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	No hace falta importar nada: pega TODO este archivo en View > Command Bar y pulsa Enter.

	Resultado:
	  StarterPack.FishingRod                          (la caña: todos empiezan con ella)
	  ReplicatedStorage.Fishing                       (FishingLogic, Fish: los peces crudos y cocinados, Bobber, Settings)
	  ServerScriptService.FishingService              (lanzar, picar, recoger, comer y cocinar)
	  StarterPlayer.StarterPlayerScripts.FishingHud   (avisos en pantalla)
	  Workspace.FishingPond + Workspace.Campfires     (lago de prueba con muelle y una hoguera, si DEMO_POND)

	Se pesca en cualquier agua de Terrain y en las zonas FishZone. Hogueras: cualquier parte o modelo con la etiqueta
	Campfire (o dentro de Workspace.Campfires).
]]

local DEMO_POND = true                        -- crea un lago de prueba con muelle y hoguera
local POND_CENTER = Vector3.new(-70, 0, 0)    -- centro del fondo del lago (sobre el suelo)
local POND_SIZE, POND_DEPTH = 44, 6
local GIVE_ROD = true                         -- la caña en el StarterPack
local CAST_RANGE = 45
local RAW_SICK_CHANCE = 0.25                  -- probabilidad de que el pescado crudo siente mal
local HUNGER_ATTRIBUTE = "Hunger"             -- si tu juego usa un atributo de hambre en el jugador, cuál
-- Sonidos: sube los .ogg de sounds/ y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = { Cast = "", Plop = "", Reel = "", Catch = "", Eat = "", Sizzle = "" }

local MODELS = __MODELS__
local SPECIES = __SPECIES__
local SOURCES = {
	Logic = [=======[__LOGIC__]=======],
	Service = [=======[__SERVICE__]=======],
	RodClient = [=======[__RODCLIENT__]=======],
	Hud = [=======[__HUD__]=======],
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar la pesca")
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
local function sound(parent, name, volume)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = SOUND_IDS[name] or ""
	s.Volume = volume or 0.7
	s.RollOffMaxDistance = 80
	s.Parent = parent
	return s
end

-- construye las piezas de un modelo: la primera es el Handle; el resto, soldadas a él
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
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CanCollide = false
		p.CastShadow = b.material ~= "Neon"
		if i == 1 then
			handle = p
			p.Anchored = anchored or false
		else
			p.Anchored = anchored or false
			p.Massless = true
			p.CanTouch, p.CanQuery = false, false
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

local function makeTool(name, list)
	local t = Instance.new("Tool")
	t.Name = name
	t.CanBeDropped = true
	local h = buildParts(list, t)
	h.CanTouch = false
	return t, h
end

-- peces: un Tool por especie, crudo y cocinado, con lo que dan al comer
local NAMES = { Trout = { "Trucha cruda", "Trucha cocinada" }, Perch = { "Perca cruda", "Perca cocinada" }, GoldenSalmon = { "Salmón dorado crudo", "Salmón dorado cocinado" } }
local function fishTool(species, cooked)
	local list = MODELS[cooked and (species .. "_Cooked") or species]
	local t, h = makeTool(NAMES[species][cooked and 2 or 1], list)
	local food = SPECIES[species][cooked and "Cooked" or "Raw"]
	local tail = 0
	for _, b in ipairs(list) do
		tail = math.max(tail, b.offset[3] + b.size[3] / 2)
	end
	t.Grip = CFrame.new(0, 0, tail * 0.55)   -- se coge por la cola, con la cabeza hacia delante
	t.ToolTip = ("Clic para comer · +%d vida"):format(food.Heal)
	t:SetAttribute("Species", species)
	t:SetAttribute("Cooked", cooked)
	t:SetAttribute("Heal", food.Heal)
	t:SetAttribute("Food", food.Food)
	CollectionService:AddTag(t, "FishFood")
	sound(h, "Eat", 0.8)
	return t
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

local folder = ensure(ReplicatedStorage, "Fishing")
for _, n in ipairs({ "Fish", "Bobber", "FishingRod" }) do
	local o = folder:FindFirstChild(n)
	if o then
		o:Destroy()
	end
end
local fishFolder = ensure(folder, "Fish")
for species in pairs(SPECIES) do   -- se llaman en español (es lo que se ve en la barra); el servicio los busca por atributos
	fishTool(species, false).Parent = fishFolder
	fishTool(species, true).Parent = fishFolder
end

-- boya
local bobber = Instance.new("Model")
bobber.Name = "Bobber"
local bh = buildParts(MODELS.Bobber, bobber, false)
bh.Anchored = true
bobber.PrimaryPart = bh
local line = Instance.new("Attachment")
line.Name = "Line"
line.Position = Vector3.new(0, 0.33, 0)
line.Parent = bh
sound(bh, "Plop", 0.6)
bobber.Parent = folder

-- caña
local rod, rh = makeTool("FishingRod", MODELS.FishingRod)
rod.ToolTip = "Caña de pescar · clic en el agua"
rod.Grip = CFrame.new(0, 0, 0.3)
rod.CanBeDropped = false
local tip = rod:FindFirstChild("Tip")
local ta = Instance.new("Attachment")
ta.Name = "Tip"
ta.Position = Vector3.new(0, 0, -tip.Size.Z / 2)
ta.Parent = tip
sound(rh, "Cast", 0.6)
sound(rh, "Reel", 0.5)
sound(rh, "Catch", 0.8)
CollectionService:AddTag(rod, "FishingRod")
local rc = Instance.new("LocalScript")
rc.Name = "FishingRodClient"
rc.Source = SOURCES.RodClient
rc.Parent = rod
rod.Parent = folder
if GIVE_ROD then
	local old = game:GetService("StarterPack"):FindFirstChild("FishingRod")
	if old then
		old:Destroy()
	end
	rod:Clone().Parent = game:GetService("StarterPack")
end

local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({ CastRange = CAST_RANGE, RawSickChance = RAW_SICK_CHANCE, HungerAttribute = HUNGER_ATTRIBUTE, MaxHunger = 100, WaitMin = 4, WaitMax = 12, BiteWindow = 1.3, ReelPower = 9 }) do
	settings:SetAttribute(k, v)
end
for species, st in pairs(SPECIES) do
	settings:SetAttribute(species .. "Weight", st.Weight)
	settings:SetAttribute(species .. "Drain", st.Drain)
end
putScript(folder, "FishingLogic", "ModuleScript", SOURCES.Logic)
putScript(game:GetService("ServerScriptService"), "FishingService", "Script", SOURCES.Service)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "FishingHud", "LocalScript", SOURCES.Hud)

-- hoguera de bloques (anclada) con fuego, luz y su etiqueta
local function campfire(cf)
	local m = Instance.new("Model")
	m.Name = "Campfire"
	local h = buildParts(MODELS.Campfire, m, true)
	m.PrimaryPart = h
	m:PivotTo(cf)
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") then
			p.CanCollide = p == h
		end
	end
	local flame = nil
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") and p.Material == Enum.Material.Neon then
			flame = flame or p
		end
	end
	if flame then
		local f = Instance.new("Fire")
		f.Size, f.Heat = 4, 6
		f.Parent = flame
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 160, 80), 18, 2
		l.Parent = flame
	end
	sound(h, "Sizzle", 0.7)
	CollectionService:AddTag(m, "Campfire")
	return m
end

-- lago de prueba: agua de Terrain, orillas de hierba anchas (para estar de pie), rampa, muelle y hoguera
if DEMO_POND then
	local old = workspace:FindFirstChild("FishingPond")
	if old then
		old:Destroy()
	end
	local pond = Instance.new("Model")
	pond.Name = "FishingPond"
	local c = POND_CENTER
	workspace.Terrain:FillBlock(CFrame.new(c + Vector3.new(0, POND_DEPTH / 2, 0)), Vector3.new(POND_SIZE, POND_DEPTH, POND_SIZE), Enum.Material.Water)
	local function block(name, size, cf, mat, color, class)
		local p = Instance.new(class or "Part")
		p.Name = name
		p.Size = size
		p.CFrame = typeof(cf) == "CFrame" and cf or CFrame.new(cf)
		p.Anchored = true
		p.Material = mat
		p.Color = color
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = pond
		return p
	end
	local h, w = POND_DEPTH + 0.5, 8
	local half = POND_SIZE / 2 + w / 2
	local grass, wood = Color3.fromRGB(86, 120, 62), Color3.fromRGB(110, 78, 50)
	block("Bed", Vector3.new(POND_SIZE, 1, POND_SIZE), c + Vector3.new(0, -0.5, 0), Enum.Material.Mud, Color3.fromRGB(58, 52, 40))
	block("BankN", Vector3.new(POND_SIZE + 2 * w, h, w), c + Vector3.new(0, h / 2, -half), Enum.Material.Grass, grass)
	block("BankS", Vector3.new(POND_SIZE + 2 * w, h, w), c + Vector3.new(0, h / 2, half), Enum.Material.Grass, grass)
	block("BankW", Vector3.new(w, h, POND_SIZE), c + Vector3.new(-half, h / 2, 0), Enum.Material.Grass, grass)
	block("BankE", Vector3.new(w, h, POND_SIZE), c + Vector3.new(half, h / 2, 0), Enum.Material.Grass, grass)
	block("Ramp", Vector3.new(8, h, h * 3), CFrame.new(c + Vector3.new(half + w / 2 + h * 1.5, h / 2, 0)) * CFrame.Angles(0, -math.pi / 2, 0), Enum.Material.Grass, grass, "WedgePart")
	-- muelle desde la orilla sur hacia el centro
	local dockLen = 14
	local dz = POND_SIZE / 2 - dockLen / 2
	block("Dock", Vector3.new(6, 0.5, dockLen), c + Vector3.new(0, h - 0.25, dz), Enum.Material.WoodPlanks, wood)
	for _, x in ipairs({ -2.6, 2.6 }) do
		for _, z in ipairs({ dz - dockLen / 2 + 0.6, dz }) do
			block("Post", Vector3.new(0.6, h + 0.6, 0.6), c + Vector3.new(x, (h + 0.6) / 2 - 0.3, z), Enum.Material.Wood, Color3.fromRGB(80, 56, 36))
		end
	end
	pond.Parent = workspace
	local fires = ensure(workspace, "Campfires")
	local oldFire = fires:FindFirstChild("PondCampfire")
	if oldFire then
		oldFire:Destroy()
	end
	local fire = campfire(CFrame.new(c + Vector3.new(7, h, half)))
	fire.Name = "PondCampfire"
	fire.Parent = fires
end

Selection:Set({ folder })
pcall(function()
	ChangeHistoryService:SetWaypoint("Pesca instalada")
end)
print(("[Fishing] Listo: caña%s, 3 peces (crudos y cocinados) y servicio de pesca.%s"):format(
	GIVE_ROD and " en el StarterPack" or "",
	DEMO_POND and " Lago de prueba en Workspace.FishingPond: pesca desde el muelle y cocina en la hoguera." or ""))
