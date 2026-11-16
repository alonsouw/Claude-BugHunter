--[[
	INSTALADOR DEL DRAGÓN DEPREDADOR (rig de huesos) · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	Pasos:
	  1. Studio > pestaña Avatar (o Home) > Import 3D > PredatorDragon.fbx.
	     En el importador: Rig General > Rig Type = "Custom" (malla con huesos). No combines las mallas.
	     Pulsa Import. Aparece el modelo en Workspace con las mallas Body, WingL y WingR y sus Bones.
	  2. Selecciona ese modelo en el Explorer.
	  3. View > Command Bar. Pega TODO este archivo y pulsa Enter.

	Resultado:
	  ReplicatedStorage.Dragons.PredatorDragon          (modelo con huesos, Settings, Animations)
	  ReplicatedStorage.Dragons.DragonAnimator          (motor de animación por datos, Motor6D o Bones)
	  ServerStorage.DragonAssets.PredatorDragon_Rig     (copia de seguridad)
	  Workspace.DragonShowcase.Stage_Predator           (escenario + estatua de vista previa)
	  StarterPlayer.StarterPlayerScripts.PredatorShowcase (vitrina nocturna, botones 1-9)
]]

-- Opcional: escala final en studs por unidad del modelo (1 = unos 46 studs de largo).
local DESIRED_SCALE = 1
-- Opcional: tras subir los PNG (Asset Manager), pega aquí sus ids para crear SurfaceAppearance PBR.
local MAPS = {
	Body = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	WingL = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
	WingR = { ColorMap = "", NormalMap = "", RoughnessMap = "" },
}

local RIG = __RIG__
local EYES = __EYES__
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
assert(source, "[Predator] No encontré el modelo importado. Impórtalo con Import 3D (Rig Type: Custom) y selecciónalo.")

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
for _, name in ipairs({ "Body", "WingL", "WingR" }) do
	local m = source:FindFirstChild(name, true)
	if m and m:IsA("MeshPart") then
		meshes[name] = m
	else
		table.insert(missing, name)
	end
end
assert(#missing == 0, "[Predator] Faltan piezas o huesos: " .. table.concat(missing, ", ") .. ". ¿Rig Type estaba en Custom?")

pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar Dragón Depredador")
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
print(("[Predator] escala del import: %.4f · error máximo de huesos: %.3f studs"):format(scale, bestErr))
if bestErr > 0.6 * scale then
	warn("[Predator] Los huesos no coinciden con el rig esperado. Revisa la importación. Continúo igualmente.")
end
local function W(t)
	return origin + R:VectorToWorldSpace(v3(t) * scale)
end

-- 3. Modelo: una sola asamblea (Body anclado, alas soldadas) para que los huesos deformen todas las mallas
local model = Instance.new("Model")
model.Name = "PredatorDragon"
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

-- Ojos: NO son globos oculares. Dos puntos diminutos de Neon que la vitrina mueve con el hueso Head;
-- de día son casi invisibles y de noche son lo único que se ve.
local head = bones[EYES.bone]
for _, name in ipairs({ "EyeL", "EyeR" }) do
	local dot = Instance.new("Part")
	dot.Name = name .. "Point"
	dot.Shape = Enum.PartType.Ball
	dot.Size = Vector3.one * 0.07 * scale
	dot.Material = Enum.Material.Neon
	dot.Color = Color3.fromRGB(255, 255, 255)
	dot.Transparency = 0.93
	dot.Anchored = true
	dot.CanCollide = false
	dot.CanQuery = false
	dot.CanTouch = false
	dot.CastShadow = false
	dot.CFrame = CFrame.new(W(EYES[name]))
	dot:SetAttribute("Bone", EYES.bone)
	dot:SetAttribute("Offset", head.WorldCFrame:ToObjectSpace(dot.CFrame))
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
model:SetAttribute("Species", "Karnathys sanguifauces")

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
local folder = dragons.PredatorDragon
local prev = folder:FindFirstChild("PredatorDragon")
if prev then
	prev:Destroy()
end
model.Parent = folder
local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({
	DisplayName = "Dragón Depredador", Species = "Karnathys sanguifauces", Epithet = "Fauce Roja",
	WalkSpeed = 12, RunSpeed = 30, FlySpeed = 40, FlyHeight = 7, MaxHealth = 2600, AttackDamage = 60,
	AttackRange = 12, EyePointColor = Color3.fromRGB(255, 255, 255),
}) do
	settings:SetAttribute(k, v)
end
putScript(dragons, "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "PredatorShowcase", "LocalScript", SOURCES.Showcase)

local assets = ensure(ServerStorage, "DragonAssets")
local bak = assets:FindFirstChild("PredatorDragon_Rig")
if bak then
	bak:Destroy()
end
local backup = model:Clone()
backup.Name = "PredatorDragon_Rig"
backup.Parent = assets

local showcase = ensure(workspace, "DragonShowcase")
local stage = showcase:FindFirstChild("Stage_Predator")
if not stage then
	stage = Instance.new("Part")
	stage.Name = "Stage_Predator"
	stage.Anchored = true
	stage.Size = Vector3.new(100, 1, 100)
	stage.CFrame = CFrame.new(0, 0.5, -150)
	stage.Material = Enum.Material.Slate
	stage.Color = Color3.fromRGB(28, 26, 30)
	stage.Parent = showcase
end
local statue = showcase:FindFirstChild("PredatorDragon_Preview")
if statue then
	statue:Destroy()
end
statue = model:Clone()
statue.Name = "PredatorDragon_Preview"
statue:PivotTo(stage.CFrame * CFrame.new(0, stage.Size.Y / 2, 0) * CFrame.Angles(0, math.rad(180), 0))
statue.Parent = showcase

if source.Parent and #source:GetChildren() == 0 then
	source:Destroy()
end
Selection:Set({ statue })
pcall(function()
	ChangeHistoryService:SetWaypoint("Dragón Depredador instalado")
end)
print("[Predator] Listo: " .. #RIG .. " huesos, 3 mallas. Pulsa Play: noche cerrada, solo dos puntos blancos te observan. Botones 1-9 y L para la luz.")
