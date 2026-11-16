// Uso: node export_model.js <three.min.js> <GLTFExporter.js> <carpeta_salida>
// Construye el Dragón Depredador en Chromium y exporta GLB + atlas PBR + rig.json.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const [, , threePath, exporterPath, outDir] = process.argv;
const SRC = path.join(__dirname, '..', 'src');

(async () => {
  fs.mkdirSync(outDir, { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage();
  page.on('pageerror', e => console.error('pageerror:', e.message));
  await page.setContent('<!doctype html><html><body></body></html>');
  for (const f of [threePath, exporterPath, path.join(SRC, 'dragon_core.js'), path.join(SRC, 'predator_model.js'), path.join(SRC, 'predator_anims.js')]) await page.addScriptTag({ content: fs.readFileSync(f, 'utf8') });

  const res = await page.evaluate(async () => {
    const M = PredatorModel.build(THREE, { atlasSize: 1024 });
    const tex = (canvas, srgb) => { const t = new THREE.CanvasTexture(canvas); t.flipY = false; if (srgb) t.encoding = THREE.sRGBEncoding; return t; };
    const mat = new THREE.MeshStandardMaterial({ name: 'PredatorSkin', map: tex(M.atlas.color, true), normalMap: tex(M.atlas.normal), roughnessMap: tex(M.atlas.roughness), roughness: 1, metalness: 0 });
    const scene = new THREE.Scene(); const root = new THREE.Group(); root.name = 'PredatorDragon'; scene.add(root);
    for (const p of M.parts) { const m = new THREE.Mesh(p.geometry, mat); m.name = p.name; root.add(m); }
    const glb = await new Promise(r => new THREE.GLTFExporter().parse(scene, r, { binary: true, embedImages: true }));
    const b64 = buf => { let s = ''; const u = new Uint8Array(buf); for (let i = 0; i < u.length; i += 0x8000) s += String.fromCharCode.apply(null, u.subarray(i, i + 0x8000)); return btoa(s); };
    const rig = M.parts.map(p => ({ name: p.name, parent: p.parent, pivot: p.pivot.toArray().map(v => +v.toFixed(4)), center: p.center.toArray().map(v => +v.toFixed(4)), tris: p.tris, mats: p.mats }));
    let box = new THREE.Box3(); for (const p of M.parts) { p.geometry.computeBoundingBox(); box.union(p.geometry.boundingBox); }
    return { glb: b64(glb), rig, bounds: { min: box.min.toArray(), max: box.max.toArray() },
      color: M.atlas.color.toDataURL('image/png'), normal: M.atlas.normal.toDataURL('image/png'), roughness: M.atlas.roughness.toDataURL('image/png') };
  });

  fs.writeFileSync(path.join(outDir, 'PredatorDragon.glb'), Buffer.from(res.glb, 'base64'));
  for (const k of ['color', 'normal', 'roughness']) fs.writeFileSync(path.join(outDir, `PredatorDragon_${k}.png`), Buffer.from(res[k].split(',')[1], 'base64'));
  fs.writeFileSync(path.join(outDir, 'rig.json'), JSON.stringify({ name: 'PredatorDragon', units: 'studs', forward: '-Z', bounds: res.bounds, parts: res.rig }, null, 1));
  const tris = res.rig.reduce((a, p) => a + p.tris, 0);
  console.log(`partes: ${res.rig.length}  triángulos: ${tris}  máx por parte: ${Math.max(...res.rig.map(p => p.tris))}`);
  console.log('límites:', res.bounds.min.map(v => v.toFixed(1)), res.bounds.max.map(v => v.toFixed(1)));
  await browser.close();
})();
