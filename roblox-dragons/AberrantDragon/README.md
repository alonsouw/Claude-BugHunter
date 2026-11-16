# Dragón Aberrante (*Xethra contorta*): paquete para Roblox Studio

Criatura de fantasía oscura con rig de 30 piezas (Motor6D) y nueve animaciones.

## Contenido
| Archivo | Para qué sirve |
|---|---|
| `model/AberrantDragon.fbx` | **Modelo recomendado.** 30 MeshParts con nombre y la textura incrustada |
| `model/AberrantDragon.glb` | Alternativa en glTF con material PBR (color, normal y rugosidad) |
| `model/AberrantDragon.obj` + `.mtl` | Alternativa simple |
| `model/AberrantDragon_color.png`, `_normal.png`, `_roughness.png` | Atlas de 1024 px para SurfaceAppearance |
| `model/rig.json` | Pivotes y jerarquía del rig (espacio Roblox: Y arriba, mira hacia −Z, en studs) |
| `roblox/InstallAberrant.lua` | **Instalador para la Command Bar.** Contiene todo lo demás |
| `roblox/DragonAnimator.lua` | ModuleScript: reproduce las animaciones escribiendo `Motor6D.Transform` |
| `roblox/AberrantAnimations.lua` | ModuleScript: datos de Idle, Walk, Run, Fly, TakeOff, Landing, Attack, Roar y Death |
| `roblox/DragonShowcase.client.lua` | LocalScript: vitrina con botones y teclas 1 a 9 |

## Instalación (unos 2 minutos)
1. Abre un place nuevo en Roblox Studio.
2. Ve a **Avatar › Import 3D** (o **Home › Import 3D**) y elige `model/AberrantDragon.fbx`.
   - Deja **Rig Type** en **No Rig**. El rig lo monta el instalador.
   - **No** actives la opción de combinar mallas: deben quedar 30 piezas con nombre (`Hips`, `Head`, `WingL_Hand`…).
   - Pulsa **Import**.
3. Selecciona el modelo importado en el Explorer.
4. Abre **View › Command Bar**, pega el contenido completo de `roblox/InstallAberrant.lua` y pulsa Enter.
   La salida mostrará la escala detectada, el error de posición y la línea «Listo».
5. Pulsa **Play**. El dragón aparece en `Workspace.DragonShowcase` con una barra de botones para probar las animaciones.

Opcional:
- Para relieve y brillo PBR, sube los tres PNG con el Asset Manager, pega sus `rbxassetid://` en `MAPS` al principio del instalador y vuelve a ejecutarlo.
- `DESIRED_SCALE` agranda o achica el dragón. Con 1, mide 24 studs de largo. `Model:ScaleTo` también escala los Motor6D.

## Qué crea el instalador
```
ReplicatedStorage
└─ Dragons
   ├─ DragonAnimator            (ModuleScript, compartido por todas las especies)
   ├─ AberrantDragon
   │  ├─ AberrantDragon         (Model: Root anclado + 30 MeshParts + 30 Motor6D)
   │  ├─ Animations             (ModuleScript)
   │  └─ Settings               (Configuration con atributos: velocidades, vida, daño…)
   └─ AbyssalDragon, PredatorDragon, AerialDragon, AncientDragon, ShadowDragon (carpetas vacías)
ServerStorage
└─ DragonAssets
   └─ AberrantDragon_Rig        (copia de seguridad)
Workspace
└─ DragonShowcase
   ├─ Stage
   └─ AberrantDragon_Preview    (estatua para verlo en modo edición; se oculta al jugar)
StarterPlayer
└─ StarterPlayerScripts
   └─ DragonShowcase            (LocalScript)
```

## Uso desde tus propios scripts
```lua
local Dragons = game.ReplicatedStorage.Dragons
local DragonAnimator = require(Dragons.DragonAnimator)
local dragon = Dragons.AberrantDragon.AberrantDragon:Clone()
dragon:PivotTo(CFrame.new(0, 0, 0))
dragon.Parent = workspace
local anim = DragonAnimator.new(dragon, require(Dragons.AberrantDragon.Animations))
anim:Play("Roar")
anim.Finished.Event:Connect(function(name) print("terminó", name) end)
```
Las animaciones son datos: claves de rotación, claves de traslación y osciladores. No hace falta subir assets de animación. Si prefieres el Animation Editor, el rig con Motor6D también funciona ahí.

## Qué está verificado y qué no
- ✅ Los cuatro archivos Luau compilan con `luau-compile`.
- ✅ `DragonAnimator.EvalJoint` en Luau da los mismos valores que el visor de la ficha (prueba `tools/test_anim_parity.js`: 1.098 muestras, diferencia máxima de 5·10⁻¹⁰).
- ✅ El FBX, el GLB y el OBJ se generaron y se abrieron en Blender 5.3, que también hizo los renders.
- ⚠️ **No se ha probado dentro de Roblox Studio.** El instalador calibra solo la escala y la orientación con que el importador deje las piezas. Si algo falla, el error indicará qué pieza falta o cuánto se desvía.
- Límites conocidos: las uniones son rígidas y se nota el solape en giros grandes. Walk y Run se animan en el sitio, sin desplazamiento. Faltan sonidos, IA e hitbox.

## Regenerar desde la fuente
```
node tools/export_model.js three.min.js GLTFExporter.js model     # GLB + atlas + rig.json
python tools/blender_pipeline.py model/AberrantDragon.glb model/rig.json model design/renders 64   # FBX, OBJ y renders (bpy 5.x)
node tools/build_roblox.js                                         # AberrantAnimations.lua + InstallAberrant.lua
node tools/test_anim_parity.js /ruta/a/luau                        # paridad Luau ↔ JS
```
La geometría está en `src/aberrant_model.js` y las animaciones en `src/aberrant_anims.js`. `ficha.html` es la ficha de diseño con el visor 3D.
