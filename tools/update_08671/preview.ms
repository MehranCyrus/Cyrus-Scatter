(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned prototype host required"
 global VRoot,VLayer,VSource,VController
 local output=createFile (MCPFixtureDir+"preview.txt")
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 try(
  resetMaxFile #noPrompt;CyrusPerfHeadless=false;CyrusPointSuspended=true
  units.SystemType=#centimeters;units.SystemScale=1.
  viewport.setLayout #layout_1;viewport.setType #view_persp_user;viewport.SetRenderLevel #smoothhighlights
  VSource=box name:"UV material fixture" width:20 length:20 height:50 pos:[500,0,0]
  VSource.material=standardMaterial diffuse:(color 220 80 40)
  VController=AminScatterObject name:"Textured viewport fixture"
  VRoot=VController.baseObject;VRoot.updateMode=1;VRoot.autoRender=false;VRoot.newLayer();VLayer=VRoot.selectedLayer()
  VLayer.addModelSource VSource
  VLayer.amount=9;VLayer.viewportMode=3;VLayer.procSelfOverride=true;VLayer.procSelfEnabled=false;VLayer.procLayerSelfEnabled=false
  local receiver=plane width:300 length:300 widthsegs:2 lengthsegs:2
  VRoot.setLayerSurfaces VLayer #(receiver);hide VSource
  VRoot.identificationMode=4;VRoot.setGroupDisplay 3
  VRoot.refreshAll();VRoot.evaluateProcedural()
  check (VRoot.groupSnapshotRows[1].count==9 and VLayer.previewError=="") "Materials produce 9 placements" output
  select receiver;max zoomext sel all;select VController;max modify mode
  VRoot.bindNativeUI();CyrusPointSuspended=false;redrawViews();completeRedraw()
  local image=gw.getViewportDib();image.filename=MCPFixtureDir+"preview.png";save image;close image
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n" (getCurrentException()) to:output)
 close output
)
