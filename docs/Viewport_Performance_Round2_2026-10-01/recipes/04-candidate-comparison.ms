global R2LegacyDraw=R2ProductionDraw,R2CandidateDraw,R2RealInteraction,R2AlwaysHeld
fn R2AlwaysHeld = true
(
 try (
  CVBCallbacks scatter:false analyzer:false
  fileIn "F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/scripts/AminScatterObject.ms"
  if not (loadMaxFile (CVDir+"round2-test.max") quiet:true useFileUnits:true) do throw "Candidate test scene reload failed"
  R2Nodes=#();R2Probes=#();gc()
  CVControllers=for n in objects where classof n.baseObject==AminScatterObject collect n
  CVAnalyzers=for n in objects where classof n.baseObject==CyrusSurfaceAnalyzer collect n
  CVBControllers=CVControllers;CVBAnalyzers=CVAnalyzers
  viewport.setTM CVOriginalView
  CVViewSettings=NitrousGraphicsManager.GetActiveViewportSetting()
  CVViewSettings.AdaptiveDegradeNeverDegradeGeometry=true
  for n in CVControllers do n.refreshDisplay()
  R2CandidateDraw=AminScatterObjectDraw;R2RealInteraction=CyrusInteractionHeld
  unRegisterRedrawViewsCallback R2CandidateDraw
  CVBOriginalScatter=R2CandidateDraw
  CVBFrameRows=#();CVBCaseRows=#();makeDir (CVDir+"candidate-matrix")
  for repeat=1 to 3 do for mode in (if repeat==2 then #(4,3,2,1) else #(1,2,3,4)) do (
   CVBCallbacks scatter:false
   CVBOriginalScatter=if mod mode 2==1 then R2LegacyDraw else R2CandidateDraw
   CyrusInteractionHeld=if mode>2 then R2AlwaysHeld else R2RealInteraction
   local label=(#("061_normal","062_normal","061_simulated_held","062_simulated_held"))[mode]
   CSPWriteText (CVDir+"progress.txt") (label+" repeat "+(repeat as string))
   CVBCallbacks();CVBRunCase label frames:60 warmup:8 repeat:repeat
   CVBWrite (CVDir+"candidate-matrix")
  )
  for which in #(1,2) do (
   CVBCallbacks scatter:false
   CVBOriginalScatter=if which==1 then R2LegacyDraw else R2CandidateDraw
   CyrusInteractionHeld=R2AlwaysHeld;CVBRestoreCallbacks();viewport.setTM CVOriginalView
   for j=1 to 5 do (redrawViews();windows.processPostedMessages())
   local bitmap=gw.getViewportDib();bitmap.filename=CVDir+"images/held-"+(if which==1 then "061" else "062")+".png";save bitmap;close bitmap
  )
  CVBCallbacks scatter:false;CyrusInteractionHeld=R2RealInteraction
  CVBOriginalScatter=R2CandidateDraw;CVBRestoreCallbacks();viewport.setTM CVOriginalView;redrawViews()
  CSPWriteText (CVDir+"candidate-complete.json") (CSPObject #(#("counts",CVBCounts()),#("node_count",objects.count),#("viewport_size",#(gw.getWinSizeX(),gw.getWinSizeY())),#("scope","0.61 and 0.62 callbacks on the same 0.62 class; simulated held conditions override the interaction predicate equally. No actual mouse input in this matrix.")))
 )catch(
  try(CVBCallbacks scatter:false)catch()
  if R2RealInteraction!=undefined do CyrusInteractionHeld=R2RealInteraction
  if R2CandidateDraw!=undefined then CVBOriginalScatter=R2CandidateDraw else CVBOriginalScatter=R2LegacyDraw
  CVBRestoreCallbacks();throw()
 )
)
