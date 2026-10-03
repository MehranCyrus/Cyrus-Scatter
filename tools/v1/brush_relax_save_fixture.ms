-- Persist paused settings and the original painted history in a private scene.
(
    if not isValidNode CyrusPatchNode do throw "Run the focused patch fixture first"
    local root=CyrusPatchNode.baseObject,layer=CyrusPatchLayer
    CyrusPatchNode.name="CYRUS_PATCH_SAVED_SCATTER"
    layer.relaxEnabled=true;layer.finalRelax=true;layer.paintEnabled=true
    root.selectLayer 1;root.refreshAll();select CyrusPatchNode;max modify mode;root.bindNativeUI()
    if layer.previewError!="" or layer.generatedCount==0 do throw "Paused Relax could not be saved with a valid preview"
    local history=cyrusBrushHistory layer.paintDocument
    local rows=layer.placements (layer.validSources()) previewOnly:true
    local expectation=stringStream ""
    with printAllElements on format "global CyrusPatchReopenExpected=%\n" #(rows.count,cyrusEditFingerprint rows "patch-reopen",history as string) to:expectation
    CSPWriteText (BLDir+"patch-reopen-expected.ms") (expectation as string)
    saveMaxFile (BLDir+"brush-relax-paused.max") quiet:true
    CSPWriteText (BLDir+"patch-save.json") (CSPObject #(#("script_version",root.uiVersion()),#("paused_settings_preserved",layer.relaxEnabled and layer.finalRelax),#("placements",layer.generatedCount),#("history_rows",history.count),#("saved_private_scene",true)))
)
