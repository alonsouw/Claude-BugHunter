--[[
	INSTALADOR DEL PEZ INFECTADO (criatura de bloques) · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	No hace falta importar nada: pega TODO este archivo en View > Command Bar y pulsa Enter.
	Construye las dos variantes con Parts (cada articulación es un Motor6D) y un estanque de prueba.

	Resultado:
	  ReplicatedStorage.Creatures.InfectedFish.Types     (Normal y Giant)
	  ReplicatedStorage.Creatures.InfectedFish           (Settings, Animations, FishBrain)
	  ReplicatedStorage.Dragons.DragonAnimator           (motor de animación, compartido con las demás criaturas)
	  ServerScriptService.FishSpawner                    (crea los peces en las zonas de agua y los controla)
	  StarterPlayer.StarterPlayerScripts.FishClient      (animación en cada jugador)
	  Workspace.FishZones.Pond + Workspace.FishPond      (estanque de prueba con agua de Terrain, si DEMO_POND)
	  Workspace.InfectedFishPreview                      (los dos peces para verlos en Studio; se borra al jugar)

	Para tu propio lago: una parte invisible que cubra el agua (cara de arriba = superficie) con la etiqueta
	FishZone, o dentro de Workspace.FishZones.
]]

local DEMO_POND = true                          -- crea un estanque de prueba
local POND_CENTER = Vector3.new(60, 0, 0)       -- centro del fondo del estanque (sobre el suelo)
local POND_SIZE, POND_DEPTH = 64, 14            -- lado y profundidad del agua (studs)
local MAX_PER_ZONE = 4                          -- peces por zona de agua
local RESPAWN_DELAY = 25
local GIANT_CHANCE = 0.125                      -- 1 de cada 8
-- Sonidos: sube los .ogg de sounds/ y pega aquí sus ids (rbxassetid://...).
local SOUND_IDS = { Screech = "", Bite = "", Splash = "", Gurgle = "" }

local BLUEPRINTS = {
	Normal = {
		limbs = {
			Root = {
				size = { 1, 1, 1 },
				center = { 0, 0, 0 },
				transparent = true,
			},
			Body = {
				size = { 1.3, 1.9, 1.6 },
				center = { 0, 0, 0 },
				color = { 104, 116, 96 },
			},
			Head = {
				size = { 1.15, 1.35, 1.1 },
				center = { 0, 0.1, -1.35 },
				color = { 104, 116, 96 },
			},
			Jaw = {
				size = { 1, 0.34, 1.15 },
				center = { 0, -0.7, -1.42 },
				color = { 104, 116, 96 },
			},
			Mid = {
				size = { 1.1, 1.5, 1.25 },
				center = { 0, -0.02, 1.4 },
				color = { 104, 116, 96 },
			},
			Tail = {
				size = { 0.34, 0.34, 1.1 },
				center = { 0, 0, 2.55 },
				color = { 214, 204, 180 },
			},
			TailFin = {
				size = { 0.14, 0.3, 0.25 },
				center = { 0, 0, 3.2 },
				color = { 214, 204, 180 },
			},
			LeftFin = {
				size = { 0.75, 0.07, 0.45 },
				center = { -1, -0.4, -0.4 },
				color = { 80, 92, 80 },
			},
			RightFin = {
				size = { 0.75, 0.07, 0.45 },
				center = { 1, -0.4, -0.4 },
				color = { 80, 92, 80 },
			},
		},
		joints = {
			{
				"Root",
				"Body",
				{ 0, 0, 0 },
			},
			{
				"Body",
				"Head",
				{ 0, 0, -0.8 },
			},
			{
				"Head",
				"Jaw",
				{ 0, -0.6, -0.85 },
			},
			{
				"Body",
				"Mid",
				{ 0, 0, 0.8 },
			},
			{
				"Mid",
				"Tail",
				{ 0, 0, 2 },
			},
			{
				"Tail",
				"TailFin",
				{ 0, 0, 3.1 },
			},
			{
				"Body",
				"LeftFin",
				{ -0.64, -0.4, -0.4 },
			},
			{
				"Body",
				"RightFin",
				{ 0.64, -0.4, -0.4 },
			},
		},
		details = {
			{
				limb = "Body",
				size = { 1.32, 0.4, 1.62 },
				offset = { 0, 0.78, 0 },
				color = { 58, 70, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 1.32, 0.36, 1.62 },
				offset = { 0, -0.8, 0 },
				color = { 184, 182, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.66, 0.3, -0.62 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.66, 0.3, 0.49 },
				color = { 90, 102, 84 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.66, 0.02, -0.44 },
				color = { 90, 102, 84 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.66, 0.02, 0.67 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.66, -0.26, -0.62 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.66, -0.26, 0.49 },
				color = { 90, 102, 84 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, 0.3, -0.62 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, 0.3, -0.25 },
				color = { 90, 102, 84 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, 0.3, 0.12 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, 0.3, 0.49 },
				color = { 90, 102, 84 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, 0.02, -0.44 },
				color = { 90, 102, 84 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, 0.02, -0.07 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, -0.26, -0.62 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, -0.26, -0.25 },
				color = { 90, 102, 84 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.95, 0.85 },
				offset = { 0.665, -0.05, 0.05 },
				color = { 70, 10, 14 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.03, 0.75, 0.65 },
				offset = { 0.672, -0.05, 0.05 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.85, 0.07 },
				offset = { 0.7, -0.05, -0.24 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -6, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.85, 0.07 },
				offset = { 0.7, -0.05, -0.08 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 6, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.85, 0.07 },
				offset = { 0.7, -0.05, 0.08 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -6, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.85, 0.07 },
				offset = { 0.7, -0.05, 0.24 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 6, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.12, 0.2 },
				offset = { 0.69, 0.42, -0.2 },
				color = { 168, 92, 88 },
				material = "SmoothPlastic",
				rot = { 20, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.12, 0.2 },
				offset = { 0.69, 0.42, 0.25 },
				color = { 168, 92, 88 },
				material = "SmoothPlastic",
				rot = { 20, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.12, 0.2 },
				offset = { 0.69, -0.5, -0.1 },
				color = { 168, 92, 88 },
				material = "SmoothPlastic",
				rot = { -20, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.12, 0.2 },
				offset = { 0.69, -0.5, 0.3 },
				color = { 168, 92, 88 },
				material = "SmoothPlastic",
				rot = { -20, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.72, 0.72 },
				offset = { -0.665, -0.12, 0.28 },
				color = { 88, 100, 56 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.16, 0.2, 0.2 },
				offset = { -0.73, 0.05, 0.1 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Body",
				size = { 0.128, 0.16, 0.16 },
				offset = { -0.722, -0.2, 0.35 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Body",
				size = { 0.096, 0.12, 0.12 },
				offset = { -0.714, 0.15, 0.45 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Body",
				size = { 0.112, 0.14, 0.14 },
				offset = { -0.718, -0.35, 0.05 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Body",
				size = { 0.08, 0.1, 0.1 },
				offset = { -0.71, -0.05, 0.55 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Body",
				size = { 0.08, 0.1, 0.1 },
				offset = { -0.71, 0.2, 0.25 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Body",
				size = { 0.06, 0.55, 0.06 },
				offset = { 0, 1.175, -0.5 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.385, 0.22 },
				offset = { 0, 1.085, -0.38 },
				color = { 80, 92, 80 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.65, 0.06 },
				offset = { 0, 1.225, -0.24 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.455, 0.22 },
				offset = { 0, 1.115, -0.12 },
				color = { 80, 92, 80 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.65, 0.06 },
				offset = { 0, 1.225, 0.02 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.55, 0.06 },
				offset = { 0, 1.175, 0.28 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.22, 0.22 },
				offset = { 0, 1.085, 0.4 },
				color = { 80, 92, 80 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.45, 0.06 },
				offset = { 0, 1.125, 0.54 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.6, 0.06 },
				offset = { -0.665, 0, -0.72 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.52, 0.06 },
				offset = { -0.665, 0, -0.6 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.44, 0.06 },
				offset = { -0.665, 0, -0.48 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.6, 0.06 },
				offset = { 0.665, 0, -0.72 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.52, 0.06 },
				offset = { 0.665, 0, -0.6 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.44, 0.06 },
				offset = { 0.665, 0, -0.48 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.07, 0.07, 0.22 },
				offset = { 0.7, -0.05, -0.68 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { -20, 30, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.07, 0.07, 0.22 },
				offset = { 0.79, -0.11, -0.56 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 5, 55, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.07, 0.07, 0.22 },
				offset = { 0.88, -0.1, -0.44 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 30, 80, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.07, 0.07, 0.22 },
				offset = { 0.7, -0.3, -0.55 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { -20, 30, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.07, 0.07, 0.22 },
				offset = { 0.79, -0.36, -0.43 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 5, 55, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.07, 0.07, 0.22 },
				offset = { 0.88, -0.35, -0.31 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 30, 80, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 1.17, 0.34, 1.12 },
				offset = { 0, 0.52, 0 },
				color = { 58, 70, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 1.13, 0.45, 0.95 },
				offset = { 0, 0.66, 0.16 },
				color = { 58, 70, 62 },
				material = "SmoothPlastic",
				rot = { -22, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 1, 0.12, 0.9 },
				offset = { 0, -0.63, -0.05 },
				color = { 28, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 1.05, 0.06, 0.06 },
				offset = { 0, -0.575, -0.56 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.3, 0.06 },
				offset = { -0.42, -0.725, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.22, 0.06 },
				offset = { -0.28, -0.685, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.34, 0.06 },
				offset = { -0.14, -0.745, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { 0, -0.675, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.32, 0.06 },
				offset = { 0.14, -0.735, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.24, 0.06 },
				offset = { 0.28, -0.695, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.28, 0.06 },
				offset = { 0.42, -0.715, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { -0.5, -0.68, -0.3 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { -0.5, -0.68, -0.1 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { -0.5, -0.68, 0.1 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { 0.5, -0.68, -0.3 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { 0.5, -0.68, -0.1 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { 0.5, -0.68, 0.1 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.04, 0.38, 0.38 },
				offset = { -0.585, 0.12, -0.12 },
				color = { 28, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.26, 0.26 },
				offset = { -0.6, 0.12, -0.12 },
				color = { 214, 255, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.03, 0.18, 0.06 },
				offset = { -0.635, 0.12, -0.12 },
				color = { 28, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.04, 0.38, 0.38 },
				offset = { 0.585, 0.12, -0.12 },
				color = { 70, 10, 14 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.05, 0.2, 0.05 },
				offset = { 0.63, 0, -0.12 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, -10 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.05, 0.2, 0.05 },
				offset = { 0.66, -0.2, -0.1 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 10 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.22, 0.22, 0.22 },
				offset = { 0.7, -0.4, -0.1 },
				color = { 232, 228, 204 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.03, 0.12, 0.12 },
				offset = { 0.815, -0.4, -0.1 },
				color = { 214, 255, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.5, 0.05, 0.4 },
				offset = { 0.12, 0.7, -0.22 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.56, 0.04, 0.46 },
				offset = { 0.12, 0.685, -0.22 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.2, 0.06, 0.04 },
				offset = { 0.1, -0.15, -0.565 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 20 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.28, 0.05, 0.04 },
				offset = { -0.2, 0.25, -0.565 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { 0, 0, -15 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.06, 0.24, 0.06 },
				offset = { -0.36, 0.25, -0.52 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.06, 0.3, 0.06 },
				offset = { -0.216, 0.28, -0.52 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.06, 0.2, 0.06 },
				offset = { -0.072, 0.23, -0.52 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.06, 0.32, 0.06 },
				offset = { 0.072, 0.29, -0.52 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.06, 0.22, 0.06 },
				offset = { 0.216, 0.24, -0.52 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.06, 0.28, 0.06 },
				offset = { 0.36, 0.27, -0.52 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 1.02, 0.08, 1.17 },
				offset = { 0, -0.14, 0 },
				color = { 184, 182, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.38, 0.04 },
				offset = { 0.2, -0.33, -0.56 },
				color = { 70, 10, 14 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.05, 0.22, 0.04 },
				offset = { -0.25, -0.26, -0.56 },
				color = { 70, 10, 14 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 1.12, 0.36, 1.27 },
				offset = { 0, 0.6, 0 },
				color = { 58, 70, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 1.06, 0.5, 0.6 },
				offset = { 0, 0.62, 0.5 },
				color = { 58, 70, 62 },
				material = "SmoothPlastic",
				rot = { 32, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 1.06, 0.5, 0.6 },
				offset = { 0, -0.64, 0.5 },
				color = { 184, 182, 150 },
				material = "SmoothPlastic",
				rot = { -32, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 1.12, 0.3, 1.27 },
				offset = { 0, -0.62, 0 },
				color = { 184, 182, 150 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, 0.25, -0.45 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, 0.25, -0.08 },
				color = { 90, 102, 84 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, 0.25, 0.29 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, -0.03, -0.27 },
				color = { 90, 102, 84 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, -0.03, 0.1 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, -0.03, 0.47 },
				color = { 90, 102, 84 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, -0.31, -0.45 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, -0.31, -0.08 },
				color = { 90, 102, 84 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, -0.31, 0.29 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.56, 0.25, -0.45 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.56, -0.03, -0.27 },
				color = { 90, 102, 84 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.56, -0.31, -0.45 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.56, -0.31, -0.08 },
				color = { 90, 102, 84 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.56, -0.31, 0.29 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.55, 0.55 },
				offset = { -0.565, 0.05, 0.12 },
				color = { 168, 92, 88 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.03, 0.3, 0.3 },
				offset = { -0.575, 0.05, 0.12 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.06, 0.55, 0.06 },
				offset = { 0, 1, -0.3 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 30, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.06, 0.45, 0.06 },
				offset = { 0, 0.92, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 30, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.06, 0.35, 0.06 },
				offset = { 0, 0.84, 0.2 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 30, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.3, 0.2 },
				offset = { 0, 0.93, -0.18 },
				color = { 80, 92, 80 },
				material = "SmoothPlastic",
				rot = { 30, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.05, 0.38, 0.05 },
				offset = { 0, -0.9, 0.1 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.05, 0.38, 0.05 },
				offset = { 0, -0.9, 0.28 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.05, 0.38, 0.05 },
				offset = { 0, -0.9, 0.46 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.07, 0.07, 0.2 },
				offset = { 0.6, -0.2, 0.2 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 30, 20, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.07, 0.07, 0.2 },
				offset = { 0.68, -0.28, 0.3 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 30, 50, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.07, 0.07, 0.2 },
				offset = { 0.76, -0.36, 0.4 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 30, 80, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.44, 0.44, 0.08 },
				offset = { 0, 0, -0.45 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.36, 0.05 },
				offset = { 0, 0.34, -0.45 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.3, 0.05 },
				offset = { 0, -0.32, -0.45 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.44, 0.44, 0.08 },
				offset = { 0, 0, -0.27 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.36, 0.05 },
				offset = { 0, 0.34, -0.27 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.3, 0.05 },
				offset = { 0, -0.32, -0.27 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.44, 0.44, 0.08 },
				offset = { 0, 0, -0.09 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.36, 0.05 },
				offset = { 0, 0.34, -0.09 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.3, 0.05 },
				offset = { 0, -0.32, -0.09 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.44, 0.44, 0.08 },
				offset = { 0, 0, 0.09 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.36, 0.05 },
				offset = { 0, 0.34, 0.09 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.3, 0.05 },
				offset = { 0, -0.32, 0.09 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.44, 0.44, 0.08 },
				offset = { 0, 0, 0.27 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.36, 0.05 },
				offset = { 0, 0.34, 0.27 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.3, 0.05 },
				offset = { 0, -0.32, 0.27 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.44, 0.44, 0.08 },
				offset = { 0, 0, 0.45 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.36, 0.05 },
				offset = { 0, 0.34, 0.45 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.3, 0.05 },
				offset = { 0, -0.32, 0.45 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.6, 0.62, 0.3 },
				offset = { 0, 0, -0.42 },
				color = { 104, 116, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.62, 0.2, 0.31 },
				offset = { 0, 0.22, -0.42 },
				color = { 58, 70, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.3, 0.26, 0.22 },
				offset = { -0.12, -0.08, -0.1 },
				color = { 168, 92, 88 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.32, 0.05 },
				offset = { 0.1, -0.3, -0.2 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { 10, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.04, 0.24, 0.04 },
				offset = { -0.14, -0.28, 0.1 },
				color = { 70, 10, 14 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.05, 0.05, 0.95 },
				offset = { 0, -0.3639, 0.3053 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 50, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.05, 0.05, 0.982 },
				offset = { 0, -0.2746, 0.4071 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 34, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.05, 0.05, 0.764 },
				offset = { 0, -0.118, 0.3633 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 18, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.05, 0.05, 1.05 },
				offset = { 0, 0, 0.525 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.05, 0.05, 1.014 },
				offset = { 0, 0.1567, 0.4822 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -18, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.05, 0.05, 0.982 },
				offset = { 0, 0.2746, 0.4071 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -34, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.05, 0.05, 0.95 },
				offset = { 0, 0.3639, 0.3053 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -50, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.04, 0.2, 0.5 },
				offset = { 0, -0.4684, 0.5202 },
				color = { 80, 92, 80 },
				material = "SmoothPlastic",
				rot = { 42, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.04, 0.2, 0.35 },
				offset = { 0, -0.2082, 0.4269 },
				color = { 80, 92, 80 },
				material = "SmoothPlastic",
				rot = { 26, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.04, 0.2, 0.45 },
				offset = { 0, 0.3178, 0.6516 },
				color = { 80, 92, 80 },
				material = "SmoothPlastic",
				rot = { -26, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.04, 0.2, 0.55 },
				offset = { 0, 0.4182, 0.4645 },
				color = { 80, 92, 80 },
				material = "SmoothPlastic",
				rot = { -42, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0, 0.1044, 0.7427 },
				color = { 80, 92, 80 },
				material = "SmoothPlastic",
				rot = { -8, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftFin",
				size = { 0.72, 0.04, 0.04 },
				offset = { -0.02, 0.04, -0.15 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftFin",
				size = { 0.72, 0.04, 0.04 },
				offset = { -0.02, 0.04, 0 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftFin",
				size = { 0.72, 0.04, 0.04 },
				offset = { -0.02, 0.04, 0.15 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftFin",
				size = { 0.2, 0.08, 0.14 },
				offset = { -0.2, 0, 0.12 },
				color = { 28, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightFin",
				size = { 0.72, 0.04, 0.04 },
				offset = { 0.02, 0.04, -0.15 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightFin",
				size = { 0.72, 0.04, 0.04 },
				offset = { 0.02, 0.04, 0 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightFin",
				size = { 0.72, 0.04, 0.04 },
				offset = { 0.02, 0.04, 0.15 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightFin",
				size = { 0.2, 0.08, 0.14 },
				offset = { 0.2, 0, 0.12 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
		},
	},
	Giant = {
		limbs = {
			Root = {
				size = { 1, 1, 1 },
				center = { 0, 0, 0 },
				transparent = true,
			},
			Body = {
				size = { 1.3, 1.9, 1.6 },
				center = { 0, 0, 0 },
				color = { 74, 86, 74 },
			},
			Head = {
				size = { 1.15, 1.35, 1.1 },
				center = { 0, 0.1, -1.35 },
				color = { 74, 86, 74 },
			},
			Jaw = {
				size = { 1, 0.34, 1.15 },
				center = { 0, -0.7, -1.42 },
				color = { 74, 86, 74 },
			},
			Mid = {
				size = { 1.1, 1.5, 1.25 },
				center = { 0, -0.02, 1.4 },
				color = { 74, 86, 74 },
			},
			Tail = {
				size = { 0.34, 0.34, 1.1 },
				center = { 0, 0, 2.55 },
				color = { 214, 204, 180 },
			},
			TailFin = {
				size = { 0.14, 0.3, 0.25 },
				center = { 0, 0, 3.2 },
				color = { 214, 204, 180 },
			},
			LeftFin = {
				size = { 0.75, 0.07, 0.45 },
				center = { -1, -0.4, -0.4 },
				color = { 56, 66, 60 },
			},
			RightFin = {
				size = { 0.75, 0.07, 0.45 },
				center = { 1, -0.4, -0.4 },
				color = { 56, 66, 60 },
			},
		},
		joints = {
			{
				"Root",
				"Body",
				{ 0, 0, 0 },
			},
			{
				"Body",
				"Head",
				{ 0, 0, -0.8 },
			},
			{
				"Head",
				"Jaw",
				{ 0, -0.6, -0.85 },
			},
			{
				"Body",
				"Mid",
				{ 0, 0, 0.8 },
			},
			{
				"Mid",
				"Tail",
				{ 0, 0, 2 },
			},
			{
				"Tail",
				"TailFin",
				{ 0, 0, 3.1 },
			},
			{
				"Body",
				"LeftFin",
				{ -0.64, -0.4, -0.4 },
			},
			{
				"Body",
				"RightFin",
				{ 0.64, -0.4, -0.4 },
			},
		},
		details = {
			{
				limb = "Body",
				size = { 1.32, 0.4, 1.62 },
				offset = { 0, 0.78, 0 },
				color = { 38, 46, 44 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 1.32, 0.36, 1.62 },
				offset = { 0, -0.8, 0 },
				color = { 160, 158, 128 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.66, 0.3, -0.62 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.66, 0.3, 0.49 },
				color = { 62, 72, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.66, 0.02, -0.44 },
				color = { 62, 72, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.66, 0.02, 0.67 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.66, -0.26, -0.62 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.66, -0.26, 0.49 },
				color = { 62, 72, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, 0.3, -0.62 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, 0.3, -0.25 },
				color = { 62, 72, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, 0.3, 0.12 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, 0.3, 0.49 },
				color = { 62, 72, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, 0.02, -0.44 },
				color = { 62, 72, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, 0.02, -0.07 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, -0.26, -0.62 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.66, -0.26, -0.25 },
				color = { 62, 72, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.95, 0.85 },
				offset = { 0.665, -0.05, 0.05 },
				color = { 70, 10, 14 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.03, 0.75, 0.65 },
				offset = { 0.672, -0.05, 0.05 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.85, 0.07 },
				offset = { 0.7, -0.05, -0.24 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -6, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.85, 0.07 },
				offset = { 0.7, -0.05, -0.08 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 6, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.85, 0.07 },
				offset = { 0.7, -0.05, 0.08 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -6, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.85, 0.07 },
				offset = { 0.7, -0.05, 0.24 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 6, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.12, 0.2 },
				offset = { 0.69, 0.42, -0.2 },
				color = { 168, 92, 88 },
				material = "SmoothPlastic",
				rot = { 20, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.12, 0.2 },
				offset = { 0.69, 0.42, 0.25 },
				color = { 168, 92, 88 },
				material = "SmoothPlastic",
				rot = { 20, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.12, 0.2 },
				offset = { 0.69, -0.5, -0.1 },
				color = { 168, 92, 88 },
				material = "SmoothPlastic",
				rot = { -20, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.12, 0.2 },
				offset = { 0.69, -0.5, 0.3 },
				color = { 168, 92, 88 },
				material = "SmoothPlastic",
				rot = { -20, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.72, 0.72 },
				offset = { -0.665, -0.12, 0.28 },
				color = { 88, 100, 56 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.16, 0.2, 0.2 },
				offset = { -0.73, 0.05, 0.1 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Body",
				size = { 0.128, 0.16, 0.16 },
				offset = { -0.722, -0.2, 0.35 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Body",
				size = { 0.096, 0.12, 0.12 },
				offset = { -0.714, 0.15, 0.45 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Body",
				size = { 0.112, 0.14, 0.14 },
				offset = { -0.718, -0.35, 0.05 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Body",
				size = { 0.08, 0.1, 0.1 },
				offset = { -0.71, -0.05, 0.55 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Body",
				size = { 0.08, 0.1, 0.1 },
				offset = { -0.71, 0.2, 0.25 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Body",
				size = { 0.06, 0.55, 0.06 },
				offset = { 0, 1.175, -0.5 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.385, 0.22 },
				offset = { 0, 1.085, -0.38 },
				color = { 56, 66, 60 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.65, 0.06 },
				offset = { 0, 1.225, -0.24 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.455, 0.22 },
				offset = { 0, 1.115, -0.12 },
				color = { 56, 66, 60 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.65, 0.06 },
				offset = { 0, 1.225, 0.02 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.55, 0.06 },
				offset = { 0, 1.175, 0.28 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.22, 0.22 },
				offset = { 0, 1.085, 0.4 },
				color = { 56, 66, 60 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.06, 0.45, 0.06 },
				offset = { 0, 1.125, 0.54 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.6, 0.06 },
				offset = { -0.665, 0, -0.72 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.52, 0.06 },
				offset = { -0.665, 0, -0.6 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.44, 0.06 },
				offset = { -0.665, 0, -0.48 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.6, 0.06 },
				offset = { 0.665, 0, -0.72 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.52, 0.06 },
				offset = { 0.665, 0, -0.6 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.04, 0.44, 0.06 },
				offset = { 0.665, 0, -0.48 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.07, 0.07, 0.22 },
				offset = { 0.7, -0.05, -0.68 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { -20, 30, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.07, 0.07, 0.22 },
				offset = { 0.79, -0.11, -0.56 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 5, 55, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.07, 0.07, 0.22 },
				offset = { 0.88, -0.1, -0.44 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 30, 80, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.07, 0.07, 0.22 },
				offset = { 0.7, -0.3, -0.55 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { -20, 30, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.07, 0.07, 0.22 },
				offset = { 0.79, -0.36, -0.43 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 5, 55, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.07, 0.07, 0.22 },
				offset = { 0.88, -0.35, -0.31 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 30, 80, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 1.17, 0.34, 1.12 },
				offset = { 0, 0.52, 0 },
				color = { 38, 46, 44 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 1.13, 0.45, 0.95 },
				offset = { 0, 0.66, 0.16 },
				color = { 38, 46, 44 },
				material = "SmoothPlastic",
				rot = { -22, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 1, 0.12, 0.9 },
				offset = { 0, -0.63, -0.05 },
				color = { 28, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 1.05, 0.06, 0.06 },
				offset = { 0, -0.575, -0.56 },
				color = { 120, 32, 42 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.3, 0.06 },
				offset = { -0.42, -0.725, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.22, 0.06 },
				offset = { -0.28, -0.685, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.34, 0.06 },
				offset = { -0.14, -0.745, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { 0, -0.675, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.32, 0.06 },
				offset = { 0.14, -0.735, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.24, 0.06 },
				offset = { 0.28, -0.695, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.28, 0.06 },
				offset = { 0.42, -0.715, -0.5 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { -0.5, -0.68, -0.3 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { -0.5, -0.68, -0.1 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { -0.5, -0.68, 0.1 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { 0.5, -0.68, -0.3 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { 0.5, -0.68, -0.1 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.2, 0.06 },
				offset = { 0.5, -0.68, 0.1 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.04, 0.38, 0.38 },
				offset = { -0.585, 0.12, -0.12 },
				color = { 28, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.26, 0.26 },
				offset = { -0.6, 0.12, -0.12 },
				color = { 214, 255, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.03, 0.18, 0.06 },
				offset = { -0.635, 0.12, -0.12 },
				color = { 28, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.04, 0.38, 0.38 },
				offset = { 0.585, 0.12, -0.12 },
				color = { 70, 10, 14 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.05, 0.2, 0.05 },
				offset = { 0.63, 0, -0.12 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, -10 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.05, 0.2, 0.05 },
				offset = { 0.66, -0.2, -0.1 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 10 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.22, 0.22, 0.22 },
				offset = { 0.7, -0.4, -0.1 },
				color = { 232, 228, 204 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.03, 0.12, 0.12 },
				offset = { 0.815, -0.4, -0.1 },
				color = { 214, 255, 96 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.5, 0.05, 0.4 },
				offset = { 0.12, 0.7, -0.22 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.56, 0.04, 0.46 },
				offset = { 0.12, 0.685, -0.22 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.2, 0.06, 0.04 },
				offset = { 0.1, -0.15, -0.565 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 20 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.28, 0.05, 0.04 },
				offset = { -0.2, 0.25, -0.565 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { 0, 0, -15 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.06, 0.24, 0.06 },
				offset = { -0.36, 0.25, -0.52 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.06, 0.3, 0.06 },
				offset = { -0.216, 0.28, -0.52 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.06, 0.2, 0.06 },
				offset = { -0.072, 0.23, -0.52 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.06, 0.32, 0.06 },
				offset = { 0.072, 0.29, -0.52 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.06, 0.22, 0.06 },
				offset = { 0.216, 0.24, -0.52 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.06, 0.28, 0.06 },
				offset = { 0.36, 0.27, -0.52 },
				color = { 228, 220, 190 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 1.02, 0.08, 1.17 },
				offset = { 0, -0.14, 0 },
				color = { 160, 158, 128 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.07, 0.38, 0.04 },
				offset = { 0.2, -0.33, -0.56 },
				color = { 70, 10, 14 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.05, 0.22, 0.04 },
				offset = { -0.25, -0.26, -0.56 },
				color = { 70, 10, 14 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 1.12, 0.36, 1.27 },
				offset = { 0, 0.6, 0 },
				color = { 38, 46, 44 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 1.06, 0.5, 0.6 },
				offset = { 0, 0.62, 0.5 },
				color = { 38, 46, 44 },
				material = "SmoothPlastic",
				rot = { 32, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 1.06, 0.5, 0.6 },
				offset = { 0, -0.64, 0.5 },
				color = { 160, 158, 128 },
				material = "SmoothPlastic",
				rot = { -32, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 1.12, 0.3, 1.27 },
				offset = { 0, -0.62, 0 },
				color = { 160, 158, 128 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, 0.25, -0.45 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, 0.25, -0.08 },
				color = { 62, 72, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, 0.25, 0.29 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, -0.03, -0.27 },
				color = { 62, 72, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, -0.03, 0.1 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, -0.03, 0.47 },
				color = { 62, 72, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, -0.31, -0.45 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, -0.31, -0.08 },
				color = { 62, 72, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0.56, -0.31, 0.29 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.56, 0.25, -0.45 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.56, -0.03, -0.27 },
				color = { 62, 72, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.56, -0.31, -0.45 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.56, -0.31, -0.08 },
				color = { 62, 72, 62 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.2, 0.3 },
				offset = { -0.56, -0.31, 0.29 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.55, 0.55 },
				offset = { -0.565, 0.05, 0.12 },
				color = { 168, 92, 88 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.03, 0.3, 0.3 },
				offset = { -0.575, 0.05, 0.12 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.06, 0.55, 0.06 },
				offset = { 0, 1, -0.3 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 30, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.06, 0.45, 0.06 },
				offset = { 0, 0.92, -0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 30, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.06, 0.35, 0.06 },
				offset = { 0, 0.84, 0.2 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 30, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.04, 0.3, 0.2 },
				offset = { 0, 0.93, -0.18 },
				color = { 56, 66, 60 },
				material = "SmoothPlastic",
				rot = { 30, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.05, 0.38, 0.05 },
				offset = { 0, -0.9, 0.1 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.05, 0.38, 0.05 },
				offset = { 0, -0.9, 0.28 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.05, 0.38, 0.05 },
				offset = { 0, -0.9, 0.46 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.07, 0.07, 0.2 },
				offset = { 0.6, -0.2, 0.2 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 30, 20, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.07, 0.07, 0.2 },
				offset = { 0.68, -0.28, 0.3 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 30, 50, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.07, 0.07, 0.2 },
				offset = { 0.76, -0.36, 0.4 },
				color = { 206, 196, 164 },
				material = "SmoothPlastic",
				rot = { 30, 80, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.44, 0.44, 0.08 },
				offset = { 0, 0, -0.45 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.36, 0.05 },
				offset = { 0, 0.34, -0.45 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.3, 0.05 },
				offset = { 0, -0.32, -0.45 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.44, 0.44, 0.08 },
				offset = { 0, 0, -0.27 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.36, 0.05 },
				offset = { 0, 0.34, -0.27 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.3, 0.05 },
				offset = { 0, -0.32, -0.27 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.44, 0.44, 0.08 },
				offset = { 0, 0, -0.09 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.36, 0.05 },
				offset = { 0, 0.34, -0.09 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.3, 0.05 },
				offset = { 0, -0.32, -0.09 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.44, 0.44, 0.08 },
				offset = { 0, 0, 0.09 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.36, 0.05 },
				offset = { 0, 0.34, 0.09 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.3, 0.05 },
				offset = { 0, -0.32, 0.09 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.44, 0.44, 0.08 },
				offset = { 0, 0, 0.27 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.36, 0.05 },
				offset = { 0, 0.34, 0.27 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.3, 0.05 },
				offset = { 0, -0.32, 0.27 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.44, 0.44, 0.08 },
				offset = { 0, 0, 0.45 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.36, 0.05 },
				offset = { 0, 0.34, 0.45 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.3, 0.05 },
				offset = { 0, -0.32, 0.45 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -25, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.6, 0.62, 0.3 },
				offset = { 0, 0, -0.42 },
				color = { 74, 86, 74 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.62, 0.2, 0.31 },
				offset = { 0, 0.22, -0.42 },
				color = { 38, 46, 44 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.3, 0.26, 0.22 },
				offset = { -0.12, -0.08, -0.1 },
				color = { 168, 92, 88 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.05, 0.32, 0.05 },
				offset = { 0.1, -0.3, -0.2 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { 10, 0, 0 },
				neon = false,
			},
			{
				limb = "Tail",
				size = { 0.04, 0.24, 0.04 },
				offset = { -0.14, -0.28, 0.1 },
				color = { 70, 10, 14 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.05, 0.05, 0.946 },
				offset = { 0, -0.3727, 0.2912 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 52, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.05, 0.05, 0.978 },
				offset = { 0, -0.2874, 0.3956 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 36, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.05, 0.05, 0.76 },
				offset = { 0, -0.13, 0.3571 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 20, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.05, 0.05, 1.01 },
				offset = { 0, 0.1727, 0.4745 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -20, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.05, 0.05, 0.978 },
				offset = { 0, 0.2874, 0.3956 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -36, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.05, 0.05, 0.946 },
				offset = { 0, 0.3727, 0.2912 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { -52, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.04, 0.2, 0.5 },
				offset = { 0, -0.4684, 0.5202 },
				color = { 56, 66, 60 },
				material = "SmoothPlastic",
				rot = { 42, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.04, 0.2, 0.35 },
				offset = { 0, -0.2082, 0.4269 },
				color = { 56, 66, 60 },
				material = "SmoothPlastic",
				rot = { 26, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.04, 0.2, 0.45 },
				offset = { 0, 0.3178, 0.6516 },
				color = { 56, 66, 60 },
				material = "SmoothPlastic",
				rot = { -26, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.04, 0.2, 0.55 },
				offset = { 0, 0.4182, 0.4645 },
				color = { 56, 66, 60 },
				material = "SmoothPlastic",
				rot = { -42, 0, 0 },
				neon = false,
			},
			{
				limb = "TailFin",
				size = { 0.04, 0.2, 0.3 },
				offset = { 0, 0.1044, 0.7427 },
				color = { 56, 66, 60 },
				material = "SmoothPlastic",
				rot = { -8, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftFin",
				size = { 0.72, 0.04, 0.04 },
				offset = { -0.02, 0.04, -0.15 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftFin",
				size = { 0.72, 0.04, 0.04 },
				offset = { -0.02, 0.04, 0 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftFin",
				size = { 0.72, 0.04, 0.04 },
				offset = { -0.02, 0.04, 0.15 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "LeftFin",
				size = { 0.2, 0.08, 0.14 },
				offset = { -0.2, 0, 0.12 },
				color = { 28, 8, 10 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightFin",
				size = { 0.72, 0.04, 0.04 },
				offset = { 0.02, 0.04, -0.15 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightFin",
				size = { 0.72, 0.04, 0.04 },
				offset = { 0.02, 0.04, 0 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightFin",
				size = { 0.72, 0.04, 0.04 },
				offset = { 0.02, 0.04, 0.15 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "RightFin",
				size = { 0.2, 0.08, 0.14 },
				offset = { 0.2, 0, 0.12 },
				color = { 140, 36, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.32, 0.06 },
				offset = { 0, 0.8, -0.32 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { -20, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.3, 0.06 },
				offset = { 0, 0.98, -0.4 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { -50, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.06, 0.06, 0.28 },
				offset = { 0, 1.08, -0.62 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.05, 0.2, 0.05 },
				offset = { 0, 0.98, -0.76 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.2, 0.2, 0.2 },
				offset = { 0, 0.84, -0.78 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Jaw",
				size = { 0.05, 0.05, 0.28 },
				offset = { -0.42, -0.18, -0.62 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { 40, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.05, 0.05, 0.28 },
				offset = { -0.45, -0.3, -0.74 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { 55, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.05, 0.05, 0.28 },
				offset = { -0.48, -0.42, -0.86 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { 70, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.05, 0.05, 0.28 },
				offset = { 0.42, -0.18, -0.62 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { 40, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.05, 0.05, 0.28 },
				offset = { 0.45, -0.3, -0.74 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { 55, 0, 0 },
				neon = false,
			},
			{
				limb = "Jaw",
				size = { 0.05, 0.05, 0.28 },
				offset = { 0.48, -0.42, -0.86 },
				color = { 120, 58, 56 },
				material = "SmoothPlastic",
				rot = { 70, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.14, 0.7, 0.14 },
				offset = { 0.25, 1.3, -0.45 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 20, 0, -15 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.14, 0.9, 0.14 },
				offset = { 0.25, 1.4, 0.05 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 20, 0, -15 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.14, 0.6, 0.14 },
				offset = { 0.25, 1.25, 0.5 },
				color = { 214, 204, 180 },
				material = "SmoothPlastic",
				rot = { 20, 0, -15 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.18, 0.1, 0.18 },
				offset = { -0.3, 0.7, -0.1 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Head",
				size = { 0.18, 0.1, 0.18 },
				offset = { 0.35, 0.68, -0.3 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Body",
				size = { 0.18, 0.1, 0.18 },
				offset = { -0.4, 0.98, 0.5 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.18, 0.1, 0.18 },
				offset = { 0.3, 0.78, 0.1 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.18, 0.1, 0.18 },
				offset = { -0.2, 0.78, -0.3 },
				color = { 176, 166, 138 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = false,
			},
			{
				limb = "Mid",
				size = { 0.112, 0.14, 0.14 },
				offset = { 0.598, 0.2, -0.3 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Mid",
				size = { 0.144, 0.18, 0.18 },
				offset = { 0.606, -0.1, -0.1 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Mid",
				size = { 0.096, 0.12, 0.12 },
				offset = { 0.594, 0.1, 0.35 },
				color = { 190, 232, 70 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
			{
				limb = "Head",
				size = { 0.06, 0.12, 0.12 },
				offset = { -0.6, 0.12, -0.12 },
				color = { 255, 120, 40 },
				material = "SmoothPlastic",
				rot = { 0, 0, 0 },
				neon = true,
			},
		},
	},
}
local STATS = {
	Normal = {
		DisplayName = "Pez infectado",
		Health = 60,
		Damage = 12,
		Reach = 3.5,
		Detect = 45,
		SwimSpeed = 6,
		CircleSpeed = 11,
		ChaseSpeed = 17,
		Cooldown = 1.2,
		LeapRange = 16,
		LeapCooldown = 7,
		LeapHeight = 4,
		Scale = 1,
		Circle = true,
		Chance = 0.875,
	},
	Giant = {
		DisplayName = "Pez infectado gigante",
		Health = 320,
		Damage = 30,
		Reach = 7,
		Detect = 70,
		SwimSpeed = 5,
		CircleSpeed = 9,
		ChaseSpeed = 14,
		Cooldown = 2,
		LeapRange = 24,
		LeapCooldown = 12,
		LeapHeight = 7,
		Scale = 2.2,
		Circle = false,
		Chance = 0.125,
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
	Animaciones del pez infectado (ModuleScript) · ReplicatedStorage.Creatures.InfectedFish.Animations
	Generado desde src/fish_anims.js con tools/build_roblox.js: edita la fuente y regenera.
]]
return {
	Idle = {
		dur = 3.2,
		loop = true,
		joints = {
			Body = {
				o = {
					{ "y", 2.5, 1, 0 },
				},
			},
			Head = {
				o = {
					{ "y", 3.5, 1, 0.5 },
					{ "x", 2, 1, 0.2 },
				},
			},
			Mid = {
				o = {
					{ "y", 6, 1, 0.15 },
				},
			},
			Tail = {
				o = {
					{ "y", 11, 1, 0.3 },
				},
			},
			TailFin = {
				o = {
					{ "y", 15, 1, 0.45 },
				},
			},
			LeftFin = {
				k = {
					{ 0, 0, 0, 0 },
				},
				o = {
					{ "z", 14, 2, 0 },
				},
			},
			RightFin = {
				k = {
					{ 0, 0, 0, 0 },
				},
				o = {
					{ "z", -14, 2, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -8, 0, 0 },
				},
				o = {
					{ "x", 6, 2, 0 },
				},
			},
		},
	},
	Swim = {
		dur = 1.2,
		loop = true,
		joints = {
			Body = {
				o = {
					{ "y", 4, 1, 0 },
				},
			},
			Head = {
				o = {
					{ "y", 5.6, 1, 0.5 },
				},
			},
			Mid = {
				o = {
					{ "y", 9.6, 1, 0.15 },
				},
			},
			Tail = {
				o = {
					{ "y", 17.6, 1, 0.3 },
				},
			},
			TailFin = {
				o = {
					{ "y", 24, 1, 0.45 },
				},
			},
			LeftFin = {
				k = {
					{ 0, 0, 0, 0 },
				},
				o = {
					{ "z", 18, 1, 0 },
				},
			},
			RightFin = {
				k = {
					{ 0, 0, 0, 0 },
				},
				o = {
					{ "z", -18, 1, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -6, 0, 0 },
				},
				o = {
					{ "x", 4, 2, 0 },
				},
			},
		},
	},
	Charge = {
		dur = 0.5,
		loop = true,
		joints = {
			Body = {
				o = {
					{ "y", 6, 1, 0 },
				},
			},
			Head = {
				o = {
					{ "y", 8.4, 1, 0.5 },
				},
				k = {
					{ 0, 6, 0, 0 },
				},
			},
			Mid = {
				o = {
					{ "y", 14.4, 1, 0.15 },
				},
			},
			Tail = {
				o = {
					{ "y", 26.4, 1, 0.3 },
				},
			},
			TailFin = {
				o = {
					{ "y", 36, 1, 0.45 },
				},
			},
			LeftFin = {
				k = {
					{ 0, 0, 0, -55 },
				},
				o = {
					{ "z", 6, 2, 0 },
				},
			},
			RightFin = {
				k = {
					{ 0, 0, 0, 55 },
				},
				o = {
					{ "z", -6, 2, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -30, 0, 0 },
				},
				o = {
					{ "x", 8, 2, 0 },
				},
			},
		},
	},
	Bite = {
		dur = 0.6,
		loop = false,
		next = "Charge",
		joints = {
			LeftFin = {
				k = {
					{ 0, 0, 0, -40 },
				},
				o = {
					{ "z", 8, 3, 0 },
				},
			},
			RightFin = {
				k = {
					{ 0, 0, 0, 40 },
				},
				o = {
					{ "z", -8, 3, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.18, 16, 0, 0 },
					{ 0.3, -10, 0, 0 },
					{ 0.6, 0, 0, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -20, 0, 0 },
					{ 0.18, -62, 0, 0 },
					{ 0.28, 0, 0, 0 },
					{ 0.6, -20, 0, 0 },
				},
			},
			Body = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.28, -6, 0, 10 },
					{ 0.6, 0, 0, 0 },
				},
			},
			Mid = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.28, 0, -18, 0 },
					{ 0.6, 0, 0, 0 },
				},
			},
			Tail = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.3, 0, 30, 0 },
					{ 0.6, 0, 0, 0 },
				},
			},
			TailFin = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.32, 0, 40, 0 },
					{ 0.6, 0, 0, 0 },
				},
			},
		},
	},
	Leap = {
		dur = 1.4,
		loop = false,
		next = "Swim",
		joints = {
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.2, 22, 0, 0 },
					{ 0.55, 10, 0, 0 },
					{ 0.75, -18, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -10, 0, 0 },
					{ 0.45, -70, 0, 0 },
					{ 0.62, 0, 0, 0 },
					{ 0.9, -25, 0, 0 },
					{ 1.4, -8, 0, 0 },
				},
			},
			Mid = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.2, -14, 0, 0 },
					{ 0.7, 12, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
				o = {
					{ "y", 10, 5, 0 },
				},
			},
			Tail = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.2, -24, 0, 0 },
					{ 0.7, 26, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
				o = {
					{ "y", 18, 5, 0.2 },
				},
			},
			TailFin = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.2, -30, 0, 0 },
					{ 0.7, 30, 0, 0 },
					{ 1.4, 0, 0, 0 },
				},
				o = {
					{ "y", 26, 5, 0.4 },
				},
			},
			LeftFin = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.3, 0, 0, -35 },
					{ 1, 0, 0, 20 },
					{ 1.4, 0, 0, 0 },
				},
				o = {
					{ "z", 15, 6, 0 },
				},
			},
			RightFin = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.3, 0, 0, 35 },
					{ 1, 0, 0, -20 },
					{ 1.4, 0, 0, 0 },
				},
				o = {
					{ "z", -15, 6, 0 },
				},
			},
		},
	},
	Screech = {
		dur = 1.2,
		loop = false,
		next = "Charge",
		joints = {
			LeftFin = {
				k = {
					{ 0, 0, 0, 30 },
				},
				o = {
					{ "z", 10, 14, 0 },
				},
			},
			RightFin = {
				k = {
					{ 0, 0, 0, -30 },
				},
				o = {
					{ "z", -10, 14, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.2, 24, 0, 0 },
					{ 0.95, 22, 0, 0 },
					{ 1.2, 0, 0, 0 },
				},
				o = {
					{ "y", 3, 16, 0 },
					{ "x", 2, 21, 0.3 },
				},
			},
			Jaw = {
				k = {
					{ 0, -10, 0, 0 },
					{ 0.2, -78, 0, 0 },
					{ 0.95, -74, 0, 0 },
					{ 1.2, -25, 0, 0 },
				},
				o = {
					{ "x", 4, 18, 0 },
				},
			},
			Mid = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.2, 8, 0, 0 },
					{ 1.2, 0, 0, 0 },
				},
				o = {
					{ "y", 4, 12, 0 },
				},
			},
			Tail = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.2, 14, 0, 0 },
					{ 1.2, 0, 0, 0 },
				},
				o = {
					{ "y", 8, 12, 0.3 },
				},
			},
			TailFin = {
				o = {
					{ "y", 14, 12, 0.5 },
				},
			},
		},
	},
	Hurt = {
		dur = 0.45,
		loop = false,
		next = "Swim",
		joints = {
			Body = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.1, 0, 0, 22 },
					{ 0.45, 0, 0, 0 },
				},
			},
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.1, 10, 20, 0 },
					{ 0.45, 0, 0, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -6, 0, 0 },
					{ 0.1, -45, 0, 0 },
					{ 0.45, -6, 0, 0 },
				},
			},
			Mid = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.12, 0, -25, 0 },
					{ 0.45, 0, 0, 0 },
				},
			},
			Tail = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.14, 0, -35, 0 },
					{ 0.45, 0, 0, 0 },
				},
			},
			TailFin = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.16, 0, -40, 0 },
					{ 0.45, 0, 0, 0 },
				},
			},
		},
	},
	Death = {
		dur = 1.6,
		loop = false,
		joints = {
			Head = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.2, 15, -20, 0 },
					{ 0.5, -10, 15, 0 },
					{ 1.6, -8, 12, 0 },
				},
			},
			Jaw = {
				k = {
					{ 0, -6, 0, 0 },
					{ 0.3, -60, 0, 0 },
					{ 1.6, -42, 0, 0 },
				},
			},
			Mid = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.25, 0, 30, 0 },
					{ 0.55, 0, -25, 0 },
					{ 1.6, 0, -10, 0 },
				},
			},
			Tail = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.3, 0, 40, 0 },
					{ 0.6, 0, -35, 0 },
					{ 1.6, 0, -16, 0 },
				},
			},
			TailFin = {
				k = {
					{ 0, 0, 0, 0 },
					{ 0.35, 0, 45, 0 },
					{ 0.65, 0, -40, 0 },
					{ 1.6, 0, -20, 0 },
				},
			},
			LeftFin = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.6, 0, 0, 40 },
				},
			},
			RightFin = {
				k = {
					{ 0, 0, 0, 0 },
					{ 1.6, 0, 0, -40 },
				},
			},
		},
	},
}
]=======],
	Brain = [=======[
--[[
	FishBrain (ModuleScript) · ReplicatedStorage.Creatures.InfectedFish.FishBrain

	Lógica pura de un pez infectado (sin Instances: se prueba fuera de Roblox). El servidor (FishSpawner) le pasa lo
	que percibe y aplica las órdenes que devuelve.

	Estados: Wander · Screech · Circle · Chase · Bite · Leap · Hurt · Dead
	  · si estás dentro de su agua y a su distancia de detección: chilla (con recarga), te rodea un rato y embiste
	    (el gigante no rodea: embiste directo)
	  · muerde al llegar a su alcance, con su recarga
	  · si estás fuera del agua pero cerca del borde (canLeap), salta hacia ti (con su recarga)
	  · si sales del agua y no te alcanza un rato, vuelve a nadar a su aire

	Percepción (P): hasTarget, inWater, canLeap, dist, hurt, dead
	Órdenes: {"anim", nombre, fundido} · {"move", modo, velocidad} con modo "wander" | "circle" | "chase" | "stop"
	         {"attack", retardo} · {"leap"} · {"sound", nombre}
]]

local Brain = {}
Brain.__index = Brain

Brain.Defaults = {
	Detect = 45,
	Reach = 3.5,
	Cooldown = 1.2,
	SwimSpeed = 6,
	CircleSpeed = 11,
	ChaseSpeed = 17,
	Circle = true,
	CircleTime = { 2.5, 4.5 },
	ScreechCooldown = 20,
	LeapCooldown = 7,
	LeapTime = 1.4,
	LoseTime = 6,
}

function Brain.new(config, rng)
	local self = setmetatable({}, Brain)
	self.cfg = setmetatable(config or {}, { __index = Brain.Defaults })
	self.rng = rng or Random.new()
	self.t = 0
	self.nextAttack = 0
	self.nextScreech = 0
	self.nextLeap = 0
	self.lost = 0
	self.out = {}
	self:enter("Wander", 0)
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

function Brain:wander()
	self:emit("anim", "Swim", 0.4)
	self:emit("move", "wander", self.cfg.SwimSpeed)
	self:enter("Wander", 0)
end

function Brain:chase()
	self:emit("anim", "Charge", 0.25)
	self:emit("move", "chase", self.cfg.ChaseSpeed)
	self:enter("Chase", 0)
end

function Brain:circle()
	self:emit("anim", "Swim", 0.3)
	self:emit("move", "circle", self.cfg.CircleSpeed)
	self:enter("Circle", self:range(self.cfg.CircleTime))
end

function Brain:engage()
	if self.cfg.Circle then
		self:circle()
	else
		self:chase()
	end
end

function Brain:leap()
	local c = self.cfg
	self.nextLeap = self.t + c.LeapCooldown
	self:emit("anim", "Leap", 0.1)
	self:emit("leap")
	self:emit("sound", "Splash")
	self:enter("Leap", c.LeapTime)
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
	if s == "Leap" then   -- en el aire no se le puede interrumpir
		if self.timer <= 0 then
			if P.hasTarget and P.inWater then
				self:chase()
			else
				self:wander()
			end
		end
		return self.out
	end
	if P.hurt and s ~= "Bite" and s ~= "Screech" then
		self:emit("anim", "Hurt", 0.05)
		self:enter("Hurt", 0.45)
		return self.out
	end
	local sees = P.hasTarget and P.inWater and P.dist <= c.Detect
	local leapable = P.hasTarget and P.canLeap and not P.inWater and self.t >= self.nextLeap
	if s == "Wander" then
		if sees then
			if self.t >= self.nextScreech then
				self.nextScreech = self.t + c.ScreechCooldown
				self:emit("anim", "Screech", 0.15)
				self:emit("move", "stop", 0)
				self:emit("sound", "Screech")
				self:enter("Screech", 1.2)
			else
				self:engage()
			end
		elseif leapable then
			self:leap()
		elseif self.rng:NextNumber() < dt * 0.08 then
			self:emit("sound", "Gurgle")
		end
	elseif s == "Screech" then
		if self.timer <= 0 then
			self:engage()
		end
	elseif s == "Circle" then
		if not P.hasTarget or not P.inWater then
			self.lost += dt
			if leapable then
				self:leap()
			elseif self.lost > c.LoseTime then
				self.lost = 0
				self:wander()
			end
		else
			self.lost = 0
			if self.timer <= 0 then
				self:chase()
			end
		end
	elseif s == "Chase" then
		if not P.hasTarget or not P.inWater then
			self.lost += dt
			if leapable then
				self:leap()
			elseif self.lost > c.LoseTime then
				self.lost = 0
				self:wander()
			end
		elseif P.dist <= c.Reach and self.t >= self.nextAttack then
			self.lost = 0
			self.nextAttack = self.t + c.Cooldown
			self:emit("anim", "Bite", 0.08)
			self:emit("attack", 0.25)
			self:emit("sound", "Bite")
			self:enter("Bite", 0.6)
		else
			self.lost = 0
		end
	elseif s == "Bite" or s == "Hurt" then
		if self.timer <= 0 then
			if P.hasTarget and P.inWater then
				self:chase()
			elseif leapable then
				self:leap()
			else
				self:wander()
			end
		end
	end
	return self.out
end

return Brain
]=======],
	Spawner = [=======[
--[[
	FishSpawner (Script) · ServerScriptService.FishSpawner

	Crea y controla a los peces infectados (los mismos para todos los jugadores).
	  · Viven dentro de "zonas de agua": partes con la etiqueta "FishZone" o dentro de Workspace.FishZones.
	    La parte cubre el agua de la superficie (su cara de arriba) al fondo; suele ser invisible y sin colisión.
	  · Aparecen en bancos de 2 a 4 por zona (Settings.MaxPerZone); 1 de cada 8 es gigante (como máximo uno por zona).
	  · El servidor decide (FishBrain), los mueve con AlignPosition/AlignOrientation y publica el atributo Anim;
	    los clientes (FishClient) animan los Motor6D.
	  · Tienen Humanoid: cualquier arma les hace daño. Al morir se ponen panza arriba y flotan; reaparecen tras
	    Settings.RespawnDelay.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local folder = ReplicatedStorage:WaitForChild("Creatures"):WaitForChild("InfectedFish")
local Brain = require(folder:WaitForChild("FishBrain"))
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
local MAX_PER_ZONE = S("MaxPerZone", 4)
local RESPAWN = S("RespawnDelay", 25)
local DEBUG = S("Debug", false)

local STATS = {
	Normal = { Health = 60, Damage = 12, Reach = 3.5, Detect = 45, SwimSpeed = 6, CircleSpeed = 11, ChaseSpeed = 17, Cooldown = 1.2,
		LeapRange = 16, LeapCooldown = 7, LeapHeight = 4, Scale = 1, Circle = true, Chance = 0.875 },
	Giant = { Health = 320, Damage = 30, Reach = 7, Detect = 70, SwimSpeed = 5, CircleSpeed = 9, ChaseSpeed = 14, Cooldown = 2.0,
		LeapRange = 24, LeapCooldown = 12, LeapHeight = 7, Scale = 2.2, Circle = false, Chance = 0.125 },
}
for name, st in pairs(STATS) do   -- Settings: "GiantHealth", "NormalChaseSpeed", "GiantChance"...
	for k, v in pairs(st) do
		local o = settings:GetAttribute(name .. k)
		if o ~= nil and type(o) == type(v) then
			st[k] = o
		end
	end
end
local LEAP_OUT, LEAP_BACK = 0.8, 0.6   -- segundos del arco hacia el jugador y de la vuelta al agua (suman FishBrain.LeapTime)

local container = workspace:FindFirstChild("InfectedFish") or Instance.new("Folder")
container.Name = "InfectedFish"
container.Parent = workspace

-- ---------------------------------------------------------------- zonas de agua
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
local function inZone(zone, pos, margin)
	local lp = zone.CFrame:PointToObjectSpace(pos)
	local h = zone.Size / 2 + Vector3.one * margin
	return math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y and math.abs(lp.Z) <= h.Z
end
local function clampZone(zone, pos, margin)
	local lp = zone.CFrame:PointToObjectSpace(pos)
	local h = zone.Size / 2
	local mx, my, mz = math.max(h.X - margin, 0), math.max(h.Y - margin, 0), math.max(h.Z - margin, 0)
	return zone.CFrame:PointToWorldSpace(Vector3.new(math.clamp(lp.X, -mx, mx), math.clamp(lp.Y, -my, my), math.clamp(lp.Z, -mz, mz)))
end
local function randomInZone(zone, margin)
	local h = zone.Size / 2
	local r = function(a)
		local m = math.max(a - margin, 0)
		return (rng:NextNumber() * 2 - 1) * m
	end
	return zone.CFrame:PointToWorldSpace(Vector3.new(r(h.X), r(h.Y), r(h.Z)))
end
local function surfaceY(zone)
	return zone.Position.Y + zone.Size.Y / 2
end
local function edgeDistance(zone, pos)   -- distancia horizontal de un punto al borde de la zona (0 si está encima)
	local lp = zone.CFrame:PointToObjectSpace(pos)
	local h = zone.Size / 2
	local dx, dz = math.max(0, math.abs(lp.X) - h.X), math.max(0, math.abs(lp.Z) - h.Z)
	return math.sqrt(dx * dx + dz * dz)
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

-- ---------------------------------------------------------------- efectos
local function sound(f, name)
	local s = f.root:FindFirstChild(name)
	if s and s:IsA("Sound") and s.SoundId ~= "" then
		s:Play()
	end
end
local function splash(pos, scale)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.one
	p.CFrame = CFrame.new(pos)
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5 * scale), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.5, 0.9)
	e.Speed = NumberRange.new(10 * math.sqrt(scale), 20 * math.sqrt(scale))
	e.SpreadAngle = Vector2.new(35, 35)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -45, 0)
	e.Rate = 0
	e.Parent = p
	p.Parent = workspace
	e:Emit(math.floor(24 * scale))
	Debris:AddItem(p, 2)
end

-- ---------------------------------------------------------------- peces
local fishes = {}
local stamp = 0
local clock = 0

local function setAnim(f, name, fade)
	stamp += 1
	f.model:SetAttribute("Anim", name)
	f.model:SetAttribute("AnimFade", fade or 0.3)
	f.model:SetAttribute("AnimStamp", stamp)
end
local function headPos(f)
	return f.root.CFrame:PointToWorldSpace(Vector3.new(0, 0, -1.6 * f.st.Scale))
end
local function count(zone)
	local n, giant = 0, false
	for _, f in pairs(fishes) do
		if f.zone == zone and not f.dead then
			n += 1
			giant = giant or f.type == "Giant"
		end
	end
	return n, giant
end

local function spawnFish(zone, typeName, near)
	local st = STATS[typeName]
	local proto = types:FindFirstChild(typeName)
	if not proto then
		return
	end
	local model = proto:Clone()
	local root = model:WaitForChild("Root")
	local hum = model:FindFirstChildOfClass("Humanoid")
	local margin = 1.2 * st.Scale
	local pos = near and clampZone(zone, near + Vector3.new(rng:NextNumber() * 6 - 3, rng:NextNumber() * 2 - 1, rng:NextNumber() * 6 - 3), margin) or randomInZone(zone, margin)
	local heading = Vector3.new(rng:NextNumber() * 2 - 1, 0, rng:NextNumber() * 2 - 1)
	heading = heading.Magnitude > 0.1 and heading.Unit or Vector3.new(0, 0, -1)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = d ~= root
		end
	end
	model:PivotTo(CFrame.lookAt(pos, pos + heading))
	local att = Instance.new("Attachment")
	att.Name = "Swim"
	att.Parent = root
	local ap = Instance.new("AlignPosition")
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment
	ap.Attachment0 = att
	ap.MaxForce = 1e7
	ap.Responsiveness = 35
	ap.Position = pos
	ap.Parent = root
	local ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.MaxTorque = 1e7
	ao.Responsiveness = 25
	ao.CFrame = CFrame.lookAt(Vector3.zero, heading)
	ao.Parent = root
	if hum then
		hum.MaxHealth = st.Health
		hum.Health = st.Health
	end
	model.Parent = container
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	local f = {
		model = model, root = root, hum = hum, ap = ap, ao = ao, zone = zone, type = typeName, st = st, margin = margin,
		pos = pos, heading = heading, speed = st.SwimSpeed, want = st.SwimSpeed, mode = "wander", circAng = rng:NextNumber() * 6.28,
		lastHealth = st.Health, nextThink = 0,
		brain = Brain.new({
			Detect = st.Detect, Reach = st.Reach, Cooldown = st.Cooldown, SwimSpeed = st.SwimSpeed, CircleSpeed = st.CircleSpeed,
			ChaseSpeed = st.ChaseSpeed, Circle = st.Circle, LeapCooldown = st.LeapCooldown, LeapTime = LEAP_OUT + LEAP_BACK,
		}, Random.new(rng:NextInteger(1, 1e6))),
	}
	fishes[model] = f
	setAnim(f, "Swim", 0)
	model.Destroying:Connect(function()
		fishes[model] = nil
	end)
	return f
end

local function spawnSchool(zone)
	local n, hasGiant = count(zone)
	local room = MAX_PER_ZONE - n
	if room <= 0 then
		return
	end
	local center
	for _ = 1, 12 do   -- lejos de los jugadores si se puede
		center = randomInZone(zone, 2)
		local far = true
		for _, p in ipairs(Players:GetPlayers()) do
			local h = alive(p)
			if h and (h.Position - center).Magnitude < 25 then
				far = false
			end
		end
		if far then
			break
		end
	end
	for _ = 1, math.min(room, rng:NextInteger(2, 4)) do
		local giant = not hasGiant and rng:NextNumber() < STATS.Giant.Chance
		hasGiant = hasGiant or giant
		spawnFish(zone, giant and "Giant" or "Normal", center)
	end
end

-- ---------------------------------------------------------------- percepción y órdenes
local function perceive(f)
	local zone, st = f.zone, f.st
	local head = headPos(f)
	local surf = surfaceY(zone)
	local best, bestD, bestWater = nil, math.huge, false
	for _, p in ipairs(Players:GetPlayers()) do
		local h = alive(p)
		if h then
			local d = (h.Position - head).Magnitude
			local wet = inZone(zone, h.Position, 1.5)
			local flat = Vector3.new(h.Position.X - f.pos.X, 0, h.Position.Z - f.pos.Z).Magnitude
			local shore = not wet and edgeDistance(zone, h.Position) <= 5 and h.Position.Y <= surf + 10 and h.Position.Y >= surf - 3 and flat <= st.LeapRange
			if (wet and d <= st.Detect) or shore then
				-- prefiere a quien está en el agua; entre iguales, al más cercano (y al que ya perseguía)
				local score = d - (wet and 1000 or 0) - (f.target == p and 5 or 0)
				if score < bestD then
					best, bestD, bestWater = p, score, wet
				end
			end
		end
	end
	f.target = best
	local h = best and alive(best)
	local health = f.hum and f.hum.Health or 1
	local hurt = health < f.lastHealth - 0.5
	f.lastHealth = health
	local dist = h and (h.Position - head).Magnitude or math.huge
	return {
		hasTarget = h ~= nil, inWater = bestWater, canLeap = h ~= nil and not bestWater, dist = dist,
		hurt = hurt, dead = health <= 0,
	}
end

local function startLeap(f)
	local h = f.target and alive(f.target)
	if not h then
		return
	end
	local zone, sc = f.zone, f.st.Scale
	local surf = surfaceY(zone)
	local A = Vector3.new(f.pos.X, surf - 0.4 * sc, f.pos.Z)
	local B = h.Position + h.AssemblyLinearVelocity * Vector3.new(0.25, 0, 0.25)
	local inward = (A - Vector3.new(B.X, A.Y, B.Z))
	inward = inward.Magnitude > 0.1 and inward.Unit or -f.heading
	local back = clampZone(zone, A + inward * 5 - Vector3.new(0, 2 * sc, 0), f.margin)
	f.leap = { t = 0, A = A, B = B, H = f.st.LeapHeight + math.max(0, B.Y - A.Y), back = back, bitten = false, splashed = false }
	f.ap.Responsiveness = 120
	f.ao.Responsiveness = 60
	splash(Vector3.new(A.X, surf, A.Z), sc)
end

local function bite(f, reachMul)
	local h, hum = nil, nil
	if f.target then
		h, hum = alive(f.target)
	end
	if h and hum and (h.Position - headPos(f)).Magnitude <= f.st.Reach * reachMul then
		hum:TakeDamage(f.st.Damage)
		return true
	end
	return false
end

local function apply(f, orders)
	for _, o in ipairs(orders) do
		local kind = o[1]
		if kind == "anim" then
			setAnim(f, o[2], o[3])
		elseif kind == "move" then
			f.mode, f.want = o[2], o[3]
		elseif kind == "attack" then
			task.delay(o[2], function()
				if fishes[f.model] and not f.dead then
					bite(f, 1.4)
				end
			end)
		elseif kind == "leap" then
			startLeap(f)
		elseif kind == "sound" then
			sound(f, o[2])
		end
		if DEBUG and kind == "anim" then
			print(("[Fish] %s %s → %s"):format(f.type, f.model:GetFullName(), o[2]))
		end
	end
end

local function die(f)
	f.dead = true
	f.ap.Responsiveness = 6
	f.ao.Responsiveness = 4
	local zone = f.zone
	task.delay(10, function()
		if f.model.Parent then
			f.model:Destroy()
		end
	end)
	task.delay(RESPAWN, function()
		if zone.Parent then
			spawnSchool(zone)
		end
	end)
end

-- ---------------------------------------------------------------- movimiento (cada frame)
local function steer(f, dir, rate, dt)
	if dir.Magnitude < 1e-3 then
		return
	end
	dir = dir.Unit
	dir = Vector3.new(dir.X, math.clamp(dir.Y, -0.6, 0.6), dir.Z).Unit
	if f.heading:Dot(dir) < -0.98 then
		dir = (dir + f.heading:Cross(Vector3.yAxis) * 0.2).Unit
	end
	local a = math.acos(math.clamp(f.heading:Dot(dir), -1, 1))
	if a > 1e-3 then
		f.heading = f.heading:Lerp(dir, math.min(1, rate * dt / a)).Unit
	end
end

local function moveLeap(f, dt)
	local L = f.leap
	L.t += dt
	local p, dir
	if L.t < LEAP_OUT then
		local u = L.t / LEAP_OUT
		p = L.A:Lerp(L.B, u) + Vector3.new(0, 4 * L.H * u * (1 - u), 0)
		dir = (L.B - L.A) + Vector3.new(0, 4 * L.H * (1 - 2 * u), 0)
		if u >= 0.8 and not L.bitten then
			L.bitten = true
			if bite(f, 1.6) then
				sound(f, "Bite")
			end
		end
	elseif L.t < LEAP_OUT + LEAP_BACK then
		local u = (L.t - LEAP_OUT) / LEAP_BACK
		p = L.B:Lerp(L.back, u) + Vector3.new(0, 6 * u * (1 - u), 0)
		dir = (L.back - L.B) + Vector3.new(0, 6 * (1 - 2 * u), 0)
		if not L.splashed and p.Y <= surfaceY(f.zone) then
			L.splashed = true
			splash(Vector3.new(p.X, surfaceY(f.zone), p.Z), f.st.Scale)
			sound(f, "Splash")
		end
	else
		f.leap = nil
		f.pos = L.back
		f.ap.Responsiveness = 35
		f.ao.Responsiveness = 25
		local flat = Vector3.new(f.heading.X, 0, f.heading.Z)
		f.heading = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, -1)
		return
	end
	f.pos = p
	if dir.Magnitude > 1e-3 then
		f.heading = dir.Unit
	end
	f.ap.Position = p
	f.ao.CFrame = CFrame.lookAt(Vector3.zero, f.heading)
end

local function move(f, dt)
	if f.leap then
		moveLeap(f, dt)
		return
	end
	local zone = f.zone
	if f.dead then   -- flota panza arriba hasta la superficie
		local top = surfaceY(zone) - 0.35 * f.st.Scale
		f.pos = Vector3.new(f.pos.X, math.min(top, f.pos.Y + dt * 1.5), f.pos.Z)
		f.ap.Position = f.pos
		local flat = Vector3.new(f.heading.X, 0, f.heading.Z)
		flat = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, -1)
		f.ao.CFrame = CFrame.lookAt(Vector3.zero, flat) * CFrame.Angles(0, 0, math.pi)
		return
	end
	local h = f.target and alive(f.target)
	local T
	if f.mode == "chase" and h then
		T = clampZone(zone, h.Position, f.margin)
	elseif f.mode == "circle" and h then
		local center = clampZone(zone, h.Position, f.margin)
		local R = 6 + 2 * f.st.Scale
		f.circAng += dt * math.max(f.speed, 1) / R
		T = clampZone(zone, center + Vector3.new(math.cos(f.circAng) * R, 0, math.sin(f.circAng) * R), f.margin)
	elseif f.mode == "stop" then
		T = f.pos + f.heading
	else
		if not f.wp or (f.wp - f.pos).Magnitude < 3 * f.st.Scale or clock > (f.wpT or 0) then
			f.wp = randomInZone(zone, f.margin)
			f.wpT = clock + 10
		end
		T = f.wp
	end
	local want = f.mode == "stop" and 0.6 or f.want
	f.speed += (want - f.speed) * math.min(1, dt * 2.5)
	steer(f, T - f.pos, (f.mode == "chase" or f.mode == "circle") and 3.2 or 1.8, dt)
	local toT = (T - f.pos).Magnitude
	local sp = f.speed
	if f.mode == "chase" and toT < 1.5 then
		sp = sp * toT / 1.5   -- espera en el borde cuando el jugador está fuera del agua
	end
	f.pos = clampZone(zone, f.pos + f.heading * sp * dt, f.margin)
	f.ap.Position = f.pos
	f.ao.CFrame = CFrame.lookAt(Vector3.zero, f.heading)
end

RunService.Heartbeat:Connect(function(dt)
	clock += dt
	for _, f in pairs(fishes) do
		if f.zone.Parent == nil then
			f.model:Destroy()
		else
			if not f.dead and clock >= f.nextThink then   -- decide 10 veces por segundo
				local step = clock - (f.lastThink or clock - 0.1)
				f.lastThink = clock
				f.nextThink = clock + 0.1
				local P = perceive(f)
				apply(f, f.brain:Update(step, P))
				if P.dead then
					die(f)
				end
			end
			move(f, dt)
		end
	end
end)

-- población: cada zona mantiene su banco
local warned = false
task.spawn(function()
	while true do
		local list = zones()
		if #list == 0 and not warned then
			warned = true
			warn("[InfectedFish] No hay zonas de agua: pon una parte con la etiqueta FishZone (o dentro de Workspace.FishZones) que cubra el agua.")
		end
		for _, z in ipairs(list) do
			local n = count(z)
			if n == 0 then
				spawnSchool(z)
			end
		end
		task.wait(5)
	end
end)
]=======],
	Client = [=======[
--[[
	FishClient (LocalScript) · StarterPlayer.StarterPlayerScripts.FishClient

	Anima a los peces infectados en cada jugador: lee el atributo Anim que publica el servidor y mueve sus Motor6D con
	DragonAnimator (Roblox no replica Motor6D.Transform desde el servidor). Los peces los mueve el
	servidor (AlignPosition); aquí solo se anima. Rendimiento: lejos se anima menos veces por segundo y muy lejos se pausa.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DragonAnimator = require(ReplicatedStorage:WaitForChild("Dragons"):WaitForChild("DragonAnimator"))
local animations = require(ReplicatedStorage:WaitForChild("Creatures"):WaitForChild("InfectedFish"):WaitForChild("Animations"))
local container = workspace:WaitForChild("InfectedFish")
local entries = {}

local function setup(model)
	if entries[model] or not model:IsA("Model") then
		return
	end
	local e = { model = model }
	e.animator = DragonAnimator.new(model, animations)
	e.animator:Play(model:GetAttribute("Anim") or "Swim", 0)
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
	m:WaitForChild("Root", 5)
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
local CollectionService = game:GetService("CollectionService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar el pez infectado")
end)

local function v3(t)
	return Vector3.new(t[1], t[2], t[3])
end
local function rgb(t)
	return Color3.fromRGB(t[1], t[2], t[3])
end
local function material(name)
	local ok, m = pcall(function()
		return Enum.Material[name]
	end)
	return ok and m or Enum.Material.SmoothPlastic
end

-- construye un pez a partir de su plano
local function build(name, bp, scale)
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
		else
			p.Color = rgb(L.color)
			p.Material = material(L.material or "SmoothPlastic")
			p.Massless = true
		end
		p.CanCollide = false
		p.CanTouch = not L.transparent   -- las espadas que dañan por contacto (Touched) también le dan
		p.Parent = model
		parts[limb] = p
	end
	model.PrimaryPart = parts.Root
	for _, j in ipairs(bp.joints) do
		local p0, p1, piv = parts[j[1]], parts[j[2]], CFrame.new(v3(j[3]))
		local m = Instance.new("Motor6D")
		m.Name = j[2]
		m.Part0, m.Part1 = p0, p1
		m.C0 = p0.CFrame:Inverse() * piv
		m.C1 = p1.CFrame:Inverse() * piv
		m.Parent = p0
	end
	for _, d in ipairs(bp.details) do
		local limb = parts[d.limb]
		local p = Instance.new("Part")
		p.Name = d.neon and "Glow" or "Detail"
		p.Size = v3(d.size)
		p.CFrame = CFrame.new(limb.Position + v3(d.offset)) * CFrame.Angles(math.rad(d.rot[1]), math.rad(d.rot[2]), math.rad(d.rot[3]))
		p.Color = rgb(d.color)
		p.Material = d.neon and Enum.Material.Neon or material(d.material)
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CanCollide, p.CanTouch, p.Massless = false, false, true
		p.CastShadow = not d.neon
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = limb, p
		w.Parent = p
		p.Parent = limb
	end
	local hum = Instance.new("Humanoid")
	hum.HipHeight = 0
	hum.RequiresNeck = false
	hum.BreakJointsOnDeath = false
	hum.AutomaticScalingEnabled = false
	hum.EvaluateStateMachine = false   -- no camina ni nada: lo mueve el servidor
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.Parent = model
	for sname, id in pairs(SOUND_IDS) do
		local s = Instance.new("Sound")
		s.Name = sname
		s.SoundId = id
		s.Volume = sname == "Gurgle" and 0.4 or 0.9
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 6
		s.RollOffMaxDistance = sname == "Screech" and 140 or 70
		s.Parent = parts.Root
	end
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
	end
	model:SetAttribute("Scale", scale or 1)
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

local folder = ensure(ensure(ReplicatedStorage, "Creatures"), "InfectedFish")
local old = folder:FindFirstChild("Types")
if old then
	old:Destroy()
end
local typesFolder = ensure(folder, "Types")
for _, name in ipairs({ "Normal", "Giant" }) do
	build(name, BLUEPRINTS[name], STATS[name].Scale).Parent = typesFolder
end
local settings = ensure(folder, "Settings", "Configuration")
for k, v in pairs({ MaxPerZone = MAX_PER_ZONE, RespawnDelay = RESPAWN_DELAY, GiantChance = GIANT_CHANCE, Debug = false }) do
	settings:SetAttribute(k, v)
end
for name, st in pairs(STATS) do
	for k, v in pairs(st) do
		if type(v) ~= "string" then
			settings:SetAttribute(name .. k, v)
		end
	end
end
settings:SetAttribute("GiantChance", GIANT_CHANCE)
putScript(ensure(ReplicatedStorage, "Dragons"), "DragonAnimator", "ModuleScript", SOURCES.DragonAnimator)
putScript(folder, "Animations", "ModuleScript", SOURCES.Animations)
putScript(folder, "FishBrain", "ModuleScript", SOURCES.Brain)
putScript(game:GetService("ServerScriptService"), "FishSpawner", "Script", SOURCES.Spawner)
putScript(ensure(StarterPlayer, "StarterPlayerScripts", "StarterPlayerScripts"), "FishClient", "LocalScript", SOURCES.Client)

-- estanque de prueba: agua de Terrain dentro de un muro de piedra, con una rampa para subir al borde
if DEMO_POND then
	local oldPond = workspace:FindFirstChild("FishPond")
	if oldPond then
		oldPond:Destroy()
	end
	local pond = Instance.new("Model")
	pond.Name = "FishPond"
	local c = POND_CENTER
	workspace.Terrain:FillBlock(CFrame.new(c + Vector3.new(0, POND_DEPTH / 2, 0)), Vector3.new(POND_SIZE, POND_DEPTH, POND_SIZE), Enum.Material.Water)
	local function block(name, size, pos, mat, color, class)
		local p = Instance.new(class or "Part")
		p.Name = name
		p.Size = size
		p.CFrame = typeof(pos) == "CFrame" and pos or CFrame.new(pos)
		p.Anchored = true
		p.Material = mat
		p.Color = color
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = pond
		return p
	end
	local wallH, t = POND_DEPTH + 1, 4
	local half = POND_SIZE / 2 + t / 2
	local stone = Color3.fromRGB(96, 98, 92)
	block("Floor", Vector3.new(POND_SIZE, 1, POND_SIZE), c + Vector3.new(0, -0.5, 0), Enum.Material.Mud, Color3.fromRGB(58, 52, 40))
	block("WallN", Vector3.new(POND_SIZE + 2 * t, wallH, t), c + Vector3.new(0, wallH / 2, -half), Enum.Material.Slate, stone)
	block("WallS", Vector3.new(POND_SIZE + 2 * t, wallH, t), c + Vector3.new(0, wallH / 2, half), Enum.Material.Slate, stone)
	block("WallW", Vector3.new(t, wallH, POND_SIZE), c + Vector3.new(-half, wallH / 2, 0), Enum.Material.Slate, stone)
	block("WallE", Vector3.new(t, wallH, POND_SIZE), c + Vector3.new(half, wallH / 2, 0), Enum.Material.Slate, stone)
	-- rampa hasta lo alto del muro oeste
	block("Ramp", Vector3.new(8, wallH, wallH * 2), CFrame.new(c + Vector3.new(-half - t / 2 - wallH, wallH / 2, 0)) * CFrame.Angles(0, math.pi / 2, 0), Enum.Material.Slate, stone, "WedgePart")   -- lo alto de la cuña (+Z) contra el muro
	pond.Parent = workspace
	local zf = ensure(workspace, "FishZones")
	local oldZone = zf:FindFirstChild("Pond")
	if oldZone then
		oldZone:Destroy()
	end
	local zone = Instance.new("Part")
	zone.Name = "Pond"
	zone.Size = Vector3.new(POND_SIZE - 1, POND_DEPTH - 0.5, POND_SIZE - 1)
	zone.CFrame = CFrame.new(c + Vector3.new(0, (POND_DEPTH - 0.5) / 2, 0))
	zone.Anchored, zone.CanCollide, zone.CanQuery, zone.CanTouch = true, false, false, false
	zone.Transparency = 1
	zone.Parent = zf
	CollectionService:AddTag(zone, "FishZone")
end

-- vista previa en Studio: los dos peces anclados (se destruye al pulsar Play)
local prev = workspace:FindFirstChild("InfectedFishPreview")
if prev then
	prev:Destroy()
end
prev = Instance.new("Model")
prev.Name = "InfectedFishPreview"
local spots = { Normal = CFrame.new(-6, 4, -30), Giant = CFrame.new(8, 7, -30) }
for name, cf in pairs(spots) do
	local m = typesFolder[name]:Clone()
	m:PivotTo(cf * CFrame.Angles(0, math.pi / 2, 0))
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
	ChangeHistoryService:SetWaypoint("Pez infectado instalado")
end)
print(("[InfectedFish] Listo: pez normal y gigante construidos con Parts.%s Vista previa en Workspace.InfectedFishPreview."):format(
	DEMO_POND and " Estanque de prueba en Workspace.FishPond: al pulsar Play, sube por la rampa y métete en el agua." or ""))
