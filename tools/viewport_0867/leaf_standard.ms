(
 local output=createFile (MCPFixtureDir+"leaf-standard.txt")
 try(
  format "CORONA % % % % % % % %\n" LMaterial.levelDiffuse LMaterial.colorDiffuse LMaterial.mapamountDiffuse LMaterial.texmapOnDiffuse LMaterial.levelOpacity LMaterial.colorOpacity LMaterial.mapamountOpacity LMaterial.texmapOnOpacity to:output
  local mat=standardMaterial diffuseMap:LCC opacityMap:LMaterial.texmapOpacity twoSided:true
  LSource.material=mat;LRoot.refreshDisplay();redrawViews();completeRedraw()
  local image=gw.getViewportDib();image.filename=MCPFixtureDir+"real-leaves-standard.png";save image;close image
  format "STANDARD % %\n" LLayer.previewError CyrusPointDetailStatus to:output
  LSource.material=LMaterial
 )catch(format "ERROR %\n" (getCurrentException()) to:output)
 close output
)
