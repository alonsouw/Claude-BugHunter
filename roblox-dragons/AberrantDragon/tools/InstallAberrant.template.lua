--[[
	INSTALADOR DEL DRAGÓN ABERRANTE · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	Pasos:
	  1. Studio > pestaña Avatar (o Home) > Import 3D > AberrantDragon.fbx (o .glb).
	     En el importador: deja "Rig General > Rig Type" en "No Rig" y NO combines mallas.
	     Pulsa Import. Aparece el modelo en Workspace.
	  2. Selecciona ese modelo en el Explorer.
	  3. View > Command Bar. Pega TODO este archivo y pulsa Enter.

	Resultado:
	  ReplicatedStorage.Dragons.AberrantDragon          (rig con Motor6D, Settings, Animations)
	  ReplicatedStorage.Dragons.DragonAnimator          (motor de animación por datos)
	  ServerStorage.DragonAssets.AberrantDragon_Rig     (copia de seguridad del rig)
	  Workspace.DragonShowcase                          (escenario + estatua de vista previa)
	  StarterPlayer.StarterPlayerScripts.DragonShowcase (vitrina con botones 1-9)
	Pulsa Play para ver al dragón y probar sus animaciones.
]]

-- Opcional: escala final en studs por unidad del modelo (1 = 23 studs de largo).
local DESIRED_SCALE = 1
-- Opcional: tras subir los PNG del atlas (Asset Manager), pega aquí sus ids "rbxassetid://..."
-- para crear SurfaceAppearance PBR en cada pieza.
local MAPS = { ColorMap = "", NormalMap = "", RoughnessMap = "" }

local RIG = __RIG__
local GROUND_Y = __GROUND_Y__
local SOURCES = {
	DragonAnimator = [=======[__ANIMATOR__]=======],
	Animations = [=======[__ANIMS__]=======],
	Showcase = [=======[__SHOWCASE__]=======],
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
for _, e in ipairs(RIG) do
	byName[e.name] = e
end

-- 1. Localizar el modelo importado
local function findParts(container)
	local found, missing = {}, {}
	for _, e in ipairs(RIG) do
		local p = container.Name == e.name and container:IsA("BasePart") and container or container:FindFirstChild(e.name, true)
		if p and p:IsA("BasePart") then
			found[e.name] = p
		else
			table.insert(missing, e.name)
		end
	end
	return found, missing
end

local source
for _, s in ipairs(Selection:Get()) do
	local cand = s:IsA("BasePart") and s.Parent or s
	if cand:FindFirstChild("WingL_Hand", true) then
		source = cand
		break
	end
end
if not source then
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and d:FindFirstChild("WingL_Hand", true) and d:FindFirstChild("Hips", true) and not d:FindFirstChildWhichIsA("Motor6D", true) then
			source = d
			break
		end
	end
end
assert(source, "[Aberrant] No encontré el modelo importado. Impórtalo con Import 3D y selecciónalo antes de ejecutar.")
local parts, missing = findParts(source)
assert(#missing == 0, "[Aberrant] Faltan piezas en el modelo importado: " .. table.concat(missing, ", ") .. ". ¿Se combinaron las mallas al importar?")

pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar Dragón Aberrante")
end)

-- 2. Calibración: escala y orientación con que el importador dejó el modelo
local function ratio(a, b)
	return (parts[a].Position - parts[b].Position).Magnitude / (v3(byName[a].center) - v3(byName[b].center)).Magnitude
end
local scale = (ratio("Head", "Tail4") + ratio("LegL_Foot", "WingL_Hand") + ratio("ArmR_Hand", "WingR")) / 3
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
	local o = parts.Hips.Position - rot:VectorToWorldSpace(v3(byName.Hips.center) * scale)
	local err = 0
	for _, e in ipairs(RIG) do
		err = math.max(err, (o + rot:VectorToWorldSpace(v3(e.center) * scale) - parts[e.name].Position).Magnitude)
	end
	if not bestErr or err < bestErr then
		R, origin, bestErr = rot, o, err
	end
end
print(("[Aberrant] escala del import: %.4f · error máximo de posición: %.3f studs"):format(scale, bestErr))
if bestErr > 0.6 * scale then
	warn("[Aberrant] Las piezas no coinciden con el rig esperado. ¿Se movió o se rotó alguna pieza después de importar? Continúo igualmente.")
end
local function W(t)
	return origin + R:VectorToWorldSpace(v3(t) * scale)
end

-- 3. Construir el rig: Root anclado + Motor6D en cada articulación
local model = Instance.new("Model")
model.Name = "AberrantDragon"
local hips = byName.Hips
local root = Instance.new("Part")
root.Name = "Root"
root.Size = Vector3.new(2, 1, 2) * scale
root.Transparency = 1
root.Anchored = true
root.CanCollide = false
root.CanQuery = false
root.CanTouch = false
root.CFrame = CFrame.new(W({ hips.pivot[1], GROUND_Y, hips.pivot[3] })) * R
root.Parent = model
model.PrimaryPart = root

for _, e in ipairs(RIG) do
	local p = parts[e.name]
	p.Parent = model
end
for _, e in ipairs(RIG) do
	local p = parts[e.name]
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = true
	local p0 = e.parent and parts[e.parent] or root
	local pivot = CFrame.new(W(e.pivot)) * R
	local m = Instance.new("Motor6D")
	m.Name = e.name
	m.Part0 = p0
	m.Part1 = p
	m.C0 = p0.CFrame:ToObjectSpace(pivot)
	m.C1 = p.CFrame:ToObjectSpace(pivot)
	m.Parent = p
	if string.sub(e.name, 1, 3) == "Eye" then
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(214, 255, 90)
		pcall(function()
			p.TextureID = ""
		end)
		p.CastShadow = false
	elseif MAPS.ColorMap ~= "" then
		local sa = p:FindFirstChildOfClass("SurfaceAppearance") or Instance.new("SurfaceAppearance")
		sa.ColorMap = MAPS.ColorMap
		sa.NormalMap = MAPS.NormalMap
		sa.RoughnessMap = MAPS.RoughnessMap
		sa.Parent = p
	end
end
local glow = Instance.new("PointLight")
glow.Color = Color3.fromRGB(214, 255, 90)
glow.Range = 7 * scale
glow.Brightness = 1.6
glow.Shadows = false
glow.Parent = parts.Eye1

-- Escala final deseada (Model:ScaleTo también escala los Motor6D)
if math.abs(DESIRED_SCALE / scale - 1) > 1e-3 then
	model:ScaleTo(DESIRED_SCALE / scale)
end
model:SetAttribute("RigScale", DESIRED_SCALE)
model:SetAttribute("Species", "Xethra contorta")

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
for _, n in ipairs({ "AbyssalDragon", "PredatorDragon", "AberrantDragon", "AerialDragon", "AncientDragon", "ShadowDragon" }) do
	ensure(dragons, n)
end
local folder = dragons.AberrantDragon
local prev = folder:FindFirstChild("AberrantDragon")
if prev then
	prev:Destroy()
end
model.Parent = folder

local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({
	DisplayName = "Dragón Aberrante", Species = "Xethra contorta", Epithet = "El Torcido",
	WalkSpeed = 9, RunSpeed = 22, FlySpeed = 34, FlyHeight = 6, MaxHealth = 1800, AttackDamage = 45,
	AttackRange = 9, EyeColor = Color3.fromRGB(214, 255, 90),
}) do
	settings:SetAttribute(k, v)
end

putScript(dragons, "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "DragonShowcase", "LocalScript", SOURCES.Showcase)

local assets = ensure(ServerStorage, "DragonAssets")
local bak = assets:FindFirstChild("AberrantDragon_Rig")
if bak then
	bak:Destroy()
end
local backup = model:Clone()
backup.Name = "AberrantDragon_Rig"
backup.Parent = assets

local showcase = ensure(workspace, "DragonShowcase")
local stage = showcase:FindFirstChild("Stage")
if not stage then
	stage = Instance.new("Part")
	stage.Name = "Stage"
	stage.Anchored = true
	stage.Size = Vector3.new(70, 1, 70)
	stage.CFrame = CFrame.new(0, 0.5, -60)
	stage.Material = Enum.Material.Slate
	stage.Color = Color3.fromRGB(28, 26, 30)
	stage.Parent = showcase
end
local statue = showcase:FindFirstChild("AberrantDragon_Preview")
if statue then
	statue:Destroy()
end
statue = model:Clone()
statue.Name = "AberrantDragon_Preview"
statue:PivotTo(stage.CFrame * CFrame.new(0, stage.Size.Y / 2, 0) * CFrame.Angles(0, math.rad(200), 0))
statue.Parent = showcase

if source.Parent and #source:GetDescendants() == 0 then
	source:Destroy()
end
Selection:Set({ statue })
pcall(function()
	ChangeHistoryService:SetWaypoint("Dragón Aberrante instalado")
end)
print("[Aberrant] Listo: rig con " .. #RIG .. " Motor6D en ReplicatedStorage.Dragons.AberrantDragon. Pulsa Play y usa los botones 1-9.")
