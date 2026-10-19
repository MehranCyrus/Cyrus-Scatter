(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local page=DRoot.mainUI.editors[6],log=createFile (MCPFixtureDir+"control-metrics.txt")
 for control in #(page.distributionUI_densityButton,page.distributionUI_modeRadio_caption) do (
  format "% class=% width=% property=% visible=%\n" control.name (classof control) control.width (isProperty control #width) control.visible to:log
  for h in control.hwnd do format "  % %\n" (windows.getHWNDData h) (windows.getWindowPos h) to:log
 )
 close log
)
