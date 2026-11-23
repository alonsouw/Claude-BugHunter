--[[
	INSTALADOR DE LA PESCA (caña, 3 peces comestibles, hoguera) · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	No hace falta importar nada: pega TODO este archivo en View > Command Bar y pulsa Enter.

	Resultado:
	  StarterPack.FishingRod                          (la caña: todos empiezan con ella)
	  ReplicatedStorage.Fishing                       (FishingLogic, Fish: los peces crudos y cocinados, Bobber, Settings)
	  ServerScriptService.FishingService              (lanzar, picar, recoger, comer y cocinar)
	  StarterPlayer.StarterPlayerScripts.FishingHud   (avisos en pantalla)
	  Workspace.FishingPond + Workspace.Campfires     (lago de prueba con muelle y una hoguera, si DEMO_POND)

	Se pesca en cualquier agua de Terrain y en las zonas FishZone. Hogueras: cualquier parte o modelo con la etiqueta
	Campfire (o dentro de Workspace.Campfires).
]]

local DEMO_POND = true                        -- crea un lago de prueba con muelle y hoguera
local POND_CENTER = Vector3.new(-70, 0, 0)    -- centro del fondo del lago (sobre el suelo)
local POND_SIZE, POND_DEPTH = 44, 6
local GIVE_ROD = true                         -- la caña en el StarterPack
local CAST_RANGE = 45
local RAW_SICK_CHANCE = 0.25                  -- probabilidad de que el pescado crudo siente mal
local HUNGER_ATTRIBUTE = "Hunger"             -- si tu juego usa un atributo de hambre en el jugador, cuál
-- Sonidos: sube los .ogg de sounds/ y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = { Cast = "", Plop = "", Reel = "", Catch = "", Eat = "", Sizzle = "" }

local MODELS = {
	Trout = {
		{
			name = "Handle",
			size = { 0.5, 0.62, 1.2 },
			offset = { 0, 0, 0 },
			rot = { 0, 0, 0 },
			color = { 122, 132, 104 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.52, 0.16, 1.22 },
			offset = { 0, 0.24, 0 },
			rot = { 0, 0, 0 },
			color = { 78, 96, 70 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.52, 0.18, 1.22 },
			offset = { 0, -0.23, 0 },
			rot = { 0, 0, 0 },
			color = { 226, 218, 196 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.46, 0.54, 0.5 },
			offset = { 0, 0, -0.82 },
			rot = { 0, 0, 0 },
			color = { 122, 132, 104 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.47, 0.14, 0.5 },
			offset = { 0, 0.22, -0.82 },
			rot = { 0, 0, 0 },
			color = { 78, 96, 70 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.36, 0.34, 0.24 },
			offset = { 0, -0.04, -1.18 },
			rot = { 0, 0, 0 },
			color = { 122, 132, 104 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.3, 0.04, 0.02 },
			offset = { 0, -0.13, -1.31 },
			rot = { 0, 0, 0 },
			color = { 60, 40, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.32, 0.42, 0.46 },
			offset = { 0, 0, 0.82 },
			rot = { 0, 0, 0 },
			color = { 122, 132, 104 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.33, 0.12, 0.47 },
			offset = { 0, 0.17, 0.82 },
			rot = { 0, 0, 0 },
			color = { 78, 96, 70 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.36, 0.36 },
			offset = { 0, -0.2, 1.2 },
			rot = { 22, 0, 0 },
			color = { 112, 118, 92 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.36, 0.36 },
			offset = { 0, 0.2, 1.2 },
			rot = { -22, 0, 0 },
			color = { 112, 118, 92 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.24, 0.42 },
			offset = { 0, 0.42, -0.05 },
			rot = { 12, 0, 0 },
			color = { 112, 118, 92 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.1, 0.14 },
			offset = { 0, 0.26, 0.62 },
			rot = { 0, 0, 0 },
			color = { 112, 118, 92 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.16, 0.26 },
			offset = { 0, -0.38, 0.45 },
			rot = { -15, 0, 0 },
			color = { 112, 118, 92 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.26, 0.03, 0.18 },
			offset = { 0.32, -0.16, -0.5 },
			rot = { 0, 0, -25 },
			color = { 112, 118, 92 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.26, 0.03, 0.18 },
			offset = { -0.32, -0.16, -0.5 },
			rot = { 0, 0, 25 },
			color = { 112, 118, 92 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.18, 0.03, 0.14 },
			offset = { 0.2, -0.32, 0.15 },
			rot = { 0, 0, -15 },
			color = { 112, 118, 92 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.18, 0.03, 0.14 },
			offset = { -0.2, -0.32, 0.15 },
			rot = { 0, 0, 15 },
			color = { 112, 118, 92 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.12, 1.1 },
			offset = { 0.261, 0.03, 0.05 },
			rot = { 0, 0, 0 },
			color = { 214, 128, 138 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.12, 1.1 },
			offset = { -0.261, 0.03, 0.05 },
			rot = { 0, 0, 0 },
			color = { 214, 128, 138 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.1, 0.42 },
			offset = { 0.231, 0.02, -0.82 },
			rot = { 0, 0, 0 },
			color = { 214, 128, 138 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.1, 0.42 },
			offset = { -0.231, 0.02, -0.82 },
			rot = { 0, 0, 0 },
			color = { 214, 128, 138 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, 0.16, -0.4 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, 0.16, -0.4 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, 0.12, -0.1 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, 0.12, -0.1 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, 0.18, 0.2 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, 0.18, 0.2 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, 0.1, 0.45 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, 0.1, 0.45 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, -0.02, -0.25 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, -0.02, -0.25 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, 0.2, -0.65 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, 0.2, -0.65 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, 0, 0.3 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, 0, 0.3 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.17, 0.14, 0.75 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.17, 0.14, 0.75 },
			rot = { 0, 0, 0 },
			color = { 40, 44, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.15, 0.15 },
			offset = { 0.236, 0.06, -0.88 },
			rot = { 0, 0, 0 },
			color = { 232, 222, 120 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.15, 0.15 },
			offset = { -0.236, 0.06, -0.88 },
			rot = { 0, 0, 0 },
			color = { 232, 222, 120 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.07, 0.07 },
			offset = { 0.246, 0.06, -0.89 },
			rot = { 0, 0, 0 },
			color = { 14, 12, 12 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.07, 0.07 },
			offset = { -0.246, 0.06, -0.89 },
			rot = { 0, 0, 0 },
			color = { 14, 12, 12 },
			material = "SmoothPlastic",
		},
	},
	Trout_Cooked = {
		{
			name = "Handle",
			size = { 0.5, 0.62, 1.2 },
			offset = { 0, 0, 0 },
			rot = { 0, 0, 0 },
			color = { 140, 103, 64 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.52, 0.16, 1.22 },
			offset = { 0, 0.24, 0 },
			rot = { 0, 0, 0 },
			color = { 125, 91, 52 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.52, 0.18, 1.22 },
			offset = { 0, -0.23, 0 },
			rot = { 0, 0, 0 },
			color = { 204, 156, 98 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.46, 0.54, 0.5 },
			offset = { 0, 0, -0.82 },
			rot = { 0, 0, 0 },
			color = { 140, 103, 64 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.47, 0.14, 0.5 },
			offset = { 0, 0.22, -0.82 },
			rot = { 0, 0, 0 },
			color = { 125, 91, 52 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.36, 0.34, 0.24 },
			offset = { 0, -0.04, -1.18 },
			rot = { 0, 0, 0 },
			color = { 140, 103, 64 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.3, 0.04, 0.02 },
			offset = { 0, -0.13, -1.31 },
			rot = { 0, 0, 0 },
			color = { 60, 40, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.32, 0.42, 0.46 },
			offset = { 0, 0, 0.82 },
			rot = { 0, 0, 0 },
			color = { 140, 103, 64 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.33, 0.12, 0.47 },
			offset = { 0, 0.17, 0.82 },
			rot = { 0, 0, 0 },
			color = { 125, 91, 52 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.36, 0.36 },
			offset = { 0, -0.2, 1.2 },
			rot = { 22, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.36, 0.36 },
			offset = { 0, 0.2, 1.2 },
			rot = { -22, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.24, 0.42 },
			offset = { 0, 0.42, -0.05 },
			rot = { 12, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.1, 0.14 },
			offset = { 0, 0.26, 0.62 },
			rot = { 0, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.16, 0.26 },
			offset = { 0, -0.38, 0.45 },
			rot = { -15, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.26, 0.03, 0.18 },
			offset = { 0.32, -0.16, -0.5 },
			rot = { 0, 0, -25 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.26, 0.03, 0.18 },
			offset = { -0.32, -0.16, -0.5 },
			rot = { 0, 0, 25 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.18, 0.03, 0.14 },
			offset = { 0.2, -0.32, 0.15 },
			rot = { 0, 0, -15 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.18, 0.03, 0.14 },
			offset = { -0.2, -0.32, 0.15 },
			rot = { 0, 0, 15 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.12, 1.1 },
			offset = { 0.261, 0.03, 0.05 },
			rot = { 0, 0, 0 },
			color = { 182, 105, 85 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.12, 1.1 },
			offset = { -0.261, 0.03, 0.05 },
			rot = { 0, 0, 0 },
			color = { 182, 105, 85 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.1, 0.42 },
			offset = { 0.231, 0.02, -0.82 },
			rot = { 0, 0, 0 },
			color = { 182, 105, 85 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.1, 0.42 },
			offset = { -0.231, 0.02, -0.82 },
			rot = { 0, 0, 0 },
			color = { 182, 105, 85 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, 0.16, -0.4 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, 0.16, -0.4 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, 0.12, -0.1 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, 0.12, -0.1 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, 0.18, 0.2 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, 0.18, 0.2 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, 0.1, 0.45 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, 0.1, 0.45 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, -0.02, -0.25 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, -0.02, -0.25 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, 0.2, -0.65 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, 0.2, -0.65 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.262, 0, 0.3 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.262, 0, 0.3 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { 0.17, 0.14, 0.75 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.06, 0.06 },
			offset = { -0.17, 0.14, 0.75 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.15, 0.15 },
			offset = { 0.236, 0.06, -0.88 },
			rot = { 0, 0, 0 },
			color = { 236, 232, 222 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.15, 0.15 },
			offset = { -0.236, 0.06, -0.88 },
			rot = { 0, 0, 0 },
			color = { 236, 232, 222 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.07, 0.07 },
			offset = { 0.246, 0.06, -0.89 },
			rot = { 0, 0, 0 },
			color = { 120, 114, 104 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.07, 0.07 },
			offset = { -0.246, 0.06, -0.89 },
			rot = { 0, 0, 0 },
			color = { 120, 114, 104 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.558, 0.07 },
			offset = { -0.262, 0, -0.432 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.558, 0.07 },
			offset = { 0.262, 0, -0.432 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.558, 0.07 },
			offset = { -0.262, 0, -0.144 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.558, 0.07 },
			offset = { 0.262, 0, -0.144 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.558, 0.07 },
			offset = { -0.262, 0, 0.144 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.558, 0.07 },
			offset = { 0.262, 0, 0.144 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.558, 0.07 },
			offset = { -0.262, 0, 0.432 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.558, 0.07 },
			offset = { 0.262, 0, 0.432 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
	},
	Perch = {
		{
			name = "Handle",
			size = { 0.46, 0.72, 1.1 },
			offset = { 0, 0, 0 },
			rot = { 0, 0, 0 },
			color = { 156, 162, 74 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.48, 0.18, 1.12 },
			offset = { 0, 0.29, 0 },
			rot = { 0, 0, 0 },
			color = { 92, 104, 46 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.48, 0.2, 1.12 },
			offset = { 0, -0.28, 0 },
			rot = { 0, 0, 0 },
			color = { 230, 222, 170 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.42, 0.58, 0.44 },
			offset = { 0, -0.02, -0.76 },
			rot = { 0, 0, 0 },
			color = { 156, 162, 74 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.43, 0.15, 0.45 },
			offset = { 0, 0.22, -0.76 },
			rot = { 0, 0, 0 },
			color = { 92, 104, 46 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.32, 0.32, 0.2 },
			offset = { 0, -0.08, -1.06 },
			rot = { 0, 0, 0 },
			color = { 156, 162, 74 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.28, 0.04, 0.02 },
			offset = { 0, -0.16, -1.17 },
			rot = { 0, 0, 0 },
			color = { 60, 40, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.28, 0.4, 0.4 },
			offset = { 0, -0.02, 0.74 },
			rot = { 0, 0, 0 },
			color = { 156, 162, 74 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.34, 0.32 },
			offset = { 0, -0.19, 1.06 },
			rot = { 20, 0, 0 },
			color = { 130, 128, 70 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.34, 0.32 },
			offset = { 0, 0.19, 1.06 },
			rot = { -20, 0, 0 },
			color = { 130, 128, 70 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.24, 0.04 },
			offset = { 0, 0.5, -0.42 },
			rot = { 15, 0, 0 },
			color = { 60, 60, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.28, 0.04 },
			offset = { 0, 0.5, -0.3 },
			rot = { 15, 0, 0 },
			color = { 60, 60, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.28, 0.04 },
			offset = { 0, 0.5, -0.18 },
			rot = { 15, 0, 0 },
			color = { 60, 60, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.24, 0.04 },
			offset = { 0, 0.5, -0.06 },
			rot = { 15, 0, 0 },
			color = { 60, 60, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.2, 0.04 },
			offset = { 0, 0.5, 0.06 },
			rot = { 15, 0, 0 },
			color = { 60, 60, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.03, 0.2, 0.5 },
			offset = { 0, 0.46, -0.18 },
			rot = { 8, 0, 0 },
			color = { 176, 150, 80 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.2, 0.32 },
			offset = { 0, 0.46, 0.35 },
			rot = { 10, 0, 0 },
			color = { 130, 128, 70 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.2, 0.26 },
			offset = { 0, -0.44, 0.36 },
			rot = { -15, 0, 0 },
			color = { 222, 96, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.2, 0.03, 0.2 },
			offset = { 0.18, -0.4, -0.3 },
			rot = { 0, 0, -30 },
			color = { 222, 96, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.2, 0.03, 0.2 },
			offset = { -0.18, -0.4, -0.3 },
			rot = { 0, 0, 30 },
			color = { 222, 96, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.24, 0.03, 0.16 },
			offset = { 0.3, -0.12, -0.45 },
			rot = { 0, 0, -25 },
			color = { 130, 128, 70 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.24, 0.03, 0.16 },
			offset = { -0.3, -0.12, -0.45 },
			rot = { 0, 0, 25 },
			color = { 130, 128, 70 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.36, 0.1 },
			offset = { 0.241, 0.08, -0.4 },
			rot = { 0, 0, 0 },
			color = { 52, 62, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.36, 0.1 },
			offset = { -0.241, 0.08, -0.4 },
			rot = { 0, 0, 0 },
			color = { 52, 62, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.42, 0.1 },
			offset = { 0.241, 0.08, -0.18 },
			rot = { 0, 0, 0 },
			color = { 52, 62, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.42, 0.1 },
			offset = { -0.241, 0.08, -0.18 },
			rot = { 0, 0, 0 },
			color = { 52, 62, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.48, 0.1 },
			offset = { 0.241, 0.08, 0.04 },
			rot = { 0, 0, 0 },
			color = { 52, 62, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.48, 0.1 },
			offset = { -0.241, 0.08, 0.04 },
			rot = { 0, 0, 0 },
			color = { 52, 62, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.42, 0.1 },
			offset = { 0.241, 0.08, 0.26 },
			rot = { 0, 0, 0 },
			color = { 52, 62, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.42, 0.1 },
			offset = { -0.241, 0.08, 0.26 },
			rot = { 0, 0, 0 },
			color = { 52, 62, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.36, 0.1 },
			offset = { 0.241, 0.08, 0.48 },
			rot = { 0, 0, 0 },
			color = { 52, 62, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.36, 0.1 },
			offset = { -0.241, 0.08, 0.48 },
			rot = { 0, 0, 0 },
			color = { 52, 62, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.17, 0.17 },
			offset = { 0.216, 0.06, -0.82 },
			rot = { 0, 0, 0 },
			color = { 240, 170, 50 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.17, 0.17 },
			offset = { -0.216, 0.06, -0.82 },
			rot = { 0, 0, 0 },
			color = { 240, 170, 50 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.08, 0.08 },
			offset = { 0.226, 0.06, -0.83 },
			rot = { 0, 0, 0 },
			color = { 14, 12, 12 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.08, 0.08 },
			offset = { -0.226, 0.06, -0.83 },
			rot = { 0, 0, 0 },
			color = { 14, 12, 12 },
			material = "SmoothPlastic",
		},
	},
	Perch_Cooked = {
		{
			name = "Handle",
			size = { 0.46, 0.72, 1.1 },
			offset = { 0, 0, 0 },
			rot = { 0, 0, 0 },
			color = { 152, 114, 53 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.48, 0.18, 1.12 },
			offset = { 0, 0.29, 0 },
			rot = { 0, 0, 0 },
			color = { 130, 94, 43 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.48, 0.2, 1.12 },
			offset = { 0, -0.28, 0 },
			rot = { 0, 0, 0 },
			color = { 204, 156, 98 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.42, 0.58, 0.44 },
			offset = { 0, -0.02, -0.76 },
			rot = { 0, 0, 0 },
			color = { 152, 114, 53 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.43, 0.15, 0.45 },
			offset = { 0, 0.22, -0.76 },
			rot = { 0, 0, 0 },
			color = { 130, 94, 43 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.32, 0.32, 0.2 },
			offset = { 0, -0.08, -1.06 },
			rot = { 0, 0, 0 },
			color = { 152, 114, 53 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.28, 0.04, 0.02 },
			offset = { 0, -0.16, -1.17 },
			rot = { 0, 0, 0 },
			color = { 60, 40, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.28, 0.4, 0.4 },
			offset = { 0, -0.02, 0.74 },
			rot = { 0, 0, 0 },
			color = { 152, 114, 53 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.34, 0.32 },
			offset = { 0, -0.19, 1.06 },
			rot = { 20, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.34, 0.32 },
			offset = { 0, 0.19, 1.06 },
			rot = { -20, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.24, 0.04 },
			offset = { 0, 0.5, -0.42 },
			rot = { 15, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.28, 0.04 },
			offset = { 0, 0.5, -0.3 },
			rot = { 15, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.28, 0.04 },
			offset = { 0, 0.5, -0.18 },
			rot = { 15, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.24, 0.04 },
			offset = { 0, 0.5, -0.06 },
			rot = { 15, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.2, 0.04 },
			offset = { 0, 0.5, 0.06 },
			rot = { 15, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.03, 0.2, 0.5 },
			offset = { 0, 0.46, -0.18 },
			rot = { 8, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.2, 0.32 },
			offset = { 0, 0.46, 0.35 },
			rot = { 10, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.2, 0.26 },
			offset = { 0, -0.44, 0.36 },
			rot = { -15, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.2, 0.03, 0.2 },
			offset = { 0.18, -0.4, -0.3 },
			rot = { 0, 0, -30 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.2, 0.03, 0.2 },
			offset = { -0.18, -0.4, -0.3 },
			rot = { 0, 0, 30 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.24, 0.03, 0.16 },
			offset = { 0.3, -0.12, -0.45 },
			rot = { 0, 0, -25 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.24, 0.03, 0.16 },
			offset = { -0.3, -0.12, -0.45 },
			rot = { 0, 0, 25 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.36, 0.1 },
			offset = { 0.241, 0.08, -0.4 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.36, 0.1 },
			offset = { -0.241, 0.08, -0.4 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.42, 0.1 },
			offset = { 0.241, 0.08, -0.18 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.42, 0.1 },
			offset = { -0.241, 0.08, -0.18 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.48, 0.1 },
			offset = { 0.241, 0.08, 0.04 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.48, 0.1 },
			offset = { -0.241, 0.08, 0.04 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.42, 0.1 },
			offset = { 0.241, 0.08, 0.26 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.42, 0.1 },
			offset = { -0.241, 0.08, 0.26 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.36, 0.1 },
			offset = { 0.241, 0.08, 0.48 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.36, 0.1 },
			offset = { -0.241, 0.08, 0.48 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.17, 0.17 },
			offset = { 0.216, 0.06, -0.82 },
			rot = { 0, 0, 0 },
			color = { 236, 232, 222 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.17, 0.17 },
			offset = { -0.216, 0.06, -0.82 },
			rot = { 0, 0, 0 },
			color = { 236, 232, 222 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.08, 0.08 },
			offset = { 0.226, 0.06, -0.83 },
			rot = { 0, 0, 0 },
			color = { 120, 114, 104 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.08, 0.08 },
			offset = { -0.226, 0.06, -0.83 },
			rot = { 0, 0, 0 },
			color = { 120, 114, 104 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.648, 0.07 },
			offset = { -0.242, 0, -0.396 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.648, 0.07 },
			offset = { 0.242, 0, -0.396 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.648, 0.07 },
			offset = { -0.242, 0, -0.132 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.648, 0.07 },
			offset = { 0.242, 0, -0.132 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.648, 0.07 },
			offset = { -0.242, 0, 0.132 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.648, 0.07 },
			offset = { 0.242, 0, 0.132 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.648, 0.07 },
			offset = { -0.242, 0, 0.396 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.648, 0.07 },
			offset = { 0.242, 0, 0.396 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
	},
	GoldenSalmon = {
		{
			name = "Handle",
			size = { 0.56, 0.66, 1.5 },
			offset = { 0, 0, 0 },
			rot = { 0, 0, 0 },
			color = { 226, 172, 62 },
			material = "Foil",
		},
		{
			size = { 0.58, 0.16, 1.52 },
			offset = { 0, 0.26, 0 },
			rot = { 0, 0, 0 },
			color = { 176, 116, 36 },
			material = "Foil",
		},
		{
			size = { 0.58, 0.18, 1.52 },
			offset = { 0, -0.25, 0 },
			rot = { 0, 0, 0 },
			color = { 250, 232, 186 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.5, 0.56, 0.56 },
			offset = { 0, 0, -1.02 },
			rot = { 0, 0, 0 },
			color = { 226, 172, 62 },
			material = "Foil",
		},
		{
			size = { 0.51, 0.14, 0.57 },
			offset = { 0, 0.22, -1.02 },
			rot = { 0, 0, 0 },
			color = { 176, 116, 36 },
			material = "Foil",
		},
		{
			size = { 0.4, 0.3, 0.3 },
			offset = { 0, -0.04, -1.42 },
			rot = { 0, 0, 0 },
			color = { 226, 172, 62 },
			material = "Foil",
		},
		{
			size = { 0.34, 0.12, 0.12 },
			offset = { 0, -0.2, -1.55 },
			rot = { -25, 0, 0 },
			color = { 226, 172, 62 },
			material = "Foil",
		},
		{
			size = { 0.32, 0.04, 0.02 },
			offset = { 0, -0.13, -1.58 },
			rot = { 0, 0, 0 },
			color = { 70, 36, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.34, 0.44, 0.5 },
			offset = { 0, 0, 1 },
			rot = { 0, 0, 0 },
			color = { 226, 172, 62 },
			material = "Foil",
		},
		{
			size = { 0.05, 0.44, 0.42 },
			offset = { 0, -0.24, 1.42 },
			rot = { 26, 0, 0 },
			color = { 206, 92, 66 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.44, 0.42 },
			offset = { 0, 0.24, 1.42 },
			rot = { -26, 0, 0 },
			color = { 206, 92, 66 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.3, 0.5 },
			offset = { 0, 0.46, -0.1 },
			rot = { 14, 0, 0 },
			color = { 206, 92, 66 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.12, 0.16 },
			offset = { 0, 0.28, 0.78 },
			rot = { 0, 0, 0 },
			color = { 206, 92, 66 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.18, 0.3 },
			offset = { 0, -0.4, 0.58 },
			rot = { -15, 0, 0 },
			color = { 206, 92, 66 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.3, 0.03, 0.2 },
			offset = { 0.36, -0.16, -0.62 },
			rot = { 0, 0, -25 },
			color = { 206, 92, 66 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.3, 0.03, 0.2 },
			offset = { -0.36, -0.16, -0.62 },
			rot = { 0, 0, 25 },
			color = { 206, 92, 66 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.2, 0.03, 0.16 },
			offset = { 0.24, -0.33, 0.2 },
			rot = { 0, 0, -15 },
			color = { 206, 92, 66 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.2, 0.03, 0.16 },
			offset = { -0.24, -0.33, 0.2 },
			rot = { 0, 0, 15 },
			color = { 206, 92, 66 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.14, 1.36 },
			offset = { 0.291, 0, 0.05 },
			rot = { 0, 0, 0 },
			color = { 240, 140, 108 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.14, 1.36 },
			offset = { -0.291, 0, 0.05 },
			rot = { 0, 0, 0 },
			color = { 240, 140, 108 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { 0.292, 0.18, -0.5 },
			rot = { 0, 0, 0 },
			color = { 255, 236, 150 },
			material = "Neon",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { -0.292, 0.18, -0.5 },
			rot = { 0, 0, 0 },
			color = { 255, 236, 150 },
			material = "Neon",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { 0.292, 0.2, 0 },
			rot = { 0, 0, 0 },
			color = { 255, 236, 150 },
			material = "Neon",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { -0.292, 0.2, 0 },
			rot = { 0, 0, 0 },
			color = { 255, 236, 150 },
			material = "Neon",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { 0.292, 0.15, 0.4 },
			rot = { 0, 0, 0 },
			color = { 255, 236, 150 },
			material = "Neon",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { -0.292, 0.15, 0.4 },
			rot = { 0, 0, 0 },
			color = { 255, 236, 150 },
			material = "Neon",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { 0.292, 0.2, 0.75 },
			rot = { 0, 0, 0 },
			color = { 255, 236, 150 },
			material = "Neon",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { -0.292, 0.2, 0.75 },
			rot = { 0, 0, 0 },
			color = { 255, 236, 150 },
			material = "Neon",
		},
		{
			size = { 0.02, 0.16, 0.16 },
			offset = { 0.256, 0.06, -1.08 },
			rot = { 0, 0, 0 },
			color = { 250, 230, 150 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.16, 0.16 },
			offset = { -0.256, 0.06, -1.08 },
			rot = { 0, 0, 0 },
			color = { 250, 230, 150 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.08, 0.08 },
			offset = { 0.266, 0.06, -1.09 },
			rot = { 0, 0, 0 },
			color = { 14, 12, 12 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.08, 0.08 },
			offset = { -0.266, 0.06, -1.09 },
			rot = { 0, 0, 0 },
			color = { 14, 12, 12 },
			material = "SmoothPlastic",
		},
	},
	GoldenSalmon_Cooked = {
		{
			name = "Handle",
			size = { 0.56, 0.66, 1.5 },
			offset = { 0, 0, 0 },
			rot = { 0, 0, 0 },
			color = { 177, 117, 49 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.58, 0.16, 1.52 },
			offset = { 0, 0.26, 0 },
			rot = { 0, 0, 0 },
			color = { 159, 98, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.58, 0.18, 1.52 },
			offset = { 0, -0.25, 0 },
			rot = { 0, 0, 0 },
			color = { 204, 156, 98 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.5, 0.56, 0.56 },
			offset = { 0, 0, -1.02 },
			rot = { 0, 0, 0 },
			color = { 177, 117, 49 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.51, 0.14, 0.57 },
			offset = { 0, 0.22, -1.02 },
			rot = { 0, 0, 0 },
			color = { 159, 98, 40 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.4, 0.3, 0.3 },
			offset = { 0, -0.04, -1.42 },
			rot = { 0, 0, 0 },
			color = { 177, 117, 49 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.34, 0.12, 0.12 },
			offset = { 0, -0.2, -1.55 },
			rot = { -25, 0, 0 },
			color = { 177, 117, 49 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.32, 0.04, 0.02 },
			offset = { 0, -0.13, -1.58 },
			rot = { 0, 0, 0 },
			color = { 70, 36, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.34, 0.44, 0.5 },
			offset = { 0, 0, 1 },
			rot = { 0, 0, 0 },
			color = { 177, 117, 49 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.44, 0.42 },
			offset = { 0, -0.24, 1.42 },
			rot = { 26, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.44, 0.42 },
			offset = { 0, 0.24, 1.42 },
			rot = { -26, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.3, 0.5 },
			offset = { 0, 0.46, -0.1 },
			rot = { 14, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.12, 0.16 },
			offset = { 0, 0.28, 0.78 },
			rot = { 0, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.05, 0.18, 0.3 },
			offset = { 0, -0.4, 0.58 },
			rot = { -15, 0, 0 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.3, 0.03, 0.2 },
			offset = { 0.36, -0.16, -0.62 },
			rot = { 0, 0, -25 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.3, 0.03, 0.2 },
			offset = { -0.36, -0.16, -0.62 },
			rot = { 0, 0, 25 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.2, 0.03, 0.16 },
			offset = { 0.24, -0.33, 0.2 },
			rot = { 0, 0, -15 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.2, 0.03, 0.16 },
			offset = { -0.24, -0.33, 0.2 },
			rot = { 0, 0, 15 },
			color = { 66, 42, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.14, 1.36 },
			offset = { 0.291, 0, 0.05 },
			rot = { 0, 0, 0 },
			color = { 192, 110, 73 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.14, 1.36 },
			offset = { -0.291, 0, 0.05 },
			rot = { 0, 0, 0 },
			color = { 192, 110, 73 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { 0.292, 0.18, -0.5 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { -0.292, 0.18, -0.5 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { 0.292, 0.2, 0 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { -0.292, 0.2, 0 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { 0.292, 0.15, 0.4 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { -0.292, 0.15, 0.4 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { 0.292, 0.2, 0.75 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.05, 0.05 },
			offset = { -0.292, 0.2, 0.75 },
			rot = { 0, 0, 0 },
			color = { 70, 44, 26 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.16, 0.16 },
			offset = { 0.256, 0.06, -1.08 },
			rot = { 0, 0, 0 },
			color = { 236, 232, 222 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.16, 0.16 },
			offset = { -0.256, 0.06, -1.08 },
			rot = { 0, 0, 0 },
			color = { 236, 232, 222 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.08, 0.08 },
			offset = { 0.266, 0.06, -1.09 },
			rot = { 0, 0, 0 },
			color = { 120, 114, 104 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.08, 0.08 },
			offset = { -0.266, 0.06, -1.09 },
			rot = { 0, 0, 0 },
			color = { 120, 114, 104 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.594, 0.07 },
			offset = { -0.292, 0, -0.54 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.594, 0.07 },
			offset = { 0.292, 0, -0.54 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.594, 0.07 },
			offset = { -0.292, 0, -0.18 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.594, 0.07 },
			offset = { 0.292, 0, -0.18 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.594, 0.07 },
			offset = { -0.292, 0, 0.18 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.594, 0.07 },
			offset = { 0.292, 0, 0.18 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.594, 0.07 },
			offset = { -0.292, 0, 0.54 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.02, 0.594, 0.07 },
			offset = { 0.292, 0, 0.54 },
			rot = { -30, 0, 0 },
			color = { 40, 24, 14 },
			material = "SmoothPlastic",
		},
	},
	FishingRod = {
		{
			name = "Handle",
			size = { 0.28, 0.28, 1.3 },
			offset = { 0, 0, 0 },
			rot = { 0, 0, 0 },
			color = { 196, 156, 104 },
			material = "Wood",
		},
		{
			size = { 0.32, 0.32, 0.14 },
			offset = { 0, 0, 0.7 },
			rot = { 0, 0, 0 },
			color = { 26, 26, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.32, 0.32, 0.12 },
			offset = { 0, 0, -0.68 },
			rot = { 0, 0, 0 },
			color = { 26, 26, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.08, 0.18, 0.08 },
			offset = { 0, -0.22, -0.2 },
			rot = { 0, 0, 0 },
			color = { 150, 150, 156 },
			material = "Metal",
		},
		{
			size = { 0.36, 0.36, 0.22 },
			offset = { 0, -0.42, -0.2 },
			rot = { 0, 0, 0 },
			color = { 150, 150, 156 },
			material = "Metal",
		},
		{
			size = { 0.38, 0.12, 0.12 },
			offset = { 0, -0.42, -0.2 },
			rot = { 0, 0, 0 },
			color = { 210, 170, 70 },
			material = "Metal",
		},
		{
			size = { 0.04, 0.24, 0.04 },
			offset = { 0.24, -0.5, -0.2 },
			rot = { 0, 0, 0 },
			color = { 26, 26, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.08, 0.08, 0.12 },
			offset = { 0.26, -0.62, -0.2 },
			rot = { 0, 0, 0 },
			color = { 26, 26, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.13, 0.13, 1 },
			offset = { 0, 0.1726, -1.2279 },
			rot = { 8, 0, 0 },
			color = { 26, 26, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.03, 0.12, 0.03 },
			offset = { 0, 0.0576, -1.2279 },
			rot = { 0, 0, 0 },
			color = { 150, 150, 156 },
			material = "Metal",
		},
		{
			size = { 0.114, 0.114, 1 },
			offset = { 0, 0.3117, -2.2182 },
			rot = { 8, 0, 0 },
			color = { 26, 26, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.154, 0.154, 0.06 },
			offset = { 0, 0.3813, -2.7133 },
			rot = { 8, 0, 0 },
			color = { 210, 170, 70 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.03, 0.12, 0.03 },
			offset = { 0, 0.2047, -2.2182 },
			rot = { 0, 0, 0 },
			color = { 150, 150, 156 },
			material = "Metal",
		},
		{
			size = { 0.098, 0.098, 1 },
			offset = { 0, 0.4509, -3.2085 },
			rot = { 8, 0, 0 },
			color = { 26, 26, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.03, 0.12, 0.03 },
			offset = { 0, 0.3519, -3.2085 },
			rot = { 0, 0, 0 },
			color = { 150, 150, 156 },
			material = "Metal",
		},
		{
			size = { 0.082, 0.082, 1 },
			offset = { 0, 0.5901, -4.1987 },
			rot = { 8, 0, 0 },
			color = { 26, 26, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.122, 0.122, 0.06 },
			offset = { 0, 0.6597, -4.6939 },
			rot = { 8, 0, 0 },
			color = { 210, 170, 70 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.03, 0.12, 0.03 },
			offset = { 0, 0.4991, -4.1987 },
			rot = { 0, 0, 0 },
			color = { 150, 150, 156 },
			material = "Metal",
		},
		{
			size = { 0.066, 0.066, 1 },
			offset = { 0, 0.7293, -5.189 },
			rot = { 8, 0, 0 },
			color = { 26, 26, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.03, 0.12, 0.03 },
			offset = { 0, 0.6463, -5.189 },
			rot = { 0, 0, 0 },
			color = { 150, 150, 156 },
			material = "Metal",
		},
		{
			name = "Tip",
			size = { 0.05, 0.05, 1 },
			offset = { 0, 0.8684, -6.1793 },
			rot = { 8, 0, 0 },
			color = { 26, 26, 30 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.09, 0.09, 0.06 },
			offset = { 0, 0.938, -6.6744 },
			rot = { 8, 0, 0 },
			color = { 210, 170, 70 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.03, 0.12, 0.03 },
			offset = { 0, 0.7934, -6.1793 },
			rot = { 0, 0, 0 },
			color = { 150, 150, 156 },
			material = "Metal",
		},
	},
	Bobber = {
		{
			name = "Handle",
			size = { 0.3, 0.16, 0.3 },
			offset = { 0, 0.07, 0 },
			rot = { 0, 0, 0 },
			color = { 220, 40, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.3, 0.14, 0.3 },
			offset = { 0, -0.08, 0 },
			rot = { 0, 0, 0 },
			color = { 240, 240, 236 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.06, 0.18, 0.06 },
			offset = { 0, 0.24, 0 },
			rot = { 0, 0, 0 },
			color = { 220, 40, 36 },
			material = "SmoothPlastic",
		},
		{
			size = { 0.04, 0.1, 0.04 },
			offset = { 0, -0.2, 0 },
			rot = { 0, 0, 0 },
			color = { 30, 30, 30 },
			material = "SmoothPlastic",
		},
	},
	Campfire = {
		{
			name = "Handle",
			size = { 2.6, 0.2, 2.6 },
			offset = { 0, 0.1, 0 },
			rot = { 0, 0, 0 },
			color = { 40, 34, 30 },
			material = "Slate",
		},
		{
			size = { 0.35, 0.35, 2.2 },
			offset = { 0, 0.42, 0 },
			rot = { -18, 0, 0 },
			color = { 92, 62, 40 },
			material = "Wood",
		},
		{
			size = { 0.35, 0.35, 2.2 },
			offset = { 0, 0.42, 0 },
			rot = { 18, 45, 0 },
			color = { 92, 62, 40 },
			material = "Wood",
		},
		{
			size = { 0.35, 0.35, 2.2 },
			offset = { 0, 0.42, 0 },
			rot = { -18, 90, 0 },
			color = { 92, 62, 40 },
			material = "Wood",
		},
		{
			size = { 0.35, 0.35, 2.2 },
			offset = { 0, 0.42, 0 },
			rot = { 18, 135, 0 },
			color = { 92, 62, 40 },
			material = "Wood",
		},
		{
			size = { 0.6, 0.4, 0.45 },
			offset = { 1.35, 0.25, 0 },
			rot = { 0, 0, 0 },
			color = { 110, 108, 104 },
			material = "Slate",
		},
		{
			size = { 0.6, 0.4, 0.45 },
			offset = { 1.0342, 0.25, 0.8678 },
			rot = { 0, -40, 0 },
			color = { 110, 108, 104 },
			material = "Slate",
		},
		{
			size = { 0.6, 0.4, 0.45 },
			offset = { 0.2344, 0.25, 1.3295 },
			rot = { 0, -80, 0 },
			color = { 110, 108, 104 },
			material = "Slate",
		},
		{
			size = { 0.6, 0.4, 0.45 },
			offset = { -0.675, 0.25, 1.1691 },
			rot = { 0, -120, 0 },
			color = { 110, 108, 104 },
			material = "Slate",
		},
		{
			size = { 0.6, 0.4, 0.45 },
			offset = { -1.2686, 0.25, 0.4617 },
			rot = { 0, -160, 0 },
			color = { 110, 108, 104 },
			material = "Slate",
		},
		{
			size = { 0.6, 0.4, 0.45 },
			offset = { -1.2686, 0.25, -0.4617 },
			rot = { 0, -200, 0 },
			color = { 110, 108, 104 },
			material = "Slate",
		},
		{
			size = { 0.6, 0.4, 0.45 },
			offset = { -0.675, 0.25, -1.1691 },
			rot = { 0, -240, 0 },
			color = { 110, 108, 104 },
			material = "Slate",
		},
		{
			size = { 0.6, 0.4, 0.45 },
			offset = { 0.2344, 0.25, -1.3295 },
			rot = { 0, -280, 0 },
			color = { 110, 108, 104 },
			material = "Slate",
		},
		{
			size = { 0.6, 0.4, 0.45 },
			offset = { 1.0342, 0.25, -0.8678 },
			rot = { 0, -320, 0 },
			color = { 110, 108, 104 },
			material = "Slate",
		},
		{
			size = { 0.7, 0.9, 0.7 },
			offset = { 0, 0.85, 0 },
			rot = { 0, 20, 0 },
			color = { 255, 120, 30 },
			material = "Neon",
		},
		{
			size = { 0.4, 1.3, 0.4 },
			offset = { 0.1, 1, 0.05 },
			rot = { 0, 50, 8 },
			color = { 255, 190, 60 },
			material = "Neon",
		},
		{
			size = { 0.3, 0.8, 0.3 },
			offset = { -0.25, 0.8, -0.1 },
			rot = { 0, 10, -10 },
			color = { 255, 90, 20 },
			material = "Neon",
		},
	},
}
local SPECIES = {
	Trout = {
		DisplayName = "Trucha",
		Weight = 60,
		Drain = 14,
		Raw = {
			Heal = 8,
			Food = 15,
		},
		Cooked = {
			Heal = 25,
			Food = 35,
		},
	},
	Perch = {
		DisplayName = "Perca",
		Weight = 30,
		Drain = 18,
		Raw = {
			Heal = 6,
			Food = 12,
		},
		Cooked = {
			Heal = 20,
			Food = 30,
		},
	},
	GoldenSalmon = {
		DisplayName = "Salmón dorado",
		Weight = 10,
		Drain = 26,
		Raw = {
			Heal = 15,
			Food = 25,
		},
		Cooked = {
			Heal = 50,
			Food = 60,
		},
	},
}
local SOURCES = {
	Logic = [=======[
--[[
	FishingLogic (ModuleScript) · ReplicatedStorage.Fishing.FishingLogic

	La pesca de un jugador como máquina de estados pura (sin Instances: se prueba fuera de Roblox).
	FishingService la usa para cada jugador que pesca y aplica los eventos que devuelve.

	Idle → (Cast) → Casting → Waiting → (pica) → Bite → (Hook a tiempo) → Reeling → (barra llena) → Caught
	  · clic antes de que pique (Hook en Waiting): espanta al pez → "escaped", "early"
	  · no hacer clic durante la picada: → "escaped", "late"
	  · recogiendo, el pez vacía la barra (Drain por segundo, según la especie); cada clic (Reel) la llena ReelPower;
	    si se vacía → "escaped", "lost"; si pasa MaxReel segundos → "escaped", "tired"

	Eventos: {"state", nombre} · {"bite", especie} · {"progress", 0-100} · {"caught", especie} · {"escaped", motivo}
]]

local Logic = {}
Logic.__index = Logic

Logic.Defaults = {
	CastTime = 0.6,
	WaitTime = { 4, 12 },
	BiteWindow = 1.3,
	ReelStart = 30,
	ReelPower = 9,
	MinClick = 0.07,   -- clics más seguidos que esto no cuentan (autoclickers)
	MaxReel = 15,
	-- especies: { nombre, peso, Drain }
	Species = { { "Trout", 60, 14 }, { "Perch", 30, 18 }, { "GoldenSalmon", 10, 26 } },
}

function Logic.new(config, rng)
	local self = setmetatable({}, Logic)
	self.cfg = setmetatable(config or {}, { __index = Logic.Defaults })
	self.rng = rng or Random.new()
	self.state = "Idle"
	self.last = 0
	return self
end

function Logic:roll()
	local total = 0
	for _, s in ipairs(self.cfg.Species) do
		total += s[2]
	end
	local x = self.rng:NextNumber() * total
	for _, s in ipairs(self.cfg.Species) do
		x -= s[2]
		if x <= 0 then
			return s[1], s[3]
		end
	end
	local s = self.cfg.Species[#self.cfg.Species]
	return s[1], s[3]
end

function Logic:set(state, out)
	self.state = state
	table.insert(out, { "state", state })
end

function Logic:Cast(now: number)
	local out = {}
	if self.state ~= "Idle" then
		return out
	end
	self.tEnd = now + self.cfg.CastTime
	self.last = now
	self:set("Casting", out)
	return out
end

function Logic:Hook(now: number)
	local out = {}
	if self.state == "Bite" then
		self.progress = self.cfg.ReelStart
		self.reelStart = now
		self.lastClick = -math.huge
		self.last = now
		self:set("Reeling", out)
		table.insert(out, { "progress", self.progress })
	elseif self.state == "Waiting" or self.state == "Casting" then
		table.insert(out, { "escaped", "early" })
		self:set("Idle", out)
	end
	return out
end

function Logic:Reel(now: number)
	local out = {}
	if self.state ~= "Reeling" then
		return out
	end
	for _, e in ipairs(self:Update(now)) do   -- primero lo que ha tirado el pez hasta ahora
		table.insert(out, e)
	end
	if self.state ~= "Reeling" or now - self.lastClick < self.cfg.MinClick then
		return out
	end
	self.lastClick = now
	self.progress = math.min(100, self.progress + self.cfg.ReelPower)
	table.insert(out, { "progress", self.progress })
	if self.progress >= 100 then
		table.insert(out, { "caught", self.species })
		self:set("Idle", out)
	end
	return out
end

function Logic:Cancel()
	local out = {}
	if self.state ~= "Idle" then
		self:set("Idle", out)
	end
	return out
end

function Logic:Update(now: number)
	local out = {}
	local dt = math.max(0, now - self.last)
	self.last = now
	local s = self.state
	if s == "Casting" and now >= self.tEnd then
		local w = self.cfg.WaitTime
		self.biteAt = now + w[1] + (w[2] - w[1]) * self.rng:NextNumber()
		self:set("Waiting", out)
	elseif s == "Waiting" and now >= self.biteAt then
		self.species, self.drain = self:roll()
		self.tEnd = now + self.cfg.BiteWindow
		table.insert(out, { "bite", self.species })
		self:set("Bite", out)
	elseif s == "Bite" and now >= self.tEnd then
		table.insert(out, { "escaped", "late" })
		self:set("Idle", out)
	elseif s == "Reeling" then
		self.progress -= self.drain * dt
		if self.progress <= 0 then
			self.progress = 0
			table.insert(out, { "escaped", "lost" })
			self:set("Idle", out)
		elseif now - self.reelStart > self.cfg.MaxReel then
			table.insert(out, { "escaped", "tired" })
			self:set("Idle", out)
		end
	end
	return out
end

return Logic
]=======],
	Service = [=======[
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
]=======],
	RodClient = [=======[
--[[
	FishingRodClient (LocalScript) · dentro del Tool FishingRod

	Lo que ve y hace el jugador con la caña en la mano:
	  · clic en el agua: lanza (manda el punto al servidor; FishingService comprueba que es agua y que está cerca)
	  · clic mientras pica: clava el anzuelo · clic mientras recoges: recoge (clic rápido)
	  · interfaz: un mensaje con lo que pasa y la barra para recoger (los avisos los muestra FishingHud)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local tool = script.Parent
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Fishing"):WaitForChild("Remote")
local mouse = player:GetMouse()

local state = "Idle"
local gui, msg, bar, fill

local MESSAGES = {
	Idle = "Haz clic en el agua para lanzar",
	Casting = "",
	Waiting = "Espera a que pique...",
	Bite = "¡PICA! ¡HAZ CLIC!",
	Reeling = "¡RECOGE! · CLIC RÁPIDO",
}

local function makeGui()
	gui = Instance.new("ScreenGui")
	gui.Name = "FishingGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -110)
	frame.Size = UDim2.fromOffset(360, 74)
	frame.BackgroundTransparency = 1
	frame.Parent = gui
	msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, 0, 0, 30)
	msg.BackgroundTransparency = 1
	msg.Font = Enum.Font.GothamBold
	msg.TextSize = 22
	msg.TextColor3 = Color3.fromRGB(245, 235, 210)
	msg.TextStrokeTransparency = 0.3
	msg.Parent = frame
	bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(20, 38)
	bar.Size = UDim2.new(1, -40, 0, 18)
	bar.BackgroundColor3 = Color3.fromRGB(18, 26, 30)
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 84, 90)
	stroke.Parent = bar
	fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0.3, 1)
	fill.BackgroundColor3 = Color3.fromRGB(130, 200, 100)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	gui.Parent = player:WaitForChild("PlayerGui")
end

local function refresh()
	if not gui then
		return
	end
	msg.Text = MESSAGES[state] or ""
	msg.TextColor3 = state == "Bite" and Color3.fromRGB(255, 90, 70) or Color3.fromRGB(245, 235, 210)
	msg.TextSize = state == "Bite" and 28 or 22
	bar.Visible = state == "Reeling"
end

local function aimPoint()
	local cam = workspace.CurrentCamera
	if not cam then
		return nil
	end
	local ray = cam:ViewportPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	params.IgnoreWater = false   -- el agua de Terrain cuenta como blanco
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 400, params)
	return hit and hit.Position or nil
end

tool.Equipped:Connect(function()
	if not gui then
		makeGui()
	end
	state = "Idle"
	refresh()
end)
tool.Unequipped:Connect(function()
	remote:FireServer("cancel")
	if gui then
		gui:Destroy()
		gui = nil
	end
end)
tool.Activated:Connect(function()
	if state == "Idle" then
		remote:FireServer("cast", aimPoint())
	elseif state == "Waiting" or state == "Bite" then
		remote:FireServer("hook")
	elseif state == "Reeling" then
		remote:FireServer("reel")
	end
end)

remote.OnClientEvent:Connect(function(kind, value)
	if kind == "state" then
		state = value
		refresh()
	elseif kind == "progress" and fill then
		TweenService:Create(fill, TweenInfo.new(0.1), { Size = UDim2.fromScale(math.clamp(value / 100, 0, 1), 1) }):Play()
		fill.BackgroundColor3 = value < 25 and Color3.fromRGB(220, 90, 60) or Color3.fromRGB(130, 200, 100)
	end
end)
]=======],
	Hud = [=======[
--[[
	FishingHud (LocalScript) · StarterPlayer.StarterPlayerScripts.FishingHud
	Muestra los avisos de la pesca («¡Has pescado: Trucha!», «¡Qué rico!: +25 de vida»…) aunque no lleves la caña.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Fishing"):WaitForChild("Remote")

local gui = Instance.new("ScreenGui")
gui.Name = "FishingHud"
gui.ResetOnSpawn = false
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 90)
label.Size = UDim2.fromOffset(520, 32)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextSize = 20
label.TextColor3 = Color3.fromRGB(255, 214, 120)
label.TextStrokeTransparency = 0.3
label.TextTransparency = 1
label.TextStrokeTransparency = 1
label.Parent = gui
gui.Parent = player:WaitForChild("PlayerGui")

local serial = 0
remote.OnClientEvent:Connect(function(kind, text)
	if kind ~= "toast" then
		return
	end
	serial += 1
	local mine = serial
	label.Text = text
	label.TextTransparency, label.TextStrokeTransparency = 0, 0.3
	task.delay(2.5, function()
		if mine == serial then
			TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end)
]=======],
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar la pesca")
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
local function sound(parent, name, volume)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = SOUND_IDS[name] or ""
	s.Volume = volume or 0.7
	s.RollOffMaxDistance = 80
	s.Parent = parent
	return s
end

-- construye las piezas de un modelo: la primera es el Handle; el resto, soldadas a él
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
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CanCollide = false
		p.CastShadow = b.material ~= "Neon"
		if i == 1 then
			handle = p
			p.Anchored = anchored or false
		else
			p.Anchored = anchored or false
			p.Massless = true
			p.CanTouch, p.CanQuery = false, false
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

local function makeTool(name, list)
	local t = Instance.new("Tool")
	t.Name = name
	t.CanBeDropped = true
	local h = buildParts(list, t)
	h.CanTouch = false
	return t, h
end

-- peces: un Tool por especie, crudo y cocinado, con lo que dan al comer
local NAMES = { Trout = { "Trucha cruda", "Trucha cocinada" }, Perch = { "Perca cruda", "Perca cocinada" }, GoldenSalmon = { "Salmón dorado crudo", "Salmón dorado cocinado" } }
local function fishTool(species, cooked)
	local list = MODELS[cooked and (species .. "_Cooked") or species]
	local t, h = makeTool(NAMES[species][cooked and 2 or 1], list)
	local food = SPECIES[species][cooked and "Cooked" or "Raw"]
	local tail = 0
	for _, b in ipairs(list) do
		tail = math.max(tail, b.offset[3] + b.size[3] / 2)
	end
	t.Grip = CFrame.new(0, 0, tail * 0.55)   -- se coge por la cola, con la cabeza hacia delante
	t.ToolTip = ("Clic para comer · +%d vida"):format(food.Heal)
	t:SetAttribute("Species", species)
	t:SetAttribute("Cooked", cooked)
	t:SetAttribute("Heal", food.Heal)
	t:SetAttribute("Food", food.Food)
	CollectionService:AddTag(t, "FishFood")
	sound(h, "Eat", 0.8)
	return t
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

local folder = ensure(ReplicatedStorage, "Fishing")
for _, n in ipairs({ "Fish", "Bobber", "FishingRod" }) do
	local o = folder:FindFirstChild(n)
	if o then
		o:Destroy()
	end
end
local fishFolder = ensure(folder, "Fish")
for species in pairs(SPECIES) do   -- se llaman en español (es lo que se ve en la barra); el servicio los busca por atributos
	fishTool(species, false).Parent = fishFolder
	fishTool(species, true).Parent = fishFolder
end

-- boya
local bobber = Instance.new("Model")
bobber.Name = "Bobber"
local bh = buildParts(MODELS.Bobber, bobber, false)
bh.Anchored = true
bobber.PrimaryPart = bh
local line = Instance.new("Attachment")
line.Name = "Line"
line.Position = Vector3.new(0, 0.33, 0)
line.Parent = bh
sound(bh, "Plop", 0.6)
bobber.Parent = folder

-- caña
local rod, rh = makeTool("FishingRod", MODELS.FishingRod)
rod.ToolTip = "Caña de pescar · clic en el agua"
rod.Grip = CFrame.new(0, 0, 0.3)
rod.CanBeDropped = false
local tip = rod:FindFirstChild("Tip")
local ta = Instance.new("Attachment")
ta.Name = "Tip"
ta.Position = Vector3.new(0, 0, -tip.Size.Z / 2)
ta.Parent = tip
sound(rh, "Cast", 0.6)
sound(rh, "Reel", 0.5)
sound(rh, "Catch", 0.8)
CollectionService:AddTag(rod, "FishingRod")
local rc = Instance.new("LocalScript")
rc.Name = "FishingRodClient"
rc.Source = SOURCES.RodClient
rc.Parent = rod
rod.Parent = folder
if GIVE_ROD then
	local old = game:GetService("StarterPack"):FindFirstChild("FishingRod")
	if old then
		old:Destroy()
	end
	rod:Clone().Parent = game:GetService("StarterPack")
end

local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({ CastRange = CAST_RANGE, RawSickChance = RAW_SICK_CHANCE, HungerAttribute = HUNGER_ATTRIBUTE, MaxHunger = 100, WaitMin = 4, WaitMax = 12, BiteWindow = 1.3, ReelPower = 9 }) do
	settings:SetAttribute(k, v)
end
for species, st in pairs(SPECIES) do
	settings:SetAttribute(species .. "Weight", st.Weight)
	settings:SetAttribute(species .. "Drain", st.Drain)
end
putScript(folder, "FishingLogic", "ModuleScript", SOURCES.Logic)
putScript(game:GetService("ServerScriptService"), "FishingService", "Script", SOURCES.Service)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "FishingHud", "LocalScript", SOURCES.Hud)

-- hoguera de bloques (anclada) con fuego, luz y su etiqueta
local function campfire(cf)
	local m = Instance.new("Model")
	m.Name = "Campfire"
	local h = buildParts(MODELS.Campfire, m, true)
	m.PrimaryPart = h
	m:PivotTo(cf)
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") then
			p.CanCollide = p == h
		end
	end
	local flame = nil
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") and p.Material == Enum.Material.Neon then
			flame = flame or p
		end
	end
	if flame then
		local f = Instance.new("Fire")
		f.Size, f.Heat = 4, 6
		f.Parent = flame
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 160, 80), 18, 2
		l.Parent = flame
	end
	sound(h, "Sizzle", 0.7)
	CollectionService:AddTag(m, "Campfire")
	return m
end

-- lago de prueba: agua de Terrain, orillas de hierba anchas (para estar de pie), rampa, muelle y hoguera
if DEMO_POND then
	local old = workspace:FindFirstChild("FishingPond")
	if old then
		old:Destroy()
	end
	local pond = Instance.new("Model")
	pond.Name = "FishingPond"
	local c = POND_CENTER
	workspace.Terrain:FillBlock(CFrame.new(c + Vector3.new(0, POND_DEPTH / 2, 0)), Vector3.new(POND_SIZE, POND_DEPTH, POND_SIZE), Enum.Material.Water)
	local function block(name, size, cf, mat, color, class)
		local p = Instance.new(class or "Part")
		p.Name = name
		p.Size = size
		p.CFrame = typeof(cf) == "CFrame" and cf or CFrame.new(cf)
		p.Anchored = true
		p.Material = mat
		p.Color = color
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = pond
		return p
	end
	local h, w = POND_DEPTH + 0.5, 8
	local half = POND_SIZE / 2 + w / 2
	local grass, wood = Color3.fromRGB(86, 120, 62), Color3.fromRGB(110, 78, 50)
	block("Bed", Vector3.new(POND_SIZE, 1, POND_SIZE), c + Vector3.new(0, -0.5, 0), Enum.Material.Mud, Color3.fromRGB(58, 52, 40))
	block("BankN", Vector3.new(POND_SIZE + 2 * w, h, w), c + Vector3.new(0, h / 2, -half), Enum.Material.Grass, grass)
	block("BankS", Vector3.new(POND_SIZE + 2 * w, h, w), c + Vector3.new(0, h / 2, half), Enum.Material.Grass, grass)
	block("BankW", Vector3.new(w, h, POND_SIZE), c + Vector3.new(-half, h / 2, 0), Enum.Material.Grass, grass)
	block("BankE", Vector3.new(w, h, POND_SIZE), c + Vector3.new(half, h / 2, 0), Enum.Material.Grass, grass)
	block("Ramp", Vector3.new(8, h, h * 3), CFrame.new(c + Vector3.new(half + w / 2 + h * 1.5, h / 2, 0)) * CFrame.Angles(0, -math.pi / 2, 0), Enum.Material.Grass, grass, "WedgePart")
	-- muelle desde la orilla sur hacia el centro
	local dockLen = 14
	local dz = POND_SIZE / 2 - dockLen / 2
	block("Dock", Vector3.new(6, 0.5, dockLen), c + Vector3.new(0, h - 0.25, dz), Enum.Material.WoodPlanks, wood)
	for _, x in ipairs({ -2.6, 2.6 }) do
		for _, z in ipairs({ dz - dockLen / 2 + 0.6, dz }) do
			block("Post", Vector3.new(0.6, h + 0.6, 0.6), c + Vector3.new(x, (h + 0.6) / 2 - 0.3, z), Enum.Material.Wood, Color3.fromRGB(80, 56, 36))
		end
	end
	pond.Parent = workspace
	local fires = ensure(workspace, "Campfires")
	local oldFire = fires:FindFirstChild("PondCampfire")
	if oldFire then
		oldFire:Destroy()
	end
	local fire = campfire(CFrame.new(c + Vector3.new(7, h, half)))
	fire.Name = "PondCampfire"
	fire.Parent = fires
end

Selection:Set({ folder })
pcall(function()
	ChangeHistoryService:SetWaypoint("Pesca instalada")
end)
print(("[Fishing] Listo: caña%s, 3 peces (crudos y cocinados) y servicio de pesca.%s"):format(
	GIVE_ROD and " en el StarterPack" or "",
	DEMO_POND and " Lago de prueba en Workspace.FishingPond: pesca desde el muelle y cocina en la hoguera." or ""))
