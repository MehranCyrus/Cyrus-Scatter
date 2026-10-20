import {readFile,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {Quaternion,Vector3} from 'three';
import {parseCameraClip,cameraAt,cameraReference,loadCameraClips} from '../../../src/presentation/camera-clip';
import {emptyProject,reconnect} from '../../../src/core/model';
import {Evaluator} from '../../../src/presentation/evaluate';

const folder=process.argv[2]??'exports/building-20261016',referenceName=process.argv[3]??'building-camera-native-reference-v2.json';
const bytes=new Uint8Array(await readFile(`${folder}/building-hero.camera.json`));
const clip=parseCameraClip(bytes),reference=JSON.parse(await readFile(`${folder}/${referenceName}`,'utf8'));
const canonical=(v:number[])=>[v[0]/100,v[2]/100,-v[1]/100];
const hash=createHash('sha256').update(bytes).digest('hex');
const project=emptyProject();project.schemaVersion=2;project.opening=0;project.revealDuration=2;
project.stops=[clip.samples[0],clip.samples.at(-1)!].map((s,i)=>({...s,id:`hero-${i}`,name:i?'The final composition':'Architecture in motion',hold:0,aspect:clip.aspect}));reconnect(project);
Object.assign(project.segments[0],{duration:36,ease:0,cameraClip:cameraReference(hash,clip)});
const evaluator=new Evaluator(project,await loadCameraClips(project,new Map([[hash,bytes]])));
let maxPosition=0,maxPositionAtExportSamples=0,maxPositionBetweenExportSamples=0,maxBasis=0,maxFov=0,maxEvaluatorPosition=0,maxEvaluatorBasis=0;
for(let index=0;index<reference.samples.length;index++) {
    const r=reference.samples[index];
    const s=cameraAt(clip,r.time),q=new Quaternion().fromArray(s.quaternion);
    const positionError=new Vector3().fromArray(s.position).distanceTo(new Vector3().fromArray(canonical(r.positionMax)));
    maxPosition=Math.max(maxPosition,positionError);
    if(index%2===0)maxPositionAtExportSamples=Math.max(maxPositionAtExportSamples,positionError);else maxPositionBetweenExportSamples=Math.max(maxPositionBetweenExportSamples,positionError);
    for(const [axis,key] of [[new Vector3(1,0,0),'rightMax'],[new Vector3(0,1,0),'upMax'],[new Vector3(0,0,1),'backMax']] as const)maxBasis=Math.max(maxBasis,axis.applyQuaternion(q).distanceTo(new Vector3().fromArray(canonical(r[key])).normalize()));
    maxFov=Math.max(maxFov,Math.abs(s.fov-2*Math.atan(Math.tan(r.horizontalFov*Math.PI/360)/clip.aspect)*180/Math.PI));
}
const indices=[0,8640,4320,1,8639,2400,7200,1200,8000,5000,600,8400];
let random=0x12345678;for(let i=0;i<1000;i++){random=(Math.imul(random,1664525)+1013904223)>>>0;indices.push(random%reference.samples.length);}
for(const i of indices) {
    const r=reference.samples[i],s=cameraAt(clip,r.time),actual=evaluator.evaluate(2+r.time);
    maxEvaluatorPosition=Math.max(maxEvaluatorPosition,new Vector3().fromArray(actual.position).distanceTo(new Vector3().fromArray(s.position)));
    maxEvaluatorBasis=Math.max(maxEvaluatorBasis,1-Math.abs(new Quaternion().fromArray(actual.quaternion).dot(new Quaternion().fromArray(s.quaternion))));
    if(Math.abs(actual.fov-s.fov)>1e-10||actual.aspect!==clip.aspect)throw Error('Evaluator lens/framing differs.');
}
const maxTime=Math.max(...clip.samples.map((s,i)=>Math.abs(s.time-reference.samples[2*i].time)));
const report={passed:maxPositionAtExportSamples<.00002&&maxPositionBetweenExportSamples<.00002&&maxTime<1e-12&&maxBasis<.00002&&maxFov<.00002&&maxEvaluatorPosition<1e-10&&maxEvaluatorBasis<1e-10,
    exporterVersion:clip.source.exporterVersion,cameraType:clip.source.cameraType,cameraSha256:hash,samples:clip.samples.length,duration:clip.samples.at(-1)!.time,
    independentNativeSamples:reference.samples.length,sourceFrames:[0,1080],fps:clip.fps,aspect:clip.aspect,presentationOffsetSeconds:2,
    maxPositionMetres:maxPosition,maxPositionAtExportSamples,maxPositionBetweenExportSamples,positionBudgetsMetres:{atExportSamples:.00002,betweenSamples:.00002},maxTimeSeconds:maxTime,maxBasisVectorError:maxBasis,maxVerticalFovDegrees:maxFov,maxEvaluatorPositionMetres:maxEvaluatorPosition,maxEvaluatorQuaternionDotError:maxEvaluatorBasis,reverseAndRandomSeeks:indices.length,
    limits:['Native pose parity does not prove the creative camera route avoids every occluder or has polished composition; inspect actual playback.','Basis-vector comparisons include the authored roll.','Reference v2 emits timestamps in Double precision; the rejected v1 reference rounded time to Float32 and produced misleading ~50 micrometre position errors. Native world transforms remain Float32.']};
await writeFile(`${folder}/building-camera-parity.json`,JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));if(!report.passed)throw Error('Native camera parity failed.');
