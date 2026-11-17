--[[
	INSTALADOR DEL CIERVO MALDITO · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	Pasos:
	  1. Studio > Avatar (o Home) > Import 3D > CursedDeer.fbx.
	     En el importador: Rig General > Rig Type = "Custom". No combines las mallas. Pulsa Import.
	     Aparece un modelo con las mallas DeerBody, HorrorBody, Antlers y Tentacles y sus Bones.
	  2. Selecciona ese modelo en el Explorer.
	  3. View > Command Bar. Pega TODO este archivo y pulsa Enter.
	  4. (Opcional) Pon partes con la etiqueta "DeerSpawn" o dentro de Workspace.DeerSpawns: cada una es una manada.

	Resultado:
	  ReplicatedStorage.Creatures.CursedDeer            (modelo, Settings, Animations, DeerBrain)
	  ReplicatedStorage.Dragons.DragonAnimator          (motor de animación, compartido con los dragones)
	  ServerScriptService.DeerHerd                      (crea los ciervos; 1 de cada 7 está maldito)
	  StarterPlayer.StarterPlayerScripts.DeerClient     (animación, transformación y movimiento suave)
	  ServerStorage.DragonAssets.CursedDeer_Rig         (copia de seguridad)
]]

-- Ajustes principales (también se pueden cambiar luego en ReplicatedStorage.Creatures.CursedDeer.Settings)
local COUNT = 14              -- ciervos en el mapa
local CURSED_RATIO = 7        -- uno de cada 7 está maldito
local DAMAGE = 0              -- daño de la criatura al tocar (0 = terror sin daño)
local NIGHT_ONLY = false      -- true: los malditos solo se transforman de noche
local SPAWN_CENTER = Vector3.new(0, 0, 0)
local SPAWN_RADIUS = 220
-- Opcional: tras subir los PNG (Asset Manager), pega aquí sus ids para crear SurfaceAppearance PBR.
local MAPS = {
	DeerBody = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	HorrorBody = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	Antlers = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	Tentacles = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
}
-- Sonidos: sube los .ogg de sounds/ y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = { Snort = "", Crack = "", Shriek = "" }

local RIG = __RIG__
local SOURCES = {
	DragonAnimator = [=======[__ANIMATOR__]=======],
	Animations = [=======[__ANIMS__]=======],
	Brain = [=======[__BRAIN__]=======],
	Herd = [=======[__HERD__]=======],
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
local function looksLikeDeer(inst)
	return inst:FindFirstChild("DeerBody", true) and inst:FindFirstChild("Neck3", true)
end
local source
for _, s in ipairs(Selection:Get()) do
	local cand = s:IsA("BasePart") and s.Parent or s
	if looksLikeDeer(cand) then
		source = cand
		break
	end
end
if not source then
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and looksLikeDeer(d) and not d:GetAttribute("RigScale") then
			source = d
			break
		end
	end
end
assert(source, "[Deer] No encontré el modelo importado. Impórtalo con Import 3D (Rig Type: Custom) y selecciónalo.")

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
for _, name in ipairs({ "DeerBody", "HorrorBody", "Antlers", "Tentacles" }) do
	local m = source:FindFirstChild(name, true)
	if m and m:IsA("MeshPart") then
		meshes[name] = m
	else
		table.insert(missing, name)
	end
end
assert(#missing == 0, "[Deer] Faltan piezas o huesos: " .. table.concat(missing, ", ") .. ". ¿Rig Type estaba en Custom?")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar el ciervo maldito")
end)

-- 2. Calibración: escala y orientación con que el importador dejó el esqueleto
local function ratio(a, b)
	return (bones[a].WorldPosition - bones[b].WorldPosition).Magnitude / (v3(byName[a].head) - v3(byName[b].head)).Magnitude
end
local scale = (ratio("Hips", "Head") + ratio("LegFL_Hoof", "LegBR_Hoof") + ratio("Tail", "EarL")) / 3
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
print(("[Deer] escala del import: %.4f · error máximo de huesos: %.3f studs"):format(scale, bestErr))
if bestErr > 0.3 * scale then
	warn("[Deer] Los huesos no coinciden con el rig esperado. Revisa la importación. Continúo igualmente.")
end
local function W(t)
	return origin + R:VectorToWorldSpace(v3(t) * scale)
end

-- 3. Modelo: DeerBody anclado y el resto soldado, para que los huesos deformen todas las mallas a la vez
local model = Instance.new("Model")
model.Name = "CursedDeer"
for _, child in ipairs(source:GetChildren()) do
	child.Parent = model
end
for name, m in pairs(meshes) do
	m.Parent = model
	m.CanCollide = false
	m.CanTouch = false
	m.CastShadow = true
	m.Anchored = name == "DeerBody"
	m.Massless = name ~= "DeerBody"
	-- la forma de criatura empieza oculta (DeerClient la muestra al transformarse)
	m.Transparency = 0
	if name ~= "DeerBody" then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = meshes.DeerBody
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
model.PrimaryPart = meshes.DeerBody
model.WorldPivot = CFrame.new(W({ byName.Hips.head[1], 0, byName.Hips.head[3] })) * R
for name, id in pairs(SOUND_IDS) do
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Volume = name == "Shriek" and 1 or 0.6
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = name == "Shriek" and 220 or 90
	s.Parent = meshes.DeerBody
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
local folder = ensure(creatures, "CursedDeer")
local prev = folder:FindFirstChild("CursedDeer")
if prev then
	prev:Destroy()
end
model.Parent = folder
local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({
	DisplayName = "Ciervo", Count = COUNT, CursedRatio = CURSED_RATIO, Damage = DAMAGE, NightOnly = NIGHT_ONLY,
	SpawnCenter = SPAWN_CENTER, SpawnRadius = SPAWN_RADIUS, HerdSize = 4, HomeRadius = 45, AntlerChance = 0.5, Debug = false,
	-- ajustes del comportamiento (ver DeerBrain.Defaults)
	AlertDistance = 45, FleeDistance = 24, TriggerMin = 12, TriggerMax = 26, StalkSpeed = 7, ChaseSpeed = 27, LoseDistance = 150,
}) do
	settings:SetAttribute(k, v)
end
putScript(ensure(ReplicatedStorage, "Dragons"), "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(folder, "DeerBrain", "ModuleScript", SOURCES.Brain)
putScript(game:GetService("ServerScriptService"), "DeerHerd", "Script", SOURCES.Herd)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "DeerClient", "LocalScript", SOURCES.Client)

local assets = ensure(ServerStorage, "DragonAssets")
local bak = assets:FindFirstChild("CursedDeer_Rig")
if bak then
	bak:Destroy()
end
local backup = model:Clone()
backup.Name = "CursedDeer_Rig"
backup.Parent = assets

if source.Parent and #source:GetChildren() == 0 then
	source:Destroy()
end
Selection:Set({ folder })
pcall(function()
	ChangeHistoryService:SetWaypoint("Ciervo maldito instalado")
end)
print(("[Deer] Listo: %d huesos, 4 mallas. Al pulsar Play aparecen %d ciervos; %d de ellos están malditos."):format(#RIG, COUNT, math.max(COUNT >= 4 and 1 or 0, math.floor(COUNT / CURSED_RATIO + 0.5))))
