(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"search-probe-"+(timeStamp() as string)+".txt")
 format "heap=% free=%\n" heapSize heapFree to:log
 format "gallery=% text=%\n" CyrusRecipeBrowser CyrusRecipeBrowser.panel.SearchText to:log
 for i=0 to 29 do (
  try(CyrusRecipeBrowser.panel.SearchText="catalog "+(i as string);format "PASS %\n" i to:log)
  catch(format "FAIL % %\n%\n" i (getCurrentException()) (getCurrentExceptionStackTrace()) to:log;flush log;close log;throw())
 )
 format "END heap=% free=%\n" heapSize heapFree to:log
 close log
)
