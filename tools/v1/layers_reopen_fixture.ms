global LFOwnershipExpected
fileIn (BLDir+"layers-reopen-expected.ms")
(
    local node=getNodeByName "Cyrus layers first",root=node.baseObject
    if root.layerObjects.count!=LFOwnershipExpected.count or (root.logicalLayers()).count!=2 do throw "Reopen lost ownership"
    for i=1 to root.layerObjects.count do (
        local leaf=root.layerObjects[i],expected=LFOwnershipExpected[i]
        local actual=#(leaf.layerID,leaf.logicalParentID,leaf.paintSetName,leaf.paintSetWeight,leaf.paintSetEnabled,leaf.paintSetVisible,cyrusEditFingerprint (leaf.placements (leaf.validSources()) previewOnly:true) "ownership")
        if actual as string!=expected as string do throw "Saved ownership/settings/transforms changed"
    )
    root.refreshAll();select node;max modify mode;root.bindNativeUI()
    for p in root.layerPanels do (p.open=true;p.mount())
    if root.layerPanels.count!=2 do throw "Saved layers did not reopen independently"
    CSPWriteText (BLDir+"layers-reopen-acceptance.json") (CSPObject #(#("fresh_process",true),#("ownership_settings_and_transforms",true),#("two_native_editors",true)))
)
