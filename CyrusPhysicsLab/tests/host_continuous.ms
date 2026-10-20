-- Public Max 2027 callbacks and actual rollout handlers. No OS input.
setSilentMode true
setQuietMode true
resetMaxFile #noPrompt
setSilentMode false
setQuietMode false
global CPLChecks=0
fn require value message = (CPLChecks+=1;if not value do throw message)
fn pump duration = (local until=timeStamp()+duration;while timeStamp()<until do (windows.processPostedMessages();sleep 0.01))
fn waitFinished lab = (local until=timeStamp()+35000;while (cplUIState lab.physicsDocument)[2] and timeStamp()<until do (cplTick lab.physicsDocument 8;pump 20);require (not (cplUIState lab.physicsDocument)[2]) ("Finish failed: "+cplStats lab.physicsDocument))
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
(
 units.SystemType=#meters;units.SystemScale=1
 viewport.setLayout #layout_1;viewport.setType #view_top
 local ground=plane name:"Continuous_receiver" width:5 length:5 widthsegs:4 lengthsegs:4
 local source=sphere name:"Continuous_model" radius:.032788 segments:32 pos:[8,8,0]
 hide source
 local lab=CyrusPhysicsLab name:"Continuous_qualification"
 lab.brushRadius=.025;lab.birthSpacing=.08;lab.emissionHeight=.8
 select ground;max zoomext sel all
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 lab.brushHeader.open=true;lab.objectsUI.open=true;lab.brushUI.open=true
 pump 300
 require lab.brushHeader.controlsReady "Header did not bind"
 require (not lab.brushHeader.startButton.enabled) "Start enabled without bindings"
 lab.objectsUI.receiverPick.picked ground
 lab.objectsUI.sourcePick.picked source
 pump 100
 require lab.brushHeader.startButton.enabled ("Bindings failed: "+lab.brushHeader.statusLabel.text)
 lab.brushHeader.startButton.pressed()
 require ((cplUIState lab.physicsDocument)[1]) ("Start failed: "+cplStats lab.physicsDocument+lab.uiError)
 cplStage "continuous held gesture"
 require (cplPrivatePaintContinue lab.physicsDocument #([-.6,0,0],[-.4,0,0])==2) "First stroke TestHit failed"
 cplSynchronize lab.physicsDocument
 local before=cplPendingRows lab.physicsDocument
 (dotNetClass "System.Threading.Thread").Sleep 220
 require (cplPendingRows lab.physicsDocument!=before) "Physics stalled while host thread was blocked during a held gesture"
 cplRelease lab.physicsDocument
 cplSynchronize lab.physicsDocument
 require ((cplUIState lab.physicsDocument)[13]>0) "Fixture was already at rest"
 require (cplPrivatePaintPath lab.physicsDocument #([.2,0,0],[.4,0,0]) false==2) "Second stroke rejected while first moves"
 cplSynchronize lab.physicsDocument
 require ((cplUIState lab.physicsDocument)[9]==2) "Continuous stroke history missing"
 require ((cplUIState lab.physicsDocument)[5]==0) "Mouse release prematurely published the session"
 cplStage "live undo redo"
 lab.brushHeader.stopButton.pressed()
 local after=cplPendingRows lab.physicsDocument,fullCount=(cplUIState lab.physicsDocument)[6]
 lab.brushHeader.undoButton.pressed()
 require ((cplUIState lab.physicsDocument)[6]<fullCount and (cplUIState lab.physicsDocument)[10]==1) "Live Undo failed"
 lab.brushHeader.redoButton.pressed()
 require (cplPendingRows lab.physicsDocument==after) "Redo failed to restore exact poses velocities and sleep"
 cplStage "pause resume lifecycle"
 for i=1 to 10 do
 (
  lab.brushHeader.startButton.pressed()
  require ((cplUIState lab.physicsDocument)[1]) ("Resume failed: "+cplStats lab.physicsDocument)
  lab.brushHeader.stopButton.pressed()
  require ((cplUIState lab.physicsDocument)[8]) "Pause failed"
 )
 cplStage "outside receiver and re-entry"
 lab.brushHeader.startButton.pressed()
 local original=(cplUIState lab.physicsDocument)[6]
 require (cplPrivatePaintPath lab.physicsDocument #([10,10,0],[12,10,0]) false==0) "Outside SDK hit unexpectedly succeeded"
 cplSynchronize lab.physicsDocument
 require ((cplUIState lab.physicsDocument)[6]==original) "Outside drag emitted bodies"
 require (cplPrivatePaintPath lab.physicsDocument #([-1,1,0],[12,10,0],[1,1,0]) false==2) "Re-entry SDK hit failed"
 cplSynchronize lab.physicsDocument
 require ((cplUIState lab.physicsDocument)[6]==original+2) "Outside gap emitted a connecting bridge"
 local history=(cplUIState lab.physicsDocument)[9]
 require (cplPrivatePaintPath lab.physicsDocument #([0,-1,0]) true==1) "Cancel callback failed"
 cplSynchronize lab.physicsDocument
 require ((cplUIState lab.physicsDocument)[9]==history) "Cancel removed earlier stroke history"
 cplStage "paused scene persistence"
 lab.brushHeader.stopButton.pressed()
 local pendingCount=(cplUIState lab.physicsDocument)[6]
 require (saveMaxFile (CPLTestDir+"pending.max") quiet:true) "Pending scene save failed"
 cplResetScene()
 require (loadMaxFile (CPLTestDir+"pending.max") quiet:true) "Pending scene load failed"
 lab=getNodeByName "Continuous_qualification"
 require ((cplUIState lab.physicsDocument)[2] and (cplUIState lab.physicsDocument)[8]) "Saved pending session did not load paused"
 require ((cplUIState lab.physicsDocument)[6]==pendingCount) "Saved preview was lost"
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 pump 200
 lab.brushHeader.startButton.pressed()
 require ((cplUIState lab.physicsDocument)[1]) ("Recovery resume failed: "+cplStats lab.physicsDocument+lab.uiError)
 lab.brushHeader.stopButton.pressed()
 require ((cplUIState lab.physicsDocument)[9]==history) "Recovered history missing"
 lab.brushHeader.undoButton.pressed()
 require ((cplUIState lab.physicsDocument)[9]==history-1) "Recovered Undo failed"
 lab.brushHeader.redoButton.pressed()
 require ((cplUIState lab.physicsDocument)[6]==pendingCount) "Recovered Redo failed"
 cplStage "finish and Max Undo"
 lab.brushHeader.finishButton.pressed()
 waitFinished lab
 require ((cplUIState lab.physicsDocument)[5]==pendingCount) "Finish lost supported bodies"
 local rows=cplRows lab.physicsDocument
 require (findString (cplStats lab.physicsDocument) "\"settled\":true"!=undefined) "Finish marked unsettled"
 max undo
 require ((cplUIState lab.physicsDocument)[5]==0) "Max Undo did not remove the whole session"
 max redo
 require (cplRows lab.physicsDocument==rows) "Max Redo did not restore exact saved positions"
 cplStage "freeze and cancel isolation"
 lab.startBrush()
 cplSample lab.physicsDocument [1,-1,0] [0,0,1] true
 cplRelease lab.physicsDocument
 cplSynchronize lab.physicsDocument
 cplFreeze lab.physicsDocument
 waitFinished lab
 require ((cplUIState lab.physicsDocument)[5]==pendingCount+1) "Freeze failed"
 require (findString (cplStats lab.physicsDocument) "\"settled\":false"!=undefined) "Freeze claimed settled"
 max undo
 require (cplRows lab.physicsDocument==rows) "Freeze Undo moved saved bodies"
 lab.startBrush()
 cplSample lab.physicsDocument [-1,-1,0] [0,0,1] true
 cplRelease lab.physicsDocument
 cplSynchronize lab.physicsDocument
 cplStop lab.physicsDocument
 require (cplRows lab.physicsDocument==rows and not (cplUIState lab.physicsDocument)[2]) "Cancel session changed saved result"
 cplStage "legacy cached result"
 local cached=cplExport lab.physicsDocument
 cached=substituteString cached "\"schema\":2" "\"schema\":1"
 cached=substituteString cached "cpl-continuous-1" "cpl-leaf-3"
 local old=CyrusPhysicsLab name:"Legacy_cached"
 cplImport old.physicsDocument cached
 require (cplRows old.physicsDocument==rows) "Schema 1 cache no longer reads"
 local report=createFile (CPLTestDir+"assertions.txt")
 format "PASS % continuous Max 2027 checks\n%\n" CPLChecks (cplStats lab.physicsDocument) to:report
 close report
)
