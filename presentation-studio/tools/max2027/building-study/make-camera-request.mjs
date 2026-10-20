// Deterministic creative camera recipe. Max authors/evaluates the resulting keys.
import {CatmullRomCurve3,Vector3} from 'three';
import {readFile,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
const session=JSON.parse(await readFile('../build/building-active-session.json','utf8'));
const requestName=process.argv[2]??'building-camera-02.ms';
if(!/^building-camera-\d+\.ms$/.test(requestName))throw Error('Use a fresh owned camera request basename.');
const folder=resolve('exports/building-20261016'),duration=36,fps=30,last=duration*fps;
const positions=[[-105,64,135],[-92,38,112],[-60,11,63],[-87,23,32],[-70,37,-82],[75,44,-95],[95,32,80],[-90,45,132]];
const targets=[[0,14,0],[-8,16,0],[-13,12,17],[-14,18,-3],[-5,20,-4],[0,17,0],[2,15,2],[-3,16,0]];
const lenses=[44,40,32,38,42,40,40,42];
const path=new CatmullRomCurve3(positions.map(p=>new Vector3(...p)),false,'centripetal');
const look=new CatmullRomCurve3(targets.map(p=>new Vector3(...p)),false,'centripetal');
const maxPoint=p=>`[${[p.x*100,-p.z*100,p.y*100].map(v=>v.toFixed(6)).join(',')}]`;
const rows=[];
for(let frame=0;frame<=last;frame++) {
    const t=frame/last,u=t*t*(3-2*t),index=Math.min(lenses.length-2,Math.floor(u*(lenses.length-1))),v=u*(lenses.length-1)-index,s=v*v*(3-2*v);
    const vfov=lenses[index]+(lenses[index+1]-lenses[index])*s,roll=.6*Math.sin(2*Math.PI*t)*Math.sin(Math.PI*t);
    rows.push(`#(${frame},${maxPoint(path.getPoint(u))},${maxPoint(look.getPoint(u))},${vfov.toFixed(8)},${roll.toFixed(8)})`);
}
const quote=p=>'@"'+p.replaceAll('\\','/')+'"';
const script=`(
 global CyrusExportCameraAnimation,CyrusCameraExporterNoUI,CyrusCameraExporterDialog
 CyrusCameraExporterNoUI=true
 if MCPFixtureDir==undefined do throw "Owned prepared host required."
 if not doesFileExist (MCPFixtureDir+"material-conversion-v3-complete.txt") do throw "Current prepared materials required."
 local oldCamera=getNodeByName "Cyrus Building Hero"
 if oldCamera!=undefined do (if getUserProp oldCamera "CyrusBuildingOwned"!="cyrus-building-20261016" do throw "Camera name belongs to another owner.";local oldTarget=oldCamera.target;delete oldCamera;if isValidNode oldTarget do delete oldTarget)
 frameRate=${fps};renderWidth=1920;renderHeight=1080;renderPixelAspect=1;animationRange=interval 0 ${last}
 local camera=TargetCamera name:"Cyrus Building Hero",target=TargetObject name:"Cyrus Building Look"
 setUserProp camera "CyrusBuildingOwned" "cyrus-building-20261016";setUserProp target "CyrusBuildingOwned" "cyrus-building-20261016"
 camera.target=target;camera.position.controller=Linear_Position();target.position.controller=Linear_Position();camera.fov.controller=Linear_Float();camera.transform.controller.Roll_Angle.controller=Linear_Float()
 local samples=#(\n${rows.join(',\n')}\n)
 animate on for row in samples do at time row[1] (
  camera.position=row[2];target.position=row[3];camera.fov=2*atan(tan(row[4]/2)*(16.0/9.0));camera.transform.controller.Roll_Angle=row[5]
 )
 fileIn ${quote(resolve('tools/max2027/CyrusCameraExporter.ms'))}
 try(destroyDialog CyrusCameraExporterDialog)catch()
 local beforeTime=currentTime,beforeSelection=selection as array,keys=numKeys camera.position.controller
 local receipt=CyrusExportCameraAnimation camera ${quote(folder+'/building-hero.camera.json')} 0 ${last} samplesPerFrame:4
 if currentTime!=beforeTime or selection.count!=beforeSelection.count or numKeys camera.position.controller!=keys do throw "Camera export changed authored state."
 local reference=createFile ${quote(folder+'/building-camera-native-reference-v2.json')} encoding:#utf8 writeBOM:false
 format "{\\"fps\\":${fps},\\"aspect\\":1.7777777777777777,\\"duration\\":${duration},\\"samples\\":[" to:reference
 for i=0 to ${last*8} do at time (i/8.0) (
  local tm=camera.transform
  if i>0 do format "," to:reference
  format "{\\"time\\":%,\\"positionMax\\":%,\\"rightMax\\":%,\\"upMax\\":%,\\"backMax\\":%,\\"horizontalFov\\":%}" (CyrusBuildingJsonNumber (i/(${fps}*8.0 as double))) (CyrusBuildingJsonVector tm.row4) (CyrusBuildingJsonVector tm.row1) (CyrusBuildingJsonVector tm.row2) (CyrusBuildingJsonVector tm.row3) (CyrusBuildingJsonNumber camera.fov) to:reference
 )
 format "]}" to:reference;close reference
 for n in objects where findItem #("light","camera","helper") (toLower ((superClassOf n) as string))>0 do hide n
 for n in geometry where classOf n==CProxy do hide n
 viewport.setCamera camera
 for frame in #(0,300,540,810,1080) do (
  sliderTime=frame;redrawViews();local bitmap=gw.getViewportDib();bitmap.filename=${quote(folder+'/max-camera-')}+(frame as string)+".png";save bitmap;close bitmap
 )
 sliderTime=0;clearSelection()
 if not saveMaxFile ${quote(folder+'/Big-building-presentation-v1.max')} quiet:true do throw "Presentation Max save failed."
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"building-camera-v1-complete.txt") ("PASS "+(receipt as string))
)
`;
await writeFile(`${session.run}/${requestName}`,'\ufeff'+script,{encoding:'utf8',flag:'wx'});
await writeFile(`${folder}/camera-recipe-v1.json`,JSON.stringify({duration,fps,frames:[0,last],samplesPerFrame:4,positionControlsCanonicalMetres:positions,targetControlsCanonicalMetres:targets,verticalFovControls:lenses,path:'centripetal Catmull-Rom sampled to per-frame native linear position keys; smoothstep global authored progression',roll:'subtle native animated roll; maximum amplitude ≤0.6 degrees',coordinateSpace:'prepared Max centimetres; canonical Y-up origin after [40,19,-17] m translation; no player transform',openingOffset:'pending presentation authoring'},null,2)+'\n');
console.log('Prepared owned Max request: '+session.run+'/'+requestName);
