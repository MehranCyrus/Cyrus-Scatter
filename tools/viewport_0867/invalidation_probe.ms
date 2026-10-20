(
 local output=createFile (MCPFixtureDir+"invalidation-probe.txt")
 try(
  for channel in #(2,99,2) do (
   TMaterials.materialList[1].opacityMap.coords.mapChannel=channel
   format "CHANNEL % KEY %\n" channel (cyrusMaterialPreviewKey #(TSource)) to:output
   try(cyrusTexturePreview TLayer.cachedPoints #(TSource);format "DIRECT OK\n" to:output)catch(format "DIRECT FAIL %\n" (getCurrentException()) to:output)
   TRoot.refreshDisplay();redrawViews();completeRedraw()
   format "LAYER % ROOT % POINT % DETAIL % COUNT %\n" TLayer.previewError TRoot.previewError CyrusPointLastError CyrusPointDetailStatus TRoot.groupSnapshotRows[1].count to:output
  )
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
