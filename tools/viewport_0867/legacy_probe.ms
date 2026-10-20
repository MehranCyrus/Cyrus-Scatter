(
 if not matchPattern MCPFixtureDir pattern:"*/viewport0867-content-2027/" do throw "Owned content host required"
 local output=createFile (MCPFixtureDir+"legacy-probe.txt")
 try (
  loadMaxFile (MCPFixtureDir+"leaf2024.max") quiet:true useFileUnits:true
  local legacy=SceneConverter.GetMissingLegacyAssetsName()
  format "LEGACY %\n" legacy to:output
  for i=1 to SceneMissingPlugIns.GetMissingPlugInCount() do format "MISSING % %\n" (SceneMissingPlugIns.GetMissingPlugInClassName i) (SceneMissingPlugIns.GetMissingPlugInFileName i) to:output
  local refsList=#(objects[1],objects[1].baseObject,objects[1].material)
  join refsList (getClassInstances Bitmaptexture target:objects[1].material)
  for object in refsList where object!=undefined do (
   format "OBJECT % ATTRS %\n" object (custAttributes.count object) to:output
   for i=1 to custAttributes.count object do format "ATTR % % DEF %\n" i (custAttributes.get object i) (custAttributes.getDef object i) to:output
  )
  if legacy.count>0 and (for name in legacy where not matchPattern name pattern:"*mental ray*" collect name).count==0 do SceneConverter.RemoveMissingLegacyAssetsFromScene &legacy
  saveNodes #(objects[1]) (MCPFixtureDir+"leaf2024-clean.max") quiet:true saveAsVersion:2024
  local missing=#(),names=getMAXFileObjectNames (MCPFixtureDir+"leaf2024-clean.max") quiet:true missingDLLsAction:#logmsg missingDLLsList:&missing
  format "SAVED % MISSING %\n" names missing to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
