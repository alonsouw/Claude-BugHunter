--[[
	ArmorBuilder (ModuleScript) · ReplicatedStorage.Armor.ArmorBuilder

	Construye una armadura de bloques sobre un personaje (jugador R15/R6 o maniquí) a partir de ArmorData.
	Cada pieza se escala por eje al tamaño real de su parte del cuerpo y se suelda a ella.

	ArmorBuilder.Attach(character, setName) -> Folder "ArmorPieces"
	ArmorBuilder.Detach(character)
	Funciones puras (se prueban fuera de Roblox): ArmorBuilder.Region(partName, isR6), ArmorBuilder.Refund(prev, new, reduction)
]]

local ArmorBuilder = {}
local Data -- se carga perezosamente: ArmorData vive junto a este módulo

local function data()
	if not Data then
		Data = require(script.Parent:WaitForChild("ArmorData"))
	end
	return Data
end

-- Dónde cae una parte R15 en un cuerpo R6: parte R6, desplazamiento vertical del centro (en el tamaño por defecto
-- de la parte R6) y escala vertical. Las cadenas R15 (brazo superior, antebrazo, mano…) se reparten a lo largo de
-- la parte R6 equivalente, que mide 2 studs.
local R6_CHAINS = {
	{ r6 = "Torso", parts = { { "UpperTorso", 1.6 }, { "LowerTorso", 0.4 } } },
	{ r6 = "Right Arm", parts = { { "RightUpperArm", 1.169 }, { "RightLowerArm", 1.052 }, { "RightHand", 0.3 } } },
	{ r6 = "Left Arm", parts = { { "LeftUpperArm", 1.169 }, { "LeftLowerArm", 1.052 }, { "LeftHand", 0.3 } } },
	{ r6 = "Right Leg", parts = { { "RightUpperLeg", 1.217 }, { "RightLowerLeg", 1.193 }, { "RightFoot", 0.3 } } },
	{ r6 = "Left Leg", parts = { { "LeftUpperLeg", 1.217 }, { "LeftLowerLeg", 1.193 }, { "LeftFoot", 0.3 } } },
}
local R6_MAP = { Head = { r6 = "Head", y = 0, sy = 1 } }
for _, chain in ipairs(R6_CHAINS) do
	local total = 0
	for _, p in ipairs(chain.parts) do
		total += p[2]
	end
	local sy = 2 / total
	local top = 1
	for _, p in ipairs(chain.parts) do
		local h = p[2] * sy
		R6_MAP[p[1]] = { r6 = chain.r6, y = top - h / 2, sy = sy }
		top -= h
	end
end

function ArmorBuilder.Region(partName: string, isR6: boolean)
	if not isR6 then
		return partName, 0, 1
	end
	local m = R6_MAP[partName]
	if not m then
		return nil, 0, 1
	end
	return m.r6, m.y, m.sy
end

-- Reducción de daño: de la vida perdida (prev - new) se devuelve el porcentaje de la armadura.
function ArmorBuilder.Refund(prev: number, new: number, reduction: number): number
	if new >= prev or reduction <= 0 then
		return new
	end
	return new + (prev - new) * math.clamp(reduction, 0, 0.95)
end

function ArmorBuilder.Detach(character)
	local old = character:FindFirstChild("ArmorPieces")
	if old then
		old:Destroy()
	end
end

function ArmorBuilder.Attach(character, setName: string)
	local D = data()
	local set = D.sets[setName]
	assert(set, "Armadura desconocida: " .. tostring(setName))
	ArmorBuilder.Detach(character)
	local folder = Instance.new("Folder")
	folder.Name = "ArmorPieces"
	local isR6 = character:FindFirstChild("UpperTorso") == nil and character:FindFirstChild("Torso") ~= nil
	for _, p in ipairs(set.pieces) do
		local targetName, regionY, sy = ArmorBuilder.Region(p.part, isR6)
		local target = targetName and character:FindFirstChild(targetName)
		if target and target:IsA("BasePart") then
			-- escala por eje = tamaño real de la región / tamaño por defecto de la pieza en el maniquí
			local ref = D.dummy[p.part]
			local sc, centerY
			if p.part == "Head" then
				-- la cabeza clásica es una Part 2x1x1 con malla redonda (~1,2); solo se escala si es una MeshPart
				sc = target:IsA("MeshPart") and target.Size / Vector3.new(1.2, 1.2, 1.2) or Vector3.one
				centerY = 0
			elseif isR6 then
				local def = targetName == "Torso" and Vector3.new(2, 2, 1) or Vector3.new(1, 2, 1)
				local real = target.Size / def
				sc = Vector3.new(real.X, real.Y * sy, real.Z)
				centerY = regionY * real.Y
			else
				sc = target.Size / Vector3.new(ref[1], ref[2], ref[3])
				centerY = 0
			end
			local part = Instance.new("Part")
			part.Name = setName .. "_" .. p.part
			part.Size = Vector3.new(p.size[1] * sc.X, p.size[2] * sc.Y, p.size[3] * sc.Z)
			part.CFrame = target.CFrame
				* CFrame.new(0, centerY, 0)
				* CFrame.new(p.offset[1] * sc.X, p.offset[2] * sc.Y, p.offset[3] * sc.Z)
				* CFrame.Angles(math.rad(p.rot[1]), math.rad(p.rot[2]), math.rad(p.rot[3]))
			part.Color = Color3.fromRGB(p.color[1], p.color[2], p.color[3])
			part.Material = p.neon and Enum.Material.Neon or (Enum.Material[p.material] or Enum.Material.SmoothPlastic)
			part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			part.CanCollide, part.CanQuery, part.CanTouch, part.Massless = false, false, false, true
			part.Anchored = false
			part.CastShadow = not p.neon
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = target, part
			w.Parent = part
			part.Parent = folder
		end
	end
	folder.Parent = character
	return folder
end

return ArmorBuilder
