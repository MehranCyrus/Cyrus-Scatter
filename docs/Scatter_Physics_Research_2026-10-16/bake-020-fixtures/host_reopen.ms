fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/bake-020-fixtures/helpers.ms"
cplResetScene()
bNeed (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-bake-020-installed-02/baked-workflow.max" quiet:true useFileUnits:true) "Baked workflow scene failed to reopen"
(
 local lab=getNodeByName "Bake_Lab_020",colliders=cplColliderNodes lab.physicsDocument
 bNeed (colliders.count==1) "Reopened baked collider lost"
 local old=colliders[1],mesh=snapshotAsMesh old,first=getVert mesh 1,faces=getNumFaces mesh
 bNeed (classOf old.baseObject==Editable_Poly) "Reopened output lost Editable Poly type"
 bNeed (old.material.materialList[1].diffuse==(color 230 90 30)) "Reopened baked material changed"
 bNeed ((cplSourceOptions lab.physicsDocument 1)[2]==2) "Reopened source quality lost"
 bNeed (cplRows lab.physicsDocument=="[]") "Reopen resurrected procedural rows"
 bShow lab;lab.startBrush();bNeed ((cplUIState lab.physicsDocument)[1]) "Reopened Detailed brush failed"
 bPath lab #([1.5,-1,0],[2,-1,0]);cplFreeze lab.physicsDocument;bWait lab
 bNeed ((cplColliderNodes lab.physicsDocument).count==2) "Direct native Freeze did not bake after reopen"
 max undo;bNeed ((cplColliderNodes lab.physicsDocument).count==1 and isValidNode old) "Reopened bake Undo damaged old batch"
 max redo;bNeed ((cplColliderNodes lab.physicsDocument).count==2) "Reopened bake Redo failed"
 bNeed (getNumFaces (snapshotAsMesh old)==faces and getVert (snapshotAsMesh old) 1==first) "Reopened old geometry changed"
 delete lab;bNeed (isValidNode old and classOf old.baseObject==Editable_Poly) "Deleting Lab deleted baked geometry"
 bWrite "reopen-count.txt" (BChecks as string)
)
cplResetScene()
bNeed (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/physics-lab-bake-020-installed-02/baked-stack.max" quiet:true useFileUnits:true) "Stack scene failed to reopen"
(
 local lab=getNodeByName "Stack_Lab_020",colliders=cplColliderNodes lab.physicsDocument
 bNeed (colliders.count==2) "Reopened stack collider count lost"
 local upper=nodeGetBoundingBox colliders[2] (matrix3 1)
 bNeed (upper[1].z>.29) "Reopened sphere is no longer on baked platform"
 bShow lab;lab.startBrush();bNeed ((cplUIState lab.physicsDocument)[1]) "Reopened static mesh cook failed"
 lab.stopBrush()
 bWrite "reopen-count.txt" (BChecks as string)
)
