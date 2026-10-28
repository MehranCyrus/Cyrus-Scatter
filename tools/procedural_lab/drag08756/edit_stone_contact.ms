(
    cyrusEditActiveLayers WFEdit #(WFCollider.editLayerKey)
    cyrusEditCommand WFEdit 1 undefined
    local tree=WFRoot.layerObjects[3],source=(tree.validSources())[1],bbox=nodeGetBoundingBox source source.transform
    local treeRows=cyrusPlacementTransformGroups WFRoot.groupSnapshotRows[3]
    local stoneRows=cyrusPlacementTransformGroups (cyrusInteractionRows WFRoot.interactionState 2)
    local target=treeRows[1][1].row4+[0,0,(bbox[2].z-bbox[1].z)*.55],before=stoneRows[1][1].row4
    cyrusEditCommand WFEdit 4 (transMatrix (target-before))
    redrawViews()
    local out=createFile (GardenRun+"edit-stone-contact.txt")
    format "before:% target:%\n%\n" before target (WFRoot.interactionsStatistics()) to:out
    local page=cyrusEditInspect WFEdit 0 1
    for offset=0 to (page[2] as integer)-1 by 500 do (
        local data=cyrusEditInspect WFEdit offset 500
        for row in data[4] where row[1]==WFCollider.editLayerKey do format "ROW %\n" row to:out
    )
    close out
)
