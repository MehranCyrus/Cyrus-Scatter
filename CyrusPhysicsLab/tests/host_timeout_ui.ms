cplResetScene()
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-brush-probe-013/" "CyrusPhysicsProbe.dlx"
(
 units.SystemType=#meters;units.SystemScale=1
 viewport.setLayout #layout_1;viewport.setType #view_top
 local ground=plane width:5 length:5 widthsegs:4 lengthsegs:4
 local source=box width:.1 length:.05 height:.004 pos:[8,8,0]
 hide source
 local lab=CyrusPhysicsLab name:"PhysicsLab_Timeout_UI"
 lab.setReceiver ground;lab.addSource source;lab.brushRadius=.01;lab.configure()
 cplArea lab.physicsDocument lab #() 1
 local done=false
 for i=1 to 1000 while not done do done=cplTick lab.physicsDocument 8
 if not done do throw "Timeout fixture baseline failed to settle."
 local saved=cplRows lab.physicsDocument
 select ground;max zoomext sel all
 select lab;max modify mode;modPanel.setCurrentObject lab.baseObject
 lab.brushHeader.open=true;lab.objectsUI.open=true;lab.brushUI.open=true
 windows.processPostedMessages()
 lab.refreshBindings()
 if not lab.brushHeader.isDisplayed do throw "Open the real brush header before testing its controls."
 lab.emissionHeight=10;lab.configure();cplBudget lab.physicsDocument 60 65536 65536
 for action in #(#stop,#keep) do
 (
  lab.brushHeader.startButton.pressed()
  if (cplPrivatePaintPath lab.physicsDocument #([0,0,0]) false)!=1 do throw "Timeout probe missed receiver."
  for i=1 to 10 do cplTick lab.physicsDocument 8
  lab.syncUI()
  if not (cplUIState lab.physicsDocument)[4] do throw "Expected deliberate step-limit timeout."
  if cplRows lab.physicsDocument!=saved do throw "Timeout changed the completed result."
  if not lab.brushHeader.keepButton.visible or not lab.brushHeader.keepButton.enabled do throw "Timeout did not expose Keep preview."
  if lab.brushHeader.startButton.enabled or not lab.brushHeader.stopButton.enabled do throw "Timeout action states are wrong."
  if lab.brushUI.radiusSpin.enabled do throw "Pending solve inputs remained editable."
  local status=substituteString lab.brushHeader.statusLabel.text "\n" " "
  if (findString status "Keep preview")==undefined do throw ("Status does not name the recovery action: "+status)
  local bitmap=windows.snapshot lab.brushHeader.hwnd captureScreenPixels:false gammaCorrect:false
  bitmap.filename=CPLTestDir+"ui-timeout.png";save bitmap;close bitmap
  if action==#stop then
  (
   lab.brushHeader.stopButton.pressed()
   if cplRows lab.physicsDocument!=saved do throw "Stop lost the saved result."
   if (cplUIState lab.physicsDocument)[1] or (cplUIState lab.physicsDocument)[2] do throw "Stop left authoring active."
  )
  else
  (
   lab.brushHeader.keepButton.pressed()
   if findString (cplExport lab.physicsDocument) "\"settled\":false"==undefined do throw "Keep preview did not mark an unfinished result."
   max undo
   if cplRows lab.physicsDocument!=saved do throw "Keep preview Undo lost the completed result."
   lab.brushHeader.stopButton.pressed()
  )
 )
 local report=createFile (CPLTestDir+"assertions.txt")
 format "PASS timeout UI: saved-result retention, status, disabled edits, Stop, explicit Keep preview and Undo\n" to:report
 close report
)
