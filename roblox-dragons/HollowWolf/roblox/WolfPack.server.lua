--[[
	WolfPack (Script) · ServerScriptService.WolfPack

	Manadas de lobos huecos, las mismas para todos los jugadores. Salen al anochecer y se van al amanecer
	(NightOnly; por defecto true). Cada manada tiene un alfa (más grande, más vida, aúlla) y varios lobos.
	El servidor decide (WolfBrain), mueve los modelos 10 veces por segundo (para que las armas acierten en el
	servidor) y publica atributos; los clientes (WolfClient) animan los huesos y suavizan el movimiento.

	Dónde aparecen: partes con la etiqueta "WolfSpawn" o dentro de Workspace.WolfSpawns; si no hay, alrededor
	de Settings.SpawnCenter, lejos de los jugadores.
	Luz segura: partes con la etiqueta "SafeLight" (atributo Radius, por defecto 25). Ningún lobo entra en esa
	zona y no muerden a quien está dentro. Es el gancho para la hoguera.

	Daño a los lobos (para las armas de tu juego):
	  ReplicatedStorage.Creatures.HollowWolf.DamageWolf:Invoke(lobo, cantidad)   -- desde el servidor
	  o simplemente lobo:SetAttribute("Health", lobo:GetAttribute("Health") - cantidad)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local folder = ReplicatedStorage:WaitForChild("Creatures"):WaitForChild("HollowWolf")
local Brain = require(folder:WaitForChild("WolfBrain"))
local settings = folder:WaitForChild("Settings")
local template = folder:WaitForChild("HollowWolf") :: Model

local function S(k, d)
	local v = settings:GetAttribute(k)
	if v == nil then
		return d
	end
	return v
end
local PACKS, PACK_SIZE = S("Packs", 2), S("PackSize", 4)
local DAMAGE, ALPHA_DAMAGE = S("Damage", 8), S("AlphaDamage", 15)
local HEALTH, ALPHA_HEALTH = S("Health", 60), S("AlphaHealth", 150)
local ALPHA_SCALE = S("AlphaScale", 1.35)
local NIGHT_ONLY = S("NightOnly", true)
local SPAWN_CENTER, SPAWN_RADIUS = S("SpawnCenter", Vector3.zero), S("SpawnRadius", 250)
local MAX_BITERS = S("MaxBiters", 2)
local DEBUG = S("Debug", false)
local config = {}
for k, v in pairs(settings:GetAttributes()) do
	if type(Brain.Defaults[k]) == "number" and type(v) == "number" then
		config[k] = v
	end
end

local container = workspace:FindFirstChild("Wolves") or Instance.new("Folder")
container.Name = "Wolves"
container.Parent = workspace
local rng = Random.new()

local damageFn = folder:FindFirstChild("DamageWolf") or Instance.new("BindableFunction")
damageFn.Name = "DamageWolf"
damageFn.Parent = folder
damageFn.OnInvoke = function(model, amount)
	if typeof(model) == "Instance" and model:IsDescendantOf(container) and type(amount) == "number" then
		model:SetAttribute("Health", math.max(0, (model:GetAttribute("Health") or 0) - amount))
		return true
	end
	return false
end

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
local function lights()
	local out = {}
	for _, p in ipairs(CollectionService:GetTagged("SafeLight")) do
		if p:IsA("BasePart") and (p:GetAttribute("Enabled") ~= false) then
			table.insert(out, { pos = p.Position, r = p:GetAttribute("Radius") or 25 })
		end
	end
	return out
end
local function inLight(pos, L)
	for _, l in ipairs(L) do
		if ((pos - l.pos) * Vector3.new(1, 0, 1)).Magnitude < l.r then
			return l
		end
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

local packs, stamp = {}, 0
local function spawnPoint()
	local pts = CollectionService:GetTagged("WolfSpawn")
	local sf = workspace:FindFirstChild("WolfSpawns")
	if sf then
		for _, d in ipairs(sf:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(pts, d)
			end
		end
	end
	for _ = 1, 30 do
		local c
		if #pts > 0 then
			c = pts[rng:NextInteger(1, #pts)].Position
		else
			local a, r = rng:NextNumber() * math.pi * 2, math.sqrt(rng:NextNumber()) * SPAWN_RADIUS
			c = SPAWN_CENTER + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		end
		local g = groundAt(c.X, c.Z, c.Y)
		local far = true
		for _, p in ipairs(Players:GetPlayers()) do
			local h = alive(p)
			if h and (h.Position - (g or c)).Magnitude < 80 then
				far = false
			end
		end
		if g and far and not inLight(g, lights()) then
			return g
		end
	end
	return nil
end

local function makeWolf(pack, isAlpha, pos)
	local m = template:Clone()
	m.Name = isAlpha and "WolfAlpha" or "Wolf"
	if isAlpha then
		m:ScaleTo(ALPHA_SCALE)
		m:SetAttribute("RigScale", ALPHA_SCALE)
	end
	local s = m:GetAttribute("RigScale") or 1
	local root = CFrame.new(pos + Vector3.new(rng:NextNumber() * 6 - 3, 0, rng:NextNumber() * 6 - 3)) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
	local hp = isAlpha and ALPHA_HEALTH or HEALTH
	for k, v in pairs({ Root = root, Anim = "Idle", AnimFade = 0, AnimStamp = 0, Alpha = isAlpha, Health = hp, MaxHealth = hp, Visible = true }) do
		m:SetAttribute(k, v)
	end
	m:PivotTo(root)
	m.Parent = container
	local w = {
		model = m, pack = pack, alpha = isAlpha, scale = s, root = root, speed = 0, mode = "stop", slot = 0, lastHp = hp,
		brain = Brain.new(table.clone(config), Random.new(rng:NextInteger(1, 1e9)), isAlpha), ground = 0, wander = pos,
	}
	table.insert(pack.wolves, w)
	return w
end

local function spawnPack()
	local pos = spawnPoint()
	if not pos then
		return
	end
	local pack = { wolves = {}, alerted = false, target = nil, home = pos }
	makeWolf(pack, true, pos)
	for _ = 2, PACK_SIZE do
		makeWolf(pack, false, pos)
	end
	for i, w in ipairs(pack.wolves) do
		w.slot = (i - 1) / #pack.wolves * math.pi * 2   -- cada lobo rodea por un flanco distinto
	end
	table.insert(packs, pack)
	if DEBUG then
		print("[WolfPack] manada en", pos)
	end
end

local function playSound(w, name)
	local body = w.model:FindFirstChild("WolfBody", true)
	local s = body and body:FindFirstChild(name)
	if s and s.SoundId ~= "" then
		s.PlaybackSpeed = (w.alpha and 0.85 or 1) * (0.92 + rng:NextNumber() * 0.16)
		s:Play()
	end
end

local function apply(w, cmds)
	for _, c in ipairs(cmds) do
		local k = c[1]
		stamp += 1
		if k == "anim" then
			w.model:SetAttribute("Anim", c[2])
			w.model:SetAttribute("AnimFade", c[3] or 0.3)
			w.model:SetAttribute("AnimStamp", stamp)
		elseif k == "move" then
			w.speed, w.mode = c[2] * w.scale, c[3]
		elseif k == "alert" then
			w.pack.alerted = true
		elseif k == "sound" then
			playSound(w, c[2])
		elseif k == "bite" then
			local h, hum = nil, nil
			if w.pack.target then
				h, hum = alive(w.pack.target)
			end
			if h and hum and (h.Position - w.root.Position).Magnitude <= (w.brain.cfg.AttackReach + 1.5) * w.scale then
				hum:TakeDamage(w.alpha and ALPHA_DAMAGE or DAMAGE)
				playSound(w, "Bite")
			end
		elseif k == "despawn" then
			w.gone = true
			w.model:SetAttribute("Visible", false)
			task.delay(1.5, function()
				w.model:Destroy()
			end)
		end
	end
end

-- movimiento (cada frame, sin física) con la luz como barrera
RunService.Heartbeat:Connect(function(dt)
	local L = lights()
	for _, pack in ipairs(packs) do
		local th = pack.target and alive(pack.target)
		local leader = pack.wolves[1]
		for _, w in ipairs(pack.wolves) do
			if w.gone or w.brain.state == "Dead" or w.mode == "stop" then
				continue
			end
			local pos = w.root.Position
			local goal
			if w.mode == "wander" then
				if (w.wander - pos).Magnitude < 4 then
					local a, r = rng:NextNumber() * math.pi * 2, 20 + rng:NextNumber() * 40
					w.wander = pack.home + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
				end
				goal = w.wander
			elseif w.mode == "follow" and leader and not leader.gone then
				goal = leader.root.Position + Vector3.new(math.cos(w.slot) * 4, 0, math.sin(w.slot) * 4)
			elseif th then
				local tp = th.Position
				if w.mode == "toward" or w.mode == "lunge" or w.mode == "face" then
					goal = tp
				elseif w.mode == "away" then
					goal = pos + (pos - tp) * Vector3.new(1, 0, 1)
				elseif w.mode == "circle" then
					w.slot += dt * 0.35 * (w.alpha and -1 or 1)
					local r = (w.brain.cfg.CircleMin + w.brain.cfg.CircleMax) * 0.5 * w.scale
					local l = inLight(tp, L)
					if l then
						r = math.max(r, l.r + 4 - ((tp - l.pos) * Vector3.new(1, 0, 1)).Magnitude)   -- rodea por fuera de la luz
					end
					goal = tp + Vector3.new(math.cos(w.slot) * r, 0, math.sin(w.slot) * r)
				end
			end
			if not goal then
				continue
			end
			local want = (goal - pos) * Vector3.new(1, 0, 1)
			local cur = w.root.LookVector * Vector3.new(1, 0, 1)
			local dir = cur
			if want.Magnitude > 0.2 then
				local maxTurn = math.rad(w.speed > 15 and 260 or 160) * dt
				local ang = math.atan2(cur:Cross(want.Unit).Y, cur:Dot(want.Unit))
				dir = (CFrame.Angles(0, math.clamp(ang, -maxTurn, maxTurn), 0) * cur).Unit
			end
			local npos = pos
			if w.mode ~= "face" and want.Magnitude > 1.5 then
				npos = pos + dir * w.speed * dt
				if inLight(npos, L) and w.mode ~= "away" then
					npos = pos   -- nunca entra en la luz
				end
				w.ground -= dt
				if w.ground <= 0 then
					w.ground = 0.2
					local g = groundAt(npos.X, npos.Z, npos.Y)
					if g then
						npos = Vector3.new(npos.X, g.Y, npos.Z)
					end
				end
			end
			if w.mode == "circle" and th then   -- en el cerco mira a la presa
				local f = (th.Position - npos) * Vector3.new(1, 0, 1)
				if f.Magnitude > 0.1 then
					dir = f.Unit
				end
			end
			w.root = CFrame.lookAt(npos, npos + dir)
		end
	end
end)

-- pensar, publicar y aparecer/desaparecer 10 veces por segundo
local acc = 0
local spawnTimer = 3
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.1 then
		return
	end
	local step = acc
	acc = 0
	refreshFilter()
	local night = not NIGHT_ONLY or isNight()
	local L = lights()
	-- manadas nuevas de noche
	for i = #packs, 1, -1 do
		local alive_ = false
		for _, w in ipairs(packs[i].wolves) do
			if not w.gone and w.model.Parent then
				alive_ = true
			end
		end
		if not alive_ then
			table.remove(packs, i)
		end
	end
	spawnTimer -= step
	if night and #packs < PACKS and spawnTimer <= 0 and #Players:GetPlayers() > 0 then
		spawnTimer = 20 + rng:NextNumber() * 40
		spawnPack()
	end
	for _, pack in ipairs(packs) do
		-- objetivo: el jugador vivo más cercano al alfa (o al primer lobo vivo)
		local ref = pack.wolves[1].root.Position
		local best, bestD = nil, math.huge
		for _, p in ipairs(Players:GetPlayers()) do
			local h = alive(p)
			if h and (h.Position - ref).Magnitude < bestD then
				best, bestD = p, (h.Position - ref).Magnitude
			end
		end
		pack.target = best
		local th = best and alive(best)
		local targetLight = th and inLight(th.Position, L) ~= nil
		local biters = 0
		for _, w in ipairs(pack.wolves) do
			if w.brain.state == "Attack" then
				biters += 1
			end
		end
		for _, w in ipairs(pack.wolves) do
			if w.gone or not w.model.Parent then
				continue
			end
			local hp = w.model:GetAttribute("Health") or 0
			local maxHp = w.model:GetAttribute("MaxHealth") or 1
			local P = {
				dist = th and (th.Position - w.root.Position).Magnitude / w.scale or math.huge, hasTarget = th ~= nil,
				canAttack = biters < MAX_BITERS, inLight = inLight(w.root.Position, L) ~= nil, targetInLight = targetLight,
				day = not night, alerted = pack.alerted, health = hp / maxHp, hurt = hp < w.lastHp, dead = hp <= 0,
			}
			w.lastHp = hp
			local wasDead = w.brain.state == "Dead"
			apply(w, w.brain:Update(step, P))
			if w.brain.state == "Attack" and P.canAttack and biters < MAX_BITERS then
				biters += 1   -- cuenta al que acaba de lanzarse, para no pasar del máximo en este mismo tick
			end
			if not wasDead and w.brain.state == "Dead" and not w.gone then
				w.gone = true
				task.delay(6, function()   -- el cuerpo se queda un rato y luego desaparece
					w.model:SetAttribute("Visible", false)
					task.delay(1.5, function()
						w.model:Destroy()
					end)
				end)
			end
			if w.model.Parent and w.model:GetAttribute("Root") ~= w.root then
				w.model:SetAttribute("Root", w.root)
				w.model:PivotTo(w.root)   -- también en el servidor, para que las armas acierten
			end
		end
	end
end)
