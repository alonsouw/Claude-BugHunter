# Dragón Sombrío (*Umbrafex ridens*): paquete para Roblox Studio

Hecho a partir de las dos referencias del usuario: `design/reference_face.jpg` (la cara) y `design/reference_body.jpg` (el cuerpo).

- **Cara**: cráneo negro con un domo de mechones que caen hacia atrás, cara en V hasta una barbilla en punta y ceño de crestas óseas.
- **Sonrisa**: de oreja a oreja, con labios rojos, encías granates y agujas blancas, largas y desiguales.
- **Ojos**: dos puntos rojos pequeños y muy separados. No son globos oculares.
- **Cuerpo**: alargado y de zancos. Torso pequeño en joroba, colgado muy alto; cuello largo hacia delante; brazos larguísimos con el codo por encima del lomo y manos de cinco dedos curvados; patas traseras en zigzag; jirones de piel colgando; alas hechas jirones plegadas como un manto; cola larga y fina.

**En la oscuridad** solo se ven los dos puntos rojos y la sonrisa. Los dientes son una malla aparte, `Teeth`, que la vitrina pasa a Neon de noche y que brilla con el Bloom.

## Cómo se construyó
1. **Escultura** (`sculpt/sdf.py`, `head.py`, `body.py`, `membrane.py`): campos de distancia con uniones suaves y piel continua con vóxel de 0,05 studs.
   - La sonrisa se traza sobre la piel real de la cara con rayos.
   - Los labios, las encías y cada aguja se colocan a lo largo de esa curva.
   - Todo lo que queda por debajo de la curva se etiqueta como mandíbula.
2. **Retopología** (`sculpt/produce.py`): los dientes se separan en su propia malla.
   - Body: unos 19k triángulos.
   - Teeth: unos 7k.
   - WingL / WingR: unos 9k cada una.
   - Todas quedan bajo el límite de 20k.
3. **Horneado**: color, normal y rugosidad a 1024 px para Body y para las alas.
4. **Huesos**: 36 Bones. La columna lleva un hueso extra, `Spine1`, para la joroba. `Jaw` se lleva el labio inferior y los dientes de abajo. Hay ocho huesos de cola.

## Contenido
| Archivo | Para qué sirve |
|---|---|
| `model/ShadowDragon.fbx` | **Para Roblox.** Armature más las mallas Body, Teeth, WingL y WingR, con skinning |
| `model/ShadowDragon.glb` / `.gltf.json` | La misma malla con huesos, para el visor web |
| `model/{Body,WingL,WingR}_{color,normal,roughness}.png` | Texturas para SurfaceAppearance |
| `model/rig.json` | Huesos (posición de reposo en studs, Y arriba, mirando a −Z), puntos de los ojos y medidas |
| `roblox/InstallShadow.lua` | **Instalador para la Command Bar** |
| `roblox/DragonAnimator.lua` | Animaciones por datos para Motor6D **y Bones**, más `SetLookTarget` |
| `roblox/ShadowAnimations.lua` | Idle (acechar y ladear la cabeza), Walk (zancos a tirones), Run, Fly, TakeOff, Landing, Attack, Roar (sonreír) y Death |
| `roblox/ShadowShowcase.client.lua` | Vitrina nocturna: ojos rojos, sonrisa Neon, mirada al jugador, botones 1 a 9 y L para día o noche |

## Instalación
1. **Avatar › Import 3D** → `model/ShadowDragon.fbx`.
   - Pon **Rig General › Rig Type = Custom**.
   - **No** combines las mallas.
   - Pulsa Import.
2. Selecciona el modelo importado en el Explorer.
3. **View › Command Bar**: pega todo `roblox/InstallShadow.lua` y pulsa Enter.
4. **Play**: se hace de noche. En `Workspace.DragonShowcase.Stage_Shadow` solo se ven dos puntos rojos y una sonrisa que te siguen. L enciende la luz y 1 a 9 lanzan las animaciones.

## Qué está verificado y qué no
- ✅ Blender 5.3 genera y exporta la malla, los huesos, los pesos y las texturas. El FBX contiene la armature y las cuatro mallas.
- ✅ El visor de la ficha carga el mismo GLB con huesos y lo anima con la misma conversión de ejes que `DragonAnimator.lua`.
- ✅ El código Luau compila y pasa la prueba de paridad Luau ↔ JS de las animaciones.
- ⚠️ **No se ha ejecutado dentro de Roblox Studio.** Falta confirmar la importación del skinning con varias mallas y el instalador.
- Límites:
  - Texturas de 1024 px.
  - Walk y Run se animan en el sitio.
  - No tiene IA ni sonido.

## Regenerar
```
cd sculpt
python stage_body.py <salida>/sculpt 0.05 24            # escultura de alta + renders de comparación (bpy 5.x + scikit-image)
python produce.py <salida>/sculpt/sculpt_high.blend ../model ../design/renders 1024 64
cd .. && node tools/build_roblox.js && node tools/test_anim_parity.js /ruta/a/luau
```
