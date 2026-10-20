(
 local output=createFile (MCPFixtureDir+"content-dependency-probe.txt"),missing=undefined
 local names=getMAXFileObjectNames @"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\mcp-qualification\viewport0867-content-2027\dependency-cleanup.max" quiet:true missingDLLsAction:#logmsg missingDLLsList:&missing
 format "%\n%\n" names missing to:output
 close output
)
