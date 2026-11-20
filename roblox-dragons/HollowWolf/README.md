# Lobos huecos (*Canis inanis*): paquete para Roblox Studio

Manadas de lobos famélicos que salen al anochecer, cazan en grupo y no cruzan la luz. Son originales, para un juego de supervivencia nocturna en el bosque.

## Cuatro tipos (mismo esqueleto de 30 huesos y mismas animaciones)
Cada tipo tiene su propia malla (unos 19,5 mil triángulos cada una; el máximo de Roblox es 20 mil) con texturas de color, normal y rugosidad de 1024 px.

| Tipo | Aspecto | Vida / mordisco | Cómo caza |
|---|---|---|---|
| **Normal** (`WolfNormal`) | Gris pardo con la montura oscura; costillas marcadas, algunas calvas de sarna, oreja mordida. Ojos amarillos. | 60 / 8 | Equilibrado. |
| **Alfa** (`WolfAlpha`, uno por manada) | Un 35 % más grande y corpulento, casi negro, crin enorme, púas de hueso que rompen la piel del lomo y la nuca, muchas cicatrices, las dos orejas mordidas. Ojos rojo anaranjado. | 150 / 15 | Lidera; aúlla al verte y la manada entera caza. Casi nunca huye. Voz más grave. |
| **Sarnoso** (`WolfMangy`) | Esquelético y casi calvo, con la piel rosácea al aire y la cola pelada. Ojos amarillo pálido. | 35 / 5 | Más rápido (×1,2) y muerde más a menudo, pero huye a mitad de vida. |
| **Pálido** (`WolfPale`) | Blanco ceniza, de pelo largo, sin sarna. Ojos azul hielo. | 70 / 10 | Silencioso: no gruñe ni ruge. Sus ojos solo se encienden cuando está a menos de 25 studs. |

- **Composición de cada manada:** un alfa, y el resto al azar con estas probabilidades (se cambian al principio del instalador):
  - normal: 60 %;
  - sarnoso: 25 %;
  - pálido: 15 %.
- **Rasgos comunes:**
  - hocico largo siempre gruñendo, con los colmillos al aire;
  - gorguera, crin y cola de mechones;
  - ojos que en el juego son puntos Neon con una luz diminuta del color de su tipo.

## Animaciones (`src/wolf_anims.js` → `roblox/WolfAnimations.lua`)
| Nombre | Qué hace |
|---|---|
| Idle | Reposo |
| Sniff | Olfatea con la cabeza en el suelo |
| Walk | Camina |
| Trot | Trote de caza, con la cabeza baja |
| Run | Galope |
| Howl | Se sienta a medias y aúlla al cielo |
| Growl | Gruñe agazapado y temblando |
| Attack | Se agacha, salta y muerde |
| Hurt | Se encoge al recibir daño |
| Death | Muere |

La cabeza sigue al jugador mientras caza.

## La manada en el juego
`ServerScriptService.WolfPack` decide con `WolfBrain` y mueve los modelos también en el servidor, para que las armas acierten. `WolfClient` anima los huesos en cada jugador.
- **Para todos**:
  - Por defecto hay 2 manadas de 4 lobos, con un alfa en cada una.
  - Aparecen lejos de los jugadores, en partes con la etiqueta `WolfSpawn` o alrededor de `SPAWN_CENTER`.
- **De noche** (`NIGHT_ONLY`, por defecto `true`): salen al anochecer (`ClockTime` ≥ 18,5) y al amanecer se retiran corriendo y desaparecen.
- **Caza**:
  1. Deambulan siguiendo al alfa.
  2. Cuando un jugador se acerca a 70 studs, el alfa aúlla y toda la manada caza.
  3. Lo rodean gruñendo a 9-14 studs, cada uno por un flanco.
  4. Se lanzan a morder por turnos, como mucho 2 a la vez, y vuelven al cerco.
- **Daño y vida**: dependen del tipo (ver la tabla). Con poca vida huyen; el sarnoso, a mitad de vida.
- **Herirlos con tus armas**, desde el servidor:
  `ReplicatedStorage.Creatures.HollowWolf.DamageWolf:Invoke(lobo, cantidad)`.
  También se puede bajar su atributo `Health`. La malla tiene `CanQuery = true` para que los rayos de las armas le acierten.
- **La luz** (`SafeLight`):
  - Las partes con esa etiqueta y un atributo `Radius` (por defecto 25) son zonas seguras.
  - Ningún lobo entra en ellas y no muerden a quien está dentro: rodean el borde de la luz.
  - Si la luz los alcanza, huyen.
  - Es el gancho para la hoguera.

## Sonido (`sounds/`, generados con `tools/make_sounds.py`, sin muestras de terceros)
| Sonido | Cuándo suena |
|---|---|
| Howl | El alfa, al descubrirte (se oye a 400 studs) |
| Growl | En el cerco |
| Snarl | Al lanzarse |
| Bite | Mordisco que acierta |
| Yelp | Herido o muerto |

Hay que subirlos y pegar sus ids en `SOUND_IDS`.

## Instalación
1. **Avatar › Import 3D** → `model/HollowWolf.fbx`, con **Rig Type = Custom** y **sin combinar las mallas**.
2. Opcional: sube las texturas y los sonidos y pega sus ids en `MAPS` y `SOUND_IDS`, al principio de `roblox/InstallWolves.lua`.
3. Selecciona el modelo importado y pega todo `roblox/InstallWolves.lua` en **View › Command Bar**.
4. Opcional: coloca partes con la etiqueta `WolfSpawn` y partes con la etiqueta `SafeLight` (con `Radius`).
5. Play de noche, o pon `NIGHT_ONLY = false` para probar de día.

## Qué está verificado y qué no
- ✅ Blender 5.3 genera y exporta la escultura, la malla, los huesos, los pesos y las texturas.
- ✅ Las animaciones del visor de la ficha están capturadas con las mismas animaciones que Roblox, cargadas con las mismas restricciones de seguridad que la página publicada.
- ✅ El Luau compila y pasa la prueba de paridad Luau ↔ JS.
- ✅ `tools/test_brain.js` comprueba:
  - que no cazan a quien está lejos;
  - que el alfa aúlla una sola vez;
  - que rodean y muerden, como mucho 2 a la vez;
  - que nunca muerden dentro de la luz y huyen si la luz los alcanza;
  - que de día desaparecen;
  - que reaccionan al daño, huyen con poca vida y mueren una sola vez;
  - que el pálido no gruñe ni ruge y que el sarnoso huye antes que el normal.
- ⚠️ **No se ha ejecutado dentro de Roblox Studio.** Falta confirmar el skinning, el instalador y el combate con varios jugadores.
- Límites:
  - No tienen pathfinding: se mueven en línea recta sobre el terreno.
  - Hace falta un arma de tu juego que llame a `DamageWolf` para poder herirlos.

## Regenerar
```
cd sculpt
python stage_wolf.py <salida>/sculpt 0.012 16
python produce_wolf.py <salida>/sculpt/sculpt_high.blend ../model ../design/renders 1024 48
cd .. && python tools/make_sounds.py
node tools/build_roblox.js && node tools/test_anim_parity.js /ruta/a/luau && node tools/test_brain.js /ruta/a/luau
```
