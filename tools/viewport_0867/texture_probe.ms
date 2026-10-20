(
 if not matchPattern MCPFixtureDir pattern:"*/viewport0867-test*-2027/" do throw "Owned viewport host required"
 local output=createFile (MCPFixtureDir+"texture-probe.txt")
 try(
  VSource.mapcoords=true
  VRoot.refreshAll();VRoot.evaluateProcedural()
  VSource.material.diffuseMap=checker color1:red color2:blue
  VSource.material.diffuseMap.coords.mapChannel=1
  VRoot.refreshDisplay()
  redrawViews();completeRedraw()
  format "DISPLAY ERROR % POINT % DETAIL %\n" VLayer.previewError CyrusPointLastError CyrusPointDetailStatus to:output
  local image=gw.getViewportDib();image.filename=MCPFixtureDir+"texture-probe.png";save image;close image
  local previewOwner=CyrusPointOwner VController
  format "STATS %\n" (cyrusRetainedViewportStats previewOwner) to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
