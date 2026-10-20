(
 if not matchPattern MCPFixtureDir pattern:"*/viewport0867-test*-202*/" do throw "Owned content qualification host required"
 local output=createFile (MCPFixtureDir+"content-compatibility.txt")
 try(
  dotNet.loadAssembly (MCPFixtureDir+"scripts/CyrusGallery.dll")
  local catalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog",year=((maxVersion())[1]/1000+1998)
  catalog.Load @"F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\CyrusScatter-0.86.7-20261020\Content\Library" "0.86.7" year
  local accepted=0,missingCount=0
  for i=0 to catalog.Count-1 do (
   local entry=catalog.MatchingAt "" "" i,missing=undefined
   local names=getMAXFileObjectNames entry.Scene quiet:true missingDLLsAction:#logmsg missingDLLsList:&missing
   if names==undefined or names.count!=1 or names[1]!=entry.NodeName do throw ("Declared mesh name differs: "+entry.Id)
   local version=getMAXFileVersionData entry.Scene
   if version[1]!=26000 do throw ("Unexpected saved format: "+entry.Id)
   if missing!=undefined and missing.count>0 do missingCount+=1
   accepted+=1
  )
  format "PASS: % prepared single-mesh files readable in Max %\nFiles with unavailable material/map plugins: %\n" accepted year missingCount to:output;flush output
  if missingCount>0 do (
   local countBefore=objects.count,failure=undefined,entry=catalog.MatchingAt "A027" "" 0
   try(CyrusModelMerge catalog entry)catch(failure=getCurrentException())
   format "Import result: %; scene objects before % after %\n" failure countBefore objects.count to:output;flush output
   if failure==undefined or not matchPattern failure pattern:"*unavailable material*plug-ins*" or objects.count!=countBefore do throw "Unavailable model dependencies were not rolled back"
   format "PASS: unavailable plug-ins produce actionable error and roll back added scene objects\n%\n" failure to:output
  )
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n" (getCurrentException()) to:output)
 close output
)
