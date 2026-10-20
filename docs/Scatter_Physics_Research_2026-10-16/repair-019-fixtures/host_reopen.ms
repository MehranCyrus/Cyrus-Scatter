-- Installed startup verifies ordinary continuous brushing first.
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/host_continuous.ms"
cplResetScene()
global CPLReopenChecks=0,CPLUILab
fn rNeed value message=(CPLReopenChecks+=1;if not value do throw message)
fn rPump ms=(local until=timeStamp()+ms;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
rNeed (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-repair-019-all-04/order-persist.max" quiet:true useFileUnits:true) "Ordered palette scene failed to load"
(
 local lab=getNodeByName "Order_Lab_019",ground=getNodeByName "Order_Ground"
 rNeed (lab.sourceNodes[1].name=="Order_B_Sphere" and lab.sourceNodes[2].name=="Order_A_Box") "Saved visible ordering changed"
 rNeed (cplSourceIndex lab.physicsDocument 1==2 and cplSourceIndex lab.physicsDocument 2==1) "Saved physical indices changed"
 rNeed ((cplSourceOptions lab.physicsDocument 1)[2]==1 and (cplSourceOptions lab.physicsDocument 2)[2]==0) "Saved per-model quality changed"
 local before=cplRows lab.physicsDocument
 cplExportFile lab.physicsDocument (CPLTestDir+"reopened-order.json")
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject;rPump 50;lab.refreshBindings()
 lab.startBrush();rNeed ((cplUIState lab.physicsDocument)[1]) "Reopened hole-order brush failed"
 rNeed (cplPrivatePaintPath lab.physicsDocument #([-200,100,0],[200,100,0]) false==2) "Reopened order stroke failed"
 cplSynchronize lab.physicsDocument;cplPause lab.physicsDocument;cplFreeze lab.physicsDocument
 local until=timeStamp()+10000
 while (cplUIState lab.physicsDocument)[2] and timeStamp()<until do (cplTick lab.physicsDocument 1;rPump 10)
 rNeed (not (cplUIState lab.physicsDocument)[2]) "Reopened order Freeze failed"
 cplExportFile lab.physicsDocument (CPLTestDir+"reopened-order-mixed.json")
 max undo;rNeed (cplRows lab.physicsDocument==before) "Ordered palette result Undo failed"
 max redo;rNeed (cplRows lab.physicsDocument!=before) "Ordered palette result Redo failed"
)
cplResetScene()
rNeed (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-repair-019-all-04/palette-retired.max" quiet:true useFileUnits:true) "Retired palette scene failed to load"
(
 local lab=getNodeByName "Q019_Mixed_Palette",ground=getNodeByName "Plane001"
 rNeed (isValidNode lab and lab.sourceNodes.count==1) "Saved visible palette membership lost"
 rNeed (cplSourceIndex lab.physicsDocument 1==4) "Saved stable source index lost"
 rNeed ((cplSourceOptions lab.physicsDocument 1)[2]==2) "Saved collision policy lost"
 local before=cplRows lab.physicsDocument
 cplExportFile lab.physicsDocument (CPLTestDir+"reopened-retired.json")
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject;rPump 50;lab.refreshBindings()
 rNeed (lab.objectsUI.sourceList.Items.Count==1) "Reopened checked list lost membership"
 lab.startBrush();rNeed ((cplUIState lab.physicsDocument)[1]) ("Retired palette resume failed "+lab.uiError)
 local factor=(units.decodeValue "1m")/100.0
 local a=intersectRay ground (ray ([-4000,4500,100000]*factor) [0,0,-1]),b=intersectRay ground (ray ([-3500,4500,100000]*factor) [0,0,-1])
 rNeed (cplPrivatePaintPath lab.physicsDocument #(a.pos,b.pos) false==2) "Reopened retired brush failed"
 cplSynchronize lab.physicsDocument;rNeed ((cplUIState lab.physicsDocument)[6]>1) "Reopened retired brush stalled"
 cplPause lab.physicsDocument;cplFreeze lab.physicsDocument
 local until=timeStamp()+10000
 while (cplUIState lab.physicsDocument)[2] and timeStamp()<until do (cplTick lab.physicsDocument 1;rPump 10)
 rNeed (not (cplUIState lab.physicsDocument)[2]) "Reopened Freeze failed"
 max undo;rNeed (cplRows lab.physicsDocument==before) "Reopened whole-result Undo failed"
 max redo;rNeed (cplRows lab.physicsDocument!=before) "Reopened whole-result Redo failed"
 local duplicate=copy lab
 rNeed (cplSourceIndex duplicate.physicsDocument 1==4 and duplicate.sourceNodes.count==1) "Clone lost retired membership"
 rNeed (cplRows duplicate.physicsDocument==cplRows lab.physicsDocument) "Clone lost output"
 delete duplicate
)
cplResetScene()
rNeed (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-repair-019-all-04/PhysicsLab-0.1.9-Mountain-Test.max" quiet:true useFileUnits:true) "Ready scene failed to open"
(
 local lab=getNodeByName "PhysicsLab_Brush_Ready_019",ground=getNodeByName "Plane001"
 rNeed (isValidNode lab and lab.sourceNodes.count==3) "Ready setup missing"
 rNeed ((cplUIState lab.physicsDocument)[5]==0) "Ready setup contains old bodies"
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject;rPump 50;lab.refreshBindings()
 for i=1 to 3 do rNeed ((cplSourceOptions lab.physicsDocument i)[2]==2) "Ready quality missing"
 lab.startBrush();rNeed ((cplUIState lab.physicsDocument)[1]) ("Ready brush failed "+lab.uiError)
 local factor=(units.decodeValue "1m")/100.0
 local a=intersectRay ground (ray ([-4000,2000,100000]*factor) [0,0,-1]),b=intersectRay ground (ray ([-3500,2000,100000]*factor) [0,0,-1])
 rNeed (cplPrivatePaintPath lab.physicsDocument #(a.pos,b.pos) false==2) "Ready scene SDK path failed"
 cplSynchronize lab.physicsDocument;rNeed ((cplUIState lab.physicsDocument)[6]>1) "Ready scene stalled"
 cplPause lab.physicsDocument;cplStop lab.physicsDocument
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"reopen-assertions.txt") ("PASS "+(CPLReopenChecks as string)+" retired/persistence/clone/installed-ready-scene checks")
)
