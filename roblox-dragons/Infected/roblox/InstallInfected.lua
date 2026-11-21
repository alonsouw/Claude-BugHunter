--[[
	INSTALADOR DE LOS INFECTADOS (personajes de bloques) · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	No hace falta importar nada: pega TODO este archivo en View > Command Bar y pulsa Enter.
	Construye los cinco tipos con Parts (cada articulación es un Motor6D) y los guarda listos para el juego.

	Resultado:
	  ReplicatedStorage.Creatures.Infected.Types         (Walker, Runner, Bloater, Screamer, Brute)
	  ReplicatedStorage.Creatures.Infected               (Settings, Animations, InfectedBrain)
	  ReplicatedStorage.Dragons.DragonAnimator           (motor de animación, compartido con los dragones)
	  ServerScriptService.InfectedSpawner                (crea a los infectados y los controla)
	  StarterPlayer.StarterPlayerScripts.InfectedClient  (animación en cada jugador)
	  Workspace.InfectedPreview                          (los cinco en fila para verlos en Studio; se borra al jugar)
]]

local MAX_ALIVE = 20          -- infectados a la vez
local RESPAWN_DELAY = 20      -- segundos hasta que un muerto vuelve a aparecer (en otro sitio)
local NIGHT_ONLY = false      -- true: solo aparecen de noche
local SPAWN_CENTER = Vector3.new(0, 0, 0)
local SPAWN_RADIUS = 200
-- probabilidad de cada tipo
local WEIGHTS = { Walker = 0.5, Runner = 0.2, Bloater = 0.12, Screamer = 0.1, Brute = 0.08 }
-- Sonidos: sube los .ogg de sounds/ y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = { Groan = "", Scream = "", Hit = "", Pop = "", Roar = "" }

local BLUEPRINTS = {
	Walker = {
		limbs = {
			HumanoidRootPart = {
				size = { 2, 2, 1 },
				center = { 0, 3.15, 0 },
				transparent = true,
			},
			Torso = {
				size = { 2, 2, 1 },
				center = { 0, 3.15, 0 },
				color = { 150, 140, 120 },
				material = "Fabric",
			},
			Head = {
				size = { 1.15, 1.15, 1.15 },
				center = { 0, 4.745, 0 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
			},
			Jaw = {
				size = { 0.805, 0.26, 0.483 },
				center = { 0, 4.32, -0.414 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
			},
			LeftUpperArm = {
				size = { 1, 1.1, 1 },
				center = { -1.5, 3.55, 0 },
				color = { 150, 140, 120 },
				material = "Fabric",
			},
			RightUpperArm = {
				size = { 1, 1.1, 1 },
				center = { 1.5, 3.55, 0 },
				color = { 150, 140, 120 },
				material = "Fabric",
			},
			LeftLowerArm = {
				size = { 0.9, 1.1, 0.9 },
				center = { -1.5, 2.45, 0 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
			},
			RightLowerArm = {
				size = { 0.9, 1.1, 0.9 },
				center = { 1.5, 2.45, 0 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
			},
			LeftUpperLeg = {
				size = { 0.95, 1.1, 0.95 },
				center = { -0.5, 1.6, 0 },
				color = { 52, 62, 88 },
				material = "Fabric",
			},
			RightUpperLeg = {
				size = { 0.95, 1.1, 0.95 },
				center = { 0.5, 1.6, 0 },
				color = { 52, 62, 88 },
				material = "Fabric",
			},
			LeftLowerLeg = {
				size = { 0.9, 1.05, 0.9 },
				center = { -0.5, 0.525, 0 },
				color = { 52, 62, 88 },
				material = "Fabric",
			},
			RightLowerLeg = {
				size = { 0.9, 1.05, 0.9 },
				center = { 0.5, 0.525, 0 },
				color = { 52, 62, 88 },
				material = "Fabric",
			},
		},
		joints = {
			{
				"HumanoidRootPart",
				"Torso",
				{ 0, 3.15, 0 },
			},
			{
				"Torso",
				"Head",
				{ 0, 4.15, 0 },
			},
			{
				"Head",
				"Jaw",
				{ 0, 4.45, -0.138 },
			},
			{
				"Torso",
				"LeftUpperArm",
				{ -1.5, 3.8, 0 },
			},
			{
				"LeftUpperArm",
				"LeftLowerArm",
				{ -1.5, 3, 0 },
			},
			{
				"Torso",
				"RightUpperArm",
				{ 1.5, 3.8, 0 },
			},
			{
				"RightUpperArm",
				"RightLowerArm",
				{ 1.5, 3, 0 },
			},
			{
				"Torso",
				"LeftUpperLeg",
				{ -0.5, 2.15, 0 },
			},
			{
				"LeftUpperLeg",
				"LeftLowerLeg",
				{ -0.5, 1.05, 0 },
			},
			{
				"Torso",
				"RightUpperLeg",
				{ 0.5, 2.15, 0 },
			},
			{
				"RightUpperLeg",
				"RightLowerLeg",
				{ 0.5, 1.05, 0 },
			},
		},
		details = {
			{
				limb = "Head",
				size = { 0.3, 0.2, 0.06 },
				offset = { -0.25, 0.1, -0.58 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.15, 0.1, 0.06 },
				offset = { -0.25, 0.1, -0.595 },
				color = { 210, 255, 90 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.3, 0.2, 0.06 },
				offset = { 0.25, 0.1, -0.58 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.15, 0.1, 0.06 },
				offset = { 0.25, 0.1, -0.595 },
				color = { 210, 255, 90 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.62, 0.22, 0.06 },
				offset = { 0, -0.33, -0.58 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { -0.22, -0.25, -0.595 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { -0.11, -0.25, -0.595 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0, -0.25, -0.595 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0.11, -0.25, -0.595 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0.22, -0.25, -0.595 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { -0.17, 0.1, -0.2515 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { -0.06, 0.1, -0.2515 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { 0.05, 0.1, -0.2515 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { 0.16, 0.1, -0.2515 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.644, 0.06, 0.05 },
				offset = { 0, -0.1, -0.2515 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 1.173, 0.12, 0.805 },
				offset = { 0, 0.605, 0.12 },
				color = { 40, 32, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.3, 0.13, 0.3 },
				offset = { 0.2, 0.635, -0.15 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.2, 0.35, 0.04 },
				offset = { 0.12, -0.5, -0.585 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.35, 0.9, 0.04 },
				offset = { 0.15, 0.5, -0.51 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.22, 0.4, 0.04 },
				offset = { 0.4, -0.1, -0.51 },
				color = { 60, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.5558, 0.4726, 0.05 },
				offset = { -0.4204, 0.0709, -0.512 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.514, 0.2553, 0.05 },
				offset = { -0.1784, -0.6525, 0.512 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3085, 0.325, 0.05 },
				offset = { 0.3068, 0.5783, -0.512 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.4118, 0.3276, 0.05 },
				offset = { -0.4317, -0.1246, -0.512 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2871, 0.3706, 0.05 },
				offset = { 0.6122, 0.6797, -0.512 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.1435, 0.1853, 0.05 },
				offset = { 0.6122, 0.6797, -0.53 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.4734, 0.4352, 0.05 },
				offset = { -0.1703, -0.449, -0.512 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2528, 0.4235, 0.08 },
				offset = { -0.3614, -1.12, -0.46 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, -10.1471 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2787, 0.247, 0.08 },
				offset = { -0.3421, -1.12, -0.46 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, 2.4002 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2908, 0.213, 0.08 },
				offset = { 0.3444, -1.12, -0.46 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, 8.8235 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3072, 0.2786, 0.08 },
				offset = { -0.1328, -1.12, -0.46 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, -9.7255 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2432, 0.2259, 0.08 },
				offset = { 0.7305, -1.12, -0.46 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, 0.7579 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.06, 0.8, 0.6 },
				offset = { -1.01, 0.1, -0.05 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -1.03, 0.4, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -1.03, 0.2, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -1.03, 0, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -1.03, -0.2, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftUpperArm",
				size = { 1.04, 0.18, 1.04 },
				offset = { 0, -0.5, 0 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, 8 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.63, 0.3, 0.05 },
				offset = { 0, 0.1, -0.46 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { -0.25, -0.67, -0.15 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0, -0.67, -0.15 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0.25, -0.67, -0.15 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.04, 0.05, 0.04 },
				offset = { -0.25, -0.86, -0.15 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightUpperArm",
				size = { 1.04, 0.18, 1.04 },
				offset = { 0, -0.5, 0 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, -8 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.63, 0.3, 0.05 },
				offset = { 0, 0.1, -0.46 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { -0.25, -0.67, -0.15 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0, -0.67, -0.15 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0.25, -0.67, -0.15 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.04, 0.05, 0.04 },
				offset = { -0.25, -0.86, -0.15 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerLeg",
				size = { 0.945, 0.32, 1.215 },
				offset = { 0, -0.365, -0.15 },
				color = { 36, 30, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerLeg",
				size = { 0.4, 0.35, 0.05 },
				offset = { 0.1, 0.15, -0.46 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerLeg",
				size = { 0.945, 0.32, 1.215 },
				offset = { 0, -0.365, -0.15 },
				color = { 36, 30, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerLeg",
				size = { 0.4, 0.35, 0.05 },
				offset = { 0.1, 0.15, -0.46 },
				color = { 118, 134, 104 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightUpperLeg",
				size = { 0.5, 0.3, 0.05 },
				offset = { 0, 0.1, -0.49 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.4, 0.25, 0.05 },
				offset = { -0.25, 0.32, -0.585 },
				color = { 150, 40, 44 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
		},
		hipHeight = 2.15,
	},
	Runner = {
		limbs = {
			HumanoidRootPart = {
				size = { 2, 2, 1 },
				center = { 0, 3.15, 0 },
				transparent = true,
			},
			Torso = {
				size = { 1.7, 2, 0.8 },
				center = { 0, 3.15, 0 },
				color = { 150, 140, 120 },
				material = "Fabric",
			},
			Head = {
				size = { 1.05, 1.05, 1.05 },
				center = { 0, 4.695, 0 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
			},
			Jaw = {
				size = { 0.735, 0.26, 0.441 },
				center = { 0, 4.32, -0.378 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
			},
			LeftUpperArm = {
				size = { 0.8, 1.232, 0.8 },
				center = { -1.25, 3.484, 0 },
				color = { 150, 140, 120 },
				material = "Fabric",
			},
			RightUpperArm = {
				size = { 0.8, 1.232, 0.8 },
				center = { 1.25, 3.484, 0 },
				color = { 150, 140, 120 },
				material = "Fabric",
			},
			LeftLowerArm = {
				size = { 0.72, 1.232, 0.72 },
				center = { -1.25, 2.252, 0 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
			},
			RightLowerArm = {
				size = { 0.72, 1.232, 0.72 },
				center = { 1.25, 2.252, 0 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
			},
			LeftUpperLeg = {
				size = { 0.8075, 1.1, 0.8075 },
				center = { -0.425, 1.6, 0 },
				color = { 70, 58, 46 },
				material = "Fabric",
			},
			RightUpperLeg = {
				size = { 0.8075, 1.1, 0.8075 },
				center = { 0.425, 1.6, 0 },
				color = { 70, 58, 46 },
				material = "Fabric",
			},
			LeftLowerLeg = {
				size = { 0.765, 1.05, 0.765 },
				center = { -0.425, 0.525, 0 },
				color = { 70, 58, 46 },
				material = "Fabric",
			},
			RightLowerLeg = {
				size = { 0.765, 1.05, 0.765 },
				center = { 0.425, 0.525, 0 },
				color = { 70, 58, 46 },
				material = "Fabric",
			},
		},
		joints = {
			{
				"HumanoidRootPart",
				"Torso",
				{ 0, 3.15, 0 },
			},
			{
				"Torso",
				"Head",
				{ 0, 4.15, 0 },
			},
			{
				"Head",
				"Jaw",
				{ 0, 4.45, -0.126 },
			},
			{
				"Torso",
				"LeftUpperArm",
				{ -1.25, 3.8, 0 },
			},
			{
				"LeftUpperArm",
				"LeftLowerArm",
				{ -1.25, 2.868, 0 },
			},
			{
				"Torso",
				"RightUpperArm",
				{ 1.25, 3.8, 0 },
			},
			{
				"RightUpperArm",
				"RightLowerArm",
				{ 1.25, 2.868, 0 },
			},
			{
				"Torso",
				"LeftUpperLeg",
				{ -0.425, 2.15, 0 },
			},
			{
				"LeftUpperLeg",
				"LeftLowerLeg",
				{ -0.425, 1.05, 0 },
			},
			{
				"Torso",
				"RightUpperLeg",
				{ 0.425, 2.15, 0 },
			},
			{
				"RightUpperLeg",
				"RightLowerLeg",
				{ 0.425, 1.05, 0 },
			},
		},
		details = {
			{
				limb = "Head",
				size = { 0.3, 0.2, 0.06 },
				offset = { -0.2283, 0.1, -0.53 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.15, 0.1, 0.06 },
				offset = { -0.2283, 0.1, -0.545 },
				color = { 255, 60, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.3, 0.2, 0.06 },
				offset = { 0.2283, 0.1, -0.53 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.15, 0.1, 0.06 },
				offset = { 0.2283, 0.1, -0.545 },
				color = { 255, 60, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.62, 0.22, 0.06 },
				offset = { 0, -0.33, -0.53 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { -0.22, -0.25, -0.545 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { -0.11, -0.25, -0.545 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0, -0.25, -0.545 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0.11, -0.25, -0.545 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0.22, -0.25, -0.545 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { -0.17, 0.1, -0.2305 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { -0.06, 0.1, -0.2305 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { 0.05, 0.1, -0.2305 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { 0.16, 0.1, -0.2305 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.588, 0.06, 0.05 },
				offset = { 0, -0.1, -0.2305 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 1.071, 0.12, 0.735 },
				offset = { 0, 0.555, 0.12 },
				color = { 40, 32, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.3, 0.13, 0.3 },
				offset = { 0.2, 0.585, -0.15 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.2, 0.35, 0.04 },
				offset = { 0.12, -0.5, -0.535 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.35, 0.9, 0.04 },
				offset = { 0.15, 0.5, -0.41 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.22, 0.4, 0.04 },
				offset = { 0.4, -0.1, -0.41 },
				color = { 60, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.4644, 0.5244, 0.05 },
				offset = { -0.3553, 0.5789, -0.412 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2322, 0.2622, 0.05 },
				offset = { -0.3553, 0.5789, -0.43 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.5944, 0.5405, 0.05 },
				offset = { -0.6078, -0.6037, -0.412 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.5229, 0.3463, 0.05 },
				offset = { 0.1428, 0.3884, -0.412 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2615, 0.1732, 0.05 },
				offset = { 0.1428, 0.3884, -0.43 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.5122, 0.492, 0.05 },
				offset = { -0.0252, -0.5713, -0.412 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.4097, 0.2378, 0.05 },
				offset = { -0.514, -0.0633, -0.412 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.5742, 0.293, 0.05 },
				offset = { -0.565, 0.1478, -0.412 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2871, 0.1465, 0.05 },
				offset = { -0.565, 0.1478, -0.43 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2868, 0.2774, 0.08 },
				offset = { 0.0162, -1.12, -0.36 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, -10.2541 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2738, 0.2948, 0.08 },
				offset = { 0.4864, -1.12, -0.36 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, 14.8907 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2067, 0.2634, 0.08 },
				offset = { -0.0201, -1.12, -0.36 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, 12.62 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2539, 0.2437, 0.08 },
				offset = { 0.1144, -1.12, -0.36 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, -1.9812 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.1803, 0.3729, 0.08 },
				offset = { -0.4179, -1.12, -0.36 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, 7.8012 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.06, 0.8, 0.6 },
				offset = { -0.86, 0.1, -0.05 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -0.88, 0.4, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -0.88, 0.2, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -0.88, 0, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -0.88, -0.2, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftUpperArm",
				size = { 0.832, 0.18, 0.832 },
				offset = { 0, -0.566, 0 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, 8 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.504, 0.3, 0.05 },
				offset = { 0, 0.1, -0.37 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { -0.25, -0.736, -0.15 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0, -0.736, -0.15 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0.25, -0.736, -0.15 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.04, 0.05, 0.04 },
				offset = { -0.25, -0.926, -0.15 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightUpperArm",
				size = { 0.832, 0.18, 0.832 },
				offset = { 0, -0.566, 0 },
				color = { 150, 140, 120 },
				material = "Fabric",
				rot = { 0, 0, -8 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.504, 0.3, 0.05 },
				offset = { 0, 0.1, -0.37 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { -0.25, -0.736, -0.15 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0, -0.736, -0.15 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0.25, -0.736, -0.15 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.04, 0.05, 0.04 },
				offset = { -0.25, -0.926, -0.15 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerLeg",
				size = { 0.8033, 0.32, 1.0328 },
				offset = { 0, -0.365, -0.15 },
				color = { 36, 30, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerLeg",
				size = { 0.8033, 0.32, 1.0328 },
				offset = { 0, -0.365, -0.15 },
				color = { 36, 30, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerLeg",
				size = { 0.4, 0.35, 0.05 },
				offset = { 0.1, 0.15, -0.3925 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightUpperLeg",
				size = { 0.5, 0.3, 0.05 },
				offset = { 0, 0.1, -0.49 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 1.615, 0.9, 0.05 },
				offset = { 0, -0.3, -0.42 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.9, 0.06, 0.05 },
				offset = { 0, -0.05, -0.44 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.9, 0.06, 0.05 },
				offset = { 0, -0.23, -0.44 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.9, 0.06, 0.05 },
				offset = { 0, -0.41, -0.44 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.9, 0.06, 0.05 },
				offset = { 0, -0.59, -0.44 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.35, 0.35, 0.05 },
				offset = { 0.4, -0.7, -0.45 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
		},
		hipHeight = 2.15,
	},
	Bloater = {
		limbs = {
			HumanoidRootPart = {
				size = { 2, 2, 1 },
				center = { 0, 3.15, 0 },
				transparent = true,
			},
			Torso = {
				size = { 2.9, 2.3, 2.1 },
				center = { 0, 3.3, 0 },
				color = { 120, 126, 96 },
				material = "Fabric",
			},
			Head = {
				size = { 1.1, 1.1, 1.1 },
				center = { 0, 5.02, 0 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
			},
			Jaw = {
				size = { 0.77, 0.26, 0.462 },
				center = { 0, 4.62, -0.396 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
			},
			LeftUpperArm = {
				size = { 1.15, 1.1, 1.15 },
				center = { -2.025, 3.85, 0 },
				color = { 120, 126, 96 },
				material = "Fabric",
			},
			RightUpperArm = {
				size = { 1.15, 1.1, 1.15 },
				center = { 2.025, 3.85, 0 },
				color = { 120, 126, 96 },
				material = "Fabric",
			},
			LeftLowerArm = {
				size = { 1.035, 1.1, 1.035 },
				center = { -2.025, 2.75, 0 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
			},
			RightLowerArm = {
				size = { 1.035, 1.1, 1.035 },
				center = { 2.025, 2.75, 0 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
			},
			LeftUpperLeg = {
				size = { 1.14, 1.1, 1.14 },
				center = { -0.6, 1.6, 0 },
				color = { 44, 44, 48 },
				material = "Fabric",
			},
			RightUpperLeg = {
				size = { 1.14, 1.1, 1.14 },
				center = { 0.6, 1.6, 0 },
				color = { 44, 44, 48 },
				material = "Fabric",
			},
			LeftLowerLeg = {
				size = { 1.08, 1.05, 1.08 },
				center = { -0.6, 0.525, 0 },
				color = { 44, 44, 48 },
				material = "Fabric",
			},
			RightLowerLeg = {
				size = { 1.08, 1.05, 1.08 },
				center = { 0.6, 0.525, 0 },
				color = { 44, 44, 48 },
				material = "Fabric",
			},
		},
		joints = {
			{
				"HumanoidRootPart",
				"Torso",
				{ 0, 3.3, 0 },
			},
			{
				"Torso",
				"Head",
				{ 0, 4.45, 0 },
			},
			{
				"Head",
				"Jaw",
				{ 0, 4.75, -0.132 },
			},
			{
				"Torso",
				"LeftUpperArm",
				{ -2.025, 4.1, 0 },
			},
			{
				"LeftUpperArm",
				"LeftLowerArm",
				{ -2.025, 3.3, 0 },
			},
			{
				"Torso",
				"RightUpperArm",
				{ 2.025, 4.1, 0 },
			},
			{
				"RightUpperArm",
				"RightLowerArm",
				{ 2.025, 3.3, 0 },
			},
			{
				"Torso",
				"LeftUpperLeg",
				{ -0.6, 2.15, 0 },
			},
			{
				"LeftUpperLeg",
				"LeftLowerLeg",
				{ -0.6, 1.05, 0 },
			},
			{
				"Torso",
				"RightUpperLeg",
				{ 0.6, 2.15, 0 },
			},
			{
				"RightUpperLeg",
				"RightLowerLeg",
				{ 0.6, 1.05, 0 },
			},
		},
		details = {
			{
				limb = "Head",
				size = { 0.3, 0.2, 0.06 },
				offset = { -0.2391, 0.1, -0.555 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.15, 0.1, 0.06 },
				offset = { -0.2391, 0.1, -0.57 },
				color = { 210, 255, 90 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.3, 0.2, 0.06 },
				offset = { 0.2391, 0.1, -0.555 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.15, 0.1, 0.06 },
				offset = { 0.2391, 0.1, -0.57 },
				color = { 210, 255, 90 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.62, 0.22, 0.06 },
				offset = { 0, -0.33, -0.555 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { -0.22, -0.25, -0.57 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { -0.11, -0.25, -0.57 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0, -0.25, -0.57 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0.11, -0.25, -0.57 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0.22, -0.25, -0.57 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { -0.17, 0.1, -0.241 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { -0.06, 0.1, -0.241 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { 0.05, 0.1, -0.241 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { 0.16, 0.1, -0.241 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.616, 0.06, 0.05 },
				offset = { 0, -0.1, -0.241 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 1.122, 0.12, 0.77 },
				offset = { 0, 0.58, 0.12 },
				color = { 40, 32, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.3, 0.13, 0.3 },
				offset = { 0.2, 0.61, -0.15 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.2, 0.35, 0.04 },
				offset = { 0.12, -0.5, -0.56 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.35, 0.9, 0.04 },
				offset = { 0.15, 0.65, -1.06 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.22, 0.4, 0.04 },
				offset = { 0.4, 0.05, -1.06 },
				color = { 60, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.373, 0.2263, 0.05 },
				offset = { -0.6024, -0.3601, 1.062 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.1865, 0.1131, 0.05 },
				offset = { -0.6024, -0.3601, 1.08 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3248, 0.4757, 0.05 },
				offset = { 0.5051, -0.6381, -1.062 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.1624, 0.2378, 0.05 },
				offset = { 0.5051, -0.6381, -1.08 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3874, 0.3676, 0.05 },
				offset = { 0.0426, 0.2283, 1.062 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.1937, 0.1838, 0.05 },
				offset = { 0.0426, 0.2283, 1.08 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2626, 0.3063, 0.05 },
				offset = { 0.5401, 0.4393, -1.062 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.1313, 0.1532, 0.05 },
				offset = { 0.5401, 0.4393, -1.08 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.5324, 0.455, 0.05 },
				offset = { -0.3214, 0.6827, 1.062 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2662, 0.2275, 0.05 },
				offset = { -0.3214, 0.6827, 1.08 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.325, 0.5008, 0.05 },
				offset = { 0.6392, -0.7537, -1.062 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3207, 0.3814, 0.08 },
				offset = { 0.627, -1.27, -1.01 },
				color = { 120, 126, 96 },
				material = "Fabric",
				rot = { 0, 0, -10.3611 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.269, 0.3427, 0.08 },
				offset = { -0.0948, -1.27, -1.01 },
				color = { 120, 126, 96 },
				material = "Fabric",
				rot = { 0, 0, -2.6189 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2726, 0.3139, 0.08 },
				offset = { -0.6154, -1.27, -1.01 },
				color = { 120, 126, 96 },
				material = "Fabric",
				rot = { 0, 0, -13.5835 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2006, 0.2089, 0.08 },
				offset = { 0.6474, -1.27, -1.01 },
				color = { 120, 126, 96 },
				material = "Fabric",
				rot = { 0, 0, 5.763 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2674, 0.2699, 0.08 },
				offset = { -0.2485, -1.27, -1.01 },
				color = { 120, 126, 96 },
				material = "Fabric",
				rot = { 0, 0, 14.8445 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.06, 0.8, 0.6 },
				offset = { -1.46, 0.1, -0.05 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -1.48, 0.4, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -1.48, 0.2, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -1.48, 0, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -1.48, -0.2, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftUpperArm",
				size = { 1.196, 0.18, 1.196 },
				offset = { 0, -0.5, 0 },
				color = { 120, 126, 96 },
				material = "Fabric",
				rot = { 0, 0, 8 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.7245, 0.3, 0.05 },
				offset = { 0, 0.1, -0.5275 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { -0.25, -0.67, -0.15 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0, -0.67, -0.15 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0.25, -0.67, -0.15 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.04, 0.05, 0.04 },
				offset = { -0.25, -0.86, -0.15 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightUpperArm",
				size = { 1.196, 0.18, 1.196 },
				offset = { 0, -0.5, 0 },
				color = { 120, 126, 96 },
				material = "Fabric",
				rot = { 0, 0, -8 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.7245, 0.3, 0.05 },
				offset = { 0, 0.1, -0.5275 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { -0.25, -0.67, -0.15 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0, -0.67, -0.15 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0.25, -0.67, -0.15 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.04, 0.05, 0.04 },
				offset = { -0.25, -0.86, -0.15 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerLeg",
				size = { 1.134, 0.32, 1.458 },
				offset = { 0, -0.365, -0.15 },
				color = { 36, 30, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerLeg",
				size = { 0.4, 0.35, 0.05 },
				offset = { 0.1, 0.15, -0.55 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerLeg",
				size = { 1.134, 0.32, 1.458 },
				offset = { 0, -0.365, -0.15 },
				color = { 36, 30, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerLeg",
				size = { 0.4, 0.35, 0.05 },
				offset = { 0.1, 0.15, -0.55 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightUpperLeg",
				size = { 0.5, 0.3, 0.05 },
				offset = { 0, 0.1, -0.49 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3991, 0.3991, 0.3991 },
				offset = { -1.5697, -0.5474, 0.0707 },
				color = { 150, 170, 60 },
				material = "SmoothPlastic",
				rot = { 7.8016, 24.7396, 15.3988 },
				neon = true,
			},
			{
				limb = "Torso",
				size = { 0.2438, 0.2438, 0.2438 },
				offset = { 0.4884, 0.8858, -1.1232 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 1.0721, 10.2856, 14.7246 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3396, 0.3396, 0.3396 },
				offset = { 1.5519, -0.3329, 0.7988 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 22.0491, 28.1225, 33.7646 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.4462, 0.4462, 0.4462 },
				offset = { -0.2916, -0.6195, -1.1839 },
				color = { 150, 170, 60 },
				material = "SmoothPlastic",
				rot = { 15.4523, 35.8328, 19.4217 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.4352, 0.4352, 0.4352 },
				offset = { 1.5806, 0.7578, -0.4566 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 24.2837, 18.199, 4.3505 },
				neon = true,
			},
			{
				limb = "Torso",
				size = { 0.335, 0.335, 0.335 },
				offset = { -1.5505, -0.4862, 0.0384 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 26.639, 19.1437, 24.4687 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.4397, 0.4397, 0.4397 },
				offset = { 1.5819, 0.097, -0.6751 },
				color = { 150, 170, 60 },
				material = "SmoothPlastic",
				rot = { 31.0137, 28.5243, 29.3916 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3717, 0.3717, 0.3717 },
				offset = { -0.3447, -0.7932, -1.1615 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 0.0265, 2.4117, 3.6746 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.542, 0.542, 0.542 },
				offset = { -1.6126, -0.1265, -0.1925 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 37.0503, 16.7232, 36.1889 },
				neon = true,
			},
			{
				limb = "Torso",
				size = { 0.36, 0.36, 0.36 },
				offset = { 1.558, -0.6433, 0.2541 },
				color = { 150, 170, 60 },
				material = "SmoothPlastic",
				rot = { 19.4293, 14.9604, 5.7652 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.4005, 0.4005, 0.4005 },
				offset = { 0.0037, -0.1617, 1.1702 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 25.28, 23.9041, 10.4717 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3929, 0.3929, 0.3929 },
				offset = { 0.3394, 0.3184, 1.1679 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 28.374, 30.7086, 30.0552 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2496, 0.2496, 0.2496 },
				offset = { 0.5351, 0.2271, 1.1249 },
				color = { 150, 170, 60 },
				material = "SmoothPlastic",
				rot = { 22.0928, 12.3067, 27.7269 },
				neon = true,
			},
			{
				limb = "Torso",
				size = { 0.5167, 0.5167, 0.5167 },
				offset = { -0.8898, 0.416, -1.205 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 38.5655, 32.3267, 3.8091 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.5172, 0.5172, 0.5172 },
				offset = { 1.6052, -0.5044, -0.1592 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 11.2376, 39.6731, 5.3809 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2729, 0.2729, 0.2729 },
				offset = { -1.5319, 0.2818, 0.6583 },
				color = { 150, 170, 60 },
				material = "SmoothPlastic",
				rot = { 23.8998, 3.4491, 31.5035 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2233, 0.2233, 0.2233 },
				offset = { 1.2175, 0.0644, -1.117 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 5.6292, 16.6867, 0.7903 },
				neon = true,
			},
			{
				limb = "Torso",
				size = { 0.4135, 0.4135, 0.4135 },
				offset = { -0.8572, -0.5452, -1.1741 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 10.9385, 13.3109, 5.3004 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.4439, 0.4439, 0.4439 },
				offset = { -1.5832, -0.0343, -0.5421 },
				color = { 150, 170, 60 },
				material = "SmoothPlastic",
				rot = { 13.0793, 27.6096, 39.255 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2925, 0.2925, 0.2925 },
				offset = { -1.5377, 0.2809, 0.5518 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 7.7323, 0.8746, 1.082 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.4216, 0.4216, 0.4216 },
				offset = { -1.5765, 0.0254, 0.1687 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 30.5566, 36.4772, 25.2135 },
				neon = true,
			},
			{
				limb = "Torso",
				size = { 0.4588, 0.4588, 0.4588 },
				offset = { 0.6685, 0.3668, 1.1876 },
				color = { 150, 170, 60 },
				material = "SmoothPlastic",
				rot = { 4.7994, 20.3963, 37.8759 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 1.74, 0.12, 0.05 },
				offset = { 0, -0.5, -1.07 },
				color = { 150, 60, 66 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.3, 0.3, 0.3 },
				offset = { 0.4, 0.3, -0.4 },
				color = { 196, 206, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
		},
		hipHeight = 2.15,
	},
	Screamer = {
		limbs = {
			HumanoidRootPart = {
				size = { 2, 2, 1 },
				center = { 0, 3.15, 0 },
				transparent = true,
			},
			Torso = {
				size = { 1.8, 2, 0.85 },
				center = { 0, 3.15, 0 },
				color = { 40, 40, 46 },
				material = "Fabric",
			},
			Head = {
				size = { 1.2, 1.2, 1.2 },
				center = { 0, 4.77, 0 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
			},
			Jaw = {
				size = { 0.84, 0.26, 0.504 },
				center = { 0, 4.32, -0.432 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
			},
			LeftUpperArm = {
				size = { 0.75, 1.595, 0.75 },
				center = { -1.275, 3.3025, 0 },
				color = { 40, 40, 46 },
				material = "Fabric",
			},
			RightUpperArm = {
				size = { 0.75, 1.595, 0.75 },
				center = { 1.275, 3.3025, 0 },
				color = { 40, 40, 46 },
				material = "Fabric",
			},
			LeftLowerArm = {
				size = { 0.675, 1.595, 0.675 },
				center = { -1.275, 1.7075, 0 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
			},
			RightLowerArm = {
				size = { 0.675, 1.595, 0.675 },
				center = { 1.275, 1.7075, 0 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
			},
			LeftUpperLeg = {
				size = { 0.95, 1.1, 0.95 },
				center = { -0.5, 1.6, 0 },
				color = { 44, 44, 48 },
				material = "Fabric",
			},
			RightUpperLeg = {
				size = { 0.95, 1.1, 0.95 },
				center = { 0.5, 1.6, 0 },
				color = { 44, 44, 48 },
				material = "Fabric",
			},
			LeftLowerLeg = {
				size = { 0.9, 1.05, 0.9 },
				center = { -0.5, 0.525, 0 },
				color = { 44, 44, 48 },
				material = "Fabric",
			},
			RightLowerLeg = {
				size = { 0.9, 1.05, 0.9 },
				center = { 0.5, 0.525, 0 },
				color = { 44, 44, 48 },
				material = "Fabric",
			},
		},
		joints = {
			{
				"HumanoidRootPart",
				"Torso",
				{ 0, 3.15, 0 },
			},
			{
				"Torso",
				"Head",
				{ 0, 4.15, 0 },
			},
			{
				"Head",
				"Jaw",
				{ 0, 4.45, -0.144 },
			},
			{
				"Torso",
				"LeftUpperArm",
				{ -1.275, 3.8, 0 },
			},
			{
				"LeftUpperArm",
				"LeftLowerArm",
				{ -1.275, 2.505, 0 },
			},
			{
				"Torso",
				"RightUpperArm",
				{ 1.275, 3.8, 0 },
			},
			{
				"RightUpperArm",
				"RightLowerArm",
				{ 1.275, 2.505, 0 },
			},
			{
				"Torso",
				"LeftUpperLeg",
				{ -0.5, 2.15, 0 },
			},
			{
				"LeftUpperLeg",
				"LeftLowerLeg",
				{ -0.5, 1.05, 0 },
			},
			{
				"Torso",
				"RightUpperLeg",
				{ 0.5, 2.15, 0 },
			},
			{
				"RightUpperLeg",
				"RightLowerLeg",
				{ 0.5, 1.05, 0 },
			},
		},
		details = {
			{
				limb = "Head",
				size = { 0.3, 0.2, 0.06 },
				offset = { -0.2609, 0.1, -0.605 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.15, 0.1, 0.06 },
				offset = { -0.2609, 0.1, -0.62 },
				color = { 255, 255, 255 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.3, 0.2, 0.06 },
				offset = { 0.2609, 0.1, -0.605 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.15, 0.1, 0.06 },
				offset = { 0.2609, 0.1, -0.62 },
				color = { 255, 255, 255 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.62, 0.22, 0.06 },
				offset = { 0, -0.33, -0.605 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { -0.22, -0.25, -0.62 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { -0.11, -0.25, -0.62 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0, -0.25, -0.62 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0.11, -0.25, -0.62 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0.22, -0.25, -0.62 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { -0.17, 0.1, -0.262 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { -0.06, 0.1, -0.262 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { 0.05, 0.1, -0.262 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { 0.16, 0.1, -0.262 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.672, 0.06, 0.05 },
				offset = { 0, -0.1, -0.262 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 1.224, 0.12, 0.84 },
				offset = { 0, 0.63, 0.12 },
				color = { 40, 32, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.3, 0.13, 0.3 },
				offset = { 0.2, 0.66, -0.15 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.2, 0.35, 0.04 },
				offset = { 0.12, -0.5, -0.61 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.35, 0.9, 0.04 },
				offset = { 0.15, 0.5, -0.435 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.22, 0.4, 0.04 },
				offset = { 0.4, -0.1, -0.435 },
				color = { 60, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3351, 0.4985, 0.05 },
				offset = { -0.3773, 0.3249, 0.437 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.1675, 0.2493, 0.05 },
				offset = { -0.3773, 0.3249, 0.455 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.5542, 0.2229, 0.05 },
				offset = { -0.402, -0.6281, -0.437 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.4157, 0.3357, 0.05 },
				offset = { -0.5063, 0.4833, 0.437 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.462, 0.4098, 0.05 },
				offset = { -0.2076, 0.3521, -0.437 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.231, 0.2049, 0.05 },
				offset = { -0.2076, 0.3521, -0.455 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3484, 0.4792, 0.05 },
				offset = { 0.0034, -0.3918, -0.437 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3488, 0.3641, 0.05 },
				offset = { -0.3758, 0.5494, -0.437 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2698, 0.2255, 0.08 },
				offset = { -0.1494, -1.12, -0.385 },
				color = { 40, 40, 46 },
				material = "Fabric",
				rot = { 0, 0, -10.2006 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2013, 0.3959, 0.08 },
				offset = { -0.5878, -1.12, -0.385 },
				color = { 40, 40, 46 },
				material = "Fabric",
				rot = { 0, 0, -6.3546 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2488, 0.2382, 0.08 },
				offset = { -0.5601, -1.12, -0.385 },
				color = { 40, 40, 46 },
				material = "Fabric",
				rot = { 0, 0, -4.2782 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2806, 0.2611, 0.08 },
				offset = { -0.6965, -1.12, -0.385 },
				color = { 40, 40, 46 },
				material = "Fabric",
				rot = { 0, 0, -5.8533 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2868, 0.2994, 0.08 },
				offset = { 0.0946, -1.12, -0.385 },
				color = { 40, 40, 46 },
				material = "Fabric",
				rot = { 0, 0, 4.2796 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.06, 0.8, 0.6 },
				offset = { -0.91, 0.1, -0.05 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -0.93, 0.4, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -0.93, 0.2, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -0.93, 0, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -0.93, -0.2, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftUpperArm",
				size = { 0.78, 0.18, 0.78 },
				offset = { 0, -0.7475, 0 },
				color = { 40, 40, 46 },
				material = "Fabric",
				rot = { 0, 0, 8 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.4725, 0.3, 0.05 },
				offset = { 0, 0.1, -0.3475 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { -0.25, -0.9175, -0.15 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0, -0.9175, -0.15 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0.25, -0.9175, -0.15 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.04, 0.05, 0.04 },
				offset = { -0.25, -1.1075, -0.15 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightUpperArm",
				size = { 0.78, 0.18, 0.78 },
				offset = { 0, -0.7475, 0 },
				color = { 40, 40, 46 },
				material = "Fabric",
				rot = { 0, 0, -8 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.4725, 0.3, 0.05 },
				offset = { 0, 0.1, -0.3475 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { -0.25, -0.9175, -0.15 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0, -0.9175, -0.15 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0.25, -0.9175, -0.15 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.04, 0.05, 0.04 },
				offset = { -0.25, -1.1075, -0.15 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerLeg",
				size = { 0.945, 0.32, 1.215 },
				offset = { 0, -0.365, -0.15 },
				color = { 36, 30, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerLeg",
				size = { 0.4, 0.35, 0.05 },
				offset = { 0.1, 0.15, -0.46 },
				color = { 168, 172, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerLeg",
				size = { 0.945, 0.32, 1.215 },
				offset = { 0, -0.365, -0.15 },
				color = { 36, 30, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.9, 0.55, 0.06 },
				offset = { 0, -0.2, -0.62 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.12, 0.05 },
				offset = { -0.36, 0.03, -0.64 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.12, 0.05 },
				offset = { -0.24, 0.03, -0.64 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.12, 0.05 },
				offset = { -0.12, 0.03, -0.64 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.12, 0.05 },
				offset = { 0, 0.03, -0.64 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.12, 0.05 },
				offset = { 0.12, 0.03, -0.64 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.12, 0.05 },
				offset = { 0.24, 0.03, -0.64 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.12, 0.05 },
				offset = { 0.36, 0.03, -0.64 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.08, 1.224, 1.224 },
				offset = { 0.15, 0.05, 0 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.05, 1.08, 0.05 },
				offset = { 0.15, 0.05, -0.63 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
		},
		hipHeight = 2.15,
	},
	Brute = {
		limbs = {
			HumanoidRootPart = {
				size = { 2, 2, 1 },
				center = { 0, 3.15, 0 },
				transparent = true,
			},
			Torso = {
				size = { 2.6, 2.3, 1.4 },
				center = { 0, 3.3, 0 },
				color = { 70, 58, 48 },
				material = "Fabric",
			},
			Head = {
				size = { 1.15, 1.15, 1.15 },
				center = { 0, 5.045, 0 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
			},
			Jaw = {
				size = { 0.805, 0.26, 0.483 },
				center = { 0, 4.62, -0.414 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
			},
			LeftUpperArm = {
				size = { 1.2, 1.1, 1.2 },
				center = { -1.9, 3.85, 0 },
				color = { 70, 58, 48 },
				material = "Fabric",
			},
			RightUpperArm = {
				size = { 1.2, 1.1, 1.2 },
				center = { 1.9, 3.85, 0 },
				color = { 70, 58, 48 },
				material = "Fabric",
			},
			LeftLowerArm = {
				size = { 1.08, 1.1, 1.08 },
				center = { -1.9, 2.75, 0 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
			},
			RightLowerArm = {
				size = { 1.08, 1.1, 1.08 },
				center = { 1.9, 2.75, 0 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
			},
			LeftUpperLeg = {
				size = { 1.1875, 1.1, 1.1875 },
				center = { -0.625, 1.6, 0 },
				color = { 52, 62, 88 },
				material = "Fabric",
			},
			RightUpperLeg = {
				size = { 1.1875, 1.1, 1.1875 },
				center = { 0.625, 1.6, 0 },
				color = { 52, 62, 88 },
				material = "Fabric",
			},
			LeftLowerLeg = {
				size = { 1.125, 1.05, 1.125 },
				center = { -0.625, 0.525, 0 },
				color = { 52, 62, 88 },
				material = "Fabric",
			},
			RightLowerLeg = {
				size = { 1.125, 1.05, 1.125 },
				center = { 0.625, 0.525, 0 },
				color = { 52, 62, 88 },
				material = "Fabric",
			},
		},
		joints = {
			{
				"HumanoidRootPart",
				"Torso",
				{ 0, 3.3, 0 },
			},
			{
				"Torso",
				"Head",
				{ 0, 4.45, 0 },
			},
			{
				"Head",
				"Jaw",
				{ 0, 4.75, -0.138 },
			},
			{
				"Torso",
				"LeftUpperArm",
				{ -1.9, 4.1, 0 },
			},
			{
				"LeftUpperArm",
				"LeftLowerArm",
				{ -1.9, 3.3, 0 },
			},
			{
				"Torso",
				"RightUpperArm",
				{ 1.9, 4.1, 0 },
			},
			{
				"RightUpperArm",
				"RightLowerArm",
				{ 1.9, 3.3, 0 },
			},
			{
				"Torso",
				"LeftUpperLeg",
				{ -0.625, 2.15, 0 },
			},
			{
				"LeftUpperLeg",
				"LeftLowerLeg",
				{ -0.625, 1.05, 0 },
			},
			{
				"Torso",
				"RightUpperLeg",
				{ 0.625, 2.15, 0 },
			},
			{
				"RightUpperLeg",
				"RightLowerLeg",
				{ 0.625, 1.05, 0 },
			},
		},
		details = {
			{
				limb = "Head",
				size = { 0.3, 0.2, 0.06 },
				offset = { -0.25, 0.1, -0.58 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.15, 0.1, 0.06 },
				offset = { -0.25, 0.1, -0.595 },
				color = { 255, 60, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.3, 0.2, 0.06 },
				offset = { 0.25, 0.1, -0.58 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.15, 0.1, 0.06 },
				offset = { 0.25, 0.1, -0.595 },
				color = { 255, 60, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.62, 0.22, 0.06 },
				offset = { 0, -0.33, -0.58 },
				color = { 30, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { -0.22, -0.25, -0.595 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { -0.11, -0.25, -0.595 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0, -0.25, -0.595 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0.11, -0.25, -0.595 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.07, 0.09, 0.05 },
				offset = { 0.22, -0.25, -0.595 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { -0.17, 0.1, -0.2515 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { -0.06, 0.1, -0.2515 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { 0.05, 0.1, -0.2515 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.08, 0.05 },
				offset = { 0.16, 0.1, -0.2515 },
				color = { 220, 210, 170 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.644, 0.06, 0.05 },
				offset = { 0, -0.1, -0.2515 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 1.173, 0.12, 0.805 },
				offset = { 0, 0.605, 0.12 },
				color = { 40, 32, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.3, 0.13, 0.3 },
				offset = { 0.2, 0.635, -0.15 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.2, 0.35, 0.04 },
				offset = { 0.12, -0.5, -0.585 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.35, 0.9, 0.04 },
				offset = { 0.15, 0.65, -0.71 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.22, 0.4, 0.04 },
				offset = { 0.4, 0.05, -0.71 },
				color = { 60, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.5937, 0.2004, 0.05 },
				offset = { -0.5417, -0.6522, -0.712 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2968, 0.1002, 0.05 },
				offset = { -0.5417, -0.6522, -0.73 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2846, 0.5081, 0.05 },
				offset = { 0.8017, -0.6662, 0.712 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.1423, 0.254, 0.05 },
				offset = { 0.8017, -0.6662, 0.73 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2801, 0.357, 0.05 },
				offset = { -0.9117, 0.3375, -0.712 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.5624, 0.2241, 0.05 },
				offset = { 0.2229, -0.1088, -0.712 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.471, 0.3464, 0.05 },
				offset = { 0.5029, 0.3049, -0.712 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.4496, 0.2219, 0.05 },
				offset = { 0.8945, -0.2919, 0.712 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2248, 0.111, 0.05 },
				offset = { 0.8945, -0.2919, 0.73 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3037, 0.3294, 0.08 },
				offset = { 0.2896, -1.27, -0.66 },
				color = { 70, 58, 48 },
				material = "Fabric",
				rot = { 0, 0, -10.3076 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.1964, 0.4438, 0.08 },
				offset = { 0.3699, -1.27, -0.66 },
				color = { 70, 58, 48 },
				material = "Fabric",
				rot = { 0, 0, 6.1359 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.3147, 0.2886, 0.08 },
				offset = { 0.8122, -1.27, -0.66 },
				color = { 70, 58, 48 },
				material = "Fabric",
				rot = { 0, 0, -0.4818 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2273, 0.2263, 0.08 },
				offset = { -0.7184, -1.27, -0.66 },
				color = { 70, 58, 48 },
				material = "Fabric",
				rot = { 0, 0, 1.8909 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.2239, 0.4464, 0.08 },
				offset = { 0.6371, -1.27, -0.66 },
				color = { 70, 58, 48 },
				material = "Fabric",
				rot = { 0, 0, 11.3228 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.06, 0.8, 0.6 },
				offset = { -1.31, 0.1, -0.05 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -1.33, 0.4, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -1.33, 0.2, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -1.33, 0, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.07, 0.08, 0.5 },
				offset = { -1.33, -0.2, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftUpperArm",
				size = { 1.248, 0.18, 1.248 },
				offset = { 0, -0.5, 0 },
				color = { 70, 58, 48 },
				material = "Fabric",
				rot = { 0, 0, 8 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.756, 0.3, 0.05 },
				offset = { 0, 0.1, -0.55 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { -0.25, -0.67, -0.15 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0, -0.67, -0.15 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0.25, -0.67, -0.15 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerArm",
				size = { 0.04, 0.05, 0.04 },
				offset = { -0.25, -0.86, -0.15 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightUpperArm",
				size = { 1.248, 0.18, 1.248 },
				offset = { 0, -0.5, 0 },
				color = { 70, 58, 48 },
				material = "Fabric",
				rot = { 0, 0, -8 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.756, 0.3, 0.05 },
				offset = { 0, 0.1, -0.55 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { -0.25, -0.67, -0.15 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0, -0.67, -0.15 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.35, 0.16 },
				offset = { 0.25, -0.67, -0.15 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.04, 0.05, 0.04 },
				offset = { -0.25, -0.86, -0.15 },
				color = { 96, 14, 18 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerLeg",
				size = { 1.1813, 0.32, 1.5188 },
				offset = { 0, -0.365, -0.15 },
				color = { 36, 30, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftLowerLeg",
				size = { 0.4, 0.35, 0.05 },
				offset = { 0.1, 0.15, -0.5725 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerLeg",
				size = { 1.1813, 0.32, 1.5188 },
				offset = { 0, -0.365, -0.15 },
				color = { 36, 30, 28 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightUpperArm",
				size = { 1.62, 1.1, 1.62 },
				offset = { 0.12, 0, 0 },
				color = { 92, 104, 60 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 1.944, 1.32, 1.944 },
				offset = { 0.15, -0.15, 0 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.5, 0.16 },
				offset = { 0.35, 0.3, -0.5 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 30, 0, -40 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.5, 0.16 },
				offset = { 0.55, 0.05, -0.25 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 30, 0, -40 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.5, 0.16 },
				offset = { 0.35, -0.2, 0 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 30, 0, -40 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.5, 0.16 },
				offset = { 0.55, -0.45, 0.25 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 30, 0, -40 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 0.16, 0.5, 0.16 },
				offset = { 0.35, -0.7, 0.5 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 30, 0, -40 },
				neon = false,
			},
			{
				limb = "RightLowerArm",
				size = { 1.2, 0.5, 1.2 },
				offset = { 0.15, -0.9, 0 },
				color = { 86, 98, 78 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.25, 0.4, 0.25 },
				offset = { -0.9, 1.2, 0.5 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -30, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.25, 0.4, 0.25 },
				offset = { -0.3, 1.2, 0.5 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -30, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.25, 0.4, 0.25 },
				offset = { 0.3, 1.2, 0.5 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -30, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 0.25, 0.4, 0.25 },
				offset = { 0.9, 1.2, 0.5 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -30, 0, 0 },
				neon = false,
			},
			{
				limb = "Torso",
				size = { 1, 0.8, 0.05 },
				offset = { -0.4, 0.2, -0.72 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
		},
		hipHeight = 2.15,
	},
}
local SOURCES = {
	DragonAnimator = [=======[
--[[
	DragonAnimator (ModuleScript) · ReplicatedStorage.Dragons.DragonAnimator

	Reproduce animaciones definidas como datos sobre un rig de Motor6D (piezas rígidas)
	o de Bones (malla con skinning). No necesita subir assets de animación: escribe
	Motor6D.Transform o Bone.Transform cada frame.

	Uso:
		local animator = DragonAnimator.new(model, require(animsModule))
		animator:Play("Idle")
		animator.Finished.Event:Connect(function(name) ... end)
		animator:SetLookTarget(player.Character.Head)   -- opcional: la cabeza sigue al objetivo
		animator:Destroy()

	Opciones (todas opcionales; sin tocarlas el comportamiento es el de siempre):
		animator.Paused = true          -- congela la pose tal como está (no escribe nada: coste cero)
		animator.UpdateInterval = 1/15  -- evalúa menos veces por segundo (lejos de la cámara)
		animator.Speed = 0.5            -- velocidad de reproducción
		animator:SetHeadTilt(35, 1.5)   -- inclina la cabeza 35° (alabeo) y llega a esa inclinación a ritmo 1.5

	Formato de cada articulación (nombre = Part1 del Motor6D o nombre del Bone):
		k = { {t, rx, ry, rz}, ... }   claves de rotación en grados
		p = { {t, x, y, z}, ... }      claves de traslación en studs del modelo original (se multiplican por RigScale)
		o = { {"eje", amplitud, ciclos, fase}, ... }   ejes "x","y","z" (grados) o "px","py","pz" (studs)
	Los ángulos se expresan en los ejes del modelo (Y arriba, el dragón mira a -Z). Para los Bones,
	el animador los convierte al marco local de cada hueso con su orientación de reposo.
]]

local RunService = game:GetService("RunService")

local DragonAnimator = {}
DragonAnimator.__index = DragonAnimator

local function smooth(x: number): number
	return x * x * (3 - 2 * x)
end

local function sampleKeys(keys, t: number, dur: number, loop: boolean)
	if keys == nil or #keys == 0 then
		return nil
	end
	local first = keys[1]
	if #keys == 1 or t <= first[1] then
		return { first[2], first[3], first[4] }
	end
	for i = 1, #keys - 1 do
		local a, b = keys[i], keys[i + 1]
		if t <= b[1] then
			local f = smooth((t - a[1]) / math.max(b[1] - a[1], 1e-6))
			return { a[2] + (b[2] - a[2]) * f, a[3] + (b[3] - a[3]) * f, a[4] + (b[4] - a[4]) * f }
		end
	end
	local last = keys[#keys]
	if loop then
		local f = smooth((t - last[1]) / math.max(dur - last[1], 1e-6))
		return { last[2] + (first[2] - last[2]) * f, last[3] + (first[3] - last[3]) * f, last[4] + (first[4] - last[4]) * f }
	end
	return { last[2], last[3], last[4] }
end

-- Devuelve rx, ry, rz (grados) y px, py, pz (studs) de una articulación en el instante t.
function DragonAnimator.EvalJoint(joint, t: number, dur: number, loop: boolean)
	local r = sampleKeys(joint.k, t, dur, loop) or { 0, 0, 0 }
	local p = sampleKeys(joint.p, t, dur, loop) or { 0, 0, 0 }
	if joint.o then
		for _, osc in ipairs(joint.o) do
			local axis, amp, cycles, phase = osc[1], osc[2], osc[3], osc[4]
			local v = amp * math.sin(2 * math.pi * (cycles * t / dur + phase))
			if axis == "x" then
				r[1] += v
			elseif axis == "y" then
				r[2] += v
			elseif axis == "z" then
				r[3] += v
			elseif axis == "px" then
				p[1] += v
			elseif axis == "py" then
				p[2] += v
			elseif axis == "pz" then
				p[3] += v
			end
		end
	end
	return r, p
end

function DragonAnimator.new(model: Model, animations)
	local self = setmetatable({}, DragonAnimator)
	self.Model = model
	self.Animations = animations
	self.Scale = model:GetAttribute("RigScale") or 1
	self.Joints = {}
	local pivot = model:GetPivot()
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") and d.Part1 then
			self.Joints[d.Part1.Name] = { inst = d, kind = "motor" }
		elseif d:IsA("Bone") then
			d.Transform = CFrame.identity
			-- orientación de reposo del hueso en los ejes del modelo
			local rest = (pivot:Inverse() * d.WorldCFrame).Rotation
			local entry = { inst = d, rest = rest, restInv = rest:Inverse() }
			local j = self.Joints[d.Name]
			if j and j.kind == "bone" then
				table.insert(j.copies, entry) -- el importador puede duplicar el esqueleto por malla
			else
				self.Joints[d.Name] = { inst = d, kind = "bone", rest = rest, restInv = entry.restInv, copies = { entry } }
			end
		end
	end
	self.Values = {} -- último valor aplicado por articulación: {rx, ry, rz, px, py, pz}
	self.From = {}
	self.Current = nil
	self.Time = 0
	self.FadeTime = 0.25
	self.FadeElapsed = 0
	self.Speed = 1
	self.Finished = Instance.new("BindableEvent")
	self.Paused = false
	self.UpdateInterval = 0
	self._acc = 0
	self._conn = RunService.Stepped:Connect(function(_, dt)
		if self.Paused then
			return
		end
		local iv = self.UpdateInterval
		if iv and iv > 0 then
			self._acc += dt
			if self._acc < iv then
				return
			end
			dt, self._acc = self._acc, 0
		end
		self:Step(dt)
	end)
	return self
end

-- Escribe en la articulación una transformación expresada en los ejes del modelo.
local function setJoint(j, m: CFrame)
	if j.kind == "bone" then
		for _, c in ipairs(j.copies) do
			c.inst.Transform = c.restInv * m * c.rest
		end
	else
		j.inst.Transform = m
	end
end

function DragonAnimator:Play(name: string, fadeTime: number?)
	local anim = self.Animations[name]
	assert(anim, "Animación desconocida: " .. tostring(name))
	self.From = {}
	for jointName, v in pairs(self.Values) do
		self.From[jointName] = table.clone(v)
	end
	self.Current = name
	self.Time = 0
	self.FadeTime = fadeTime or 0.25
	self.FadeElapsed = 0
	self._done = false
end

function DragonAnimator:Step(dt: number)
	local name = self.Current
	if not name then
		return
	end
	local anim = self.Animations[name]
	self.Time += dt * self.Speed
	self.FadeElapsed += dt
	if not anim.loop and self.Time >= anim.dur then
		if anim.next then
			self:Play(anim.next, 0.2)
			self.Finished:Fire(name)
			return self:Step(0)
		end
		self.Time = anim.dur
		if not self._done then
			self._done = true
			task.defer(function()
				self.Finished:Fire(name)
			end)
		end
	end
	local t = anim.loop and (self.Time % anim.dur) or self.Time
	local w = self.FadeTime > 0 and smooth(math.clamp(self.FadeElapsed / self.FadeTime, 0, 1)) or 1
	local s = self.Scale
	local frames = {}
	for jointName in pairs(self.Joints) do
		local j = anim.joints[jointName]
		local v
		if j then
			local r, p = DragonAnimator.EvalJoint(j, t, anim.dur, anim.loop)
			v = { r[1], r[2], r[3], p[1], p[2], p[3] }
		else
			v = { 0, 0, 0, 0, 0, 0 }
		end
		local from = self.From[jointName]
		if from and w < 1 then
			for i = 1, 6 do
				v[i] = from[i] + (v[i] - from[i]) * w
			end
		end
		self.Values[jointName] = v
		frames[jointName] = CFrame.new(v[4] * s, v[5] * s, v[6] * s)
			* CFrame.Angles(math.rad(v[1]), math.rad(v[2]), math.rad(v[3]))
	end
	self:_applyLook(dt, frames)
	self:_applyTilt(dt, frames)
	for jointName, m in pairs(frames) do
		setJoint(self.Joints[jointName], m)
	end
end

local function resolveTarget(target): Vector3?
	if typeof(target) == "Vector3" then
		return target
	elseif typeof(target) == "Instance" then
		if target:IsA("BasePart") then
			return target.Position
		elseif target:IsA("Model") then
			return target:GetPivot().Position
		end
	elseif type(target) == "function" then
		return target()
	end
	return nil
end

--[[
	Seguimiento de mirada: la cabeza (y una parte del cuello) gira hacia el objetivo,
	sumado encima de la animación. target: BasePart, Model, Vector3, función que devuelve
	Vector3, o nil para soltarlo.
	options: Head ("Head"), Neck ("Neck2"), NeckShare (0.35), MaxYaw (75), MaxPitch (35),
	         RestPitch (grados que apunta el hocico en reposo; negativo = hacia abajo), Speed (5)
]]
function DragonAnimator:SetLookTarget(target, options)
	self.LookTarget = target
	if options then
		self.LookOptions = options
	end
	self.LookOptions = self.LookOptions or {}
	self.LookYaw = self.LookYaw or 0
	self.LookPitch = self.LookPitch or 0
end

-- Marco (en ejes del modelo) del pivote de una articulación, sin su propia transformación.
local function baseFrame(j): CFrame?
	if j.kind == "bone" then
		local b = j.inst
		local parent = b.Parent
		local pcf = parent:IsA("Bone") and parent.TransformedWorldCFrame or (parent:IsA("BasePart") and parent.CFrame)
		if not pcf then
			return nil
		end
		return pcf * b.CFrame * j.restInv
	end
	local m = j.inst
	if not m.Part0 then
		return nil
	end
	return m.Part0.CFrame * m.C0
end

local function pivotPosition(j): Vector3?
	if j.kind == "bone" then
		return j.inst.TransformedWorldCFrame.Position
	end
	local m = j.inst
	return m.Part0 and (m.Part0.CFrame * m.C0).Position or nil
end

function DragonAnimator:_applyLook(dt: number, frames)
	if self.LookYaw == nil then
		return
	end
	local o = self.LookOptions or {}
	local headName, neckName = o.Head or "Head", o.Neck or "Neck2"
	local head, neck = self.Joints[headName], self.Joints[neckName]
	if not head or not neck then
		return
	end
	local goalYaw, goalPitch = 0, 0
	local pos = resolveTarget(self.LookTarget)
	local base = baseFrame(neck)
	local headPivot = pivotPosition(head)
	if pos and base and headPivot then
		local p = base:VectorToObjectSpace(pos - headPivot)
		local maxYaw, maxPitch = math.rad(o.MaxYaw or 75), math.rad(o.MaxPitch or 35)
		goalYaw = math.clamp(math.atan2(-p.X, -p.Z), -maxYaw, maxYaw)
		goalPitch = math.clamp(math.atan2(p.Y, math.sqrt(p.X * p.X + p.Z * p.Z)) - math.rad(o.RestPitch or 0), -maxPitch, maxPitch)
	end
	local k = math.min(1, dt * (o.Speed or 5))
	self.LookYaw += (goalYaw - self.LookYaw) * k
	self.LookPitch += (goalPitch - self.LookPitch) * k
	local share = o.NeckShare or 0.35
	frames[neckName] = CFrame.Angles(0, self.LookYaw * share, 0) * CFrame.Angles(self.LookPitch * share, 0, 0) * (frames[neckName] or CFrame.identity)
	frames[headName] = CFrame.Angles(0, self.LookYaw * (1 - share), 0) * CFrame.Angles(self.LookPitch * (1 - share), 0, 0) * (frames[headName] or CFrame.identity)
end

--[[
	Inclinación de cabeza (alabeo alrededor del eje del hocico), sumada encima de la animación y
	de la mirada. degrees = 0 la endereza; speed controla lo rápido que llega (por defecto 2).
]]
function DragonAnimator:SetHeadTilt(degrees: number, speed: number?, headName: string?)
	self.TiltGoal = degrees
	self.TiltSpeed = speed or 2
	self.TiltHead = headName or self.TiltHead or "Head"
	self.Tilt = self.Tilt or 0
end

function DragonAnimator:_applyTilt(dt: number, frames)
	if self.TiltGoal == nil then
		return
	end
	self.Tilt += (self.TiltGoal - self.Tilt) * math.min(1, dt * self.TiltSpeed)
	local h = self.TiltHead
	if self.Joints[h] then
		frames[h] = CFrame.Angles(0, 0, math.rad(self.Tilt)) * (frames[h] or CFrame.identity)
	end
end

function DragonAnimator:Destroy()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
	for _, j in pairs(self.Joints) do
		for _, c in ipairs(j.copies or { j }) do
			c.inst.Transform = CFrame.identity
		end
	end
	self.Finished:Destroy()
end

return DragonAnimator
]=======],
	Animations = [=======[
--[[
	Animaciones de los infectados (ModuleScript) · ReplicatedStorage.Creatures.Infected.Animations
	Generado desde src/infected_anims.js con tools/build_roblox.js: edita la fuente y regenera.
]]
return {
	Idle = {
		dur = 4.5,
		loop = true,
		joints = {
			Torso = {
				k = {
					{ 0, -8, 0, 0 },
				},
				o = {
					{ "z", 3, 1, 0 },
					{ "x", 1.5, 2, 0.2 },
				},
			},
			Head = {
				k = {
					{ 0, -6, 0, 14 },
					{ 1.8, -6, 0, 14 },
					{ 1.9, -10, 10, -12 },
					{ 3.2, -10, 10, -12 },
					{ 3.35, -6, 0, 14 },
				},
				o = {
					{ "z", 2, 7, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -14, 0, 0 },
				},
				o = {
					{ "x", 4, 3, 0 },
				},
			},
			LeftUpperArm = {
				k = {
					{ 0, 6, 0, -3 },
				},
				o = {
					{ "x", 4, 1, 0.1 },
				},
			},
			RightUpperArm = {
				k = {
					{ 0, 4, 0, 5 },
				},
				o = {
					{ "x", 5, 1, 0.6 },
				},
			},
			LeftLowerArm = {
				k = {
					{ 0, 10, 0, 0 },
				},
			},
			RightLowerArm = {
				k = {
					{ 0, 6, 0, 0 },
				},
			},
			RightUpperLeg = {
				k = {
					{ 0, -3, 0, 4 },
				},
			},
			RightLowerLeg = {
				k = {
					{ 0, -6, 0, 0 },
				},
			},
		},
	},
	Walk = {
		dur = 1.9,
		loop = true,
		joints = {
			LeftUpperArm = {
				k = {
					{ 0, 78, 0, -4 },
				},
				o = {
					{ "x", 8, 1, 0 },
				},
			},
			RightUpperArm = {
				k = {
					{ 0, 68, 0, 6 },
				},
				o = {
					{ "x", 8, 1, 0.5 },
				},
			},
			LeftLowerArm = {
				k = {
					{ 0, 12, 0, 0 },
				},
				o = {
					{ "x", 4.8, 1, 0.2 },
				},
			},
			RightLowerArm = {
				k = {
					{ 0, 18, 0, 0 },
				},
				o = {
					{ "x", 4.8, 1, 0.7 },
				},
			},
			Torso = {
				k = {
					{ 0, -14, 0, 0 },
				},
				p = {
					{ 0, 0, 0, 0 },
				},
				o = {
					{ "z", 6, 1, 0 },
					{ "y", 6, 1, 0.25 },
					{ "py", 0.07, 2, 0 },
				},
			},
			Head = {
				k = {
					{ 0, -8, 0, 16 },
				},
				o = {
					{ "z", 5, 1, 0.5 },
					{ "x", 3, 2, 0.3 },
				},
			},
			Jaw = {
				k = {
					{ 0, -18, 0, 0 },
				},
				o = {
					{ "x", 5, 2, 0 },
				},
			},
			LeftUpperLeg = {
				o = {
					{ "x", 24, 1, 0 },
				},
			},
			LeftLowerLeg = {
				k = {
					{ 0, -14, 0, 0 },
				},
				o = {
					{ "x", 14, 1, 0.75 },
				},
			},
			RightUpperLeg = {
				k = {
					{ 0, -4, 0, 4 },
				},
				o = {
					{ "x", 13, 1, 0.5 },
				},
			},
			RightLowerLeg = {
				k = {
					{ 0, -6, 0, 0 },
				},
				o = {
					{ "x", 5, 1, 0.25 },
				},
			},
		},
	},
	Run = {
		dur = 0.56,
		loop = true,
		joints = {
			Torso = {
				k = {
					{ 0, -30, 0, 0 },
				},
				o = {
					{ "py", 0.18, 2, 0 },
					{ "y", 8, 1, 0 },
					{ "z", 4, 1, 0.3 },
				},
			},
			Head = {
				k = {
					{ 0, 18, 0, 10 },
				},
				o = {
					{ "z", 8, 2, 0.4 },
				},
			},
			Jaw = {
				k = {
					{ 0, -32, 0, 0 },
				},
				o = {
					{ "x", 8, 2, 0 },
				},
			},
			LeftUpperArm = {
				k = {
					{ 0, 10, 0, -20 },
				},
				o = {
					{ "x", 60, 1, 0.5 },
				},
			},
			RightUpperArm = {
				k = {
					{ 0, 10, 0, 20 },
				},
				o = {
					{ "x", 60, 1, 0 },
				},
			},
			LeftLowerArm = {
				k = {
					{ 0, 35, 0, 0 },
				},
				o = {
					{ "x", 20, 1, 0.7 },
				},
			},
			RightLowerArm = {
				k = {
					{ 0, 35, 0, 0 },
				},
				o = {
					{ "x", 20, 1, 0.2 },
				},
			},
			LeftUpperLeg = {
				k = {
					{ 0, 10, 0, 0 },
				},
				o = {
					{ "x", 48, 1, 0 },
				},
			},
			RightUpperLeg = {
				k = {
					{ 0, 10, 0, 0 },
				},
				o = {
					{ "x", 48, 1, 0.5 },
				},
			},
			LeftLowerLeg = {
				k = {
					{ 0, -40, 0, 0 },
				},
				o = {
					{ "x", 35, 1, 0.75 },
				},
			},
			RightLowerLeg = {
				k = {
					{ 0, -40, 0, 0 },
				},
				o = {
					{ "x", 35, 1, 0.25 },
				},
			},
		},
	},
	Attack = {
		dur = 0.75,
		loop = false,
		next = "Walk",
		joints = {
			Torso = {
				k = {
					{ 0, -14, 0, 0 },
					{ 0.25, 4, 0, 0 },
					{ 0.45, -32, 0, 0 },
					{ 0.75, -14, 0, 0 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 0.45, 0, -0.15, -0.4 },
					{ 0.75, 0, 0, 0 },
				},
			},
			LeftUpperArm = {
				k = {
					{ 0, 78, 0, -4 },
					{ 0.25, 155, 0, -12 },
					{ 0.45, 40, 0, 8 },
					{ 0.75, 78, 0, -4 },
				},
			},
			RightUpperArm = {
				k = {
					{ 0, 68, 0, 6 },
					{ 0.25, 150, 0, 14 },
					{ 0.45, 35, 0, -8 },
					{ 0.75, 68, 0, 6 },
				},
			},
			LeftLowerArm = {
				k = {
					{ 0, 12, 0, 0 },
					{ 0.25, 30, 0, 0 },
					{ 0.45, 5, 0, 0 },
					{ 0.75, 12, 0, 0 },
				},
			},
			RightLowerArm = {
				k = {
					{ 0, 18, 0, 0 },
					{ 0.25, 30, 0, 0 },
					{ 0.45, 5, 0, 0 },
					{ 0.75, 18, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, -8, 0, 16 },
					{ 0.3, 10, 0, 0 },
					{ 0.5, -15, 0, 5 },
					{ 0.75, -8, 0, 16 },
				},
			},
			Jaw = {
				k = {
					{ 0, -18, 0, 0 },
					{ 0.3, -50, 0, 0 },
					{ 0.48, 0, 0, 0 },
					{ 0.75, -18, 0, 0 },
				},
			},
			LeftUpperLeg = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, 25, 0, 0 },
					{ 0.75, 0, 0, 0 },
				},
			},
			LeftLowerLeg = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.45, -20, 0, 0 },
					{ 0.75, 0, 0, 0 },
				},
			},
		},
	},
	Scream = {
		dur = 2.3,
		loop = false,
		next = "Run",
		joints = {
			Torso = {
				k = {
					{ 0, -8, 0, 0 },
					{ 0.35, 12, 0, 0 },
					{ 1.9, 12, 0, 0 },
					{ 2.3, -14, 0, 0 },
				},
				o = {
					{ "z", 1.5, 40, 0 },
				},
			},
			Head = {
				k = {
					{ 0, -6, 0, 0 },
					{ 0.35, 38, 0, 0 },
					{ 1.9, 36, 0, 0 },
					{ 2.3, -6, 0, 10 },
				},
				o = {
					{ "z", 3, 34, 0 },
					{ "y", 2, 27, 0.2 },
				},
			},
			Jaw = {
				k = {
					{ 0, -14, 0, 0 },
					{ 0.3, -75, 0, 0 },
					{ 1.9, -72, 0, 0 },
					{ 2.3, -20, 0, 0 },
				},
				o = {
					{ "x", 4, 38, 0 },
				},
			},
			LeftUpperArm = {
				k = {
					{ 0, 6, 0, -3 },
					{ 0.4, 20, 0, -75 },
					{ 1.9, 20, 0, -78 },
					{ 2.3, 70, 0, -4 },
				},
				o = {
					{ "z", 3, 30, 0 },
				},
			},
			RightUpperArm = {
				k = {
					{ 0, 4, 0, 5 },
					{ 0.4, 20, 0, 75 },
					{ 1.9, 20, 0, 78 },
					{ 2.3, 70, 0, 6 },
				},
				o = {
					{ "z", -3, 30, 0.5 },
				},
			},
			LeftLowerArm = {
				k = {
					{ 0, 10, 0, 0 },
					{ 0.4, 25, 0, -20 },
					{ 2.3, 12, 0, 0 },
				},
			},
			RightLowerArm = {
				k = {
					{ 0, 6, 0, 0 },
					{ 0.4, 25, 0, 20 },
					{ 2.3, 18, 0, 0 },
				},
			},
		},
	},
	Slam = {
		dur = 1.35,
		loop = false,
		next = "Walk",
		joints = {
			Torso = {
				k = {
					{ 0, -14, 0, 0 },
					{ 0.5, 12, 0, -8 },
					{ 0.72, -38, 0, 6 },
					{ 1, -38, 0, 6 },
					{ 1.35, -14, 0, 0 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 0.72, 0, -0.5, -0.3 },
					{ 1, 0, -0.5, -0.3 },
					{ 1.35, 0, 0, 0 },
				},
			},
			RightUpperArm = {
				k = {
					{ 0, 68, 0, 6 },
					{ 0.5, 175, 0, 10 },
					{ 0.72, 25, 0, 0 },
					{ 1, 25, 0, 0 },
					{ 1.35, 68, 0, 6 },
				},
			},
			RightLowerArm = {
				k = {
					{ 0, 18, 0, 0 },
					{ 0.5, 40, 0, 0 },
					{ 0.72, 0, 0, 0 },
					{ 1.35, 18, 0, 0 },
				},
			},
			LeftUpperArm = {
				k = {
					{ 0, 78, 0, -4 },
					{ 0.5, 30, 0, -30 },
					{ 0.72, 60, 0, -10 },
					{ 1.35, 78, 0, -4 },
				},
			},
			Head = {
				k = {
					{ 0, -8, 0, 16 },
					{ 0.5, 20, 0, 0 },
					{ 0.72, -10, 0, 0 },
					{ 1.35, -8, 0, 16 },
				},
			},
			Jaw = {
				k = {
					{ 0, -18, 0, 0 },
					{ 0.55, -60, 0, 0 },
					{ 1, -40, 0, 0 },
					{ 1.35, -18, 0, 0 },
				},
			},
			LeftUpperLeg = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.72, 30, 0, 0 },
					{ 1, 30, 0, 0 },
					{ 1.35, 0, 0, 0 },
				},
			},
			LeftLowerLeg = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.72, -45, 0, 0 },
					{ 1, -45, 0, 0 },
					{ 1.35, 0, 0, 0 },
				},
			},
			RightUpperLeg = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.72, -20, 0, 0 },
					{ 1.35, 0, 0, 0 },
				},
			},
		},
	},
	Hurt = {
		dur = 0.4,
		loop = false,
		next = "Walk",
		joints = {
			Torso = {
				k = {
					{ 0, -14, 0, 0 },
					{ 0.1, 10, 0, 8 },
					{ 0.4, -14, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, -8, 0, 16 },
					{ 0.1, 20, 15, -20 },
					{ 0.4, -8, 0, 16 },
				},
			},
			Jaw = {
				k = {
					{ 0, -18, 0, 0 },
					{ 0.1, -40, 0, 0 },
					{ 0.4, -18, 0, 0 },
				},
			},
			LeftUpperArm = {
				k = {
					{ 0, 78, 0, -4 },
					{ 0.1, 40, 0, -30 },
					{ 0.4, 78, 0, -4 },
				},
			},
			RightUpperArm = {
				k = {
					{ 0, 68, 0, 6 },
					{ 0.1, 40, 0, 30 },
					{ 0.4, 68, 0, 6 },
				},
			},
		},
	},
	Death = {
		dur = 1.6,
		loop = false,
		joints = {
			Torso = {
				k = {
					{ 0, -14, 0, 0 },
					{ 0.3, 8, 0, 10 },
					{ 1.1, -84, 0, 6 },
					{ 1.6, -88, 0, 4 },
				},
				p = {
					{ 0, 0, 0, 0 },
					{ 0.3, 0, 0.1, 0.1 },
					{ 1.1, 0, -2.45, -0.9 },
					{ 1.6, 0, -2.55, -1 },
				},
			},
			Head = {
				k = {
					{ 0, -8, 0, 16 },
					{ 1.1, 20, 30, 0 },
					{ 1.6, 25, 40, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -18, 0, 0 },
					{ 1.6, -40, 0, 0 },
				},
			},
			LeftUpperArm = {
				k = {
					{ 0, 78, 0, -4 },
					{ 1.1, 160, 0, -40 },
					{ 1.6, 170, 0, -45 },
				},
			},
			RightUpperArm = {
				k = {
					{ 0, 68, 0, 6 },
					{ 1.1, 120, 0, 50 },
					{ 1.6, 125, 0, 55 },
				},
			},
			LeftUpperLeg = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.1, 75, 0, -5 },
					{ 1.6, 82, 0, -5 },
				},
			},
			RightUpperLeg = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.1, 70, 0, 8 },
					{ 1.6, 80, 0, 8 },
				},
			},
			LeftLowerLeg = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.6, -20, 0, 0 },
				},
			},
			RightLowerLeg = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.6, -35, 0, 0 },
				},
			},
		},
	},
}
]=======],
	Brain = [=======[
--[[
	InfectedBrain (ModuleScript) · ReplicatedStorage.Creatures.Infected.InfectedBrain

	Lógica pura de un infectado (sin Instances: se prueba fuera de Roblox). El servidor (InfectedSpawner) le pasa lo
	que percibe y aplica las órdenes que devuelve.

	Estados: Idle · Wander · Chase · Attack · Scream · Hurt · Dead
	  · te detecta si te ve a su distancia de detección, o si un gritón ha gritado cerca (alerted)
	  · el gritón, al verte, grita primero (con recarga) y alerta a todos los infectados del radio
	  · ataca al llegar a su alcance, con su tiempo de recarga; el bruto usa el golpe al suelo (Slam)
	  · si te pierde de vista un rato y estás lejos, vuelve a vagar

	Percepción (P): dist, hasTarget, canSee, alerted, health (0-1), hurt, dead
	Órdenes: {"anim", nombre, fundido} · {"move", modo, velocidad} con modo "wander" | "chase" | "stop"
	         {"attack", tipo, retardo} · {"scream"} · {"sound", nombre}
]]

local Brain = {}
Brain.__index = Brain

Brain.Defaults = {
	Detect = 55,
	Reach = 4,
	Cooldown = 1.4,
	WalkSpeed = 5,
	ChaseSpeed = 9,
	ChaseAnim = "Walk",     -- el corredor y el gritón usan "Run"
	AttackAnim = "Attack",  -- el bruto usa "Slam"
	CanScream = false,
	ScreamCooldown = 25,
	LoseTime = 8,
}

function Brain.new(config, rng)
	local self = setmetatable({}, Brain)
	self.cfg = setmetatable(config or {}, { __index = Brain.Defaults })
	self.rng = rng or Random.new()
	self.t = 0
	self.nextAttack = 0
	self.nextScream = 0
	self.lost = 0
	self.out = {}
	self:enter("Idle", self:range({ 1, 4 }))
	return self
end

function Brain:range(r)
	return r[1] + (r[2] - r[1]) * self.rng:NextNumber()
end

function Brain:emit(...)
	table.insert(self.out, { ... })
end

function Brain:enter(state, timer)
	self.state = state
	self.timer = timer or 0
	self.stateTime = 0
end

function Brain:chase()
	local c = self.cfg
	self:emit("anim", c.ChaseAnim, 0.25)
	self:emit("move", "chase", c.ChaseSpeed)
	self:enter("Chase", 0)
end

function Brain:Update(dt, P)
	self.out = {}
	local c = self.cfg
	self.t += dt
	self.timer -= dt
	self.stateTime += dt
	local s = self.state
	if s == "Dead" then
		return self.out
	end
	if P.dead then
		self:emit("move", "stop", 0)
		self:emit("anim", "Death", 0.1)
		self:enter("Dead", 0)
		return self.out
	end
	if P.hurt and s ~= "Attack" and s ~= "Scream" then
		self:emit("anim", "Hurt", 0.05)
		self:emit("move", "stop", 0)
		self:enter("Hurt", 0.4)
		return self.out
	end
	local sees = P.hasTarget and P.canSee and P.dist <= c.Detect
	if s == "Idle" or s == "Wander" then
		if sees and c.CanScream and self.t >= self.nextScream then
			self.nextScream = self.t + c.ScreamCooldown
			self:emit("anim", "Scream", 0.2)
			self:emit("move", "stop", 0)
			self:emit("scream")
			self:emit("sound", "Scream")
			self:enter("Scream", 2.3)
		elseif sees or (P.alerted and P.hasTarget) then
			self:emit("sound", "Groan")
			self:chase()
		elseif self.timer <= 0 then
			if s == "Idle" then
				self:emit("anim", "Walk", 0.4)
				self:emit("move", "wander", c.WalkSpeed)
				self:enter("Wander", self:range({ 4, 9 }))
			else
				self:emit("anim", "Idle", 0.4)
				self:emit("move", "stop", 0)
				self:enter("Idle", self:range({ 2, 6 }))
				if self.rng:NextNumber() < 0.4 then
					self:emit("sound", "Groan")
				end
			end
		end
	elseif s == "Scream" then
		if self.timer <= 0 then
			self:chase()
		end
	elseif s == "Chase" then
		if not P.hasTarget then
			self:emit("anim", "Idle", 0.4)
			self:emit("move", "stop", 0)
			self:enter("Idle", 2)
			return self.out
		end
		self.lost = (P.canSee or P.alerted) and 0 or (self.lost + dt)
		if self.lost > c.LoseTime and P.dist > c.Detect then
			self.lost = 0
			self:emit("anim", "Walk", 0.4)
			self:emit("move", "wander", c.WalkSpeed)
			self:enter("Wander", self:range({ 4, 9 }))
		elseif P.dist <= c.Reach and self.t >= self.nextAttack then
			self.nextAttack = self.t + c.Cooldown
			local slam = c.AttackAnim == "Slam"
			self:emit("anim", c.AttackAnim, 0.1)
			self:emit("move", "stop", 0)
			self:emit("attack", slam and "slam" or "hit", slam and 0.72 or 0.45)
			if slam then
				self:emit("sound", "Roar")
			end
			self:enter("Attack", slam and 1.35 or 0.75)
		elseif self.rng:NextNumber() < dt * 0.05 then
			self:emit("sound", "Groan")
		end
	elseif s == "Attack" or s == "Hurt" then
		if self.timer <= 0 then
			if P.hasTarget then
				self:chase()
			else
				self:emit("anim", "Idle", 0.3)
				self:enter("Idle", 2)
			end
		end
	end
	return self.out
end

return Brain
]=======],
	Spawner = [=======[
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
]=======],
	Client = [=======[
--[[
	InfectedClient (LocalScript) · StarterPlayer.StarterPlayerScripts.InfectedClient

	Anima a los infectados en cada jugador: lee el atributo Anim que publica el servidor y mueve sus Motor6D con
	DragonAnimator (Roblox no replica Motor6D.Transform desde el servidor). Los cuerpos los mueve la física del
	servidor; aquí solo se anima. Rendimiento: lejos se anima menos veces por segundo y muy lejos se pausa.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DragonAnimator = require(ReplicatedStorage:WaitForChild("Dragons"):WaitForChild("DragonAnimator"))
local animations = require(ReplicatedStorage:WaitForChild("Creatures"):WaitForChild("Infected"):WaitForChild("Animations"))
local container = workspace:WaitForChild("Infected")
local entries = {}

local function setup(model)
	if entries[model] or not model:IsA("Model") then
		return
	end
	local e = { model = model }
	e.animator = DragonAnimator.new(model, animations)
	e.animator:Play(model:GetAttribute("Anim") or "Idle", 0)
	model:GetAttributeChangedSignal("AnimStamp"):Connect(function()
		e.animator:Play(model:GetAttribute("Anim"), model:GetAttribute("AnimFade") or 0.3)
	end)
	entries[model] = e
	model.Destroying:Connect(function()
		e.animator:Destroy()
		entries[model] = nil
	end)
end

for _, m in ipairs(container:GetChildren()) do
	task.spawn(setup, m)
end
container.ChildAdded:Connect(function(m)
	m:WaitForChild("HumanoidRootPart", 5)
	setup(m)
end)

RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or Vector3.zero
	for model, e in pairs(entries) do
		local root = model.PrimaryPart
		if root then
			local d = (root.Position - camPos).Magnitude
			e.animator.Paused = d > 400
			e.animator.UpdateInterval = d < 60 and 0 or (d < 160 and 1 / 20 or 1 / 8)
		end
	end
end)
]=======],
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar los infectados")
end)

local function v3(t)
	return Vector3.new(t[1], t[2], t[3])
end
local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end

-- construye un infectado a partir de su plano
local function build(name, bp)
	local model = Instance.new("Model")
	model.Name = name
	local parts = {}
	for limb, L in pairs(bp.limbs) do
		local p = Instance.new("Part")
		p.Name = limb
		p.Size = v3(L.size)
		p.CFrame = CFrame.new(v3(L.center))
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if L.transparent then
			p.Transparency = 1
			p.CanCollide = true
		else
			p.Color = rgb(L.color)
			p.Material = Enum.Material[L.material] or Enum.Material.SmoothPlastic
			p.CanCollide = false
			p.Massless = true
		end
		p.CanTouch = false
		p.Parent = model
		parts[limb] = p
	end
	model.PrimaryPart = parts.HumanoidRootPart
	-- articulaciones: Motor6D en el pivote, sin rotación (las animaciones giran en los ejes del modelo)
	for _, j in ipairs(bp.joints) do
		local p0, p1, piv = parts[j[1]], parts[j[2]], CFrame.new(v3(j[3]))
		local m = Instance.new("Motor6D")
		m.Name = j[2]
		m.Part0, m.Part1 = p0, p1
		m.C0 = p0.CFrame:Inverse() * piv
		m.C1 = p1.CFrame:Inverse() * piv
		m.Parent = p0
	end
	-- detalles: bloques soldados a su pieza
	for _, d in ipairs(bp.details) do
		local limb = parts[d.limb]
		local p = Instance.new("Part")
		p.Name = d.neon and "Glow" or "Detail"
		p.Size = v3(d.size)
		p.CFrame = CFrame.new(limb.Position + v3(d.offset)) * CFrame.Angles(math.rad(d.rot[1]), math.rad(d.rot[2]), math.rad(d.rot[3]))
		p.Color = rgb(d.color)
		p.Material = d.neon and Enum.Material.Neon or (Enum.Material[d.material] or Enum.Material.SmoothPlastic)
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CanCollide, p.CanTouch, p.Massless = false, false, true
		p.CastShadow = not d.neon
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = limb, p
		w.Parent = p
		p.Parent = limb
	end
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = bp.hipHeight
	hum.AutomaticScalingEnabled = false
	hum.BreakJointsOnDeath = false
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.Parent = model
	for sname, id in pairs(SOUND_IDS) do
		local s = Instance.new("Sound")
		s.Name = sname
		s.SoundId = id
		s.Volume = (sname == "Scream" or sname == "Roar") and 1 or 0.6
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 8
		s.RollOffMaxDistance = (sname == "Scream") and 250 or 90
		s.Parent = parts.HumanoidRootPart
	end
	model:SetAttribute("HipHeight", bp.hipHeight)
	model:SetAttribute("RigScale", 1)
	return model
end

local function ensure(parent, name, class)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new(class or "Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end
local function putScript(parent, name, class, src)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local s = Instance.new(class)
	s.Name = name
	s.Source = src
	s.Parent = parent
end

local folder = ensure(ensure(ReplicatedStorage, "Creatures"), "Infected")
local old = folder:FindFirstChild("Types")
if old then
	old:Destroy()
end
local typesFolder = ensure(folder, "Types")
local order = { "Walker", "Runner", "Bloater", "Screamer", "Brute" }
for _, name in ipairs(order) do
	build(name, BLUEPRINTS[name]).Parent = typesFolder
end
local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({ MaxAlive = MAX_ALIVE, RespawnDelay = RESPAWN_DELAY, NightOnly = NIGHT_ONLY, SpawnCenter = SPAWN_CENTER, SpawnRadius = SPAWN_RADIUS, Debug = false }) do
	settings:SetAttribute(k, v)
end
for name, w in pairs(WEIGHTS) do
	settings:SetAttribute(name .. "Weight", w)
end
putScript(ensure(ReplicatedStorage, "Dragons"), "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(folder, "InfectedBrain", "ModuleScript", SOURCES.Brain)
putScript(game:GetService("ServerScriptService"), "InfectedSpawner", "Script", SOURCES.Spawner)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "InfectedClient", "LocalScript", SOURCES.Client)

-- vista previa en Studio: los cinco en fila, anclados (se destruye al pulsar Play)
local prev = workspace:FindFirstChild("InfectedPreview")
if prev then
	prev:Destroy()
end
prev = Instance.new("Model")
prev.Name = "InfectedPreview"
for i, name in ipairs(order) do
	local m = typesFolder[name]:Clone()
	if name == "Brute" then
		m:ScaleTo(1.4)
	end
	m:PivotTo(CFrame.new((i - 3) * 6, 0, -30) * CFrame.Angles(0, math.pi, 0))
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
	m.Parent = prev
end
prev.Parent = workspace
local cleanup = Instance.new("Script")
cleanup.Name = "RemoveOnPlay"
cleanup.Source = "script.Parent:Destroy()"
cleanup.Parent = prev

Selection:Set({ typesFolder })
pcall(function()
	ChangeHistoryService:SetWaypoint("Infectados instalados")
end)
print(("[Infected] Listo: 5 tipos construidos con Parts. Al pulsar Play aparecen hasta %d infectados. Vista previa en Workspace.InfectedPreview."):format(MAX_ALIVE))
