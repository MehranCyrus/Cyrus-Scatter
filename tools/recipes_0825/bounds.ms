-- Real 256/257 native document boundary plus an exhausted aggregate byte budget.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-recipes0825-*/" do throw "Owned recipe host required"
 local log=createFile (MCPFixtureDir+"recipe-bounds.txt")
 fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 try (
  CyrusPerfHeadless=true;resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
  local node=AminScatterObject name:"Recipe bound witness",root=node.baseObject,terrain=plane width:2 length:2 widthsegs:1 lengthsegs:1
  root.updateMode=1;root.autoRender=false
  for i=1 to 3 do (
   root.newLayer();local leaf=root.selectedLayer();root.setLayerSurfaces leaf #(terrain);leaf.addPointSource()
   for j=1 to (if i==3 then 1 else 128) do (local area=root.addPaintArea leaf target:terrain;area.paintView=0)
  )
  local document=CyrusRecipeCapture root #(root.layerObjects[1],root.layerObjects[2]) "Exactly 256"
  verify ((CyrusRecipeGet (CyrusRecipeGet document "layers")[1] "areas").count==128 and (CyrusRecipeGet (CyrusRecipeGet document "layers")[2] "areas").count==128) "Exactly 256 native Paint documents capture successfully" log
  local message="";try(CyrusRecipeCapture root (root.layerObjects as array) "257 must block")catch(message=getCurrentException())
  verify (findString message "256 Paint-document"!=undefined and root.layerObjects[3].paintAreas.count==1) "257th native document rejects during capture and preserves every area" log
  local area=root.layerObjects[1].paintAreas[1],before=(cyrusBrushRecipeExport area.paintDocument)[1]
  local context=CyrusRecipeCaptureContext root:root node:node owners:#() paintBytes:67108864
  message="";try(CyrusRecipeCapturePaint context area)catch(message=getCurrentException())
  verify (findString message "64 MiB"!=undefined and context.paintDocuments==0 and (cyrusBrushRecipeExport area.paintDocument)[1]==before) "Exhausted aggregate byte budget rejects before appending or modifying native Paint" log
  verify (not theHold.Holding()) "Bounded capture leaves no stranded hold" log
  format "PASSED\n" to:log
 )catch(format "FAILED: %\n" (getCurrentException()) to:log;close log;throw())
 close log
)
