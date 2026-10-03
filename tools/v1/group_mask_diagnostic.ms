-- Diagnostic characterization of the shipped 1.0.1 behavior, not acceptance
-- of the proposed planting-group solver. Run only in a disposable v1 host.
(
    local evidence=#()
    local target=plane name:"CYRUS_GROUP_AUDIT_PLANE" width:200 length:200 widthsegs:16 lengthsegs:16
    local source=cone name:"CYRUS_GROUP_AUDIT_PLANT" radius1:1 radius2:0 height:5 sides:8 heightsegs:1 capsegs:1 pos:[130,0,0]
    local node=CyrusScatterObject name:"CYRUS_GROUP_AUDIT_PREVIEW"
    local root=node.baseObject
    root.surfaceNodes=#(target);root.autoRender=false;root.updateMode=1
    root.viewportMode=3;root.viewportInstances=100000;root.viewportFaces=20000000
    root.newLayer()
    local layer=root.layerObjects[1]
    layer.sources=#(source);layer.amount=200;layer.randomSeed=73
    layer.paintDocument=cyrusBrushCreate target;layer.paintIdentity=true;layer.paintEnabled=true
    cyrusBrushSettings layer.paintDocument 40 1 0 false 1
    if not (cyrusBrushDab layer.paintDocument [0,0,100] [0,0,-1] true) do throw "Plane dab missed"
    cyrusBrushRefreshMask layer.paintDocument
    local overlay200=(cyrusBrushStats layer.paintDocument)[16]
    root.refreshAll()
    local mesh200=layer.cacheSnapshot()
    if mesh200[4]!="" or mesh200[5]<=0 or mesh200[5]>=200 or mesh200[2]!=mesh200[5] do throw "Uncapped Mesh did not show all accepted placements"
    if overlay200<=mesh200[5] do throw "Fixture did not reproduce independent overlay density"
    append evidence #("flat_base_candidates",200)
    append evidence #("flat_overlay_samples",overlay200)
    append evidence #("flat_accepted_plants",mesh200[5])
    append evidence #("flat_mesh_instances",mesh200[2])

    root.viewportMode=1;root.pointsPerPlant=80;root.previewBudget=500000
    root.refreshAll()
    local cloud=layer.cacheSnapshot()
    if cloud[5]!=mesh200[5] or cloud[2]!=80*mesh200[5] do throw "Point Cloud population changed or unexpected point count"
    append evidence #("point_cloud_points",cloud[2])
    layer.showCenters=true;root.refreshAll()
    local centers=layer.cacheSnapshot()
    if centers[2]!=mesh200[5] or centers[5]!=mesh200[5] do throw "Centers and Mesh disagree on the population"
    append evidence #("placement_centers",centers[2])
    layer.showCenters=false;root.viewportMode=3
    root.viewportInstances=7;root.refreshAll()
    local capped=layer.cacheSnapshot()
    if capped[2]!=7 or capped[5]!=mesh200[5] do throw "Instance limit changed the placement population"
    append evidence #("instance_limited_shown",capped[2])
    root.viewportInstances=100000
    local sourceMesh=snapshotAsMesh source
    root.viewportFaces=sourceMesh.numfaces*5;root.refreshAll()
    local faceCapped=layer.cacheSnapshot()
    if faceCapped[2]!=5 or faceCapped[5]!=mesh200[5] do throw "Face limit changed the placement population"
    append evidence #("face_limited_shown",faceCapped[2])
    root.viewportFaces=20000000
    layer.amount=4000;root.refreshAll();cyrusBrushRefreshMask layer.paintDocument
    local mesh4000=layer.cacheSnapshot(),overlay4000=(cyrusBrushStats layer.paintDocument)[16]
    if overlay4000!=overlay200 or mesh4000[5]<=mesh200[5] or mesh4000[2]!=mesh4000[5] do throw "Overlay unexpectedly follows candidate Count"
    append evidence #("larger_base_candidates",4000)
    append evidence #("larger_overlay_samples",overlay4000)
    append evidence #("larger_accepted_plants",mesh4000[5])
    cyrusBrushFill layer.paintDocument 0.0
    layer.checkPaintRevision();cyrusBrushRefreshMask layer.paintDocument
    local stale=layer.cacheSnapshot()
    if not stale[3] or stale[5]!=mesh4000[5] or stale[6]!=mesh4000[6] do throw "Manual mode did not preserve the last published preview"
    append evidence #("manual_stale_plants",stale[5])
    append evidence #("manual_current_overlay_samples",(cyrusBrushStats layer.paintDocument)[16])
    root.refreshAll()
    if (layer.cacheSnapshot())[5]!=0 do throw "Manual Update did not publish the empty mask"
    append evidence #("manual_updated_plants",(layer.cacheSnapshot())[5])

    local curved=sphere name:"CYRUS_GROUP_AUDIT_SPHERE" radius:50 segs:48 pos:[300,0,0]
    local curvedNode=CyrusScatterObject name:"CYRUS_GROUP_AUDIT_CURVED"
    local curvedRoot=curvedNode.baseObject
    curvedRoot.surfaceNodes=#(curved);curvedRoot.autoRender=false;curvedRoot.updateMode=1
    curvedRoot.viewportMode=3;curvedRoot.newLayer()
    local curvedLayer=curvedRoot.layerObjects[1]
    curvedLayer.sources=#(source);curvedLayer.amount=200;curvedLayer.randomSeed=73
    curvedLayer.paintDocument=cyrusBrushCreate curved;curvedLayer.paintIdentity=true;curvedLayer.paintEnabled=true
    viewport.setType #view_persp_user
    local eye=[300,-250,150],look=normalize([300,0,0]-eye),right=normalize(cross look [0,0,1]),up=cross right look
    viewport.setTM (inverse(matrix3 right up (-look) eye))
    cyrusBrushSettings curvedLayer.paintDocument 40 1 .5 false 1
    if not (cyrusBrushDab curvedLayer.paintDocument [0,-200,100] [0,1,-.5] true) do throw "Curved dab missed"
    curvedRoot.refreshAll();cyrusBrushRefreshMask curvedLayer.paintDocument
    local curvedState=curvedLayer.cacheSnapshot(),curvedOverlay=(cyrusBrushStats curvedLayer.paintDocument)[16]
    if curvedState[4]!="" or curvedState[5]<=0 or curvedState[2]!=curvedState[5] or curvedOverlay<=curvedState[5] do throw "Curved fixture did not reproduce independent mask preview"
    append evidence #("curved_overlay_samples",curvedOverlay)
    append evidence #("curved_accepted_plants",curvedState[5])
    append evidence #("curved_mesh_instances",curvedState[2])

    -- One shared receiving surface already supports independent plant groups.
    local garden=CyrusScatterObject name:"CYRUS_GROUP_AUDIT_GARDEN"
    local gardenRoot=garden.baseObject
    gardenRoot.surfaceNodes=#(target);gardenRoot.autoRender=false;gardenRoot.updateMode=1
    local names=#("Grass","Red flowers","Blue flowers","Yellow flowers")
    for i=1 to 4 do (
        gardenRoot.newLayer();gardenRoot.layerNames[i]=names[i]
        local group=gardenRoot.layerObjects[i]
        group.sources=#(source);group.amount=1000;group.randomSeed=100+i
        if i>1 do (
            group.paintDocument=cyrusBrushCreate target;group.paintIdentity=true;group.paintEnabled=true
            cyrusBrushSettings group.paintDocument 55 1 0 false 1
            cyrusBrushDab group.paintDocument [(i-3)*20,0,100] [0,0,-1] true
        )
    )
    local before=for group in gardenRoot.layerObjects collect (group.placements #(source) previewOnly:true).count
    local grass=gardenRoot.layerObjects[1]
    grass.overlapEnabled=true;grass.overlapRadius=4;grass.overlapBlockers=#(2,3,4)
    local blockedGrass=(grass.placements #(source) previewOnly:true).count
    if blockedGrass>=before[1] do throw "Grass did not avoid painted flower groups"
    cyrusBrushFill gardenRoot.layerObjects[2].paintDocument 0.0
    local after=for group in gardenRoot.layerObjects collect (group.placements #(source) previewOnly:true).count
    if after[2]!=0 or after[3]!=before[3] or after[4]!=before[4] do throw "Editing one group's mask changed another group's mask"
    append evidence #("four_group_names",names)
    append evidence #("four_group_initial_counts",before)
    append evidence #("grass_avoiding_all_flowers",blockedGrass)
    append evidence #("four_group_after_erasing_red",after)

    -- Characterize existing raw-blocker semantics. These assertions expose the
    -- limitation; a future accepted-placement solver must have different tests.
    local collisionNode=CyrusScatterObject name:"CYRUS_GROUP_AUDIT_BLOCKERS"
    local collisionRoot=collisionNode.baseObject
    collisionRoot.surfaceNodes=#(target);collisionRoot.autoRender=false;collisionRoot.updateMode=1
    for i=1 to 3 do (
        collisionRoot.newLayer()
        local group=collisionRoot.layerObjects[i]
        group.sources=#(source);group.amount=1;group.randomSeed=73
        group.overlapRadius=1;group.overlapGap=0;group.overlapPlanar=false
    )
    local a=collisionRoot.layerObjects[1],b=collisionRoot.layerObjects[2],c=collisionRoot.layerObjects[3]
    a.overlapEnabled=true;a.overlapBlockers=#(2)
    c.overlapEnabled=true;c.overlapBlockers=#(1)
    local chain=for group in #(a,b,c) collect (group.placements #(source) previewOnly:true).count
    local rawA=(a.cachedBlockerRows #(source)).count
    if chain as string!="#(0, 1, 0)" or rawA!=1 do throw "Raw-blocker characterization changed"
    append evidence #("blocker_chain_final_a_b_c",chain)
    append evidence #("blocker_chain_raw_a",rawA)
    b.overlapEnabled=true;b.overlapBlockers=#(1)
    local mutual=for group in #(a,b) collect (group.placements #(source) previewOnly:true).count
    if mutual as string!="#(0, 0)" do throw "Mutual raw-blocker characterization changed"
    append evidence #("mutual_blockers_final_a_b",mutual)

    -- A moved blocker still reserves its original location in the raw cache.
    b.overlapEnabled=false;collisionRoot.layerEnabled[3]=false
    local modifier=CyrusScatterEdit()
    addModifier collisionNode modifier
    local initialB=b.placements #(source) previewOnly:true
    if initialB.count!=1 do throw "Could not prepare edited blocker"
    local oldB=initialB[1][1].row4
    cyrusEditSelect modifier #(1)
    cyrusEditCommand modifier 4 (transMatrix [500,0,0])
    local movedB=b.placements #(source) previewOnly:true
    if distance movedB[1][1].row4 (oldB+[500,0,0])>0.001 do throw "Blocker edit failed"
    -- Force a fresh raw-cache key as well; this is not only stale-cache reuse.
    b.overlapGap=0.125
    local rawB=b.cachedBlockerRows #(source)
    local afterMoveA=a.placements #(source) previewOnly:true
    if distance rawB[1][1].row4 oldB>0.001 or afterMoveA.count!=0 do throw "Edited raw-blocker characterization changed"
    append evidence #("edited_blocker_move_distance",distance movedB[1][1].row4 oldB)
    append evidence #("edited_blocker_raw_move_distance",distance rawB[1][1].row4 oldB)
    append evidence #("blocked_group_after_blocker_moved_away",afterMoveA.count)

    -- Within-group collision currently happens before painted membership.
    layer.amount=2000;layer.collisionRadius=10;layer.collisionEnabled=true
    cyrusBrushDab layer.paintDocument [0,0,100] [0,0,-1] true
    local spacedThenPainted=layer.placements #(source) previewOnly:true
    local preMaskCount=(layer.paintCacheStats())[3]
    layer.collisionEnabled=false
    local paintedUnspaced=layer.placements #(source) previewOnly:true
    local freeRejected=0
    local survivingIDs=for row in spacedThenPainted collect row[3]
    for candidate in paintedUnspaced where findItem survivingIDs candidate[3]==0 do (
        local hasNeighbor=false
        for placed in spacedThenPainted while not hasNeighbor do if distance candidate[1].row4 placed[1].row4<20 do hasNeighbor=true
        if not hasNeighbor do freeRejected+=1
    )
    if freeRejected==0 do throw "Fixture did not expose collision-before-mask underfill"
    append evidence #("within_group_base_candidates",2000)
    append evidence #("within_group_after_spacing_before_mask",preMaskCount)
    append evidence #("within_group_after_spacing_and_mask",spacedThenPainted.count)
    append evidence #("within_group_mask_without_spacing",paintedUnspaced.count)
    append evidence #("within_group_rejected_candidates_clear_of_final_plants",freeRejected)
    append evidence #("script_version",root.uiVersion())
    append evidence #("fixture_scope","Synthetic installed Max 2027 API diagnostics; not the live artist scene or mouse gesture qualification")
    CSPWriteText (BLDir+"group-mask-diagnostic.json") (CSPObject evidence)
)
