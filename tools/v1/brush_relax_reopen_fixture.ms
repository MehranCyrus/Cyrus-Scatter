-- Run in a fresh installed private process opened on brush-relax-paused.max.
global CyrusPatchReopenExpected
(
    fileIn (BLDir+"patch-reopen-expected.ms")
    if CyrusPatchReopenExpected==undefined do throw "No companion patch expectations"
    local node=getNodeByName "CYRUS_PATCH_SAVED_SCATTER"
    if not isValidNode node do throw "Saved patch controller is missing"
    local root=node.baseObject,layer=root.layerObjects[1]
    if root.uiVersion()!="1.0.1" or not layer.relaxEnabled or not layer.finalRelax or not layer.paintEnabled do throw "Saved paused settings were lost"
    if not layer.brushMaskActive() do throw "Saved painted mask is inactive"
    local history=cyrusBrushHistory layer.paintDocument
    if history as string!=CyrusPatchReopenExpected[3] do throw "Saved Brush history changed"
    root.refreshAll()
    local rows=layer.placements (layer.validSources()) previewOnly:true
    if layer.previewError!="" or rows.count!=CyrusPatchReopenExpected[1] do throw "Reopened paused layer lost its preview"
    if cyrusEditFingerprint rows "patch-reopen"!=CyrusPatchReopenExpected[2] do throw "Reopened masked placements changed"
    select node;max modify mode;root.bindNativeUI()
    if root.spacingUI.spacingSpin.enabled or root.separationUI.finalStrengthSpin.enabled do throw "Reopen lost paused control availability"
    CSPWriteText (BLDir+"patch-reopen.json") (CSPObject #(#("script_version",root.uiVersion()),#("saved_settings_preserved",true),#("exact_placements_preserved",rows.count),#("brush_history_preserved",history.count),#("preview_error",layer.previewError),#("paused_controls_restored",true)))
)
