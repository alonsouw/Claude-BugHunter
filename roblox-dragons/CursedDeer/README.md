# Ciervo maldito (*Cervus falsus*): paquete para Roblox Studio

Un ciervo de cola blanca en 3D. **Uno de cada siete ciervos del mapa está maldito**: parece normal hasta que te acercas, y entonces se transforma con una animación en la criatura de las referencias.
- `design/reference_mouth.jpg`: la cabeza se parte por debajo con hileras de agujas.
- `design/reference_creature.jpg`: cuello largo de carne roja, cuerpo gris con ojos, tentáculos y patas largas.

## Las dos formas, un solo esqueleto
| Malla | Triángulos | Qué es |
|---|---|---|
| `DeerBody` | 18,5k | Ciervo: pelaje pardo con degradados (lomo más oscuro, vientre crema, garganta, anillo del ojo, banda del hocico y bajo la cola blancos), trufa negra, orejas grandes y pezuñas hendidas |
| `Antlers` | 4k | Cuernas (comunes a las dos formas; con `AntlerChance` la mitad son hembras sin cuernas) |
| `HorrorBody` | 19,5k | Criatura: piel gris pálida, costillas y vértebras marcadas, flancos hundidos, 5 ojos abiertos en el pecho y los hombros, **sin cuello**: la cabeza cuelga de la columna vertebral al aire (vértebras con apófisis, discos de carne, tendones y manchas de sangre) que sale de un hueco desgarrado en el pecho rodeado por un collar de dientes, con piel rota también bajo el cráneo; cabeza que se parte por debajo con agujas e interior morado |
| `Tentacles` | 14k | 7 tentáculos que brotan del cráneo: un núcleo de carne roja cubierto de placas rectangulares encadenadas (y placas iguales a lo largo del lomo), cada uno con 4 huesos |

Las dos formas comparten **56 huesos**. La criatura no es otro modelo: es la misma anatomía, un poco más gruesa, que aparece por encima del ciervo durante la transformación. Después:
- la columna del cuello y las patas se estiran moviendo los huesos a lo largo de su eje; cada vértebra va casi rígida con su hueso, así que al estirarse la columna se separa y se ven los tendones;
- los tentáculos crecen desde dentro del cráneo.

## Animaciones (`src/deer_anims.js`)
- **Ciervo**: Graze (pastar), Idle, Walk, Run (galope a saltos con la cola blanca levantada), Alert y Death.
- **Transform** (4,6 s):
  1. Se queda rígido.
  2. Convulsiona.
  3. A los 1,15 s aparece la piel de la criatura.
  4. La columna y las patas se estiran a tirones, con crujidos.
  5. Brotan los tentáculos.
  6. La mandíbula cae hasta unos 135° y la cabeza mira al cielo.
- **Criatura**: CreatureIdle, CreatureWalk, CreatureRun y Shriek.
- Las animaciones de la criatura se generan con `makeDeerAnims(rig.json)`, así se estiran exactamente a lo largo de los huesos. `tools/build_roblox.js` las convierte en `roblox/DeerAnimations.lua`.

## Comportamiento (un solo rebaño para todos)
`ServerScriptService.DeerHerd` crea los ciervos (14 por defecto, en manadas de 4) y decide qué hacen con `DeerBrain`. `DeerClient` anima los huesos en cada jugador.
- **Normales**: pastan, caminan, te miran y huyen si te acercas. Al huir avisan a la manada.
- **Malditos** (uno de cada 7, elegidos al azar; con 14 ciervos hay 2):
  - No huyen: se quedan mirándote.
  - Cuando te acercas a entre 12 y 26 studs (al azar por ciervo), se transforman.
  - Que un ciervo está maldito no se publica a los clientes, así que no se puede saber de antemano.
- **Criatura**:
  - Al transformarse, chilla.
  - Después alterna entre quedarse mirándote, seguirte despacio y hacer carreras cortas hacia ti, con pausa entre carreras.
  - Si te alejas más de 150 studs durante 25 s, se desvanece y vuelve a ser un ciervo en su manada. Sigue maldito.
- **Ajustes** (al principio del instalador o en `Settings`):
  - `COUNT`, `CURSED_RATIO` y `SPAWN_CENTER` / `SPAWN_RADIUS`;
  - `DAMAGE`: 0 por defecto, sin daño;
  - `NIGHT_ONLY`: solo se transforman de noche;
  - las distancias de `DeerBrain.Defaults`.
- **Rendimiento**:
  - Sin física: posiciones calculadas y publicadas 10 veces por segundo.
  - Los clientes animan a 60, 20 u 8 Hz según la distancia y pausan los ciervos que no se ven.

## Sonido (`sounds/`, generados con `tools/make_sounds.py`, sin muestras de terceros)
| Sonido | Dónde suena |
|---|---|
| Snort | Resoplido de alarma al huir |
| Crack | Huesos que crujen en la transformación |
| Shriek | Un balido que se rompe en un chillido |

Hay que subirlos y pegar sus ids en `SOUND_IDS`.

## Instalación
1. **Avatar › Import 3D** → `model/CursedDeer.fbx`, con **Rig Type = Custom** y **sin combinar las mallas**.
2. Opcional: sube las texturas PNG y los sonidos, y pega sus ids en `MAPS` y `SOUND_IDS`, al principio de `roblox/InstallDeer.lua`.
3. Selecciona el modelo importado y pega todo `roblox/InstallDeer.lua` en **View › Command Bar**.
4. Opcional: coloca partes con la etiqueta `DeerSpawn` (o dentro de `Workspace.DeerSpawns`). Cada una es el centro de una manada.
5. **Play**.

## Qué está verificado y qué no
- ✅ Blender 5.3 genera y exporta la escultura, las mallas (todas por debajo de 20k), los huesos, los pesos y las texturas.
- ✅ El visor de la ficha usa el mismo GLB con huesos. La secuencia de la transformación de la ficha está capturada de ese visor con las mismas animaciones que Roblox.
- ✅ El Luau compila sin avisos de `luau-analyze`, y la prueba de paridad Luau ↔ JS de las animaciones pasa.
- ✅ `tools/test_brain.js` comprueba:
  - la proporción de 1 de cada 7 (7→1, 14→2, 70→10);
  - que los normales huyen y nunca se transforman;
  - que los malditos no huyen y se transforman al acercarte;
  - `NIGHT_ONLY`;
  - el enfriamiento entre carreras;
  - que desaparecen y vuelven a ser ciervos al alejarte;
  - que en 70 ciervos solo se transforman los 10 malditos.
- ⚠️ **No se ha ejecutado dentro de Roblox Studio.** Falta confirmar:
  - el skinning de cuatro mallas sobre un esqueleto;
  - el instalador;
  - la red con varios jugadores.
- Límites:
  - No tiene pathfinding: se mueven en línea recta y, si algo les bloquea, se paran (huyendo, giran).
  - Al abrir la mandíbula, la piel de las comisuras se estira mucho; queda como carne que se desgarra.

## Regenerar
```
cd sculpt
python stage_deer.py <salida>/sculpt 0.015 24
python produce_deer.py <salida>/sculpt/sculpt_high.blend ../model ../design/renders 1024 48
cd .. && python tools/make_sounds.py
node tools/build_roblox.js && node tools/test_anim_parity.js /ruta/a/luau && node tools/test_brain.js /ruta/a/luau
```
