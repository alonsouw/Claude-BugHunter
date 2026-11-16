# Bestiario Umbral: dragones de fantasía oscura para Roblox Studio

## Estado
- **Etapa 1 (conceptos): hecha.** `concepts/bestiario.html` contiene las fichas de las seis especies. Cada ficha se dibuja con un esbozo 3D procedural (three.js) y muestra la vista libre, la frontal, la lateral (junto a un avatar de 5 studs), la posterior, la cabeza, el ala y la cola, además de la paleta, las medidas en studs, las notas de animación y el rig previsto.
- Etapa 2: pendiente. Falta elegir el primer dragón.

Los esbozos de la etapa 1 son proxies de volumen, no mallas finales de Roblox. Sirven para fijar la silueta y las proporciones antes de modelar en Blender.

## Especies
| # | Especie | Rasgo clave |
|---|---------|-------------|
| I | Dragón Abisal (*Vharneth pallidus*) | Cuerpo de anguila y alas fusionadas a los flancos |
| II | Dragón Depredador (*Karnathys sanguifauces*) | Cuadrúpedo negro con franjas incandescentes y cuatro ojos |
| III | Dragón Aberrante (*Xethra contorta*) | Cuerpo asimétrico sobre zancos y cuello de jirafa |
| IV | Dragón Aéreo (*Silvanyx ventisecans*) | Tipo wyvern con 39 studs de envergadura |
| V | Dragón Ancestral (*Gorrmathos primaevus*) | Gigante con placas óseas y maza caudal |
| VI | Dragón Sombrío (*Nhulgarax umbrifer*) | Extremidades de araña, alas rasgadas y sonrisa |

## Flujo previsto (etapas 3 a 6)
Blender: mallas por segmento, texturas PBR y armature → .fbx con Bones → importación en Roblox Studio (MeshParts, SurfaceAppearance) → Motor6D y Bones → animaciones con Animation Editor o clips importados.

```
ReplicatedStorage/Dragons/{AbyssalDragon,PredatorDragon,AberrantDragon,AerialDragon,AncientDragon,ShadowDragon}
ServerStorage/DragonAssets
Workspace/DragonShowcase
StarterPlayer/StarterPlayerScripts
```
