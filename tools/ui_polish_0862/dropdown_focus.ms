(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local log=createFile (MCPFixtureDir+"dropdown-focus.txt")
 local h=14885604P
 for i=1 to 12 while h!=0 do (local data=windows.getHWNDData h;format "%\n" data to:log;h=data[2])
 close log
 cyrusReleaseRolloutScroll DRoot.mainUI.slots[6].hwnd
)
