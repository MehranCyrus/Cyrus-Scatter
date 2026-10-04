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
                if state.densityCapped do text+="\nDensity limited to 100,000 candidates."
                if leaf.brushRelaxPaused() do text+="\nRelax is paused for this coverage/policy."
                if state.errorText!="" do text+="\n"+state.errorText
            )
            info.text=text;controlsReady=true
        )
        on detailsUI open do bind owner
        on detailsUI close do controlsReady=false
        on refreshButton pressed do bind owner
        on helpButton pressed do messageBox (info.text+"\n\nAll sections belong to this layer. Paint sets own their assets and independent stroke history. Population, area, transforms and spacing apply to the whole layer. A shared candidate budget is split by enabled set weights before painted coverage.\n\nPoint Cloud uses many samples per plant; Plant centres uses one. Mesh/Proxy and cloud budgets affect display, never final output. Hidden layers/sets still affect collision and render; disabled ones do not.\n\nManual keeps the previous completed planting until Update. Live mode updates after changes. Paint tint/samples show mask coverage, not instance counts.\n\nWithin-layer collision uses 3D centre spacing (2 x radius), including all paint sets. Between-layer rules can use XY or 3D; footprints are radius approximations. Manual Edit overrides are retained and conflicts reported. Changing base generation (seed/count/set budget) can invalidate an existing Edit binding; preserve/Undo the change or explicitly reset Edit.\n\nThe first/base set cannot be removed separately from its layer; it can be renamed, disabled or erased. Capacity: 10 total populations per controller.") title:"Cyrus layer help"
    )
