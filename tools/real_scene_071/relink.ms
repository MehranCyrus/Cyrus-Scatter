(
 local repaired=0,missing=#(),proxyRows=#()
 for map in getClassInstances Bitmaptexture do (
  local path=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/Test Scene/maps/"+filenameFromPath map.filename
  if doesFileExist path then (map.filename=path;repaired+=1)else append missing path
 )
 for node in objects where (classof node.baseObject)==CProxy do (
  local old=node.filename,path=@"F:/Cursor/_Cyrus_Apps/CyrusScatter/Test Scene/maps/"+filenameFromPath old
  if doesFileExist path do node.filename=path
  append proxyRows #(node.name,old,node.filename,doesFileExist node.filename)
 )
 local pipeline=#(),op=renderers.current.colorMap_pipeline
 local f=createFile (MCPFixtureDir+"tonemap-values.txt")
 while op!=undefined do (format "\nCLASS %\n" (classof op) to:f;show op to:f;op=op.colorMappingOperator_nextOperator)
 close f
 CSPWriteText (MCPFixtureDir+"relink.json") (CSPObject #(#("bitmap_references_relinked",repaired),#("missing",missing),#("proxies",proxyRows),#("corona",CoronaRenderer.getVersionString())))
)
