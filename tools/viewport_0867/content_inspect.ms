(
 if not matchPattern MCPFixtureDir pattern:"*/viewport0867-content-2027/" do throw "Owned content host required"
 local output=createFile (MCPFixtureDir+"content-inspect.txt")
 try (
  local library=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\CyrusScatter-0.86.6.2-20261020\Content\Library"
  dotNet.loadAssembly (MCPFixtureDir+"scripts/CyrusGallery.dll")
  local catalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
  catalog.Load library "0.86.6.2"
  local entry=catalog.MatchingAt "" "Leaves" 0
  format "ENTRY % % %\n" entry.Id entry.Name entry.Scene to:output
  format "VERSION %\n" (getMAXFileVersionData entry.Scene) to:output
  local missing=#()
  local names=getMAXFileObjectNames entry.Scene quiet:true missingDLLsAction:#logmsg missingDLLsList:&missing
  format "EXPECTED % NAMES % MISSING % GLOBAL %\n" entry.NodeName names missing (execute "getLastMergedNodes") to:output
  resetMaxFile #noPrompt
  format "MERGE %\n" (mergeMAXFile entry.Scene #autoRenameDups #renameMtlDups #neverReparent quiet:true) to:output
  local n=objects[1]
  format "MATERIAL % CLASS %\n" (classof n.material) n.material.classID to:output
  showProperties n.material to:output
  for material in getClassInstances CoronaPhysicalMtl target:n.material do (format "\nPHYSICAL % %\n" material.name material.classID to:output;showProperties material to:output)
  for material in getClassInstances CoronaPhysicalMtl target:n.material do for key in #(#baseLevel,#baseMapAmount,#opacityMapAmount,#opacityLevel) do format "%=%\n" key (getProperty material key) to:output
  for material in getClassInstances CoronaLegacyMtl target:n.material do (format "\nLEGACY % %\n" material.name material.classID to:output;showProperties material to:output)
  for map in getClassInstances CoronaBitmap target:n.material do (format "\nBITMAP % %\n" map.name map.classID to:output;showProperties map to:output)
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
