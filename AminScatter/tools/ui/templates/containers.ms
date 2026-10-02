global CyrusUIBuildTarget,CyrusUIBuildView,CyrusUIBuildIndex,CyrusMount
fn CyrusMount host r collapsed = (
    local oldTarget=CyrusUIBuildTarget,oldView=CyrusUIBuildView,oldIndex=CyrusUIBuildIndex
    CyrusUIBuildTarget=r.obj;CyrusUIBuildView=r.parentView
    CyrusUIBuildIndex=try(r.layerIndex)catch(0)
    try(addSubRollout host r rolledUp:collapsed)
    catch(
        CyrusUIBuildTarget=oldTarget;CyrusUIBuildView=oldView;CyrusUIBuildIndex=oldIndex
        throw()
    )
    CyrusUIBuildTarget=oldTarget;CyrusUIBuildView=oldView;CyrusUIBuildIndex=oldIndex
)
fn CyrusMakeManager target view = (
    rollout manager "Layer Manager" width:162 (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,refreshing=false
        dotNetControl layerList "System.Windows.Forms.ListView" pos:[6,8] width:138 height:120
        button addButton "Add Layer" pos:[6,136] width:138
        button removeButton "Remove Layer" pos:[6,162] width:138
        edittext nameEdit "Name:" pos:[6,196] width:138
        fn refresh = (
            refreshing=true;layerList.BeginUpdate();layerList.Items.Clear()
            for i=1 to obj.layerNames.count do (
                local item=layerList.Items.Add obj.layerNames[i]
                item.Checked=obj.layerEnabled[i]
                item.Selected=i==obj.activeLayer
            )
            layerList.EndUpdate();refreshing=false
            local valid=obj.activeLayer>0 and obj.activeLayer<=obj.layerNames.count
            nameEdit.enabled=valid;removeButton.enabled=valid
            addButton.enabled=obj.layerNames.count<10
            nameEdit.text=if valid then obj.layerNames[obj.activeLayer] else ""
        )
        on manager open do (
            layerList.View=(dotNetClass "System.Windows.Forms.View").Details
            layerList.HeaderStyle=(dotNetClass "System.Windows.Forms.ColumnHeaderStyle").None
            layerList.CheckBoxes=true;layerList.MultiSelect=false;layerList.FullRowSelect=true;layerList.HideSelection=false
            layerList.BackColor=(dotNetClass "System.Drawing.Color").FromArgb 80 80 80
            layerList.ForeColor=(dotNetClass "System.Drawing.Color").WhiteSmoke
            layerList.Columns.Add "Layer" (layerList.ClientSize.Width-4)
            refresh()
        )
        on manager rolledUp state do parentView.layoutPanels()
        on layerList SelectedIndexChanged sender args do (
            if not refreshing and layerList.SelectedIndices.Count>0 do (
                obj.selectLayer (layerList.SelectedIndices.Item[0]+1)
                nameEdit.text=obj.layerNames[obj.activeLayer]
            )
        )
        on layerList ItemChecked sender args do (
            if not refreshing do (
                local i=args.Item.Index+1
                if i>0 and i<=obj.layerEnabled.count do undo "Cyrus Scatter enable layer" on obj.layerEnabled[i]=args.Item.Checked
                redrawViews()
            )
        )
        on addButton pressed do (obj.newLayer();parentView.rebuildLayers();refresh();redrawViews())
        on removeButton pressed do (obj.removeLayer();parentView.rebuildLayers();refresh();redrawViews())
        on nameEdit entered value do (
            if obj.activeLayer>0 and value!="" do undo "Cyrus Scatter rename layer" on obj.layerNames[obj.activeLayer]=value
            parentView.refreshTitles();refresh()
        )
    )
    manager.obj=target;manager.parentView=view;manager
)
fn CyrusMakeLayer target view index = (
    rollout layerPanel "Layer" width:162 (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,layerIndex=CyrusUIBuildIndex,children=#()
        subrollout sections "" pos:[2,2] width:158 height:180 scrollBar:#off
        fn fitHeight = (
            local h=0
            local dpi=parentView.dpiScale
            local header=floor(23.333*dpi+0.5)
            for r in children do h+=(if r.open then r.height+header else header)
            if sections.pos!=[2,0] do sections.pos=[2,0]
            if sections.height!=h do sections.height=h
            if layerPanel.height!=h do layerPanel.height=h
        )
        on layerPanel open do (
            children=#(CyrusMake_sourceUI obj parentView,CyrusMake_distributionUI obj parentView,CyrusMake_areaUI obj parentView,CyrusMake_diversityUI obj parentView,CyrusMake_randomUI obj parentView)
            for r in children do CyrusMount sections r true
            fitHeight()
        )
        on layerPanel close do (children=#())
        on layerPanel rolledUp state do parentView.layoutPanels()
    )
    layerPanel.obj=target;layerPanel.parentView=view;layerPanel.layerIndex=index;layerPanel
)





