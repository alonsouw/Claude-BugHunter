--[[
	CureService (Script) · ServerScriptService.CureService

	El objetivo del juego: reunir los ingredientes del «Remedio del Alba», prepararlo en el caldero y usarlo.
	  · Botín: el dragón de la guarida suelta saliva; el lobo alfa, su colmillo; el ciervo maldito deja caer su asta al
	    transformarse; el pez infectado gigante lleva una perla negra; el infectado bruto, su corazón.
	    Cualquier modelo con el atributo CureDrop = "<id>" suelta ese ingrediente al morir (para tus criaturas).
	  · Plantas: la flor de luna solo se puede coger de noche; la raíz de sangre hay que desenterrarla.
	  · Caldero (Workspace.CureCauldron o etiqueta "CureCauldron"): echar ingredientes (E), y con todo, preparar.
	    Tarda BrewTime segundos (avisa con CureBrewingStarted, por si quieres una horda). Luego sale el remedio.
	  · Usarlo: se acaban los infectados (humanos y peces) y amanece. Avisa con CureCompleted.
	El progreso es de todo el servidor (todos ayudan) y se ve en ReplicatedStorage.Cure.Progress.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")

local folder = ReplicatedStorage:WaitForChild("Cure")
local Logic = require(folder:WaitForChild("CureLogic"))
local RECIPE = require(folder:WaitForChild("Recipe"))
local itemsFolder = folder:WaitForChild("Items")
local worldFolder = folder:WaitForChild("World")
local settings = folder:WaitForChild("Settings")
local rng = Random.new()

local function S(k, d)
	local v = settings:GetAttribute(k)
	if v == nil then
		return d
	end
	return v
end
local BREW_TIME = S("BrewTime", 90)
local BOSS_KIND = S("BossDragon", "PredatorDragon")
local BOSS_HEALTH = S("BossHealth", 2500)
local BOSS_DAMAGE = S("BossDamage", 35)
local BOSS_RESPAWN = S("BossRespawn", 600)
local N_MOON, N_ROOT = S("Moonflowers", 6), S("BloodRoots", 4)
local PLANT_CENTER, PLANT_RADIUS = S("PlantCenter", Vector3.zero), S("PlantRadius", 150)
local PLANT_RESPAWN = S("PlantRespawn", 120)

local remote = folder:FindFirstChild("Remote") or Instance.new("RemoteEvent")
remote.Name = "Remote"
remote.Parent = folder
local function event(name)
	local e = folder:FindFirstChild(name) or Instance.new("BindableEvent")
	e.Name = name
	e.Parent = folder
	return e
end
local brewingStarted = event("CureBrewingStarted")   -- :Fire()  al empezar a preparar
local completed = event("CureCompleted")             -- :Fire(jugador) al usar el remedio
local progressCfg = folder:FindFirstChild("Progress") or Instance.new("Configuration")
progressCfg.Name = "Progress"
progressCfg.Parent = folder

local NAMES = {}
for _, r in ipairs(RECIPE) do
	NAMES[r.id] = r.name
end
NAMES.Remedy = "Remedio del Alba"

local function toast(player, text)
	if player then
		remote:FireClient(player, "toast", text)
	else
		remote:FireAllClients("toast", text)
	end
end
local function playSound(inst, name)
	local s = inst and inst:FindFirstChild(name, true)
	if s and s:IsA("Sound") and s.SoundId ~= "" then
		s:Play()
	end
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
local function itemProto(id)
	for _, t in ipairs(itemsFolder:GetChildren()) do
		if t:GetAttribute("CureItem") == id then
			return t
		end
	end
	return nil
end
local function give(player, id)
	local proto = itemProto(id)
	if proto then
		proto:Clone().Parent = player:FindFirstChildOfClass("Backpack") or player.Character
	end
end

-- ---------------------------------------------------------------- progreso y caldero
local progress = {}
local brew = Logic.Brew.new(BREW_TIME)
local function publish()
	for _, r in ipairs(RECIPE) do
		progressCfg:SetAttribute(r.id, progress[r.id] or 0)
	end
	local done, total = Logic.Count(progress, RECIPE)
	folder:SetAttribute("Done", done)
	folder:SetAttribute("Total", total)
	folder:SetAttribute("Stage", brew.state)
end
publish()

local cauldron = workspace:FindFirstChild("CureCauldron") or CollectionService:GetTagged("CureCauldron")[1]
local function slots()
	if not cauldron then
		return
	end
	for i, r in ipairs(RECIPE) do
		local slot = cauldron:FindFirstChild("Slot" .. i, true)
		if slot then
			local have = progress[r.id] or 0
			local c = Color3.fromRGB(r.color[1], r.color[2], r.color[3])
			slot.Color = have >= r.need and c or (have > 0 and c:Lerp(Color3.fromRGB(40, 40, 40), 0.6) or Color3.fromRGB(60, 56, 54))
			slot.Material = have > 0 and Enum.Material.Neon or Enum.Material.SmoothPlastic
		end
	end
end
slots()

local function dropItem(id, pos, float)
	local proto = itemProto(id)
	if not proto then
		return
	end
	local t = proto:Clone()
	local h = t:FindFirstChild("Handle")
	if not h then
		return
	end
	h.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))   -- (un Tool no tiene PivotTo: se mueve el Handle y lo soldado va con él)
	if float then   -- la perla flota en el agua
		h.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.3, 0.5)
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "CureLabel"
	bb.Size = UDim2.fromOffset(200, 40)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 80
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextColor3 = Color3.fromRGB(255, 226, 140)
	l.TextStrokeTransparency = 0.2
	l.Text = "★ " .. (NAMES[id] or id)
	l.Parent = bb
	bb.Parent = h
	t.AncestryChanged:Connect(function()   -- al cogerlo, fuera el cartel
		if t.Parent and t.Parent ~= workspace and bb.Parent then
			bb:Destroy()
		end
	end)
	t.Parent = workspace
	playSound(t, "Pickup")
	toast(nil, ("Ha aparecido: %s"):format(NAMES[id] or id))
end

local function addIngredients(player)
	if brew.state ~= "Collecting" then
		return
	end
	local added = {}
	local containers = { player:FindFirstChildOfClass("Backpack"), player.Character }
	for _, c in ipairs(containers) do
		if c then
			for _, t in ipairs(c:GetChildren()) do
				local id = t:IsA("Tool") and t:GetAttribute("CureItem")
				if id and Logic.Add(progress, RECIPE, id) then
					added[id] = (added[id] or 0) + 1
					t:Destroy()
				end
			end
		end
	end
	if next(added) == nil then
		toast(player, "No llevas nada que le falte a la cura.")
		return
	end
	local parts = {}
	for id, n in pairs(added) do
		table.insert(parts, n > 1 and ("%s ×%d"):format(NAMES[id], n) or NAMES[id])
	end
	playSound(cauldron, "Add")
	toast(nil, ("%s ha echado al caldero: %s"):format(player.DisplayName, table.concat(parts, ", ")))
	brew:SetReady(Logic.Complete(progress, RECIPE))
	if brew.state == "Ready" then
		toast(nil, "¡Están todos los ingredientes! Preparad la cura en el caldero.")
	end
	publish()
	slots()
end

local liquid = cauldron and cauldron:FindFirstChild("Liquid", true)
local cauldronPrompt, remedyPrompt
local function updatePrompts()
	if not cauldronPrompt then
		return
	end
	cauldronPrompt.Enabled = brew.state == "Collecting" or brew.state == "Ready"
	cauldronPrompt.ActionText = brew.state == "Ready" and "Preparar la cura" or "Echar ingredientes"
	cauldronPrompt.HoldDuration = brew.state == "Ready" and 2 or 0.6
	if remedyPrompt then
		remedyPrompt.Enabled = brew.state == "Done" and not folder:GetAttribute("RemedyTaken")
	end
end

local function startBrew(player)
	if not brew:Start(os.clock()) then
		return
	end
	folder:SetAttribute("Brewing", true)
	brewingStarted:Fire()
	playSound(cauldron, "Brew")
	toast(nil, ("%s ha empezado a preparar la cura. ¡Aguantad %d segundos!"):format(player.DisplayName, BREW_TIME))
	if liquid then
		TweenService:Create(liquid, TweenInfo.new(BREW_TIME, Enum.EasingStyle.Linear), { Color = Color3.fromRGB(255, 214, 110) }):Play()
		local e = Instance.new("ParticleEmitter")
		e.Name = "Bubbles"
		e.Color = ColorSequence.new(Color3.fromRGB(220, 255, 180))
		e.Size = NumberSequence.new(0.3, 0)
		e.Lifetime = NumberRange.new(0.6, 1.2)
		e.Speed = NumberRange.new(2, 4)
		e.Rate = 25
		e.EmissionDirection = Enum.NormalId.Top
		e.Parent = liquid
	end
	publish()
	updatePrompts()
end

if cauldron then
	local base = cauldron:IsA("BasePart") and cauldron or cauldron.PrimaryPart or cauldron:FindFirstChildWhichIsA("BasePart")
	cauldronPrompt = Instance.new("ProximityPrompt")
	cauldronPrompt.Name = "CurePrompt"
	cauldronPrompt.ObjectText = "Caldero de la cura"
	cauldronPrompt.MaxActivationDistance = 12
	cauldronPrompt.RequiresLineOfSight = false
	cauldronPrompt.Parent = liquid or base
	cauldronPrompt.Triggered:Connect(function(player)
		if brew.state == "Ready" then
			startBrew(player)
		else
			addIngredients(player)
		end
		updatePrompts()
	end)
	remedyPrompt = Instance.new("ProximityPrompt")
	remedyPrompt.Name = "RemedyPrompt"
	remedyPrompt.ActionText = "Coger el Remedio del Alba"
	remedyPrompt.ObjectText = "Caldero de la cura"
	remedyPrompt.HoldDuration = 1
	remedyPrompt.MaxActivationDistance = 12
	remedyPrompt.RequiresLineOfSight = false
	remedyPrompt.UIOffset = Vector2.new(0, 60)
	remedyPrompt.Enabled = false
	remedyPrompt.Parent = liquid or base
	remedyPrompt.Triggered:Connect(function(player)
		if brew.state == "Done" and not folder:GetAttribute("RemedyTaken") then
			folder:SetAttribute("RemedyTaken", true)
			give(player, "Remedy")
			toast(nil, ("%s tiene el Remedio del Alba. ¡Que lo use!"):format(player.DisplayName))
			updatePrompts()
		end
	end)
	updatePrompts()
else
	warn("[Cure] No encuentro el caldero (Workspace.CureCauldron o la etiqueta CureCauldron).")
end

-- ---------------------------------------------------------------- el final
local function cleanse(model)
	local pivot = model:GetPivot().Position
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.CFrame = CFrame.new(pivot)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(255, 226, 140))
	e.LightEmission = 1
	e.Size = NumberSequence.new(0.6, 0)
	e.Speed = NumberRange.new(4, 10)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 0
	e.Parent = p
	p.Parent = workspace
	e:Emit(30)
	Debris:AddItem(p, 3)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			TweenService:Create(d, TweenInfo.new(2), { Transparency = 1 }):Play()
		end
	end
	Debris:AddItem(model, 2.2)
end

local function ending(player)
	folder:SetAttribute("Cured", true)
	publish()
	for _, n in ipairs({ "InfectedSpawner", "FishSpawner" }) do
		local s = ServerScriptService:FindFirstChild(n)
		if s then
			s.Disabled = true   -- ya no aparecen más
		end
	end
	for _, n in ipairs({ "Infected", "InfectedFish" }) do
		local f = workspace:FindFirstChild(n)
		if f then
			for i, m in ipairs(f:GetChildren()) do
				if m:IsA("Model") then
					task.delay(i * 0.08, cleanse, m)
				end
			end
		end
	end
	TweenService:Create(Lighting, TweenInfo.new(6, Enum.EasingStyle.Sine), { ClockTime = 7 }):Play()
	remote:FireAllClients("ending", player.DisplayName)
	completed:Fire(player)
end

local function hookRemedy(tool)
	if tool:IsA("Tool") and not tool:GetAttribute("RemedyHooked") then
		tool:SetAttribute("RemedyHooked", true)
		tool.Activated:Connect(function()
			local player = Players:GetPlayerFromCharacter(tool.Parent)
			if player and brew:Use() then
				tool:Destroy()
				ending(player)
			end
		end)
	end
end
for _, t in ipairs(CollectionService:GetTagged("CureRemedy")) do
	hookRemedy(t)
end
CollectionService:GetInstanceAddedSignal("CureRemedy"):Connect(hookRemedy)

-- ---------------------------------------------------------------- botín de las criaturas
local function onDeath(model, kind, info, float)
	if model:GetAttribute("CureDropped") then
		return
	end
	local id = Logic.DropFor(kind, info)
	if id then
		model:SetAttribute("CureDropped", true)
		dropItem(id, model:GetPivot().Position, float)
	end
end
local function watchHumanoid(model, kind, float)
	local hum = model:FindFirstChildOfClass("Humanoid") or model:WaitForChild("Humanoid", 5)
	if hum then
		hum.HealthChanged:Connect(function(h)
			if h <= 0 then
				onDeath(model, kind, { name = model.Name, cureDrop = model:GetAttribute("CureDrop") }, float)
			end
		end)
	end
end
local function watchFolder(name, fn)
	local function hook(f)
		for _, m in ipairs(f:GetChildren()) do
			task.spawn(fn, m)
		end
		f.ChildAdded:Connect(fn)
	end
	local f = workspace:FindFirstChild(name)
	if f then
		hook(f)
	end
	workspace.ChildAdded:Connect(function(c)
		if c.Name == name and c:IsA("Folder") then
			hook(c)
		end
	end)
end
watchFolder("Wolves", function(m)   -- los lobos llevan la vida en el atributo Health
	m:GetAttributeChangedSignal("Health"):Connect(function()
		if (m:GetAttribute("Health") or 1) <= 0 then
			onDeath(m, "wolf", { alpha = m:GetAttribute("Alpha"), variant = m:GetAttribute("Variant"), cureDrop = m:GetAttribute("CureDrop") })
		end
	end)
end)
watchFolder("Deer", function(m)   -- el ciervo maldito deja caer el asta al transformarse
	m:GetAttributeChangedSignal("Form"):Connect(function()
		onDeath(m, "deerForm", { form = m:GetAttribute("Form") })
	end)
end)
watchFolder("Infected", function(m)
	if m:IsA("Model") then
		watchHumanoid(m, "infected")
	end
end)
watchFolder("InfectedFish", function(m)
	if m:IsA("Model") then
		watchHumanoid(m, "fish", true)
	end
end)
-- cualquier otro modelo con el atributo CureDrop
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("Humanoid") and d.Parent and d.Parent:GetAttribute("CureDrop") then
		watchHumanoid(d.Parent, "custom")
	end
end)

-- ---------------------------------------------------------------- plantas
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
local plantsFolder = workspace:FindFirstChild("CurePlants") or Instance.new("Folder")
plantsFolder.Name = "CurePlants"
plantsFolder.Parent = workspace
local function groundPoint(spotTag)
	local spots = CollectionService:GetTagged(spotTag)
	local list = { plantsFolder }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	groundParams.FilterDescendantsInstances = list
	for _ = 1, 30 do
		local c
		if #spots > 0 then
			local s = spots[rng:NextInteger(1, #spots)]
			c = s.Position + Vector3.new(rng:NextNumber() * 6 - 3, 0, rng:NextNumber() * 6 - 3)
		else
			local a, r = rng:NextNumber() * math.pi * 2, math.sqrt(rng:NextNumber()) * PLANT_RADIUS
			c = PLANT_CENTER + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		end
		local hit = workspace:Raycast(c + Vector3.new(0, 80, 0), Vector3.new(0, -200, 0), groundParams)
		if hit and hit.Normal.Y > 0.6 and hit.Material ~= Enum.Material.Water then
			return hit.Position
		end
	end
	return nil
end

local plants = {}
local spawnPlant
local function setBloom(m, open)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			if d.Name == "Petal" then
				d.Transparency = open and 0 or 1
			elseif d.Name == "Bud" then
				d.Transparency = open and 1 or 0
			end
		end
	end
end
spawnPlant = function(kind)
	local proto = worldFolder:FindFirstChild(kind == "Moonflower" and "MoonflowerPlant" or "BloodRootMound")
	local pos = groundPoint(kind == "Moonflower" and "MoonflowerSpot" or "BloodRootSpot")
	if not proto or not pos then
		return
	end
	local m = proto:Clone()
	m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber() * 6.28, 0))
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = kind == "Moonflower" and "Flor de luna" or "Raíz de sangre"
	prompt.ActionText = kind == "Moonflower" and "Coger" or "Desenterrar"
	prompt.HoldDuration = kind == "Moonflower" and 0.5 or 2.5
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
	m.Parent = plantsFolder
	local entry = { model = m, kind = kind, prompt = prompt }
	plants[m] = entry
	prompt.Triggered:Connect(function(player)
		if not plants[m] then
			return
		end
		if kind == "Moonflower" and not Logic.IsNight(Lighting.ClockTime) then
			toast(player, "Está cerrada. La flor de luna solo se abre de noche.")
			return
		end
		plants[m] = nil
		playSound(m, "Harvest")
		give(player, kind)
		toast(player, ("Has conseguido: %s"):format(NAMES[kind]))
		m:Destroy()
		task.delay(PLANT_RESPAWN, spawnPlant, kind)
	end)
	if kind == "Moonflower" then
		setBloom(m, Logic.IsNight(Lighting.ClockTime))
	end
end
task.spawn(function()
	task.wait(2)
	for _ = 1, N_MOON do
		spawnPlant("Moonflower")
	end
	for _ = 1, N_ROOT do
		spawnPlant("BloodRoot")
	end
	while true do   -- las flores se abren y se cierran con la noche
		local night = Logic.IsNight(Lighting.ClockTime)
		for m, e in pairs(plants) do
			if e.kind == "Moonflower" then
				setBloom(m, night)
				e.prompt.ActionText = night and "Coger" or "Cerrada (de noche)"
			end
		end
		task.wait(3)
	end
end)

-- ---------------------------------------------------------------- jefe: el dragón de la guarida
local bossFolder = workspace:FindFirstChild("CureBoss") or Instance.new("Folder")
bossFolder.Name = "CureBoss"
bossFolder.Parent = workspace
local boss
local stamp = 0

local function findTemplate()
	local dragons = ReplicatedStorage:FindFirstChild("Dragons")
	if not dragons then
		return nil
	end
	for _, kind in ipairs({ BOSS_KIND, "PredatorDragon", "AberrantDragon" }) do
		local f = dragons:FindFirstChild(kind)
		local m = f and f:FindFirstChild(kind)
		if m and m:IsA("Model") and f:FindFirstChild("Animations") then
			return m, kind
		end
	end
	return nil
end
local function lairCFrame()
	local l = CollectionService:GetTagged("DragonLair")[1] or workspace:FindFirstChild("DragonLair")
	if l and l:IsA("BasePart") then
		return CFrame.new(l.Position)
	elseif l and l:IsA("Model") then
		return CFrame.new(l:GetPivot().Position)
	end
	return nil
end
local function headPos(b)
	local h = b.model:FindFirstChild("Head", true)
	if h and h:IsA("Bone") then
		return h.WorldPosition
	elseif h and h:IsA("BasePart") then
		return h.Position
	end
	return b.model:GetPivot().Position
end
local function bossAnim(b, name, fade)
	stamp += 1
	b.model:SetAttribute("Anim", name)
	b.model:SetAttribute("AnimFade", fade or 0.3)
	b.model:SetAttribute("AnimStamp", stamp)
end

local function spawnBoss()
	local template, kind = findTemplate()
	local lair = lairCFrame()
	if not template or not lair then
		warn("[Cure] Sin jefe dragón: hace falta un dragón instalado (Depredador o Aberrante) y una parte DragonLair.")
		return
	end
	local m = template:Clone()
	m.Name = "LairDragon"
	-- las piezas movidas por Motor6D/soldaduras quedan sueltas (las anima el cliente); el resto, ancladas
	local jointed = {}
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			if d.Part0 then
				jointed[d.Part0] = true
			end
			if d.Part1 then
				jointed[d.Part1] = true
			end
		end
	end
	local rootPart = m.PrimaryPart or m:FindFirstChild("Root")
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = (d == rootPart) or not jointed[d]
			d.CanCollide = false
			d.CanTouch = true
		end
	end
	local rot = m:GetPivot().Rotation
	m:PivotTo(lair * rot)
	m.Parent = bossFolder
	local cf, size = m:GetBoundingBox()
	local lift = lair.Position.Y - (cf.Position.Y - size.Y / 2)
	m:PivotTo(lair * rot + Vector3.new(0, lift, 0))
	local hum = Instance.new("Humanoid")
	hum.RequiresNeck = false
	hum.BreakJointsOnDeath = false
	hum.EvaluateStateMachine = false
	hum.MaxHealth = BOSS_HEALTH
	hum.Health = BOSS_HEALTH
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.HealthDisplayDistance = 80
	hum.DisplayName = "Dragón de la guarida"
	hum.Parent = m
	m:SetAttribute("DragonKind", kind)
	-- hacia dónde mira el modelo (de su pivote a la cabeza), para girarlo hacia los jugadores
	local b = { model = m, hum = hum, kind = kind, home = lair.Position, y = m:GetPivot().Position.Y, rot = rot, yaw = 0, mode = "stop", speed = 0,
		brain = Logic.Boss.new({ Reach = math.max(12, size.Z * 0.35), Speed = 12, Detect = 80, Leash = 80 }) }
	local fwd = headPos(b) - m:GetPivot().Position
	fwd = Vector3.new(fwd.X, 0, fwd.Z)
	b.headYaw = fwd.Magnitude > 0.1 and math.atan2(fwd.X, fwd.Z) or math.pi
	b.size = size
	boss = b
	bossAnim(b, "Idle", 0)
end

local function bossTarget(b)
	local best, bestD = nil, math.huge
	local p0 = b.model:GetPivot().Position
	for _, p in ipairs(Players:GetPlayers()) do
		local h = alive(p)
		if h then
			local d = Vector3.new(h.Position.X - p0.X, 0, h.Position.Z - p0.Z).Magnitude
			if d < bestD then
				best, bestD = p, d
			end
		end
	end
	return best
end

local function bossApply(b, orders)
	for _, o in ipairs(orders) do
		if o[1] == "anim" then
			bossAnim(b, o[2], o[3])
		elseif o[1] == "move" then
			b.mode, b.speed = o[2], o[3]
		elseif o[1] == "sound" then
			playSound(b.model, o[2])
		elseif o[1] == "attack" then
			task.delay(o[2], function()
				local t = b.target and alive(b.target)
				local _, hum = nil, nil
				if b.target then
					_, hum = alive(b.target)
				end
				if t and hum and not b.dead and (t.Position - headPos(b)).Magnitude <= b.brain.cfg.Reach * 1.3 then
					hum:TakeDamage(BOSS_DAMAGE)
				end
			end)
		end
	end
end

local thinkAt = 0
RunService.Heartbeat:Connect(function(dt)
	local b = boss
	if not b or not b.model.Parent then
		return
	end
	local now = os.clock()
	if now >= thinkAt and not b.dead then
		thinkAt = now + 0.1
		b.target = bossTarget(b)
		local h = b.target and alive(b.target)
		local p0 = b.model:GetPivot().Position
		local flat = function(v)
			return Vector3.new(v.X, 0, v.Z)
		end
		local P = {
			hasTarget = h ~= nil, dist = h and (h.Position - headPos(b)).Magnitude or math.huge,
			fromHome = flat(p0 - b.home).Magnitude, targetFromHome = h and flat(h.Position - b.home).Magnitude or math.huge,
			dead = b.hum.Health <= 0,
		}
		bossApply(b, b.brain:Update(0.1, P))
		if P.dead and not b.dead then
			b.dead = true
			b.mode = "stop"
			local pos = headPos(b)
			task.delay(1.5, function()
				dropItem("DragonSaliva", Vector3.new(pos.X, b.y, pos.Z), false)
			end)
			toast(nil, "¡El dragón de la guarida ha caído! Ha dejado su saliva.")
			task.delay(30, function()
				if b.model.Parent then
					cleanse(b.model)
				end
			end)
			task.delay(BOSS_RESPAWN, function()
				if not folder:GetAttribute("Cured") then
					spawnBoss()
				end
			end)
		end
	end
	-- movimiento: andar hacia el objetivo o hacia la guarida, girando poco a poco
	local p0 = b.model:GetPivot().Position
	local goal
	if b.mode == "chase" and b.target then
		local h = alive(b.target)
		goal = h and h.Position
	elseif b.mode == "home" then
		goal = b.home
	end
	local face = goal
	if not face and b.target and not b.dead then
		local h = alive(b.target)
		face = h and h.Position
	end
	if face then
		local d = Vector3.new(face.X - p0.X, 0, face.Z - p0.Z)
		if d.Magnitude > 0.5 then
			local want = math.atan2(d.X, d.Z) - b.headYaw
			local diff = (want - b.yaw + math.pi) % (2 * math.pi) - math.pi
			b.yaw += math.clamp(diff, -1.6 * dt, 1.6 * dt)
		end
	end
	local pos = p0
	if goal and not b.dead then
		local d = Vector3.new(goal.X - p0.X, 0, goal.Z - p0.Z)
		local stopAt = b.mode == "home" and 1 or b.brain.cfg.Reach * 0.7
		if d.Magnitude > stopAt then
			pos = p0 + d.Unit * math.min(d.Magnitude - stopAt, b.speed * dt)
		end
	end
	b.model:PivotTo(CFrame.new(pos.X, b.y, pos.Z) * CFrame.Angles(0, b.yaw, 0) * b.rot)
end)

task.spawn(function()
	task.wait(3)
	if not folder:GetAttribute("Cured") then
		spawnBoss()
	end
end)

-- ---------------------------------------------------------------- preparación (cada frame)
RunService.Heartbeat:Connect(function()
	if brew.state == "Brewing" then
		folder:SetAttribute("BrewFraction", brew:Fraction(os.clock()))
		if brew:Update(os.clock()) then
			folder:SetAttribute("Brewing", false)
			folder:SetAttribute("BrewFraction", 1)
			if liquid and liquid:FindFirstChild("Bubbles") then
				liquid.Bubbles.Rate = 6
			end
			playSound(cauldron, "Ready")
			toast(nil, "¡El Remedio del Alba está listo! Cogedlo del caldero y usadlo.")
			publish()
			updatePrompts()
		end
	end
end)
