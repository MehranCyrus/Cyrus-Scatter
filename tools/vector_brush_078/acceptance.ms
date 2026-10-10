(
-- Vector 0.78 integration qualification, disposable host only.
global VChecks=#(),VAssert,VRoot,VLayer,VNode,VPlane,VSecond,VSource,VArea,VD
fn VAssert value message = (
 if not value do throw ("Vector 0.78: "+message)
 append VChecks message
 local f=createFile (MCPFixtureDir+"vector-checks.txt")
 for item in VChecks do format "%\n" item to:f
 close f;true
)
if findString (toLower MCPFixtureDir) "/build/vector-brush-078/"==undefined do throw "Owned host required"
CyrusStopBrush();resetMaxFile #noPrompt
viewport.setLayout #layout_1;viewport.setType #view_top
VPlane=plane name:"V_Plane" width:200 length:200 widthsegs:4 lengthsegs:4
VSecond=plane name:"V_Second" width:200 length:200 widthsegs:4 lengthsegs:4 pos:[300,0,0]
VSource=box name:"V_Model" width:1 length:1 height:4 pos:[1000,0,0];hide VSource
VNode=AminScatterObject name:"V_Controller";VRoot=VNode.baseObject
VRoot.setLayerTransfer true;VRoot.updateMode=1;VRoot.autoRender=false;VRoot.newLayer()
VLayer=VRoot.selectedLayer();VLayer.sources=#(VSource);VLayer.sourceWeights=#(1.0);VLayer.amount=5000
VRoot.setLayerTransfer false;VRoot.setLayerSurfaces VLayer #(VPlane,VSecond);VRoot.refreshAll()
VAssert (VRoot.uiVersion()=="0.78.2") "Current UI version 0.78.2"
VAssert (VRoot.groupSnapshotRows[1].count==5000) "Two receivers generate without paint"
VArea=VRoot.addPaintArea VLayer target:VPlane;VD=VArea.paintDocument
cyrusBrushSettings VD 35 false
VAssert (cyrusBrushDab VD [0,0,200] [0,0,-1] true) "Vector paint accepted"
VRoot.refreshAll()
local initial=VRoot.groupSnapshotRows[1],finger=cyrusEditFingerprint initial "vector",initialCount=initial.count
VAssert (initialCount>0 and initialCount<2500 and VLayer.previewError=="") "Vector filters layer candidates"
VAssert ((for row in initial where row[1].row4.x>150 collect row).count==0) "Receiver ownership prevents bleed"
cyrusBrushDab VD [0,0,200] [0,0,-1] true;VRoot.refreshAll()
VAssert ((cyrusEditFingerprint VRoot.groupSnapshotRows[1] "vector")==finger) "Repeated paint is idempotent"
local duplicate=VRoot.addPaintArea VLayer target:VPlane
cyrusBrushSettings duplicate.paintDocument 35 false;cyrusBrushDab duplicate.paintDocument [0,0,200] [0,0,-1] true
VRoot.refreshAll();VAssert ((cyrusEditFingerprint VRoot.groupSnapshotRows[1] "vector")==finger) "Overlapping areas union once"
VRoot.removePaintArea VLayer duplicate
local other=VRoot.addPaintArea VLayer target:VSecond
cyrusBrushSettings other.paintDocument 35 false;cyrusBrushDab other.paintDocument [0,0,200] [0,0,-1] true
VRoot.refreshAll()
VAssert ((for row in VRoot.groupSnapshotRows[1] where row[1].row4.x>150 collect row).count>0) "Second area paints second receiver"
VRoot.setLayerSurfaces VLayer #(VPlane);VRoot.refreshAll()
VAssert ((cyrusBrushStats other.paintDocument)[2]>0) "Removing receiver preserves inactive vector area"
VRoot.setLayerSurfaces VLayer #(VPlane,VSecond);VRoot.refreshAll()
VAssert ((for row in VRoot.groupSnapshotRows[1] where row[1].row4.x>150 collect row).count>0) "Restoring receiver restores its area"
other.paintSetEnabled=false;VRoot.refreshAll()
local original=cyrusEditFingerprint VRoot.groupSnapshotRows[1] "vector"
cyrusBrushSettings VD 1000 true;cyrusBrushDab VD [0,0,200] [0,0,-1] true
VAssert ((cyrusEditFingerprint VRoot.groupSnapshotRows[1] "vector")==original) "Manual preserves last publication during erase"
VRoot.refreshAll();VAssert (VRoot.groupSnapshotRows[1].count==0) "Explicit update applies erase"
max undo;VRoot.refreshAll();VAssert ((cyrusEditFingerprint VRoot.groupSnapshotRows[1] "vector")==original) "Undo restores canonical region and exact plants"
max redo;VRoot.refreshAll();VAssert (VRoot.groupSnapshotRows[1].count==0) "Redo restores erase"
max undo;VRoot.refreshAll()
cyrusBrushSettings VD 1000 true;cyrusBrushDab VD [0,0,200] [0,0,-1] false;cyrusBrushCancel VD;VRoot.refreshAll()
VAssert ((cyrusEditFingerprint VRoot.groupSnapshotRows[1] "vector")==original) "Cancel restores committed vector area"
local cfg=cyrusBrushFalloff VD
cfg[1]=0;cfg[2]=20;cfg[3]=true;cfg[4]=false;cyrusBrushSetFalloff VD cfg;VRoot.refreshAll()
local outside=VRoot.groupSnapshotRows[1]
VAssert (outside.count>initialCount) "Outside fade admits additional candidates"
local positions=dotNetObject "System.Collections.Hashtable"
for i=1 to initial.count do positions.Add (initial[i][3] as string) i
for row in outside where positions.ContainsKey (row[3] as string) do VAssert (row[1].row4==initial[positions.Item[row[3] as string]][1].row4) "Outside fade preserves surviving positions"
cfg[3]=false;cfg[4]=true;cfg[5]=0.25;cfg[6]=1;cyrusBrushSetFalloff VD cfg;VRoot.refreshAll()
VAssert ((for row in VRoot.groupSnapshotRows[1] where length row[1].row1<0.99 collect row).count>0) "Independent scale fade reaches instance transforms"
VAssert (VLayer.previewError=="") "Falloff builds without layer error"
cfg[1]=0;cfg[2]=0;cfg[4]=false;cyrusBrushSetFalloff VD cfg;VRoot.refreshAll()
VAssert ((cyrusEditFingerprint VRoot.groupSnapshotRows[1] "vector")==original) "Turning feather off restores exact transforms"
-- Density curve changes leave base receiver caches intact.
local builds=VLayer.receiverCacheStats()
cfg[1]=15;cfg[7]=#(0,0.2,1);cyrusBrushSetFalloff VD cfg;VRoot.refreshAll()
VAssert ((VLayer.receiverCacheStats())[1]==builds[1]) "Curve change reuses base candidate caches"
-- Full refill and arbitrary erase leave unrelated regions intact.
cyrusBrushFill VD 1;VRoot.refreshAll();VAssert (VRoot.groupSnapshotRows[1].count>1000) "Fill receiver vector domain"
cyrusBrushFill VD 0;VRoot.refreshAll();VAssert (VRoot.groupSnapshotRows[1].count==0) "Clear vector contours"
cfg[1]=0;cfg[2]=0;cyrusBrushSetFalloff VD cfg
cyrusBrushSettings VD 12 false
local watch=dotNetObject "System.Diagnostics.Stopwatch",timings=#()
cyrusBrushBegin VD
for i=1 to 400 do (
 watch.Restart()
 local x=60*sin(i*5),y=60*cos(i*4)
 cyrusBrushDab VD [x,y,200] [0,0,-1] true
 cyrusBrushRefreshMask VD;watch.Stop()
 append timings watch.Elapsed.TotalMilliseconds
)
local stats=cyrusBrushStats VD
VAssert (stats[2]<400 and stats[3]>0 and stats[19]>0 and stats[18]==0) "400 gestures merge to complete cached borders"
local fields=stats[9],queries=stats[10]
for i=1 to 8 do (cyrusBrushRefreshMask VD;redrawViews())
stats=cyrusBrushStats VD
VAssert (stats[9]==fields and stats[10]==queries) "Idle border refresh does no field evaluation"
VRoot.refreshAll();local before=cyrusEditFingerprint VRoot.groupSnapshotRows[1] "save"
cyrusBrushStop()
local out=createFile (MCPFixtureDir+"vector-timings.csv");format "gesture,edit_and_border_ms\n" to:out
for i=1 to timings.count do format "%,%\n" i timings[i] to:out
close out
-- An unsupported target fails before it can replace the existing area.
local sphereTarget=sphere radius:20 pos:[600,0,0],rejected=false
try(cyrusBrushCreate sphereTarget)catch(rejected=true)
VAssert rejected "Closed sphere receiver explicitly rejected"
VAssert ((cyrusEditFingerprint VRoot.groupSnapshotRows[1] "save")==before) "Unsupported target leaves completed layer untouched"
select VNode;max modify mode;modPanel.setCurrentObject VRoot
if not VRoot.mainUI.controlsReady do VRoot.mainUI.mountTimer.tick()
VLayer.uiAreaID=VArea.layerID;VRoot.bindNativeUI()
VRoot.coverageUI.open=true;VRoot.mainUI.bindSection VRoot.coverageUI
VAssert (isProperty VRoot.coverageUI #brushUI_insideSpin and isProperty VRoot.coverageUI #brushUI_densityCurve) "Generated main UI binds vector controls"
VAssert (not isProperty VRoot.coverageUI #brushUI_strengthSpin and not isProperty VRoot.coverageUI #setsUI_importButton) "Retired controls absent"
saveMaxFile (MCPFixtureDir+"vector078.max") quiet:true
loadMaxFile (MCPFixtureDir+"vector078.max") quiet:true
VRoot=(getNodeByName "V_Controller").baseObject;VLayer=VRoot.layerObjects[1];VArea=VLayer.paintAreas[1];VD=VArea.paintDocument
VRoot.refreshAll()
VAssert ((cyrusEditFingerprint VRoot.groupSnapshotRows[1] "save")==before) "Save/reopen restores vector regions and exact placements"
VAssert ((cyrusBrushStats VD)[3]>0) "Reopened vector contours persisted"
VRoot.updateMode=2
cyrusBrushFill VD 0;VArea.publishPaint();VLayer.refreshPreview()
VAssert (VRoot.groupSnapshotRows[1].count==0) "Live responds to committed vector edit"
VRoot.updateMode=1


)
