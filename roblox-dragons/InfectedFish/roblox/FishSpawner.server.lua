--[[
	FishSpawner (Script) · ServerScriptService.FishSpawner

	Crea y controla a los peces infectados (los mismos para todos los jugadores).
	  · Viven dentro de "zonas de agua": partes con la etiqueta "FishZone" o dentro de Workspace.FishZones.
	    La parte cubre el agua de la superficie (su cara de arriba) al fondo; suele ser invisible y sin colisión.
	  · Aparecen en bancos de 2 a 4 por zona (Settings.MaxPerZone); 1 de cada 8 es gigante (como máximo uno por zona).
	  · El servidor decide (FishBrain), los mueve con AlignPosition/AlignOrientation y publica el atributo Anim;
	    los clientes (FishClient) animan los Motor6D.
	  · Tienen Humanoid: cualquier arma les hace daño. Al morir se ponen panza arriba y flotan; reaparecen tras
	    Settings.RespawnDelay.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local folder = ReplicatedStorage:WaitForChild("Creatures"):WaitForChild("InfectedFish")
local Brain = require(folder:WaitForChild("FishBrain"))
local types = folder:WaitForChild("Types")
local settings = folder:WaitForChild("Settings")
local rng = Random.new()

local function S(k, d)
	local v = settings:GetAttribute(k)
	if v == nil then
		return d
	end
	return v
end
local MAX_PER_ZONE = S("MaxPerZone", 4)
local RESPAWN = S("RespawnDelay", 25)
local DEBUG = S("Debug", false)

local STATS = {
	Normal = { Health = 60, Damage = 12, Reach = 3.5, Detect = 45, SwimSpeed = 6, CircleSpeed = 11, ChaseSpeed = 17, Cooldown = 1.2,
		LeapRange = 16, LeapCooldown = 7, LeapHeight = 4, Scale = 1, Circle = true, Chance = 0.875 },
	Giant = { Health = 320, Damage = 30, Reach = 7, Detect = 70, SwimSpeed = 5, CircleSpeed = 9, ChaseSpeed = 14, Cooldown = 2.0,
		LeapRange = 24, LeapCooldown = 12, LeapHeight = 7, Scale = 2.2, Circle = false, Chance = 0.125 },
}
for name, st in pairs(STATS) do   -- Settings: "GiantHealth", "NormalChaseSpeed", "GiantChance"...
	for k, v in pairs(st) do
		local o = settings:GetAttribute(name .. k)
		if o ~= nil and type(o) == type(v) then
			st[k] = o
		end
	end
end
local LEAP_OUT, LEAP_BACK = 0.8, 0.6   -- segundos del arco hacia el jugador y de la vuelta al agua (suman FishBrain.LeapTime)

local container = workspace:FindFirstChild("InfectedFish") or Instance.new("Folder")
container.Name = "InfectedFish"
container.Parent = workspace

-- ---------------------------------------------------------------- zonas de agua
local function zones()
	local list = {}
	for _, z in ipairs(CollectionService:GetTagged("FishZone")) do
		if z:IsA("BasePart") then
			table.insert(list, z)
		end
	end
	local zf = workspace:FindFirstChild("FishZones")
	if zf then
		for _, d in ipairs(zf:GetDescendants()) do
			if d:IsA("BasePart") and not table.find(list, d) then
				table.insert(list, d)
			end
		end
	end
	return list
end
local function inZone(zone, pos, margin)
	local lp = zone.CFrame:PointToObjectSpace(pos)
	local h = zone.Size / 2 + Vector3.one * margin
	return math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y and math.abs(lp.Z) <= h.Z
end
local function clampZone(zone, pos, margin)
	local lp = zone.CFrame:PointToObjectSpace(pos)
	local h = zone.Size / 2
	local mx, my, mz = math.max(h.X - margin, 0), math.max(h.Y - margin, 0), math.max(h.Z - margin, 0)
	return zone.CFrame:PointToWorldSpace(Vector3.new(math.clamp(lp.X, -mx, mx), math.clamp(lp.Y, -my, my), math.clamp(lp.Z, -mz, mz)))
end
local function randomInZone(zone, margin)
	local h = zone.Size / 2
	local r = function(a)
		local m = math.max(a - margin, 0)
		return (rng:NextNumber() * 2 - 1) * m
	end
	return zone.CFrame:PointToWorldSpace(Vector3.new(r(h.X), r(h.Y), r(h.Z)))
end
local function surfaceY(zone)
	return zone.Position.Y + zone.Size.Y / 2
end
local function edgeDistance(zone, pos)   -- distancia horizontal de un punto al borde de la zona (0 si está encima)
	local lp = zone.CFrame:PointToObjectSpace(pos)
	local h = zone.Size / 2
	local dx, dz = math.max(0, math.abs(lp.X) - h.X), math.max(0, math.abs(lp.Z) - h.Z)
	return math.sqrt(dx * dx + dz * dz)
end

local function alive(p)
	local c = p.Character
	local h = c and c:FindFirstChild("HumanoidRootPart")
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if h and hum and hum.Health > 0 then
		return h, hum
	end
	return nil
end

-- ---------------------------------------------------------------- efectos
local function sound(f, name)
	local s = f.root:FindFirstChild(name)
	if s and s:IsA("Sound") and s.SoundId ~= "" then
		s:Play()
	end
end
local function splash(pos, scale)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one
	p.CFrame = CFrame.new(pos)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5 * scale), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.5, 0.9)
	e.Speed = NumberRange.new(10 * math.sqrt(scale), 20 * math.sqrt(scale))
	e.SpreadAngle = Vector2.new(35, 35)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -45, 0)
	e.Rate = 0
	e.Parent = p
	p.Parent = workspace
	e:Emit(math.floor(24 * scale))
	Debris:AddItem(p, 2)
end

-- ---------------------------------------------------------------- peces
local fishes = {}
local stamp = 0
local clock = 0

local function setAnim(f, name, fade)
	stamp += 1
	f.model:SetAttribute("Anim", name)
	f.model:SetAttribute("AnimFade", fade or 0.3)
	f.model:SetAttribute("AnimStamp", stamp)
end
local function headPos(f)
	return f.root.CFrame:PointToWorldSpace(Vector3.new(0, 0, -1.6 * f.st.Scale))
end
local function count(zone)
	local n, giant = 0, false
	for _, f in pairs(fishes) do
		if f.zone == zone and not f.dead then
			n += 1
			giant = giant or f.type == "Giant"
		end
	end
	return n, giant
end

local function spawnFish(zone, typeName, near)
	local st = STATS[typeName]
	local proto = types:FindFirstChild(typeName)
	if not proto then
		return
	end
	local model = proto:Clone()
	local root = model:WaitForChild("Root")
	local hum = model:FindFirstChildOfClass("Humanoid")
	local margin = 1.2 * st.Scale
	local pos = near and clampZone(zone, near + Vector3.new(rng:NextNumber() * 6 - 3, rng:NextNumber() * 2 - 1, rng:NextNumber() * 6 - 3), margin) or randomInZone(zone, margin)
	local heading = Vector3.new(rng:NextNumber() * 2 - 1, 0, rng:NextNumber() * 2 - 1)
	heading = heading.Magnitude > 0.1 and heading.Unit or Vector3.new(0, 0, -1)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = d ~= root
		end
	end
	model:PivotTo(CFrame.lookAt(pos, pos + heading))
	local att = Instance.new("Attachment")
	att.Name = "Swim"
	att.Parent = root
	local ap = Instance.new("AlignPosition")
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment
	ap.Attachment0 = att
	ap.MaxForce = 1e7
	ap.Responsiveness = 35
	ap.Position = pos
	ap.Parent = root
	local ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.MaxTorque = 1e7
	ao.Responsiveness = 25
	ao.CFrame = CFrame.lookAt(Vector3.zero, heading)
	ao.Parent = root
	if hum then
		hum.MaxHealth = st.Health
		hum.Health = st.Health
	end
	model.Parent = container
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	local f = {
		model = model, root = root, hum = hum, ap = ap, ao = ao, zone = zone, type = typeName, st = st, margin = margin,
		pos = pos, heading = heading, speed = st.SwimSpeed, want = st.SwimSpeed, mode = "wander", circAng = rng:NextNumber() * 6.28,
		lastHealth = st.Health, nextThink = 0,
		brain = Brain.new({
			Detect = st.Detect, Reach = st.Reach, Cooldown = st.Cooldown, SwimSpeed = st.SwimSpeed, CircleSpeed = st.CircleSpeed,
			ChaseSpeed = st.ChaseSpeed, Circle = st.Circle, LeapCooldown = st.LeapCooldown, LeapTime = LEAP_OUT + LEAP_BACK,
		}, Random.new(rng:NextInteger(1, 1e6))),
	}
	fishes[model] = f
	setAnim(f, "Swim", 0)
	model.Destroying:Connect(function()
		fishes[model] = nil
	end)
	return f
end

local function spawnSchool(zone)
	local n, hasGiant = count(zone)
	local room = MAX_PER_ZONE - n
	if room <= 0 then
		return
	end
	local center
	for _ = 1, 12 do   -- lejos de los jugadores si se puede
		center = randomInZone(zone, 2)
		local far = true
		for _, p in ipairs(Players:GetPlayers()) do
			local h = alive(p)
			if h and (h.Position - center).Magnitude < 25 then
				far = false
			end
		end
		if far then
			break
		end
	end
	for _ = 1, math.min(room, rng:NextInteger(2, 4)) do
		local giant = not hasGiant and rng:NextNumber() < STATS.Giant.Chance
		hasGiant = hasGiant or giant
		spawnFish(zone, giant and "Giant" or "Normal", center)
	end
end

-- ---------------------------------------------------------------- percepción y órdenes
local function perceive(f)
	local zone, st = f.zone, f.st
	local head = headPos(f)
	local surf = surfaceY(zone)
	local best, bestD, bestWater = nil, math.huge, false
	for _, p in ipairs(Players:GetPlayers()) do
		local h = alive(p)
		if h then
			local d = (h.Position - head).Magnitude
			local wet = inZone(zone, h.Position, 1.5)
			local flat = Vector3.new(h.Position.X - f.pos.X, 0, h.Position.Z - f.pos.Z).Magnitude
			local shore = not wet and edgeDistance(zone, h.Position) <= 5 and h.Position.Y <= surf + 10 and h.Position.Y >= surf - 3 and flat <= st.LeapRange
			if (wet and d <= st.Detect) or shore then
				-- prefiere a quien está en el agua; entre iguales, al más cercano (y al que ya perseguía)
				local score = d - (wet and 1000 or 0) - (f.target == p and 5 or 0)
				if score < bestD then
					best, bestD, bestWater = p, score, wet
				end
			end
		end
	end
	f.target = best
	local h = best and alive(best)
	local health = f.hum and f.hum.Health or 1
	local hurt = health < f.lastHealth - 0.5
	f.lastHealth = health
	local dist = h and (h.Position - head).Magnitude or math.huge
	return {
		hasTarget = h ~= nil, inWater = bestWater, canLeap = h ~= nil and not bestWater, dist = dist,
		hurt = hurt, dead = health <= 0,
	}
end

local function startLeap(f)
	local h = f.target and alive(f.target)
	if not h then
		return
	end
	local zone, sc = f.zone, f.st.Scale
	local surf = surfaceY(zone)
	local A = Vector3.new(f.pos.X, surf - 0.4 * sc, f.pos.Z)
	local B = h.Position + h.AssemblyLinearVelocity * Vector3.new(0.25, 0, 0.25)
	local inward = (A - Vector3.new(B.X, A.Y, B.Z))
	inward = inward.Magnitude > 0.1 and inward.Unit or -f.heading
	local back = clampZone(zone, A + inward * 5 - Vector3.new(0, 2 * sc, 0), f.margin)
	f.leap = { t = 0, A = A, B = B, H = f.st.LeapHeight + math.max(0, B.Y - A.Y), back = back, bitten = false, splashed = false }
	f.ap.Responsiveness = 120
	f.ao.Responsiveness = 60
	splash(Vector3.new(A.X, surf, A.Z), sc)
end

local function bite(f, reachMul)
	local h, hum = nil, nil
	if f.target then
		h, hum = alive(f.target)
	end
	if h and hum and (h.Position - headPos(f)).Magnitude <= f.st.Reach * reachMul then
		hum:TakeDamage(f.st.Damage)
		return true
	end
	return false
end

local function apply(f, orders)
	for _, o in ipairs(orders) do
		local kind = o[1]
		if kind == "anim" then
			setAnim(f, o[2], o[3])
		elseif kind == "move" then
			f.mode, f.want = o[2], o[3]
		elseif kind == "attack" then
			task.delay(o[2], function()
				if fishes[f.model] and not f.dead then
					bite(f, 1.4)
				end
			end)
		elseif kind == "leap" then
			startLeap(f)
		elseif kind == "sound" then
			sound(f, o[2])
		end
		if DEBUG and kind == "anim" then
			print(("[Fish] %s %s → %s"):format(f.type, f.model:GetFullName(), o[2]))
		end
	end
end

local function die(f)
	f.dead = true
	f.ap.Responsiveness = 6
	f.ao.Responsiveness = 4
	local zone = f.zone
	task.delay(10, function()
		if f.model.Parent then
			f.model:Destroy()
		end
	end)
	task.delay(RESPAWN, function()
		if zone.Parent then
			spawnSchool(zone)
		end
	end)
end

-- ---------------------------------------------------------------- movimiento (cada frame)
local function steer(f, dir, rate, dt)
	if dir.Magnitude < 1e-3 then
		return
	end
	dir = dir.Unit
	dir = Vector3.new(dir.X, math.clamp(dir.Y, -0.6, 0.6), dir.Z).Unit
	if f.heading:Dot(dir) < -0.98 then
		dir = (dir + f.heading:Cross(Vector3.yAxis) * 0.2).Unit
	end
	local a = math.acos(math.clamp(f.heading:Dot(dir), -1, 1))
	if a > 1e-3 then
		f.heading = f.heading:Lerp(dir, math.min(1, rate * dt / a)).Unit
	end
end

local function moveLeap(f, dt)
	local L = f.leap
	L.t += dt
	local p, dir
	if L.t < LEAP_OUT then
		local u = L.t / LEAP_OUT
		p = L.A:Lerp(L.B, u) + Vector3.new(0, 4 * L.H * u * (1 - u), 0)
		dir = (L.B - L.A) + Vector3.new(0, 4 * L.H * (1 - 2 * u), 0)
		if u >= 0.8 and not L.bitten then
			L.bitten = true
			if bite(f, 1.6) then
				sound(f, "Bite")
			end
		end
	elseif L.t < LEAP_OUT + LEAP_BACK then
		local u = (L.t - LEAP_OUT) / LEAP_BACK
		p = L.B:Lerp(L.back, u) + Vector3.new(0, 6 * u * (1 - u), 0)
		dir = (L.back - L.B) + Vector3.new(0, 6 * (1 - 2 * u), 0)
		if not L.splashed and p.Y <= surfaceY(f.zone) then
			L.splashed = true
			splash(Vector3.new(p.X, surfaceY(f.zone), p.Z), f.st.Scale)
			sound(f, "Splash")
		end
	else
		f.leap = nil
		f.pos = L.back
		f.ap.Responsiveness = 35
		f.ao.Responsiveness = 25
		local flat = Vector3.new(f.heading.X, 0, f.heading.Z)
		f.heading = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, -1)
		return
	end
	f.pos = p
	if dir.Magnitude > 1e-3 then
		f.heading = dir.Unit
	end
	f.ap.Position = p
	f.ao.CFrame = CFrame.lookAt(Vector3.zero, f.heading)
end

local function move(f, dt)
	if f.leap then
		moveLeap(f, dt)
		return
	end
	local zone = f.zone
	if f.dead then   -- flota panza arriba hasta la superficie
		local top = surfaceY(zone) - 0.35 * f.st.Scale
		f.pos = Vector3.new(f.pos.X, math.min(top, f.pos.Y + dt * 1.5), f.pos.Z)
		f.ap.Position = f.pos
		local flat = Vector3.new(f.heading.X, 0, f.heading.Z)
		flat = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, -1)
		f.ao.CFrame = CFrame.lookAt(Vector3.zero, flat) * CFrame.Angles(0, 0, math.pi)
		return
	end
	local h = f.target and alive(f.target)
	local T
	if f.mode == "chase" and h then
		T = clampZone(zone, h.Position, f.margin)
	elseif f.mode == "circle" and h then
		local center = clampZone(zone, h.Position, f.margin)
		local R = 6 + 2 * f.st.Scale
		f.circAng += dt * math.max(f.speed, 1) / R
		T = clampZone(zone, center + Vector3.new(math.cos(f.circAng) * R, 0, math.sin(f.circAng) * R), f.margin)
	elseif f.mode == "stop" then
		T = f.pos + f.heading
	else
		if not f.wp or (f.wp - f.pos).Magnitude < 3 * f.st.Scale or clock > (f.wpT or 0) then
			f.wp = randomInZone(zone, f.margin)
			f.wpT = clock + 10
		end
		T = f.wp
	end
	local want = f.mode == "stop" and 0.6 or f.want
	f.speed += (want - f.speed) * math.min(1, dt * 2.5)
	steer(f, T - f.pos, (f.mode == "chase" or f.mode == "circle") and 3.2 or 1.8, dt)
	local toT = (T - f.pos).Magnitude
	local sp = f.speed
	if f.mode == "chase" and toT < 1.5 then
		sp = sp * toT / 1.5   -- espera en el borde cuando el jugador está fuera del agua
	end
	f.pos = clampZone(zone, f.pos + f.heading * sp * dt, f.margin)
	f.ap.Position = f.pos
	f.ao.CFrame = CFrame.lookAt(Vector3.zero, f.heading)
end

RunService.Heartbeat:Connect(function(dt)
	clock += dt
	for _, f in pairs(fishes) do
		if f.zone.Parent == nil then
			f.model:Destroy()
		else
			if not f.dead and clock >= f.nextThink then   -- decide 10 veces por segundo
				local step = clock - (f.lastThink or clock - 0.1)
				f.lastThink = clock
				f.nextThink = clock + 0.1
				local P = perceive(f)
				apply(f, f.brain:Update(step, P))
				if P.dead then
					die(f)
				end
			end
			move(f, dt)
		end
	end
end)

-- población: cada zona mantiene su banco
local warned = false
task.spawn(function()
	while true do
		local list = zones()
		if #list == 0 and not warned then
			warned = true
			warn("[InfectedFish] No hay zonas de agua: pon una parte con la etiqueta FishZone (o dentro de Workspace.FishZones) que cubra el agua.")
		end
		for _, z in ipairs(list) do
			local n = count(z)
			if n == 0 then
				spawnSchool(z)
			end
		end
		task.wait(5)
	end
end)
