-- Load a genuinely saved 1.0.1 scene and compare its original evidence.
-- Run after launch.py --scene .../v101-relax-reset/v1-qualified.max
-- --reopen-expected .../v101-relax-reset/reopen-expected.ms.
global CyrusV1ReopenExpected
(
    fileIn (BLDir+"reopen-expected.ms")
    for record in CyrusV1ReopenExpected do (
        local node=getNodeByName record[1],root=node.baseObject,group=root.layerObjects[1]
        if root.uiVersion()!="1.1.0" or root.groupPolicy!=1 do throw "Old file was silently converted to new spacing"
        if group.layerID!=record[2] or group.editLayerKey!=record[3] do throw "Legacy identity changed"
        if (cyrusBrushHistory group.paintDocument) as string!=record[5] do throw "Legacy strokes changed"
        local rows=group.placements (group.validSources()) previewOnly:true
        if (cyrusEditFingerprint rows "reopen")!=record[4] do throw "Legacy output changed under new binary/script"
    )
    CSPWriteText (BLDir+"planting-legacy-acceptance.json") (CSPObject #(#("saved_1_0_1_scene",true),#("legacy_policy_preserved",true),#("original_id_history_transform_fingerprints",true)))
)
