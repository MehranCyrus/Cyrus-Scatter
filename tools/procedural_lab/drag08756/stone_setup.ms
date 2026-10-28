(
    if not matchPattern GardenRun pattern:"*/build/drag08756-*/host-*/" do throw "Owned drag campaign required"
    WFEdit=undefined
    for m in WFOwner.modifiers where classof m==CyrusScatterEdit do WFEdit=m
    if WFEdit==undefined do throw "Fixture needs its Cyrus Edit modifier"
    local busy=CyrusPointBusy,suspended=CyrusPointSuspended
    try(
        CyrusPointBusy=true;CyrusPointSuspended=true;WFRoot.setLayerTransfer true
        WFCollider.removeModelSources (for i=1 to WFCollider.sources.count collect i)
        WFCollider.addModelSource (getNodeByName "Stone 1" exact:true)
        WFCollider.amount=1;WFCollider.interactionCollider=true
        WFRoot.setLayerTransfer false
        CyrusPointBusy=busy;CyrusPointSuspended=suspended
        WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
        cyrusEditActiveLayers WFEdit #(WFCollider.editLayerKey)
        cyrusEditCommand WFEdit 1 undefined
        local file=createFile (GardenRun+"stone-setup.txt")
        format "%\n%\n" (WFRoot.interactionsStatistics()) (cyrusEditInspect WFEdit 0 3) to:file;close file
        local preview=CyrusPointOwner WFOwner,bounds=nodeGetBoundingBox (CyrusPointOwner WFOwner) (matrix3 1)
        local centre=(bounds[1]+bounds[2])*0.5,size=distance bounds[1] bounds[2]
        local eye=centre+[size*.6,-size*.8,size*.6],back=normalize (eye-centre),right=normalize (cross [0,0,1] back),up=cross back right
        viewport.setType #view_persp_user;viewport.setTM (inverse (matrix3 right up back eye));viewport.SetRenderLevel #smoothhighlights
        completeRedraw()
    )catch(WFRoot.setLayerTransfer false;CyrusPointBusy=busy;CyrusPointSuspended=suspended;throw())
)
