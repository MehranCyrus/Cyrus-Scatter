-- External container contract, unit-normalized static settings and guarded data.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-recipes0825-*/" do throw "Owned recipe host required"
 local log=createFile (MCPFixtureDir+"recipe-bindings.txt")
 fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 try (
  CyrusPerfHeadless=true;resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
  local node=AminScatterObject name:"Recipe binding source",root=node.baseObject,terrain=plane name:"Binding terrain" width:10 length:10,model=pyramid name:"Container model",other=box name:"Other container model"
  root.updateMode=1;root.autoRender=false;root.newLayer();local leaf=root.selectedLayer();root.setLayerSurfaces leaf #(terrain)
  leaf.sources=#(model);leaf.ensureSourceRows();leaf.amount=80;leaf.sourceZOffsetsWU=#(0.25);leaf.procLayerSelfEnabled=false
  local container=CyrusSourceContainer name:"Recipe saved container" width:3 length:4;container.collectEnabled=false;container.savedSources=#(model)
  leaf.containerNodes=#(container);leaf.containerMode=4
  local document=CyrusRecipeCapture root #(leaf) "Container recipe",bindings=CyrusRecipeSuggestBindings root document
  local result=CyrusRecipeImport root document bindings
  verify (root.layerObjects.count==2 and result[2][1].containerNodes[1]==container) "Compatible container settings and ordered membership bind successfully" log
  container.savedSources=#(other);local failed=false
  try(CyrusRecipeImport root document bindings)catch(failed=true)
  verify (failed and root.layerObjects.count==2 and container.savedSources[1]==other) "Changed container membership blocks import without modifying the external container" log
  container.savedSources=#(model)
  local roles=CyrusRecipeGet document "roles",ambiguous=pyramid name:model.name
  local suggestions=CyrusRecipeSuggestBindings root document,unbound=false
  for i=1 to roles.count where (CyrusRecipeGet roles[i] "name")==model.name do unbound=suggestions[i][2]==undefined
  verify unbound "Duplicate scene names stay unbound until explicit review" log
  delete ambiguous
  leaf.containerNodes=#();leaf.containerMode=1
  document=CyrusRecipeCapture root #(leaf) "Metre settings";bindings=CyrusRecipeSuggestBindings root document
  units.SystemType=#centimeters;units.SystemScale=1
  result=CyrusRecipeImport root document bindings newSetup:true
  verify (abs(result[2][1].sourceZOffsetsWU[1]-25.0)<0.00001) "Paint-free typed distances convert from metres into the destination system units" log
  units.SystemType=#meters;units.SystemScale=1
  local area=root.addPaintArea leaf target:terrain
  area.procRadiusIDs=#("blocked-area-radius");area.procRadiusModes=#(1);area.procRadiusValues=#(1.0);area.procRadiusDistances=#(0.1)
  failed=false;try(CyrusRecipeCapture root #(leaf) "Area radius guard")catch(failed=true)
  verify (failed and area.procRadiusIDs.count==1) "Unsupported Paint Area radius records block full save and remain intact" log
  area.procClearRadii()
  verify (not theHold.Holding()) "Binding and rejection commands leave no stranded hold" log
  format "PASSED\n" to:log
 )catch(format "FAILED: %\n" (getCurrentException()) to:log;close log;throw())
 close log
)
