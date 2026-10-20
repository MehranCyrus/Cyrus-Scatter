import {readFile,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {deepStrictEqual} from 'node:assert';
import {projectFiles,packSync,readProjectArchive} from '../../../src/storage/archive';
import {validateProject} from '../../../src/core/model';
const folder='exports/building-20261016';
const state=JSON.parse(await readFile(`${folder}/authoring-state-v1.json`,'utf8')),project=validateProject(state.project),blobs=new Map();
for(const file of ['building-support-creases-e0003-context-v5.glb','building-hero.camera.json']) {
    const bytes=new Uint8Array(await readFile(`${folder}/${file}`)),hash=createHash('sha256').update(bytes).digest('hex');blobs.set(hash,bytes);
}
const bytes=packSync(await projectFiles(project,blobs));
const opened=await readProjectArchive(bytes);
deepStrictEqual(opened.project,project);
await writeFile(`${folder}/fixture-input.cyrus-presentation.zip`,bytes);
console.log(JSON.stringify({fixtureInput:true,bytes:bytes.length,assetTriangles:project.assets[0].triangles,cameraSamples:project.segments[0].cameraClip?.sampleCount,projectId:project.id}));
