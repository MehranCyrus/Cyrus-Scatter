(
 if not matchPattern MCPFixtureDir pattern:"*/viewport0867-content-2027/" do throw "Owned content host required"
 local output=createFile (MCPFixtureDir+"material-probe.txt"),n=objects[1]
 try(
  format "MERGED %\n" (getLastMergedNodes()) to:output
  for material in getClassInstances CoronaLegacyMtl target:n.material do (
   for key in #(#levelDiffuse,#mapamountDiffuse,#mapamountOpacity,#levelOpacity,#texmapDiffuse,#texmapOpacity) do format "%=%\n" key (getProperty material key) to:output
   format "ATTRS %\n" (custAttributes.count material) to:output
   showProperties material.texmapDiffuse to:output
   format "COLOR MAP ID % BASE %\n" material.texmapDiffuse.classID material.texmapDiffuse.mapbase to:output
   for i=1 to custAttributes.count material do format "ATTR % % DEF %\n" i (custAttributes.get material i) (custAttributes.getDef material i) to:output
  )
  local target=MCPFixtureDir+"leaf2024.max"
  local legacy=SceneConverter.GetMissingLegacyAssetsName()
  format "LEGACY ASSETS %\n" legacy to:output
  format "MISSING PLUGINS %\n" (SceneMissingPlugIns.GetMissingPlugInCount()) to:output
  if legacy.count==1 and matchPattern legacy[1] pattern:"*mental ray*material custom attribute*" do SceneConverter.RemoveMissingLegacyAssetsFromScene &legacy
  saveNodes #(n) target quiet:true saveAsVersion:2024
  local missing=#(),names=getMAXFileObjectNames target quiet:true missingDLLsAction:#logmsg missingDLLsList:&missing
  format "SAVED % VERSION % MISSING %\n" names (getMAXFileVersionData target) missing to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 close output
)
