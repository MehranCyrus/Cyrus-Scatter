(
 if not matchPattern MCPFixtureDir pattern:"*/foundation-memory0854-*/" do throw "Owned memory host required"
 local log=createFile (MCPFixtureDir+"runtime-identity.txt")
 format "maxVersion=%\nscriptPayload=%\npublicationCapability=%\nmemoryCapability=%\nheapSize=%\nheapFree=%\nreserved=%\nnormalInstallPerformed=false\n" (maxVersion()) CyrusLoadedScriptFingerprint (cyrusProceduralPublicationVersion()) (cyrusScriptMemoryVersion()) heapSize heapFree CyrusScriptWorkspaceReserved to:log
 close log
)
