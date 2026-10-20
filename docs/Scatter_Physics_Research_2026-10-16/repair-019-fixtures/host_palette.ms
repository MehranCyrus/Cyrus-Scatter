-- Runs after host_matrix.ms. Direct rollout handlers / SDK Painter callbacks only.
(
 local lab=CPLUILab,node=refs.dependentNodes CPLUILab firstOnly:true
 qShow node
 local rows=cplRows lab.physicsDocument,tea=getNodeByName "Q019_Teapot",ground=lab.receiverNode
 local materials=node.material
 qNeed (lab.sourceNodes.count==3) "Expected three bound models"
 lab.objectsUI.sourceList.SelectedIndex=0
 lab.objectsUI.removeSourceButton.pressed()
 qNeed (lab.sourceNodes.count==2 and lab.objectsUI.sourceList.Items.Count==2) "Remove did not update list"
 qNeed (cplSourceIndex lab.physicsDocument 1==2) "Remove changed stable source identity"
 qNeed (cplRows lab.physicsDocument==rows) "Remove deleted or moved saved bodies"
 qNeed (node.material==materials) "Remove changed published material slots"
 qNeed (isValidNode (getNodeByName "Pyramid001")) "Remove deleted the scene model"
 max undo;qNeed (lab.sourceNodes.count==3 and cplSourceIndex lab.physicsDocument 1==1) "Remove Undo lost binding"
 max redo;qNeed (lab.sourceNodes.count==2 and cplSourceIndex lab.physicsDocument 1==2) "Remove Redo lost identity"
 qNeed (cplRows lab.physicsDocument==rows) "Binding Undo/Redo modified output"
 lab.brushHeader.startButton.pressed()
 qNeed ((cplUIState lab.physicsDocument)[1]) ("Cannot brush after removal: "+lab.uiError)
 local denied=false
 try(lab.removeSource 1)catch(denied=true)
 qNeed (denied and lab.sourceNodes.count==2) "Pending removal was admitted"
 qPath node ground -5000 6000;qPath node ground -1500 6000
 qNeed ((cplUIState lab.physicsDocument)[6]>1) "Continuous removed-palette stroke failed"
 lab.brushHeader.stopButton.pressed();qFreeze node
 qWrite "removed-palette-result.json" (cplExport lab.physicsDocument)
 rows=cplRows lab.physicsDocument
 -- Removing the final bindings keeps existing output and disables Start.
 lab.objectsUI.sourceList.SelectedIndex=0;lab.objectsUI.removeSourceButton.pressed()
 lab.objectsUI.sourceList.SelectedIndex=0;lab.objectsUI.removeSourceButton.pressed()
 qNeed (lab.sourceNodes.count==0 and not lab.brushHeader.startButton.enabled) "Empty palette did not disable Start"
 qNeed (cplRows lab.physicsDocument==rows) "Remove all changed output"
 lab.addSource tea;lab.refreshBindings()
 qNeed (lab.sourceNodes.count==1 and cplSourceIndex lab.physicsDocument 1==4) "Re-add overwrote a used retired source"
 qNeed (node.material.numsubs>=4) "Re-add lost historical material slots"
 max undo;qNeed (lab.sourceNodes.count==0) "Add Undo failed"
 max redo;qNeed (lab.sourceNodes.count==1 and cplSourceIndex lab.physicsDocument 1==4) "Add Redo failed"
 lab.objectsUI.sourceList.SelectedIndex=0;lab.objectsUI.removeSourceButton.pressed()
 local ball=getNodeByName "Q019_Sphere32"
 lab.addSource ball;lab.refreshBindings()
 qNeed (cplSourceIndex lab.physicsDocument 1==4) "Unused removed slot was not reused"
 local current=lab.sourceNodes[1]
 lab.replaceSource 1 tea;lab.refreshBindings()
 qNeed (lab.sourceNodes[1]==tea) "Replace failed"
 max undo;qNeed (lab.sourceNodes[1]==current) "Replace Undo failed"
 max redo;qNeed (lab.sourceNodes[1]==tea) "Replace Redo failed"
 cplSetSourceOptions lab.physicsDocument 1 2 16 1
 lab.refreshBindings()
 lab.brushHeader.startButton.pressed();qNeed ((cplUIState lab.physicsDocument)[1]) ("Single re-added teapot failed: "+lab.uiError)
 qPath node ground 2000 6000;lab.brushHeader.stopButton.pressed();qFreeze node
 qWrite "readded-teapot-result.json" (cplExport lab.physicsDocument)
 local kept=cplRows lab.physicsDocument
 local originalType=units.SystemType,originalScale=units.SystemScale
 for kind in #(#millimeters,#centimeters,#meters) do
 (
  units.SystemType=kind;units.SystemScale=1
  local icon=CyrusPhysicsLab name:"Owned_Icon_Size_Test",perMetre=units.decodeValue "1m"
  qNeed (abs (icon.viewportIconSize*perMetre-10)<.0001) "New icon is not 10 scene units"
  qNeed (abs (icon.creationRadius [0,0,0] [3,4,0]*perMetre-5)<.0001) "Drag icon sizing lost scene units"
  qNeed ((icon.creationRadius [0,0,0] [0,0,0])<=icon.viewportIconSize) "First-click marker exceeds default"
  delete icon
 )
 units.SystemType=originalType;units.SystemScale=originalScale
 qNeed (cplRows lab.physicsDocument==kept) "Icon sizing changed output"
 qShow node
 qWrite "palette-final-result.json" (cplExport lab.physicsDocument)
 qNeed (saveMaxFile (CPLTestDir+"palette-retired.max") quiet:true) "Palette persistence save failed"
 local reclaimed=copy node
 cplClear reclaimed.physicsDocument;reclaimed.removeSource 1;reclaimed.addSource ball
 qNeed (cplSourceIndex reclaimed.physicsDocument 1==1) "Clear did not free historical slots for reuse"
 qShow reclaimed;reclaimed.startBrush();qPath reclaimed ground -5000 7000;cplPause reclaimed.physicsDocument;qFreeze reclaimed
 cplExportFile reclaimed.physicsDocument (CPLTestDir+"reclaimed-result.json")
 qNeed (cplRows lab.physicsDocument==kept) "Clearing a clone changed original output"
 delete reclaimed
 -- Independent empty setup for artist brushing, using the actual mountain.
 local ready=CyrusPhysicsLab name:"PhysicsLab_Brush_Ready_019"
 ready.pos=[0,0,1400]*CPLQUnits;ready.viewportIconSize=2;ready.setReceiver ground
 for model in #((getNodeByName "Pyramid001"),ball,tea) do ready.addSource model
 for i=1 to 3 do cplSetSourceOptions ready.physicsDocument i 2 16 1
 ready.brushRadius=.08;ready.birthSpacing=1.5;ready.emissionHeight=.6;ready.showCollisionShapes=true
 hide node;qShow ready
 global CPLUILab=ready.baseObject
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/repair-019-fixtures/popup_layout.py"
 qNeed (saveMaxFile (CPLTestDir+"PhysicsLab-0.1.9-Mountain-Test.max") quiet:true) "Ready scene save failed"
 qWrite "assertions.txt" ("PASS "+(CPLQChecks as string)+" mountain/quality/palette/remove/history/icon checks")
)
