(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 for dialog in #(CyrusRecipeBrowser,CyrusReadyPresetEditor) where dialog!=undefined do destroyDialog dialog
 CyrusClearMeshMaskPreview undefined
 with undo off (
  resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1.
  global DTerrain=plane name:"Physical library target" width:1000 length:1000 widthsegs:10 lengthsegs:10 mapCoords:false
 )
 select DTerrain;max modify mode
 viewport.setLayout #layout_1;viewport.setType #view_top;max zoomext sel
 CyrusOpenRecipeLibrary undefined
 CyrusRecipeBrowser.panel.SetNavigation 2 "" false;CyrusRecipeBrowser.action "library"
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"window.txt") ((windows.getMAXHWND()) as string)
)
