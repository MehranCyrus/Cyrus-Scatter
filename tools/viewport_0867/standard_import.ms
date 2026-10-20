(
 if not matchPattern MCPFixtureDir pattern:"*/viewport0867-test*-202*/" do throw "Owned fixture host required"
 local output=createFile (MCPFixtureDir+"standard-import.txt")
 try(
  dotNet.loadAssembly (MCPFixtureDir+"scripts/CyrusGallery.dll")
  local catalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
  catalog.Load @"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\viewport-0867-20261020\standard-fixture\Library" "0.86.7" ((maxVersion())[1]/1000+1998)
  local entry=catalog.MatchingAt "" "" 0,missing=undefined,before=objects.count
  getMAXFileObjectNames entry.Scene quiet:true missingDLLsAction:#logmsg missingDLLsList:&missing
  local node=CyrusModelMerge catalog entry
  if not isValidNode node or classof node.material!=Standardmaterial or objects.count!=before+1 do throw "Standard model import failed"
  format "PASS: actual supported shader imports despite unrelated file header dependencies\nHeader: %\nSUCCESS\n" missing to:output
  delete node
 )catch(format "ERROR %\n" (getCurrentException()) to:output)
 close output
)
