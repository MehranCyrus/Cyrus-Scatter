global CVAnalyzerNoFlush
fn CVAnalyzerNoFlush = (
 local c=CVBClockClass.StartNew()
 gw.setTransform (matrix3 1)
 for n in objects where classOf n==CyrusSurfaceAnalyzer and not n.isHidden do (
  local o=n.baseObject
  gw.setTransform n.objectTransform;gw.setColor #line red
  for path in o.iconLines() do gw.polyline path false
  gw.setTransform (matrix3 1)
  if o.cyrusEnabled and o.showBoundary do (
   gw.setColor #line (color 235 95 65)
   for line in o.boundaryOutput() where line.count>1 do gw.polyline line o.includeStreetBoundary
  )
  if o.cyrusEnabled and o.showPaths do (
   gw.setColor #line (color 150 220 70)
   for line in (o.packedLines o.pathVertices o.pathCounts) where line.count>1 do gw.polyline line false
  )
  if o.cyrusEnabled and o.showStreet do (
   gw.setColor #line (color 255 40 40)
   for line in (o.packedLines o.streetVertices o.streetCounts) where line.count>1 do gw.polyline line false
  )
  if o.cyrusEnabled and o.showPoints do (for p in o.samplePoints do gw.marker p #hollowBox color:(color 40 190 245))
 )
 gw.enlargeUpdateRect #whole
 c.Stop();CVBAnalyzerMS+=c.Elapsed.TotalMilliseconds;CVBAnalyzerCalls+=1
)
try (
 makeDir (CVDir+"analyzer-flush")
 CVBFrameRows=#();CVBCaseRows=#()
 for r=1 to 3 do (
  CVBCallbacks()
  CVBRunCase "original_callbacks" frames:40 warmup:6 repeat:r
  CVBCallbacks analyzer:false
  registerRedrawViewsCallback CVAnalyzerNoFlush
  CVBRunCase "analyzer_without_updateScreen" frames:40 warmup:6 repeat:r
  unRegisterRedrawViewsCallback CVAnalyzerNoFlush
  CVBCallbacks scatter:false analyzer:false
  registerRedrawViewsCallback CVAnalyzerNoFlush
  CVBRunCase "analyzer_without_updateScreen_scatter_off" frames:40 warmup:6 repeat:r
  unRegisterRedrawViewsCallback CVAnalyzerNoFlush
  CVBWrite (CVDir+"analyzer-flush")
 )
 CVBRestoreCallbacks();viewport.setTM CVOriginalView;redrawViews()
)catch(
 try(unRegisterRedrawViewsCallback CVAnalyzerNoFlush;CVBRestoreCallbacks())catch()
 CSPWriteText (CVDir+"analyzer-flush-error.txt") ((getCurrentException())+"\n"+(getCurrentExceptionStackTrace()))
)
