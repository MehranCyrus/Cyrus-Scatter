-- Private fault build only. Collision inspection must match the retained pending world.
cplResetScene()
fn faultNeed value message = if not value do throw message
fn cachedLines text = (((dotNetClass "System.Text.RegularExpressions.Regex").Match text "\"cached_lines\":([0-9]+)").Groups.Item[1].Value as integer)
(
 units.SystemType=#meters;units.SystemScale=1
 local ground=plane width:5 length:5
 local source=box width:.1 length:.05 height:.004 pos:[8,8,0]
 local lab=CyrusPhysicsLab name:"Faults_collision_display"
 lab.setReceiver ground;lab.addSource source;lab.brushRadius=.001;lab.showCollisionShapes=true
 local baseline=cplRows lab.physicsDocument
 for mode=1 to 2 do
 (
  cplStage ("publication fault "+mode as string)
  lab.startBrush();cplSample lab.physicsDocument [0,0,0] [0,0,1] true;cplRelease lab.physicsDocument;cplSynchronize lab.physicsDocument
  local expected=cachedLines (cplCollisionDisplayInfo lab.physicsDocument)
  faultNeed (expected>12) "Fault fixture lacks a collider overlay"
  cplInject lab.physicsDocument mode;cplFreeze lab.physicsDocument
  for i=1 to 50 do (cplTick lab.physicsDocument 1;sleep .01)
  faultNeed (cplRows lab.physicsDocument==baseline) "Publication failure changed completed result"
  faultNeed ((cplUIState lab.physicsDocument)[2] and (cplUIState lab.physicsDocument)[6]==1) "Publication failure lost pending body"
  faultNeed (findString (cplStats lab.physicsDocument) "Injected"!=undefined) "Fault not exercised"
  faultNeed (cachedLines (cplCollisionDisplayInfo lab.physicsDocument)==expected) "Publication rollback changed pending collision geometry"
  cplFreeze lab.physicsDocument
  for i=1 to 100 while (cplUIState lab.physicsDocument)[2] do (cplTick lab.physicsDocument 1;sleep .01)
  faultNeed ((cplUIState lab.physicsDocument)[5]==1) "Explicit retry failed"
  max undo
  faultNeed (cplRows lab.physicsDocument==baseline) "Retry Undo changed cached result"
 )
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") "PASS pre/post publication faults: retained result, pending world and its collision wires; explicit retry and Undo"
)
