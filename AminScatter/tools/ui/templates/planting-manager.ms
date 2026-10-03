    rollout mainUI "Cyrus Scatter 1.1 | Plant groups" width:#cmdPanel (
        local controlsReady=false,binding=false,dpiScale=1.0,lastRows=#()
        checkbox enabledCheck "Enable Cyrus Scatter" pos:[8,8] width:146
        pickbutton sharedPick "Pick shared surface" filter:AminScatterSourceFilter pos:[8,34] width:146
        label sharedInfo "Choose the shared surface." pos:[8,62] width:146 height:32
        button surfacesButton "Receiving surfaces..." pos:[8,96] width:146 tooltip:"Replace the shared receiving set. Painting requires one static receiver. Existing strokes are preserved."
        listbox layerList "Group / placed / state" items:#() pos:[8,130] width:146 height:7
        button addButton "Add" pos:[8,286] width:46
        button copyButton "Copy" pos:[58,286] width:46
        button removeButton "Remove" pos:[108,286] width:46
        edittext nameEdit "Group:" pos:[8,318] width:146
        checkbox visibleCheck "Visible in viewport" pos:[8,346] width:146
        checkbox renderCheck "Enabled group" pos:[8,372] width:146 tooltip:"Enabled groups participate in final output and spacing. Viewport visibility is separate."
        label countInfo "Add a plant group." pos:[8,402] width:146 height:126
        button policyButton "Shared spacing active" pos:[8,532] width:146
        button helpButton "Group details / help" pos:[8,562] width:146
        timer statusTimer interval:1000 active:false
        fn layoutPanels = true
        fn refreshTitles = true
        fn refreshStats = (
            if not controlsReady or binding do return false
            local rows=#(),detail="Add a plant group, assign its assets,\nthen choose Whole surface or Painted."
            for i=1 to layerObjects.count do (
                local group=layerObjects[i],state=group.uiLayerStats(),stats=group.groupStats()
                local status=CyrusUILayerState state layerEnabled[i] cyrusEnabled (visibleLayer i and (group.showPoints or group.showCenters))
                if state.hasResult and not state.needsUpdate and stats[3]>0 and groupPolicy==2 do status=#("Conflict","Manual edits overlap; preserved")
                append rows (layerNames[i]+" | "+(if state.hasResult then CyrusUICount state.placements compact:true else "--")+" | "+status[1])
                if i==activeLayer do (
                    detail="Editing: "+layerNames[i]+"\n"+status[2]
                    detail+="\nPlaced: "+(if state.hasResult then CyrusUICount state.placements else "--")
                    detail+="\n"+(if state.mode==1 then "Cloud points: " else if state.mode==4 then "Plant centres: " else "Shown instances: ")+(if state.hasResult then CyrusUICount state.previewCount else "--")
                    if groupPolicy==2 and state.hasResult do detail+="\nRemoved: "+(CyrusUICount stats[2])+"\nManual conflicts: "+(CyrusUICount stats[3])
                    detail+="\nBuild: "+(if state.hasResult then (state.buildMs as string)+" ms" else "--")
                    if group.brushRelaxPaused() do detail+="\nSome Relax settings are paused."
                    if state.errorText!="" do detail+="\n"+state.errorText
                )
            )
            local rowsChanged=rows.count!=lastRows.count
            if not rowsChanged do for i=1 to rows.count where rows[i]!=lastRows[i] do rowsChanged=true
            if rowsChanged do (binding=true;layerList.items=rows;layerList.selection=activeLayer;lastRows=rows;binding=false)
            if countInfo.text!=detail do countInfo.text=detail
            this.syncBrushCompatibility();true
        )
        fn bind = (
            binding=true
            local valid=selectedLayer()!=undefined,targets=this.validSurfaces()
            enabledCheck.checked=cyrusEnabled;layerList.selection=activeLayer
            sharedInfo.text=if targets.count==1 then targets[1].name else (if targets.count==0 then "Choose the shared surface." else (targets.count as string)+" surfaces; Brush needs one receiver")
            for c in #(removeButton,nameEdit,visibleCheck,renderCheck) do c.enabled=valid
            addButton.enabled=layerObjects.count<10;copyButton.enabled=valid and layerObjects.count<10
            nameEdit.text=if valid then layerNames[activeLayer] else ""
            visibleCheck.checked=valid and visibleLayer activeLayer;renderCheck.checked=valid and layerEnabled[activeLayer]
            policyButton.enabled=groupPolicy==1;policyButton.text=if groupPolicy==1 then "Upgrade legacy spacing..." else "Shared spacing active"
            binding=false;refreshStats()
        )
        fn setSurfaces nodes = (
            CyrusStopBrush()
            undo "Cyrus shared receiving surface" on (surfaceNodes=nodes;surface=undefined)
            this.invalidateGroups();this.bindNativeUI()
        )
        fn rebuild = bindNativeUI()
        fn rebuildLayers = bindNativeUI()
        fn selectLayerView layer expand:false = (local i=findItem layerObjects layer;if i>0 do selectLayer i;bindNativeUI())
        on mainUI open do (syncLayerIdentity();controlsReady=true;statusTimer.active=true;bind())
        on mainUI close do (controlsReady=false;statusTimer.active=false)
        on statusTimer tick do if mainUI.open and not CyrusInteractionHeld() do refreshStats()
        on sharedPick picked node do setSurfaces #(node)
        on surfacesButton pressed do (
            local nodes=selectByName title:"Cyrus shared receiving surfaces" buttonText:"Use selected" filter:AminScatterSourceFilter single:false
            if nodes!=undefined and nodes.count>0 do setSurfaces nodes
        )
        on layerList selected i do if not binding and i>0 do (selectLayer i;bindNativeUI())
        on enabledCheck changed value do if not binding do (undo "Cyrus enabled" on cyrusEnabled=value;this.invalidateGroups();bind())
        on visibleCheck changed value do if not binding and selectedLayer()!=undefined do (undo "Cyrus group visibility" on layerVisible[activeLayer]=value;CyrusViewportRedraw();bind())
        on renderCheck changed value do if not binding and selectedLayer()!=undefined do (undo "Cyrus group enabled" on layerEnabled[activeLayer]=value;this.invalidateGroups();bind())
        on nameEdit entered value do if not binding and selectedLayer()!=undefined and value!="" do (undo "Cyrus group name" on layerNames[activeLayer]=value;bindNativeUI())
        on addButton pressed do (newLayer();syncLayerIdentity();bindNativeUI();this.invalidateGroups())
        on copyButton pressed do copySelectedLayer()
        on removeButton pressed do (removeLayer();bindNativeUI();this.invalidateGroups())
        on policyButton pressed do (
            if queryBox "Use accepted final plant positions for shared spacing? Placement counts can change. Existing masks and sources are retained. This is one Undo action. Set group priority and check every spacing rule after conversion." title:"Cyrus group spacing" do (
                try(this.groupConversion();this.refreshAll();bind())catch(messageBox (getCurrentException()) title:"Cyrus group spacing")
            )
        )
        on helpButton pressed do (
            local message="One shared surface; independent plant groups. Select Grass, Red Flowers or another group, assign its assets, then paint that group's coverage. Each group keeps its editable stroke history.\n\nGroup spacing defines pair gaps. Higher priority is evaluated first. Manual overrides reserve their actual positions and are preserved; conflicting overrides are reported.\n\nPlaced counts accepted plants. Shown instances may be limited by the preview budgets. Point Cloud contains many points per plant. Coverage tint/samples show the painted field and are never a plant count.\n\nManual mode keeps the previous complete planting until Update. Hidden groups still participate in spacing/output; disabled groups do not.\n\nNative rollout headers open with one click; selecting a group reuses the same editor."
            messageBox (countInfo.text+"\n\n"+message) title:"Cyrus Scatter 1.1"
        )
    )
