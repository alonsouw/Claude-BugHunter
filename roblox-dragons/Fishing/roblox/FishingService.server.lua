--[[
	FishingService (Script) · ServerScriptService.FishingService

	La pesca en el servidor (la lógica de cada jugador es FishingLogic):
	  · Lanzar: el cliente de la caña manda dónde ha hecho clic; aquí se comprueba que es agua (de Terrain o una zona
	    FishZone) y que está a menos de CastRange. Sale la boya en arco, atada con el sedal (un Beam) a la punta.
	  · Esperar, picar (la boya se hunde y salpica), clavar y recoger: los estados van al cliente para su interfaz.
	  · Al sacarlo, el pez (un Tool de ReplicatedStorage.Fishing.Fish) va a la mochila del jugador.
	  · Comer: cualquier Tool con la etiqueta "FishFood": clic con él en la mano. Cura y, si el jugador tiene el
	    atributo Hunger, lo sube. Crudo puede sentar mal. Avisa con ReplicatedStorage.Fishing.FishEaten.
	  · Cocinar: en las hogueras (etiqueta "Campfire" o dentro de Workspace.Campfires) aparece «Cocinar pescado» (E);
	    cambia el pez crudo que tienes en la mano por el cocinado.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local folder = ReplicatedStorage:WaitForChild("Fishing")
local Logic = require(folder:WaitForChild("FishingLogic"))
local fishFolder = folder:WaitForChild("Fish")
local bobberTemplate = folder:WaitForChild("Bobber")
local settings = folder:WaitForChild("Settings")
local rng = Random.new()

local function S(k, d)
	local v = settings:GetAttribute(k)
	if v == nil then
		return d
	end
	return v
end
local CAST_RANGE = S("CastRange", 45)
local SICK_CHANCE = S("RawSickChance", 0.25)
local HUNGER_ATTR = S("HungerAttribute", "Hunger")
local MAX_HUNGER = S("MaxHunger", 100)
local SPECIES = {}
for _, s in ipairs({ { "Trout", 60, 14 }, { "Perch", 30, 18 }, { "GoldenSalmon", 10, 26 } }) do
	table.insert(SPECIES, { s[1], S(s[1] .. "Weight", s[2]), S(s[1] .. "Drain", s[3]) })
end
local LOGIC_CFG = {
	WaitTime = { S("WaitMin", 4), S("WaitMax", 12) },
	BiteWindow = S("BiteWindow", 1.3),
	ReelPower = S("ReelPower", 9),
	Species = SPECIES,
}

local remote = folder:FindFirstChild("Remote") or Instance.new("RemoteEvent")
remote.Name = "Remote"
remote.Parent = folder
local eaten = folder:FindFirstChild("FishEaten") or Instance.new("BindableEvent")
eaten.Name = "FishEaten"   -- FishEaten.Event:Connect(function(player, species, cooked, heal, food) ... end)
eaten.Parent = folder
local bobbers = workspace:FindFirstChild("FishingBobbers") or Instance.new("Folder")
bobbers.Name = "FishingBobbers"
bobbers.Parent = workspace

local NAMES = { Trout = "Trucha", Perch = "Perca", GoldenSalmon = "Salmón dorado" }
local COOKED = { Trout = "Trucha cocinada", Perch = "Perca cocinada", GoldenSalmon = "Salmón dorado cocinado" }
local ESCAPE = {
	early = "¡Lo has espantado! Espera a que pique.",
	late = "Se ha llevado el cebo...",
	lost = "Se ha escapado...",
	tired = "Se ha soltado del anzuelo.",
}

local function toast(player, text)
	remote:FireClient(player, "toast", text)
end
local function playSound(parent, name)
	local s = parent and parent:FindFirstChild(name, true)
	if s and s:IsA("Sound") and s.SoundId ~= "" then
		s:Play()
	end
end
local function splash(pos, n)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one
	p.CFrame = CFrame.new(pos)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(225, 240, 255))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.3, 0.6)
	e.Speed = NumberRange.new(5, 9)
	e.SpreadAngle = Vector2.new(40, 40)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -35, 0)
	e.Rate = 0
	e.Parent = p
	p.Parent = workspace
	e:Emit(n or 12)
	Debris:AddItem(p, 1.5)
end

-- ---------------------------------------------------------------- agua
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false
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
-- superficie del agua bajo/sobre un punto, o nil si ahí no hay agua
local function waterSurfaceAt(pos)
	for _, z in ipairs(zones()) do
		local lp = z.CFrame:PointToObjectSpace(pos)
		local h = z.Size / 2
		if math.abs(lp.X) <= h.X and math.abs(lp.Z) <= h.Z and lp.Y <= h.Y + 4 and lp.Y >= -h.Y then
			return Vector3.new(pos.X, z.Position.Y + h.Y, pos.Z)
		end
	end
	local list = { bobbers }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	rayParams.FilterDescendantsInstances = list
	local hit = workspace:Raycast(pos + Vector3.new(0, 10, 0), Vector3.new(0, -30, 0), rayParams)
	if hit and hit.Instance == workspace.Terrain and hit.Material == Enum.Material.Water then
		return hit.Position
	end
	return nil
end
local function findCastPoint(hrp, wanted)
	local flat = function(p)
		return Vector3.new(p.X - hrp.Position.X, 0, p.Z - hrp.Position.Z).Magnitude
	end
	if typeof(wanted) == "Vector3" and flat(wanted) <= CAST_RANGE then
		local w = waterSurfaceAt(wanted)
		if w then
			return w
		end
	end
	-- sin un punto válido (o en móvil): prueba delante del jugador
	local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	look = look.Magnitude > 0.1 and look.Unit or Vector3.new(0, 0, -1)
	for d = 8, CAST_RANGE, 3 do
		local w = waterSurfaceAt(hrp.Position + look * d - Vector3.new(0, 3, 0))
		if w then
			return w
		end
	end
	return nil
end

-- ---------------------------------------------------------------- sesiones de pesca
local sessions = {}

local function equippedRod(player)
	local c = player.Character
	local tool = c and c:FindFirstChildOfClass("Tool")
	if tool and CollectionService:HasTag(tool, "FishingRod") then
		return tool
	end
	return nil
end

local function removeBobber(s, pullIn)
	local b = s.bobber
	s.bobber = nil
	if not b then
		return
	end
	if pullIn and s.tool and s.tool:FindFirstChild("Tip") then
		local cv = Instance.new("CFrameValue")
		cv.Value = b:GetPivot()
		cv.Changed:Connect(function(v)
			b:PivotTo(v)
		end)
		TweenService:Create(cv, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = s.tool.Tip.CFrame }):Play()
		Debris:AddItem(cv, 0.5)
		Debris:AddItem(b, 0.4)
	else
		b:Destroy()
	end
end

local function flick(tool)   -- golpe de muñeca al lanzar: la caña atrás y adelante
	local g = tool.Grip
	tool.Grip = g * CFrame.Angles(math.rad(-35), 0, 0)
	task.delay(0.15, function()
		tool.Grip = g * CFrame.Angles(math.rad(25), 0, 0)
		task.delay(0.2, function()
			tool.Grip = g
		end)
	end)
end

local function spawnBobber(s, target)
	local b = bobberTemplate:Clone()
	local tip = s.tool:FindFirstChild("Tip")
	local start = tip and tip.Position or target
	b:PivotTo(CFrame.new(start))
	b.Parent = bobbers
	local a1 = b.Handle:FindFirstChild("Line")
	local a0 = tip and tip:FindFirstChild("Tip")
	if a0 and a1 then
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = a0, a1
		beam.Width0, beam.Width1 = 0.04, 0.03
		beam.Color = ColorSequence.new(Color3.fromRGB(235, 235, 230))
		beam.FaceCamera = true
		beam.Segments = 12
		beam.CurveSize0, beam.CurveSize1 = 0, 0
		beam.Parent = b.Handle
	end
	-- vuelo en arco hasta el agua
	local cv = Instance.new("CFrameValue")
	cv.Value = CFrame.new(start)
	cv.Changed:Connect(function(v)
		if b.Parent then
			b:PivotTo(v)
		end
	end)
	local mid = start:Lerp(target, 0.5) + Vector3.new(0, 5, 0)
	local up = TweenService:Create(cv, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = CFrame.new(mid) })
	local down = TweenService:Create(cv, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = CFrame.new(target) })
	up.Completed:Connect(function()
		down:Play()
	end)
	down.Completed:Connect(function()
		cv:Destroy()
		if b.Parent then
			splash(target, 8)
			playSound(b, "Plop")
		end
	end)
	up:Play()
	s.bobber, s.target = b, target
end

local function fishProto(species, cooked)   -- los Tools de Fishing.Fish se buscan por sus atributos
	for _, t in ipairs(fishFolder:GetChildren()) do
		if t:GetAttribute("Species") == species and (t:GetAttribute("Cooked") == true) == cooked then
			return t
		end
	end
	return nil
end

local function giveFish(player, species)
	local proto = fishProto(species, false)
	if proto then
		local t = proto:Clone()
		t.Parent = player:FindFirstChildOfClass("Backpack") or player.Character
	end
end

local function handle(player, s, events)
	for _, e in ipairs(events) do
		local kind = e[1]
		if kind == "state" then
			remote:FireClient(player, "state", e[2])
			if e[2] == "Idle" then
				s.active = false
			end
		elseif kind == "bite" then
			if s.bobber then
				splash(s.target, 10)
				playSound(s.bobber, "Plop")
			end
		elseif kind == "progress" then
			remote:FireClient(player, "progress", e[2])
		elseif kind == "caught" then
			giveFish(player, e[2])
			if s.tool then
				playSound(s.tool, "Catch")
			end
			if s.target then
				splash(s.target, 16)
			end
			toast(player, ("¡Has pescado: %s!"):format(NAMES[e[2]] or e[2]))
			removeBobber(s, true)
		elseif kind == "escaped" then
			toast(player, ESCAPE[e[2]] or "Se ha escapado...")
			removeBobber(s, true)
		end
	end
end

local function session(player)
	local s = sessions[player]
	if not s then
		s = { logic = Logic.new(table.clone(LOGIC_CFG), Random.new(rng:NextInteger(1, 1e6))) }
		sessions[player] = s
	end
	return s
end

remote.OnServerEvent:Connect(function(player, action, data)
	local s = session(player)
	local now = os.clock()
	if action == "cast" then
		local tool = equippedRod(player)
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not tool or not hrp or s.logic.state ~= "Idle" then
			return
		end
		local target = findCastPoint(hrp, data)
		if not target then
			toast(player, "Apunta al agua (hasta " .. CAST_RANGE .. " studs).")
			return
		end
		s.tool = tool
		s.active = true
		flick(tool)
		playSound(tool, "Cast")
		spawnBobber(s, target)
		handle(player, s, s.logic:Cast(now))
	elseif action == "hook" then
		handle(player, s, s.logic:Hook(now))
	elseif action == "reel" then
		local before = s.logic.progress
		handle(player, s, s.logic:Reel(now))
		if s.tool and s.logic.progress ~= before then
			playSound(s.tool, "Reel")
		end
	elseif action == "cancel" then
		handle(player, s, s.logic:Cancel())
		removeBobber(s, false)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local s = sessions[player]
	if s then
		removeBobber(s, false)
		sessions[player] = nil
	end
end)

local lastProgress = 0
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local sendProgress = now - lastProgress > 0.1
	if sendProgress then
		lastProgress = now
	end
	for player, s in pairs(sessions) do
		if s.active then
			-- si ha guardado la caña o ha muerto, se acaba
			if not s.tool or s.tool.Parent ~= player.Character then
				handle(player, s, s.logic:Cancel())
				removeBobber(s, false)
			else
				handle(player, s, s.logic:Update(now))
				local st = s.logic.state
				if st == "Reeling" and sendProgress then
					remote:FireClient(player, "progress", s.logic.progress)
				end
				-- la boya: flota, se hunde al picar y se acerca mientras recoges
				local b, t = s.bobber, s.target
				if b and t and (st == "Waiting" or st == "Bite" or st == "Reeling") then
					local pos = t
					if st == "Waiting" then
						pos += Vector3.new(0, math.sin(now * 3) * 0.06, 0)
					elseif st == "Bite" then
						pos += Vector3.new(math.sin(now * 23) * 0.08, -0.3 + math.sin(now * 17) * 0.12, 0)
					else
						local hrp = player.Character:FindFirstChild("HumanoidRootPart")
						if hrp then
							local toward = Vector3.new(hrp.Position.X - t.X, 0, hrp.Position.Z - t.Z)
							pos += toward * (s.logic.progress / 100) * 0.5 + Vector3.new(math.sin(now * 13) * 0.25, -0.15, math.cos(now * 11) * 0.25)
						end
					end
					b:PivotTo(CFrame.new(pos))
				end
			end
		end
	end
end)

-- ---------------------------------------------------------------- comer
local function ownerOf(tool)
	local c = tool.Parent
	return c and Players:GetPlayerFromCharacter(c), c
end
local function eat(tool)
	if tool:GetAttribute("Eating") then
		return
	end
	local player, character = ownerOf(tool)
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not player or not hum or hum.Health <= 0 then
		return
	end
	tool:SetAttribute("Eating", true)
	playSound(tool, "Eat")
	task.wait(0.7)
	if tool.Parent ~= character then   -- lo ha guardado a medio bocado
		tool:SetAttribute("Eating", nil)
		return
	end
	local species = tool:GetAttribute("Species") or "Trout"
	local cooked = tool:GetAttribute("Cooked") == true
	local heal, food = tool:GetAttribute("Heal") or 10, tool:GetAttribute("Food") or 15
	hum.Health = math.min(hum.MaxHealth, hum.Health + heal)
	for _, holder in ipairs({ player, character }) do
		local h = holder:GetAttribute(HUNGER_ATTR)
		if type(h) == "number" then
			holder:SetAttribute(HUNGER_ATTR, math.min(MAX_HUNGER, h + food))
		end
	end
	eaten:Fire(player, species, cooked, heal, food)
	tool:Destroy()
	if not cooked and rng:NextNumber() < SICK_CHANCE then
		toast(player, "El pescado crudo te ha sentado mal...")
		task.spawn(function()
			for _ = 1, 5 do
				task.wait(1)
				if hum.Health > 0 then
					hum:TakeDamage(2)
				end
			end
		end)
	else
		toast(player, ("%s: +%d de vida"):format(cooked and "¡Qué rico!" or "Crudo, pero alimenta", heal))
	end
end
local function hookFood(tool)
	if tool:IsA("Tool") and not tool:GetAttribute("FoodHooked") then
		tool:SetAttribute("FoodHooked", true)
		tool.Activated:Connect(function()
			eat(tool)
		end)
	end
end
for _, t in ipairs(CollectionService:GetTagged("FishFood")) do
	hookFood(t)
end
CollectionService:GetInstanceAddedSignal("FishFood"):Connect(hookFood)

-- ---------------------------------------------------------------- cocinar en hogueras
local function cook(player, fire)
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if not tool or not CollectionService:HasTag(tool, "FishFood") or tool:GetAttribute("Cooked") then
		toast(player, "Ten en la mano un pescado crudo para cocinarlo.")
		return
	end
	local species = tool:GetAttribute("Species")
	local proto = species and fishProto(species, true)
	if not proto then
		return
	end
	tool:Destroy()
	proto:Clone().Parent = character   -- ya en la mano
	playSound(fire, "Sizzle")
	toast(player, ("¡%s!"):format(COOKED[species] or species))
end
local function hookFire(inst)
	local part = inst:IsA("BasePart") and inst or (inst:IsA("Model") and (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)))
	if not part or part:FindFirstChild("CookPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CookPrompt"
	prompt.ActionText = "Cocinar pescado"
	prompt.ObjectText = "Hoguera"
	prompt.HoldDuration = 2
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		cook(player, inst)
	end)
end
for _, f in ipairs(CollectionService:GetTagged("Campfire")) do
	hookFire(f)
end
CollectionService:GetInstanceAddedSignal("Campfire"):Connect(hookFire)
local cf = workspace:FindFirstChild("Campfires")
if cf then
	for _, f in ipairs(cf:GetChildren()) do
		hookFire(f)
	end
	cf.ChildAdded:Connect(hookFire)
end
