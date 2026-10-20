// Codec evaluation only. Current production admission has not enabled this extension.
import {NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS,EXTMeshoptCompression} from '@gltf-transform/extensions';
import {MeshoptEncoder} from 'meshoptimizer';
import {MeshoptDecoder} from 'three/addons/libs/meshopt_decoder.module.js';
import {readFile,writeFile,access} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const folder='exports/building-20261016',sourcePath=`${folder}/building-support-creases-e0003-context-v5.glb`,output=`${folder}/building-meshopt-trial-v2.glb`;
try{await access(output);throw Error('Preserve existing trial output.');}catch(e){if(e.code!=='ENOENT')throw e;}
await Promise.all([MeshoptEncoder.ready,MeshoptDecoder.ready]);
const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.encoder':MeshoptEncoder,'meshopt.decoder':MeshoptDecoder});
const hash=data=>createHash('sha256').update(data).digest('hex');
const typed=a=>({count:a.getCount(),type:a.getType(),component:a.getComponentType(),normalized:a.getNormalized(),hash:hash(new Uint8Array(a.getArray().buffer,a.getArray().byteOffset,a.getArray().byteLength))});
const orientedTriangles=a=>{
    const input=a.getArray(),out=new Uint32Array(input.length);
    for(let i=0;i<input.length;i+=3){let best=0;for(let r=1;r<3;r++)for(let k=0;k<3;k++){const x=input[i+(r+k)%3],y=input[i+(best+k)%3];if(x<y){best=r;break;}if(x>y)break;}for(let k=0;k<3;k++)out[i+k]=input[i+(best+k)%3];}
    return{count:a.getCount(),component:a.getComponentType(),orientedTriangleHash:hash(new Uint8Array(out.buffer))};
};
const fingerprint=doc=>JSON.stringify(doc.getRoot().listNodes().filter(n=>n.getMesh()).map(n=>({id:n.getExtras().cyrus.entityId,matrix:n.getWorldMatrix(),primitives:n.getMesh().listPrimitives().map(p=>({mode:p.getMode(),material:p.getMaterial()?.getName(),indices:orientedTriangles(p.getIndices()),attributes:Object.fromEntries(p.listSemantics().sort().map(s=>[s,typed(p.getAttribute(s))]))}))})).sort((a,b)=>a.id.localeCompare(b.id)));
const materialFingerprint=doc=>JSON.stringify(doc.getRoot().listMaterials().map(m=>({name:m.getName(),base:m.getBaseColorFactor(),roughness:m.getRoughnessFactor(),metalness:m.getMetallicFactor(),alphaMode:m.getAlphaMode(),alphaCutoff:m.getAlphaCutoff(),doubleSided:m.getDoubleSided(),emissive:m.getEmissiveFactor(),textures:['BaseColor','MetallicRoughness','Normal','Occlusion','Emissive'].map(slot=>{const t=m[`get${slot}Texture`]();return t?{mime:t.getMimeType(),hash:hash(t.getImage())}:null;})})).sort((a,b)=>a.name.localeCompare(b.name)));
const source=await readFile(sourcePath),doc=await io.readBinary(source),before=fingerprint(doc),materialsBefore=materialFingerprint(doc),started=performance.now();
doc.createExtension(EXTMeshoptCompression).setRequired(true).setEncoderOptions({method:EXTMeshoptCompression.EncoderMethod.QUANTIZE});
const bytes=await io.writeBinary(doc);await writeFile(output,bytes);const encodeMs=performance.now()-started;
const decodeStart=performance.now(),decoded=await io.readBinary(bytes),decodeMs=performance.now()-decodeStart;
const exactGeometry=before===fingerprint(decoded),exactMaterials=materialsBefore===materialFingerprint(decoded);
const report={source:sourcePath,output,sourceBytes:source.length,outputBytes:bytes.length,sourceSha256:hash(source),outputSha256:hash(bytes),encodeMs,decodeAndParseMs:decodeMs,exactGeometry,exactMaterials,renderedPlacements:decoded.getRoot().listNodes().filter(n=>n.getMesh()).length,encoder:'meshoptimizer 1.3.0',decoder:'Three.js 0.186.1 bundled meshoptimizer 1.1',method:'Existing quantized attribute bytes/types/counts and canonical matrices match exactly; triangle sequence and winding match allowing cyclic corner rotation within each triangle; PBR factors and embedded texture bytes match',productionCompatible:false,remaining:'Bounded admission/decode, public pruning, actual browser loading and full resource/performance qualification are required before selection.'};
await writeFile(`${folder}/meshopt-lossless-trial-v2.json`,JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));if(!exactGeometry||!exactMaterials)throw Error('Codec trial changes scene content.');
