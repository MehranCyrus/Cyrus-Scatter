(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local f=createFile (MCPFixtureDir+"dropdown-ancestry.txt")
 format "SLOT % BODY % INFO %\n" DRoot.mainUI.slots[6].hwnd DropProbePage.hwnd (cyrusRolloutScrollInfo DRoot.mainUI.slots[6].hwnd) to:f
 local h=DropProbePage.distributionUI_coordinatesList.hwnd[1]
 for i=1 to 18 while h!=0 do (local d=windows.getHWNDData h;format "%\n" d to:f;h=d[2])
 close f
)
