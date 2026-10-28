global DGStone
(
    WFRoot.interactionsEnsure();CyrusPointSync()
    local tree=WFRoot.layerObjects[3],source=(tree.validSources())[1],bbox=nodeGetBoundingBox source source.transform
    local rows=cyrusPlacementTransformGroups WFRoot.groupSnapshotRows[3],tm=rows[1][1]
    WFCollider.interactionCollider=false
    DGStone=copy (getNodeByName "Stone 1" exact:true);DGStone.name="DG_Stone_Viewport_Test"
    DGStone.scale*=3;DGStone.pos=(tm.row4+[0,0,(bbox[2].z-bbox[1].z)*.55])
    WFRoot.interactionSceneColliders=#(DGStone)
    WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync();CyrusSceneColliderWatch()
    local out=createFile (GardenRun+"scene-stone.txt")
    format "tree:%\nstone:%\n%\n" tm DGStone.transform (WFRoot.interactionsStatistics()) to:out;close out
    local centre=tm.row4+[0,0,40],size=140.0,eye=centre+[size,-size*1.4,size*.6],back=normalize (eye-centre),right=normalize (cross [0,0,1] back),up=cross back right
    viewport.setTM (inverse (matrix3 right up back eye));completeRedraw()
    local bitmap=gw.getViewportDib();bitmap.filename=GardenRun+"scene-stone.png";save bitmap;close bitmap
)
