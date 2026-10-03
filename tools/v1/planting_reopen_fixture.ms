-- launch.py copies the explicit saved-scene expectation into this private run.
global CyrusGroupsReopenExpected
(
    fileIn (BLDir+"groups-reopen-expected.ms")
    for record in CyrusGroupsReopenExpected do (
        local node=getNodeByName record[1],root=node.baseObject
        if root.groupPolicy!=record[2] do throw "Saved policy changed on reopen"
        local rules=(for p in #(#groupRuleA,#groupRuleB,#groupRuleEnabled,#groupRuleGap,#groupRuleFootprints,#groupRulePlanar) collect getProperty root p) as string
        if rules!=record[3] as string do throw "Pair rules changed on reopen"
        for i=1 to root.layerObjects.count do (
            local group=root.layerObjects[i],expected=record[4][i]
            if group.layerID!=expected[1] or group.editLayerKey!=expected[2] or group.groupPriority!=expected[3] or group.paintEnabled!=expected[4] do throw "Saved group identity/priority changed"
            if group.paintDocument!=undefined and (cyrusBrushHistory group.paintDocument) as string!=expected[5] do throw "Saved paint history changed"
            local rows=group.placements (group.validSources()) previewOnly:true
            if cyrusEditFingerprint rows "reopen"!=expected[6] do throw "Saved accepted plants changed"
        )
        root.refreshAll()
        for group in root.layerObjects where (group.cacheSnapshot())[4]!="" do throw (group.cacheSnapshot())[4]
    )
    CSPWriteText (BLDir+"groups-reopen-acceptance.json") (CSPObject #(#("fresh_process",true),#("group_identity_priority_rules_history",true),#("accepted_transforms_match",true)))
)
