(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-2027/" do throw "Owned content host required"
 local output=createFile (MCPFixtureDir+"installed-content-08672.txt")
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 try(
  resetMaxFile #noPrompt
  local root=(dotNetClass "System.IO.File").ReadAllText @"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\final-08672-20261020\exe-ui-final\library-root.txt"
  dotNet.loadAssembly (MCPFixtureDir+"scripts/CyrusGallery.dll")
  local catalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
  catalog.Load root "0.86.7" 2027
  check (catalog.Count==96 and catalog.CategoryCount==7) "EXE-installed ZIP exposes all 96 models and seven categories" output
  local node=AminScatterObject(),controller=node.baseObject
  controller.newLayer();local layer=controller.selectedLayer()
  local source=CyrusModelMerge catalog (catalog.MatchingAt "A027" "" 0) owner:layer
  check (isValidNode source and source.material!=undefined and source.numfaces>0) "Real leaf imports from the installed ZIP library" output
  local maps=getClassInstances Bitmaptexture target:source.material
  check (maps.count>0) "Imported leaf has bitmap dependencies" output
  for map in maps do check (doesFileExist map.filename and findString (toLower map.filename) (toLower root)==1) "Leaf texture resolves inside the installed shared library" output
  controller.setLayerSurfaces layer #(plane width:100 length:100)
  layer.amount=12;layer.procSelfOverride=true;layer.procSelfEnabled=false;layer.procLayerSelfEnabled=false
  controller.updateMode=1;controller.autoRender=false;controller.identificationMode=4;controller.setGroupDisplay 3
  controller.refreshAll();controller.evaluateProcedural();redrawViews();completeRedraw()
  check (controller.groupSnapshotRows[1].count==12 and layer.previewError=="") "Installed leaf produces textured scatter without missing files" output
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
