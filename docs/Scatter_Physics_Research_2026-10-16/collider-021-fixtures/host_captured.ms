fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/bake-020-fixtures/helpers.ms"
cplResetScene()
python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/docs/Scatter_Physics_Research_2026-10-16/collider-021-fixtures/load_captured.py"
(
 local ground=getNodeByName "Captured_Receiver_021",lab=getNodeByName "Captured_Lab_021",baked=getNodeByName "Captured_Baked_21_Teapots_021"
 viewport.setLayout #layout_1;viewport.setType #view_top;select ground;max zoomext sel all;bShow lab
 local before=snapshotAsMesh baked,tm=baked.transform
 for quality in #(1,3,2,3) do
 (
  cplStage ("Captured restart quality "+quality as string)
  lab.collisionUI.selectQuality quality
  lab.brushHeader.startButton.pressed();bNeed ((cplUIState lab.physicsDocument)[1]) ("Captured Start failed: "+lab.uiError)
  bPath lab #([20,80,0],[100,80,0]);bPath lab #([20,110,0],[100,110,0])
  bNeed ((cplUIState lab.physicsDocument)[6]>1) "Captured continuous brushing stalled"
  bPump 500;cplSynchronize lab.physicsDocument
  bWrite ("captured-q"+(quality as string)+"-stats.json") (cplStats lab.physicsDocument)
  lab.brushHeader.cancelButton.pressed()
  bNeed (not (cplUIState lab.physicsDocument)[2]) "Captured cancel left pending"
 )
 bNeed (isValidNode baked and baked.transform==tm and getNumFaces (snapshotAsMesh baked)==getNumFaces before) "Original baked batch was changed"
 lab.collisionUI.selectQuality 3
 bNeed (saveMaxFile (CPLTestDir+"PhysicsLab-0.2.1-Captured-Teapot-Test.max") quiet:true) "Captured test scene save failed"
 bWrite "captured-count.txt" (BChecks as string)
)
