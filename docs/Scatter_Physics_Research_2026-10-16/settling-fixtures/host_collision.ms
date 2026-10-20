-- Actual rollout and Painter SDK callbacks in an owned Max 2027 profile.
-- No cursor/keyboard automation, screenshots, or artist-session changes.
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global CPLCollisionChecks=0
fn collisionRequire value message = (CPLCollisionChecks+=1;if not value do throw message)
fn collisionPump duration = (local until=timeStamp()+duration;while timeStamp()<until do (windows.processPostedMessages();sleep .01))
fn collisionFinish lab =
(
 lab.brushHeader.finishButton.pressed()
 local until=timeStamp()+30000
 while (cplUIState lab.physicsDocument)[2] and timeStamp()<until do (cplTick lab.physicsDocument 1;collisionPump 10)
 collisionRequire (not (cplUIState lab.physicsDocument)[2]) ("Finish failed: "+cplStats lab.physicsDocument)
 collisionRequire (findString (cplStats lab.physicsDocument) "\"settled\":true"!=undefined) "Result was frozen instead of settled"
)
fn collisionPanel lab =
(
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 lab.brushHeader.open=true;lab.objectsUI.open=true;lab.collisionUI.open=true
 collisionPump 150;lab.refreshBindings()
)
(
 cplResetScene();units.SystemType=#centimeters;units.SystemScale=1
 viewport.setLayout #layout_1;viewport.setType #view_top
 local ground=plane name:"Plane001" width:225.4415 length:142.2994 widthsegs:4 lengthsegs:4
 local source=sphere name:"Sphere001" radius:1.5983 segments:32 pos:[300,0,0]
 local small=sphere name:"Sphere_proxy" radius:1.5983 segments:8 pos:[300,0,0]
 local copied=copy ground;copied.name="Wrong_large_proxy"
 hide source;hide small;hide copied
 local lab=CyrusPhysicsLab name:"Collision_016"
 select ground;max zoomext sel all
 collisionPanel lab
 lab.objectsUI.receiverPick.picked ground;lab.objectsUI.sourcePick.picked source;lab.objectsUI.colliderPick.picked ground
 lab.brushRadius=.001;lab.emissionHeight=.4;lab.birthSpacing=.08
 collisionRequire (not cplCustomProxy lab.physicsDocument 1) "Detailed model defaulted to custom"
 lab.collisionUI.proxyPick.picked ground
 collisionRequire (findString lab.uiError "Receiver 'Plane001'"!=undefined) "Receiver/model proxy confusion was not explained"
 collisionRequire (not cplCustomProxy lab.physicsDocument 1) "Failed proxy assignment mutated binding"
 lab.collisionUI.proxyPick.picked copied
 collisionRequire (findString lab.uiError "much larger"!=undefined) "Another oversized plane proxy was accepted"
 collisionRequire (not cplCustomProxy lab.physicsDocument 1) "Oversized proxy replaced automatic shape"
 lab.collisionUI.proxyPick.picked small
 collisionRequire (cplProxyNode lab.physicsDocument 1==small) "Valid simplified custom proxy rejected"
 collisionRequire (findString lab.collisionUI.proxyLabel.tooltip "Sphere_proxy"!=undefined) "UI hides custom proxy identity"
 collisionRequire (findString lab.collisionUI.modelLabel.tooltip "Sphere001"!=undefined) "UI hides selected model identity"
 lab.objectsUI.receiverPick.picked small
 collisionRequire (findString lab.uiError "cannot be the collision proxy"!=undefined and lab.receiverNode==ground) "Reverse assignment changed receiver"
 lab.collisionUI.proxyPick.picked ground
 collisionRequire (cplProxyNode lab.physicsDocument 1==small) "Rejected pick destroyed the valid prior proxy"
 small.radius=60
 lab.brushHeader.startButton.pressed()
 collisionRequire (findString lab.uiError "much larger"!=undefined and not (cplUIState lab.physicsDocument)[1]) "Changed proxy geometry bypassed preparation validation"
 small.radius=1.5983
 lab.collisionUI.autoProxyButton.pressed()
 collisionRequire (not cplCustomProxy lab.physicsDocument 1 and cplProxyNode lab.physicsDocument 1==undefined) "Use auto did not clear the override"
 -- BindSource must apply the same checks as the pick button before adding a slot.
 local rejected=false
 try(lab.addSource small proxy:ground)catch(rejected=true)
 collisionRequire (rejected and lab.sourceNodes.count==1) "Direct source+proxy binding bypassed validation"
 cplStage "sphere continuous strokes"
 lab.brushHeader.startButton.pressed()
 collisionRequire ((cplUIState lab.physicsDocument)[1]) ("Start failed: "+lab.uiError)
 collisionRequire (not lab.collisionUI.proxyPick.enabled) "Proxy binding editable during live work"
 for y=0 to 7 do for x=0 to 7 do
 (
  collisionRequire (cplPrivatePaintPath lab.physicsDocument #([-28.+x*8,-28.+y*8,0]) false==1) "SDK sphere hit missed"
  cplSynchronize lab.physicsDocument
 )
 collisionRequire ((cplUIState lab.physicsDocument)[6]==64) "Continuous brush did not create 64 spheres"
 collisionRequire ((cplUIState lab.physicsDocument)[13]>0) "No moving bodies during continuous brushing test"
 collisionRequire (cplPrivatePaintPath lab.physicsDocument #([200,200,0],[300,300,0]) false==0) "Outside ray incorrectly hit receiver"
 cplSynchronize lab.physicsDocument
 collisionRequire ((cplUIState lab.physicsDocument)[6]==64) "Outside stroke emitted"
 lab.brushHeader.stopButton.pressed()
 local pending=cplPendingRows lab.physicsDocument
 lab.brushHeader.undoButton.pressed()
 collisionRequire ((cplUIState lab.physicsDocument)[6]==63) "Live Undo changed wrong stroke"
 lab.brushHeader.redoButton.pressed()
 collisionRequire (cplPendingRows lab.physicsDocument==pending) "Redo changed full poses"
 local previewMesh=snapshotAsMesh lab
 saveMaxFile (CPLTestDir+"sphere-pending.max") quiet:true
 collisionRequire (loadMaxFile (CPLTestDir+"sphere-pending.max") quiet:true) "Pending scene failed to reopen"
 lab=getNodeByName "Collision_016";collisionPanel lab
 local loadedPreview=snapshotAsMesh lab,maxDifference=0.
 collisionRequire ((cplUIState lab.physicsDocument)[6]==64 and loadedPreview.numverts==previewMesh.numverts) "Pending scene lost preview bodies"
 for i=1 to loadedPreview.numverts do maxDifference=amax maxDifference (distance (getVert loadedPreview i) (getVert previewMesh i))
 collisionRequire (maxDifference<.001) "Pending scene changed cached geometry by more than 0.01 mm"
 lab.brushHeader.startButton.pressed()
 collisionFinish lab
 collisionRequire ((cplUIState lab.physicsDocument)[5]==64) "Finish lost sphere bodies"
 local output=snapshotAsMesh lab,minimum=1e9
 for i=1 to output.numverts do minimum=amin minimum (getVert output i).z
 collisionRequire (minimum>-.1) "Finished sphere geometry penetrated floor by more than 1 mm"
 collisionRequire (output.numverts==64*482 and output.numfaces==64*960) "Automatic proxy changed render detail"
 local completed=cplRows lab.physicsDocument
 max undo;collisionRequire ((cplUIState lab.physicsDocument)[5]==0) "Result Undo failed"
 max redo;collisionRequire (cplRows lab.physicsDocument==completed) "Result Redo changed poses"
 cplExportFile lab.physicsDocument (CPLTestDir+"sphere-result.json")
 -- Names must follow the selected slot without changing the other model's proxy.
 source=getNodeByName "Sphere001";small=getNodeByName "Sphere_proxy"
 lab.addSource small
 lab.refreshBindings();lab.objectsUI.sourceList.selection=2;lab.refreshBindings()
 collisionRequire (findString lab.collisionUI.modelLabel.tooltip "Sphere_proxy"!=undefined) "Selected model identity did not follow the slot"
 lab.collisionUI.proxyPick.picked small
 collisionRequire (cplProxyNode lab.physicsDocument 2==small and cplProxyNode lab.physicsDocument 1==undefined) "Proxy mutated another source slot"
 lab.objectsUI.sourceList.selection=1;lab.refreshBindings()
 collisionRequire (findString (toLower lab.collisionUI.proxyLabel.text) "automatic"!=undefined) "Automatic first-slot label was stale"
 -- Inspect real control/font rectangles at the current scale, with long names.
 source.name="Sphere_with_a_long_source_name_for_layout"
 global CPLUILab=lab.baseObject
 python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusPhysicsLab/tests/ui_layout.py"
 cplStage "legacy wrong proxy scene"
 cplResetScene()
 units.SystemType=#centimeters;units.SystemScale=1
 collisionRequire (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-016-legacy-02/legacy-bad-proxy.max" quiet:true) "Legacy completed scene failed to open"
 lab=getNodeByName "Legacy_BadProxy";local saved=cplRows lab.physicsDocument
 collisionPanel lab
 collisionRequire (findString lab.collisionUI.proxyLabel.tooltip "Legacy_Plane"!=undefined) "Legacy bad proxy is still hidden"
 lab.brushHeader.startButton.pressed()
 collisionRequire (findString lab.uiError "Receiver 'Legacy_Plane'"!=undefined) "Legacy wrong proxy bypassed preparation guard"
 collisionRequire (cplRows lab.physicsDocument==saved) "Failed start changed cached result"
 lab.collisionUI.autoProxyButton.pressed()
 collisionRequire (cplRows lab.physicsDocument==saved) "Use auto silently rebuilt cached result"
 lab.brushHeader.startButton.pressed()
 collisionRequire (findString lab.uiError "Rebuild"!=undefined) "Changed cached collision shape did not require explicit rebuild"
 cplRebuild lab.physicsDocument lab
 local done=false
 for i=1 to 1000 while not done do done=cplTick lab.physicsDocument 8
 collisionRequire done "Explicit legacy correction rebuild failed"
 output=snapshotAsMesh lab;minimum=1e9
 for i=1 to output.numverts do minimum=amin minimum (getVert output i).z
 collisionRequire (minimum>-.1) "Rebuilt legacy sphere is below receiver"
 collisionRequire (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-016-legacy-02/legacy-bad-proxy-pending.max" quiet:true) "Legacy pending scene failed to load"
 lab=getNodeByName "Legacy_BadProxy";local oldPreviewCount=(cplUIState lab.physicsDocument)[6]
 collisionPanel lab;lab.brushHeader.startButton.pressed()
 collisionRequire (oldPreviewCount>0 and (cplUIState lab.physicsDocument)[2] and (cplUIState lab.physicsDocument)[6]==oldPreviewCount and lab.uiError!="") "Rejected old pending replay lost cached preview"
 cplCancel lab.physicsDocument;lab.refreshBindings();lab.collisionUI.autoProxyButton.pressed()
 collisionRequire (not cplCustomProxy lab.physicsDocument 1) "Old pending setup cannot be corrected after cancellation"
 local report=createFile (CPLTestDir+"collision-assertions.txt")
 format "PASS % collision-binding/64 sphere/SDK/continuous/outside/Undo/recovery/legacy/layout checks\n" CPLCollisionChecks to:report
 close report
)
