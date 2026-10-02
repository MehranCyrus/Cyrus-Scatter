global R2ProfileDraw,R2ProfileRows=#(),R2FastDraw,R2FastHeld=false,R2ProfileHeld=false,R2Retained,R2UseFastTraversal=false
fn R2ProfileDraw = (
 local timer=CVBClockClass.StartNew(),held=if R2ProfileHeld then true else CyrusInteractionHeld()
 local marks=#(timer.Elapsed.TotalMilliseconds)
 local nodes=for n in objects where classof n.baseObject==AminScatterObject and not n.isHidden collect n
 append marks timer.Elapsed.TotalMilliseconds
 for n in nodes do (
  gw.setTransform n.objectTransform;gw.setColor #line red
  for path in n.baseObject.iconLines() do gw.polyline path false
 )
 gw.setTransform (matrix3 1);append marks timer.Elapsed.TotalMilliseconds
 local entries=#()
 for n in nodes do join entries (n.baseObject.layerEntries())
 append marks timer.Elapsed.TotalMilliseconds
 local caches=for e in entries collect e[2].previewCache interactionHeld:held
 append marks timer.Elapsed.TotalMilliseconds
 for e in entries do e[2].drawRadii()
 append marks timer.Elapsed.TotalMilliseconds
 for i=1 to entries.count do (
  local obj=entries[i][2],cache=caches[i]
  if (obj.showPoints or obj.showCenters) and cache!=undefined do aminScatterDrawPreview cache (obj.pointColorMode==1) obj.solidPointColor
 )
 append marks timer.Elapsed.TotalMilliseconds
 gw.enlargeUpdateRect #whole
 timer.Stop();append marks timer.Elapsed.TotalMilliseconds
 append R2ProfileRows #(R2ProfileHeld,marks)
)
fn R2FastDraw = (
 local held=if R2FastHeld then true else CyrusInteractionHeld()
 gw.setTransform (matrix3 1)
 for n in objects where (classof n.baseObject==AminScatterObject and not n.isHidden) do (
  local root=n.baseObject
  gw.setTransform n.objectTransform;gw.setColor #line red
  for path in root.iconLines() do gw.polyline path false
  gw.setTransform (matrix3 1)
  local entries=if held and R2UseFastTraversal then (for i=1 to root.layerObjects.count where root.cyrusEnabled and root.layerEnabled[i] collect #(i,root.layerObjects[i])) else root.layerEntries()
  for entry in entries do (
   local obj=entry[2],cache=obj.previewCache interactionHeld:held
   obj.drawRadii()
   if (not R2Retained) and (obj.showPoints or obj.showCenters) and cache!=undefined do aminScatterDrawPreview cache (obj.pointColorMode==1) obj.solidPointColor
  )
 )
 gw.enlargeUpdateRect #whole
)
(
 makeDir (CVDir+"profile");makeDir (CVDir+"matrix")
 try (
  CVBCallbacks scatter:false;CVBOriginalScatter=R2ProfileDraw
  CVBFrameRows=#();CVBCaseRows=#()
  for held in #(false,true) do (
   R2ProfileHeld=held;CVBCallbacks()
   CVBRunCase (if held then "profile_simulated_held" else "profile_normal") frames:20 warmup:4 repeat:1
  )
  CVBWrite (CVDir+"profile")
  CSPWriteText (CVDir+"profile/stages.json") (CSPObject #(#("cumulative_ms",R2ProfileRows),#("stages",#("interaction","discover","icons","layer_entries","preview_cache","radii","native_draw","update_rect"))))
  CVBFrameRows=#();CVBCaseRows=#()
  for repeat=1 to 3 do for mode in (if repeat==2 then #(7,6,5,4,3,2,1) else #(1,2,3,4,5,6,7)) do (
   CVBCallbacks scatter:false
   R2Retained=(mode==4 or mode==5)
   for n in R2Nodes do n.isHidden=not R2Retained
   R2FastHeld=(mode==3 or mode==5 or mode==7)
   R2UseFastTraversal=(mode==3 or mode==5)
   CVBOriginalScatter=case mode of (1: R2ProductionDraw; 2: R2RetainedDraw; default: R2FastDraw)
   -- Mode 2 is the normal script plumbing without native triangle submission.
   if mode==2 do R2Retained=true
   CVBCallbacks scatter:(mode!=6)
   local label=(#("candidate_061","script_without_triangles","fast_simulated_held","retained_with_plumbing","retained_fast_simulated_held","scatter_callback_off","legacy_traversal_simulated_held"))[mode]
   CSPWriteText (CVDir+"progress.txt") (label+" repeat "+(repeat as string))
   CVBRunCase label frames:60 warmup:8 repeat:repeat
   CVBWrite (CVDir+"matrix")
  )
  CVBCallbacks scatter:false;CVBOriginalScatter=R2ProductionDraw;CVBRestoreCallbacks()
  R2Retained=false;for n in R2Nodes do n.isHidden=true
  viewport.setTM CVOriginalView;redrawViews()
  CSPWriteText (CVDir+"matrix-complete.txt") "Profile and seven-condition matrix complete. 0.61 restored."
 )catch(
  CVBCallbacks scatter:false;CVBOriginalScatter=R2ProductionDraw;CVBRestoreCallbacks()
  R2Retained=false;for n in R2Nodes where isValidNode n do n.isHidden=true
  throw()
 )
)
