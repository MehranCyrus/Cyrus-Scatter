fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/bake-020-fixtures/helpers.ms"
global C021Cases=0,C021Freezes=0
fn c021Finish lab requireSettled =
(
 lab.brushHeader.finishButton.pressed()
 local deadline=timeStamp()+40000
 while (cplUIState lab.physicsDocument)[2] and not (cplUIState lab.physicsDocument)[4] and timeStamp()<deadline do (cplTick lab.physicsDocument 4;bPump 10)
 if (cplUIState lab.physicsDocument)[2] do
 (
  bNeed (not requireSettled) ("Required Finish did not settle: "+lab.uiError+" "+cplStats lab.physicsDocument)
  C021Freezes+=1;lab.brushHeader.keepButton.pressed();bWait lab
 )
 bNeed (lab.uiError=="") ("Finish error: "+lab.uiError)
)
fn c021Case kind radius count =
(
 cplResetScene();units.SystemType=#millimeters;units.SystemScale=1
 local r=radius*1000,span=amax 200 (r*80)
 local ground=plane name:"Cook021_Ground" width:span length:span lengthsegs:4 widthsegs:4
 local source=case kind of
 (
  "teapot":teapot name:"Cook021_Teapot" radius:r segments:8 pos:[span,0,0]
  "sphere":sphere name:"Cook021_Sphere" radius:r segments:32 pos:[span,0,0]
  "pyramid":pyramid name:"Cook021_Pyramid" width:(r*2) depth:(r*2) height:(r*3) pos:[span,0,0]
 )
 source.wirecolor=color 80 180 230;hide source
 local lab=CyrusPhysicsLab name:("Cook021_"+kind)
 lab.pos=[-18.631124,-66.093643,0];lab.setReceiver ground;lab.addSource source
 lab.brushRadius=radius*.05;lab.birthSpacing=radius*10;lab.emissionHeight=amax .04 (radius*3);lab.scaleMinimum=.8;lab.scaleMaximum=1.2;lab.bodyLimit=100
 viewport.setLayout #layout_1;viewport.setType #view_top;select ground;max zoomext sel all;bShow lab
 lab.collisionUI.selectQuality 1
 cplStage ("Fast "+kind+" radius "+radius as string)
 lab.brushHeader.startButton.pressed();bNeed ((cplUIState lab.physicsDocument)[1]) ("Fast start failed "+lab.uiError)
 local spacing=amax 15 (r*6)
 for i=0 to count-1 do bPath lab #([(mod i 7-3)*spacing,((i/7 as integer)-1)*spacing,0])
 bNeed ((cplUIState lab.physicsDocument)[6]==count) "First batch body count mismatch"
 c021Finish lab true
 local batches=cplColliderNodes lab.physicsDocument
 bNeed (batches.count==1 and classOf batches[1].baseObject==Editable_Poly) "Fast Finish did not bake"
 local baked=batches[1],meshBefore=snapshotAsMesh baked,tmBefore=baked.transform,materialBefore=baked.material
 local beforeVertices=for i=1 to getNumVerts meshBefore collect getVert meshBefore i
 max undo;bNeed ((cplColliderNodes lab.physicsDocument).count==0) "Bake Undo left binding"
 max redo;baked=(cplColliderNodes lab.physicsDocument)[1]
 -- Start again with unchanged Fast too: quality is not the cause of this defect.
 lab.brushHeader.startButton.pressed();bNeed ((cplUIState lab.physicsDocument)[1]) ("Fast restart failed "+lab.uiError);lab.stopBrush()
 lab.collisionUI.selectQuality 3
 cplStage ("Detailed after Finish "+kind+" radius "+radius as string)
 lab.brushHeader.startButton.pressed();bNeed ((cplUIState lab.physicsDocument)[1]) ("Detailed restart failed "+lab.uiError)
 bPath lab #([-spacing,spacing*2,0]);local initial=(cplUIState lab.physicsDocument)[6]
 bPath lab #([spacing,spacing*2,0]);bNeed ((cplUIState lab.physicsDocument)[6]>initial) "Second continuous Detailed stroke missing"
 local current=(cplUIState lab.physicsDocument)[6]
 bNeed (cplPrivatePaintPath lab.physicsDocument #([span*2,span*2,0]) false==0) "Outside stroke hit"
 cplSynchronize lab.physicsDocument;bNeed ((cplUIState lab.physicsDocument)[6]==current) "Outside emitted"
 lab.brushHeader.stopButton.pressed();local poses=cplPendingRows lab.physicsDocument
 lab.brushHeader.undoButton.pressed();bNeed ((cplUIState lab.physicsDocument)[6]<current) "Detailed live Undo failed"
 lab.brushHeader.redoButton.pressed();bNeed (cplPendingRows lab.physicsDocument==poses) "Detailed live Redo changed poses"
 c021Finish lab false
 bNeed ((cplColliderNodes lab.physicsDocument).count==2) "Second bake missing"
 bNeed (baked.material==materialBefore and baked.transform==tmBefore) "Quality changed first batch bindings"
 local after=snapshotAsMesh baked
 bNeed (getNumVerts after==beforeVertices.count and getNumFaces after==getNumFaces meshBefore) "Quality changed topology"
 for i=1 to beforeVertices.count do if getVert after i!=beforeVertices[i] do throw "Quality changed baked vertices"
 local path=CPLTestDir+kind+"-"+(radius as string)+"-transition.max"
 bNeed (saveMaxFile path quiet:true) "Transition save failed"
 cplResetScene();bNeed (loadMaxFile path quiet:true useFileUnits:true) "Transition reopen failed"
 lab=getNodeByName ("Cook021_"+kind);bShow lab
 lab.brushHeader.startButton.pressed();bNeed ((cplUIState lab.physicsDocument)[1]) ("Cold restart failed "+lab.uiError)
 bPath lab #([0,-spacing*2,0]);lab.stopBrush()
 C021Cases+=1;bWrite "transition-summary.txt" ((C021Cases as string)+" cases; "+(BChecks as string)+" checks; "+(C021Freezes as string)+" optional second-Finish freezes")
)
for radius in #(.00334,.03,.3) do c021Case "teapot" radius (if radius==.00334 then 21 else 3)
for kind in #("sphere","pyramid") do for radius in #(.00334,.3) do c021Case kind radius 3
