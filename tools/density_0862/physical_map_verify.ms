(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 if DLayer.densityPatternID!="wide-bands" or classof DLayer.densityMap!=Bitmaptexture do throw "Expected mouse-selected wide-bands QA image"
 local page=DRoot.mainUI.editors[6],shown=page.distributionUI_imageThumbnail.bitmap
 if shown==undefined or shown.width!=256 or shown.height!=256 or page.distributionUI_imageThumbnail.style!=#bmp_stretch do throw "Thumbnail lost the full source tile"
 if page.distributionUI_obj!=DLayer do throw "Picker changed the wrong owner"
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"physical-pattern-load.txt") "PASS: Mouse-opened pattern chooser and double-clicked Wide bands apply to the selected layer; the actual thumbnail retains the complete 256x256 source tile and uses native stretch display."
)
