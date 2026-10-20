-- Fresh-process artist scene roundtrip and changes, no physical input.
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/host_continuous.ms"
cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global CPLReopenChecks=0
fn rNeed b message=(CPLReopenChecks+=1;if not b do throw message)
fn rPump ms=(local until=timeStamp()+ms;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
fn rShow lab=(select lab;max modify mode;modPanel.setCurrentObject lab.baseObject;lab.objectsUI.open=true;lab.collisionUI.open=true;lab.resultUI.open=true;rPump 100;lab.refreshBindings())
fn rWaitFreeze lab=(lab.brushHeader.keepButton.pressed();local until=timeStamp()+8000;while (cplUIState lab.physicsDocument)[2] and timeStamp()<until do (cplTick lab.physicsDocument 8;rPump 10);rNeed (not (cplUIState lab.physicsDocument)[2]) "Freeze did not complete")
rNeed (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-quality-018-mountain-05/PhysicsLab-0.1.8-Mountain-Test.max" quiet:true) "Delivered artist test scene failed to load"
(
 local lab=getNodeByName "Q018_Mixed_Palette",ground=getNodeByName "Plane001"
 rNeed (isValidNode lab and isValidNode ground) "Scene setup missing"
 rNeed (lab.sourceNodes.count==3) "Scene lost model bindings"
 for i=1 to 3 do (rNeed (isValidNode lab.sourceNodes[i]) "Missing source";rNeed ((cplSourceOptions lab.physicsDocument i)[1]) "Saved enabled state missing";rNeed ((cplSourceOptions lab.physicsDocument i)[2]==2) "Saved quality missing")
 local baseRows=cplRows lab.physicsDocument,baseCount=(cplUIState lab.physicsDocument)[5]
 rNeed (baseCount>0 and not (cplUIState lab.physicsDocument)[2]) "Scene should contain a frozen result and no live world"
 rShow lab
 lab.objectsUI.sourceList.SetItemChecked 0 false;lab.objectsUI.sourceList.SetItemChecked 2 false
 lab.brushHeader.startButton.pressed()
 rNeed ((cplUIState lab.physicsDocument)[1]) ("Scene brush failed: "+lab.uiError+" "+cplStats lab.physicsDocument)
 local h1=intersectRay ground (ray [-2000,-8000,100000] [0,0,-1]),h2=intersectRay ground (ray [-1500,-8000,100000] [0,0,-1])
 rNeed (cplPrivatePaintPath lab.physicsDocument #(h1.pos,h2.pos) false==2) "Reopened brush hit failed"
 cplSynchronize lab.physicsDocument
 rNeed ((cplUIState lab.physicsDocument)[6]>1) "Reopened scene stalled at one body"
 local rejected=false
 try(lab.objectsUI.sourceList.SetItemChecked 0 true)catch(rejected=true)
 rNeed (not (cplSourceOptions lab.physicsDocument 1)[1]) "Pending checkbox changed active source mask"
 rNeed (not (lab.objectsUI.sourceList.GetItemChecked 0)) "Pending checkbox visual state did not roll back"
 lab.brushHeader.stopButton.pressed()
 local pendingCount=(cplUIState lab.physicsDocument)[6],pendingMesh=cplMesh lab.physicsDocument true,pendingVertices=for v=1 to pendingMesh.numverts collect (getVert pendingMesh v)
 rNeed (saveMaxFile (CPLTestDir+"quality-pending.max") quiet:true) "Pending quality scene save failed"
 cplResetScene();rNeed (loadMaxFile (CPLTestDir+"quality-pending.max") quiet:true) "Pending quality scene load failed"
 lab=getNodeByName "Q018_Mixed_Palette";rShow lab
 rNeed ((cplUIState lab.physicsDocument)[6]==pendingCount) "Pending cached count changed on reopen"
 local loadedMesh=cplMesh lab.physicsDocument true
 rNeed (loadedMesh.numverts==pendingVertices.count) "Pending cached geometry count changed"
 for v=1 to loadedMesh.numverts do rNeed ((distance (getVert loadedMesh v) pendingVertices[v])<.0001) "Pending cached geometry changed"
 rNeed (not (cplSourceOptions lab.physicsDocument 1)[1] and (cplSourceOptions lab.physicsDocument 2)[1] and not (cplSourceOptions lab.physicsDocument 3)[1]) "Checked palette did not persist"
 lab.brushHeader.startButton.pressed();rNeed ((cplUIState lab.physicsDocument)[1]) ("Detailed session failed to Resume: "+lab.uiError+" "+cplStats lab.physicsDocument)
 rPump 200;lab.brushHeader.stopButton.pressed();rWaitFreeze lab
 rNeed ((cplUIState lab.physicsDocument)[5]>baseCount) "Reopened scene lost new bodies"
 local after=cplRows lab.physicsDocument
 max undo;rNeed (cplRows lab.physicsDocument==baseRows) "Result Undo lost saved base"
 max redo;rNeed (cplRows lab.physicsDocument==after) "Result Redo changed transforms"
 -- Explicit Rebuild is required after quality edits; failed Start keeps old output.
 local test=copy lab
 rShow test
 cplSetSourceOptions test.physicsDocument 3 0 16 1
 local oldRows=cplRows test.physicsDocument,failed=false
 try(test.startBrush())catch(failed=true)
 rNeed failed "Changed shape extended old output without Rebuild"
 rNeed (cplRows test.physicsDocument==oldRows) "Rejected shape edit lost previous output"
 test.resultUI.rebuildButton.pressed()
 local until=timeStamp()+50000
 while (cplUIState test.physicsDocument)[2] and not (cplUIState test.physicsDocument)[4] and timeStamp()<until do (cplTick test.physicsDocument 16;rPump 10)
 if (cplUIState test.physicsDocument)[2] do (rNeed ((cplUIState test.physicsDocument)[4]) "Rebuild missed its finite bound";rWaitFreeze test)
 rNeed ((cplUIState test.physicsDocument)[5]>0) "Rebuild lost recipe"
 local published=cplRows test.physicsDocument
 local card=plane width:100 length:100 pos:[19000,0,0]
 cplReplaceSource test.physicsDocument 2 card;test.sourceNodes[2]=card
 failed=false;try(test.startBrush())catch(failed=true)
 rNeed failed "Detailed flat-card preparation was accepted"
 rNeed (cplRows test.physicsDocument==published) "Preparation failure changed published body state"
 delete test;delete card
 rShow lab
 global CPLUILab=lab.baseObject
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/quality-fixtures/list_layout.py"
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/ui_layout.py"
 lab.objectsUI.allButton.pressed()
 rNeed (saveMaxFile (CPLTestDir+"PhysicsLab-0.1.8-Mountain-Results.max") quiet:true) "Result comparison scene save failed"
 local ready=copy lab
 ready.name="PhysicsLab_Brush_Ready"
 cplClear ready.physicsDocument
 hide lab;unhide ready;rShow ready
 rNeed ((cplUIState ready.physicsDocument)[5]==0 and not (cplUIState ready.physicsDocument)[2]) "Artist scene is not clean and ready"
 for i=1 to 3 do rNeed ((cplSourceOptions ready.physicsDocument i)[1]) "Ready scene has a disabled model"
 rNeed (saveMaxFile (CPLTestDir+"PhysicsLab-0.1.8-Mountain-Test.max") quiet:true) "Ready artist scene save failed"
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"reopen-stats.json") (cplStats lab.physicsDocument)
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"reopen-assertions.txt") ("PASS "+(CPLReopenChecks as string)+" fresh-scene/palette/pending/rebuild/failure-retention checks")
)
