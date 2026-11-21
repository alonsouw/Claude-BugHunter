--[[
	INSTALADOR DE LOS INFECTADOS (personajes de bloques) · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	No hace falta importar nada: pega TODO este archivo en View > Command Bar y pulsa Enter.
	Construye los cinco tipos con Parts (cada articulación es un Motor6D) y los guarda listos para el juego.

	Resultado:
	  ReplicatedStorage.Creatures.Infected.Types         (Walker, Runner, Bloater, Screamer, Brute)
	  ReplicatedStorage.Creatures.Infected               (Settings, Animations, InfectedBrain)
	  ReplicatedStorage.Dragons.DragonAnimator           (motor de animación, compartido con los dragones)
	  ServerScriptService.InfectedSpawner                (crea a los infectados y los controla)
	  StarterPlayer.StarterPlayerScripts.InfectedClient  (animación en cada jugador)
	  Workspace.InfectedPreview                          (los cinco en fila para verlos en Studio; se borra al jugar)
]]

local MAX_ALIVE = 20          -- infectados a la vez
local RESPAWN_DELAY = 20      -- segundos hasta que un muerto vuelve a aparecer (en otro sitio)
local NIGHT_ONLY = false      -- true: solo aparecen de noche
local SPAWN_CENTER = Vector3.new(0, 0, 0)
local SPAWN_RADIUS = 200
-- probabilidad de cada tipo
local WEIGHTS = { Walker = 0.5, Runner = 0.2, Bloater = 0.12, Screamer = 0.1, Brute = 0.08 }
-- Sonidos: sube los .ogg de sounds/ y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = { Groan = "", Scream = "", Hit = "", Pop = "", Roar = "" }

local BLUEPRINTS = __BLUEPRINTS__
local SOURCES = {
	DragonAnimator = [=======[__ANIMATOR__]=======],
	Animations = [=======[__ANIMS__]=======],
	Brain = [=======[__BRAIN__]=======],
	Spawner = [=======[__SPAWNER__]=======],
	Client = [=======[__CLIENT__]=======],
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar los infectados")
end)

local function v3(t)
	return Vector3.new(t[1], t[2], t[3])
end
local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

-- construye un infectado a partir de su plano
local function build(name, bp)
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
			p.CanCollide = true
		else
			p.Color = rgb(L.color)
			p.Material = Enum.Material[L.material] or Enum.Material.SmoothPlastic
			p.CanCollide = false
			p.Massless = true
		end
		p.CanTouch = false
		p.Parent = model
		parts[limb] = p
	end
	model.PrimaryPart = parts.HumanoidRootPart
	-- articulaciones: Motor6D en el pivote, sin rotación (las animaciones giran en los ejes del modelo)
	for _, j in ipairs(bp.joints) do
		local p0, p1, piv = parts[j[1]], parts[j[2]], CFrame.new(v3(j[3]))
		local m = Instance.new("Motor6D")
		m.Name = j[2]
		m.Part0, m.Part1 = p0, p1
		m.C0 = p0.CFrame:Inverse() * piv
		m.C1 = p1.CFrame:Inverse() * piv
		m.Parent = p0
	end
	-- detalles: bloques soldados a su pieza
	for _, d in ipairs(bp.details) do
		local limb = parts[d.limb]
		local p = Instance.new("Part")
		p.Name = d.neon and "Glow" or "Detail"
		p.Size = v3(d.size)
		p.CFrame = CFrame.new(limb.Position + v3(d.offset)) * CFrame.Angles(math.rad(d.rot[1]), math.rad(d.rot[2]), math.rad(d.rot[3]))
		p.Color = rgb(d.color)
		p.Material = d.neon and Enum.Material.Neon or (Enum.Material[d.material] or Enum.Material.SmoothPlastic)
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CanCollide, p.CanTouch, p.Massless = false, false, true
		p.CastShadow = not d.neon
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = limb, p
		w.Parent = p
		p.Parent = limb
	end
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = bp.hipHeight
	hum.AutomaticScalingEnabled = false
	hum.BreakJointsOnDeath = false
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.Parent = model
	for sname, id in pairs(SOUND_IDS) do
		local s = Instance.new("Sound")
		s.Name = sname
		s.SoundId = id
		s.Volume = (sname == "Scream" or sname == "Roar") and 1 or 0.6
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 8
		s.RollOffMaxDistance = (sname == "Scream") and 250 or 90
		s.Parent = parts.HumanoidRootPart
	end
	model:SetAttribute("HipHeight", bp.hipHeight)
	model:SetAttribute("RigScale", 1)
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

local folder = ensure(ensure(ReplicatedStorage, "Creatures"), "Infected")
local old = folder:FindFirstChild("Types")
if old then
	old:Destroy()
end
local typesFolder = ensure(folder, "Types")
local order = { "Walker", "Runner", "Bloater", "Screamer", "Brute" }
for _, name in ipairs(order) do
	build(name, BLUEPRINTS[name]).Parent = typesFolder
end
local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({ MaxAlive = MAX_ALIVE, RespawnDelay = RESPAWN_DELAY, NightOnly = NIGHT_ONLY, SpawnCenter = SPAWN_CENTER, SpawnRadius = SPAWN_RADIUS, Debug = false }) do
	settings:SetAttribute(k, v)
end
for name, w in pairs(WEIGHTS) do
	settings:SetAttribute(name .. "Weight", w)
end
putScript(ensure(ReplicatedStorage, "Dragons"), "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(folder, "InfectedBrain", "ModuleScript", SOURCES.Brain)
putScript(game:GetService("ServerScriptService"), "InfectedSpawner", "Script", SOURCES.Spawner)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "InfectedClient", "LocalScript", SOURCES.Client)

-- vista previa en Studio: los cinco en fila, anclados (se destruye al pulsar Play)
local prev = workspace:FindFirstChild("InfectedPreview")
if prev then
	prev:Destroy()
end
prev = Instance.new("Model")
prev.Name = "InfectedPreview"
for i, name in ipairs(order) do
	local m = typesFolder[name]:Clone()
	if name == "Brute" then
		m:ScaleTo(1.4)
	end
	m:PivotTo(CFrame.new((i - 3) * 6, 0, -30) * CFrame.Angles(0, math.pi, 0))
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
	ChangeHistoryService:SetWaypoint("Infectados instalados")
end)
print(("[Infected] Listo: 5 tipos construidos con Parts. Al pulsar Play aparecen hasta %d infectados. Vista previa en Workspace.InfectedPreview."):format(MAX_ALIVE))
