(
    if not matchPattern GardenRun pattern:"*/build/drag08756-*/host-*/" do throw "Owned drag campaign required"
    WFRoot.interactionSceneColliders=#()
    if isValidNode DGStone do hide DGStone
    WFCollider.interactionCollider=true
    WFCollider.sourceScales[1]=3.0
    WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync();CyrusSceneColliderWatch();completeRedraw()
    local out=createFile (GardenRun+"edit-stone-setup.txt")
    format "key:%\n%\n" WFCollider.editLayerKey (WFRoot.interactionsStatistics()) to:out
    close out
)
