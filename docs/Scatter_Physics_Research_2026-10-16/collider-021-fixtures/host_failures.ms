fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/bake-020-fixtures/helpers.ms"
cplResetScene()
(
 units.SystemType=#meters;units.SystemScale=1
 local ground=plane name:"Failure_Ground" width:5 length:5,source=box width:.1 length:.1 height:.1 pos:[10,0,0]
 local invalid=mesh name:"ZeroArea_Collider" vertices:#([0,0,0],[1,0,0],[2,0,0]) faces:#([1,2,3])
 hide source;hide invalid
 local lab=CyrusPhysicsLab name:"Failure_Lab"
 lab.setReceiver ground;lab.addSource source;lab.addCollider invalid
 viewport.setType #view_top;select ground;max zoomext sel all;bShow lab
 cplStage "failed worker restart cleanup"
 for attempt=1 to 3 do
 (
  lab.brushHeader.startButton.pressed()
  bNeed (not (cplUIState lab.physicsDocument)[1] and not (cplUIState lab.physicsDocument)[2]) "Failed world remains a resumable pending session"
  bNeed (findString lab.uiError "Static collider 1"!=undefined and findString lab.uiError "non-degenerate"!=undefined) ("Failed world hid collider cause: "+lab.uiError)
  bNeed (findString lab.uiError "retired"==undefined) "Retry used retired worker"
 )
 delete invalid
 lab.brushHeader.startButton.pressed();bNeed ((cplUIState lab.physicsDocument)[1]) ("Cannot retry after deleting invalid collider: "+lab.uiError)
 bPath lab #([0,0,0]);lab.brushHeader.finishButton.pressed();bWait lab
 local baked=(cplColliderNodes lab.physicsDocument)[1]
 bNeed (classOf baked.baseObject==Editable_Poly) "Successful retry did not bake"
 -- Valid volume vertices with invalid render triangles: preparation has a valid
 -- auto hull, but baking must reject the unusable rendered collider atomically.
 local snapshot=snapshotAsMesh source
 local badSource=mesh name:"Degenerate_Render" vertices:(for i=1 to getNumVerts snapshot collect getVert snapshot i) faces:#([1,1,1])
 badSource.pos=[12,0,0];hide badSource
 cplReplaceSource lab.physicsDocument 1 badSource;lab.sourceNodes[1]=badSource;lab.refreshBindings()
 lab.brushHeader.startButton.pressed();bNeed ((cplUIState lab.physicsDocument)[1]) ("Bad render fixture failed before bake: "+lab.uiError)
 bPath lab #([1,0,0]);lab.brushHeader.stopButton.pressed()
 local count=objects.count,preview=cplPendingRows lab.physicsDocument
 cplStage "bake preflight rollback"
 lab.brushHeader.keepButton.pressed();bPump 200;cplTick lab.physicsDocument 4
 bNeed ((cplUIState lab.physicsDocument)[2] and (cplUIState lab.physicsDocument)[6]>0) "Rejected bake lost pending preview"
 bNeed (objects.count==count and isValidNode baked and (cplColliderNodes lab.physicsDocument).count==1) "Rejected bake changed previous nodes or binding"
 bNeed (cplPendingRows lab.physicsDocument==preview) "Rejected bake changed paused poses"
 lab.stopBrush()
 bWrite "failure-count.txt" (BChecks as string)
)
