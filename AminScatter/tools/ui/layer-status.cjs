// Layer navigation and passive statistics. Runs after feature stages so the
// manager keeps their controls; no placement or renderer work belongs here.
const fs=require('fs');
module.exports=function(s){
 const replace=(a,b)=>{if(s.split(a).length!==2)throw Error('Layer UI anchor must be unique: '+a.slice(0,90));s=s.replace(a,b);};
 const helpers=fs.readFileSync('tools/ui/templates/layer-status-helpers.ms','utf8');
 s=helpers+'\n'+s;
 replace('    fn refreshPreview = (',`    local uiPreviewMode=0
    fn uiLayerStats = (
        CyrusLayerStatusData hasResult:(cachedPoints!=undefined and previewError=="") placements:generatedCount previewCount:cachedPointCount mode:uiPreviewMode buildMs:previewBuildMs needsUpdate:dirty errorText:previewError densityCapped:densityCapped inputOff:(disabledAnalyzerInput())
    )
    fn uiVersion = "2026-10-02.5"
    fn refreshPreview = (`);
 replace('            cachedPointCount=aminScatterPreviewCount cachedPoints','            cachedPointCount=aminScatterPreviewCount cachedPoints\n            uiPreviewMode=viewportMode');
 // A transferred legacy cache has no mode metadata. Keep its count, but never
 // label it with a potentially different current display mode.
 replace('    fn restoreCache state = (','    fn restoreCache state = (\n        uiPreviewMode=0');
 const a=s.indexOf('fn CyrusMakeManager target view = ('),b=s.indexOf('\nglobal CyrusMake_spacingUI_1',a);
 if(a<0||b<0)throw Error('Missing complete manager factory');
 let manager=s.slice(a,b);
 const edit=(old,value)=>{if(manager.split(old).length!==2)throw Error('Manager anchor must be unique: '+old.slice(0,90));manager=manager.replace(old,value);};
 edit('parentView=CyrusUIBuildView,refreshing=false','parentView=CyrusUIBuildView,refreshing=false,rowOwners=#(),rowSignatures=#(),rowDetails=#(),selectedOwner=undefined');
 // Keep the list compact, put two common actions on one row, and move the
 // existing overlap/cleanup controls below the selected-layer summary.
 manager=manager.replace(/pos:\[(\d+),(\d+)\]/g,(m,x,y)=>Number(y)>=226?`pos:[${x},${Number(y)+96}]`:m);
 edit('width:138 height:120','width:146 height:144');
 edit('button addButton "Add Layer" pos:[6,136] width:138','button addButton "Add Layer" pos:[6,196] width:70');
 edit('button removeButton "Remove Layer" pos:[6,162] width:138','button removeButton "Remove" pos:[82,196] width:70');
 edit('edittext nameEdit "Name:" pos:[6,196] width:138',`edittext nameEdit "Layer:" pos:[6,226] width:146
        label statsTotal "" pos:[6,158] width:146 height:32
        label statsDetail "" pos:[6,256] width:146 height:58`);
 edit('button statsButton "Refresh counts"','button statsButton "Update scatter + counts"');
 const methods=fs.readFileSync('tools/ui/templates/layer-status-manager.ms','utf8');
 edit('        fn refresh = (',methods+'\n        fn refresh = (');
 edit('refreshing=true;layerList.BeginUpdate();layerList.Items.Clear()', 'refreshing=true;layerList.BeginUpdate();layerList.Items.Clear();rowOwners=obj.layerObjects as array;rowSignatures=#();rowDetails=#()');
 edit('local item=layerList.Items.Add obj.layerNames[i]', 'local item=layerList.Items.Add obj.layerNames[i]\n                item.SubItems.Add "--";item.SubItems.Add "--"');
 edit('            refreshOverlap()\n        )\n        on manager open do (','            refreshOverlap();resizeColumns();refreshStats()\n        )\n        on manager open do (');
 edit('layerList.HeaderStyle=(dotNetClass "System.Windows.Forms.ColumnHeaderStyle").None','layerList.HeaderStyle=(dotNetClass "System.Windows.Forms.ColumnHeaderStyle").Nonclickable\n            layerList.ShowItemToolTips=true');
 edit('layerList.Columns.Add "Layer" (layerList.ClientSize.Width-4)', 'layerList.Columns.Add "Layer" 80\n            layerList.Columns.Add "Count" 54\n            layerList.Columns.Add "State" 42\n            layerList.Columns.Item[1].TextAlign=(dotNetClass "System.Windows.Forms.HorizontalAlignment").Right');
 edit('on manager rolledUp expanded do (if expanded do refreshOverlap();parentView.layoutPanels())', 'on manager rolledUp expanded do (if expanded do syncSelection force:true;parentView.layoutPanels())\n        on manager close do (rowOwners=#();rowSignatures=#();rowDetails=#();selectedOwner=undefined)');
 edit('                obj.selectLayer (layerList.SelectedIndices.Item[0]+1)\n                nameEdit.text=obj.layerNames[obj.activeLayer]\n                refreshOverlap()', '                local i=layerList.SelectedIndices.Item[0]+1\n                if i<=rowOwners.count do parentView.selectLayerView rowOwners[i]');
 edit('        on layerList ItemChecked sender args do (',`        on layerList MouseClick sender args do (
            local hit=layerList.HitTest args.X args.Y
            if hit.Item!=undefined and hit.Location!=(dotNetClass "System.Windows.Forms.ListViewHitTestLocations").StateImage do (
                local i=hit.Item.Index+1
                if i<=rowOwners.count do parentView.selectLayerView rowOwners[i] expand:true
            )
        )
        on layerList KeyUp sender args do (
            if args.KeyCode==(dotNetClass "System.Windows.Forms.Keys").Enter and currentLayer()!=undefined do parentView.selectLayerView (currentLayer()) expand:true
        )
        on layerList ItemChecked sender args do (`);
 edit('local i=args.Item.Index+1', 'local row=args.Item.Index+1\n                local i=if row<=rowOwners.count then findItem obj.layerObjects rowOwners[row] else 0');
 edit('on addButton pressed do (obj.newLayer();parentView.rebuildLayers();refresh();CyrusViewportRedraw())','on addButton pressed do (obj.newLayer();parentView.rebuildLayers();refresh();parentView.selectLayerView (currentLayer()) expand:true;CyrusViewportRedraw())');
 s=s.slice(0,a)+manager+s.slice(b);
 return s;
};
