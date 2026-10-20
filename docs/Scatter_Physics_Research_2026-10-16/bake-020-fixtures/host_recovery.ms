fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/bake-020-fixtures/helpers.ms"
cplResetScene()
(
 units.SystemType=#meters;units.SystemScale=1
 local ground=plane name:"Recovery_Ground_020" width:5 length:5,source=box name:"Recovery_Source_020" width:.1 length:.1 height:.1 pos:[10,0,0]
 hide source
 local lab=CyrusPhysicsLab name:"Recovery_Lab_020"
 lab.setReceiver ground;lab.addSource source;lab.brushRadius=.001;lab.birthSpacing=.2;lab.emissionHeight=.6
 viewport.setType #view_top;select ground;max zoomext sel all;bShow lab
 lab.startBrush();bPath lab #([-.3,0,0],[.3,0,0]);lab.brushHeader.stopButton.pressed()
 local count=(cplUIState lab.physicsDocument)[6]
 bNeed (saveMaxFile (CPLTestDir+"pending-bake.max") quiet:true) "Pending save failed"
 cplResetScene();bNeed (loadMaxFile (CPLTestDir+"pending-bake.max") quiet:true useFileUnits:true) "Pending reload failed"
 lab=getNodeByName "Recovery_Lab_020";bShow lab
 bNeed ((cplUIState lab.physicsDocument)[2] and (cplUIState lab.physicsDocument)[6]==count) "Pending preview not retained"
 lab.startBrush();bNeed ((cplUIState lab.physicsDocument)[1]) "Pending recovery Resume failed"
 lab.brushHeader.stopButton.pressed()
 bNeed (saveMaxFile (CPLTestDir+"pending-bake-resumed.max") quiet:true) "Resumed pending save failed"
 cplResetScene();bNeed (loadMaxFile (CPLTestDir+"pending-bake-resumed.max") quiet:true useFileUnits:true) "Second pending reload failed"
 lab=getNodeByName "Recovery_Lab_020";bShow lab
 -- Freeze directly from cached data, before Resume has established transient ownerHandle.
 lab.brushHeader.keepButton.pressed();bWait lab
 local colliders=cplColliderNodes lab.physicsDocument
 bNeed (colliders.count==1 and classOf colliders[1].baseObject==Editable_Poly) "Cached recovery did not bake to Editable Poly"
 bNeed ((getUserProp colliders[1] "CyrusPhysicsLabBodies")==count) "Cached bake lost bodies"
 max undo;bNeed ((cplColliderNodes lab.physicsDocument).count==0) "Cached bake Undo failed"
 max redo;bNeed ((cplColliderNodes lab.physicsDocument).count==1) "Cached bake Redo failed"
 bWrite "recovery-count.txt" (BChecks as string)
)
