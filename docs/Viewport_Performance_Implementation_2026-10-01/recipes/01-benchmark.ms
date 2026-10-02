global VPProductionDraw=AminScatterObjectDraw,VPDoubleCacheDraw
fn VPDoubleCacheDraw = (
 gw.setTransform (matrix3 1)
 for n in objects where (classof n.baseObject==AminScatterObject and not n.isHidden) do (
  gw.setTransform n.objectTransform;gw.setColor #line red
  for path in n.baseObject.iconLines() do gw.polyline path false
  gw.setTransform (matrix3 1)
  for entry in n.baseObject.layerEntries() do (
   local obj=entry[2]
   obj.previewCache();obj.drawRadii()
   if obj.showPoints or obj.showCenters do (
    local cache=obj.previewCache()
    if cache!=undefined do aminScatterDrawPreview cache (obj.pointColorMode==1) obj.solidPointColor
   )
  )
 )
 gw.enlargeUpdateRect #whole
)
try (
 makeDir (CVDir+"matrix")
 CVBFrameRows=#();CVBCaseRows=#()
 viewport.setTM CVOriginalView
 CSPWriteText (CVDir+"conditions.json") (CSPObject #(#("viewport_size",#(gw.getWinSizeX(),gw.getWinSizeY())),#("viewport_count",viewport.numViews),#("visual_style",CVViewSettings.VisualStyleMode as string),#("edged_faces",CVViewSettings.ShowEdgedFacesEnabled),#("never_degrade",CVViewSettings.AdaptiveDegradeNeverDegradeGeometry),#("baseline_scope","Same native binary and 0.61 script; batch drawing switch selects the preserved 0.60 native loop. Duplicate-cache control restores old callback ordering only.")))
 for r=1 to 3 do (
  local order=if r==2 then #(5,4,3,2,1) else #(1,2,3,4,5)
  for mode in order do (
   unRegisterRedrawViewsCallback VPDoubleCacheDraw
   CVBRestoreCallbacks()
   unRegisterRedrawViewsCallback VPProductionDraw
   CVBOriginalScatter=if mode==3 then VPDoubleCacheDraw else VPProductionDraw
   cyrusPreviewBatchDrawing (mode!=1)
   for n in CVControllers do (
    local value=if mode==4 then 1 else 2
    if n.updateMode!=value do (n.updateMode=value;n.refreshDisplay())
   )
   local label=(#("legacy_native_061_script","candidate_realtime","candidate_duplicate_cache_control","candidate_manual","scatter_callback_off"))[mode]
   CVBCallbacks scatter:(mode!=5)
   CVBRunCase label frames:60 warmup:8 repeat:r
   CVBWrite (CVDir+"matrix")
   CSPWriteText (CVDir+"progress.txt") (label+" repeat "+(r as string))
  )
 )
 CVBRestoreCallbacks();unRegisterRedrawViewsCallback VPDoubleCacheDraw
 CVBOriginalScatter=VPProductionDraw;CVBRestoreCallbacks();cyrusPreviewBatchDrawing true
 for n in CVControllers do (n.updateMode=2;n.refreshDisplay())
 viewport.setTM CVOriginalView;redrawViews()
 CSPWriteText (CVDir+"benchmark-complete.txt") "Three repeats complete; candidate drawing restored."
)catch(
 try(CVBRestoreCallbacks())catch();try(unRegisterRedrawViewsCallback VPDoubleCacheDraw)catch()
 CVBOriginalScatter=VPProductionDraw;CVBRestoreCallbacks();cyrusPreviewBatchDrawing true
 throw()
)
