(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local f=openFile (MCPFixtureDir+"dropdown-final.txt") mode:"a",page=DRoot.mainUI.editors[6],open=false
 for h in page.distributionUI_coordinatesList.hwnd where windows.sendMessage h 0x157 0 0!=0 do open=true
 format "time=% scale=% open=% epoch=% builds=%\n" (timestamp()) (GetUIScaleFactor()) open DRoot.procEpoch DRoot.groupBuilds to:f;close f
 if not open do throw "Physical dropdown did not remain open after entering the host focus chain"
)
