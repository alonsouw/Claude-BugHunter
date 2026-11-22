--[[
	INSTALADOR DE LAS ARMADURAS (cuero, lobo, dragón) · Roblox Studio
	Archivo generado por tools/build_roblox.js: no lo edites a mano, edita la plantilla.

	No hace falta importar nada: pega TODO este archivo en View > Command Bar y pulsa Enter.

	Resultado:
	  ReplicatedStorage.Armor.ArmorData       (planos y estadísticas: reducción de daño y velocidad)
	  ReplicatedStorage.Armor.ArmorBuilder    (construye y ajusta las piezas sobre un cuerpo R15 o R6)
	  ServerScriptService.ArmorService        (equipar, defensa, velocidad, conservar al reaparecer)
	  Workspace.ArmorStands                   (tres maniquíes con la armadura puesta y el botón «Equipar» (E))
]]

local STANDS_ORIGIN = CFrame.new(0, 0, -20)   -- dónde colocar los maniquíes (luego se pueden mover)

local SOURCES = {
	Data = [=======[
--[[
	ArmorData (ModuleScript) · ReplicatedStorage.Armor.ArmorData
	Planos de las armaduras (piezas por parte del cuerpo R15) y estadísticas. Generado desde src/armor_blueprints.js.
	stats: Reduction = parte del daño que se devuelve (0,45 = −45 %), Speed = suma a WalkSpeed. Se pueden editar aquí.
]]
return {
	dummy = {
		Head = { 1.2, 1.2, 1.2 },
		UpperTorso = { 2, 1.6, 1 },
		LowerTorso = { 2, 0.4, 1 },
		RightUpperArm = { 1, 1.169, 1 },
		LeftUpperArm = { 1, 1.169, 1 },
		RightLowerArm = { 1, 1.052, 1 },
		LeftLowerArm = { 1, 1.052, 1 },
		RightHand = { 1, 0.3, 1 },
		LeftHand = { 1, 0.3, 1 },
		RightUpperLeg = { 1, 1.217, 1 },
		LeftUpperLeg = { 1, 1.217, 1 },
		RightLowerLeg = { 1, 1.193, 1 },
		LeftLowerLeg = { 1, 1.193, 1 },
		RightFoot = { 1, 0.3, 1 },
		LeftFoot = { 1, 0.3, 1 },
	},
	dummyParts = {
		Head = {
			size = { 1.2, 1.2, 1.2 },
			center = { 0, 5.31, 0 },
		},
		UpperTorso = {
			size = { 2, 1.6, 1 },
			center = { 0, 3.91, 0 },
		},
		LowerTorso = {
			size = { 2, 0.4, 1 },
			center = { 0, 2.91, 0 },
		},
		RightUpperArm = {
			size = { 1, 1.169, 1 },
			center = { 1.5, 4.1255, 0 },
		},
		LeftUpperArm = {
			size = { 1, 1.169, 1 },
			center = { -1.5, 4.1255, 0 },
		},
		RightLowerArm = {
			size = { 1, 1.052, 1 },
			center = { 1.5, 3.015, 0 },
		},
		LeftLowerArm = {
			size = { 1, 1.052, 1 },
			center = { -1.5, 3.015, 0 },
		},
		RightHand = {
			size = { 1, 0.3, 1 },
			center = { 1.5, 2.339, 0 },
		},
		LeftHand = {
			size = { 1, 0.3, 1 },
			center = { -1.5, 2.339, 0 },
		},
		RightUpperLeg = {
			size = { 1, 1.217, 1 },
			center = { 0.5, 2.1015, 0 },
		},
		LeftUpperLeg = {
			size = { 1, 1.217, 1 },
			center = { -0.5, 2.1015, 0 },
		},
		RightLowerLeg = {
			size = { 1, 1.193, 1 },
			center = { 0.5, 0.8965, 0 },
		},
		LeftLowerLeg = {
			size = { 1, 1.193, 1 },
			center = { -0.5, 0.8965, 0 },
		},
		RightFoot = {
			size = { 1, 0.3, 1 },
			center = { 0.5, 0.15, 0 },
		},
		LeftFoot = {
			size = { 1, 0.3, 1 },
			center = { -0.5, 0.15, 0 },
		},
	},
	sets = {
		Leather = {
			name = "Leather",
			pieces = {
				{
					part = "Head",
					size = { 1.32, 0.42, 1.32 },
					offset = { 0, 0.44, 0.04 },
					color = { 112, 74, 44 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 1.34, 0.14, 1.34 },
					offset = { 0, 0.22, 0 },
					color = { 74, 48, 30 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.16, 0.7, 1.1 },
					offset = { 0.66, -0.05, 0.1 },
					color = { 112, 74, 44 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.16, 0.7, 1.1 },
					offset = { -0.66, -0.05, 0.1 },
					color = { 112, 74, 44 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 1.32, 0.9, 0.16 },
					offset = { 0, 0, 0.66 },
					color = { 112, 74, 44 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 2.12, 1.66, 1.14 },
					offset = { 0, 0.02, 0 },
					color = { 112, 74, 44 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.14, 1.5, 0.06 },
					offset = { 0, 0, -0.6 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.36, 0.05, 0.05 },
					offset = { 0, 0.6, -0.62 },
					color = { 190, 160, 108 },
					material = "SmoothPlastic",
					rot = { 0, 0, -20 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.36, 0.05, 0.05 },
					offset = { 0, 0.3, -0.62 },
					color = { 190, 160, 108 },
					material = "SmoothPlastic",
					rot = { 0, 0, 20 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.36, 0.05, 0.05 },
					offset = { 0, 0, -0.62 },
					color = { 190, 160, 108 },
					material = "SmoothPlastic",
					rot = { 0, 0, -20 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.36, 0.05, 0.05 },
					offset = { 0, -0.3, -0.62 },
					color = { 190, 160, 108 },
					material = "SmoothPlastic",
					rot = { 0, 0, 20 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.36, 0.05, 0.05 },
					offset = { 0, -0.6, -0.62 },
					color = { 190, 160, 108 },
					material = "SmoothPlastic",
					rot = { 0, 0, -20 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.24, 2.3, 0.08 },
					offset = { 0.15, 0.05, -0.62 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 40 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.24, 2.3, 0.08 },
					offset = { -0.15, 0.05, 0.62 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, -40 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.28, 0.22, 0.1 },
					offset = { 0.42, 0.42, -0.66 },
					color = { 200, 164, 74 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 2.18, 0.2, 1.2 },
					offset = { 0, 0.82, 0 },
					color = { 74, 48, 30 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 2.18, 0.32, 1.18 },
					offset = { 0, 0, 0 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.34, 0.26, 0.1 },
					offset = { 0, 0, -0.62 },
					color = { 200, 164, 74 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 0.5, 0.45, 0.35 },
					offset = { 0.55, 0.42, -0.25 },
					color = { 112, 74, 44 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 0.5, 0.45, 0.35 },
					offset = { -0.55, 0.42, -0.25 },
					color = { 112, 74, 44 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 0.5, 0.08, 0.37 },
					offset = { 0.55, 0.66, -0.25 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 0.5, 0.08, 0.37 },
					offset = { -0.55, 0.66, -0.25 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 1.22, 0.36, 1.22 },
					offset = { 0.05, 0.42, 0 },
					color = { 112, 74, 44 },
					material = "Fabric",
					rot = { 0, 0, -8 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 1.22, 0.36, 1.22 },
					offset = { -0.05, 0.42, 0 },
					color = { 112, 74, 44 },
					material = "Fabric",
					rot = { 0, 0, 8 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 1.24, 0.08, 1.24 },
					offset = { 0.05, 0.26, 0 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 1.24, 0.08, 1.24 },
					offset = { -0.05, 0.26, 0 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 1.12, 0.72, 1.12 },
					offset = { 0, -0.1, 0 },
					color = { 112, 74, 44 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 1.12, 0.72, 1.12 },
					offset = { 0, -0.1, 0 },
					color = { 112, 74, 44 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 1.14, 0.08, 1.14 },
					offset = { 0, 0.15, 0 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 1.14, 0.08, 1.14 },
					offset = { 0, 0.15, 0 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 1.14, 0.08, 1.14 },
					offset = { 0, -0.3, 0 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 1.14, 0.08, 1.14 },
					offset = { 0, -0.3, 0 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightHand",
					size = { 1.06, 0.26, 1.06 },
					offset = { 0, 0, 0 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftHand",
					size = { 1.06, 0.26, 1.06 },
					offset = { 0, 0, 0 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 1.08, 0.7, 0.2 },
					offset = { 0, -0.1, -0.52 },
					color = { 112, 74, 44 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 1.08, 0.7, 0.2 },
					offset = { 0, -0.1, -0.52 },
					color = { 112, 74, 44 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerLeg",
					size = { 1.12, 0.95, 1.12 },
					offset = { 0, -0.1, 0 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerLeg",
					size = { 1.12, 0.95, 1.12 },
					offset = { 0, -0.1, 0 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerLeg",
					size = { 1.16, 0.14, 1.16 },
					offset = { 0, 0.32, 0 },
					color = { 112, 74, 44 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerLeg",
					size = { 1.16, 0.14, 1.16 },
					offset = { 0, 0.32, 0 },
					color = { 112, 74, 44 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerLeg",
					size = { 0.2, 0.12, 0.08 },
					offset = { 0, 0, -0.58 },
					color = { 200, 164, 74 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerLeg",
					size = { 0.2, 0.12, 0.08 },
					offset = { 0, 0, -0.58 },
					color = { 200, 164, 74 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightFoot",
					size = { 1.12, 0.36, 1.3 },
					offset = { 0, 0.02, -0.12 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftFoot",
					size = { 1.12, 0.36, 1.3 },
					offset = { 0, 0.02, -0.12 },
					color = { 74, 48, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightFoot",
					size = { 1.14, 0.08, 1.32 },
					offset = { 0, -0.15, -0.12 },
					color = { 40, 28, 20 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftFoot",
					size = { 1.14, 0.08, 1.32 },
					offset = { 0, -0.15, -0.12 },
					color = { 40, 28, 20 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
			},
		},
		Wolf = {
			name = "Wolf",
			pieces = {
				{
					part = "Head",
					size = { 1.36, 0.5, 1.36 },
					offset = { 0, 0.5, 0.05 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.66, 0.38, 0.75 },
					offset = { 0, 0.5, -0.95 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.5, 0.18, 0.7 },
					offset = { 0, 0.32, -0.95 },
					color = { 176, 172, 162 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.22, 0.16, 0.12 },
					offset = { 0, 0.6, -1.33 },
					color = { 30, 26, 26 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.28, 0.42, 0.14 },
					offset = { -0.42, 0.88, 0.1 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, 10 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.14, 0.26, 0.06 },
					offset = { -0.42, 0.86, 0.02 },
					color = { 84, 80, 74 },
					material = "SmoothPlastic",
					rot = { 0, 0, 10 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.16, 0.08, 0.06 },
					offset = { -0.38, 0.62, -0.62 },
					color = { 250, 210, 90 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = true,
				},
				{
					part = "Head",
					size = { 0.06, 0.12, 0.06 },
					offset = { -0.26, 0.24, -0.72 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.06, 0.12, 0.06 },
					offset = { -0.26, 0.24, -0.9 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.06, 0.12, 0.06 },
					offset = { -0.26, 0.24, -1.08 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.28, 0.42, 0.14 },
					offset = { 0.42, 0.88, 0.1 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, -10 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.14, 0.26, 0.06 },
					offset = { 0.42, 0.86, 0.02 },
					color = { 84, 80, 74 },
					material = "SmoothPlastic",
					rot = { 0, 0, -10 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.16, 0.08, 0.06 },
					offset = { 0.38, 0.62, -0.62 },
					color = { 250, 210, 90 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = true,
				},
				{
					part = "Head",
					size = { 0.06, 0.12, 0.06 },
					offset = { 0.26, 0.24, -0.72 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.06, 0.12, 0.06 },
					offset = { 0.26, 0.24, -0.9 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.06, 0.12, 0.06 },
					offset = { 0.26, 0.24, -1.08 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 1.4, 1.1, 0.4 },
					offset = { 0, 0, 0.62 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.2, 0.95, 1.2 },
					offset = { -0.7, 0.02, 0.15 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.2, 0.95, 1.2 },
					offset = { 0.7, 0.02, 0.15 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 2.1, 1.62, 1.12 },
					offset = { 0, 0, 0 },
					color = { 92, 64, 42 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.42, 0.42, 1.4 },
					offset = { -1.25, 0.82, 0.05 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 24 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.42, 0.5, 1.4 },
					offset = { -0.94, 0.82, 0.05 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, 18 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.42, 0.58, 1.4 },
					offset = { -0.63, 0.82, 0.05 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 12 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.42, 0.42, 1.4 },
					offset = { -0.32, 0.82, 0.05 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, 6 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.42, 0.5, 1.4 },
					offset = { -0.01, 0.82, 0.05 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.42, 0.58, 1.4 },
					offset = { 0.3, 0.82, 0.05 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, -6 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.42, 0.42, 1.4 },
					offset = { 0.61, 0.82, 0.05 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, -12 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.42, 0.5, 1.4 },
					offset = { 0.92, 0.82, 0.05 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, -18 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.42, 0.58, 1.4 },
					offset = { 1.23, 0.82, 0.05 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, -24 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 2.3, 1.1, 0.25 },
					offset = { 0, 0.25, 0.65 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.32, 0.25, 0.2 },
					offset = { -0.95, -0.38, 0.66 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.32, 0.37, 0.2 },
					offset = { -0.63, -0.44, 0.66 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.32, 0.25, 0.2 },
					offset = { -0.31, -0.38, 0.66 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.32, 0.37, 0.2 },
					offset = { 0.01, -0.44, 0.66 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.32, 0.25, 0.2 },
					offset = { 0.33, -0.38, 0.66 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.32, 0.37, 0.2 },
					offset = { 0.65, -0.44, 0.66 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.32, 0.25, 0.2 },
					offset = { 0.97, -0.38, 0.66 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.08, 0.2, 0.08 },
					offset = { -0.5325, 0.3768, -0.6 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, 28.8 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.08, 0.2, 0.08 },
					offset = { -0.3882, 0.3356, -0.6 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, 19.2 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.08, 0.2, 0.08 },
					offset = { -0.2045, 0.3091, -0.6 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, 9.6 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.08, 0.2, 0.08 },
					offset = { 0, 0.3, -0.6 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.08, 0.2, 0.08 },
					offset = { 0.2045, 0.3091, -0.6 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, -9.6 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.08, 0.2, 0.08 },
					offset = { 0.3882, 0.3356, -0.6 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, -19.2 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.08, 0.2, 0.08 },
					offset = { 0.5325, 0.3768, -0.6 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, -28.8 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.2, 0.2, 0.08 },
					offset = { 0, 0.22, -0.62 },
					color = { 160, 30, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 1.3, 0.45, 1.3 },
					offset = { 0.08, 0.4, 0 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, -12 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 1.3, 0.45, 1.3 },
					offset = { -0.08, 0.4, 0 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, 12 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 1, 0.3, 1 },
					offset = { 0.12, 0.62, 0 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, -12 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 1, 0.3, 1 },
					offset = { -0.12, 0.62, 0 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 12 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 0.08, 0.25, 0.08 },
					offset = { 0.66, 0.25, -0.3 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, 30 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 0.08, 0.25, 0.08 },
					offset = { -0.66, 0.25, -0.3 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, -30 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 0.08, 0.25, 0.08 },
					offset = { 0.66, 0.25, 0 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, 30 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 0.08, 0.25, 0.08 },
					offset = { -0.66, 0.25, 0 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, -30 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 0.08, 0.25, 0.08 },
					offset = { 0.66, 0.25, 0.3 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, 30 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 0.08, 0.25, 0.08 },
					offset = { -0.66, 0.25, 0.3 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { 0, 0, -30 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 1.1, 0.8, 1.1 },
					offset = { 0, -0.05, 0 },
					color = { 92, 64, 42 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 1.1, 0.8, 1.1 },
					offset = { 0, -0.05, 0 },
					color = { 92, 64, 42 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 1.13, 0.07, 1.13 },
					offset = { 0, 0.25, 0 },
					color = { 60, 42, 28 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 1.13, 0.07, 1.13 },
					offset = { 0, 0.25, 0 },
					color = { 60, 42, 28 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 1.13, 0.07, 1.13 },
					offset = { 0, 0, 0 },
					color = { 60, 42, 28 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 1.13, 0.07, 1.13 },
					offset = { 0, 0, 0 },
					color = { 60, 42, 28 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 1.13, 0.07, 1.13 },
					offset = { 0, -0.25, 0 },
					color = { 60, 42, 28 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 1.13, 0.07, 1.13 },
					offset = { 0, -0.25, 0 },
					color = { 60, 42, 28 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 1.22, 0.24, 1.22 },
					offset = { 0, 0.45, 0 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 1.22, 0.24, 1.22 },
					offset = { 0, 0.45, 0 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightHand",
					size = { 1.08, 0.3, 1.08 },
					offset = { 0, 0, 0 },
					color = { 92, 64, 42 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftHand",
					size = { 1.08, 0.3, 1.08 },
					offset = { 0, 0, 0 },
					color = { 92, 64, 42 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightHand",
					size = { 0.1, 0.32, 0.1 },
					offset = { -0.3, -0.25, -0.42 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { -35, 0, 0 },
					neon = false,
				},
				{
					part = "LeftHand",
					size = { 0.1, 0.32, 0.1 },
					offset = { 0.3, -0.25, -0.42 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { -35, 0, 0 },
					neon = false,
				},
				{
					part = "RightHand",
					size = { 0.1, 0.32, 0.1 },
					offset = { 0, -0.25, -0.42 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { -35, 0, 0 },
					neon = false,
				},
				{
					part = "LeftHand",
					size = { 0.1, 0.32, 0.1 },
					offset = { 0, -0.25, -0.42 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { -35, 0, 0 },
					neon = false,
				},
				{
					part = "RightHand",
					size = { 0.1, 0.32, 0.1 },
					offset = { 0.3, -0.25, -0.42 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { -35, 0, 0 },
					neon = false,
				},
				{
					part = "LeftHand",
					size = { 0.1, 0.32, 0.1 },
					offset = { -0.3, -0.25, -0.42 },
					color = { 228, 218, 192 },
					material = "SmoothPlastic",
					rot = { -35, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 2.16, 0.34, 1.16 },
					offset = { 0, 0, 0 },
					color = { 92, 64, 42 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.42, 0.42, 0.4 },
					offset = { 0, -0.25, 0.65 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 20, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.37, 0.37, 0.4 },
					offset = { 0, -0.57, 0.77 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 28, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.32, 0.32, 0.4 },
					offset = { 0, -0.89, 0.89 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 36, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.27, 0.27, 0.4 },
					offset = { 0, -1.21, 1.01 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 44, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.22, 0.22, 0.4 },
					offset = { 0, -1.53, 1.13 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 52, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.17, 0.17, 0.4 },
					offset = { 0, -1.85, 1.25 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 60, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.22, 0.22, 0.22 },
					offset = { 0, -2.15, 1.37 },
					color = { 176, 172, 162 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 1.08, 1.1, 1.08 },
					offset = { 0, 0, 0 },
					color = { 92, 64, 42 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 1.08, 1.1, 1.08 },
					offset = { 0, 0, 0 },
					color = { 92, 64, 42 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 1.11, 0.08, 1.11 },
					offset = { 0, 0.35, 0 },
					color = { 60, 42, 28 },
					material = "SmoothPlastic",
					rot = { 0, 0, 6 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 1.11, 0.08, 1.11 },
					offset = { 0, 0.35, 0 },
					color = { 60, 42, 28 },
					material = "SmoothPlastic",
					rot = { 0, 0, -6 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 1.11, 0.08, 1.11 },
					offset = { 0, 0.05, 0 },
					color = { 60, 42, 28 },
					material = "SmoothPlastic",
					rot = { 0, 0, 6 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 1.11, 0.08, 1.11 },
					offset = { 0, 0.05, 0 },
					color = { 60, 42, 28 },
					material = "SmoothPlastic",
					rot = { 0, 0, -6 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 1.11, 0.08, 1.11 },
					offset = { 0, -0.25, 0 },
					color = { 60, 42, 28 },
					material = "SmoothPlastic",
					rot = { 0, 0, 6 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 1.11, 0.08, 1.11 },
					offset = { 0, -0.25, 0 },
					color = { 60, 42, 28 },
					material = "SmoothPlastic",
					rot = { 0, 0, -6 },
					neon = false,
				},
				{
					part = "RightLowerLeg",
					size = { 1.1, 1, 1.1 },
					offset = { 0, -0.08, 0 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerLeg",
					size = { 1.1, 1, 1.1 },
					offset = { 0, -0.08, 0 },
					color = { 84, 80, 74 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerLeg",
					size = { 1.26, 0.3, 1.26 },
					offset = { 0, 0.45, 0 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerLeg",
					size = { 1.26, 0.3, 1.26 },
					offset = { 0, 0.45, 0 },
					color = { 124, 120, 112 },
					material = "Fabric",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightFoot",
					size = { 1.12, 0.36, 1.32 },
					offset = { 0, 0.02, -0.14 },
					color = { 92, 64, 42 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftFoot",
					size = { 1.12, 0.36, 1.32 },
					offset = { 0, 0.02, -0.14 },
					color = { 92, 64, 42 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = false,
				},
			},
		},
		Dragon = {
			name = "Dragon",
			pieces = {
				{
					part = "Head",
					size = { 1.38, 1.38, 1.38 },
					offset = { 0, 0.02, 0 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 1.1, 0.16, 0.08 },
					offset = { 0, 0.1, -0.7 },
					color = { 255, 140, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 0 },
					neon = true,
				},
				{
					part = "Head",
					size = { 1.4, 0.12, 1.4 },
					offset = { 0, -0.3, 0 },
					color = { 206, 154, 52 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.4, 0.45, 0.2 },
					offset = { 0, -0.38, -0.65 },
					color = { 34, 30, 32 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.12, 0.3, 0.2 },
					offset = { 0, 0.82, -0.45 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -25, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.12, 0.27, 0.2 },
					offset = { 0, 0.79, -0.2 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -25, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.12, 0.24, 0.2 },
					offset = { 0, 0.76, 0.05 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -25, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.12, 0.21, 0.2 },
					offset = { 0, 0.73, 0.3 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -25, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.12, 0.18, 0.2 },
					offset = { 0, 0.7, 0.55 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -25, 0, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.24, 0.24, 0.32 },
					offset = { -0.6, 0.55, 0.05 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -30, 0, 15 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.205, 0.205, 0.32 },
					offset = { -0.6875, 0.7329, 0.2375 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -42, 0, 15 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.17, 0.17, 0.32 },
					offset = { -0.775, 0.8619, 0.425 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -54, 0, 15 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.135, 0.135, 0.32 },
					offset = { -0.8625, 0.8989, 0.6125 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -66, 0, 15 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.1, 0.1, 0.32 },
					offset = { -0.95, 0.833, 0.8 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -78, 0, 15 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.18, 0.5, 0.5 },
					offset = { -0.72, -0.1, -0.15 },
					color = { 72, 12, 14 },
					material = "Metal",
					rot = { 0, -15, 0 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.24, 0.24, 0.32 },
					offset = { 0.6, 0.55, 0.05 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -30, 0, -15 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.205, 0.205, 0.32 },
					offset = { 0.6875, 0.7329, 0.2375 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -42, 0, -15 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.17, 0.17, 0.32 },
					offset = { 0.775, 0.8619, 0.425 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -54, 0, -15 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.135, 0.135, 0.32 },
					offset = { 0.8625, 0.8989, 0.6125 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -66, 0, -15 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.1, 0.1, 0.32 },
					offset = { 0.95, 0.833, 0.8 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -78, 0, -15 },
					neon = false,
				},
				{
					part = "Head",
					size = { 0.18, 0.5, 0.5 },
					offset = { 0.72, -0.1, -0.15 },
					color = { 72, 12, 14 },
					material = "Metal",
					rot = { 0, 15, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 2.18, 1.7, 1.2 },
					offset = { 0, 0.02, 0 },
					color = { 34, 30, 32 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.9, 0.65, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.54, 0.65, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.18, 0.65, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.18, 0.65, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.54, 0.65, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.9, 0.65, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.72, 0.425, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.36, 0.425, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0, 0.425, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.36, 0.425, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.72, 0.425, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.9, 0.2, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.54, 0.2, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.18, 0.2, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.18, 0.2, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.54, 0.2, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.9, 0.2, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.72, -0.025, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.36, -0.025, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0, -0.025, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.36, -0.025, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.72, -0.025, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.9, -0.25, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.54, -0.25, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.18, -0.25, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.18, -0.25, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.54, -0.25, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.9, -0.25, -0.63 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.72, -0.475, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { -0.36, -0.475, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0, -0.475, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.36, -0.475, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.342, 0.3, 0.07 },
					offset = { 0.72, -0.475, -0.63 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 2.22, 0.12, 1.24 },
					offset = { 0, 0.84, 0 },
					color = { 206, 154, 52 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 2.22, 0.1, 1.24 },
					offset = { 0, -0.8, 0 },
					color = { 206, 154, 52 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.32, 0.32, 0.1 },
					offset = { 0, 0.15, -0.72 },
					color = { 206, 154, 52 },
					material = "Metal",
					rot = { 0, 0, 45 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.2, 0.2, 0.1 },
					offset = { 0, 0.15, -0.78 },
					color = { 255, 140, 30 },
					material = "SmoothPlastic",
					rot = { 0, 0, 45 },
					neon = true,
				},
				{
					part = "UpperTorso",
					size = { 0.14, 0.32, 0.32 },
					offset = { 0, 0.65, 0.68 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 45, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.14, 0.32, 0.32 },
					offset = { 0, 0.32, 0.68 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 45, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.14, 0.32, 0.32 },
					offset = { 0, -0.01, 0.68 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 45, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.14, 0.32, 0.32 },
					offset = { 0, -0.34, 0.68 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 45, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.14, 0.32, 0.32 },
					offset = { 0, -0.67, 0.68 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 45, 0, 0 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.9, 1.3, 0.06 },
					offset = { -0.6, 0.35, 0.78 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { 0, -25, -12 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.1, 1.4, 0.1 },
					offset = { -1, 0.45, 0.85 },
					color = { 34, 30, 32 },
					material = "Metal",
					rot = { 0, -25, -12 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.9, 1.3, 0.06 },
					offset = { 0.6, 0.35, 0.78 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { 0, 25, 12 },
					neon = false,
				},
				{
					part = "UpperTorso",
					size = { 0.1, 1.4, 0.1 },
					offset = { 1, 0.45, 0.85 },
					color = { 34, 30, 32 },
					material = "Metal",
					rot = { 0, 25, 12 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 1.45, 0.3, 1.45 },
					offset = { 0.1, 0.52, 0 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { 0, 0, -15 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 1.45, 0.3, 1.45 },
					offset = { -0.1, 0.52, 0 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { 0, 0, 15 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 1.33, 0.3, 1.33 },
					offset = { 0.14, 0.32, 0 },
					color = { 72, 12, 14 },
					material = "Metal",
					rot = { 0, 0, -15 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 1.33, 0.3, 1.33 },
					offset = { -0.14, 0.32, 0 },
					color = { 72, 12, 14 },
					material = "Metal",
					rot = { 0, 0, 15 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 1.21, 0.3, 1.21 },
					offset = { 0.18, 0.12, 0 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { 0, 0, -15 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 1.21, 0.3, 1.21 },
					offset = { -0.18, 0.12, 0 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { 0, 0, 15 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 1.48, 0.07, 1.48 },
					offset = { 0.1, 0.38, 0 },
					color = { 206, 154, 52 },
					material = "Metal",
					rot = { 0, 0, -15 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 1.48, 0.07, 1.48 },
					offset = { -0.1, 0.38, 0 },
					color = { 206, 154, 52 },
					material = "Metal",
					rot = { 0, 0, 15 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 0.16, 0.45, 0.16 },
					offset = { 0.35, 0.85, -0.25 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 0, 0, -30 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 0.16, 0.45, 0.16 },
					offset = { -0.35, 0.85, -0.25 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 0, 0, 30 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 0.16, 0.45, 0.16 },
					offset = { 0.47, 0.8, 0 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 0, 0, -38 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 0.16, 0.45, 0.16 },
					offset = { -0.47, 0.8, 0 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 0, 0, 38 },
					neon = false,
				},
				{
					part = "RightUpperArm",
					size = { 0.16, 0.45, 0.16 },
					offset = { 0.59, 0.75, 0.25 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 0, 0, -46 },
					neon = false,
				},
				{
					part = "LeftUpperArm",
					size = { 0.16, 0.45, 0.16 },
					offset = { -0.59, 0.75, 0.25 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 0, 0, 46 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 1.14, 0.95, 1.14 },
					offset = { 0, -0.02, 0 },
					color = { 34, 30, 32 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 1.14, 0.95, 1.14 },
					offset = { 0, -0.02, 0 },
					color = { 34, 30, 32 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { -0.32, 0.25, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { 0, 0.25, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { 0.32, 0.25, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { -0.16, 0.0625, -0.58 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { 0.16, 0.0625, -0.58 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { -0.32, -0.125, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { 0, -0.125, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { 0.32, -0.125, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { -0.32, 0.25, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { 0, 0.25, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { 0.32, 0.25, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { -0.16, 0.0625, -0.58 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { 0.16, 0.0625, -0.58 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { -0.32, -0.125, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { 0, -0.125, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 0.304, 0.25, 0.07 },
					offset = { 0.32, -0.125, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 0.12, 0.28, 0.28 },
					offset = { 0.6, 0.3, 0 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 45, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 0.12, 0.28, 0.28 },
					offset = { -0.6, 0.3, 0 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 45, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 0.12, 0.28, 0.28 },
					offset = { 0.6, 0, 0 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 45, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 0.12, 0.28, 0.28 },
					offset = { -0.6, 0, 0 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 45, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerArm",
					size = { 0.12, 0.28, 0.28 },
					offset = { 0.6, -0.3, 0 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 45, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerArm",
					size = { 0.12, 0.28, 0.28 },
					offset = { -0.6, -0.3, 0 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 45, 0, 0 },
					neon = false,
				},
				{
					part = "RightHand",
					size = { 1.12, 0.34, 1.12 },
					offset = { 0, 0, 0 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftHand",
					size = { 1.12, 0.34, 1.12 },
					offset = { 0, 0, 0 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightHand",
					size = { 0.09, 0.4, 0.09 },
					offset = { -0.36, -0.3, -0.45 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -40, 0, 0 },
					neon = false,
				},
				{
					part = "LeftHand",
					size = { 0.09, 0.4, 0.09 },
					offset = { 0.36, -0.3, -0.45 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -40, 0, 0 },
					neon = false,
				},
				{
					part = "RightHand",
					size = { 0.09, 0.4, 0.09 },
					offset = { -0.12, -0.3, -0.45 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -40, 0, 0 },
					neon = false,
				},
				{
					part = "LeftHand",
					size = { 0.09, 0.4, 0.09 },
					offset = { 0.12, -0.3, -0.45 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -40, 0, 0 },
					neon = false,
				},
				{
					part = "RightHand",
					size = { 0.09, 0.4, 0.09 },
					offset = { 0.12, -0.3, -0.45 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -40, 0, 0 },
					neon = false,
				},
				{
					part = "LeftHand",
					size = { 0.09, 0.4, 0.09 },
					offset = { -0.12, -0.3, -0.45 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -40, 0, 0 },
					neon = false,
				},
				{
					part = "RightHand",
					size = { 0.09, 0.4, 0.09 },
					offset = { 0.36, -0.3, -0.45 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -40, 0, 0 },
					neon = false,
				},
				{
					part = "LeftHand",
					size = { 0.09, 0.4, 0.09 },
					offset = { -0.36, -0.3, -0.45 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -40, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 2.2, 0.36, 1.2 },
					offset = { 0, 0, 0 },
					color = { 34, 30, 32 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.36, 0.3, 0.1 },
					offset = { 0, 0, -0.64 },
					color = { 206, 154, 52 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.36, 0.55, 0.08 },
					offset = { -0.9, -0.42, -0.6 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { -8, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.36, 0.55, 0.08 },
					offset = { -0.54, -0.42, -0.6 },
					color = { 72, 12, 14 },
					material = "Metal",
					rot = { -8, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.36, 0.55, 0.08 },
					offset = { -0.18, -0.42, -0.6 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { -8, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.36, 0.55, 0.08 },
					offset = { 0.18, -0.42, -0.6 },
					color = { 72, 12, 14 },
					material = "Metal",
					rot = { -8, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.36, 0.55, 0.08 },
					offset = { 0.54, -0.42, -0.6 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { -8, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.36, 0.55, 0.08 },
					offset = { 0.9, -0.42, -0.6 },
					color = { 72, 12, 14 },
					material = "Metal",
					rot = { -8, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.5, 0.42, 0.45 },
					offset = { 0, -0.3, 0.7 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { 25, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.445, 0.375, 0.45 },
					offset = { 0, -0.58, 1.02 },
					color = { 72, 12, 14 },
					material = "Metal",
					rot = { 31, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.39, 0.33, 0.45 },
					offset = { 0, -0.86, 1.34 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { 37, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.335, 0.285, 0.45 },
					offset = { 0, -1.14, 1.66 },
					color = { 72, 12, 14 },
					material = "Metal",
					rot = { 43, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.28, 0.24, 0.45 },
					offset = { 0, -1.42, 1.98 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { 49, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.225, 0.195, 0.45 },
					offset = { 0, -1.7, 2.3 },
					color = { 72, 12, 14 },
					material = "Metal",
					rot = { 55, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.17, 0.15, 0.45 },
					offset = { 0, -1.98, 2.62 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { 61, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.08, 0.2, 0.15 },
					offset = { 0, -0.05, 0.75 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 30, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.08, 0.18, 0.15 },
					offset = { 0, -0.33, 1.07 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 30, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.08, 0.16, 0.15 },
					offset = { 0, -0.61, 1.39 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 30, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.08, 0.14, 0.15 },
					offset = { 0, -0.89, 1.71 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 30, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.08, 0.12, 0.15 },
					offset = { 0, -1.17, 2.03 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 30, 0, 0 },
					neon = false,
				},
				{
					part = "LowerTorso",
					size = { 0.08, 0.1, 0.15 },
					offset = { 0, -1.45, 2.35 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 30, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 1.12, 1.15, 1.12 },
					offset = { 0, 0, 0 },
					color = { 34, 30, 32 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 1.12, 1.15, 1.12 },
					offset = { 0, 0, 0 },
					color = { 34, 30, 32 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { -0.32, 0.4, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { 0, 0.4, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { 0.32, 0.4, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { -0.16, 0.19, -0.58 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { 0.16, 0.19, -0.58 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { -0.32, -0.02, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { 0, -0.02, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { 0.32, -0.02, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { -0.16, -0.23, -0.58 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { 0.16, -0.23, -0.58 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { -0.32, 0.4, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { 0, 0.4, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { 0.32, 0.4, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { -0.16, 0.19, -0.58 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { 0.16, 0.19, -0.58 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { -0.32, -0.02, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { 0, -0.02, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { 0.32, -0.02, -0.58 },
					color = { 128, 22, 22 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { -0.16, -0.23, -0.58 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "LeftUpperLeg",
					size = { 0.304, 0.28, 0.07 },
					offset = { 0.16, -0.23, -0.58 },
					color = { 72, 12, 14 },
					material = "SmoothPlastic",
					rot = { -12, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerLeg",
					size = { 1.14, 1.15, 1.14 },
					offset = { 0, 0, 0 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerLeg",
					size = { 1.14, 1.15, 1.14 },
					offset = { 0, 0, 0 },
					color = { 128, 22, 22 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerLeg",
					size = { 0.5, 0.4, 0.3 },
					offset = { 0, 0.45, -0.62 },
					color = { 206, 154, 52 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerLeg",
					size = { 0.5, 0.4, 0.3 },
					offset = { 0, 0.45, -0.62 },
					color = { 206, 154, 52 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightLowerLeg",
					size = { 0.14, 0.4, 0.14 },
					offset = { 0, 0.6, -0.8 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -50, 0, 0 },
					neon = false,
				},
				{
					part = "LeftLowerLeg",
					size = { 0.14, 0.4, 0.14 },
					offset = { 0, 0.6, -0.8 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { -50, 0, 0 },
					neon = false,
				},
				{
					part = "RightFoot",
					size = { 1.16, 0.38, 1.35 },
					offset = { 0, 0.03, -0.15 },
					color = { 34, 30, 32 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "LeftFoot",
					size = { 1.16, 0.38, 1.35 },
					offset = { 0, 0.03, -0.15 },
					color = { 34, 30, 32 },
					material = "Metal",
					rot = { 0, 0, 0 },
					neon = false,
				},
				{
					part = "RightFoot",
					size = { 0.14, 0.14, 0.4 },
					offset = { -0.3, -0.05, -0.95 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 15, 0, 0 },
					neon = false,
				},
				{
					part = "LeftFoot",
					size = { 0.14, 0.14, 0.4 },
					offset = { 0.3, -0.05, -0.95 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 15, 0, 0 },
					neon = false,
				},
				{
					part = "RightFoot",
					size = { 0.14, 0.14, 0.4 },
					offset = { 0, -0.05, -0.95 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 15, 0, 0 },
					neon = false,
				},
				{
					part = "LeftFoot",
					size = { 0.14, 0.14, 0.4 },
					offset = { 0, -0.05, -0.95 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 15, 0, 0 },
					neon = false,
				},
				{
					part = "RightFoot",
					size = { 0.14, 0.14, 0.4 },
					offset = { 0.3, -0.05, -0.95 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 15, 0, 0 },
					neon = false,
				},
				{
					part = "LeftFoot",
					size = { 0.14, 0.14, 0.4 },
					offset = { -0.3, -0.05, -0.95 },
					color = { 222, 206, 170 },
					material = "SmoothPlastic",
					rot = { 15, 0, 0 },
					neon = false,
				},
			},
		},
	},
	stats = {
		Leather = {
			DisplayName = "Armadura de cuero",
			Reduction = 0.15,
			Speed = 1,
			Color = { 112, 74, 44 },
		},
		Wolf = {
			DisplayName = "Armadura de lobo",
			Reduction = 0.25,
			Speed = 2,
			Color = { 124, 120, 112 },
		},
		Dragon = {
			DisplayName = "Armadura de dragón",
			Reduction = 0.45,
			Speed = -1,
			Color = { 128, 22, 22 },
		},
	},
}
]=======],
	Builder = [=======[
--[[
	ArmorBuilder (ModuleScript) · ReplicatedStorage.Armor.ArmorBuilder

	Construye una armadura de bloques sobre un personaje (jugador R15/R6 o maniquí) a partir de ArmorData.
	Cada pieza se escala por eje al tamaño real de su parte del cuerpo y se suelda a ella.

	ArmorBuilder.Attach(character, setName) -> Folder "ArmorPieces"
	ArmorBuilder.Detach(character)
	Funciones puras (se prueban fuera de Roblox): ArmorBuilder.Region(partName, isR6), ArmorBuilder.Refund(prev, new, reduction)
]]

local ArmorBuilder = {}
local Data -- se carga perezosamente: ArmorData vive junto a este módulo

local function data()
	if not Data then
		Data = require(script.Parent:WaitForChild("ArmorData"))
	end
	return Data
end

-- Dónde cae una parte R15 en un cuerpo R6: parte R6, desplazamiento vertical del centro (en el tamaño por defecto
-- de la parte R6) y escala vertical. Las cadenas R15 (brazo superior, antebrazo, mano…) se reparten a lo largo de
-- la parte R6 equivalente, que mide 2 studs.
local R6_CHAINS = {
	{ r6 = "Torso", parts = { { "UpperTorso", 1.6 }, { "LowerTorso", 0.4 } } },
	{ r6 = "Right Arm", parts = { { "RightUpperArm", 1.169 }, { "RightLowerArm", 1.052 }, { "RightHand", 0.3 } } },
	{ r6 = "Left Arm", parts = { { "LeftUpperArm", 1.169 }, { "LeftLowerArm", 1.052 }, { "LeftHand", 0.3 } } },
	{ r6 = "Right Leg", parts = { { "RightUpperLeg", 1.217 }, { "RightLowerLeg", 1.193 }, { "RightFoot", 0.3 } } },
	{ r6 = "Left Leg", parts = { { "LeftUpperLeg", 1.217 }, { "LeftLowerLeg", 1.193 }, { "LeftFoot", 0.3 } } },
}
local R6_MAP = { Head = { r6 = "Head", y = 0, sy = 1 } }
for _, chain in ipairs(R6_CHAINS) do
	local total = 0
	for _, p in ipairs(chain.parts) do
		total += p[2]
	end
	local sy = 2 / total
	local top = 1
	for _, p in ipairs(chain.parts) do
		local h = p[2] * sy
		R6_MAP[p[1]] = { r6 = chain.r6, y = top - h / 2, sy = sy }
		top -= h
	end
end

function ArmorBuilder.Region(partName: string, isR6: boolean)
	if not isR6 then
		return partName, 0, 1
	end
	local m = R6_MAP[partName]
	if not m then
		return nil, 0, 1
	end
	return m.r6, m.y, m.sy
end

-- Reducción de daño: de la vida perdida (prev - new) se devuelve el porcentaje de la armadura.
function ArmorBuilder.Refund(prev: number, new: number, reduction: number): number
	if new >= prev or reduction <= 0 then
		return new
	end
	return new + (prev - new) * math.clamp(reduction, 0, 0.95)
end

function ArmorBuilder.Detach(character)
	local old = character:FindFirstChild("ArmorPieces")
	if old then
		old:Destroy()
	end
end

function ArmorBuilder.Attach(character, setName: string)
	local D = data()
	local set = D.sets[setName]
	assert(set, "Armadura desconocida: " .. tostring(setName))
	ArmorBuilder.Detach(character)
	local folder = Instance.new("Folder")
	folder.Name = "ArmorPieces"
	local isR6 = character:FindFirstChild("UpperTorso") == nil and character:FindFirstChild("Torso") ~= nil
	for _, p in ipairs(set.pieces) do
		local targetName, regionY, sy = ArmorBuilder.Region(p.part, isR6)
		local target = targetName and character:FindFirstChild(targetName)
		if target and target:IsA("BasePart") then
			-- escala por eje = tamaño real de la región / tamaño por defecto de la pieza en el maniquí
			local ref = D.dummy[p.part]
			local sc, centerY
			if p.part == "Head" then
				-- la cabeza clásica es una Part 2x1x1 con malla redonda (~1,2); solo se escala si es una MeshPart
				sc = target:IsA("MeshPart") and target.Size / Vector3.new(1.2, 1.2, 1.2) or Vector3.one
				centerY = 0
			elseif isR6 then
				local def = targetName == "Torso" and Vector3.new(2, 2, 1) or Vector3.new(1, 2, 1)
				local real = target.Size / def
				sc = Vector3.new(real.X, real.Y * sy, real.Z)
				centerY = regionY * real.Y
			else
				sc = target.Size / Vector3.new(ref[1], ref[2], ref[3])
				centerY = 0
			end
			local part = Instance.new("Part")
			part.Name = setName .. "_" .. p.part
			part.Size = Vector3.new(p.size[1] * sc.X, p.size[2] * sc.Y, p.size[3] * sc.Z)
			part.CFrame = target.CFrame
				* CFrame.new(0, centerY, 0)
				* CFrame.new(p.offset[1] * sc.X, p.offset[2] * sc.Y, p.offset[3] * sc.Z)
				* CFrame.Angles(math.rad(p.rot[1]), math.rad(p.rot[2]), math.rad(p.rot[3]))
			part.Color = Color3.fromRGB(p.color[1], p.color[2], p.color[3])
			part.Material = p.neon and Enum.Material.Neon or (Enum.Material[p.material] or Enum.Material.SmoothPlastic)
			part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			part.CanCollide, part.CanQuery, part.CanTouch, part.Massless = false, false, false, true
			part.Anchored = false
			part.CastShadow = not p.neon
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = target, part
			w.Parent = part
			part.Parent = folder
		end
	end
	folder.Parent = character
	return folder
end

return ArmorBuilder
]=======],
	Service = [=======[
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
]=======],
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
pcall(function()
	ChangeHistoryService:SetWaypoint("Antes de instalar las armaduras")
end)

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

local folder = ensure(ReplicatedStorage, "Armor")
putScript(folder, "ArmorData", "ModuleScript", SOURCES.Data)
local builderModule = putScript(folder, "ArmorBuilder", "ModuleScript", SOURCES.Builder)
putScript(game:GetService("ServerScriptService"), "ArmorService", "Script", SOURCES.Service)

-- maniquíes: cuerpo R15 de bloques anclado, con la armadura puesta y un ProximityPrompt
local Builder = require(builderModule)
local Data = require(folder.ArmorData)
local old = workspace:FindFirstChild("ArmorStands")
if old then
	old:Destroy()
end
local stands = Instance.new("Folder")
stands.Name = "ArmorStands"
local order = { "Leather", "Wolf", "Dragon" }
for i, setName in ipairs(order) do
	local st = Data.stats[setName]
	local base = STANDS_ORIGIN * CFrame.new((i - 2) * 7, 0, 0) * CFrame.Angles(0, math.pi, 0)
	local m = Instance.new("Model")
	m.Name = "Stand_" .. setName
	local pedestal = Instance.new("Part")
	pedestal.Name = "Pedestal"
	pedestal.Size = Vector3.new(4, 0.6, 4)
	pedestal.CFrame = base * CFrame.new(0, 0.3, 0)
	pedestal.Anchored = true
	pedestal.Material = Enum.Material.Wood
	pedestal.Color = Color3.fromRGB(70, 52, 36)
	pedestal.Parent = m
	for name, P in pairs(Data.dummyParts) do
		local p = Instance.new("Part")
		p.Name = name
		p.Size = Vector3.new(P.size[1], P.size[2], P.size[3])
		p.CFrame = base * CFrame.new(P.center[1], P.center[2] + 0.6, P.center[3])
		p.Anchored = true
		p.CanCollide = name == "UpperTorso"
		p.Material = Enum.Material.Wood
		p.Color = Color3.fromRGB(150, 120, 88)
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = m
	end
	Builder.Attach(m, setName)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Equipar / quitar"
	prompt.ObjectText = st.DisplayName
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.4
	prompt:SetAttribute("ArmorSet", setName)
	prompt.Parent = m.UpperTorso
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 50)
	bb.StudsOffset = Vector3.new(0, 4.2, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(240, 230, 210)
	label.TextStrokeTransparency = 0.4
	label.Text = ("%s\n−%d %% daño · %+d velocidad"):format(st.DisplayName, math.floor(st.Reduction * 100 + 0.5), st.Speed)
	label.Parent = bb
	bb.Parent = m.Head
	m.PrimaryPart = pedestal
	m.Parent = stands
end
stands.Parent = workspace

Selection:Set({ stands })
pcall(function()
	ChangeHistoryService:SetWaypoint("Armaduras instaladas")
end)
print("[Armor] Listo: 3 armaduras (cuero, lobo, dragón) y sus maniquíes en Workspace.ArmorStands. En Play, acércate y pulsa E.")
