--[[
	InfectedSpawner (Script) · ServerScriptService.InfectedSpawner

	Crea y controla a los infectados (los mismos para todos los jugadores). Son personajes de bloques con Humanoid:
	reciben el daño de cualquier arma, caminan con física y persiguen con PathfindingService.
	El servidor decide (InfectedBrain) y publica el atributo Anim; los clientes (InfectedClient) animan los Motor6D.

	Tipos (ReplicatedStorage.Creatures.Infected.Types): Walker, Runner, Bloater, Screamer, Brute.
	Dónde aparecen: partes con la etiqueta "InfectedSpawn" o dentro de Workspace.InfectedSpawns; si no hay, alrededor
	de Settings.SpawnCenter, lejos de los jugadores. Los muertos reaparecen tras Settings.RespawnDelay.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local folder = ReplicatedStorage:WaitForChild("Creatures"):WaitForChild("Infected")
local Brain = require(folder:WaitForChild("InfectedBrain"))
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
local MAX_ALIVE = S("MaxAlive", 20)
local RESPAWN = S("RespawnDelay", 20)
local NIGHT_ONLY = S("NightOnly", false)
local SPAWN_CENTER, SPAWN_RADIUS = S("SpawnCenter", Vector3.zero), S("SpawnRadius", 200)
local DEBUG = S("Debug", false)

local STATS = {
	Walker = { Health = 100, Damage = 15, WalkSpeed = 5, ChaseSpeed = 9, Detect = 55, Reach = 4, Cooldown = 1.4, Scale = 1, Weight = 0.5 },
	Runner = { Health = 60, Damage = 10, WalkSpeed = 7, ChaseSpeed = 22, Detect = 75, Reach = 4, Cooldown = 0.9, Scale = 1, Weight = 0.2, ChaseAnim = "Run" },
	Bloater = { Health = 140, Damage = 10, WalkSpeed = 4, ChaseSpeed = 6, Detect = 45, Reach = 4.5, Cooldown = 1.8, Scale = 1, Weight = 0.12, ExplodeDamage = 35, ExplodeRadius = 12 },
	Screamer = { Health = 70, Damage = 8, WalkSpeed = 6, ChaseSpeed = 13, Detect = 80, Reach = 5, Cooldown = 1.2, Scale = 1, Weight = 0.1, ChaseAnim = "Run", CanScream = true, ScreamRadius = 120, ScreamCooldown = 25 },
	Brute = { Health = 400, Damage = 35, WalkSpeed = 5, ChaseSpeed = 8, Detect = 60, Reach = 7, Cooldown = 2.6, Scale = 1.4, Weight = 0.08, AttackAnim = "Slam", SlamRadius = 8 },
}
for name, st in pairs(STATS) do   -- Settings: "BruteHealth", "RunnerChaseSpeed", "WalkerWeight"...
	for k, v in pairs(st) do
		local o = settings:GetAttribute(name .. k)
		if o ~= nil and type(o) == type(v) then
			st[k] = o
		end
	end
end

local container = workspace:FindFirstChild("Infected") or Instance.new("Folder")
container.Name = "Infected"
container.Parent = workspace

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
local function groundAt(x, z, fromY)
	local hit = workspace:Raycast(Vector3.new(x, fromY + 60, z), Vector3.new(0, -300, 0), rayParams)
	if hit and hit.Normal.Y > 0.55 and hit.Material ~= Enum.Material.Water then
		return hit.Position
	end
	return nil
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
local function isNight()
	return Lighting.ClockTime >= 18.5 or Lighting.ClockTime < 5.5
end

local function pickType()
	local total = 0
	for _, st in pairs(STATS) do
		total += st.Weight
	end
	local x = rng:NextNumber() * total
	for name, st in pairs(STATS) do
		x -= st.Weight
		if x <= 0 then
			return name
		end
	end
	return "Walker"
end

local function spawnPoint()
	local pts = CollectionService:GetTagged("InfectedSpawn")
	local sf = workspace:FindFirstChild("InfectedSpawns")
	if sf then
		for _, d in ipairs(sf:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(pts, d)
			end
		end
	end
	for _ = 1, 25 do
		local c
		if #pts > 0 then
			c = pts[rng:NextInteger(1, #pts)].Position + Vector3.new(rng:NextNumber() * 10 - 5, 0, rng:NextNumber() * 10 - 5)
		else
			local a, r = rng:NextNumber() * math.pi * 2, math.sqrt(rng:NextNumber()) * SPAWN_RADIUS
			c = SPAWN_CENTER + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		end
		local g = groundAt(c.X, c.Z, c.Y)
		local far = true
		for _, p in ipairs(Players:GetPlayers()) do
			local h = alive(p)
			if h and g and (h.Position - g).Magnitude < 40 then
				far = false
			end
		end
		if g and far then
			return g
		end
	end
	return nil
end

local zombies = {}
local stamp = 0

local function sound(z, name)
	local s = z.hrp:FindFirstChild(name)
	if s and s.SoundId ~= "" then
		s.PlaybackSpeed = (z.kind == "Brute" and 0.8 or (z.kind == "Runner" and 1.15 or 1)) * (0.9 + rng:NextNumber() * 0.2)
		s:Play()
	end
end

local function setAnim(z, name, fade)
	stamp += 1
	z.model:SetAttribute("Anim", name)
	z.model:SetAttribute("AnimFade", fade or 0.3)
	z.model:SetAttribute("AnimStamp", stamp)
end

local function explode(z)   -- el hinchado revienta: daño en área con caída por distancia y nube verde
	local st = z.stats
	local pos = z.hrp.Position
	sound(z, "Pop")
	local cloud = Instance.new("Part")
	cloud.Anchored, cloud.CanCollide, cloud.CanQuery, cloud.CanTouch, cloud.Transparency = true, false, false, false, 1
	cloud.Size = Vector3.one
	cloud.Position = pos
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(150, 190, 60), Color3.fromRGB(80, 110, 30))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(1.5, 2.5)
	pe.Speed = NumberRange.new(6, 14)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Rate = 0
	pe.Parent = cloud
	cloud.Parent = workspace
	pe:Emit(60)
	Debris:AddItem(cloud, 3)
	for _, p in ipairs(Players:GetPlayers()) do
		local h, hum = alive(p)
		if h then
			local d = (h.Position - pos).Magnitude
			if d < st.ExplodeRadius then
				hum:TakeDamage(st.ExplodeDamage * (1 - d / st.ExplodeRadius * 0.6))
			end
		end
	end
	for _, part in ipairs(z.model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
end

local function spawnOne()
	local pos = spawnPoint()
	if not pos then
		return
	end
	local kind = pickType()
	local st = STATS[kind]
	local m = types[kind]:Clone()
	m.Name = kind
	if math.abs(st.Scale - 1) > 1e-3 then
		m:ScaleTo(st.Scale)
		m:SetAttribute("RigScale", st.Scale)   -- el animador escala las traslaciones de las animaciones
	end
	local hum = m:FindFirstChildOfClass("Humanoid")
	local hrp = m.PrimaryPart
	hum.MaxHealth = st.Health
	hum.Health = st.Health
	hum.WalkSpeed = st.WalkSpeed
	hum.HipHeight = (m:GetAttribute("HipHeight") or 2.15) * st.Scale
	m:PivotTo(CFrame.new(pos + Vector3.new(0, hum.HipHeight + 1.2 * st.Scale, 0)) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0))
	m:SetAttribute("Kind", kind)
	m:SetAttribute("Anim", "Idle")
	m:SetAttribute("AnimStamp", 0)
	m.Parent = container
	pcall(function()
		hrp:SetNetworkOwner(nil)   -- el servidor mueve a los infectados: sin tirones entre jugadores
	end)
	local cfg = {
		Detect = st.Detect, Reach = st.Reach * st.Scale, Cooldown = st.Cooldown, WalkSpeed = st.WalkSpeed, ChaseSpeed = st.ChaseSpeed,
		ChaseAnim = st.ChaseAnim, AttackAnim = st.AttackAnim, CanScream = st.CanScream, ScreamCooldown = st.ScreamCooldown,
	}
	local z = { model = m, hum = hum, hrp = hrp, kind = kind, stats = st, brain = Brain.new(cfg, Random.new(rng:NextInteger(1, 1e9))),
		home = pos, lastHp = st.Health, alertT = -1e9, mode = "stop", path = nil, pathT = 0, wp = nil }
	hum.Died:Connect(function()
		z.dead = true
	end)
	zombies[m] = z
	if DEBUG then
		print("[Infected]", kind, "en", pos)
	end
end

local function canSee(z, h)
	local head = z.model:FindFirstChild("Head") or z.hrp
	local hit = workspace:Raycast(head.Position, h.Position - head.Position, rayParams)
	return hit == nil
end

-- moverse: directo si te ve, con pathfinding si hay obstáculos (recalculado cada segundo)
local function follow(z, goal)
	local now = os.clock()
	if z.target and canSee(z, z.target) then
		z.path = nil
		z.hum:MoveTo(goal)
		return
	end
	if not z.path or now - z.pathT > 1 then
		z.pathT = now
		task.spawn(function()
			local path = PathfindingService:CreatePath({ AgentRadius = 1.5 * z.stats.Scale, AgentHeight = 5.5 * z.stats.Scale, AgentCanJump = true })
			local ok = pcall(function()
				path:ComputeAsync(z.hrp.Position, goal)
			end)
			if ok and path.Status == Enum.PathStatus.Success then
				z.path = path:GetWaypoints()
				z.wp = 2
			else
				z.path = nil
				z.hum:MoveTo(goal)
			end
		end)
	end
	if z.path and z.path[z.wp] then
		local w = z.path[z.wp]
		if w.Action == Enum.PathWaypointAction.Jump then
			z.hum.Jump = true
		end
		z.hum:MoveTo(w.Position)
		if (w.Position - z.hrp.Position) * Vector3.new(1, 0, 1) ~= Vector3.zero and ((w.Position - z.hrp.Position) * Vector3.new(1, 0, 1)).Magnitude < 2.5 then
			z.wp += 1
		end
	end
end

local function apply(z, cmds)
	for _, c in ipairs(cmds) do
		local k = c[1]
		if k == "anim" then
			setAnim(z, c[2], c[3])
		elseif k == "move" then
			z.mode = c[2]
			z.hum.WalkSpeed = c[3]
			if c[2] == "stop" then
				z.hum:MoveTo(z.hrp.Position)
			elseif c[2] == "wander" then
				local a, r = rng:NextNumber() * math.pi * 2, 8 + rng:NextNumber() * 25
				z.wanderGoal = z.home + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			end
		elseif k == "sound" then
			sound(z, c[2])
		elseif k == "scream" then
			for _, o in pairs(zombies) do
				if o ~= z and (o.hrp.Position - z.hrp.Position).Magnitude < (z.stats.ScreamRadius or 120) then
					o.alertT = os.clock()
					o.alertTarget = z.target
				end
			end
		elseif k == "attack" then
			local kind, delay = c[2], c[3]
			task.delay(delay, function()
				if z.dead or not z.model.Parent then
					return
				end
				if kind == "slam" then   -- golpe al suelo: daña a todos en el radio
					for _, p in ipairs(Players:GetPlayers()) do
						local h, hum = alive(p)
						if h and (h.Position - z.hrp.Position).Magnitude < z.stats.SlamRadius * z.stats.Scale then
							hum:TakeDamage(z.stats.Damage)
							h.AssemblyLinearVelocity += ((h.Position - z.hrp.Position) * Vector3.new(1, 0, 1)).Unit * 45 + Vector3.new(0, 30, 0)
						end
					end
					sound(z, "Hit")
				elseif z.target then
					local h, hum = z.target, z.target.Parent and z.target.Parent:FindFirstChildOfClass("Humanoid")
					if hum and hum.Health > 0 and (h.Position - z.hrp.Position).Magnitude <= z.brain.cfg.Reach * 1.4 then
						hum:TakeDamage(z.stats.Damage)
						sound(z, "Hit")
					end
				end
			end)
		end
	end
end

-- cerebro 5 veces por segundo; movimiento en el mismo tick
local acc, spawnT = 0, 2
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.2 then
		return
	end
	local step = acc
	acc = 0
	refreshFilter()
	local count = 0
	for _ in pairs(zombies) do
		count += 1
	end
	spawnT -= step
	if spawnT <= 0 and count < MAX_ALIVE and #Players:GetPlayers() > 0 and (not NIGHT_ONLY or isNight()) then
		spawnT = 1.5
		spawnOne()
	end
	for m, z in pairs(zombies) do
		if not m.Parent then
			zombies[m] = nil
			continue
		end
		-- objetivo: el jugador vivo más cercano (o el que señaló un gritón)
		local best, bestD = nil, math.huge
		for _, p in ipairs(Players:GetPlayers()) do
			local h = alive(p)
			if h and (h.Position - z.hrp.Position).Magnitude < bestD then
				best, bestD = h, (h.Position - z.hrp.Position).Magnitude
			end
		end
		local alerted = os.clock() - z.alertT < 15 and z.alertTarget ~= nil and z.alertTarget.Parent ~= nil
		if alerted and (not best or (z.alertTarget.Position - z.hrp.Position).Magnitude < bestD + 20) then
			best, bestD = z.alertTarget, (z.alertTarget.Position - z.hrp.Position).Magnitude
		end
		z.target = best
		local hp = z.hum.Health
		local P = {
			dist = bestD, hasTarget = best ~= nil and bestD < 400, canSee = best ~= nil and bestD <= z.stats.Detect * z.stats.Scale and canSee(z, best),
			alerted = alerted, health = hp / z.hum.MaxHealth, hurt = hp < z.lastHp - 0.5, dead = z.dead or hp <= 0,
		}
		z.lastHp = hp
		local was = z.brain.state
		apply(z, z.brain:Update(step, P))
		if was ~= "Dead" and z.brain.state == "Dead" then
			z.hrp.Anchored = true   -- queda tendido donde cayó mientras se reproduce la muerte
			if z.kind == "Bloater" then
				task.delay(0.3, function()
					explode(z)
				end)
			end
			task.delay(RESPAWN, function()
				if m.Parent then
					m:Destroy()
				end
			end)
			task.delay(6, function()   -- el cuerpo desaparece
				for _, part in ipairs(m:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1
					end
				end
			end)
		end
		if z.brain.state ~= "Dead" then
			if z.mode == "chase" and best then
				follow(z, best.Position)
			elseif z.mode == "wander" and z.wanderGoal then
				z.hum:MoveTo(z.wanderGoal)
			end
		end
	end
end)
