try (
 makeDir (CVDir+"display-matrix")
 CVBFrameRows=#();CVBCaseRows=#()
 CVBCallbacks()
 global CVDisplayConfigs=#(#("pyramid_2000",2,3,2000,500000,false),#("pyramid_1000",2,3,1000,500000,false),#("pyramid_500",2,3,500,500000,false),#("pyramid_250",2,3,250,500000,false),#("pyramid_100",2,3,100,500000,false),#("box_2000",2,1,2000,500000,false),#("pointcloud_500k",1,3,2000,500000,false),#("pointcloud_50k",1,3,2000,50000,false),#("pointcloud_10k",1,3,2000,10000,false),#("centers_all",1,3,2000,500000,true))
 for cfg in CVDisplayConfigs do (
  for n in CVControllers do (
   n.updateMode=1;n.viewportMode=cfg[2];n.proxyShape=cfg[3];n.viewportInstances=cfg[4];n.previewBudget=cfg[5]
   for l in n.layerObjects do l.showCenters=cfg[6]
   n.refreshDisplay()
  )
  for r=1 to 3 do CVBRunCase cfg[1] frames:40 warmup:6 repeat:r
  CVBWrite (CVDir+"display-matrix")
  CSPWriteText (CVDir+"progress.txt") (cfg[1]+" display trial complete")
 )
 for state in CVSavedDisplay do (
  local n=state[1]
  n.viewportMode=state[2];n.proxyShape=state[3];n.viewportInstances=state[4];n.viewportFaces=state[5];n.previewBudget=state[6];n.pointsPerPlant=state[7];n.updateMode=state[8]
  for i=1 to n.layerObjects.count do n.layerObjects[i].showCenters=state[9][i]
  n.refreshDisplay()
 )
 CVBRestoreCallbacks();viewport.setTM CVOriginalView;redrawViews()
)catch(
 try(CVBRestoreCallbacks())catch()
 CSPWriteText (CVDir+"display-error.txt") ((getCurrentException())+"\n"+(getCurrentExceptionStackTrace()))
)
