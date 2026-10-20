-- A reused hole must append in the palette without moving physical source IDs.
cplResetScene()
global CPLOChecks=0,CPLUILab
fn oNeed value message=(CPLOChecks+=1;if not value do throw message)
fn oPump ms=(local until=timeStamp()+ms;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
fn oFreeze lab=(cplPause lab.physicsDocument;cplFreeze lab.physicsDocument;local until=timeStamp()+10000;while (cplUIState lab.physicsDocument)[2] and timeStamp()<until do (cplTick lab.physicsDocument 1;oPump 10);oNeed (not (cplUIState lab.physicsDocument)[2]) "Order-case Freeze failed")
(
 units.SystemType=#centimeters;units.SystemScale=1
 local ground=plane name:"Order_Ground" length:2000 width:2000
 local a=box name:"Order_A_Box" length:10 width:12 height:15 pos:[3000,0,0]
 local b=sphere name:"Order_B_Sphere" radius:5 segments:32 pos:[3100,0,0]
 local c=teapot name:"Order_C_Teapot" radius:8 segments:8 pos:[3200,0,0]
 a.material=standardMaterial diffuse:(color 220 50 40);b.material=standardMaterial diffuse:(color 50 100 220);c.material=standardMaterial diffuse:(color 60 190 90)
 local lab=CyrusPhysicsLab name:"Order_Lab_019"
 lab.setReceiver ground;lab.addSource a;lab.addSource b;cplSetSourceOptions lab.physicsDocument 2 1 8 1
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject;oPump 30;lab.refreshBindings()
 lab.objectsUI.sourceList.SelectedIndex=0;lab.objectsUI.removeSourceButton.pressed()
 lab.objectsUI.sourcePick.picked c
 oNeed (lab.sourceNodes.count==2 and lab.sourceNodes[1]==b and lab.sourceNodes[2]==c) "Add did not append in visible order"
 oNeed (cplSourceIndex lab.physicsDocument 1==2 and cplSourceIndex lab.physicsDocument 2==1) "Visible/native order diverged when reusing a hole"
 oNeed ((cplSourceOptions lab.physicsDocument 1)[2]==1 and (cplSourceOptions lab.physicsDocument 2)[2]==0) "Quality options follow the wrong model"
 cplSetSourceOptions lab.physicsDocument 2 2 16 1;lab.refreshBindings()
 lab.objectsUI.sourceList.SetItemChecked 1 false
 oNeed ((cplSourceOptions lab.physicsDocument 1)[1] and not (cplSourceOptions lab.physicsDocument 2)[1]) "Enablement follows the wrong reused slot"
 oNeed (lab.material.materialList[1]==c.material and lab.material.materialList[2]==b.material) "Material slots follow visible rather than physical order"
 viewport.setLayout #layout_1;viewport.setType #view_top;select ground;max zoomext sel all
 select lab;modPanel.setCurrentObject lab.baseObject;oPump 30
 lab.brushRadius=.02;lab.birthSpacing=.2;lab.emissionHeight=.2;lab.startBrush()
 oNeed (cplPrivatePaintPath lab.physicsDocument #([-200,0,0],[200,0,0]) false==2) "Reused-slot palette stroke failed"
 cplSynchronize lab.physicsDocument;oNeed ((cplUIState lab.physicsDocument)[6]>1) "Reused-slot brush stalled"
 oFreeze lab
 cplExportFile lab.physicsDocument (CPLTestDir+"order-sphere-result.json")
 local before=cplRows lab.physicsDocument
 lab.objectsUI.sourceList.SelectedIndex=1;lab.objectsUI.removeSourceButton.pressed();lab.objectsUI.sourcePick.picked a
 oNeed (lab.sourceNodes[1]==b and lab.sourceNodes[2]==a and cplSourceIndex lab.physicsDocument 2==1) "Second hole reuse changed palette order"
 oNeed (cplRows lab.physicsDocument==before) "Unused-slot reuse changed saved bodies"
 max undo;max undo
 oNeed (lab.sourceNodes[1]==b and lab.sourceNodes[2]==c and (cplSourceOptions lab.physicsDocument 2)[2]==2) "Hole reuse Undo lost order or quality"
 max redo;max redo
 oNeed (lab.sourceNodes[1]==b and lab.sourceNodes[2]==a) "Hole reuse Redo lost order"
 local duplicate=copy lab
 oNeed (duplicate.sourceNodes[1]==b and cplSourceIndex duplicate.physicsDocument 1==2 and cplSourceIndex duplicate.physicsDocument 2==1) "Clone lost explicit palette ordering"
 delete duplicate
 oNeed (saveMaxFile (CPLTestDir+"order-persist.max") quiet:true) "Ordered palette scene save failed"
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"order-assertions.txt") ("PASS "+(CPLOChecks as string)+" reused-hole/order/enablement/material/Undo/clone checks")
)
