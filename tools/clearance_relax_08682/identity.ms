(
 if not matchPattern MCPFixtureDir pattern:"*/clearance-relax-08682-*/" do throw "Owned clearance host required"
 local node=getNodeByName "Clearance and Relax QA",root=node.baseObject
 dotNet.loadAssembly (MCPFixtureDir+"scripts/CyrusGallery.dll")
 local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),native="{",count=0
 for i=0 to process.Modules.Count-1 do (
  local module=process.Modules.Item[i],name=filenameFromPath module.FileName
  if findItem #("AminScatter.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh","CyrusScatterEdit.dlm") name>0 do (
   local hash=(dotNetClass "Cyrus.Content.LibraryLocation").Hash module.FileName
   native+=(if count>0 then "," else "")+"\""+name+"\":\""+hash+"\"";count+=1
  )
 )
 if count!=4 do throw "Missing native module identity"
 native+="}"
 -- Release a file stream left by a failed diagnostic invocation before retry.
 gc light:true
 local output=createFile (MCPFixtureDir+"loaded-identity.json")
 local panel=dotNetObject "CyrusScatter.UI.LibraryPanel",kind=panel.GetType()
 local gallery=(dotNetClass "Cyrus.Content.LibraryLocation").Hash kind.Assembly.Location
 panel.Dispose()
 format "{\"year\":%,\"version\":\"%\",\"script\":\"%\",\"gallery\":\"%\",\"recipe\":%,\"publication\":%,\"uiScale\":%,\"window\":%,\"native\":%}\n" \
  ((maxVersion())[1]/1000+1998) (root.uiVersion()) CyrusLoadedScriptFingerprint gallery (cyrusRecipeVersion()) (cyrusProceduralPublicationVersion()) (GetUIScaleFactor()) (process.MainWindowHandle as integer) native to:output
 close output
)
