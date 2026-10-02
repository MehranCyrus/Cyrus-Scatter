module.exports=function(s){
 s=s.replace('version:20','version:22');
 s=s.replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#overlapEnabled,#overlapRadius,#overlapGap,#overlapPlanar,#overlapBlockers,');
 s=s.replace('AminScatterLayerTabs=#(','AminScatterLayerTabs=#(#overlapBlockers,');
 s=s.replace('    parameters sourceTransformSettings (',`    local overlapOwner=undefined,overlapBefore=0,overlapAfter=0
    parameters overlapSettings (
        overlapEnabled type:#boolean default:false
        overlapRadius type:#worldunits default:10
        overlapGap type:#worldunits default:0
        overlapPlanar type:#boolean default:true
        overlapBlockers type:#intTab tabSize:0 tabSizeVariable:true
        on overlapEnabled set v do dirty=true
        on overlapRadius set v do dirty=true
        on overlapGap set v do dirty=true
        on overlapPlanar set v do dirty=true
        on overlapBlockers set v i do dirty=true
    )
    fn setOverlapOwner root = (overlapOwner=root)
    fn overlapStats = (#(overlapBefore,overlapBefore-overlapAfter,overlapAfter))
    parameters sourceTransformSettings (`);
 s=s.replace('fn placements plants previewOnly:false = (','fn placements plants previewOnly:false rawOnly:false = (');
 s=s.replace('        result\n    )\n    fn refreshPreview',`        if not rawOnly do (
            overlapBefore=result.count
            if overlapEnabled and overlapOwner!=undefined and overlapRadius+overlapGap>0 do (
                local obstacles=#()
                for idx in overlapBlockers where idx>0 and idx<=overlapOwner.layerObjects.count do (
                    local blocker=overlapOwner.layerObjects[idx]
                    if blocker!=this and overlapOwner.layerEnabled[idx] do (
                        overlapOwner.syncLayerSurface blocker
                        local src=blocker.validSources()
                        if src.count>0 or blocker.showCenters do join obstacles (blocker.placements src previewOnly:blocker.showCenters rawOnly:true)
                    )
                )
                result=cyrusRemoveOverlaps result obstacles (overlapRadius+overlapGap) overlapPlanar
            )
            overlapAfter=result.count
        )
        result
    )
    fn refreshPreview`);
 s=s.replace('    fn syncLayerSurface obj = (','    fn syncLayerSurface obj = (\n        obj.setOverlapOwner this');
 s=s.replace('layerEnabled type:#boolTab tabSize:0 tabSizeVariable:true','layerEnabled type:#boolTab tabSize:0 tabSizeVariable:true\n        on layerEnabled set v i do (for layer in layerObjects do layer.dirty=true)');
 s=s.replace('        entries\n    )\n    fn migrateLayers',`        if (for e in entries where layerEnabled[e[1]] and e[2].dirty collect e).count>0 do
            for e in entries where layerEnabled[e[1]] and e[2].overlapEnabled do e[2].dirty=true
        entries
    )
    fn migrateLayers`);
 s=s.replace('                deleteItem layerObjects i;deleteItem layerNames i;deleteItem layerEnabled i',`                -- Remap surviving indices on deletion.
                for layer in layerObjects do (
                    layer.overlapBlockers=for k in layer.overlapBlockers where k!=i collect (if k>i then k-1 else k)
                    
                    layer.dirty=true
                )
                deleteItem layerObjects i;deleteItem layerNames i;deleteItem layerEnabled i`);
 // Only the root manager owns this UI. Persist indices and remap on deletion.
 s=s.replace('        fn refresh = (\n            refreshing=true;layerList.BeginUpdate()',`        local blockerRows=#()
        label overlapTitle "Remove Overlaps" pos:[6,226] width:146
        checkbox overlapCheck "Enable" pos:[6,249] width:140
        multiListBox blockerList "Blocking layers (Ctrl/Shift)" pos:[6,273] width:146 height:5
        spinner radiusSpin "Radius: " type:#worldunits range:[0,1000000,10] pos:[6,383] width:146 fieldWidth:62
        spinner gapSpin "Extra gap: " type:#worldunits range:[0,1000000,0] pos:[6,409] width:146 fieldWidth:62
        checkbox planarCheck "Plan XY (ignore height)" checked:true pos:[6,435] width:146
        label overlapInfo "Before / Removed / Left" pos:[6,461] width:146
        label overlapCounts "-- / -- / --" pos:[6,481] width:146
        button statsButton "Refresh counts" pos:[6,505] width:146
        fn currentLayer = (if obj.activeLayer>0 and obj.activeLayer<=obj.layerObjects.count then obj.layerObjects[obj.activeLayer] else undefined)
        fn refreshOverlap = (
            refreshing=true
            local layer=currentLayer()
            for c in #(overlapCheck,blockerList,radiusSpin,gapSpin,planarCheck,statsButton) do c.enabled=layer!=undefined
            blockerRows=#();local labels=#();local chosen=#{}
            if layer!=undefined do (
                overlapCheck.checked=layer.overlapEnabled;radiusSpin.value=layer.overlapRadius;gapSpin.value=layer.overlapGap;planarCheck.checked=layer.overlapPlanar
                for i=1 to obj.layerObjects.count where obj.layerObjects[i]!=layer do (
                    append blockerRows i;append labels (obj.layerNames[i]+(if obj.layerEnabled[i] then "" else " (off)"))
                    if findItem layer.overlapBlockers i>0 do chosen[blockerRows.count]=true
                )
                local stats=layer.overlapStats();overlapCounts.text=(stats[1] as string)+" / "+(stats[2] as string)+" / "+(stats[3] as string)
            )
            blockerList.items=labels;blockerList.selection=chosen
            refreshing=false
        )
        fn changedOverlap = (for layer in obj.layerObjects do layer.dirty=true;redrawViews())
        on overlapCheck changed v do if not refreshing do (undo "Remove overlaps" on (currentLayer()).overlapEnabled=v;changedOverlap())
        on radiusSpin changed v do if not refreshing do (undo "Overlap radius" on (currentLayer()).overlapRadius=v;changedOverlap())
        on gapSpin changed v do if not refreshing do (undo "Overlap gap" on (currentLayer()).overlapGap=v;changedOverlap())
        on planarCheck changed v do if not refreshing do (undo "Overlap distance" on (currentLayer()).overlapPlanar=v;changedOverlap())
        on blockerList selected i do if not refreshing do (
            undo "Blocking layers" on (currentLayer()).overlapBlockers=(for k in blockerList.selection collect blockerRows[k])
            changedOverlap()
        )
        on statsButton pressed do (obj.refreshAll();refreshOverlap())
        fn refresh = (
            refreshing=true;layerList.BeginUpdate()`);
 s=s.replace('            nameEdit.text=if valid then obj.layerNames[obj.activeLayer] else ""','            nameEdit.text=if valid then obj.layerNames[obj.activeLayer] else ""\n            refreshOverlap()');
 s=s.replace('nameEdit.text=obj.layerNames[obj.activeLayer]\n','nameEdit.text=obj.layerNames[obj.activeLayer]\n                refreshOverlap()\n');
 s=s.replace('on manager rolledUp state do parentView.layoutPanels()','on manager rolledUp expanded do (if expanded do refreshOverlap();parentView.layoutPanels())');
 return s;
};

