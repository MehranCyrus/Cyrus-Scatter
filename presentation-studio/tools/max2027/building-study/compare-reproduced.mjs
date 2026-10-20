import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import { readFile,writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';
const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
function orientedIndexHash(accessor) {
  const input = accessor.getArray(), output = new Uint32Array(input.length);
  for (let i = 0; i < input.length; i += 3) {
    let best = 0;
    for (let r = 1; r < 3; r++) for (let k = 0; k < 3; k++) { const a = input[i + (r + k) % 3], b = input[i + (best + k) % 3]; if (a < b) { best = r; break; } if (a > b) break; }
    for (let k = 0; k < 3; k++) output[i + k] = input[i + (best + k) % 3];
  }
  return hash(new Uint8Array(output.buffer));
}
function codecFingerprint(doc) {
  const attribute = a => ({ count: a.getCount(), component: a.getComponentType(), type: a.getType(), normalized: a.getNormalized(), hash: hash(new Uint8Array(a.getArray().buffer, a.getArray().byteOffset, a.getArray().byteLength)) });
  return {
    nodes: doc.getRoot().listNodes().filter(n => n.getMesh()).map(n => ({ id: n.getExtras().cyrus.entityId.split(':').at(-1), matrix: n.getWorldMatrix(), primitives: n.getMesh().listPrimitives().map(p => ({ mode: p.getMode(), material: p.getMaterial()?.getName(), indices: p.getIndices() ? orientedIndexHash(p.getIndices()) : null, attributes: Object.fromEntries(p.listSemantics().sort().map(s => [s, attribute(p.getAttribute(s))])) })) })).sort((a, b) => a.id.localeCompare(b.id)),
    materials: doc.getRoot().listMaterials().map(m => ({ name: m.getName(), base: m.getBaseColorFactor(), roughness: m.getRoughnessFactor(), metalness: m.getMetallicFactor(), alpha: m.getAlphaMode(), cutoff: m.getAlphaCutoff(), doubleSided: m.getDoubleSided(), emissive: m.getEmissiveFactor(), textures: ['BaseColor', 'MetallicRoughness', 'Normal', 'Occlusion', 'Emissive'].map(slot => { const t = m[`get${slot}Texture`](); return t ? { mime: t.getMimeType(), hash: hash(t.getImage()) } : null; }) })).sort((a, b) => a.name.localeCompare(b.name)),
  };
}


const folder='exports/building-20261016';await MeshoptDecoder.ready;
const loader=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder});
const paths=['building-meshopt-trial-v2.glb','reproduction-v4/delivery/optimized.glb'];
const docs=await Promise.all(paths.map(async p=>loader.readBinary(new Uint8Array(await readFile(`${folder}/${p}`)))));
const [a,b]=docs.map(codecFingerprint);let maximumMatrixEntryError=0;const materialDifferences=[],materialMapping=new Map();
assert.equal(a.nodes.length,b.nodes.length);
for(const n of a.nodes){const next=b.nodes.find(v=>v.id===n.id);assert.ok(next,n.id);assert.equal(n.primitives.length,next.primitives.length);for(let i=0;i<n.primitives.length;i++){const {material:oldName,...oldGeometry}=n.primitives[i],{material:newName,...newGeometry}=next.primitives[i];assert.deepEqual(oldGeometry,newGeometry,`geometry ${n.id}`);if(materialMapping.has(oldName))assert.equal(materialMapping.get(oldName),newName);else materialMapping.set(oldName,newName);}n.matrix.forEach((v,i)=>maximumMatrixEntryError=Math.max(maximumMatrixEntryError,Math.abs(v-next.matrix[i])));}
let maximumWorldPositionBoundMetres=0;
for(const n of docs[0].getRoot().listNodes().filter(n=>n.getMesh())){
 const handle=n.getExtras().cyrus.entityId.split(':').at(-1),next=docs[1].getRoot().listNodes().find(v=>v.getMesh()&&v.getExtras().cyrus.entityId.split(':').at(-1)===handle),a=n.getWorldMatrix(),b=next.getWorldMatrix();
 for(const p of n.getMesh().listPrimitives()){
  const pos=p.getAttribute('POSITION'),min=pos.getMinNormalized([]),max=pos.getMaxNormalized([]),bounds=min.map((v,i)=>Math.max(Math.abs(v),Math.abs(max[i]))),error=[];
  for(let axis=0;axis<3;axis++)error.push(Math.abs(a[12+axis]-b[12+axis])+bounds.reduce((sum,v,k)=>sum+v*Math.abs(a[k*4+axis]-b[k*4+axis]),0));
  maximumWorldPositionBoundMetres=Math.max(maximumWorldPositionBoundMetres,Math.hypot(...error));
 }
}
assert.ok(maximumWorldPositionBoundMetres<=.0001,'Investigate world position differences above 0.1 mm');
for(const m of a.materials){const next=b.materials.find(v=>v.name===materialMapping.get(m.name));assert.ok(next,m.name);if(JSON.stringify({...m,name:null})!==JSON.stringify({...next,name:null}))materialDifferences.push({before:m,after:next});}
assert.equal(a.materials.length,b.materials.length);
const report={old:paths[0],current:paths[1],renderedPlacements:b.nodes.length,exactAttributesAndOrientedTriangles:true,maximumMatrixEntryError,maximumWorldPositionBoundMetres,materialDifferences,notes:['Source handles match across the old and namespaced IDs. Empty native transform wrappers are omitted in the new export.','Ordinary serialization rounds one near-unit matrix entry; this is distinct from exact Meshopt codec identity.','Identical attributes and oriented triangles are qualified with a conservative world displacement bound. A fresh five-view silhouette comparison against original baseline masks provides current silhouette acceptance.']};
await writeFile(`${folder}/final-presentation-v1/geometry-material-successor.json`,JSON.stringify(report,null,2));console.log(JSON.stringify({placements:b.nodes.length,maximumMatrixEntryError,maximumWorldPositionBoundMetres,materialChanges:materialDifferences.length,changes:materialDifferences.map(m=>({name:m.before.name,roughness:[m.before.roughness,m.after.roughness]}))},null,2));
