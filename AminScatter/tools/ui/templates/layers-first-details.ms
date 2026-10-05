    rollout detailsUI "Statistics / Help" width:146 (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false
        label info "Statistics describe the last build." pos:[4,8] width:132 height:300
        button refreshButton "Read cached statistics" pos:[4,314] width:132
        button helpButton "Layer / display help" pos:[4,344] width:132
        fn bind layer = (
            local text="Last completed build\n"
            for leaf in root.layerSets owner do (
                local state=leaf.uiLayerStats(),stats=leaf.groupStats(),cache=leaf.cacheSnapshot(),index=findItem root.layerObjects leaf
                local status=CyrusUILayerState state (root.enabledLayer index) root.cyrusEnabled (root.visibleLayer index)
                text+="\n"+leaf.paintSetName+" | "+status[2]
                local eligible=if root.groupPolicy==2 then CyrusUICount stats[1] else "n/a (legacy)",removed=if root.groupPolicy==2 then CyrusUICount stats[2] else "n/a"
                text+="\nRequested: "+(CyrusUICount cache[8])+" | Eligible: "+eligible
                text+="\nPlaced: "+(CyrusUICount state.placements)+" | Removed: "+removed
                text+="\nShown: "+(CyrusUICount state.previewCount)+" | "+(state.buildMs as string)+" ms"
                if stats[3]>0 do text+="\nManual conflicts: "+(CyrusUICount stats[3])
                if root.groupPolicy==3 do (
                    local detail=leaf.procStatistics()
                    if detail[1].count==12 do (
                        text+="\nRejected layer / set / self: "+(detail[1][5] as string)+" / "+(detail[1][6] as string)+" / "+(detail[1][7] as string)
                        text+="\nCleanup: "+(detail[1][8] as string)+" | Shortfall: "+(detail[1][11] as string)
                        text+="\nEpoch: "+(detail[5] as string)+" | Rounds: "+(detail[2][1] as string)
                    )
                )
                if state.densityCapped do text+="\nDensity limited to 100,000 candidates."
                if leaf.brushRelaxPaused() do text+="\nRelax is paused for this coverage/policy."
                if state.errorText!="" do text+="\n"+state.errorText
            )
            info.text=text;controlsReady=true
        )
        on detailsUI open do bind owner
        on detailsUI close do controlsReady=false
        on refreshButton pressed do bind owner
        on helpButton pressed do messageBox (info.text+"\n\nPaint sets own assets and independent stroke history. Population, area, transforms and cleanup belong to the layer. Enabled set weights divide the layer budget.\n\nPoint Cloud uses many samples per plant; Plant centres uses one. Preview budgets affect display. Hidden owners still affect collision and render; disabled owners do not. Manual shows the previous completed build until Update. Paint feedback shows coverage, not accepted instances.\n\n"+(if root.groupPolicy==3 then "Procedural 0.7: visible order decides ordinary winners. Self, sibling-set and layer-pair rules are separate. Radius factor x (A + B) + gap; XY or 3D. Protected edits survive and report conflicts. Outside coverage uses explicitly referenced earlier siblings, including their shared Area domain. Between plants uses configured rules. Accepted target retries a bounded candidate prefix; a shortfall is not proof that the surface is full. Count/order changes preserve eligible Edit bindings; seed/source/receiver changes may need an explicit Reset. Relax is paused." else "Existing policy: within-layer collision includes all sets with 3D centre distance (2 x radius). Pair rules can use XY or 3D. Changes to base generation may invalidate CS Edit bindings. Existing results keep their original policy until explicit conversion.")+"\n\nBase cannot be removed separately; disable or erase it. Capacity: ten populations, including sets. A Point source is an accepted placeholder. Weighted Empty sources are supported in candidate-budget mode.") title:"Cyrus layer help"
    )
