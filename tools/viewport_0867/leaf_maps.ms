(
 local output=createFile (MCPFixtureDir+"leaf-maps.txt")
 try(
  format "KEY %\nSTATUS % % %\n" (cyrusMaterialPreviewKey #(LSource)) LRoot.procEpoch LLayer.previewError CyrusPointDetailStatus to:output
  for m in #(LMaterial,LForest,LBase,LMaterial.texmapOpacity) do (
   format "\nCLASS % ID %\n" (classof m) m.classID to:output
   showProperties m to:output
  )
  for pair in #(#(LForest,"forest"),#(LBase,"frontback"),#(LMaterial.texmapOpacity,"opacity")) do (
   local image=renderMap pair[1] size:[256,256]
   image.filename=MCPFixtureDir+"leaf-map-"+pair[2]+".png";save image;close image
  )
  LCC.map=LBase;LForest.mapbase=LCC;LCC.hueShift=120;LCC.saturation=70;LCC.brightness=15
  LRoot.refreshDisplay();redrawViews();completeRedraw()
  local image=gw.getViewportDib();image.filename=MCPFixtureDir+"real-leaves-correction-base.png";save image;close image
  format "AFTER % %\n" LLayer.previewError CyrusPointDetailStatus to:output
 )catch(format "ERROR %\n" (getCurrentException()) to:output)
 close output
)
