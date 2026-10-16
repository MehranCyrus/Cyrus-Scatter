(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"copy-rollback-"+(timeStamp() as string)+".txt")
 fn check v label log = (format "%: %\n" (if v then "PASS" else "FAIL") label to:log;flush log;if not v do throw label)
 global VariationOriginalCopy
 try (
  if theHold.Holding() do theHold.Cancel()
  loadMaxFile (MCPFixtureDir+"variation-core.max") quiet:true useFileUnits:true
  local root=(getNodeByName "Variation qualification").baseObject,leaf=root.layerObjects[1]
  root.updateMode=1;root.refreshAll()
  local count=root.layerObjects.count,nextKey=root.nextEditLayerKey,oldID=leaf.layerID,oldPaint=(cyrusBrushRecipeExport leaf.paintAreas[1].paintDocument)[1],epoch=root.procEpoch
  local failed=false
  try(root.copyLogicalLayer leaf variation:#unsupported)catch(failed=true)
  check (failed and root.layerObjects.count==count and root.nextEditLayerKey==nextKey) "Unknown policy rejects before mutation" log
  local radiusIDs=leaf.procRadiusIDs as array
  leaf.procRadiusIDs=#("owned-probe");failed=false
  try(root.copyLogicalLayer leaf)catch(failed=true)
  check (failed and root.layerObjects.count==count and leaf.procRadiusIDs.count==1) "Unsupported authored radius copy rejects without discarding source data" log
  leaf.procRadiusIDs=radiusIDs
  VariationOriginalCopy=AminScatterCopyLayer
  fn AminScatterCopyLayer origin destination variation:#same = (
   VariationOriginalCopy origin destination variation:variation
   throw "Owned fixture failure after copied owner, settings and Paint"
  )
  failed=false;try(root.copyLogicalLayer leaf variation:#new)catch(failed=true)
  AminScatterCopyLayer=VariationOriginalCopy;VariationOriginalCopy=undefined
  check (failed and root.layerObjects.count==count and root.nextEditLayerKey==nextKey and leaf.layerID==oldID) "Post-mutation failure rolls back complete owner transaction" log
  check (root.procEpoch==epoch and (cyrusBrushRecipeExport leaf.paintAreas[1].paintDocument)[1]==oldPaint) "Failed copy retains publication and original Paint" log
  check (not theHold.Holding() and not CyrusPointSuspended) "Failure restores hold and display suspension" log
  local copied=root.copyLogicalLayer leaf variation:#same
  check (root.layerObjects.count==count+1) "Ordinary copy succeeds after rollback" log
  max undo;check (root.layerObjects.count==count) "Recovered copy remains one Undo" log
  format "PASS: complete\n" to:log;close log
 )catch(
  if VariationOriginalCopy!=undefined do (AminScatterCopyLayer=VariationOriginalCopy;VariationOriginalCopy=undefined)
  format "ERROR: %\n" (getCurrentException()) to:log;close log;throw()
 )
)
