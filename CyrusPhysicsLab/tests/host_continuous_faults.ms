cplResetScene()
fn faultRequire value message = if not value do throw message
(
 units.SystemType=#meters;units.SystemScale=1
 local ground=plane width:5 length:5
 local leaf=box width:.1 length:.05 height:.004 pos:[8,8,0]
 local lab=CyrusPhysicsLab name:"Faults_continuous"
 lab.setReceiver ground;lab.addSource leaf;lab.brushRadius=.001
 local baseline=cplRows lab.physicsDocument
 for mode=1 to 2 do
 (
  cplStage ("publication fault "+mode as string)
  lab.startBrush();cplSample lab.physicsDocument [0,0,0] [0,0,1] true;cplRelease lab.physicsDocument;cplSynchronize lab.physicsDocument
  cplInject lab.physicsDocument mode;cplFreeze lab.physicsDocument
  for i=1 to 50 do (cplTick lab.physicsDocument 1;sleep .01)
  faultRequire (cplRows lab.physicsDocument==baseline) "Publication failure altered previous result"
  faultRequire ((cplUIState lab.physicsDocument)[2] and (cplUIState lab.physicsDocument)[6]==1) "Publication failure destroyed pending preview"
  faultRequire (findString (cplStats lab.physicsDocument) "Injected"!=undefined) "Failure was not exercised or automatically retried"
  cplFreeze lab.physicsDocument
  for i=1 to 20 while (cplUIState lab.physicsDocument)[2] do (cplTick lab.physicsDocument 1;sleep .01)
  faultRequire ((cplUIState lab.physicsDocument)[5]==1) "Explicit retry failed"
  max undo
  faultRequire (cplRows lab.physicsDocument==baseline) "Retry Undo failed"
 )
 lab.emissionHeight=10;lab.configure();cplBudget lab.physicsDocument 60 65536 65536
 lab.startBrush();cplSample lab.physicsDocument [0,0,0] [0,0,1] true;cplRelease lab.physicsDocument;cplFinish lab.physicsDocument
 for i=1 to 300 while not (cplUIState lab.physicsDocument)[4] do (cplTick lab.physicsDocument 1;sleep .01)
 faultRequire ((cplUIState lab.physicsDocument)[4]) "Finish timeout missing"
 faultRequire (cplRows lab.physicsDocument==baseline and (cplUIState lab.physicsDocument)[6]==1) "Timeout lost result or preview"
 cplFreeze lab.physicsDocument
 for i=1 to 100 while (cplUIState lab.physicsDocument)[2] do (cplTick lab.physicsDocument 1;sleep .01)
 faultRequire (findString (cplStats lab.physicsDocument) "\"settled\":false"!=undefined) "Timeout Freeze failed"
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") "PASS both publication faults, retained preview, no automatic retry, explicit retry/Undo, Finish timeout and Freeze"
)
