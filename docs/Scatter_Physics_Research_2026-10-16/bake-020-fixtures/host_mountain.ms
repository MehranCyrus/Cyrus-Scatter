cplResetScene()
bNeed (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-quality-018-20261018-01/Mountain Scene Brush Test.max" quiet:true useFileUnits:true) "Mountain copy failed"
(
 local ground=getNodeByName "Plane001",pyramid=getNodeByName "Pyramid001"
 local foreign=for node in objects where node!=ground and node!=pyramid collect node
 delete foreign
 local factor=(units.decodeValue "1m")/100.0
 local sphereModel=sphere name:"Bake020_Sphere" radius:(60*factor) segments:32 pos:([16000,0,0]*factor)
 local tea=teapot name:"Bake020_Teapot" radius:(120*factor) segments:8 pos:([17000,0,0]*factor)
 pyramid.wirecolor=color 230 130 50;sphereModel.wirecolor=color 80 150 230;tea.wirecolor=color 80 200 100
 ground.material=standardMaterial name:"Mountain_Grey_020" diffuse:(color 140 140 140)
 pyramid.material=undefined;sphereModel.material=undefined;tea.material=standardMaterial name:"Teapot_Green_020" diffuse:(color 80 200 100)
 local models=#(pyramid,sphereModel,tea),kindNames=#("pyramid","sphere","teapot")
 for model in models do hide model
 viewport.setLayout #layout_1;viewport.setType #view_top;select ground;max zoomext sel all
 local timeoutCount=0,caseCount=0
 for sourceIndex=1 to 3 do for quality=0 to 2 do
 (
  local kind=kindNames[sourceIndex]+"_q"+(quality as string)
  cplStage ("mountain "+kind)
  local lab=CyrusPhysicsLab name:("Bake020_"+kind)
  lab.pos=[0,0,1400]*factor;lab.viewportIconSize=2;lab.setReceiver ground;lab.addSource models[sourceIndex]
  lab.brushRadius=.08;lab.birthSpacing=1.5;lab.emissionHeight=.6;lab.bodyLimit=1000
  lab.showCollisionShapes=true;bShow lab;lab.collisionUI.selectQuality (quality+1)
  lab.brushHeader.startButton.pressed();bNeed ((cplUIState lab.physicsDocument)[1]) ("Mountain Start failed "+lab.uiError)
  local y=6000-sourceIndex*2400-quality*500
  local a=intersectRay ground (ray ([-5000,y,100000]*factor) [0,0,-1]),b=intersectRay ground (ray ([-4550,y,100000]*factor) [0,0,-1])
  bNeed (a!=undefined and b!=undefined) "Mountain fixture points missed"
  bPath lab #(a.pos,b.pos)
  local count=(cplUIState lab.physicsDocument)[6],poses=cplPendingRows lab.physicsDocument
  (dotNetClass "System.Threading.Thread").Sleep 200;cplSynchronize lab.physicsDocument
  bNeed (cplPendingRows lab.physicsDocument!=poses) "Mountain animation waits for Finish"
  local c=intersectRay ground (ray ([-2000,y,100000]*factor) [0,0,-1]),d=intersectRay ground (ray ([-1550,y,100000]*factor) [0,0,-1])
  bPath lab #(c.pos,d.pos)
  bNeed ((cplUIState lab.physicsDocument)[6]>count) "Mountain continuous brushing stalled"
  count=(cplUIState lab.physicsDocument)[6]
  bNeed (cplPrivatePaintPath lab.physicsDocument #([50000,50000,0]*factor,[51000,50000,0]*factor) false==0) "Outside mountain hit"
  cplSynchronize lab.physicsDocument;bNeed ((cplUIState lab.physicsDocument)[6]==count) "Outside mountain emitted"
  lab.brushHeader.finishButton.pressed()
  local until=timeStamp()+35000
  while (cplUIState lab.physicsDocument)[2] and not (cplUIState lab.physicsDocument)[4] and timeStamp()<until do (cplTick lab.physicsDocument 4;bPump 10)
  if (cplUIState lab.physicsDocument)[2] do
  (
   bNeed ((cplUIState lab.physicsDocument)[4]) ("Mountain Finish did not reach a bound "+cplStats lab.physicsDocument)
   timeoutCount+=1;lab.brushHeader.keepButton.pressed();bWait lab
  )
  local colliders=cplColliderNodes lab.physicsDocument
  bNeed (colliders.count==1 and classOf colliders[1].baseObject==Editable_Poly) "Mountain batch is not one Editable Poly"
  bNeed ((cplUIState lab.physicsDocument)[5]==0) "Mountain procedural rows not retired"
  local output=colliders[1],faces=getNumFaces (snapshotAsMesh output),transform=output.transform
  bNeed (output.material.materialList[1]!=undefined) "Mountain batch has empty material slot"
  lab.collisionUI.selectQuality (if quality==2 then 1 else 3)
  lab.startBrush();bNeed ((cplUIState lab.physicsDocument)[1]) ("Quality change blocked new mountain session "+lab.uiError)
  bNeed (getNumFaces (snapshotAsMesh output)==faces and output.transform==transform) "Quality changed baked mountain output"
  bPath lab #(c.pos,d.pos);lab.stopBrush()
  bWrite (kind+"-stats.json") (cplStats lab.physicsDocument)
  bWrite (kind+"-collision.json") (cplCollisionDisplayInfo lab.physicsDocument)
  hide lab;caseCount+=1
 )
 local ready=CyrusPhysicsLab name:"PhysicsLab_Brush_Ready_020"
 ready.pos=[0,0,1400]*factor;ready.viewportIconSize=2;ready.setReceiver ground
 for model in models do ready.addSource model
 ready.brushRadius=.25;ready.birthSpacing=1.5;ready.emissionHeight=.6
 for i=1 to 3 do cplSetSourceOptions ready.physicsDocument i 2 16 1
 bShow ready;ready.refreshBindings()
 bNeed (saveMaxFile (CPLTestDir+"PhysicsLab-0.2.0-Mountain-Test.max") quiet:true) "Mountain test scene save failed"
 bWrite "mountain-count.txt" ((caseCount as string)+" cases; "+(timeoutCount as string)+" settle timeouts; "+(BChecks as string)+" cumulative assertions")
)
