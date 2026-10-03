    local cachedPaintRevision=0,paintPopulation="",paintBaseKey="",paintBaseRows=undefined,paintBaseBuilds=0,paintBaseHits=0,paintSignatureRows=undefined
    parameters paintSettings (
        paintDocument type:#maxObject
        paintEnabled type:#boolean default:false
        paintIdentity type:#boolean default:false
        paintDensity type:#float default:1
        editLayerKey type:#integer default:0
        nextEditLayerKey type:#integer default:1
        on paintDocument set value do (cachedPaintRevision=0;dirty=true)
        on paintEnabled set value do dirty=true
        on paintDensity set value do dirty=true
    )
    fn brushMaskActive = (paintIdentity and paintEnabled and paintDocument!=undefined)
    fn brushRelaxPaused = (this.brushMaskActive() and (relaxEnabled or finalRelax))
    fn checkPaintRevision = (
        if paintDocument!=undefined do (
            local state=cyrusBrushStats paintDocument
            if state[6]==0 and state[1]!=cachedPaintRevision do (cachedPaintRevision=state[1];dirty=true)
        )
    )
    fn paintKey = (
        if paintDocument==undefined then "none" else ((getHandleByAnim paintDocument as string)+":"+((cyrusBrushStats paintDocument)[1] as string))
    )
    fn applyPaint rows = (
        if not paintIdentity do return rows
        if paintSignatureRows!=rows do (
            -- Ownership GUIDs must not change probabilistic mask acceptance on Copy Layer.
            paintPopulation=cyrusEditFingerprint rows ((randomSeed as string)+"|"+(diversitySeed as string))
            paintSignatureRows=rows
        )
        if not paintEnabled or paintDocument==undefined do return (cyrusClonePlacementRows rows)
        local result=cyrusBrushFilter paintDocument rows paintPopulation paintDensity
        cachedPaintRevision=(cyrusBrushStats paintDocument)[1]
        result
    )
    fn paintBaseInputKey plants previewOnly = (
        local stream=stringStream ""
        with printAllElements on (
            format "%|%|%|%|%|" currentTime CyrusPFRevision CyrusPFManualRevision plants previewOnly to:stream
            format "EffectiveRelax:%|" (relaxEnabled and not this.brushMaskActive()) to:stream
            for key in AminScatterLayerFields where findItem #(#paintDocument,#paintEnabled,#paintIdentity,#paintDensity,#bakedNodes,#showPoints,#pointsPerPlant,#updateMode,#autoRender,#previewBudget,#pointColorMode,#solidPointColor) key==0 do format "%:%|" key (getProperty this key) to:stream
            for n in (this.validSurfaces()+(sources as array)+(areaNodes as array)+(patternLines as array)+#(analyzerNode,areaAnalyzer,fallAnalyzer)) where isValidNode n do format "%:%|" (getHandleByAnim n) n.objectTransform to:stream
            for n in #(analyzerNode,areaAnalyzer,fallAnalyzer) where isValidNode n do format "%|" (n.getAnalysisRuns()) to:stream
            format "%|%|%|%|%|%|%|%|" strokeSides strokeModes strokeColorRows strokeColorKeys strokeSourceRows strokeSourceNodes strokeMin strokeMax to:stream
        )
        stream as string
    )
    fn paintCacheStats = (#(paintBaseBuilds,paintBaseHits,if paintBaseRows==undefined then 0 else paintBaseRows.count))
    fn publishPaint = (
        checkPaintRevision()
        if this.mainUI.controlsReady do this.mainUI.refreshStats()
        CyrusViewportRedraw()
    )
    rollout brushUI "Procedural Brush" width:#cmdPanel (
        local obj=undefined,controlsReady=false,binding=false,history=#()
        checkbox maskCheck "Use painted density" pos:[8,8] width:146
        pickbutton targetPick "Pick receiving surface" filter:AminScatterSourceFilter pos:[8,34] width:146 tooltip:"This Brush layer uses one receiving object, including curved meshes. It overrides the shared surface list for this layer."
        label targetInfo "No Brush target" pos:[8,62] width:146 height:32
        radiobuttons modeRadio "Next stroke" labels:#("Paint","Erase") columns:2 pos:[8,98] width:146
        spinner radiusSpin "Radius:" type:#worldunits range:[0.0001,1e9,20] fieldWidth:58 pos:[8,152] width:146
        spinner strengthSpin "Strength %:" range:[0,100,100] fieldWidth:58 pos:[8,180] width:146
        spinner softSpin "Softness %:" range:[0,100,50] fieldWidth:58 pos:[8,208] width:146
        spinner densitySpin "Density %:" range:[0,100,100] fieldWidth:58 pos:[8,236] width:146 tooltip:"Thins the stable candidate population. Increase Count or plants/m2 in Point Generation for a larger base population."
        button beginButton "Start Brush" pos:[8,270] width:70
        button stopButton "Stop" pos:[84,270] width:70
        button fillButton "Fill" pos:[8,302] width:70 tooltip:"Fill the receiving surface and reset stroke history. Undo restores the previous field."
        button emptyButton "Empty" pos:[84,302] width:70 tooltip:"Empty the density field and reset stroke history. Undo restores the previous field."
        label brushState "Pick a target to start." pos:[8,334] width:146 height:54
        listbox strokeList "Editable stroke history" items:#() pos:[8,394] width:146 height:5
        checkbox strokeEnabled "Stroke enabled" pos:[8,514] width:146
        checkbox strokeErase "Erase stroke" pos:[8,540] width:146
        spinner strokeRadius "Radius:" type:#worldunits range:[0.0001,1e9,20] fieldWidth:58 pos:[8,568] width:146
        spinner strokeStrength "Strength %:" range:[0,100,100] fieldWidth:58 pos:[8,596] width:146
        spinner strokeSoft "Softness %:" range:[0,100,50] fieldWidth:58 pos:[8,624] width:146
        button deleteStroke "Delete stroke" pos:[8,658] width:146
        label brushHelp "White dots show density.\nRight-click stops Brush.\nManual mode waits for Update." pos:[8,690] width:146 height:54
        fn showStroke = (
            binding=true
            local i=strokeList.selection,valid=i>0 and i<=history.count
            for c in #(strokeEnabled,strokeErase,strokeRadius,strokeStrength,strokeSoft,deleteStroke) do c.enabled=valid
            if valid do (
                local row=history[i]
                strokeEnabled.checked=row[1];strokeErase.checked=row[2];strokeRadius.value=row[3];strokeStrength.value=row[4]*100;strokeSoft.value=row[5]*100
            )
            binding=false
        )
        fn refreshHistory = (
            binding=true
            local chosen=strokeList.selection
            history=if obj!=undefined and obj.paintDocument!=undefined then cyrusBrushHistory obj.paintDocument else #()
            strokeList.items=for i=1 to history.count collect ((i as string)+" | "+(if history[i][2] then "Erase" else "Paint")+(if history[i][1] then "" else " (off)")+" | "+(history[i][6] as string)+" samples")
            strokeList.selection=amin chosen history.count
            binding=false;showStroke()
        )
        fn editStroke = (
            local i=strokeList.selection
            if binding or i<1 or i>history.count do return false
            cyrusBrushStroke obj.paintDocument i strokeEnabled.checked (strokeStrength.value/100.0) strokeRadius.value (strokeSoft.value/100.0) strokeErase.checked
            obj.publishPaint();refreshHistory()
        )
        fn saveOptions = (
            if not binding and obj!=undefined and obj.paintDocument!=undefined do cyrusBrushSettings obj.paintDocument radiusSpin.value (strengthSpin.value/100.0) (softSpin.value/100.0) (modeRadio.state==2) 1.0
        )
        fn status = (
            if obj==undefined do return false
            if obj.paintDocument==undefined then brushState.text="Pick a receiving surface." else (
                local state=cyrusBrushStats obj.paintDocument
                local message=(if state[5]==1 then "Brush active" else "Brush stopped")+" | "+(CyrusUICount state[2])+" strokes"
                if state[11]!="" do message+="\n"+state[11]
                if obj.updateMode==1 and obj.dirty do message+="\nPlants need Update."
                if brushState.text!=message do brushState.text=message
            )
        )
        fn bind layer = (
            binding=true;obj=layer
            for c in brushUI.controls do c.enabled=layer!=undefined
            local has=layer!=undefined and layer.paintDocument!=undefined
            for c in #(maskCheck,modeRadio,radiusSpin,strengthSpin,softSpin,densitySpin,beginButton,stopButton,fillButton,emptyButton) do c.enabled=has
            targetInfo.text=if has and isValidNode (cyrusBrushTarget layer.paintDocument) then (cyrusBrushTarget layer.paintDocument).name else "No Brush target"
            if has do (
                local cfg=cyrusBrushOptions layer.paintDocument
                maskCheck.checked=layer.paintEnabled;radiusSpin.value=cfg[1];strengthSpin.value=cfg[2]*100;softSpin.value=cfg[3]*100;modeRadio.state=if cfg[5] then 2 else 1;densitySpin.value=layer.paintDensity*100
            )
            controlsReady=true;binding=false;refreshHistory();status()
        )
        on brushUI open do bind (this.selectedLayer())
        on brushUI close do (controlsReady=false;CyrusStopBrush())
        on targetPick picked node do if obj!=undefined do (
            CyrusStopBrush()
            undo "Cyrus Brush target" on (obj.paintDocument=cyrusBrushCreate node;obj.paintIdentity=true;obj.paintEnabled=true)
            obj.publishPaint();bind obj;this.syncBrushCompatibility()
        )
        on maskCheck changed value do if not binding do (undo "Cyrus Brush enabled" on obj.paintEnabled=value;obj.publishPaint();this.syncBrushCompatibility())
        on modeRadio changed value do saveOptions()
        on radiusSpin changed value do saveOptions()
        on strengthSpin changed value do saveOptions()
        on softSpin changed value do saveOptions()
        on densitySpin changed value do if not binding do (undo "Cyrus Brush density" on obj.paintDensity=value/100.0;obj.publishPaint())
        on beginButton pressed do (saveOptions();CyrusStartBrush this obj;status())
        on stopButton pressed do (CyrusStopBrush();refreshHistory();status())
        on fillButton pressed do (cyrusBrushFill obj.paintDocument 1.0;obj.publishPaint();refreshHistory();status())
        on emptyButton pressed do (cyrusBrushFill obj.paintDocument 0.0;obj.publishPaint();refreshHistory();status())
        on strokeList selected value do showStroke()
        on strokeEnabled changed value do editStroke()
        on strokeErase changed value do editStroke()
        on strokeRadius changed value do editStroke()
        on strokeStrength changed value do editStroke()
        on strokeSoft changed value do editStroke()
        on deleteStroke pressed do if strokeList.selection>0 do (cyrusBrushDeleteStroke obj.paintDocument strokeList.selection;obj.publishPaint();refreshHistory();status())
    )
