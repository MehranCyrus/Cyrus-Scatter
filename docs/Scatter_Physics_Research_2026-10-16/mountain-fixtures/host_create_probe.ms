cplResetScene()
(
 cplStage "construct"
 local lab=CyrusPhysicsLab name:"Collision_Create_Probe"
 cplStage "constructed"
 local ground=plane width:100 length:100
 local model=box width:1 length:1 height:10 pos:[200,200,0]
 lab.setReceiver ground;lab.addSource model
 cplSetCollisionDisplay lab.physicsDocument lab true
 lab.startBrush()
 cplSample lab.physicsDocument [0,0,0] [0,0,1] true
 cplRelease lab.physicsDocument;cplSynchronize lab.physicsDocument
 redrawViews()
 cplDrawCollisionShapes()
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"overlay.json") (cplCollisionDisplayInfo lab.physicsDocument)
 cplPause lab.physicsDocument
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"assertions.txt") "PASS constructor and explicit collision inspection"
)
