(
    WFRoot.interactionsEnsure();CyrusPointSync()
    local tree=WFRoot.layerObjects[3],treeSource=(tree.validSources())[1],sourceBox=nodeGetBoundingBox treeSource (matrix3 1)
    local treeRows=cyrusPlacementTransformGroups WFRoot.groupSnapshotRows[3],stoneRows=cyrusPlacementTransformGroups (cyrusInteractionRows WFRoot.interactionState 2)
    local treeTM=treeRows[1][1],stoneTM=stoneRows[1][1]
    local delta=treeTM.row4-stoneTM.row4
    delta.z+=(sourceBox[2].z-sourceBox[1].z)*.45*(length treeTM.row1)
    cyrusEditCommand WFEdit 4 (transMatrix delta)
    WFRoot.interactionsEnsure();CyrusPointSync();completeRedraw()
    local out=createFile (GardenRun+"contact-setup.txt")
    format "tree:%\nstone:%\nshift:%\n%\n" treeTM stoneTM delta (WFRoot.interactionsStatistics()) to:out;close out
    local centre=treeTM.row4+[0,0,delta.z],size=(sourceBox[2].z-sourceBox[1].z)*length treeTM.row1
    local eye=centre+[size*.8,-size*1.3,size*.6],back=normalize (eye-centre),right=normalize (cross [0,0,1] back),up=cross back right
    viewport.setTM (inverse (matrix3 right up back eye));completeRedraw()
)
