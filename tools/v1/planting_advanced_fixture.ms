-- Additional shared-group correctness and persistence preparation.
(
    fn require condition message = if not condition do throw message
    local results=#(),source=CyrusGroupsSource
    local target=sphere name:"CYRUS_GROUPS_CURVED" radius:50 segs:40 pos:[300,0,0]
    target.scale=[1.3,.8,1.1]
    local node=CyrusScatterObject name:"CYRUS_GROUPS_CURVED_SETUP",root=node.baseObject
    root.surfaceNodes=#(target);root.autoRender=false;root.updateMode=1;root.viewportMode=3;root.newLayer()
    local group=root.layerObjects[1]
    group.sources=#(source);group.amount=4000;group.randomSeed=73
    root.setGroupCoverage group true
    viewport.setType #view_persp_user
    local eye=[300,-250,150],look=normalize([300,0,0]-eye),right=normalize(cross look [0,0,1]),up=cross right look
    viewport.setTM (inverse(matrix3 right up (-look) eye))
    cyrusBrushSettings group.paintDocument 40 1 .5 false 1
    require (cyrusBrushDab group.paintDocument [0,-200,100] [0,1,-.5] true) "Curved brush missed"
    group.collisionEnabled=true;group.collisionRadius=2
    local curved=(root.evaluateGroups())[1]
    require (curved.count>20 and curved.count<4000) "Curved painted population invalid"
    for i=1 to curved.count do for j=i+1 to curved.count do require (distance curved[i][1].row4 curved[j][1].row4>=3.999) "Curved spacing violated"
    cyrusBrushRefreshMask group.paintDocument
    require ((cyrusBrushStats group.paintDocument)[19]>0) "Curved tint missing"
    append results #("curved_nonuniform_scale_placed",curved.count)
    local history=(cyrusBrushHistory group.paintDocument) as string,rejected=false
    target.segs=32
    try(root.evaluateGroups())catch(rejected=true)
    require rejected "Changed topology silently reused placements"
    require ((cyrusBrushHistory group.paintDocument) as string==history) "Topology mismatch lost paint"
    target.segs=40;cyrusBrushBind group.paintDocument
    require ((root.evaluateGroups())[1].count==curved.count) "Restored topology changed placement"
    root.surfaceNodes=#(CyrusGroupsSurface);rejected=false
    try(root.evaluateGroups())catch(rejected=true)
    require rejected "Wrong shared receiving target was silently accepted"
    root.surfaceNodes=#(target)
    require ((root.evaluateGroups())[1].count==curved.count) "Restored shared target lost history"
    append results #("surface_validation_preserves_history",true)

    local modifier=CyrusScatterEdit();addModifier node modifier
    local initial=(root.evaluateGroups())[1],key=initial[1][3],position=initial[1][1].row4
    cyrusEditSelect modifier #(1);cyrusEditCommand modifier 4 (transMatrix [3,4,0])
    local moved=(root.evaluateGroups())[1]
    require (moved[1][3]==key and distance moved[1][1].row4 (position+[3,4,0])<0.001) "Curved CS Edit failed"
    local preparedBuilds=(group.paintCacheStats())[1]
    group.collisionRadius=3
    local respaced=(root.evaluateGroups())[1]
    require (cyrusEditCommand modifier 5 (matrix3 1)) "Spacing invalidated stable Edit binding"
    require ((group.paintCacheStats())[1]==preparedBuilds) "Spacing regenerated candidate distribution"
    cyrusBrushStroke group.paintDocument 1 false 1 40 .5 false
    require ((root.evaluateGroups())[1].count==0 and cyrusEditVisibleCount modifier==0) "Dormant Edit remained visible"
    cyrusBrushStroke group.paintDocument 1 true 1 40 .5 false
    local restored=(root.evaluateGroups())[1]
    require (restored[1][3]==key and distance restored[1][1].row4 moved[1][1].row4<0.001) "Dormant override was lost"
    root.layerVisible[1]=false;root.layerEntries()
    require (cyrusEditVisibleCount modifier==0) "Hidden group had visible Edit handles"
    root.layerVisible[1]=true;root.layerEntries()
    require (cyrusEditVisibleCount modifier==restored.count) "Shown group lost Edit handles"
    cyrusEditSelect modifier #(1);cyrusEditCommand modifier 3 (matrix3 1)
    local cloned=(root.evaluateGroups())[1]
    require (cloned.count==restored.count+1 and (group.groupStats())[3]>=2) "Protected clone was removed or conflict unreported"
    cyrusEditCommand modifier 2 (matrix3 1)
    require ((root.evaluateGroups())[1].count==restored.count) "Edited clone delete failed"
    max undo
    require ((root.evaluateGroups())[1].count==cloned.count) "Edited clone Delete Undo failed"
    max redo
    local staleSeed=group.randomSeed;group.randomSeed+=1;rejected=false
    try(root.evaluateGroups())catch(rejected=true)
    require rejected "Base-generation mismatch was not reported"
    group.randomSeed=staleSeed;cyrusEditCommand modifier 0 (matrix3 1)
    root.evaluateGroups()
    append results #("edit_dormant_spacing_clone_delete_visibility",true)

    -- Explicit legacy conversion is undoable; existing Edits are never reset.
    local oldNode=CyrusScatterObject name:"CYRUS_GROUPS_LEGACY_TEST",old=oldNode.baseObject
    old.groupPolicy=1;old.surfaceNodes=#(CyrusGroupsSurface);old.autoRender=false;old.updateMode=1
    for i=1 to 2 do (old.newLayer();old.layerObjects[i].sources=#(source);old.layerObjects[i].amount=10)
    old.layerObjects[1].overlapEnabled=true;old.layerObjects[1].overlapBlockers=#(2);old.layerObjects[1].overlapRadius=4;old.layerObjects[1].overlapGap=2
    old.groupConversion()
    require (old.groupPolicy==2 and old.groupRuleA.count==1 and old.groupRuleGap[1]==6) "Legacy rules not imported"
    max undo
    require (old.groupPolicy==1 and old.groupRuleA.count==0) "Legacy conversion Undo failed"
    local legacyEdit=CyrusScatterEdit();addModifier oldNode legacyEdit
    rejected=false;try(old.groupConversion())catch(rejected=true)
    require (rejected and old.groupPolicy==1) "Legacy conversion reset manual Edits"
    append results #("conversion_undo_and_edit_guard",true)

    -- Footprints are radius approximations, with edited/source scale respected.
    local footprintNode=CyrusScatterObject name:"CYRUS_GROUPS_FOOTPRINT",footprint=footprintNode.baseObject
    footprint.surfaceNodes=#(CyrusGroupsSurface);footprint.autoRender=false;footprint.updateMode=1
    for i=1 to 2 do (footprint.newLayer();local g=footprint.layerObjects[i];g.sources=#(source);g.amount=100;g.sourceRadii=#(3.0);g.sourceFollowScale=#(true);g.sourceScales=#(2.0))
    footprint.setGroupPair footprint.layerObjects[1] footprint.layerObjects[2] true 2 true true
    local fp=footprint.evaluateGroups()
    for a in fp[1] do for b in fp[2] do require (distance a[1].row4 b[1].row4>=13.999) "Scaled source footprints overlapped"
    append results #("scaled_footprint_rule",true)
    -- Real-time production signature responds to shared rules; display does not.
    footprint.updateMode=2
    local signature=CyrusPFKey()
    footprint.setGroupPair footprint.layerObjects[1] footprint.layerObjects[2] true 3 true true
    require (CyrusPFKey()!=signature) "Render cache ignored pair edits"
    footprint.updateMode=1

    -- Save exact IDs, rules, histories, accepted transforms, and priorities.
    local records=#()
    for owner in #(CyrusGroupsNode,node,footprintNode) do (
        local r=owner.baseObject;r.refreshAll()
        local groupRecords=#()
        for g in r.layerObjects do append groupRecords #(g.layerID,g.editLayerKey,g.groupPriority,g.paintEnabled,if g.paintDocument==undefined then "none" else (cyrusBrushHistory g.paintDocument) as string,cyrusEditFingerprint (g.placements (g.validSources()) previewOnly:true) "reopen")
        append records #(owner.name,r.groupPolicy,(for p in #(#groupRuleA,#groupRuleB,#groupRuleEnabled,#groupRuleGap,#groupRuleFootprints,#groupRulePlanar) collect getProperty r p),groupRecords)
    )
    local expected=createFile (BLDir+"groups-reopen-expected.ms")
    with printAllElements on format "global CyrusGroupsReopenExpected=%\n" records to:expected
    close expected
    saveMaxFile (BLDir+"groups-qualified.max") quiet:true
    append results #("saved_for_fresh_process",true)
    CSPWriteText (BLDir+"planting-advanced-acceptance.json") (CSPObject results)
)
