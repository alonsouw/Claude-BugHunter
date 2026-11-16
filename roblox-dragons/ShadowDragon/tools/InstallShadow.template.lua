--[[
	INSTALADOR DEL DRAGÓN SOMBRÍO (rig de huesos) · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	Pasos:
	  1. Studio > pestaña Avatar (o Home) > Import 3D > ShadowDragon.fbx.
	     En el importador: Rig General > Rig Type = "Custom" (malla con huesos). No combines las mallas.
	     Pulsa Import. Aparece el modelo en Workspace con las mallas Body, Skull, Teeth, WingL y WingR y sus Bones.
	  2. Selecciona ese modelo en el Explorer.
	  3. View > Command Bar. Pega TODO este archivo y pulsa Enter.

	Versión 2 (remaster): cabeza en malla propia (Skull), dientes irregulares, ojos con luz roja controlada,
	animaciones nuevas y comportamiento de terror psicológico en el servidor: un solo dragón para todos.
	Si ya había un Dragón Sombrío v1 instalado, se guarda como ServerStorage.DragonAssets.ShadowDragon_v1.

	Resultado:
	  ReplicatedStorage.Dragons.ShadowDragon          (modelo con huesos, Settings, Animations)
	  ReplicatedStorage.Dragons.DragonAnimator          (motor de animación por datos, Motor6D o Bones)
	  ServerStorage.DragonAssets.ShadowDragon_Rig     (copia de seguridad)
	  Workspace.DragonShowcase.Stage_Shadow           (escenario + estatua de vista previa)
	  ReplicatedStorage.Dragons.ShadowDragon.ShadowBrain (lógica del comportamiento)
	  ServerScriptService.ShadowStalker                  (el dragón para todos: decide dónde está y qué hace)
	  StarterPlayer.StarterPlayerScripts.ShadowClient    (anima, fundidos, ojos, ambiente y silencios)
	  StarterPlayer.StarterPlayerScripts.ShadowShowcase  (solo si INSTALL_SHOWCASE = true)
]]

-- Opcional: escala final en studs por unidad del modelo (1 = unos 45 studs de largo y 19 de alto).
local DESIRED_SCALE = 1
-- Opcional: tras subir los PNG (Asset Manager), pega aquí sus ids para crear SurfaceAppearance PBR.
-- La vitrina de prueba (noche, botones 1-9) choca con un juego real: actívala solo para revisar animaciones.
local INSTALL_SHOWCASE = false
-- Visión nocturna de prueba con la tecla N (desactívala si tu juego ya tiene la suya).
local PROVIDE_NIGHT_VISION = true
-- Sonidos: sube los .ogg de la carpeta sounds/ (Asset Manager) y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = {
	Breath = "",        -- respiración grave en bucle, sale del cuerpo del dragón
	Creak = "",         -- crujido de articulaciones (cerca)
	Shriek = "",        -- chillido del rugido
	Whisper = "",       -- ambiente: susurro lejano, suena en puntos al azar alrededor del jugador
	DistantBreath = "", -- ambiente: respiración lejana
	Crack = "",         -- ambiente: rama que cruje
}
local MAPS = {
	Body = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	WingL = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	WingR = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	Skull = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
}
-- Teeth no lleva texturas: es marfil liso y ShadowClient la pasa a Neon tenue (la sonrisa brilla en la oscuridad).

local RIG = __RIG__
local EYES = __EYES__
local GROUND_Y = __GROUND_Y__
local SOURCES = {
	DragonAnimator = [=======[__ANIMATOR__]=======],
	Animations = [=======[__ANIMS__]=======],
	Showcase = [=======[__SHOWCASE__]=======],
	Brain = [=======[__BRAIN__]=======],
	Stalker = [=======[__STALKER__]=======],
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
local function looksLikeDragon(inst)
	return inst:FindFirstChild("Body", true) and inst:FindFirstChild("Neck3", true)
end
local source
for _, s in ipairs(Selection:Get()) do
	local cand = s:IsA("BasePart") and s.Parent or s
	if looksLikeDragon(cand) then
		source = cand
		break
	end
end
if not source then
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and looksLikeDragon(d) and not d:GetAttribute("RigScale") then
			source = d
			break
		end
	end
end
assert(source, "[Shadow] No encontré el modelo importado. Impórtalo con Import 3D (Rig Type: Custom) y selecciónalo.")

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
for _, name in ipairs({ "Body", "Skull", "Teeth", "WingL", "WingR" }) do
	local m = source:FindFirstChild(name, true)
	if m and m:IsA("MeshPart") then
		meshes[name] = m
	else
		table.insert(missing, name)
	end
end
assert(#missing == 0, "[Shadow] Faltan piezas o huesos: " .. table.concat(missing, ", ") .. ". ¿Rig Type estaba en Custom?")

pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar Dragón Sombrío")
end)

-- 2. Calibración: escala y orientación con que el importador dejó el esqueleto
local function ratio(a, b)
	return (bones[a].WorldPosition - bones[b].WorldPosition).Magnitude / (v3(byName[a].head) - v3(byName[b].head)).Magnitude
end
local scale = (ratio("Hips", "Head") + ratio("Hips", "Tail7") + ratio("WingL_Hand", "WingR_Hand")) / 3
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
print(("[Shadow] escala del import: %.4f · error máximo de huesos: %.3f studs"):format(scale, bestErr))
if bestErr > 0.6 * scale then
	warn("[Shadow] Los huesos no coinciden con el rig esperado. Revisa la importación. Continúo igualmente.")
end
local function W(t)
	return origin + R:VectorToWorldSpace(v3(t) * scale)
end

-- 3. Modelo: una sola asamblea (Body anclado, alas soldadas) para que los huesos deformen todas las mallas
local model = Instance.new("Model")
model.Name = "ShadowDragon"
for _, child in ipairs(source:GetChildren()) do
	child.Parent = model
end
for name, m in pairs(meshes) do
	m.Parent = model
	m.CanCollide = false
	m.CanTouch = false
	m.CastShadow = true
	m.Anchored = name == "Body"
	m.Massless = name ~= "Body"
	if name ~= "Body" then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = meshes.Body
		weld.Part1 = m
		weld.Parent = m
	end
	if name == "Teeth" then
		m.Material = Enum.Material.SmoothPlastic
		m.Color = Color3.fromRGB(222, 216, 202)
		m.CastShadow = false
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
model.WorldPivot = CFrame.new(W({ byName.Hips.head[1], GROUND_Y, byName.Hips.head[3] })) * R

-- Ojos: NO son globos oculares. Dos puntos rojos de Neon, pequeños y separados, que la vitrina mueve
-- con el hueso Head; de noche solo se ven ellos y la sonrisa.
local head = bones[EYES.bone]
for _, name in ipairs({ "EyeL", "EyeR" }) do
	local dot = Instance.new("Part")
	dot.Name = name .. "Point"
	dot.Shape = Enum.PartType.Ball
	dot.Size = Vector3.one * 0.1 * scale
	dot.Material = Enum.Material.Neon
	dot.Color = Color3.fromRGB(255, 20, 12)
	dot.Transparency = 0.4
	dot.Anchored = true
	dot.CanCollide = false
	dot.CanQuery = false
	dot.CanTouch = false
	dot.CastShadow = false
	dot.CFrame = CFrame.new(W(EYES[name]))
	dot:SetAttribute("Bone", EYES.bone)
	dot:SetAttribute("Kind", "eye")
	dot:SetAttribute("Offset", head.WorldCFrame:ToObjectSpace(dot.CFrame))
	dot:SetAttribute("LightBrightness", 1.4)
	-- brillo rojo intenso pero controlado: luz diminuta que solo tiñe la cuenca y el ceño
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 30, 20)
	light.Range = 2.4 * scale
	light.Brightness = 1.4
	light.Shadows = false
	light.Parent = dot
	dot.Parent = model
end

if math.abs(DESIRED_SCALE / scale - 1) > 1e-3 then
	model:ScaleTo(DESIRED_SCALE / scale)
	for _, p in ipairs(model:GetChildren()) do
		if p:GetAttribute("Offset") then
			local off = p:GetAttribute("Offset")
			p:SetAttribute("Offset", off.Rotation + off.Position * (DESIRED_SCALE / scale))
		end
	end
end
model:SetAttribute("RigScale", DESIRED_SCALE)
model:SetAttribute("Version", 2)
-- puntos de referencia para el servidor (en el espacio del pivote): cabeza y joroba
model:SetAttribute("HeadOffset", model.WorldPivot:PointToObjectSpace(bones.Head.WorldPosition))
model:SetAttribute("BodyOffset", model.WorldPivot:PointToObjectSpace(bones.Chest.WorldPosition))
-- sonidos que salen del cuerpo
for _, name in ipairs({ "Breath", "Creak", "Shriek" }) do
	local snd = Instance.new("Sound")
	snd.Name = name
	snd.SoundId = SOUND_IDS[name]
	snd.Looped = name == "Breath"
	snd.Volume = name == "Breath" and 0.5 or (name == "Shriek" and 0.9 or 0.6)
	snd.RollOffMode = Enum.RollOffMode.InverseTapered
	snd.RollOffMinDistance = 6 * DESIRED_SCALE
	snd.RollOffMaxDistance = (name == "Shriek" and 260 or 120) * DESIRED_SCALE
	snd.Parent = meshes.Body
end
model:SetAttribute("Species", "Umbrafex ridens")

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

local dragons = ensure(ReplicatedStorage, "Dragons")
for _, n in ipairs({ "AbyssalDragon", "ShadowDragon", "AberrantDragon", "AerialDragon", "AncientDragon", "ShadowDragon" }) do
	ensure(dragons, n)
end
local folder = dragons.ShadowDragon
local prev = folder:FindFirstChild("ShadowDragon")
if prev then
	local assetsFolder = ensure(ServerStorage, "DragonAssets")
	if (prev:GetAttribute("Version") or 1) < 2 and not assetsFolder:FindFirstChild("ShadowDragon_v1") then
		prev.Name = "ShadowDragon_v1" -- copia de seguridad de la versión original
		prev.Parent = assetsFolder
	else
		prev:Destroy()
	end
end
model.Parent = folder
local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({
	DisplayName = "Dragón Sombrío", Species = "Umbrafex ridens", Epithet = "La Sonrisa en la Oscuridad",
	WalkSpeed = 8, RunSpeed = 34, FlySpeed = 36, FlyHeight = 7, MaxHealth = 2200, AttackDamage = 70,
	AttackRange = 16, EyePointColor = Color3.fromRGB(255, 20, 12), GrinGlows = true,
	StalkerEnabled = true, Debug = false, ProvideNightVision = PROVIDE_NIGHT_VISION, TeethGlow = true,
	AmbientGroupName = "Ambient", MaxSightDistance = 320,
	-- ajustes del comportamiento (ver ShadowBrain.Defaults): distancias en studs, probabilidades por segundo
	VanishDistance = 38, StalkSpeed = 5, ChaseSpeed = 34, ChaseChance = 0.22, ChaseCooldown = 240,
}) do
	settings:SetAttribute(k, v)
end
putScript(dragons, "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(folder, "ShadowBrain", "ModuleScript", SOURCES.Brain)
local sps = ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts")
putScript(sps, "ShadowClient", "LocalScript", SOURCES.Client)
putScript(game:GetService("ServerScriptService"), "ShadowStalker", "Script", SOURCES.Stalker)
if INSTALL_SHOWCASE then
	putScript(sps, "ShadowShowcase", "LocalScript", SOURCES.Showcase)
elseif sps:FindFirstChild("ShadowShowcase") then
	sps.ShadowShowcase:Destroy()
end
if not folder:FindFirstChild("ShadowGaze") then
	local gaze = Instance.new("UnreliableRemoteEvent")
	gaze.Name = "ShadowGaze"
	gaze.Parent = folder
end
local amb = ensure(folder, "AmbientSounds")
for _, name in ipairs({ "Whisper", "DistantBreath", "Crack" }) do
	local snd = amb:FindFirstChild(name) or Instance.new("Sound")
	snd.Name = name
	snd.SoundId = SOUND_IDS[name]
	snd.Volume = 0.35
	snd.RollOffMode = Enum.RollOffMode.InverseTapered
	snd.RollOffMinDistance = 10
	snd.RollOffMaxDistance = 140
	snd.Parent = amb
end

local assets = ensure(ServerStorage, "DragonAssets")
local bak = assets:FindFirstChild("ShadowDragon_Rig")
if bak then
	bak:Destroy()
end
local backup = model:Clone()
backup.Name = "ShadowDragon_Rig"
backup.Parent = assets

local statue
if INSTALL_SHOWCASE then
	local showcase = ensure(workspace, "DragonShowcase")
	local stage = showcase:FindFirstChild("Stage_Shadow")
	if not stage then
		stage = Instance.new("Part")
		stage.Name = "Stage_Shadow"
		stage.Anchored = true
		stage.Size = Vector3.new(100, 1, 100)
		stage.CFrame = CFrame.new(0, 0.5, -300)
		stage.Material = Enum.Material.Slate
		stage.Color = Color3.fromRGB(22, 21, 24)
		stage.Parent = showcase
	end
	statue = showcase:FindFirstChild("ShadowDragon_Preview")
	if statue then
		statue:Destroy()
	end
	statue = model:Clone()
	statue.Name = "ShadowDragon_Preview"
	statue:PivotTo(stage.CFrame * CFrame.new(0, stage.Size.Y / 2, 0) * CFrame.Angles(0, math.rad(180), 0))
	statue.Parent = showcase
end

if source.Parent and #source:GetChildren() == 0 then
	source:Destroy()
end
Selection:Set({ statue or folder })
pcall(function()
	ChangeHistoryService:SetWaypoint("Dragón Sombrío instalado")
end)
print("[Shadow] Listo (v2): " .. #RIG .. " huesos, 5 mallas. Al pulsar Play el dragón aparecerá tras un rato, lejos y en la periferia; si lo miras se queda inmóvil." .. (PROVIDE_NIGHT_VISION and " Tecla N: visión nocturna de prueba." or ""))
