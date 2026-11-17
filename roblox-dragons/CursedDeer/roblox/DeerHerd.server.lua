--[[
	DeerHerd (Script) · ServerScriptService.DeerHerd

	Crea los ciervos del mapa y los mueve. Uno de cada 7 está maldito (nadie lo sabe hasta que se transforma).
	Todos los jugadores ven los mismos ciervos. El servidor decide (DeerBrain) y publica atributos;
	los clientes (DeerClient) animan los huesos, porque Roblox no replica Bone.Transform.

	Dónde aparecen: partes con la etiqueta "DeerSpawn" o dentro de Workspace.DeerSpawns (cada una es el centro
	de una manada). Si no hay, alrededor de Settings.SpawnCenter dentro de Settings.SpawnRadius.

	Atributos de cada Workspace.Deer.Deer_N:
	  Root (CFrame) · Anim, AnimFade, AnimStamp · Form ("deer"/"creature") · FormStamp
	  Visible, FadeTime, FadeStamp · HasAntlers
	(Que esté maldito NO se publica: un cliente no puede saberlo de antemano.)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local folder = ReplicatedStorage:WaitForChild("Creatures"):WaitForChild("CursedDeer")
local Brain = require(folder:WaitForChild("DeerBrain"))
local settings = folder:WaitForChild("Settings")
local template = folder:WaitForChild("CursedDeer") :: Model

local COUNT = settings:GetAttribute("Count") or 14
local RATIO = settings:GetAttribute("CursedRatio") or 7
local HERD_SIZE = settings:GetAttribute("HerdSize") or 4
local HOME_RADIUS = settings:GetAttribute("HomeRadius") or 45
local DAMAGE = settings:GetAttribute("Damage") or 0
local ANTLER_CHANCE = settings:GetAttribute("AntlerChance") or 0.5
local SPAWN_CENTER = settings:GetAttribute("SpawnCenter") or Vector3.new(0, 0, 0)
local SPAWN_RADIUS = settings:GetAttribute("SpawnRadius") or 220
local DEBUG = settings:GetAttribute("Debug") == true
local config = {}
for k, v in pairs(settings:GetAttributes()) do
	if Brain.Defaults[k] ~= nil and type(v) == type(Brain.Defaults[k]) then
		config[k] = v
	end
end

local container = workspace:FindFirstChild("Deer") or Instance.new("Folder")
container.Name = "Deer"
container.Parent = workspace
local scale = template:GetAttribute("RigScale") or 1

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function refreshFilter()
	local list = { container }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	rayParams.FilterDescendantsInstances = list
end
refreshFilter()

local function groundAt(x, z, fromY)
	local hit = workspace:Raycast(Vector3.new(x, fromY + 80, z), Vector3.new(0, -400, 0), rayParams)
	if hit and hit.Normal.Y > 0.55 and hit.Material ~= Enum.Material.Water then
		return hit.Position
	end
	return nil
end

-- centros de manada
local centers = {}
local tagged = CollectionService:GetTagged("DeerSpawn")
local sf = workspace:FindFirstChild("DeerSpawns")
if sf then
	for _, d in ipairs(sf:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(tagged, d)
		end
	end
end
for _, p in ipairs(tagged) do
	table.insert(centers, p.Position)
end
local rng = Random.new()
local function randomCenter()
	for _ = 1, 30 do
		local a = rng:NextNumber() * math.pi * 2
		local r = math.sqrt(rng:NextNumber()) * SPAWN_RADIUS
		local g = groundAt(SPAWN_CENTER.X + math.cos(a) * r, SPAWN_CENTER.Z + math.sin(a) * r, SPAWN_CENTER.Y)
		if g then
			return g
		end
	end
	return SPAWN_CENTER
end
local herds = math.max(1, math.ceil(COUNT / HERD_SIZE))
while #centers < herds do
	table.insert(centers, randomCenter())
end

local function nearestPlayerTo(pos)
	local best, bestD = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		local c = p.Character
		local h = c and c:FindFirstChild("HumanoidRootPart")
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if h and hum and hum.Health > 0 then
			local d = (h.Position - pos).Magnitude
			if d < bestD then
				best, bestD = h, d
			end
		end
	end
	return best, bestD
end

local function spotNear(center, radius, avoidPlayers)
	for _ = 1, 20 do
		local a = rng:NextNumber() * math.pi * 2
		local r = math.sqrt(rng:NextNumber()) * radius
		local g = groundAt(center.X + math.cos(a) * r, center.Z + math.sin(a) * r, center.Y)
		if g then
			local _, d = nearestPlayerTo(g)
			if not avoidPlayers or d > 90 then
				return g
			end
		end
	end
	return groundAt(center.X, center.Z, center.Y) or center
end

local cursedSet, cursedCount = Brain.PickCursed(COUNT, rng, RATIO)
if DEBUG then
	print(("[DeerHerd] %d ciervos, %d malditos"):format(COUNT, cursedCount))
end

local deer = {}
local stamp = 0
local function setAttr(d, k, v)
	d.model:SetAttribute(k, v)
end

for i = 1, COUNT do
	local home = centers[(i - 1) % #centers + 1]
	local pos = spotNear(home, 18, false)
	local m = template:Clone()
	m.Name = "Deer_" .. i
	for _, part in ipairs(m:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	local root = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
	local d = {
		model = m, home = home, root = root, brain = Brain.new(table.clone(config), Random.new(rng:NextInteger(1, 1e9)), cursedSet[i]),
		speed = 0, mode = "stop", target = nil, wander = pos, alarmT = -1e9, ground = 0, blocked = false, hitT = 0,
	}
	m:SetAttribute("Root", root)
	m:SetAttribute("Anim", "Graze")
	m:SetAttribute("AnimFade", 0)
	m:SetAttribute("AnimStamp", 0)
	m:SetAttribute("Form", "deer")
	m:SetAttribute("FormStamp", 0)
	m:SetAttribute("Visible", true)
	m:SetAttribute("FadeTime", 0)
	m:SetAttribute("FadeStamp", 0)
	m:SetAttribute("HasAntlers", rng:NextNumber() < ANTLER_CHANCE)
	m:PivotTo(root)
	m.Parent = container
	deer[i] = d
end

local function playSound(d, name)
	local body = d.model:FindFirstChild("DeerBody", true)
	local s = body and body:FindFirstChild(name)
	if s and s.SoundId ~= "" then
		s.PlaybackSpeed = 0.9 + rng:NextNumber() * 0.2
		s:Play()
	end
end

local function apply(d, cmds)
	for _, c in ipairs(cmds) do
		local k = c[1]
		stamp += 1
		if DEBUG then
			print("[DeerHerd]", d.model.Name, d.brain.state, k, tostring(c[2]), tostring(c[3]))
		end
		if k == "anim" then
			setAttr(d, "Anim", c[2])
			setAttr(d, "AnimFade", c[3] or 0.3)
			setAttr(d, "AnimStamp", stamp)
		elseif k == "move" then
			d.speed, d.mode = c[2] * scale, c[3]
		elseif k == "wanderTarget" then
			d.wander = spotNear(d.home, HOME_RADIUS, false)
		elseif k == "alarm" then
			for _, o in ipairs(deer) do
				if o ~= d and (o.root.Position - d.root.Position).Magnitude < 40 then
					o.alarmT = os.clock()
				end
			end
		elseif k == "form" then
			setAttr(d, "Form", c[2])
			setAttr(d, "FormStamp", stamp)
		elseif k == "sound" then
			playSound(d, c[2])
		elseif k == "vanish" or k == "appear" then
			setAttr(d, "FadeTime", c[2])
			setAttr(d, "Visible", k == "appear")
			setAttr(d, "FadeStamp", stamp)
		elseif k == "respawn" then
			local pos = spotNear(d.home, HOME_RADIUS, true)
			d.root = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
			setAttr(d, "Root", d.root)
		end
	end
end

-- movimiento de todos (cada frame, barato: sin física)
RunService.Heartbeat:Connect(function(dt)
	for _, d in ipairs(deer) do
		if d.mode ~= "stop" then
			local pos = d.root.Position
			local cur = d.root.LookVector * Vector3.new(1, 0, 1)
			local want
			if d.mode == "wander" then
				want = (d.wander - pos) * Vector3.new(1, 0, 1)
				if want.Magnitude < 2 then
					d.speed = 0
				end
			elseif d.target then
				local tp = d.target.Position
				want = (tp - pos) * Vector3.new(1, 0, 1)
				if d.mode == "flee" then
					want = -want
				end
			end
			if want and want.Magnitude > 0.1 then
				local maxTurn = math.rad(d.speed > 10 and 200 or 110) * dt
				local ang = math.atan2(cur:Cross(want.Unit).Y, cur:Dot(want.Unit))
				local dir = (CFrame.Angles(0, math.clamp(ang, -maxTurn, maxTurn), 0) * cur).Unit
				d.ground -= dt
				if d.ground <= 0 then
					d.ground = 0.25
					d.blocked = d.speed > 0 and workspace:Raycast(pos + Vector3.new(0, 2 * scale, 0), dir * 5 * scale, rayParams) ~= nil
					if d.blocked and d.mode == "flee" then   -- huyendo, esquiva girando
						dir = (CFrame.Angles(0, math.rad(rng:NextNumber() < 0.5 and 90 or -90), 0) * dir).Unit
						d.blocked = false
					end
				end
				if d.speed > 0 and not d.blocked then
					pos += dir * d.speed * dt
					if d.ground >= 0.24 then
						local g = groundAt(pos.X, pos.Z, pos.Y)
						if g then
							pos = Vector3.new(pos.X, g.Y, pos.Z)
						end
					end
				end
				d.root = CFrame.lookAt(pos, pos + dir)
			end
		end
		-- daño opcional al tocar (desactivado por defecto: Damage = 0)
		if DAMAGE > 0 and d.brain.form == "creature" and d.target and os.clock() - d.hitT > 1.2 then
			if (d.target.Position - d.root.Position).Magnitude < 5 * scale then
				local hum = d.target.Parent and d.target.Parent:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:TakeDamage(DAMAGE)
					d.hitT = os.clock()
				end
			end
		end
	end
end)

-- pensar y publicar 10 veces por segundo
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.1 then
		return
	end
	local step = acc
	acc = 0
	refreshFilter()
	local night = Lighting.ClockTime >= 18.5 or Lighting.ClockTime < 5.5
	for _, d in ipairs(deer) do
		local target, dist = nearestPlayerTo(d.root.Position)
		d.target = target
		local P = { dist = dist, alarm = os.clock() - d.alarmT < 1.5, night = night }
		apply(d, d.brain:Update(step, P))
		if d.model:GetAttribute("Root") ~= d.root then
			d.model:SetAttribute("Root", d.root)
		end
	end
end)
