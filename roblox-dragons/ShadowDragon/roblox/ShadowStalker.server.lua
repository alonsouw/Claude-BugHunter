--[[
	ShadowStalker (Script) · ServerScriptService.ShadowStalker

	Un solo Dragón Sombrío para todos los jugadores. El servidor decide (ShadowBrain) dónde está y qué hace;
	los clientes animan los huesos y suavizan el movimiento (ShadowClient), porque Roblox no replica
	Bone.Transform desde el servidor.

	Lo que el servidor publica en el modelo Workspace.ShadowDragonLive (atributos):
	  Root (CFrame)                pivote del dragón sobre el suelo, mirando a -Z
	  Visible, FadeTime, FadeStamp aparecer / desaparecer gradualmente
	  Anim, AnimFade, AnimStamp    animación actual
	  Frozen, Pose, PoseStamp      inmovilidad y postura extraña
	  Tilt                         inclinación de cabeza (grados)
	  SilenceUntil                 hora del servidor hasta la que el ambiente queda en silencio
	  State, TargetUserId          estado y objetivo (para depurar)

	Cada cliente envía 5 veces por segundo el CFrame de su cámara (ShadowGaze) para saber si lo está mirando.
	Sitios para aparecer: partes con la etiqueta "ShadowPerch" o dentro de Workspace.ShadowPerches (junto a
	árboles, rocas, zonas oscuras). Si no hay, busca sitios en el terreno alrededor del jugador, mejor si hay
	objetos cerca que lo tapen.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local folder = ReplicatedStorage:WaitForChild("Dragons"):WaitForChild("ShadowDragon")
local Brain = require(folder:WaitForChild("ShadowBrain"))
local settings = folder:WaitForChild("Settings")
local template = folder:WaitForChild("ShadowDragon") :: Model
local gazeRemote = folder:WaitForChild("ShadowGaze")

if settings:GetAttribute("StalkerEnabled") == false then
	return
end
local DEBUG = settings:GetAttribute("Debug") == true
local MAX_SIGHT = settings:GetAttribute("MaxSightDistance") or 320

-- configuración: los atributos de Settings que coinciden con un valor numérico de Brain.Defaults lo sustituyen
local config = {}
for k, v in pairs(settings:GetAttributes()) do
	if type(Brain.Defaults[k]) == "number" and type(v) == "number" then
		config[k] = v
	end
end
local brain = Brain.new(config, Random.new())

-- el dragón vivo: oculto hasta que el cerebro decide aparecer
local live = template:Clone()
live.Name = "ShadowDragonLive"
local scale = live:GetAttribute("RigScale") or 1
local HEAD_OFFSET = live:GetAttribute("HeadOffset") or Vector3.new(0, 7 * scale, -14 * scale)
local BODY_OFFSET = live:GetAttribute("BodyOffset") or Vector3.new(0, 13 * scale, 0)
for _, d in ipairs(live:GetDescendants()) do
	if d:IsA("BasePart") then
		d.CanCollide = false
		d.CanTouch = false
		d.CanQuery = false
	end
end
local root = CFrame.new(0, -500, 0)
live:SetAttribute("Root", root)
live:SetAttribute("Visible", false)
live:SetAttribute("FadeTime", 0)
live:SetAttribute("FadeStamp", 0)
live:SetAttribute("Anim", "Idle")
live:SetAttribute("AnimFade", 0)
live:SetAttribute("AnimStamp", 0)
live:SetAttribute("Frozen", false)
live:SetAttribute("Pose", "")
live:SetAttribute("PoseStamp", 0)
live:SetAttribute("Tilt", 0)
live:SetAttribute("SilenceUntil", 0)
live.Parent = workspace

local sounds = {}
local body = live:FindFirstChild("Body", true)
if body then
	for _, s in ipairs(body:GetChildren()) do
		if s:IsA("Sound") and s.SoundId ~= "" then
			sounds[s.Name] = s
		end
	end
end

-- miradas de los jugadores (CFrame de cámara reciente)
local gaze = {}
gazeRemote.OnServerEvent:Connect(function(player, cf)
	if typeof(cf) == "CFrame" then
		gaze[player] = { cf = cf, t = os.clock() }
	end
end)
Players.PlayerRemoving:Connect(function(p)
	gaze[p] = nil
end)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false
local function refreshFilter()
	local list = { live }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	rayParams.FilterDescendantsInstances = list
end

local function hrpOf(p)
	local c = p.Character
	local h = c and c:FindFirstChild("HumanoidRootPart")
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if h and hum and hum.Health > 0 then
		return h
	end
	return nil
end

local function cameraOf(p)
	local g = gaze[p]
	if g and os.clock() - g.t < 1.5 then
		return g.cf.Position, g.cf.LookVector
	end
	local h = hrpOf(p)
	if h then
		return h.Position + Vector3.new(0, 1.5, 0), h.CFrame.LookVector
	end
	return nil
end

-- ¿ve el jugador p el punto (cabeza o cuerpo) directamente y sin obstáculos?
local function sees(p, points, visible)
	if not visible then
		return false, 180
	end
	local pos, look = cameraOf(p)
	if not pos then
		return false, 180
	end
	local best = 180
	for _, pt in ipairs(points) do
		local dist = (pt - pos).Magnitude
		local ang = Brain.AngleTo(pos, look, pt)
		best = math.min(best, ang)
		-- de cerca el dragón ocupa más pantalla: el cono crece con su tamaño aparente
		local cone = math.max(brain.cfg.LookAngle, math.deg(math.atan2(6 * scale, dist)))
		if dist < MAX_SIGHT and ang < cone then
			local hit = workspace:Raycast(pos, pt - pos, rayParams)
			if not hit or (hit.Position - pt).Magnitude < 2 then
				return true, best
			end
		end
	end
	return false, best
end

local function groundAt(x, z, fromY)
	local hit = workspace:Raycast(Vector3.new(x, fromY + 60, z), Vector3.new(0, -260, 0), rayParams)
	if hit and hit.Normal.Y > 0.6 and hit.Material ~= Enum.Material.Water then
		return hit.Position
	end
	return nil
end

local function coverAt(pos)
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = rayParams.FilterDescendantsInstances
	local n = 0
	for _, part in ipairs(workspace:GetPartBoundsInRadius(pos, 12 * scale, op)) do
		if part ~= workspace.Terrain and part.Size.Y > 4 then
			n += 1
		end
	end
	return n
end

local target: Player? = nil
local lastTargeted = {}
local function pickTarget()
	local best, bestScore = nil, -math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if hrpOf(p) then
			local score = math.random() + (os.clock() - (lastTargeted[p] or -1e6)) / 600
			if score > bestScore then
				best, bestScore = p, score
			end
		end
	end
	target = best
	if best then
		lastTargeted[best] = os.clock()
	end
	live:SetAttribute("TargetUserId", best and best.UserId or 0)
end

local visible = false
local function headPoint(cf)
	return cf:PointToWorldSpace(HEAD_OFFSET), cf:PointToWorldSpace(BODY_OFFSET)
end

local function place(kind: string): boolean
	if not target then
		return false
	end
	local h = hrpOf(target)
	if not h then
		return false
	end
	local tpos = h.Position
	local camPos, camLook = cameraOf(target)
	local candidates = {}
	local perches = CollectionService:GetTagged("ShadowPerch")
	local pf = workspace:FindFirstChild("ShadowPerches")
	if pf then
		for _, d in ipairs(pf:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(perches, d)
			end
		end
	end
	for _, part in ipairs(perches) do
		local g = groundAt(part.Position.X, part.Position.Z, part.Position.Y)
		if g then
			table.insert(candidates, { pos = g, cover = 3 })
		end
	end
	local here = root.Position
	for _ = 1, 28 do
		local a = math.random() * math.pi * 2
		local d = kind == "far" and (60 + math.random() * 110) or (brain.cfg.VanishDistance + 8 + math.random() * 40)
		local c = tpos + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		if kind == "closer" then -- más cerca, pero desde el lado donde ya estaba
			local dir = (here - tpos) * Vector3.new(1, 0, 1)
			if dir.Magnitude > 1 then
				c = tpos + (dir.Unit:Lerp(Vector3.new(math.cos(a), 0, math.sin(a)), 0.35)).Unit * d
			end
		end
		local g = groundAt(c.X, c.Z, tpos.Y)
		if g then
			table.insert(candidates, { pos = g })
		end
	end
	local best, bestScore = nil, 0
	for _, c in ipairs(candidates) do
		local cf = CFrame.lookAt(c.pos, Vector3.new(tpos.X, c.pos.Y, tpos.Z))
		local hp, bp = headPoint(cf)
		local inView = false
		for _, p in ipairs(Players:GetPlayers()) do
			if sees(p, { hp, bp }, true) then
				inView = true
				break
			end
		end
		local dist = (c.pos - tpos).Magnitude
		local ang = camPos and Brain.AngleTo(camPos, camLook, hp) or 90
		local s = Brain.ScoreSpot(kind, dist, ang, inView, c.cover or coverAt(c.pos), brain.cfg)
		if s > bestScore then
			best, bestScore = cf, s
		end
	end
	if not best then
		return false
	end
	root = best
	live:SetAttribute("Root", root)
	return true
end

local stamp = 0
local moveSpeed = 0
local function apply(cmds)
	for _, c in ipairs(cmds) do
		local k = c[1]
		stamp += 1
		if DEBUG then
			print("[ShadowStalker]", brain.state, k, tostring(c[2]), tostring(c[3]))
		end
		if k == "newTarget" then
			pickTarget()
		elseif k == "place" then
			if not place(c[2]) then
				brain:PlaceFailed()
				visible = false
				live:SetAttribute("Visible", false)
				return
			end
		elseif k == "appear" or k == "vanish" then
			visible = k == "appear"
			live:SetAttribute("FadeTime", c[2])
			live:SetAttribute("Visible", visible)
			live:SetAttribute("FadeStamp", stamp)
			if sounds.Breath then
				sounds.Breath.Playing = visible
			end
		elseif k == "anim" then
			live:SetAttribute("Anim", c[2])
			live:SetAttribute("AnimFade", c[3] or 0.3)
			live:SetAttribute("AnimStamp", stamp)
		elseif k == "freeze" then
			live:SetAttribute("Frozen", c[2])
		elseif k == "pose" then
			live:SetAttribute("Pose", c[2])
			live:SetAttribute("PoseStamp", stamp)
		elseif k == "move" then
			moveSpeed = c[2] * scale
		elseif k == "tilt" then
			live:SetAttribute("Tilt", c[2])
		elseif k == "silence" then
			live:SetAttribute("SilenceUntil", workspace:GetServerTimeNow() + c[2])
			if sounds.Breath then
				sounds.Breath.Playing = false
				task.delay(c[2], function()
					sounds.Breath.Playing = visible
				end)
			end
		elseif k == "sound" then
			local s = sounds[c[2]]
			if s then
				s.PlaybackSpeed = 0.9 + math.random() * 0.2
				s:Play()
			end
		end
	end
end

-- movimiento: hacia el objetivo, girando con un límite y pegado al suelo
local groundTimer = 0
local blocked = false
RunService.Heartbeat:Connect(function(dt)
	if moveSpeed <= 0 or not target then
		return
	end
	local h = hrpOf(target)
	if not h then
		return
	end
	local pos = root.Position
	local flat = (h.Position - pos) * Vector3.new(1, 0, 1)
	if flat.Magnitude < 1 then
		return
	end
	local cur = root.LookVector * Vector3.new(1, 0, 1)
	local maxTurn = math.rad(moveSpeed > 15 * scale and 220 or 70) * dt
	local ang = math.atan2(cur:Cross(flat.Unit).Y, cur:Dot(flat.Unit))
	local yaw = math.clamp(ang, -maxTurn, maxTurn)
	local dir = (CFrame.Angles(0, yaw, 0) * cur).Unit
	groundTimer -= dt
	if groundTimer <= 0 then
		groundTimer = 0.2
		-- sin pathfinding: si hay un obstáculo delante (pared, tronco), se queda quieto en vez de atravesarlo
		blocked = workspace:Raycast(pos + Vector3.new(0, 3 * scale, 0), dir * 7 * scale, rayParams) ~= nil
	end
	if blocked then
		root = CFrame.lookAt(pos, pos + dir)
		return
	end
	pos += dir * moveSpeed * dt
	if groundTimer >= 0.19 then
		local g = groundAt(pos.X, pos.Z, pos.Y)
		if g then
			pos = Vector3.new(pos.X, g.Y, pos.Z)
		end
	end
	root = CFrame.lookAt(pos, pos + dir)
end)

-- publicar la posición 10 veces por segundo (solo si cambió) y pensar
local TICK = 0.1
local acc, lastPublished = 0, root
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < TICK then
		return
	end
	local step = acc
	acc = 0
	if root ~= lastPublished then
		lastPublished = root
		live:SetAttribute("Root", root)
	end
	refreshFilter()
	if target and (not target.Parent or not hrpOf(target)) then
		target = nil
	end
	local P = { hasTarget = target ~= nil, dist = math.huge, targetAngle = 180, targetSees = false, anySees = false }
	local hp, bp = headPoint(root)
	if target then
		P.dist = (hrpOf(target).Position - root.Position).Magnitude
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local s, ang = sees(p, { hp, bp }, visible)
		if s then
			P.anySees = true
		end
		if p == target then
			P.targetSees, P.targetAngle = s, ang
		end
	end
	if not target and brain.state == "Absent" then
		P.hasTarget = #Players:GetPlayers() > 0 -- en ausencia basta con que haya alguien; newTarget lo elige
	end
	apply(brain:Update(step, P))
	live:SetAttribute("State", brain.state)
end)
