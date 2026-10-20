-- Uses the shared helpers from host_workflow.ms. No OS input.
cplResetScene()
(
 units.SystemType=#meters;units.SystemScale=1
 local ground=plane name:"Stack_Ground_020" width:8 length:8
 local platform=box name:"Platform_Source_020" width:1.2 length:1.2 height:.3 pos:[10,0,0]
 local ball=sphere name:"Stack_Sphere_020" radius:.1 segments:16 pos:[11,0,0]
 platform.wirecolor=color 230 150 40;ball.wirecolor=color 60 140 220;hide platform;hide ball
 local lab=CyrusPhysicsLab name:"Stack_Lab_020"
 lab.setReceiver ground;lab.addSource platform;lab.addSource ball
 lab.brushRadius=.0001;lab.birthSpacing=.5;lab.emissionHeight=.8;lab.scaleMinimum=1;lab.scaleMaximum=1;lab.bounce=0
 viewport.setType #view_top;select ground;max zoomext sel all;bShow lab
 lab.objectsUI.setChecked #(true,false)
 lab.startBrush();bPath lab #([0,0,0]);lab.brushHeader.finishButton.pressed();bWait lab
 local base=(cplColliderNodes lab.physicsDocument)[1],bounds=nodeGetBoundingBox base (matrix3 1)
 bNeed (abs(bounds[1].z)<.005 and abs(bounds[2].z-.3)<.005) "Baked platform pose incorrect"
 lab.objectsUI.setChecked #(false,true);lab.objectsUI.sourceList.SelectedIndex=1;lab.collisionUI.selectQuality 3
 lab.startBrush();bPath lab #([0,0,0]);lab.brushHeader.finishButton.pressed();bWait lab
 local top=(cplColliderNodes lab.physicsDocument)[2],upper=nodeGetBoundingBox top (matrix3 1)
 bNeed (upper[1].z>.29 and upper[2].z>.49) "New sphere did not collide with baked poly platform"
 bWrite "stack-height.txt" ((upper[1].z as string)+","+(upper[2].z as string))
 lab.showCollisionShapes=true;lab.applyCollisionDisplay();lab.startBrush();lab.stopBrush();redrawViews()
 bWrite "stack-collision-display.json" (cplCollisionDisplayInfo lab.physicsDocument)
 bNeed (saveMaxFile (CPLTestDir+"baked-stack.max") quiet:true) "Stack scene save failed"
 -- A dense output must fail BEFORE publication, retaining preview and other batches.
 lab.objectsUI.setChecked #(false,true)
 ball.segments=128;lab.emissionHeight=3;lab.birthSpacing=.25;lab.brushRadius=.0001
 lab.startBrush();bPath lab #([-2,2,0],[1.5,2,0]);lab.brushHeader.stopButton.pressed()
 bNeed (((cplUIState lab.physicsDocument)[6])*(getNumFaces (snapshotAsMesh ball))>200000) "Budget fixture did not exceed the triangle limit"
 local beforeNodes=objects.count,beforePreview=cplPendingRows lab.physicsDocument,beforeColliders=(cplColliderNodes lab.physicsDocument).count
 lab.brushHeader.keepButton.pressed()
 local until=timeStamp()+10000
 while timeStamp()<until and findString (cplStats lab.physicsDocument) "200,000"==undefined do (cplTick lab.physicsDocument 1;bPump 20)
 bNeed ((cplUIState lab.physicsDocument)[2]) "Over-budget bake discarded pending session"
 bNeed (objects.count==beforeNodes and (cplColliderNodes lab.physicsDocument).count==beforeColliders) "Rejected bake partially published geometry"
 bNeed ((cplUIState lab.physicsDocument)[6]>0 and findString (cplStats lab.physicsDocument) "200,000"!=undefined) ("Budget error not recorded: "+cplStats lab.physicsDocument)
 bWrite "expected-bake-budget-error.json" (cplStats lab.physicsDocument)
 lab.stopBrush()
 bNeed ((cplColliderNodes lab.physicsDocument).count==2) "Cancel after failed bake damaged batches"
 bWrite "stack-count.txt" (BChecks as string)
)
