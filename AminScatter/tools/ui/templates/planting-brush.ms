    rollout brushUI "Coverage / Brush" width:#cmdPanel (
        local obj=undefined,controlsReady=false,binding=false,history=#()
        label activeInfo "Select a plant group." pos:[8,8] width:146 height:32
        dropdownlist coverageMode "Coverage" items:#("Whole shared surface","Painted area") pos:[8,44] width:146
        label targetInfo "Receiving surface comes from the setup." pos:[8,94] width:146 height:32
        radiobuttons modeRadio "Next stroke" labels:#("Paint","Erase") columns:2 pos:[8,130] width:146
        spinner radiusSpin "Radius:" type:#worldunits range:[0.0001,1e9,20] fieldWidth:58 pos:[8,184] width:146
        spinner strengthSpin "Strength %:" range:[0,100,100] fieldWidth:58 pos:[8,212] width:146
        spinner softSpin "Softness %:" range:[0,100,50] fieldWidth:58 pos:[8,240] width:146
        spinner densitySpin "Mask %:" range:[0,100,100] fieldWidth:58 pos:[8,268] width:146 tooltip:"Thins eligible plants. Set absolute Count or plants/m2 in Population / Density."
        button beginButton "Start Brush" pos:[8,300] width:70
        button stopButton "Stop" pos:[84,300] width:70
        button fillButton "Fill" pos:[8,332] width:70
        button emptyButton "Empty" pos:[84,332] width:70
        label brushState "Select a group and receiving surface." pos:[8,366] width:146 height:66
        dropdownlist overlayMode "Paint feedback" items:#("Coverage tint","Coverage samples","Off") pos:[8,436] width:146
        colorpicker overlayColor "Color:" pos:[8,490] width:146
        listbox strokeList "Group stroke history" items:#() pos:[8,522] width:146 height:5
        checkbox strokeEnabled "Enabled" pos:[8,638] width:70
        checkbox strokeErase "Erase" pos:[84,638] width:70
        spinner strokeRadius "Radius:" type:#worldunits range:[0.0001,1e9,20] fieldWidth:58 pos:[8,666] width:146
        spinner strokeStrength "Strength %:" range:[0,100,100] fieldWidth:58 pos:[8,694] width:146
        spinner strokeSoft "Softness %:" range:[0,100,50] fieldWidth:58 pos:[8,722] width:146
        button deleteStroke "Delete selected stroke" pos:[8,754] width:146
        button resetTarget "Reset coverage target..." pos:[8,786] width:146
        label brushHelp "One centre = one plant.\nTint shows painted coverage.\nManual mode needs Update." pos:[8,818] width:146 height:54
        fn showStroke = (
            binding=true
            local i=strokeList.selection,valid=i>0 and i<=history.count
            for c in #(strokeEnabled,strokeErase,strokeRadius,strokeStrength,strokeSoft,deleteStroke) do c.enabled=valid
            if valid do (local row=history[i];strokeEnabled.checked=row[1];strokeErase.checked=row[2];strokeRadius.value=row[3];strokeStrength.value=row[4]*100;strokeSoft.value=row[5]*100)
            binding=false
        )
        fn refreshHistory = (
            binding=true
            local chosen=strokeList.selection
            history=if obj!=undefined and obj.paintDocument!=undefined then cyrusBrushHistory obj.paintDocument else #()
            strokeList.items=for i=1 to history.count collect ((i as string)+" | "+(if history[i][2] then "Erase" else "Paint")+(if history[i][1] then "" else " (off)")+" | "+(history[i][6] as string)+" samples")
            strokeList.selection=amin chosen history.count;binding=false;showStroke()
        )
        fn editStroke = (
            local i=strokeList.selection
            if binding or i<1 or i>history.count do return false
            cyrusBrushStroke obj.paintDocument i strokeEnabled.checked (strokeStrength.value/100.0) strokeRadius.value (strokeSoft.value/100.0) strokeErase.checked
            obj.publishPaint();refreshHistory()
        )
        fn saveOptions = (
            if not binding and obj!=undefined and obj.paintDocument!=undefined do (
                cyrusBrushSettings obj.paintDocument radiusSpin.value (strengthSpin.value/100.0) (softSpin.value/100.0) (modeRadio.state==2) 1.0
                cyrusBrushDisplay obj.paintDocument obj.paintView obj.paintColor
            )
        )
        fn status = (
            if obj==undefined do return false
            if obj.paintDocument==undefined then brushState.text="Start Brush creates an empty mask\non the shared receiving surface." else (
                local state=cyrusBrushStats obj.paintDocument
                local message=(if state[5]==1 then "Brush active" else "Brush stopped")+" | "+(CyrusUICount state[2])+" strokes"
                if not obj.paintEnabled do message+="\nWhole surface; strokes retained."
                if state[11]!="" do message+="\n"+state[11]
                if obj.updateMode==1 and obj.dirty do message+="\nChanges pending; plants need Update."
                if state.count>=18 and state[18]>0 do message+="\nCoverage preview uses bounded detail."
                if brushState.text!=message do brushState.text=message
            )
        )
        fn bind layer = (
            binding=true;obj=layer
            for c in brushUI.controls do c.enabled=layer!=undefined
            local has=layer!=undefined and layer.paintDocument!=undefined
            for c in #(fillButton,emptyButton,stopButton) do c.enabled=has
            activeInfo.text=if layer==undefined then "Select a plant group." else "Painting: "+this.layerNames[this.activeLayer]
            local targets=this.validSurfaces()
            targetInfo.text=if has then "Mask surface: "+(if isValidNode (cyrusBrushTarget layer.paintDocument) then (cyrusBrushTarget layer.paintDocument).name else "<missing>") else (if targets.count==1 then "Shared surface: "+targets[1].name else "Pick one shared surface above.")
            if layer!=undefined do (
                coverageMode.selection=if layer.paintEnabled then 2 else 1
                densitySpin.value=layer.paintDensity*100;overlayMode.selection=findItem #(2,1,0) layer.paintView;overlayColor.color=layer.paintColor
            )
            if has do (local cfg=cyrusBrushOptions layer.paintDocument;radiusSpin.value=cfg[1];strengthSpin.value=cfg[2]*100;softSpin.value=cfg[3]*100;modeRadio.state=if cfg[5] then 2 else 1)
            controlsReady=true;binding=false;refreshHistory();status()
        )
        on brushUI open do bind (this.selectedLayer())
        on brushUI close do (controlsReady=false;CyrusStopBrush())
        on coverageMode selected i do if not binding and obj!=undefined do try(this.setGroupCoverage obj (i==2))catch(messageBox (getCurrentException()) title:"Cyrus coverage";bind obj)
        on beginButton pressed do if obj!=undefined do (
            try (
                local options=#(radiusSpin.value,strengthSpin.value,softSpin.value,modeRadio.state)
                this.setGroupCoverage obj true
                radiusSpin.value=options[1];strengthSpin.value=options[2];softSpin.value=options[3];modeRadio.state=options[4]
                saveOptions();CyrusStartBrush this obj;status()
            ) catch(messageBox (getCurrentException()) title:"Cyrus Brush")
        )
        on stopButton pressed do (CyrusStopBrush();refreshHistory();status())
        on modeRadio changed value do saveOptions()
        on radiusSpin changed value do saveOptions()
        on strengthSpin changed value do saveOptions()
        on softSpin changed value do saveOptions()
        on densitySpin changed value do if not binding and obj!=undefined do (undo "Cyrus painted density" on obj.paintDensity=value/100.0;obj.publishPaint())
        on overlayMode selected value do if not binding and obj!=undefined do (undo "Cyrus coverage display" on obj.paintView=(#(2,1,0))[value];saveOptions();redrawViews())
        on overlayColor changed value do if not binding and obj!=undefined do (undo "Cyrus coverage color" on obj.paintColor=value;saveOptions();redrawViews())
        on fillButton pressed do (cyrusBrushFill obj.paintDocument 1.0;obj.publishPaint();refreshHistory();status())
        on emptyButton pressed do (cyrusBrushFill obj.paintDocument 0.0;obj.publishPaint();refreshHistory();status())
        on strokeList selected value do showStroke()
        on strokeEnabled changed value do editStroke()
        on strokeErase changed value do editStroke()
        on strokeRadius changed value do editStroke()
        on strokeStrength changed value do editStroke()
        on strokeSoft changed value do editStroke()
        on deleteStroke pressed do if strokeList.selection>0 do (cyrusBrushDeleteStroke obj.paintDocument strokeList.selection;obj.publishPaint();refreshHistory();status())
        on resetTarget pressed do if obj!=undefined do (
            if queryBox "Replace this group's saved paint with an empty mask on the shared surface? Undo restores the previous document." title:"Cyrus reset coverage" do try(this.setGroupCoverage obj true reset:true)catch(messageBox (getCurrentException()) title:"Cyrus coverage")
        )
    )
