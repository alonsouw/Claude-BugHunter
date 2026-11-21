# Infectados: humanos infectados de bloques para Roblox

Cinco tipos de infectados al estilo Roblox: **personajes hechos de Parts (bloques)**, con Humanoid, ropa rota, heridas, sangre, costillas al aire y ojos que brillan. No hace falta importar ningún modelo: el instalador los construye pieza a pieza en Studio.

## Los cinco
| Tipo | Aspecto | Vida / golpe | Cómo actúa |
|---|---|---|---|
| **Walker** (común) | Piel verdosa, camisa y vaqueros rotos, mandíbula colgando, tajo en la frente | 100 / 15 | Arrastra una pierna con los brazos por delante. Persigue a 9 studs/s. Es el más numeroso. |
| **Runner** (corredor) | Flaco, pálido y encorvado, el pecho al aire con las costillas marcadas, ojos rojos | 60 / 10 | Corre a 22 studs/s, encorvado y sacudiendo los brazos. |
| **Bloater** (hinchado) | Torso enorme lleno de pústulas amarillo verdosas (algunas brillan) y la costura reventada | 140 / 10 | Lento. **Al morir revienta**: hasta 35 de daño en 12 studs y una nube verde. |
| **Screamer** (gritón) | Brazos larguísimos, cráneo partido, boca enorme llena de dientes, ojos blancos | 70 / 8 | **Al verte grita** (recarga de 25 s) y todos los infectados en 120 studs van a por ti. Luego corre. |
| **Brute** (bruto) | Un 40 % más grande, con el brazo derecho deforme, púas de hueso y un puño enorme | 400 / 35 | **Golpe al suelo**: 35 de daño a todos en 8 studs y los lanza por el aire. |

## Cómo están hechos (`src/infected_blueprints.js`)
- **Esqueleto de bloques** (tipo R15):
  - torso;
  - cabeza con mandíbula;
  - brazos y piernas con codo y rodilla.
- **Articulaciones**: cada una es un `Motor6D` con C0/C1 sin rotación, situado en su pivote.
- **Detalles**: 67 a 94 bloques soldados por personaje. Son:
  - ojos Neon;
  - boca, dientes y sangre;
  - jirones y agujeros en la ropa;
  - costillas;
  - dedos y zapatos;
  - en algunos tipos, pústulas o púas de hueso.
- **Humanoid real**:
  - `HipHeight` propio y `BreakJointsOnDeath = false`;
  - **cualquier arma de Roblox les hace daño**;
  - caminan con física y persiguen con `PathfindingService`, así que rodean paredes y obstáculos.

## Animaciones (`src/infected_anims.js` → `roblox/InfectedAnimations.lua`)
| Nombre | Qué hace |
|---|---|
| Idle | Se balancea con tirones de cabeza |
| Walk | Arrastra los pies cojeando, con los brazos por delante |
| Run | Corre desbocado |
| Attack | Zarpazo con las dos manos y mordisco |
| Scream | Grita: cabeza atrás, boca abierta al máximo y brazos abiertos temblando |
| Slam | El bruto golpea el suelo con el brazo deforme |
| Hurt | Se encoge al recibir daño |
| Death | Se desploma de bruces |

Las reproduce cada cliente con `DragonAnimator` (Roblox no replica `Motor6D.Transform` desde el servidor).

## En el juego
- **Aparecen**: `InfectedSpawner` crea hasta 20 infectados a la vez.
  - Salen en partes con la etiqueta `InfectedSpawn` o alrededor de `SPAWN_CENTER`, lejos de los jugadores.
  - Todos los jugadores ven los mismos.
- **Te detectan**:
  - si te ven a su distancia de detección, con línea de visión;
  - o si un gritón grita cerca.
- **Te persiguen**: si te pierden de vista un rato y estás lejos, vuelven a vagar.
- **Al morir**: el cuerpo se queda un rato y luego desaparece. A los `RESPAWN_DELAY` segundos sale otro.
- **Ajustes**:
  - al principio del instalador: cantidad, probabilidades de cada tipo y solo de noche;
  - en `Settings`: cualquier estadística, como `BruteHealth`, `RunnerChaseSpeed` o `WalkerWeight`.

## Sonido (`sounds/`, generados con `tools/make_sounds.py`, sin muestras de terceros)
| Sonido | Cuándo suena |
|---|---|
| Groan | Gemido al deambular |
| Scream | El grito del gritón (se oye a 250 studs) |
| Hit | Golpe que acierta |
| Pop | El hinchado revienta |
| Roar | El bruto al golpear |

Hay que subirlos y pegar sus ids en `SOUND_IDS`.

## Instalación
1. Opcional: sube `sounds/*.ogg` y pega sus ids en `SOUND_IDS`, al principio de `roblox/InstallInfected.lua`.
2. Pega todo `roblox/InstallInfected.lua` en **View › Command Bar** y pulsa Enter.
   - Construye los cinco tipos en `ReplicatedStorage.Creatures.Infected.Types`.
   - Deja una vista previa en `Workspace.InfectedPreview`, que se borra al jugar.
3. Opcional: coloca partes con la etiqueta `InfectedSpawn`.
4. **Play**.

## Qué está verificado y qué no
- ✅ Los planos generan los cinco personajes en el visor de la ficha. Las capturas salen de ahí, con las mismas animaciones que Roblox.
- ✅ El Luau compila sin avisos de `luau-analyze`, y la prueba de paridad Luau ↔ JS de las animaciones pasa.
- ✅ `tools/test_brain.js` comprueba:
  - que no persiguen a quien está lejos o fuera de su vista;
  - que persiguen al verte;
  - que atacan solo a su alcance y respetando la recarga;
  - que el gritón grita una vez y luego corre;
  - que acuden al grito aunque no te vean;
  - que el bruto golpea el suelo;
  - que vuelven a vagar si te pierden;
  - que reaccionan al daño y mueren una sola vez.
- ⚠️ **No se ha ejecutado dentro de Roblox Studio.** Falta confirmar:
  - el instalador;
  - la física de los Humanoid con este rig;
  - el pathfinding y la red con varios jugadores.

## Regenerar
```
python tools/make_sounds.py
node tools/build_roblox.js && node tools/test_anim_parity.js /ruta/a/luau && node tools/test_brain.js /ruta/a/luau
```
