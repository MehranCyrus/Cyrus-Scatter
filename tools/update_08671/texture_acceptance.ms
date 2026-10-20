(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned viewport host required"
 global TRoot,TLayer,TSource,TNode,TMaterials
 local output=createFile (MCPFixtureDir+"texture-acceptance.txt")
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 fn draw=(CyrusPointSuspended=false;redrawViews();completeRedraw())
 fn capture label=(local image=gw.getViewportDib();image.filename=MCPFixtureDir+label+".png";save image;close image)
 try(
  resetMaxFile #noPrompt;CyrusPerfHeadless=false;CyrusPointSuspended=true
  units.SystemType=#centimeters;units.SystemScale=1.
  viewport.setLayout #layout_1;viewport.setType #view_top;viewport.SetRenderLevel #smoothhighlights
  local receiver=plane name:"Texture test receiver" width:260 length:260 widthsegs:1 lengthsegs:1
  TSource=plane name:"Texture test source" width:80 length:80 widthsegs:1 lengthsegs:1 pos:[700,0,0]
  convertToMesh TSource
  meshop.setNumMaps TSource 3 keep:true
  meshop.setMapSupport TSource 2 true
  meshop.setNumMapVerts TSource 2 (meshop.getNumMapVerts TSource 1)
  meshop.setNumMapFaces TSource 2 TSource.numfaces
  for i=1 to meshop.getNumMapVerts TSource 1 do (local p=meshop.getMapVert TSource 1 i;meshop.setMapVert TSource 2 i (p+[0.25,0.125,0]))
  for i=1 to TSource.numfaces do meshop.setMapFace TSource 2 i (meshop.getMapFace TSource 1 i)
  TMaterials=multimaterial numsubs:2
  TMaterials.materialIDList=#(3,8)
  TMaterials.materialList[1]=standardMaterial diffuse:red
  TMaterials.materialList[2]=standardMaterial diffuse:blue
  TSource.material=TMaterials
  setFaceMatID TSource 1 3;setFaceMatID TSource 2 8;update TSource
  TNode=AminScatterObject name:"Material acceptance";TRoot=TNode.baseObject;TRoot.updateMode=1;TRoot.autoRender=false
  TRoot.newLayer();TLayer=TRoot.selectedLayer();TLayer.addModelSource TSource
  TLayer.amount=4;TLayer.procSelfOverride=true;TLayer.procSelfEnabled=false;TLayer.procLayerSelfEnabled=false
  TRoot.setLayerSurfaces TLayer #(receiver);TRoot.identificationMode=4;TRoot.setGroupDisplay 3;hide TSource
  TRoot.refreshAll();TRoot.evaluateProcedural()
  select receiver;max zoomext sel all;select TNode;max modify mode;draw()
  check (TLayer.previewError=="" and TRoot.groupSnapshotRows[1].count==4 and CyrusPointLastError=="") "Multi/Sub IDs 3 and 8 publish" output
  capture "material-ids"
  local epoch=TRoot.procEpoch,builds=TRoot.groupBuilds,geometry=(cyrusRetainedStreamStats())[2]
  for material in TMaterials.materialList do (
   material.diffuseMap=checker color1:yellow color2:(color 40 100 180)
   material.opacityMap=checker color1:white color2:black
   material.opacityMap.coords.mapChannel=2
  )
  TRoot.refreshDisplay();draw()
  check (TLayer.previewError=="" and CyrusPointLastError=="") "Color channel 1 and separate opacity channel 2 publish" output
  check (TRoot.procEpoch==epoch and TRoot.groupBuilds==builds and (cyrusRetainedStreamStats())[2]==geometry) "Material edits reuse placements and geometry uploads" output
  capture "textured-cutouts"
  local stats=cyrusRetainedStats (CyrusPointOwner TNode),uploads=stats[6],bytes=stats[7]
  for i=1 to 10 do (local tm=viewport.getTM();tm.row4.x+=1;viewport.setTM tm;draw())
  stats=cyrusRetainedStats (CyrusPointOwner TNode)
  check (stats[6]==uploads and stats[7]==bytes and TRoot.procEpoch==epoch) "Warm viewport movement uploads no unchanged buffers" output
  TLayer.amount=19
  TMaterials.materialList[1].diffuseMap.color1=green;TRoot.refreshDisplay();draw()
  check (TRoot.groupSnapshotRows[1].count==4 and TLayer.amount==19 and TRoot.procEpoch==epoch) "Material edit preserves pending Manual amount" output
  TMaterials.materialList[1].opacityMap.coords.mapChannel=99
  TRoot.refreshDisplay();draw()
  check (TLayer.previewError!="" and TRoot.groupSnapshotRows[1].count==4) "Missing UV successor fails with prior placements retained" output
  capture "retained-after-missing-uv"
  TMaterials.materialList[1].opacityMap.coords.mapChannel=2
  TRoot.refreshDisplay();draw()
  check (TLayer.previewError=="" and TRoot.procEpoch==epoch) "Repairing UV selection recovers without applying pending amount" output
  local uv=meshop.getMapVert TSource 2 1
  meshop.setMapVert TSource 2 1 (uv+[0.3,0,0]);update TSource
  TRoot.refreshDisplay();draw()
  check (TLayer.previewError=="" and TRoot.procEpoch==epoch and (cyrusRetainedStreamStats())[2]==geometry) "Source UV edits update appearance independently" output
  for mode in #(1,2,3) do (TRoot.setGroupDisplay mode;draw();check (TRoot.procEpoch==epoch and TLayer.previewError=="") ("Representation switch "+(mode as string)) output)
  TRoot.identificationMode=1;TRoot.refreshDisplay();draw()
  TRoot.identificationMode=4;TRoot.refreshDisplay();draw()
  check (TRoot.procEpoch==epoch and TLayer.previewError=="") "Identification and textured appearance switches preserve placements" output
  capture "texture-final"
  local scene=MCPFixtureDir+"texture-persistence.max"
  saveMaxFile scene quiet:true
  resetMaxFile #noPrompt;loadMaxFile scene quiet:true
  local restored=(getNodeByName "Material acceptance").baseObject
  check (restored.identificationMode==4 and restored.viewportMode==3) "Materials / Textures persists through scene reopen" output
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
