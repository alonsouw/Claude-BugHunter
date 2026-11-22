--[[
	ArmorService (Script) · ServerScriptService.ArmorService

	  · Maniquíes: cada ProximityPrompt dentro de Workspace.ArmorStands con el atributo ArmorSet equipa esa
	    armadura al jugador (si ya la lleva, se la quita).
	  · Defensa: mientras lleva armadura, de cada pérdida de vida se le devuelve el porcentaje "Reduction"
	    (funciona con cualquier fuente de daño: lobos, infectados, caídas, armas).
	  · Velocidad: suma "Speed" a su WalkSpeed y lo restaura al quitársela.
	  · Al reaparecer conserva la armadura (atributo Armor del jugador).

	Desde otros scripts del servidor (tiendas, cofres, recompensas):
	  ReplicatedStorage.Armor.EquipArmor:Invoke(player, "Dragon")   -- "Leather", "Wolf", "Dragon"; nil o "" para quitarla
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local armorFolder = ReplicatedStorage:WaitForChild("Armor")
local Builder = require(armorFolder:WaitForChild("ArmorBuilder"))
local Data = require(armorFolder:WaitForChild("ArmorData"))

local conns = {}

local function strip(character)
	Builder.Detach(character)
	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum and character:GetAttribute("BaseWalkSpeed") then
		hum.WalkSpeed = character:GetAttribute("BaseWalkSpeed")
	end
	character:SetAttribute("ArmorSet", nil)
	character:SetAttribute("DamageReduction", nil)
	if conns[character] then
		conns[character]:Disconnect()
		conns[character] = nil
	end
end

local function dress(character, setName)
	strip(character)
	local st = Data.stats[setName]
	if not st then
		return
	end
	local hum = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if not hum then
		return
	end
	Builder.Attach(character, setName)
	character:SetAttribute("ArmorSet", setName)
	character:SetAttribute("DamageReduction", st.Reduction)
	if not character:GetAttribute("BaseWalkSpeed") then
		character:SetAttribute("BaseWalkSpeed", hum.WalkSpeed)
	end
	hum.WalkSpeed = character:GetAttribute("BaseWalkSpeed") + st.Speed
	local last, busy = hum.Health, false
	conns[character] = hum.HealthChanged:Connect(function(h)
		if busy then
			return
		end
		if h > 0 and h < last then
			busy = true
			h = Builder.Refund(last, h, st.Reduction)
			hum.Health = h
			busy = false
		end
		last = h
	end)
end

local function equip(player, setName)
	if setName == "" then
		setName = nil
	end
	player:SetAttribute("Armor", setName)
	local character = player.Character
	if character then
		if setName then
			dress(character, setName)
		else
			strip(character)
		end
	end
end

local fn = armorFolder:FindFirstChild("EquipArmor") or Instance.new("BindableFunction")
fn.Name = "EquipArmor"
fn.OnInvoke = equip
fn.Parent = armorFolder

local function onPlayer(player)
	player.CharacterAdded:Connect(function(character)
		local setName = player:GetAttribute("Armor")
		if setName then
			character:WaitForChild("HumanoidRootPart", 10)
			task.wait(0.2)   -- espera a que carguen las partes del avatar
			dress(character, setName)
		end
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayer(p)
end

-- maniquíes con ProximityPrompt
local function hookPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") or prompt:GetAttribute("Hooked") then
		return
	end
	prompt:SetAttribute("Hooked", true)
	prompt.Triggered:Connect(function(player)
		local setName = prompt:GetAttribute("ArmorSet")
		if player:GetAttribute("Armor") == setName then
			equip(player, nil)
		else
			equip(player, setName)
		end
	end)
end
local stands = workspace:FindFirstChild("ArmorStands")
if stands then
	for _, d in ipairs(stands:GetDescendants()) do
		hookPrompt(d)
	end
	stands.DescendantAdded:Connect(hookPrompt)
end
