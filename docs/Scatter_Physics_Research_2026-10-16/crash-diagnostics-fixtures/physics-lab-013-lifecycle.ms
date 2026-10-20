cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
global CPLLifecycleChecks=0
fn lifecycleRequire value message = (CPLLifecycleChecks+=1;if not value do throw message)
fn lifecyclePump ms = (local end=timeStamp()+ms;while timeStamp()<end do (windows.processPostedMessages();sleep .01))
fn lifecycleFinish lab = (local done=false;for i=1 to 1000 while not done do (done=cplTick lab.physicsDocument 8);lifecycleRequire done (cplStats lab.physicsDocument);lifecycleRequire (not (cplUIState lab.physicsDocument)[4]) "Unexpected settle timeout")
(
 units.SystemType=#millimeters;units.SystemScale=1
 viewport.setLayout #layout_1;viewport.setType #view_top
 local ground=plane name:"Diagnostic_receiver" width:5000 length:5000 widthsegs:4 lengthsegs:4
 local source=sphere name:"Diagnostic_Sphere32" radius:32.788 segments:32 pos:[8000,8000,1000]
 local extra=box name:"Diagnostic_extra_collider" width:100 length:400 height:100 pos:[1500,1500,0]
 hide source
 local lab=CyrusPhysicsLab name:"Diagnostics_lifecycle"
 lab.brushRadius=.01;lab.birthSpacing=.2;lab.emissionHeight=.1
 select ground;max zoomext sel all
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 lab.brushHeader.open=true;lab.objectsUI.open=true
 lifecyclePump 300
 lab.objectsUI.receiverPick.picked ground;lab.objectsUI.sourcePick.picked source;lab.objectsUI.colliderPick.picked extra
 lab.brushHeader.startButton.pressed()
 lifecycleRequire ((cplUIState lab.physicsDocument)[1]) "Start did not activate Painter"
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"diagnostic-info.json") (cplDiagnosticInfo())
 lifecycleRequire (findString (cplDiagnosticInfo()) "\"watcher_ready\":true"!=undefined) "Crash watcher not ready"
 lifecycleRequire (findString (cplDiagnosticInfo()) "\"error\":0"!=undefined) "Diagnostic initialization failed"
 lifecycleRequire (cplPrivatePaintPath lab.physicsDocument #([-1000,-1000,0],[-600,-1000,0]) false==2) "Baseline hit failed"
 lifecycleFinish lab
 local baseline=cplRows lab.physicsDocument
 lifecycleRequire ((cplUIState lab.physicsDocument)[5]>=2) "No saved baseline"
 lab.brushHeader.stopButton.pressed()

 cplStage "50 Start brush / pending / Stop / restart / late callback cycles"
 for i=1 to 50 do
 (
  lab.brushHeader.startButton.pressed()
  lifecycleRequire ((cplUIState lab.physicsDocument)[1]) ("Restart failed "+i as string)
  lifecycleRequire (cplPrivatePaintLate lab.physicsDocument #([0,0,0])==false) "Late callback before StartStroke should be ignored"
  lifecycleRequire (cplPrivatePaintContinue lab.physicsDocument #([0,0,0])==1) "Pending stroke failed"
  lifecycleRequire ((cplUIState lab.physicsDocument)[6]>=1) "Missing pending preview"
  lab.brushHeader.stopButton.pressed()
  lifecycleRequire (not (cplUIState lab.physicsDocument)[1] and not (cplUIState lab.physicsDocument)[2]) "Stop left active work"
  lifecycleRequire (cplRows lab.physicsDocument==baseline) "Stop/restart changed saved result"
  lifecyclePump 20
 )

 cplStage "repeated callbacks during settling, rejected Cancel, exact result retention"
 lab.brushHeader.startButton.pressed()
 lifecycleRequire (cplPrivatePaintPath lab.physicsDocument #([0,0,0],[400,0,0]) false==2) "Released stroke failed"
 local pending=(cplUIState lab.physicsDocument)[6]
 local rejected=false
 try(cplPrivatePaintContinue lab.physicsDocument #([800,0,0]))catch(rejected=true)
 lifecycleRequire rejected "New stroke should be rejected while prior one settles"
 for i=1 to 20 do lifecycleRequire (cplPrivatePaintLate lab.physicsDocument #([1000,0,0])==false) "Late settling hit should be ignored"
 cplPrivateRejectedFinish lab.physicsDocument
 lifecycleRequire ((cplUIState lab.physicsDocument)[2] and (cplUIState lab.physicsDocument)[6]==pending) "Rejected callback cancelled prior settling stroke"
 lifecycleFinish lab
 lifecycleRequire ((cplUIState lab.physicsDocument)[5]>2) "Prior settling result was not published"
 cplExportFile lab.physicsDocument (CPLTestDir+"retained-after-rejection.json")
 max undo
 lifecycleRequire (cplRows lab.physicsDocument==baseline) "Rejected-gesture path broke Undo"

 cplStage "late callback after cancellation"
 lifecycleRequire (cplPrivatePaintContinue lab.physicsDocument #([0,1000,0])==1) "Cancel fixture failed"
 cplCancel lab.physicsDocument
 for i=1 to 20 do lifecycleRequire (cplPrivatePaintLate lab.physicsDocument #([0,1200,0])==false) "Cancelled stroke accepted a late callback"
 lifecycleRequire (cplRows lab.physicsDocument==baseline) "Late cancelled callbacks changed saved result"
 lifecycleRequire (cplPrivatePaintPath lab.physicsDocument #([0,1000,0],[400,1000,0]) false==2) "Recovery stroke failed"
 lifecycleFinish lab
 lab.brushHeader.stopButton.pressed()
 lifecycleRequire (findString (cplDiagnosticInfo()) "\"error\":0"!=undefined) "Recorder error occurred during lifecycle tests"
 saveMaxFile (CPLTestDir+"Diagnostics_Lifecycle.max") quiet:true
 local saved=cplRows lab.physicsDocument
 loadMaxFile (CPLTestDir+"Diagnostics_Lifecycle.max") quiet:true
 lab=getNodeByName "Diagnostics_lifecycle"
 lifecycleRequire (cplRows lab.physicsDocument==saved) "Diagnostic version changed saved poses on reopen"
 local out=createFile (CPLTestDir+"assertions.txt")
 format "PASS % checks: 50 Stop/restart cycles, late callbacks during rejected/settling/cancelled gestures, prior-result retention, Undo, recovery and save/reopen.\n" CPLLifecycleChecks to:out
 close out
)
