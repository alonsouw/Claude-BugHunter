--[[
	INSTALADOR DEL PEZ INFECTADO (criatura de bloques) · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	No hace falta importar nada: pega TODO este archivo en View > Command Bar y pulsa Enter.
	Construye las dos variantes con Parts (cada articulación es un Motor6D) y un estanque de prueba.

	Resultado:
	  ReplicatedStorage.Creatures.InfectedFish.Types     (Normal y Giant)
	  ReplicatedStorage.Creatures.InfectedFish           (Settings, Animations, FishBrain)
	  ReplicatedStorage.Dragons.DragonAnimator           (motor de animación, compartido con las demás criaturas)
	  ServerScriptService.FishSpawner                    (crea los peces en las zonas de agua y los controla)
	  StarterPlayer.StarterPlayerScripts.FishClient      (animación en cada jugador)
	  Workspace.FishZones.Pond + Workspace.FishPond      (estanque de prueba con agua de Terrain, si DEMO_POND)
	  Workspace.InfectedFishPreview                      (los dos peces para verlos en Studio; se borra al jugar)

	Para tu propio lago: una parte invisible que cubra el agua (cara de arriba = superficie) con la etiqueta
	FishZone, o dentro de Workspace.FishZones.
]]

local DEMO_POND = true                          -- crea un estanque de prueba
local POND_CENTER = Vector3.new(60, 0, 0)       -- centro del fondo del estanque (sobre el suelo)
local POND_SIZE, POND_DEPTH = 64, 14            -- lado y profundidad del agua (studs)
local MAX_PER_ZONE = 4                          -- peces por zona de agua
local RESPAWN_DELAY = 25
local GIANT_CHANCE = 0.125                      -- 1 de cada 8
-- Sonidos: sube los .ogg de sounds/ y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = { Screech = "", Bite = "", Splash = "", Gurgle = "" }

local BLUEPRINTS = __BLUEPRINTS__
local STATS = __STATS__
local SOURCES = {
	DragonAnimator = [=======[__ANIMATOR__]=======],
	Animations = [=======[__ANIMS__]=======],
	Brain = [=======[__BRAIN__]=======],
	Spawner = [=======[__SPAWNER__]=======],
	Client = [=======[__CLIENT__]=======],
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar el pez infectado")
end)

local function v3(t)
	return Vector3.new(t[1], t[2], t[3])
end
local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end
local function material(name)
	local ok, m = pcall(function()
		return Enum.Material[name]
	end)
	return ok and m or Enum.Material.SmoothPlastic
end

-- construye un pez a partir de su plano
local function build(name, bp, scale)
	local model = Instance.new("Model")
	model.Name = name
	local parts = {}
	for limb, L in pairs(bp.limbs) do
		local p = Instance.new("Part")
		p.Name = limb
		p.Size = v3(L.size)
		p.CFrame = CFrame.new(v3(L.center))
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if L.transparent then
			p.Transparency = 1
		else
			p.Color = rgb(L.color)
			p.Material = material(L.material or "SmoothPlastic")
			p.Massless = true
		end
		p.CanCollide = false
		p.CanTouch = not L.transparent   -- las espadas que dañan por contacto (Touched) también le dan
		p.Parent = model
		parts[limb] = p
	end
	model.PrimaryPart = parts.Root
	for _, j in ipairs(bp.joints) do
		local p0, p1, piv = parts[j[1]], parts[j[2]], CFrame.new(v3(j[3]))
		local m = Instance.new("Motor6D")
		m.Name = j[2]
		m.Part0, m.Part1 = p0, p1
		m.C0 = p0.CFrame:Inverse() * piv
		m.C1 = p1.CFrame:Inverse() * piv
		m.Parent = p0
	end
	for _, d in ipairs(bp.details) do
		local limb = parts[d.limb]
		local p = Instance.new("Part")
		p.Name = d.neon and "Glow" or "Detail"
		p.Size = v3(d.size)
		p.CFrame = CFrame.new(limb.Position + v3(d.offset)) * CFrame.Angles(math.rad(d.rot[1]), math.rad(d.rot[2]), math.rad(d.rot[3]))
		p.Color = rgb(d.color)
		p.Material = d.neon and Enum.Material.Neon or material(d.material)
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CanCollide, p.CanTouch, p.Massless = false, false, true
		p.CastShadow = not d.neon
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = limb, p
		w.Parent = p
		p.Parent = limb
	end
	local hum = Instance.new("Humanoid")
	hum.HipHeight = 0
	hum.RequiresNeck = false
	hum.BreakJointsOnDeath = false
	hum.AutomaticScalingEnabled = false
	hum.EvaluateStateMachine = false   -- no camina ni nada: lo mueve el servidor
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.Parent = model
	for sname, id in pairs(SOUND_IDS) do
		local s = Instance.new("Sound")
		s.Name = sname
		s.SoundId = id
		s.Volume = sname == "Gurgle" and 0.4 or 0.9
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 6
		s.RollOffMaxDistance = sname == "Screech" and 140 or 70
		s.Parent = parts.Root
	end
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	model:SetAttribute("Scale", scale or 1)
	return model
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
end

local folder = ensure(ensure(ReplicatedStorage, "Creatures"), "InfectedFish")
local old = folder:FindFirstChild("Types")
if old then
	old:Destroy()
end
local typesFolder = ensure(folder, "Types")
for _, name in ipairs({ "Normal", "Giant" }) do
	build(name, BLUEPRINTS[name], STATS[name].Scale).Parent = typesFolder
end
local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({ MaxPerZone = MAX_PER_ZONE, RespawnDelay = RESPAWN_DELAY, GiantChance = GIANT_CHANCE, Debug = false }) do
	settings:SetAttribute(k, v)
end
for name, st in pairs(STATS) do
	for k, v in pairs(st) do
		if type(v) ~= "string" then
			settings:SetAttribute(name .. k, v)
		end
	end
end
settings:SetAttribute("GiantChance", GIANT_CHANCE)
putScript(ensure(ReplicatedStorage, "Dragons"), "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(folder, "FishBrain", "ModuleScript", SOURCES.Brain)
putScript(game:GetService("ServerScriptService"), "FishSpawner", "Script", SOURCES.Spawner)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "FishClient", "LocalScript", SOURCES.Client)

-- estanque de prueba: agua de Terrain dentro de un muro de piedra, con una rampa para subir al borde
if DEMO_POND then
	local oldPond = workspace:FindFirstChild("FishPond")
	if oldPond then
		oldPond:Destroy()
	end
	local pond = Instance.new("Model")
	pond.Name = "FishPond"
	local c = POND_CENTER
	workspace.Terrain:FillBlock(CFrame.new(c + Vector3.new(0, POND_DEPTH / 2, 0)), Vector3.new(POND_SIZE, POND_DEPTH, POND_SIZE), Enum.Material.Water)
	local function block(name, size, pos, mat, color, class)
		local p = Instance.new(class or "Part")
		p.Name = name
		p.Size = size
		p.CFrame = typeof(pos) == "CFrame" and pos or CFrame.new(pos)
		p.Anchored = true
		p.Material = mat
		p.Color = color
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = pond
		return p
	end
	local wallH, t = POND_DEPTH + 1, 4
	local half = POND_SIZE / 2 + t / 2
	local stone = Color3.fromRGB(96, 98, 92)
	block("Floor", Vector3.new(POND_SIZE, 1, POND_SIZE), c + Vector3.new(0, -0.5, 0), Enum.Material.Mud, Color3.fromRGB(58, 52, 40))
	block("WallN", Vector3.new(POND_SIZE + 2 * t, wallH, t), c + Vector3.new(0, wallH / 2, -half), Enum.Material.Slate, stone)
	block("WallS", Vector3.new(POND_SIZE + 2 * t, wallH, t), c + Vector3.new(0, wallH / 2, half), Enum.Material.Slate, stone)
	block("WallW", Vector3.new(t, wallH, POND_SIZE), c + Vector3.new(-half, wallH / 2, 0), Enum.Material.Slate, stone)
	block("WallE", Vector3.new(t, wallH, POND_SIZE), c + Vector3.new(half, wallH / 2, 0), Enum.Material.Slate, stone)
	-- rampa hasta lo alto del muro oeste
	block("Ramp", Vector3.new(8, wallH, wallH * 2), CFrame.new(c + Vector3.new(-half - t / 2 - wallH, wallH / 2, 0)) * CFrame.Angles(0, math.pi / 2, 0), Enum.Material.Slate, stone, "WedgePart")   -- lo alto de la cuña (+Z) contra el muro
	pond.Parent = workspace
	local zf = ensure(workspace, "FishZones")
	local oldZone = zf:FindFirstChild("Pond")
	if oldZone then
		oldZone:Destroy()
	end
	local zone = Instance.new("Part")
	zone.Name = "Pond"
	zone.Size = Vector3.new(POND_SIZE - 1, POND_DEPTH - 0.5, POND_SIZE - 1)
	zone.CFrame = CFrame.new(c + Vector3.new(0, (POND_DEPTH - 0.5) / 2, 0))
	zone.Anchored, zone.CanCollide, zone.CanQuery, zone.CanTouch = true, false, false, false
	zone.Transparency = 1
	zone.Parent = zf
	CollectionService:AddTag(zone, "FishZone")
end

-- vista previa en Studio: los dos peces anclados (se destruye al pulsar Play)
local prev = workspace:FindFirstChild("InfectedFishPreview")
if prev then
	prev:Destroy()
end
prev = Instance.new("Model")
prev.Name = "InfectedFishPreview"
local spots = { Normal = CFrame.new(-6, 4, -30), Giant = CFrame.new(8, 7, -30) }
for name, cf in pairs(spots) do
	local m = typesFolder[name]:Clone()
	m:PivotTo(cf * CFrame.Angles(0, math.pi / 2, 0))
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
	m.Parent = prev
end
prev.Parent = workspace
local cleanup = Instance.new("Script")
cleanup.Name = "RemoveOnPlay"
cleanup.Source = "script.Parent:Destroy()"
cleanup.Parent = prev

Selection:Set({ typesFolder })
pcall(function()
	ChangeHistoryService:SetWaypoint("Pez infectado instalado")
end)
print(("[InfectedFish] Listo: pez normal y gigante construidos con Parts.%s Vista previa en Workspace.InfectedFishPreview."):format(
	DEMO_POND and " Estanque de prueba en Workspace.FishPond: al pulsar Play, sube por la rampa y métete en el agua." or ""))
