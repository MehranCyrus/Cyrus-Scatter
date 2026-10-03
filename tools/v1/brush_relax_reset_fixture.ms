-- Script/UI patch acceptance. Use a new disposable profile, never an artist scene.
global CyrusPatchNode,CyrusPatchLayer,CyrusPatchPlain,CyrusPatchSource,CyrusPatchRowsEqual
fn CyrusPatchRowsEqual a b = (
    if a.count!=b.count do return false
    for i=1 to a.count do (
        if a[i].count!=b[i].count do return false
        for j=1 to a[i].count where a[i][j]!=b[i][j] do return false
    )
    true
)
(
    local surface=plane name:"CYRUS_PATCH_SURFACE" width:200 length:200 widthsegs:16 lengthsegs:16
    CyrusPatchSource=cone name:"CYRUS_PATCH_SOURCE" radius1:2 radius2:0 height:10 sides:8 heightsegs:1 capsegs:1 pos:[130,0,0]
    hide CyrusPatchSource
    CyrusPatchNode=CyrusScatterObject name:"CYRUS_PATCH_SCATTER"
    local root=CyrusPatchNode.baseObject
    root.surfaceNodes=#(surface);root.viewportMode=3;root.updateMode=1;root.autoRender=false
    root.newLayer();root.layerNames[1]="Painted"
    local layer=root.selectedLayer();CyrusPatchLayer=layer
    layer.sources=#(CyrusPatchSource);layer.amount=4000;layer.randomSeed=73
    layer.paintDocument=cyrusBrushCreate surface;layer.paintIdentity=true;layer.paintEnabled=true
    cyrusBrushSettings layer.paintDocument 45 1 .5 false 1
    cyrusBrushDab layer.paintDocument [0,0,100] [0,0,-1] true
    local baseline=layer.placements #(CyrusPatchSource) previewOnly:true
    if baseline.count==0 do throw "Patch Brush fixture is empty"
    local history=cyrusBrushHistory layer.paintDocument
    layer.relaxEnabled=true;layer.relaxSpacing=10;layer.relaxIterations=3;layer.relaxStrength=.6
    layer.finalRelax=true;layer.finalStrength=.6;layer.finalIterations=3;layer.finalMaxMove=5
    local paused=layer.placements #(CyrusPatchSource) previewOnly:true
    if not CyrusPatchRowsEqual baseline paused do throw "Paused Relax moved or removed masked candidates"
    if not layer.relaxEnabled or not layer.finalRelax do throw "Pause deleted saved Relax settings"
    if not CyrusPatchRowsEqual (cyrusBrushHistory layer.paintDocument) history do throw "Pause modified Brush history"
    root.refreshAll()
    if layer.previewError!="" or layer.generatedCount!=baseline.count do throw "Masked Relax failed publication"
    select CyrusPatchNode;max modify mode;root.bindNativeUI()
    if root.spacingUI.spacingSpin.enabled or root.separationUI.finalStrengthSpin.enabled do throw "Paused Relax controls are still editable"
    if findString root.mainUI.countInfo.text "Relax paused by Brush"==undefined do throw "Layer has no paused-setting notice"
    local published=layer.cacheSnapshot(),builds=(layer.paintCacheStats())[1]
    for i=1 to 20 do root.bindNativeUI()
    if (layer.cacheSnapshot())[6]!=published[6] or (layer.paintCacheStats())[1]!=builds do throw "Compatibility UI generated geometry"

    -- Mask-off must invalidate the previously unrelaxed cached base.
    layer.paintEnabled=false;root.syncBrushCompatibility()
    if not root.spacingUI.spacingSpin.enabled or not root.separationUI.finalStrengthSpin.enabled do throw "Mask-off did not restore Relax controls"
    local relaxed=layer.placements #(CyrusPatchSource) previewOnly:true
    if (layer.paintCacheStats())[1]<=builds do throw "Effective Relax change reused unrelaxed base"
    layer.relaxEnabled=false;layer.finalRelax=false
    local unrelaxed=layer.placements #(CyrusPatchSource) previewOnly:true
    if CyrusPatchRowsEqual relaxed unrelaxed do throw "Mask-off Relax did not actually move points"
    layer.paintEnabled=true;layer.relaxEnabled=true;layer.finalRelax=true
    if not CyrusPatchRowsEqual baseline (layer.placements #(CyrusPatchSource) previewOnly:true) do throw "Re-enabled mask did not restore stable painted candidates"
    layer.collisionEnabled=true;layer.collisionRadius=2
    layer.finalCleanup=true;layer.finalNeighborRadius=30;layer.finalMinNeighbors=1;layer.finalMinIsland=1
    local guarded=layer.placements #(CyrusPatchSource) previewOnly:true
    layer.relaxEnabled=false;layer.finalRelax=false
    if not CyrusPatchRowsEqual guarded (layer.placements #(CyrusPatchSource) previewOnly:true) do throw "Pause changed collision or final-cleanup output"

    -- A normal layer keeps its existing solver and is independent of selection.
    root.newLayer();root.layerNames[2]="Unpainted"
    local plain=root.selectedLayer();CyrusPatchPlain=plain
    plain.sources=#(CyrusPatchSource);plain.amount=700
    plain.paintEnabled=true -- A flag without a document is not an active mask.
    plain.relaxEnabled=true;plain.relaxSpacing=10;plain.relaxIterations=3
    root.refreshAll();root.bindNativeUI()
    if plain.previewError!="" or not root.spacingUI.relaxCheck.enabled or not root.spacingUI.spacingSpin.enabled do throw "Unpainted layer lost Relax support"
    root.selectLayer 1;root.bindNativeUI()
    if root.spacingUI.relaxCheck.enabled do throw "Layer switch enabled masked Relax"
    root.selectLayer 2;root.bindNativeUI()
    if not root.spacingUI.relaxCheck.enabled do throw "Layer switch left normal Relax disabled"
    CSPWriteText (BLDir+"brush-relax-patch.json") (CSPObject #(#("masked_placements_preserved",baseline.count),#("settings_and_history_preserved",true),#("mask_off_relax_moves_points",true),#("effective_relax_invalidates_base",true),#("collision_and_cleanup_preserved",true),#("unpainted_relax_supported",true),#("selection_controls_correct",true),#("passive_ui_zero_generation",true)))

    -- Group resets use one native Undo action and keep unrelated data intact.
    root.updateMode=1;root.refreshAll();root.bindNativeUI()
    local rotations=#(#rotXMin,#rotXMax,#rotYMin,#rotYMax,#rotZMin,#rotZMax,#tiltDegrees,#yawMinimum,#yawMaximum)
    local scales=#(#sclXMin,#sclXMax,#sclYMin,#sclYMax,#sclZMin,#sclZMax,#scaleMinimum,#scaleMaximum)
    local whole=#(#wholeScaleMin,#wholeScaleMax)
    local movements=#(#movXMin,#movXMax,#movYMin,#movYMax,#movZMin,#movZMax,#movementRange)
    local groups=#(rotations,scales,whole,movements),kinds=#(#rotation,#scale,#wholeScale,#movement),allFields=#()
    for fields in groups do join allFields fields
    undo off (
        plain.setLayerTransfer true
        for i=1 to allFields.count do setProperty plain allFields[i] (1.5+i*.1)
        plain.setLayerTransfer false
    )
    root.bindNativeUI()
    local initial=for field in allFields collect getProperty plain field
    local other=for field in allFields collect getProperty layer field
    local controlHandle=root.randomUI.hwnd
    for group=1 to kinds.count do (
        local priorCount=plain.generatedCount,priorBuild=(plain.cacheSnapshot())[6]
        if not root.resetSelectedRandomization kinds[group] do throw "Native reset handler did not run"
        for i=1 to allFields.count do (
            local expected=if findItem groups[group] allFields[i]>0 then (if group==2 or group==3 then 1.0 else 0.0) else initial[i]
            if (getProperty plain allFields[i])!=expected do throw "Reset changed the wrong group or neutral value"
            if (getProperty layer allFields[i])!=other[i] do throw "Reset changed another layer"
        )
        if root.updateMode!=1 or plain.updateMode!=1 or plain.generatedCount!=priorCount or (plain.cacheSnapshot())[6]!=priorBuild do throw "Manual reset published without Update"
        if root.randomUI.hwnd!=controlHandle do throw "Reset remounted the Randomize rollout"
        max undo
        for i=1 to allFields.count where (getProperty plain allFields[i])!=initial[i] do throw "One Undo did not restore the entire reset group"
        max redo
        for field in groups[group] where (getProperty plain field)!=(if group==2 or group==3 then 1.0 else 0.0) do throw "Redo did not restore reset"
        max undo
    )
    CSPWriteText (BLDir+"random-reset-patch.json") (CSPObject #(#("groups",4),#("rotation_zero",true),#("scale_one",true),#("whole_scale_one",true),#("movement_zero",true),#("legacy_ranges_reset",true),#("unrelated_groups_and_layer_preserved",true),#("single_undo_and_redo",true),#("native_editor_reused",true),#("manual_publication_preserved",true)))
    -- Neutralize the fixture for the subsequent interactive button check.
    undo off (for kind in kinds do plain.resetRandomization kind)
    plain.relaxEnabled=false;plain.paintEnabled=false;root.refreshAll();root.bindNativeUI()
)
