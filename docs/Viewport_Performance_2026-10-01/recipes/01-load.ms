(
 if not (loadMaxFile (CVDir+"SaveSelect 2 - viewport test.max") quiet:true useFileUnits:true) do throw "Scene load failed"
 global CVControllers=for n in objects where classof n.baseObject==AminScatterObject collect n
 global CVAnalyzers=for n in objects where classof n.baseObject==CyrusSurfaceAnalyzer collect n
 if CVControllers.count==0 do throw "No Cyrus Scatter controllers loaded"
 global CVOriginalView=viewport.getTM()
 global CVOriginalType=viewport.getType()
 global CVOriginalSelection=selection as array
 local data=#(#("scene",maxFilePath+maxFileName),#("max_version",maxVersion()),#("renderer",classof renderers.current as string),#("object_count",objects.count),#("viewport_type",CVOriginalType as string),#("viewport_tm",CVOriginalView as string),#("viewport_size",#(gw.getWinSizeX(),gw.getWinSizeY())),#("viewport_count",viewport.numViews),#("active_viewport",viewport.activeViewport),#("view_level",viewport.GetRenderLevel() as string),#("dirty",getSaveRequired()))
 CSPWriteText (CVDir+"scene.json") (CSPObject data)
 local report=createFile (CVDir+"scene-details.txt")
 format "Registered callbacks:\n" to:report
 showRegisteredRedrawViewsCallbacks to:report
 for n in CVControllers do (
  format "\nSCATTER % handle % modifiers % hidden %\n" n.name n.handle (for m in n.modifiers collect classof m) n.isHidden to:report
  CSPWriteText (CVDir+"settings-"+(n.handle as string)+".json") (CSPSettings n)
  for i=1 to n.layerObjects.count do (
   local l=n.layerObjects[i],s=l.cacheSnapshot()
   format "Layer % % enabled=% mode=% proxy=% generated=% shown=% faces=% builds=% last_ms=% dirty=% error=% radii=% sources=% centers=%\n" i n.layerNames[i] n.layerEnabled[i] l.viewportMode l.proxyShape s[5] s[2] (try(cyrusPreviewFaces s[1])catch(-1)) s[6] s[7] s[3] s[4] (l.radiusDisplayCount()) (for x in l.sources collect x.name) l.showCenters to:report
  )
 )
 for n in CVAnalyzers do format "ANALYZER % runs=% enabled=% boundary=% paths=% street=% points=% point_count=%\n" n.name (n.getAnalysisRuns()) n.cyrusEnabled n.showBoundary n.showPaths n.showStreet n.showPoints n.samplePoints.count to:report
 format "\nViewport properties and interfaces:\n" to:report
 showProperties viewport to:report
 showInterface NitrousGraphicsManager to:report
 close report
 local bitmap=gw.getViewportDib()
 bitmap.filename=CVDir+"initial-viewport.png"
 save bitmap;close bitmap
)
