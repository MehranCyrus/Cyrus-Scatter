try (
 global CVBCallbacks,CVBRunCase,CVBWrite,CVBRestoreCallbacks,CVBCounts
 global CVSavedDisplay=for n in CVControllers collect #(n,n.viewportMode,n.proxyShape,n.viewportInstances,n.viewportFaces,n.previewBudget,n.pointsPerPlant,n.updateMode,for l in n.layerObjects collect l.showCenters)
 global CVViewSettings=NitrousGraphicsManager.GetActiveViewportSetting()
 global CVNeverDegrade=CVViewSettings.AdaptiveDegradeNeverDegradeGeometry
 CVViewSettings.AdaptiveDegradeNeverDegradeGeometry=true
 CSPWriteText (CVDir+"viewport-conditions.json") (CSPObject #(#("original_never_degrade_geometry",CVNeverDegrade),#("test_never_degrade_geometry",CVViewSettings.AdaptiveDegradeNeverDegradeGeometry),#("statistics_visible_in_screenshot",true),#("progressive_rendering",CVViewSettings.ProgressiveRenderingEnabled),#("nitrous_enabled",NitrousGraphicsManager.IsEnabled()),#("nitrous_api",NitrousGraphicsManager.API()),#("edged_faces",CVViewSettings.ShowEdgedFacesEnabled),#("visual_style",CVViewSettings.VisualStyleMode as string),#("active_viewport",viewport.activeViewport)))
 CSPStart CVControllers[1] (CVDir+"resources") "0.60-viewport-investigation" "Corona 15 idle" "navigation_ablation" "idle" true traceEdits:false recordFPS:false
 makeDir (CVDir+"matrix")
 CVBFrameRows=#();CVBCaseRows=#()
 for r=1 to 3 do (
  local order=if r==2 then #(4,3,2,1,5) else #(1,2,3,4,5)
  for mode in order do (
   local label=case mode of (1:"original_realtime";2:"original_manual";3:"scatter_callback_off";4:"analyzer_callback_off";5:"both_callbacks_off")
   for n in CVControllers do (
    local value=if mode==2 then 1 else 2
    if n.updateMode!=value do (n.updateMode=value;n.refreshDisplay())
   )
   CVBCallbacks scatter:(mode!=3 and mode!=5) analyzer:(mode!=4 and mode!=5)
   CSPMark ("BEGIN "+label+" repeat "+(r as string))
   CVBRunCase label frames:60 warmup:8 repeat:r
   CVBWrite (CVDir+"matrix")
   CSPObserve label
   CSPWriteText (CVDir+"progress.txt") (label+" repeat "+(r as string)+" complete")
  )
 )
 CSPStop "navigation_matrix_complete"
 CVBRestoreCallbacks()
 viewport.setTM CVOriginalView
 redrawViews()
)catch(
 try(CVBRestoreCallbacks())catch()
 try(CSPStop "error")catch()
 CSPWriteText (CVDir+"matrix-error.txt") ((getCurrentException())+"\n"+(getCurrentExceptionStackTrace()))
)
