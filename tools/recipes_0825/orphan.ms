-- Orphan native Paint and external model/map substitution; no compatible-terrain guess.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-recipes0825-*/" do throw "Owned recipe host required"
 local log=createFile (MCPFixtureDir+"recipe-orphan.txt")
 fn sameFrame a b = (if a==undefined or b==undefined then a==undefined and b==undefined else (local same=a.count==b.count;if same do for i=1 to a.count where a[i]!=b[i] do same=false;same))
 fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 try (
  CyrusPerfHeadless=true;resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
  local node=AminScatterObject name:"Orphan recipe",root=node.baseObject,terrain=plane name:"Orphan receiver" width:10 length:10 pos:[3,4,5]
  convertToMesh terrain;root.updateMode=1;root.autoRender=false;root.newLayer()
  local leaf=root.selectedLayer(),model=pyramid name:"Original recipe model",replacement=box name:"Replacement recipe model"
  root.setLayerSurfaces leaf #(terrain);leaf.sources=#(model);leaf.ensureSourceRows();leaf.amount=80;leaf.procLayerSelfEnabled=false
  local texture=checker name:"Saved dormant texture",replacementTexture=noise name:"Replacement dormant texture"
  leaf.densityMap=texture;leaf.distributionMode=1
  local area=root.addPaintArea leaf target:terrain;area.paintView=0;cyrusBrushFill area.paintDocument 1
  local payload=(cyrusBrushRecipeExport area.paintDocument)[1],frame=(cyrusBrushRecipeExport area.paintDocument)[4]
  delete terrain
  local document=CyrusRecipeCapture root #(leaf) "Orphan complete recipe",paint=CyrusRecipeGet (CyrusRecipeGet (CyrusRecipeGet document "layers")[1] "areas")[1] "paint"
  verify ((CyrusRecipeGet paint "payload")==payload and (CyrusRecipeGet paint "receiverRole")==undefined and sameFrame (CyrusRecipeGet paint "frame") frame) "Orphan capture retains exact coverage and known receiver frame" log
  local bindings=CyrusRecipeSuggestBindings root document,roles=CyrusRecipeGet document "roles"
  for i=1 to roles.count do (
   if (CyrusRecipeGet roles[i] "kind")=="texture" do bindings[i][2]=replacementTexture
   if (CyrusRecipeGet roles[i] "name")==model.name do bindings[i][2]=replacement
  )
  local result=CyrusRecipeImport root document bindings,imported=result[2][1],restored=cyrusBrushRecipeExport imported.paintAreas[1].paintDocument
  verify (restored[1]==payload and sameFrame restored[4] frame and imported.paintAreas[1].areaTarget==undefined) "Orphan import stays unbound with exact Paint and frame" log
  verify (imported.sources[1]==replacement and imported.densityMap==replacementTexture and imported.distributionMode==1) "Explicit model and dormant texture roles substitute without changing enable state" log
  saveMaxFile (MCPFixtureDir+"recipe-orphan.max") quiet:true
  resetMaxFile #noPrompt;loadMaxFile (MCPFixtureDir+"recipe-orphan.max") quiet:true useFileUnits:true
  root=(getNodeByName "Orphan recipe").baseObject;restored=cyrusBrushRecipeExport root.layerObjects[2].paintAreas[1].paintDocument
  verify (restored[1]==payload and sameFrame restored[4] frame) "Orphan Paint bytes and frame survive cold scene reopen" log
  local recaptured=CyrusRecipeCapture root #(root.layerObjects[2]) "Saved orphan again"
  verify (sameFrame (CyrusRecipeGet (CyrusRecipeGet (CyrusRecipeGet (CyrusRecipeGet recaptured "layers")[1] "areas")[1] "paint") "frame") frame) "Save Everything after reopen preserves orphan frame" log
  verify (not theHold.Holding()) "Orphan lifecycle leaves no stranded hold" log
  format "PASSED\n" to:log
 )catch(format "FAILED: %\n" (getCurrentException()) to:log;close log;throw())
 close log
)
