-- A failed calculation after a valid import retains the complete prior publication.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-recipes0825-*/" do throw "Owned recipe host required"
 local log=createFile (MCPFixtureDir+"recipe-failure.txt")
 fn equalRows a b = (if a.count!=b.count do return false;for i=1 to a.count do (if a[i].count!=b[i].count do return false;for j=1 to a[i].count where a[i][j]!=b[i][j] do return false);true)
 fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 try (
  CyrusPerfHeadless=true;resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
  local node=AminScatterObject name:"Recipe calculation failure",root=node.baseObject,terrain=plane width:10 length:10
  root.updateMode=1;root.autoRender=false;root.newLayer();local leaf=root.selectedLayer();root.setLayerSurfaces leaf #(terrain);leaf.addPointSource();leaf.amount=100;leaf.procLayerSelfEnabled=false
  root.refreshAll();local previous=deepCopy root.groupSnapshotRows[1],epoch=root.procEpoch
  local document=CyrusRecipeCapture root #(leaf) "Failure recipe",bindings=CyrusRecipeSuggestBindings root document
  CyrusRecipeImport root document bindings
  root.layerObjects[2].meshMaskEnabled=true;root.layerObjects[2].meshMaskChannel=99
  local failed=false;try(root.refreshAll())catch(failed=true)
  verify (root.procEpoch==epoch and root.groupSnapshotRows.count==1 and equalRows root.groupSnapshotRows[1] previous) "Post-import invalid mesh channel retains all eight fields of prior publication" log
  verify (failed or leaf.previewError!="" or root.layerObjects[2].previewError!="") "Invalid successor reports failure" log
  root.layerObjects[2].meshMaskEnabled=false;root.refreshAll()
  verify (root.procEpoch==epoch+1 and root.groupSnapshotRows.count==2 and root.groupSnapshotRows[2].count==100) "Correcting the imported input publishes the complete new graph" log
  verify (not theHold.Holding()) "Failed solve does not strand an import hold" log
  format "PASSED\n" to:log
 )catch(format "FAILED: %\n" (getCurrentException()) to:log;close log;throw())
 close log
)
