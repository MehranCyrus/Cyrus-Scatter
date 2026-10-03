-- Source policy, exact Bake, stacked Edit, and display-only overlay regression.
-- Run only in a disposable profile after planting_groups_fixture.ms.
(
    fn require condition message = if not condition do throw message
    local results=#(),target=CyrusGroupsSurface,source=CyrusGroupsSource
    local node=CyrusScatterObject name:"CYRUS_GROUPS_OUTPUT",root=node.baseObject
    root.surfaceNodes=#(target);root.autoRender=false;root.updateMode=1;root.newLayer()
    local group=root.layerObjects[1],second=sphere name:"CYRUS_GROUPS_POINT_ASSET" radius:2 segs:8 pos:[130,40,0]
    group.sources=#(source,second);group.sourceWeights=#(.25,.75);group.amount=64;group.randomSeed=73
    root.setGroupCoverage group true;cyrusBrushFill group.paintDocument 1.0
    group.sourceEmpty=#(false,true)
    local empty=group.placements (group.validSources()) previewOnly:true
    require (empty.count>0 and empty.count<64) "Empty asset policy failed"
    group.sourcePoint=#(false,true)
    local preview=group.placements (group.validSources()) previewOnly:true
    local finalRows=group.placements (group.validSources())
    require (preview.count==64 and finalRows.count==empty.count) "Point-only asset leaked to final output"
    for row in finalRows do require (row[2]==1) "Wrong final asset index"
    root.layerVisible[1]=false
    require (group.bakeInstances node==finalRows.count) "Hidden group's Bake omitted final plants"
    for i=1 to finalRows.count do for axis=1 to 4 do require (distance (group.bakedNodes[i].transform)[axis] finalRows[i][1][axis]<.0001) "Bake transform mismatch"
    group.clearBaked node;root.layerVisible[1]=true
    append results #("empty_point_source_policy_and_exact_hidden_bake",true)
    group.sources=#(source);group.sourceWeights=#();group.sourceEmpty=#();group.sourcePoint=#()
    group.paintEnabled=false;group.distributionMode=3;group.advancedAxes=false
    group.densityMap=Gradient color1:black color2:black color3:black
    require ((group.placements #(source) previewOnly:true).count==0) "Black texture density ignored"
    group.densityMap=Gradient color1:white color2:white color3:white
    require ((group.placements #(source) previewOnly:true).count==64) "White texture density changed population"
    group.densityMap.color1=black;group.densityMap.color2=black;group.densityMap.color3=black
    root.refreshAll()
    require (group.generatedCount==0) "Update reused an edited density texture"
    group.densityMap.color1=white;group.densityMap.color2=white;group.densityMap.color3=white
    root.refreshAll()
    require (group.generatedCount==64) "Update did not rebuild the edited white density texture"
    root.updateMode=2
    local renderSignature=CyrusPFKey()
    group.densityMap=Gradient color1:black color2:black color3:black
    require (CyrusPFKey()!=renderSignature) "Render signature missed density-map replacement"
    root.updateMode=1
    group.distributionMode=1;group.densityMap=undefined;group.paintEnabled=true
    append results #("texture_density_dispatch",true)

    local lower=CyrusScatterEdit();addModifier node lower
    local before=root.evaluateGroups(),position=before[1][1][1].row4,key=before[1][1][3]
    cyrusEditSelect lower #(1);cyrusEditCommand lower 4 (transMatrix [3,0,0]);root.evaluateGroups()
    local upper=CyrusScatterEdit();addModifier node upper;root.evaluateGroups()
    cyrusEditSelect upper #(1);cyrusEditCommand upper 4 (transMatrix [0,4,0])
    local stacked=(root.evaluateGroups())[1]
    require (stacked[1][3]==key and distance stacked[1][1].row4 (position+[3,4,0])<.001) "Stacked Edit lost identity or composition"
    require (cyrusEditVisibleCount upper==64 and cyrusEditVisibleCount lower==64) "Stacked Edit published wrong handles"
    cyrusEditCommand upper 3 (matrix3 1)
    require ((root.evaluateGroups())[1].count==65 and cyrusEditVisibleCount upper==65 and cyrusEditVisibleCount lower==64) "Downstream clone polluted upstream Edit"
    append results #("stacked_edit_move_and_clone",true)
    while node.modifiers.count>0 do deleteModifier node 1

    -- The new display selector must work for retained legacy setups as well.
    root.groupPolicy=1;root.pointsPerPlant=80;root.previewBudget=100000;root.refreshAll()
    root.setGroupDisplay 4
    require ((group.cacheSnapshot())[2]==64 and group.showCenters) "Legacy Plant centres did not display one per plant"
    root.setGroupDisplay 1
    require ((group.cacheSnapshot())[2]==5120 and not group.showCenters) "Legacy Point Cloud was stuck in centres"
    root.groupPolicy=2;root.setGroupDisplay 3;root.refreshAll()
    append results #("legacy_display_selector",true)

    select node;max modify mode;root.bindNativeUI();CyrusStartBrush root group
    cyrusBrushRefreshMask group.paintDocument;redrawViews()
    local state=cyrusBrushStats group.paintDocument,builds=root.groupCounters(),tm=viewport.getTM()
    require (state[19]>0 and state[20]>0) "Coverage not submitted to viewport"
    for i=1 to 15 do (viewport.setTM ((rotateZMatrix (i*.25))*tm);redrawViews())
    viewport.setTM tm
    local after=cyrusBrushStats group.paintDocument
    require (after[8]==state[8] and after[9]==state[9] and after[10]==state[10] and (root.groupCounters())[1]==builds[1]) "Camera navigation recalculated coverage or placements"
    group.paintView=1;cyrusBrushDisplay group.paintDocument 1 (color 90 200 150);redrawViews()
    local sampleDraws=(cyrusBrushStats group.paintDocument)[20]
    require (sampleDraws>after[20]) "Coverage samples were not drawn"
    group.paintView=0;cyrusBrushDisplay group.paintDocument 0 (color 90 200 150);redrawViews()
    require ((cyrusBrushStats group.paintDocument)[20]==sampleDraws) "Overlay Off still drew"
    CyrusStopBrush()
    group.paintView=2;root.refreshAll()
    append results #("overlay_modes_camera_draw_only",true)
    CSPWriteText (BLDir+"planting-output-acceptance.json") (CSPObject results)
)
