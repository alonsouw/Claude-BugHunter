--[[
	ShadowClient (LocalScript) · StarterPlayer.StarterPlayerScripts.ShadowClient

	Parte visual y sonora del Dragón Sombrío en cada jugador. El servidor (ShadowStalker) decide;
	aquí se anima el rig, se suaviza el movimiento, se hacen los fundidos y suena el ambiente.

	  · envía el CFrame de la cámara 5 veces por segundo (para saber si lo miras)
	  · reproduce la animación que indica el servidor; si está "Frozen", congela la pose tal como está
	  · la cabeza te sigue despacio (cada jugador siente que lo mira a él) y se ladea según "Tilt"
	  · aparición / desaparición gradual: los ojos se encienden antes que el cuerpo y se apagan después
	  · rendimiento: invisible = animador en pausa; lejos = menos actualizaciones por segundo
	  · sonido: crujidos cerca, ambiente difícil de localizar y silencios repentinos
	  · visión nocturna de prueba con la tecla N (solo si Settings.ProvideNightVision = true)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local Dragons = ReplicatedStorage:WaitForChild("Dragons")
local DragonAnimator = require(Dragons:WaitForChild("DragonAnimator"))
local folder = Dragons:WaitForChild("ShadowDragon")
local animations = require(folder:WaitForChild("Animations"))
local settings = folder:WaitForChild("Settings")
local gazeRemote = folder:WaitForChild("ShadowGaze")
local ambientFolder = folder:FindFirstChild("AmbientSounds")
local player = Players.LocalPlayer

local LOOK = { Head = "Head", Neck = "Neck2", NeckShare = 0.45, MaxYaw = 85, MaxPitch = 35, RestPitch = -5, Speed = 1.1 }

-- mirada de la cámara al servidor (UnreliableRemoteEvent: barato y sin cola)
task.spawn(function()
	while true do
		local cam = workspace.CurrentCamera
		if cam then
			gazeRemote:FireServer(cam.CFrame)
		end
		task.wait(0.2)
	end
end)

local live = workspace:WaitForChild("ShadowDragonLive") :: Model
local scale = live:GetAttribute("RigScale") or 1
local animator = DragonAnimator.new(live, animations)
animator:Play(live:GetAttribute("Anim") or "Idle", 0)
animator:SetLookTarget(function()
	local cam = workspace.CurrentCamera
	return cam and cam.CFrame.Position
end, LOOK)
animator:SetHeadTilt(0, 1.2)

-- piezas: mallas (fundido), puntos de ojos (siguen al hueso Head) y dientes
local meshes, eyes, follow = {}, {}, {}
for _, d in ipairs(live:GetDescendants()) do
	if d:IsA("MeshPart") then
		table.insert(meshes, d)
	end
end
for _, p in ipairs(live:GetChildren()) do
	if p:IsA("BasePart") and p:GetAttribute("Offset") then
		local bone = live:FindFirstChild(p:GetAttribute("Bone"), true)
		if bone then
			table.insert(follow, { p, bone, p:GetAttribute("Offset") })
		end
		if p:GetAttribute("Kind") == "eye" then
			table.insert(eyes, p)
		end
	end
end

-- la sonrisa brilla en la oscuridad (Neon tenue); el color controla la intensidad
local teeth = live:FindFirstChild("Teeth", true)
if teeth and teeth:IsA("BasePart") and settings:GetAttribute("TeethGlow") ~= false then
	teeth.Material = Enum.Material.Neon
	teeth.Color = settings:GetAttribute("TeethGlowColor") or Color3.fromRGB(128, 124, 116)
end

-- visibilidad: 0 = invisible, 1 = visible
local vis, visGoal, fadeTime = 0, 0, 1
local function applyVisibility()
	for _, m in ipairs(meshes) do
		m.LocalTransparencyModifier = 1 - vis
	end
	local eyeVis = math.clamp(vis * 1.6, 0, 1) -- los ojos llegan antes y se van después
	for _, e in ipairs(eyes) do
		e.LocalTransparencyModifier = 1 - eyeVis
		local light = e:FindFirstChildOfClass("PointLight")
		if light then
			light.Enabled = eyeVis > 0.02
			light.Brightness = (e:GetAttribute("LightBrightness") or 1.2) * eyeVis
		end
	end
end
local function onVisible()
	visGoal = live:GetAttribute("Visible") and 1 or 0
	fadeTime = math.max(live:GetAttribute("FadeTime") or 1, 0.01)
	if fadeTime <= 0.011 then
		vis = visGoal
	end
end
live:GetAttributeChangedSignal("FadeStamp"):Connect(onVisible)
live:GetAttributeChangedSignal("Visible"):Connect(onVisible)
onVisible()
vis = visGoal
applyVisibility()

-- animación, inmovilidad y posturas
local posing = false
local function refreshPause()
	animator.Paused = vis <= 0.001 or (live:GetAttribute("Frozen") and not posing)
end
live:GetAttributeChangedSignal("AnimStamp"):Connect(function()
	animator:Play(live:GetAttribute("Anim") or "Idle", live:GetAttribute("AnimFade") or 0.3)
end)
live:GetAttributeChangedSignal("PoseStamp"):Connect(function()
	local pose = live:GetAttribute("Pose")
	if pose and pose ~= "" then
		posing = true
		animator:Play(pose, 0.3)
		task.delay(0.4, function()
			posing = false
		end)
	end
end)
live:GetAttributeChangedSignal("Tilt"):Connect(function()
	animator:SetHeadTilt(live:GetAttribute("Tilt") or 0, 1.2)
end)

-- movimiento suave hacia el Root que publica el servidor
local current = live:GetAttribute("Root") or live:GetPivot()
live:PivotTo(current)

-- sonidos
local closeCreak = live:FindFirstChild("Creak", true)
local ambient = {}
if ambientFolder then
	for _, s in ipairs(ambientFolder:GetChildren()) do
		if s:IsA("Sound") and s.SoundId ~= "" then
			table.insert(ambient, s)
		end
	end
end
local emitter = Instance.new("Part")
emitter.Name = "ShadowAmbientEmitter"
emitter.Anchored = true
emitter.CanCollide = false
emitter.CanQuery = false
emitter.CanTouch = false
emitter.Transparency = 1
emitter.Size = Vector3.one
emitter.Parent = workspace

local silenced = false
local savedVolumes = {}
local function setSilence(on: boolean)
	if on == silenced then
		return
	end
	silenced = on
	local groupName = settings:GetAttribute("AmbientGroupName") or "Ambient"
	local groups = {}
	for _, g in ipairs(SoundService:GetDescendants()) do
		if g:IsA("SoundGroup") and g.Name == groupName then
			table.insert(groups, g)
		end
	end
	for _, g in ipairs(groups) do
		if on then
			savedVolumes[g] = g.Volume
			TweenService:Create(g, TweenInfo.new(0.12), { Volume = 0 }):Play()
		elseif savedVolumes[g] then
			TweenService:Create(g, TweenInfo.new(2.5), { Volume = savedVolumes[g] }):Play()
		end
	end
	for _, s in ipairs(emitter:GetChildren()) do
		if s:IsA("Sound") then
			s:Stop()
		end
	end
end

local nextAmbient = os.clock() + 20 + math.random() * 40
local nextCreak = os.clock() + 5
local function ambientTick(now, myPos, dragonDist)
	if silenced or #ambient == 0 or not myPos then
		return
	end
	if now >= nextAmbient then
		-- más frecuente cuando el dragón está presente; siempre en un punto distinto alrededor
		nextAmbient = now + (vis > 0.5 and (12 + math.random() * 25) or (35 + math.random() * 60))
		local a = math.random() * math.pi * 2
		local d = 25 + math.random() * 40
		emitter.Position = myPos + Vector3.new(math.cos(a) * d, math.random() * 8 - 2, math.sin(a) * d)
		local s = ambient[math.random(#ambient)]:Clone()
		s.PlaybackSpeed = 0.85 + math.random() * 0.25
		s.Parent = emitter
		s:Play()
		s.Ended:Once(function()
			s:Destroy()
		end)
	end
	if closeCreak and vis > 0.5 and dragonDist < 55 * scale and now >= nextCreak then
		nextCreak = now + 4 + math.random() * 9
		closeCreak.PlaybackSpeed = 0.8 + math.random() * 0.3
		closeCreak:Play()
	end
end

-- visión nocturna de prueba (el juego final puede usar la suya)
if settings:GetAttribute("ProvideNightVision") then
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "ShadowNightVision"
	cc.Enabled = false
	cc.TintColor = Color3.fromRGB(150, 255, 160)
	cc.Brightness = 0.18
	cc.Contrast = 0.15
	cc.Saturation = -0.6
	cc.Parent = Lighting
	local savedExposure = Lighting.ExposureCompensation
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.N then
			cc.Enabled = not cc.Enabled
			Lighting.ExposureCompensation = cc.Enabled and savedExposure + 2.2 or savedExposure
		end
	end)
end

RunService.RenderStepped:Connect(function(dt)
	-- fundido
	if vis ~= visGoal then
		local stepV = dt / fadeTime
		vis = visGoal > vis and math.min(visGoal, vis + stepV) or math.max(visGoal, vis - stepV)
		applyVisibility()
	end
	-- posición
	local goal = live:GetAttribute("Root") or current
	if (goal.Position - current.Position).Magnitude > 25 * scale or vis <= 0.001 then
		current = goal -- teletransporte o invisible: salto directo
	else
		current = current:Lerp(goal, 1 - math.exp(-dt * 8))
	end
	if vis > 0.001 then
		live:PivotTo(current)
		for _, e in ipairs(follow) do
			e[1].CFrame = e[2].TransformedWorldCFrame * e[3]
		end
	end
	-- rendimiento: menos actualizaciones lejos de la cámara
	local cam = workspace.CurrentCamera
	local camDist = cam and (cam.CFrame.Position - current.Position).Magnitude or 0
	animator.UpdateInterval = camDist < 90 * scale and 0 or (camDist < 220 * scale and 1 / 20 or 1 / 10)
	refreshPause()
	-- sonido
	local now = os.clock()
	setSilence(workspace:GetServerTimeNow() < (live:GetAttribute("SilenceUntil") or 0))
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	ambientTick(now, hrp and hrp.Position, hrp and (hrp.Position - current.Position).Magnitude or math.huge)
end)
