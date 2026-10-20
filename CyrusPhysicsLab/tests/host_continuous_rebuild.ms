cplResetScene()
(
 units.SystemType=#meters;units.SystemScale=1
 local ground=plane width:5 length:5,source=box width:.1 length:.05 height:.004 pos:[8,8,0]
 local lab=CyrusPhysicsLab name:"Continuous_rebuild"
 lab.setReceiver ground;lab.addSource source;lab.brushRadius=.001
 for session=1 to 2 do
 (
  lab.startBrush()
  for gesture=1 to 2 do (cplSample lab.physicsDocument [(session*.5),(gesture*.5),0] [0,0,1] true;cplRelease lab.physicsDocument;cplSynchronize lab.physicsDocument)
  cplFreeze lab.physicsDocument
  for i=1 to 100 while (cplUIState lab.physicsDocument)[2] do (cplTick lab.physicsDocument 1;sleep .01)
  if (cplUIState lab.physicsDocument)[5]!=session*2 do throw "Completed sessions did not append"
 )
 local before=cplRows lab.physicsDocument
 lab.configure();cplRebuild lab.physicsDocument lab
 local done=false
 for i=1 to 1500 while not done do done=cplTick lab.physicsDocument 8
 if not done or (cplUIState lab.physicsDocument)[5]!=4 do throw ("Continuous rebuild failed: "+cplStats lab.physicsDocument)
 local after=cplRows lab.physicsDocument
 max undo
 if cplRows lab.physicsDocument!=before do throw "Rebuild Undo failed"
 max redo
 if cplRows lab.physicsDocument!=after do throw "Rebuild Redo failed"
 cplExportFile lab.physicsDocument (CPLTestDir+"rebuilt-schedule.json")
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") "PASS two continuous sessions, four gestures, explicit scheduled Rebuild and Max Undo/Redo"
)
