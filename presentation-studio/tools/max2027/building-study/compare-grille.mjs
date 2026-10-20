import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import { weld, simplify, prune, quantize, dedup } from '@gltf-transform/functions';
import { MeshoptSimplifier } from 'meshoptimizer';
import { readFile, writeFile } from 'node:fs/promises';
import sharp from 'sharp';
const folder = 'exports/building-20261016', source = await readFile(`${folder}/grille-original.glb`);
await MeshoptSimplifier.ready;
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS), results = [];
for (const error of [.00005, .0001, .0003]) {
  const doc = await io.readBinary(source), start = performance.now();
  await doc.transform(weld(), simplify({ simplifier: MeshoptSimplifier, ratio: .01, error, lockBorder: true }), dedup(), prune({ keepLeaves: true }), quantize({ quantizePosition: 16, quantizeNormal: 12 }));
  const data = await io.writeBinary(doc), triangles = doc.getRoot().listMeshes().reduce((n,m) => n + m.listPrimitives().reduce((s,p) => s+(p.getIndices()?.getCount() ?? 0)/3,0),0), name = `post-${String(error).replace('.', '_')}`;
  await writeFile(`${folder}/grille-${name}.glb`,data);results.push({name,error,ratio:.01,bytes:data.length,triangles,elapsedMs:performance.now()-start});
}
await writeFile(`${folder}/grille-post-results.json`,JSON.stringify(results,null,2));console.log(JSON.stringify(results,null,2));
// Image comparison is analysis of screenshots; it does not alter the rendered evidence.
const comparisons=[];
const mask=(raw,bg)=>{const a=new Uint8Array(raw.length/3);for(let i=0;i<a.length;i++)a[i]=+(Math.max(...[0,1,2].map(c=>Math.abs(raw[i*3+c]-bg[c])))>18);return a;};
const expanded=(input,w,h)=>{const out=new Uint8Array(input.length);for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(input[y*w+x])for(let yy=Math.max(0,y-1);yy<=Math.min(h-1,y+1);yy++)for(let xx=Math.max(0,x-1);xx<=Math.min(w-1,x+1);xx++)out[yy*w+xx]=1;return out;};
const iou=(a,b)=>{let intersection=0,union=0;for(let i=0;i<a.length;i++){intersection+=a[i]&b[i];union+=a[i]|b[i];}return intersection/Math.max(1,union);};
for(const view of ['front','oblique','detail']){
  const a=await sharp(`${folder}/grille-comparison/original-${view}.png`).removeAlpha().raw().toBuffer({resolveWithObject:true}),bg=[...a.data.subarray(0,3)],ma=mask(a.data,bg),ea=expanded(ma,a.info.width,a.info.height);
  for(const name of ['panel-10','panel-5','panel-2','panel-1']){const b=await sharp(`${folder}/grille-comparison/${name}-${view}.png`).removeAlpha().raw().toBuffer(),mb=mask(b,bg);let error=0;for(let i=0;i<b.length;i++)error+=Math.abs(a.data[i]-b[i]);comparisons.push({name,view,maskIoU:iou(ma,mb),onePixelExpandedIoU:iou(ea,expanded(mb,a.info.width,a.info.height)),meanRGBAbsoluteDifference:error/b.length});}
}
await writeFile(`${folder}/grille-comparison/image-metrics.json`,JSON.stringify(comparisons,null,2));console.log(JSON.stringify(comparisons,null,2));
