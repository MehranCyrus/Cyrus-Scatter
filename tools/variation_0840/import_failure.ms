-- Late Paint failures must roll back the new graph and preserve the old result.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"import-failure-"+(timeStamp() as string)+".txt")
 fn check v label log = (format "%: %\n" (if v then "PASS" else "FAIL") label to:log;flush log;if not v do throw label)
 fn equalRows a b = (if a.count!=b.count do return false;for i=1 to a.count do for j=1 to 8 where a[i][j]!=b[i][j] do return false;true)
 global VariationRestorePaint
 try (
  if theHold.Holding() do theHold.Cancel()
  CyrusPerfHeadless=true
  loadMaxFile (MCPFixtureDir+"variation-core.max") quiet:true useFileUnits:true
  local root=(getNodeByName "Variation qualification").baseObject,leaf=root.layerObjects[1]
  root.updateMode=1;root.refreshAll()
  local doc=CyrusRecipeCapture root #(leaf) "Paint failure",bindings=CyrusRecipeSuggestBindings root doc
  local count=root.layerObjects.count,key=root.nextEditLayerKey,epoch=root.procEpoch,rows=deepCopy root.groupSnapshotRows[1]
  local paint=(cyrusBrushRecipeExport leaf.paintAreas[1].paintDocument)[1],receiver=leaf.paintAreas[1].areaTarget
  local incompatible=copy receiver;incompatible.width*=1.2
  local bad=for pair in bindings collect #(pair[1],if pair[2]==receiver then incompatible else pair[2])
  for policy in #(#same,#new) do (
   local failed=false
   try(CyrusRecipeImport root doc bad variation:policy)catch(failed=true)
   check (failed and root.layerObjects.count==count and root.nextEditLayerKey==key) "Incompatible Paint terrain rejects import and restores graph" log
   check (root.procEpoch==epoch and equalRows rows root.groupSnapshotRows[1] and (cyrusBrushRecipeExport leaf.paintAreas[1].paintDocument)[1]==paint) "Rejected Paint binding preserves full publication and authored coverage" log
  )
  VariationRestorePaint=CyrusRecipeRestorePaint
  fn CyrusRecipeRestorePaint data target document = (
   local restored=VariationRestorePaint data target document
   if data!=undefined do throw "Owned late failure after native Paint restoration"
   restored
  )
  for newSetup in #(false,true) do (
   local nodesBefore=objects.count,failed=false
   try(CyrusRecipeImport root doc bindings newSetup:newSetup variation:#same)catch(failed=true)
   check (failed and objects.count==nodesBefore and root.layerObjects.count==count and root.nextEditLayerKey==key) "Late Add/New setup failure removes newly created graph" log
   check (root.procEpoch==epoch and equalRows rows root.groupSnapshotRows[1]) "Late import failure retains previous complete publication" log
   check (not theHold.Holding() and not CyrusPointSuspended) "Late import failure restores hold and display suspension" log
  )
  CyrusRecipeRestorePaint=VariationRestorePaint;VariationRestorePaint=undefined
  local result=CyrusRecipeImport root doc bindings variation:#same
  root.refreshAll();check (equalRows rows root.groupSnapshotRows[count+1]) "Import recovers after late failure with identical saved variation" log
  max undo;check (root.layerObjects.count==count) "Recovered import remains one Undo" log
  CyrusPerfHeadless=false;format "PASS: complete\n" to:log;close log
 )catch(
  if VariationRestorePaint!=undefined do (CyrusRecipeRestorePaint=VariationRestorePaint;VariationRestorePaint=undefined)
  format "ERROR: %\n" (getCurrentException()) to:log;close log;throw()
 )
)
