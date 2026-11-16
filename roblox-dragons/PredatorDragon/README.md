# Dragón Depredador (*Karnathys sanguifauces*): paquete para Roblox Studio

Construido a partir de la hoja de diseño del usuario (`design/reference.jpg`). Es un cuadrúpedo negro con heridas abiertas, fauces babeantes y alas rasgadas. En la oscuridad solo se le ven **dos puntos blancos que miran fijamente al jugador**.

## Contenido
| Archivo | Para qué sirve |
|---|---|
| `model/PredatorDragon.fbx` | **Modelo recomendado.** 31 MeshParts con nombre y la textura incrustada |
| `model/PredatorDragon.glb` · `.obj` + `.mtl` | Alternativas en glTF (con PBR) y OBJ |
| `model/PredatorDragon_color.png`, `_normal.png`, `_roughness.png` | Atlas de 1024 px para SurfaceAppearance |
| `model/rig.json` | Pivotes y jerarquía del rig (Y arriba, mira hacia −Z, en studs) |
| `roblox/InstallPredator.lua` | **Instalador para la Command Bar.** Contiene todo lo demás |
| `roblox/DragonAnimator.lua` | ModuleScript compartido: animaciones por datos y seguimiento de mirada (`SetLookTarget`) |
| `roblox/PredatorAnimations.lua` | Idle (acechar), Walk, Run, Fly, TakeOff, Landing, Attack, Roar y Death |
| `roblox/PredatorShowcase.client.lua` | Vitrina nocturna: bloom, mirada al jugador, botones 1 a 9 y L para día o noche |

## Instalación
1. **Avatar › Import 3D** (o **Home › Import 3D**) y elige `model/PredatorDragon.fbx`.
   Deja **Rig Type** en **No Rig** y **no** combines las mallas: deben quedar 31 piezas con nombre. Pulsa Import.
2. Selecciona el modelo importado en el Explorer.
3. Abre **View › Command Bar**, pega el contenido completo de `roblox/InstallPredator.lua` y pulsa Enter.
   La salida mostrará la escala detectada, el error de posición y la línea «Listo».
4. Pulsa **Play**: se hace de noche, el dragón aparece en `Workspace.DragonShowcase.Stage_Predator` y su cabeza sigue tu cámara.

Opcional:
- Para relieve PBR, sube los tres PNG, pega sus `rbxassetid://` en `MAPS` y vuelve a ejecutar el instalador.
- `DESIRED_SCALE` cambia el tamaño. Con 1, mide 40 studs de largo.

## La mirada
- Los ojos son las piezas `EyeL` y `EyeR`: de material Neon blanco, con una `PointLight` tenue y hundidas bajo una ceja pesada. De día casi no se ven; de noche, con bloom, son lo único visible.
- `DragonAnimator:SetLookTarget(target, options)` gira el cuello (35 %) y la cabeza (65 %) hacia el objetivo, suavizado y con límites (80° a los lados, 35° arriba y abajo). Se suma encima de cualquier animación. La vitrina usa la posición de la cámara, así que te mira estés donde estés.
- Al morir, el cuerpo se disuelve primero y los dos puntos tardan casi dos segundos más en apagarse.

```lua
local animator = DragonAnimator.new(dragon, require(Dragons.PredatorDragon.Animations))
animator:Play("Idle")
animator:SetLookTarget(player.Character.Head, { Head = "Head", Neck = "Neck2", RestPitch = -18 })
```

## Qué está verificado y qué no
- ✅ Los archivos Luau compilan con `luau-compile`.
- ✅ La prueba de paridad Luau ↔ JS de las animaciones coincide en 1.134 muestras (diferencia máxima de 5·10⁻¹⁰).
- ✅ Con un ray casting en Blender se comprobó que los dos ojos se ven desde cinco cámaras frontales. Antes de este ajuste, la ceja y la cuenca los tapaban.
- ✅ El FBX, el GLB y el OBJ se generaron con Blender 5.3, que también hizo los renders.
- ⚠️ **No se ha probado dentro de Roblox Studio.** El seguimiento de mirada en Luau sigue la misma fórmula que el visor web, pero no tiene prueba automática.
- Límites: uniones rígidas, 100.400 triángulos (un modelo de jefe), Walk y Run en el sitio, sin IA ni sonido.

## Regenerar
```
node tools/export_model.js three.min.js GLTFExporter.js model
python tools/blender_pipeline.py model/PredatorDragon.glb model/rig.json model design/renders 64
node tools/build_roblox.js
node tools/test_anim_parity.js /ruta/a/luau
```
La geometría está en `src/predator_model.js`, que usa el núcleo común `src/dragon_core.js`. Las animaciones están en `src/predator_anims.js` y el animador compartido en `../shared/DragonAnimator.lua`.
