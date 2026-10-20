fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/bake-020-fixtures/helpers.ms"
cplResetScene()
(
 units.SystemType=#meters;units.SystemScale=1
 local ground=plane width:5 length:5,model=box width:.1 length:.1 height:.1 pos:[10,0,0]
 hide model
 local lab=CyrusPhysicsLab name:"Fault_Bake_020"
 lab.setReceiver ground;lab.addSource model;lab.brushRadius=.001;lab.birthSpacing=.2;lab.emissionHeight=.6
 viewport.setType #view_top;select ground;max zoomext sel all;bShow lab
 for mode=1 to 2 do
 (
  cplStage ("bake fault "+mode as string)
  lab.startBrush();bPath lab #([-.3,0,0],[.3,0,0]);lab.brushHeader.stopButton.pressed()
  local count=objects.count,rows=(cplUIState lab.physicsDocument)[6]
  cplInject lab.physicsDocument mode
  lab.brushHeader.keepButton.pressed()
  local until=timeStamp()+10000
  while timeStamp()<until and findString (cplStats lab.physicsDocument) "Injected failure"==undefined do (cplTick lab.physicsDocument 1;bPump 10)
  bNeed (findString (cplStats lab.physicsDocument) "Injected failure"!=undefined) "Fault did not reach bake publication"
  bNeed ((cplUIState lab.physicsDocument)[2] and (cplUIState lab.physicsDocument)[6]==rows) "Fault discarded pending bodies"
  bNeed ((cplColliderNodes lab.physicsDocument).count==0 and cplRows lab.physicsDocument=="[]") "Fault left partial binding/state"
  bNeed (objects.count==count) "Fault left an orphan baked node"
  bWrite ("fault-"+(mode as string)+"-retained.json") (cplStats lab.physicsDocument)
  lab.brushHeader.keepButton.pressed();bWait lab
  bNeed ((cplColliderNodes lab.physicsDocument).count==1 and objects.count==count+1) "Retry after fault failed"
  max undo;bNeed ((cplColliderNodes lab.physicsDocument).count==0 and objects.count==count) "Undo after fault/retry failed"
 )
 bWrite "fault-count.txt" (BChecks as string)
)
