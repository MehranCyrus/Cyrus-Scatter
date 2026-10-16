-- Native command fixture: no Python Undo context around product transactions.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
    local log=createFile (MCPFixtureDir+"style-"+(timeStamp() as string)+".txt")
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    fn counters root = #(root.procEpoch,root.groupBuilds,(for owner in root.layerObjects collect #(owner.procPreparedBuilds,owner.procDensityBakes,(owner.receiverCacheStats())[1])))
    fn paintBytes root = (for owner in root.layerObjects collect #(if owner.paintDocument==undefined then undefined else (cyrusBrushRecipeExport owner.paintDocument)[1],for area in owner.paintAreas collect (if area.paintDocument==undefined then undefined else (cyrusBrushRecipeExport area.paintDocument)[1])))
    try (
        check (not theHold.Holding()) "Start outside a surrounding hold" log
        CyrusPerfHeadless=true
        check (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/library/borders.max" quiet:true useFileUnits:true) "Painted border example opens" log
        local nodes=for n in objects where classof n.baseObject==AminScatterObject collect n
        local node=nodes[1],root=node.baseObject,owner=undefined
        root.refreshAll()
        for leaf in root.logicalLayers() where leaf.paintDocument!=undefined or leaf.paintAreas.count>0 do owner=leaf
        check (owner!=undefined) "Destination owns Paint" log
        local beforePaint=paintBytes root,beforeSources=owner.sources as array,beforeReceivers=owner.surfaceNodes as array,beforeIDs=owner.sourceRowIDs as array
        local beforeLayers=root.layerObjects as array,beforeWork=counters root,oldAmount=owner.amount,oldScale=owner.wholeScaleMin
        local data=CyrusRecipeCapture root #(owner) "Owned style witness",record=(CyrusRecipeGet data "layers")[1],recordID=CyrusRecipeGet record "id",settings=CyrusRecipeGet record "settings"
        local path=MCPFixtureDir+"style-"+CyrusNewLayerID()+".csrecipe.json",metadata=CyrusRecipeObject #(#("category","Style fixture"),#("tags",#()),#("description","Owned test data"))
        local digest=cyrusRecipeEntryWrite path data metadata "" undefined "" false
        local plan=CyrusStylePrepare root owner path digest recordID #("Amount","Transforms","Mesh channel mask","Slope and altitude") #()
        undo "Prior user operation" on node.name="Prior edit must survive a no-op"
        check (not (CyrusStyleCommit plan)) "Identical Keep style is passive" log
        check (CyrusPresetSameValues beforeWork (counters root)) "No-op performs no terrain/map/placement work" log
        max undo
        check (node.name!="Prior edit must survive a no-op") "No-op retains preceding Undo" log
        max redo
        CyrusRecipePut settings "amount" (oldAmount+17)
        digest=cyrusRecipeEntryWrite path data metadata "" undefined digest false
        plan=CyrusStylePrepare root owner path digest recordID #("Amount") #()
        check (CyrusStyleCommit plan) "Changed Amount style commits" log
        check (owner.amount==oldAmount+17 and root.procEpoch==beforeWork[1]) "Manual style waits for Update" log
        check (CyrusPresetSameValues beforePaint (paintBytes root)) "Complete destination Paint bytes retained" log
        check (CyrusPresetSameValues beforeSources (owner.sources as array) and CyrusPresetSameValues beforeReceivers (owner.surfaceNodes as array)) "Models and terrain retained" log
        check (CyrusPresetSameValues beforeIDs (owner.sourceRowIDs as array) and CyrusPresetSameValues beforeLayers (root.layerObjects as array)) "Source IDs and layer order retained" log
        max undo;check (owner.amount==oldAmount) "One Undo restores previous Amount" log
        max redo;check (owner.amount==oldAmount+17) "Redo restores reviewed values" log
        plan=CyrusStylePrepare root owner path digest recordID #("Amount") #()
        check (not (CyrusStyleCommit plan)) "Repeat Keep style is a no-op" log
        local rejected=false
        plan=CyrusStylePrepare root owner path digest recordID #("Amount") #()
        undo off owner.amount+=1
        try(CyrusStyleCommit plan)catch(rejected=true)
        check rejected "Destination edits invalidate a reviewed plan" log
        undo off owner.amount-=1
        plan=CyrusStylePrepare root owner path digest recordID #("Amount") #() seedPolicy:#new
        local oldSeed=owner.randomSeed
        check (CyrusStyleCommit plan) "New seeds are one authored change" log
        local newSeed=owner.randomSeed
        check (newSeed!=oldSeed) "New seeds differ from destination" log
        max undo;check (owner.randomSeed==oldSeed) "New seed Undo" log
        max redo;check (owner.randomSeed==newSeed) "New seed Redo does not reroll" log
        plan=CyrusStylePrepare root owner path digest recordID #("Amount") #()
        digest=cyrusRecipeEntryWrite path data metadata "" undefined digest false
        rejected=false;try(CyrusStyleCommit plan)catch(rejected=true)
        check rejected "Changed recipe revision rejects stale plan" log
        local peer=undefined;for leaf in root.logicalLayers() where leaf!=owner do peer=leaf
        check (peer!=undefined) "Independent layer available for late validation boundary" log
        local peerPopulation=peer.procPopulation,prior=owner.amount
        undo off peer.procPopulation=9
        CyrusRecipePut settings "amount" (prior+9)
        digest=cyrusRecipeEntryWrite path data metadata "" undefined digest false
        plan=CyrusStylePrepare root owner path digest recordID #("Amount") #()
        rejected=false;try(CyrusStyleCommit plan)catch(rejected=true)
        check (rejected and owner.amount==prior) "Late root validation rolls back applied setters" log
        check (root.procEpoch==beforeWork[1] and CyrusPresetSameValues beforePaint (paintBytes root)) "Failed style retains prior publication and Paint" log
        undo off peer.procPopulation=peerPopulation
        check (not theHold.Holding()) "No stranded style hold" log
        root.activeLayer=findItem root.layerObjects owner
        CyrusOpenRecipeStyle root path digest
        check (CyrusStyleEditor.owner==owner) "Style dialog captures the explicit destination" log
        CyrusStyleEditor.review.pressed()
        check CyrusStyleEditor.applyStyle.enabled "Actual style Review handler creates proposal" log
        CyrusStyleEditor.applyStyle.pressed()
        check (owner.amount==prior+9) "Actual Apply Style handler commits proposal" log
        destroyDialog CyrusStyleEditor
        format "PASS: complete\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
