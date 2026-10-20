// Recreate the qualified camera recipe in the reproducible prepared scene.
import { CatmullRomCurve3, Vector3 } from 'three';
import { readFile, writeFile, mkdir, access, copyFile } from 'node:fs/promises';
import { resolve } from 'node:path';
const session = JSON.parse(await readFile('../build/building-active-session.json', 'utf8'));
const base = resolve('exports/building-20261016'), input = `${base}/reproduction-v4/delivery/prepared.max`, output = `${base}/final-presentation-v1`;
await access(input); await mkdir(output); await mkdir(`${output}/textures`);
const delivery = `${base}/reproduction-v4/delivery`, manifest = JSON.parse(await readFile(`${delivery}/report.json`, 'utf8')), textureMappings = [], copied = new Set();
for (const [name, identity] of Object.entries(manifest.files).filter(([name]) => name.startsWith('textures/'))) {
  const suffix = name.slice(name.lastIndexOf('.')), target = `${output}/textures/${identity.sha256.slice(0, 20)}${suffix}`;
  if (!copied.has(target)) { await copyFile(`${delivery}/${name}`, target); copied.add(target); }
  textureMappings.push([`${delivery}/${name}`, target]);
}
const recipe = JSON.parse(await readFile(`${base}/camera-recipe-v1.json`, 'utf8')), duration = recipe.duration, fps = recipe.fps, last = duration * fps;
const path = new CatmullRomCurve3(recipe.positionControlsCanonicalMetres.map(p => new Vector3(...p)), false, 'centripetal');
const look = new CatmullRomCurve3(recipe.targetControlsCanonicalMetres.map(p => new Vector3(...p)), false, 'centripetal'), lenses = recipe.verticalFovControls;
const point = p => `[${[p.x * 100, -p.z * 100, p.y * 100].map(v => v.toFixed(6)).join(',')}]`, quoted = p => '@"' + p.replaceAll('\\', '/') + '"', rows = [];
for (let frame = 0; frame <= last; frame++) {
  const t = frame / last, u = t * t * (3 - 2 * t), index = Math.min(lenses.length - 2, Math.floor(u * (lenses.length - 1))), v = u * (lenses.length - 1) - index, blend = v * v * (3 - 2 * v);
  rows.push(`#(${frame},${point(path.getPoint(u))},${point(look.getPoint(u))},${(lenses[index] + (lenses[index + 1] - lenses[index]) * blend).toFixed(8)},${(.6 * Math.sin(2 * Math.PI * t) * Math.sin(Math.PI * t)).toFixed(8)})`);
}
const script = `global CyrusExportCameraAnimation,CyrusCameraExporterNoUI,CyrusCameraExporterDialog,CyrusFinalNumber,CyrusFinalVector
fn CyrusFinalNumber value = ((dotNetObject "System.Double" value).ToString "R" (dotNetClass "System.Globalization.CultureInfo").InvariantCulture)
fn CyrusFinalVector value = "["+(CyrusFinalNumber value.x)+","+(CyrusFinalNumber value.y)+","+(CyrusFinalNumber value.z)+"]"
(
 if MCPFixtureDir==undefined do throw "Owned host required."
 if not loadMaxFile ${quoted(input)} useFileUnits:true quiet:true allowPrompts:false missingDLLsAction:#logmsg missingExtFilesAction:#logmsg do throw "Reproduced scene did not load."
 if abs((units.decodeValue "1m")-100)>0.00001 do throw "The creative recipe expects prepared centimetres."
 if getNodeByName "Cyrus Building Hero"!=undefined do throw "Preserve an existing camera; expected the fresh tool derivative."
 frameRate=${fps};renderWidth=1920;renderHeight=1080;renderPixelAspect=1;animationRange=interval 0 ${last}
 local camera=TargetCamera name:"Cyrus Building Hero",target=TargetObject name:"Cyrus Building Look"
 setUserProp camera "CyrusBuildingOwned" "cyrus-building-20261016";setUserProp target "CyrusBuildingOwned" "cyrus-building-20261016"
 camera.target=target;camera.position.controller=Linear_Position();target.position.controller=Linear_Position();camera.fov.controller=Linear_Float();camera.transform.controller.Roll_Angle.controller=Linear_Float()
 local samples=#(\n${rows.join(',\n')}\n)
 animate on for row in samples do at time row[1] (
  camera.position=row[2];target.position=row[3];camera.fov=2*atan(tan(row[4]/2)*(16.0/9.0));camera.transform.controller.Roll_Angle=row[5]
 )
 CyrusCameraExporterNoUI=true
 fileIn ${quoted(resolve('tools/max2027/CyrusCameraExporter.ms'))}
 try(destroyDialog CyrusCameraExporterDialog)catch()
 local oldTime=currentTime,beforeKeys=numKeys camera.position.controller
 CyrusExportCameraAnimation camera ${quoted(output + '/building-hero.camera.json')} 0 ${last} samplesPerFrame:4
 if currentTime!=oldTime or numKeys camera.position.controller!=beforeKeys do throw "Export changed camera authoring state."
 local reference=createFile ${quoted(output + '/building-camera-native-reference.json')} encoding:#utf8 writeBOM:false
 format "{\\"fps\\":${fps},\\"aspect\\":1.7777777777777777,\\"duration\\":${duration},\\"samples\\":[" to:reference
 for i=0 to ${last * 8} do at time (i/8.0) (
  local tm=camera.transform
  if i>0 do format "," to:reference
  format "{\\"time\\":%,\\"positionMax\\":%,\\"rightMax\\":%,\\"upMax\\":%,\\"backMax\\":%,\\"horizontalFov\\":%}" (CyrusFinalNumber (i/(${fps}*8.0 as double))) (CyrusFinalVector tm.row4) (CyrusFinalVector tm.row1) (CyrusFinalVector tm.row2) (CyrusFinalVector tm.row3) (CyrusFinalNumber camera.fov) to:reference
 )
 format "]}" to:reference;close reference
 local materialStack=(for n in geometry where n.material!=undefined collect n.material),seenMaterials=#(),mapStack=#(),maps=#(),seenMaps=#()
 while materialStack.count>0 do (
  local m=materialStack[materialStack.count];deleteItem materialStack materialStack.count
  if findItem seenMaterials m==0 do (
   append seenMaterials m
   for i=1 to getNumSubMtls m where getSubMtl m i!=undefined do append materialStack (getSubMtl m i)
   for i=1 to getNumSubTexmaps m where getSubTexmap m i!=undefined do append mapStack (getSubTexmap m i)
  )
 )
 while mapStack.count>0 do (
  local m=mapStack[mapStack.count];deleteItem mapStack mapStack.count
  if findItem seenMaps m==0 do (
   append seenMaps m
   if classOf m==BitmapTexture do append maps m
   for i=1 to getNumSubTexmaps m where getSubTexmap m i!=undefined do append mapStack (getSubTexmap m i)
  )
 )
 local textureMappings=#(${textureMappings.map(pair => `#(${quoted(pair[0])},${quoted(pair[1])})`).join(',')})
 for i=1 to maps.count do (
  local source=maps[i].filename
  if source!="" do (
   if not doesFileExist source do throw "Prepared scene has an unavailable bitmap."
   local destination=undefined,key=toLower (substituteString source "\\\\" "/")
   for pair in textureMappings where toLower pair[1]==key do destination=pair[2]
   if destination==undefined do throw "Active prepared texture is absent from the tool manifest."
   maps[i].filename=destination
  )
 )
 -- Hide cameras/targets without hiding the origin parent of the building.
 for n in objects where (toLower ((superClassOf n) as string))=="camera" or classOf n==TargetObject do hide n
 viewport.setCamera camera
 for frame in #(0,300,540,810,1080) do (
  sliderTime=frame;redrawViews();local bitmap=gw.getViewportDib();bitmap.filename=${quoted(output + '/max-camera-')}+(frame as string)+".png";save bitmap;close bitmap
 )
 sliderTime=0;clearSelection()
 if not saveMaxFile ${quoted(output + '/BAILEY-prepared-with-camera.max')} quiet:true do throw "Final camera scene save failed."
 (dotNetClass "System.IO.File").WriteAllText ${quoted(output + '/native-complete.txt')} "PASS"
)
`;
const request = `${session.run}/building-final-camera-01.ms`; await writeFile(request, '\ufeff' + script, { encoding: 'utf8', flag: 'wx' });
await writeFile(`${output}/camera-recipe.json`, JSON.stringify({ ...recipe, openingOffset: 2, preparedScene: input }, null, 2), { flag: 'wx' });
console.log(JSON.stringify({ request, output }));
