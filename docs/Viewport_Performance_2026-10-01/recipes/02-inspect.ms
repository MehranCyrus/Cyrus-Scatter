(
 local report=createFile (CVDir+"scene-settled.txt")
 for n in CVControllers do (
  format "SCATTER % handle % modifiers % hidden %\n" n.name n.handle (for m in n.modifiers collect classof m) n.isHidden to:report
  CSPWriteText (CVDir+"settings-settled-"+(n.handle as string)+".json") (CSPSettings n)
  for i=1 to n.layerObjects.count do (
   local l=n.layerObjects[i],s=l.cacheSnapshot()
   format "Layer % % enabled=% mode=% proxy=% generated=% shown=% faces=% builds=% last_ms=% dirty=% error=% radii=% sources=% centers=%\n" i n.layerNames[i] n.layerEnabled[i] l.viewportMode l.proxyShape s[5] s[2] (try(cyrusPreviewFaces s[1])catch(-1)) s[6] s[7] s[3] s[4] (l.radiusDisplayCount()) (for x in l.sources collect (if isValidNode x then x.name else "empty")) l.showCenters to:report
  )
 )
 for n in CVAnalyzers do format "ANALYZER % runs=% enabled=% boundary=% paths=% street=% points=% point_count=%\n" n.name (n.getAnalysisRuns()) n.cyrusEnabled n.showBoundary n.showPaths n.showStreet n.showPoints n.samplePoints.count to:report
 format "\nViewport interfaces:\n" to:report
 try(showInterface NitrousGraphicsManager to:report)catch(format "%\n" (getCurrentException()) to:report)
 try(showProperties (NitrousGraphicsManager.GetActiveViewportSetting()) to:report)catch(format "%\n" (getCurrentException()) to:report)
 format "\nDegradation global %\nStats %\n" (try(degradeOn)catch("unavailable")) (try(viewport.GetFPS())catch("unavailable")) to:report
 close report
 local b=gw.getViewportDib();b.filename=CVDir+"initial-viewport.png";save b;close b
)
