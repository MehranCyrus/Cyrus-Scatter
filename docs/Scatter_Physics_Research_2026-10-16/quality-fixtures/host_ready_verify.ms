-- Installed exact-pair startup plus the actual clean artist scene.
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/host_continuous.ms"
cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global CPLReadyChecks=0
fn readyNeed b message=(CPLReadyChecks+=1;if not b do throw message)
fn readyPump ms=(local until=timeStamp()+ms;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
readyNeed (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-quality-018-reopen-02/PhysicsLab-0.1.8-Mountain-Test.max" quiet:true) "Artist ready scene failed to open"
(
 local lab=getNodeByName "PhysicsLab_Brush_Ready",ground=getNodeByName "Plane001"
 readyNeed (isValidNode lab and lab.sourceNodes.count==3) "Ready Lab/model list missing"
 readyNeed ((cplUIState lab.physicsDocument)[5]==0 and not (cplUIState lab.physicsDocument)[2]) "Clean scene contains pending or saved bodies"
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 lab.objectsUI.open=true;lab.collisionUI.open=true;readyPump 100;lab.refreshBindings()
 readyNeed (lab.objectsUI.sourceList.Items.Count==3) "Managed model list lost rows"
 for i=1 to 3 do (readyNeed ((cplSourceOptions lab.physicsDocument i)[1]) "Ready source disabled";readyNeed ((cplSourceOptions lab.physicsDocument i)[2]==2) "Ready source quality lost")
 readyNeed (lab.collisionUI.qualityList.items[1]=="Fast" and lab.collisionUI.qualityList.items[2]=="Balanced" and lab.collisionUI.qualityList.items[3]=="Detailed") ("Current short quality labels missing: "+(lab.collisionUI.qualityList.items as string))
 lab.objectsUI.sourceList.SelectedIndex=2
 for quality=1 to 3 do (lab.collisionUI.selectQuality quality;readyNeed ((cplSourceOptions lab.physicsDocument 3)[2]==quality-1) "Current quality handler/native options mismatch")
 lab.objectsUI.sourceList.SelectedIndex=1;lab.objectsUI.soloButton.pressed()
 readyNeed ((cplSourceOptions lab.physicsDocument 2)[1] and not (cplSourceOptions lab.physicsDocument 1)[1] and not (cplSourceOptions lab.physicsDocument 3)[1]) "Installed Solo handler failed"
 lab.brushHeader.startButton.pressed();readyNeed ((cplUIState lab.physicsDocument)[1]) ("Installed scene brush failed: "+lab.uiError+" "+cplStats lab.physicsDocument)
 local a=intersectRay ground (ray [-4000,2000,100000] [0,0,-1]),b=intersectRay ground (ray [-3500,2000,100000] [0,0,-1])
 readyNeed (cplPrivatePaintPath lab.physicsDocument #(a.pos,b.pos) false==2) "Installed scene brush missed actual terrain"
 cplSynchronize lab.physicsDocument;readyPump 250
 readyNeed ((cplUIState lab.physicsDocument)[6]>1) "Installed scene brush stalled"
 lab.brushHeader.stopButton.pressed();lab.brushHeader.keepButton.pressed()
 local until=timeStamp()+8000
 while (cplUIState lab.physicsDocument)[2] and timeStamp()<until do (cplTick lab.physicsDocument 8;readyPump 10)
 readyNeed (not (cplUIState lab.physicsDocument)[2] and (cplUIState lab.physicsDocument)[5]>1) "Installed scene failed to publish"
 cplExportFile lab.physicsDocument (CPLTestDir+"ready-scene-stroke.json")
 global CPLUILab=lab.baseObject
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/quality-fixtures/list_layout.py"
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/ui_layout.py"
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"ready-assertions.txt") ("PASS "+(CPLReadyChecks as string)+" installed/clean-scene/short-labels/palette/brush checks")
)
