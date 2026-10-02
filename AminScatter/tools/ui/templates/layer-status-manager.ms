        fn resizeColumns = (
            if layerList.Columns.Count==3 do (
                local w=layerList.ClientSize.Width-4
                local countWidth=amax 42 (layerList.Font.Height*4)
                local stateWidth=amax 34 (layerList.Font.Height*3)
                layerList.Columns.Item[0].Width=amax 40 (w-countWidth-stateWidth)
                layerList.Columns.Item[1].Width=countWidth
                layerList.Columns.Item[2].Width=stateWidth
            )
        )
        fn refreshStats = (
            -- Read scalar cache metadata only. Never synchronize, generate,
            -- enumerate preview points or redraw the viewport from this path.
            local same=rowOwners.count==obj.layerObjects.count and layerList.Items.Count==obj.layerObjects.count
            if same do for i=1 to rowOwners.count where rowOwners[i]!=obj.layerObjects[i] do same=false
            if not same do (manager.refresh();return true)
            local total=0,enabled=0,incomplete=false,detail="Select a layer to see its cached statistics."
            local colorClass=dotNetClass "System.Drawing.Color"
            for i=1 to rowOwners.count do (
                local layer=rowOwners[i],stats=layer.uiLayerStats()
                local active=obj.cyrusEnabled and obj.layerEnabled[i] and not stats.inputOff
                local state=CyrusUILayerState stats obj.layerEnabled[i] obj.cyrusEnabled (layer.showPoints or layer.showCenters)
                -- Cross the .NET boundary only when a displayed value changes.
                -- The signature contains scalar metadata, never point arrays.
                local signature=#(stats.hasResult,stats.placements,stats.previewCount,stats.mode,stats.buildMs,stats.needsUpdate,stats.errorText,stats.densityCapped,state,obj.layerNames[i]) as string
                if i>rowSignatures.count or rowSignatures[i]!=signature do (
                local item=layerList.Items.Item[i-1]
                local countText=if stats.hasResult then CyrusUICount stats.placements compact:true else "--"
                local exact=if stats.hasResult then CyrusUICount stats.placements else "--"
                local preview=if not stats.hasResult then "Preview: --" else (
                    case stats.mode of (
                        1: ("Preview dots: "+CyrusUICount stats.previewCount)
                        2: ("Proxy shown: "+CyrusUICount stats.previewCount)
                        3: ("Mesh shown: "+CyrusUICount stats.previewCount)
                        default: ("Preview count: "+CyrusUICount stats.previewCount+" (mode unknown)")
                    )
                )
                local timing=if stats.hasResult then "Last build: "+(stats.buildMs as string)+" ms" else if stats.errorText!="" then "Last attempt: "+(stats.buildMs as string)+" ms" else "Last build: --"
                local tip=obj.layerNames[i]+"\n"+state[2]+"\nPlacements: "+exact+"\n"+preview+"\n"+timing+"\nCounts are from the last preview build."
                if stats.densityCapped do tip+="\nGeneration density limit reached."
                if stats.errorText!="" do tip+="\n"+stats.errorText
                if item.Text!=obj.layerNames[i] do item.Text=obj.layerNames[i]
                if item.SubItems.Item[1].Text!=countText do item.SubItems.Item[1].Text=countText
                if item.SubItems.Item[2].Text!=state[1] do item.SubItems.Item[2].Text=state[1]
                if item.ToolTipText!=tip do item.ToolTipText=tip
                local ink=if state[1]=="Off" then colorClass.FromArgb 160 160 160 else if state[1]=="Error" then colorClass.FromArgb 255 150 135 else if state[1]=="Stale" then colorClass.FromArgb 240 205 125 else colorClass.WhiteSmoke
                if not item.ForeColor.Equals ink do item.ForeColor=ink
                rowDetails[i]=state[2]+" | "+exact+" placed\n"+preview+"\n"+timing
                rowSignatures[i]=signature
                )
                if active do (
                    enabled+=1
                    if stats.hasResult then total+=stats.placements else incomplete=true
                    if stats.needsUpdate or stats.errorText!="" do incomplete=true
                )
                if i==obj.activeLayer do detail=rowDetails[i]
            )
            local summary=(enabled as string)+" enabled | "+(CyrusUICount total compact:true)+" placed\n"+(if incomplete then "Last counts: stale or incomplete" else "Counts from last preview build")
            if statsTotal.text!=summary do statsTotal.text=summary
            if statsDetail.text!=detail do statsDetail.text=detail
            true
        )
        fn syncSelection force:false = (
            refreshing=true
            try (
                for i=0 to layerList.Items.Count-1 do (
                    local item=layerList.Items.Item[i],chosen=i+1==obj.activeLayer
                    if item.Selected!=chosen do item.Selected=chosen
                )
                local valid=obj.activeLayer>0 and obj.activeLayer<=obj.layerNames.count
                if nameEdit.enabled!=valid do nameEdit.enabled=valid
                if removeButton.enabled!=valid do removeButton.enabled=valid
                local label=if valid then obj.layerNames[obj.activeLayer] else ""
                if nameEdit.text!=label do nameEdit.text=label
            )catch(refreshing=false;throw())
            refreshing=false
            local layer=currentLayer()
            if force or selectedOwner!=layer do (refreshOverlap();selectedOwner=layer)
            refreshStats()
        )
