# Dragón Sombrío (*Umbrafex ridens*), versión 2: remaster nocturno para Roblox Studio

La versión 2 parte del modelo original, con la misma escultura, la misma silueta y **el mismo rig**: 35 huesos con los mismos nombres y posiciones. Lo que cambia:
- más detalle para la visión nocturna;
- animaciones nuevas;
- un comportamiento de terror psicológico en el servidor, con un solo dragón para todos los jugadores;
- sonido.

La versión 1 completa está guardada en `v1_legacy/`. Al instalar en Studio, si ya había una v1, se mueve a `ServerStorage.DragonAssets.ShadowDragon_v1`.

Referencias: `design/reference_face.jpg` (la cara) y `design/reference_body.jpg` (el cuerpo).

## Qué cambia en el aspecto
- **Cabeza en malla propia (`Skull`)**: unos 15,5k triángulos y su propia textura de 1024 px, unas 4 veces más resolución en la cara. Usa los mismos huesos Head y Jaw.
- **Mandíbula**: barbilla más larga y adelantada, crestas óseas con nudos a los lados y una púa en el mentón.
- **Dientes irregulares**:
  - largos y cortos, torcidos;
  - alrededor del 12 % rotos y alrededor del 10 % que faltan;
  - nueve colmillos sueltos y una segunda fila detrás de los del frente;
  - encías hinchadas en cada raíz y labios de grosor irregular.
  - Siguen en la malla `Teeth`, que brilla con Neon tenue en la oscuridad.
- **Ojos**: cuencas hondas con borde de hueso. El punto rojo Neon lleva una `PointLight` roja de alcance mínimo, unos 2,4 studs, que solo tiñe la cuenca y el ceño. Es un brillo intenso pero controlado.
- **Lomo y cuello**: pliegues en anillo, tendones, venas moradas en relieve, nódulos, racimos de púas finas, cicatrices y colgajos de piel mudada. Todo va colocado con rayos sobre la piel real.
- **Texturas**:
  - piel gris carbón con manchas moradas de moratón y grietas finas de piel seca;
  - sombras de cavidad horneadas en el color;
  - rugosidad variable: boca húmeda y piel seca.
  - Es más clara que la v1 (0,068 frente a 0,035 de albedo), para que la visión nocturna saque relieve en lugar de una mancha negra.
- **Proporciones antinaturales sin mover articulaciones**: cuello más fino y dedos más largos, con nudillos.

## Animaciones
| Nombre | Qué hace |
|---|---|
| Idle (v2) | Respiración lenta y profunda (el pecho y la joroba se hinchan) y micro-movimientos de cabeza |
| Walk (v2) | Zancos irregulares y articulados: fases desiguales y articulaciones que tiemblan a destiempo |
| Detect → Watch | Se queda quieto, levanta la cabeza muy despacio y sostiene la pose |
| Chase | Rápido, bajo y agresivo, con la boca abierta (solo en ráfagas cortas) |
| Roar (v2) | Abre la sonrisa al máximo, estira el cuello y la cabeza tiembla ladeada |
| Freeze1-3 | Posturas extrañas de inmovilidad: cuello torcido, cabeza casi del revés o agazapado mirando hacia arriba |
| Run, Fly, TakeOff, Landing, Attack, Death | Las de la v1, sin cambios |

- **Mirada**: la cabeza sigue al jugador despacio (velocidad 1,1). Cada jugador siente que lo mira a él.
- **Inclinación de cabeza**: `DragonAnimator:SetHeadTilt`.
- **Rendimiento**: `DragonAnimator` tiene tres opciones nuevas. Si no se activan, nada cambia para los demás dragones.
  - `Paused`: congela la pose sin coste.
  - `UpdateInterval`: menos actualizaciones por segundo cuando está lejos.
  - `SetHeadTilt`: la inclinación de cabeza.
  - El cliente pausa el animador cuando el dragón es invisible y baja a 20 Hz o 10 Hz según la distancia.

## Comportamiento (un dragón para todos)
`ServerScriptService.ShadowStalker` decide qué hace el dragón con la lógica de `ShadowBrain`. Cada `ShadowClient` envía 5 veces por segundo hacia dónde mira su cámara y se encarga de animar, suavizar el movimiento y hacer los fundidos.

| Estado | Qué hace |
|---|---|
| Ausente | Uno o dos minutos sin aparecer. A veces el ambiente se queda en silencio de golpe. |
| Observa | Aparece lejos (60-170 studs), en la visión periférica (unos 70°), y mejor junto a árboles o rocas. Se queda quieto y ladea la cabeza. |
| Inmóvil | Si alguien lo mira directamente (con un rayo que comprueba que no hay obstáculos), se congela en mitad del movimiento. Si apartas la vista y vuelves a mirar, puede estar en otra postura o más cerca, puede haberse ido o puede seguir observando. |
| Acecha | Avanza despacio **solo mientras el objetivo no mira hacia él**. Se detiene a unos 32-48 studs. |
| Se desvanece | Si te acercas a menos de 38 studs, si lo miras fijamente entre 7 y 16 segundos o si se acaba su tiempo de presencia, se disuelve poco a poco. Los ojos se apagan los últimos. |
| Detecta | Cuando lo ves de reojo, levanta la cabeza. A veces sigue una sonrisa con chillido. |
| Persigue | Muy rara vez y con al menos 4 minutos entre persecuciones: una carrera corta que termina desvaneciéndose y en silencio. **No hace daño.** |

Para que no sea predecible:
- todos los tiempos son aleatorios;
- evita repetir la última elección;
- cada aparición dura entre 30 y 70 segundos;
- cambia de objetivo entre los jugadores.

**Sitios para aparecer**: pon partes con la etiqueta `ShadowPerch` (o dentro de `Workspace.ShadowPerches`) junto a árboles y zonas oscuras. Sin ellas, busca solo sitios en el suelo alrededor del jugador, mejor si hay objetos altos cerca.

**Ajustes**: los atributos de `ReplicatedStorage.Dragons.ShadowDragon.Settings` permiten cambiar cosas sin tocar código:
- `VanishDistance`, `StalkSpeed`, `ChaseChance`, `ChaseCooldown`, etc., o cualquier valor numérico de `ShadowBrain.Defaults`;
- `StalkerEnabled`, `Debug` (imprime los estados), `ProvideNightVision`, `TeethGlow` y `AmbientGroupName`.

## Sonido (`sounds/`, generados con `tools/make_sounds.py`)
Son sonidos sintetizados desde cero, sin muestras de terceros:

| Sonido | Dónde suena |
|---|---|
| Breath | Respiración grave en bucle, sale del cuerpo del dragón |
| Creak | Crujidos de articulaciones, cuando está cerca |
| Shriek | Chillido del rugido |
| Whisper | Ambiente: susurro |
| DistantBreath | Ambiente: respiración lejana |
| Crack | Ambiente: rama que cruje |

Los de ambiente suenan cada vez en un punto distinto alrededor del jugador, a 25-65 studs, para que cueste localizarlos.

**Silencio repentino**: baja a 0 los `SoundGroup` llamados `Ambient` (configurable con `AmbientGroupName`) y luego los recupera en 2,5 segundos.

⚠️ Hay que subir los .ogg a Roblox (Asset Manager › Import) y pegar sus ids en `SOUND_IDS`, al principio del instalador. Sin ids, el dragón funciona igual, pero en silencio.

## Contenido
| Archivo | Para qué sirve |
|---|---|
| `model/ShadowDragon.fbx` | **Para Roblox.** Armature más Body, Skull, Teeth, WingL y WingR con skinning |
| `model/*_{color,normal,roughness}.png` | Texturas de Body, Skull, WingL y WingR para SurfaceAppearance |
| `model/rig.json` | Huesos, ojos y medidas |
| `roblox/InstallShadow.lua` | **Instalador para la Command Bar** (lo genera `tools/build_roblox.js`) |
| `roblox/ShadowStalker.server.lua` | Comportamiento en el servidor |
| `roblox/ShadowClient.client.lua` | Animación, fundidos, ojos, sonido de ambiente, silencios y visión nocturna de prueba (N) |
| `roblox/ShadowBrain.lua` | Lógica de estados, pura y probada fuera de Roblox |
| `roblox/ShadowAnimations.lua` / `DragonAnimator.lua` | Animaciones por datos y motor |
| `roblox/ShadowShowcase.client.lua` | Vitrina de prueba (botones 1 a 9), solo con `INSTALL_SHOWCASE = true` |
| `sounds/*.ogg` | Los seis sonidos |
| `v1_legacy/` | La versión 1 completa (respaldo) |

## Instalación
1. **Avatar › Import 3D** → `model/ShadowDragon.fbx`, con **Rig Type = Custom** y **sin combinar las mallas**.
2. Opcional: sube los sonidos y las texturas, y pega sus ids en `SOUND_IDS` y `MAPS`, al principio de `roblox/InstallShadow.lua`.
3. Selecciona el modelo importado y pega todo `roblox/InstallShadow.lua` en **View › Command Bar**.
4. Opcional: coloca partes `ShadowPerch` en el mapa.
5. **Play**: el dragón aparece al cabo de 20-45 segundos. Ajusta `FirstAbsent` si quieres. La tecla N enciende una visión nocturna de prueba; si el juego ya tiene la suya, pon `PROVIDE_NIGHT_VISION = false`.

## Qué está verificado y qué no
- ✅ Blender 5.3 genera y exporta la malla, el rig (idéntico al de la v1), los pesos y las texturas. Ninguna malla pasa de 20k triángulos.
- ✅ Todo el Luau compila y pasa `luau-analyze` sin avisos nuevos. La prueba de paridad Luau ↔ JS de las animaciones pasa.
- ✅ `tools/test_brain.js` simula horas de juego y comprueba lo siguiente:
  - nunca se mueve mientras alguien lo mira;
  - si lo ven, se congela en el mismo instante;
  - solo cambia de postura cuando nadie lo ve;
  - se desvanece si te acercas;
  - deja al menos 4 minutos entre persecuciones;
  - está visible menos del 50 % del tiempo (unos 23 % con mirada aleatoria);
  - pasa por al menos 6 estados distintos.
- ⚠️ **No se ha ejecutado dentro de Roblox Studio.** Falta confirmar:
  - la importación del skinning con cinco mallas;
  - el instalador;
  - la replicación con varios jugadores;
  - el rendimiento real.
- Límites:
  - no tiene pathfinding: acecha en línea recta sobre el terreno y, si algo le bloquea el paso, se queda quieto en lugar de rodearlo;
  - no hace daño;
  - las texturas son de 1024 px.

## Regenerar
```
cd sculpt
python stage_body.py <salida>/sculpt 0.05 24            # escultura de alta (bpy 5.x + scikit-image)
python produce.py <salida>/sculpt/sculpt_high.blend ../model ../design/renders 1024 64
cd .. && python tools/make_sounds.py                     # sonidos (numpy, scipy, ffmpeg)
node tools/build_roblox.js && node tools/test_anim_parity.js /ruta/a/luau && node tools/test_brain.js /ruta/a/luau
```
