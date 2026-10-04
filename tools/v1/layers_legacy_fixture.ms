-- Frozen 1.0.1 scene, untouched; compare its original saved expectations.
if findString (toLower BLDir) "/build/cyrus-v1/hosts/"==undefined do throw "Private profile required"
loadMaxFile (BLRoot+"build/cyrus-v1/hosts/v101-relax-reset/v1-qualified.max") useFileUnits:true quiet:true
global CyrusV1ReopenExpected
fileIn (BLRoot+"build/cyrus-v1/hosts/v101-relax-reset/reopen-expected.ms")
(
    for record in CyrusV1ReopenExpected do (
        local root=(getNodeByName record[1]).baseObject,leaf=root.layerObjects[1]
        if root.uiVersion()!="1.2.0" or root.groupPolicy!=1 or leaf.logicalParentID!="" do throw "Legacy ownership/policy migrated silently"
        if leaf.layerID!=record[2] or leaf.editLayerKey!=record[3] do throw "Legacy identity changed"
        if (cyrusBrushHistory leaf.paintDocument) as string!=record[5] do throw "Legacy history changed"
        if cyrusEditFingerprint (leaf.placements (leaf.validSources()) previewOnly:true) "reopen"!=record[4] do throw "Legacy placement changed"
    )
    CSPWriteText (BLDir+"layers-legacy-acceptance.json") (CSPObject #(#("frozen_1_0_1_scene",true),#("policy_identity_history_and_transforms_preserved",true)))
)
