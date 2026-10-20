fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/bake-020-fixtures/helpers.ms"
cplResetScene()
bNeed (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-bake-020-installed-02/PhysicsLab-0.2.0-Mountain-Test.max" quiet:true useFileUnits:true) "Final matrix scene failed to open"
(
 local ready=getNodeByName "PhysicsLab_Brush_Ready_020",ground=getNodeByName "Plane001"
 for node in objects where getUserProp node "CyrusPhysicsLabBodies"!=undefined do hide node
 bShow ready
 local factor=(units.decodeValue "1m")/100.0
 local a=intersectRay ground (ray ([-5000,-5000,100000]*factor) [0,0,-1]),b=intersectRay ground (ray ([0,-5000,100000]*factor) [0,0,-1])
 bNeed (ready.sourceNodes.count==3 and a!=undefined and b!=undefined) "Mixed fixture is incomplete"
 ready.startBrush();bNeed ((cplUIState ready.physicsDocument)[1]) ("Mixed Start failed "+ready.uiError)
 bPath ready #(a.pos,b.pos)
 ready.brushHeader.keepButton.pressed();bWait ready
 local batches=cplColliderNodes ready.physicsDocument
 bNeed (batches.count==1 and classOf batches[1].baseObject==Editable_Poly) "Mixed batch did not bake"
 local mesh=snapshotAsMesh batches[1],ids=#(),faces=getNumFaces mesh,first=getVert mesh 1
 for face=1 to faces do appendIfUnique ids (getFaceMatID mesh face)
 bNeed (findItem ids 1>0 and findItem ids 2>0 and findItem ids 3>0) "Mixed batch lost a source/material ID"
 for slot=1 to 3 do bNeed (batches[1].material.materialList[slot]!=undefined) "Mixed material slot is empty"
 for slot=1 to 3 do cplSetSourceOptions ready.physicsDocument slot 0 16 1
 ready.startBrush();bNeed ((cplUIState ready.physicsDocument)[1]) "Cold reopened quality change blocked new strokes"
 bPath ready #(a.pos,b.pos);ready.stopBrush()
 bNeed (getNumFaces (snapshotAsMesh batches[1])==faces and getVert (snapshotAsMesh batches[1]) 1==first) "Mixed quality change altered baked output"
 for slot=1 to 3 do cplSetSourceOptions ready.physicsDocument slot 2 16 1
 ready.refreshBindings();bShow ready
 bNeed (saveMaxFile (CPLTestDir+"PhysicsLab-0.2.0-Mountain-Test.max") quiet:true) "Final artist scene save failed"
 bWrite "mixed-count.txt" (BChecks as string)
 bWrite "mixed-material-ids.txt" (ids as string)
 bWrite "mixed-stats.json" (cplStats ready.physicsDocument)
)
cplResetScene()
bNeed (loadMaxFile (CPLTestDir+"PhysicsLab-0.2.0-Mountain-Test.max") quiet:true useFileUnits:true) "Artist scene cold reopen failed"
(
 local ready=getNodeByName "PhysicsLab_Brush_Ready_020",ground=getNodeByName "Plane001",factor=(units.decodeValue "1m")/100.0
 bNeed (ready.sourceNodes.count==3 and (cplColliderNodes ready.physicsDocument).count==1) "Artist scene bindings failed after save"
 for i=1 to 3 do bNeed ((cplSourceOptions ready.physicsDocument i)[1] and (cplSourceOptions ready.physicsDocument i)[2]==2) "Artist scene palette/options lost"
 bShow ready;ready.startBrush();bNeed ((cplUIState ready.physicsDocument)[1]) "Artist scene cold brush failed"
 local hit=intersectRay ground (ray ([5000,-5000,100000]*factor) [0,0,-1])
 bPath ready #(hit.pos);ready.stopBrush()
 bNeed ((cplColliderNodes ready.physicsDocument).count==1) "Cold brush cancel damaged artist scene"
 bWrite "artist-reopen-count.txt" (BChecks as string)
)
