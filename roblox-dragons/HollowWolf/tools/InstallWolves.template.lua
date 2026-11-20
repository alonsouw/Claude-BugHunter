--[[
	INSTALADOR DE LOS LOBOS HUECOS · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	Pasos:
	  1. Studio > Avatar (o Home) > Import 3D > HollowWolf.fbx.
	     En el importador: Rig General > Rig Type = "Custom". No combines las mallas. Pulsa Import.
	     Aparece un modelo con la malla WolfBody y sus Bones.
	  2. Selecciona ese modelo en el Explorer.
	  3. View > Command Bar. Pega TODO este archivo y pulsa Enter.
	  4. (Opcional) Partes con la etiqueta "WolfSpawn" (o en Workspace.WolfSpawns): por dónde salen las manadas.
	     Partes con la etiqueta "SafeLight" (atributo Radius): zonas de luz donde los lobos no entran (la hoguera).

	Resultado:
	  ReplicatedStorage.Creatures.HollowWolf            (modelo, Settings, Animations, WolfBrain, DamageWolf)
	  ReplicatedStorage.Dragons.DragonAnimator          (motor de animación, compartido con los dragones)
	  ServerScriptService.WolfPack                      (manadas: salen de noche, cazan en grupo, se van al amanecer)
	  StarterPlayer.StarterPlayerScripts.WolfClient     (animación, ojos y movimiento suave)
	  ServerStorage.DragonAssets.HollowWolf_Rig         (copia de seguridad)
]]

-- Ajustes principales (también se pueden cambiar luego en ReplicatedStorage.Creatures.HollowWolf.Settings)
local PACKS = 2               -- manadas a la vez
local PACK_SIZE = 4           -- lobos por manada (1 alfa + 3)
local DAMAGE = 8              -- daño de cada mordisco (el alfa hace ALPHA_DAMAGE)
local ALPHA_DAMAGE = 15
local HEALTH = 60             -- vida de cada lobo (el alfa tiene ALPHA_HEALTH)
local ALPHA_HEALTH = 150
local NIGHT_ONLY = true       -- salen al anochecer y se van al amanecer
local SPAWN_CENTER = Vector3.new(0, 0, 0)
local SPAWN_RADIUS = 250
-- Opcional: tras subir los PNG (Asset Manager), pega aquí sus ids para crear SurfaceAppearance PBR.
local MAPS = {
	WolfBody = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
}
-- Sonidos: sube los .ogg de sounds/ y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = { Howl = "", Growl = "", Snarl = "", Bite = "", Yelp = "" }

local RIG = __RIG__
local EYES = __EYES__
local SOURCES = {
	DragonAnimator = [=======[__ANIMATOR__]=======],
	Animations = [=======[__ANIMS__]=======],
	Brain = [=======[__BRAIN__]=======],
	Pack = [=======[__PACK__]=======],
	Client = [=======[__CLIENT__]=======],
}

local Selection = game:GetService("Selection")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local function v3(t)
	return Vector3.new(t[1], t[2], t[3])
end
local byName = {}
for _, b in ipairs(RIG) do
	byName[b.name] = b
end

-- 1. Localizar el modelo importado
local function looksLikeWolf(inst)
	return inst:FindFirstChild("WolfBody", true) and inst:FindFirstChild("Neck2", true) and inst:FindFirstChild("Tail4", true)
end
local source
for _, s in ipairs(Selection:Get()) do
	local cand = s:IsA("BasePart") and s.Parent or s
	if looksLikeWolf(cand) then
		source = cand
		break
	end
end
if not source then
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and looksLikeWolf(d) and not d:GetAttribute("RigScale") then
			source = d
			break
		end
	end
end
assert(source, "[Wolf] No encontré el modelo importado. Impórtalo con Import 3D (Rig Type: Custom) y selecciónalo.")

local bones, meshes, missing = {}, {}, {}
for _, d in ipairs(source:GetDescendants()) do
	if d:IsA("Bone") and not bones[d.Name] then
		bones[d.Name] = d
	end
end
for _, b in ipairs(RIG) do
	if not bones[b.name] then
		table.insert(missing, b.name)
	end
end
for _, name in ipairs({ "WolfBody" }) do
	local m = source:FindFirstChild(name, true)
	if m and m:IsA("MeshPart") then
		meshes[name] = m
	else
		table.insert(missing, name)
	end
end
assert(#missing == 0, "[Wolf] Faltan piezas o huesos: " .. table.concat(missing, ", ") .. ". ¿Rig Type estaba en Custom?")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar los lobos")
end)

-- 2. Calibración: escala y orientación con que el importador dejó el esqueleto
local function ratio(a, b)
	return (bones[a].WorldPosition - bones[b].WorldPosition).Magnitude / (v3(byName[a].head) - v3(byName[b].head)).Magnitude
end
local scale = (ratio("Hips", "Head") + ratio("LegFL_Paw", "LegBR_Paw") + ratio("Tail4", "EarL")) / 3
local ROTATIONS = {
	CFrame.identity,
	CFrame.Angles(0, math.pi, 0),
	CFrame.Angles(math.pi / 2, 0, 0),
	CFrame.Angles(-math.pi / 2, 0, 0),
	CFrame.Angles(0, math.pi, 0) * CFrame.Angles(math.pi / 2, 0, 0),
	CFrame.Angles(0, math.pi, 0) * CFrame.Angles(-math.pi / 2, 0, 0),
}
local R, origin, bestErr
for _, rot in ipairs(ROTATIONS) do
	local o = bones.Hips.WorldPosition - rot:VectorToWorldSpace(v3(byName.Hips.head) * scale)
	local err = 0
	for _, b in ipairs(RIG) do
		err = math.max(err, (o + rot:VectorToWorldSpace(v3(b.head) * scale) - bones[b.name].WorldPosition).Magnitude)
	end
	if not bestErr or err < bestErr then
		R, origin, bestErr = rot, o, err
	end
end
print(("[Wolf] escala del import: %.4f · error máximo de huesos: %.3f studs"):format(scale, bestErr))
if bestErr > 0.3 * scale then
	warn("[Wolf] Los huesos no coinciden con el rig esperado. Revisa la importación. Continúo igualmente.")
end
local function W(t)
	return origin + R:VectorToWorldSpace(v3(t) * scale)
end

-- 3. Modelo: WolfBody anclado (lo mueven los scripts, sin física)
local model = Instance.new("Model")
model.Name = "HollowWolf"
for _, child in ipairs(source:GetChildren()) do
	child.Parent = model
end
for name, m in pairs(meshes) do
	m.Parent = model
	m.CanCollide = false
	m.CanTouch = false
	m.CastShadow = true
	m.Anchored = name == "WolfBody"
	m.Massless = name ~= "WolfBody"
	m.CanQuery = true   -- para que las armas puedan acertarle
	if name ~= "WolfBody" then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = meshes.WolfBody
		weld.Part1 = m
		weld.Parent = m
	end
	local maps = MAPS[name]
	if maps and maps.ColorMap ~= "" then
		local sa = m:FindFirstChildOfClass("SurfaceAppearance") or Instance.new("SurfaceAppearance")
		sa.ColorMap = maps.ColorMap
		sa.NormalMap = maps.NormalMap
		sa.RoughnessMap = maps.RoughnessMap
		sa.Parent = m
	end
end
model.PrimaryPart = meshes.WolfBody
model.WorldPivot = CFrame.new(W({ byName.Hips.head[1], 0, byName.Hips.head[3] })) * R
for name, id in pairs(SOUND_IDS) do
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Volume = name == "Howl" and 1 or 0.7
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = name == "Howl" and 400 or 90
	s.Parent = meshes.WolfBody
end
-- ojos: puntos Neon amarillos con una luz diminuta; WolfClient los pega al hueso Head
for i, p in ipairs(EYES) do
	local dot = Instance.new("Part")
	dot.Name = i == 1 and "EyeL" or "EyeR"
	dot.Shape = Enum.PartType.Ball
	dot.Size = Vector3.one * 0.075 * scale
	dot.Material = Enum.Material.Neon
	dot.Color = Color3.fromRGB(255, 205, 80)
	dot.Anchored = true
	dot.CanCollide = false
	dot.CanQuery = false
	dot.CanTouch = false
	dot.CastShadow = false
	dot.CFrame = CFrame.new(W(p))
	dot:SetAttribute("Kind", "eye")
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 90)
	light.Range = 1.6 * scale
	light.Brightness = 0.8
	light.Parent = dot
	dot.Parent = model
end
model:SetAttribute("RigScale", 1)
if math.abs(scale - 1) > 1e-3 then
	model:ScaleTo(1 / scale)
end

-- 4. Organización del proyecto
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

local creatures = ensure(ReplicatedStorage, "Creatures")
local folder = ensure(creatures, "HollowWolf")
local prev = folder:FindFirstChild("HollowWolf")
if prev then
	prev:Destroy()
end
model.Parent = folder
local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({
	DisplayName = "Lobo hueco", Packs = PACKS, PackSize = PACK_SIZE, Damage = DAMAGE, AlphaDamage = ALPHA_DAMAGE,
	Health = HEALTH, AlphaHealth = ALPHA_HEALTH, AlphaScale = 1.35, NightOnly = NIGHT_ONLY, MaxBiters = 2,
	SpawnCenter = SPAWN_CENTER, SpawnRadius = SPAWN_RADIUS, Debug = false,
	-- ajustes del comportamiento (ver WolfBrain.Defaults)
	DetectDistance = 70, LoseDistance = 130, CircleMin = 9, CircleMax = 14, TrotSpeed = 13, RunSpeed = 28,
}) do
	settings:SetAttribute(k, v)
end
putScript(ensure(ReplicatedStorage, "Dragons"), "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(folder, "WolfBrain", "ModuleScript", SOURCES.Brain)
putScript(game:GetService("ServerScriptService"), "WolfPack", "Script", SOURCES.Pack)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "WolfClient", "LocalScript", SOURCES.Client)

local assets = ensure(ServerStorage, "DragonAssets")
local bak = assets:FindFirstChild("HollowWolf_Rig")
if bak then
	bak:Destroy()
end
local backup = model:Clone()
backup.Name = "HollowWolf_Rig"
backup.Parent = assets

if source.Parent and #source:GetChildren() == 0 then
	source:Destroy()
end
Selection:Set({ folder })
pcall(function()
	ChangeHistoryService:SetWaypoint("Lobos instalados")
end)
print(("[Wolf] Listo: %d huesos. Al anochecer salen %d manadas de %d lobos (un alfa cada una). Partes con la etiqueta SafeLight: zonas donde no entran."):format(#RIG, PACKS, PACK_SIZE))
