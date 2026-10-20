import {readFile,writeFile} from 'node:fs/promises';
import {Matrix4,Vector3,Quaternion} from 'three';
const folder='exports/building-20261016';
const j=JSON.parse(await readFile(`${folder}/baseline-glb-json.json`,'utf8'));
const metadata=JSON.parse(await readFile(`${folder}/export-node-map-v2.json`,'utf8'));
const world=new Map(),parents=new Map();j.nodes.forEach((n,i)=>(n.children??[]).forEach(c=>parents.set(c,i)));
function matrix(i) {if(world.has(i))return world.get(i);const n=j.nodes[i],local=n.matrix?new Matrix4().fromArray(n.matrix):new Matrix4().compose(new Vector3().fromArray(n.translation??[0,0,0]),new Quaternion().fromArray(n.rotation??[0,0,0,1]),new Vector3().fromArray(n.scale??[1,1,1]));const result=parents.has(i)?matrix(parents.get(i)).clone().multiply(local):local;world.set(i,result);return result;}
const used=new Set(),result={};
for(let i=0;i<j.nodes.length;i++) {
    const node=j.nodes[i];if(node.mesh===undefined)continue;
    const prototype=metadata.find(n=>n.name===node.name);
    if(!prototype)throw new Error(`No baseline prototype: ${node.name}`);
    const actual=matrix(i).elements,candidates=metadata.filter(n=>n.instanceOwner===prototype.instanceOwner && !used.has(n.handle) && n.objectMatrix.every((v,k)=>Math.abs(v-actual[k])<(k>=12&&k<15?.001:.00001)));
    if(candidates.length!==1)throw new Error(`Ambiguous baseline instance: ${node.name}, ${candidates.map(n=>n.handle)}`);
    used.add(candidates[0].handle);result[i]={handle:candidates[0].handle,layer:candidates[0].layer,name:candidates[0].name};
}
await writeFile(`${folder}/baseline-node-identities.json`,JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify({boundRenderableNodes:used.size,source:'baseline-native.glb',method:'original prototype plus canonical world object transform',unique:true}));
