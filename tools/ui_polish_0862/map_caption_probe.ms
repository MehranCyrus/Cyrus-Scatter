(
 local p=DRoot.mainUI.editors[6],f=createFile (MCPFixtureDir+"map-caption.txt")
 UIAccessor.SetWindowText p.distributionUI_densityButton.hwnd[1] "Map"
 format "text=%\n" p.distributionUI_densityButton.text to:f
 for h in p.distributionUI_densityButton.hwnd do format "%\n" (windows.getHWNDData h) to:f
 close f
)
