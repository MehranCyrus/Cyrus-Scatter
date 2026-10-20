import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS} from '@gltf-transform/extensions';
import {createHash} from 'node:crypto';
import {writeFile} from 'node:fs/promises';
const folder='exports/building-20261016',stem='building-support-creases-e0003-context';
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS);
// Read sequentially to bound peak parsing memory for the actual assets.
const source=await io.read(`${folder}/${stem}-v4.glb`),target=await io.read(`${folder}/${stem}-v5.glb`);
const digest=a=>createHash('sha256').update(new Uint8Array(a.buffer,a.byteOffset,a.byteLength)).digest('hex');
const accessor=a=>({count:a.getCount(),type:a.getType(),normalized:a.getNormalized(),componentType:a.getComponentType(),sha256:digest(a.getArray())});
const geometry=n=>n.getMesh().listPrimitives().map(p=>({mode:p.getMode(),indices:p.getIndices()?accessor(p.getIndices()):null,attributes:Object.fromEntries(p.listSemantics().sort().map(s=>[s,accessor(p.getAttribute(s))]))}));
const index=doc=>new Map(doc.getRoot().listNodes().filter(n=>n.getMesh()).map(n=>[n.getExtras().cyrus?.entityId,n]));
const a=index(source),b=index(target),rows=[];
if(a.size!==295||a.size!==b.size||a.has(undefined)||b.has(undefined))throw Error('Original placement identity set changed.');
for(const [id,node] of a) {
    const next=b.get(id);if(!next)throw Error('Missing placement: '+id);
    const maxMatrixDifference=Math.max(...node.getWorldMatrix().map((v,i)=>Math.abs(v-next.getWorldMatrix()[i])));
    if(maxMatrixDifference>1e-9||JSON.stringify(geometry(node))!==JSON.stringify(geometry(next)))throw Error('Geometry differs: '+id);
    rows.push({id,maxMatrixDifference});
}
const report={passed:true,source:`${stem}-v4.glb`,target:`${stem}-v5.glb`,placements:a.size,method:'Every rendered placement: identical index and all attribute bytes/types/counts, canonical world matrices ≤1e-9; material-only successor',rows};
await writeFile(`${folder}/material-successor-geometry-identity.json`,JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({...report,rows:undefined}));
