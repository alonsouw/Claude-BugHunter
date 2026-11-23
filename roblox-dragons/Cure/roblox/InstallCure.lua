--[[
	INSTALADOR DE LA CURA («Remedio del Alba») · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	No hace falta importar nada: pega TODO este archivo en View > Command Bar y pulsa Enter.

	Resultado:
	  ReplicatedStorage.Cure                     (Recipe, CureLogic, Items, World, Settings, Progress, eventos)
	  ServerScriptService.CureService            (botín, jefe dragón, plantas, caldero y final)
	  StarterPlayer.StarterPlayerScripts.CureClient (recetario, avisos, pantalla final, animación del jefe)
	  Workspace.CureCauldron                     (el caldero, en CAULDRON_POS)
	  Workspace.DragonLair                       (la guarida del dragón, en LAIR_POS)

	Ingredientes: saliva de dragón (jefe de la guarida), colmillo de alfa (lobos), asta maldita (ciervo maldito),
	perla negra (pez infectado gigante), corazón del bruto (infectados), flor de luna ×3 y raíz de sangre ×2 (plantas).
	Para el jefe hace falta tener instalado el Dragón Depredador o el Dragón Aberrante.
]]

local CAULDRON_POS = Vector3.new(0, 0, 30)    -- el caldero (pon aquí tu campamento)
local LAIR_POS = Vector3.new(0, 0, -160)      -- la guarida del dragón (lejos del campamento)
local CREATE_LAIR = true
local BOSS_DRAGON = "PredatorDragon"          -- "PredatorDragon" o "AberrantDragon" (el que tengas instalado)
local BOSS_HEALTH, BOSS_DAMAGE = 2500, 35
local BREW_TIME = 90                          -- segundos que tarda en prepararse
local PLANT_CENTER, PLANT_RADIUS = Vector3.new(0, 0, 0), 150   -- dónde crecen las plantas (o etiquetas MoonflowerSpot / BloodRootSpot)
local MOONFLOWERS, BLOODROOTS = 6, 4
-- Sonidos: sube los .ogg de sounds/ y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = { Pickup = "", Harvest = "", Add = "", Brew = "", Ready = "", Dawn = "" }

local ITEMS = {
	DragonSaliva = {
		{
			size = { 0.5, 0.7, 0.5 },
			offset = { 0, 0, 0 },
			color = { 200, 230, 220 },
			rot = { 0, 0, 0 },
			material = "Glass",
			name = "Handle",
		},
		{
			size = { 0.42, 0.5, 0.42 },
			offset = { 0, -0.08, 0 },
			color = { 190, 230, 60 },
			rot = { 0, 0, 0 },
			material = "Neon",
		},
		{
			size = { 0.3, 0.14, 0.3 },
			offset = { 0, 0.42, 0 },
			color = { 200, 230, 220 },
			rot = { 0, 0, 0 },
			material = "Glass",
		},
		{
			size = { 0.26, 0.16, 0.26 },
			offset = { 0, 0.55, 0 },
			color = { 120, 84, 50 },
			rot = { 0, 0, 0 },
			material = "Wood",
		},
		{
			size = { 0.08, 0.08, 0.08 },
			offset = { 0.1, 0.05, -0.18 },
			color = { 240, 255, 170 },
			rot = { 0, 0, 0 },
			material = "Neon",
		},
		{
			size = { 0.06, 0.06, 0.06 },
			offset = { -0.12, -0.12, -0.19 },
			color = { 240, 255, 170 },
			rot = { 0, 0, 0 },
			material = "Neon",
		},
		{
			size = { 0.54, 0.06, 0.54 },
			offset = { 0, -0.33, 0 },
			color = { 90, 70, 50 },
			rot = { 0, 0, 0 },
			material = "Wood",
		},
		{
			size = { 0.06, 0.3, 0.04 },
			offset = { 0.15, 0.25, -0.24 },
			color = { 190, 230, 60 },
			rot = { 0, 0, 10 },
			material = "Neon",
		},
	},
	AlphaFang = {
		{
			size = { 0.32, 0.36, 0.28 },
			offset = { 0, 0, 0 },
			color = { 92, 62, 40 },
			rot = { 0, 0, 0 },
			material = "Leather",
			name = "Handle",
		},
		{
			size = { 0.34, 0.12, 0.3 },
			offset = { 0, -0.22, 0 },
			color = { 70, 40, 30 },
			rot = { 0, 0, 0 },
			material = "Leather",
		},
		{
			size = { 0.28, 0.34, 0.28 },
			offset = { 0, 0.2883, 0.0237 },
			color = { 236, 226, 196 },
			rot = { 8, 0, 0 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.23, 0.32, 0.23 },
			offset = { 0, 0.5781, 0.1035 },
			color = { 232, 220, 186 },
			rot = { 22, 0, 0 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.18, 0.28, 0.18 },
			offset = { 0, 0.813, 0.24 },
			color = { 226, 212, 176 },
			rot = { 38, 0, 0 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.12, 0.24, 0.12 },
			offset = { 0, 0.9745, 0.4107 },
			color = { 218, 202, 164 },
			rot = { 55, 0, 0 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.07, 0.18, 0.07 },
			offset = { 0, 1.0631, 0.5779 },
			color = { 210, 194, 156 },
			rot = { 70, 0, 0 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.36, 0.05 },
			offset = { 0, 0.42, -0.1 },
			color = { 150, 40, 36 },
			rot = { 12, 0, 0 },
			material = "SmoothPlastic",
		},
	},
	CursedAntler = {
		{
			size = { 0.24, 0.3, 0.24 },
			offset = { 0, 0, 0 },
			color = { 110, 30, 30 },
			rot = { 0, 0, 0 },
			material = "SmoothPlastic",
			name = "Handle",
		},
		{
			size = { 0.2, 0.6, 0.2 },
			offset = { 0.0314, 0.4184, 0 },
			color = { 68, 54, 44 },
			rot = { 0, 0, -6 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.17, 0.55, 0.17 },
			offset = { 0.1242, 0.9358, 0 },
			color = { 68, 54, 44 },
			rot = { 0, 0, -14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.14, 0.5, 0.14 },
			offset = { 0.2818, 1.3883, 0 },
			color = { 68, 54, 44 },
			rot = { 0, 0, -24 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.1, 0.35, 0.1 },
			offset = { 0.4701, 1.7218, 0 },
			color = { 68, 54, 44 },
			rot = { 0, 0, -36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.12, 0.5, 0.12 },
			offset = { -0.1073, 0.7358, 0 },
			color = { 68, 54, 44 },
			rot = { 0, 0, 42 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.08, 0.32, 0.08 },
			offset = { -0.3154, 1.0369, 0 },
			color = { 68, 54, 44 },
			rot = { 0, 0, 25 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.11, 0.45, 0.11 },
			offset = { 0.3949, 1.157, 0.0348 },
			color = { 68, 54, 44 },
			rot = { 18, 0, -60 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.07, 0.25, 0.07 },
			offset = { 0.6389, 1.3298, 0.1118 },
			color = { 68, 54, 44 },
			rot = { 30, 0, -40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.09, 0.4, 0.09 },
			offset = { 0.2853, 1.5351, -0.0674 },
			color = { 68, 54, 44 },
			rot = { -20, 0, 10 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.035, 0.55, 0.035 },
			offset = { 0.0487, 0.4235, -0.11 },
			color = { 210, 30, 30 },
			rot = { 0, 0, -6 },
			material = "Neon",
		},
		{
			size = { 0.035, 0.5, 0.035 },
			offset = { 0.1334, 0.8958, -0.11 },
			color = { 210, 30, 30 },
			rot = { 0, 0, -14 },
			material = "Neon",
		},
		{
			size = { 0.035, 0.3, 0.035 },
			offset = { 0.2452, 1.2366, -0.11 },
			color = { 210, 30, 30 },
			rot = { 0, 0, -24 },
			material = "Neon",
		},
		{
			size = { 0.03, 0.4, 0.03 },
			offset = { -0.0538, 0.7286, -0.07 },
			color = { 210, 30, 30 },
			rot = { 0, 0, 42 },
			material = "Neon",
		},
	},
	BlackPearl = {
		{
			size = { 0.56, 0.56, 0.56 },
			offset = { 0, 0, 0 },
			color = { 24, 20, 30 },
			rot = { 0, 0, 0 },
			material = "Glass",
			name = "Handle",
		},
		{
			size = { 0.5, 0.5, 0.5 },
			offset = { 0, 0, 0 },
			color = { 30, 24, 40 },
			rot = { 45, 45, 0 },
			material = "Glass",
		},
		{
			size = { 0.42, 0.42, 0.42 },
			offset = { 0, 0, 0 },
			color = { 40, 30, 56 },
			rot = { 0, 45, 45 },
			material = "Glass",
		},
		{
			size = { 0.1, 0.1, 0.04 },
			offset = { 0.12, 0.14, -0.3 },
			color = { 200, 140, 255 },
			rot = { 0, 0, 0 },
			material = "Neon",
		},
		{
			size = { 0.06, 0.06, 0.04 },
			offset = { -0.1, -0.06, -0.3 },
			color = { 170, 110, 240 },
			rot = { 0, 0, 0 },
			material = "Neon",
		},
	},
	BruteHeart = {
		{
			size = { 0.6, 0.6, 0.5 },
			offset = { 0, 0, 0 },
			color = { 110, 20, 26 },
			rot = { 0, 0, 0 },
			material = "SmoothPlastic",
			name = "Handle",
		},
		{
			size = { 0.4, 0.4, 0.44 },
			offset = { -0.18, 0.28, 0 },
			color = { 120, 24, 30 },
			rot = { 0, 0, 0 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.36, 0.36, 0.42 },
			offset = { 0.2, 0.3, 0 },
			color = { 104, 18, 24 },
			rot = { 0, 0, 0 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.36, 0.36, 0.4 },
			offset = { 0, -0.32, 0 },
			color = { 96, 16, 22 },
			rot = { 0, 0, 45 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.12, 0.3, 0.12 },
			offset = { -0.12, 0.58, 0.05 },
			color = { 80, 14, 20 },
			rot = { 0, 0, 0 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.1, 0.24, 0.1 },
			offset = { 0.14, 0.58, -0.05 },
			color = { 140, 140, 120 },
			rot = { 0, 0, 0 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.5, 0.04 },
			offset = { 0.05, 0.05, -0.26 },
			color = { 40, 8, 12 },
			rot = { 0, 0, 20 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.4, 0.04 },
			offset = { -0.15, -0.05, -0.26 },
			color = { 40, 8, 12 },
			rot = { 0, 0, -25 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.12, 0.12, 0.12 },
			offset = { 0.2, -0.05, -0.25 },
			color = { 190, 232, 70 },
			rot = { 0, 0, 0 },
			material = "Neon",
		},
		{
			size = { 0.09, 0.09, 0.09 },
			offset = { -0.22, 0.15, -0.24 },
			color = { 190, 232, 70 },
			rot = { 0, 0, 0 },
			material = "Neon",
		},
	},
	Moonflower = {
		{
			size = { 0.08, 0.8, 0.08 },
			offset = { 0, 0, 0 },
			color = { 60, 110, 70 },
			rot = { 0, 0, 0 },
			material = "SmoothPlastic",
			name = "Handle",
		},
		{
			size = { 0.14, 0.04, 0.32 },
			offset = { 0, 0.44, 0.16 },
			color = { 190, 225, 255 },
			rot = { -25, 0, 0 },
			material = "Neon",
		},
		{
			size = { 0.14, 0.04, 0.32 },
			offset = { 0.1522, 0.44, 0.0494 },
			color = { 190, 225, 255 },
			rot = { -25, 72, 0 },
			material = "Neon",
		},
		{
			size = { 0.14, 0.04, 0.32 },
			offset = { 0.094, 0.44, -0.1294 },
			color = { 190, 225, 255 },
			rot = { -25, 144, 0 },
			material = "Neon",
		},
		{
			size = { 0.14, 0.04, 0.32 },
			offset = { -0.094, 0.44, -0.1294 },
			color = { 190, 225, 255 },
			rot = { -25, 216, 0 },
			material = "Neon",
		},
		{
			size = { 0.14, 0.04, 0.32 },
			offset = { -0.1522, 0.44, 0.0494 },
			color = { 190, 225, 255 },
			rot = { -25, 288, 0 },
			material = "Neon",
		},
		{
			size = { 0.1, 0.1, 0.1 },
			offset = { 0, 0.46, 0 },
			color = { 255, 250, 200 },
			rot = { 0, 0, 0 },
			material = "Neon",
		},
		{
			size = { 0.24, 0.03, 0.12 },
			offset = { 0.1, -0.1, 0 },
			color = { 70, 130, 80 },
			rot = { 0, 0, -20 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.22, 0.03, 0.1 },
			offset = { -0.1, 0.05, 0 },
			color = { 70, 130, 80 },
			rot = { 0, 30, 20 },
			material = "SmoothPlastic",
		},
	},
	BloodRoot = {
		{
			size = { 0.3, 0.5, 0.3 },
			offset = { 0, 0, 0 },
			color = { 140, 26, 34 },
			rot = { 0, 0, 10 },
			material = "SmoothPlastic",
			name = "Handle",
		},
		{
			size = { 0.2, 0.45, 0.2 },
			offset = { 0.14, -0.35, 0.05 },
			color = { 130, 22, 30 },
			rot = { 0, 0, -25 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.14, 0.4, 0.14 },
			offset = { -0.16, -0.32, -0.05 },
			color = { 124, 20, 28 },
			rot = { 10, 0, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.1, 0.35, 0.1 },
			offset = { 0.28, -0.6, 0.06 },
			color = { 118, 18, 26 },
			rot = { 0, 0, -45 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.08, 0.3, 0.08 },
			offset = { -0.3, -0.58, 0 },
			color = { 118, 18, 26 },
			rot = { 0, 0, 50 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.34, 0.16, 0.34 },
			offset = { 0, 0.22, 0 },
			color = { 70, 52, 36 },
			rot = { 0, 0, 0 },
			material = "Ground",
		},
		{
			size = { 0.06, 0.3, 0.06 },
			offset = { 0.05, 0.4, 0 },
			color = { 60, 110, 50 },
			rot = { 0, 0, 15 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.06, 0.26, 0.06 },
			offset = { -0.06, 0.38, 0.03 },
			color = { 60, 110, 50 },
			rot = { 0, 0, -20 },
			material = "SmoothPlastic",
		},
	},
	Remedy = {
		{
			size = { 0.62, 0.8, 0.62 },
			offset = { 0, 0, 0 },
			color = { 230, 236, 240 },
			rot = { 0, 0, 0 },
			material = "Glass",
			name = "Handle",
		},
		{
			size = { 0.54, 0.62, 0.54 },
			offset = { 0, -0.06, 0 },
			color = { 255, 214, 110 },
			rot = { 0, 0, 0 },
			material = "Neon",
		},
		{
			size = { 0.32, 0.22, 0.32 },
			offset = { 0, 0.5, 0 },
			color = { 230, 236, 240 },
			rot = { 0, 0, 0 },
			material = "Glass",
		},
		{
			size = { 0.38, 0.14, 0.38 },
			offset = { 0, 0.66, 0 },
			color = { 214, 170, 60 },
			rot = { 0, 0, 0 },
			material = "Metal",
		},
		{
			size = { 0.1, 0.1, 0.1 },
			offset = { 0, 0.78, 0 },
			color = { 214, 170, 60 },
			rot = { 0, 0, 0 },
			material = "Metal",
		},
		{
			size = { 0.66, 0.06, 0.66 },
			offset = { 0, -0.38, 0 },
			color = { 214, 170, 60 },
			rot = { 0, 0, 0 },
			material = "Metal",
		},
		{
			size = { 0.2, 0.2, 0.03 },
			offset = { 0, 0, -0.33 },
			color = { 255, 250, 220 },
			rot = { 0, 0, 45 },
			material = "Neon",
		},
		{
			size = { 0.36, 0.05, 0.03 },
			offset = { 0, 0, -0.335 },
			color = { 255, 236, 160 },
			rot = { 0, 0, 0 },
			material = "Neon",
		},
		{
			size = { 0.05, 0.36, 0.03 },
			offset = { 0, 0, -0.335 },
			color = { 255, 236, 160 },
			rot = { 0, 0, 0 },
			material = "Neon",
		},
	},
}
local WORLD = {
	MoonflowerPlant = {
		{
			size = { 1.4, 0.2, 1.4 },
			offset = { 0, 0.1, 0 },
			color = { 52, 74, 44 },
			rot = { 0, 0, 0 },
			material = "Grass",
			name = "Handle",
		},
		{
			size = { 0.1, 1.6, 0.1 },
			offset = { 0, 1, 0 },
			color = { 60, 110, 70 },
			rot = { 0, 0, 0 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { 0, 1.85, 0.2 },
			color = { 190, 225, 255 },
			rot = { -25, 0, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { 0.1902, 1.85, 0.0618 },
			color = { 190, 225, 255 },
			rot = { -25, 72, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { 0.1176, 1.85, -0.1618 },
			color = { 190, 225, 255 },
			rot = { -25, 144, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { -0.1176, 1.85, -0.1618 },
			color = { 190, 225, 255 },
			rot = { -25, 216, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { -0.1902, 1.85, 0.0618 },
			color = { 190, 225, 255 },
			rot = { -25, 288, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.12, 0.12, 0.12 },
			offset = { 0, 1.87, 0 },
			color = { 255, 250, 200 },
			rot = { 0, 0, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.3, 0.18 },
			offset = { 0, 1.9, 0 },
			color = { 70, 110, 90 },
			rot = { 0, 0, 0 },
			material = "SmoothPlastic",
			name = "Bud",
		},
		{
			size = { 0.1, 1.1, 0.1 },
			offset = { 0.35, 0.75, 0.2 },
			color = { 60, 110, 70 },
			rot = { 0, 0, 0 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { 0.35, 1.35, 0.4 },
			color = { 190, 225, 255 },
			rot = { -25, 0, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { 0.5402, 1.35, 0.2618 },
			color = { 190, 225, 255 },
			rot = { -25, 72, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { 0.4676, 1.35, 0.0382 },
			color = { 190, 225, 255 },
			rot = { -25, 144, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { 0.2324, 1.35, 0.0382 },
			color = { 190, 225, 255 },
			rot = { -25, 216, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { 0.1598, 1.35, 0.2618 },
			color = { 190, 225, 255 },
			rot = { -25, 288, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.12, 0.12, 0.12 },
			offset = { 0.35, 1.37, 0.2 },
			color = { 255, 250, 200 },
			rot = { 0, 0, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.3, 0.18 },
			offset = { 0.35, 1.4, 0.2 },
			color = { 70, 110, 90 },
			rot = { 0, 0, 0 },
			material = "SmoothPlastic",
			name = "Bud",
		},
		{
			size = { 0.1, 1.25, 0.1 },
			offset = { -0.3, 0.825, -0.2 },
			color = { 60, 110, 70 },
			rot = { 0, 0, 0 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { -0.3, 1.5, 0 },
			color = { 190, 225, 255 },
			rot = { -25, 0, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { -0.1098, 1.5, -0.1382 },
			color = { 190, 225, 255 },
			rot = { -25, 72, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { -0.1824, 1.5, -0.3618 },
			color = { 190, 225, 255 },
			rot = { -25, 144, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { -0.4176, 1.5, -0.3618 },
			color = { 190, 225, 255 },
			rot = { -25, 216, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.05, 0.4 },
			offset = { -0.4902, 1.5, -0.1382 },
			color = { 190, 225, 255 },
			rot = { -25, 288, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.12, 0.12, 0.12 },
			offset = { -0.3, 1.52, -0.2 },
			color = { 255, 250, 200 },
			rot = { 0, 0, 0 },
			material = "Neon",
			name = "Petal",
		},
		{
			size = { 0.18, 0.3, 0.18 },
			offset = { -0.3, 1.55, -0.2 },
			color = { 70, 110, 90 },
			rot = { 0, 0, 0 },
			material = "SmoothPlastic",
			name = "Bud",
		},
		{
			size = { 0.5, 0.04, 0.18 },
			offset = { 0.3, 0.45, -0.3 },
			color = { 70, 130, 80 },
			rot = { 0, 30, 15 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.5, 0.04, 0.18 },
			offset = { -0.35, 0.45, 0.3 },
			color = { 70, 130, 80 },
			rot = { 0, -20, 15 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.5, 0.04, 0.18 },
			offset = { 0.1, 0.45, 0.4 },
			color = { 70, 130, 80 },
			rot = { 0, 70, 15 },
			material = "SmoothPlastic",
		},
	},
	BloodRootMound = {
		{
			size = { 1.6, 0.4, 1.4 },
			offset = { 0, 0.2, 0 },
			color = { 74, 56, 40 },
			rot = { 0, 0, 0 },
			material = "Ground",
			name = "Handle",
		},
		{
			size = { 1, 0.3, 0.9 },
			offset = { 0.1, 0.5, 0 },
			color = { 84, 64, 46 },
			rot = { 0, 0, 0 },
			material = "Ground",
		},
		{
			size = { 0.14, 0.6, 0.14 },
			offset = { 0.3, 0.6, 0.1 },
			color = { 140, 26, 34 },
			rot = { -10, 0, -30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.14, 0.6, 0.14 },
			offset = { -0.25, 0.6, -0.15 },
			color = { 140, 26, 34 },
			rot = { 13.3333, 0, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.14, 0.6, 0.14 },
			offset = { 0, 0.6, 0.35 },
			color = { 140, 26, 34 },
			rot = { 3.3333, 0, 10 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.14, 0.6, 0.14 },
			offset = { 0.45, 0.6, -0.3 },
			color = { 140, 26, 34 },
			rot = { -20, 0, -60 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.06, 0.4, 0.06 },
			offset = { 0.2, 0.85, -0.1 },
			color = { 60, 110, 50 },
			rot = { 0, 0, 12 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.06, 0.4, 0.06 },
			offset = { -0.2, 0.85, 0.2 },
			color = { 60, 110, 50 },
			rot = { 0, 0, -12 },
			material = "SmoothPlastic",
		},
	},
	Cauldron = {
		{
			size = { 6.5, 0.3, 6.5 },
			offset = { 0, 0.15, 0 },
			color = { 70, 66, 62 },
			rot = { 0, 0, 0 },
			material = "Slate",
			name = "Handle",
		},
		{
			size = { 1.35, 1.8, 0.25 },
			offset = { 0, 2.1, 1.55 },
			color = { 40, 38, 40 },
			rot = { 0, 0, 0 },
			material = "Metal",
		},
		{
			size = { 1.35, 1.8, 0.25 },
			offset = { 1.096, 2.1, 1.096 },
			color = { 40, 38, 40 },
			rot = { 0, 45, 0 },
			material = "Metal",
		},
		{
			size = { 1.35, 1.8, 0.25 },
			offset = { 1.55, 2.1, 0 },
			color = { 40, 38, 40 },
			rot = { 0, 90, 0 },
			material = "Metal",
		},
		{
			size = { 1.35, 1.8, 0.25 },
			offset = { 1.096, 2.1, -1.096 },
			color = { 40, 38, 40 },
			rot = { 0, 135, 0 },
			material = "Metal",
		},
		{
			size = { 1.35, 1.8, 0.25 },
			offset = { 0, 2.1, -1.55 },
			color = { 40, 38, 40 },
			rot = { 0, 180, 0 },
			material = "Metal",
		},
		{
			size = { 1.35, 1.8, 0.25 },
			offset = { -1.096, 2.1, -1.096 },
			color = { 40, 38, 40 },
			rot = { 0, 225, 0 },
			material = "Metal",
		},
		{
			size = { 1.35, 1.8, 0.25 },
			offset = { -1.55, 2.1, 0 },
			color = { 40, 38, 40 },
			rot = { 0, 270, 0 },
			material = "Metal",
		},
		{
			size = { 1.35, 1.8, 0.25 },
			offset = { -1.096, 2.1, 1.096 },
			color = { 40, 38, 40 },
			rot = { 0, 315, 0 },
			material = "Metal",
		},
		{
			size = { 1, 0.2, 0.3 },
			offset = { 0.6429, 3, 1.5521 },
			color = { 60, 56, 58 },
			rot = { 0, 22.5, 0 },
			material = "Metal",
		},
		{
			size = { 1, 0.2, 0.3 },
			offset = { 1.5521, 3, 0.6429 },
			color = { 60, 56, 58 },
			rot = { 0, 67.5, 0 },
			material = "Metal",
		},
		{
			size = { 1, 0.2, 0.3 },
			offset = { 1.5521, 3, -0.6429 },
			color = { 60, 56, 58 },
			rot = { 0, 112.5, 0 },
			material = "Metal",
		},
		{
			size = { 1, 0.2, 0.3 },
			offset = { 0.6429, 3, -1.5521 },
			color = { 60, 56, 58 },
			rot = { 0, 157.5, 0 },
			material = "Metal",
		},
		{
			size = { 1, 0.2, 0.3 },
			offset = { -0.6429, 3, -1.5521 },
			color = { 60, 56, 58 },
			rot = { 0, 202.5, 0 },
			material = "Metal",
		},
		{
			size = { 1, 0.2, 0.3 },
			offset = { -1.5521, 3, -0.6429 },
			color = { 60, 56, 58 },
			rot = { 0, 247.5, 0 },
			material = "Metal",
		},
		{
			size = { 1, 0.2, 0.3 },
			offset = { -1.5521, 3, 0.6429 },
			color = { 60, 56, 58 },
			rot = { 0, 292.5, 0 },
			material = "Metal",
		},
		{
			size = { 1, 0.2, 0.3 },
			offset = { -0.6429, 3, 1.5521 },
			color = { 60, 56, 58 },
			rot = { 0, 337.5, 0 },
			material = "Metal",
		},
		{
			size = { 3, 0.3, 3 },
			offset = { 0, 1.25, 0 },
			color = { 40, 38, 40 },
			rot = { 0, 0, 0 },
			material = "Metal",
		},
		{
			size = { 2.9, 0.2, 2.9 },
			offset = { 0, 2.7, 0 },
			color = { 70, 120, 60 },
			rot = { 0, 0, 0 },
			material = "Neon",
			name = "Liquid",
		},
		{
			size = { 0.3, 1.1, 0.3 },
			offset = { 1.2, 0.75, 1.2 },
			color = { 40, 38, 40 },
			rot = { 0, 0, 0 },
			material = "Metal",
		},
		{
			size = { 0.3, 1.1, 0.3 },
			offset = { 1.2, 0.75, -1.2 },
			color = { 40, 38, 40 },
			rot = { 0, 0, 0 },
			material = "Metal",
		},
		{
			size = { 0.3, 1.1, 0.3 },
			offset = { -1.2, 0.75, 1.2 },
			color = { 40, 38, 40 },
			rot = { 0, 0, 0 },
			material = "Metal",
		},
		{
			size = { 0.3, 1.1, 0.3 },
			offset = { -1.2, 0.75, -1.2 },
			color = { 40, 38, 40 },
			rot = { 0, 0, 0 },
			material = "Metal",
		},
		{
			size = { 1, 0.6, 1 },
			offset = { 0, 0.6, 0 },
			color = { 255, 120, 30 },
			rot = { 0, 0, 0 },
			material = "Neon",
			name = "Fire",
		},
		{
			size = { 0.6, 0.8, 0.6 },
			offset = { 0.1, 0.7, 0.05 },
			color = { 255, 190, 60 },
			rot = { 0, 40, 0 },
			material = "Neon",
		},
		{
			size = { 0.25, 0.25, 0.8 },
			offset = { -1.75, 2.85, 0 },
			color = { 40, 38, 40 },
			rot = { 0, 0, 0 },
			material = "Metal",
		},
		{
			size = { 0.25, 0.25, 0.8 },
			offset = { 1.75, 2.85, 0 },
			color = { 40, 38, 40 },
			rot = { 0, 0, 0 },
			material = "Metal",
		},
		{
			size = { 0.7, 1.2, 0.7 },
			offset = { 0, 0.9, -4.3 },
			color = { 90, 86, 80 },
			rot = { 0, 0, 0 },
			material = "Slate",
		},
		{
			size = { 0.5, 0.2, 0.5 },
			offset = { 0, 1.6, -4.3 },
			color = { 60, 56, 54 },
			rot = { 0, 0, 0 },
			material = "Neon",
			name = "Slot1",
		},
		{
			size = { 0.7, 1.2, 0.7 },
			offset = { -3.3619, 0.9, -2.681 },
			color = { 90, 86, 80 },
			rot = { 0, 0, 0 },
			material = "Slate",
		},
		{
			size = { 0.5, 0.2, 0.5 },
			offset = { -3.3619, 1.6, -2.681 },
			color = { 60, 56, 54 },
			rot = { 0, 0, 0 },
			material = "Neon",
			name = "Slot2",
		},
		{
			size = { 0.7, 1.2, 0.7 },
			offset = { -4.1922, 0.9, 0.9568 },
			color = { 90, 86, 80 },
			rot = { 0, 0, 0 },
			material = "Slate",
		},
		{
			size = { 0.5, 0.2, 0.5 },
			offset = { -4.1922, 1.6, 0.9568 },
			color = { 60, 56, 54 },
			rot = { 0, 0, 0 },
			material = "Neon",
			name = "Slot3",
		},
		{
			size = { 0.7, 1.2, 0.7 },
			offset = { -1.8657, 0.9, 3.8742 },
			color = { 90, 86, 80 },
			rot = { 0, 0, 0 },
			material = "Slate",
		},
		{
			size = { 0.5, 0.2, 0.5 },
			offset = { -1.8657, 1.6, 3.8742 },
			color = { 60, 56, 54 },
			rot = { 0, 0, 0 },
			material = "Neon",
			name = "Slot4",
		},
		{
			size = { 0.7, 1.2, 0.7 },
			offset = { 1.8657, 0.9, 3.8742 },
			color = { 90, 86, 80 },
			rot = { 0, 0, 0 },
			material = "Slate",
		},
		{
			size = { 0.5, 0.2, 0.5 },
			offset = { 1.8657, 1.6, 3.8742 },
			color = { 60, 56, 54 },
			rot = { 0, 0, 0 },
			material = "Neon",
			name = "Slot5",
		},
		{
			size = { 0.7, 1.2, 0.7 },
			offset = { 4.1922, 0.9, 0.9568 },
			color = { 90, 86, 80 },
			rot = { 0, 0, 0 },
			material = "Slate",
		},
		{
			size = { 0.5, 0.2, 0.5 },
			offset = { 4.1922, 1.6, 0.9568 },
			color = { 60, 56, 54 },
			rot = { 0, 0, 0 },
			material = "Neon",
			name = "Slot6",
		},
		{
			size = { 0.7, 1.2, 0.7 },
			offset = { 3.3619, 0.9, -2.681 },
			color = { 90, 86, 80 },
			rot = { 0, 0, 0 },
			material = "Slate",
		},
		{
			size = { 0.5, 0.2, 0.5 },
			offset = { 3.3619, 1.6, -2.681 },
			color = { 60, 56, 54 },
			rot = { 0, 0, 0 },
			material = "Neon",
			name = "Slot7",
		},
	},
}
local RECIPE_SRC = [=======[
--[[
	Receta del Remedio del Alba (ModuleScript) · ReplicatedStorage.Cure.Recipe
	Generado desde src/cure_blueprints.js. Se puede editar aquí: need = cuántos hacen falta, hint = la pista del recetario.
]]
return {
	{
		id = "DragonSaliva",
		name = "Saliva de dragón",
		need = 1,
		hint = "Mata al dragón que guarda la guarida.",
		color = { 190, 230, 60 },
	},
	{
		id = "AlphaFang",
		name = "Colmillo de alfa",
		need = 1,
		hint = "Lo suelta el lobo alfa al morir.",
		color = { 236, 226, 196 },
	},
	{
		id = "CursedAntler",
		name = "Asta maldita",
		need = 1,
		hint = "Un ciervo maldito la deja caer al transformarse.",
		color = { 200, 30, 30 },
	},
	{
		id = "BlackPearl",
		name = "Perla negra",
		need = 1,
		hint = "La lleva dentro el pez infectado gigante.",
		color = { 170, 110, 240 },
	},
	{
		id = "BruteHeart",
		name = "Corazón del bruto",
		need = 1,
		hint = "Arráncaselo a un infectado bruto.",
		color = { 160, 30, 36 },
	},
	{
		id = "Moonflower",
		name = "Flor de luna",
		need = 3,
		hint = "Solo se abre de noche, en el bosque.",
		color = { 190, 225, 255 },
	},
	{
		id = "BloodRoot",
		name = "Raíz de sangre",
		need = 2,
		hint = "Desentiérrala; crece en la tierra enferma.",
		color = { 140, 26, 34 },
	},
}
]=======]
local SOURCES = {
	Logic = [=======[
--[[
	CureLogic (ModuleScript) · ReplicatedStorage.Cure.CureLogic

	Lógica pura de la cura (sin Instances: se prueba fuera de Roblox). La usa CureService.
	  · Receta: cuánto falta de cada ingrediente, echar uno al caldero, si ya está todo.
	  · Botín: qué suelta cada criatura (DropFor).
	  · Noche: la flor de luna solo se abre de noche (IsNight).
	  · Preparación: Collecting → Ready → Brewing → Done → Used.
	  · Jefe dragón de la guarida (Boss): Idle · Roar · Chase · Attack · Return · Hurt · Dead.
]]

local Logic = {}

-- ---------------------------------------------------------------- receta
function Logic.Remaining(progress, recipe, id)
	for _, r in ipairs(recipe) do
		if r.id == id then
			return math.max(0, r.need - (progress[id] or 0))
		end
	end
	return 0
end

function Logic.Add(progress, recipe, id)   -- true si hacía falta y se ha echado
	if Logic.Remaining(progress, recipe, id) > 0 then
		progress[id] = (progress[id] or 0) + 1
		return true
	end
	return false
end

function Logic.Complete(progress, recipe)
	for _, r in ipairs(recipe) do
		if (progress[r.id] or 0) < r.need then
			return false
		end
	end
	return true
end

function Logic.Count(progress, recipe)   -- ingredientes completos, total
	local done = 0
	for _, r in ipairs(recipe) do
		if (progress[r.id] or 0) >= r.need then
			done += 1
		end
	end
	return done, #recipe
end

-- ---------------------------------------------------------------- botín
-- kind: "boss" | "wolf" | "deerForm" | "infected" | "fish" | "custom"; info: lo que se sabe de la criatura
function Logic.DropFor(kind, info)
	info = info or {}
	if info.cureDrop and info.cureDrop ~= "" then
		return info.cureDrop
	end
	if kind == "boss" then
		return "DragonSaliva"
	elseif kind == "wolf" and (info.alpha == true or info.variant == "Alpha") then
		return "AlphaFang"
	elseif kind == "deerForm" and info.form == "creature" then
		return "CursedAntler"
	elseif kind == "infected" and info.name == "Brute" then
		return "BruteHeart"
	elseif kind == "fish" and info.name == "Giant" then
		return "BlackPearl"
	end
	return nil
end

function Logic.IsNight(clockTime: number)
	return clockTime >= 18.5 or clockTime < 5.5
end

-- ---------------------------------------------------------------- preparación en el caldero
local Brew = {}
Brew.__index = Brew
Logic.Brew = Brew

function Brew.new(duration: number)
	return setmetatable({ state = "Collecting", duration = duration, t0 = 0 }, Brew)
end
function Brew:SetReady(ready: boolean)
	if self.state == "Collecting" and ready then
		self.state = "Ready"
	end
end
function Brew:Start(now: number)
	if self.state ~= "Ready" then
		return false
	end
	self.state = "Brewing"
	self.t0 = now
	return true
end
function Brew:Fraction(now: number)
	if self.state == "Brewing" then
		return math.clamp((now - self.t0) / self.duration, 0, 1)
	end
	return (self.state == "Done" or self.state == "Used") and 1 or 0
end
function Brew:Update(now: number)   -- true justo cuando termina
	if self.state == "Brewing" and now - self.t0 >= self.duration then
		self.state = "Done"
		return true
	end
	return false
end
function Brew:Use()
	if self.state == "Done" then
		self.state = "Used"
		return true
	end
	return false
end

-- ---------------------------------------------------------------- jefe dragón
-- P: hasTarget, dist (al jugador), fromHome (distancia del dragón a su guarida), targetFromHome, dead, hurt
-- Órdenes: {"anim", nombre, fundido} · {"move", "chase"|"home"|"stop", velocidad} · {"attack", retardo} · {"sound", nombre}
local Boss = {}
Boss.__index = Boss
Logic.Boss = Boss
Boss.Defaults = { Detect = 70, Reach = 14, Cooldown = 2.8, Speed = 12, Leash = 70, RoarCooldown = 25 }

function Boss.new(cfg)
	local self = setmetatable({}, Boss)
	self.cfg = setmetatable(cfg or {}, { __index = Boss.Defaults })
	self.t = 0
	self.nextAttack = 0
	self.nextRoar = 0
	self.state = "Idle"
	self.timer = 0
	return self
end
function Boss:emit(out, ...)
	table.insert(out, { ... })
end
function Boss:Update(dt, P)
	local out, c = {}, self.cfg
	self.t += dt
	self.timer -= dt
	local s = self.state
	if s == "Dead" then
		return out
	end
	if P.dead then
		self:emit(out, "move", "stop", 0)
		self:emit(out, "anim", "Death", 0.2)
		self:emit(out, "sound", "Death")
		self.state = "Dead"
		return out
	end
	local valid = P.hasTarget and P.dist <= c.Detect and P.targetFromHome <= c.Leash
	if s == "Idle" or s == "Return" then
		if valid then
			if self.t >= self.nextRoar then
				self.nextRoar = self.t + c.RoarCooldown
				self:emit(out, "move", "stop", 0)
				self:emit(out, "anim", "Roar", 0.2)
				self:emit(out, "sound", "Roar")
				self.state, self.timer = "Roar", 2.2
			else
				self:emit(out, "anim", "Walk", 0.3)
				self:emit(out, "move", "chase", c.Speed)
				self.state = "Chase"
			end
		elseif s == "Return" and P.fromHome < 3 then
			self:emit(out, "anim", "Idle", 0.4)
			self:emit(out, "move", "stop", 0)
			self.state = "Idle"
		end
	elseif s == "Roar" then
		if self.timer <= 0 then
			self:emit(out, "anim", "Walk", 0.3)
			self:emit(out, "move", "chase", c.Speed)
			self.state = "Chase"
		end
	elseif s == "Chase" then
		if not valid then
			self:emit(out, "anim", "Walk", 0.3)
			self:emit(out, "move", "home", c.Speed * 0.7)
			self.state = "Return"
		elseif P.dist <= c.Reach and self.t >= self.nextAttack then
			self.nextAttack = self.t + c.Cooldown
			self:emit(out, "move", "stop", 0)
			self:emit(out, "anim", "Attack", 0.15)
			self:emit(out, "attack", 0.5)
			self.state, self.timer = "Attack", 1.3
		elseif P.dist <= c.Reach then
			self:emit(out, "move", "stop", 0)
		else
			self:emit(out, "move", "chase", c.Speed)
		end
	elseif s == "Attack" then
		if self.timer <= 0 then
			self:emit(out, "anim", "Walk", 0.3)
			if valid then
				self:emit(out, "move", "chase", c.Speed)
				self.state = "Chase"
			else
				self:emit(out, "move", "home", c.Speed * 0.7)
				self.state = "Return"
			end
		end
	end
	return out
end

return Logic
]=======],
	Service = [=======[
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
]=======],
	Client = [=======[
--[[
	CureClient (LocalScript) · StarterPlayer.StarterPlayerScripts.CureClient

	  · Recetario: botón «Cura 2/7» arriba a la derecha; al pulsarlo (o con la tecla R) se ve qué falta y dónde buscarlo.
	  · Avisos («Ha aparecido: Perla negra», «X ha echado al caldero…»).
	  · Pantalla final al usar el Remedio del Alba.
	  · Anima al dragón de la guarida con DragonAnimator (Roblox no replica Motor6D/Bone.Transform desde el servidor).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local folder = ReplicatedStorage:WaitForChild("Cure")
local RECIPE = require(folder:WaitForChild("Recipe"))
local progressCfg = folder:WaitForChild("Progress")
local remote = folder:WaitForChild("Remote")

local GOLD = Color3.fromRGB(255, 214, 120)
local INK = Color3.fromRGB(236, 228, 210)
local DIM = Color3.fromRGB(150, 142, 132)

local gui = Instance.new("ScreenGui")
gui.Name = "CureHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Gotham
	l.TextColor3 = INK
	l.TextXAlignment = Enum.TextXAlignment.Left
	for k, v in pairs(props) do
		l[k] = v
	end
	l.Parent = parent
	return l
end

-- botón y panel del recetario
local button = Instance.new("TextButton")
button.AnchorPoint = Vector2.new(1, 0)
button.Position = UDim2.new(1, -16, 0, 60)
button.Size = UDim2.fromOffset(150, 40)
button.BackgroundColor3 = Color3.fromRGB(28, 22, 18)
button.BackgroundTransparency = 0.15
button.Font = Enum.Font.GothamBold
button.TextSize = 18
button.TextColor3 = GOLD
button.AutoButtonColor = true
button.Parent = gui
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -16, 0, 108)
panel.Size = UDim2.fromOffset(360, 70 + #RECIPE * 52)
panel.BackgroundColor3 = Color3.fromRGB(20, 16, 14)
panel.BackgroundTransparency = 0.08
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local pad = Instance.new("UIPadding", panel)
pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop = UDim.new(0, 14), UDim.new(0, 14), UDim.new(0, 10)
label(panel, { Text = "Remedio del Alba", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = GOLD, Size = UDim2.new(1, 0, 0, 26) })
local stageLabel = label(panel, { Text = "", TextSize = 14, TextColor3 = DIM, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 28), TextWrapped = true })
local rows = {}
for i, r in ipairs(RECIPE) do
	local y = 56 + (i - 1) * 52
	local sw = Instance.new("Frame")
	sw.Position = UDim2.fromOffset(0, y + 4)
	sw.Size = UDim2.fromOffset(14, 14)
	sw.BackgroundColor3 = Color3.fromRGB(r.color[1], r.color[2], r.color[3])
	sw.BorderSizePixel = 0
	sw.Parent = panel
	local name = label(panel, { Text = r.name, Font = Enum.Font.GothamBold, TextSize = 16, Position = UDim2.fromOffset(22, y), Size = UDim2.new(1, -90, 0, 22) })
	local count = label(panel, { Text = "", Font = Enum.Font.GothamBold, TextSize = 16, Position = UDim2.new(1, -66, 0, y), Size = UDim2.fromOffset(66, 22), TextXAlignment = Enum.TextXAlignment.Right })
	local hint = label(panel, { Text = r.hint, TextSize = 13, TextColor3 = DIM, Position = UDim2.fromOffset(22, y + 22), Size = UDim2.new(1, -22, 0, 20), TextWrapped = true })
	rows[r.id] = { name = name, count = count, hint = hint, need = r.need }
end

local STAGE = {
	Collecting = "Busca los ingredientes y échalos al caldero (E).",
	Ready = "¡Está todo! Ve al caldero y prepara la cura.",
	Done = "¡El Remedio del Alba está listo en el caldero!",
	Used = "La infección se ha curado.",
}
local function refresh()
	local done, total = folder:GetAttribute("Done") or 0, folder:GetAttribute("Total") or #RECIPE
	local stage = folder:GetAttribute("Stage") or "Collecting"
	button.Text = stage == "Used" and "✓ Curado" or ("Cura  %d/%d"):format(done, total)
	if stage == "Brewing" then
		stageLabel.Text = ("Preparando la cura... %d %%"):format(math.floor((folder:GetAttribute("BrewFraction") or 0) * 100))
	else
		stageLabel.Text = STAGE[stage] or ""
	end
	for id, row in pairs(rows) do
		local have = progressCfg:GetAttribute(id) or 0
		local full = have >= row.need
		row.count.Text = full and "✓" or ("%d/%d"):format(have, row.need)
		row.count.TextColor3 = full and Color3.fromRGB(150, 220, 120) or INK
		row.name.TextColor3 = full and DIM or INK
	end
end
for _, a in ipairs({ "Done", "Total", "Stage", "BrewFraction" }) do
	folder:GetAttributeChangedSignal(a):Connect(refresh)
end
progressCfg.AttributeChanged:Connect(refresh)
refresh()
button.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.R then
		panel.Visible = not panel.Visible
	end
end)

-- avisos
local toastLabel = label(gui, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 120), Size = UDim2.fromOffset(640, 30),
	Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = GOLD, TextStrokeTransparency = 1, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center })
local serial = 0
local function showToast(text)
	serial += 1
	local mine = serial
	toastLabel.Text = text
	toastLabel.TextTransparency, toastLabel.TextStrokeTransparency = 0, 0.3
	task.delay(3.5, function()
		if mine == serial then
			TweenService:Create(toastLabel, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- pantalla final
local function showEnding(who)
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.fromRGB(255, 236, 190)
	f.BackgroundTransparency = 1
	f.Parent = gui
	local title = label(f, { Text = "EL REMEDIO DEL ALBA", Font = Enum.Font.GothamBlack, TextSize = 48, TextColor3 = Color3.fromRGB(90, 56, 20),
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.new(1, -40, 0, 60), TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1, TextScaled = true })
	local sub = label(f, { Text = ("La infección se ha curado. Gracias, %s."):format(who), TextSize = 22, TextColor3 = Color3.fromRGB(110, 76, 36),
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.54), Size = UDim2.new(1, -40, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1 })
	local tin = TweenInfo.new(1.5)
	TweenService:Create(f, tin, { BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(title, tin, { TextTransparency = 0 }):Play()
	TweenService:Create(sub, tin, { TextTransparency = 0 }):Play()
	local dawn = folder:FindFirstChild("Dawn")
	if dawn and dawn:IsA("Sound") and dawn.SoundId ~= "" then
		dawn:Play()
	end
	task.delay(9, function()
		local tout = TweenInfo.new(2)
		TweenService:Create(f, tout, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(title, tout, { TextTransparency = 1 }):Play()
		TweenService:Create(sub, tout, { TextTransparency = 1 }):Play()
		task.delay(2.2, function()
			f:Destroy()
		end)
	end)
end

remote.OnClientEvent:Connect(function(kind, value)
	if kind == "toast" then
		showToast(value)
	elseif kind == "ending" then
		showEnding(value)
	end
end)
gui.Parent = player:WaitForChild("PlayerGui")

-- animación del dragón de la guarida
local bossFolder = workspace:WaitForChild("CureBoss")
local function animate(model)
	if not model:IsA("Model") then
		return
	end
	local kind = model:GetAttribute("DragonKind")
	local dragons = ReplicatedStorage:FindFirstChild("Dragons")
	local animatorModule = dragons and dragons:FindFirstChild("DragonAnimator")
	local animsModule = dragons and kind and dragons:FindFirstChild(kind) and dragons[kind]:FindFirstChild("Animations")
	if not animatorModule or not animsModule then
		return
	end
	local ok, err = pcall(function()
		local animator = require(animatorModule).new(model, require(animsModule))
		animator:Play(model:GetAttribute("Anim") or "Idle", 0)
		model:GetAttributeChangedSignal("AnimStamp"):Connect(function()
			animator:Play(model:GetAttribute("Anim"), model:GetAttribute("AnimFade") or 0.3)
		end)
		model.Destroying:Connect(function()
			animator:Destroy()
		end)
	end)
	if not ok then
		warn("[Cure] No pude animar al dragón: " .. tostring(err))
	end
end
for _, m in ipairs(bossFolder:GetChildren()) do
	task.spawn(animate, m)
end
bossFolder.ChildAdded:Connect(function(m)
	task.wait(0.5)
	animate(m)
end)
]=======],
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar la cura")
end)

local function v3(t)
	return Vector3.new(t[1], t[2], t[3])
end
local function material(name)
	local ok, m = pcall(function()
		return Enum.Material[name]
	end)
	return ok and m or Enum.Material.SmoothPlastic
end
local function sound(parent, name, volume, looped)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = SOUND_IDS[name] or ""
	s.Volume = volume or 0.7
	s.Looped = looped or false
	s.RollOffMaxDistance = 90
	s.Parent = parent
	return s
end
-- piezas de un modelo: la primera es el Handle; el resto, soldadas (o ancladas si anchored)
local function buildParts(list, parent, anchored)
	local handle
	for i, b in ipairs(list) do
		local p = Instance.new("Part")
		p.Name = b.name or (i == 1 and "Handle" or "Part")
		p.Size = v3(b.size)
		local cf = CFrame.new(v3(b.offset)) * CFrame.Angles(math.rad(b.rot[1]), math.rad(b.rot[2]), math.rad(b.rot[3]))
		p.CFrame = handle and handle.CFrame * cf or cf
		p.Color = Color3.fromRGB(b.color[1], b.color[2], b.color[3])
		p.Material = material(b.material)
		if b.material == "Glass" then
			p.Transparency = 0.45
		end
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CanCollide = anchored and i == 1 or false
		p.CastShadow = b.material ~= "Neon"
		p.Anchored = anchored or false
		if i == 1 then
			handle = p
		else
			p.Massless = true
			p.CanTouch, p.CanQuery = false, anchored and true or false
			if not anchored then
				local w = Instance.new("WeldConstraint")
				w.Part0, w.Part1 = handle, p
				w.Parent = p
			end
		end
		p.Parent = parent
	end
	return handle
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
	return s
end

local folder = ensure(ReplicatedStorage, "Cure")
for _, n in ipairs({ "Items", "World" }) do
	local o = folder:FindFirstChild(n)
	if o then
		o:Destroy()
	end
end
local recipeModule = putScript(folder, "Recipe", "ModuleScript", RECIPE_SRC)
putScript(folder, "CureLogic", "ModuleScript", SOURCES.Logic)
local RECIPE = require(recipeModule)
local NAMES = { Remedy = "Remedio del Alba" }
local COLORS = { Remedy = { 255, 214, 110 } }
for _, r in ipairs(RECIPE) do
	NAMES[r.id], COLORS[r.id] = r.name, r.color
end

-- ingredientes y el remedio: Tools (se cogen al tocarlos y van a la mochila)
local items = ensure(folder, "Items")
for id, list in pairs(ITEMS) do
	local t = Instance.new("Tool")
	t.Name = NAMES[id] or id
	t.CanBeDropped = true
	t.ToolTip = id == "Remedy" and "Clic para usar la cura" or "Ingrediente de la cura · échalo al caldero"
	local h = buildParts(list, t, false)
	local c = COLORS[id] or { 255, 255, 255 }
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(c[1], c[2], c[3])
	light.Range, light.Brightness = 8, 1.2
	light.Parent = h
	sound(h, "Pickup", 0.7)
	t:SetAttribute("CureItem", id)
	CollectionService:AddTag(t, id == "Remedy" and "CureRemedy" or "CureItem")
	t.Parent = items
end
-- plantas (ancladas)
local world = ensure(folder, "World")
for name, list in pairs(WORLD) do
	if name ~= "Cauldron" then
		local m = Instance.new("Model")
		m.Name = name
		m.PrimaryPart = buildParts(list, m, true)
		sound(m.PrimaryPart, "Harvest", 0.7)
		if name == "MoonflowerPlant" then
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = Color3.fromRGB(170, 210, 255), 10, 1
			l.Parent = m.PrimaryPart
		end
		m.Parent = world
	end
end
local dawn = folder:FindFirstChild("Dawn")
if dawn then
	dawn:Destroy()
end
sound(folder, "Dawn", 0.9)

local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({ BrewTime = BREW_TIME, BossDragon = BOSS_DRAGON, BossHealth = BOSS_HEALTH, BossDamage = BOSS_DAMAGE, BossRespawn = 600,
	Moonflowers = MOONFLOWERS, BloodRoots = BLOODROOTS, PlantCenter = PLANT_CENTER, PlantRadius = PLANT_RADIUS, PlantRespawn = 120 }) do
	settings:SetAttribute(k, v)
end
for _, a in ipairs({ "Done", "Total", "Stage", "Brewing", "BrewFraction", "Cured", "RemedyTaken" }) do
	folder:SetAttribute(a, nil)
end
putScript(game:GetService("ServerScriptService"), "CureService", "Script", SOURCES.Service)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "CureClient", "LocalScript", SOURCES.Client)

-- el caldero
local old = workspace:FindFirstChild("CureCauldron")
if old then
	old:Destroy()
end
local cauldron = Instance.new("Model")
cauldron.Name = "CureCauldron"
cauldron.PrimaryPart = buildParts(WORLD.Cauldron, cauldron, true)
for _, p in ipairs(cauldron:GetChildren()) do
	if p:IsA("BasePart") and p.Material == Enum.Material.Metal then
		p.CanCollide = true
	end
end
local fire = cauldron:FindFirstChild("Fire")
if fire then
	local f = Instance.new("Fire")
	f.Size, f.Heat = 3, 4
	f.Parent = fire
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 160, 80), 16, 2
	l.Parent = fire
end
local liquid = cauldron:FindFirstChild("Liquid")
sound(liquid, "Add", 0.8)
sound(liquid, "Brew", 0.6, true)
sound(liquid, "Ready", 1)
-- carteles de las peanas con el nombre de cada ingrediente
for i, r in ipairs(RECIPE) do
	local slot = cauldron:FindFirstChild("Slot" .. i)
	if slot then
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(150, 24)
		bb.StudsOffset = Vector3.new(0, 1.2, 0)
		bb.MaxDistance = 30
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.GothamBold
		l.TextScaled = true
		l.TextColor3 = Color3.fromRGB(236, 228, 210)
		l.TextStrokeTransparency = 0.3
		l.Text = r.need > 1 and ("%s ×%d"):format(r.name, r.need) or r.name
		l.Parent = bb
		bb.Parent = slot
	end
end
cauldron:PivotTo(CFrame.new(CAULDRON_POS))
CollectionService:AddTag(cauldron, "CureCauldron")
cauldron.Parent = workspace

-- la guarida: un anillo de rocas y huesos; el marcador DragonLair es donde aparece el jefe
if CREATE_LAIR then
	local oldLair = workspace:FindFirstChild("DragonLair")
	if oldLair then
		oldLair:Destroy()
	end
	local lair = Instance.new("Model")
	lair.Name = "DragonLair"
	local marker = Instance.new("Part")
	marker.Name = "Center"
	marker.Size = Vector3.new(40, 0.4, 40)
	marker.CFrame = CFrame.new(LAIR_POS + Vector3.new(0, 0.2, 0))
	marker.Anchored = true
	marker.Material = Enum.Material.Ground
	marker.Color = Color3.fromRGB(50, 42, 36)
	marker.Parent = lair
	lair.PrimaryPart = marker
	local r = Random.new(9)
	for i = 1, 16 do
		local a = i / 16 * math.pi * 2
		local rock = Instance.new("Part")
		rock.Size = Vector3.new(r:NextNumber(4, 8), r:NextNumber(4, 10), r:NextNumber(4, 7))
		rock.CFrame = CFrame.new(LAIR_POS + Vector3.new(math.cos(a) * 34, rock.Size.Y / 2 - 0.5, math.sin(a) * 34)) * CFrame.Angles(0, r:NextNumber(0, 6), r:NextNumber(-0.2, 0.2))
		rock.Anchored = true
		rock.Material = Enum.Material.Slate
		rock.Color = Color3.fromRGB(70, 66, 64)
		rock.Parent = lair
	end
	for i = 1, 10 do   -- huesos de presas
		local bone = Instance.new("Part")
		bone.Size = Vector3.new(0.5, 0.5, r:NextNumber(2, 4))
		bone.CFrame = CFrame.new(LAIR_POS + Vector3.new(r:NextNumber(-16, 16), 0.45, r:NextNumber(-16, 16))) * CFrame.Angles(0, r:NextNumber(0, 6), 0)
		bone.Anchored = true
		bone.CanCollide = false
		bone.Color = Color3.fromRGB(220, 210, 186)
		bone.Parent = lair
	end
	CollectionService:AddTag(marker, "DragonLair")
	lair.Parent = workspace
end

local dragons = ReplicatedStorage:FindFirstChild("Dragons")
local hasDragon = dragons and ((dragons:FindFirstChild(BOSS_DRAGON) and dragons[BOSS_DRAGON]:FindFirstChild(BOSS_DRAGON))
	or (dragons:FindFirstChild("PredatorDragon") and dragons.PredatorDragon:FindFirstChild("PredatorDragon"))
	or (dragons:FindFirstChild("AberrantDragon") and dragons.AberrantDragon:FindFirstChild("AberrantDragon")))
if not hasDragon then
	warn("[Cure] Aviso: no hay ningún dragón instalado (Depredador o Aberrante). Sin él no aparece el jefe y no hay saliva de dragón.")
end
Selection:Set({ cauldron })
pcall(function()
	ChangeHistoryService:SetWaypoint("Cura instalada")
end)
print("[Cure] Listo: caldero en Workspace.CureCauldron" .. (CREATE_LAIR and ", guarida en Workspace.DragonLair" or "") .. ". En Play, pulsa R o el botón «Cura» para ver la receta.")
