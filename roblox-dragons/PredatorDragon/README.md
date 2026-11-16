# Dragón Depredador (*Karnathys sanguifauces*), versión 2: paquete para Roblox Studio

Rehecho desde cero a partir de las referencias del usuario (`design/reference_render.jpg` y `design/reference_sheet.jpg`).
Es un cuadrúpedo negro carbón con heridas y costillas al aire, fauces babeantes con la lengua colgando, corona de cuchillas óseas, alas enormes con membrana granate rasgada y una cola larga con púas y aleta de lóbulos.

**No tiene ojos.** En cada cuenca hay un punto de luz blanca diminuto: de día casi no se ve y en la oscuridad es lo único visible.

## Desnutrición y deformidad (sculpt/body.py, sculpt/deform.py)
- Famélico: torso y cuello estrechos, vientre hundido, costillas y vértebras marcadas bajo la piel, caderas y omóplatos salientes, patas flacas de articulaciones nudosas y sienes hundidas.
- Segunda boca dentada en el flanco derecho, más de 30 tajos abiertos repartidos por todo el cuerpo (colocados con rayos contra la piel real), joroba de vértebras que rompen la piel y costillas astilladas.
- Mandíbula derecha hinchada de tumores, cuerno torcido en la mejilla, cráneo pelado, placas de podredumbre con pústulas, cola descarnada hasta las vértebras y antebrazo izquierdo con el hueso al aire. Alas hechas jirones.

## Heridas de batalla (gore)
- Mejilla izquierda arrancada con el maxilar, las raíces de los dientes y tiras de músculo al aire. Babas con sangre, y sangre en labios, colmillos y mentón.
- Lomo abierto con las vértebras expuestas, costillar desgarrado con jirones de carne y regueros de sangre.
- Lanza rota en el hombro izquierdo, dos flechas en el cuello, zarpazos en el muslo derecho y garras delanteras ensangrentadas.
- En el juego: `BloodDripPoint` (partículas de sangre que caen de la mandíbula y siguen al hueso `Jaw`) y un charco de sangre que se extiende al morir.
- ⚠️ Roblox exige declarar la sangre y el gore en el cuestionario de madurez del contenido. El gore realista solo se permite en experiencias 17+. Para una versión sin gore, quita `gore.apply` en `sculpt/stage_body.py` y regenera.

## Cómo se construyó
1. **Escultura** (`sculpt/sdf.py`, `head.py`, `body.py`, `membrane.py`): campos de distancia con uniones suaves. Cada músculo, hueso, cuerno y diente es una forma que se funde con las demás, y el resultado es una piel continua de alta resolución (vóxel de 0,05 studs). Primero se esculpió la cabeza, comparándola con la hoja de referencia, y después el cuerpo, la cola y las alas.
2. **Retopología** (`sculpt/produce.py`): decimado en dos pasos para que la cabeza conserve los dientes. Resultado: Body unos 19k triángulos y WingL/WingR unos 9k cada una, bajo el límite de 20k por MeshPart.
3. **Horneado**: color, normal y rugosidad de 1024 px por malla, sacados de la escultura (escamas, relieve y brillo).
4. **Huesos**: 35 Bones con pesos calculados por zona anatómica. La mandíbula y la lengua van aparte, las babas se reparten entre las dos mandíbulas y la membrana sigue a los huesos del ala.

## Contenido
| Archivo | Para qué sirve |
|---|---|
| `model/PredatorDragon.fbx` | **Para Roblox.** Armature + mallas Body, WingL y WingR con skinning y texturas |
| `model/PredatorDragon.glb` | La misma malla con huesos, para el visor web |
| `model/{Body,WingL,WingR}_{color,normal,roughness}.png` | Texturas para SurfaceAppearance |
| `model/rig.json` | Huesos (posición de reposo en studs, Y arriba, mirando a −Z), puntos de los ojos y medidas |
| `roblox/InstallPredator.lua` | **Instalador para la Command Bar** |
| `roblox/DragonAnimator.lua` | Animaciones por datos para Motor6D **y Bones**, más `SetLookTarget` para la mirada |
| `roblox/PredatorAnimations.lua` | Idle (acechar), Walk, Run, Fly, TakeOff, Landing, Attack, Roar y Death |
| `roblox/PredatorShowcase.client.lua` | Vitrina nocturna: puntos de los ojos, mirada al jugador, botones 1 a 9 y L para día o noche |

## Instalación
1. **Avatar › Import 3D** → `model/PredatorDragon.fbx`.
   En el importador pon **Rig General › Rig Type = Custom** y **no** combines las mallas. Pulsa Import.
2. Selecciona el modelo importado en el Explorer.
3. **View › Command Bar**: pega todo `roblox/InstallPredator.lua` y pulsa Enter. La salida muestra la escala detectada y el error de los huesos.
4. **Play**: se hace de noche y en `Workspace.DragonShowcase.Stage_Predator` solo se ven dos puntos blancos que te siguen. L enciende la luz y 1 a 9 lanzan las animaciones.

Detalles técnicos:
- El instalador ancla `Body` y suelda las alas a ella, para que las tres mallas formen una sola asamblea y los huesos las deformen juntas.
- Si el importador duplica el esqueleto por malla, `DragonAnimator` mueve todas las copias.
- Las animaciones se escriben en `Bone.Transform`, convertidas desde los ejes del modelo con la orientación de reposo de cada hueso.
- Los ojos (`EyeLPoint` y `EyeRPoint`) son esferas Neon de 0,07 studs que la vitrina coloca cada frame sobre el hueso `Head`. De día tienen transparencia 0,93 y de noche 0. No llevan luz, así que no iluminan la cara.

## Qué está verificado y qué no
- ✅ La malla, los huesos, los pesos y las texturas se generan y exportan en Blender 5.3. El FBX contiene la armature y las tres mallas.
- ✅ El visor de la ficha carga el mismo GLB con huesos y lo anima con la misma conversión de ejes que `DragonAnimator.lua`.
- ✅ El código Luau compila, y la prueba de paridad Luau ↔ JS de las animaciones pasa.
- ⚠️ **No se ha ejecutado dentro de Roblox Studio.** Hay que confirmar la importación del skinning con varias mallas y el instalador.
- Límites: texturas de 1024 px (máximo de Roblox), Walk y Run en el sitio, sin IA ni sonido.

## Regenerar
```
cd sculpt
python stage_body.py <salida>/sculpt 0.05 32            # escultura de alta + renders de comparación (bpy 5.x + scikit-image)
python produce.py <salida>/sculpt/sculpt_high.blend ../model ../design/renders 1024 64
cd .. && node tools/build_roblox.js && node tools/test_anim_parity.js /ruta/a/luau
```
