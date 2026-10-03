-- Acceptance of 1.1 shared planting groups in a disposable host only.
global CyrusGroupsNode,CyrusGroupsSource,CyrusGroupsSurface
(
    local results=#()
    fn require condition message = if not condition do throw message
    fn counts root = (for rows in root.evaluateGroups() collect rows.count)
    fn makeSetup target source names amounts = (
        local node=CyrusScatterObject name:"CYRUS_GROUPS_ACCEPTANCE"
        local root=node.baseObject
        root.surfaceNodes=#(target);root.autoRender=false;root.updateMode=1
        root.viewportMode=3;root.viewportInstances=100000;root.viewportFaces=20000000
        for i=1 to names.count do (
            root.newLayer();root.layerNames[i]=names[i]
            root.layerObjects[i].sources=#(source);root.layerObjects[i].amount=amounts[i]
            root.layerObjects[i].randomSeed=73
        )
        node
    )
    CyrusGroupsSurface=plane name:"CYRUS_GROUPS_SURFACE" width:200 length:200 widthsegs:12 lengthsegs:12
    CyrusGroupsSource=cone name:"CYRUS_GROUPS_ASSET" radius1:1 radius2:0 height:5 sides:8 heightsegs:1 capsegs:1 pos:[130,0,0]
    CyrusGroupsNode=makeSetup CyrusGroupsSurface CyrusGroupsSource #("Grass","Red flowers","Blue flowers","Yellow flowers") #(1000,2000,2000,2000)
    local root=CyrusGroupsNode.baseObject,groups=root.layerObjects
    require (root.groupPolicy==2 and root.uiVersion()=="1.1.0") "New setup did not use shared policy"
    for i=2 to 4 do (
        root.setGroupCoverage groups[i] true
        cyrusBrushSettings groups[i].paintDocument 45 1 0 false 1
        require (cyrusBrushDab groups[i].paintDocument [(i-3)*22,0,100] [0,0,-1] true) "Brush missed shared receiver"
        groups[i].collisionEnabled=true;groups[i].collisionRadius=3
        cyrusBrushDisplay groups[i].paintDocument 2 (color 255 140 35)
        cyrusBrushRefreshMask groups[i].paintDocument
        require ((cyrusBrushStats groups[i].paintDocument)[19]>0) "Continuous coverage was empty"
    )
    for i=1 to 3 do for j=i+1 to 4 do root.setGroupPair groups[i] groups[j] true 6 false true
    root.refreshAll()
    local final=root.evaluateGroups()
    for i=1 to 4 do (
        local state=groups[i].cacheSnapshot()
        require (state[4]=="" and state[5]==final[i].count and state[2]==state[5]) ("Mesh population mismatch: "+state[4])
        require (final[i].count>0) "One flower color disappeared entirely"
        for j=i+1 to 4 do for a in final[i] do for b in final[j] do require (distance a[1].row4 b[1].row4>=5.999) "Pair gap violated"
    )
    append results #("four_group_accepted",counts root)
    local flower=groups[2],spaced=final[2]
    -- Compare the whole shared resolution to a simple sequential oracle,
    -- including external blockers before within-group spacing.
    local candidates=flower.prepareGroup(),oracle=#()
    for row in candidates do (
        local blocked=false
        for keep in oracle while not blocked do if distance row[1].row4 keep[1].row4<6 do blocked=true
        if not blocked do append oracle row
    )
    require (oracle as string==spaced as string) "Mask-first spacing differed from exhaustive oracle"
    append results #("masked_candidates",candidates.count)
    append results #("mask_first_spaced",spaced.count)
    local builds=root.groupCounters(),base=flower.paintCacheStats()
    root.viewportMode=1;root.pointsPerPlant=80;root.previewBudget=500000;root.refreshDisplay()
    require ((flower.cacheSnapshot())[2]==80*spaced.count) "Point Cloud count is not points per accepted plant"
    root.groupCenters=true;root.refreshDisplay()
    require ((flower.cacheSnapshot())[2]==spaced.count) "One centre must mean one plant"
    root.groupCenters=false;root.viewportMode=3;root.viewportInstances=7;root.refreshDisplay()
    require ((flower.cacheSnapshot())[2]==7 and (flower.cacheSnapshot())[5]==spaced.count) "Preview cap changed population"
    require ((root.groupCounters())[1]==builds[1] and (flower.paintCacheStats())[1]==base[1]) "Display rebuilt planting"
    cyrusBrushFill flower.paintDocument 0.0;flower.checkPaintRevision()
    root.refreshDisplay()
    require ((flower.cacheSnapshot())[5]==spaced.count and (flower.cacheSnapshot())[3]) "Manual display lost pending state"
    root.refreshAll()
    require ((counts root)[2]==0) "Erased red flowers survived Update"
    require ((counts root)[1]>=final[1].count) "Grass did not recover erased flower space"
    append results #("after_erasing_red",counts root)

    -- Three coincident groups: A loses to B; C must not see a ghost of A.
    local chainNode=makeSetup CyrusGroupsSurface CyrusGroupsSource #("A","B","C") #(1,1,1)
    local chain=chainNode.baseObject,a=chain.layerObjects[1],b=chain.layerObjects[2],c=chain.layerObjects[3]
    b.groupPriority=30;a.groupPriority=20;c.groupPriority=10
    chain.setGroupPair a b true 1 false false
    chain.setGroupPair a c true 1 false false
    require ((counts chain) as string=="#(0, 1, 1)") "Discarded group became an invisible blocker"
    chain.layerEnabled[3]=false
    require ((counts chain) as string=="#(0, 1, 0)") "Priority did not resolve mutual exclusion"
    local edit=CyrusScatterEdit();addModifier chainNode edit
    local before=chain.evaluateGroups(),old=before[2][1][1].row4
    require (cyrusEditVisibleCount edit==1) "CS Edit exposed rejected candidates"
    cyrusEditSelect edit #(1);cyrusEditCommand edit 4 (transMatrix [100,0,0])
    local moved=chain.evaluateGroups()
    require (moved[1].count==1 and moved[2].count==1) "Moved blocker still reserved its old position"
    require (distance moved[2][1][1].row4 (old+[100,0,0])<0.001) "CS Edit transform was lost"
    require (cyrusEditVisibleCount edit==2) "CS Edit did not publish final plants"
    -- Move the other plant onto the protected plant: preserve and report both.
    cyrusEditSelect edit #(1);cyrusEditCommand edit 4 (transMatrix [100,0,0])
    local conflicts=chain.evaluateGroups()
    require (conflicts[1].count==1 and conflicts[2].count==1) "Spacing silently deleted a manual edit"
    require ((a.groupStats())[3]==1 and (b.groupStats())[3]==1) "Manual conflict was not reported"
    append results #("final_blockers_and_edit",true)
    -- Disabling/hiding have different meanings.
    chain.layerVisible[2]=false
    require ((chain.viewportLayerEntries false).count==1 and (counts chain)[2]==1) "Viewport visibility changed spacing"
    chain.layerEnabled[2]=false
    require ((counts chain)[2]==0) "Disabled group still participated"

    -- A rejected cleanup result must not block a later group.
    local cleanupNode=makeSetup CyrusGroupsSurface CyrusGroupsSource #("High","Low") #(1,1)
    local cleanup=cleanupNode.baseObject,high=cleanup.layerObjects[1],low=cleanup.layerObjects[2]
    high.groupPriority=10;low.groupPriority=0;high.finalCleanup=true;high.finalMinNeighbors=2;high.finalNeighborRadius=1
    cleanup.setGroupPair high low true 1 false false
    require ((counts cleanup) as string=="#(0, 1)") "Cleanup ghost blocked lower group"
    append results #("cleanup_before_blocking",true)

    root.activeLayer=3;local origin=root.layerObjects[3],originID=origin.layerID
    root.copySelectedLayer();local copied=root.selectedLayer()
    require (copied.layerID!=originID and copied.paintDocument!=origin.paintDocument) "Copy shares ownership/history"
    require (root.groupPair copied root.layerObjects[1]>0) "Copy lost pair rules"
    local history=cyrusBrushHistory origin.paintDocument
    cyrusBrushFill copied.paintDocument 0.0
    require (history as string==(cyrusBrushHistory origin.paintDocument) as string) "Copy edits changed original strokes"
    local rules=root.groupRuleA.count
    root.removeLayer()
    require (root.groupRuleA.count<rules and root.layerObjects.count==4) "Remove left dangling pair rules"
    max undo
    require (root.layerObjects.count==5 and root.groupRuleA.count==rules) "Remove Undo lost groups/rules"
    max redo
    require (root.layerObjects.count==4) "Remove Redo failed"
    append results #("copy_remove_undo",true)
    root.viewportInstances=100000;root.selectLayer 3;root.refreshAll()
    select CyrusGroupsNode;max modify mode;root.bindNativeUI()
    local editor=root.brushUI.hwnd
    for i=1 to 20 do (root.selectLayer (1+mod i 4);root.bindNativeUI();require (root.brushUI.hwnd==editor) "Group selection remounted Brush")
    append results #("native_editor_reused",true)
    CSPWriteText (BLDir+"planting-groups-acceptance.json") (CSPObject results)
)
