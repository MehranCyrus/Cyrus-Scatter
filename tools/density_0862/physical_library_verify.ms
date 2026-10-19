(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 if CyrusReadyPresetEditor==undefined or not CyrusReadyPresetEditor.finished do throw "Wait for the already requested load"
 if not matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*" do throw CyrusReadyPresetEditor.status.text
 global DRoot=CyrusReadyPresetEditor.result[1],DNode=CyrusReadyPresetEditor.result[3],DLayer=undefined
 if DRoot.layerObjects.count!=3 do throw "Expected physical selection of the three-layer meadow"
 for leaf in DRoot.layerObjects do if not (CyrusPresetSameValues (leaf.validSurfaces()) #(DTerrain)) do throw "Wrong selected surface"
 if (for leaf in DRoot.layerObjects where leaf.previewError!="" collect leaf).count!=0 do throw "Loaded recipe has a calculation error"
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"physical-library-load.txt") "PASS: Mouse-selected bundled meadow and Load Selected create three layers on the selected plain terrain with no calculation errors."
 destroyDialog CyrusReadyPresetEditor;destroyDialog CyrusRecipeBrowser
 select DNode;max modify mode;DRoot.selectLayer 1;DLayer=DRoot.selectedLayer();DRoot.bindNativeUI()
 for i=2 to DRoot.mainUI.slots.count do DRoot.mainUI.slots[i].open=(i==6)
 DRoot.mainUI.bindEditors()
)
