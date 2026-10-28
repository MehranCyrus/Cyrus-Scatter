(
    if not matchPattern GardenRun pattern:"*/build/drag08756-*/host-*/" do throw "Owned drag campaign required"
    loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/Test Scene/New Plants test 22.max" quiet:true useFileUnits:true
    local report=createFile (GardenRun+"scene-inspection.txt")
    format "VERSION %\nUNITS % %\n" (CyrusLibraryVersion()) units.SystemType units.SystemScale to:report
    for n in objects where classof n.baseObject==AminScatterObject and n.baseObject.overlapOwner==undefined do (
        WFOwner=n;WFRoot=n.baseObject
        format "CONTROLLER %\n" n.name to:report
        for leaf in WFRoot.layerObjects do format "LAYER % count:% sources:% react:% collider:% response:% errors:%\n" leaf.layerID leaf.amount (for n in leaf.sources collect if isValidNode n then n.name else "missing") leaf.interactionReact leaf.interactionCollider leaf.interactionResponse leaf.previewError to:report
        WFGrass=WFRoot.layerObjects[1];WFCollider=WFRoot.layerObjects[2]
        WFEdit=for m in WFOwner.modifiers where classof m==CyrusScatterEdit collect m
    )
    for n in geometry where classof n.baseObject!=AminScatterObject do format "NODE % % SCALE %\n" n.name (classof n) n.scale to:report
    close report
)
